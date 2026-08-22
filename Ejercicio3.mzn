/*
Dado que MiniZinc requiere una única función objetivo, he transformado el problema multiobjetivo en 
una función ponderada que hace lo siguiente:
1º Maximizar Utilidad (Sumando)
2º Minimizar Peso (Restando)
3º Minimizar Coste (Restando)

He asignado pesos (múltiplos de 10 por simplicidad) muy dispares a cada criterio:
- W_COSTE = 1
- W_PESO = 100 (mayor que el mayor valor que toma coste. Si eligieramos todos los objetos, coste=61)
- W_UTILIDAD = 10000 (mayor que la máxima penalización conjunta de peso y coste -> 61 + 15(peso máximo)*100 = 1561)

Al asignar saltos de varios órdenes de magnitud entre las ponderaciones, garantizamos que un aumento en el 
criterio de mayor prioridad siempre aportará un valor mayor a la función que la optimización máxima posible 
de los criterios inferiores combinados.
*/

% Definición de variables y constantes

% Enum con los objetos disponibles, para usar los nombres como índices de arrays
enum Objetos = {GPS, Camara, Ordenador, Bateria_extra, Sensor_termico, Botiquin, Radio, Panel_solar};

% Arrays con los datos del problema
array[Objetos] of int: peso = [3, 2, 4, 2, 5, 3, 4, 6];
array[Objetos] of int: coste = [8, 6, 10, 4, 12, 5, 7, 9];
array[Objetos] of int: utilidad = [10, 9, 14, 7, 16, 8, 11, 13];
array[Objetos] of string: objetos_str = [
    "GPS", "Cámara", "Ordenador", "Batería extra", 
    "Sensor térmico", "Botiquín", "Radio", "Panel solar"
];

% Array que guarda qué objetos están seleccionados
array[Objetos] of var bool: seleccion;


% Definición de restricciones

% Peso máximo: la suma de pesos no puede superar 15.
% Uso bool2int para convertir el true/false en 1/0
constraint (sum(i in Objetos)(peso[i] * bool2int(seleccion[i]))) <= 15;

% Dependencia técnica: si se selecciona el "Ordenador", también debe seleccionarse la "Batería extra".
constraint seleccion[Ordenador] -> seleccion[Bateria_extra];

% Compatibilidad energética: si se selecciona el "Sensor térmico", también debe seleccionarse el "Panel solar".
constraint seleccion[Sensor_termico] -> seleccion[Panel_solar];

% Seguridad mínima: debe seleccionarse obligatoriamente el "Botiquín".
constraint seleccion[Botiquin] == true;


% Variables para la función objetivo
var int: utilidad_total = sum(i in Objetos)(utilidad[i] * bool2int(seleccion[i]));
var int: peso_total = sum(i in Objetos)(peso[i] * bool2int(seleccion[i]));
var int: coste_total = sum(i in Objetos)(coste[i] * bool2int(seleccion[i]));


% Pesos
int: W_UTILIDAD = 10000;
int: W_PESO     = 100;
int: W_COSTE    = 1;

% Función objetivo ponderada
var int: funcion_objetivo = (W_UTILIDAD * utilidad_total) 
                          - (W_PESO * peso_total) 
                          - (W_COSTE * coste_total);


% Definición del problema
solve maximize funcion_objetivo;


% Definición del output
% Uso 'where fix(seleccion[i])' para iterar solo por los objetos elegidos

output 
  [ "Objetos seleccionados:\n"] ++
  [ "- \(objetos_str[i]): (peso=\(fix(peso[i])), coste=\(fix(coste[i])), utilidad=\(fix(utilidad[i])))\n" 
    | i in Objetos where fix(seleccion[i]) ] ++
  [ "\nUtilidad total = \(fix(utilidad_total))\n" ] ++
  [ "Peso total = \(fix(peso_total))\n" ] ++
  [ "Coste total = \(fix(coste_total))\n" ];
