      SUBROUTINE KPG1_LOCTR( NDIM, LBND, UBND, ARRAY, INIT, SEARCH,
     :                         POSTIV, MXSHFT, MAXITE, TOLER, FINAL,
     :                         STATUS )
*+
*  Name:
*     KPG1_LOCTx
 
*  Purpose:
*     Locates the centroid of a blob image feature in an n-D array.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_LOCTx( NDIM, LBND, UBND, ARRAY, INIT, SEARCH, POSTIV,
*                      MXSHFT, MAXITE, TOLER, FINAL, STATUS )
 
*  Description:
*     This routine locates the centroid of a blob feature within
*     a defined search area in an n-D array about suggested starting
*     co-ordinates, and returns the final centroid position.  A blob
*     is a series of connected pixels above or below the value of the
*     surrounding background.
 
*     The routine forms marginal profiles within a search square, and
*     then subtracts a background estimate from each profile, before
*     finding the profile centroids.  This is repeated for a specified
*     number of iterations, until the requested accuracy is met, or
*     until one of several error conditions is met.
 
*  Arguments:
*     NDIM = INTEGER (Given)
*        The dimensionality of the n-d array.  It must be greater than
*        1.
*     LBND( NDIM ) = INTEGER (Given)
*        The lower bounds of the n-d array.
*     UBND( NDIM ) = INTEGER (Given)
*        The upper bounds of the n-d array.
*     ARRAY( * ) = ? (Given)
*        The input data array.
*     INIT( NDIM ) = REAL (Given)
*        The co-ordinates of the initial estimate position.
*     SEARCH( NDIM ) = INTEGER (Given)
*        Size of the search region to be used in pixels along each
*        dimension.  Each value must be odd and lie in the range 3--51.
*     POSTIV = LOGICAL (Given)
*        True if image features are positive above the background.
*     MXSHFT( NDIM ) = REAL (Given)
*        Maximum shifts allowable from the initial position along each
*        dimension.
*     MAXITE = INTEGER  (Given)
*        Maximum number of iterations to be used.  At least one
*        iteration will be performed even if this is less than one.
*     TOLER = REAL (Given)
*        Accuracy required in the centroid position.
*     FINAL( NDIM ) = REAL (Write)
*        The final co-ordinates of the centroid position.
*     STATUS  =  INTEGER (Given and Returned).
*        Global status value
 
*  Notes:
*     -  There is a routine for each of the numeric data types: replace
*     "x" in the routine name by B, D, I, R, UB, UW, or W as
*     appropriate.
*     -  The lower and upper bounds must correspond to the dimension
*     of the array which is passed by assumed size, and therefore the
*     routine does not check for this.
 
*  Algorithm:
*     The formation of the marginal profiles is derived logically from
*     a recursive treatment of the problem of traversing an arbitrary
*     number of array dimensions whilst processing data from a
*     sub-region in each dimension.  It may be written schematically as
*     follows...
*
*        procedure LOOP( I )
*           for IDIM( I ) from LSUB( I ) to USUB( I ) do
*              if ( I = 1 ) then
*                 <form marginal profiles>
*                 return
*              else
*                 LOOP( I - 1 )
*              end
*           end
*        end
 
*     where LSUB and USUB are the lower and upper bounds respectively
*     of the region used to calculate the marginal profiles, and IDIM
*     is the index along the dimension.  A call of LOOP( NDIM ) then
*     performs the entire formation of the marginal profiles.
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
*     -  Validate the dimensions. Initialise the finished flag and the
*     region centre to be at the initial estimated position. Constrain
*     the search region sizes to between 3 and the maximum-allowed size,
*     and initialise the half-box sizes. Constrain number of iterations
*     to be positive. Initialise the number of iterations done so far.
*     -  Loop until completed.  Increment the current iteration counter.
*     Note the starting co-ords for this iteration. Work out the
*     starting and finishing edges of the current search region.
*     -  Initialise the arrays used to form the marginal profiles. Set
*     up strides for each dimension.  Initialise a pointer into the
*     region.
*     -  Invoke the recursive algorithm.
*     -  Set the pointer to the start array regions to be skipped (in
*     front of the sub-region) in the current dimension.
*     -  If the current dimension is 1 form the marginal profiles,
*     otherwise invoke the algorithm again to handle the next lower
*     dimension.
*     -  Adjust pointer to allow for data beyond the upper bound of the
*     region (after the sub-region) in the current dimension.
*     -  Return from the recursive algorithm.
*     -  For all profile bins and dimensions normalise the current y
*     bin value with apropriate sign depending on whether data are
*     positive or negative w.r.t. background pixels
*     -  Estimate the background in each dimension by assigning it the
*     lower quartile of the marginal profiles.
*     -  Initialise the sums used for forming the centroids
*     -  For all profile bins and dimensions scan the profiles, using
*     all data above the estimated backgrounds to form sums for the
*     centroids.  Increment the current values of the scanning
*     positions.  If there are data in the current bin then sum weights
*     and moment for each centroid. If no profile has any data---set the
*     co-ordinates back to their starting values, report the error and
*     exit.  Otherwise for each dimension evaluate the centroid
*     co-ordinate.
*     - Calculate the shift of the current position from the starting
*     position along each dimension.  If the maximum allowable shift
*     has been exceeded along any dimension reset the co-ordinates back
*     to the initial values, report the error including the shifts.
*     -  If the shift from the initial co-ordinates is acceptable
*     evaluate the shift in position since the last iteration.  Check
*     whether if the incremental shift is less than the accuracy
*     tolerance.  If it is or the maximum nuber of iterations has been
*     exceeded then exit the loop.
 
*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1991 March 25 (MJC):
*        Original version based on LOCATE in earlier versions of KAPPA.
*     5-JUL-1999 (DSB):
*        Fill BUFFER with spaces before using it to avoid spurious
*        trailing characters being displayed.
*     {enter_changes_here}
 
*  Bugs:
*     {note_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT  NONE           ! no implicit typing allowed
 
 
*  Global Constants:
      INCLUDE  'SAE_PAR'       ! SSE global definitions
      INCLUDE  'PRM_PAR'       ! Magic-value and extreme constants
      INCLUDE  'NDF_PAR'       ! NDF constants
 
*  Arguments Given:
      INTEGER
     :  NDIM,
     :  LBND( NDIM ),
     :  UBND( NDIM ),
     :  SEARCH( NDIM ),
     :  MAXITE
 
      REAL
     :  ARRAY( * )
 
      REAL
     :  INIT( NDIM ),
     :  MXSHFT( NDIM ),
     :  TOLER
 
      LOGICAL
     :  POSTIV
 
*  Arguments Returned:
      REAL
     :  FINAL( NDIM )
 
*  Status:
      INTEGER  STATUS
 
*  Local Constants:
      INTEGER
     :  SRCHMX                 ! Maximum search square/cube size allowed
      PARAMETER( SRCHMX  =  51 )
 
*  Local Variables:
      INTEGER
     :  CURITE,                ! Current iteration counter
     :  DIM( NDF__MXDIM ),     ! Dimensions of the array
     :  FINISH( NDF__MXDIM ),  ! Co-ords of far edge of current search
                               ! box
     :  HLFSIZ( NDF__MXDIM ),  ! Half width of the search square/cube
     :  I, J, K, L, M,         ! Counters
     :  ID,                    ! Pointer to the start of a line segment
                               ! within the search region
     :  IDIM( NDF__MXDIM ),    ! Indices of an array element
     :  MO,                    ! Offset in the marginal
     :  NAV( SRCHMX, NDF__MXDIM ), ! Used to count additions to profiles
     :  NC,                    ! Number of characters in list of shifts
     :  NSAMPL( NDF__MXDIM ),  ! number of lines/columns etc. in search
                               ! square actually used
     :  NTH( NDF__MXDIM ),     ! Value used to determine background
                               ! level - Nth smallest number taken
     :  NUMITE,                ! Maximum number of iterations to be
                               ! used, forced to be at least one
                               ! iteration
     :  START( NDF__MXDIM ),   ! Co-ords of edge of current search box
     :  STRID( NDF__MXDIM ),   ! Dimension strides for search region
     :  VO                     ! Offset in the input array
 
      CHARACTER * 120
     :  BUFFER                 ! Shifts in (s1,s2,...sn) format
 
      REAL
     :  AV( SRCHMX, NDF__MXDIM ), ! Used to sum profiles
     :  BACK( NDF__MXDIM ),    ! Background values used
     :  DAV( SRCHMX ),         ! Copy of a dimensions marginal profiles
     :  DENOM( NDF__MXDIM ),   ! Denominator in centroid calculations
     :  DUMMY,                 ! Dummy variable used in centroiding
     :  LAST( NDF__MXDIM ),    ! Co-ords worked out in last iteration
     :  NUMER( NDF__MXDIM ),   ! Numerator in centroid calculations
     :  POSCHG,                ! Shift of current posn from previous one
     :  POSN,                  ! Real position used in scanning
 
     :  STACK( SRCHMX/4 + 2 )  ! Stack used by background estimator
 
      LOGICAL                  ! If true:
     :  EVAL( NDF__MXDIM ),    ! A position along a dimension can be
                               ! evaluated
     :  FINSHD,                ! Calculation finished
     :  NEVAL,                 ! No position can be evaluated
     :  SHIFT,                 ! Shift of current posn from initial one
                               ! exceeds maximum shift allowed
     :  SMLDIM                 ! One or more dimensions are too small
 
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*    Check the inherited status on entry.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*    Check the dimensionality.
 
      IF ( NDIM .LT. 2 .AND. NDIM .GT. NDF__MXDIM ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NDIM', NDIM )
         CALL ERR_REP( 'KPG1_LOCTx_INVDIM',
     :     'Unable to find centroid of array with dimensionality of '/
     :     /'^NDIM.', STATUS )
         GOTO 999
      END IF
 
*    Compute the array dimensions.
 
      SMLDIM = .FALSE.
      DO  I = 1, NDIM
         DIM( I ) = UBND( I ) - LBND( I ) + 1
         SMLDIM = SMLDIM .OR. DIM( I ) .LT. 3
      END DO
 
*    Check that the bounds are acceptable.
 
      IF ( SMLDIM ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NDIM', NDIM )
         CALL ERR_REP( 'KPG1_LOCTx_SMLDIM',
     :     'Unable to find centroid of array, a dimension has less '/
     :     /'three elements.', STATUS )
         GOTO 999
      END IF
 
*    Initialise the completion flag.
 
      FINSHD = .FALSE.
 
*    Initialise the centre of the square/cube/hypercube to be at the
*    initial estimated position.
 
      DO  I = 1, NDIM
         FINAL( I ) = INIT( I )
      END DO
 
*    Ensure that the search square size is between 3 and the maximum
*    allowed size, and initialise the half-box size.
 
      DO  I = 1, NDIM
         NSAMPL( I ) = MIN( MAX( 3, SEARCH( I ) ), SRCHMX )
         HLFSIZ( I ) = NSAMPL( I ) / 2
      END DO
 
*    Check that at least one iteration is done.
 
      NUMITE = MAX( 1, MAXITE )
 
*    Initialise the number of iterations done so far, and start
*    the main loop.
 
      CURITE = 0
 
      DO WHILE ( .NOT. FINSHD )
 
*       Increment the current iteration counter.
 
         CURITE = CURITE + 1
 
*       Record the starting co-ordinates for this iteration.
 
         DO  I = 1, NDIM
            LAST( I ) = FINAL( I )
         END DO
 
*       Work out the starting edges of the current search square/cube/
*       hypercube.
 
         DO  I = 1, NDIM
            START( I ) = MIN( UBND( I ), MAX( LBND( I ),
     :                   NINT( MIN( MAX( -1.0E6, FINAL( I ) ), 1.0E6 ) )
     :                   - ( HLFSIZ( I ) ) ) )
            FINISH( I ) = MIN( UBND( I ), MAX( LBND( I ),
     :                   NINT( MIN( MAX( -1.0E6, FINAL( I ) ), 1.0E6 ) )
     :                   + ( HLFSIZ( I ) ) ) )
            NSAMPL( I ) = FINISH( I ) - START( I ) + 1
         END DO
 
*       Prepare to calculate the marginal profiles.
*       ===========================================
*
*       Initialise the arrays used to form the marginal profiles.
 
         DO  I = 1, NDIM
            DO  K = 1, NSAMPL( I )
               AV( K, I ) = 0.0
               NAV( K, I ) =  0
            END DO
         END DO
 
*       Initialise the stride of dimension number 1 for the data and
*       output array objects. (The stride for a dimension is the amount
*       by which the vectorised array index increases when the
*       n-dimensional array index for that dimension increases by 1.)
 
         STRID( 1 ) = 1
 
*       Calculate the stride for each remaining dimension.
 
         DO  I = 2, NDIM
            STRID( I ) = STRID( I - 1 ) *
     :                   ( UBND( I - 1 ) - LBND( I - 1 ) + 1 )
         END DO
 
*       Initialise the vector index within the square/cube.
 
         ID = 1
 
*       Recursive scanning of the array dimensions begins with the
*       highest dimension.
 
         I = NDIM
 
*       Form a section via recursive invocation starting here.
*       ======================================================
 
*       This is quite complicated as the section of the array under
*       analysis has to be extracted via pseudo-recursion.  A list of
*       vector pointers is calculated for a series of sub-sections along
*       the first dimension, each of length given by the bounds of the
*       section along the first dimension.
*
*       Increment the pointer to the end of the region which lies
*       before the lower bound of the sub-region being extracted (in the
*       current dimension), and which is therefore excluded from the
*       calculation of the marginal profiles.
 
   20 CONTINUE
         ID = ID + ( START( I ) - LBND( I ) ) * STRID( I )
 
*       This is a "DO UNTIL" loop, which starts with the current
*       dimension set to the lower bound of the sub-region and executes
*       until it goes beyond the upper bound.
 
         IDIM( I ) = START( I )
 
   30    CONTINUE
         IF ( IDIM( I ) .GT. FINISH( I ) ) GOTO 50
 
*       The algorithm calls itself recursively here.
*       ============================================
 
*       The algorithm invokes itself recursively to process the next
*       lower dimension.  Decrement the current dimension count and
*       branch back to the start.
 
         IF ( I .GT. 1 ) THEN
            I = I - 1
            GOTO 20
         ELSE
 
*          Form the marginal profiles.
*          ===========================
*
*          Sum along the line segment marked by the pointer.
 
            DO  J = START( 1 ), FINISH( 1 )
 
*             Calculate the offset within the whole array.  The pixel
*             is used in marginals for all dimensions.
 
               VO = ID + J - START( 1 )
 
*             Use IDIM to store the pixel number along the first
*             dimension so that the offset may be calculated.
 
               IDIM( 1 ) = J
 
*             Test for bad pixels.
 
               IF ( ARRAY( VO ) .NE. VAL__BADR ) THEN
 
*                Loop for each dimension.
 
                  DO  M = 1, NDIM
 
*                   Calculate the offset in the marginal profile.
 
                     MO = IDIM( M ) - START( M ) + 1
 
*                   Now finally form the marginal profiles and count
*                   of the contributing pixels.
 
                     AV( MO, M ) = AV( MO, M ) +
     :                             NUM_RTOR( ARRAY( VO ) )
                     NAV( MO, M ) = NAV( MO, M ) + 1
                  END DO
               END IF
            END DO
 
*          Update the dimension index to indicate that all of the
*          sub-region in this dimension has now been processed.
 
            IDIM( 1 ) = FINISH( 1 )
 
*          Move the pointer to allow for the pixels within the section
*          along the line.
 
            ID = ID + FINISH( 1 ) - START( 1 ) + 1
         END IF
 
*        The recursively invoked algorithm returns to this point.
*        =======================================================
 
   40    CONTINUE
 
*       The current dimension count is "popped" back to its previous
*       value before the recursively invoked algorithm returns, so
*       increment the dimension index and branch to continue execution
*       of the "DO UNTIL" loop.
 
         IDIM( I ) = IDIM( I ) + 1
         GOTO 30
 
   50    CONTINUE
 
*       Increment pointers to the end of the data region which lies
*       after the upper bound of the sub-region being processed (in the
*       current dimension), and which is therefore NOT going to be
*       included in the marginal profiles.
 
         ID = ID + ( UBND( I ) - FINISH( I ) ) * STRID( I )
 
*       The recursively invoked algorithm returns from here.
*       ===================================================
 
*       "Pop" the current dimension count and make a return from a
*       recursive invocation of the algorithm (unless this is the top
*       level invocation---i.e. the current dimension count is equal to
*       NDIM---in which case all the data have been transferred, so
*       make a final exit).
 
         IF ( I .GE. NDIM ) GOTO 60
         I = I + 1
         GOTO 40
 
   60    CONTINUE
 
*       Find the means in profile bins.
*       ===============================
 
*       Evaluate the profile bins that contain at least one valid
*       pixel. Invert the results if the blob is hole, i.e.  smaller
*       than the background.
 
         DO  I = 1, NDIM
            DO  L = 1, NSAMPL( I )
 
*             Check for nil pixels having been added to the current bin.
 
               IF ( NAV( L, I ) .EQ. 0 ) THEN
 
*                In that case, make the current bin very large so that
*                it is excluded from the quartile.
 
                  AV( L, I ) = VAL__MAXR
 
               ELSE
 
*                Normalise the current bin value, checking POSTIV.
 
                  IF ( POSTIV ) THEN
                     AV( L, I ) = AV( L, I ) / NAV( L, I )
                  ELSE
                     AV( L, I )  = -AV( L, I ) / NAV( L, I )
                  END IF
 
               END IF
 
            END DO
         END DO
 
*       Estimate the background.
*       ========================
*
         DO  I = 1, NDIM
 
*         Find the lower quartile point in each profile as a background
*         estimate.  First evaluate the quartile index.
 
            NTH( I ) = MAX( NSAMPL( I ) / 4, 2 )
 
*          Copy the marginals for the current dimension into a work
*          array.
 
            DO  J = 1, NSAMPL( I )
               DAV( J ) = AV( J, I )
            END DO
 
*          Now get the n smallest numbers in the profile, and put
*          the n-th smallest into BACK.
 
            CALL KPG1_NTHMR( .FALSE., DAV, NSAMPL( I ), NTH( I ),
     :                       STACK, STATUS )
            BACK( I ) = STACK( 1 )
 
*          Check for potential errors that might cause a divde by zero
*          later.
 
            IF ( BACK( I ) .EQ. VAL__BADR ) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP( 'KPG1_LOCTx_UNDEFBGD',
     :           'The background could not be defined in order to '/
     :           /'evaluate the centroid.', STATUS )
               GOTO 999
            END IF
         END DO
 
*       Evaluate the centroids.
*       =======================
*
*       Initialise the sums used for forming the centroids.
 
         DO  I = 1, NDIM
            NUMER( I ) = 0.0
            DENOM( I ) = 0.0
 
*          Assume for the moment that the position cannot be evaluated.
 
            EVAL( I ) = .FALSE.
         END DO
 
*       Loop for each dimension.
 
         DO  I = 1, NDIM
 
            POSN = REAL( START( I ) - 1 )
 
*          Scan the profiles, using all data above the estimated
*          backgrounds to form sums for the centroids via first-order
*          moments.
 
            DO  M = 1, NSAMPL( I )
 
*             Increment the current values of the scanning positions.
 
               POSN = POSN + 1.0
 
*             Form sums when there are data in the current bin.
 
               IF ( NAV( M, I ) .NE. 0 ) THEN
                  EVAL( I ) = .TRUE.
                  DUMMY = MAX( AV( M, I ) - BACK( I ), 0.0 )
                  NUMER( I ) = NUMER( I ) + ( POSN * DUMMY )
                  DENOM( I ) = DENOM( I ) + DUMMY
               END IF
 
            END DO
         END DO
 
*       Form the current centroid positions, checking for each
*       profile not containing data.
 
         NEVAL = .TRUE.
         DO  I = 1, NDIM
            NEVAL = NEVAL .AND. ( .NOT. EVAL( I ) )
         END DO
 
         IF ( NEVAL ) THEN
 
*          None of the profiles has any data.  Therefore set the
*          positions back to the starting values, set an error status,
*          and return.
 
            DO  I = 1, NDIM
               FINAL( I ) = VAL__BADR
            END DO
 
            STATUS = SAI__ERROR
            CALL ERR_REP( 'KPG1_LOCT_NODATA',
     :        'Unable to compute a centroid because the array is all '/
     :        /'bad.', STATUS )
            FINSHD = .TRUE.
 
         ELSE
 
            DO  I = 1, NDIM
               IF ( .NOT. EVAL( I ) ) THEN
 
*                No data in the Ith profile. Therefore set the position
*                in the Ith dimension to be the same as the previous
*                iteration.
 
                  FINAL( I ) = LAST( I )
               ELSE IF ( DENOM( I ) .LT. VAL__EPSR ) THEN
 
*                There were no data above/below the background.
 
                  STATUS = SAI__ERROR
                  CALL MSG_SETI( 'I', I )
                  IF ( POSTIV ) THEN
                     CALL MSG_SETC( 'SIGN', 'above' )
                  ELSE
                     CALL MSG_SETC( 'SIGN', 'below' )
                  END IF
                  CALL ERR_REP( 'KPG_LOCTR_NOOBJ',
     :              'Centroid ^SIGN the background could not be found '/
     :              /'in dimension ^I', STATUS )
                  FINSHD = .TRUE.
 
               ELSE
 
*                There was data, so evaluate the first-order moment to
*                obtain a centroid.  The '-0.5' converts from the pixel
*                index into a co-ordinate.
 
                  FINAL( I ) = NUMER( I ) / DENOM( I ) - 0.5
               END IF
            END DO
 
*          Test the shift.
*          ===============
*
*          Compute the shift of the current position from the starting
*          position.  Protect against no shift.
 
            SHIFT = .FALSE.
            DO  I = 1, NDIM
               SHIFT = ABS( FINAL( I ) - INIT( I ) ) .GT. MXSHFT( I )
     :                 .OR. SHIFT
            END DO
 
*          Test to see if the maximum allowable shift has been exceeded.
 
            IF ( SHIFT ) THEN
 
*             Form a list of the shifts in parentheses, separated by
*             commas.
 
               NC = 0
               BUFFER = ' '
               CALL CHR_PUTC( '( ', BUFFER, NC )
               DO  I = 1, NDIM
                  CALL CHR_PUTR( FINAL( I ) - INIT( I ), BUFFER, NC )
                  CALL CHR_PUTC( ', ', BUFFER, NC )
               END DO
               NC = NC - 2
               CALL CHR_PUTC( ' )', BUFFER, NC )
 
*             Make the error report.
 
               CALL MSG_SETC( 'BUFFER', BUFFER )
               STATUS = SAI__ERROR
               CALL ERR_REP( 'KPG1_LOCT_SHIFT',
     :           'Maximum allowable shift has been exceeded. '/
     :           /'Current shift is ^BUFFER pixels.', STATUS )
 
*             In that case, reset the position back to the initial
*             values, and return.
 
               DO  I = 1, NDIM
                 FINAL( I ) = VAL__BADR
               END DO
               FINSHD = .TRUE.
 
            ELSE
 
*             Otherwise, evaluate the shift in position since the last
*             iteration. Protect against no shift.
 
               POSCHG = 0.0
               DO  I = 1, NDIM
                  POSCHG = POSCHG + ( FINAL( I ) - LAST( I ) )**2
               END DO
               POSCHG = SQRT( MAX( VAL__SMLR, POSCHG ) )
 
*             Tolerance test
*             ==============
 
*             Check to see if the routine can return.  First check
*             the required accuracy tolerance criterion.
 
               IF ( POSCHG .LE. TOLER ) THEN
 
*                The required tolerance has been met, therefore exit
*                the loop.
 
                  FINSHD = .TRUE.
 
               ELSE IF ( CURITE .EQ. NUMITE ) THEN
 
*                The requested number of iterations have been done,
*                therefore return.
 
                  FINSHD = .TRUE.
 
               END IF
 
*          Bottom of if-shift-greater-than-MXSHFT statement.
 
            END IF
 
*       Bottom of if-no-data-in-profiles statement.
 
         END IF
 
*    Bottom of iteration do-loop.
 
      END DO
 
  999 CONTINUE
 
      END
