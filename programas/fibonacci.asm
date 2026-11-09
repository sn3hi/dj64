; Fibonacci iterativo - Calcula el n-esimo termino de la serie de Fibonacci
fib:    Cargar      R0, n
        CargarValor R1, 0
        CargarValor R2, 1
        CargarValor R4, 0
bucle:  Comparar    R4, R0
        SaltarSiMayorIgual fin
        Copiar      R3, R1
        Sumar       R3, R2
        Copiar      R1, R2
        Copiar      R2, R3
        SumarInm    R4, 1
        Saltar      bucle
fin:    Almacenar   R1, resultado
        Parar

.datos
n:          10
resultado:  0
