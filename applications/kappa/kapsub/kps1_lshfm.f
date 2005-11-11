      SUBROUTINE KPS1_LSHFM( FRM, NPOS, NAX, ID, POS, IGRP, STATUS )

*+
*  Name:
*     KPS1_LSHFM

*  Purpose:
*     Format the selected positions to be displayed by LISTSHOW.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_LSHFM( FRM, NPOS, NAX, ID, POS, IGRP, STATUS )

*  Description:
*     This routine formats the supplied positions and identifiers and
*     stores the resulting strings in the supplied GRP group.

*  Arguments:
*     FRM = INTEGER (Given)
*        An AST Pointer to the Frame in which the positions are defined.
*     NPOS = INTEGER (Given)
*        The number of supplied positions.
*     NAX = INTEGER (Given)
*        The number of axes for the supplied positions.
*     ID( NPOS ) = INTEGER (Given)
*        The supplied position identifiers.
*     POS( NPOS, NAX ) = DOUBLE PRECISION (Given and Returned)
*        The supplied positions. These are normalised using AST_NORM on
*        return.
*     IGRP = INTEGER (Given)
*        A GRP identifier for the group to receive the formatted positions.
*     STATUS = INTEGER (Given)
*        Global status value.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     16-SEP-1998 (DSB):
*        Original version.
*     7-AUG-2003 (DSB):
*        Normalise the supplied positions.
*     11-NOV-2005 (DSB):
*        Allow up to 50 axes (this allows tables such as those produced by 
*        CUPID:CLUMPS which have more than NDF__MXDIM columns to be
*        displayed).
*     {enter_further_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE            

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'GRP_PAR'          ! GRP constants
      INCLUDE 'AST_PAR'          ! AST constants and function declarations

*  Arguments Given:
      INTEGER FRM
      INTEGER NPOS
      INTEGER NAX
      INTEGER ID( NPOS )
      INTEGER IGRP

*  Arguments Given and Returned:
      DOUBLE PRECISION POS( NPOS, NAX )

*  Status:
      INTEGER STATUS               ! Global status

*  External References:
      INTEGER CHR_LEN              ! Used length of a string

*  Local Constants:
      INTEGER NSP                  ! No. of spaces between fields
      PARAMETER( NSP = 3 ) 

      INTEGER MXDIM                ! Max number of axes
      PARAMETER( MXDIM = 50 ) 

*  Local Variables:
      CHARACTER ATTRIB*15          ! AST attribute name
      CHARACTER LINE*( GRP__SZNAM )! Buffer for text
      CHARACTER TEXT*40            ! AST attribute value
      DOUBLE PRECISION C( MXDIM )  ! Buffer for a single position
      INTEGER BLEN                 ! Length of each line
      INTEGER I                    ! Axis index
      INTEGER IAT                  ! No. of characters in a string
      INTEGER K                    ! Position index
      INTEGER MXWID( 0 : MXDIM )   ! Field widths
      INTEGER TAB( 0 : MXDIM + 1 ) ! Field starting positions
*.

*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Find the maximum field width on each axis.
*  ==========================================

*  Initialise the maximum field widths.
      DO I = 1, NAX
         MXWID( I ) = 0
      END DO

*  Loop round each position.
      DO K = 1, NPOS

*  Normalise the position.
         DO I = 1, NAX
            C( I ) = POS( K, I )
         END DO
         CALL AST_NORM( FRM, C, STATUS )         
         DO I = 1, NAX
            POS( K, I ) = C( I )
         END DO

*  Do each axis.
         DO I = 1, NAX

*  Find the used length of the formatted axis value.
           MXWID( I ) = MAX( MXWID( I ), CHR_LEN( 
     :                     AST_FORMAT( FRM, I, POS( K, I ), STATUS ) ) )

         END DO

      END DO

*  Make sure the field widths are wide enough to hold the axis symbols
*  and units.
      DO I = 1, NAX

         ATTRIB = 'Unit('
         IAT = 5
         CALL CHR_PUTI( I, ATTRIB, IAT )
         CALL CHR_APPND( ')', ATTRIB, IAT )
         TEXT = AST_GETC( FRM, ATTRIB( : IAT ), STATUS ) 
         CALL KPG1_PGESC( TEXT, STATUS )
         MXWID( I ) = MAX( MXWID( I ), CHR_LEN( TEXT ) )

         ATTRIB = 'Symbol('
         IAT = 7
         CALL CHR_PUTI( I, ATTRIB, IAT )
         CALL CHR_APPND( ')', ATTRIB, IAT )

         TEXT = AST_GETC( FRM, ATTRIB( : IAT ), STATUS ) 
         CALL KPG1_PGESC( TEXT, STATUS )
         MXWID( I ) = MAX( MXWID( I ), CHR_LEN( TEXT ) )

      END DO

*  Set the tab positions for each column. Zero is for identifiers. Allow
*  NSP spaces after each column.
      TAB( 0 ) = 1
      MXWID( 0 ) = 10

      DO I = 1, NAX + 1
         TAB( I ) = TAB( I - 1 ) + MXWID( I - 1 ) + NSP
      END DO

*  Store the full used length of each line (i.e. minus the trailing
*  spaces).
      BLEN = TAB( NAX + 1 ) - NSP

*  Create the header, putting each word in the middle of the corresponding 
*  field...
*  =======================================================================

*  First line: "Position" and axis symbols
      LINE = ' ' 
      IAT = ( TAB( 1 ) + TAB( 0 ) - NSP - 8 )/2
      LINE( IAT : ) = 'Position'

      DO I = 1, NAX
         ATTRIB = 'Symbol('
         IAT = 7
         CALL CHR_PUTI( I, ATTRIB, IAT )
         CALL CHR_APPND( ')', ATTRIB, IAT )
         TEXT = AST_GETC( FRM, ATTRIB( : IAT ), STATUS )
         CALL KPG1_PGESC( TEXT, STATUS )
         IAT = ( TAB( I + 1 ) + TAB( I ) - NSP - CHR_LEN( TEXT ) )/2
         LINE( IAT : ) = TEXT
      END DO

      CALL GRP_PUT( IGRP, 1, LINE( : BLEN ), 0, STATUS ) 

*  Second line: "identifier" and axis units (if any).
      LINE = ' ' 
      IAT = ( TAB( 1 ) + TAB( 0 ) - NSP - 10 )/2
      LINE( IAT : ) = 'identifier'

      DO I = 1, NAX
         ATTRIB = 'Unit('
         IAT = 5
         CALL CHR_PUTI( I, ATTRIB, IAT )
         CALL CHR_APPND( ')', ATTRIB, IAT )
         TEXT = AST_GETC( FRM, ATTRIB( : IAT ), STATUS )
         CALL KPG1_PGESC( TEXT, STATUS )
         IAT = ( TAB( I + 1 ) + TAB( I ) - NSP - CHR_LEN( TEXT ) )/2
         LINE( IAT : ) = TEXT
      END DO

      CALL GRP_PUT( IGRP, 1, LINE( : BLEN ), 0, STATUS ) 

*  Separator lines.
      DO I = 1, BLEN
         LINE( I : I ) = '-'
      END DO
      CALL GRP_PUT( IGRP, 1, LINE( : BLEN ), 0, STATUS ) 
      CALL GRP_PUT( IGRP, 1, ' ', 0, STATUS ) 

*  Format the identifiers and positions in columns
*  ===============================================

*  Loop round each position.
      DO K = 1, NPOS
         LINE = ' '

*  Put the position identifier into the buffer.
         IAT = TAB( 0 ) + 2
         LINE( IAT : ) = '#'
         CALL CHR_PUTI( ID( K ), LINE, IAT )
   
*  Format the results on each axis. Start each axis value at the tab
*  positions found above. 
         DO I = 1, NAX
            LINE( TAB( I ) : ) = AST_FORMAT( FRM, I, POS( K, I ), 
     :                                       STATUS )
         END DO

*  Store the buffer in the group.
         CALL GRP_PUT( IGRP, 1, LINE( : BLEN ), 0, STATUS ) 

      END DO

      END
