--
-- PostgreSQL database dump
--

\restrict z7bdm90cwuX8aHYnAts7SCf4RTVeE9PMf9bMpqxsXFOg6WsQIa9HyzmfrDEbqTt

-- Dumped from database version 17.12
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    iso_code character(2) NOT NULL,
    timezone character varying(100),
    created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE ONLY public.countries ALTER COLUMN id SET (pg_attver=134243312);
ALTER TABLE ONLY public.countries ALTER COLUMN name SET (pg_attver=134243312);
ALTER TABLE ONLY public.countries ALTER COLUMN iso_code SET (pg_attver=134243312);
ALTER TABLE ONLY public.countries ALTER COLUMN timezone SET (pg_attver=134243312);
ALTER TABLE ONLY public.countries ALTER COLUMN created_at SET (pg_attver=134243312);


--
-- Name: emergency_numbers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emergency_numbers (
    country_code text NOT NULL,
    label text NOT NULL,
    number text NOT NULL,
    source_name text NOT NULL,
    source_url text NOT NULL,
    verified_at date DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT emergency_numbers_country_code_check CHECK ((country_code ~ '^[A-Z]{2}$'::text))
);
ALTER TABLE ONLY public.emergency_numbers ALTER COLUMN country_code SET (pg_attver=1174431608);
ALTER TABLE ONLY public.emergency_numbers ALTER COLUMN label SET (pg_attver=1174431608);
ALTER TABLE ONLY public.emergency_numbers ALTER COLUMN number SET (pg_attver=1174431608);
ALTER TABLE ONLY public.emergency_numbers ALTER COLUMN source_name SET (pg_attver=1174431608);
ALTER TABLE ONLY public.emergency_numbers ALTER COLUMN source_url SET (pg_attver=1174431608);
ALTER TABLE ONLY public.emergency_numbers ALTER COLUMN verified_at SET (pg_attver=1174431608);


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    country_id uuid NOT NULL,
    name character varying(150) NOT NULL,
    region character varying(150),
    latitude numeric(10,7) NOT NULL,
    longitude numeric(10,7) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE ONLY public.locations ALTER COLUMN id SET (pg_attver=134331144);
ALTER TABLE ONLY public.locations ALTER COLUMN country_id SET (pg_attver=134331144);
ALTER TABLE ONLY public.locations ALTER COLUMN name SET (pg_attver=134331144);
ALTER TABLE ONLY public.locations ALTER COLUMN region SET (pg_attver=134331144);
ALTER TABLE ONLY public.locations ALTER COLUMN latitude SET (pg_attver=134331144);
ALTER TABLE ONLY public.locations ALTER COLUMN longitude SET (pg_attver=134331144);
ALTER TABLE ONLY public.locations ALTER COLUMN created_at SET (pg_attver=134331144);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    alert_id uuid NOT NULL,
    title character varying(200) NOT NULL,
    message text,
    status character varying(20) DEFAULT 'PENDING'::character varying,
    sent_at timestamp with time zone,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT notifications_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SENT'::character varying, 'FAILED'::character varying])::text[])))
);
ALTER TABLE ONLY public.notifications ALTER COLUMN id SET (pg_attver=134465880);
ALTER TABLE ONLY public.notifications ALTER COLUMN user_id SET (pg_attver=134465880);
ALTER TABLE ONLY public.notifications ALTER COLUMN alert_id SET (pg_attver=134465880);
ALTER TABLE ONLY public.notifications ALTER COLUMN title SET (pg_attver=134465880);
ALTER TABLE ONLY public.notifications ALTER COLUMN message SET (pg_attver=134465880);
ALTER TABLE ONLY public.notifications ALTER COLUMN status SET (pg_attver=134465880);
ALTER TABLE ONLY public.notifications ALTER COLUMN sent_at SET (pg_attver=134465880);
ALTER TABLE ONLY public.notifications ALTER COLUMN read_at SET (pg_attver=134465880);
ALTER TABLE ONLY public.notifications ALTER COLUMN created_at SET (pg_attver=134465880);


--
-- Name: prevention_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prevention_recommendations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category_id uuid NOT NULL,
    severity character varying(20) NOT NULL,
    title character varying(200) NOT NULL,
    description text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT prevention_recommendations_severity_check CHECK (((severity)::text = ANY ((ARRAY['INFO'::character varying, 'LOW'::character varying, 'MODERATE'::character varying, 'HIGH'::character varying, 'CRITICAL'::character varying])::text[])))
);
ALTER TABLE ONLY public.prevention_recommendations ALTER COLUMN id SET (pg_attver=134513544);
ALTER TABLE ONLY public.prevention_recommendations ALTER COLUMN category_id SET (pg_attver=134513544);
ALTER TABLE ONLY public.prevention_recommendations ALTER COLUMN severity SET (pg_attver=134513544);
ALTER TABLE ONLY public.prevention_recommendations ALTER COLUMN title SET (pg_attver=134513544);
ALTER TABLE ONLY public.prevention_recommendations ALTER COLUMN description SET (pg_attver=134513544);
ALTER TABLE ONLY public.prevention_recommendations ALTER COLUMN created_at SET (pg_attver=134513544);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    full_name character varying(150),
    created_at timestamp with time zone DEFAULT now(),
    is_active boolean DEFAULT true
);
ALTER TABLE ONLY public.profiles ALTER COLUMN id SET (pg_attver=134299912);
ALTER TABLE ONLY public.profiles ALTER COLUMN full_name SET (pg_attver=134299912);
ALTER TABLE ONLY public.profiles ALTER COLUMN created_at SET (pg_attver=134299912);
ALTER TABLE ONLY public.profiles ALTER COLUMN is_active SET (pg_attver=134299912);


--
-- Name: user_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    location_id uuid NOT NULL,
    is_primary boolean DEFAULT false,
    notifications_enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE ONLY public.user_locations ALTER COLUMN id SET (pg_attver=134356864);
ALTER TABLE ONLY public.user_locations ALTER COLUMN user_id SET (pg_attver=134356864);
ALTER TABLE ONLY public.user_locations ALTER COLUMN location_id SET (pg_attver=134356864);
ALTER TABLE ONLY public.user_locations ALTER COLUMN is_primary SET (pg_attver=134356864);
ALTER TABLE ONLY public.user_locations ALTER COLUMN notifications_enabled SET (pg_attver=134356864);
ALTER TABLE ONLY public.user_locations ALTER COLUMN created_at SET (pg_attver=134356864);


--
-- Name: weather_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weather_alerts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    category_id uuid NOT NULL,
    source character varying(100) NOT NULL,
    external_id character varying(255),
    title character varying(200) NOT NULL,
    description text,
    severity character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    starts_at timestamp with time zone,
    ends_at timestamp with time zone,
    detected_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT weather_alerts_severity_check CHECK (((severity)::text = ANY ((ARRAY['INFO'::character varying, 'LOW'::character varying, 'MODERATE'::character varying, 'HIGH'::character varying, 'CRITICAL'::character varying])::text[]))),
    CONSTRAINT weather_alerts_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'EXPIRED'::character varying, 'CANCELLED'::character varying])::text[])))
);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN id SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN location_id SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN category_id SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN source SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN external_id SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN title SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN description SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN severity SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN status SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN starts_at SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN ends_at SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN detected_at SET (pg_attver=134418848);
ALTER TABLE ONLY public.weather_alerts ALTER COLUMN created_at SET (pg_attver=134418848);


--
-- Name: weather_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weather_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    animation_key character varying(100),
    created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE ONLY public.weather_categories ALTER COLUMN id SET (pg_attver=134388920);
ALTER TABLE ONLY public.weather_categories ALTER COLUMN code SET (pg_attver=134388920);
ALTER TABLE ONLY public.weather_categories ALTER COLUMN name SET (pg_attver=134388920);
ALTER TABLE ONLY public.weather_categories ALTER COLUMN description SET (pg_attver=134388920);
ALTER TABLE ONLY public.weather_categories ALTER COLUMN animation_key SET (pg_attver=134388920);
ALTER TABLE ONLY public.weather_categories ALTER COLUMN created_at SET (pg_attver=134388920);


--
-- Name: weather_observations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weather_observations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    source character varying(100) NOT NULL,
    temperature numeric(5,2),
    feels_like numeric(5,2),
    humidity numeric(5,2),
    wind_speed numeric(7,2),
    precipitation numeric(7,2),
    recorded_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN id SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN location_id SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN source SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN temperature SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN feels_like SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN humidity SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN wind_speed SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN precipitation SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN recorded_at SET (pg_attver=134543856);
ALTER TABLE ONLY public.weather_observations ALTER COLUMN created_at SET (pg_attver=134543856);


--
-- Name: countries countries_iso_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_iso_code_key UNIQUE (iso_code);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: emergency_numbers emergency_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emergency_numbers
    ADD CONSTRAINT emergency_numbers_pkey PRIMARY KEY (country_code, number);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_user_id_alert_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_alert_id_key UNIQUE (user_id, alert_id);


--
-- Name: prevention_recommendations prevention_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prevention_recommendations
    ADD CONSTRAINT prevention_recommendations_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: locations unique_location; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT unique_location UNIQUE (country_id, name, region);


--
-- Name: user_locations user_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_locations
    ADD CONSTRAINT user_locations_pkey PRIMARY KEY (id);


--
-- Name: user_locations user_locations_user_id_location_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_locations
    ADD CONSTRAINT user_locations_user_id_location_id_key UNIQUE (user_id, location_id);


--
-- Name: weather_alerts weather_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_alerts
    ADD CONSTRAINT weather_alerts_pkey PRIMARY KEY (id);


--
-- Name: weather_categories weather_categories_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_categories
    ADD CONSTRAINT weather_categories_code_key UNIQUE (code);


--
-- Name: weather_categories weather_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_categories
    ADD CONSTRAINT weather_categories_pkey PRIMARY KEY (id);


--
-- Name: weather_observations weather_observations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_observations
    ADD CONSTRAINT weather_observations_pkey PRIMARY KEY (id);


--
-- Name: idx_locations_country; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_locations_country ON public.locations USING btree (country_id);


--
-- Name: idx_notifications_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_status ON public.notifications USING btree (status);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- Name: idx_prevention_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prevention_category ON public.prevention_recommendations USING btree (category_id);


--
-- Name: idx_user_locations_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_locations_user ON public.user_locations USING btree (user_id);


--
-- Name: idx_weather_alerts_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_weather_alerts_dates ON public.weather_alerts USING btree (starts_at, ends_at);


--
-- Name: idx_weather_alerts_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_weather_alerts_location ON public.weather_alerts USING btree (location_id);


--
-- Name: idx_weather_alerts_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_weather_alerts_status ON public.weather_alerts USING btree (status);


--
-- Name: idx_weather_observations_location_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_weather_observations_location_date ON public.weather_observations USING btree (location_id, recorded_at DESC);


--
-- Name: uq_weather_alert_external; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_weather_alert_external ON public.weather_alerts USING btree (source, external_id) WHERE (external_id IS NOT NULL);


--
-- Name: locations locations_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: notifications notifications_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.weather_alerts(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: prevention_recommendations prevention_recommendations_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prevention_recommendations
    ADD CONSTRAINT prevention_recommendations_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.weather_categories(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_locations user_locations_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_locations
    ADD CONSTRAINT user_locations_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE CASCADE;


--
-- Name: user_locations user_locations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_locations
    ADD CONSTRAINT user_locations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: weather_alerts weather_alerts_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_alerts
    ADD CONSTRAINT weather_alerts_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.weather_categories(id);


--
-- Name: weather_alerts weather_alerts_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_alerts
    ADD CONSTRAINT weather_alerts_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: weather_observations weather_observations_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_observations
    ADD CONSTRAINT weather_observations_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- PostgreSQL database dump complete
--

\unrestrict z7bdm90cwuX8aHYnAts7SCf4RTVeE9PMf9bMpqxsXFOg6WsQIa9HyzmfrDEbqTt

