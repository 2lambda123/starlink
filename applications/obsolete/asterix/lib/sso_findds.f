*+  SSO_FINDDS - Introduce locator to SSO system
      SUBROUTINE SSO_FINDDS( LOC, ADDIFNEW, N, STATUS )
*
*    Description :
*
*     Look up table of existing datasets. If present, return the entry
*     number. If not present, add to table if the ADDIFNEW flag is true.
*
*    Authors :
*
*     David J. Allan (BHVAD::DJA)
*
*    History :
*
*      2 Jul 91 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'AST_PKG'
*
*    Global variables :
*
      INCLUDE 'SSO_CMN'
*
*    Status :
*
      INTEGER STATUS
*
*    Import :
*
      CHARACTER*(DAT__SZLOC)     LOC                ! The dataset
      LOGICAL                    ADDIFNEW           ! Add if new locator
*
*    Export :
*
      INTEGER                    N                  ! The dataset slot
*
*    External References:
*
      EXTERNAL			AST_QPKGI
        LOGICAL			AST_QPKGI
*
*    Local variables :
*
      INTEGER                    I                  ! Loop over SSO resources
*-

      IF ( STATUS .EQ. SAI__OK ) THEN

*      Initialise yet?
        IF ( .NOT. AST_QPKGI( SSO__PKG ) ) CALL SSO_INIT( STATUS )

*      Search for locator in table
        N = 0
        I = 1
        DO WHILE ( ( I .LE. SSO__MXDS ) .AND. ( N .EQ. 0 ) )
          IF ( ( LOC .EQ. SSO_DS_LOC(I) ) .AND. SSO_DS_USED(I) ) THEN
            N = I
          ELSE
            I = I + 1
          END IF
        END DO

*      Add to table if not present?
        IF ( ( N .EQ. 0 ) .AND. ADDIFNEW ) THEN

*        Search for unused slot
          I = 1
          DO WHILE ( ( I .LE. SSO__MXDS ) .AND. ( N .EQ. 0 ) )
            IF ( .NOT. SSO_DS_USED(I) ) THEN
              N = I
            ELSE
              I = I + 1
            END IF
          END DO

*        No more slots?
          IF ( N .EQ. 0 ) THEN
            CALL MSG_PRNT( '! Maximum number of datasets exceeded' )
            STATUS = SAI__ERROR

          ELSE

*          Use slot
            SSO_DS_USED(N) = .TRUE.
            SSO_DS_LOC(N) = LOC

          END IF

        END IF

*      Tidy up
        IF ( STATUS .NE. SAI__OK ) THEN
          CALL AST_REXIT( 'SSO_FINDDS', STATUS )
        END IF

      END IF

      END
