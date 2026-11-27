-- seed_recommendations.sql
-- Populates prevention_recommendations for the 11 MVP hazards × (PE, US, MX).
-- Also populates emergency_numbers for PE, US and MX.
--
-- Language: English only. The frontend handles language switching.
--
-- Schema columns used (supabase/schema.sql):
--   prevention_recommendations:
--     id          uuid PK (generated)
--     category_id uuid FK → weather_categories.id  ← resolved by subquery on code
--     severity    varchar(20) CHECK IN (INFO, LOW, MODERATE, HIGH, CRITICAL)
--     title       varchar(200)  format: "<Phase> · <country_code> · <source>"
--     description text          action text in English
--
--   emergency_numbers:
--     country_code  text  PK (part)
--     label         text
--     number        text  PK (part)
--     source_name   text
--     source_url    text
--     verified_at   date
--
-- Title convention:
--   "Before · PE · INDECI"    what to do before the hazard, Peru
--   "During · US · Ready.gov" what to do during the hazard, United States
--   "After  · MX · CENAPRED"  what to do after the hazard, Mexico
--
-- Severity mapping:
--   CRITICAL → ciclon_tropical, tornado, sismo
--   HIGH     → huayco, inundacion, tormenta_electrica, viento_fuerte
--   MODERATE → lluvia_intensa, helada, ola_calor, radiacion_uv
--
-- Idempotent: WHERE NOT EXISTS on (category_id, title, description).
-- Combinations with no applicable official guidance are intentionally omitted
-- (e.g. huayco for US/MX, tornado for PE/MX) and return HTTP 404 from the API.

-- ═════════════════════════════════════════════════════════════════════════════
-- lluvia_intensa  (MODERATE)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Clear gutters and drains around your home to prevent blockages.'),
       ('Identify low-lying areas near you that are prone to water accumulation.'),
       ('Prepare an emergency kit with a flashlight, drinking water and important documents.'),
       ('Reinforce roofs and walls that show signs of water leakage.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Stay indoors and keep away from windows.'),
       ('Do not cross rivers, ravines or flooded streets on foot or by vehicle.'),
       ('Unplug electrical appliances if water enters your home.'),
       ('Monitor National Radio and your municipality''s early warning system.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Do not enter flooded areas until authorities confirm it is safe.'),
       ('Check for structural damage to your home before re-entering.'),
       ('Report damage to your municipality or INDECI to access humanitarian assistance.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Sign up for local emergency alerts and monitor NOAA Weather Radio.'),
       ('Clear drains and gutters near your home before storm season.'),
       ('Move valuables to higher floors if you live in a flood-prone area.'),
       ('Keep a 72-hour emergency kit with water, food, medications and documents.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Stay indoors and away from windows during heavy rain.'),
       ('Never drive through flooded roads — Turn Around, Don''t Drown.'),
       ('Avoid walking through moving water; six inches can knock you down.'),
       ('Unplug appliances and avoid using the phone during lightning.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Wait for official all-clear before returning to evacuated areas.'),
       ('Document damage with photos before cleaning up for insurance purposes.'),
       ('Avoid contact with floodwater — it may be contaminated.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Register the emergency number of your municipality''s Civil Protection office.'),
       ('Clear rooftop drains and gutters before the rainy season begins.'),
       ('Prepare an emergency kit with water, medications and documents.'),
       ('Learn the evacuation routes in your neighborhood.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Stay in a safe place away from windows.'),
       ('Do not cross fords or streams with current, even if they look shallow.'),
       ('Cut the electrical supply if water enters your home.'),
       ('Tune in to local radio or the National Meteorological Service (SMN) alerts.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Do not return to affected areas until Civil Protection authorizes it.'),
       ('Report damage to the local emergency number or Civil Protection (800-900-2024).'),
       ('Do not drink tap water until its quality is officially certified.')
     ) AS t(action)
WHERE wc.code = 'lluvia_intensa'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- huayco  (HIGH — PE only)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Identify whether your home is near a ravine, dry riverbed or steep slope.'),
       ('Learn your district''s evacuation routes and the nearest meeting point.'),
       ('Do not build or store materials in ravine channels.'),
       ('Stay informed through SENAMHI advisories and your municipality.')
     ) AS t(action)
WHERE wc.code = 'huayco'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Move away immediately from ravines, channels and slopes when heavy rain begins.'),
       ('Do not attempt to cross an active debris flow on foot or by vehicle.'),
       ('Climb to upper floors or higher ground if the flow approaches.'),
       ('Alert neighbors and call 115 (INDECI) or 116 (Fire Department) if people are trapped.')
     ) AS t(action)
WHERE wc.code = 'huayco'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Do not return to your home until INDECI or your municipality confirms it is safe.'),
       ('Report structural damage to infrastructure (bridges, roads) to your municipality.'),
       ('Disinfect with bleach any surface that came into contact with mud before using it.')
     ) AS t(action)
WHERE wc.code = 'huayco'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · INDECI' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- inundacion  (HIGH)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Check whether your home is in a flood zone using your municipality''s risk map.'),
       ('Move furniture and electrical items to upper floors if a flood advisory is issued.'),
       ('Store drinking water and non-perishable food for at least 3 days.'),
       ('Know the location of the temporary shelters in your district.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Evacuate immediately if authorities order it; do not wait to see the water level.'),
       ('Never walk or drive through flooded streets; water can hide open manholes.'),
       ('Shut off electricity at the main panel if water reaches the outlets.'),
       ('Stay in contact with family and follow INDECI instructions.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Wait for official authorization before returning to your home.'),
       ('Wear rubber boots and gloves when cleaning; floodwater may contain pathogens.'),
       ('Photograph damage before cleaning up to support assistance claims.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Know your property''s flood risk at msc.fema.gov/portal.'),
       ('Consider flood insurance — standard homeowner''s insurance does not cover flooding.'),
       ('Install check valves in plumbing to prevent floodwater from backing up.'),
       ('Prepare an emergency kit and identify two evacuation routes from your home.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Evacuate immediately if told to do so by local authorities.'),
       ('Do not walk, swim or drive through flood waters — 6 inches of moving water can knock you down.'),
       ('Disconnect electrical appliances; do not touch electrical equipment if wet.'),
       ('Stay off bridges over fast-moving water.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Return home only when authorities say it is safe.'),
       ('Document all damage with photos before cleaning up.'),
       ('Discard food that may have come in contact with floodwater.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Check the National Risk Atlas to see if your neighborhood is in a flood zone.'),
       ('Store important documents in waterproof bags or at an elevated location.'),
       ('Learn how to shut off the gas and electricity in your home.'),
       ('Register the emergency numbers of your municipality''s Civil Protection office.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Evacuate as soon as authorities instruct; do not underestimate water speed.'),
       ('Do not cross fords or flooded zones by vehicle.'),
       ('Shut off the electrical supply at the panel if water threatens to enter.'),
       ('Call 911 if people are trapped or injured.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Wait for Civil Protection''s all-clear before returning.'),
       ('Clean and disinfect all surfaces that came into contact with floodwater.'),
       ('Boil drinking water until the supply is officially certified safe.')
     ) AS t(action)
WHERE wc.code = 'inundacion'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- tormenta_electrica  (HIGH)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Keep electronics unplugged when a thunderstorm is forecast.'),
       ('Identify nearby safe shelters: solid buildings, not trees or open metal structures.'),
       ('Avoid outdoor activities when SENAMHI issues a thunderstorm advisory.')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Seek shelter in a solid building or a closed vehicle with windows up.'),
       ('Do not lean against exterior walls, windows or metal objects.'),
       ('If outdoors with no shelter, crouch with feet together away from tall trees.'),
       ('Do not use landline phones or devices connected to the power grid during the storm.')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Wait at least 30 minutes after the last thunder before going outside.'),
       ('Check for electrical damage in your home before plugging in appliances.'),
       ('Report downed poles or cables to the electricity distributor or call 105 (PNP).')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Check weather forecasts before outdoor activities and have an indoor plan.'),
       ('Unplug electronics and appliances before a storm arrives.'),
       ('Avoid tall isolated trees, hilltops, open fields and bodies of water during a storm.')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Go inside a substantial building or a hard-topped vehicle immediately.'),
       ('Stay away from windows, doors and electrical equipment.'),
       ('If caught outdoors, crouch low with feet together — do not lie flat on the ground.'),
       ('Do not use corded phones or plumbing during a thunderstorm.')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Wait 30 minutes after the last thunder before going outside.'),
       ('Never touch a downed power line — call 911 and your utility company.'),
       ('Check for damage to your home''s electrical system before turning things back on.')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Check the SMN forecast before outdoor activities.'),
       ('Unplug electronics and antennas before the storm.'),
       ('Identify solid nearby buildings you can use as shelter.')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Enter a solid building or closed car; do not shelter under trees.'),
       ('Stay away from poles, antennas, metal fences and bodies of water.'),
       ('If in open ground, crouch with feet together and head down; do not lie flat.')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Wait at least 30 minutes after the last thunder before going outside.'),
       ('Report downed cables or poles to CFE (071) or 911.'),
       ('Check for electrical installation damage before using appliances.')
     ) AS t(action)
WHERE wc.code = 'tormenta_electrica'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- helada  (MODERATE)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Provide adequate warm clothing for children, elderly and people with respiratory conditions.'),
       ('Protect crops and livestock with blankets or shelters before nightfall.'),
       ('Store water in closed containers to prevent it from freezing.'),
       ('Check your home for cold-air gaps around doors and windows.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Stay indoors and dress in layers; cover extremities, head and neck.'),
       ('Do not use charcoal braziers or burn materials indoors — risk of CO poisoning.'),
       ('If you must go out, minimize time exposed to the cold.'),
       ('Stay hydrated with warm drinks; cold reduces the sensation of thirst.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Inspect crops and livestock; report losses to MIDAGRI for assistance.'),
       ('Check water pipes for cracks caused by freezing.'),
       ('Seek immediate medical attention for hypothermia symptoms: intense shivering, confusion or blue skin.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Weatherize your home: insulate pipes, seal drafts around doors and windows.'),
       ('Bring pets inside and protect outdoor plants before temperatures drop.'),
       ('Stock extra blankets, warm clothing and a few days of food and water.'),
       ('Check on elderly neighbors and those without adequate heating.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Stay indoors; if you must go out, dress in loose warm layers and cover extremities.'),
       ('Never use a generator, grill or camp stove indoors — carbon monoxide is deadly.'),
       ('Watch for frostbite (numbness, white or grayish skin) and hypothermia (shivering, confusion).'),
       ('Keep moving to maintain body heat if stranded outdoors.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Thaw frozen pipes slowly with warm air — never use an open flame.'),
       ('Seek medical attention immediately if you suspect hypothermia or frostbite.'),
       ('Report utility outages to your local power company.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Provide warm clothing for vulnerable groups: children, elderly and people with chronic illness.'),
       ('Wrap exposed pipes with fabric or foam insulation.'),
       ('Shelter livestock and pets in covered areas.'),
       ('Stock firewood, blankets and food for several days in highland zones.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Dress in layers and cover your head, hands and feet when going outside.'),
       ('Do not burn charcoal or use braziers in closed rooms.'),
       ('If you feel numbness, intense chills or confusion, seek warmth and medical care.'),
       ('Stay hydrated even if you do not feel thirsty; cold masks dehydration.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Check for frozen or burst pipes and report them to the municipal water authority.'),
       ('Go to the nearest health center if you experience hypothermia symptoms.'),
       ('Report crop damage to SENASICA to access government support.')
     ) AS t(action)
WHERE wc.code = 'helada'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- ola_calor  (MODERATE)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · PE · CENEPRED', action
FROM weather_categories wc,
     (VALUES
       ('Identify the nearest health centers and their opening hours.'),
       ('Store enough cool water for the whole family, especially children and elderly.'),
       ('Close blinds and curtains during peak heat hours (10 am–4 pm).'),
       ('Avoid scheduling intense physical activities outdoors during peak heat.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · CENEPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · PE · CENEPRED', action
FROM weather_categories wc,
     (VALUES
       ('Stay hydrated by drinking water frequently, even if you do not feel thirsty.'),
       ('Seek cool places: air-conditioned shopping centers, libraries or health centers.'),
       ('Wear light, loose, light-colored clothing made of breathable fabrics.'),
       ('Never leave children or pets inside a parked vehicle.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · CENEPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · PE · CENEPRED', action
FROM weather_categories wc,
     (VALUES
       ('Seek immediate medical attention for heat stroke signs: high body temperature, dry skin, confusion.'),
       ('Report isolated elderly or vulnerable people to your municipality''s social services.'),
       ('Continue drinking more fluids than usual until temperatures return to normal.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · CENEPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Never leave children, pets or vulnerable adults in a parked car.'),
       ('Know the location of your nearest cooling center — check with your local health department.'),
       ('Install window air conditioners and check that they work before summer.'),
       ('Check on elderly neighbors and those without air conditioning daily during heat advisories.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Stay in air-conditioned spaces as much as possible.'),
       ('Drink plenty of fluids; avoid alcohol and caffeine, which cause dehydration.'),
       ('Wear lightweight, light-colored, loose-fitting clothing.'),
       ('Reschedule strenuous outdoor activities to early morning or evening.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Call 911 immediately if someone shows signs of heat stroke: high body temperature, hot dry skin, confusion.'),
       ('Cool the person with cool water and fan them until help arrives.'),
       ('Continue drinking extra fluids for the rest of the day.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Ventilate homes by closing blinds during the day and opening windows at night.'),
       ('Store cool drinking water and ensure access to oral rehydration salts.'),
       ('Schedule physical activities in the early morning or after dark.'),
       ('Check on elderly people and those living alone.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Drink water frequently even if you do not feel thirsty; avoid alcohol.'),
       ('Wear light, light-colored clothing; cover yourself with a hat or cap in the sun.'),
       ('Go to cool public spaces (shopping centers, libraries) if you have no air conditioning.'),
       ('Apply cool water to your body or use damp towels on your neck and wrists.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Call 911 if someone presents heat stroke: hot dry skin, high fever, confused state.'),
       ('Continue hydrating above normal levels until temperatures return to normal.'),
       ('Report serious cases to the nearest health center for epidemiological follow-up.')
     ) AS t(action)
WHERE wc.code = 'ola_calor'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- radiacion_uv  (MODERATE)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · PE · CENEPRED', action
FROM weather_categories wc,
     (VALUES
       ('Check the daily UV index on the SENAMHI website before going outside.'),
       ('Apply SPF 50+ sunscreen to all exposed skin at least 20 minutes before going out.'),
       ('Wear a wide-brim hat, UV-protection sunglasses and long-sleeved clothing.'),
       ('Schedule outdoor activities outside peak UV hours (10 am–4 pm).')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · CENEPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · PE · CENEPRED', action
FROM weather_categories wc,
     (VALUES
       ('Seek shade whenever possible; do not rely on clouds to block UV radiation.'),
       ('Reapply sunscreen every 2 hours, or after sweating or getting wet.'),
       ('Keep infants and young children in full shade; their skin is highly sensitive.'),
       ('Stay hydrated with water frequently.')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · CENEPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · PE · CENEPRED', action
FROM weather_categories wc,
     (VALUES
       ('For sunburn, apply cool compresses and moisturizer; do not pop blisters.'),
       ('See a doctor if the burn covers large areas or is accompanied by fever.'),
       ('Have annual dermatological check-ups if you are frequently exposed to high UV.')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · CENEPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Check the UV Index forecast at weather.gov or the EPA SunWise program.'),
       ('Apply broad-spectrum SPF 30+ sunscreen 15 minutes before going outside.'),
       ('Wear UV-blocking sunglasses, a wide-brim hat and tightly woven loose clothing.'),
       ('Schedule outdoor activities before 10 am or after 4 pm when UV is lower.')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Seek shade, especially during peak UV hours (10 am–4 pm).'),
       ('Reapply sunscreen every 2 hours, or after swimming or sweating.'),
       ('Keep infants out of direct sunlight entirely; use strollers with hoods.')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Treat sunburn with cool compresses and aloe vera gel; avoid breaking blisters.'),
       ('See a doctor if the burn is severe, blistered or accompanied by fever.'),
       ('Conduct regular skin self-exams and see a dermatologist annually if you have high UV exposure.')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Check the SMN UV index before going out, especially between March and October.'),
       ('Apply SPF 50+ sunscreen before any prolonged sun exposure.'),
       ('Wear a hat, UV-filter glasses and long-sleeved shirts during high-radiation hours.'),
       ('Avoid direct sun exposure between 11 am and 3 pm.')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Actively seek shade; remember that UV radiation penetrates clouds.'),
       ('Reapply sunscreen every 2 hours or after bathing.'),
       ('Give extra protection to children and fair-skinned people, who are more susceptible.')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'MODERATE', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Apply cool compresses and moisturizer for sunburn.'),
       ('See a doctor if there are extensive blisters or fever associated with the burn.'),
       ('Have regular dermatological check-ups if you work or exercise outdoors.')
     ) AS t(action)
WHERE wc.code = 'radiacion_uv'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- viento_fuerte  (HIGH)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Secure or store objects that could become projectiles (pots, signs, garden furniture).'),
       ('Inspect the condition of roofs, antennas and trees near your home.'),
       ('Close doors and windows tightly when strong gust advisories are issued.'),
       ('Stay informed through SENAMHI advisories.')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Stay indoors and away from windows and glass doors.'),
       ('Avoid areas with trees, hanging signs or buildings under construction.'),
       ('If driving, slow down and keep distance from high-profile vehicles (buses, trucks).'),
       ('Do not shelter under light metal structures (awnings, temporary sheds).')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Check for damage to your home''s structure before restoring utilities.'),
       ('Report downed poles or cables to the electricity distributor or call 105 (PNP).'),
       ('Prune or remove broken branches that pose a risk on your property.')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Secure or bring in outdoor furniture, decorations and garbage cans before high winds arrive.'),
       ('Trim trees and shrubs near your home to reduce the risk of falling limbs.'),
       ('Check that your garage door is reinforced — it is a common failure point in high winds.')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Stay indoors and away from windows.'),
       ('Avoid driving, especially in high-profile vehicles, during gusts above 45 mph.'),
       ('Stay clear of downed power lines — always assume they are live.')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Inspect your roof and siding for damage before turning on HVAC or fireplace.'),
       ('Report downed power lines to your utility company and do not approach them.'),
       ('Document property damage with photos for insurance claims.')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Secure or store objects that could become projectiles in the wind.'),
       ('Inspect roofs and antennas; reinforce anything that is loose.'),
       ('Close blinds and windows before gusts arrive.')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Stay indoors and away from glass windows and doors.'),
       ('Avoid areas with tall trees, power poles or buildings under construction.'),
       ('If driving, slow down and keep both hands on the wheel.')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'HIGH', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Check for damage to electrical and gas installations before using them.'),
       ('Report downed poles or cables to 911 or CFE (071).'),
       ('Remove debris from your property carefully; use gloves and sturdy footwear.')
     ) AS t(action)
WHERE wc.code = 'viento_fuerte'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- ciclon_tropical  (CRITICAL — US and MX only)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Know your evacuation zone and route before hurricane season begins (June 1).'),
       ('Prepare a hurricane kit: water (1 gallon/person/day for 7 days), food, medications, documents.'),
       ('Board up windows or install hurricane shutters.'),
       ('Fill your gas tank and withdraw cash before a storm watch is issued.')
     ) AS t(action)
WHERE wc.code = 'ciclon_tropical'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Evacuate immediately if ordered — do not wait to see the storm.'),
       ('If sheltering in place, stay in an interior room away from windows.'),
       ('Do not go outside during the eye of the storm — dangerous winds return quickly.'),
       ('Avoid flood waters; storm surge is the leading cause of hurricane deaths.')
     ) AS t(action)
WHERE wc.code = 'ciclon_tropical'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Wait for official all-clear before returning to evacuated areas.'),
       ('Do not use generators, grills or camp stoves indoors — carbon monoxide is lethal.'),
       ('Photograph all damage before cleanup for FEMA and insurance claims.')
     ) AS t(action)
WHERE wc.code = 'ciclon_tropical'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Know your coastal municipality''s evacuation plan before cyclone season.'),
       ('Prepare an emergency kit with water, food, medications, documents and cash.'),
       ('Board up windows and reinforce doors.'),
       ('Fill your water tank and fuel tank in advance.')
     ) AS t(action)
WHERE wc.code = 'ciclon_tropical'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Evacuate as soon as Civil Protection instructs; follow official routes.'),
       ('If staying at home, move to an interior room without windows.'),
       ('Do not go outside during the eye of the cyclone; winds will return within minutes.'),
       ('Stay away from the coast: storm surge can exceed several meters.')
     ) AS t(action)
WHERE wc.code = 'ciclon_tropical'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Return only when authorities authorize it.'),
       ('Do not use generators or braziers in closed indoor spaces.'),
       ('Report damage to Civil Protection to access government relief funds.')
     ) AS t(action)
WHERE wc.code = 'ciclon_tropical'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- tornado  (CRITICAL — US only)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Identify the safest room in your home: a basement, storm cellar or interior room on the lowest floor.'),
       ('Practice a tornado drill with your family so everyone knows where to go.'),
       ('Invest in a weather alert radio that activates automatically for tornado warnings.'),
       ('Mobile homes are not safe during tornadoes — know the location of the nearest shelter.')
     ) AS t(action)
WHERE wc.code = 'tornado'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Go immediately to your designated safe room when a tornado warning is issued.'),
       ('Get under a sturdy table and protect your head and neck with your arms.'),
       ('Do not open windows — this wastes time and does not equalize pressure.'),
       ('If outdoors or in a vehicle, do not try to outrun a tornado; lie flat in a ditch and cover your head.')
     ) AS t(action)
WHERE wc.code = 'tornado'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Stay in the shelter until the tornado warning expires and the all-clear is issued.'),
       ('Watch for hazards: downed power lines, broken glass and unstable structures.'),
       ('Document damage with photos before repairs for insurance and FEMA assistance.')
     ) AS t(action)
WHERE wc.code = 'tornado'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- sismo  (CRITICAL)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'Before · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Identify safe spots in your home: under a sturdy table or next to a structural column.'),
       ('Secure shelves, bookcases and heavy objects to walls to prevent them from falling.'),
       ('Prepare an emergency kit: water, food, flashlight, battery radio, first aid and documents.'),
       ('Learn to shut off the gas manually and keep an adjustable wrench near the valve.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'During · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Stay calm and take cover under a sturdy table or next to a column; protect your head.'),
       ('Do not use the elevator; do not run to the stairs while shaking continues.'),
       ('Move away from windows, shelves and objects that could fall.'),
       ('If outside, move away from buildings, poles and electrical cables.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'After · PE · INDECI', action
FROM weather_categories wc,
     (VALUES
       ('Exit the building calmly once shaking stops and go to your assembly point.'),
       ('Shut off the gas if you smell a leak; do not light candles or cigarettes.'),
       ('Do not re-enter the building until a technician confirms it is structurally safe.'),
       ('Call 115 (INDECI) only for real emergencies to avoid overloading the lines.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · PE · INDECI' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'Before · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Identify safe spots in each room: under a sturdy table or against an interior wall away from windows.'),
       ('Secure heavy furniture and appliances to walls with straps or L-brackets.'),
       ('Build an emergency kit with water, food, first aid, flashlight and important documents.'),
       ('Know how to shut off your gas supply and keep a wrench near the meter.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'During · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Drop, Cover and Hold On: drop to hands and knees, take cover under a sturdy table, hold on.'),
       ('Stay away from windows, exterior walls and anything that could fall.'),
       ('If indoors, stay there until shaking stops; most injuries occur when people try to move.'),
       ('If outdoors, move away from buildings, streetlights and utility wires.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'After · US · Ready.gov', action
FROM weather_categories wc,
     (VALUES
       ('Expect aftershocks — take cover again each time.'),
       ('Check for gas leaks; if you smell gas, open windows, leave and call the gas company.'),
       ('Do not use elevators; inspect your home for structural damage before re-entering.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · US · Ready.gov' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'Before · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Participate in earthquake drills on September 19 and those called by your municipality.'),
       ('Secure heavy furniture and tall shelves to walls; remove heavy objects from high shelves.'),
       ('Locate the gas shutoff valve and practice closing it.'),
       ('Prepare an emergency kit with water, food, medications and copies of documents.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'Before · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'During · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('When the seismic alert sounds, take cover under a sturdy table or next to a column.'),
       ('Do not run or use the elevator during shaking.'),
       ('If outside, move away from facades, poles and electrical cables.'),
       ('Protect your head with your arms if no table is available.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'During · MX · CENAPRED' AND pr.description = t.action
  );

INSERT INTO prevention_recommendations (category_id, severity, title, description)
SELECT wc.id, 'CRITICAL', 'After · MX · CENAPRED', action
FROM weather_categories wc,
     (VALUES
       ('Exit the building in an orderly way; go to your block''s assembly point.'),
       ('Shut off the gas if you smell a leak; do not strike matches or use electrical appliances.'),
       ('Wait for trained personnel to inspect the building before re-entering.'),
       ('Call 911 only for real emergencies; use social media to signal that you are safe.')
     ) AS t(action)
WHERE wc.code = 'sismo'
  AND NOT EXISTS (
    SELECT 1 FROM prevention_recommendations pr
    WHERE pr.category_id = wc.id AND pr.title = 'After · MX · CENAPRED' AND pr.description = t.action
  );

-- ═════════════════════════════════════════════════════════════════════════════
-- emergency_numbers
-- Schema: (country_code, label, number, source_name, source_url, verified_at)
-- PK: (country_code, number)
-- CHECK: country_code ~ '^[A-Z]{2}$'
-- ═════════════════════════════════════════════════════════════════════════════

-- Remove national numbers that were previously seeded with incorrect or outdated coverage.
DELETE FROM emergency_numbers
WHERE (country_code = 'PE' AND number = '911')
   OR (country_code = 'MX' AND number IN ('800-900-2024', '065'));

INSERT INTO emergency_numbers (country_code, label, number, source_name, source_url, verified_at) VALUES

('PE', 'Fire Department (Bomberos)', '116',
 'Policia Nacional del Peru - emergency numbers', 'https://www.gob.pe/institucion/pnp/contacto-y-numeros-de-emergencias', '2026-11-26'),
('PE', 'National Police (PNP)', '105',
 'Policia Nacional del Peru', 'https://www.gob.pe/institucion/pnp/contacto-y-numeros-de-emergencias', '2026-11-26'),
('PE', 'SAMU medical emergencies (availability varies by region)', '106',
 'Ministerio de Salud del Peru', 'https://www.gob.pe/institucion/minsa/contacto-y-numeros-de-emergencias', '2026-11-26'),
('PE', 'Civil Defense emergencies', '115',
 'Presidencia del Consejo de Ministros - Peru emergency numbers', 'https://www.gob.pe/547', '2026-11-26'),

('US', 'Emergency services (police / fire / ambulance)', '911',
 'USAGov', 'https://www.usa.gov/report-crime', '2026-11-26'),
('US', 'FEMA disaster assistance (non-immediate emergencies)', '1-800-621-3362',
 'USAGov - Federal Emergency Management Agency', 'https://www.usa.gov/agencies/federal-emergency-management-agency', '2026-11-26'),
('US', 'Poison Control Center', '1-800-222-1222',
 'Poison Help', 'https://www.poisonhelp.org', '2026-11-26'),

('MX', 'Emergency services (police / fire / ambulance)', '911',
 'Secretaria de Gobernacion - 911 Emergencias', 'https://www.gob.mx/911/articulos/servicio-de-atencion-de-llamadas-de-emergencias-9-1-1?idiom=es', '2026-11-26')

ON CONFLICT (country_code, number) DO UPDATE
SET label = EXCLUDED.label,
    source_name = EXCLUDED.source_name,
    source_url = EXCLUDED.source_url,
    verified_at = EXCLUDED.verified_at;
