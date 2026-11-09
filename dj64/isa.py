"""
isa.py - Repertorio de instrucciones del DJ-64 (Hunza DJ Systems).

Palabra de 64 bits, 8 registros (R0-R7, campo de 3 bits), 5 formatos y 41
instrucciones. Los campos de cada formato suman exactamente 64 bits, por lo
que el campo de codigo tiene longitud distinta segun el formato:

    F1  codigo(64)                        sin operandos
    F2  codigo(29) R(3) direccion(32)     registro + memoria
    F3  codigo(29) R(3) valor(32)         registro + inmediato
    F4  codigo(32) direccion(32)          saltos y llamadas
    F5  codigo(58) R(3) R'(3)             uno o dos registros

Dentro de cada formato el codigo empieza siempre en los bits mas altos de la
palabra: los 3 primeros bits son el selector de formato y los siguientes son
el indice de la instruccion dentro de ese formato. El resto del campo de
codigo queda en cero (reservado).
"""

import math

WORD_BITS = 64
NUM_REGISTROS = 8
MASCARA_PALABRA = (1 << WORD_BITS) - 1
MASCARA_DIR = 0xFFFFFFFF          # bus de direcciones de 32 bits

# formato: (selector, longitud del campo de codigo, campos de operando)
# el orden de los campos es el orden en que se escriben en ensamblador y en
# que aparecen en la palabra (de mas a menos significativo).
FORMATOS = {
    'F1': (0, 64, []),
    'F2': (1, 29, [('R', 3), ('M', 32)]),
    'F3': (2, 29, [('R', 3), ('V', 32)]),
    'F4': (3, 32, [('M', 32)]),
    'F5': (4, 58, [('R', 3), ('R2', 3)]),
}

# mnemonico -> (formato, indice dentro del formato)
INSTRUCCIONES = {
    # F1 - sin operandos (4)
    'Parar': ('F1', 0), 'Nop': ('F1', 1), 'Ret': ('F1', 2), 'IRet': ('F1', 3),
    # F2 - registro + memoria (3)
    'Cargar': ('F2', 0), 'Almacenar': ('F2', 1), 'Lea': ('F2', 2),
    # F3 - registro + inmediato (7)
    'CargarValor': ('F3', 0), 'SumarInm': ('F3', 1), 'RestarInm': ('F3', 2),
    'DespInm': ('F3', 3), 'AndInm': ('F3', 4), 'OrInm': ('F3', 5),
    'CmpInm': ('F3', 6),
    # F4 - saltos y llamadas (10)
    'Saltar': ('F4', 0), 'SaltarSiCero': ('F4', 1), 'SaltarSiNoCero': ('F4', 2),
    'SaltarSiNeg': ('F4', 3), 'SaltarSiPos': ('F4', 4),
    'SaltarSiMayor': ('F4', 5), 'SaltarSiMenor': ('F4', 6),
    'SaltarSiMayorIgual': ('F4', 7), 'SaltarSiMenorIgual': ('F4', 8),
    'Llamar': ('F4', 9),
    # F5 - uno o dos registros (17)
    'Copiar': ('F5', 0), 'Sumar': ('F5', 1), 'Restar': ('F5', 2),
    'Mult': ('F5', 3), 'Div': ('F5', 4), 'And': ('F5', 5), 'Or': ('F5', 6),
    'Xor': ('F5', 7), 'Comparar': ('F5', 8), 'DespIzq': ('F5', 9),
    'DespDer': ('F5', 10), 'CargarIndR': ('F5', 11), 'AlmacenarIndR': ('F5', 12),
    'Push': ('F5', 13), 'Pop': ('F5', 14), 'Neg': ('F5', 15), 'Not': ('F5', 16),
}

# instrucciones del formato F5 que solo usan un registro (R' queda en 0)
UN_REGISTRO = frozenset({'Push', 'Pop', 'Neg', 'Not'})


class InstruccionInvalida(ValueError):
    """La palabra leida no corresponde a ninguna instruccion del DJ-64."""


def _bits_de_indice(fmt):
    cuenta = sum(1 for f, _ in INSTRUCCIONES.values() if f == fmt)
    return max(math.ceil(math.log2(cuenta)), 1)


BITS_INDICE = {f: _bits_de_indice(f) for f in FORMATOS}
_SELECTOR_A_FORMATO = {sel: f for f, (sel, _, _) in FORMATOS.items()}
_INDICE_INVERSO = {(f, i): mn for mn, (f, i) in INSTRUCCIONES.items()}


# ---------------- utilidades numericas ----------------
def a_signed64(v):
    v &= MASCARA_PALABRA
    return v - (1 << 64) if v & (1 << 63) else v


def a_signed32(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


# ---------------- codificacion / decodificacion ----------------
def codificar(mnemonico, **operandos):
    """Devuelve la palabra de 64 bits de `mnemonico` con los operandos dados
    (por nombre de campo: R, R2, M o V segun el formato)."""
    if mnemonico not in INSTRUCCIONES:
        raise ValueError(f"Instruccion desconocida: {mnemonico}")
    fmt, idx = INSTRUCCIONES[mnemonico]
    selector, _, campos = FORMATOS[fmt]
    bits_idx = BITS_INDICE[fmt]
    palabra = ((selector << bits_idx) | idx) << (WORD_BITS - (3 + bits_idx))
    despl = sum(b for _, b in campos)
    for nombre, bits in campos:
        despl -= bits
        v = operandos[nombre]
        if nombre in ('R', 'R2') and not (0 <= v < NUM_REGISTROS):
            raise ValueError(f"Registro fuera de rango (R0-R7): {v}")
        palabra |= (v & ((1 << bits) - 1)) << despl
    return palabra & MASCARA_PALABRA


def decodificar(palabra):
    """A partir de una palabra de 64 bits devuelve (mnemonico, operandos)."""
    palabra &= MASCARA_PALABRA
    selector = palabra >> (WORD_BITS - 3)
    if selector not in _SELECTOR_A_FORMATO:
        raise InstruccionInvalida(
            f"palabra {palabra:016X}: el selector de formato {selector:03b} no existe")
    fmt = _SELECTOR_A_FORMATO[selector]
    _, _, campos = FORMATOS[fmt]
    bits_idx = BITS_INDICE[fmt]
    idx = (palabra >> (WORD_BITS - (3 + bits_idx))) & ((1 << bits_idx) - 1)
    if (fmt, idx) not in _INDICE_INVERSO:
        raise InstruccionInvalida(
            f"palabra {palabra:016X}: no hay instruccion {idx} en el formato {fmt}")
    bits_operandos = sum(b for _, b in campos)
    zona_reservada = ((1 << (WORD_BITS - (3 + bits_idx))) - 1) & ~((1 << bits_operandos) - 1)
    if palabra & zona_reservada:
        raise InstruccionInvalida(
            f"palabra {palabra:016X}: los bits reservados del codigo del formato {fmt} deben ser cero")
    operandos = {}
    despl = bits_operandos
    for nombre, bits in campos:
        despl -= bits
        operandos[nombre] = (palabra >> despl) & ((1 << bits) - 1)
    return _INDICE_INVERSO[(fmt, idx)], operandos


def hexpalabra(palabra):
    return f"{palabra & MASCARA_PALABRA:016X}"


def formato_de(mnemonico):
    return INSTRUCCIONES[mnemonico][0]
