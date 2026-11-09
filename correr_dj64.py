"""
correr_dj64.py - Ejecuta en el emulador del DJ-64 (Tareas 10 y 17) la imagen
de memoria que produce el enlazador-cargador (archivo .hex).

El archivo trae una linea '; CP XXXXXXXX' con la direccion de la primera
instruccion y luego lineas 'DIRECCION PALABRA'. Se cargan con el Cargador
del emulador (cargar_hex), se pone el CP y se corre hasta 'Parar'.

Lo que el programa escribe en la pantalla del DJ-64 sale por la salida
estandar; las estadisticas, por la salida de errores.

Uso:  python3 correr_dj64.py imagen.hex
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dj64.cargador import Cargador
from dj64.cpu import CPU
from dj64.memoria import Memoria
from dj64.perifericos import Perifericos

MAX_PASOS = 200_000_000


def main():
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    ruta = sys.argv[1]
    with open(ruta, encoding='utf-8') as f:
        m = re.search(r'^;\s*CP\s+([0-9A-Fa-f]+)', f.read(), re.M)
    if not m:
        print(f"{ruta}: falta la linea '; CP ...' con el punto de entrada", file=sys.stderr)
        return 2

    memoria = Memoria()
    Perifericos(memoria, salida=sys.stdout.write)
    cpu = CPU(memoria)
    palabras = Cargador(memoria, cpu).cargar_hex(ruta, 0)
    cpu.CP = int(m.group(1), 16)
    cpu.correr(MAX_PASOS)
    sys.stdout.flush()

    print(f"[DJ-64] {palabras} palabras cargadas, CP inicial {m.group(1)}, "
          f"instrucciones ejecutadas: {cpu.pasos}", file=sys.stderr)
    if cpu.mensaje:
        print(f"[DJ-64] {cpu.mensaje}", file=sys.stderr)
        return 1
    if not cpu.detenida:
        print(f"[DJ-64] no termino en {MAX_PASOS} pasos", file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
