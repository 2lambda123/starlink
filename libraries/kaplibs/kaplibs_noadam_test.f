      PROGRAM KAPLIBS_NOADAM

      INCLUDE 'DAT_PAR'

*   Exists mainly to test linking of non-ADAM kaplibs
      INTEGER DIMS( 1 )
      INTEGER PNTR
      CHARACTER * ( DAT__SZLOC ) WKLOC
      INTEGER STATUS
      STATUS = 0

      CALL ERR_BEGIN( STATUS )
      CALL KPG1_PSEED( STATUS )

      DIMS(1) = 1
      CALL AIF_GETVM('_INTEGER',1,DIMS,PNTR,WKLOC, STATUS)
      CALL AIF_ANTMP( WKLOC, STATUS )

      CALL IRA_INIT( STATUS )

      CALL ERR_ANNUL( STATUS )

      END
