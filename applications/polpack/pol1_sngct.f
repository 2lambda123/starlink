      SUBROUTINE POL1_SNGCT( INDF, ILEVEL, ITER, NEL, DIN, VIN, T, PHI,
     :                       EPS, ZERO, DIMST, STOKES, NSIGMA, TVAR, 
     :                       TOL, DEZERO, CONV, NREJ, DOUT, STATUS )
*+
*  Name:
*     POL1_SNGCT

*  Purpose:
*     Reject input intensity values more than NSIGMA from the current model.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL POL1_SNGCT( INDF, ILEVEL, ITER, NEL, DIN, VIN, T, PHI, EPS, 
*                      ZERO, DIMST, STOKES, NSIGMA, TVAR, TOL, DEZERO, 
*                      CONV, NREJ, DOUT, STATUS )

*  Description:
*     This routine rejects input intensity values which deviate by more
*     than NSIGMA standard deviations from the corresponding intensity
*     value implied by the supplied stokes vectors.
*
*     If ITER is zero, all the input DIN values are copied to DOUT.

*  Arguments:
*     INDF = INTEGER (Given)
*        NDF identifier for current input NDF.
*     ILEVEL = INTEGER (Given)
*        Information reporting level.
*     ITER = INTEGER (Given)
*        Current iteration number.
*     NEL = INTEGER (Given)
*        The number of pixels in an image.
*     DIN( NEL ) = REAL (Given)
*        The input intensity values read from the current input NDF.
*     VIN( NEL ) = REAL (Given)
*        The variances associated with the input intensity values.
*     T = REAL (Given)
*        The analyser transmission factor for the current NDF.
*     PHI = REAL (Given)
*        The analyser angle for the current NDF. In radians.
*     EPS = REAL (Given)
*        The analyser efficiency factor for the current NDF.
*     ZERO = REAL (Given)
*        The zero point correction for the input NDF. This value should 
*        be addedonto the data values read from the NDF before using the 
*        data values.
*     DIMST = INTEGER (Given)
*        No. of planes in STOKES.
*     STOKES( NEL, DIMST ) = REAL (Given)
*        The current (smoothed) estimate of the Stokes parameters.
*     NSIGMA = REAL (Given)
*        The rejection threshold for aberrant points, expressed as a
*        multiple of the standard deviation.
*     TVAR = REAL (Given)
*        The mean variance in the image. Used only within screen messages.
*        Not displayed if it is VAL_BADR.
*     TOL = INTEGER (Given)
*        If the difference between the number of pixels rejected during
*        this iteration, and the number rejected during the previous 
*        iteration (as supplied in NREJ) is less than TOL, then the NDF
*        is presumed to have converged.
*     DEZERO = LOGICAL (Given)
*        Should the zero point correction be displayed at ILEVEL > 2?
*     CONV = LOGICAL (Given and Returned)
*        Return .FALSE. if this NDF has not yet converged. Unchanged
*        otherwise. Supplied value is ignored if ITER is zero.
*     NREJ = INTEGER (Given and Returned)
*        On entry, the number of pixel rejected from this NDF on the
*        previous iteration. On exit, the number of pixel rejected during 
*        this iteration. Supplied value is ignored if ITER is zero.
*     DOUT( NEL ) = REAL (Returned)
*        The output intensity values. Each pixel value is either a copy 
*        of the corresponding input pixel value, or VAL__BADR (if it
*        deviates by more than NSIGMA standard deviations form the model).
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     12-APR-1999 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants

*  Arguments Given:
      INTEGER INDF
      INTEGER ILEVEL
      INTEGER ITER
      INTEGER NEL
      REAL DIN( NEL )
      REAL VIN( NEL )
      REAL T
      REAL PHI
      REAL EPS
      REAL ZERO
      INTEGER DIMST
      REAL STOKES( NEL, DIMST )
      REAL NSIGMA
      REAL TVAR
      INTEGER TOL
      LOGICAL DEZERO

*  Arguments Given and Returned:
      LOGICAL CONV
      INTEGER NREJ

*  Arguments Returned:
      REAL DOUT( NEL )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER PATH*255
      INTEGER I
      INTEGER IAT
      INTEGER LPATH
      INTEGER NGOOD
      INTEGER NREJL
      INTEGER SEC
      REAL EXPECT
      REAL K1
      REAL K2
      REAL K3
      REAL VARFAC
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  On the zeroth iteration, just copy all input values to the output array.
      IF( ITER .EQ. 0 ) THEN
         DO I = 1, NEL
            DOUT( I ) = DIN( I )
         END DO

         NREJ = 0
         CONV = .FALSE.

*  Otherwise...
      ELSE

*  Store some constants.
         K1 = 0.5*T
         K2 = EPS*COS( 2*PHI )
         K3 = EPS*SIN( 2*PHI )
         VARFAC = NSIGMA**2

*  Initialise.
         NREJL = NREJ
         NREJ = 0
         NGOOD = 0

*  Do each pixel.
         DO I = 1, NEL

*  Check all values are good.
            IF( STOKES( I, 1 ) .NE. VAL__BADR .AND.
     :          STOKES( I, 2 ) .NE. VAL__BADR .AND.
     :          STOKES( I, 3 ) .NE. VAL__BADR .AND.
     :          DIN( I ) .NE. VAL__BADR .AND. 
     :          VIN( I ) .NE. VAL__BADR ) THEN

*  Calculate the expected intensity value on the basis of the supplied
*  Stokes vector.
               EXPECT = K1*( STOKES( I, 1 ) + K2*STOKES( I, 2 ) 
     :                                      + K3*STOKES( I, 3 ) )

*  Store bad value if the squared residual is too large. Otherwise, copy
*  the supplied input data value.
               IF( ( DIN( I ) + ZERO - EXPECT )**2 .GT. 
     :               VIN( I )*VARFAC ) THEN
                  DOUT( I ) = VAL__BADR
               ELSE
                  DOUT( I ) = DIN( I ) + ZERO
               END IF

*  If any of the input values are bad, return a bad output value.
            ELSE
               DOUT( I ) = VAL__BADR
            END IF

*  Update the number of remaining good pixels, and the number of rejcetd
*  pixels.   
            IF( DOUT( I ) .NE. VAL__BADR ) THEN
               NGOOD = NGOOD + 1

            ELSE IF( DIN( I ) .NE. VAL__BADR ) THEN
               NREJ = NREJ + 1

            END IF

         END DO

*  Get the ndf name, and find the end of the directory path (i.e. the
*  final "\" ).
         CALL NDF_MSG( 'NDF', INDF )
         CALL MSG_LOAD( ' ', '^NDF', PATH, LPATH, STATUS )
         CALL NDG1_LASTO( PATH( : LPATH ), '/', IAT, STATUS )

*  Move on to point to the first character in the NDF base name.
         IF( STATUS .EQ. SAI__OK ) THEN
            IAT = IAT + 1
         ELSE
            IAT = 1
         END IF
             
*  Truncate the patg before any opening parenthesis (NDF section).
         SEC = INDEX( PATH( : LPATH ), '(' )
         IF( SEC .GT. 0 ) LPATH = SEC - 1

*  If required, tell the user how many pixels were rejected from this NDF
*  during this iteration.
         IF( ILEVEL .GT. 2 ) THEN
            CALL MSG_BLANK( STATUS )
   
            CALL MSG_SETC( 'NDF', PATH( IAT : LPATH ) )
            CALL MSG_SETI( 'ITER', ITER )
            CALL MSG_OUT( 'POL1_SNGCT_MSG1', '   ''^NDF''', STATUS )

            CALL MSG_SETI( 'NREJ', NREJ )
            CALL MSG_SETI( 'NGOOD', NGOOD )
            CALL MSG_OUT( 'POL1_SNGCT_MSG2', '      Pixels rejected: '//
     :                     '^NREJ   Pixels remaining: ^NGOOD', STATUS )

            IF( TVAR .GE. 0.0 .AND. TVAR .NE. VAL__BADR ) THEN
               CALL MSG_SETR( 'NOISE', SQRT( TVAR ) )
               CALL MSG_OUT( 'POL1_SNGFL_MSG3', '      RMS '//
     :                       'noise estimate: ^NOISE', STATUS )
            END IF

            IF( DEZERO ) THEN
               CALL MSG_SETR( 'ZERO', ZERO )
               CALL MSG_OUT( 'POL1_SNGFL_MSG3b', '      Zero-point '//
     :                       'correction: ^ZERO', STATUS )
            END IF

*  If required, warn the user if no good pixels remain in this NDF.
         ELSE IF( ILEVEL .GT. 0 .AND. NGOOD .EQ. 0 ) THEN
            CALL MSG_SETC( 'NDF', PATH( IAT : LPATH ) )
            CALL MSG_SETI( 'ITER', ITER )
            CALL MSG_OUT( 'POL1_SNGCT_MSG3', '   WARNING: No usable '//
     :                    'pixels remain in ''^NDF'' after ^ITER '//
     :                    'rejection iterations.', STATUS )

         END IF

*  See if the NDF has converged (i.e. if the difference between the
*  number of pixels rejected in this iteration, and the number rejected in
*  the previous iteration, is less than TOL.
         IF( ABS( NREJ - NREJL ) .GT. TOL ) THEN
            CONV = .FALSE.
         END IF

      END IF

      END
