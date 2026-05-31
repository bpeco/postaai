# Producto entra como tercer eje seguible, y se establece la regla de los dos filtros

## Contexto

El modelo de personalización tenía dos ejes (Tema + Entidad). Surgió la necesidad de seguir **productos** específicos dentro de una org (Claude Code, ChatGPT, Codex, Cursor...), que un dev usa a diario y son un modelo mental distinto de "seguir a la org entera". A diferencia de Industria (diferida en ADR-0003) y de Personas, Producto pasó los dos filtros que ahora aplicamos como regla.

## Decisión

Se agrega **Producto** como tercer eje seguible, modelado **jerárquicamente** sobre Entidad:

- La Card suma un campo opcional `product: String?` (lista curada ~10: Claude Code, Claude Desktop, ChatGPT, Codex, Cursor, Copilot, Gemini app, Perplexity, v0, Windsurf — editable).
- El `tag` sigue siendo la org (la pill coloreada). Producto se muestra como metadata secundaria (texto), no como pill propia.
- En el onboarding va como **sección secundaria/colapsable**, no obligatoria. Solo Tema es obligatorio.
- El filtro matchea "lo tuyo" si la Card matchea **cualquiera** de las selecciones del usuario: tema ∨ org ∨ producto.

Y queda establecido como principio durable la **regla de los dos filtros** para agregar cualquier eje futuro:

1. **Filtro de supply**: las fuentes actuales producen contenido para ese eje con frecuencia suficiente. (Industria falló acá.)
2. **Filtro de valor único**: el eje captura un modelo mental que los ejes existentes no cubren. (Personas falló acá: news de Altman ≈ news de OpenAI.)

Solo se agrega un eje al producto si pasa **ambos** filtros.

## Consecuencias

- Schema: `Card.product` (opcional). El generador lo emite solo cuando la card es claramente sobre un producto específico de la lista.
- Display: la Card muestra "Org · Producto" cuando aplica; pill coloreada sigue siendo solo la Org.
- Onboarding: 3 secciones de chips (Tema obligatoria, Entidad opcional, Producto opcional/colapsada).
- Cuando vuelvan a aparecer pedidos de eje nuevo (Industria, Personas, Idioma, Región...), se evalúan contra la regla de los dos filtros antes de decidir.
