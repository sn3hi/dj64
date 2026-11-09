/* =====================================================================
 * ensamblador.l - ENSAMBLADOR del DJ-64 (Hunza DJ Systems) escrito en FLEX.
 * Taller 01 - Lenguajes de programacion (2025966) - Grupo 2 2026-2
 *
 * Traduce un programa en lenguaje ensamblador del DJ-64 a un MODULO OBJETO
 * reubicable. Es un ensamblador de DOS PASADAS:
 *   1a pasada: Flex parte cada linea en tokens; se guardan las instrucciones
 *              y los datos y se asigna una direccion a cada etiqueta.
 *   2a pasada: se codifica cada instruccion en su palabra de 64 bits,
 *              resolviendo las etiquetas con la tabla de simbolos.
 *
 * Lenguaje:
 *     ; comentario
 *     .equ NOMBRE, 0xFFFF0010        constante (no se reubica)
 *     .global fpu_sumar, ...         simbolos que este modulo exporta
 *     .externo fpu_sumar, ...        simbolos que se usan pero estan en otro modulo
 *     etiqueta:  Instruccion op1, op2
 *     .datos                         desde aqui, datos (.codigo vuelve al codigo)
 *     n:      10, -3, 0x1F           enteros de 64 bits
 *     medio:  0.5                    doble IEEE 754
 *     txt:    "Hola\n"               un caracter por palabra, terminado en 0
 *
 * Modulo objeto (texto, uno por linea; direcciones relativas en hexadecimal):
 *     H nombre tamano      encabezado (tamano en palabras)
 *     D simbolo dir        definicion exportada (.global)
 *     T dir palabra        texto: una palabra de codigo o de datos
 *     M dir                modificacion: sumar la base al campo de direccion
 *     R simbolo dir        referencia externa: sumar la direccion del simbolo
 *     E entrada            fin y punto de entrada
 * Los datos quedan justo despues del codigo, para que el enlazador pueda
 * poner varios modulos uno tras otro.
 *
 * Uso:  ./ensamblador entrada.asm salida.obj [-s]     (-s: tabla de simbolos)
 * ===================================================================== */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdint.h>
#include <errno.h>

/* categorias de los tokens que entrega Flex */
enum { T_FIN = 0, T_NL, T_DIR, T_ETIQ, T_REG, T_ENTERO, T_REAL, T_TEXTO,
       T_ID, T_COMA, T_ERROR };
%}

%option noyywrap nounput noinput

DIGITO      [0-9]
HEX         [0-9A-Fa-f]
ID          [A-Za-z_][A-Za-z0-9_]*

%%
";"[^\n]*                       { /* comentario: se ignora */ }
[ \t\r]+                        { /* espacios */ }
\n                              { return T_NL; }
"."{ID}                         { return T_DIR; }
{ID}[ \t]*":"                   { return T_ETIQ; }
[Rr]{DIGITO}+                   { return T_REG; }
-?({DIGITO}+"."{DIGITO}*([eE][-+]?{DIGITO}+)?|{DIGITO}+[eE][-+]?{DIGITO}+)  { return T_REAL; }
-?(0[xX]{HEX}+|{DIGITO}+)       { return T_ENTERO; }
\"[^"\n]*\"                     { return T_TEXTO; }
{ID}                            { return T_ID; }
","                             { return T_COMA; }
.                               { return T_ERROR; }
%%

/* ------------------------- repertorio del DJ-64 ------------------------- */
/* formato F1..F5: selector (3 bits) + indice; el resto del codigo en cero  */
typedef struct { const char *nombre; int formato; int indice; } Instruccion;

static const Instruccion REPERTORIO[] = {
    {"Parar",1,0}, {"Nop",1,1}, {"Ret",1,2}, {"IRet",1,3},
    {"Cargar",2,0}, {"Almacenar",2,1}, {"Lea",2,2},
    {"CargarValor",3,0}, {"SumarInm",3,1}, {"RestarInm",3,2}, {"DespInm",3,3},
    {"AndInm",3,4}, {"OrInm",3,5}, {"CmpInm",3,6},
    {"Saltar",4,0}, {"SaltarSiCero",4,1}, {"SaltarSiNoCero",4,2},
    {"SaltarSiNeg",4,3}, {"SaltarSiPos",4,4}, {"SaltarSiMayor",4,5},
    {"SaltarSiMenor",4,6}, {"SaltarSiMayorIgual",4,7},
    {"SaltarSiMenorIgual",4,8}, {"Llamar",4,9},
    {"Copiar",5,0}, {"Sumar",5,1}, {"Restar",5,2}, {"Mult",5,3}, {"Div",5,4},
    {"And",5,5}, {"Or",5,6}, {"Xor",5,7}, {"Comparar",5,8}, {"DespIzq",5,9},
    {"DespDer",5,10}, {"CargarIndR",5,11}, {"AlmacenarIndR",5,12},
    {"Push",5,13}, {"Pop",5,14}, {"Neg",5,15}, {"Not",5,16},
};
#define N_INSTR ((int)(sizeof REPERTORIO / sizeof REPERTORIO[0]))
/* bits del indice en cada formato = techo(log2(cantidad de instrucciones)) */
static const int BITS_INDICE[6] = {0, 2, 2, 3, 4, 5};
/* operandos que se escriben en cada formato: F1 ninguno, F2 R,M, F3 R,V,
   F4 M, F5 R,R' (Push, Pop, Neg y Not usan solo R) */
static const int N_OPERANDOS[6] = {0, 0, 2, 2, 1, 2};

static int buscar_instruccion(const char *s)
{
    for (int i = 0; i < N_INSTR; i++)
        if (strcasecmp(s, REPERTORIO[i].nombre) == 0)
            return i;
    return -1;
}

static int operandos_de(int ins)
{
    const char *n = REPERTORIO[ins].nombre;
    if (!strcmp(n, "Push") || !strcmp(n, "Pop") || !strcmp(n, "Neg") || !strcmp(n, "Not"))
        return 1;
    return N_OPERANDOS[REPERTORIO[ins].formato];
}

/* ------------------------- estructuras de datos ------------------------- */
#define MAX_SIM   2000
#define MAX_COD   8000
#define MAX_DAT   20000
#define MASCARA32 0xFFFFFFFFULL

enum { S_CODIGO, S_DATO, S_CONSTANTE, S_EXTERNO };
static const char *NOMBRE_CLASE[] = {"codigo", "dato", "constante", "externo"};

typedef struct { char *nombre; int clase; uint64_t valor; int global; int linea; } Simbolo;
typedef struct { int ins; int n; int tipo[2]; char *txt[2]; int linea; } LineaCodigo;
typedef struct { int es_simbolo; uint64_t valor; char *simbolo; int linea; } Dato;

static Simbolo tabla[MAX_SIM];           static int n_sim = 0;
static LineaCodigo codigo[MAX_COD];      static int n_cod = 0;
static Dato datos[MAX_DAT];              static int n_dat = 0;
static char *globales[MAX_SIM];          static int glob_linea[MAX_SIM]; static int n_glob = 0;

/* resultado de la segunda pasada */
static uint64_t palabras[MAX_COD + MAX_DAT];
static uint32_t reubicables[MAX_COD + MAX_DAT]; static int n_reub = 0;
static struct { char *simbolo; uint32_t dir; } externas[MAX_COD + MAX_DAT];
static int n_ext = 0;

static int linea = 1, errores = 0, seccion_datos = 0;

static void error(int n, const char *fmt, const char *arg)
{
    fprintf(stderr, "linea %d: error: ", n);
    fprintf(stderr, fmt, arg);
    fputc('\n', stderr);
    errores++;
}

static Simbolo *buscar(const char *nombre)          /* busqueda lineal */
{
    for (int i = 0; i < n_sim; i++)
        if (strcmp(tabla[i].nombre, nombre) == 0)
            return &tabla[i];
    return NULL;
}

static void definir(const char *nombre, int clase, uint64_t valor, int n)
{
    Simbolo *s = buscar(nombre);
    if (s) {
        if (clase == S_CONSTANTE && s->clase == S_CONSTANTE && s->valor == valor)
            return;                               /* misma constante dos veces */
        if (s->clase == S_EXTERNO || clase == S_EXTERNO)
            error(n, "'%s' se declara .externo y tambien se define en este modulo", nombre);
        else
            error(n, "el simbolo '%s' ya esta definido", nombre);
        return;
    }
    if (n_sim == MAX_SIM) { error(n, "demasiados simbolos%s", ""); return; }
    tabla[n_sim++] = (Simbolo){strdup(nombre), clase, valor, 0, n};
}

/* "125", "-3", "0x1F" -> valor de 64 bits (los negativos en complemento a 2) */
static uint64_t valor_entero(const char *s, int n)
{
    int neg = (s[0] == '-');
    const char *t = s + neg;
    errno = 0;
    uint64_t v = (t[0] == '0' && (t[1] == 'x' || t[1] == 'X'))
                 ? strtoull(t + 2, NULL, 16) : strtoull(t, NULL, 10);
    if (errno == ERANGE)
        error(n, "el numero %s no cabe en 64 bits", s);
    return neg ? 0 - v : v;
}

static uint64_t bits_de_doble(const char *s)    /* patron IEEE 754 del literal */
{
    double d = strtod(s, NULL);
    uint64_t b;
    memcpy(&b, &d, sizeof b);
    return b;
}

static void agregar_dato(int es_simbolo, uint64_t valor, const char *sim, int n)
{
    if (n_dat == MAX_DAT) { error(n, "demasiados datos%s", ""); return; }
    datos[n_dat++] = (Dato){es_simbolo, valor, sim ? strdup(sim) : NULL, n};
}

/* ------------------------ PRIMERA PASADA (por linea) -------------------- */
typedef struct { int tipo; char *txt; } Token;

static void directiva(Token *t, int n, int nl)
{
    const char *d = t[0].txt;
    if (!strcasecmp(d, ".datos"))  { seccion_datos = 1; return; }
    if (!strcasecmp(d, ".codigo")) { seccion_datos = 0; return; }
    if (!strcasecmp(d, ".equ")) {                 /* .equ NOMBRE[,] numero */
        int i = (n > 2 && t[2].tipo == T_COMA) ? 3 : 2;
        if (n != i + 1 || t[1].tipo != T_ID || t[i].tipo != T_ENTERO)
            error(nl, ".equ espera: .equ NOMBRE, numero%s", "");
        else
            definir(t[1].txt, S_CONSTANTE, valor_entero(t[i].txt, nl), nl);
        return;
    }
    if (!strcasecmp(d, ".global") || !strcasecmp(d, ".externo")) {
        int es_global = !strcasecmp(d, ".global");
        for (int i = 1; i < n; i++) {
            if (t[i].tipo == T_COMA) continue;
            if (t[i].tipo != T_ID) { error(nl, "%s espera nombres separados por comas", d); return; }
            if (es_global) { globales[n_glob] = strdup(t[i].txt); glob_linea[n_glob++] = nl; }
            else definir(t[i].txt, S_EXTERNO, 0, nl);
        }
        return;
    }
    if (!strcasecmp(d, ".incluir")) {
        error(nl, ".incluir ya no existe: use #include \"archivo\" con el preprocesador%s", "");
        return;
    }
    error(nl, "directiva desconocida '%s'", d);
}

static void procesar_linea(Token *t, int n, int nl)
{
    int i = 0;
    if (n == 0) return;
    for (int k = 0; k < n; k++)
        if (t[k].tipo == T_ERROR) { error(nl, "caracter no valido '%s'", t[k].txt); return; }
    if (t[0].tipo == T_DIR) { directiva(t, n, nl); return; }

    if (t[0].tipo == T_ETIQ) {                   /* "nombre:" -> quitar ':' y espacios */
        char *e = t[0].txt;
        e[strcspn(e, " \t:")] = '\0';
        if (seccion_datos) definir(e, S_DATO, n_dat, nl);      /* desplazamiento en datos */
        else               definir(e, S_CODIGO, n_cod, nl);    /* direccion de codigo */
        i = 1;
    }
    if (i == n) return;                          /* linea con solo la etiqueta */

    if (seccion_datos) {                         /* valores separados por comas */
        for (; i < n; i++) {
            Token *v = &t[i];
            if (v->tipo == T_COMA) continue;
            if (v->tipo == T_ENTERO)      agregar_dato(0, valor_entero(v->txt, nl), NULL, nl);
            else if (v->tipo == T_REAL)   agregar_dato(0, bits_de_doble(v->txt), NULL, nl);
            else if (v->tipo == T_ID)     agregar_dato(1, 0, v->txt, nl);
            else if (v->tipo == T_TEXTO) {
                size_t largo = strlen(v->txt) - 1;          /* sin las comillas */
                for (size_t k = 1; k < largo; k++) {
                    if (v->txt[k] == '\\' && v->txt[k + 1] == 'n') { agregar_dato(0, '\n', NULL, nl); k++; }
                    else agregar_dato(0, (unsigned char)v->txt[k], NULL, nl);
                }
                agregar_dato(0, 0, NULL, nl);               /* terminador */
            } else { error(nl, "valor de datos no valido '%s'", v->txt); return; }
        }
        return;
    }

    /* seccion de codigo: Mnemonico [op1 [, op2]] */
    if (t[i].tipo != T_ID) { error(nl, "se esperaba una instruccion y se encontro '%s'", t[i].txt); return; }
    int ins = buscar_instruccion(t[i].txt);
    if (ins < 0) { error(nl, "instruccion desconocida '%s'", t[i].txt); return; }
    LineaCodigo lc = {ins, 0, {0, 0}, {NULL, NULL}, nl};
    int espera_operando = 1;
    for (i++; i < n; i++) {
        if (t[i].tipo == T_COMA) {
            if (espera_operando) { error(nl, "falta un operando antes de la coma%s", ""); return; }
            espera_operando = 1;
            continue;
        }
        if (!espera_operando) { error(nl, "falta una coma antes de '%s'", t[i].txt); return; }
        if (lc.n == 2) { error(nl, "%s tiene demasiados operandos", REPERTORIO[ins].nombre); return; }
        lc.tipo[lc.n] = t[i].tipo;
        lc.txt[lc.n++] = strdup(t[i].txt);
        espera_operando = 0;
    }
    if (n_cod == MAX_COD) { error(nl, "programa demasiado grande%s", ""); return; }
    codigo[n_cod++] = lc;
}

/* ------------------------------ SEGUNDA PASADA -------------------------- */
static int registro(LineaCodigo *lc, int k)
{
    if (lc->tipo[k] != T_REG || atoi(lc->txt[k] + 1) > 7) {
        error(lc->linea, "'%s' no es un registro valido (R0-R7)", lc->txt[k]);
        return 0;
    }
    return atoi(lc->txt[k] + 1);
}

/* operando de direccion: numero, constante, etiqueta (se reubica) o externo */
static uint32_t direccion(LineaCodigo *lc, int k, uint32_t donde)
{
    const char *s = lc->txt[k];
    if (lc->tipo[k] == T_ENTERO) return valor_entero(s, lc->linea) & MASCARA32;
    if (lc->tipo[k] != T_ID) { error(lc->linea, "'%s' no es una direccion", s); return 0; }
    Simbolo *sim = buscar(s);
    if (!sim) { error(lc->linea, "simbolo no definido '%s'", s); return 0; }
    switch (sim->clase) {
    case S_CONSTANTE: return sim->valor & MASCARA32;
    case S_EXTERNO:   externas[n_ext].simbolo = sim->nombre; externas[n_ext++].dir = donde; return 0;
    default:          reubicables[n_reub++] = donde; return sim->valor & MASCARA32;
    }
}

static uint32_t inmediato(LineaCodigo *lc, int k)
{
    const char *s = lc->txt[k];
    if (lc->tipo[k] == T_ENTERO) return valor_entero(s, lc->linea) & MASCARA32;
    Simbolo *sim = (lc->tipo[k] == T_ID) ? buscar(s) : NULL;
    if (sim && sim->clase == S_CONSTANTE) return sim->valor & MASCARA32;
    error(lc->linea, "un inmediato debe ser un numero o una constante .equ "
          "(para la direccion de '%s' use Lea)", s);
    return 0;
}

static uint64_t codificar(LineaCodigo *lc, uint32_t donde)
{
    const Instruccion *in = &REPERTORIO[lc->ins];
    int f = in->formato, b = BITS_INDICE[f];
    uint64_t w = ((uint64_t)(((f - 1) << b) | in->indice)) << (64 - (3 + b));
    int esperados = operandos_de(lc->ins);
    if (lc->n != esperados) {
        char msg[80];
        snprintf(msg, sizeof msg, "%s espera %d operando(s)", in->nombre, esperados);
        error(lc->linea, "%s", msg);
        return w;
    }
    switch (f) {
    case 2: w |= (uint64_t)registro(lc, 0) << 32 | direccion(lc, 1, donde); break;
    case 3: w |= (uint64_t)registro(lc, 0) << 32 | inmediato(lc, 1);        break;
    case 4: w |= direccion(lc, 0, donde);                                   break;
    case 5: w |= (uint64_t)registro(lc, 0) << 3;
            if (esperados == 2) w |= registro(lc, 1);                       break;
    }
    return w;
}

static int comparar_dir(const void *a, const void *b)
{
    uint32_t x = *(const uint32_t *)a, y = *(const uint32_t *)b;
    return (x > y) - (x < y);
}

static void segunda_pasada(void)
{
    /* las direcciones de los datos empiezan donde termina el codigo */
    for (int i = 0; i < n_sim; i++)
        if (tabla[i].clase == S_DATO) tabla[i].valor += n_cod;
    for (int i = 0; i < n_glob; i++) {
        Simbolo *s = buscar(globales[i]);
        if (!s || s->clase == S_EXTERNO)
            error(glob_linea[i], ".global '%s': el simbolo no esta definido en este modulo", globales[i]);
        else if (s->clase == S_CONSTANTE)
            error(glob_linea[i], ".global '%s': solo se exportan etiquetas", globales[i]);
        else s->global = 1;
    }
    for (int i = 0; i < n_cod; i++)
        palabras[i] = codificar(&codigo[i], i);
    for (int i = 0; i < n_dat; i++) {
        uint32_t donde = n_cod + i;
        Dato *d = &datos[i];
        palabras[donde] = d->valor;
        if (!d->es_simbolo) continue;
        Simbolo *s = buscar(d->simbolo);
        if (!s) { error(d->linea, "simbolo no definido '%s'", d->simbolo); continue; }
        if (s->clase == S_CONSTANTE) palabras[donde] = s->valor;
        else if (s->clase == S_EXTERNO) { externas[n_ext].simbolo = s->nombre; externas[n_ext++].dir = donde; palabras[donde] = 0; }
        else { palabras[donde] = s->valor & MASCARA32; reubicables[n_reub++] = donde; }
    }
    qsort(reubicables, n_reub, sizeof reubicables[0], comparar_dir);
}

static void escribir_objeto(FILE *f, const char *nombre)
{
    fprintf(f, "H %s %d\n", nombre, n_cod + n_dat);
    for (int i = 0; i < n_sim; i++)
        if (tabla[i].global) fprintf(f, "D %s %08X\n", tabla[i].nombre, (unsigned)tabla[i].valor);
    for (int i = 0; i < n_cod + n_dat; i++)
        fprintf(f, "T %08X %016llX\n", i, (unsigned long long)palabras[i]);
    for (int i = 0; i < n_reub; i++)
        fprintf(f, "M %08X\n", reubicables[i]);
    for (int i = 0; i < n_ext; i++)
        fprintf(f, "R %s %08X\n", externas[i].simbolo, externas[i].dir);
    fprintf(f, "E %08X\n", 0);
}

static void mostrar_tabla(void)
{
    fprintf(stderr, "\n%-24s %-10s %-18s %s\n", "SIMBOLO", "CLASE", "VALOR", "LINEA");
    for (int i = 0; i < n_sim; i++)
        fprintf(stderr, "%-24s %-10s %016llX   %d%s\n", tabla[i].nombre,
                NOMBRE_CLASE[tabla[i].clase], (unsigned long long)tabla[i].valor,
                tabla[i].linea, tabla[i].global ? "  (global)" : "");
}

int main(int argc, char **argv)
{
    if (argc < 3) {
        fprintf(stderr, "uso: %s entrada.asm salida.obj [-s]\n", argv[0]);
        return 2;
    }
    if (!(yyin = fopen(argv[1], "r"))) { perror(argv[1]); return 2; }

    /* primera pasada: Flex entrega los tokens de cada linea */
    Token linea_tok[64];
    int n = 0, tok;
    do {
        tok = yylex();
        if (tok == T_NL || tok == T_FIN) {
            procesar_linea(linea_tok, n, linea);
            for (int i = 0; i < n; i++) free(linea_tok[i].txt);
            n = 0;
            linea++;
        } else if (n < 64) {
            linea_tok[n].tipo = tok;
            linea_tok[n++].txt = strdup(yytext);
        }
    } while (tok != T_FIN);
    fclose(yyin);

    segunda_pasada();
    if (argc > 3 && !strcmp(argv[3], "-s")) mostrar_tabla();
    if (errores) {
        fprintf(stderr, "%d error(es): no se genero el modulo objeto\n", errores);
        return 1;
    }

    /* nombre del modulo = nombre del archivo de salida sin carpeta ni extension */
    char nombre[256];
    const char *base = strrchr(argv[2], '/');
    snprintf(nombre, sizeof nombre, "%s", base ? base + 1 : argv[2]);
    nombre[strcspn(nombre, ".")] = '\0';

    FILE *f = fopen(argv[2], "w");
    if (!f) { perror(argv[2]); return 2; }
    escribir_objeto(f, nombre);
    fclose(f);
    int globales_exp = 0;
    for (int i = 0; i < n_sim; i++) globales_exp += tabla[i].global;
    fprintf(stderr, "%s: %d palabras de codigo, %d de datos, %d reubicables, "
            "%d exportados, %d referencias externas\n",
            nombre, n_cod, n_dat, n_reub, globales_exp, n_ext);
    return 0;
}
