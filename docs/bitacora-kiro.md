# Bitácora de uso de Kiro — Hauntcast Weather

> Este archivo registra cómo se usó Kiro durante el desarrollo.
> Se actualiza con cada uso notable: spec creado, hook añadido, servidor MCP usado,
> test de propiedad que encontró un bug, prompt que hizo una diferencia.
> El escrito final de la hackatón sale de aquí.

---

## 24 de noviembre de 2026

### Spec M0 · Cimientos — workflow requirements-first

**Qué se hizo con Kiro:**

- Se establecieron cinco steering files en `.kiro/steering/`: `product.md`, `tech.md`,
  `structure.md`, `hazards.md` y `workflow.md`. Estos archivos alimentan cada request de
  Kiro con el contexto completo del proyecto sin necesidad de repetirlo en cada prompt.
  El resultado: Kiro conoce los slugs de peligros, el stack tecnológico y las reglas de
  trabajo sin que haya que explicarlos.

- Se creó `requirements.md` para M0 con 11 requisitos usando el workflow requirements-first
  de Kiro. Las preguntas de clarificación del equipo llevaron a agregar el Requisito 11
  (lazy initialization del cliente Supabase), que no estaba en el backlog inicial. Sin Kiro,
  ese bug potencial no se habría descubierto hasta que `manage.py check` fallara en el CI.

- Se creó `design.md` para M0: Kiro investigó versiones compatibles de paquetes para
  Django 6.1, diseñó el patrón de lazy singleton para el cliente Supabase, y definió el
  código completo de `base.py` con el protocolo `WeatherProvider` y los dataclasses
  `HazardAlert` y `ProviderResult`.

- `integrations/weather_providers/base.py` fue scaffoldeado por Kiro a partir del diseño.
  El protocolo define el contrato de no-raise de `fetch_alerts` y el modelo `ProviderResult`
  que distingue "sin alertas activas" de "fuente caída", cumpliendo el principio
  "Never fake calm" del steering product.

- Se ejecutó `tasks.md` completo: 17 tareas en waves de ejecución paralela. Kiro generó y
  aplicó todos los cambios de código (settings, urls, supabase_client, base.py, decorador
  503, api-contract.md) y los tests de propiedad con Hypothesis.

**Impacto medible:** `python manage.py check` pasa con cero errores sin credenciales de
Supabase en el entorno. El servidor arranca. El contrato de la API está congelado y listo
para que Luciana avance con los mocks del frontend.
