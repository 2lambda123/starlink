      PROGRAM TEST_TIME

* Test the subroutine PSX_TIME

      IMPLICIT NONE
      INCLUDE 'SAE_PAR'
      INTEGER STATUS

* Local Variables:
      INTEGER NTICKS
      INTEGER SEC, MIN, HOUR, DAY, MONTH, YEAR, WDAY, YDAY, ISDST,
     : TSTRCT
      CHARACTER * ( 27 ) STRING, STRING2

* Initialize STATUS
      STATUS = SAI__OK

      STRING = ' '
      STRING2 = ' '

      CALL EMS_BEGIN( STATUS )

* Test PSX_TIME
      PRINT *,' '
      PRINT *,'--  Program PSX_TIME, function PSX_TIME  --'
      PRINT *,' '

      CALL PSX_TIME( NTICKS, STATUS )
      PRINT *,'The value returned by PSX_TIME is ',NTICKS

* Test PSX_LOCALTIME
      PRINT *,' '
      PRINT *,'--  Program PSX_TIME, function PSX_LOCALTIME  --'
      PRINT *,' '

      CALL PSX_LOCALTIME( NTICKS, SEC, MIN, HOUR, DAY, MONTH, YEAR,
     : WDAY, YDAY, ISDST, TSTRCT, STATUS )
      PRINT *,'The values returned by PSX_LOCALTIME are:'
      PRINT *,'SEC   = ',SEC
      PRINT *,'MIN   = ',MIN
      PRINT *,'HOUR  = ',HOUR
      PRINT *,'DAY   = ',DAY
      PRINT *,'MONTH = ',MONTH
      PRINT *,'YEAR  = ',YEAR
      PRINT *,'WDAY  = ',WDAY
      PRINT *,'YDAY  = ',YDAY
      PRINT *,'ISDST = ',ISDST

* Test PSX_ASCTIME
      PRINT *,' '
      PRINT *,'--  Program PSX_TIME, function PSX_ASCTIME  --'
      PRINT *,' '

      CALL PSX_ASCTIME( TSTRCT, STRING, STATUS )
      PRINT *,'The value returned by PSX_ASCTIME is :'
      PRINT *,STRING

* Test PSX_TIME
      PRINT *,' '
      PRINT *,'--  Program PSX_TIME, function PSX_CTIME  --'
      PRINT *,' '

      CALL PSX_CTIME( NTICKS, STRING2, STATUS )
      PRINT *,'The value returned by PSX_CTIME is :'
      PRINT *,STRING2

* Test PSX_GMTIME
      PRINT *,' '
      PRINT *,'--  Program PSX_TIME, function PSX_GMTIME  --'
      PRINT *,' '

      CALL PSX_GMTIME( NTICKS, SEC, MIN, HOUR, DAY, MONTH, YEAR,
     : WDAY, YDAY, TSTRCT, STATUS )
      PRINT *,'The values returned by PSX_GMTIME are:'
      PRINT *,'SEC   = ',SEC
      PRINT *,'MIN   = ',MIN
      PRINT *,'HOUR  = ',HOUR
      PRINT *,'DAY   = ',DAY
      PRINT *,'MONTH = ',MONTH
      PRINT *,'YEAR  = ',YEAR
      PRINT *,'WDAY  = ',WDAY
      PRINT *,'YDAY  = ',YDAY

* Test PSX_ASCTIME
      PRINT *,' '
      PRINT *,'--  Program PSX_TIME, function PSX_ASCTIME  --'
      PRINT *,' '

      CALL PSX_ASCTIME( TSTRCT, STRING, STATUS )
      PRINT *,'The value returned by PSX_ASCTIME is :'
      PRINT *,STRING

      CALL EMS_END( STATUS )

      END
