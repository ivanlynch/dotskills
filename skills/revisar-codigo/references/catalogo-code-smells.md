# Catálogo base de code smells

Aplicar este catálogo únicamente como heurística sobre el diff. Cada observación
debe citar el fragmento exacto que coincide con la descripción. Las reglas
documentadas del repositorio prevalecen y pueden aceptar deliberadamente una
estructura que este catálogo señalaría.

Un code smell no demuestra por sí mismo un defecto ni autoriza a atribuir un
impacto. Si no existe evidencia ejecutable de una falla, informarlo solo como
observación de diseño.

## Nombre misterioso (*Mysterious Name*)

Una función, variable o tipo no comunica qué hace o qué representa. La dirección
de mejora es renombrarlo. Si no existe un nombre preciso, revisar si el diseño
mezcla responsabilidades.

## Código duplicado (*Duplicated Code*)

La misma forma de lógica aparece en más de un fragmento o archivo del cambio. La
dirección de mejora es extraer la parte compartida y reutilizarla desde ambos
lugares.

## Envidia de funcionalidad (*Feature Envy*)

Un método consulta y manipula más datos de otro objeto que del propio. La
dirección de mejora es mover el comportamiento junto a los datos que utiliza.

## Grupo de datos (*Data Clumps*)

Los mismos campos o parámetros aparecen juntos de forma repetida. La dirección
de mejora es representarlos mediante un tipo con significado propio.

## Obsesión por primitivos (*Primitive Obsession*)

Un string, número u otro valor primitivo representa un concepto de dominio que
necesita reglas propias. La dirección de mejora es crear un tipo pequeño para
ese concepto.

## Condicionales repetidos (*Repeated Switches*)

El mismo `switch` o cadena de `if` sobre el mismo tipo aparece en varios lugares
del cambio. La dirección de mejora es centralizar la decisión mediante
polimorfismo o un único mapa compartido.

## Cirugía a perdigonazos (*Shotgun Surgery*)

Un único cambio lógico exige editar muchos archivos dispersos. La dirección de
mejora es reunir en un mismo módulo las partes que cambian juntas.

## Cambio divergente (*Divergent Change*)

Un archivo o módulo se modifica por varios motivos independientes dentro del
mismo cambio. La dirección de mejora es separar responsabilidades para que cada
módulo tenga un motivo coherente de cambio.

## Generalidad especulativa (*Speculative Generality*)

Se agregan abstracciones, parámetros o extensiones para necesidades que la
especificación no exige. La dirección de mejora es eliminarlos o simplificarlos
hasta que exista una necesidad concreta.

## Cadena de mensajes (*Message Chains*)

El código navega una cadena larga como `a.b().c().d()` y queda acoplado a la
estructura interna de varios objetos. La dirección de mejora es encapsular esa
navegación detrás de una operación del primer objeto apropiado.

## Intermediario (*Middle Man*)

Una clase o función se limita casi por completo a delegar llamadas. La dirección
de mejora es eliminar la capa sin responsabilidad propia y llamar al destino
real.

## Herencia rechazada (*Refused Bequest*)

Una subclase o implementación ignora o reemplaza gran parte del contrato que
hereda. La dirección de mejora es sustituir la herencia por composición o
definir un contrato más pequeño.
