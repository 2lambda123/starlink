      SUBROUTINE KPG1_NTHMR ( BAD, ARRAY, DIMS, N, STACK, STATUS )
*+
*  Name:
*     KPG_NTHMx
 
*  Purpose:
*     Returns the n smallest values in a REAL array.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_NTHMR( BAD, ARRAY, DIMS, N, STACK, STATUS )
 
*  Description:
*     This routine takes an REAL array and returns a stack
*     containing the n smallest values in that array.
 
*     Bad pixels are processed by the magic-value method.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        If true bad-pixel testing will be performed.  It should be true
*        if there may be bad pixels present.
*     ARRAY ( DIMS )  =  ? (Given)
*        Input array of data values.
*     DIMS  =  INTEGER  (Given)
*        Dimension of the input array.
*     N  =  INTEGER  (Given)
*        The number of values to be stored in stack, i.e. specifies
*        n in "n-th smallest value."
*     STACK ( N )  =  ? (Returned)
*        Ordered n smallest values in the input array. The first element
*        is the n-th smallest, the second is the (n-1)-th smallest and
*        so on until the n-th element is the minimum value.
*     STATUS  =  INTEGER (Given)
*        Global status value.
 
*  Algorithm:
*     Initialise stack entries to a very high value
*     For all valid array values
*        If current array value is less than top stack entry then
*           For all stack entries below first one
*              If current array value less than current stack entry then
*                 Set current-1 stack entry = current stack entry
*              Elseif at bottom of stack
*                 Set bottom stack entry to current array value
*              Else
*                 Set current-1 stack entry = current array value
*              Endif
*           Endfor
*        Endif
*     Endfor
 
*  Authors:
*     MJM: Mark McCaughrean (UoE)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     14-01-1986 : (MJM):
*        First implementation - more or less a straight copy of routine
*        of same name written by Rodney Warren-Smith for Starlink
*        package EDRS.
*     1986 Aug 12: (MJC):
*        Completed prologue and nearly conformed to Starlink standards.
*     1986 Sep 2 : (MJC):
*        Renamed parameters -> arguments section in prologue and added
*        bad-pixel handling.
*     1986 Dec 18: (MJC):
*        Made generic and renamed from NTHMIN to KPG_NTHM.
*     1990 Sep 27: (MJC):
*        Renamed to KPG1_NTHMx, and added bad-pixel-checking switch.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_new_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT  NONE              ! no implicit typing allowed
 
*  Global Constants:
      INCLUDE  'SAE_PAR'          ! SSE global definitions
      INCLUDE  'PRM_PAR'          ! Bad-pixel definitions
 
*  Arguments Given:
      INTEGER
     :  DIMS,
     :  N
 
      REAL
     :  ARRAY( DIMS )
 
      LOGICAL
     :  BAD
 
*  Arguments Returned:
      REAL
     :  STACK( N )
 
*  Status:
      INTEGER  STATUS
 
*  Local Variables:
      INTEGER
     :    LOCAT,                  ! Locator used in sort
     :    I, J                    ! Array counters
 
*.
 
*    Check status on entry - return if not o.k.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*    Start by initialising the stack entries to the maximum value.
 
      DO  I  =  1, N
         STACK( I )  =  VAL__MAXR
      END DO
 
*    Two parts to the routine depending on whether or not bad-pixel
*    checking is necessary.
 
      IF ( BAD ) THEN
 
*       Now loop through all members of the input array.
 
         DO  J  =  1, DIMS
 
*          Test if pixel is bad.
 
            IF ( ARRAY( J ) .NE. VAL__BADR ) THEN
 
*             Check if current array value is less than the top stack
*             value - continue with sort if it is.
 
               IF ( ARRAY( J ) .LT. STACK( 1 ) ) THEN
 
*                Current array value is less than the top of stack
*                value, and thus belongs in the stack. Run down the
*                stack checking where the value belongs.
 
                  DO  LOCAT  =  2, N
 
*                   Check array value against current stack entry.
 
                     IF ( ARRAY( J ) .LT. STACK( LOCAT ) ) THEN
 
*                      Array value belongs somewhere below the current
*                      stack entry - move the current stack entry up one
*                      to make space.
 
                        STACK( LOCAT - 1 )  =  STACK( LOCAT )
 
                     ELSE
 
*                      The array value is greater than the current
*                      stack entry - insert the array value one place
*                      above the current stack position.
 
                        STACK( LOCAT - 1 )  =  ARRAY( J )
                        GOTO 100
 
                     END IF
 
*                End of scan down stack.
 
                  END DO
 
*                We are at the bottom stack position - insert
*                array value here.
 
                  STACK( N )  =  ARRAY( J )
 
  100             CONTINUE
 
*             End of if-current-array-value-less-than-top-stack-entry
*             statement.
 
               END IF
 
*          End of bad pixel check.
 
            END IF
 
*       End of loop through all array values.
 
         END DO
 
      ELSE
 
*       Now loop through all members of the input array.
 
         DO  J  =  1, DIMS
 
*          Check if current array value is less than the top stack
*          value - continue with sort if it is.
 
            IF ( ARRAY( J ) .LT. STACK( 1 ) ) THEN
 
*             Current array value is less than the top of stack
*             value, and thus belongs in the stack. Run down the
*             stack checking where the value belongs.
 
               DO  LOCAT  =  2, N
 
*                Check array value against current stack entry.
 
                  IF ( ARRAY( J ) .LT. STACK( LOCAT ) ) THEN
 
*                   Array value belongs somewhere below the current
*                   stack entry - move the current stack entry up one
*                   to make space.
 
                     STACK( LOCAT - 1 )  =  STACK( LOCAT )
 
                  ELSE
 
*                   The array value is greater than the current
*                   stack entry - insert the array value one place
*                   above the current stack position.
 
                     STACK( LOCAT - 1 )  =  ARRAY( J )
                     GOTO 120
 
                  END IF
 
*             End of scan down stack.
 
               END DO
 
*             We are at the bottom stack position - insert
*             array value here.
 
               STACK( N )  =  ARRAY( J )
 
  120          CONTINUE
 
*          End of if-current-array-value-less-than-top-stack-entry
*          statement.
 
            END IF
 
*       End of loop through all array values.
 
         END DO
 
*    End of bad-pixel-processing check.
 
      END IF
 
      END
