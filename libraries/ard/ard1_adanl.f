      SUBROUTINE ARD1_ADANL( IGRP, NDIM, AWCS, DLBND, DUBND, IPEXPR, 
     :                       IPOPND, SZEXPR, SZOPND, INP, STATUS )
*+
*  Name:
*     ARD1_ADANL

*  Purpose:
*     Analyse an ARD description into operators, keywords and statement.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARD1_ADANL( IGRP, NDIM, AWCS, DLBND, DUBND, IPEXPR, 
*                      IPOPND, SZEXPR, SZOPND, INP, STATUS )

*  Description:
*     This routine analyses the supplied ARD description by identifying
*     and verifying the field symbols within the ARD description.
*     Numerical values representing the keyword and operator fields are
*     returned in an array (pointed to by IPEXPR) in the same order in
*     which they appear in the ARD description. No attempt is made to
*     verify that operators and operands occur in the correct order,
*     or to insert implicit .OR.s, etc. Any statement fields found in
*     the ARD description are used immediately to modify the
*     interpretation of the remaining keyword and operator fields.

*  Arguments:
*     IGRP = INTEGER (Given)
*        The identifier for the GRP group containing the text of the
*        complete ARD description.
*     NDIM = INTEGER (Given)
*        The number of dimensions in the mask supplied to ARD_WORK.
*     AWCS = INTEGER (Given)
*        A pointer to an AST FrameSet supplied by the application. This
*        should have a Base Frame with Domain PIXEL referring to pixel
*        coords within the pixel mask and another Frame with Domain 
*        ARDAPP referring to "Application co-ordinates" (i.e. default
*        user coords).
*     DLBND( * ) = DOUBLE PRECISION (Given)
*        The lower bounds of pixel coordinates.
*     DUBND( * ) = DOUBLE PRECISION (Given)
*        The upper bounds of pixel coordinates.
*     IPEXPR = INTEGER (Given and Returned)
*        A pointer to a one dimensional integer work array. On return,
*        the logical expression representing the ARD description is
*        defined by this array. Each value in the returned array
*        (starting at index 1) represents an instruction which can be
*        executed by the ARD expression evaluator routine (ARD1_EVAL)
*        Such instructions are stored in the returned array in the same
*        order in which they appear in the ARD description. Keyword
*        fields are represented by a "Load Keyword Region" (LKR)
*        instruction which causes the expression evaluator to load a
*        mask defined by the keyword. The parameters which describe
*        such keywords are stored in another array (pointed to by
*        IPOPND). The index within the IPOPND array at which the
*        keyword description starts is stored as an argument for the
*        LKR instruction. An "End Expression" instruction is inserted
*        at the end of the ARD description. The array is extended if
*        necessary.
*     IPOPND = INTEGER (Given and Returned)
*        A pointer to a one dimensional _DOUBLE work array. On return, the
*        array holds information about all the operands (i.e. keywords)
*        used within the logical expression representing the ARD
*        description. Each operand is defined by a variable length block 
*        of values (see ARD1_LKR prologue for details). Checks are made on 
*        the validity of the keyword argument lists.  The array is extended 
*        if necessary.
*     SZEXPR = INTEGER (Given and Returned)
*        The size of the array pointed to by IPEXPR. The array is
*        truncated on exit so that there is no un-used space at the
*        end.  
*     SZOPND = INTEGER (Given and Returned)
*        The size of the array pointed to by IPOPND. The array is
*        truncated on exit so that there is no un-used space at the
*        end.  
*     INP = INTEGER (Returned)
*        Returned .TRUE if any INPUT keywords were found in the ARD
*        description, and .FALSE. otherwise.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     27-APR-1994 (DSB):
*        Original version.
*     25-OCT-2000 (DSB):
*        Report an error if a blank ARD expression is supplied.
*     5-JUN-2001 (DSB):
*        Modified to use AST FrameSets insetad of coeff arrays.
*     18-JUL-2001 (DSB):
*        Modified for ARD version 2.0.
*     {enter_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL_ constans
      INCLUDE 'GRP_PAR'          ! GRP_ constants
      INCLUDE 'AST_PAR'          ! AST_ constants and functions
      INCLUDE 'ARD_CONST'        ! ARD_ private constants
      INCLUDE 'ARD_ERR'          ! ARD_ error constants

*  Global Constants:
      INCLUDE 'ARD_COM'          ! ARD common blocks
*        CMN_KWARG( ARD__NKEYW ) = INTEGER (Read)
*           The number of arguments required by each keyword.
*        CMN_STARG( ARD__NSTAT ) = INTEGER (Read)
*           The number of arguments required by each statement.

*  Arguments Given:
      INTEGER IGRP
      INTEGER NDIM
      INTEGER AWCS
      DOUBLE PRECISION DLBND( * )
      DOUBLE PRECISION DUBND( * )

*  Arguments Given and Returned:
      INTEGER IPEXPR
      INTEGER IPOPND
      INTEGER SZEXPR
      INTEGER SZOPND

*  Arguments Returned:
      LOGICAL INP

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL ARD1_INIT         ! Initialise ARD common blocks
      INTEGER CHR_LEN            ! Used length of a string

*  Local Variables:
      CHARACTER
     : ELEM*(GRP__SZNAM )        ! Current GRP element

      DOUBLE PRECISION           ! Extra WCS data
     : WCSDAT( ARD__MXDIM*( ARD__MXDIM + 1 ) )

      INTEGER
     : I,                        ! Index of next character 
     : IELEM,                    ! Index of next GRP element
     : IEXPR,                    ! Next free entry in expression array
     : IOPND,                    ! Next free entry in operands array
     : IWCS,                     ! Total FrameSet from pixel to user coords
     : L,                        ! Used length of current GRP element
     : MAP,                      ! AST Mapping from PIXEL to user coords
     : NARG,                     ! No. of arguments obtained so far
     : NKEYW,                    ! No. of keywords in ARD description
     : PNARG,                    ! Index at which to store no. of arg.s
     : SIZE,                     ! No. of elements in group
     : TYPE,                     ! Identifier for operator or operand
     : UWCS                      ! FrameSet supplied by user 
      
      LOGICAL
     : KEYW,                     ! Is current field a keyword?
     : MORE,                     ! More GRP elements to be processed?
     : NEEDIM,                   ! Is a DIMENSION statement needed?
     : NOARGS,                   ! No argument list required?
     : OPER,                     ! Is current field an operator?
     : STAT                      ! Is current field a statement?

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get the size of the group containing the supplied ARD description.
      CALL GRP_GRPSZ( IGRP, SIZE, STATUS )

*  Report an error if the group is empty.
      IF( SIZE .EQ. 0 .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = ARD__BLANK
         CALL ERR_REP( 'ARD1_ADANL_ERR0', 'Blank ARD expression '//
     :                 'supplied.', STATUS )
         GO TO 999
      END IF

*  Initialise the index of the next element to be obtained from the
*  group.
      IELEM = 1

*  Initialise the number of keywords found in the ARD expression so
*  far (excluding INPUT keywords).
      NKEYW = 0

*  Indicate that the "current element" has been exhausted. This will
*  cause an element to be obtained on the first pass through the
*  DO-WHILE loop below. I is the index of the next character to be
*  checked in the current element and L is the total length of the
*  current element.
      L = 0
      I = 1

*  Indicate that no field of any type has yet been identified.
      KEYW = .FALSE.
      OPER = .FALSE.
      STAT = .FALSE.

*  Initialise pointers to the next free entries in the arrays used to
*  hold the expression instructions, and operands.
      IEXPR = 1
      IOPND = 1

*  Set a flag to indicate if a DIMENSION statement is needed before any
*  keyword fields can be interpreted. This will be the case unless the
*  mask supplied to routine ARD_WORK is 2-dimensional (the default
*  case).
      NEEDIM = NDIM .NE. 2

*  Create a default user FrameSet in which application coords and user
*  coords are connected by a UnitMap.
      UWCS = AST__NULL
      CALL ARD1_COWCS( AST_GETI( AWCS, 'NAXES', STATUS ), AST__BAD, 
     :                 UWCS, STATUS )

*  Merge the UWCS and AWCS to get the Mapping from PIXEL to user coords.
      CALL ARD1_MERGE( UWCS, AWCS, DLBND, DUBND, MAP, IWCS, WCSDAT, 
     :                 STATUS )

*  Initialise a flag to show that no INPUT keywords have yet been found.
      INP = .FALSE.

*  Loop round until the entire ARD description has been processed.
      MORE = .TRUE.
      DO WHILE ( MORE .AND. STATUS .EQ. SAI__OK ) 

*  If all symbols have been read from the current GRP element, try to
*  obtain a new GRP element.
         IF( I .GT. L ) THEN

*  If no more elements remain to be read, leave the loop and report an
*  error if we are in the middle of assembling a keyword or statement
*  argument list.
            IF( IELEM .GT. SIZE ) THEN
               MORE = .FALSE.

               IF( ( STAT .OR. KEYW ) .AND. STATUS .EQ. SAI__OK ) THEN

*  Do not report an error if the keyword or statement does not need an
*  argument list and no argument list has been started.
                  IF( ( NOARGS.AND.NARG.GE.0 ) .OR. .NOT. NOARGS ) THEN
                     STATUS = ARD__ARGS
                     CALL MSG_SETC( 'DESC', ELEM )
                     CALL ERR_REP( 'ARD1_ADANL_ERR1', 'Missing or '//
     :                             'incomplete argument list at end '//
     :                             'of an ARD description; ''^DESC''.',
     :                             STATUS )
                     GO TO 999
                  END IF
      
               END IF
            
*  Otherwise, get the next element from the group containing the ARD
*  description.
            ELSE
               CALL GRP_GET( IGRP, IELEM, 1, ELEM, STATUS )      

*  Increment the element index.
               IELEM = IELEM + 1

*  Replace all non-printable ASCII codes with spaces (for instance,
*  each TAB is replaced by a single space).
               CALL CHR_CLEAN( ELEM )

*  Remove leading blanks.
               CALL CHR_LDBLK( ELEM )

*  Find the index of the last non-blank character in the element.
               L = CHR_LEN( ELEM )

*  Initialise the index of the next character to be checked in the
*  new element.
               I = 1

            END IF

*  Argument lists for keyword and statement fields can be split over
*  several GRP elements. If we are in the middle of processing a
*  keyword field, copy any remaining keyword arguments from the current
*  GRP element into the returned operand array.
         ELSE IF( KEYW ) THEN
            CALL ARD1_KEYW( TYPE, NEEDIM, NDIM, IWCS, WCSDAT, ELEM, L, 
     :                      UWCS, IPOPND, IOPND, PNARG, SZOPND, NARG, I, 
     :                      KEYW, STATUS )

*  If we are in the middle of processing a statement field, obtain any 
*  remaining arguments from the GRP element. When the argument list
*  is complete, make any modifications to the current transformations,
*  etc, specified by the statement.
         ELSE IF( STAT ) THEN
            CALL ARD1_STAT( TYPE, ELEM, L, NDIM, AWCS, DLBND, DUBND, 
     :                      NEEDIM, NARG, I, UWCS, MAP, STAT, IWCS, 
     :                      WCSDAT, STATUS )

*  If we are ready to start a new field...
         ELSE

*  Try to identify a field symbol at the start of the remainder of
*  the current element.
            CALL ARD1_FIELD( ELEM, L, I, KEYW, OPER, STAT, TYPE,
     :                       STATUS )

*  If an operator field was found...
            IF( OPER ) THEN

*  Store an identifier for the operator in the expression array.
               CALL ARD1_STORI( TYPE, SZEXPR, IEXPR, IPEXPR, STATUS )

*  If a keyword field was found...
            ELSE IF( KEYW ) THEN

*  Store an identifier for the "Load Keyword Region" (LKR) instruction
*  in the expression array.
               CALL ARD1_STORI( ARD__LKR, SZEXPR, IEXPR, IPEXPR,
     :                          STATUS )

*  Each LKR instruction is followed by a single argument which is the
*  index within the operand array at which the description of the
*  keyword region to be loaded starts.
               CALL ARD1_STORI( IOPND, SZEXPR, IEXPR, IPEXPR, STATUS )

*  Now insert the identifier for the current keyword into the operand
*  array. The argument list for the operand will be read from the
*  supplied GRP group and added to the operand array in succesive
*  passes through the DO-WHILE loop.
               CALL ARD1_STORD( DBLE( TYPE ), SZOPND, IOPND, IPOPND,
     :                          STATUS )

*  Now insert a value into the operand array which records the position
*  of this keyword within the ARD description (excluding INPUT
*  keywords).
               IF( TYPE .NE. ARD__INP ) THEN
                  NKEYW = NKEYW + 1
                  CALL ARD1_STORD( DBLE( NKEYW ), SZOPND, IOPND, IPOPND,
     :                             STATUS )

*  If this is an INPUT keyword, store a zero for the keyword position,
*  and set a flag to indicate that the ARD description contained at
*  least one INPUT keyword.
               ELSE
                  CALL ARD1_STORD( 0.0D0, SZOPND, IOPND, IPOPND, 
     :                             STATUS )
                  INP = .TRUE.
               END IF

*  Indicate that no argument list (i.e. an opening parenthesis) has yet
*  been found.
               NARG = -1

*  If the keyword does not have an argument list, set a flag indicating
*  that it is OK to end the ARD description with NARG=-1 (i.e. with no
*  argument list).
               NOARGS = CMN_KWARG( TYPE ) .EQ. 0

*  Save the index at which the number of arguments is stored so that
*  the stored value can be updated later when the total number of
*  arguments is known. Initialise the number of arguments associated
*  with the keyword to zero.
               PNARG = IOPND
               CALL ARD1_STORD( 0.0D0, SZOPND, IOPND, IPOPND, STATUS )

*  If a statement field was found...
            ELSE IF( STAT ) THEN

*  Indicate that no argument list has yet been found.
               NARG = -1

*  If the statement does not have an argument list, set a flag
*  indicating that it is OK to end the ARD description with NARG=-1
*  (i.e. with no argument list).
               NOARGS = CMN_STARG( TYPE ) .EQ. 0

            END IF

         END IF            

      END DO

*  Report an error and abort if a null ARD description was supplied.
      IF( IEXPR .EQ. 1 ) THEN
         STATUS = ARD__BADDM
         CALL ERR_REP( 'ARD1_ADANL_ERR2', 'Null ARD description '//
     :                 'supplied.', STATUS )
         GO TO 999
      END IF

*  Store an identifier for the "End Expression" instruction
*  in the expression array.
      CALL ARD1_STORI( ARD__END, SZEXPR, IEXPR, IPEXPR, STATUS )

*  Truncate the arrays so that there is no un-used space at the ends.
      SZEXPR = IEXPR - 1
      SZOPND = IOPND - 1
      CALL PSX_REALLOC( SZEXPR*VAL__NBI, IPEXPR, STATUS )
      CALL PSX_REALLOC( SZOPND*VAL__NBD, IPOPND, STATUS )

*  Jump to here if an error occurs.
 999  CONTINUE
      
*  End the AST context.
      CALL AST_END( STATUS )

      END
