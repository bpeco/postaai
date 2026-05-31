# Personalización por Pool etiquetado + filtro on-device, entregado por CDN estático

## Contexto

El MVP apunta a un lanzamiento público en App Store donde cada usuario elige Intereses (Tema + Entidad) y ve contenido relevante a eso. Los docs previos asumían "contenido global e idéntico" y posponían la personalización; este MVP la pone en el centro, así que hay que decidir cómo se realiza sin sobre-construir.

## Decisión

El pipeline genera **un solo Pool** de ~30-40 Cards por Edición, cada una etiquetada con metadata de Interés (Tema, alineado a `kind`; Entidad, alineada a `tag`). El Pool se publica como **JSON estático en un CDN**. La app lo baja entero y arma el **Drop** del usuario **on-device**: las Cards que matchean sus Intereses arriba, y abajo una sección acotada "también pasó hoy" con lo más grande del resto (modelo **híbrido**, nunca esconde la noticia grande ni deja el Drop vacío). Los Intereses viven en el dispositivo (UserDefaults), no en un backend.

## Alternativas descartadas

- **Backend / Supabase sirviendo contenido**: innecesario mientras el contenido sea un Pool global y el filtro sea on-device. Se reconsiderará cuando lleguen cuentas o sync entre dispositivos.
- **Generación por-usuario** (una pasada de Claude por combinación de Intereses): N llamadas por Edición, más costo/latencia/falla. El filtro sobre un Pool único da la sensación de personalización a costo O(1).
- **Filtro duro (esconder lo que no matchea)**: con dos dimensiones de Interés y fuentes AI-only, arriesga Drops flacos o vacíos y hace perder noticias grandes off-topic.

## Consecuencias

- La generación debe etiquetar cada Card con un **vocabulario fijo de Intereses** compartido entre pipeline y app; texto libre del usuario no es filtrable.
- El paso de rank debe ensancharse de top-15 a ~30-40 para alimentar el Pool.
- Sin backend no hay sync de Intereses entre dispositivos ni analytics central en el MVP.
