      BLOCK DATA TRN1_SYMDT






*+
*  Name:
*     TRN1_SYMDT

*  Purpose:
*     initialise symbol data table.

*  Language:
*     Starlink Fortran

*  Description:
*     The routine initialises the symbol data table which is held in
*     common blocks.  This table is used by the parsing routines when
*     compiling expressions which appear on the right hand sides of
*     transformation function definitions.  The symbol data table
*     contents and common blocks are defined in the include file
*     TRN_CMN_SYM.

*  Algorithm:
*     This is a BLOCK DATA routine which assigns the initial common
*     block values using DATA statements.

*  Authors:
*     R.F. Warren-Smith (DUVAD::RFWS)
*     {enter_new_authors_here}

*  History:
*     20-MAY-1988:  Original version (DUVAD::RFWS)
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-


*  Type Definitions:
      IMPLICIT NONE             ! No implicit typing


*  Global Constants:
      INCLUDE 'TRN_CONST_STM'   ! TRN_ private constants used by
                                ! routines which process standard
                                ! transformation modules


*  Global Variables:
      INCLUDE 'TRN_CMN_SYM'     ! Symbol data table common blocks


*  Local Constants:
*     <local constants defined by PARAMETER>


*  Local Variables:
      INTEGER I                 ! Loop counter for DATA statement
                                ! implied loop


*.



*   Initialise the symbol data table entries.

*   ...entries SYM_MNSYM..0:
      DATA ( SYM_NAME( I ), SYM_SIZE( I ), SYM_OPERL( I ),
     :       SYM_OPERR( I ), SYM_UNEXT( I ), SYM_UNOPR( I ),
     :       SYM_LPRI( I ), SYM_RPRI( I ), SYM_DPAR( I ),
     :       SYM_DSTK( I ), SYM_NARGS( I ), SYM_OPCOD( I ),
     :       I = SYM_MNSYM, 0 ) /
     :     '       ', 1, 0, 0, 0, 0, 10, 10,  0,  1, 0, TRN_OP_LDVAR,
     :     '       ', 1, 0, 0, 0, 0, 10, 10,  0,  1, 0, TRN_OP_LDCON /

*   ...entries 1..10:
      DATA ( SYM_NAME( I ), SYM_SIZE( I ), SYM_OPERL( I ),
     :       SYM_OPERR( I ), SYM_UNEXT( I ), SYM_UNOPR( I ),
     :       SYM_LPRI( I ), SYM_RPRI( I ), SYM_DPAR( I ),
     :       SYM_DSTK( I ), SYM_NARGS( I ), SYM_OPCOD( I ),
     :       I = 1, 10 ) /
     :     ')      ', 1, 1, 0, 0, 0,  2, 10, -1,  0, 0, TRN_OP_NULL,
     :     '(      ', 1, 0, 1, 1, 0, 10,  1,  1,  0, 0, TRN_OP_NULL,
     :     '-      ', 1, 1, 1, 0, 0,  4,  4,  0, -1, 0, TRN_OP_SUB,
     :     '+      ', 1, 1, 1, 0, 0,  4,  4,  0, -1, 0, TRN_OP_ADD,
     :     '**     ', 2, 1, 1, 0, 0,  9,  6,  0, -1, 0, TRN_OP_PWR,
     :     '*      ', 1, 1, 1, 0, 0,  5,  5,  0, -1, 0, TRN_OP_MULT,
     :     '/      ', 1, 1, 1, 0, 0,  5,  5,  0, -1, 0, TRN_OP_DIV,
     :     ',      ', 1, 1, 1, 1, 0,  2,  2,  0,  0, 0, TRN_OP_NULL,
     :     '-      ', 1, 0, 1, 0, 1,  8,  7,  0,  0, 0, TRN_OP_NEG,
     :     '+      ', 1, 0, 1, 0, 1,  8,  7,  0,  0, 0, TRN_OP_NULL /

*   ...entries 11..20:
      DATA ( SYM_NAME( I ), SYM_SIZE( I ), SYM_OPERL( I ),
     :       SYM_OPERR( I ), SYM_UNEXT( I ), SYM_UNOPR( I ),
     :       SYM_LPRI( I ), SYM_RPRI( I ), SYM_DPAR( I ),
     :       SYM_DSTK( I ), SYM_NARGS( I ), SYM_OPCOD( I ),
     :       I = 11, 20 ) /
     :     'SQRT(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_SQRT,
     :     'LOG(   ', 4, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_LOG,
     :     'LOG10( ', 6, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_LG10,
     :     'EXP(   ', 4, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_EXP,
     :     'SIN(   ', 4, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_SIN,
     :     'COS(   ', 4, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_COS,
     :     'TAN(   ', 4, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_TAN,
     :     'SIND(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_SIND,
     :     'COSD(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_COSD,
     :     'TAND(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_TAND /

*   ...entries 21..30:
      DATA ( SYM_NAME( I ), SYM_SIZE( I ), SYM_OPERL( I ),
     :       SYM_OPERR( I ), SYM_UNEXT( I ), SYM_UNOPR( I ),
     :       SYM_LPRI( I ), SYM_RPRI( I ), SYM_DPAR( I ),
     :       SYM_DSTK( I ), SYM_NARGS( I ), SYM_OPCOD( I ),
     :       I = 21, 30 ) /
     :     'ASIN(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_ASIN,
     :     'ACOS(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_ACOS,
     :     'ATAN(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_ATAN,
     :     'ASIND( ', 6, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_ASND,
     :     'ACOSD( ', 6, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_ACSD,
     :     'ATAND( ', 6, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_ATND,
     :     'SINH(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_SINH,
     :     'COSH(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_COSH,
     :     'TANH(  ', 5, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_TANH,
     :     'ABS(   ', 4, 0, 1, 1, 0, 10,  1,  1,  0, 1, TRN_OP_ABS /

*   ...entries 31..SYM_MXSYM:
      DATA ( SYM_NAME( I ), SYM_SIZE( I ), SYM_OPERL( I ),
     :       SYM_OPERR( I ), SYM_UNEXT( I ), SYM_UNOPR( I ),
     :       SYM_LPRI( I ), SYM_RPRI( I ), SYM_DPAR( I ),
     :       SYM_DSTK( I ), SYM_NARGS( I ), SYM_OPCOD( I ),
     :       I = 31, SYM_MXSYM ) /
     :     'NINT(  ', 5, 0, 1, 1, 0, 10,  1,  1,   0, 1, TRN_OP_NINT,
     :     'MIN(   ', 4, 0, 1, 1, 0, 10,  1,  1,  -1,-2, TRN_OP_MIN,
     :     'MAX(   ', 4, 0, 1, 1, 0, 10,  1,  1,  -1,-2, TRN_OP_MAX,
     :     'DIM(   ', 4, 0, 1, 1, 0, 10,  1,  1,  -1, 2, TRN_OP_DIM,
     :     'MOD(   ', 4, 0, 1, 1, 0, 10,  1,  1,  -1, 2, TRN_OP_MOD,
     :     'SIGN(  ', 5, 0, 1, 1, 0, 10,  1,  1,  -1, 2, TRN_OP_SIGN,
     :     'ATAN2( ', 6, 0, 1, 1, 0, 10,  1,  1,  -1, 2, TRN_OP_ATN2,
     :     'ATAN2D(', 7, 0, 1, 1, 0, 10,  1,  1,  -1, 2, TRN_OP_AT2D,
     :     '<BAD>  ', 5, 0, 0, 0, 0, 10, 10,  0,   1, 0, TRN_OP_LDBAD /


*   Initialise variables holding the table entry numbers for the
*   comma, LDVAR and LDCON symbols.
      DATA SYM_COMMA / 8 /
      DATA SYM_LDVAR / -1 /
      DATA SYM_LDCON / 0 /


*   End of routine.
      END
