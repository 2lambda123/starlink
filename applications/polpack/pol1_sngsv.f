      SUBROUTINE POL1_SNGSV( IGRP1, NNDF, WSCH, OUTVAR, PHI, ANLIND, T, 
     :                       EPS, TVAR, NREJ, IGRP2, TOL, INDFO, INDFC, 
     :                       MAXIT, NSIGMA, ILEVEL, HW, SETVAR, MNFRAC,
     :                       DEZERO, ZERO, STATUS )
*+
*  Name:
*     POL1_SNGSV

*  Purpose:
*     Calulates Stokes vectors from a set of single-beam intensity images.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL POL1_SNGSV( IGRP1, NNDF, WSCH, OUTVAR, PHI, ANLIND, T, EPS, 
*                      TVAR, NREJ, IGRP2, TOL, INDFO, INDFC, MAXIT, NSIGMA,
*                      ILEVEL, HW, SETVAR, MNFRAC, DEZERO, ZERO, STATUS )

*  Description:
*     This routine calculates Stokes vectors from a set of single-beam 
*     intensity images, and stores them in the supplied output NDF. The
*     method used is described by Sparks & Axon (PASP ????). Once I,Q,U
*     values have been found, the corresponding input data values can be
*     found and the residuals between these and the actual input data values
*     can be used to reject aberrant input data values (i.e. input data
*     values for which the residual is greater than NSIGMA standard
*     deviations, where the standard deviation is either the square root of
*     the supplied input variance value if supplied, or the standard
*     deviation estimated from the residuals). New I,Q,U values are then 
*     found excluding the rejected input values. This rejection process is 
*     repeated up to MAXIT times (see also TOL).

*  Arguments:
*     IGRP1 = INTEGER (Given)
*        A GRP identifier for the group containing the input NDF names. 
*        These should be aligned pixel-for-pixel.
*     NNDF = INTEGER (Given)
*        The number of input NDFs in the supplied group.
*     WSCH = INTEGER (Given)
*        The scheme to use for selecting the weights for input intensity
*        values:
*
*        1 - Use the reciprocal of the variances supplied with the
*        input images. A check will have been made that these are
*        available for all input images.
*
*        2 - Use the reciprocal of estimates of the input variances. Any
*        variances supplied with the input images are ignored.
*
*        3 - Use a constant weight of 1.0 for all input images. Any 
*        variances supplied with the input images are ignored. 

*     OUTVAR = LOGICAL (Given)
*        Should output variances be created?
*     PHI( NNDF ) = REAL (Given)
*        The effective analyser angle for each input NDF, in radians. 
*        This is the ACW angle from the output NDF X axis to the
*        effective analyser axis. For a rotating analyser system, this is
*        the same as the actual analyser angle. For a rotating half-wave
*        plate system, this is the orientation of an analyser which gives the
*        same effect as the half-wave plate/fixed analyser combination.
*     ANLIND( NNDF ) = INTEGER (Given)
*        The analyser index for each input NDF. These are indices into 
*        the IGRP2 group.
*     T( NNDF ) = REAL (Given)
*        The analyser transmission factor for each input NDF. 
*     EPS( NNDF ) = REAL (Given)
*        The analyser efficiency factor for each input NDF. 
*     TVAR( NNDF ) = REAL (Given)
*        Workspace to hold an estimate of the mean variance in each input NDF.
*     NREJ( NNDF ) = INTEGER (Returned)
*        Workspace to hold the number of pixels rejected from each NDF.
*     IGRP2 = INTEGER (Given)
*        A GRP identifier for a group holding the unique analyser identifiers 
*        found in the supplied NDFs. These are text strings which identify 
*        the analysers through which the supplied images were taken. The
*        string "DEFAULT" is used if no analyser identifier is supplied for
*        an NDF. Each unique identifier is included only once in the
*        returned group.
*     TOL = INTEGER (Given)
*        The convergence criterion for leaving the iterative loop. If the
*        the number of pixels rejected from the image changes by
*        less than or equal to TOL pixels for all images, then the process is
*        presumed to have converged. No more iterations are performed if
*        convergence has been reached or it the maximum number of
*        iterations (given by MAXIT) has been reached.
*     INDFO = INTEGER (Given)
*        An NDF identifier for the output NDF in which to store the 
*        I, Q and U values, relative to a reference direction parallel to
*        the output X axis.
*     INDFC = INTEGER (Given)
*        An NDF identifier for the output NDF in which to store the 
*        QU co-variances associated with the Stokes vectors stored in INDFO.
*        The NDF should be 2D with the same bounds as INDFO. This argument is 
*        ignored if VAR is .FALSE. 
*     MAXIT = INTEGER (Given)
*        The maximum number of rejection iterations to perform. If this is zero
*        then no rejection iterations are performed.
*     NSIGMA = REAL (Given)
*        The number of standard deviations at which input data points are
*        rejected when iterating. Ignored if MAXIT is zero.
*     ILEVEL = INTEGER (Given)
*        The information level. Zero produces no screen output; 1 gives
*        brief details of each iteration; 2 gives some details of each
*        iteration; 3 gives full details of each iteration.
*     HW = INTEGER (Given)
*        The half size of the box to use when smoothing STokes vectors
*        prior to estimating input variances (in pixels). The full size
*        used is 2*HW + 1.
*     SETVAR = LOGICAL (Given)
*        If TRUE, and if WSCH is 2, then a constant value is stored in the 
*        VARIANCE component of each input NDF on exit. This constant value 
*        is the mean variance estimated in the image.
*     MNFRAC = REAL (given)
*        This controls how much good input data is required to form a
*        good output pixel. It is given as a fraction in the range 0 to 1.
*        The miminum number of good input values required to form a good
*        output value at a particular pixel is equal to this fraction 
*        multiplied by the number of input NDFs which have good values 
*        for the pixel. The number is rounded to the nearest integer and 
*        limited to at least 3. 
*     DEZERO = LOGICAL (Given)
*        Perform zero point corrections?
*     ZERO( NNDF ) = REAL (Returned)
*        The zero points for the input NDFs.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     15-JAN-1999 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'GRP_PAR'          ! GRP constants
      INCLUDE 'PRM_PAR'          ! VAL constants

*  Arguments Given:
      INTEGER IGRP1
      INTEGER NNDF
      INTEGER WSCH
      LOGICAL OUTVAR
      REAL PHI( NNDF )
      INTEGER ANLIND( NNDF )
      REAL T( NNDF )
      REAL EPS( NNDF )
      REAL TVAR( NNDF )
      INTEGER NREJ( NNDF )
      INTEGER IGRP2
      INTEGER TOL
      INTEGER INDFO
      INTEGER INDFC
      INTEGER MAXIT
      REAL NSIGMA
      INTEGER ILEVEL
      INTEGER HW
      LOGICAL SETVAR
      REAL MNFRAC
      LOGICAL DEZERO

*  Arguments Returned:
      REAL ZERO( NNDF )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER DIM1               ! Dimension of output cube on axis 1
      INTEGER DIM2               ! Dimension of output cube on axis 2
      INTEGER DIM3               ! Dimension of output cube on axis 3
      INTEGER EL                 ! No. of elements in a plane of the output NDF
      INTEGER I                  ! Index of current input NDF
      INTEGER IERR               ! Index of first numerical error
      INTEGER INDF               ! NDF identifier for the current input NDF
      INTEGER INDFS              ! NDF identifier for the input section
      INTEGER IPCOUT             ! Pointer to output (co-variance) DATA array
      INTEGER IPDCUT             ! Pointer to filtered input intensity values
      INTEGER IPDIN              ! Pointer to input DATA array
      INTEGER IPDOUT             ! Pointer to output DATA array
      INTEGER IPIE1              ! Pointer to 1st effective intensity image
      INTEGER IPIE2              ! Pointer to 2nd effective intensity image
      INTEGER IPIE3              ! Pointer to 3rd effective intensity image
      INTEGER IPMT11             ! Pointer to column 1 row 1 image
      INTEGER IPMT21             ! Pointer to column 2 row 1 image
      INTEGER IPMT22             ! Pointer to column 2 row 2 image
      INTEGER IPMT31             ! Pointer to column 3 row 1 image
      INTEGER IPMT32             ! Pointer to column 3 row 2 image
      INTEGER IPMT33             ! Pointer to column 3 row 3 image
      INTEGER IPN                ! Pointer to array holding curr. image counts
      INTEGER IPNIN              ! Pointer to array holding orig. image counts
      INTEGER IPVEST             ! Pointer to estimated input variances
      INTEGER IPVIN              ! Pointer to input VARIANCE array
      INTEGER IPVOUT             ! Pointer to output VARIANCE array
      INTEGER IPX2Y              ! Pointer to work array     
      INTEGER IPX2Y2             ! Pointer to work array     
      INTEGER IPX3               ! Pointer to work array     
      INTEGER IPX3Y              ! Pointer to work array     
      INTEGER IPX4               ! Pointer to work array     
      INTEGER IPXY2              ! Pointer to work array     
      INTEGER IPXY3              ! Pointer to work array     
      INTEGER ITER               ! Number of rejection iterations completed
      INTEGER LBND( 3 )          ! Lower bounds of output NDF
      INTEGER NDIM               ! No. of axes in output NDF
      INTEGER NEL                ! No. of elements in whole output NDF
      INTEGER NERR               ! Number of numerical errors
      INTEGER NW                 ! No. of elements in work array
      INTEGER TOTREJ             ! Total number of input pixels rejected
      INTEGER UBND( 3 )          ! Upper bounds of output NDF
      LOGICAL CANDO              ! Is write access available?
      LOGICAL CONV               ! Has variance estimation converged?
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise pointers to dynamic memory.
      IPNIN = 0

*  Get the bounds and dimensions of the output NDF.
      CALL NDF_BOUND( INDFO, 3, LBND, UBND, NDIM, STATUS )
      DIM1 = UBND( 1 ) - LBND( 1 ) + 1
      DIM2 = UBND( 2 ) - LBND( 2 ) + 1
      DIM3 = UBND( 3 ) - LBND( 3 ) + 1

*  Store the number of elements in a single plane of the output NDF.
      EL = DIM1*DIM2

*  Map the output DATA array in which to store the IQU values. NEL gets
*  set to the number of elements in the entire 3D output cube.
      CALL NDF_MAP( INDFO, 'DATA', '_REAL', 'WRITE', IPDOUT, NEL, 
     :              STATUS )   

*  If required map the output VARIANCE array in which to store the variances 
*  on I, Q and U, and the DATA array of the co-variance NDF in which to
*  store the co-variances. 
      IF( OUTVAR ) THEN
         CALL NDF_MAP( INDFO, 'VARIANCE', '_REAL', 'WRITE', IPVOUT, NEL, 
     :                 STATUS )   
         CALL NDF_MAP( INDFC, 'DATA', '_REAL', 'WRITE', IPCOUT, EL, 
     :                 STATUS )   

*  If no variances are to be stored in the output NDF, allocate a temporary 
*  array to hold output variances and co-variances.
      ELSE
         CALL PSX_CALLOC( NEL, '_REAL', IPVOUT, STATUS )     
         CALL PSX_CALLOC( EL, '_REAL', IPCOUT, STATUS )     
      END IF

*  Allocate work space for the three terms of the vector on the left hand 
*  side of the matrix equation (these are effective measured intensities).
      CALL PSX_CALLOC( EL, '_REAL', IPIE1, STATUS )     
      CALL PSX_CALLOC( EL, '_REAL', IPIE2, STATUS )     
      CALL PSX_CALLOC( EL, '_REAL', IPIE3, STATUS )     

*  We also need work arrays to hold six elements from the matrix on the 
*  right hand side of the equation. The matrix is symetric and so only 
*  six elements are required instead of nine.
      CALL PSX_CALLOC( EL, '_REAL', IPMT11, STATUS )     
      CALL PSX_CALLOC( EL, '_REAL', IPMT21, STATUS )     
      CALL PSX_CALLOC( EL, '_REAL', IPMT31, STATUS )     
      CALL PSX_CALLOC( EL, '_REAL', IPMT22, STATUS )     
      CALL PSX_CALLOC( EL, '_REAL', IPMT32, STATUS )     
      CALL PSX_CALLOC( EL, '_REAL', IPMT33, STATUS )     

*  We also need an extra work array to hold the number of input images
*  contributing to each output pixel.
      CALL PSX_CALLOC( EL, '_REAL', IPN, STATUS )     

*  We may also need an extra work array to hold the input variance estimates.
      IF( WSCH .NE. 1 ) CALL PSX_CALLOC( EL, '_REAL', IPVEST, STATUS )     

*  We also need an extra work array to hold the filtered input intensity 
*  values (i.e a copy of an input NDF from which aberrant values have
*  been removed).
      CALL PSX_CALLOC( EL, '_REAL', IPDCUT, STATUS )     

*  We also need extra work arrays to hold co-efficient values needed in
*  when smoothing Stokes parameters in POL1_SNGSM.
      NW = ( 2*HW + 1 )**2
      CALL PSX_CALLOC( NW, '_DOUBLE', IPX4, STATUS )     
      CALL PSX_CALLOC( NW, '_DOUBLE', IPX3Y, STATUS )     
      CALL PSX_CALLOC( NW, '_DOUBLE', IPX2Y2, STATUS )     
      CALL PSX_CALLOC( NW, '_DOUBLE', IPXY3, STATUS )     
      CALL PSX_CALLOC( NW, '_DOUBLE', IPX3, STATUS )     
      CALL PSX_CALLOC( NW, '_DOUBLE', IPX2Y, STATUS )     
      CALL PSX_CALLOC( NW, '_DOUBLE', IPXY2, STATUS )     

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Indicate we have no mean variance estimates for the input NDFs yet. 
      DO I = 1, NNDF
         TVAR( I ) = VAL__BADR       
      END DO

*  Indicate we have not yet done any rejection iterations.
      ITER = 0

*  Jump back to here when the I,Q,U values have been calculated in order to
*  perform another rejection iteration.
 10   CONTINUE

*  If this is not the first pass through the loop, we will have Stokes
*  vectors in IPDOUT estimated by the previous pass. Apply light spatial 
*  smoothing to these STokes vectors. Each smoothed value is estimated by 
*  fitting a least squares quadratic surface to the data within a small 
*  fitting box.
      IF( ITER .GT. 0 ) THEN 
         CALL POL1_SNGSM( ILEVEL, HW, DIM1, DIM2, DIM3, 
     :                    %VAL( IPVOUT ), %VAL( IPDOUT ), 
     :                    %VAL( IPCOUT ), %VAL( IPIE1 ),
     :                    %VAL( IPX4 ), %VAL( IPX3Y ), 
     :                    %VAL( IPX2Y2 ), %VAL( IPXY3 ), 
     :                    %VAL( IPX3 ), %VAL( IPX2Y ),
     :                    %VAL( IPXY2 ), STATUS )

*  If required, update the image holding the estimated variance at each
*  pixel with in the input images. All input images are assumed to have
*  the same variance at any given pixel position. IPIE1 and IPIE2 are used 
*  as temporary work space.
         IF( WSCH .EQ. 2 ) THEN 
            CALL POL1_SNGVN( NNDF, IGRP1, ILEVEL, T, PHI, EPS, EL, HW,
     :                       DEZERO, DIM3, %VAL( IPDOUT ), LBND, UBND, 
     :                       %VAL( IPIE1 ), TVAR, %VAL( IPVEST ), 
     :                       %VAL( IPIE2 ), ZERO, STATUS )
         END IF

*  Display the iteration number of required.
         IF( ILEVEL .GT. 1 ) THEN
            CALL MSG_BLANK( STATUS )
            CALL MSG_SETI( 'ITER', ITER )
            CALL MSG_OUT( 'POL1_SNGSV_MSG1', ' Iteration: ^ITER...',
     :                    STATUS )
         END IF

*  On the zeroth iteration, initialise the variance estimate image to hold 
*  1.0 at every pixel. Do not do this if variances in the input NDFs will
*  be used.
      ELSE IF( WSCH .NE. 1 ) THEN
         CALL POL1_FILLR( 1.0, EL, %VAL( IPVEST ), STATUS )
      END IF

*  Calculate the effective intensities, transmittances, eficiciencies and
*  position angles, etc. See the Sparks and Axon paper for details.
*  ======================================================================

*  Initialise all the work arrays to hold zero.
      CALL POL1_FILLR( 0.0, EL, %VAL( IPIE1 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPIE2 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPIE3 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPMT11 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPMT21 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPMT31 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPMT22 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPMT32 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPMT33 ), STATUS )
      CALL POL1_FILLR( 0.0, EL, %VAL( IPN ), STATUS )

*  Indicate that we have not yet found an unconverged NDF during this
*  iteration.
      CONV = .TRUE.
      TOTREJ = 0

*  Loop round each NDF.
      DO I = 1, NNDF

*  Begin an NDF context.
         CALL NDF_BEGIN

*  Get the current input NDF identifier.
         CALL NDG_NDFAS( IGRP1, I, 'READ', INDF, STATUS )

*  Get a section from it which matches the output NDF.
         CALL NDF_SECT( INDF, 2, LBND, UBND, INDFS, STATUS ) 

*  Map the data array.
         CALL NDF_MAP( INDFS, 'DATA', '_REAL', 'READ', IPDIN, EL, 
     :                 STATUS )

*  We now need to get the variances to associate with the input 
*  intensity values. The scheme used to do this is selected by WSCH. 
*  If the VARIANCE values stored in the input NDF are to be used. 
*  map the VARIANCE array.
        IF( WSCH .EQ. 1 ) THEN
            CALL NDF_MAP( INDFS, 'VARIANCE', '_REAL', 'READ', IPVIN, 
     :                    EL, STATUS )

*  Otherwise, use the current variance estimate image.
         ELSE
            IPVIN = IPVEST
         END IF

*  Reject intensity values which lie more than NSIGMA standard deviations
*  from the intensity values implied by the current smoothed Stokes vectors. 
*  On the zeroth iteration (when no Stokes vectors are available), all 
*  intensity values are accepted.
         CALL POL1_SNGCT( INDF, ILEVEL, ITER, EL, %VAL( IPDIN ), 
     :                    %VAL( IPVIN ), T( I ), PHI( I ), EPS( I ), 
     :                    ZERO( I ), DIM3, %VAL( IPDOUT ), NSIGMA, 
     :                    TVAR( I ), TOL, DEZERO, CONV, NREJ( I ), 
     :                    %VAL( IPDCUT ), STATUS )

*  Update the total number of pixels rejected from all images.
         TOTREJ = TOTREJ + NREJ( I )

*  Update the work arrays to include the effect of the current input NDF.
         CALL POL1_SNGAD( EL, %VAL( IPDCUT ), %VAL( IPVIN ), 
     :                   PHI( I ), T( I ), EPS( I ), 
     :                   %VAL( IPIE1 ),  %VAL( IPIE2 ),  %VAL( IPIE3 ), 
     :                   %VAL( IPMT11 ), %VAL( IPMT21 ), %VAL( IPMT31 ), 
     :                                   %VAL( IPMT22 ), %VAL( IPMT32 ),
     :                                                   %VAL( IPMT33 ), 
     :                   %VAL( IPN ), STATUS )

*  End the NDF context.
         CALL NDF_END( STATUS )

      END DO

*  Report the total number of pixels rejected (except for the zeroth
*  iteration).
      IF( ITER .GT. 0 .AND. ILEVEL .GT. 1 ) THEN
         IF( ILEVEL .GT. 2 ) CALL MSG_BLANK( STATUS )
         CALL MSG_SETI( 'TOTREJ', TOTREJ )
         CALL MSG_OUT( 'POL1_SNGSV_MSG2', '   Total number of '//
     :                 'aberrant input pixels rejected: ^TOTREJ',
     :                 STATUS )
      END IF

*  Calculate the output Stokes vectors, variances, and co-variances.
*  =================================================================

*  If this is the zeroth iteration, take a copy of the number of good
*  input images at each pixel. This is done now before any bad input
*  values ahev been rejected.
      IF( ITER .EQ. 0 .AND. MAXIT .GT. 0 ) THEN 
         CALL PSX_CALLOC( EL, '_INTEGER', IPNIN, STATUS )     
         CALL VEC_RTOI( .FALSE., EL, %VAL( IPN ), %VAL( IPNIN ), IERR,
     :                  NERR, STATUS )
      END IF

*  Now calculate the output values.
      CALL POL1_SNGCL( EL, 
     :                 %VAL( IPIE1 ),  %VAL( IPIE2 ),  %VAL( IPIE3 ), 
     :                 %VAL( IPMT11 ), %VAL( IPMT21 ), %VAL( IPMT31 ), 
     :                                 %VAL( IPMT22 ), %VAL( IPMT32 ),
     :                                                   %VAL( IPMT33 ), 
     :                 %VAL( IPN ), %VAL( IPDOUT ), %VAL( IPVOUT ), 
     :                 %VAL( IPCOUT ), STATUS )

*  Go back to recalculate the output I,Q,U values excluding aberrant input
*  data values unless we have already done the maximum number of
*  iterations, or if the process has converged.
      IF( STATUS .EQ. SAI__OK .AND. ITER .LT. MAXIT .AND. 
     :    .NOT. CONV ) THEN
         ITER = ITER + 1
         IF( ILEVEL .GT. 2 ) CALL MSG_BLANK( STATUS )
         GO TO 10
      END IF

*  Warn the user if convergence was not reached.
      IF( .NOT. CONV .AND. ITER .EQ. MAXIT .AND. MAXIT .GT. 0 .AND. 
     :     ILEVEL .GT. 1 ) THEN
         CALL MSG_BLANK( STATUS )
         CALL MSG_SETI( 'MAXIT', MAXIT )
         CALL MSG_OUT( 'POL1_SNGSV_MSG0', ' Failed to reached '//
     :                 'convergence in ^MAXIT iteration.', STATUS )
         CALL MSG_BLANK( STATUS )
      END IF

*  Set bad any output pixels which were contributed to by fewer than the
*  required minimum number of uinput images.
      IF( MAXIT .GT. 0 ) THEN
         CALL POL1_SNGMN( EL, %VAL( IPNIN ), MNFRAC, %VAL( IPN ),
     :                    ILEVEL, %VAL( IPDOUT ), %VAL( IPVOUT ), 
     :                    %VAL( IPCOUT ), STATUS )
      END IF

*  If required set the VARIANCE component of each input NDF to the mean
*  variance found above.
      IF( SETVAR .AND. WSCH .EQ. 2 .AND. STATUS .EQ. SAI__OK ) THEN

         IF( ILEVEL .GT. 0 ) CALL MSG_OUT( 'POL1_SNGSV_MSG1', 
     :           ' Storing constant VARIANCE values in the input NDFs:', 
     :                                      STATUS )

         DO I = 1, NNDF
            CALL NDG_NDFAS( IGRP1, I, 'UPDATE', INDF, STATUS )
            CALL NDF_MSG( 'NDF', INDF )

            CALL NDF_ISACC( INDF, 'WRITE', CANDO, STATUS ) 

            IF( .NOT. CANDO ) THEN
               IF( ILEVEL .GT. 0 ) CALL MSG_OUT( 'POL1_SNGSV_MSG2', 
     :                    '   ^NDF : (NDF is write protected)', STATUS )

            ELSE IF( TVAR( I ) .GT. 0.0 .AND. 
     :           TVAR( I ) .NE. VAL__BADR ) THEN
               CALL NDF_MAP( INDF, 'VARIANCE', '_REAL', 'WRITE', IPVIN, 
     :                       EL, STATUS )
               CALL MSG_SETR( 'VAR', TVAR( I ) )
               IF( ILEVEL .GT. 0 ) CALL MSG_OUT( 'POL1_SNGSV_MSG3', 
     :                    '   ^NDF : ^VAR', STATUS )
               CALL POL1_FILLR( TVAR( I ), EL, %VAL( IPVIN ), STATUS )

            ELSE
               CALL NDF_RESET( INDF, 'VARIANCE', STATUS )
               IF( ILEVEL .GT. 0 ) CALL MSG_OUT( 'POL1_SNGSV_MSG4', 
     :                    '   ^NDF : (undefined)', STATUS )

            END IF
   
            CALL NDF_ANNUL( INDF, STATUS )
         END DO

      END IF


*  Tidy up
*  =======

 999  CONTINUE

*  Release the work space.
      CALL PSX_FREE( IPIE1, STATUS )
      CALL PSX_FREE( IPIE2, STATUS )
      CALL PSX_FREE( IPIE3, STATUS )
      CALL PSX_FREE( IPMT11, STATUS )
      CALL PSX_FREE( IPMT21, STATUS )
      CALL PSX_FREE( IPMT31, STATUS )
      CALL PSX_FREE( IPMT22, STATUS )
      CALL PSX_FREE( IPMT32, STATUS )
      CALL PSX_FREE( IPMT33, STATUS )
      CALL PSX_FREE( IPN, STATUS )     
      IF( IPNIN .NE. 0 ) CALL PSX_FREE( IPNIN, STATUS )     
      CALL PSX_FREE( IPX4, STATUS )     
      CALL PSX_FREE( IPX3Y, STATUS )     
      CALL PSX_FREE( IPX2Y2, STATUS )     
      CALL PSX_FREE( IPXY3, STATUS )     
      CALL PSX_FREE( IPX3, STATUS )     
      CALL PSX_FREE( IPX2Y, STATUS )     
      CALL PSX_FREE( IPXY2, STATUS )     
      IF( WSCH .NE. 1 ) CALL PSX_FREE( IPVEST, STATUS )     
      CALL PSX_FREE( IPDCUT, STATUS )     
    
      IF( .NOT. OUTVAR ) THEN
         CALL PSX_FREE( IPVOUT, STATUS )
         CALL PSX_FREE( IPCOUT, STATUS )
      END IF

      END
