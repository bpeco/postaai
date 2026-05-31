# PostaAI

Noticias de AI diarias con voz argentina. El producto tiene dos patas que viven en este repo:

| Sub-proyecto | Qué es | Stack | Detalle |
|---|---|---|---|
| `ai-digest/` | **Motor de contenido**: junta noticias AI de 21 fuentes 2x/día y genera el material editorial | Python + bash, launchd | ver `ai-digest/CLAUDE.md` |
| `PostaAI/` | **App iOS**: muestra "drops" diarios de noticias, swipe para decidir, doble-tap para profundizar | SwiftUI nativo, iOS 17 | ver `PostaAI/CLAUDE.md` |

## El norte: cómo se conectan

El pipeline es el **motor de contenido de la app**. El objetivo del proyecto es que `ai-digest` termine produciendo el `Drop` JSON que la app consume.

**Hoy NO están conectados.** La app corre con un fixture mock (`PostaAI/PostaAI/Resources/Fixtures/PostaDrop.json`) vía `MockCardRepository`. El pipeline hoy entrega digests en markdown por email. El puente —una fase que transforme los items rankeados al schema `Drop`/`Card`— todavía no existe. El contrato de datos exacto está documentado en `PostaAI/CLAUDE.md`.

## Guardrails (reglas de trabajo)

Estas aplican siempre, en los dos sub-proyectos:

1. **Validar antes de proponer.** Nunca proponer una solución sin antes verificar (docs oficiales / internet) que se puede hacer de verdad. Nada de suposiciones que después en la implementación resulten falsas.
2. **Voz rioplatense en todo el contenido.** Digest, reels y copy de la app van en rioplatense argentino: "vos", "dale", "posta", "está buenísimo". Prohibido "tú", "vosotros", "guay", "chévere", "ordenador". (Esto aplica al *contenido del producto*, no a estas notas de dev.)
3. **Probar antes de cantar victoria.** Correr el pipeline o buildear la app y verificar el resultado real antes de decir "listo". No reportar éxito sin evidencia.

## Glosario

- **Drop**: la tanda de noticias de una edición (mañana o tarde). Tiene `date`, `edition`, `number` y un array de `cards`.
- **Card**: una noticia individual en la app (headline + take + contexto + take editorial + fuente).
- **Edición**: cada drop es "de la mañana" (09:00) o "de la tarde" (18:00).
- **digest** vs **reels**: el `digest` es el resumen para ponerse al día (audiencia técnica); los `reels` son ideas de contenido masivo/divulgativo para producir videos.
