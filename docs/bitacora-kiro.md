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

---

## 25 de noviembre de 2026

### Spec M1 · Catálogo de fenómenos y recomendaciones — ciclo completo con Kiro

**Qué se hizo con Kiro:**

#### 1. Spec inicial de M1

Se creó la spec completa de M1 (`requirements.md`, `design.md`, `tasks.md`) a partir del
README y del contrato en `docs/api-contract.md`. El proceso detectó de inmediato una
divergencia que no era evidente en el README: la spec asumió columnas (`slug`, `name_es`,
`name_en`, `group`, `mvp`) que no existían en el schema real de Supabase. Esa discrepancia
habría bloqueado la ejecución de los seeds si se hubiera descubierto tarde.

#### 2. Seeds v1 — primer intento

Kiro generó `seed_hazards.sql` y `seed_recommendations.sql` usando las columnas de la spec
inicial. Al incorporar el `schema.sql` real exportado de Supabase, se detectó que las tablas
tienen una estructura distinta:

- `weather_categories` usa `code` (no `slug`) como identificador único, y no tiene columnas
  `name_es`, `name_en`, `group`, `mvp` ni `icon`.
- `prevention_recommendations` usa `category_id` (UUID FK), `severity`, `title` y
  `description` — no arrays `before[]`/`during[]`/`after[]` ni `country_code`.

Kiro rediseñó la estrategia de almacenamiento en lugar de proponer una migración de schema:
los metadatos de grupo y MVP se codifican en el campo `description` existente como
`"group:water | mvp:true | ..."`, y cada acción de recomendación se guarda como una fila
individual en `prevention_recommendations`, con la fase, el país y la fuente codificados en
`title` siguiendo el formato `"Before · PE · INDECI"`.

#### 3. Repositorios y vistas (R4, R5, R6)

Kiro implementó cuatro clases nuevas:

- `HazardCategoryRepository` con `list_all()` y `get_by_slug()`.
- `RecommendationRepository` con `get_by_slug_and_country()` (que resuelve el UUID de
  categoría, filtra por token de país en `title` y agrupa las filas por fase) y
  `list_by_hazard()`.
- `EmergencyNumberRepository` con `list_by_country()`.
- `HazardListView` y `RecommendationDetailView` con validación completa de parámetros.

Un punto que Kiro detectó al ejecutar las pruebas: el decorator `handle_supabase_unavailable`
en `core/exceptions.py` solo capturaba `SupabaseNotConfiguredError`. Con credenciales
presentes pero schema incorrecto, `postgrest.exceptions.APIError` escapaba y producía un 500.
Kiro amplió el decorator para capturar también `APIError` y `httpx.HTTPError`, convirtiendo
ambos en HTTP 503. Esto alineó el comportamiento con el principio "Never fake calm" para todos
los escenarios de falla de Supabase, no solo el de credenciales ausentes.

#### 4. Revisión de alineación con el schema

Al revisar los repositorios y vistas contra el schema real, se encontraron referencias
residuales a columnas inexistentes (`icon` en los `SELECT`, `_split_bilingual_name` en la
vista para nombres bilingües). Kiro los eliminó en una pasada limpia:

- `_split_bilingual_name()` eliminada: `name` ya es solo inglés.
- `_build_hazard_payload()` simplificada: lee `code` → `slug`, `name` → `name_en`, y parsea
  `description` con dos regex para `group` y `mvp`.
- `SELECT` de repositorios actualizados para no pedir `icon`.

#### 5. Decisión de idioma único

A mitad del módulo el equipo decidió almacenar todo el contenido en inglés y delegar el
cambio de idioma al frontend. Kiro actualizó en cadena:

- `seed_hazards.sql`: nombres de peligros de bilingüe (`"Lluvias intensas / Heavy rain"`) a
  solo inglés (`"Heavy rain"`).
- `seed_recommendations.sql`: 84 bloques de acciones reescritos de español (PE/MX) a inglés.
- `docs/api-contract.md`: shape de `/api/v1/hazards` actualizado — `name_es` eliminado,
  `name_en` es el único campo de nombre.
- Spec de M1 (`requirements.md`, `design.md`, `tasks.md`): todos los criterios y ejemplos
  actualizados al schema real y al idioma único.
- `README.md`: descripción de `weather_categories` y `prevention_recommendations` en la
  tabla de base de datos corregida a las columnas reales del schema.

#### 6. Verificación automática

Kiro escribió scripts de verificación para cada ciclo de cambios. El resultado final fue
37 checks en verde cubriendo: parseo de `description`, shape del payload (sin `name_es`,
sin `icon`), todos los códigos HTTP de ambos endpoints (200, 400×5, 404, 503), caché en
memoria del catálogo, y `python manage.py check` con cero errores.

**Impacto medible:** los endpoints `GET /api/v1/hazards` y `GET /api/v1/recommendations`
están implementados y verificados. Los seeds son idempotentes y ejecutables sobre el schema
real. El contrato de la API y la spec de M1 reflejan fielmente el código que existe en el
repositorio.
