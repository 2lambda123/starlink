      SUBROUTINE KPG1_CMVVD( NDIM, DIMS, INARR, INVAR, COMPRS, NLIM,
     :                         WEIGHT, OUTARR, OUTVAR, SUM, NUM,
     :                         STATUS )
*+
*  Name:
*     KPG1_CMVVx

*  Purpose:
*     Compresses n-dimensional data and variance arrays by averaging in
*     `rectangular' boxes.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_CMVVx( NDIM, DIMS, INARR, INVAR, COMPRS, NLIM, WEIGHT,
*                      OUTARR, OUTVAR, SUM, NUM, STATUS )

*  Description:
*     This routine compresses an n-dimensional data array and its
*     associated variance array by integer factors along each dimension
*     by averaging the arrays' values in a rectangular box.  The output
*     data array may be variance-weighted average. 

*  Arguments:
*     NDIM = INTEGER (Given)
*        The dimensionality of the n-dimensional arrays.  It must be
*        greater than one.  To handle one-dimensional arrays, give them
*        a second dummy dimension of 1.
*     DIMS( NDIM ) = INTEGER (Given)
*        The dimensions of the input n-dimensional arrays.
*     INARR( * ) = ? (Given)
*        The input n-dimensional data array.
*     INVAR( * ) = ? (Given)
*        The input n-dimensional variance array.
*     COMPRS( NDIM ) = REAL (Given)
*        The factors along each dimension by which the input array is
*        compressed to form the output array.
*     NLIM = INTEGER (Given)
*        The minimum number of good input elements in a compression box
*        that permits the corresponding output array element to be good.
*        If fewer than NLIM pixels participated in the sum, the output
*        pixel will be bad.
*     WEIGHT = LOGICAL (Given)
*        If true, the summation is weighted by the corresponding
*        variance.  If false all the input good elements are given equal
*        weight when forming the output data-array value.
*     OUTARR( * ) = ? (Write)
*        The compressed n-dimensional data array.  Its dimension I must
*        be given by DIMS( I )/COMPRS( I ).
*     OUTVAR( * ) = ? (Write)
*        The compressed n-dimensional variance array.  Its dimension I
*        must be given by DIMS( I )/COMPRS( I ).
*     SUM( * ) = ? (Returned)
*        Workspace used for efficiency in computing the summations.
*        This should have size at least equal to DIMS( 1 ) * 2.
*     NUM( * ) = ? (Returned)
*        Workspace used to count the number of good elements in the
*        input box. This should have size at least equal to DIMS( 1 )
*        * 2.
*     STATUS  =  INTEGER (Given and Returned).
*        Global status value

*  Notes:
*     -  There is a routine for the following numeric data types:
*     replace "x" in the routine name by D or R as appropriate.  The
*     input and output arrays plus a work space must have the data type
*     specified.
*     -  There is no protection against overflows when the absolute data
*     values are very large.
*     -  If the sum of variances in the weighted average is zero, the
*     output element is bad.

*  Algorithm:
*     The n-dimensional boxes are derived from a recursive treatment of
*     the problem of traversing an arbitrary number of array dimensions
*     whilst processing data from a sub-region in each dimension.  It
*     may be written schematically as follows...
*
*        procedure LOOP( I )
*           for IDIM( I ) from 1 to DIMS( I ) do
*              if ( I = 1 ) then
*                 <sum in the rectangular box>
*                 return
*              else
*                 LOOP( I - 1 )
*              end
*           end
*        end

*     where DIMS( I ) is dimension of the region used to calculate the
*     marginal profiles, and IDIM is the index along the dimension.  A
*     call of LOOP( NDIM ) then performs the entire formation of the
*     marginal profiles.
*
*     Since Fortran does not allow recursive subroutine calls, they are
*     simulated here by branching back to the start of the algorithm,
*     having saved the previous dimension index in an appropriate
*     element of an array.  A similar process (in reverse) is used to
*     simulate a return from the recursively invoked algorithm.  To
*     avoid branching back into the range of a DO loop, looping has to
*     be implemented using IF and GO TO statements.
*
*     The algorithm operates as follows:-
*     -  Validate the dimensionality and compression factors.  Find the
*     total number of elements in the output arrays, and the effective
*     dimensions of the input arrays.  Constrain the minimum number of
*     good values within each box to be sensible.  Initialise the edges
*     of the first box.
*     -  Compute the strides of each dimension and initialise a pointer
*     to the region within the input arrays.
*     -  Loop until all the output elements have been evaluated.
*        o Initialise the arrays used to form the sums along the first
*        dimension (for all boxes along the first dimension).
*        o  Invoke the recursive algorithm.
*        o  Set the pointer to the start array regions to be skipped (in
*        front of the sub-region) in the current dimension.
*        o  If the current dimension is 1 sum within the bin and
*        increment the count (provided the input value is not bad),
*        otherwise invoke the algorithm again to handle the next lower
*        dimension.
*        o  Adjust pointer to allow for data beyond the upper bound of
*        the region (after the sub-region) in the current dimension.
*        o  Return from the recursive algorithm.
*        o  Calculate the varaince and weighted output-data-array
*        elements for each of the boxes along the first dimension,
*        incrementing the output index.  The output elements are bad
*        when the number of contributing input elements fails to exceed
*        the minimum-number criterion (separate test for data and
*        variance).

*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1991 November 25 (MJC):
*        Original version.
*     11-JUN-1998 (DSB):
*        Corrected the initialisation of the edges of the first 
*        summation box so that it works for cases where NDIM > 2.
*     1998 October 20 (MJC):
*        Protect against accessing COMPRS elements with index > 2, when
*        NDIM is <3.
*     {enter_further_changes_here}

*  Bugs:
*     {note_bugs_here}

*-

*  Type Definitions:
      IMPLICIT  NONE             ! no implicit typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SSE global definitions
      INCLUDE 'PRM_PAR'          ! Magic-value and extreme constants
      INCLUDE 'NDF_PAR'          ! NDF constants

*  Arguments Given:
      INTEGER NDIM
      DOUBLE PRECISION INARR( * )
      DOUBLE PRECISION INVAR( * )
      INTEGER DIMS( NDIM )
      INTEGER COMPRS( NDIM )
      INTEGER NLIM
      LOGICAL WEIGHT

*  Arguments Returned:
      DOUBLE PRECISION OUTARR( * )
      DOUBLE PRECISION OUTVAR( * )
      DOUBLE PRECISION SUM( * )
      DOUBLE PRECISION NUM( * )

*  Status:
      INTEGER STATUS

*  Local Variables:
      INTEGER EDIMS( NDF__MXDIM ) ! Effective dimensions of input array
      INTEGER EL                 ! Number of elements in output array
      LOGICAL END                ! New box has been found or there are
                                 ! no more boxes to sum
      INTEGER FINISH( NDF__MXDIM ) ! Indices of far edge of current
                                 ! search box 
      INTEGER I                  ! Counter
      INTEGER ID                 ! Pointer to the start of a line
                                 ! segment within the search region
      INTEGER IDIM( NDF__MXDIM ) ! Indices of an array element
      INTEGER J                  ! Counter
      INTEGER K                  ! Counter
      INTEGER M                  ! Counter
      INTEGER NUMBOX             ! Number of elements in the box
      INTEGER NVAL               ! Minimum number of input values needed
                                 ! for output (after constraint)
      INTEGER ODIMS( NDF__MXDIM ) ! Dimensions of the output array
      INTEGER START( NDF__MXDIM ) ! Indices of edge of current search
                                 ! box
      INTEGER STRID( NDF__MXDIM ) ! Dimension strides for search region
      INTEGER VO                 ! Offset in the input array

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions

*.

*  Check the inherited status on entry.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check the dimensionality.
      IF ( NDIM .LT. 2 .OR. NDIM .GT. NDF__MXDIM ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NDIM', NDIM )
         CALL ERR_REP( 'KPG1_CMVVx_INVDIM',
     :     'Unable to compress an array with '/
     :     /'dimensionality of ^NDIM. (Programming error.)', STATUS )
         GOTO 999
      END IF

*  Validate the compressions factors, checking them all before exiting
*  if an error is encountered.
      DO I = 1, NDIM
         IF ( COMPRS( I ) .LT. 1 .OR. COMPRS( I ) .GT. DIMS( I ) ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI( 'C', COMPRS( I ) )
            CALL MSG_SETI( 'I', I )
            CALL MSG_SETI( 'DIMS', DIMS( I ) )
            IF ( COMPRS( I ) .GT. DIMS( I ) ) THEN
               CALL ERR_REP( 'KPG1_CMVVx_INVCMP',
     :           'Unable to compress an array since the compression '/
     :           /'factor (^C) along dimension ^I is greater than the '/
     :           /'array dimension (^DIMS). (Programming error.)',
     :           STATUS )
            ELSE
               CALL ERR_REP( 'KPG1_CMVVx_INVCMP2',
     :           'Unable to compress an array since the compression '/
     :           /'factor (^C) along dimension ^I is non-positive. '/
     :           /'(Programming error.)', STATUS )
            END IF
         END IF
      END DO
      IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Compute the output arrays' dimensions and total number of pixels.
*  Also find the effective dimensions of the input arrays and the
*  number of pixels in the averaging box.
      EL = 1
      NUMBOX = 1
      DO  I = 1, NDIM
         ODIMS( I ) = DIMS( I ) / COMPRS( I )
         EL = EL * ODIMS( I )
         EDIMS( I ) = ODIMS( I ) * COMPRS( I )
         NUMBOX = NUMBOX * COMPRS( I )
      END DO

*  Constrain the limiting number of good values.
      NVAL = MIN( MAX( 1, NLIM ), NUMBOX )

*  Work out the starting edges of the current square/cube/hypercube to
*  sum.
      START( 1 ) = 1
      FINISH( 1 ) = EDIMS( 1 )

      START( 2 ) = 1 - COMPRS( 2 )
      FINISH( 2 ) = 0

      IF ( NDIM .GT. 2 ) THEN
         DO I = 3, NDIM
            START( I ) = 1
            FINISH( I ) = COMPRS( I )
         END DO
      END IF
 
*  Compute the strides.
*  ====================

*  Initialise the stride of dimension number 1 for the data and output
*  array objects. (The stride for a dimension is the amount by which
*  the vectorised array index increases when the n-dimensional array
*  index for that dimension increases by 1.)
      STRID( 1 ) = 1

*  Calculate the stride for each remaining dimension.
      DO  I = 2, NDIM
         STRID( I ) = STRID( I - 1 ) * DIMS( I - 1 )
      END DO

*  Loop for every output pixel.
*  ============================
      K = 0
      DO WHILE ( K .LT. EL )

*  Increment the summation box through the arrays.
*  ===============================================

*  Initialise the vector index within the square/cube/hypercube.
         ID = 1

         END = .FALSE.
         J = 2
         DO WHILE ( .NOT. END )

*  Shift the box along the current dimension.
            START( J ) = START( J ) + COMPRS( J )
            FINISH( J ) = FINISH( J ) + COMPRS( J )

*  Has it gone beyond the current dimension?
            IF ( FINISH( J ) .GT. DIMS( J ) ) THEN

*  It has therefore go to the next higher dimension.  There must be one
*  since there are output elements to be computed.
               J = J + 1

*  Reset the lower dimension's box back to its start position.
               START( J - 1 ) = 1
               FINISH( J - 1 ) = COMPRS( J - 1 )
            ELSE

*  The next box has been located successfully so exit the loop.
               END = .TRUE.
            END IF
         END DO

*  Prepare to form the sums.
*  =========================
*
*  It would be straightforward to extract each box in turn and sum
*  within it in.  However, some efficiency gain is achieved if all bins
*  along the first dimension are extracted together.

*  Initialise the arrays used to form the sums.
         DO  I = 1, 2 * ODIMS( 1 )
            SUM( I ) = 0.0D0
            NUM( I ) =  0.0D0
         END DO

*  Recursive scanning of the array dimensions begins with the highest
*  dimension.
         I = NDIM

*  Form a section via recursive invocation starting here.
*  ======================================================

*  This is quite complicated as the section of the array under analysis
*  has to be extracted via pseudo-recursion.  A list of vector pointers
*  is calculated for a series of sub-sections along the first
*  dimension, each of length given by the bounds of the section along
*  the first dimension.
*
*  Increment the pointer to the end of the region which lies before the
*  lower bound of the sub-region being extracted (in the current
*  dimension), and which is therefore excluded from the calculation of
*  the marginal profiles.
   20 CONTINUE
         ID = ID + ( START( I ) - 1 ) * STRID( I )

*  This is a "DO UNTIL" loop, which starts with the current dimension
*  set to the lower bound of the sub-region and executes until it goes
*  beyond the upper bound.
         IDIM( I ) = START( I )

   30    CONTINUE
         IF ( IDIM( I ) .GT. FINISH( I ) ) GOTO 50

*  The algorithm calls itself recursively here.
*  ============================================

*  The algorithm invokes itself recursively to process the next lower
*  dimension.  Decrement the current dimension count and branch back to
*  the start.
         IF ( I .GT. 1 ) THEN
            I = I - 1
            GOTO 20
         ELSE

*  Form the sums within each bin along the output line.
*  ====================================================
*
*  Make different sums depending on whether weighting is required.
*  Ideally this would be done across most of the routine, but the test
*  is done here for convenience and has marginal cost.
            IF ( WEIGHT ) THEN

*  Sum along the line segment marked by the pointer.
               DO  J = START( 1 ), FINISH( 1 )

*  Calculate the offset within the whole array.  The pixel is used in
*  marginals for all dimensions.
                  VO = ID + J - START( 1 )

*  Use IDIM to store the pixel number along the first dimension so that
*  the offset may be calculated.
                  IDIM( 1 ) = J

*  Test for bad pixels.
                  IF ( INARR( VO ) .NE. VAL__BADD .AND.
     :                 INVAR( VO ) .NE. VAL__BADD ) THEN

*  Determine in which bin within the output line of data the input
*  value should be inserted.
                     M = ( J - 1 ) / COMPRS( 1 ) + 1

*  Add the current element within the box to the running total for the
*  data array.  Sum the weighting will be used to obtain the output
*  variance.
                     SUM( M ) = SUM( M ) + INARR( VO ) / INVAR( VO )
                     NUM( M ) = NUM( M ) + 1.0D0 / INVAR( VO )

*  Use another part of the counting workspace for the good-pixel count.
*  Increment the number of good data and variance pixels.
                     M = M + ODIMS( 1 )
                     NUM( M ) = NUM( M ) + 1.0D0
                  END IF
               END DO

*  Handle the equal-weighted case.
            ELSE

*  Sum along the line segment marked by the pointer.
               DO  J = START( 1 ), FINISH( 1 )

*  Calculate the offset within the whole array.  The pixel is used in
*  marginals for all dimensions.
                  VO = ID + J - START( 1 )

*  Use IDIM to store the pixel number along the first dimension so that
*  the offset may be calculated.
                  IDIM( 1 ) = J

*  Test for bad pixels.
                  IF ( INARR( VO ) .NE. VAL__BADD ) THEN

*  Determine in which bin within the output line of data the input
*  value should be inserted.
                     M = ( J - 1 ) / COMPRS( 1 ) + 1

*  Add the current element within the box to the running total for the
*  data array.  Sum the weighting will be used to obtain the output
*  variance.
                     SUM( M ) = SUM( M ) + INARR( VO )
                     NUM( M ) = NUM( M ) + 1.0D0

*  The sums for the variance can only be computed if both it and the
*  corresponding data value are not bad.
                     IF ( INVAR( VO ) .NE. VAL__BADD ) THEN

*  Use another part of the workspace for the variance calculations.
                        M = M + ODIMS( 1 )

*  Add the current element within the box to the running total for the
*  variance array.
                        SUM( M ) = SUM( M ) + 1.0D0 / INVAR( VO )
                        NUM( M ) = NUM( M ) + 1.0D0
                     END IF
                  END IF
               END DO
            END IF

*  Update the dimension index to indicate that all of the sub-region in
*  this dimension has now been processed.
            IDIM( 1 ) = FINISH( 1 )

*  Move the pointer to allow for the pixels within the section along
*  the line.
            ID = ID + FINISH( 1 ) - START( 1 ) + 1
         END IF

*  The recursively invoked algorithm returns to this point.
*  =======================================================
   40    CONTINUE

*  The current dimension count is "popped" back to its previous value
*  before the recursively invoked algorithm returns, so increment the
*  dimension index and branch to continue execution of the "DO UNTIL"
*  loop.
         IDIM( I ) = IDIM( I ) + 1
         GOTO 30

   50    CONTINUE

*  Increment pointers to the end of the data region which lies after
*  the upper bound of the sub-region being processed (in the current
*  dimension), and which is therefore NOT going to be included in the
*  marginal profiles.
         ID = ID + ( DIMS( I ) - FINISH( I ) ) * STRID( I )

*  The recursively invoked algorithm returns from here.
*  ===================================================

*  "Pop" the current dimension count and make a return from a recursive
*  invocation of the algorithm (unless this is the top level
*  invocation---i.e. the current dimension count is equal to NDIM---in
*  which case all the data have been transferred, so make a final
*  exit).
         IF ( I .GE. NDIM ) GOTO 60
         I = I + 1
         GOTO 40

   60    CONTINUE

*  Find the total value in each output element.
*  ============================================
         IF ( WEIGHT ) THEN
            DO  J = 1, ODIMS( 1 )

*  Increment the output pixel index.
               K = K + 1

*  The pixel count is offset from the weights in the counting array.
*  Note this is different from the non-weighted case where the offset
*  separates the sums and ocunts of the data and variance arrays.  Here
*  they are counted together, so the non-offset part part of the
*  counting array is used for the weights.
               M = J + ODIMS( 1 )

*  If there were too few elements in the summation or the the weighting
*  is zero , set the output elements to be bad.  Otherwise normalise
*  the average by the sum of the inverse variances.  Compute the
*  variance too.
               IF ( NINT( NUM( M ) ) .LT. NVAL .OR.
     :              ABS( NUM( J ) ) .LT. VAL__SMLD ) THEN
                  OUTARR( K ) = VAL__BADD
                  OUTVAR( K ) = VAL__BADD
               ELSE
                  OUTARR( K ) = SUM( J ) / NUM( J )
                  OUTVAR( K ) = 1.0D0 / NUM( J )
               END IF
            END DO

         ELSE
            DO  J = 1, ODIMS( 1 )

*  Increment the output pixel index.
               K = K + 1

*  If there were too few data elements in the summation, set the output
*  elements to be bad.  Otherwise derive the average.
               IF ( NUM( J ) .LT. NVAL ) THEN
                  OUTARR( K ) = VAL__BADD
               ELSE
                  OUTARR( K ) = SUM( J ) / NUM( J )
               END IF

*  If there were too few variance elements in the summation or the sum
*  is zero, set the output elements to be bad.  Otherwise the variance
*  is is the inverse of the sum of inverse variances.  Remember that
*  the offset distinguishes the variance from the data sums.  The
*  counting array just counts pixels.
               M = J + ODIMS( 1 )
               IF ( NINT( NUM( M ) ) .LT. NVAL .OR.
     :              ABS( SUM( M ) ) .LT. VAL__SMLD ) THEN
                  OUTVAR( K ) = VAL__BADD
               ELSE
                  OUTVAR( K ) = 1.0D0 / SUM( M ) 
               END IF
            END DO
         END IF

*  Bottom of pixel iteration do-loop.
      END DO

  999 CONTINUE

      END
