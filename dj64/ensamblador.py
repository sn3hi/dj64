"""
ensamblador.py - Traduce el lenguaje ensamblador del DJ-64 a codigo maquina.

Sintaxis:

    ; comentario (tambien al final de una linea)
    .equ NOMBRE, 0xFFFF0010          constante (no se reubica)
    etiqueta:  Instruccion  op1, op2
               Instruccion  op1

    .incluir "fpu.asm"               inserta otro archivo fuente (biblioteca)

    .datos
    n:         10                    una palabra de datos (entero de 64 bits)
    arreglo:   2, 4, 7, 10           varias palabras consecutivas
    uno:       1.0                   numero con punto: se guarda como doble IEEE 754
    texto:     "Hola"                un caracter por palabra, terminado en 0

Operandos: registro (R0..R7), numero (decimal o 0x...), constante (.equ) o
etiqueta (de codigo o de datos). Las instrucciones Push, Pop, Neg y Not usan
un solo registro.

Salidas:
  * ensamblar(base_codigo, base_datos): palabras con direcciones ya absolutas,
    para copiarlas directamente en la RAM.
  * generar_objeto(...): modulo objeto reubicable en el formato que lee el
    Cargador (registros H, T, M y E, como en el pseudocodigo de la Tarea 9).
"""

import os
import re
import struct

from .isa import INSTRUCCIONES, FORMATOS, UN_REGISTRO, NUM_REGISTROS, codificar, MASCARA_PALABRA

MASCARA32 = 0xFFFFFFFF
_CANONICO = {nombre.lower(): nombre for nombre in INSTRUCCIONES}
_RE_ETIQUETA = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$')
_RE_EQU = re.compile(r'\.equ\s+([A-Za-z_]\w*)\s*,?\s*(\S+)$', re.IGNORECASE)
_RE_NUMERO = re.compile(r'-?(0[xX][0-9A-Fa-f]+|\d+)$')
_RE_REGISTRO = re.compile(r'[Rr](\d+)$')
_RE_FLOTANTE = re.compile(r'-?(\d+\.\d*([eE][-+]?\d+)?|\d+[eE][-+]?\d+)$')
_RE_INCLUIR = re.compile(r'\.incluir\s+"?([^"]+?)"?$', re.IGNORECASE)
_RE_VALOR_DATO = re.compile(r'"[^"]*"|[^,]+')


def _bits_de_doble(texto):
    """Patron de bits IEEE 754 de doble precision de un literal como 1.5 o 2e-3."""
    return struct.unpack('>Q', struct.pack('>d', float(texto)))[0]


def _valores_de_datos(texto):
    """Separa una linea de datos en palabras: numeros enteros, numeros con
    punto decimal (se guardan como dobles IEEE 754), simbolos y textos entre
    comillas (un caracter por palabra, terminado en 0)."""
    valores = []
    for tok in _RE_VALOR_DATO.findall(texto):
        tok = tok.strip()
        if not tok:
            continue
        if tok.startswith('"'):
            valores.extend(('num', ord(c)) for c in tok[1:-1].replace('\\n', '\n'))
            valores.append(('num', 0))
        elif _RE_FLOTANTE.match(tok):
            valores.append(('num', _bits_de_doble(tok)))
        elif _es_numero(tok):
            valores.append(('num', _valor_numero(tok) & MASCARA_PALABRA))
        else:
            valores.append(('sim', tok))
    return valores or [('num', 0)]


class ErrorDeEnsamblado(Exception):
    pass


def _es_numero(tok):
    return _RE_NUMERO.match(tok) is not None


def _valor_numero(tok):
    neg = tok.startswith('-')
    t = tok[1:] if neg else tok
    v = int(t, 16) if t.lower().startswith('0x') else int(t)
    return -v if neg else v


class Ensamblado:
    """Resultado de ensamblar con unas bases de codigo y de datos dadas."""

    def __init__(self, base_codigo, base_datos, palabras_codigo, palabras_datos,
                 simbolos, reubicables):
        self.base_codigo = base_codigo
        self.base_datos = base_datos
        self.palabras_codigo = palabras_codigo
        self.palabras_datos = palabras_datos
        self.simbolos = simbolos            # etiqueta -> direccion (con las bases dadas)
        self.reubicables = reubicables      # direcciones de palabras que contienen una direccion

    def lineas_hex(self):
        """Listado 'DIRECCION PALABRA' (codigo y datos) que entiende Cargador.cargar_hex."""
        lineas = [f"{self.base_codigo + i:08X}  {p:016X}" for i, p in enumerate(self.palabras_codigo)]
        lineas += [f"{self.base_datos + i:08X}  {p:016X}" for i, p in enumerate(self.palabras_datos)]
        return lineas


class Ensamblador:
    def __init__(self):
        self.lineas_codigo = []      # (etiqueta, mnemonico, [operandos], n_linea)
        self.lineas_datos = []       # (etiqueta, [valores], n_linea)
        self.constantes = {}
        self._incluidos = set()

    # ---------------- lectura del fuente ----------------
    def leer_texto(self, texto, directorio='.'):
        seccion = 'codigo'
        for n, cruda in enumerate(texto.splitlines(), 1):
            s = cruda.split(';')[0].strip()
            if not s:
                continue
            m = _RE_INCLUIR.match(s)
            if m:
                ruta = os.path.abspath(os.path.join(directorio, m.group(1)))
                if ruta not in self._incluidos:
                    self._incluidos.add(ruta)
                    self.leer_archivo(ruta)
                continue
            if s.lower() == '.datos':
                seccion = 'datos'
                continue
            if s.lower() == '.codigo':
                seccion = 'codigo'
                continue
            m = _RE_EQU.match(s)
            if m:
                if not _es_numero(m.group(2)):
                    raise ErrorDeEnsamblado(f"linea {n}: .equ espera un numero, no '{m.group(2)}'")
                self.constantes[m.group(1)] = _valor_numero(m.group(2))
                continue
            etiqueta = None
            m = _RE_ETIQUETA.match(s)
            if m:
                etiqueta, s = m.group(1), m.group(2).strip()
            if seccion == 'codigo':
                if not s:
                    self.lineas_codigo.append((etiqueta, None, [], n))
                    continue
                partes = s.split(None, 1)
                mn = _CANONICO.get(partes[0].lower())
                if mn is None:
                    raise ErrorDeEnsamblado(f"linea {n}: instruccion desconocida '{partes[0]}'")
                ops = [t.strip() for t in partes[1].split(',')] if len(partes) > 1 else []
                self.lineas_codigo.append((etiqueta, mn, ops, n))
            else:
                self.lineas_datos.append((etiqueta, _valores_de_datos(s), n))

    def leer_archivo(self, ruta):
        self._incluidos.add(os.path.abspath(ruta))
        with open(ruta, 'r', encoding='utf-8') as f:
            self.leer_texto(f.read(), os.path.dirname(os.path.abspath(ruta)))

    # ---------------- ensamblado ----------------
    def ensamblar(self, base_codigo=0x1000, base_datos=0x2000):
        simbolos = {}

        def definir(etiqueta, direccion, n):
            if etiqueta in simbolos or etiqueta in self.constantes:
                raise ErrorDeEnsamblado(f"linea {n}: el simbolo '{etiqueta}' ya esta definido")
            simbolos[etiqueta] = direccion

        # primera pasada: direcciones de las etiquetas
        pc = base_codigo
        for etiqueta, mn, _, n in self.lineas_codigo:
            if etiqueta:
                definir(etiqueta, pc, n)
            if mn is not None:
                pc += 1
        dd = base_datos
        for etiqueta, valores, n in self.lineas_datos:
            if etiqueta:
                definir(etiqueta, dd, n)
            dd += len(valores)

        reubicables = []

        def resolver_direccion(tok, n):
            """Devuelve (valor, es_reubicable) para un operando de direccion."""
            if _es_numero(tok):
                return _valor_numero(tok) & MASCARA32, False
            if tok in self.constantes:
                return self.constantes[tok] & MASCARA32, False
            if tok in simbolos:
                return simbolos[tok] & MASCARA32, True
            raise ErrorDeEnsamblado(f"linea {n}: simbolo no definido '{tok}'")

        # datos
        palabras_datos = []
        for _, valores, n in self.lineas_datos:
            for tipo, v in valores:
                direccion = base_datos + len(palabras_datos)
                if tipo == 'num':
                    palabras_datos.append(v)
                elif v in self.constantes:
                    palabras_datos.append(self.constantes[v] & MASCARA_PALABRA)
                elif v in simbolos:
                    reubicables.append(direccion)
                    palabras_datos.append(simbolos[v] & MASCARA32)
                else:
                    raise ErrorDeEnsamblado(f"linea {n}: simbolo no definido '{v}'")

        # segunda pasada: codificacion
        palabras_codigo = []
        for _, mn, ops, n in self.lineas_codigo:
            if mn is None:
                continue
            direccion = base_codigo + len(palabras_codigo)
            fmt, _ = INSTRUCCIONES[mn]
            campos = FORMATOS[fmt][2]
            esperados = 1 if mn in UN_REGISTRO else len(campos)
            if len(ops) != esperados:
                raise ErrorDeEnsamblado(f"linea {n}: {mn} espera {esperados} operando(s) y recibio {len(ops)}")
            kw = {nombre: 0 for nombre, _ in campos}
            for (nombre, _), tok in zip(campos, ops):
                if nombre in ('R', 'R2'):
                    m = _RE_REGISTRO.match(tok)
                    if not m or int(m.group(1)) >= NUM_REGISTROS:
                        raise ErrorDeEnsamblado(f"linea {n}: '{tok}' no es un registro valido (R0-R7)")
                    kw[nombre] = int(m.group(1))
                elif nombre == 'M':
                    kw['M'], reub = resolver_direccion(tok, n)
                    if reub:
                        reubicables.append(direccion)
                elif nombre == 'V':
                    if _es_numero(tok):
                        kw['V'] = _valor_numero(tok) & MASCARA32
                    elif tok in self.constantes:
                        kw['V'] = self.constantes[tok] & MASCARA32
                    else:
                        raise ErrorDeEnsamblado(
                            f"linea {n}: un valor inmediato debe ser un numero o una constante "
                            f"(para usar la direccion de '{tok}' use Lea)")
            palabras_codigo.append(codificar(mn, **kw))

        return Ensamblado(base_codigo, base_datos, palabras_codigo, palabras_datos,
                          simbolos, reubicables)

    # ---------------- modulo objeto reubicable ----------------
    def generar_objeto(self, nombre, desplazamiento_datos=0x1000, entrada=None):
        """Texto del modulo objeto. El codigo se ensambla desde la direccion
        relativa 0 y los datos desde `desplazamiento_datos`; el Cargador suma la
        direccion base de carga (LAD) a cada palabra marcada con un registro M.

            H nombre tamaño     tamaño = cantidad de palabras (T) del modulo
            T dir palabra       texto: una palabra de codigo o de datos
            M dir               modificacion: sumar LAD al campo de direccion
            E entrada           fin del programa y punto de entrada (relativo)
        """
        res = self.ensamblar(0, desplazamiento_datos)
        if len(res.palabras_codigo) > desplazamiento_datos:
            raise ErrorDeEnsamblado("el codigo es mas grande que el desplazamiento de los datos")
        if entrada is None:
            punto_entrada = 0
        elif entrada in res.simbolos:
            punto_entrada = res.simbolos[entrada]
        else:
            raise ErrorDeEnsamblado(f"la etiqueta de entrada '{entrada}' no existe")
        tamano = len(res.palabras_codigo) + len(res.palabras_datos)
        lineas = [f"H {nombre} {tamano}"]
        lineas += [f"T {i:08X} {p:016X}" for i, p in enumerate(res.palabras_codigo)]
        lineas += [f"T {desplazamiento_datos + i:08X} {p:016X}" for i, p in enumerate(res.palabras_datos)]
        lineas += [f"M {d:08X}" for d in sorted(res.reubicables)]
        lineas.append(f"E {punto_entrada:08X}")
        return "\n".join(lineas) + "\n", res


def guardar_bin(palabras, ruta):
    with open(ruta, 'wb') as f:
        for p in palabras:
            f.write((p & MASCARA_PALABRA).to_bytes(8, 'big'))
