WITH x AS (SELECT distinct
	ebr.e_base_recordid,
	--, ebr."type"
	zicd.exportid hes_icd
	, zicd.shortdesc hes_label
	, vda.status hes_status
	,concat_ws(', ',
	rt.virtualfieldtext::jsonb->>'opertn_01',
	rt.virtualfieldtext::jsonb->>'opertn_02',
	rt.virtualfieldtext::jsonb->>'opertn_03',
	rt.virtualfieldtext::jsonb->>'opertn_04',
	rt.virtualfieldtext::jsonb->>'opertn_05',
	rt.virtualfieldtext::jsonb->>'opertn_06',
	rt.virtualfieldtext::jsonb->>'opertn_07',
	rt.virtualfieldtext::jsonb->>'opertn_08',
	rt.virtualfieldtext::jsonb->>'opertn_09',
	rt.virtualfieldtext::jsonb->>'opertn_10',
	rt.virtualfieldtext::jsonb->>'opertn_11',
	rt.virtualfieldtext::jsonb->>'opertn_12',
	rt.virtualfieldtext::jsonb->>'opertn_13',
	rt.virtualfieldtext::jsonb->>'opertn_14',
	rt.virtualfieldtext::jsonb->>'opertn_15'
	) opcs_codes
	, ebr.matched_patientid
	, ebrel."action"
	, vda.*
FROM
	e_base_record ebr
INNER JOIN e_base_record_event_link ebrel ON
	ebr.e_base_recordid = ebrel.e_base_recordid
INNER JOIN e_base_rawtext rt ON ebr.e_base_recordid = rt.e_base_recordid 
INNER JOIN vdiagnosedanomaly vda ON
	ebrel.eventid = vda.eventid
INNER JOIN zicd ON
	vda.icd = zicd.zicdid
WHERE
	ebr."type" = 'EHes' AND ebr.e_batchid >= 108305 AND vda.status = 2
) SELECT * FROM x
 WHERE providercode IS null
-- Not found:
-- Q2182
-- Q770*
-- Q771
-- Q778*
-- Q793

SELECT ebr.matched_patientid, ebr.e_base_recordid, rt.virtualfieldtext FROM e_base_record ebr INNER JOIN e_batch eb ON ebr.e_batchid = eb.e_batchid AND eb.e_type = 'HES' INNER JOIN e_base_rawtext rt ON ebr.e_base_recordid = rt.e_base_recordid  WHERE --ebr.e_batchid >= 108305 AND 
rt.virtualfieldtext ILIKE '%Q771%' ORDER BY 2 DESC

SELECT * FROM zicd WHERE zicd.exportid ILIKE 'Q2182'
