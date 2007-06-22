      SUBROUTINE KPS1_BFOP( RFRM, MAP, NAXR, NP, P, SIGMA, NBEAM,
     :                      REFOFF, POLAR, POLSIG, RMS, STATUS )
*+
*  Name:
*     KPS1_BFOP

*  Purpose:
*     Writes the fit coefficients and errors to output parameters.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_BFOP( RFRM, MAP, NAXR, NP, P, SIGMA, NBEAM, REFOFF,
*                     POLAR, POLSIG, RMS, STATUS )

*  Description:
*     The supplied Gaussian parameters from BEAMFIT are written to the
*     environment.  Each output parameter is a two-element vector
*     containing the fit coefficient in the first element, and its error
*     in the second for the primary beam. 
*
*     The parameters written are as follows.
*
*        CENTRE   LITERAL   The centre of the beam, formatted as a
*                           single string in the reference co-ordinate
*                           Frame
*        MAJFWHM  _DOUBLE   The major-axis full width half maximum
*                           in the reference co-ordinate Frame
*        MINFWHM  _DOUBLE   The minor-axis full width half maximum
*                           in the reference co-ordinate Frame
*        ORIENT   _DOUBLE   The orientation of the major axis in
*                           degrees
*        AMP      _DOUBLE   The amplitude of the Gaussian beam
*        BACK     _DOUBLE   The background level
*        RMS      _REAL     The RMS of the fit
*
*    In addition there is always a further vector parameter
*
*        REFOFF   LITERAL   The offset of the primary beam with respect
*                           to a reference position, and its error.
*
*    Two further parameters are written if the number of beam
*    positions is more than one.  Each is an array of length twice the
*    number of secondary beams, storing alternatinng value then error 
*    for each secondary beam position, starting with the first and 
*    progressing in order.
*
*        OFFSET   LITERAL   The radial offsets of the secondary beam
*                           positions from the primary beam, each 
*                           formatted as a single single string in the
*                           reference co-ordinate Frame
*        PA      _REAL      The position angles of the secondary beam
*                           positions with respect to the primary beam.
*
*  Arguments:
*     RFRM = INTEGER (Given)
*        A pointer to the reporting Frame (i.e. the Frame in which
*        positions are to be reported).
*     MAP = INTEGER (Given)
*        The AST Mapping from the PIXEL Frame of the NDF to the
*        reporting Frame.
*     NAXR = INTEGER (Given)
*        The number of axes in the reporting Frame.
*     NP = INTEGER (Given)
*        The size of array P.
*     P( NP ) = DOUBLE PRECISION (Given)
*        The fit parameters.  Spatial co-ordinates should be measured
*        in the reporting Frame.  See KPS1_BFCRF to convert from
*        PIXEL co-ordinates.  Only the first BF_MXCOEF elements are
*        used.
*     SIGMA( NP ) = DOUBLE PRECISION (Given)
*        The errors in the fit parameters.   Spatial co-ordinates should
*        be measured in the reporting Frame.  Only the first BF_MXCOEF 
*        elements are used.
*     NBEAM = INTEGER (Given)
*        The number of beam positions.
*     REFOFF( 2 ) = DOUBLE PRECISION (Given)
*        The offset of the primary beam with respect to the reference
*        point measured in the current WCS Frame, followed by its error.
*     POLAR( 2, NBEAM ) =  DOUBLE PRECISION (Given)
*         The polar co-ordinates of the beam features with respect to
*         the primary beam measured in the current co-ordinate Frame.
*         The orientation is a position angle in degrees, measured from
*         North through East if the current Frame is a Skyframe, or 
*         anticlockwise from the Y axis otherwise.  The POLAR(*,1)
*         values of the primary beam are ignored.
*     POLSIG( 2, NBEAM ) =  DOUBLE PRECISION (Given)
*         The standard-deviation errors associated with the polar 
*          co-ordinates supplied in argument POLAR.  The POLSIG(*,1)
*         values of the primary beam are ignored.
*     RMS = DOUBLE PRECISION (Given)
*        The RMS residual in pixels.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2007 Particle Physics and Astronomy Research 
*     Council.  All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
*     02111-1307, USA.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     2007 March 16 (MJC):
*        Original version.
*     2007 May 21 (MJC):
*        Remove the conversions from PIXEL to the reporting Frame.
*     2007 May 30 (MJC):
*        Add NBEAM, POLAR, and POLSIG arguments to report polar
*        co-ordinates of secondary-beam features.
*     2007 June 11 (MJC):
*        Made RMS single precision.
*     2007 June 15 (MJC):
*        Add REFOFF argument and parameter.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'MSG_PAR'          ! Message-system public constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants
      INCLUDE 'NDF_PAR'          ! NDF constants 
      INCLUDE 'AST_PAR'          ! AST constants and functions
      INCLUDE 'BF_PAR'           ! BEAMFIT constants

*  Arguments Given:
      INTEGER RFRM
      INTEGER MAP
      INTEGER NAXR
      INTEGER NP
      DOUBLE PRECISION P( NP )
      DOUBLE PRECISION SIGMA( NP )
      INTEGER NBEAM
      DOUBLE PRECISION REFOFF( 2 )
      DOUBLE PRECISION POLAR( 2, NBEAM )
      DOUBLE PRECISION POLSIG( 2, NBEAM )
      DOUBLE PRECISION RMS

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER BUFSIZ             ! Buffers' dimension
      PARAMETER ( BUFSIZ = 2 * ( BF__MXPOS - 1 ) )

      DOUBLE PRECISION PI
      PARAMETER ( PI = 3.1415926535898 )

      DOUBLE PRECISION R2D       ! Radians to degrees
      PARAMETER ( R2D = 180.0D0 / PI )

*  Local Variables:
      CHARACTER*50 AXVAL         ! A formatted axis value
      INTEGER IAT                ! No. of characters currently in buffer
      INTEGER IB                 ! Beam loop counter
      INTEGER J                  ! Loop count
      INTEGER K                  ! Loop count
      CHARACTER*128 LINE( BUFSIZ ) ! Buffer for output text
      DOUBLE PRECISION S2FWHM    ! Sigma-to-FWHM conversion
      DOUBLE PRECISION WORK( 2 ) ! Work array for storing values
                                 ! and errors
      REAL WORKER( BUFSIZ )      ! Work array for storing values
                                 ! and errors

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  CENTRE
*  ======

*  Now write the primary-beam position out to the output parameters. 
*  The complete set of axis values (separated by spaces) is written to
*  CENTRE.
      IAT = 0
      LINE( 1 ) = ' '

      DO J = 1, NAXR
         AXVAL = AST_FORMAT( RFRM, 1, P( J ), STATUS )
         CALL CHR_APPND( AXVAL, LINE( 1 ), IAT )
         IAT = IAT + 1
      END DO

      IAT = 0
      LINE( 2 ) = ' '
      IF ( SIGMA( 1 ) .NE. VAL__BADD ) THEN
         AXVAL = AST_FORMAT( RFRM, 1, SIGMA( 1 ), STATUS )
      ELSE
         AXVAL = 'bad'
      END IF
      CALL CHR_APPND( AXVAL, LINE( 2 ), IAT )
      IAT = IAT + 1

*  Now we swap the path to the second axis.
      IF ( SIGMA( 2 ) .NE. VAL__BADD ) THEN
         AXVAL = AST_FORMAT( RFRM, 1, SIGMA( 2 ), STATUS )
      ELSE
         AXVAL = 'bad'
      END IF
      CALL CHR_APPND( AXVAL, LINE( 2 ), IAT )
      IAT = IAT + 1

      CALL PAR_PUT1C( 'CENTRE', 2, LINE, STATUS )

*  FWHMs
*  =====
      S2FWHM = SQRT( 8.D0 * LOG( 2.D0 ) )

      WORK( 1 ) = P( 3 ) * S2FWHM
      WORK( 2 ) = SIGMA( 3 ) * S2FWHM
      CALL PAR_PUT1D( 'MAJFWHM', 2, WORK, STATUS )

      WORK( 1 ) = P( 4 ) * S2FWHM
      WORK( 2 ) = SIGMA( 4 ) * S2FWHM
      CALL PAR_PUT1D( 'MINFWHM', 2, WORK, STATUS )

*  ORIENT
*  ======

* Convert to degrees.  May need a +/- 90 later...
      WORK( 1 ) = P( 5 ) * R2D
      WORK( 2 ) = SIGMA( 5 ) * R2D
      CALL PAR_PUT1D( 'ORIENT', 2, WORK, STATUS )

*  AMP
*  ===
      WORK( 1 ) = P( 6 )
      WORK( 2 ) = SIGMA( 6 )
      CALL PAR_PUT1D( 'AMP', 2, WORK, STATUS )

*  BACK
*  ====
      WORK( 1 ) = P( 7 )
      WORK( 2 ) = SIGMA( 7 )
      CALL PAR_PUT1D( 'BACK', 2, WORK, STATUS )

*  RMS
*  ===
      CALL PAR_PUT0R( 'RMS', SNGL( RMS ), STATUS )

*  OFFSET of primary beam
*  ======================

*  Write the primary-beam offset and error out to the output
*  parameter.  Both values are written to REFOFF.
      LINE( 1 ) = AST_FORMAT( RFRM, 1, REFOFF( 1 ), STATUS )

      IF ( REFOFF( 2 ) .NE. VAL__BADD ) THEN
         LINE( 2 ) = AST_FORMAT( RFRM, 1, REFOFF( 2 ), STATUS )
      ELSE
         LINE( 2 ) = 'bad'
      END IF

      CALL PAR_PUT1C( 'REFOFF', 2, LINE, STATUS )

      
*  OFFSET and PA of secondary beam positions
*  =========================================
      IF ( NBEAM .GT. 1 ) THEN
         K = 0
         DO IB = 2, NBEAM

*  Now write the secondary-beam polar position and error out to the output
*  parameters.  The complete set of values (separated by spaces) is 
*  written to OFFSET.
            K = K + 1
            LINE( K ) = AST_FORMAT( RFRM, 1, POLAR( 1, IB ), STATUS )

            K = K + 1
            IF ( POLSIG( 1, IB ) .NE. VAL__BADD ) THEN
               LINE( K ) = AST_FORMAT( RFRM, 1, POLSIG( 1, IB ), 
     :                                 STATUS )
            ELSE
               LINE( K ) = 'bad'
            END IF

*  PA
*  ==
            WORKER( K - 1 ) = SNGL( POLAR( 2, IB ) )
            IF ( POLSIG( 1, IB ) .NE. VAL__BADD ) THEN
               WORKER( K ) = SNGL( POLSIG( 2, IB ) )
            ELSE
               WORKER( K ) = VAL__BADR
            END IF
         END DO

         CALL PAR_PUT1C( 'OFFSET', K, LINE, STATUS )
         CALL PAR_PUT1R( 'PA', K, WORKER, STATUS )
      END IF

      END
