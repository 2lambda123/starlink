      SUBROUTINE KPG1_TRALR( NDIMI, IDIMS, LBND, UBND, TRID, IEL,
     :                         NDIMO, COIN, COOUT, COMIN, COMAX,
     :                         STATUS )
*+
*  Name:
*     KPG1_TRALx
 
*  Purpose:
*     Finds the extreme co-ordinates of an n-d array after being
*     transformed.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_TRALx( NDIMI, IDIMS, LBND, UBND, TRID, IEL, NDIMO, COIN, COOUT,
*                      COMIN, COMAX, STATUS )
 
*  Description:
*     This routine applies a forward mapping to the co-ordinates
*     of all pixel corners in an n-dimensional array in order to find
*     the limits of the array after a transformation (forward mapping)
*     has been applied.  It assumes equally spaced co-ordinates which
*     will be true for pixel co-ordinates and many sets of data
*     co-ordinates, but should be adequate even for unevenly spaced
*     data co-ordinates.  It will only give poor results for strange
*     transformations with singularities.
 
*  Arguments:
*     NDIMI = INTEGER (Given)
*        The dimensionality of the input array.
*     IDIMS( NDIMI ) = INTEGER (Given)
*        The dimensions of the associated input n-dimensional data
*        array.
*     LBND( NDIMI ) = ? (Given)
*        The co-ordinates of the lower bounds of the associated input
*        n-dimensional array.
*     UBND( NDIMI ) = ? (Given)
*        The co-ordinates of the upper bounds of the associated input
*        n-dimensional array.
*     TRID = INTEGER (Given)
*        The TRANSFORM identifier of the mapping.
*     IEL = INTEGER (Given)
*        The first dimension of the work arrays.  It should be at least
*        IDIMS( 1 ) + 1.
*     NDIMO = INTEGER (Given)
*        The dimensionality of the output array.
*     COIN( IEL, NDIMI ) = DOUBLE PRECISION (Returned)
*        Workspace used to store the co-ordinates of a row of points
*        in the input array.
*     COOUT( IEL, NDIMO ) = DOUBLE PRECISION (Returned)
*        Workspace used to store the co-ordinates of a row of points in
*        the output array.
*     COMIN( NDIMO ) = ? (Returned)
*        The minimum co-ordinate along each dimension of the output
*        array.
*     COMAX( NDIMO ) = ? (Returned)
*        The maximum co-ordinate along each dimension of the output
*        array.
*     STATUS  =  INTEGER (Given and Returned).
*        Global status value
 
*  Notes:
*     -  There is a routine for the following numeric data types:
*     replace "x" in the routine name by D or R as appropriate.  The
*     input co-ordinate work arrays and the output limiting-co-ordinate
*     arrays must have the data type specified.
 
*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1995 August 16 (MJC):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT  NONE             ! No implicit typing allowed
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SSE global definitions
      INCLUDE 'PRM_PAR'          ! Magic-value and extreme constants
      INCLUDE 'NDF_PAR'          ! NDF constants
 
*  Arguments Given:
      INTEGER NDIMI
      INTEGER IDIMS( NDIMI )
      REAL LBND( NDIMI )
      REAL UBND( NDIMI )
      INTEGER TRID
      INTEGER IEL
      INTEGER NDIMO
 
*  Arguments Returned:
      REAL COIN( IEL, NDIMI )
      REAL COOUT( IEL, NDIMO )
      REAL COMIN( NDIMO )
      REAL COMAX( NDIMO )
 
*  Status:
      INTEGER  STATUS            ! Global status
 
*  Local Variables:
      INTEGER EL                 ! Number of elements in the output array
      LOGICAL END                ! True if need to increment the
                                 ! co-ordinates of a dimension above
                                 ! the first
      INTEGER I                  ! Loop counter
      INTEGER IAXIS              ! Loop counter for the axes
      INTEGER J                  ! Loop counter
      INTEGER K                  ! Input-array index
      INTEGER NCIN               ! Number of values in the inverse
                                 ! transformation
      INTEGER NCOUT              ! Number of values in the forward
                                 ! transformation
      INTEGER OFFSET             ! Offset within the first dimension
                                 ! of the output array
      REAL STEP( NDF__MXDIM ) ! Increments of the input co-ordinates
      INTEGER STRID( NDF__MXDIM ) ! Dimension strides for co-ords array
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*  Check the inherited status on entry.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Check the dimensionality.
      IF ( NDIMI .LT. 1 .OR. NDIMI .GT. NDF__MXDIM ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NDIM', NDIMI )
         CALL ERR_REP( 'KPG1_TRALx_INVDIM1',
     :     'Unable to transform a co-ordinate array with '/
     :     /'dimensionality of ^NDIM. (Programming error.)', STATUS )
         GOTO 999
      END IF
 
*  Check the first dimension of the co-ordinate arrays.
      IF ( IEL .LT. IDIMS( 1 ) + 1 ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'EL', IDIMS( 1 ) + 1 )
         CALL MSG_SETI( 'IEL', IEL )
         CALL ERR_REP( 'KPG1_TRALx_INVDIM2',
     :     'Unable to find co-rdinate bounds because the work array '/
     :     /'is too small (^IEL).  The first dimnension must be at '/
     :     /'least ^EL. (Programming error.)', STATUS )
         GOTO 999
      END IF
 
*  Obtain the number of co-ordinates in the transformations.
      CALL TRN_GTNVC( TRID, NCIN, NCOUT, STATUS )
 
*  Validate that the transformation is applicable to the supplied
*  arrays.
      IF ( NCOUT .NE. NDIMO .OR. NCIN .NE. NDIMI ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NCIN', NCIN )
         CALL MSG_SETI( 'NCOUT', NCOUT )
         CALL MSG_SETI( 'IN', NDIMI )
         CALL MSG_SETI( 'OUT', NDIMO )
         CALL ERR_REP( 'KPG1_TRALx_MISMATCH',
     :    'There is a mismatch between the number of values '/
     :    /'(^NCIN -> NCOUT) in the supplied transformation and the '/
     :    /'number of dimensions of the arrays (^IN -> ^OUT).', STATUS )
         GOTO 999
      END IF
 
*  Initialise the input co-ordinates.
*  ==================================
 
*  Find the step size along each axis.
      DO IAXIS = 1, NDIMI
         STEP( IAXIS ) = ( UBND( IAXIS ) - LBND( IAXIS ) ) /
     :                   NUM_ITOR( IDIMS( 1 ) )
      END DO
 
*  The co-ordinates of the first dimension are fixed throughout this
*  routine, as the transformation is applied row by row.
      DO I = 1, IDIMS( 1 ) + 1
         COIN( I, 1 ) = LBND( 1 ) + NUM_ITOR( I - 1 ) * STEP( 1 )
      END DO
 
*  Initialise the input co-ordinates for any higher dimensions.
      IF ( NDIMI .GT. 1 ) THEN
         DO IAXIS = 2, NDIMI
            DO I = 1, IDIMS( 1 ) + 1
               COIN( I, IAXIS ) = LBND( IAXIS )
            END DO
         END DO
      END IF
 
*  Compute the strides.
*  ====================
 
*  Initialise the stride of dimension number 1 for the input arrays.
*  (The stride for a dimension is the amount by which the vectorised
*  array index increases when the n-dimensional array index for that
*  dimension increases by 1.)
      STRID( 1 ) = 1
 
*  Calculate the stride for each remaining dimension.
      DO I = 2, NDIMI
         STRID( I ) = STRID( I - 1 ) * IDIMS( I - 1 )
      END DO
 
*  Find the number elements in the input file.
      EL = 1
      DO I = 1, NDIMI
         EL = EL * IDIMS( I )
      END DO
 
*   Initialise the minimum and maximum values to the opposite extremes.
      DO IAXIS = 1, NDIMI
         COMIN( IAXIS ) = VAL__MAXR
         COMAX( IAXIS ) = VAL__MINR
      END DO
 
*  Loop for every output element.
*  ==============================
 
*  K will count the index within the vector arrangement of the array.
      K = 1
      DO WHILE ( K .LE. EL )
 
*  The initial values are loaded into the input co-ordinate list.
         IF ( K .GT. 1 ) THEN
 
*  There is no need to test whether there are higher dimensions since
*  IDIMS( 2 ) will always be defined...
            END = .FALSE.
            J = 2
 
*  Update the input co-ordinates.
*  ==============================
 
*  Find which co-ordinates have to change.  Normally this will just be
*  the next higher dimension.
            DO WHILE ( .NOT. END )
               OFFSET = MOD( K, STRID( J ) )
               IF ( OFFSET .NE. 0 ) THEN
 
*  Increment the co-ordinates for that dimension.
                  DO I = 1, IDIMS( 1 ) + 1
                     COIN( I, J ) = COIN( I, J ) + STEP( J )
                  END DO
 
*  The input co-ordinates have been updated and are ready for
*  conversion.
                  END = .TRUE.
               ELSE
 
*  Just completed a stride in the Jth dimension, so we must reset it
*  to it's minimum value for the next stride.
                  DO I = 1, IDIMS( 1 ) + 1
                     COIN( I, J ) = LBND( J )
                  END DO
 
*  Now go to the next higher dimension to see if that has completed a
*  stride, or just needs to have its co-ordinate incremented.  There
*  must be a higher dimension since there are output elements to be
*  computed.
                  J = J + 1
               END IF
            END DO
         END IF
 
*   Perform the transformation to pixel indices.
*   ============================================
 
*   Convert the co-ordinates for those of the input array, to those of
*   the output array.  For efficiency reasons we compute the
*   transformation for all the co-ordinates in a row with a single
*   subroutine call.
         CALL TRN_TRNR( .TRUE., IEL, NCOUT, IDIMS( 1 ) + 1, COIN,
     :                    TRID, IEL, NCIN, COOUT, STATUS )
 
*   Might as well exit if something has gone wrong performing the
*   transformation.
         IF ( STATUS .NE. SAI__OK ) GOTO 999
 
*   Find the extreme values.
*   ========================
         DO IAXIS = 1, NDIMO
 
*   Find the minimum and maximum of the transformed array elements in
*   the output co-ordinate system.
            DO I = 1, IDIMS( 1 ) + 1
               IF ( COOUT( I, IAXIS ) .NE. VAL__BADR ) THEN
                  COMIN( IAXIS ) = MIN( COMIN( IAXIS ),
     :                                  COOUT( I, IAXIS ) )
                  COMAX( IAXIS ) = MAX( COMAX( IAXIS ),
     :                                  COOUT( I, IAXIS ) )
               END IF
            END DO
         END DO
 
*   Increment the number of input co-ordinates converted so far.
         K = K + IDIMS( 1 )
      END DO
 
  999 CONTINUE
 
      END
