--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4 (Debian 13.4-4.pgdg110+1)
-- Dumped by pg_dump version 14.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: qaqc_historic; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qaqc_historic (
    version text,
    b_likely_occ_desc integer,
    b_large_alt_reduction integer,
    b_nonres_with_units integer,
    units_co_prop_mismatch integer,
    partially_complete integer,
    units_init_null integer,
    units_prop_null integer,
    units_res_accessory integer,
    outlier_demo_20plus integer,
    outlier_nb_500plus integer,
    outlier_top_alt_increase integer,
    dup_bbl_address_units integer,
    dup_bbl_address integer,
    inactive_with_update integer,
    no_work_job integer,
    geo_water integer,
    geo_taxlot integer,
    geo_null_latlong integer,
    geo_null_boundary integer,
    invalid_date_filed integer,
    invalid_date_lastupdt integer,
    invalid_date_statusd integer,
    invalid_date_statusp integer,
    invalid_date_statusr integer,
    invalid_date_statusx integer,
    incomp_tract_home integer,
    dem_nb_overlap integer
);


ALTER TABLE public.qaqc_historic OWNER TO postgres;

--
-- Data for Name: qaqc_historic; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.qaqc_historic (version, b_likely_occ_desc, b_large_alt_reduction, b_nonres_with_units, units_co_prop_mismatch, partially_complete, units_init_null, units_prop_null, units_res_accessory, outlier_demo_20plus, outlier_nb_500plus, outlier_top_alt_increase, dup_bbl_address_units, dup_bbl_address, inactive_with_update, no_work_job, geo_water, geo_taxlot, geo_null_latlong, geo_null_boundary, invalid_date_filed, invalid_date_lastupdt, invalid_date_statusd, invalid_date_statusp, invalid_date_statusr, invalid_date_statusx, incomp_tract_home, dem_nb_overlap) FROM stdin;
20Q2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
20Q4	4334	600	10393	1119	13	43810	234	6824	116	95	20	1920	52395	0	15574	0	1537	553	1774	0	0	0	2	0	1	3532	65359
21Q2	6660	715	103626	1141	16	43787	235	7097	119	100	20	655647	1883333	0	15997	0	2261	819	2312	0	0	0	2	0	1	3531	66659
21Q4	4018	684	10572	1075	5	39483	61	5332	121	108	20	1934	52943	9	15927	217	993	160	1661	0	0	0	1	0	1	3525	68076
22Q2	4060	714	10612	1086	5	39467	61	5577	126	114	20	1983	53521	8	16048	62	881	163	383	0	0	0	1	0	1	3525	69539
\.


--
-- PostgreSQL database dump complete
--

