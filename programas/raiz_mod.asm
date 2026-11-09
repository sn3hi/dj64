; =====================================================================
;  raiz.asm - Raiz cuadrada por el metodo de Heron de Alejandria,
;  con el emulador de la FPU.
;
;      y(i+1) = 1/2 * ( y(i) + x / y(i) ),   empezando con y0 tal que y0^2 < x
;
;  Datos: x (el numero), y0 (aproximacion inicial; si es 0 o negativa se
;  elige y0 = 2^k con k = floor(e/2) - 1, donde x = m * 2^e, que cumple
;  y0^2 < x) y la cantidad de decimales a mostrar.
;  Desde y1 la sucesion es decreciente (y(i) >= raiz de x), asi que se
;  detiene cuando una nueva aproximacion ya no es menor que la anterior:
;  en ese punto se alcanzo la precision de la doble precision.
;  Resultado en 'resultado' (doble) e 'iteraciones' (entero).
; =====================================================================

; Taller 01: la FPU se ensambla aparte (fpu.obj) y la une el enlazador
.externo fpu_comparar, fpu_div, fpu_imprimir, fpu_mult, fpu_sumar, imprimir_entero, imprimir_texto, nueva_linea

inicio:     Lea     R0, txt_titulo
            Llamar  imprimir_texto
            Cargar  R6, decimales
            Lea     R0, txt_x
            Llamar  imprimir_texto
            Cargar  R2, x                   ; R2 = x
            Copiar  R0, R2
            Copiar  R1, R6
            Llamar  fpu_imprimir
            Llamar  nueva_linea
            ; casos que no necesitan iterar
            Copiar  R0, R2
            Cargar  R1, cero
            Llamar  fpu_comparar
            SaltarSiMenor negativo          ; x < 0
            SaltarSiCero es_cero            ; x = 0
            CmpInm  R0, 2
            SaltarSiCero negativo           ; x es NaN
            ; aproximacion inicial: la de los datos si es positiva
            Cargar  R3, y0
            Copiar  R0, R3
            Cargar  R1, cero
            Llamar  fpu_comparar
            SaltarSiMayor tengo_y0
            ; si no, y0 = 2^k con k = floor(e/2) - 1, donde x = m * 2^e (1 <= m < 2):
            ; y0^2 <= 2^(e-2) < x, como pide el metodo, y y0 queda cerca de la raiz
            Copiar  R3, R2
            DespInm R3, 52                  ; exponente de x, con sesgo
            RestarInm R3, 1023              ; e
            DespInm R3, 1                   ; floor(e / 2)
            SumarInm R3, 1022               ; (k + 1023): exponente con sesgo de 2^k
            CargarValor R0, 52
            DespIzq R3, R0                  ; R3 = 2^k como doble
tengo_y0:   CargarValor R4, 0               ; R4 = i
            Llamar  mostrar_y
            ; ---- iteracion de Heron ----
bucle:      Copiar  R0, R2
            Copiar  R1, R3
            Llamar  fpu_div                 ; x / y
            Copiar  R1, R3
            Llamar  fpu_sumar               ; y + x / y
            Cargar  R1, medio
            Llamar  fpu_mult                ; y_nuevo = (y + x / y) / 2
            Copiar  R5, R0
            SumarInm R4, 1
            Push    R3
            Copiar  R3, R5
            Llamar  mostrar_y
            Pop     R3
            CmpInm  R4, 2
            SaltarSiMenor seguir            ; y1 puede ser mayor que y0
            Copiar  R0, R5
            Copiar  R1, R3
            Llamar  fpu_comparar
            SaltarSiMayorIgual convergio    ; y_nuevo >= y: ya no mejora
seguir:     Copiar  R3, R5
            CmpInm  R4, 200
            SaltarSiMenor bucle
convergio:  Almacenar R3, resultado
            Almacenar R4, iteraciones
            Lea     R0, txt_raiz
            Llamar  imprimir_texto
            Copiar  R0, R3
            Copiar  R1, R6
            Llamar  fpu_imprimir
            Lea     R0, txt_iter
            Llamar  imprimir_texto
            Copiar  R0, R4
            Llamar  imprimir_entero
            Lea     R0, txt_iter2
            Llamar  imprimir_texto
            Llamar  nueva_linea
            Parar
negativo:   Lea     R0, txt_negativo
            Llamar  imprimir_texto
            Cargar  R0, nan
            Almacenar R0, resultado
            Parar
es_cero:    Almacenar R2, resultado         ; raiz de 0 = 0
            Lea     R0, txt_raiz
            Llamar  imprimir_texto
            Copiar  R0, R2
            Copiar  R1, R6
            Llamar  fpu_imprimir
            Llamar  nueva_linea
            Parar

; mostrar_y: escribe "  y<R4> = <R3>"
mostrar_y:  Push    R0
            Push    R1
            Lea     R0, txt_y
            Llamar  imprimir_texto
            Copiar  R0, R4
            Llamar  imprimir_entero
            Lea     R0, txt_igual
            Llamar  imprimir_texto
            Copiar  R0, R3
            Copiar  R1, R6
            Llamar  fpu_imprimir
            Llamar  nueva_linea
            Pop     R1
            Pop     R0
            Ret

.datos
x:            125.0
y0:           10.0
decimales:    12
resultado:    0
iteraciones:  0
cero:         0.0
uno:          1.0
medio:        0.5
nan:          0x7FF8000000000000
txt_titulo:   "Raiz cuadrada por el metodo de Heron (De Euclides a Java, p. 26)\n"
txt_x:        "x  = "
txt_y:        "  y"
txt_igual:    " = "
txt_raiz:     "raiz(x) = "
txt_iter:     "   ("
txt_iter2:    " iteraciones)"
txt_negativo: "x es negativo: su raiz cuadrada no es un numero real\n"

