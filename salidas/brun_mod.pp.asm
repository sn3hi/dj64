; =====================================================================
;  brun.asm - Estimacion de la constante de Brun con el emulador de la FPU
;
;  B = (1/3 + 1/5) + (1/5 + 1/7) + (1/11 + 1/13) + ...  (primos gemelos)
;
;  1. Criba de Eratostenes hasta N (aritmetica entera, en la tabla CRIBA).
;  2. Para cada par de gemelos (p, p+2) con p+2 <= N se suma, en doble
;     precision con la FPU, 1/p + 1/(p+2) = (2p + 2) / (p (p + 2)):
;     una sola division por par, con numerador y denominador exactos.
;  3. La suma converge muy despacio, asi que tambien se da la estimacion
;     corregida de Hardy-Littlewood:  B ~ B(N) + 4 C2 / ln(N),
;     con C2 = 0.6601618158... (constante de los primos gemelos).
;     ln(N) se calcula con la FPU (rutina 'ln', al final).
;  Resultados en 'pares', 'suma' y 'estimacion'.
; =====================================================================

; Taller 01: limite de la criba, como macro del preprocesador


; Taller 01: la FPU se ensambla aparte (fpu.obj) y la une el enlazador
.externo fpu_comparar, fpu_desde_entero, fpu_div, fpu_imprimir, fpu_mult, fpu_restar, fpu_sumar, imprimir_entero, imprimir_texto, nueva_linea

.equ CRIBA, 0x100000            ; tabla de la criba: CRIBA + i, para i = 0..N

inicio:     Lea     R0, txt_titulo
            Llamar  imprimir_texto
            Cargar  R6, N                   ; R6 = N
            CargarValor R5, CRIBA           ; R5 = base de la tabla
            ; ---- 1. criba: 0 = primo, 1 = compuesto ----
            CargarValor R1, 0
            CargarValor R2, 0
ini_tabla:  Copiar  R3, R5
            Sumar   R3, R1
            AlmacenarIndR R2, R3
            SumarInm R1, 1
            Comparar R1, R6
            SaltarSiMenorIgual ini_tabla
            CargarValor R1, 2               ; i
            CargarValor R4, 1               ; marca de compuesto
criba_i:    Copiar  R2, R1
            Mult    R2, R1                  ; j = i * i
            Comparar R2, R6
            SaltarSiMayor criba_fin
            Copiar  R3, R5
            Sumar   R3, R1
            CargarIndR R3, R3
            CmpInm  R3, 0
            SaltarSiNoCero criba_sig        ; i ya estaba tachado
criba_j:    Copiar  R3, R5
            Sumar   R3, R2
            AlmacenarIndR R4, R3            ; tacha j
            Sumar   R2, R1
            Comparar R2, R6
            SaltarSiMenorIgual criba_j
criba_sig:  SumarInm R1, 1
            Saltar  criba_i
criba_fin:
            ; ---- 2. suma de 1/p + 1/(p+2) sobre los primos gemelos ----
            Cargar  R0, cero
            Almacenar R0, suma
            CargarValor R1, 3               ; p (impar)
par_sig:    Copiar  R2, R1
            SumarInm R2, 2                  ; p + 2
            Comparar R2, R6
            SaltarSiMayor suma_fin
            Copiar  R3, R5
            Sumar   R3, R1
            CargarIndR R3, R3
            CmpInm  R3, 0
            SaltarSiNoCero no_gemelos       ; p no es primo
            Copiar  R3, R5
            Sumar   R3, R2
            CargarIndR R3, R3
            CmpInm  R3, 0
            SaltarSiNoCero no_gemelos       ; p + 2 no es primo
            Cargar  R3, pares
            SumarInm R3, 1
            Almacenar R3, pares
            Push    R1
            Copiar  R0, R1
            Mult    R0, R2                  ; p (p + 2), entero exacto
            Llamar  fpu_desde_entero
            Copiar  R4, R0
            Copiar  R0, R1
            Sumar   R0, R2                  ; 2p + 2
            Llamar  fpu_desde_entero
            Copiar  R1, R4
            Llamar  fpu_div                 ; 1/p + 1/(p+2)
            Cargar  R1, suma
            Llamar  fpu_sumar
            Almacenar R0, suma
            Pop     R1
no_gemelos: SumarInm R1, 2
            Saltar  par_sig
suma_fin:
            ; ---- 3. correccion: B ~ B(N) + 4 C2 / ln(N) ----
            Copiar  R0, R6
            Llamar  fpu_desde_entero
            Llamar  ln
            Copiar  R2, R0                  ; ln(N)
            Cargar  R0, c2
            Cargar  R1, cuatro
            Llamar  fpu_mult                ; 4 C2
            Copiar  R1, R2
            Llamar  fpu_div                 ; 4 C2 / ln(N)
            Cargar  R1, suma
            Llamar  fpu_sumar
            Almacenar R0, estimacion
            ; ---- resultados en pantalla ----
            Lea     R0, txt_n
            Llamar  imprimir_texto
            Copiar  R0, R6
            Llamar  imprimir_entero
            Llamar  nueva_linea
            Lea     R0, txt_pares
            Llamar  imprimir_texto
            Cargar  R0, pares
            Llamar  imprimir_entero
            Llamar  nueva_linea
            Lea     R0, txt_suma
            Llamar  imprimir_texto
            Cargar  R0, suma
            CargarValor R1, 12
            Llamar  fpu_imprimir
            Llamar  nueva_linea
            Lea     R0, txt_ln
            Llamar  imprimir_texto
            Copiar  R0, R2
            CargarValor R1, 12
            Llamar  fpu_imprimir
            Llamar  nueva_linea
            Lea     R0, txt_estimacion
            Llamar  imprimir_texto
            Cargar  R0, estimacion
            CargarValor R1, 12
            Llamar  fpu_imprimir
            Llamar  nueva_linea
            Parar

; ---------------------------------------------------------------------
; ln: R0 = ln(R0), para R0 > 0 y normal. Conserva R1-R6.
; x = m * 2^e con m en [raiz(2)/2, raiz(2)]; ln(x) = e ln 2 + ln m, y
; ln m = 2 (t + t^3/3 + t^5/5 + ...) con t = (m - 1) / (m + 1), |t| < 0.18.
; La serie se suma hasta que un termino ya no cambia el resultado.
; ---------------------------------------------------------------------
ln:         Push    R1
            Push    R2
            Push    R3
            Push    R4
            Push    R5
            Push    R6
            Copiar  R2, R0
            DespInm R2, 52
            RestarInm R2, 1023              ; e
            Cargar  R3, k_fraccion
            And     R0, R3
            Cargar  R3, k_exp_uno
            Or      R0, R3                  ; m en [1, 2)
            Copiar  R4, R0
            Cargar  R1, raiz2
            Llamar  fpu_comparar
            Copiar  R0, R4
            SaltarSiMenorIgual ln_reducido
            Cargar  R1, medio               ; m > raiz(2): m = m / 2, e = e + 1
            Llamar  fpu_mult
            SumarInm R2, 1
ln_reducido:
            Copiar  R4, R0
            Cargar  R1, uno
            Llamar  fpu_restar              ; m - 1
            Copiar  R5, R0
            Copiar  R0, R4
            Llamar  fpu_sumar               ; m + 1
            Copiar  R1, R0
            Copiar  R0, R5
            Llamar  fpu_div                 ; t
            Copiar  R3, R0
            Copiar  R1, R0
            Llamar  fpu_mult
            Almacenar R0, ln_t2             ; t^2
            Copiar  R4, R3                  ; suma = t
            Copiar  R5, R3                  ; potencia = t
            CargarValor R6, 1               ; k
ln_serie:   Copiar  R0, R5
            Cargar  R1, ln_t2
            Llamar  fpu_mult
            Copiar  R5, R0                  ; potencia = t^k
            SumarInm R6, 2
            Copiar  R0, R6
            Llamar  fpu_desde_entero
            Copiar  R1, R0
            Copiar  R0, R5
            Llamar  fpu_div                 ; t^k / k
            Copiar  R1, R4
            Llamar  fpu_sumar
            Copiar  R1, R4
            Copiar  R4, R0
            Llamar  fpu_comparar            ; cambio la suma?
            SaltarSiNoCero ln_serie
            Copiar  R0, R4
            Copiar  R1, R4
            Llamar  fpu_sumar               ; ln m = 2 * suma
            Copiar  R4, R0
            Copiar  R0, R2
            Llamar  fpu_desde_entero
            Cargar  R1, ln2
            Llamar  fpu_mult                ; e ln 2
            Copiar  R1, R4
            Llamar  fpu_sumar
            Pop     R6
            Pop     R5
            Pop     R4
            Pop     R3
            Pop     R2
            Pop     R1
            Ret

.datos
N:              10000          ; macro del preprocesador
pares:          0
suma:           0
estimacion:     0
ln_t2:          0
cero:           0.0
uno:            1.0
medio:          0.5
cuatro:         4.0
c2:             0.6601618158468696
ln2:            0.6931471805599453
raiz2:          1.4142135623730951
k_fraccion:     0x000FFFFFFFFFFFFF
k_exp_uno:      0x3FF0000000000000
txt_titulo:     "Constante de Brun (suma de inversos de primos gemelos)\n"
txt_n:          "N                       = "
txt_pares:      "pares de gemelos <= N   = "
txt_suma:       "suma parcial B(N)       = "
txt_ln:         "ln(N)                   = "
txt_estimacion: "B(N) + 4 C2 / ln(N)     = "

