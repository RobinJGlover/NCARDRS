WITH x AS (SELECT distinct
	b.patientid
	, bp.birthdate1
	, CASE
		WHEN DATE_PART('year', bp.birthdate1) IN (
			2015, 2016
		) THEN 'Yes'
		ELSE 'No'
	END AS dob_criteria
	, CASE WHEN vda.eventid IS NULL THEN 'Yes' ELSE 'No' END as anomaly_criteria
	, CASE WHEN ebr2.e_base_recordid IS NULL THEN 'Yes' ELSE 'No' END AS unprocessed_criteria
	, CASE WHEN ebr3.e_base_recordid IS NULL THEN 'Yes' ELSE 'No' END AS processed_criteria
	, string_agg(DISTINCT ebr3."type", ', ') processed_ebrs
FROM
	e_batch eb
INNER JOIN e_base_record ebr ON
	ebr.e_batchid = eb.e_batchid
INNER JOIN baby b ON
	ebr.matched_patientid = b.patientid
INNER JOIN patient bp ON
	b.patientid = bp.patientid
LEFt JOIN vdiagnosedanomaly vda ON bp.patientid = vda.patientid AND vda.status <> 4
LEFT JOIN e_base_record ebr2 ON bp.patientid = ebr2.matched_patientid AND ebr2.tran_status IS NULL
LEFT JOIN e_base_record ebr3 ON bp.patientid = ebr3.matched_patientid AND ebr3.tran_status IS NOT NULL AND ebr3."type" NOT IN ('EChildDiagnosedanomaly', 'EChildTestresult')
WHERE
	eb.e_batchid IN (
		4549, 4552, 4550, 4559, 9573, 9574, 40682, 40685, 5713, 5719, 4557, 4564, 4889, 4891, 4892, 4895
	) 
GROUP BY 1,2,3,4,5,6
) SELECT * FROM x WHERE dob_criteria = 'Yes' AND anomaly_criteria = 'Yes' AND unprocessed_criteria = 'Yes' AND processed_criteria = 'Yes'
