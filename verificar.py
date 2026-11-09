"""
verificar.py - Compara el ensamblador y el cargador escritos en Flex con los
del emulador de la Tarea 10 (escritos en Python), palabra por palabra.

1. Ensamblador: para cada programa ya preprocesado (salidas/<p>.pp.asm) se
   comparan las palabras y los registros M del modulo objeto de Flex
   (salidas/<p>.obj) con lo que produce dj64/ensamblador.py para el mismo
   fuente (datos justo despues del codigo, igual que en el Taller).
2. Enlazador-cargador: el modulo enlazado (salidas/<e>.obj) se carga con el
   Cargador de Python en la misma LAD, y la memoria resultante se compara con
   la imagen .hex que genero el cargador de Flex.

Uso:  python3 verificar.py ensamblador p1 p2 ...
      python3 verificar.py cargador enlazado.obj imagen.hex LAD
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dj64.cargador import Cargador
from dj64.ensamblador import Ensamblador
from dj64.memoria import Memoria

SALIDAS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'salidas')


def registros(texto, tipo):
    return [l for l in texto.splitlines() if l.startswith(tipo + ' ')]


def verificar_ensamblador(programas):
    fallos = 0
    for p in programas:
        with open(os.path.join(SALIDAS, f'{p}.pp.asm'), encoding='utf-8') as f:
            # .global/.externo solo existen en el Taller: no generan palabras
            fuente = re.sub(r'^\s*\.(global|externo)\b.*$', '', f.read(), flags=re.M | re.I)
        asm = Ensamblador()
        asm.leer_texto(fuente)
        n_codigo = len(asm.ensamblar(0, 0).palabras_codigo)
        esperado, _ = asm.generar_objeto(p, desplazamiento_datos=n_codigo)
        with open(os.path.join(SALIDAS, f'{p}.obj'), encoding='utf-8') as f:
            obtenido = f.read()
        iguales = all(registros(esperado, t) == registros(obtenido, t) for t in 'TM')
        n_t, n_m = len(registros(obtenido, 'T')), len(registros(obtenido, 'M'))
        print(f"  {p:12s} {n_t:4d} palabras, {n_m:3d} registros M: "
              f"{'IGUAL al ensamblador de la Tarea 10' if iguales else 'DIFERENTE'}")
        fallos += not iguales
    return fallos


def verificar_cargador(enlazado, imagen, lad):
    memoria = Memoria()
    with open(enlazado, encoding='utf-8') as f:
        info = Cargador(memoria).cargar_objeto_texto(f.read(), lad)
    diferentes = 0
    with open(imagen, encoding='utf-8') as f:
        for linea in f:
            linea = linea.split(';')[0].split()
            if linea:
                d, w = int(linea[0], 16), int(linea[1], 16)
                diferentes += memoria.leer_ram(d) != w
    print(f"  Cargador de Python con LAD = {lad:08X}: {info['palabras']} palabras, CP = {info['PC']:08X}; "
          f"{'la memoria es IGUAL a la imagen de Flex' if diferentes == 0 else f'{diferentes} palabras DIFERENTES'}")
    return int(diferentes != 0)


if __name__ == '__main__':
    if len(sys.argv) > 2 and sys.argv[1] == 'ensamblador':
        sys.exit(verificar_ensamblador(sys.argv[2:]))
    if len(sys.argv) == 5 and sys.argv[1] == 'cargador':
        sys.exit(verificar_cargador(sys.argv[2], sys.argv[3], int(sys.argv[4], 16)))
    sys.exit(__doc__)
