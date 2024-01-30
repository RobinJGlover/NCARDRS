WITH biochem_events AS (
          SELECT vn.patientid
               , vn.providercode vn_provider
               , ebrel.e_base_recordid
               , ebr.tran_status
               , evaluation_data
               , vp.pregnancyid
               , vp.expecteddeliverydate
               , vp.combinedscreeningaccpt
               , vp.quadscreeningaccpt
               , vp.maternalillnessstatus
               , vp.providercode vp_provider
               , evaluation_data->>'risk' chance_t21
               , evaluation_data->>'riskt13' chance_t13
               , evaluation_data->>'riskt18' chance_t18
               , evaluation_data->>'riskt13t18' chance_t13t18
               , vn.eventid
               , CASE
                   WHEN (evaluation_data->>'testtype' = 'Prenatal Other')
                     AND (evaluation_data->>'othertestname') IN ('Age & NT Risk Only', 'Early Combined Test')
                     THEN 'Combined Test'
                   ELSE evaluation_data->>'testtype'
                   END testtype
               , evaluation_data->>'organisationcode_testresult' lab
               , (evaluation_data->>'expecteddeliverydate')::date event_edd
               , (evaluation_data->>'testdate1')::date testdate
          FROM vniptevaluation vn
          LEFT JOIN e_base_record_event_link ebrel on vn.eventid = ebrel.eventid
          LEFT JOIN e_base_record ebr ON ebrel.e_base_recordid = ebr.e_base_recordid
          LEFT JOIN vpregnancy vp
            ON  vn.patientid = vp.patientid
            AND abs((vn.evaluation_data->>'expecteddeliverydate')::date-vp.expecteddeliverydate::date) <= 31
          WHERE vn.data_type = 'BIOCHEM'
            AND (evaluation_data->>'testdate1')::date > '2019-09-01'::date
        ), validations AS (
          (SELECT patientid
               , eventid
               , lab
               , event_edd
               , testdate
               , 'BIOCHEM source event missing lab provider.' AS validation_error
          FROM biochem_events
          WHERE lab IS NULL)
          UNION
          (SELECT patientid
               , eventid
               , lab
               , event_edd
               , testdate
               , 'BIOCHEM source event missing requesting hospital.' AS validation_error
          FROM biochem_events
          WHERE (evaluation_data->>'bookingprovidercode') IS NULL
            AND lab <> '698F0')
          UNION
          (SELECT patientid
               , eventid
               , lab
               , event_edd
               , testdate
               , 'BIOCHEM source event missing EDD.' AS validation_error
          FROM biochem_events
          WHERE event_edd IS NULL)
          UNION
          (SELECT patientid
               , eventid
               , lab
               , event_edd
               , testdate
               , 'BIOCHEM source event missing NT measurement.' AS validation_error
          FROM biochem_events
          WHERE testtype = 'Combined Test'
            AND (evaluation_data->>'ntmeasurement') IS NULL
            AND lab <> '695H0' -- Wolfson sent NTs FOR twins IN format 'X.Y / Z.W' could NOT separate BETWEEN twins so cannot map
            )
          UNION
          (SELECT patientid
               , eventid
               , lab
               , event_edd
               , testdate
               , 'BIOCHEM source event has incorrect combined screening acceptance: historical value "1".' AS validation_error
          FROM biochem_events
          WHERE (evaluation_data->>'combinedscreeningaccpt')::int = 1)
          UNION
          (SELECT patientid
               , eventid
               , lab
               , event_edd
               , testdate
               , 'BIOCHEM source event has both combinedscreeningaccpt and quadscreeningaccpt populated.' AS validation_error 
          FROM biochem_events
          WHERE (evaluation_data->>'combinedscreeningaccpt') IS NOT NULL
            AND (evaluation_data->>'quadscreeningaccpt') IS NOT NULL)
          UNION
          (SELECT patientid
               , eventid
               , lab
               , event_edd
               , testdate
               , 'BIOCHEM source event for first trimester screening has Quad screening acceptance populated.' AS validation_error
          FROM biochem_events
          WHERE testtype = 'Combined Test'
            AND (evaluation_data->>'quadscreeningaccpt') IS NOT NULL)
          UNION
          (SELECT patientid
               , eventid
               , lab
               , event_edd
               , testdate
               , 'BIOCHEM source event for second trimester screening has Combined screening acceptance populated.' AS validation_error
          FROM biochem_events
          WHERE testtype = 'Serum Screen'
            AND (evaluation_data->>'combinedscreeningaccpt') IS NOT NULL)
          UNION
          (SELECT bioc1.patientid
               , bioc1.eventid
               , bioc1.lab
               , bioc1.event_edd
               , bioc1.testdate
               , 'BIOCHEM source event is missing ''edd_in_generated_pregnancy'' for twins with different EDDs.' AS validation_error
          FROM biochem_events bioc1
          LEFT JOIN biochem_events bioc2
            ON  bioc1.patientid = bioc2.patientid
            AND bioc1.eventid < bioc2.eventid
            AND bioc1.lab = bioc2.lab
          WHERE abs(bioc1.event_edd - bioc2.event_edd) IS NOT NULL
            AND (bioc1.evaluation_data->>'numberoffetuses')::int > 1
            AND abs(bioc1.event_edd - bioc2.event_edd) < 30 
            AND bioc1.event_edd <> bioc2.event_edd
            AND bioc1.testtype = bioc2.testtype
            AND (bioc1.evaluation_data->>'edd_in_generated_pregnancy') IS NULL
            AND (bioc2.evaluation_data->>'edd_in_generated_pregnancy') IS NULL)
        ), qa AS (
        -- copy of BIOCHEM QA Actions SQL but does not check user populated so we can pull out where user is null or batch% and does not concat multiple issues
        WITH biochem_events AS( SELECT vn.patientid , vn.providercode vn_provider , ebrel.e_base_recordid , ebr.tran_status , evaluation_data , vp.pregnancyid , vp.expecteddeliverydate , vp.combinedscreeningaccpt , vp.quadscreeningaccpt , vp.maternalillnessstatus , vp.providercode vp_provider , evaluation_data->>'risk' chance_t21 , evaluation_data->>'riskt13' chance_t13 , evaluation_data->>'riskt18' chance_t18 , evaluation_data->>'riskt13t18' chance_t13t18 , eub.userassignedto , vn.eventid , CASE WHEN (evaluation_data->>'testtype' = 'Prenatal Other') AND (evaluation_data->>'othertestname') IN ('Age & NT Risk Only', 'Early Combined Test') THEN 'Combined Test' ELSE evaluation_data->>'testtype' END testtype , evaluation_data->>'organisationcode_testresult' lab , (evaluation_data->>'expecteddeliverydate')::date event_edd , (evaluation_data->>'testdate1')::date testdate FROM vniptevaluation vn LEFT JOIN e_base_record_event_link ebrel on vn.eventid = ebrel.eventid LEFT JOIN e_base_record ebr ON ebrel.e_base_recordid = ebr.e_base_recordid LEFT JOIN e_user_batch eub ON ebr.e_user_batchid = eub.e_user_batchid LEFT JOIN vpregnancy vp ON vn.patientid = vp.patientid AND abs((vn.evaluation_data->>'expecteddeliverydate')::date-vp.expecteddeliverydate::date) < 30 WHERE vn.data_type = 'BIOCHEM' AND (evaluation_data->>'testdate1')::date > '2019-09-01'::date), validations AS ( (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , userassignedto , event_edd , 'Missing pregnancy despite BIOCHEM data being processed.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype WHERE pregnancyid IS NULL AND event_edd IS NOT null AND tran_status IS NOT NULL AND vtr.testresultid IS NOT null ) UNION (SELECT patientid , eventid , lab , testdate , userassignedto , event_edd , CASE WHEN combinedscreeningaccpt IS NULL THEN 'Missing combined screening acceptance on pregnancy.' WHEN combinedscreeningaccpt = 10 AND (chance_t21 IS NULL OR coalesce(chance_t13, chance_t18, chance_t13t18) IS NULL) THEN 'Incorrect combined screening acceptance on pregnancy: all screening not performed.' WHEN combinedscreeningaccpt = 11 AND coalesce(chance_t13, chance_t18, chance_t13t18) IS NOT NULL THEN 'Incorrect combined screening acceptance on pregnancy: screening performed for T13/18 as well as T21.' WHEN combinedscreeningaccpt = 12 AND chance_t21 IS NOT NULL THEN 'Incorrect combined screening acceptance on pregnancy: screening performed for T21 as well as T13/18.' ELSE NULL END AS validation_error FROM biochem_events WHERE pregnancyid IS NOT NULL AND testtype = 'Combined Test' AND tran_status IS NOT NULL) UNION (SELECT patientid , eventid , lab , testdate , userassignedto , event_edd , 'Missing quad screening acceptance on pregnancy.' AS validation_error FROM biochem_events WHERE testtype = 'Serum Screen' AND quadscreeningaccpt IS NULL AND pregnancyid IS NOT null AND tran_status IS NOT NULL) UNION (SELECT patientid , eventid , lab , testdate , userassignedto , event_edd , 'Maternalillnessstatus is incorrect in the pregnancy.' AS validation_error FROM biochem_events WHERE (evaluation_data->>'maternalillnessstatus')::int = 2 AND maternalillnessstatus::int <> 2 AND tran_status IS NOT NULL) UNION (SELECT bioc1.patientid , bioc1.eventid , bioc1.lab , bioc1.testdate , bioc1.userassignedto , bioc1.event_edd , 'The pregnancy EDD should be the earlier of the twins with different EDDs' AS validation_error FROM biochem_events bioc1 LEFT JOIN biochem_events bioc2 ON bioc1.patientid = bioc2.patientid AND bioc1.eventid < bioc2.eventid AND bioc1.lab = bioc2.lab WHERE abs(bioc1.event_edd - bioc2.event_edd) IS NOT NULL AND abs(bioc1.event_edd - bioc2.event_edd) < 30 AND bioc1.event_edd <> bioc2.event_edd AND bioc1.testtype = bioc2.testtype AND bioc1.expecteddeliverydate <> least(bioc1.event_edd, bioc2.event_edd) AND (bioc1.evaluation_data->>'numberoffetuses')::int > 1) UNION (SELECT bioc1.patientid , bioc1.eventid , bioc1.lab , bioc1.testdate , bioc1.userassignedto , bioc1.event_edd , 'The pregnancy EDD should be the earlier of the two BIOCHEM NIPT Evaluation events where it is a repeated test.' AS validation_error FROM biochem_events bioc1 LEFT JOIN biochem_events bioc2 ON bioc1.patientid = bioc2.patientid AND bioc1.eventid < bioc2.eventid AND bioc1.testtype = bioc2.testtype WHERE abs(bioc1.testdate - bioc2.testdate) < 30 AND bioc1.testdate <> bioc2.testdate AND bioc1.expecteddeliverydate <> LEAST(bioc1.event_edd, bioc2.event_edd)) UNION (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , bioc.userassignedto , bioc.event_edd , 'Missing screening test despite BIOCHEM data being processed.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype WHERE vtr.testresultid IS NULL AND bioc.tran_status IS NOT NULL AND pregnancyid IS NOT null) UNION (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , bioc.userassignedto , bioc.event_edd , 'Lab code is incorrect in the screening test.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype AND bioc.lab = vtr.organisationcode_testresult LEFT JOIN vtestresult vtr2 ON bioc.patientid = vtr2.patientid AND ( bioc.testdate = vtr2.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr2.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr2.testtype AND vtr.eventid <> vtr2.eventid AND bioc.lab = vtr2.organisationcode_testresult WHERE bioc.lab IS NOT NULL AND vtr.eventid IS NOT null AND (vtr.organisationcode_testresult <> bioc.lab OR vtr.organisationcode_testresult IS null) AND (vtr2.organisationcode_testresult <> bioc.lab OR vtr2.organisationcode_testresult IS NULL) AND bioc.tran_status IS NOT NULL) UNION (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , bioc.userassignedto , bioc.event_edd , 'Provider code is incorrect in the screening test.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype AND (bioc.evaluation_data->>'bookingprovidercode') = vtr.providercode WHERE bioc.tran_status IS NOT NULL AND bioc.vn_provider IS NOT NULL AND vtr.eventid IS NOT NULL AND (bioc.vn_provider <> vtr.providercode OR vtr.providercode IS null)) UNION (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , bioc.userassignedto , bioc.event_edd , 'T21 risk is incorrect in the screening test.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype LEFT JOIN vtestresult vtr2 ON bioc.patientid = vtr2.patientid AND ( bioc.testdate = vtr2.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr2.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr2.testtype AND vtr.eventid <> vtr2.eventid WHERE bioc.tran_status IS NOT NULL AND bioc.chance_t21 IS NOT NULL AND vtr.eventid IS NOT null AND (vtr.risk <> bioc.chance_t21::int OR vtr.risk IS null) AND (vtr2.risk <> bioc.chance_t21::int OR vtr2.risk IS null)) UNION (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , bioc.userassignedto , bioc.event_edd , 'T13 risk is incorrect in the screening test.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype LEFT JOIN vtestresult vtr2 ON bioc.patientid = vtr2.patientid AND ( bioc.testdate = vtr2.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr2.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr2.testtype AND vtr.eventid <> vtr2.eventid WHERE bioc.tran_status IS NOT NULL AND bioc.chance_t13 IS NOT NULL AND vtr.eventid IS NOT null AND (vtr.riskt13 <> bioc.chance_t13::int OR vtr.riskt13 IS null) AND (vtr2.riskt13 <> bioc.chance_t13::int OR vtr2.riskt13 IS null)) UNION (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , bioc.userassignedto , bioc.event_edd , 'T18 risk is incorrect in the screening test.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype LEFT JOIN vtestresult vtr2 ON bioc.patientid = vtr2.patientid AND ( bioc.testdate = vtr2.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr2.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr2.testtype AND vtr.eventid <> vtr2.eventid WHERE bioc.tran_status IS NOT NULL AND bioc.chance_t18 IS NOT NULL AND vtr.eventid IS NOT null AND (vtr.riskt18 <> bioc.chance_t18::int OR vtr.riskt18 IS NULL) AND (vtr2.riskt18 <> bioc.chance_t18::int OR vtr2.riskt18 IS null)) UNION (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , bioc.userassignedto , bioc.event_edd , 'T13/18 risk is incorrect in the screening test.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype LEFT JOIN vtestresult vtr2 ON bioc.patientid = vtr2.patientid AND ( bioc.testdate = vtr2.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr2.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr2.testtype AND vtr.eventid <> vtr2.eventid WHERE bioc.tran_status IS NOT NULL AND bioc.chance_t13t18 IS NOT NULL AND vtr.eventid IS NOT null AND (vtr.riskt13t18 <> bioc.chance_t13t18::int OR vtr.riskt13t18 IS null) AND (vtr2.riskt13t18 <> bioc.chance_t13t18::int OR vtr2.riskt13t18 IS null)) UNION (SELECT bioc.patientid , bioc.eventid , bioc.lab , bioc.testdate , bioc.userassignedto , bioc.event_edd , 'NT Measurement is incorrect in the screening test.' AS validation_error FROM biochem_events bioc LEFT JOIN vtestresult vtr ON bioc.patientid = vtr.patientid AND ( bioc.testdate = vtr.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr.testtype LEFT JOIN vtestresult vtr2 ON bioc.patientid = vtr2.patientid AND ( bioc.testdate = vtr2.testdate1::date OR (bioc.evaluation_data->>'scandate')::date = vtr2.testdate1::date ) AND (bioc.evaluation_data->>'testtype') = vtr2.testtype AND vtr.eventid <> vtr2.eventid WHERE bioc.tran_status IS NOT NULL AND (bioc.evaluation_data->>'ntmeasurement')::float IS NOT NULL AND vtr.eventid IS NOT null AND (vtr.ntmeasurement::float <> (bioc.evaluation_data->>'ntmeasurement')::float OR vtr.ntmeasurement IS null) AND (vtr2.ntmeasurement <> (bioc.evaluation_data->>'ntmeasurement')::float OR vtr2.ntmeasurement IS NULL)) ) SELECT validations.patientid , validations.eventid , validations.lab , validations.testdate , validations.userassignedto "user" , validations.event_edd , validations.validation_error FROM validations LEFT JOIN vniptevaluation vn ON validations.eventid = vn.eventid WHERE validations.validation_error IS NOT NULL ORDER BY 6 desc
        ) SELECT validations.patientid
             , validations.eventid nipt_eventid
             , validations.lab
             , validations.event_edd
             , validations.testdate
             , validations.validation_error
        FROM validations
        LEFT JOIN zprovider zp ON validations.lab = zp.exportid
        LEFT JOIN vniptevaluation vn ON validations.eventid = vn.eventid
        WHERE validations.validation_error IS NOT NULL
        UNION
        SELECT patientid, eventid, lab, event_edd, testdate, validation_error FROM qa WHERE validation_error IS NOT NULL AND ("user" IS NULL OR "user" ILIKE 'batch%')
        ORDER BY 3 desc;
