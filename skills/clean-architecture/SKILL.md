---
name: clean-architecture
description: "Revisión de arquitectura: analiza código y diseño con los principios de Clean Architecture, la regla de dependencias, la separación de capas, los límites entre componentes y SOLID. Usar cuando el usuario pida revisar arquitectura, verificar dependencias, evaluar capas, diseñar una funcionalidad con arquitectura limpia o detectar acoplamiento y violaciones de límites."
---

# Revisión de arquitectura limpia

Analiza el proyecto con los principios de Clean Architecture de Robert C. Martin. El objetivo no es imponer una cantidad fija de carpetas o capas, sino comprobar que las reglas de negocio estén protegidas de los detalles externos y que los cambios tengan un alcance controlado.

## Cuándo usar este skill

Actívalo cuando el usuario solicite:

- una revisión de Clean Architecture o de arquitectura de software;
- verificar dependencias, acoplamiento o dirección de las dependencias;
- evaluar la separación entre dominio, casos de uso, adaptadores e infraestructura;
- diseñar una funcionalidad respetando arquitectura limpia;
- detectar violaciones de SOLID, límites mal definidos o abstracciones innecesarias.

## Procedimiento de revisión

### 1. Entender el proyecto

Antes de emitir conclusiones:

1. Inspecciona la estructura de directorios y módulos.
2. Identifica el lenguaje, el framework y los puntos de entrada.
3. Localiza entidades, casos de uso, controladores, presentadores, repositorios, gateways y adaptadores.
4. Revisa imports, declaraciones de módulos y configuración de dependencias.
5. Sigue al menos un flujo real de entrada a salida para comprobar cómo atraviesa los límites.

Si no tienes acceso a una parte relevante del proyecto, indícalo como limitación y no presentes la ausencia de evidencia como una violación confirmada.

### 2. Aplicar la regla de dependencias

La regla principal es: las dependencias del código fuente deben apuntar hacia las políticas de mayor nivel, es decir, hacia el interior.

```text
+-----------------------------------------------------------+
|                 Frameworks y controladores                |
|   +-----------------------------------------------+       |
|   |              Adaptadores de interfaz          |       |
|   |   +---------------------------------------+   |       |
|   |   |              Casos de uso              |   |       |
|   |   |   +-------------------------------+   |   |       |
|   |   |   |           Entidades             |   |   |       |
|   |   |   +-------------------------------+   |   |       |
|   |   +---------------------------------------+   |       |
|   +-----------------------------------------------+       |
+-----------------------------------------------------------+
             Las dependencias apuntan hacia dentro
```

Comprueba lo siguiente:

- Las entidades no conocen casos de uso, adaptadores, frameworks ni infraestructura.
- Los casos de uso no importan implementaciones concretas de bases de datos, HTTP, UI o proveedores externos.
- Las capas internas no dependen de formatos propios de un framework.
- Las interfaces que representan necesidades externas se definen en una capa interna y se implementan en una capa externa.
- El contenedor de dependencias o el punto de composición conecta las implementaciones concretas con las abstracciones.

Distingue entre dirección del control y dirección de la dependencia: el flujo de ejecución puede ir hacia fuera y volver hacia dentro, mientras que el código interno debe seguir aislado de los detalles externos.

### 3. Revisar los límites

Cuando un caso de uso necesita comunicarse con un componente externo:

1. Define en la capa interna el puerto que expresa la necesidad.
2. Haz que el adaptador externo implemente ese puerto.
3. Inyecta la implementación desde el borde de la aplicación.
4. Verifica que el caso de uso no importe ni construya el adaptador concreto.

Ejemplo correcto:

```typescript
// Capa de casos de uso: la abstracción vive en el interior.
interface OrderOutputPort {
  presentOrder(order: OrderData): void;
}

class CreateOrderUseCase {
  constructor(private readonly output: OrderOutputPort) {}

  execute(): void {
    // Reglas de negocio...
    this.output.presentOrder(orderData);
  }
}

// Capa externa: el adaptador depende del caso de uso.
class OrderPresenter implements OrderOutputPort {
  presentOrder(order: OrderData): void {
    // Transformación para la UI o la respuesta HTTP.
  }
}
```

Marca como problema que el caso de uso importe directamente `OrderPresenter`, un controlador HTTP, un ORM o un cliente de terceros.

### 4. Revisar los datos que cruzan límites

Los límites deben transportar estructuras de datos simples y apropiadas para el contrato, no objetos que expongan detalles de otra capa.

Comprueba si:

- una entidad de dominio cruza directamente hasta la respuesta HTTP o la UI;
- una fila de base de datos penetra en el dominio;
- tipos de un framework aparecen en las firmas de los casos de uso;
- existen DTOs o modelos de entrada y salida donde son necesarios;
- las transformaciones entre DTOs, entidades y modelos externos ocurren en el adaptador adecuado.

```typescript
// Evitar: exponer directamente la entidad.
class GetUserUseCase {
  execute(): User {
    return this.userRepository.findById(id);
  }
}

// Preferir: devolver un contrato de salida simple.
class GetUserUseCase {
  execute(): UserResponseDTO {
    const user = this.userRepository.findById(id);
    return { id: user.id, name: user.name };
  }
}
```

No conviertas todo valor en un DTO por reflejo: explica el riesgo real de exposición, acoplamiento o mutabilidad antes de recomendar una transformación.

### 5. Evaluar las capas

#### Entidades o dominio

- Contienen las reglas de negocio más generales y estables.
- No dependen de frameworks, persistencia, red, UI ni librerías externas innecesarias.
- Mantienen invariantes y comportamiento del negocio, no solo datos anémicos.

#### Casos de uso o aplicación

- Orquestan entidades para cumplir una intención de la aplicación.
- Contienen reglas específicas del flujo de la aplicación.
- Definen puertos de entrada y salida cuando interactúan con el exterior.
- Dependen de interfaces de repositorio o gateway, no de sus implementaciones.
- Mantienen una responsabilidad clara y un contrato comprobable.

#### Adaptadores de interfaz

- Traducen entre formatos externos e internos.
- Incluyen controladores, presenters, gateways, mappers y adaptadores de persistencia cuando corresponda.
- Evitan que formatos de HTTP, UI, ORM o mensajería penetren en las capas internas.

#### Frameworks y drivers o infraestructura

- Contienen bases de datos, servidores web, SDKs, colas, proveedores externos y configuración.
- Funcionan principalmente como código de conexión y composición.
- Concentran los detalles que tienen mayor probabilidad de cambiar.

La arquitectura puede usar nombres o agrupaciones distintas. Evalúa el comportamiento de las dependencias, no solo si existen carpetas llamadas `domain`, `application` o `infrastructure`.

### 6. Revisar SOLID

Relaciona cada hallazgo con un principio concreto y con su impacto:

| Principio | Pregunta de revisión | Relación con arquitectura limpia |
| --- | --- | --- |
| SRP | ¿La clase tiene un solo motivo de cambio? | Mantiene responsabilidades separadas. |
| OCP | ¿Se puede extender sin modificar reglas estables? | Favorece puertos y políticas protegidas. |
| LSP | ¿Las implementaciones respetan el contrato? | Permite reemplazar adaptadores con seguridad. |
| ISP | ¿La interfaz contiene solo lo que el cliente necesita? | Evita puertos grandes y acoplamiento accidental. |
| DIP | ¿El código depende de abstracciones y no de concreciones? | Sostiene la inversión de dependencias. |

No etiquetes automáticamente todo problema como una violación de SOLID. Describe la dependencia observada y el efecto práctico: dificultad para probar, propagación de cambios, imposibilidad de sustituir un proveedor o mezcla de responsabilidades.

## Formato de salida

Entrega un informe con esta estructura:

```markdown
# Informe de revisión de arquitectura

## Resumen
- Evaluación general: Buena / Necesita mejoras / Crítica
- Alcance revisado y limitaciones
- Hallazgos principales

## Análisis de la regla de dependencias
- [Severidad] Archivo o módulo: dependencia observada.
  Impacto: por qué importa.
  Recomendación: cambio concreto.

## Revisión de capas
### Entidades: Buena / Necesita mejoras
### Casos de uso: Buena / Necesita mejoras
### Adaptadores de interfaz: Buena / Necesita mejoras
### Infraestructura: Buena / Necesita mejoras

## SOLID y límites
- Principio relacionado, evidencia e impacto.

## Recomendaciones priorizadas
1. Alta: correcciones que rompen la dirección de dependencias o reglas de negocio.
2. Media: reducción de acoplamiento y mejora de contratos o pruebas.
3. Baja: simplificaciones y mejoras de mantenimiento.

## Aspectos que están bien
- Prácticas o decisiones que conviene conservar.
```

Incluye rutas y símbolos concretos siempre que estén disponibles. Separa hechos observados, inferencias y recomendaciones. Si no se detectan problemas, di qué verificaste y qué evidencia respalda la evaluación.

## Criterio y casos borde

Clean Architecture no es una solución universal ni exige exactamente cuatro capas. Considera el tamaño, la vida útil, el equipo y la complejidad del proyecto.

Evita:

1. Confundir separación de carpetas con aislamiento real de dependencias.
2. Crear interfaces para cada clase sin una necesidad de sustitución, prueba o límite.
3. Añadir abstracciones para cambios hipotéticos y poco probables.
4. Tratar un proyecto pequeño como un sistema distribuido solo para cumplir una plantilla.
5. Recomendar una reestructuración masiva sin una secuencia incremental y verificable.

Formula siempre estas preguntas:

- ¿La separación aporta un beneficio observable?
- ¿La regla de dependencias se cumple realmente o solo lo parece por los nombres?
- ¿El impacto de un cambio queda limitado a los detalles externos?
- ¿Se puede cambiar un framework o proveedor sin modificar las políticas internas?
- ¿La complejidad añadida está justificada por el problema actual?

## Ejemplos por lenguaje

### TypeScript o JavaScript

```typescript
interface UserRepository {
  findById(id: string): Promise<User>;
}

class GetUserUseCase {
  constructor(private readonly repository: UserRepository) {}
}
```

El caso de uso debe depender de `UserRepository`, no de `PostgresUserRepository`.

### Python

```python
from typing import Protocol

class UserRepository(Protocol):
    def find_by_id(self, user_id: str) -> User: ...
```

Señala como acoplamiento externo que un caso de uso importe directamente `infrastructure.postgres.PostgresUserRepository`.

### Java o Kotlin

```kotlin
interface UserRepository {
    fun findById(id: String): User?
}

class GetUserUseCase(
    private val repository: UserRepository
)
```

El caso de uso no debería recibir directamente una implementación como `JpaUserRepository`.

## Referencia

Este skill es una traducción y adaptación al español del skill original publicado en [clean-architecture-skills](https://github.com/nathankim0/clean-architecture-skills/blob/main/plugins/clean-architecture/skills/clean-architecture/SKILL.md). Las recomendaciones deben ajustarse al contexto y a la evidencia del proyecto revisado.
