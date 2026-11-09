Analisis lexico de salidas/heron.pp.djl

LINEA  COL  LEXEMA                 CATEGORIA          CODIGO
-----  ---  ---------------------- ------------------ ------
    6    1  float                  PALABRA_RESERVADA     102
    6    7  abs_f                  IDENTIFICADOR         200
    6   12  (                      DELIMITADOR          1101
    6   13  float                  PALABRA_RESERVADA     102
    6   19  x                      IDENTIFICADOR         200
    6   20  )                      DELIMITADOR          1102
    6   22  {                      DELIMITADOR          1105
    7    5  if                     PALABRA_RESERVADA     108
    7    8  (                      DELIMITADOR          1101
    7    9  x                      IDENTIFICADOR         200
    7   11  <                      OP_RELACIONAL         803
    7   13  0.0                    CONSTANTE_REAL        400
    7   16  )                      DELIMITADOR          1102
    7   18  {                      DELIMITADOR          1105
    8    9  return                 PALABRA_RESERVADA     115
    8   16  -                      OP_ARITMETICO         702
    8   17  x                      IDENTIFICADOR         200
    8   18  ;                      DELIMITADOR          1107
    9    5  }                      DELIMITADOR          1106
   10    5  return                 PALABRA_RESERVADA     115
   10   12  x                      IDENTIFICADOR         200
   10   13  ;                      DELIMITADOR          1107
   11    1  }                      DELIMITADOR          1106
   14    1  float                  PALABRA_RESERVADA     102
   14    7  heron                  IDENTIFICADOR         200
   14   12  (                      DELIMITADOR          1101
   14   13  float                  PALABRA_RESERVADA     102
   14   19  x                      IDENTIFICADOR         200
   14   20  ,                      DELIMITADOR          1108
   14   22  float                  PALABRA_RESERVADA     102
   14   28  y0                     IDENTIFICADOR         200
   14   30  )                      DELIMITADOR          1102
   14   32  {                      DELIMITADOR          1105
   15    5  float                  PALABRA_RESERVADA     102
   15   11  y                      IDENTIFICADOR         200
   15   13  =                      ASIGNACION           1001
   15   15  y0                     IDENTIFICADOR         200
   15   17  ;                      DELIMITADOR          1107
   16    5  float                  PALABRA_RESERVADA     102
   16   11  anterior               IDENTIFICADOR         200
   16   19  ;                      DELIMITADOR          1107
   17    5  int                    PALABRA_RESERVADA     101
   17    9  i                      IDENTIFICADOR         200
   17   11  =                      ASIGNACION           1001
   17   13  0                      CONSTANTE_ENTERA      300
   17   14  ;                      DELIMITADOR          1107
   18    5  do                     PALABRA_RESERVADA     111
   18    8  {                      DELIMITADOR          1105
   19    9  anterior               IDENTIFICADOR         200
   19   18  =                      ASIGNACION           1001
   19   20  y                      IDENTIFICADOR         200
   19   21  ;                      DELIMITADOR          1107
   20    9  y                      IDENTIFICADOR         200
   20   11  =                      ASIGNACION           1001
   20   13  0.5                    CONSTANTE_REAL        400
   20   17  *                      OP_ARITMETICO         703
   20   19  (                      DELIMITADOR          1101
   20   20  y                      IDENTIFICADOR         200
   20   22  +                      OP_ARITMETICO         701
   20   24  x                      IDENTIFICADOR         200
   20   26  /                      OP_ARITMETICO         704
   20   28  y                      IDENTIFICADOR         200
   20   29  )                      DELIMITADOR          1102
   20   30  ;                      DELIMITADOR          1107
   21    9  i                      IDENTIFICADOR         200
   21   11  =                      ASIGNACION           1001
   21   13  i                      IDENTIFICADOR         200
   21   15  +                      OP_ARITMETICO         701
   21   17  1                      CONSTANTE_ENTERA      300
   21   18  ;                      DELIMITADOR          1107
   22    5  }                      DELIMITADOR          1106
   22    7  while                  PALABRA_RESERVADA     110
   22   13  (                      DELIMITADOR          1101
   22   14  abs_f                  IDENTIFICADOR         200
   22   19  (                      DELIMITADOR          1101
   22   20  y                      IDENTIFICADOR         200
   22   22  -                      OP_ARITMETICO         702
   22   24  anterior               IDENTIFICADOR         200
   22   32  )                      DELIMITADOR          1102
   22   34  >                      OP_RELACIONAL         805
   22   36  1e-12                  CONSTANTE_REAL        400
   22   42  &&                     OP_LOGICO             901
   22   45  i                      IDENTIFICADOR         200
   22   47  <                      OP_RELACIONAL         803
   22   49  50                     CONSTANTE_ENTERA      300
   22   51  )                      DELIMITADOR          1102
   22   52  ;                      DELIMITADOR          1107
   23    5  return                 PALABRA_RESERVADA     115
   23   12  y                      IDENTIFICADOR         200
   23   13  ;                      DELIMITADOR          1107
   24    1  }                      DELIMITADOR          1106
   26    1  int                    PALABRA_RESERVADA     101
   26    5  main                   IDENTIFICADOR         200
   26    9  (                      DELIMITADOR          1101
   26   10  )                      DELIMITADOR          1102
   26   12  {                      DELIMITADOR          1105
   27    5  float                  PALABRA_RESERVADA     102
   27   11  x                      IDENTIFICADOR         200
   27   13  =                      ASIGNACION           1001
   27   15  125.0                  CONSTANTE_REAL        400
   27   20  ;                      DELIMITADOR          1107
   28    5  print                  PALABRA_RESERVADA     117
   28   10  (                      DELIMITADOR          1101
   28   11  "raiz("                CONSTANTE_CADENA      600
   28   18  ,                      DELIMITADOR          1108
   28   20  x                      IDENTIFICADOR         200
   28   21  ,                      DELIMITADOR          1108
   28   23  ") = "                 CONSTANTE_CADENA      600
   28   29  ,                      DELIMITADOR          1108
   28   31  heron                  IDENTIFICADOR         200
   28   36  (                      DELIMITADOR          1101
   28   37  x                      IDENTIFICADOR         200
   28   38  ,                      DELIMITADOR          1108
   28   40  10.0                   CONSTANTE_REAL        400
   28   44  )                      DELIMITADOR          1102
   28   45  ,                      DELIMITADOR          1108
   28   47  '\n'                   CONSTANTE_CARACTER    500
   28   51  )                      DELIMITADOR          1102
   28   52  ;                      DELIMITADOR          1107
   29    5  return                 PALABRA_RESERVADA     115
   29   12  0                      CONSTANTE_ENTERA      300
   29   13  ;                      DELIMITADOR          1107
   30    1  }                      DELIMITADOR          1106

TABLA DE SIMBOLOS (identificadores)
  #   NOMBRE                           LINEA  USOS
  1   abs_f                                6     2
  2   x                                    6     9
  3   heron                               14     2
  4   y0                                  14     2
  5   y                                   15     7
  6   anterior                            16     3
  7   i                                   17     4
  8   main                                26     1

RESUMEN
  PALABRA_RESERVADA       18
  IDENTIFICADOR           30
  CONSTANTE_ENTERA         4
  CONSTANTE_REAL           5
  CONSTANTE_CARACTER       1
  CONSTANTE_CADENA         2
  OP_ARITMETICO            6
  OP_RELACIONAL            3
  OP_LOGICO                1
  ASIGNACION               6
  DELIMITADOR             47
  TOTAL DE TOKENS        123
  ERRORES LEXICOS          0
