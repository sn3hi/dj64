/* =====================================================================
 * lexico.l - MODULO DE ANALISIS LEXICO del compilador del lenguaje DJL
 * para el DJ-64 (Hunza DJ Systems), escrito en FLEX.
 * Taller 01 - Lenguajes de programacion (2025966) - Grupo 2 2026-2
 *
 * DJL es un lenguaje imperativo con palabras reservadas en ingles:
 * tipos int, float, bool, char, void; registros (TDA) con struct;
 * constantes con const; secuencia, seleccion (if/else) e iteracion
 * (while, do, for); arreglos y matrices (v[10], m[3][3]); funciones
 * (return) y entrada/salida (read, print).
 *
 * El analizador lee el programa YA PREPROCESADO y entrega la secuencia de
 * tokens. Cada token tiene una categoria (centenas) y un codigo:
 *     100 palabra reservada (101-119)    700 operador aritmetico (701-705)
 *     200 identificador                  800 operador relacional (801-806)
 *     300 constante entera               900 operador logico     (901-903)
 *     400 constante real                1000 asignacion          (1001)
 *     500 constante caracter            1100 delimitador         (1101-1109)
 *     600 constante cadena                 0 error lexico
 * Los identificadores se guardan sin repetir en la tabla de simbolos.
 *
 * Uso:  ./lexico programa.djl [tokens.txt]
 *       (tokens.txt: "codigo linea lexema" por token, para la fase 2)
 * ===================================================================== */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

enum { KW = 100, ID = 200, ENTERO = 300, REAL = 400, CARACTER = 500,
       CADENA = 600, OP_ARIT = 700, OP_REL = 800, OP_LOG = 900,
       ASIGNACION = 1000, DELIM = 1100, ERROR = 0 };

static const char *RESERVADAS[] = {
    "int", "float", "bool", "char", "void", "struct", "const",
    "if", "else", "while", "do", "for", "break", "continue", "return",
    "read", "print", "true", "false" };
static const char *ARITMETICOS[]  = {"+", "-", "*", "/", "%"};
static const char *RELACIONALES[] = {"==", "!=", "<", "<=", ">", ">="};
static const char *LOGICOS[]      = {"&&", "||", "!"};
static const char *DELIMITADORES[] = {"(", ")", "[", "]", "{", "}", ";", ",", "."};

#define MAX_ID      31
#define MAX_SIMBOLOS 1000

static struct { char nombre[MAX_ID + 1]; int linea; int usos; } simbolos[MAX_SIMBOLOS];
static int n_simbolos = 0;

static int linea = 1, columna = 1, col_token = 1;
static int cuenta[12], errores = 0, linea_comentario = 0, col_comentario = 0;
static FILE *archivo_tokens = NULL;

#define YY_USER_ACTION  { col_token = columna; columna += yyleng; }

static int indice(const char **tabla, int n, const char *lexema)
{
    for (int i = 0; i < n; i++)
        if (strcmp(tabla[i], lexema) == 0) return i + 1;
    return 0;
}
#define CODIGO(tabla, base) ((base) + indice(tabla, sizeof tabla / sizeof tabla[0], yytext))

static void token(int categoria, int codigo);
static void error_lexico(const char *msg);
static void identificador(void);
static void entero(void);
%}

%option noyywrap nounput noinput
%x COMENTARIO

DIGITO      [0-9]
LETRA       [A-Za-z_]
ID          {LETRA}({LETRA}|{DIGITO})*
ENTERO      {DIGITO}+
EXPONENTE   [eE][+-]?{DIGITO}+
REAL        {DIGITO}+"."{DIGITO}+{EXPONENTE}?|{DIGITO}+{EXPONENTE}
ESCAPE      \\[ntr0\\'"]
CARACTER    \'([^'\\\n]|{ESCAPE})\'
CADENA      \"([^"\\\n]|{ESCAPE})*\"
RESERVADA   int|float|bool|char|void|struct|const|if|else|while|do|for|break|continue|return|read|print|true|false

%%
[ \t\r]+                    { /* espacios */ }
\n                          { linea++; columna = 1; }
"//"[^\n]*                  { /* comentario de linea */ }
"/*"                        { linea_comentario = linea; col_comentario = col_token; BEGIN(COMENTARIO); }
<COMENTARIO>"*/"            { BEGIN(INITIAL); }
<COMENTARIO>\n              { linea++; columna = 1; }
<COMENTARIO>[^*\n]+|"*"     { /* dentro del comentario */ }
<COMENTARIO><<EOF>>         { linea = linea_comentario; col_token = col_comentario;
                              error_lexico("comentario /* sin cerrar"); yyterminate(); }

{RESERVADA}                 { token(KW, CODIGO(RESERVADAS, KW)); }
{ID}                        { identificador(); }
{REAL}                      { token(REAL, REAL); }
{ENTERO}                    { entero(); }
{CARACTER}                  { token(CARACTER, CARACTER); }
{CADENA}                    { token(CADENA, CADENA); }

"+"|"-"|"*"|"/"|"%"         { token(OP_ARIT, CODIGO(ARITMETICOS, OP_ARIT)); }
"=="|"!="|"<"|"<="|">"|">=" { token(OP_REL, CODIGO(RELACIONALES, OP_REL)); }
"&&"|"||"|"!"               { token(OP_LOG, CODIGO(LOGICOS, OP_LOG)); }
"="                         { token(ASIGNACION, ASIGNACION + 1); }
"("|")"|"["|"]"|"{"|"}"|";"|","|"." { token(DELIM, CODIGO(DELIMITADORES, DELIM)); }

    /* ---------------- errores lexicos ---------------- */
{DIGITO}+{LETRA}({LETRA}|{DIGITO})*  { error_lexico("numero mal formado (un identificador no puede empezar con digito)"); }
{DIGITO}+"."                { error_lexico("real incompleto: faltan digitos despues del punto"); }
{DIGITO}+("."{DIGITO}+)?[eE][+-]?   { error_lexico("real incompleto: faltan digitos en el exponente"); }
\"([^"\n])*\"               { error_lexico("secuencia de escape no valida en la cadena"); }
\"([^"\\\n]|\\.)*           { error_lexico("cadena sin cerrar"); }
\'[^'\n]*\'?                { error_lexico("constante caracter mal formada"); }
"&"|"|"                     { error_lexico("operador incompleto (use && o ||)"); }
"#"[^\n]*                   { error_lexico("directiva sin preprocesar (use el preprocesador)"); }
.                           { error_lexico("caracter no valido"); }
%%

static const char *nombre_categoria(int c)
{
    static const char *n[] = {"ERROR", "PALABRA_RESERVADA", "IDENTIFICADOR",
        "CONSTANTE_ENTERA", "CONSTANTE_REAL", "CONSTANTE_CARACTER",
        "CONSTANTE_CADENA", "OP_ARITMETICO", "OP_RELACIONAL", "OP_LOGICO",
        "ASIGNACION", "DELIMITADOR"};
    return n[c / 100];
}

static void token(int categoria, int codigo)
{
    cuenta[categoria / 100]++;
    printf("%5d %4d  %-22.22s %-19s %5d\n", linea, col_token, yytext,
           nombre_categoria(categoria), codigo);
    if (archivo_tokens)
        fprintf(archivo_tokens, "%d %d %s\n", codigo, linea, yytext);
}

static void error_lexico(const char *msg)
{
    const char *lexema = (YY_START == COMENTARIO) ? "/*" : yytext;
    errores++;
    cuenta[0]++;
    printf("%5d %4d  %-22.22s %-19s %5d  <- %s\n", linea, col_token, lexema,
           "ERROR", 0, msg);
    fprintf(stderr, "linea %d, columna %d: error lexico: %s: %s\n",
            linea, col_token, msg, lexema);
}

/* identificador: se valida la longitud y se instala en la tabla de simbolos */
static void identificador(void)
{
    if (yyleng > MAX_ID) { error_lexico("identificador de mas de 31 caracteres"); return; }
    int i;
    for (i = 0; i < n_simbolos; i++)                    /* busqueda lineal */
        if (strcmp(simbolos[i].nombre, yytext) == 0) break;
    if (i == n_simbolos && n_simbolos < MAX_SIMBOLOS) {
        strcpy(simbolos[i].nombre, yytext);
        simbolos[i].linea = linea;
        n_simbolos++;
    }
    if (i < n_simbolos) simbolos[i].usos++;
    token(ID, ID);
}

/* constante entera: debe caber en una palabra del DJ-64 (64 bits con signo) */
static void entero(void)
{
    errno = 0;
    strtoll(yytext, NULL, 10);
    if (errno == ERANGE) { error_lexico("constante entera fuera de rango (64 bits)"); return; }
    token(ENTERO, ENTERO);
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "uso: %s programa.djl [tokens.txt]\n", argv[0]);
        return 2;
    }
    if (!(yyin = fopen(argv[1], "r"))) { perror(argv[1]); return 2; }
    if (argc > 2 && !(archivo_tokens = fopen(argv[2], "w"))) { perror(argv[2]); return 2; }

    printf("Analisis lexico de %s\n\n", argv[1]);
    printf("LINEA  COL  LEXEMA                 CATEGORIA          CODIGO\n");
    printf("-----  ---  ---------------------- ------------------ ------\n");
    yylex();
    fclose(yyin);
    if (archivo_tokens) fclose(archivo_tokens);

    printf("\nTABLA DE SIMBOLOS (identificadores)\n");
    printf("  #   NOMBRE                           LINEA  USOS\n");
    for (int i = 0; i < n_simbolos; i++)
        printf("%3d   %-32s %5d  %4d\n", i + 1, simbolos[i].nombre,
               simbolos[i].linea, simbolos[i].usos);

    printf("\nRESUMEN\n");
    int total = 0;
    for (int c = 1; c <= 11; c++) {
        printf("  %-20s %5d\n", nombre_categoria(c * 100), cuenta[c]);
        total += cuenta[c];
    }
    printf("  %-20s %5d\n  %-20s %5d\n", "TOTAL DE TOKENS", total, "ERRORES LEXICOS", errores);
    return errores ? 1 : 0;
}
