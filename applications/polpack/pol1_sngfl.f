      SUBROUTINE POL1_SNGFL( INDF, ITER, VSCH, ILEVEL, T, PHI,
     :                       EPS, DIM1, DIM2, DIM3, STOKES, 
     :                       WORK, NSIGMA, IPDIN, IPVIN, FRDIN, FRVIN, 
     :                       STATUS )
*+
*  Name:
*     POL1_SNGFL

*  Purpose:
*     Obtain input intensity avd variance values to use in single-beam mode.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL POL1_SNGFL( INDF, ITER, VSCH, ILEVEL, T, PHI, EPS, 
*                      DIM1, DIM2, DIM3, STOKES, WORK, NSIGMA, IPDIN, 
*                      IPVIN, FRDIN, FRVIN, STATUS )

*  Description:
*     This routine returns pointers to arrays holding the intensity values 
*     and associated variances to use for a given input intensity NDF.

*  Arguments:
*     INDF = INTEGER (Given)
*        The input intensity NDF identifier.
*     ITER = INTEGER (Given)
*        The index of the current iteration.
*     VSCH = INTEGER (Given)
*        The scheme to use for selecting the variances to return:
*
*        1 - Return the variances supplied with the input images. A check
*        will have been made that these are available for all input images.
*
*        2 - Return the variances supplied with the input images, if
*        available. If an input image does not have associated variances  
*        then the returned variances for that image are estimated from the 
*        spread of input intensity values. 
*
*        3 - Return variances estimated from the spread of input intensity 
*        values. Any variances supplied with the input images are ignored.
*
*        4 - Return a constant variance of 1.0 for all input images. Any 
*        variances supplied with the input images are ignored. 
*
*     ILEVEL = INTEGER (Given)
*        Amount of information to display on the screen. 
*     T = REAL (Given)
*        The analyser transmission factor for the supplied array.
*     PHI = REAL (Given)
*        The analyser angle for the supplied array. In radians.
*     EPS = REAL (Given)
*        The analyser efficiency factor for the supplied array.
*     DIM1 = INTEGER (Given)
*        No. of pixels per row in each plane.
*     DIM2 = INTEGER (Given)
*        No. of rows in each plane.
*     DIM3 = INTEGER (Given)
*        No. of planes.
*     STOKES( DIM1, DIM2, DIM3 ) = REAL (Given)
*        The current (smoothed) estimate of the Stokes parameters.
*     WORK( DIM1, DIM2 ) = REAL (Given)
*        A work array.
*     NSIGMA = REAL (Given)
*        The rejection threshold for aberrant points, expressed as a
*        multiple of the standard deviation.
*     IPDIN = INTEGER (Returned)
*        A pointer to the array holding the intensity values to use.
*     IPVIN = INTEGER (Returned)
*        A pointer to the array holding the variance values to use.
*     FRDIN = LOGICAL (Returned)
*        If .TRUE. then IPDIN should be freed using PSX_FREE when no
*        longer needed. Otherwise, the pointer will be freed when the NDF
*        context is ended.
*     FRVIN = LOGICAL (Returned)
*        If .TRUE. then IPVIN should be freed using PSX_FREE when no
*        longer needed. Otherwise, the pointer will be freed when the NDF
*        context is ended.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     25-FEB-1999 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER INDF
      INTEGER ITER
      INTEGER VSCH
      INTEGER ILEVEL
      REAL T
      REAL PHI
      REAL EPS
      INTEGER DIM1
      INTEGER DIM2
      INTEGER DIM3
      REAL STOKES( DIM1, DIM2, DIM3 )
      REAL WORK( DIM1, DIM2 )
      REAL NSIGMA

*  Arguments Returned:
      INTEGER IPDIN
      INTEGER IPVIN
      LOGICAL FRDIN
      LOGICAL FRVIN

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER PATH*256         ! Full NDF path 
      INTEGER EL                 ! No. of pixels in one plane
      INTEGER IAT                ! Index of basename 
      INTEGER IPD                ! Pointer to NDF DATA array
      INTEGER NGOOD              ! No. of good pixels remaining
      INTEGER NREJ               ! No. of pixels rejected this iteration
      INTEGER IPW1               ! Pointer to work array                
      INTEGER IPW2               ! Pointer to work array                
      INTEGER IPWGT              ! Pointer to squared residual weights array
      INTEGER LPATH              ! Used length of PATH
      LOGICAL INVAR              ! Does the NDF have a VARIANCE component?
      REAL DINMAX                ! Max input data value
      REAL DINMIN                ! Min input data value
      REAL NOISE                 ! Estimate of the backgroudn noise level
*.

*  Initialise the returned flags.
      FRDIN = .FALSE.
      FRVIN = .FALSE.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  See if the input image has a VARIANCE component.
      CALL NDF_STATE( INDF, 'VARIANCE', INVAR, STATUS )

*  If this is the first time through, get the required arrays from the NDF.
      IF( ITER .EQ. 0 ) THEN

*  Map the data array.
         CALL NDF_MAP( INDF, 'DATA', '_REAL', 'READ', IPDIN, EL, 
     :                 STATUS )

*  We now need to get the variances for the input image. The scheme
*  used to do this is selected by VSCH. If the input VARIANCE values 
*  are to be used...
         IF( VSCH .EQ. 1 .OR. ( VSCH .EQ. 2 .AND. INVAR ) ) THEN

*  Map the VARIANCE array if available, otherwise report an error.
            IF( INVAR ) THEN
               CALL NDF_MAP( INDF, 'VARIANCE', '_REAL', 'READ', IPVIN, 
     :                       EL, STATUS )

            ELSE IF( STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL NDF_MSG( 'NDF', INDF )
               CALL ERR_REP( 'POL1_SNGFL_ERR1', 'POL1_SNGFL: No '//
     :                       'VARIANCE component in ''^NDF'' '//
     :                       '(programming error).', STATUS )
            END IF

*  Otherwise, allocate an array to hold synthetic variances, and fill the
*  array with the constant value 1.0.
         ELSE
            CALL PSX_CALLOC( EL, '_REAL', IPVIN, STATUS )
            CALL POL1_FILLR( 1.0, EL, %VAL( IPVIN ), STATUS )

*  Indicate that the variance array must be freed when no longer needed.
            FRVIN = .TRUE.

         END IF

*  If this is not the first time through...
      ELSE

*  Map the NDF data array.
         CALL NDF_MAP( INDF, 'DATA', '_REAL', 'READ', IPD, EL, 
     :                 STATUS )

*  Allocate an array to hold the filtered intensity values, and indicate
*  this array need to be freed when no longer needed.
         CALL PSX_CALLOC( EL, '_REAL', IPDIN, STATUS )
         FRDIN = .TRUE.

*  Calculated the squared residuals between the NDF intensity values and
*  the intensity values implied by the supplied Stokes vectors. These are
*  stored in the array pointed to by IPDIN (temporarily). This also
*  returns the max and min NDF intensity values.
         CALL PSX_CALLOC( EL, '_REAL', IPWGT, STATUS )
         CALL POL1_SNGSI( T, PHI, EPS, EL, DIM1, DIM2, STOKES, 
     :                    %VAL( IPD ), %VAL( IPDIN ), WORK, 
     :                    %VAL( IPWGT ), DINMAX, DINMIN, STATUS )

*  We now need to get the variances for the input image. The scheme
*  used to do this is selected by VSCH. If the input VARIANCE values 
*  are to be used, map them.
         IF( VSCH .EQ. 1 .OR. ( VSCH .EQ. 2 .AND. INVAR ) ) THEN
            CALL NDF_MAP( INDF, 'VARIANCE', '_REAL', 'READ', IPVIN, EL, 
     :                    STATUS )

*  Otherwise, we estimate the variances. If constant weights were requested, 
*  these estimates will be over-written by 1.0 before returning them. The
*  variances here are then only used to identify any aberant pixels.
         ELSE      

*  First allocate a variance array and indicate it is to be freed when no
*  longer needed.
            CALL PSX_CALLOC( EL, '_REAL', IPVIN, STATUS )
            FRVIN = .TRUE.

*  Now calculate the variance estmates and store them in this array.
            CALL PSX_CALLOC( DIM1, '_DOUBLE', IPW1, STATUS )
            CALL PSX_CALLOC( DIM1, '_DOUBLE', IPW2, STATUS )


            CALL POL1_SNGVR( DIM1, DIM2, %VAL( IPDIN ), WORK, 
     :                       %VAL( IPWGT ), DINMAX, DINMIN, 
     :                       %VAL( IPVIN ), %VAL( IPW1 ), %VAL( IPW2 ), 
     :                       NOISE, STATUS )

            CALL PSX_FREE( IPW1, STATUS )
            CALL PSX_FREE( IPW2, STATUS )
         END IF

*  Free the array holding the squared residuals weights.
         CALL PSX_FREE( IPWGT, STATUS )

*  Reject aberant data values.
         CALL POL1_SNGRJ( NSIGMA, EL, %VAL( IPD ), %VAL( IPVIN ), 
     :                    %VAL( IPDIN ), NREJ, NGOOD, STATUS )

*  If constant weights are required, fill the variance array with 1.0.
         IF( VSCH .EQ. 4 ) THEN
            CALL POL1_FILLR( 1.0, EL, %VAL( IPVIN ), STATUS )
         END IF

*  Get the ndf name, and find the end of the directory path (i.e. the
*  final "\" ).
         CALL NDF_MSG( 'NDF', INDF )
         CALL MSG_LOAD( ' ', '^NDF', PATH, LPATH, STATUS )
         CALL NDG1_LASTO( PATH( : LPATH ), '/', IAT, STATUS )

*  Move on to point to the first character ni the ndf base name.
         IF( STATUS .EQ. SAI__OK ) THEN
            IAT = IAT + 1
         ELSE
            IAT = 1
         END IF
             
*  If required, tell the user how many pixels were rejected from this NDF
*  during this iteration.
         IF( ILEVEL .GT. 1 ) THEN
            CALL MSG_BLANK( STATUS )

            CALL MSG_SETC( 'NDF', PATH( IAT : LPATH ) )
            CALL MSG_SETI( 'ITER', ITER )
            CALL MSG_OUT( 'POL1_SNGFL_MSG1', '   Iteration: ^ITER  --'//
     :                    ' ''^NDF''', STATUS )

            CALL MSG_SETI( 'NREJ', NREJ )
            CALL MSG_SETI( 'NGOOD', NGOOD )
            CALL MSG_OUT( 'POL1_SNGFL_MSG2', '      Pixels rejected: '//
     :                    '^NREJ   Pixels remaining: ^NGOOD', STATUS )

            IF( FRVIN ) THEN
               CALL MSG_SETR( 'NOISE', NOISE )
               CALL MSG_OUT( 'POL1_SNGFL_MSG3', '      Background '//
     :                       'noise estimate: ^NOISE', STATUS )
            END IF

*  If required, warn the user if no good pixels remain in this NDF.
         ELSE IF( ILEVEL .GT. 0 .AND. NGOOD .EQ. 0 ) THEN
            CALL MSG_SETC( 'NDF', PATH( IAT : LPATH ) )
            CALL MSG_SETI( 'ITER', ITER )
            CALL MSG_OUT( 'POL1_SNGFL_MSG4', '   WARNING: No usable '//
     :                    'pixels remain in ''^NDF'' after ^ITER '//
     :                    'rejection iterations.', STATUS )
         END IF

      END IF

      END
