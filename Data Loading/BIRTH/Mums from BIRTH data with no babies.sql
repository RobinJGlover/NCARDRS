DROP TABLE IF EXISTS dataset;

select distinct *
into temporary table DataSet
from 
	(select b.matched_patientid as mumid
			, p.personid as mumpersonid
			, b.e_batchid
			, b.tran_status
		from springmvc3.e_base_record b                   -- see if those relationships are babies
		inner join springmvc3.patient p 
     	  on  b.matched_patientid = p.patientid
     	   and type = 'EMumRecord' --limit 5
     	   and e_batchid in ()  -- Change to UMUM batch id for BIRTH data just loaded
     ) mum
left join springmvc3.rovpersonrole01 r -- need to find all relationships that the mum has
       on mum.mumpersonid = r.subjectpersonid
left join 
	(select b.patientid as babyid
			, p.personid as babypersonid
		from springmvc3.baby b                   -- see if those relationships are babies
		inner join springmvc3.patient p 
     	  on  b.patientid = p.patientid  --limit 5
     ) baby
	on baby.babypersonid = r.objectpersonid 
where baby.babypersonid is null  
;


-- CHECK 1: In most cases total rows should be higher than total patients
select count(*) as TotalRows, count(distinct mumid) as TotalMums
from DataSet;
-- 61	61
	
-- CHECK 2: Check sample of records to see if they have any baby relationship
select r.*
from DataSet a
left join springmvc3.rovpersonrole01 r 
	on a.mumpersonid = r.subjectpersonid;
 -- no relationships = no babies
 
select mumid   
	, e_batchid
	, tran_status
from DataSet
order by e_batchid ASC;
