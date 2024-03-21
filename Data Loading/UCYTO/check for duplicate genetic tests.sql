WITH x AS (
	SELECT
		vgt.patientid
		, vgt.eventid
		, vgt.sourcetype
		, COALESCE(vgt.authoriseddate, vgt.receiveddate, vgt.collecteddate, vgt.requesteddate)::date testdate
		, vgt.karyotypingmethod 
		, vgt.organisationcode_testresult
		, vgt.servicereportidentifier
		, gtr.teststatus 
		, a.userid
		, a.dt
		, a.tablename
		, ROW_NUMBER() OVER(
			PARTITION BY eventid
		ORDER BY
			dt ASC
		)
	FROM
		vgenetictest vgt
	LEFT JOIN aaudit a ON
		vgt.eventid = a.localid
		AND a.tablename = 'genetictest'
	INNER JOIN genetictestresult gtr ON vgt.genetictestid = gtr.genetictestid  
	WHERE
		vgt.sourcetype = 'GENETICS FEED'
	ORDER BY
		1
)
,
auto_tests AS (
	SELECT
		*
	FROM
		x
	WHERE
		ROW_NUMBER = 1
		AND userid ILIKE '%batch%'
)
SELECT
	*
FROM
	auto_tests auto
INNER JOIN auto_tests auto2 ON
	auto.patientid = auto2.patientid
	AND auto.eventid < auto2.eventid
	AND auto.testdate = auto2.testdate
	AND auto.karyotypingmethod = auto2.karyotypingmethod 
	AND auto.organisationcode_testresult = auto2.organisationcode_testresult 
	AND auto.servicereportidentifier = auto2.servicereportidentifier 
	AND auto.teststatus = auto2.teststatus 
ORDER BY 1;
