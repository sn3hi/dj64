/* =====================================================================
 * enlazador.l - ENLAZADOR-CARGADOR del DJ-64 (Hunza DJ Systems) en FLEX.
 * Taller 01 - Lenguajes de programacion (2025966) - Grupo 2 2026-2
 *
 * Flex reconoce los registros de los modulos objeto que produce el
 * ensamblador:
 *     H nombre tamano   D simbolo dir   T dir palabra
 *     M dir             R simbolo dir   E entrada
 *
 * ENLAZADOR (une varios modulos en uno solo):
 *   1a pasada: lee cada modulo, le asigna una base (el primero en 0, el
 *              siguiente donde termina el anterior...) y arma la tabla de
 *              simbolos globales con los registros D (direccion = base + dir).
 *   2a pasada: copia las palabras en su nueva posicion (base + dir).
 *              Cada registro M suma la base del modulo; cada registro R
 *              suma la direccion del simbolo externo. Las dos clases de
 *              palabras quedan con una direccion relativa al modulo
 *              enlazado, asi que ambas se escriben como registros M.
 *   Resultado: un modulo H/T/M/E sin referencias externas.
 *
 * CARGADOR:
 *     LAD = direccion de carga
 *     cada T:  RAM[LAD + dir] = palabra
 *     cada M:  RAM[LAD + dir] = RAM[LAD + dir] + LAD   (campo de direccion)
 *     E:       CP = LAD + entrada
 *   Resultado: la imagen absoluta en memoria, como archivo .hex
 *   ("DIRECCION PALABRA" por linea), que el emulador carga y ejecuta.
 *
 * Uso:  ./enlazador -o enlazado.obj [-l LAD -x imagen.hex] a.obj b.obj ...
 *       (el punto de entrada es el del primer modulo; LAD en hexadecimal)
 * ===================================================================== */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#define MAX_MODULOS  32
#define MAX_PALABRAS 65536
#define MAX_REG      65536
#define MAX_GLOBALES 2000
#define MASCARA32    0xFFFFFFFFULL

typedef struct { char simbolo[64]; uint32_t dir; } Ref;

typedef struct {
    char archivo[256], nombre[64];
    int tamano, n_t, tiene_h, tiene_e;
    uint32_t base, entrada;
    uint64_t *palabra;          /* palabras del modulo (indice = dir relativa) */
    char *definida;             /* 1 si la palabra vino en un registro T */
    uint32_t *m;   int n_m;     /* registros M */
    Ref *r;        int n_r;     /* registros R (referencias externas) */
    Ref *d;        int n_d;     /* registros D (definiciones globales) */
} Modulo;

static Modulo mod[MAX_MODULOS];
static int n_mod = 0, linea = 1, errores = 0;
static Modulo *actual;

/* tabla de simbolos globales (ESTAB): nombre -> direccion en el enlazado */
static struct { char simbolo[64]; uint32_t dir; int modulo; } globales[MAX_GLOBALES];
static int n_glob = 0;

static void error(const char *fmt, const char *a, const char *b)
{
    fprintf(stderr, "error: ");
    fprintf(stderr, fmt, a, b);
    fputc('\n', stderr);
    errores++;
}

static void error_linea(const char *msg)
{
    char donde[300];
    snprintf(donde, sizeof donde, "%s:%d", actual->archivo, linea);
    error("%s: %s", donde, msg);
}

static void registro_h(void);
static void registro_t(void);
static void registro_m(void);
static void registro_dr(int es_d);
static void registro_e(void);
%}

%option noyywrap nounput noinput

HEX     [0-9A-Fa-f]+
NUM     [0-9]+
NOMBRE  [A-Za-z_][A-Za-z0-9_]*
SEP     [ \t]+

%%
^H{SEP}{NOMBRE}{SEP}{NUM}[ \t]*     { registro_h(); }
^D{SEP}{NOMBRE}{SEP}{HEX}[ \t]*     { registro_dr(1); }
^T{SEP}{HEX}{SEP}{HEX}[ \t]*        { registro_t(); }
^M{SEP}{HEX}[ \t]*                  { registro_m(); }
^R{SEP}{NOMBRE}{SEP}{HEX}[ \t]*     { registro_dr(0); }
^E{SEP}{HEX}[ \t]*                  { registro_e(); }
";"[^\n]*                           { /* comentario */ }
\n                                  { linea++; }
[ \t\r]+                            { /* espacios */ }
[^\n]+                              { error_linea("registro mal formado"); }
%%

/* --------------------- acciones de los registros ---------------------- */
static int dentro(uint32_t dir)
{
    if (!actual->tiene_h) { error_linea("registro antes del encabezado H"); return 0; }
    if (dir >= (uint32_t)actual->tamano) { error_linea("direccion fuera del modulo"); return 0; }
    return 1;
}

static void registro_h(void)
{
    if (actual->tiene_h) { error_linea("hay dos encabezados H"); return; }
    sscanf(yytext + 1, "%63s %d", actual->nombre, &actual->tamano);
    if (actual->tamano <= 0 || actual->tamano > MAX_PALABRAS) {
        error_linea("tamano de modulo no valido");
        actual->tamano = 0;
    }
    actual->tiene_h = 1;
    actual->palabra  = calloc(actual->tamano + 1, sizeof(uint64_t));
    actual->definida = calloc(actual->tamano + 1, 1);
    actual->m = malloc(MAX_REG * sizeof(uint32_t));
    actual->r = malloc(MAX_REG * sizeof(Ref));
    actual->d = malloc(MAX_GLOBALES * sizeof(Ref));
}

static void registro_t(void)
{
    unsigned dir;
    unsigned long long w;
    sscanf(yytext + 1, "%x %llx", &dir, &w);
    if (!dentro(dir)) return;
    if (actual->definida[dir]) { error_linea("la palabra se define dos veces"); return; }
    actual->palabra[dir] = w;
    actual->definida[dir] = 1;
    actual->n_t++;
}

static void registro_m(void)
{
    unsigned dir;
    sscanf(yytext + 1, "%x", &dir);
    if (dentro(dir) && actual->n_m < MAX_REG) actual->m[actual->n_m++] = dir;
}

static void registro_dr(int es_d)
{
    Ref x;
    unsigned dir;
    sscanf(yytext + 1, "%63s %x", x.simbolo, &dir);
    x.dir = dir;
    if (!dentro(dir)) return;
    if (es_d && actual->n_d < MAX_GLOBALES) actual->d[actual->n_d++] = x;
    if (!es_d && actual->n_r < MAX_REG)     actual->r[actual->n_r++] = x;
}

static void registro_e(void)
{
    unsigned e;
    sscanf(yytext + 1, "%x", &e);
    actual->entrada = e;
    actual->tiene_e = 1;
}

/* ----------------------------- enlazador ------------------------------ */
static int buscar_global(const char *s)
{
    for (int i = 0; i < n_glob; i++)
        if (strcmp(globales[i].simbolo, s) == 0) return i;
    return -1;
}

static uint64_t imagen[MAX_PALABRAS];          /* modulo enlazado */
static uint32_t reubicar[MAX_REG];             /* sus registros M */
static int total = 0, n_reub = 0;

static void primera_pasada(void)
{
    uint32_t base = 0;
    for (int k = 0; k < n_mod; k++) {
        Modulo *md = &mod[k];
        md->base = base;
        base += md->tamano;
        for (int i = 0; i < md->n_d; i++) {
            int g = buscar_global(md->d[i].simbolo);
            if (g >= 0) {
                error("el simbolo global '%s' esta definido en dos modulos (%s)",
                      md->d[i].simbolo, md->archivo);
                continue;
            }
            snprintf(globales[n_glob].simbolo, 64, "%s", md->d[i].simbolo);
            globales[n_glob].dir = md->base + md->d[i].dir;
            globales[n_glob++].modulo = k;
        }
    }
    total = base;
    if (total > MAX_PALABRAS) error("el programa enlazado es demasiado grande%s%s", "", "");
}

static void sumar_al_campo(uint32_t donde, uint32_t cuanto)   /* campo de direccion = 32 bits bajos */
{
    uint64_t w = imagen[donde];
    imagen[donde] = (w & ~MASCARA32) | ((w + cuanto) & MASCARA32);
}

static int comparar_dir(const void *a, const void *b)
{
    uint32_t x = *(const uint32_t *)a, y = *(const uint32_t *)b;
    return (x > y) - (x < y);
}

static void segunda_pasada(void)
{
    for (int k = 0; k < n_mod; k++) {
        Modulo *md = &mod[k];
        for (int i = 0; i < md->tamano; i++)
            imagen[md->base + i] = md->palabra[i];
        for (int i = 0; i < md->n_m; i++) {          /* direccion interna del modulo */
            sumar_al_campo(md->base + md->m[i], md->base);
            reubicar[n_reub++] = md->base + md->m[i];
        }
        for (int i = 0; i < md->n_r; i++) {          /* referencia a otro modulo */
            int g = buscar_global(md->r[i].simbolo);
            if (g < 0) {
                error("referencia externa no resuelta: '%s' (usada en %s)", md->r[i].simbolo, md->archivo);
                continue;
            }
            sumar_al_campo(md->base + md->r[i].dir, globales[g].dir);
            reubicar[n_reub++] = md->base + md->r[i].dir;
        }
    }
    qsort(reubicar, n_reub, sizeof reubicar[0], comparar_dir);
}

static void escribir_enlazado(const char *ruta)
{
    char nombre[256];
    const char *b = strrchr(ruta, '/');
    snprintf(nombre, sizeof nombre, "%s", b ? b + 1 : ruta);
    nombre[strcspn(nombre, ".")] = '\0';
    FILE *f = fopen(ruta, "w");
    if (!f) { perror(ruta); exit(2); }
    fprintf(f, "H %s %d\n", nombre, total);
    for (int i = 0; i < total; i++)
        fprintf(f, "T %08X %016llX\n", i, (unsigned long long)imagen[i]);
    for (int i = 0; i < n_reub; i++)
        fprintf(f, "M %08X\n", reubicar[i]);
    fprintf(f, "E %08X\n", mod[0].base + mod[0].entrada);
    fclose(f);
}

/* ------------------------------ cargador ------------------------------ */
static void cargar(uint32_t LAD, const char *ruta)
{
    static uint64_t ram[MAX_PALABRAS];               /* memoria a partir de LAD */
    for (int i = 0; i < total; i++)                  /* registros T */
        ram[i] = imagen[i];
    for (int i = 0; i < n_reub; i++) {               /* registros M: + LAD */
        uint64_t w = ram[reubicar[i]];
        ram[reubicar[i]] = (w & ~MASCARA32) | ((w + LAD) & MASCARA32);
    }
    uint32_t CP = LAD + mod[0].base + mod[0].entrada; /* registro E */
    FILE *f = fopen(ruta, "w");
    if (!f) { perror(ruta); exit(2); }
    fprintf(f, "; imagen cargada en LAD = %08X, %d palabras\n", LAD, total);
    fprintf(f, "; CP %08X\n", CP);
    for (int i = 0; i < total; i++)
        fprintf(f, "%08X  %016llX\n", LAD + i, (unsigned long long)ram[i]);
    fclose(f);
    printf("Cargador: LAD = %08X, CP = %08X, imagen en %s\n", LAD, CP, ruta);
}

int main(int argc, char **argv)
{
    const char *salida = NULL, *hex = NULL;
    long LAD = -1;
    int op;
    while ((op = getopt(argc, argv, "o:l:x:")) != -1) {
        if (op == 'o') salida = optarg;
        else if (op == 'l') LAD = strtol(optarg, NULL, 16);
        else if (op == 'x') hex = optarg;
        else return 2;
    }
    if (!salida || optind == argc || (hex && LAD < 0)) {
        fprintf(stderr, "uso: %s -o enlazado.obj [-l LAD -x imagen.hex] a.obj b.obj ...\n", argv[0]);
        return 2;
    }

    /* lectura de los modulos: Flex reconoce cada registro */
    for (int i = optind; i < argc && n_mod < MAX_MODULOS; i++) {
        actual = &mod[n_mod++];
        snprintf(actual->archivo, sizeof actual->archivo, "%s", argv[i]);
        if (!(yyin = fopen(argv[i], "r"))) { perror(argv[i]); return 2; }
        linea = 1;
        yyrestart(yyin);
        yylex();
        fclose(yyin);
        if (!actual->tiene_h) { error("%s: falta el encabezado H%s", argv[i], ""); return 1; }
        if (!actual->tiene_e) error("%s: falta el registro E (fin de modulo)%s", argv[i], "");
        if (actual->n_t != actual->tamano) {
            char msg[100];
            snprintf(msg, sizeof msg, "el encabezado dice %d palabras y hay %d registros T",
                     actual->tamano, actual->n_t);
            error("%s: %s", argv[i], msg);
        }
    }
    if (errores) { fprintf(stderr, "%d error(es) al leer los modulos\n", errores); return 1; }

    primera_pasada();
    if (!errores) segunda_pasada();
    if (errores) { fprintf(stderr, "%d error(es): no se genero el programa enlazado\n", errores); return 1; }

    /* mapa de enlace */
    printf("Enlazador: %d modulo(s), %d palabras\n", n_mod, total);
    printf("  %-14s %-10s %-8s %s\n", "MODULO", "BASE", "TAMANO", "ARCHIVO");
    for (int k = 0; k < n_mod; k++)
        printf("  %-14s %08X   %-8d %s\n", mod[k].nombre, mod[k].base, mod[k].tamano, mod[k].archivo);
    printf("  %d simbolos globales, %d palabras para reubicar al cargar\n", n_glob, n_reub);
    escribir_enlazado(salida);
    printf("  modulo enlazado en %s\n", salida);
    if (hex) cargar((uint32_t)LAD, hex);
    return 0;
}
