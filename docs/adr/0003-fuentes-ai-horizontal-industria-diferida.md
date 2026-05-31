# Las fuentes son AI-horizontal: el filtro por Industria se difiere a v1.1

## Contexto

La visión de personalización incluía filtrar por Industria (fintech, salud, legal...). Pero las 21 fuentes del pipeline cubren la **industria de la AI** (labs, modelos, research, tooling), no **AI aplicada a verticales**. Evidencia: en un digest real (2026-05-18-18), 14 de 15 titulares eran AI horizontal; ninguno de salud/retail/legal-no-AI.

## Decisión

El MVP filtra por dos dimensiones que las fuentes sí sostienen: **Tema** (sub-campos de AI) y **Entidad** (orgs). **Industria queda fuera del MVP**: un chip "salud" estaría vacío casi todos los días, y romper así una promesa en un onboarding obligatorio es el peor lugar para fallar. Industria entra en v1.1 **empaquetada con fuentes vertical-específicas** que le den supply real, no antes.

## Consecuencias

- Agregar Industria no es solo taxonomía: requiere trabajo de fuentes en `ai-digest` (parsing, pesos, dedup) — es la rama "extracción por-usuario / más fuentes" del roadmap.
- "Personas" como faceta seguible (Altman, Hassabis) también se difiere: hoy esas noticias caen en su org, que acumula más supply.
- Regla general que queda: **no se ofrece un chip de Interés que las fuentes no puedan llenar de forma consistente.**
