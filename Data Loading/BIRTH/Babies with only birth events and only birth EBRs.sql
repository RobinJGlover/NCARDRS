DROP TABLE IF EXISTS baby_events;
CREATE TEMP TABLE baby_events AS (
	SELECT
		b.patientid baby_id
		, p.birthdate1::date baby_dob
		, zp.shortdesc baby_region
		, string_agg(e.eventable_type, ', ') events
	FROM
		baby b
	LEFT JOIN zprovider zp ON
		b.registryid = zp.zproviderid
	LEFT JOIN EVENT e ON
		b.patientid = e.patientid
	LEFT JOIN patient p ON
		b.patientid = p.patientid
	GROUP BY
		b.patientid
		, p.birthdate1
		, zp.shortdesc
);

DROP TABLE IF EXISTS baby_ebrs;
CREATE TEMP TABLE baby_ebrs AS (
	SELECT
		b.patientid baby_id
		, string_agg(concat(ebr."type", ' - ', CASE WHEN ebr.tran_status IS NULL THEN 'Unprocessed' ELSE ebr.tran_status end), ', ') ebrs
	FROM
		baby b
	LEFT JOIN e_base_record ebr ON
		b.patientid = ebr.matched_patientid
	GROUP BY
		b.patientid
);

DROP TABLE IF EXISTS baby_antenatal_tests;
CREATE TEMP TABLE baby_antenatal_tests AS (
	SELECT
	b.patientid
	, string_agg(e.eventable_type, ', ') antenatal_tests
FROM
	baby b
LEFT JOIN maternal_event_relevance mer ON
	b.patientid = mer.patientid
LEFT JOIN EVENT e ON mer.eventid = e.eventid
GROUP BY b.patientid
);

DROP TABLE IF EXISTS baby_created_by;
CREATE TEMP TABLE baby_created_by AS (
SELECT
	b.patientid, a.userid "Created By"
FROM
	baby b
LEFT JOIN (SELECT
	localid
	, userid
	, dt
	, ROW_NUMBER() OVER(
		PARTITION BY localid
		ORDER BY dt
	) rownumber
FROM
	aaudit a) a ON
	b.patientid = a.localid AND a.rownumber = 1
);

SELECT
	b_ev.baby_id, b_ev.events
	, b_ebr.ebrs
	, bat.antenatal_tests
	, bcb."Created By"
FROM
	baby_events b_ev
LEFT JOIN baby_ebrs b_ebr ON
	b_ev.baby_id = b_ebr.baby_id
LEFT JOIN baby_antenatal_tests bat ON b_ev.baby_id = bat.patientid
LEFT JOIN baby_created_by bcb ON b_ev.baby_id = bcb.patientid
WHERE events = 'Vbirth' AND ebrs = 'EBirth - Linked' AND bat.antenatal_tests is NULL AND bcb."Created By" ILIKE 'batch%'