"""
cargador.py - Submodulo "Cargador" del Enlazador-Cargador del DJ-64.

Implementa el pseudocodigo entregado en la Tarea 9:

    LAD = Direccion de Memoria Inicial
    Mientras no sea Fin_Programa hacer:
        Leer Registro
        Si Registro es Texto/Codigo:
            Direccion_Destino = LAD + Registro.Direccion_Relativa
            Escribir_RAM(Direccion_Destino, Registro.Cod_Maquina)
        Si Registro es Modificacion:
            Direccion_Modificar = LAD + Registro.Direccion_Instruccion
            V_Actual = Leer_RAM(Direccion_Modificar)
            V_Nuevo  = V_Actual + LAD
            Escribir_RAM(Direccion_Modificar, V_Nuevo)
    Actualizar_PC(LAD + Registro_E.Punto_Entrada)

Registros del modulo objeto (texto plano, uno por linea):
    H nombre tamaño        encabezado; tamaño = palabras que tiene el programa
    T dir palabra          texto: una palabra de codigo o datos (dir relativa, hex)
    M dir                  modificacion: sumar LAD a la direccion de esa palabra
    E entrada              fin del programa; punto de entrada relativo (hex)

El "Contador Bytes" del diseño (tamaño del programa, que se decrementa con cada
carga) es aqui `contador_palabras`, porque la memoria se direcciona por palabras.
La suma de LAD se hace sobre el campo de direccion (32 bits menos significativos)
de la palabra, que es donde estan las direcciones en los formatos F2 y F4.

Ademas se admiten dos formas simples de cargar codigo ya en binario:
    cargar_bin  archivo con palabras de 64 bits (8 bytes cada una, big-endian)
    cargar_hex  archivo de texto: 'DIRECCION PALABRA' o solo 'PALABRA' por linea
"""

from .isa import MASCARA_PALABRA, MASCARA_DIR


class ErrorDeCarga(ValueError):
    pass


class Cargador:
    def __init__(self, memoria, cpu=None):
        self.memoria = memoria
        self.cpu = cpu               # si se da, el cargador actualiza su CP al terminar
        self.LAD = 0                 # Direccion Base de Carga
        self.PC = 0                  # PC con el que quedo el programa cargado
        self.contador_palabras = 0   # "Contador Bytes" del diseño

    # ---------------- modulo objeto reubicable ----------------
    def cargar_objeto(self, ruta, direccion_inicial):
        with open(ruta, 'r', encoding='utf-8') as f:
            return self.cargar_objeto_texto(f.read(), direccion_inicial)

    def cargar_objeto_texto(self, texto, direccion_inicial):
        self.LAD = direccion_inicial & MASCARA_DIR
        self.contador_palabras = 0
        nombre, tamano, entrada = None, None, None
        for n, linea in enumerate(texto.splitlines(), 1):
            linea = linea.split(';')[0].strip()
            if not linea:
                continue
            partes = linea.split()
            tipo = partes[0].upper()
            try:
                if tipo == 'H':
                    nombre, tamano = partes[1], int(partes[2])
                    self.contador_palabras = tamano
                elif tipo == 'T':
                    if tamano is None:
                        raise ErrorDeCarga("registro T antes del encabezado H")
                    destino = (self.LAD + int(partes[1], 16)) & MASCARA_DIR
                    self.memoria.escribir_ram(destino, int(partes[2], 16) & MASCARA_PALABRA)
                    self.contador_palabras -= 1
                elif tipo == 'M':
                    modificar = (self.LAD + int(partes[1], 16)) & MASCARA_DIR
                    actual = self.memoria.leer_ram(modificar)
                    nuevo = (actual & ~MASCARA_DIR) | ((actual + self.LAD) & MASCARA_DIR)
                    self.memoria.escribir_ram(modificar, nuevo)
                elif tipo == 'E':
                    entrada = int(partes[1], 16)
                    break
                else:
                    raise ErrorDeCarga(f"tipo de registro desconocido '{partes[0]}'")
            except (IndexError, ValueError) as e:
                raise ErrorDeCarga(f"linea {n} del modulo objeto: {e}") from e
        if entrada is None:
            raise ErrorDeCarga("el modulo no termina con un registro E (fin de programa)")
        if self.contador_palabras != 0:
            raise ErrorDeCarga(
                f"el encabezado declara {tamano} palabras pero el modulo trae "
                f"{tamano - self.contador_palabras}")
        self.PC = (self.LAD + entrada) & MASCARA_DIR
        if self.cpu is not None:
            self.cpu.CP = self.PC
        return {'nombre': nombre, 'palabras': tamano, 'LAD': self.LAD, 'PC': self.PC}

    # ---------------- archivos con codigo ya en binario ----------------
    def cargar_bin(self, ruta, direccion_base):
        with open(ruta, 'rb') as f:
            datos = f.read()
        if len(datos) % 8:
            raise ErrorDeCarga("el .bin no contiene un numero entero de palabras de 64 bits")
        palabras = [int.from_bytes(datos[i:i + 8], 'big') for i in range(0, len(datos), 8)]
        self.memoria.cargar_palabras(direccion_base, palabras)
        return len(palabras)

    def cargar_hex(self, ruta, direccion_base=0):
        """Cada linea es 'DIRECCION PALABRA' (la direccion se suma a direccion_base)
        o solo 'PALABRA' (se coloca en la posicion siguiente a la anterior)."""
        siguiente = direccion_base
        cargadas = 0
        with open(ruta, 'r', encoding='utf-8') as f:
            for n, linea in enumerate(f, 1):
                linea = linea.split(';')[0].split('#')[0].strip()
                if not linea:
                    continue
                partes = linea.split()
                try:
                    if len(partes) >= 2:
                        destino = direccion_base + int(partes[0], 16)
                        palabra = int(partes[1], 16)
                    else:
                        destino, palabra = siguiente, int(partes[0], 16)
                except ValueError as e:
                    raise ErrorDeCarga(f"linea {n} del .hex: {e}") from e
                self.memoria.escribir_ram(destino, palabra & MASCARA_PALABRA)
                siguiente = destino + 1
                cargadas += 1
        return cargadas

    # ---------------- escritura manual ----------------
    def escribir_directo(self, direccion, valor):
        """Pone una palabra a mano en la RAM (sin pasar por ningun archivo)."""
        self.memoria.escribir_ram(direccion, valor)
