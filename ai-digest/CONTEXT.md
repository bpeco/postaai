# ai-digest

Motor de contenido: junta noticias AI de 21 fuentes 2x/día, las rankea y genera el material editorial. Es el productor del **Pool** que consume PostaAI. Los términos del contrato entre contextos (Pool, Drop, Card, Edición, Interés) están en [CONTEXT-MAP.md](../CONTEXT-MAP.md).

## Language

**Fuente**:
Un origen de noticias (RSS, HN, Reddit, webfetch). Hay 21, con un peso que pondera su ranking.
_Avoid_: feed (ambiguo con el output), canal.

**Item**:
Una noticia cruda ya extraída y normalizada de una Fuente, antes de rankear y antes de convertirse en Card. Schema unificado interno del pipeline.
_Avoid_: noticia (reservada para la Card), entry.

**Generación del Pool**:
La fase que toma los Items rankeados y produce el **Pool** de Cards con voz rioplatense, cada una etiquetada con su Interés (Tema + Entidad). Es el "puente" hacia la app; corre como un `claude -p` con prompt propio. Reemplaza, para el producto, al viejo flujo de digest por email.
_Avoid_: bridge, conversión.

**digest / ideas / reels**:
Los tres outputs markdown históricos del pipeline (resumen técnico, ideas de Shorts, ideas de Reels masivos), entregados por email. Son para uso editorial de Bauti, distintos del **Pool** que consume la app.

## Diálogo de ejemplo

— ¿El reranking afecta el digest del email o el Pool?
— Los dos comen del mismo top rankeado de Items, pero son outputs distintos: el digest es markdown técnico para tu mail, el Pool es Cards etiquetadas para la app.
— ¿Y si una Fuente no produce nada de cierto Tema un día?
— No pasa nada: el Pool igual se llena con lo más rankeado, y la app reordena por Interés sin esconder lo grande.
