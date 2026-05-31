# Context Map — PostaAI

Noticias de AI diarias con voz rioplatense. Dos contextos en un repo: un motor de contenido y una app iOS que lo consume.

## Contextos

- [ai-digest](./ai-digest/CONTEXT.md) — motor de contenido: junta noticias AI de 21 fuentes 2x/día, rankea y genera el material editorial.
- [PostaAI](./PostaAI/CONTEXT.md) — app iOS: muestra los drops diarios; swipe para decidir, doble-tap para profundizar.

## Relaciones

- **ai-digest → PostaAI**: ai-digest produce un **Pool** de Cards etiquetadas y lo publica como JSON estático en un CDN. PostaAI baja ese Pool y lo filtra on-device por los **Intereses** del usuario para armar el **Drop** que ve cada persona. La comunicación es asíncrona vía un archivo, no hay API en vivo (ver ADR-0002).

## Lenguaje compartido (el contrato entre contextos)

Estos términos cruzan los dos contextos y son el contrato de integración.

**Pool**:
El conjunto completo de Cards generadas para una Edición (~30-40), cada una etiquetada con metadata de Interés. Es el artefacto que ai-digest publica; ningún usuario ve el Pool entero.
_Avoid_: feed, batch, lote.

**Drop**:
La vista de una Edición que un usuario concreto ve. Se arma on-device a partir del Pool con el modelo **híbrido**: las Cards que matchean sus Intereses arriba, y abajo una sección acotada "también pasó hoy" con lo más grande del resto. Nunca esconde la noticia grande ni queda vacío. Lo que para la app es "el drop de hoy" es siempre esta vista personalizada, no el Pool.
_Avoid_: edición (esa es el horario), tanda.

**Edición**:
Cada corrida del día: "de la mañana" (09:00) o "de la tarde" (18:00). Una Edición produce un Pool.

**Card**:
Una noticia individual con voz editorial rioplatense: headline con onda, `take` (hook), `context` (background), `editorial` ("El take de Posta"), más metadata de fuente, de Interés y `publishedAt` (timestamp ISO 8601 absoluto de cuándo se publicó la noticia original). El renderizado relativo ("hace 2 horas", "ayer") lo computa el cliente en runtime — el campo nunca es un string display, así un Pool cacheado offline no miente sobre la edad.

**Interés**:
La unidad de personalización que el usuario elige y por la que se ordena el Pool. Tres facetas en el MVP. Una Card matchea "lo tuyo" si cualquiera de sus facetas matchea cualquier selección del usuario (OR pleno):
- **Tema**: sub-campo de AI, enum fijo de 9 (modelos · código/devtools · agentes · research/papers · open source/local · negocio/plata · hardware/robots · regulación/política · producto/apps). 1 primario + hasta 1 secundario por Card (el campo `kind` es array de 1-2). Sección **obligatoria** en el onboarding.
- **Entidad**: org/empresa. El `tag` **visible** de la Card es abierto (una entidad primaria por Card). Las Entidades **seguibles** son una lista curada (~12-15 orgs). Sección opcional en el onboarding.
- **Producto**: producto/feature específico dentro de una org (Claude Code, ChatGPT, Codex...). Campo `product: String?` opcional en la Card, valor de una lista curada (~10). Modelado jerárquicamente sobre Entidad (un producto pertenece a una org). Sección secundaria/colapsable en el onboarding.
- **Industria** (verticales) y **Personas** seguibles: diferidas a v1.1 (no pasan la regla de los dos filtros, ver ADR-0003 y ADR-0004).
_Avoid_: tag (eso es el campo crudo de la Card que codifica la Entidad), categoría.
