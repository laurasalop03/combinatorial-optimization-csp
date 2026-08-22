/*
Para resolver el problema de la bebida isotónica cumpliendo con la prohibición de usar variables de tipo 'float',
he seguido la siguiente estrategia de modelado:

1. Estructura de Datos: He utilizado arrays paralelos indexados mediante un enum Ingredientes, lo que mejora la 
   legibilidad y facilita el acceso a los datos.

2. Eliminación de Decimales en Restricciones: Para calcular las proporciones nutricionales (que están dadas por cada
   1000 ml, mientras que los datos base son por 100 ml), he reescrito las inecuaciones mediante reglas de tres. En
   los casos donde el límite generaba un decimal (ej. 85g o 475mg), he multiplicado ambos lados de la inecuación
   por 10 para mantener todo en enteros.

3. Porcentajes de Volumen: Las restricciones relativas a porcentajes (ej. el 3% del volumen total) se han escalado
   multiplicando por 100, haciendo así comparaciones de forma entera (ej. cantidad * 100 >= 3 * VTOTAL).
*/

include "globals.mzn";

% Definición de variables y constantes

% Comentar y descomentar según el volumen total que se desee probar
 int: VTOTAL = 200;
% int: VTOTAL = 1000;
% int: VTOTAL = 5000;
% int: VTOTAL = 10000;


% Enum con los ingredientes disponibles, para usar los nombres como índices de los arrays
enum Ingredientes = {Agua_base, Jarabe_A, Jarabe_B, Concentrado_salino, Extracto_energetico, Aroma_citrico};

% Arrays con los datos del problema
array[Ingredientes] of int: costes = [2, 12, 10, 8, 20, 6];  % en céntimos y así no usamos float
array[Ingredientes] of int: azucar = [0, 18, 12, 0, 4, 2];
array[Ingredientes] of int: sodio = [0, 40, 20, 180, 10, 5];
array[Ingredientes] of int: cafeina = [0, 0, 0, 0, 30, 0];
array[Ingredientes] of string: ingredientes = [
  "Agua base", 
  "Jarabe A", 
  "Jarabe B", 
  "Concentrado salino", 
  "Extracto energético", 
  "Aroma cítrico"
];

% Array que guardará las cantidades de cada ingrediente
% La máxima cantidad que podemos tener de un ingrediente es el volumen total
array[Ingredientes] of var 0..VTOTAL: cantidades;  


% Definición de restricciones

% La suma de todas las cantidades tiene que ser el volumen total
constraint sum(i in Ingredientes)(cantidades[i]) == VTOTAL;

% Cada cantidad de ingrediente debe expresarse en múltiplos de 10 ml
constraint forall(i in Ingredientes)((cantidades[i] mod 10) == 0);

% entre 70 y 85 g de azúcar (por 1000 ml de bebida)
/*
Para un ingrediente i sabemos que hay azucar[i] gr por cada 100 ml.
Por cada 1000 ml necesitamos que haya más de 70 gr de azúcar. Haciendo una regla de tres, obtenemos que, 
para VTOTAL ml necesitamos más de (VTOTAL * 70 / 1000) gr. 
Juntando todo llegamos a:
azucar[i] * cantidades[i] / 100 >= (VTOTAL * 70 / 1000) -> azucar[i] * cantidades[i] >= VTOTAL * 7

Este mismo razonamiento se repite para el menor que 85 gr y para las dos siguientes restricciones.

En los casos en los que obtengo un número decimal, como para los 85 gr de azúcar (8.5 * VTOTAL), multiplico ambos lados de la inecuación por 10.
*/
constraint (sum(i in Ingredientes)(azucar[i] * cantidades[i]) >= 7 * VTOTAL) /\ ((sum(i in Ingredientes)(azucar[i] * cantidades[i])) * 10 <= 85 * VTOTAL);

% entre 400 y 475 mg de sodio (por 1000 ml de bebida)
constraint (sum(i in Ingredientes)(sodio[i] * cantidades[i]) >= 40 * VTOTAL) /\ ((sum(i in Ingredientes)(sodio[i] * cantidades[i])) * 10 <= 475 * VTOTAL);

% entre 60 y 90 mg de cafeína (por 1000 ml de bebida)
constraint (sum(i in Ingredientes)(cafeina[i] * cantidades[i]) >= 6 * VTOTAL) /\ (sum(i in Ingredientes)(cafeina[i] * cantidades[i]) <= 9 * VTOTAL);

% El aroma cítrico debe usarse obligatoriamente en entre el 3% y el 20% del volumen total.
% Multiplicamos la cantidad por 100 para no usar float al poner 0.03 * VTOTAL, por ejemplo.
constraint (cantidades[Aroma_citrico] * 100 >= 3 * VTOTAL) /\ (cantidades[Aroma_citrico] * 100 <= 20 * VTOTAL);

% El extracto energético no puede superar el 40% del volumen total.
constraint cantidades[Extracto_energetico] * 100 <= 40 * VTOTAL;

% Debe utilizarse exactamente uno de los dos jarabes (Jarabe A o Jarabe B).
% Compruebo si el A es cero y el B mayor que cero, o al contrario.
constraint (cantidades[Jarabe_A] == 0 /\ cantidades[Jarabe_B] > 0) \/ (cantidades[Jarabe_B] == 0 /\ cantidades[Jarabe_A] > 0);

% Si se usa Jarabe A, debe emplearse al menos en el 5% del volumen total.
constraint cantidades[Jarabe_A] > 0 -> cantidades[Jarabe_A] * 100 >= 5 * VTOTAL;

% Si se usa concentrado salino, debe emplearse al menos en el 3% del volumen total.
constraint cantidades[Concentrado_salino] > 0 -> cantidades[Concentrado_salino] * 100 >= 3 * VTOTAL;

% Como mucho pueden usarse 4 ingredientes distintos.
constraint count(cantidades, 0) >= 2;  % el número de ingredientes con cantidad == 0 tiene que ser al menos 2


% Definición del problema
solve satisfy;


% Variables auxiliares para limpiar el output y no repetir calculos.
var int: sum_coste = sum(i in Ingredientes)(costes[i] * cantidades[i]);
var int: sum_azucar = sum(i in Ingredientes)(azucar[i] * cantidades[i]);
var int: sum_sodio = sum(i in Ingredientes)(sodio[i] * cantidades[i]);
var int: sum_cafeina = sum(i in Ingredientes)(cafeina[i] * cantidades[i]);

% Definición del output
output 
  [ "Cantidades usadas:\n------------------\n"] ++
  [ "\(ingredientes[i]): \(fix(cantidades[i])) ml\n" | i in Ingredientes ] ++
  [ "\nCoste total = \(fix(sum_coste div 100)).\(fix((sum_coste div 10) mod 10)) centimos\n" ] ++
  [ "Azucar total = \(fix(sum_azucar div 100)).\(fix((sum_azucar div 10) mod 10)) g\n" ] ++
  [ "Sodio total = \(fix(sum_sodio div 100)).\(fix((sum_sodio div 10) mod 10)) mg\n" ] ++
  [ "Cafeina total = \(fix(sum_cafeina div 100)).\(fix((sum_cafeina div 10) mod 10)) mg\n" ];

