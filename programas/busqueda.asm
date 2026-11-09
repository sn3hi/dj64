; Busqueda binaria - busca 'clave' en un arreglo ordenado de n elementos.
; Retorna el indice de la posicion o -1 si no se encuentra.
busqueda: CargarValor R0, 0
          Cargar      R1, n
          RestarInm   R1, 1
          Cargar      R4, clave
          CargarValor R6, -1
          Lea         R5, arreglo
bucle:    Comparar    R0, R1
          SaltarSiMayor no_encontrado
          Copiar      R2, R0
          Sumar       R2, R1
          DespInm     R2, 1
          Copiar      R3, R5
          Sumar       R3, R2
          CargarIndR  R3, R3
          Comparar    R3, R4
          SaltarSiCero encontrado
          SaltarSiMenor mitad_derecha
          Copiar      R1, R2
          RestarInm   R1, 1
          Saltar      bucle
mitad_derecha: Copiar R0, R2
          SumarInm    R0, 1
          Saltar      bucle
encontrado: Copiar    R6, R2
no_encontrado: Almacenar R6, resultado
          Parar

.datos
n:          10
clave:      19
resultado:  0
arreglo:    2, 4, 7, 10, 15, 19, 23, 28, 33, 40
