-- IF mdob OR mforename diff

DROP TABLE IF EXISTS rg_mismatched_mums;
CREATE TEMP table rg_mismatched_mums AS (SELECT
	b.patientid, p.personid, p.nhsnumber cara_bnhs, ebr.e_base_recordid, regexp_replace(ebr_mat.forenames, '\-',' ') forenames, ebr_mat.dateofbirth
FROM baby b
INNER JOIN e_base_record ebr ON
	b.patientid = ebr.matched_patientid
	AND ebr."type" = 'EBirth'
INNER JOIN e_batch eb ON ebr.e_batchid = eb.e_batchid
INNER JOIN e_batch eb_mum ON eb.e_batchid = eb_mum.umum_source_id 
INNER JOIN e_base_rawtext rt ON ebr.e_base_recordid = rt.e_base_recordid 
INNER JOIN e_base_rawtext rt_mat ON (rt.virtualfieldtext::jsonb->>'row_identifier') = (rt_mat.virtualfieldtext::jsonb->>'row_identifier')
INNER JOIN e_base_record ebr_mat ON rt_mat.e_base_recordid = ebr_mat.e_base_recordid AND ebr_mat.e_batchid = eb_mum.e_batchid 
INNER JOIN patient p ON b.patientid = p.patientid
); 
WITH y AS (
	SELECT
		x.patientid baby_id
		, mp.patientid mum_id
		, mp.nhsnumber cara_mnhs
		, regexp_replace(regexp_replace(regexp_replace(mp.forename,'-',' '), '\s+',' '), '''','') cara_forename
		, mp.birthdate1::date cara_dob
		, regexp_replace(regexp_replace(regexp_replace(forenames,'-',' '), '\s+',' '), '''','') birth_ebr_forename
		, dateofbirth::date birth_ebr_dob
	FROM
		rg_mismatched_mums x
	INNER JOIN rovpersonrole01 rpr ON
		x.personid = rpr.objectpersonid
	INNER JOIN patient mp ON
		mp.personid = rpr.subjectpersonid
), z AS (
SELECT distinct
	*, CASE
			WHEN birth_ebr_forename ILIKE '%' || regexp_replace(cara_forename,'-',' ') || '%' THEN 'Match'
			WHEN birth_ebr_forename = regexp_replace(cara_forename,'-',' ') THEN 'Match'
			WHEN regexp_replace(cara_forename,'-',' ') ILIKE '%' || birth_ebr_forename || '%' THEN 'Match'
			ELSE 'Mismatch'
		END forename_check
		, CASE
			WHEN abs(birth_ebr_dob - cara_dob) <= 7
			OR birth_ebr_dob - INTERVAL '1 month' = cara_dob
			OR birth_ebr_dob + INTERVAL '1 month' = cara_dob
			OR birth_ebr_dob - INTERVAL '1 year' = cara_dob
			OR birth_ebr_dob + INTERVAL '1 year' = cara_dob
			OR cara_dob IS NULL THEN 'Match'
			ELSE 'Mismatch'
		END AS dob_check
FROM
	y) SELECT * FROM z WHERE 'Mismatch' IN (forename_check, dob_check) ORDER BY forename_check desc
