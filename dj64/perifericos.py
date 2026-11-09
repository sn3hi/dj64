"""
perifericos.py - Teclado, pantalla, disco y adaptador de red del DJ-64.

Segun el diseño de la Tarea 9 no hay instrucciones especiales de E/S: se
reservan direcciones de memoria para cada periferico y se usan Cargar,
Almacenar y sus variantes (CargarIndR, AlmacenarIndR) para hablar con ellos
(E/S mapeada en memoria).

Mapa de direcciones reservadas (bus de direcciones de 32 bits):

    0xFFFF0000  TECLADO_DATO         lectura: siguiente dato tecleado (0 si no hay)
    0xFFFF0001  TECLADO_ESTADO       lectura: 1 si hay datos esperando, 0 si no
    0xFFFF0010  PANTALLA_CARACTER    escritura: muestra el caracter con ese codigo
    0xFFFF0011  PANTALLA_NUMERO      escritura: muestra el numero (con signo) y salto de linea
    0xFFFF0020  DISCO_DIRECCION      escritura: fija la posicion del disco; lectura: la devuelve
    0xFFFF0021  DISCO_DATO           lectura/escritura de la posicion actual (avanza 1 despues)
    0xFFFF0030  RED_ENVIAR           escritura: envia una palabra por el adaptador de red
    0xFFFF0031  RED_RECIBIR          lectura: siguiente palabra recibida (0 si no hay)
    0xFFFF0032  RED_ESTADO           lectura: cuantas palabras recibidas hay esperando
"""

import sys
from collections import deque

from .isa import MASCARA_PALABRA, MASCARA_DIR, a_signed64

TECLADO_DATO = 0xFFFF0000
TECLADO_ESTADO = 0xFFFF0001
PANTALLA_CARACTER = 0xFFFF0010
PANTALLA_NUMERO = 0xFFFF0011
DISCO_DIRECCION = 0xFFFF0020
DISCO_DATO = 0xFFFF0021
RED_ENVIAR = 0xFFFF0030
RED_RECIBIR = 0xFFFF0031
RED_ESTADO = 0xFFFF0032

CONSTANTES = {
    'TECLADO_DATO': TECLADO_DATO, 'TECLADO_ESTADO': TECLADO_ESTADO,
    'PANTALLA_CARACTER': PANTALLA_CARACTER, 'PANTALLA_NUMERO': PANTALLA_NUMERO,
    'DISCO_DIRECCION': DISCO_DIRECCION, 'DISCO_DATO': DISCO_DATO,
    'RED_ENVIAR': RED_ENVIAR, 'RED_RECIBIR': RED_RECIBIR, 'RED_ESTADO': RED_ESTADO,
}


class Teclado:
    def __init__(self, entrada_fn=None):
        self.cola = deque()
        # funcion opcional que se llama cuando el programa lee y no hay datos;
        # debe devolver un texto o una lista de numeros (modo interactivo)
        self.entrada_fn = entrada_fn

    def teclear(self, datos):
        if isinstance(datos, str):
            datos = [ord(c) for c in datos]
        self.cola.extend(int(d) & MASCARA_PALABRA for d in datos)

    def _leer_dato(self):
        if not self.cola and self.entrada_fn is not None:
            self.teclear(self.entrada_fn())
        return self.cola.popleft() if self.cola else 0

    def _leer_estado(self):
        return 1 if self.cola else 0

    def conectar(self, memoria):
        memoria.mapear(TECLADO_DATO, lectura=self._leer_dato)
        memoria.mapear(TECLADO_ESTADO, lectura=self._leer_estado)


class Pantalla:
    def __init__(self, salida=None):
        self.salida = salida if salida is not None else sys.stdout.write
        self.contenido = ""

    def _emitir(self, texto):
        self.contenido += texto
        self.salida(texto)

    def _escribir_caracter(self, valor):
        try:
            self._emitir(chr(valor & 0x10FFFF))
        except ValueError:
            self._emitir('?')

    def _escribir_numero(self, valor):
        self._emitir(f"{a_signed64(valor)}\n")

    def conectar(self, memoria):
        memoria.mapear(PANTALLA_CARACTER, escritura=self._escribir_caracter)
        memoria.mapear(PANTALLA_NUMERO, escritura=self._escribir_numero)


class Disco:
    """Almacenamiento secundario: un arreglo de palabras con un puntero de
    posicion que avanza solo despues de cada lectura o escritura."""

    def __init__(self):
        self.datos = {}
        self.puntero = 0
        self.lecturas = 0
        self.escrituras = 0

    def _fijar_puntero(self, valor):
        self.puntero = valor & MASCARA_DIR

    def _leer_puntero(self):
        return self.puntero

    def _leer_dato(self):
        valor = self.datos.get(self.puntero, 0)
        self.puntero = (self.puntero + 1) & MASCARA_DIR
        self.lecturas += 1
        return valor

    def _escribir_dato(self, valor):
        self.datos[self.puntero] = valor & MASCARA_PALABRA
        self.puntero = (self.puntero + 1) & MASCARA_DIR
        self.escrituras += 1

    def conectar(self, memoria):
        memoria.mapear(DISCO_DIRECCION, lectura=self._leer_puntero, escritura=self._fijar_puntero)
        memoria.mapear(DISCO_DATO, lectura=self._leer_dato, escritura=self._escribir_dato)


class AdaptadorRed:
    """Adaptador de red (NIC) simplificado. `enviados` guarda lo que el
    programa transmite; `inyectar` simula la llegada de datos desde la red.
    Con bucle_local=True lo enviado vuelve a la cola de recepcion (loopback)."""

    def __init__(self, bucle_local=False):
        self.rx = deque()
        self.enviados = []
        self.bucle_local = bucle_local

    def inyectar(self, valores):
        self.rx.extend(int(v) & MASCARA_PALABRA for v in valores)

    def _enviar(self, valor):
        self.enviados.append(valor)
        if self.bucle_local:
            self.rx.append(valor)

    def _recibir(self):
        return self.rx.popleft() if self.rx else 0

    def _estado(self):
        return len(self.rx)

    def conectar(self, memoria):
        memoria.mapear(RED_ENVIAR, escritura=self._enviar)
        memoria.mapear(RED_RECIBIR, lectura=self._recibir)
        memoria.mapear(RED_ESTADO, lectura=self._estado)


class Perifericos:
    """Crea y conecta los cuatro perifericos a una memoria."""

    def __init__(self, memoria, entrada_fn=None, salida=None, red_bucle_local=False):
        self.teclado = Teclado(entrada_fn)
        self.pantalla = Pantalla(salida)
        self.disco = Disco()
        self.red = AdaptadorRed(red_bucle_local)
        for p in (self.teclado, self.pantalla, self.disco, self.red):
            p.conectar(memoria)
