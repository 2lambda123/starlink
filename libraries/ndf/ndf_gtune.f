      SUBROUTINE NDF_GTUNE( TPAR, VALUE, STATUS )
*+
*  Name:
*     NDF_GTUNE

*  Purpose:
*     Obtain the value of an NDF_ system tuning parameter.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF_GTUNE( TPAR, VALUE, STATUS )

*  Description:
*     The routine returns the current value of an NDF_ system internal
*     tuning parameter.

*  Arguments:
*     TPAR = CHARACTER * ( * ) (Given)
*        Name of the tuning parameter whose value is required (case
*        insensitive). This name may be abbreviated, to no less than 3
*        characters.
*     VALUE = INTEGER (Returned)
*        Value of the parameter.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     See the NDF_TUNE routine for a list of the tuning parameters
*     currently available.

*  Copyright:
*     Copyright (C) 1993 Science & Engineering Research Council

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     4-OCT-1991 (RFWS):
*        Original version.
*     14-OCT-1991 (RFWS):
*        Report contextual error information.
*     17-OCT-1991 (RFWS):
*        Fixed bug: missing argument to ERR_REP.
*     5-NOV-1993 (RFWS):
*        Added new tuning parameters to control foreign format
*        conversion.
*     11-MAR-1997 (RFWS):
*        Add the DOCVT tuning parameter.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'NDF_CONST'        ! NDF_ private constants
      INCLUDE 'NDF_ERR'          ! NDF_ error codes

*  Global Variables:
      INCLUDE 'NDF_TCB'          ! NDF_ Tuning Control Block
*        TCB_DOCVT = LOGICAL (Read)
*           Do format conversions flag.
*        TCB_ETFLG = LOGICAL (Read)
*           Error tracing flag.
*        TCB_KEEP = LOGICAL (Read)
*           Keep NDF data objects flag.
*        TCB_SHCVT = LOGICAL (Read)
*           Show format conversions flag.
*        TCB_WARN = LOGICAL (Read)
*           Warning message flag.

*  Arguments Given:
      CHARACTER * ( * ) TPAR

*  Arguments Returned:
      INTEGER VALUE

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      LOGICAL NDF1_SIMLR         ! String compare with abbreviation

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Ensure that the TCB is initialised.
      CALL NDF1_INTCB( STATUS )
      IF ( STATUS .EQ. SAI__OK ) THEN

*  Test the tuning parameter name supplied against each permitted value
*  in turn, allowing abbreviation...

*  Error tracing flag.
*  ==================
*  If TRACE was specified, then return the error tracing flag value.
         IF ( NDF1_SIMLR( TPAR, 'TRACE', NDF__MINAB ) ) THEN
            IF ( TCB_ETFLG ) THEN
               VALUE = 1
            ELSE
               VALUE = 0
            END IF

*  Do format conversion flag.
*  =========================
*  If DOCVT was specified, then return the do format conversion flag
*  value.
         ELSE IF ( NDF1_SIMLR( TPAR, 'DOCVT', NDF__MINAB ) ) THEN
            IF ( TCB_DOCVT ) THEN
               VALUE = 1
            ELSE
               VALUE = 0
            END IF

*  Keep NDF objects flag.
*  =====================
*  If KEEP was specified, then return the keep NDF objects flag value.
         ELSE IF ( NDF1_SIMLR( TPAR, 'KEEP', NDF__MINAB ) ) THEN
            IF ( TCB_KEEP ) THEN
               VALUE = 1
            ELSE
               VALUE = 0
            END IF

*  Show data conversion flag.
*  =========================
*  If SHCVT was specified, then return the show data conversion flag
*  value.
         ELSE IF ( NDF1_SIMLR( TPAR, 'SHCVT', NDF__MINAB ) ) THEN
            IF ( TCB_SHCVT ) THEN
               VALUE = 1
            ELSE
               VALUE = 0
            END IF

*  Warning message flag.
*  ====================
*  If WARN was specified, then return the warning message flag value.
         ELSE IF ( NDF1_SIMLR( TPAR, 'WARN', NDF__MINAB ) ) THEN
            IF ( TCB_WARN ) THEN
               VALUE = 1
            ELSE
               VALUE = 0
            END IF

*  Unknown tuning parameter.
*  ========================
*  Report an error if the tuning parameter name is not recognised.
         ELSE
            STATUS = NDF__TPNIN
            CALL MSG_SETC( 'TPAR', TPAR )
            CALL ERR_REP( 'NDF_GTUNE_TPAR',
     : '''^TPAR'' is not a valid tuning parameter name (possible ' //
     : 'programming error).',
     :                    STATUS )
         END IF
      END IF
 
*  If an error occurred, then report context information and call the
*  error tracing routine.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'NDF_GTUNE_ERR',
     : 'NDF_GTUNE: Error obtaining the value of an NDF_ system ' //
     : 'tuning parameter.',
     :                 STATUS )
         CALL NDF1_TRACE( 'NDF_GTUNE', STATUS )
      END IF      

      END
