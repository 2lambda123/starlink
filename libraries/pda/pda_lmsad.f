      SUBROUTINE PDA_LMSAD( NEL, ARRAY, IP, LINK )
*+
*  Name:
*     PDA_LMSAD

*  Purpose:
*     Sorts an array using a list-merge technique.

*  Language:
*     Fortran-77

*  Invocation:
*     CALL PDA_LMSAD( NEL, ARRAY, IP )

*  Description:
*     This routine sorts an array using a list-merge technique. The sort
*     is returned as an array of indices into the input array.  It has a
*     guaranteed NlogN sorting time and works well for all inputs. It
*     uses the natural ordering of the data and will terminate
*     immediately if the input is already sorted. A major advantage of
*     this method over quicksort (which is generally faster for random
*     data, but doesn't have guaranteed NlogN behaviour)) is that it is
*     stable. This means that any tied keys preserve their input
*     order. A disadvantage is that an extra 2 elements are required in
*     the input array and a second array is required.
*
*     This routine has been modified to deal with the case when the
*     input data is already sorted by an index array (this allows
*     repeated calls of this routine sorting different keys each time,
*     but still preserving the stability of the solution across all
*     sorts).

*  Arguments:
*     NEL = INTEGER (Given)
*       The number of elements of ARRAY to be sorted. Note that the
*       arrays must be at least 2 larger then this value.
*     ARRAY( NEL + 2 ) = DOUBLE PRECISION (Given)
*        The array of values to be sorted. This is unchanged on exit.
*     IP( NEL + 2 ) = INTEGER (Given and Returned)
*        On entry these indicate the current sorted order of the data in
*        ARRAY (i.e. if any data related to ARRAY has already been
*        sorted and you want to retain the stability of that sort, you
*        should indicate the true order of the input data using this).
*        If the data isn't already sorted by index then just set this
*        array to the monotonically increasing range 1...N.
*        On exit this array contains the indices of the sorted
*        data. I.e. on exit ARRAY(IP(1)) is the smallest value,
*        ARRAY(IP(2)) then next largest etc. up to ARRAY(IP(N)).
*     LINK( NEL + 2 ) = INTEGER (Returned)
*        On exit this will contain the same information as IP. It is
*        used internally as workspace.

*  Timing:
*     Scales roughly as NlogN.

*  References:
*     Knuth, D.E., "The art of computer programming", vol 3, algorithm L.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     13-SEP-1996 (PDRAPER):
*        Original version based on Knuth's algorithm L.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE             ! No implicit typing

*  Arguments Given:
      INTEGER NEL
      DOUBLE PRECISION ARRAY( 0 : NEL + 1 )

      INTEGER IP( 0: NEL + 1 )
      
*  Arguments Returned:
      INTEGER LINK( 0 : NEL + 1 )
      
*  Local Variables:
      INTEGER T
      INTEGER P
      INTEGER Q
      INTEGER S
      INTEGER K
      INTEGER D
      INTEGER I
      INTEGER IFAIL
*.

*  Preparatory work. Move the elements of ARRAY up one position to free
*  the first element.
      DO 20 I = NEL, 1, -1
         ARRAY( I ) = ARRAY( I - 1 )
         IP( I ) = IP( I - 1 )
 20   CONTINUE
      IP( 0 ) = 0
      IP( NEL + 1 ) = NEL + 1

*  L1 Prepare two lists: Modified in line with question 12 prepare lists
*  in such a way that a sorted list will terminate quickly.
      LINK( IP( 0 ) ) = 1
      T = NEL + 1
      DO 1 P = 1, NEL - 1
         IF ( ARRAY( IP( P ) ) .LE. ARRAY( IP( P + 1 ) ) ) THEN
            LINK( IP( P ) ) = P + 1
         ELSE
            LINK( IP( T ) ) = -( P + 1 )
            T = P
         END IF
 1    CONTINUE
      LINK( IP( T ) ) = 0
      LINK( IP( NEL ) ) = 0
      LINK( IP( NEL + 1 ) ) = ABS( LINK( IP( NEL + 1 ) ) )

*  L2: Begin new pass.
*      During each pass P and Q traverse the lists being merged; S
*      usually points to the most recently processed record of the
*      current sublist, while T points to the end of the previous output
*      sublist).
 2    CONTINUE
      S = 0
      T = NEL + 1
      P = LINK( IP( S ) )
      Q = LINK( IP( T ) )
      IF ( Q .EQ. 0 ) THEN

*     Algorithm terminates.
         GO TO 99
      END IF

*  L3: Compare ARRAY(P):ARRAY(Q).
 3    CONTINUE
      IF ( ARRAY( IP( P ) ) .GT. ARRAY( IP( Q ) ) ) GO TO 6

*  L4: Advance P.
 4    CONTINUE
      LINK( IP( S ) ) = SIGN( P, LINK( IP( S ) ) )
      S = P
      P = LINK( IP( P ) )
      IF ( P .GT. 0 ) GO TO 3

*  L5: Complete the sublist.
 5    CONTINUE
      LINK( IP( S ) ) = Q
      S = T
 9    CONTINUE
         T = Q
         Q = LINK( IP( Q ) )
      IF ( Q .GT. 0 ) GO TO 9
      GO TO 8

*  L6: Advance Q.
 6    CONTINUE
      LINK( IP( S ) ) = SIGN( Q, LINK( IP( S ) ) )
      S = Q
      Q = LINK( IP( Q ) )
      IF ( Q .GT. 0 ) GO TO 3

*  L7: Complete the sublist.
 7    CONTINUE
      LINK( IP( S ) ) = P
      S = T
 10   CONTINUE
         T = P
         P = LINK( IP( P ) )
      IF ( P .GT. 0 ) GO TO 10

*  L8: End of pass?
*      At this point P and Q are <= 0, since both pointers have moved to
*      the end of their respective sublists.
 8    CONTINUE
      P = -P
      Q = -Q
      IF ( Q .EQ. 0 ) THEN
         LINK( IP( S ) ) = SIGN( P, LINK( IP( S ) ) )
         LINK( IP( T ) ) = SIGN( 0, LINK( IP( S ) ) )
         GO TO 2
      END IF
      GO TO 3

*  Exit here from L2:
 99   CONTINUE

*  The results from the previous run are a linked list of positions
*  starting at LINK(IP(0)). Unroll this into a list of ranks.
      Q = LINK( IP( 0 ) )
      DO I = 1, NEL
         P = LINK( IP( Q ) )
         LINK( IP( Q ) ) = I
         Q = P
      END DO

*  And permute these ranks into straight-forward indices and copy into
*  IP. 
      CALL PDA_IPERM( NEL, LINK( 1 ) )
      DO I = 1, NEL
         IP( I ) = LINK( I )
      END DO

*  Move the contents of ARRAY and IP down one element to give data back
*  to caller in straight-forward format.
      DO 21 I = 0, NEL - 1
         ARRAY( I ) = ARRAY( I + 1 )
         IP( I ) = IP( I + 1 )
 21   CONTINUE

      END
