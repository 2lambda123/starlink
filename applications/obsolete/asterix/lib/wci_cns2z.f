      SUBROUTINE WCI_CNS2Z( SYS, INP, OUT, STATUS )
*+
*  Name:
*     WCI_CNS2Z

*  Purpose:
*     Convert position in specified system to WCI standard system

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL WCI_CNS2Z( SYS, INP, OUT, STATUS )

*  Description:
*     Convert the position in the coordinate system described by SYS to the
*     WCI standard J2000 FK5 (in the same epoch)

*  Arguments:
*     SYS = INTEGER (given)
*        ADI identifier of required output coordinate system
*     INP[2] = DOUBLE (given)
*        Input position
*     OUT[2] = DOUBLE (returned)
*        Output position
*     STATUS = INTEGER (given)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     WCI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/wci.html

*  Keywords:
*     package:wci, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     5 Jan 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PKG'

*  Arguments Given:
      INTEGER			SYS
      DOUBLE PRECISION		INP(2)

*  Arguments Returned:
      DOUBLE PRECISION		OUT(2)

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			AST_QPKGI
        LOGICAL			AST_QPKGI
      EXTERNAL			SLA_EPCO		! Epoch convertor
        DOUBLE PRECISION	SLA_EPCO
      EXTERNAL                  SLA_EPJ2D               ! Epoch -> MJD
        DOUBLE PRECISION        SLA_EPJ2D

*  Local Variables:
      CHARACTER*1		EFORM			! Epoch code, B|J
      CHARACTER*3		N3			! System name code

      DOUBLE PRECISION		A, B, AW, BW	        ! Work space variables
      DOUBLE PRECISION		EPOCH			! Output system epoch
      DOUBLE PRECISION		EQNX			! Output system equinox
      DOUBLE PRECISION		FEQNX			! Final equinox
      DOUBLE PRECISION		FEPOCH			! Final epoch
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check initialised
      IF ( .NOT. AST_QPKGI( WCI__PKG ) ) CALL WCI1_INIT( STATUS )

*  Get the name of the input system
      CALL ADI_CGET0C( SYS, 'NAME', N3, STATUS )

*  Get the supplied equinox and epoch
      CALL ADI_CGET0D( SYS, 'EQUINOX', EQNX, STATUS )
      CALL ADI_CGET0C( SYS, 'EFORM', EFORM, STATUS )
      CALL ADI_CGET0D( SYS, 'EPOCH', EPOCH, STATUS )

*  Switch on output system
*    This is our standard system
      IF ( N3 .EQ. 'FK5' ) THEN

*    Precess to required epoch
        OUT(1) = INP(1)
        OUT(2) = INP(2)
        CALL SLA_PRECES( 'FK5', EQNX, 2000D0, OUT(1), OUT(2) )

*    The old system
      ELSE IF ( N3 .EQ. 'FK4' ) THEN

*      Get final epoch
        FEQNX = SLA_EPCO( 'B', EFORM, EQNX )
        FEPOCH = SLA_EPCO( 'B', EFORM, EPOCH )

*      Remove E-terms
        CALL SLA_SUBET( INP(1), INP(2), FEQNX, A, B )

*      Precess to B1950
        CALL SLA_PRECES( 'FK4', FEQNX, 1950D0, A, B )

*      Add E-terms to make FK4 position
        CALL SLA_ADDET( A, B, 1950D0, AW, BW )

*      Convert to J2000 FK5 without proper motion
        CALL SLA_FK45Z( AW, BW, FEPOCH, OUT(1), OUT(2) )

*    Ecliptic
      ELSE IF ( N3 .EQ. 'ECL' ) THEN

        CALL SLA_ECLEQ( INP(1), INP(2),
     :                  SLA_EPJ2D(SLA_EPCO( 'J', EFORM, EPOCH )),
     :                  OUT(1), OUT(2) )

*    Galactic
      ELSE IF ( N3 .EQ. 'GAL' ) THEN

        CALL SLA_GALEQ( INP(1), INP(2), OUT(1), OUT(2) )

*    Supergalactic
      ELSE IF ( N3 .EQ. 'SUP' ) THEN

        CALL SLA_GALSUP( INP(1), INP(2), A, B )
        CALL SLA_GALEQ( A, B, OUT(1), OUT(2) )

      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'WCI_CNS2Z', STATUS )

      END
