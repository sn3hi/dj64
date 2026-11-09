Analisis lexico de pruebas/djl/errores.djl

LINEA  COL  LEXEMA                 CATEGORIA          CODIGO
-----  ---  ---------------------- ------------------ ------
    2    1  int                    PALABRA_RESERVADA     101
    2    5  main                   IDENTIFICADOR         200
    2    9  (                      DELIMITADOR          1101
    2   10  )                      DELIMITADOR          1102
    2   12  {                      DELIMITADOR          1105
    3    5  int                    PALABRA_RESERVADA     101
    3    9  2valor                 ERROR                   0  <- numero mal formado (un identificador no puede empezar con digito)
    3   16  =                      ASIGNACION           1001
    3   18  10                     CONSTANTE_ENTERA      300
    3   20  ;                      DELIMITADOR          1107
    4    5  float                  PALABRA_RESERVADA     102
    4   11  r                      IDENTIFICADOR         200
    4   13  =                      ASIGNACION           1001
    4   15  3.                     ERROR                   0  <- real incompleto: faltan digitos despues del punto
    4   17  ;                      DELIMITADOR          1107
    5    5  float                  PALABRA_RESERVADA     102
    5   11  e                      IDENTIFICADOR         200
    5   13  =                      ASIGNACION           1001
    5   15  1.5e                   ERROR                   0  <- real incompleto: faltan digitos en el exponente
    5   19  ;                      DELIMITADOR          1107
    6    5  char                   PALABRA_RESERVADA     104
    6   10  c                      IDENTIFICADOR         200
    6   12  =                      ASIGNACION           1001
    6   14  'ab'                   ERROR                   0  <- constante caracter mal formada
    6   18  ;                      DELIMITADOR          1107
    7    5  print                  PALABRA_RESERVADA     117
    7   10  (                      DELIMITADOR          1101
    7   11  "tab\q"                ERROR                   0  <- secuencia de escape no valida en la cadena
    7   18  )                      DELIMITADOR          1102
    7   19  ;                      DELIMITADOR          1107
    8    5  print                  PALABRA_RESERVADA     117
    8   10  (                      DELIMITADOR          1101
    8   11  "sin cerrar);          ERROR                   0  <- cadena sin cerrar
    9    5  if                     PALABRA_RESERVADA     108
    9    8  (                      DELIMITADOR          1101
    9    9  a                      IDENTIFICADOR         200
    9   11  &                      ERROR                   0  <- operador incompleto (use && o ||)
    9   13  b                      IDENTIFICADOR         200
    9   14  )                      DELIMITADOR          1102
    9   16  {                      DELIMITADOR          1105
    9   18  x                      IDENTIFICADOR         200
    9   20  =                      ASIGNACION           1001
    9   22  y                      IDENTIFICADOR         200
    9   24  |                      ERROR                   0  <- operador incompleto (use && o ||)
    9   26  z                      IDENTIFICADOR         200
    9   27  ;                      DELIMITADOR          1107
    9   29  }                      DELIMITADOR          1106
   10    5  int                    PALABRA_RESERVADA     101
   10    9  este_identificador_es_ ERROR                   0  <- identificador de mas de 31 caracteres
   10   47  =                      ASIGNACION           1001
   10   49  1                      CONSTANTE_ENTERA      300
   10   50  ;                      DELIMITADOR          1107
   11    5  int                    PALABRA_RESERVADA     101
   11    9  grande                 IDENTIFICADOR         200
   11   16  =                      ASIGNACION           1001
   11   18  99999999999999999999   ERROR                   0  <- constante entera fuera de rango (64 bits)
   11   38  ;                      DELIMITADOR          1107
   12    5  float                  PALABRA_RESERVADA     102
   12   11  p                      IDENTIFICADOR         200
   12   13  =                      ASIGNACION           1001
   12   15  2                      CONSTANTE_ENTERA      300
   12   17  @                      ERROR                   0  <- caracter no valido
   12   19  3                      CONSTANTE_ENTERA      300
   12   20  ;                      DELIMITADOR          1107
   13    5  #define TARDE 1        ERROR                   0  <- directiva sin preprocesar (use el preprocesador)
   14    5  return                 PALABRA_RESERVADA     115
   14   12  0                      CONSTANTE_ENTERA      300
   14   13  ;                      DELIMITADOR          1107
   15    1  }                      DELIMITADOR          1106
   16    1  /*                     ERROR                   0  <- comentario /* sin cerrar

TABLA DE SIMBOLOS (identificadores)
  #   NOMBRE                           LINEA  USOS
  1   main                                 2     1
  2   r                                    4     1
  3   e                                    5     1
  4   c                                    6     1
  5   a                                    9     1
  6   b                                    9     1
  7   x                                    9     1
  8   y                                    9     1
  9   z                                    9     1
 10   grande                              11     1
 11   p                                   12     1

RESUMEN
  PALABRA_RESERVADA       12
  IDENTIFICADOR           11
  CONSTANTE_ENTERA         5
  CONSTANTE_REAL           0
  CONSTANTE_CARACTER       0
  CONSTANTE_CADENA         0
  OP_ARITMETICO            0
  OP_RELACIONAL            0
  OP_LOGICO                0
  ASIGNACION               8
  DELIMITADOR             21
  TOTAL DE TOKENS         57
  ERRORES LEXICOS         13
