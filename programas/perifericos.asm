; Demostracion de E/S mapeada en memoria: teclado, pantalla, disco y red.
; Lee un numero del teclado, lo muestra, lo guarda (y su doble) en el disco,
; lo lee de vuelta, lo envia por la red y escribe "Hi" en pantalla.
.equ TECLADO_DATO,      0xFFFF0000
.equ PANTALLA_CARACTER, 0xFFFF0010
.equ PANTALLA_NUMERO,   0xFFFF0011
.equ DISCO_DIRECCION,   0xFFFF0020
.equ DISCO_DATO,        0xFFFF0021
.equ RED_ENVIAR,        0xFFFF0030
.equ RED_RECIBIR,       0xFFFF0031
.equ RED_ESTADO,        0xFFFF0032

inicio:     Cargar      R0, TECLADO_DATO      ; R0 = dato tecleado
            Almacenar   R0, PANTALLA_NUMERO   ; lo muestra en pantalla
            Copiar      R1, R0
            Sumar       R1, R0                ; R1 = 2 * R0
            CargarValor R2, 0
            Almacenar   R2, DISCO_DIRECCION   ; posicion 0 del disco
            Almacenar   R0, DISCO_DATO        ; disco[0] = R0
            Almacenar   R1, DISCO_DATO        ; disco[1] = 2 * R0
            Almacenar   R2, DISCO_DIRECCION   ; vuelve a la posicion 0
            Cargar      R3, DISCO_DATO        ; R3 = disco[0]
            Cargar      R4, DISCO_DATO        ; R4 = disco[1]
            Almacenar   R4, PANTALLA_NUMERO
            Almacenar   R3, RED_ENVIAR        ; envia por la red
            Almacenar   R4, RED_ENVIAR
            Cargar      R5, RED_ESTADO        ; palabras recibidas
            Cargar      R6, RED_RECIBIR       ; primera palabra recibida
            CargarValor R2, 72                ; 'H'
            Almacenar   R2, PANTALLA_CARACTER
            CargarValor R2, 105               ; 'i'
            Almacenar   R2, PANTALLA_CARACTER
            CargarValor R2, 10                ; salto de linea
            Almacenar   R2, PANTALLA_CARACTER
            Parar
