/*
Este modelo resuelve la asignación de 12 partidos de la NBA en una semana de 7 días y 3 franjas 
horarias, cumpliendo con restricciones como la disponibilidad de los estadios. Las claves del diseño son:

1. Enfoque centrado en el Partido: Las variables de decisión son el 'día' y la 'sesión' para cada 
   partido específico. Esto garantiza de forma implícita que cada encuentro se programe exactamente una vez.
   
2. Gestión de Back-to-Backs: Utilizo una matriz auxiliar 'juega[equipo, día]' que permite transformar 
   una restricción temporal compleja en un conteo aritmético simple sobre días consecutivos.
   
3. Restricciones Cruzadas: Se implementan validaciones para evitar solapamientos de equipos en 
   un mismo día y para asegurar restricciones como Prime Time hoy -> no Tarde mañana).
*/


% Definición de variables y constantes

% Datos del problema:
enum Equipos = {Celtics, Knicks, Sixers, Heat, Bucks, Lakers, Warriors, Suns, Nuggets, Mavericks};
set of int: Dias = 1..7;
enum Sesion = {Tarde, Noche, Prime};

% número de partidos
int: N = 12;
set of int: POS = 1..N;

% Guardamos los partidos a jugar con dos arrays
array [POS] of Equipos: local = [Celtics, Heat, Bucks, Lakers, Suns, Mavericks, Warriors, Knicks, Sixers, Nuggets, Celtics, Heat];
array [POS] of Equipos: visitante = [Knicks, Sixers, Celtics, Warriors, Nuggets, Lakers, Suns, Heat, Bucks, Mavericks, Lakers, Warriors];
% 1. Celtics vs Knicks      5. Suns vs Nuggets        9. Sixers vs Bucks
% 2. Heat vs Sixers         6. Mavericks vs Lakers   10. Nuggets vs Mavericks
% 3. Bucks vs Celtics       7. Warriors vs Suns      11. Celtics vs Lakers
% 4. Lakers vs Warriors     8. Knicks vs Heat        12. Heat vs Warriors


% Variables que guardarán el día y sesión de cada partido.
% Usando POS como índice garantizamos que cada partido se juegue una única vez.
array[POS] of var Dias: dia;
array[POS] of var Sesion: sesion;



% Definición de restricciones

% Un equipo no puede jugar más de un partido el mismo día.
constraint forall(i, j in POS where i < j)(
    (dia[i] == dia[j]) -> (
        local[i] != local[j] /\
        visitante[i] != visitante[j] /\
        local[i] != visitante[j] /\
        visitante[i] != local[j]
    )
);

% En una misma franja horaria puede haber como mucho 2 partidos.
constraint forall(d in Dias, s in Sesion)(
    sum(i in POS)(dia[i] == d /\ sesion[i] == s) <= 2
);

% En un mismo día puede haber como mucho 4 partidos.
constraint forall(i in Dias)(count(dia, i) <= 4);

% El día 4 no puede haber partidos, dado que corresponde a un festivo nacional.
constraint forall(i in POS)(dia[i] != 4);

% El día 7 (domingo) no puede haber partidos en Prime Time
constraint forall(i in POS)(dia[i] == 7 -> sesion[i] != Prime);

% Los equipos Lakers, Celtics y Warriors no pueden jugar en la franja de Tarde.
constraint forall(i in POS)(local[i] == Lakers \/ visitante[i] == Lakers -> sesion[i] != Tarde);
constraint forall(i in POS)(local[i] == Celtics \/ visitante[i] == Celtics -> sesion[i] != Tarde);
constraint forall(i in POS)(local[i] == Warriors \/ visitante[i] == Warriors -> sesion[i] != Tarde);

% Al menos 3 partidos de la semana deben disputarse en Prime Time.
constraint count(sesion, Prime) >= 3;

% El partido Lakers vs Warriors debe jugarse el día 2 en Prime Time.
% Es el partido 4:
constraint dia[4] == 2;
constraint sesion[4] == Prime;

% El partido Celtics vs Lakers debe jugarse el día 6 en Prime Time.
% Partido 11:
constraint dia[11] == 6;
constraint sesion[11] == Prime;

% El partido Bucks vs Celtics debe jugarse también en Prime Time.
% Partido 3:
constraint sesion[3] == Prime;

% El pabellón de los Knicks no está disponible el día 5 (por lo que Knicks vs Heat no puede jugarse ese día)
% Partido 8:
constraint dia[8] != 5;
 
% El pabellón de los Suns no está disponible el día 2 (por lo que Suns vs Nuggets no puede jugarse ese día) 
% Partido 5:
constraint dia[5] != 2;

% Los partidos Bucks vs Celtics y Nuggets vs Mavericks no pueden jugarse en los días 1 y 6, respectivamente.
constraint dia[3] != 1;
constraint dia[10] != 6;

% Los días 5 y 6 deben tener al menos 3 partidos cada uno.
constraint count(dia, 5) >= 3;
constraint count(dia, 6) >= 3;

% Si un equipo juega en Prime Time, no puede jugar al día siguiente en la franja de Tarde. (idea de Gemini)
constraint forall(p1, p2 in POS where p1 != p2)(
    (dia[p1] + 1 == dia[p2] /\ sesion[p1] == Prime /\ sesion[p2] == Tarde) -> (
        local[p1] != local[p2] /\ local[p1] != visitante[p2] /\
        visitante[p1] != local[p2] /\ visitante[p1] != visitante[p2]
    )
);
% El número de partidos de Tarde debe ser mayor que el número de partidos de Noche.
constraint count(sesion, Tarde) > count(sesion, Noche);
 
% El número de partidos de Noche debe ser mayor que el número de partidos de Prime Time.
constraint count(sesion, Noche) > count(sesion, Prime);


% Restricciones sobre los back to back (idea de Gemini):

% variables auxiliares:

% Matriz auxiliar para saber si un equipo 'e' juega en el día 'd'
array[Equipos, Dias] of var bool: juega;
constraint forall(e in Equipos, d in Dias)(
    % Juega si existe algún partido ese día donde sea local o visitante
    juega[e, d] == exists(p in POS)(dia[p] == d /\ (local[p] == e \/ visitante[p] == e))
);

% Array auxiliar para guardar cuántos back-to-backs tiene cada equipo
array[Equipos] of var int: b2b_equipo;
constraint forall(e in Equipos)(
    % Un b2b ocurre cuando juega[e, d] y juega[e, d+1] son verdaderos a la vez
    % Uso bool2int para convertir el true/false en 1/0
    b2b_equipo[e] == sum(d in 1..6)(bool2int(juega[e, d] /\ juega[e, d+1]))
);


% restricciones:

% Cada equipo puede tener como máximo un back-to-back durante la semana. 
constraint forall(e in Equipos)(b2b_equipo[e] <= 1);

% Entre todos los equipos puede haber como máximo dos back-to-back en toda la semana. 
constraint sum(b2b_equipo) <= 2;

% Los Celtics y los Warriors no pueden tener ningún back-to-back esta semana.
constraint b2b_equipo[Celtics] == 0;
constraint b2b_equipo[Warriors] == 0;



% Definición del problema
solve satisfy;



% Definición del output

% Array de siglas para imprimir la tabla
array[Equipos] of string: siglas = ["BOS", "NYK", "PHI", "MIA", "MIL", "LAL", "GSW", "PHX", "DEN", "DAL"];

output [
    "CALENDARIO SEMANAL NBA (CSP)\n",
    "============================\n",
    "Back-to-backs totales = \(sum(e in Equipos)(fix(b2b_equipo[e])))\n",
    "+------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+\n",
    "| Sesion     | Dia 1             | Dia 2             | Dia 3             | Dia 4             | Dia 5             | Dia 6             | Dia 7             |\n",
    "+------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+\n"
] ++ 
[
    % Imprimir el nombre de la sesión al principio de la fila (solo si estamos en el Dia 1)
    if d == 1 then 
        if s == Tarde then "| Tarde      |"
        elseif s == Noche then "| Noche      |"
        else "| Prime Time |" endif
    else "" endif ++
    
    % Calcular los partidos que se juegan en ese (día, sesión) y unirlos con " /"
    let {
        string: partidos = join(" /", [ "\(siglas[local[p]])-\(siglas[visitante[p]])" | p in POS where fix(dia[p]) == d /\ fix(sesion[p]) == s ]);
        string: celda = if string_length(partidos) == 0 then "-" else partidos endif;
        
        % Rellenar con espacios dinámicamente para que la columna mida exactamente 23 caracteres
        int: espacios = 18 - string_length(celda);
    } in " " ++ celda ++ concat([" " | i in 1..espacios]) ++ "|" ++
    
    % Imprimir el borde inferior al final de cada fila (cuando llegamos al Dia 7)
    if d == 7 then "\n+------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+-------------------+\n" else "" endif
    
    | s in Sesion, d in Dias
] ++
[
    "Leyenda:\nBOS=Celtics, NYK=Knicks, PHI=Sixers, MIA=Heat, MIL=Bucks,\nLAL=Lakers, GSW=Warriors, PHX=Suns, DEN=Nuggets, DAL=Mavericks\n"
];