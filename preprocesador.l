/* =====================================================================
 * preprocesador.l - PREPROCESADOR del sistema de procesamiento de
 * lenguaje (SPL) del DJ-64, escrito en FLEX.
 * Taller 01 - Lenguajes de programacion (2025966) - Grupo 2 2026-2
 *
 * Recibe un archivo fuente (del lenguaje de alto nivel DJL o del
 * ensamblador del DJ-64) y produce el mismo texto con las macros
 * resueltas:
 *
 *   #include "archivo"     se reemplaza por el contenido del archivo,
 *                          que a su vez se preprocesa (inclusiones
 *                          anidadas). La ruta es relativa al archivo
 *                          que hace la inclusion.
 *   #define NOMBRE valor   desde esa linea, cada aparicion del
 *                          identificador NOMBRE se reemplaza por valor.
 *
 * No se reemplaza dentro de cadenas "..." ni de comentarios //.
 * El valor de una macro se expande al definirla, asi que puede usar
 * macros definidas antes (por ejemplo #define DOBLE (N*2)).
 * Errores: archivo que no existe, inclusion circular, demasiada
 * profundidad y directivas desconocidas.
 *
 * Uso:  ./preprocesador entrada [salida]     (sin salida: pantalla)
 * ===================================================================== */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#define MAX_PROFUNDIDAD 16
#define MAX_MACROS      500

/* pila de archivos abiertos: cada #include agrega un nivel */
typedef struct { char ruta[PATH_MAX]; FILE *f; int linea; } Nivel;
static Nivel pila[MAX_PROFUNDIDAD];
static int nivel = -1;

/* tabla de macros (busqueda lineal) */
typedef struct { char *nombre; char *valor; } Macro;
static Macro macros[MAX_MACROS];
static int n_macros = 0;

static FILE *salida;
static int errores = 0, inclusiones = 0, reemplazos = 0;

static void incluir(const char *texto);
static void definir(const char *texto);
static void identificador(const char *id);
static void aviso(const char *tipo, const char *fmt, const char *arg);
static int  abrir(const char *ruta);
static char ultimo = '\n';                    /* ultimo caracter escrito */
static void escribir(const char *s) { if (*s) { fputs(s, salida); ultimo = s[strlen(s) - 1]; } }
%}

%option noyywrap nounput noinput

ID          [A-Za-z_][A-Za-z0-9_]*
ESPACIO     [ \t]

%%
^{ESPACIO}*"#"{ESPACIO}*"include"{ESPACIO}*\"[^"\n]+\"{ESPACIO}*\n?  { incluir(yytext); }
^{ESPACIO}*"#"{ESPACIO}*"define"{ESPACIO}+{ID}[^\n]*\n?             { definir(yytext); }
^{ESPACIO}*"#"[^\n]*\n?    { aviso("error", "directiva desconocida o mal escrita: %s", yytext);
                             if (yytext[yyleng - 1] == '\n') { pila[nivel].linea++; escribir("\n"); } }
\"([^"\\\n]|\\.)*\"        { escribir(yytext); /* cadena: no se toca */ }
"//"[^\n]*                 { escribir(yytext); /* comentario: no se toca */ }
{ID}                       { identificador(yytext); }
\n                         { pila[nivel].linea++; escribir("\n"); }
.                          { escribir(yytext); }

<<EOF>>                    {
                               fclose(pila[nivel].f);
                               nivel--;
                               if (nivel >= 0 && ultimo != '\n') escribir("\n");
                               yypop_buffer_state();
                               if (!YY_CURRENT_BUFFER) yyterminate();
                           }
%%

static void aviso(const char *tipo, const char *fmt, const char *arg)
{
    char msg[PATH_MAX + 200];
    snprintf(msg, sizeof msg, fmt, arg);
    msg[strcspn(msg, "\n")] = '\0';
    fprintf(stderr, "%s:%d: %s: %s\n", pila[nivel].ruta, pila[nivel].linea, tipo, msg);
    if (tipo[0] == 'e') errores++;
}

static Macro *buscar(const char *nombre)
{
    for (int i = 0; i < n_macros; i++)
        if (strcmp(macros[i].nombre, nombre) == 0)
            return &macros[i];
    return NULL;
}

/* identificador del texto: si es una macro se escribe su valor */
static void identificador(const char *id)
{
    Macro *m = buscar(id);
    if (m) { escribir(m->valor); reemplazos++; }
    else   escribir(id);
}

/* reemplaza las macros ya definidas dentro de un texto (valor de un #define) */
static char *expandir(const char *s)
{
    size_t cap = strlen(s) * 2 + 64, n = 0;
    char *r = malloc(cap);
    while (*s) {
        size_t largo = 1;
        const char *pedazo = s;
        if (*s == '"') {                              /* cadena: se copia igual */
            while (s[largo] && s[largo] != '"') largo += (s[largo] == '\\' && s[largo + 1]) ? 2 : 1;
            if (s[largo]) largo++;
        } else if ((*s >= 'A' && *s <= 'Z') || (*s >= 'a' && *s <= 'z') || *s == '_') {
            while ((s[largo] >= 'A' && s[largo] <= 'Z') || (s[largo] >= 'a' && s[largo] <= 'z') ||
                   (s[largo] >= '0' && s[largo] <= '9') || s[largo] == '_') largo++;
            char id[256];
            snprintf(id, sizeof id, "%.*s", (int)largo, s);
            Macro *m = buscar(id);
            if (m) { pedazo = m->valor; s += largo; largo = strlen(m->valor); goto copiar; }
        }
        s += largo;
    copiar:
        if (n + largo + 1 > cap) { cap = (n + largo + 1) * 2; r = realloc(r, cap); }
        memcpy(r + n, pedazo, largo);
        n += largo;
    }
    r[n] = '\0';
    return r;
}

/* #define NOMBRE valor */
static void definir(const char *texto)
{
    int fin_linea = texto[strlen(texto) - 1] == '\n';
    const char *p = strstr(texto, "define") + 6;
    p += strspn(p, " \t");
    size_t largo = strspn(p, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_");
    char nombre[256];
    snprintf(nombre, sizeof nombre, "%.*s", (int)largo, p);
    p += largo;
    p += strspn(p, " \t");

    char valor[4096];                               /* sin el salto de linea, sin // y sin espacios finales */
    snprintf(valor, sizeof valor, "%s", p);
    valor[strcspn(valor, "\n")] = '\0';
    char *com = strstr(valor, "//");
    if (com) *com = '\0';
    for (int k = (int)strlen(valor) - 1; k >= 0 && (valor[k] == ' ' || valor[k] == '\t' || valor[k] == '\r'); k--)
        valor[k] = '\0';

    char *expandido = expandir(valor);
    Macro *m = buscar(nombre);
    if (m) {
        if (strcmp(m->valor, expandido) != 0)
            aviso("aviso", "la macro %s se redefine con otro valor", nombre);
        free(m->valor);
        m->valor = expandido;
    } else if (n_macros == MAX_MACROS) {
        aviso("error", "demasiadas macros (%s)", nombre);
        free(expandido);
    } else {
        macros[n_macros].nombre = strdup(nombre);
        macros[n_macros++].valor = expandido;
    }
    if (fin_linea) { pila[nivel].linea++; escribir("\n"); }   /* conserva la numeracion */
}

/* abre un archivo y lo pone en la cima de la pila; 0 si no se pudo */
static int abrir(const char *ruta)
{
    FILE *f = fopen(ruta, "r");
    if (!f) return 0;
    nivel++;
    snprintf(pila[nivel].ruta, PATH_MAX, "%s", ruta);
    pila[nivel].f = f;
    pila[nivel].linea = 1;
    yypush_buffer_state(yy_create_buffer(f, YY_BUF_SIZE));
    return 1;
}

/* #include "archivo" */
static void incluir(const char *texto)
{
    const char *a = strchr(texto, '"') + 1;
    char nombre[PATH_MAX], ruta[2 * PATH_MAX + 2], real[PATH_MAX];
    snprintf(nombre, sizeof nombre, "%.*s", (int)(strchr(a, '"') - a), a);

    /* la ruta se toma relativa a la carpeta del archivo actual */
    const char *barra = strrchr(pila[nivel].ruta, '/');
    if (nombre[0] == '/' || !barra)
        snprintf(ruta, sizeof ruta, "%s", nombre);
    else
        snprintf(ruta, sizeof ruta, "%.*s/%s", (int)(barra - pila[nivel].ruta), pila[nivel].ruta, nombre);

    int fin_linea = texto[strlen(texto) - 1] == '\n';
    int problema = 1;
    if (!realpath(ruta, real))
        aviso("error", "no se encuentra el archivo \"%s\"", nombre);
    else if (nivel + 1 == MAX_PROFUNDIDAD)
        aviso("error", "demasiados #include anidados (\"%s\")", nombre);
    else {
        problema = 0;
        for (int i = 0; i <= nivel; i++) {           /* inclusion circular */
            char otro[PATH_MAX];
            if (realpath(pila[i].ruta, otro) && strcmp(otro, real) == 0) {
                aviso("error", "inclusion circular de \"%s\"", nombre);
                problema = 1;
                break;
            }
        }
    }
    pila[nivel].linea += fin_linea;
    if (problema) { if (fin_linea) escribir("\n"); return; }
    if (!abrir(ruta)) { aviso("error", "no se puede abrir \"%s\"", nombre); return; }
    inclusiones++;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "uso: %s entrada [salida]\n", argv[0]);
        return 2;
    }
    salida = stdout;
    if (argc > 2 && !(salida = fopen(argv[2], "w"))) { perror(argv[2]); return 2; }
    if (!abrir(argv[1])) { perror(argv[1]); return 2; }
    yylex();
    if (salida != stdout) fclose(salida);
    fprintf(stderr, "preprocesador: %d archivo(s) incluido(s), %d macro(s) definida(s), "
            "%d reemplazo(s), %d error(es)\n", inclusiones, n_macros, reemplazos, errores);
    return errores ? 1 : 0;
}
