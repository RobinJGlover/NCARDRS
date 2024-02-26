WITH hes_anomalies AS (
  -- anomalies linked to HES records that have diagnostic variables present
  SELECT da.diagnosedanomalyid
       , ebrel.e_base_recordid 
       , da.patientid
       , da.icd
       , da.status
       , da.detecteddate1 
       , da.diagnosticmethod
  FROM vdiagnosedanomaly da
  INNER JOIN e_base_record_event_link ebrel ON ebrel.eventid = da.eventid 
  INNER JOIN e_base_record ebr ON ebr.e_base_recordid = ebrel.e_base_recordid 
  WHERE ebr."type" = 'EHes'
    AND NOT (da.diagnosticmethod IS NULL AND da.detecteddate1 IS NULL)
), audits AS (
  -- audits for those anomalies, pulling out detecteddate1 and diagnosticmethod
  SELECT ra.auditable_id diagnosedanomalyid
       , to_timestamp(substring(ra.xmldata, '<DETECTEDDATE1>(.*)</DETECTEDDATE1>'), 'YYYY-MM-DD HH24:MI:SS') detecteddate1
       , substring(ra.xmldata, '<DIAGNOSTICMETHOD>(.*)</DIAGNOSTICMETHOD>')::int diagnosticmethod
       , ra.userid 
       , ra.created_at 
       , row_number() OVER (PARTITION BY ra.auditable_id ORDER BY ra.created_at DESC) sortorder
  FROM rovaudit ra
  INNER JOIN hes_anomalies ha ON ha.diagnosedanomalyid = ra.auditable_id AND ra.auditable_type = 'Diagnosedanomaly'
), audit_history AS (
  -- union current state to audits to create the full ordered timeline
  SELECT ha.diagnosedanomalyid
       , ha.detecteddate1
       , ha.diagnosticmethod
       , TO_TIMESTAMP(0) AS created_at
       , NULL AS userid
       , 0 AS sortorder
  FROM hes_anomalies ha
  UNION 
  SELECT aa.diagnosedanomalyid
       , aa.detecteddate1
       , aa.diagnosticmethod
       , aa.created_at
       , aa.userid
       , aa.sortorder
  FROM audits aa
), change_history AS (
  -- self join audit history to identify 'from' and 'to' values of each change
  SELECT ah_to.diagnosedanomalyid
       , ah_from.userid 
       , ah_from.created_at change_timestamp
       , ah_from.detecteddate1 detecteddate_from
       , ah_to.detecteddate1 detecteddate_to
       , ah_from.diagnosticmethod diagnosticmethod_from
       , ah_to.diagnosticmethod diagnosticmethod_to
  FROM audit_history ah_from
  INNER JOIN audit_history ah_to
     ON ah_to.diagnosedanomalyid = ah_from.diagnosedanomalyid
    AND ah_to.sortorder = ah_from.sortorder - 1
), relevant_changes AS (
  -- isolate changes to diagnostic variables and group userids by type
  SELECT ch.diagnosedanomalyid
       , CASE WHEN ch.userid IN ('Dev1', 'Dev2') OR ch.userid LIKE 'batch%' OR ch.userid LIKE 'dba%'
         THEN 'machine'
         ELSE 'user'
         END AS user_type
       , ch.change_timestamp
       , ch.detecteddate_from
       , ch.detecteddate_to
       , ch.diagnosticmethod_from
       , ch.diagnosticmethod_to
  FROM change_history ch
  WHERE ch.detecteddate_from != ch.detecteddate_to
     OR ch.diagnosticmethod_from != ch.diagnosticmethod_to
     OR (ch.detecteddate_from IS NULL AND ch.detecteddate_to IS NOT NULL)
     OR (ch.diagnosticmethod_from IS NULL AND ch.diagnosticmethod_to IS NOT NULL)
)
SELECT rc.diagnosedanomalyid
     , zicd.exportid
     , da.status
     , rc.change_timestamp
     , rc.detecteddate_from
     , rc.detecteddate_to
     , rc.diagnosticmethod_from
     , rc.diagnosticmethod_to
FROM relevant_changes rc
INNER JOIN vdiagnosedanomaly da ON da.diagnosedanomalyid = rc.diagnosedanomalyid
INNER JOIN zicd ON zicd.zicdid = da.icd
  -- the change was made automatically
WHERE rc.user_type = 'machine'
  -- the diagnostic variable has not been changed since
  AND (da.detecteddate1 = rc.detecteddate_to OR da.diagnosticmethod = rc.diagnosticmethod_to)
;
