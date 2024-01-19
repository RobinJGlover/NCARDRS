SELECT distinct
	b.patientid patientid
	, 'child' patient_type
	, string_agg(DISTINCT eb.e_type, ', ') e_types
	, eub.e_user_batchid 
	, eub.userassignedto 
	, eub.started_at 
FROM
	baby b
INNER JOIN patient bp ON
	b.patientid = bp.patientid
INNER JOIN vpregnancy vp ON
	b.pregnancyid = vp.pregnancyid
INNER JOIN e_base_record ebr ON
	b.patientid = ebr.matched_patientid
INNER JOIN e_batch eb ON ebr.e_batchid = eb.e_batchid 
LEFT JOIN e_user_batch eub ON ebr.e_user_batchid = eub.e_user_batchid 
WHERE
	ebr.tran_status IS NULL
	AND (
		date_part('year', bp.birthdate1) = 2021
			OR date_part('year', bp.birthdate2) = 2021
	) AND (ebr.ragrating <> 1 or ebr.ragrating IS NULL)
GROUP BY 1,2,4
union
SELECT distinct
	vp.patientid patientid 
	, 'mother'
	, string_agg(DISTINCT eb.e_type, ', ') e_types
	, eub.e_user_batchid 
	, eub.userassignedto 
	, eub.started_at 
FROM
	baby b
INNER JOIN vpregnancy vp ON
	b.pregnancyid = vp.pregnancyid
INNER JOIN patient bp ON b.patientid = bp.patientid 
INNER JOIN e_base_record ebr ON vp.patientid = ebr.matched_patientid AND ebr.tran_status IS NULL
INNER JOIN e_batch eb ON ebr.e_batchid = eb.e_batchid 
LEFT JOIN e_user_batch eub ON ebr.e_user_batchid = eub.e_user_batchid 
WHERE (
		date_part('year', bp.birthdate1) = 2021
			OR date_part('year', bp.birthdate2) = 2021
	) AND (ebr.ragrating <> 1 or ebr.ragrating IS NULL)
GROUP BY 1,2,4
union
SELECT distinct
	p.patientid
	, 'mother'
	, string_agg(DISTINCT eb.e_type, ', ') e_types
	, eub.e_user_batchid
	, eub.userassignedto
	, eub.started_at
FROM
	patient p
INNER JOIN vpregnancy vp ON
	p.patientid = vp.patientid
	AND date_part('year', vp.expecteddeliverydate) = 2021
INNER JOIN e_base_record ebr ON
	p.patientid = ebr.matched_patientid
	AND ebr.tran_status IS NULL
INNER JOIN e_base_rawtext rt ON
	ebr.e_base_recordid = rt.e_base_recordid
INNER JOIN e_batch eb ON
	ebr.e_batchid = eb.e_batchid
LEFT JOIN e_user_batch eub ON
	ebr.e_user_batchid = eub.e_user_batchid
WHERE
	(
		ebr.ragrating <> 1
			OR ebr.ragrating IS NULL
	) AND date_part('year',COALESCE(
		(rt.virtualfieldtext::jsonb->>'expecteddeliverydate')::date,
		(rt.virtualfieldtext::jsonb->>'datefirstcontact')::date,
		(rt.virtualfieldtext::jsonb->>'epistart_dv')::date,
		ebr.authoriseddate::date,
		ebr.receiveddate::date,
		(rt.virtualfieldtext::jsonb->>'testdate')::date, (rt.virtualfieldtext::jsonb->>'datefirstnotified')::date
	)::date) = 2021
GROUP BY 1,2,4
