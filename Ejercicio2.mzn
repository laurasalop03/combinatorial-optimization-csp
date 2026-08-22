/*
Para resolver este ejercicio he usado Arrays Paralelos, más fácil y eficiente que usar una matriz (mi idea inicial).

1. Estructura de Datos (Arrays Paralelos): Dado que las restricciones temporales son el eje del problema, 
   he utilizado la 'Hora' (representada por el índice POS de 1 a 6) como pivote central. He creado tres 
   arrays (est, proy, aula) que comparten este índice. Así, cada posición temporal contiene exactamente sus 
   tres atributos correspondientes.

2. Reducción del Espacio de Búsqueda: Empleo la restricción global 'all_different' sobre los tres arrays paralelos.
   Esto garantiza que cada alumno, proyecto y aula aparece una única vez, acotando el árbol de búsqueda para el solver.

3. Traducción de Pistas Temporales: Gracias a indexar por el tiempo, las restricciones relativas ("una hora después",
   "inmediatamente antes") se traducen en operaciones aritméticas entre los índices (ej. i - j == 1 o i < j).
*/

include "globals.mzn";


% Definición de variables y constantes

int: N = 6;  % número de alumnos
set of int: POS = 1..N;

% Enums con los datos del problema
enum Estudiantes = {Alba, Bruno, Carla, Diego, Elena, Pablo};
enum Proyectos = {P1, P2, P3, P4, P5, P6};
enum Aulas = {A1, A2, B1, B2, C1, C2};

% Arrays de strings para el formateo de salida
array[POS] of string: horas_str = ["15:00", "16:00", "17:00", "18:00", "19:00", "20:00"];
array[Proyectos] of string: proy_str = [
    "A* cuántico", 
    "Demostración matemática de que RTA* es un algoritmo absurdo", 
    "Modelado de la incertidumbre a la hora de aprobar TSI sin estudiar nada", 
    "Poda alfa-beta aplicada al encaje de bolillos", 
    "Planificación automática jerárquica híbrida dedicada a la yuxtaposición de los mundos paralelos", 
    "Brazo robótico para jugar a la pocha"
];


% Arrays paralelos donde el índice (1..6) representa la hora
% 1 = 15:00, 2 = 16:00, ..., 6 = 20:00
array[POS] of var Estudiantes: est;
array[POS] of var Proyectos: proy;
array[POS] of var Aulas: aula;

% Garantizamos que no se repitan dos elementos iguales en los arrays
constraint all_different(est);
constraint all_different(proy);
constraint all_different(aula);


% Definición de restricciones

% Bruno es el primero en presentar.
constraint est[1] == Bruno;

% El proyecto 4 se presenta en el aula B2 y antes que el proyecto 1.
constraint exists(i in POS)(proy[i] == P4 /\ aula[i] == B2);  % proyecto 4 en aula B2
constraint exists(i,j in POS)(proy[i] == P4 /\ proy[j] == P1 /\ i < j);  % proyecto 4 antes que proyecto 1

% El proyecto 1 se presenta inmediatamente antes que el proyecto 3, en un aula que no es ni la B2 ni la A1.
constraint exists(i,j in POS)(proy[i] == P1 /\ proy[j] == P3 /\ j-i == 1);  % proyecto 1 inmediatamente antes que proyecto 3
constraint exists(i in POS)(proy[i] == P1 /\ aula[i] != B2 /\ aula[i] != A1);  % proyecto 1 en aula distinta de B2 y A1

% Diego presenta exactamente una hora después que Alba.
constraint exists(i,j in POS)(est[i] == Diego /\ est[j] == Alba /\ i-j == 1);

% Carla presenta exactamente una hora después que Diego.
constraint exists(i,j in POS)(est[i] == Carla /\ est[j] == Diego /\ i-j == 1);

% Elena presenta en el aula C1, y su presentación tiene lugar después de Carla pero antes de Pablo.
constraint exists(i in POS)(est[i] == Elena /\ aula[i] == C1);  % Elena en aula C1
constraint exists(i,j in POS)(est[i] == Elena /\ est[j] == Carla /\ i > j);  % Elena después de Carla
constraint exists(i,j in POS)(est[i] == Elena /\ est[j] == Pablo /\ i < j);  % Elena antes de Pablo

% El proyecto 2 se presenta exactamente una hora después que el proyecto 3, en un aula que no es la A2.
constraint exists(i,j in POS)(proy[i] == P2 /\ proy[j] == P3 /\ i-j == 1);  % proyecto 2 una hora después que el 3
constraint exists(i in POS)(proy[i] == P2 /\ aula[i] != A2);  % proyecto 2 en aula distinta a A2

% El proyecto 3 se presenta en el aula A2.
constraint exists(i in POS)(proy[i] == P3 /\ aula[i] == A2);

% El proyecto 5 se presenta a las 19:00, mientras que el proyecto 6 se presenta en la C2 a última hora.
constraint proy[5] == P5;  % proyecto 5 a las 19h
constraint proy[6] == P6;  % proyecto 6 a última hora
constraint aula[6] == C2; % aula C2 a última hora


% Definición del problema
solve satisfy;


% Definición del output
output [
  "\"\(est[i])\": \(proy_str[fix(proy[i])]), \"\(aula[i])\", \(horas_str[i])\n" 
  | i in POS
];

