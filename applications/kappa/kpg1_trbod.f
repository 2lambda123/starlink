      SUBROUTINE KPG1_TRBOD( NDIMI, LBND, UBND, TRID, NDIMO, COMIN,
     :                         COMAX, STATUS )
*+
*  Name:
*     KPG1_TRBOx
 
*  Purpose:
*     Finds the extreme co-ordinates of an n-d array after being
*     transformed.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_TRBOx( NDIMI, LBND, UBND, TRID, NDIMO, COMIN, COMAX,
*                      STATUS )
 
*  Description:
*     This routine applies a forward mapping to the pixel co-ordinates
*     of test points in an n-dimensional array in order to find the
*     limits of the array after a transformation (forward mapping) has
*     been applied.  The test points are the vertices and the midpoints
*     between them.
 
*  Arguments:
*     NDIMI = INTEGER (Given)
*        The dimensionality of the input array.
*     LBND( NDIMI ) = ? (Given)
*        The co-ordinates of the lower bounds of the input n-dimensional
*        array.
*     UBND( NDIMI ) = ? (Given)
*        The co-ordinates of the upper bounds of the input n-dimensional
*        array.
*     TRID = INTEGER (Given)
*        The TRANSFORM identifier of the mapping.
*     NDIMO = INTEGER (Given)
*        The dimensionality of the output array.
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
*     input co-ordinate bounds and the output limiting-co-ordinate
*     arrays must have the data type specified.
 
*  Algorithm:
*     -  Validate the dimensionality and compare the number of
*     transformation values with the number of dimensions.
*     -  Find the floating-point bounds and the step interval along each
*     axis.
*     -  Compute the strides of each dimension. Find the total number of
*     test points in the co-ordinate array.
*     -  Initialise the input co-ordinates for the first test point.
*     -  Loop until all the test points have been assigned.
*     Increment the x co-ordinate of the test point for each new point
*     and copy the higher co-ordinates from the previous point.
*     However if the set of 3 is complete,  reset the co-ordinate of
*     the first dimension to the lower bound, increment the co-ordinate
*     of the next higher dimension unless this too has completed a
*     stride, whereupon it too is set to its lower bound (and so on to
*     any higher dimensions).
*     -  Convert the input to output co-ordinates for the test points.
*     -  Find the minimum and maximum co-ordinates along each output
*     dimension.
 
*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1993 March 25 (MJC):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT  NONE           ! no implicit typing allowed
 
*  Global Constants:
      INCLUDE 'SAE_PAR'        ! SSE global definitions
      INCLUDE 'PRM_PAR'        ! Magic-value and extreme constants
      INCLUDE 'NDF_PAR'        ! NDF constants
 
*  Arguments Given:
      INTEGER NDIMI
      DOUBLE PRECISION LBND( NDIMI )
      DOUBLE PRECISION UBND( NDIMI )
      INTEGER TRID
      INTEGER NDIMO
 
*  Arguments Returned:
      DOUBLE PRECISION COMIN( NDIMO )
      DOUBLE PRECISION COMAX( NDIMO )
 
*  Status:
      INTEGER  STATUS          ! Global status
 
*  Local Constants:
      INTEGER NPOINT           ! The number of test points along a
                               ! dimension (must be > 1)
      PARAMETER ( NPOINT = 3 )
 
      INTEGER MAXPTS           ! The maximum number of test points
      PARAMETER ( MAXPTS = NPOINT ** NDF__MXDIM )
 
*  Local Variables:
      DOUBLE PRECISION BOUNDI( MAXPTS, NDF__MXDIM ) ! Input co-ordinates
      DOUBLE PRECISION BOUNDO( MAXPTS, NDF__MXDIM ) ! Output co-ordinates
      INTEGER EL               ! Number of elements in the output array
      LOGICAL END              ! True if a new box has been found
                               ! or there are no more boxes to sum
      INTEGER I                ! Loop counter
      INTEGER IAXIS            ! Loop counter for the axes
      INTEGER J                ! Loop counter
      INTEGER K                ! Output-array index
      INTEGER NCIN             ! Number of values in the inverse
                               ! transformation
      INTEGER NCOUT            ! Number of values in the forward
                               ! transformation
      INTEGER OFFSET           ! Offset within the first dimension
                               ! of the output array
      DOUBLE PRECISION STEP( NDF__MXDIM ) ! Increments of the input co-ordinates
      INTEGER STRID( NDF__MXDIM ) ! Dimension strides for co-ords array
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'    ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'    ! NUM definitions for conversions
 
*.
 
*  Check the inherited status on entry.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Check the dimensionality.
      IF ( NDIMI .LT. 1 .OR. NDIMI .GT. NDF__MXDIM ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NDIM', NDIMI )
         CALL ERR_REP( 'KPG1_TRBOx_INVDIM',
     :     'Unable to interpolate an array with '/
     :     /'dimensionality of ^NDIM. (Programming error.)', STATUS )
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
         CALL ERR_REP( 'KPG1_TRBOx_MISMATCH',
     :    'There is a mismatch between the number of values '/
     :    /'(^NCIN -> NCOUT) in the supplied transformation and the '/
     :    /'number of dimensions of the arrays (^IN -> ^OUT).', STATUS )
         GOTO 999
      END IF
 
*  Find the bounds and step size.
*  ==============================
      DO IAXIS = 1, NDIMI
         STEP( IAXIS ) = ( UBND( IAXIS ) - LBND( IAXIS ) ) /
     :                   NUM_ITOD( NPOINT - 1 )
      END DO
 
*  Initialise the input co-ordinates for the first point at the lower
*  bounds.
      DO IAXIS = 1, NDIMI
         BOUNDI( 1, IAXIS ) = LBND( IAXIS )
      END DO
 
*  Compute the strides.
*  ====================
 
*  Initialise the stride of dimension number 1 for the co-ordinates.
      STRID( 1 ) = NPOINT
 
*  Calculate the stride for each remaining dimension. Also calculate
*  the strides in the concatenated axes array.
      IF ( NDIMI .GT. 1 ) THEN
         DO I = 2, NDIMI
            STRID( I ) = STRID( I - 1 ) * NPOINT
         END DO
      END IF
 
*  Find the number elements in the co-ordinate list.
      EL = 1
      DO  I = 1, NDIMI
         EL = EL * NPOINT
      END DO
 
*  Loop for every output element.
*  ==============================
 
*  K will count the index within the vector arrangement of the input
*  co-ordinate array. The co-ordinates have been set for the first
*  element.
      K = 2
      DO WHILE ( K .LE. EL )
 
*  Test whether the current input co-ordinate is at the start of a new
*  row.
         IF ( MOD( K, NPOINT ) .NE. 1 ) THEN
            BOUNDI( K, 1 ) = BOUNDI( K - 1, 1 ) + STEP( 1 )
            IF ( NDIMI .GT. 1 ) THEN
               DO IAXIS = 2, NDIMI
                  BOUNDI( K, IAXIS ) = BOUNDI( K - 1, IAXIS )
               END DO
            END IF
         ELSE
 
*  At the end of row, change the co-ordinate of the first row and
*  increment or reset higher ones as necessary.
            BOUNDI( K, 1 ) = LBND( 1 )
 
*  Start the change at the second dimension.  This code will not be
*  reached if there is only one dimension.
            END = .FALSE.
            J = 2
 
*  Update the input co-ordinates.
*  ==============================
 
*  Find which co-ordinates have to change.  Normally this will just be
*  the next higher dimension.
            DO WHILE ( .NOT. END )
               OFFSET = MOD( K, STRID( J ) )
               IF ( OFFSET .NE. 0 ) THEN
                  BOUNDI( K, J ) = BOUNDI( K - 1, J ) + STEP( J )
 
*  The input co-ordinates have been updated and are ready for
*  conversion.
                  END = .TRUE.
               ELSE
 
*  Just completed a stride in the Jth dimension, so we must reset it
*  to it's minimum value for the next stride.
                  BOUNDI( K, J ) = LBND( J )
 
*  Now go to the next higher dimension to see if that has completed a
*  stride, or just needs to have its co-ordinate incremented.  There
*  must be a higher dimension since there are output elements to be
*  computed.
                  J = J + 1
               END IF
            END DO
 
         END IF
 
*   Move to the next co-ordinate.
         K = K + 1
 
*   Bottom of pixel iteration do-loop.
      END DO
 
*   Perform the transformation.
*   ===========================
 
*   Convert the co-ordinates for those of the output array, to those
*   of the input array.
      CALL TRN_TRND( .FALSE., MAXPTS, NCOUT, EL, BOUNDI,
     :                 TRID, MAXPTS, NCIN, BOUNDO, STATUS )
 
*   Might as well exit if something has gone wrong performing the
*   transformation.
      IF ( STATUS .NE. SAI__OK ) GOTO 999
 
*   Find the extreme values.
*   ========================
      DO IAXIS = 1, NDIMO
 
*   Initialise the minimum and maximum values to the opposite extremes.
         COMIN( IAXIS ) = VAL__MAXD
         COMAX( IAXIS ) = VAL__MIND
 
*   Find the minimum and maximum of the test points in the output
*   co-ordinate system.
         DO I = 1, EL
            IF ( BOUNDO( I, IAXIS ) .NE. VAL__BADD ) THEN
               COMIN( IAXIS ) = MIN( COMIN( IAXIS ),
     :                               BOUNDO( I, IAXIS ) )
               COMAX( IAXIS ) = MAX( COMAX( IAXIS ),
     :                               BOUNDO( I, IAXIS ) )
            END IF
         END DO
      END DO
 
  999 CONTINUE
 
      END
