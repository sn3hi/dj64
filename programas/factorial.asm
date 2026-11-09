; Factorial recursivo - usa Llamar, Ret, Push y Pop (pila en R7)
inicio:     Cargar      R0, n
            Llamar      factorial
            Almacenar   R0, resultado
            Parar

factorial:  CargarValor R1, 1
            Comparar    R0, R1
            SaltarSiMenorIgual base
            Push        R0
            RestarInm   R0, 1
            Llamar      factorial
            Pop         R1
            Mult        R0, R1
            Ret
base:       CargarValor R0, 1
            Ret

.datos
n:          5
resultado:  0
