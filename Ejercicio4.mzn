/*
Para resolver esta variante del cuadrado mágico (COP), he aplicado las siguientes estrategias:

1. Restricción de Paridad: En lugar de usar implicaciones lógicas, he simplificado la restricción 
   en comparar si el módulo 2 de todos los elementos de la matriz coincide con el módulo 2 de N.
   Esto fuerza directamente a que todos los valores sean pares si N es par, o impares si N es impar.

2. Valores Distintos: Calculo el mínimo número de valores distintos necesario usando una división pero 
   con redondeo hacia arriba: '((N*N)+1) div 2'. Luego, he empleado la restricción global 'nvalue' sobre la 
   matriz (convertida en 1D usando 'array1d') para que el solver cuente los números diferentes.

3. Sumas y Diagonales: He usado bucles 'forall' para las sumas de filas, columnas y las dos diagonales 
   (principal y secundaria), siguiendo la idea que había en las diapositivas, igualándolas a una variable 
   libre 'ms'.
   
4. Ruptura de Simetrías: Al buscar la matriz óptima, el espacio de búsqueda genera soluciones espejo 
   (rotaciones de 90/180/270 grados y reflexiones horizontales/verticales/diagonales). Para evitar que se
   exploren ramas redundantes, se rompe la simetría con las siguientes ideas:
   - Fijar que la celda de la esquina superior izquierda (magic[1,1]) sea menor o igual que las otras tres esquinas. 
   - Imponer un orden entre la esquina superior derecha y la inferior izquierda.
   Esto reduce el espacio de matrices isomórficas (de 8 posibles simetrías a un solo representante), mejorando
   el rendimiento del solver sin alterar el valor óptimo buscado.
   
5. Optimización: Debido a la explosión combinatoria del espacio de búsqueda al aumentar N, he implementado dos 
   optimizaciones para hacer el problema tratable:
   - Restricción redundante: Establecer explícitamente que 'suma_total == ms * N', permitiendo al solver inferir 
     el total sin tener que instanciar todas las variables.
   - Heurística de búsqueda: Utilizar 'int_search' con las estrategias 'first_fail' (para instanciar primero las 
     variables más restrictivas) e 'indomain_min' (para probar los valores de menor a mayor). Al ser un problema de 
     minimización, esto dirige la búsqueda directamente hacia las ramas más prometedoras, encontrando el óptimo antes.
*/

include "globals.mzn";


% Definición de variables y constantes

% Descomentar y comentar según corresponda
% int: N = 3;
% int: N = 4;
 int: N = 5;
% int: N = 6;
% int: N = 7;

set of int: S = 1..N;  % size
int: MAXV = 100;  % máximo valor permitido en cada celda

% Mínimo de valores distintos exigidos, redondeando hacia arriba.
int: min_distintos = ((N * N) + 1) div 2;

% matriz de tamaño NxN con números enteros positivos
array [S,S] of var 1..MAXV: magic;

% número mágico para la suma de filas, columnas y diagonales
var int: ms;

% Variable para almacenar el recuento de valores distintos
var 1..(N*N): num_distintos;


% Definición de restricciones

% Al menos la mitad de los valores de la matriz son distintos
% - 'array1d(matriz)': Convierte una matriz 2D en un array 1D. Se usa porque 'nvalue' 
%   sólo acepta listas unidimensionales.
% - 'nvalue(var, array)': Restricción global que fuerza a que la variable coincida con el 
%   número de valores distintos en el array.
constraint nvalue(num_distintos, array1d(magic));
constraint num_distintos >= min_distintos;

% si N es par, todos sus valores deben ser pares
% si N es impar, todos los valores deben ser impares
% Esto se traduce en que, sea cual sea N, el módulo de cualquier número entre 2
% debe coincidir con el módulo de N entre 2.
constraint forall(fila, col in S)(magic[fila,col] mod 2 == N mod 2);

% La suma de los elementos de cada fila y de cada columna, y la suma de los elementos 
% de la diagonal principal y de la diagonal secundaria, proporcionen el mismo valor.
constraint forall(fila in S)(sum(col in S) (magic[fila,col]) == ms);
constraint forall(col in S) (sum(fila in S) (magic[fila,col]) == ms);
constraint sum(fila in S)(magic[fila,fila]) == ms;
constraint sum(fila in S) (magic[fila, N-fila+1]) == ms;

% minimizar la suma total de los elementos de la matriz
var int: suma_total = sum(fila, col in S)(magic[fila,col]);

% Si las N filas suman 'ms', la matriz completa suma N * ms.
% Esto descarta ramas antes, haciendo el programa más eficiente.
constraint suma_total == ms * N;


% Romper las simetrías
% Eliminamos matrices equivalentes por rotación o reflexión imponiendo un orden
% en las esquinas de la matriz.

% 1. Forzamos a que la esquina superior izquierda sea estrictamente la menor de las 4 esquinas.
% Esto elimina las 4 rotaciones y 2 de los reflejos.
constraint magic[1,1] <= magic[1,N];
constraint magic[1,1] <= magic[N,1];
constraint magic[1,1] <= magic[N,N];

% 2. Para romper el reflejo en la diagonal principal restante, ordenamos otras dos esquinas.
constraint magic[1,N] <= magic[N,1];


% Definición del problema
% - 'first_fail': Elige primero la variable con el dominio más pequeño.
% - 'indomain_min': Prueba primero los valores más bajos del dominio.
solve :: int_search(array1d(magic), first_fail, indomain_min) minimize suma_total;


% Definición del output
output 
  [ "N = \(N)\n" ] ++
  [ "MAXV = \(MAXV)\n" ] ++
  [ "Mínimo de valores distintos exigido = \(fix(min_distintos))\n" ] ++
  [ "Número de valores distintos = \(fix(num_distintos))\n" ] ++
  [ "Suma común de filas/columnas/diagonales = \(fix(ms))\n" ] ++
  [ "Suma total minimizada = \(fix(suma_total))\n" ] ++
  [ "\nMatriz: \n" ] ++
  [ "\(fix(magic[fila,col]))" ++ if col == N then "\n" else " " endif | fila, col in S ];  
  