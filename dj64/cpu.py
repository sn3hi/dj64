"""
cpu.py - Unidad Central de Proceso del DJ-64: banco de registros R0-R7, ALU
(con banderas Z, N y P) y unidad de control (registros IC y CP).

Ciclo de instruccion (Tarea 9):
  1. Busqueda: se lee la palabra cuya direccion esta en CP y se carga en IC.
  2. Decodificacion: se identifica el formato (F1-F5) y el codigo de operacion.
  3. Ejecucion: accesos a registros, memoria y/o ALU segun el formato.
  4. Actualizacion del CP: +1 en instrucciones secuenciales; en saltos,
     llamadas y retornos se carga el valor correspondiente.

Banderas de la ALU (se actualizan con las operaciones aritmeticas, logicas,
de desplazamiento y de comparacion; Copiar, Cargar*, Almacenar, Lea, Push,
Pop y los saltos NO las modifican):
    Z = resultado cero      N = resultado negativo      P = resultado positivo
Comparar y CmpInm comparan con signo (sin desbordamiento) y activan Z si son
iguales, N si el primero es menor y P si es mayor.
"""

from collections import deque

from .isa import (decodificar, InstruccionInvalida, MASCARA_PALABRA, MASCARA_DIR,
                  NUM_REGISTROS, WORD_BITS, a_signed64, a_signed32)

SP = 7    # R7 actua como puntero de pila

_CONDICIONES = {
    'Saltar':             lambda f: True,
    'SaltarSiCero':       lambda f: f['Z'],
    'SaltarSiNoCero':     lambda f: not f['Z'],
    'SaltarSiNeg':        lambda f: f['N'],
    'SaltarSiPos':        lambda f: f['P'],
    'SaltarSiMayor':      lambda f: f['P'],
    'SaltarSiMenor':      lambda f: f['N'],
    'SaltarSiMayorIgual': lambda f: f['P'] or f['Z'],
    'SaltarSiMenorIgual': lambda f: f['N'] or f['Z'],
}


def _division_entera(a, b):
    """Division entera truncada hacia cero (a y b con signo)."""
    q = abs(a) // abs(b)
    return q if (a < 0) == (b < 0) else -q


class CPU:
    SP_INICIAL = 0xF000     # tope inicial de la pila (crece hacia direcciones menores)

    def __init__(self, memoria):
        self.memoria = memoria
        self.historial = deque(maxlen=100)     # ultimas instrucciones ejecutadas
        self.mnemonicos_ejecutados = set()
        self.reiniciar()

    def reiniciar(self):
        self.R = [0] * NUM_REGISTROS
        self.R[SP] = self.SP_INICIAL
        self.CP = 0
        self.IC = 0
        self.banderas = {'Z': 0, 'N': 0, 'P': 0}
        self.detenida = False
        self.pasos = 0
        self.mensaje = ""
        self.historial.clear()

    # ---------------- banderas ----------------
    def _banderas_por_signo(self, z, n, p):
        self.banderas['Z'], self.banderas['N'], self.banderas['P'] = int(z), int(n), int(p)

    def _fijar_banderas(self, resultado):
        v = a_signed64(resultado)
        self._banderas_por_signo(v == 0, v < 0, v > 0)

    def _comparar(self, a, b):
        self._banderas_por_signo(a == b, a < b, a > b)

    def _banderas_a_palabra(self):
        b = self.banderas
        return b['Z'] | (b['N'] << 1) | (b['P'] << 2)

    def _palabra_a_banderas(self, palabra):
        self._banderas_por_signo(palabra & 1, (palabra >> 1) & 1, (palabra >> 2) & 1)

    # ---------------- pila (R7) ----------------
    def _apilar(self, valor):
        self.R[SP] = (self.R[SP] - 1) & MASCARA_PALABRA
        self.memoria.escribir_palabra(self.R[SP], valor)

    def _desapilar(self):
        valor = self.memoria.leer_palabra(self.R[SP])
        self.R[SP] = (self.R[SP] + 1) & MASCARA_PALABRA
        return valor

    # ---------------- interrupciones ----------------
    def generar_interrupcion(self, direccion_rutina):
        """Simula una interrupcion externa: la unidad de control guarda en la
        pila el estado del procesador (banderas y CP) y salta a la rutina de
        atencion, que debe terminar con IRet. No hace nada si la CPU esta
        detenida."""
        if self.detenida:
            return False
        self._apilar(self._banderas_a_palabra())
        self._apilar(self.CP)
        self.CP = direccion_rutina & MASCARA_DIR
        return True

    # ---------------- ejecucion ----------------
    def paso(self):
        """Ejecuta UNA instruccion. Devuelve (direccion, mnemonico, operandos)
        o None si la CPU esta detenida o la instruccion es invalida."""
        if self.detenida:
            return None
        direccion = self.CP
        self.IC = self.memoria.leer_palabra(direccion)                 # 1. busqueda
        try:
            mnemonico, ops = decodificar(self.IC)                       # 2. decodificacion
        except InstruccionInvalida as e:
            self.detenida = True
            self.mensaje = f"INSTRUCCION INVALIDA en 0x{direccion:08X}: {e}"
            return None
        siguiente = self._ejecutar(mnemonico, ops, direccion)           # 3. ejecucion
        self.CP = siguiente & MASCARA_DIR                               # 4. actualizacion del CP
        self.pasos += 1
        self.historial.append((direccion, mnemonico, dict(ops)))
        self.mnemonicos_ejecutados.add(mnemonico)
        return direccion, mnemonico, ops

    def correr(self, max_pasos=1_000_000):
        """Ejecuta automaticamente hasta encontrar Parar (o hasta max_pasos mas)."""
        limite = self.pasos + max_pasos
        while not self.detenida and self.pasos < limite:
            self.paso()
        return self.pasos

    def _alu(self, registro, resultado):
        self.R[registro] = resultado & MASCARA_PALABRA
        self._fijar_banderas(self.R[registro])

    def _ejecutar(self, mn, o, d):
        R, mem = self.R, self.memoria
        sig = (d + 1) & MASCARA_DIR

        # ---- F1: sin operandos ----
        if mn == 'Parar':
            self.detenida = True
            sig = d
        elif mn == 'Nop':
            pass
        elif mn == 'Ret':
            sig = self._desapilar()
        elif mn == 'IRet':
            sig = self._desapilar()
            self._palabra_a_banderas(self._desapilar())

        # ---- F2: registro + memoria ----
        elif mn == 'Cargar':
            R[o['R']] = mem.leer_palabra(o['M'])
        elif mn == 'Almacenar':
            mem.escribir_palabra(o['M'], R[o['R']])
        elif mn == 'Lea':
            R[o['R']] = o['M']

        # ---- F3: registro + inmediato (aritmeticos con signo; logicos sin signo) ----
        elif mn == 'CargarValor':
            R[o['R']] = a_signed32(o['V']) & MASCARA_PALABRA
        elif mn == 'SumarInm':
            self._alu(o['R'], a_signed64(R[o['R']]) + a_signed32(o['V']))
        elif mn == 'RestarInm':
            self._alu(o['R'], a_signed64(R[o['R']]) - a_signed32(o['V']))
        elif mn == 'DespInm':
            self._alu(o['R'], a_signed64(R[o['R']]) >> (o['V'] & 63))
        elif mn == 'AndInm':
            self._alu(o['R'], R[o['R']] & o['V'])
        elif mn == 'OrInm':
            self._alu(o['R'], R[o['R']] | o['V'])
        elif mn == 'CmpInm':
            self._comparar(a_signed64(R[o['R']]), a_signed32(o['V']))

        # ---- F4: saltos y llamadas ----
        elif mn in _CONDICIONES:
            if _CONDICIONES[mn](self.banderas):
                sig = o['M']
        elif mn == 'Llamar':
            self._apilar(sig)
            sig = o['M']

        # ---- F5: uno o dos registros ----
        elif mn == 'Copiar':
            R[o['R']] = R[o['R2']]
        elif mn == 'Sumar':
            self._alu(o['R'], a_signed64(R[o['R']]) + a_signed64(R[o['R2']]))
        elif mn == 'Restar':
            self._alu(o['R'], a_signed64(R[o['R']]) - a_signed64(R[o['R2']]))
        elif mn == 'Mult':
            self._alu(o['R'], a_signed64(R[o['R']]) * a_signed64(R[o['R2']]))
        elif mn == 'Div':
            divisor = a_signed64(R[o['R2']])
            if divisor == 0:
                self.detenida = True
                self.mensaje = "*** DIVISION POR CERO: maquina detenida ***"
                sig = d
            else:
                self._alu(o['R'], _division_entera(a_signed64(R[o['R']]), divisor))
        elif mn == 'And':
            self._alu(o['R'], R[o['R']] & R[o['R2']])
        elif mn == 'Or':
            self._alu(o['R'], R[o['R']] | R[o['R2']])
        elif mn == 'Xor':
            self._alu(o['R'], R[o['R']] ^ R[o['R2']])
        elif mn == 'Comparar':
            self._comparar(a_signed64(R[o['R']]), a_signed64(R[o['R2']]))
        elif mn == 'DespIzq':
            self._alu(o['R'], R[o['R']] << (R[o['R2']] & 63))
        elif mn == 'DespDer':
            self._alu(o['R'], a_signed64(R[o['R']]) >> (R[o['R2']] & 63))
        elif mn == 'CargarIndR':
            R[o['R']] = mem.leer_palabra(R[o['R2']])
        elif mn == 'AlmacenarIndR':
            mem.escribir_palabra(R[o['R2']], R[o['R']])
        elif mn == 'Push':
            self._apilar(R[o['R']])
        elif mn == 'Pop':
            R[o['R']] = self._desapilar()
        elif mn == 'Neg':
            self._alu(o['R'], -a_signed64(R[o['R']]))
        elif mn == 'Not':
            self._alu(o['R'], ~R[o['R']])

        return sig

    # ---------------- inspeccion ----------------
    def estado(self):
        return {
            'CP': self.CP, 'IC': self.IC, 'R': list(self.R),
            'banderas': dict(self.banderas), 'detenida': self.detenida,
            'pasos': self.pasos, 'mensaje': self.mensaje,
        }
