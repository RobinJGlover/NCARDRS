WITH x AS (
	SELECT
		p.patientid
		, rt.virtualfieldtext::jsonb->>'opertn_01' opcs_code_1
		, string_agg(DISTINCT to_char((rt.virtualfieldtext::jsonb->>'opdate_01_dv')::date, 'YYYY-MM-DD'), ', ') opcs_dates
		, min((rt.virtualfieldtext::jsonb->>'opdate_01_dv')::date) earliest
	FROM
		patient p
	INNER JOIN e_base_record ebr ON
		p.patientid = ebr.matched_patientid
		AND ebr."type" = 'EHes'
	INNER JOIN e_base_rawtext rt ON
		ebr.e_base_recordid = rt.e_base_recordid
	WHERE
		rt.virtualfieldtext::jsonb->>'opertn_01' IN (
			'G071',
'G073',
'M765',
'T702',
'X481',
'X216',
'C791',
'M731',
'E088',
'W912',
'E083',
'M031'
		)
		AND (
			rt.virtualfieldtext::jsonb->>'opdate_01_dv'
		) IS NOT NULL
	GROUP BY
		1
		, 2
	ORDER BY
		opcs_dates DESC
)
SELECT
	x.*
	, vs.eventid
	, vs.proceduredate1::date
FROM
	x
INNER JOIN vsurgery vs ON
	x.patientid = vs.patientid
	AND x.opcs_code_1 = vs.primaryprocedure_opcs 
WHERE vs.proceduredate1::date > x.earliest
	
	
