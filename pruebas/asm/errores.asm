; errores.asm - errores que detecta el ensamblador (uno por linea)
.equ PANTALLA, 0xFFFF0011
.externo fpu_sumar
inicio:     Cargar      R8, n            ; no hay registro R8
            Sumar       R1               ; Sumar espera 2 operandos
            Multiplicar R1, R2           ; instruccion desconocida
            Saltar      fin_no_existe    ; simbolo no definido
            CargarValor R0, n            ; un inmediato no puede ser una etiqueta
            Cargar      R0, R1           ; se esperaba una direccion
inicio:     Parar                        ; etiqueta repetida
fpu_sumar:  Parar                        ; definida y declarada .externo
            Almacenar   R0, PANTALLA $   ; caracter no valido
.global     no_definido
.incluir "fpu.asm"
.datos
n:          10, 0.5, "ok"
