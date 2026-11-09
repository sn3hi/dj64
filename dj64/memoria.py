"""
memoria.py - Jerarquia de memoria del DJ-64.

    Registros (en la CPU)  ->  Cache  ->  RAM  ->  Almacenamiento secundario

  - RAM: memoria principal direccionable por palabras de 64 bits. Se guarda en
    un diccionario disperso porque el espacio de direcciones (2^32 palabras)
    es enorme; una celda nunca escrita vale 0.
  - Cache: pequeña, de correspondencia directa, con politica de escritura
    "write-through". Guarda datos reales y cuenta aciertos y fallos.
  - Memoria: el controlador que ve la CPU por el bus. Si la direccion esta
    reservada para un periferico, el acceso va al periferico (E/S mapeada en
    memoria); si no, pasa por la cache y la RAM.
  - El almacenamiento secundario (disco) es un periferico mas, que se
    accede por direcciones reservadas (ver perifericos.py).

Hay dos formas de acceder a la RAM:
  * por el bus (leer_palabra / escribir_palabra): lo que hace la CPU;
    pasa por cache y por los dispositivos.
  * directa (leer_ram / escribir_ram / leer_bit / escribir_bit): lo que hace
    el operador o el Cargador para poner codigo y datos "a mano" en cualquier
    posicion o bit de la RAM. Mantiene la cache coherente.
"""

from .isa import MASCARA_PALABRA, MASCARA_DIR, WORD_BITS


class RAM:
    def __init__(self):
        self._celdas = {}

    def leer(self, direccion):
        return self._celdas.get(direccion, 0)

    def escribir(self, direccion, valor):
        self._celdas[direccion] = valor & MASCARA_PALABRA

    def celdas_usadas(self):
        return len(self._celdas)

    def limpiar(self):
        self._celdas.clear()


class Cache:
    """Cache de correspondencia directa: `lineas` lineas de `palabras_por_linea`
    palabras. Escritura write-through sin asignacion en fallo de escritura."""

    def __init__(self, ram, lineas=16, palabras_por_linea=4):
        self.ram = ram
        self.lineas = lineas
        self.palabras_por_linea = palabras_por_linea
        self._datos = [None] * lineas       # cada linea: [etiqueta, [palabras]]
        self.reiniciar_estadisticas()

    def reiniciar_estadisticas(self):
        self.aciertos_lectura = 0
        self.fallos_lectura = 0
        self.aciertos_escritura = 0
        self.fallos_escritura = 0

    def _ubicar(self, direccion):
        bloque = direccion // self.palabras_por_linea
        return bloque % self.lineas, bloque // self.lineas, direccion % self.palabras_por_linea

    def leer(self, direccion):
        indice, etiqueta, desplazamiento = self._ubicar(direccion)
        linea = self._datos[indice]
        if linea is not None and linea[0] == etiqueta:
            self.aciertos_lectura += 1
            return linea[1][desplazamiento]
        self.fallos_lectura += 1
        base = (direccion // self.palabras_por_linea) * self.palabras_por_linea
        palabras = [self.ram.leer((base + i) & MASCARA_DIR)
                    for i in range(self.palabras_por_linea)]
        self._datos[indice] = [etiqueta, palabras]
        return palabras[desplazamiento]

    def escribir(self, direccion, valor):
        self.ram.escribir(direccion, valor)              # write-through
        indice, etiqueta, desplazamiento = self._ubicar(direccion)
        linea = self._datos[indice]
        if linea is not None and linea[0] == etiqueta:
            self.aciertos_escritura += 1
            linea[1][desplazamiento] = valor & MASCARA_PALABRA
        else:
            self.fallos_escritura += 1

    def actualizar_si_presente(self, direccion, valor):
        """Mantiene la coherencia cuando la RAM se escribe directamente."""
        indice, etiqueta, desplazamiento = self._ubicar(direccion)
        linea = self._datos[indice]
        if linea is not None and linea[0] == etiqueta:
            linea[1][desplazamiento] = valor & MASCARA_PALABRA

    def vaciar(self):
        self._datos = [None] * self.lineas

    def estadisticas(self):
        lecturas = self.aciertos_lectura + self.fallos_lectura
        escrituras = self.aciertos_escritura + self.fallos_escritura
        return {
            'lineas': self.lineas,
            'palabras_por_linea': self.palabras_por_linea,
            'capacidad_palabras': self.lineas * self.palabras_por_linea,
            'lecturas': lecturas,
            'aciertos_lectura': self.aciertos_lectura,
            'fallos_lectura': self.fallos_lectura,
            'tasa_aciertos_lectura': (self.aciertos_lectura / lecturas) if lecturas else 0.0,
            'escrituras': escrituras,
            'aciertos_escritura': self.aciertos_escritura,
            'fallos_escritura': self.fallos_escritura,
        }


class Memoria:
    def __init__(self, lineas_cache=16, palabras_por_linea=4):
        self.ram = RAM()
        self.cache = Cache(self.ram, lineas_cache, palabras_por_linea)
        self._dispositivos = {}      # direccion -> (funcion_de_lectura, funcion_de_escritura)

    # ---------- dispositivos mapeados en memoria ----------
    def mapear(self, direccion, lectura=None, escritura=None):
        self._dispositivos[direccion & MASCARA_DIR] = (lectura, escritura)

    def es_dispositivo(self, direccion):
        return (direccion & MASCARA_DIR) in self._dispositivos

    # ---------- acceso por el bus (CPU) ----------
    def leer_palabra(self, direccion):
        direccion &= MASCARA_DIR
        if direccion in self._dispositivos:
            lectura = self._dispositivos[direccion][0]
            return (lectura() & MASCARA_PALABRA) if lectura else 0
        return self.cache.leer(direccion)

    def escribir_palabra(self, direccion, valor):
        direccion &= MASCARA_DIR
        valor &= MASCARA_PALABRA
        if direccion in self._dispositivos:
            escritura = self._dispositivos[direccion][1]
            if escritura:
                escritura(valor)
            return
        self.cache.escribir(direccion, valor)

    # ---------- acceso directo a la RAM (operador / Cargador) ----------
    def leer_ram(self, direccion):
        return self.ram.leer(direccion & MASCARA_DIR)

    def escribir_ram(self, direccion, valor):
        direccion &= MASCARA_DIR
        self.ram.escribir(direccion, valor)
        self.cache.actualizar_si_presente(direccion, valor)

    def leer_bit(self, direccion, n_bit):
        if not (0 <= n_bit < WORD_BITS):
            raise ValueError("n_bit debe estar entre 0 (menos significativo) y 63")
        return (self.leer_ram(direccion) >> n_bit) & 1

    def escribir_bit(self, direccion, n_bit, valor):
        if not (0 <= n_bit < WORD_BITS):
            raise ValueError("n_bit debe estar entre 0 (menos significativo) y 63")
        palabra = self.leer_ram(direccion)
        palabra = (palabra | (1 << n_bit)) if valor else (palabra & ~(1 << n_bit))
        self.escribir_ram(direccion, palabra)

    def cargar_palabras(self, direccion_base, palabras):
        for i, p in enumerate(palabras):
            self.escribir_ram(direccion_base + i, p)

    def volcado(self, direccion_inicial, cantidad):
        """Lista de (direccion, palabra) leida directamente de la RAM, sin
        efectos secundarios (no dispara periféricos ni toca la cache)."""
        return [((direccion_inicial + i) & MASCARA_DIR, self.leer_ram(direccion_inicial + i))
                for i in range(cantidad)]

    def limpiar(self):
        self.ram.limpiar()
        self.cache.vaciar()
        self.cache.reiniciar_estadisticas()
