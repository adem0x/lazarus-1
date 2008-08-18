#!/bin/sh

PROCTESTSUITEDIFF=/home/lazarus/testsuite/bin/proctestsuitediff
MAILDIR=/home/lazarus/testsuite/mail
CFGFILE=$MAILDIR/mailtestresults.cfg

cd $MAILDIR

. $CFGFILE

datename=`date +%Y-%m-%d`

cat > tests_mail << EOF
Subject: Daily test suite diffs ($datename)
From: "Lazarus Testsuite Diff Cron" <vincents@freepascal.org>
To: "Lazarus Developer List" <vincents@freepascal.org>

EOF
mysql -vvv -u ${USERNAME} --password=${PASSWORD} ${DATABASE} -e '
SELECT (TU_FAILURECOUNT+TU_ERRORCOUNT) as FAILS,DATE(TU_DATE) as DATE,
  TESTLAZVERSION.TLV_VERSION as LAZVERSION, TESTFPCVERSION.TFV_VERSION as FPCVERSION, 
  TESTCPU.TC_NAME as CPU,TESTOS.TO_NAME as OS, TESTWIDGETSET.TW_NAME as WIDGETSET,
  TU_SUBMITTER as TESTER,TU_MACHINE as MACHINE,TU_COMMENT as COMMENT, TIME(TU_DATE) as TIME, TU_ID, GROUP_CONCAT(TR_TEST_FK)
FROM TESTRUN LEFT JOIN (TESTCPU) ON (TU_CPU_FK=TC_ID) LEFT JOIN (TESTOS) ON (TU_OS_FK=TO_ID) LEFT JOIN (TESTWIDGETSET) ON (TU_WS_FK=TW_ID)
  LEFT JOIN (TESTFPCVERSION) ON (TU_FPC_VERSION_FK=TFV_ID) LEFT JOIN (TESTLAZVERSION) ON (TU_LAZ_VERSION_FK=TLV_ID) 
  LEFT JOIN TESTRESULTS ON (TR_TESTRUN_FK=TU_ID)
WHERE (DATE_SUB(CURDATE(), INTERVAL 2 DAY)<=DATE(TU_DATE)) AND TR_OK<>"+" AND TR_SKIP<>"+"
GROUP BY TU_ID
ORDER BY LAZVERSION, FPCVERSION, OS, CPU, WIDGETSET, TESTER, MACHINE, COMMENT, DATE;' | tee mysql-output | $PROCTESTSUITEDIFF >> tests_mail
#/usr/sbin/sendmail -f ${MAILFROM} ${MAILTO} < tests_mail >/dev/null 2>&1
