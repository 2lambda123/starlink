      SUBROUTINE CCD1_WRGRA( GRAPH, NEDGES, STATUS )
*+
*  Name:
*     CCD1_WRGRA

*  Purpose:
*     Writes out a description of a graph.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_WRGRA( GRAPH, NEDGES, STATUS )

*  Description:
*     This routine writes out a description of the graph stored in the
*     GRAPH array. The node numbers are held in elements 1 and 2 the
*     weights in position 3, original intercomparison index in position
*     4. The written description follows the format
*         Spanning graph connections:
*            Nodes N and M with weight X
*            .
*            .
*            .
*         Sum of weights: SUM

*  Arguments:
*     GRAPH( 4, NEDGES ) = INTEGER (Given)
*        The graph. The node numbers are held in elements 1 and 2 the
*        weights in position 3, original intercomparison index in
*        position 4. This graph should be complete (i.e. fully
*        connected) on entry. On exit the graph will be sorted into
*        decreasing weight order.
*     NEDGES = INTEGER (Given)
*        The number of edges in the graph.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - Uses the CCDPACK log file system.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     18-MAY-1993 (PDRAPER):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER NEDGES
      INTEGER GRAPH( 4, NEDGES )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I
      INTEGER SUM

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Report the connection and weights of the graph.
      CALL CCD1_MSG( ' ', '    Graph connections:', STATUS )
      SUM = 0
      DO 5 I = 1, NEDGES
         CALL MSG_SETI( 'S1', GRAPH( 1, I ) )
         CALL MSG_SETI( 'S2', GRAPH( 2, I ) )
         CALL MSG_SETI( 'S3', GRAPH( 3, I ) )
         CALL MSG_SETI( 'I', I )
         CALL CCD1_MSG( ' ',
     :'  Nodes ^S1) and ^S2) with weight ^S3', STATUS )
         SUM = SUM + GRAPH( 3, I )
 5    CONTINUE
      CALL MSG_SETI( 'SUM', SUM )
      CALL CCD1_MSG( ' ',
     :'    Sum of weights: ^SUM', STATUS )
      CALL CCD1_MSG( ' ', ' ', STATUS )
      END
* $Id$
