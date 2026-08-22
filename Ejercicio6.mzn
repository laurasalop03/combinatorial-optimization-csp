/*
Este problema de asignación se ha modelado estructurando las variables en torno a dos 
conceptos clave: los Tribunales y los TFGs.

1. Estructura de Tribunales: Se definen 3 tribunales. Para garantizar la regla de los 
   departamentos, se usan tres variables por tribunal acotadas estrictamente a los 
   profesores de cada área (DECSAI, LSI, ICAR). Cada tribunal tiene asociado un único 
   Día y una única Sesión, cruzando estos datos con matrices booleanas de disponibilidad.

2. Carga de trabajo: Sabiendo que hay 12 TFGs y 3 tribunales que deben evaluar entre 
   4 y 6 trabajos, se deduce que cada tribunal evalua exactamente 4 TFGs.

3. Incompatibilidades (Indexación Anidada): Para evitar que un director evalúe a su 
   alumno, uso la variable de asignación del TFG como índice para acceder al profesor 
   de ese tribunal (ej. prof_decsai[asignacion_tfg[i]]) y fuerzo a que sea distinto del 
   director. Esto evita bucles y optimiza el modelo.

4. Ruptura de Simetrías: Dado que los "números" de los tribunales (1, 2, 3) son 
   etiquetas intercambiables, el solver generaba permutaciones repetidas de la misma 
   solución. He roto esta simetría forzando un orden cronológico en los días de los 
   tribunales, reduciendo el espacio de búsqueda y aislando las soluciones únicas reales.
*/

include "globals.mzn";


% Definición de variables y constantes

% Enums para profesores, dias y sesion para poder usarlos como índices
enum Profesores = {P1, P2, P3, P4, P5, P6, P7, P8, P9, P10};
enum Dias = {Lunes, Martes, Miercoles, Jueves, Viernes};
enum Sesiones = {Manana, Tarde};

% Matrices booleanas para saber quién puede qué día y qué sesión
% Disponibilidad de días (Lunes, Martes, Miercoles, Jueves, Viernes)
array[Profesores, Dias] of bool: disp_dias = [|
  false, true,  false, false, false | % P1: solo martes
  true,  false, true,  false, true  | % P2: L, X, V
  true,  false, true,  false, false | % P3: L, X
  false, false, true,  true,  false | % P4: X, J
  true,  false, false, true,  false | % P5: L, J
  true,  true,  true,  true,  true  | % P6: todos
  false, false, false, false, true  | % P7: V
  false, false, true,  true,  false | % P8: X, J
  false, false, false, true,  false | % P9: J
  true,  true,  false, false, true  |]; % P10: L, M, V

% Disponibilidad de sesiones (Manana, Tarde)
array[Profesores, Sesiones] of bool: disp_sesiones = [|
  true,  false | % P1: solo mañana
  false, true  | % P2: solo tarde
  true,  true  | % P3: sin restricción
  false, true  | % P4: solo tarde
  true,  false | % P5: solo mañana
  false, true  | % P6: solo tarde
  true,  true  | % P7: sin restricción
  true,  false | % P8: solo mañana
  true,  true  | % P9: sin restricción
  true,  true  |]; % P10: sin restricción

% Cada tribunal está compuesto de 3 profesores
set of int: TRIBUNALES = 1..3;

% Variables que guardarán los días y sesiones de cada tribunal
array[TRIBUNALES] of var Dias: dia_tribunal;
array[TRIBUNALES] of var Sesiones: sesion_tribunal;

% Subdividimos los profesores por departamento para forzar que haya 1 de cada
array[TRIBUNALES] of var {P1, P2, P3, P4}: prof_decsai;
array[TRIBUNALES] of var {P5, P6, P7}: prof_lsi;
array[TRIBUNALES] of var {P8, P9, P10}: prof_icar;

% Hay 12 TFGs
set of int: TFGS = 1..12;

% Variable que guardará el tribunal asignado a cada tfg
array[TFGS] of var TRIBUNALES: asignacion_tfg;


% Definición de restricciones

% Cada profesor de un tribunal tiene que ser de un departamente diferente.
constraint all_different(prof_decsai);
constraint all_different(prof_lsi);
% El profesor 10 puede estar en 2 tribunales
constraint all_different_except(prof_icar, {P10}); 
constraint count(prof_icar, P10) <= 2;


% 12 TFGs, 3 tribunales y cada uno evalua entre 4 y 6 -> todos evalúan 4 exactamente.
constraint forall(t in TRIBUNALES)(count(asignacion_tfg, t) == 4);


% Los profesores elegidos tiene que estar disponibles en el día y sesión de su tribunal.
constraint forall(t in TRIBUNALES)(
    disp_dias[prof_decsai[t], dia_tribunal[t]] == true /\
    disp_sesiones[prof_decsai[t], sesion_tribunal[t]] == true /\
    
    disp_dias[prof_lsi[t], dia_tribunal[t]] == true /\
    disp_sesiones[prof_lsi[t], sesion_tribunal[t]] == true /\
    
    disp_dias[prof_icar[t], dia_tribunal[t]] == true /\
    disp_sesiones[prof_icar[t], sesion_tribunal[t]] == true
);


% Un profesor que haya supervisado/dirigido un TFG no puede formar parte del tribunal que lo evalúe.
% Como asignacion_tfg[i] nos da el número del tribunal que evalúa el TFG i, podemos usar ese número como
% índice para saber qué profesor está en ese tribunal.

% El profesor 2 ha dirigido los TFGs 1 y 10.
constraint prof_decsai[asignacion_tfg[1]] != P2;
constraint prof_decsai[asignacion_tfg[10]] != P2;

% El profesor 3 ha dirigido el TFG 8.
constraint prof_decsai[asignacion_tfg[8]] != P3;

% El profesor 3 ha codirigido el TFG 7 con el profesor 8.
constraint prof_decsai[asignacion_tfg[7]] != P3;
constraint prof_icar[asignacion_tfg[7]] != P8;

% El profesor 4 ha dirigido el TFG 6 y 12.
constraint prof_decsai[asignacion_tfg[6]] != P4;
constraint prof_decsai[asignacion_tfg[12]] != P4;

% El profesor 4 ha codirigido el TFG 4 con el profesor 8.
constraint prof_decsai[asignacion_tfg[4]] != P4;
constraint prof_icar[asignacion_tfg[4]] != P8;

% El profesor 5 ha dirigido el TFG 2.
constraint prof_lsi[asignacion_tfg[2]] != P5;

% El profesor 6 ha codirigido con el profesor 7 el TFG 3 y el 5.
constraint prof_lsi[asignacion_tfg[3]] != P6;
constraint prof_lsi[asignacion_tfg[3]] != P7;
constraint prof_lsi[asignacion_tfg[5]] != P6;
constraint prof_lsi[asignacion_tfg[5]] != P7;

% El profesor 10 ha codirigido con el profesor 1 el TFG 9 y el 11.
constraint prof_decsai[asignacion_tfg[9]] != P1;
constraint prof_icar[asignacion_tfg[9]] != P10;
constraint prof_decsai[asignacion_tfg[11]] != P1;
constraint prof_icar[asignacion_tfg[11]] != P10;


% TFGs 6 y 12 tienen temática similar -> mismo tribunal
constraint asignacion_tfg[6] == asignacion_tfg[12];

% TFGs 1 y 10 tienen temática similar -> mismo tribunal
constraint asignacion_tfg[1] == asignacion_tfg[10];


% Un mismo profesor no puede tener dos tribunales el mismo día.
% Uso t1 < t2 para romper simetría.
% Las condiciones en prof_decsai y prof_lsi son redundantes, pues ya hemos
% puesto un all_different, pero no pasa nada por añadirlas.
constraint forall(t1, t2 in TRIBUNALES where t1 < t2)(
    (dia_tribunal[t1] == dia_tribunal[t2]) -> (
        prof_decsai[t1] != prof_decsai[t2] /\
        prof_lsi[t1] != prof_lsi[t2] /\
        prof_icar[t1] != prof_icar[t2]
    )
);


% Romper las simetrías

% Los números de los tribunales (1, 2, 3) son intercambiables. 
% Para evitar que se permuten los tribunales, forzamos a que el Tribunal 1 sea 
% cronológicamente anterior o igual al 2, y el 2 al 3.
constraint dia_tribunal[1] <= dia_tribunal[2];
constraint dia_tribunal[2] <= dia_tribunal[3];


% Definición del problema
solve satisfy;


% Definición del output
output [
    "Tribunal \(t): " ++
    "\(fix(prof_decsai[t]))(\"DECSAI\"), " ++
    "\(fix(prof_lsi[t]))(\"LSI\"), " ++
    "\(fix(prof_icar[t]))(\"ICAR\") " ++
    "(Día: \(dia_tribunal[t]), Sesion: \(sesion_tribunal[t]))\n" ++
    "TFGs a evaluar: " ++ join(", ", [ "\(i)" | i in TFGS where fix(asignacion_tfg[i]) == t ]) ++ "\n"
    | t in TRIBUNALES
];


