SELECT
	ebr.e_base_recordid, vda.eventid
FROM
	e_base_record ebr
INNER JOIN e_base_record_event_link ebrel ON ebr.e_base_recordid = ebrel.e_base_recordid 
INNER JOIN vdiagnosedanomaly vda ON ebrel.eventid = vda.eventid 
INNER JOIN vdiagnosedanomaly vda2 ON vda.patientid = vda2.patientid AND vda.icd = vda2.icd AND vda.eventid <> vda2.eventid
WHERE
	ebr.e_batchid > 108305 AND ebr."type" = 'EHes'
