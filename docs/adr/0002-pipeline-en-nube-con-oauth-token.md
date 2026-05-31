# El pipeline corre en la nube con CLAUDE_CODE_OAUTH_TOKEN

## Contexto

Hoy el pipeline corre en la Mac de Bauti vía launchd, usando `claude -p` con la suscripción Max (OAuth interactivo). Para un lanzamiento público el contenido tiene que salir 2x/día sí o sí; depender de que una laptop esté despierta a las 09:00 y 18:00 es un punto único de falla inaceptable.

## Decisión

El pipeline se mueve a un runner en la nube (GitHub Actions cron o un VPS chico) que dispara las 2 corridas diarias de forma independiente de la Mac. Se autentica con `CLAUDE_CODE_OAUTH_TOKEN` (generado con `claude setup-token`, válido ~1 año), lo que permite correr `claude -p` headless **sin API key y manteniendo la suscripción**. El Pool resultante se sube al CDN desde el mismo runner.

## Alternativas descartadas

- **Mac always-on**: cero migración y cero costo extra, pero un corte, un viaje o cerrar la laptop = sin drop. Sirve como stopgap para validar, no para sostener público.
- **API key (`ANTHROPIC_API_KEY`)**: headless y simple, pero saca de la suscripción y factura por token en cada corrida. Solo si el OAuth token da problemas.

## Consecuencias

- Hay que migrar secrets al runner: el OAuth token, la config de envío de mail, y credenciales del CDN.
- El token expira en ~1 año → recordatorio de rotación.
- **Desde el 15-jun-2026**, el uso de `claude -p` / Agent SDK en planes de suscripción sale de un crédito mensual de Agent SDK separado del uso interactivo. Presupuestar las corridas (2/día) contra ese crédito.
