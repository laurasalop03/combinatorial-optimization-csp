/*
Este modelo calcula la asignación óptima de tareas y tiempos para ensamblar el DeLorean 
en el menor tiempo posible. La codificación se basa en las siguientes ideas:

1. Variables de Decisión: El solver debe deducir quién hace la tarea ('encargado' 
   entre Marty y Doc), cuándo empieza ('inicio') y si recibe apoyo ('ayuda_biff' o 
   'ayuda_george' mediante booleanos).
   
2. Cálculo Dinámico de Duraciones: La variable 'duracion_real' se calcula en 
   función de la duración base del trabajador elegido, restando los días correspondientes 
   si los booleanos de ayuda están activos.
   
3. Precedencias y Solapamientos: Se asegura el orden secuencial de las tareas 
   dependientes mediante restricciones. Además, se garantiza que ninguna de las 4 
   personas involucradas pueda trabajar en dos tareas simultáneamente.
   
4. Función Objetivo: Se busca minimizar 'tiempo_total', definido como el instante en 
   el que finaliza la última tarea.
*/

include "globals.mzn";


% Definición de variables y constantes

% Enum para las tareas y los trabajadores
enum Tareas = {A,B,C,D,E,F,G,H,I,J,K};
enum Trabajadores = {Marty, Doc}; % solo los principales

% Matriz para guardar la duración de cada tarea según quién la hace
array[Tareas, Trabajadores] of int: duracion_base = [|
  10, 16 | % A
  1,  2  | % B
  5,  4  | % C
  15, 5  | % D
  12, 4  | % E
  13, 5  | % F
  7,  6  | % G
  4,  3  | % H
  2,  2  | % I
  4,  2  | % J
  4,  3  |]; % K
  

% Variable que guardará qué trabajador hace qué tarea.
array[Tareas] of var Trabajadores: encargado;

% El máximo tiempo posible lo calculo sumando lo máximo que se puede tardar en cada
% tarea, suponiendo que no hay ayudas de Biff ni George.
% Esta constante se usa para limitar los valores que puede tomar el array que guarda
% cuándo empieza cada tarea.
int: MAX_TIEMPO = 84;
array[Tareas] of var 1..MAX_TIEMPO: inicio;

% Arrays de bool que indican si Biff o George ayudan en la tarea.
array[Tareas] of var bool: ayuda_biff;
array[Tareas] of var bool: ayuda_george;

% Array que guarda la duración real de una tarea, teniendo en cuenta si hay ayuda.
array[Tareas] of var int: duracion_real;



% Definición de restricciones

% Defino todas las restricciones relativas a las precedencias de tareas.
% Si B va después de A, el inicio de B tiene que ser >= que el final de A.
constraint inicio[B] >= inicio[A] + duracion_real[A];
constraint inicio[C] >= inicio[B] + duracion_real[B];
constraint inicio[D] >= inicio[A] + duracion_real[A];
constraint inicio[D] >= inicio[C] + duracion_real[C];
constraint inicio[E] >= inicio[C] + duracion_real[C];
constraint inicio[F] >= inicio[C] + duracion_real[C];
constraint inicio[F] >= inicio[D] + duracion_real[D];
constraint inicio[F] >= inicio[E] + duracion_real[E];
constraint inicio[G] >= inicio[C] + duracion_real[C];
constraint inicio[G] >= inicio[D] + duracion_real[D];
constraint inicio[H] >= inicio[E] + duracion_real[E];
constraint inicio[H] >= inicio[G] + duracion_real[G];
constraint inicio[I] >= inicio[F] + duracion_real[F];
constraint inicio[I] >= inicio[H] + duracion_real[H];
constraint inicio[J] >= inicio[G] + duracion_real[G];
constraint inicio[J] >= inicio[I] + duracion_real[I];
constraint inicio[K] >= inicio[H] + duracion_real[H];
constraint inicio[K] >= inicio[I] + duracion_real[I];


% Un mismo trabajador (Marty y Doc) no puede hacer dos tareas a la vez.
% Si hay dos tareas con el mismo encargado, compruebo que una empiece después de haber 
% acabado la otra.
constraint forall(t1, t2 in Tareas where t1 < t2)(
    (encargado[t1] == encargado[t2]) ->
    (inicio[t1] >= inicio[t2] + duracion_real[t2] \/ inicio[t2] >= inicio[t1] + duracion_real[t1])
);


% Restricciones Biff:

% Biff solo puede apoyar en tareas cuya duración sea al menos de 3 días.
constraint forall(t in Tareas)(ayuda_biff[t] -> duracion_base[t, encargado[t]] >= 3);

% Biff puede apoyar como máximo en 4 tareas en total.
constraint sum(ayuda_biff) <= 4;

% Biff no puede apoyar en tareas que se ejecuten simultáneamente.
% Misma lógica que la de que un trabajador no puede hacer dos tareas a la vez.
constraint forall(t1, t2 in Tareas where t1 < t2)(
    (ayuda_biff[t1] /\ ayuda_biff[t2]) ->
    (inicio[t1] >= inicio[t2] + duracion_real[t2] \/ inicio[t2] >= inicio[t1] + duracion_real[t1])
);


% Biff no puede ayudar en las tareas D ni F.
constraint ayuda_biff[D] == false;
constraint ayuda_biff[F] == false;

% Biff no puede apoyar en más de 2 tareas asignadas a Marty, ni en más de 2 tareas asignadas a Doc.
constraint sum(t in Tareas where encargado[t] == Marty)(ayuda_biff[t]) <= 2;
constraint sum(t in Tareas where encargado[t] == Doc)(ayuda_biff[t]) <= 2;


% Restricciones George:

% George solo puede ayudar a Marty, nunca a Doc.
constraint forall(t in Tareas)(ayuda_george[t] -> encargado[t] == Marty);

% George solo puede ayudar en tareas asignadas a Marty cuya duración original para Marty sea
% de al menos 2 días.
constraint forall(t in Tareas)(ayuda_george[t] -> duracion_base[t, Marty] >= 2);

% George no puede realizar dos apoyos simultáneamente.
constraint forall(t1, t2 in Tareas where t1 < t2)(
    (ayuda_george[t1] /\ ayuda_george[t2]) ->
    (inicio[t1] >= inicio[t2] + duracion_real[t2] \/ inicio[t2] >= inicio[t1] + duracion_real[t1])
);

% George no puede coincidir con Biff en una misma tarea.
constraint forall(t in Tareas)(not (ayuda_biff[t] /\ ayuda_george[t]));


% Establecemos la duración real según quien ayude.
constraint forall(t in Tareas)(
    duracion_real[t] == duracion_base[t, encargado[t]] 
        % Gracias al apoyo de Biff, la duración de la tarea se reduce: en 3 días si la tarea es A; en 2 días
        % si la tarea es H; en 1 día para cualquier otra tarea elegible.
        - (if ayuda_biff[t] /\ t == A then 3
           elseif ayuda_biff[t] /\ t == H then 2
           elseif ayuda_biff[t] then 1
           else 0 endif)
        % Si George ayuda en una tarea, la duración de dicha tarea se reduce en 1 día.
        - (if ayuda_george[t] then 1 else 0 endif)
);



% Queremos que el tiempo total sea el menor posible, es decir, que el tiempo de fin máximo sea
% el menor posible
var int: tiempo_total = max(i in Tareas)(inicio[i] + duracion_real[i]);


% Definición del problema
solve minimize tiempo_total;



% Definición del output

% Array con los nombres de las tareas para la salida
array[Tareas] of string: desc = [
    "A - Montar chasis",
    "B - Instalar ruedas",
    "C - Cableado eléctrico",
    "D - Motor de fusión nuclear",
    "E - Tablero de control",
    "F - Instalación y configuración del condensador de fluzo",
    "G - Ajuste aerodinámico",
    "H - Instalación de puertas de ala de gaviota",
    "I - Panel de tiempo",
    "J - Implementación y validación de algoritmos de búsqueda heurística para optimización de caminos",
    "K - Prueba de plutonio"
];

output [
    "\(desc[t]) inicio dia \"\(fix(inicio[t]))\" fin dia \"\(fix(inicio[t] + duracion_real[t] - 1))\". Asignada a \"\(fix(encargado[t]))\"" ++
    if fix(ayuda_biff[t]) then " con apoyo de Biff.\n"
    elseif fix(ayuda_george[t]) then " con apoyo de George.\n"
    else ".\n" endif
    | t in Tareas
];

