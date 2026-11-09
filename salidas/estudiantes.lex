Analisis lexico de salidas/estudiantes.pp.djl

LINEA  COL  LEXEMA                 CATEGORIA          CODIGO
-----  ---  ---------------------- ------------------ ------
    4    1  const                  PALABRA_RESERVADA     107
    4    7  float                  PALABRA_RESERVADA     102
    4   13  APROBAR                IDENTIFICADOR         200
    4   21  =                      ASIGNACION           1001
    4   23  3.0                    CONSTANTE_REAL        400
    4   26  ;                      DELIMITADOR          1107
    6    1  struct                 PALABRA_RESERVADA     106
    6    8  Estudiante             IDENTIFICADOR         200
    6   19  {                      DELIMITADOR          1105
    7    5  char                   PALABRA_RESERVADA     104
    7   10  inicial                IDENTIFICADOR         200
    7   17  ;                      DELIMITADOR          1107
    8    5  int                    PALABRA_RESERVADA     101
    8    9  codigo                 IDENTIFICADOR         200
    8   15  ;                      DELIMITADOR          1107
    9    5  float                  PALABRA_RESERVADA     102
    9   11  nota                   IDENTIFICADOR         200
    9   15  ;                      DELIMITADOR          1107
   10    1  }                      DELIMITADOR          1106
   10    2  ;                      DELIMITADOR          1107
   12    1  struct                 PALABRA_RESERVADA     106
   12    8  Estudiante             IDENTIFICADOR         200
   12   19  grupo                  IDENTIFICADOR         200
   12   24  [                      DELIMITADOR          1103
   12   25  4                      CONSTANTE_ENTERA      300
   12   26  ]                      DELIMITADOR          1104
   12   27  ;                      DELIMITADOR          1107
   14    1  void                   PALABRA_RESERVADA     105
   14    6  ordenar                IDENTIFICADOR         200
   14   13  (                      DELIMITADOR          1101
   14   14  )                      DELIMITADOR          1102
   14   16  {                      DELIMITADOR          1105
   15    5  int                    PALABRA_RESERVADA     101
   15    9  i                      IDENTIFICADOR         200
   15   11  =                      ASIGNACION           1001
   15   13  0                      CONSTANTE_ENTERA      300
   15   14  ;                      DELIMITADOR          1107
   16    5  bool                   PALABRA_RESERVADA     103
   16   10  cambio                 IDENTIFICADOR         200
   16   17  =                      ASIGNACION           1001
   16   19  true                   PALABRA_RESERVADA     118
   16   23  ;                      DELIMITADOR          1107
   17    5  struct                 PALABRA_RESERVADA     106
   17   12  Estudiante             IDENTIFICADOR         200
   17   23  tmp                    IDENTIFICADOR         200
   17   26  ;                      DELIMITADOR          1107
   18    5  while                  PALABRA_RESERVADA     110
   18   11  (                      DELIMITADOR          1101
   18   12  cambio                 IDENTIFICADOR         200
   18   18  )                      DELIMITADOR          1102
   18   20  {                      DELIMITADOR          1105
   19    9  cambio                 IDENTIFICADOR         200
   19   16  =                      ASIGNACION           1001
   19   18  false                  PALABRA_RESERVADA     119
   19   23  ;                      DELIMITADOR          1107
   20    9  for                    PALABRA_RESERVADA     112
   20   13  (                      DELIMITADOR          1101
   20   14  i                      IDENTIFICADOR         200
   20   16  =                      ASIGNACION           1001
   20   18  0                      CONSTANTE_ENTERA      300
   20   19  ;                      DELIMITADOR          1107
   20   21  i                      IDENTIFICADOR         200
   20   23  <                      OP_RELACIONAL         803
   20   25  4                      CONSTANTE_ENTERA      300
   20   27  -                      OP_ARITMETICO         702
   20   29  1                      CONSTANTE_ENTERA      300
   20   30  ;                      DELIMITADOR          1107
   20   32  i                      IDENTIFICADOR         200
   20   34  =                      ASIGNACION           1001
   20   36  i                      IDENTIFICADOR         200
   20   38  +                      OP_ARITMETICO         701
   20   40  1                      CONSTANTE_ENTERA      300
   20   41  )                      DELIMITADOR          1102
   20   43  {                      DELIMITADOR          1105
   21   13  if                     PALABRA_RESERVADA     108
   21   16  (                      DELIMITADOR          1101
   21   17  grupo                  IDENTIFICADOR         200
   21   22  [                      DELIMITADOR          1103
   21   23  i                      IDENTIFICADOR         200
   21   24  ]                      DELIMITADOR          1104
   21   25  .                      DELIMITADOR          1109
   21   26  nota                   IDENTIFICADOR         200
   21   31  <                      OP_RELACIONAL         803
   21   33  grupo                  IDENTIFICADOR         200
   21   38  [                      DELIMITADOR          1103
   21   39  i                      IDENTIFICADOR         200
   21   41  +                      OP_ARITMETICO         701
   21   43  1                      CONSTANTE_ENTERA      300
   21   44  ]                      DELIMITADOR          1104
   21   45  .                      DELIMITADOR          1109
   21   46  nota                   IDENTIFICADOR         200
   21   50  )                      DELIMITADOR          1102
   21   52  {                      DELIMITADOR          1105
   22   17  tmp                    IDENTIFICADOR         200
   22   21  =                      ASIGNACION           1001
   22   23  grupo                  IDENTIFICADOR         200
   22   28  [                      DELIMITADOR          1103
   22   29  i                      IDENTIFICADOR         200
   22   30  ]                      DELIMITADOR          1104
   22   31  ;                      DELIMITADOR          1107
   23   17  grupo                  IDENTIFICADOR         200
   23   22  [                      DELIMITADOR          1103
   23   23  i                      IDENTIFICADOR         200
   23   24  ]                      DELIMITADOR          1104
   23   26  =                      ASIGNACION           1001
   23   28  grupo                  IDENTIFICADOR         200
   23   33  [                      DELIMITADOR          1103
   23   34  i                      IDENTIFICADOR         200
   23   36  +                      OP_ARITMETICO         701
   23   38  1                      CONSTANTE_ENTERA      300
   23   39  ]                      DELIMITADOR          1104
   23   40  ;                      DELIMITADOR          1107
   24   17  grupo                  IDENTIFICADOR         200
   24   22  [                      DELIMITADOR          1103
   24   23  i                      IDENTIFICADOR         200
   24   25  +                      OP_ARITMETICO         701
   24   27  1                      CONSTANTE_ENTERA      300
   24   28  ]                      DELIMITADOR          1104
   24   30  =                      ASIGNACION           1001
   24   32  tmp                    IDENTIFICADOR         200
   24   35  ;                      DELIMITADOR          1107
   25   17  cambio                 IDENTIFICADOR         200
   25   24  =                      ASIGNACION           1001
   25   26  true                   PALABRA_RESERVADA     118
   25   30  ;                      DELIMITADOR          1107
   26   13  }                      DELIMITADOR          1106
   27    9  }                      DELIMITADOR          1106
   28    5  }                      DELIMITADOR          1106
   29    1  }                      DELIMITADOR          1106
   31    1  int                    PALABRA_RESERVADA     101
   31    5  main                   IDENTIFICADOR         200
   31    9  (                      DELIMITADOR          1101
   31   10  )                      DELIMITADOR          1102
   31   12  {                      DELIMITADOR          1105
   32    5  int                    PALABRA_RESERVADA     101
   32    9  i                      IDENTIFICADOR         200
   32   10  ;                      DELIMITADOR          1107
   33    5  for                    PALABRA_RESERVADA     112
   33    9  (                      DELIMITADOR          1101
   33   10  i                      IDENTIFICADOR         200
   33   12  =                      ASIGNACION           1001
   33   14  0                      CONSTANTE_ENTERA      300
   33   15  ;                      DELIMITADOR          1107
   33   17  i                      IDENTIFICADOR         200
   33   19  <                      OP_RELACIONAL         803
   33   21  4                      CONSTANTE_ENTERA      300
   33   22  ;                      DELIMITADOR          1107
   33   24  i                      IDENTIFICADOR         200
   33   26  =                      ASIGNACION           1001
   33   28  i                      IDENTIFICADOR         200
   33   30  +                      OP_ARITMETICO         701
   33   32  1                      CONSTANTE_ENTERA      300
   33   33  )                      DELIMITADOR          1102
   33   35  {                      DELIMITADOR          1105
   34    9  read                   PALABRA_RESERVADA     116
   34   13  (                      DELIMITADOR          1101
   34   14  grupo                  IDENTIFICADOR         200
   34   19  [                      DELIMITADOR          1103
   34   20  i                      IDENTIFICADOR         200
   34   21  ]                      DELIMITADOR          1104
   34   22  .                      DELIMITADOR          1109
   34   23  inicial                IDENTIFICADOR         200
   34   30  ,                      DELIMITADOR          1108
   34   32  grupo                  IDENTIFICADOR         200
   34   37  [                      DELIMITADOR          1103
   34   38  i                      IDENTIFICADOR         200
   34   39  ]                      DELIMITADOR          1104
   34   40  .                      DELIMITADOR          1109
   34   41  codigo                 IDENTIFICADOR         200
   34   47  ,                      DELIMITADOR          1108
   34   49  grupo                  IDENTIFICADOR         200
   34   54  [                      DELIMITADOR          1103
   34   55  i                      IDENTIFICADOR         200
   34   56  ]                      DELIMITADOR          1104
   34   57  .                      DELIMITADOR          1109
   34   58  nota                   IDENTIFICADOR         200
   34   62  )                      DELIMITADOR          1102
   34   63  ;                      DELIMITADOR          1107
   35    5  }                      DELIMITADOR          1106
   36    5  ordenar                IDENTIFICADOR         200
   36   12  (                      DELIMITADOR          1101
   36   13  )                      DELIMITADOR          1102
   36   14  ;                      DELIMITADOR          1107
   37    5  for                    PALABRA_RESERVADA     112
   37    9  (                      DELIMITADOR          1101
   37   10  i                      IDENTIFICADOR         200
   37   12  =                      ASIGNACION           1001
   37   14  0                      CONSTANTE_ENTERA      300
   37   15  ;                      DELIMITADOR          1107
   37   17  i                      IDENTIFICADOR         200
   37   19  <                      OP_RELACIONAL         803
   37   21  4                      CONSTANTE_ENTERA      300
   37   22  ;                      DELIMITADOR          1107
   37   24  i                      IDENTIFICADOR         200
   37   26  =                      ASIGNACION           1001
   37   28  i                      IDENTIFICADOR         200
   37   30  +                      OP_ARITMETICO         701
   37   32  1                      CONSTANTE_ENTERA      300
   37   33  )                      DELIMITADOR          1102
   37   35  {                      DELIMITADOR          1105
   38    9  if                     PALABRA_RESERVADA     108
   38   12  (                      DELIMITADOR          1101
   38   13  grupo                  IDENTIFICADOR         200
   38   18  [                      DELIMITADOR          1103
   38   19  i                      IDENTIFICADOR         200
   38   20  ]                      DELIMITADOR          1104
   38   21  .                      DELIMITADOR          1109
   38   22  nota                   IDENTIFICADOR         200
   38   27  >=                     OP_RELACIONAL         806
   38   30  APROBAR                IDENTIFICADOR         200
   38   38  ||                     OP_LOGICO             902
   38   41  !                      OP_LOGICO             903
   38   42  (                      DELIMITADOR          1101
   38   43  grupo                  IDENTIFICADOR         200
   38   48  [                      DELIMITADOR          1103
   38   49  i                      IDENTIFICADOR         200
   38   50  ]                      DELIMITADOR          1104
   38   51  .                      DELIMITADOR          1109
   38   52  codigo                 IDENTIFICADOR         200
   38   59  %                      OP_ARITMETICO         705
   38   61  2                      CONSTANTE_ENTERA      300
   38   63  !=                     OP_RELACIONAL         802
   38   66  0                      CONSTANTE_ENTERA      300
   38   67  )                      DELIMITADOR          1102
   38   68  )                      DELIMITADOR          1102
   38   70  {                      DELIMITADOR          1105
   39   13  print                  PALABRA_RESERVADA     117
   39   18  (                      DELIMITADOR          1101
   39   19  grupo                  IDENTIFICADOR         200
   39   24  [                      DELIMITADOR          1103
   39   25  i                      IDENTIFICADOR         200
   39   26  ]                      DELIMITADOR          1104
   39   27  .                      DELIMITADOR          1109
   39   28  inicial                IDENTIFICADOR         200
   39   35  ,                      DELIMITADOR          1108
   39   37  " aprobo\t"            CONSTANTE_CADENA      600
   39   48  ,                      DELIMITADOR          1108
   39   50  grupo                  IDENTIFICADOR         200
   39   55  [                      DELIMITADOR          1103
   39   56  i                      IDENTIFICADOR         200
   39   57  ]                      DELIMITADOR          1104
   39   58  .                      DELIMITADOR          1109
   39   59  nota                   IDENTIFICADOR         200
   39   63  ,                      DELIMITADOR          1108
   39   65  '\n'                   CONSTANTE_CARACTER    500
   39   69  )                      DELIMITADOR          1102
   39   70  ;                      DELIMITADOR          1107
   40    9  }                      DELIMITADOR          1106
   40   11  else                   PALABRA_RESERVADA     109
   40   16  {                      DELIMITADOR          1105
   41   13  continue               PALABRA_RESERVADA     114
   41   21  ;                      DELIMITADOR          1107
   42    9  }                      DELIMITADOR          1106
   43    5  }                      DELIMITADOR          1106
   44    5  return                 PALABRA_RESERVADA     115
   44   12  0                      CONSTANTE_ENTERA      300
   44   13  ;                      DELIMITADOR          1107
   45    1  }                      DELIMITADOR          1106

TABLA DE SIMBOLOS (identificadores)
  #   NOMBRE                           LINEA  USOS
  1   APROBAR                              4     2
  2   Estudiante                           6     3
  3   inicial                              7     3
  4   codigo                               8     3
  5   nota                                 9     6
  6   grupo                               12    14
  7   ordenar                             14     2
  8   i                                   15    27
  9   cambio                              16     4
 10   tmp                                 17     3
 11   main                                31     1

RESUMEN
  PALABRA_RESERVADA       27
  IDENTIFICADOR           68
  CONSTANTE_ENTERA        18
  CONSTANTE_REAL           1
  CONSTANTE_CARACTER       1
  CONSTANTE_CADENA         1
  OP_ARITMETICO            8
  OP_RELACIONAL            6
  OP_LOGICO                2
  ASIGNACION              14
  DELIMITADOR            112
  TOTAL DE TOKENS        258
  ERRORES LEXICOS          0
