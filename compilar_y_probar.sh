#!/bin/bash
# Compila los cuatro modulos del SPL del DJ-64 (Taller 01) y ejecuta los
# escenarios de prueba documentados en el Archivo 02 (Experimentacion):
#   1. Preprocesador:   #include anidado y #define; inclusion circular; errores.
#   2. Ensamblador:     7 programas de las Tareas 10 y 17, comparados palabra
#                       por palabra con el ensamblador de Python; errores.
#   3. Enlazador-cargador: raiz y brun enlazados con la FPU (fpu.obj), cargados
#                       en dos LAD distintas y ejecutados en el emulador;
#                       errores de enlace y modulo objeto mal formado.
#   4. Analizador lexico: tres programas DJL y un programa con errores.
#   5. SPL completo:    preprocesar -> ensamblar -> enlazar -> cargar -> correr.
# Uso: ./compilar_y_probar.sh   (desde la carpeta codigo/)
cd "$(dirname "$0")" || exit 1
PY=${PY:-python3}
S=salidas
mkdir -p $S
fallos=0
titulo() { echo; echo "########## $1"; }
ok()     { if [ "$1" -eq 0 ]; then echo "---------- OK"; else echo "---------- FALLA"; fallos=$((fallos + 1)); fi; }
espera_error() { if [ "$1" -ne 0 ]; then echo "---------- OK (se detecto el error, codigo de salida $1)"; else echo "---------- FALLA (no se detecto el error)"; fallos=$((fallos + 1)); fi; }

echo "== Compilando los modulos con flex y gcc"
for m in preprocesador ensamblador enlazador lexico; do
	flex -o $m.yy.c $m.l || exit 1
	gcc -Wall -Wextra -O2 $m.yy.c -o $m || exit 1
	echo "   $m.l -> ./$m"
done

# ---------------------------------------------------------------- 1
titulo "1a. Preprocesador: heron.djl (#include de matematicas.djl y #define)"
./preprocesador pruebas/djl/heron.djl $S/heron.pp.djl; ok $?
head -12 $S/heron.pp.djl

titulo "1b. Preprocesador: inclusion circular (ciclo_a.djl -> ciclo_b.djl -> ciclo_a.djl)"
./preprocesador pruebas/preprocesador/ciclo_a.djl $S/ciclo_a.pp.djl; espera_error $?

titulo "1c. Preprocesador: archivo inexistente, directiva desconocida y redefinicion"
./preprocesador pruebas/preprocesador/errores.djl $S/errores.pp.djl; espera_error $?
cat $S/errores.pp.djl

# ---------------------------------------------------------------- 2
titulo "2a. Ensamblador: programas de las Tareas 10 y 11"
for p in fibonacci busqueda factorial perifericos raiz brun fpu raiz_mod brun_mod; do
	./preprocesador programas/$p.asm $S/$p.pp.asm 2>/dev/null &&
	./ensamblador $S/$p.pp.asm $S/$p.obj || fallos=$((fallos + 1))
done

titulo "2b. Ensamblador: comparacion con el ensamblador de la Tarea 10 (Python)"
$PY verificar.py ensamblador fibonacci busqueda factorial perifericos raiz brun fpu; ok $?

titulo "2c. Ensamblador: programa con errores (pruebas/asm/errores.asm)"
./ensamblador pruebas/asm/errores.asm $S/errores.obj; espera_error $?

# ---------------------------------------------------------------- 3
titulo "3a. Enlazador-cargador: raiz_mod.obj + fpu.obj, LAD = 1000"
./enlazador -o $S/raiz_enlazado.obj -l 1000 -x $S/raiz_1000.hex $S/raiz_mod.obj $S/fpu.obj; ok $?
$PY verificar.py cargador $S/raiz_enlazado.obj $S/raiz_1000.hex 1000 || fallos=$((fallos + 1))
echo "---------- pantalla del DJ-64"
$PY correr_dj64.py $S/raiz_1000.hex | tee $S/raiz_1000.txt

titulo "3b. El mismo programa cargado en LAD = 5000"
./enlazador -o $S/raiz_enlazado.obj -l 5000 -x $S/raiz_5000.hex $S/raiz_mod.obj $S/fpu.obj > /dev/null
$PY verificar.py cargador $S/raiz_enlazado.obj $S/raiz_5000.hex 5000 || fallos=$((fallos + 1))
$PY correr_dj64.py $S/raiz_5000.hex > $S/raiz_5000.txt
if diff -q $S/raiz_1000.txt $S/raiz_5000.txt > /dev/null; then echo "---------- misma pantalla que con LAD = 1000: OK"; else echo "---------- FALLA"; fallos=$((fallos + 1)); fi

titulo "3c. Enlazador-cargador: brun_mod.obj (LIMITE = 10000) + fpu.obj, LAD = 1000"
./enlazador -o $S/brun_enlazado.obj -l 1000 -x $S/brun_1000.hex $S/brun_mod.obj $S/fpu.obj; ok $?
$PY verificar.py cargador $S/brun_enlazado.obj $S/brun_1000.hex 1000 || fallos=$((fallos + 1))
echo "---------- pantalla del DJ-64"
$PY correr_dj64.py $S/brun_1000.hex | tee $S/brun_1000.txt

titulo "3d. Enlazador: referencias externas sin resolver (raiz_mod.obj solo)"
./enlazador -o $S/x.obj $S/raiz_mod.obj 2> $S/enlace_errores.txt; rc=$?
head -4 $S/enlace_errores.txt; echo "   ... ($(wc -l < $S/enlace_errores.txt) lineas de error en total)"
espera_error $rc

titulo "3e. Enlazador: simbolo global definido dos veces (fpu.obj + fpu.obj)"
./enlazador -o $S/x.obj $S/raiz_mod.obj $S/fpu.obj $S/fpu.obj 2> $S/enlace_errores.txt; rc=$?
head -3 $S/enlace_errores.txt; echo "   ... ($(wc -l < $S/enlace_errores.txt) lineas de error en total)"
espera_error $rc

titulo "3f. Enlazador: modulo objeto mal formado (pruebas/obj/malo.obj)"
./enlazador -o $S/x.obj pruebas/obj/malo.obj; espera_error $?
rm -f $S/x.obj

# ---------------------------------------------------------------- 4
for p in heron matrices estudiantes; do
	titulo "4. Analizador lexico: $p.djl (preprocesado)"
	./preprocesador pruebas/djl/$p.djl $S/$p.pp.djl 2>/dev/null
	./lexico $S/$p.pp.djl $S/$p.tok > $S/$p.lex; ok $?
	sed -n 3,12p $S/$p.lex; echo "  ..."; tail -14 $S/$p.lex
done

titulo "4d. Analizador lexico: programa con errores (pruebas/djl/errores.djl)"
./lexico pruebas/djl/errores.djl > $S/errores.lex 2>/dev/null; espera_error $?
grep "ERROR  " $S/errores.lex

# ---------------------------------------------------------------- 5
titulo "5. SPL completo: raiz.asm (#include \"fpu.asm\") -> preprocesador -> ensamblador -> enlazador-cargador -> DJ-64"
./preprocesador programas/raiz.asm $S/raiz.pp.asm &&
./ensamblador $S/raiz.pp.asm $S/raiz.obj &&
./enlazador -o $S/raiz_solo.obj -l 1000 -x $S/raiz_solo.hex $S/raiz.obj &&
$PY correr_dj64.py $S/raiz_solo.hex > $S/raiz_solo.txt; ok $?
if diff -q $S/raiz_solo.txt $S/raiz_1000.txt > /dev/null; then
	echo "---------- misma pantalla que con la FPU enlazada como modulo aparte (3a): OK"
else echo "---------- FALLA"; fallos=$((fallos + 1)); fi

echo
echo "== Pruebas que fallaron: $fallos"
[ "$fallos" -eq 0 ]
