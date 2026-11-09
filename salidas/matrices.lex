Analisis lexico de salidas/matrices.pp.djl

LINEA  COL  LEXEMA                 CATEGORIA          CODIGO
-----  ---  ---------------------- ------------------ ------
    4    1  int                    PALABRA_RESERVADA     101
    4    5  a                      IDENTIFICADOR         200
    4    6  [                      DELIMITADOR          1103
    4    7  3                      CONSTANTE_ENTERA      300
    4    8  ]                      DELIMITADOR          1104
    4    9  [                      DELIMITADOR          1103
    4   10  3                      CONSTANTE_ENTERA      300
    4   11  ]                      DELIMITADOR          1104
    4   12  ;                      DELIMITADOR          1107
    5    1  int                    PALABRA_RESERVADA     101
    5    5  b                      IDENTIFICADOR         200
    5    6  [                      DELIMITADOR          1103
    5    7  3                      CONSTANTE_ENTERA      300
    5    8  ]                      DELIMITADOR          1104
    5    9  [                      DELIMITADOR          1103
    5   10  3                      CONSTANTE_ENTERA      300
    5   11  ]                      DELIMITADOR          1104
    5   12  ;                      DELIMITADOR          1107
    6    1  int                    PALABRA_RESERVADA     101
    6    5  c                      IDENTIFICADOR         200
    6    6  [                      DELIMITADOR          1103
    6    7  3                      CONSTANTE_ENTERA      300
    6    8  ]                      DELIMITADOR          1104
    6    9  [                      DELIMITADOR          1103
    6   10  3                      CONSTANTE_ENTERA      300
    6   11  ]                      DELIMITADOR          1104
    6   12  ;                      DELIMITADOR          1107
    8    1  void                   PALABRA_RESERVADA     105
    8    6  multiplicar            IDENTIFICADOR         200
    8   17  (                      DELIMITADOR          1101
    8   18  )                      DELIMITADOR          1102
    8   20  {                      DELIMITADOR          1105
    9    5  int                    PALABRA_RESERVADA     101
    9    9  i                      IDENTIFICADOR         200
    9   10  ;                      DELIMITADOR          1107
   10    5  int                    PALABRA_RESERVADA     101
   10    9  j                      IDENTIFICADOR         200
   10   10  ;                      DELIMITADOR          1107
   11    5  int                    PALABRA_RESERVADA     101
   11    9  k                      IDENTIFICADOR         200
   11   10  ;                      DELIMITADOR          1107
   12    5  for                    PALABRA_RESERVADA     112
   12    9  (                      DELIMITADOR          1101
   12   10  i                      IDENTIFICADOR         200
   12   12  =                      ASIGNACION           1001
   12   14  0                      CONSTANTE_ENTERA      300
   12   15  ;                      DELIMITADOR          1107
   12   17  i                      IDENTIFICADOR         200
   12   19  <                      OP_RELACIONAL         803
   12   21  3                      CONSTANTE_ENTERA      300
   12   22  ;                      DELIMITADOR          1107
   12   24  i                      IDENTIFICADOR         200
   12   26  =                      ASIGNACION           1001
   12   28  i                      IDENTIFICADOR         200
   12   30  +                      OP_ARITMETICO         701
   12   32  1                      CONSTANTE_ENTERA      300
   12   33  )                      DELIMITADOR          1102
   12   35  {                      DELIMITADOR          1105
   13    9  for                    PALABRA_RESERVADA     112
   13   13  (                      DELIMITADOR          1101
   13   14  j                      IDENTIFICADOR         200
   13   16  =                      ASIGNACION           1001
   13   18  0                      CONSTANTE_ENTERA      300
   13   19  ;                      DELIMITADOR          1107
   13   21  j                      IDENTIFICADOR         200
   13   23  <                      OP_RELACIONAL         803
   13   25  3                      CONSTANTE_ENTERA      300
   13   26  ;                      DELIMITADOR          1107
   13   28  j                      IDENTIFICADOR         200
   13   30  =                      ASIGNACION           1001
   13   32  j                      IDENTIFICADOR         200
   13   34  +                      OP_ARITMETICO         701
   13   36  1                      CONSTANTE_ENTERA      300
   13   37  )                      DELIMITADOR          1102
   13   39  {                      DELIMITADOR          1105
   14   13  c                      IDENTIFICADOR         200
   14   14  [                      DELIMITADOR          1103
   14   15  i                      IDENTIFICADOR         200
   14   16  ]                      DELIMITADOR          1104
   14   17  [                      DELIMITADOR          1103
   14   18  j                      IDENTIFICADOR         200
   14   19  ]                      DELIMITADOR          1104
   14   21  =                      ASIGNACION           1001
   14   23  0                      CONSTANTE_ENTERA      300
   14   24  ;                      DELIMITADOR          1107
   15   13  for                    PALABRA_RESERVADA     112
   15   17  (                      DELIMITADOR          1101
   15   18  k                      IDENTIFICADOR         200
   15   20  =                      ASIGNACION           1001
   15   22  0                      CONSTANTE_ENTERA      300
   15   23  ;                      DELIMITADOR          1107
   15   25  k                      IDENTIFICADOR         200
   15   27  <                      OP_RELACIONAL         803
   15   29  3                      CONSTANTE_ENTERA      300
   15   30  ;                      DELIMITADOR          1107
   15   32  k                      IDENTIFICADOR         200
   15   34  =                      ASIGNACION           1001
   15   36  k                      IDENTIFICADOR         200
   15   38  +                      OP_ARITMETICO         701
   15   40  1                      CONSTANTE_ENTERA      300
   15   41  )                      DELIMITADOR          1102
   15   43  {                      DELIMITADOR          1105
   16   17  c                      IDENTIFICADOR         200
   16   18  [                      DELIMITADOR          1103
   16   19  i                      IDENTIFICADOR         200
   16   20  ]                      DELIMITADOR          1104
   16   21  [                      DELIMITADOR          1103
   16   22  j                      IDENTIFICADOR         200
   16   23  ]                      DELIMITADOR          1104
   16   25  =                      ASIGNACION           1001
   16   27  c                      IDENTIFICADOR         200
   16   28  [                      DELIMITADOR          1103
   16   29  i                      IDENTIFICADOR         200
   16   30  ]                      DELIMITADOR          1104
   16   31  [                      DELIMITADOR          1103
   16   32  j                      IDENTIFICADOR         200
   16   33  ]                      DELIMITADOR          1104
   16   35  +                      OP_ARITMETICO         701
   16   37  a                      IDENTIFICADOR         200
   16   38  [                      DELIMITADOR          1103
   16   39  i                      IDENTIFICADOR         200
   16   40  ]                      DELIMITADOR          1104
   16   41  [                      DELIMITADOR          1103
   16   42  k                      IDENTIFICADOR         200
   16   43  ]                      DELIMITADOR          1104
   16   45  *                      OP_ARITMETICO         703
   16   47  b                      IDENTIFICADOR         200
   16   48  [                      DELIMITADOR          1103
   16   49  k                      IDENTIFICADOR         200
   16   50  ]                      DELIMITADOR          1104
   16   51  [                      DELIMITADOR          1103
   16   52  j                      IDENTIFICADOR         200
   16   53  ]                      DELIMITADOR          1104
   16   54  ;                      DELIMITADOR          1107
   17   13  }                      DELIMITADOR          1106
   18    9  }                      DELIMITADOR          1106
   19    5  }                      DELIMITADOR          1106
   20    1  }                      DELIMITADOR          1106
   22    1  int                    PALABRA_RESERVADA     101
   22    5  main                   IDENTIFICADOR         200
   22    9  (                      DELIMITADOR          1101
   22   10  )                      DELIMITADOR          1102
   22   12  {                      DELIMITADOR          1105
   23    5  int                    PALABRA_RESERVADA     101
   23    9  i                      IDENTIFICADOR         200
   23   10  ;                      DELIMITADOR          1107
   24    5  int                    PALABRA_RESERVADA     101
   24    9  j                      IDENTIFICADOR         200
   24   10  ;                      DELIMITADOR          1107
   25    5  for                    PALABRA_RESERVADA     112
   25    9  (                      DELIMITADOR          1101
   25   10  i                      IDENTIFICADOR         200
   25   12  =                      ASIGNACION           1001
   25   14  0                      CONSTANTE_ENTERA      300
   25   15  ;                      DELIMITADOR          1107
   25   17  i                      IDENTIFICADOR         200
   25   19  <                      OP_RELACIONAL         803
   25   21  3                      CONSTANTE_ENTERA      300
   25   22  ;                      DELIMITADOR          1107
   25   24  i                      IDENTIFICADOR         200
   25   26  =                      ASIGNACION           1001
   25   28  i                      IDENTIFICADOR         200
   25   30  +                      OP_ARITMETICO         701
   25   32  1                      CONSTANTE_ENTERA      300
   25   33  )                      DELIMITADOR          1102
   25   35  {                      DELIMITADOR          1105
   26    9  for                    PALABRA_RESERVADA     112
   26   13  (                      DELIMITADOR          1101
   26   14  j                      IDENTIFICADOR         200
   26   16  =                      ASIGNACION           1001
   26   18  0                      CONSTANTE_ENTERA      300
   26   19  ;                      DELIMITADOR          1107
   26   21  j                      IDENTIFICADOR         200
   26   23  <                      OP_RELACIONAL         803
   26   25  3                      CONSTANTE_ENTERA      300
   26   26  ;                      DELIMITADOR          1107
   26   28  j                      IDENTIFICADOR         200
   26   30  =                      ASIGNACION           1001
   26   32  j                      IDENTIFICADOR         200
   26   34  +                      OP_ARITMETICO         701
   26   36  1                      CONSTANTE_ENTERA      300
   26   37  )                      DELIMITADOR          1102
   26   39  {                      DELIMITADOR          1105
   27   13  a                      IDENTIFICADOR         200
   27   14  [                      DELIMITADOR          1103
   27   15  i                      IDENTIFICADOR         200
   27   16  ]                      DELIMITADOR          1104
   27   17  [                      DELIMITADOR          1103
   27   18  j                      IDENTIFICADOR         200
   27   19  ]                      DELIMITADOR          1104
   27   21  =                      ASIGNACION           1001
   27   23  i                      IDENTIFICADOR         200
   27   25  +                      OP_ARITMETICO         701
   27   27  j                      IDENTIFICADOR         200
   27   28  ;                      DELIMITADOR          1107
   28   13  b                      IDENTIFICADOR         200
   28   14  [                      DELIMITADOR          1103
   28   15  i                      IDENTIFICADOR         200
   28   16  ]                      DELIMITADOR          1104
   28   17  [                      DELIMITADOR          1103
   28   18  j                      IDENTIFICADOR         200
   28   19  ]                      DELIMITADOR          1104
   28   21  =                      ASIGNACION           1001
   28   23  (                      DELIMITADOR          1101
   28   24  i                      IDENTIFICADOR         200
   28   26  ==                     OP_RELACIONAL         801
   28   29  j                      IDENTIFICADOR         200
   28   30  )                      DELIMITADOR          1102
   28   31  ;                      DELIMITADOR          1107
   29    9  }                      DELIMITADOR          1106
   30    5  }                      DELIMITADOR          1106
   31    5  multiplicar            IDENTIFICADOR         200
   31   16  (                      DELIMITADOR          1101
   31   17  )                      DELIMITADOR          1102
   31   18  ;                      DELIMITADOR          1107
   32    5  print                  PALABRA_RESERVADA     117
   32   10  (                      DELIMITADOR          1101
   32   11  c                      IDENTIFICADOR         200
   32   12  [                      DELIMITADOR          1103
   32   13  2                      CONSTANTE_ENTERA      300
   32   14  ]                      DELIMITADOR          1104
   32   15  [                      DELIMITADOR          1103
   32   16  1                      CONSTANTE_ENTERA      300
   32   17  ]                      DELIMITADOR          1104
   32   18  ,                      DELIMITADOR          1108
   32   20  c                      IDENTIFICADOR         200
   32   21  [                      DELIMITADOR          1103
   32   22  3                      CONSTANTE_ENTERA      300
   32   24  -                      OP_ARITMETICO         702
   32   26  1                      CONSTANTE_ENTERA      300
   32   27  ]                      DELIMITADOR          1104
   32   28  [                      DELIMITADOR          1103
   32   29  3                      CONSTANTE_ENTERA      300
   32   31  -                      OP_ARITMETICO         702
   32   33  1                      CONSTANTE_ENTERA      300
   32   34  ]                      DELIMITADOR          1104
   32   35  )                      DELIMITADOR          1102
   32   36  ;                      DELIMITADOR          1107
   33    5  return                 PALABRA_RESERVADA     115
   33   12  0                      CONSTANTE_ENTERA      300
   33   13  ;                      DELIMITADOR          1107
   34    1  }                      DELIMITADOR          1106

TABLA DE SIMBOLOS (identificadores)
  #   NOMBRE                           LINEA  USOS
  1   a                                    4     3
  2   b                                    5     3
  3   c                                    6     6
  4   multiplicar                          8     2
  5   i                                    9    18
  6   j                                   10    18
  7   k                                   11     7
  8   main                                22     1

RESUMEN
  PALABRA_RESERVADA       17
  IDENTIFICADOR           58
  CONSTANTE_ENTERA        29
  CONSTANTE_REAL           0
  CONSTANTE_CARACTER       0
  CONSTANTE_CADENA         0
  OP_ARITMETICO           10
  OP_RELACIONAL            6
  OP_LOGICO                0
  ASIGNACION              14
  DELIMITADOR            108
  TOTAL DE TOKENS        242
  ERRORES LEXICOS          0
