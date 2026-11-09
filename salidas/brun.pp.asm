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
N:              100000
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

; Taller 01: la FPU se inserta aqui con el preprocesador
; =====================================================================
;  fpu.asm - Emulador de la FPU del DJ-64 (Hunza DJ Systems)
;  Aritmetica de punto flotante IEEE 754 de doble precision (64 bits),
;  escrita en el lenguaje ensamblador del DJ-64.
;
;  Formato de un doble:  signo (1 bit) | exponente (11 bits, sesgo 1023)
;                        | fraccion (52 bits, con un 1 implicito)
;
;  Convencion de llamado (Llamar <rutina>):
;     entrada: R0 = a, R1 = b      salida: R0 = resultado
;     R1 a R6 se conservan; R7 es la pila.
;
;  Rutinas publicas:
;     fpu_sumar        R0 = a + b
;     fpu_restar       R0 = a - b
;     fpu_mult         R0 = a * b
;     fpu_div          R0 = a / b
;     fpu_desde_entero R0 = (doble) R0          (entero con signo -> doble)
;     fpu_a_entero     R0 = (entero) R0         (trunca hacia cero)
;     fpu_comparar     R0 = -1 si a<b, 0 si a=b, 1 si a>b, 2 si hay NaN
;                      (deja las banderas como CmpInm R0, 0)
;     fpu_neg, fpu_abs R0 = -a, |a|
;     fpu_imprimir     muestra R0 en pantalla con R1 decimales
;     imprimir_entero  muestra el entero R0 en pantalla
;     imprimir_texto   muestra el texto (terminado en 0) que empieza en R0
;     nueva_linea      salto de linea
;
;  Redondeo al par mas cercano (el de IEEE 754 por omision). Los numeros
;  subnormales se tratan como cero (modo "flush to zero").
; =====================================================================

; ---------------------------------------------------------------------
; Taller 01: para usar la FPU como modulo aparte (enlazador) se exportan
; sus rutinas publicas. '.codigo' asegura que, si se incluye con
; #include despues de una seccion .datos, el codigo vuelva a ser codigo.
; ---------------------------------------------------------------------
.codigo
.global fpu_sumar, fpu_restar, fpu_mult, fpu_div
.global fpu_desde_entero, fpu_a_entero, fpu_comparar, fpu_neg, fpu_abs
.global fpu_imprimir, imprimir_entero, imprimir_texto, nueva_linea

.equ PANTALLA_CARACTER, 0xFFFF0010

; ---------------------------------------------------------------------
; fpu_sumar: R0 = R0 + R1
; ---------------------------------------------------------------------
fpu_sumar:      Push    R1
                Push    R2
                Push    R3
                Push    R4
                Push    R5
                Push    R6
                Almacenar R0, fpu_a
                Almacenar R1, fpu_b
                Llamar  fpu_desempacar_ab
                ; --- infinitos y NaN ---
                Cargar  R3, fpu_ea
                CmpInm  R3, 2047
                SaltarSiCero fpu_su_a_especial
                Cargar  R3, fpu_eb
                CmpInm  R3, 2047
                SaltarSiCero fpu_su_b_especial
                ; --- ceros ---
                Cargar  R3, fpu_ea
                CmpInm  R3, 0
                SaltarSiCero fpu_su_a_cero
                Cargar  R3, fpu_eb
                CmpInm  R3, 0
                SaltarSiCero fpu_dev_a              ; a + 0 = a
                Saltar  fpu_su_normal
fpu_su_a_especial:                                  ; a es infinito o NaN
                Cargar  R4, fpu_ma
                CmpInm  R4, 0
                SaltarSiNoCero fpu_ret_nan          ; NaN + b
                Cargar  R3, fpu_eb
                CmpInm  R3, 2047
                SaltarSiNoCero fpu_dev_a            ; inf + finito = inf
                Cargar  R4, fpu_mb
                CmpInm  R4, 0
                SaltarSiNoCero fpu_ret_nan          ; inf + NaN
                Cargar  R2, fpu_sa
                Cargar  R3, fpu_sb
                Comparar R2, R3
                SaltarSiCero fpu_dev_a              ; inf + inf (mismo signo)
                Saltar  fpu_ret_nan                 ; inf - inf
fpu_su_b_especial:                                  ; a finito, b infinito o NaN
                Cargar  R4, fpu_mb
                CmpInm  R4, 0
                SaltarSiNoCero fpu_ret_nan
                Saltar  fpu_dev_b
fpu_su_a_cero:
                Cargar  R3, fpu_eb
                CmpInm  R3, 0
                SaltarSiNoCero fpu_dev_b            ; 0 + b = b
                Cargar  R2, fpu_sa                  ; 0 + 0: negativo solo si ambos lo son
                Cargar  R3, fpu_sb
                And     R2, R3
                Saltar  fpu_ret_cero
fpu_su_normal:
                ; que a sea el de mayor exponente (si no, se intercambian)
                Cargar  R3, fpu_ea
                Cargar  R4, fpu_eb
                Comparar R3, R4
                SaltarSiMayorIgual fpu_su_alinear
                Almacenar R4, fpu_ea
                Almacenar R3, fpu_eb
                Cargar  R3, fpu_ma
                Cargar  R4, fpu_mb
                Almacenar R4, fpu_ma
                Almacenar R3, fpu_mb
                Cargar  R3, fpu_sa
                Cargar  R4, fpu_sb
                Almacenar R4, fpu_sa
                Almacenar R3, fpu_sb
fpu_su_alinear:
                CargarValor R6, 3
                Cargar  R4, fpu_ma
                DespIzq R4, R6                      ; 3 bits de guarda para redondear
                Cargar  R5, fpu_mb
                DespIzq R5, R6
                Cargar  R3, fpu_ea
                Cargar  R6, fpu_eb
                Copiar  R1, R3
                Restar  R1, R6                      ; d = ea - eb
                CmpInm  R1, 58
                SaltarSiMenor fpu_su_desplazar
                CargarValor R5, 1                   ; b es tan pequeño que solo cuenta como "bit pegajoso"
                Saltar  fpu_su_operar
fpu_su_desplazar:
                CmpInm  R1, 0
                SaltarSiCero fpu_su_operar
                CargarValor R6, 1
                DespIzq R6, R1
                RestarInm R6, 1                     ; mascara de los d bits que se pierden
                And     R6, R5
                DespDer R5, R1                      ; mb >> d
                CmpInm  R6, 0
                SaltarSiCero fpu_su_operar
                OrInm   R5, 1                       ; si se perdio algo, queda el bit pegajoso
fpu_su_operar:
                Cargar  R2, fpu_sa
                Cargar  R6, fpu_sb
                Comparar R2, R6
                SaltarSiNoCero fpu_su_resta
                Sumar   R4, R5                      ; signos iguales: se suman magnitudes
                Saltar  fpu_redondear
fpu_su_resta:
                Restar  R4, R5                      ; signos distintos: se restan magnitudes
                SaltarSiCero fpu_su_cero_exacto
                SaltarSiMayor fpu_redondear
                Neg     R4
                Copiar  R2, R6                      ; el resultado lleva el signo de b
                Saltar  fpu_redondear
fpu_su_cero_exacto:
                CargarValor R2, 0                   ; x - x = +0
                Saltar  fpu_ret_cero

; ---------------------------------------------------------------------
; fpu_restar: R0 = R0 - R1   (a + (-b))
; ---------------------------------------------------------------------
fpu_restar:     Push    R1
                Push    R2
                Cargar  R2, fpu_k_signo
                Xor     R1, R2
                Pop     R2
                Llamar  fpu_sumar
                Pop     R1
                Ret

; ---------------------------------------------------------------------
; fpu_mult: R0 = R0 * R1
; El producto de dos mantisas de 53 bits tiene 106 bits y Mult solo da
; 64, asi que cada mantisa se parte en 27 + 26 bits y se suman los
; productos parciales (multiplicacion "de escuela" en base 2^26).
; ---------------------------------------------------------------------
fpu_mult:       Push    R1
                Push    R2
                Push    R3
                Push    R4
                Push    R5
                Push    R6
                Almacenar R0, fpu_a
                Almacenar R1, fpu_b
                Llamar  fpu_desempacar_ab
                Cargar  R2, fpu_sa
                Cargar  R3, fpu_sb
                Xor     R2, R3                      ; signo del resultado
                Cargar  R3, fpu_ea
                Cargar  R4, fpu_eb
                CmpInm  R3, 2047
                SaltarSiCero fpu_mu_a_especial
                CmpInm  R4, 2047
                SaltarSiCero fpu_mu_b_especial
                CmpInm  R3, 0
                SaltarSiCero fpu_ret_cero           ; 0 * b
                CmpInm  R4, 0
                SaltarSiCero fpu_ret_cero           ; a * 0
                Saltar  fpu_mu_normal
fpu_mu_a_especial:                                  ; a infinito o NaN
                Cargar  R5, fpu_ma
                CmpInm  R5, 0
                SaltarSiNoCero fpu_ret_nan
                CmpInm  R4, 0
                SaltarSiCero fpu_ret_nan            ; inf * 0
                CmpInm  R4, 2047
                SaltarSiNoCero fpu_ret_inf          ; inf * finito
                Cargar  R5, fpu_mb
                CmpInm  R5, 0
                SaltarSiNoCero fpu_ret_nan          ; inf * NaN
                Saltar  fpu_ret_inf                 ; inf * inf
fpu_mu_b_especial:                                  ; a finito, b infinito o NaN
                Cargar  R5, fpu_mb
                CmpInm  R5, 0
                SaltarSiNoCero fpu_ret_nan
                CmpInm  R3, 0
                SaltarSiCero fpu_ret_nan            ; 0 * inf
                Saltar  fpu_ret_inf
fpu_mu_normal:
                Cargar  R1, fpu_ma
                Copiar  R3, R1
                AndInm  R3, 0x3FFFFFF               ; al (26 bits bajos de a)
                DespInm R1, 26                      ; ah
                Cargar  R4, fpu_mb
                Copiar  R5, R4
                AndInm  R5, 0x3FFFFFF               ; bl
                DespInm R4, 26                      ; bh
                Copiar  R6, R1
                Mult    R6, R4
                Almacenar R6, fpu_t                 ; alto = ah * bh
                Copiar  R6, R1
                Mult    R6, R5                      ; ah * bl
                Mult    R4, R3                      ; bh * al
                Sumar   R6, R4                      ; medio = ah*bl + al*bh
                Mult    R3, R5                      ; bajo = al * bl
                Copiar  R4, R6
                AndInm  R4, 0x3FFFFFF
                CargarValor R5, 26
                DespIzq R4, R5
                Sumar   R3, R4                      ; bajo + (medio mod 2^26) * 2^26
                DespInm R6, 26
                Cargar  R4, fpu_t
                Sumar   R4, R6
                Copiar  R6, R3
                DespInm R6, 52
                Sumar   R4, R6                      ; Q = producto >> 52
                Cargar  R6, fpu_k_fraccion
                And     R3, R6                      ; los 52 bits bajos del producto
                CargarValor R6, 3
                DespIzq R4, R6
                Copiar  R6, R3
                DespInm R6, 49
                Or      R4, R6                      ; Q con 3 bits de guarda
                Cargar  R6, fpu_k_masc49
                And     R3, R6
                SaltarSiCero fpu_mu_exponente
                OrInm   R4, 1                       ; bit pegajoso
fpu_mu_exponente:
                Cargar  R3, fpu_ea
                Cargar  R6, fpu_eb
                Sumar   R3, R6
                RestarInm R3, 1023                  ; los exponentes se suman y se quita un sesgo
                Saltar  fpu_redondear

; ---------------------------------------------------------------------
; fpu_div: R0 = R0 / R1
; Division larga de las mantisas: 57 bits de cociente + bit pegajoso.
; ---------------------------------------------------------------------
fpu_div:        Push    R1
                Push    R2
                Push    R3
                Push    R4
                Push    R5
                Push    R6
                Almacenar R0, fpu_a
                Almacenar R1, fpu_b
                Llamar  fpu_desempacar_ab
                Cargar  R2, fpu_sa
                Cargar  R3, fpu_sb
                Xor     R2, R3
                Cargar  R3, fpu_ea
                Cargar  R4, fpu_eb
                CmpInm  R3, 2047
                SaltarSiCero fpu_dv_a_especial
                CmpInm  R4, 2047
                SaltarSiCero fpu_dv_b_especial
                CmpInm  R4, 0
                SaltarSiCero fpu_dv_b_cero
                CmpInm  R3, 0
                SaltarSiCero fpu_ret_cero           ; 0 / b = 0
                Saltar  fpu_dv_normal
fpu_dv_a_especial:
                Cargar  R5, fpu_ma
                CmpInm  R5, 0
                SaltarSiNoCero fpu_ret_nan          ; NaN / b
                CmpInm  R4, 2047
                SaltarSiCero fpu_ret_nan            ; inf / inf, inf / NaN
                Saltar  fpu_ret_inf                 ; inf / finito
fpu_dv_b_especial:                                  ; a finito
                Cargar  R5, fpu_mb
                CmpInm  R5, 0
                SaltarSiNoCero fpu_ret_nan          ; a / NaN
                Saltar  fpu_ret_cero                ; a / inf = 0
fpu_dv_b_cero:
                CmpInm  R3, 0
                SaltarSiCero fpu_ret_nan            ; 0 / 0
                Saltar  fpu_ret_inf                 ; a / 0 = inf
fpu_dv_normal:
                Cargar  R4, fpu_ma                  ; resto
                Cargar  R5, fpu_mb                  ; divisor
                CargarValor R6, 0                   ; cociente
                CargarValor R1, 57                  ; bits a calcular
                CargarValor R3, 1
fpu_dv_bucle:
                DespIzq R6, R3
                Comparar R4, R5
                SaltarSiMenor fpu_dv_sigue
                Restar  R4, R5
                OrInm   R6, 1
fpu_dv_sigue:
                DespIzq R4, R3
                RestarInm R1, 1
                SaltarSiNoCero fpu_dv_bucle
                CmpInm  R4, 0
                SaltarSiCero fpu_dv_exponente
                OrInm   R6, 1                       ; resto distinto de cero: bit pegajoso
fpu_dv_exponente:
                Copiar  R4, R6
                Cargar  R3, fpu_ea
                Cargar  R6, fpu_eb
                Restar  R3, R6
                SumarInm R3, 1022                   ; los exponentes se restan
                Saltar  fpu_redondear

; ---------------------------------------------------------------------
; fpu_desde_entero: R0 (entero con signo) -> R0 (doble)
; ---------------------------------------------------------------------
fpu_desde_entero:
                Push    R1
                Push    R2
                Push    R3
                Push    R4
                Push    R5
                Push    R6
                CargarValor R2, 0
                Copiar  R4, R0
                CmpInm  R4, 0
                SaltarSiCero fpu_ret_cero
                SaltarSiMayor fpu_de_positivo
                CargarValor R2, 1
                Neg     R4
                SaltarSiMayor fpu_de_positivo
                Cargar  R0, fpu_k_menos2a63         ; -2^63 no tiene opuesto en 64 bits
                Saltar  fpu_salir
fpu_de_positivo:
                CargarValor R3, 1078                ; valor = M * 2^(1078 - 1078)
                Saltar  fpu_redondear

; ---------------------------------------------------------------------
; fpu_a_entero: R0 (doble) -> R0 (entero), truncando hacia cero.
; Si no cabe en 64 bits (o es NaN/inf) devuelve 0x8000000000000000.
; ---------------------------------------------------------------------
fpu_a_entero:   Push    R1
                Push    R2
                Push    R3
                Push    R4
                Push    R5
                Push    R6
                Llamar  fpu_desempacar
                CmpInm  R3, 0
                SaltarSiCero fpu_ae_cero
                CmpInm  R3, 2047
                SaltarSiCero fpu_ae_invalido
                RestarInm R3, 1075                  ; valor = mantisa * 2^(e - 1075)
                CmpInm  R3, 0
                SaltarSiMayorIgual fpu_ae_izquierda
                Neg     R3
                CmpInm  R3, 53
                SaltarSiMayorIgual fpu_ae_cero      ; |x| < 1
                DespDer R4, R3
                Saltar  fpu_ae_signo
fpu_ae_izquierda:
                CmpInm  R3, 11
                SaltarSiMayorIgual fpu_ae_invalido  ; |x| >= 2^63
                DespIzq R4, R3
fpu_ae_signo:
                CmpInm  R2, 0
                SaltarSiCero fpu_ae_fin
                Neg     R4
fpu_ae_fin:
                Copiar  R0, R4
                Saltar  fpu_salir
fpu_ae_cero:
                CargarValor R0, 0
                Saltar  fpu_salir
fpu_ae_invalido:
                Cargar  R0, fpu_k_signo
                Saltar  fpu_salir

; ---------------------------------------------------------------------
; fpu_comparar: R0 = -1, 0, 1 (a<b, a=b, a>b) o 2 si alguno es NaN
; ---------------------------------------------------------------------
fpu_comparar:   Push    R1
                Push    R2
                Push    R3
                Push    R4
                Push    R5
                Push    R6
                Cargar  R5, fpu_k_magnitud
                Cargar  R6, fpu_k_inf
                Copiar  R2, R0
                And     R2, R5                      ; |a| como entero
                Comparar R2, R6
                SaltarSiMayor fpu_cp_nan
                Copiar  R3, R1
                And     R3, R5                      ; |b| como entero
                Comparar R3, R6
                SaltarSiMayor fpu_cp_nan
                CmpInm  R0, 0
                SaltarSiMayorIgual fpu_cp_a
                Neg     R2                          ; negativo: se compara como -|a|
fpu_cp_a:       CmpInm  R1, 0
                SaltarSiMayorIgual fpu_cp_b
                Neg     R3
fpu_cp_b:       CargarValor R0, 0
                Comparar R2, R3
                SaltarSiCero fpu_cp_fin
                CargarValor R0, 1
                SaltarSiMayor fpu_cp_fin
                CargarValor R0, -1
                Saltar  fpu_cp_fin
fpu_cp_nan:     CargarValor R0, 2
fpu_cp_fin:     CmpInm  R0, 0
                Saltar  fpu_salir

; ---------------------------------------------------------------------
; fpu_neg y fpu_abs
; ---------------------------------------------------------------------
fpu_neg:        Push    R1
                Cargar  R1, fpu_k_signo
                Xor     R0, R1
                Pop     R1
                Ret
fpu_abs:        Push    R1
                Cargar  R1, fpu_k_magnitud
                And     R0, R1
                Pop     R1
                Ret

; ---------------------------------------------------------------------
; fpu_imprimir: muestra R0 en pantalla con R1 decimales (0 a 15).
; Calcula round(|x| * 10^R1) con la FPU y escribe sus digitos poniendo
; el punto decimal. Si |x| * 10^R1 pasa de 2^53 (donde los enteros dejan de
; ser exactos en doble precision), usa menos decimales.
; ---------------------------------------------------------------------
fpu_imprimir:   Push    R1
                Push    R2
                Push    R3
                Push    R4
                Push    R5
                Push    R6
                Almacenar R1, fpu_dec
                Cargar  R5, fpu_k_magnitud
                Copiar  R2, R0
                And     R2, R5
                Cargar  R5, fpu_k_inf
                Comparar R2, R5
                SaltarSiMenor fpu_im_finito
                SaltarSiCero fpu_im_infinito
                Lea     R0, fpu_txt_nan
                Llamar  imprimir_texto
                Saltar  fpu_salir
fpu_im_infinito:
                CmpInm  R0, 0
                SaltarSiMayorIgual fpu_im_inf_pos
                CargarValor R2, 45                  ; '-'
                Almacenar R2, PANTALLA_CARACTER
fpu_im_inf_pos: Lea     R0, fpu_txt_inf
                Llamar  imprimir_texto
                Saltar  fpu_salir
fpu_im_finito:
                CmpInm  R0, 0
                SaltarSiMayorIgual fpu_im_positivo
                CargarValor R2, 45                  ; '-'
                Almacenar R2, PANTALLA_CARACTER
fpu_im_positivo:
                Llamar  fpu_abs
                Copiar  R2, R0                      ; R2 = |x|
fpu_im_intento: Cargar  R0, fpu_k_uno               ; R0 = 10^decimales
                Cargar  R1, fpu_k_diez
                Cargar  R3, fpu_dec
fpu_im_potencia:
                CmpInm  R3, 0
                SaltarSiCero fpu_im_escalar
                Llamar  fpu_mult
                RestarInm R3, 1
                Saltar  fpu_im_potencia
fpu_im_escalar:
                Copiar  R1, R0
                Copiar  R0, R2
                Llamar  fpu_mult                    ; |x| * 10^decimales
                Cargar  R1, fpu_k_medio
                Llamar  fpu_sumar                   ; + 0.5 para redondear
                Llamar  fpu_a_entero
                CmpInm  R0, 0
                SaltarSiMenor fpu_im_reducir        ; ni siquiera cabe en 64 bits
                Cargar  R5, fpu_k_dos53
                Comparar R0, R5
                SaltarSiMenor fpu_im_cabe           ; < 2^53: todos sus digitos son exactos
fpu_im_reducir: Cargar  R3, fpu_dec                 ; si no, un decimal menos
                CmpInm  R3, 0
                SaltarSiCero fpu_im_grande
                RestarInm R3, 1
                Almacenar R3, fpu_dec
                Saltar  fpu_im_intento
fpu_im_grande:  Lea     R0, fpu_txt_grande
                Llamar  imprimir_texto
                Saltar  fpu_salir
fpu_im_cabe:    Copiar  R4, R0
                Llamar  fpu_imp_digitos
                Saltar  fpu_salir

; imprimir_entero: muestra el entero con signo R0
imprimir_entero:
                Push    R1
                Push    R2
                Push    R3
                Push    R4
                Push    R5
                Push    R6
                CargarValor R2, 0
                Almacenar R2, fpu_dec
                Copiar  R4, R0
                CmpInm  R4, 0
                SaltarSiMayorIgual fpu_ie_positivo
                CargarValor R2, 45                  ; '-'
                Almacenar R2, PANTALLA_CARACTER
                Neg     R4
fpu_ie_positivo:
                Llamar  fpu_imp_digitos
                Saltar  fpu_salir

; fpu_imp_digitos (interna): muestra R4 (>= 0) con fpu_dec decimales.
; Apila los digitos de derecha a izquierda y los saca en orden.
fpu_imp_digitos:
                CargarValor R3, 0                   ; digitos apilados
                CargarValor R5, 10
fpu_id_bucle:   Copiar  R6, R4
                Div     R6, R5                      ; n / 10
                Copiar  R1, R6
                Mult    R1, R5
                Copiar  R2, R4
                Restar  R2, R1                      ; digito = n - (n/10)*10
                Push    R2
                SumarInm R3, 1
                Copiar  R4, R6
                CmpInm  R4, 0
                SaltarSiNoCero fpu_id_bucle
                Cargar  R6, fpu_dec
                Comparar R3, R6
                SaltarSiMenorIgual fpu_id_bucle     ; al menos decimales + 1 digitos
fpu_id_salida:  Cargar  R6, fpu_dec
                Comparar R3, R6
                SaltarSiNoCero fpu_id_digito
                CmpInm  R6, 0
                SaltarSiCero fpu_id_digito
                CargarValor R2, 46                  ; '.'
                Almacenar R2, PANTALLA_CARACTER
fpu_id_digito:  Pop     R2
                SumarInm R2, 48                     ; '0' + digito
                Almacenar R2, PANTALLA_CARACTER
                RestarInm R3, 1
                SaltarSiNoCero fpu_id_salida
                Ret

; imprimir_texto: muestra el texto que empieza en la direccion R0
imprimir_texto: Push    R1
                Push    R2
                Copiar  R1, R0
fpu_it_bucle:   CargarIndR R2, R1
                CmpInm  R2, 0
                SaltarSiCero fpu_it_fin
                Almacenar R2, PANTALLA_CARACTER
                SumarInm R1, 1
                Saltar  fpu_it_bucle
fpu_it_fin:     Pop     R2
                Pop     R1
                Ret

nueva_linea:    Push    R1
                CargarValor R1, 10
                Almacenar R1, PANTALLA_CARACTER
                Pop     R1
                Ret

; =====================================================================
;  Rutinas internas
; =====================================================================

; fpu_desempacar: R0 (doble) -> R2 = signo (0/1), R3 = exponente (0..2047),
; R4 = mantisa con el 1 implicito (0 si es cero/subnormal; la fraccion
; cruda si es infinito o NaN). Usa R5.
fpu_desempacar: CargarValor R2, 0
                Copiar  R3, R0
                CmpInm  R3, 0
                SaltarSiMayorIgual fpu_dp_positivo
                CargarValor R2, 1
fpu_dp_positivo:
                Cargar  R5, fpu_k_magnitud
                And     R3, R5
                Copiar  R4, R3
                Cargar  R5, fpu_k_fraccion
                And     R4, R5
                DespInm R3, 52
                CmpInm  R3, 0
                SaltarSiCero fpu_dp_cero
                CmpInm  R3, 2047
                SaltarSiCero fpu_dp_fin
                Cargar  R5, fpu_k_implicito
                Or      R4, R5
                Ret
fpu_dp_cero:    CargarValor R4, 0
fpu_dp_fin:     Ret

; fpu_desempacar_ab: desempaca fpu_a y fpu_b en las variables sa, ea, ma, sb, eb, mb
fpu_desempacar_ab:
                Cargar  R0, fpu_a
                Llamar  fpu_desempacar
                Almacenar R2, fpu_sa
                Almacenar R3, fpu_ea
                Almacenar R4, fpu_ma
                Cargar  R0, fpu_b
                Llamar  fpu_desempacar
                Almacenar R2, fpu_sb
                Almacenar R3, fpu_eb
                Almacenar R4, fpu_mb
                Ret

; fpu_redondear: normaliza, redondea y empaqueta.
; Entrada: R2 = signo, R3 = exponente, R4 = M >= 0, con valor = M * 2^(R3 - 1078).
; Deja M en [2^55, 2^56): 53 bits de mantisa + 3 de guarda (guarda, redondeo
; y pegajoso), redondea al par mas cercano y arma el doble en R0.
fpu_redondear:  CmpInm  R4, 0
                SaltarSiCero fpu_ret_cero
                Cargar  R5, fpu_k_dos56
fpu_rd_derecha: Comparar R4, R5                     ; mientras M >= 2^56
                SaltarSiMenor fpu_rd_izq_inicio
                Copiar  R6, R4
                AndInm  R6, 1
                DespInm R4, 1
                Or      R4, R6                      ; el bit que sale se conserva como pegajoso
                SumarInm R3, 1
                Saltar  fpu_rd_derecha
fpu_rd_izq_inicio:
                Cargar  R5, fpu_k_dos55
                CargarValor R6, 1
fpu_rd_izquierda:
                Comparar R4, R5                     ; mientras M < 2^55
                SaltarSiMayorIgual fpu_rd_redondeo
                DespIzq R4, R6
                RestarInm R3, 1
                Saltar  fpu_rd_izquierda
fpu_rd_redondeo:
                Copiar  R6, R4
                AndInm  R6, 7                       ; bits de guarda
                DespInm R4, 3
                CmpInm  R6, 4
                SaltarSiMenor fpu_rd_listo          ; menos de la mitad: se trunca
                SaltarSiMayor fpu_rd_subir          ; mas de la mitad: se sube
                Copiar  R5, R4                      ; exactamente la mitad: al par
                AndInm  R5, 1
                SaltarSiCero fpu_rd_listo
fpu_rd_subir:   SumarInm R4, 1
                Cargar  R5, fpu_k_dos53
                Comparar R4, R5
                SaltarSiMenor fpu_rd_listo
                DespInm R4, 1                       ; 1.111..1 + 1 = 10.000..0
                SumarInm R3, 1
fpu_rd_listo:   CmpInm  R3, 2047
                SaltarSiMayorIgual fpu_ret_inf      ; desbordamiento
                CmpInm  R3, 0
                SaltarSiMenorIgual fpu_ret_cero     ; demasiado pequeño: cero
                Cargar  R5, fpu_k_fraccion
                And     R4, R5                      ; quita el 1 implicito
                CargarValor R5, 52
                DespIzq R3, R5
                Or      R4, R3
                CargarValor R5, 63
                DespIzq R2, R5
                Or      R4, R2
                Copiar  R0, R4
                Saltar  fpu_salir

; Salidas comunes (todas restauran R1-R6 y vuelven a quien llamo)
fpu_dev_a:      Cargar  R0, fpu_a
                Saltar  fpu_salir
fpu_dev_b:      Cargar  R0, fpu_b
                Saltar  fpu_salir
fpu_ret_nan:    Cargar  R0, fpu_k_nan
                Saltar  fpu_salir
fpu_ret_cero:   CargarValor R5, 63                  ; cero con el signo de R2
                Copiar  R0, R2
                DespIzq R0, R5
                Saltar  fpu_salir
fpu_ret_inf:    CargarValor R5, 63                  ; infinito con el signo de R2
                Copiar  R0, R2
                DespIzq R0, R5
                Cargar  R5, fpu_k_inf
                Or      R0, R5
fpu_salir:      Pop     R6
                Pop     R5
                Pop     R4
                Pop     R3
                Pop     R2
                Pop     R1
                Ret

.datos
; variables de trabajo
fpu_a:          0
fpu_b:          0
fpu_sa:         0
fpu_ea:         0
fpu_ma:         0
fpu_sb:         0
fpu_eb:         0
fpu_mb:         0
fpu_t:          0
fpu_dec:        0
; constantes
fpu_k_signo:      0x8000000000000000
fpu_k_magnitud:   0x7FFFFFFFFFFFFFFF
fpu_k_fraccion:   0x000FFFFFFFFFFFFF
fpu_k_implicito:  0x0010000000000000
fpu_k_dos53:      0x0020000000000000
fpu_k_dos55:      0x0080000000000000
fpu_k_dos56:      0x0100000000000000
fpu_k_masc49:     0x0001FFFFFFFFFFFF
fpu_k_inf:        0x7FF0000000000000
fpu_k_nan:        0x7FF8000000000000
fpu_k_menos2a63:  0xC3E0000000000000
fpu_k_uno:        1.0
fpu_k_diez:       10.0
fpu_k_medio:      0.5
fpu_txt_nan:      "NaN"
fpu_txt_inf:      "inf"
fpu_txt_grande:   "(muy grande para mostrarlo)"
