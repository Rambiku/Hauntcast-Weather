---
inclusion: always
---

# Hazard catalog and Skull Scale

## Hazard slugs

These slugs are shared by the backend, the database, the frontend and the animation folders.
**Do not rename, add or remove slugs** without a PR approved by both teammates. MVP hazards must work for the demo.

| Slug | Hazard | Group | Sources | MVP |
|---|---|---|---|---|
| `lluvia_intensa` | Heavy rain | water | SENAMHI layer 5, NWS, SMN, Open-Meteo | yes |
| `huayco` | Debris flows / ravine activation | water | SENAMHI layer 2 | yes |
| `inundacion` | Floods and river overflow | water | SENAMHI layer 4, NWS, Open-Meteo Flood | yes |
| `tormenta_electrica` | Thunderstorms | water | NWS, Open-Meteo `weather_code` 95–99 | yes |
| `granizo` | Hail | water | NWS, Open-Meteo `weather_code` 96 and 99 | |
| `deslizamiento` | Landslides | water | NWS, estimated from accumulated rain | |
| `helada` | Frost | cold_heat | NWS, Open-Meteo minimum temperature, SMN | yes |
| `ola_calor` | Heat wave / extreme heat | cold_heat | NWS, Open-Meteo, SMN | yes |
| `radiacion_uv` | Extreme UV radiation | cold_heat | Open-Meteo `uv_index` | yes |
| `nevada` | Snow and blizzards | cold_heat | NWS, Open-Meteo `snowfall` | |
| `friaje` | Cold surge in the Peruvian Amazon (*friaje*) | cold_heat | Estimated with Open-Meteo | |
| `viento_fuerte` | Strong winds and gusts | wind_sea | NWS, Open-Meteo `wind_gusts_10m`, SMN | yes |
| `ciclon_tropical` | Hurricanes and tropical cyclones | wind_sea | NWS, GDACS | yes |
| `tornado` | Tornadoes | wind_sea | NWS | yes |
| `oleaje` | Abnormal waves and storm surge | wind_sea | NWS, Open-Meteo Marine | |
| `tsunami` | Tsunamis | wind_sea | NWS | |
| `sismo` | Recent earthquakes | earth_fire_air | USGS | yes |
| `incendio_forestal` | Wildfire risk | earth_fire_air | SENAMHI layer 3, NWS, GDACS | |
| `volcan` | Volcanic activity and ash fall | earth_fire_air | NWS, GDACS | |
| `niebla` | Dense fog | earth_fire_air | NWS, Open-Meteo `visibility` | |
| `polvo` | Dust and sand storms | earth_fire_air | NWS, estimated from wind | |
| `calidad_aire` | Poor air quality or smoke | earth_fire_air | Open-Meteo Air Quality | |
| `sequia` | Drought | earth_fire_air | GDACS | |

## Skull Scale (0–4)

| Level | Name (EN / ES) | Phase 2 indicator | Color |
|---|---|---|---|
| 0 | Calm / Calma | Sleeping ghost | Purple |
| 1 | Watchful / Atento | Lit pumpkin | Green |
| 2 | Caution / Precaución | Restless ghost | Yellow |
| 3 | Danger / Peligro | Skeleton | Orange |
| 4 | Extreme / Extremo | The Grim Reaper | Red |

### Mapping from sources

| Source | Rule |
|---|---|
| SENAMHI layers 2 and 5 | `NIVEL` "Nivel 1" → 1, "Nivel 2" → 2, "Nivel 3" → 3, "Nivel 4" → 4 |
| SENAMHI layer 4 (rivers) | Map by `COLOR_TEXT`, **not** by `NIVEL` (its numbers use a different scale): AMARILLO → 2, NARANJA → 3, ROJO → 4 |
| NWS | `severity`: Minor → 1, Moderate → 2, Severe → 3, Extreme → 4, Unknown → 2. Map `event` (e.g. "Flash Flood Warning") to a slug |
| Estimated (Open-Meteo, SMN) | Thresholds defined in the M3 spec, capped at level 3 |

### Invariants (test them with property-based tests)

- Every mapped level is an integer from 0 to 4.
- The overall level of a place is the **maximum** level of its active alerts (0 when there are none and all sources answered).
- Unknown or malformed input **never lowers** the risk: it maps to level 2.
- Estimated alerts never exceed level 3; level 4 is reserved for official alerts.
- Deduplicating alerts is idempotent: running it twice gives the same result as running it once.
