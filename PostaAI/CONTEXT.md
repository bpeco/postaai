# PostaAI

App iOS nativa (SwiftUI). Baja el **Pool** del CDN y arma el **Drop** personalizado de cada usuario filtrando on-device por sus **Intereses**. Los términos del contrato entre contextos (Pool, Drop, Card, Edición, Interés) están en [CONTEXT-MAP.md](../CONTEXT-MAP.md).

## Language

**Deck**:
La pila de Cards del Drop que el usuario recorre con swipe. Arriba van las Cards que matchean sus Intereses; abajo, la sección "también pasó hoy".
_Avoid_: feed, lista.

**También pasó hoy**:
La sección acotada del Deck, debajo de lo que matchea los Intereses, con lo más grande del resto del Pool. Garantiza que el Drop nunca quede vacío ni esconda la noticia importante.

**Decisión**:
Lo que el usuario hace con una Card al swipear: descartar (izquierda) o guardar (derecha). Las guardadas viven en el Archivo.
_Avoid_: voto, like.

**Archivo**:
Las Cards que el usuario guardó (swipe a la derecha). Persistido local en UserDefaults (`postaai.savedIds`).
_Avoid_: favoritos, bookmarks.

## Diálogo de ejemplo

— Si el usuario no eligió ningún Interés, ¿qué ve en el Deck?
— No puede: el onboarding es obligatorio, elige al menos uno (o "todos") antes de entrar.
— ¿Y si su Interés no aparece hoy en el Pool?
— El Deck arranca directo con "también pasó hoy" — nunca vacío. El Drop siempre tiene las Cards grandes de la Edición.
