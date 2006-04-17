      SUBROUTINE IRQ_SBADB( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD,
     :                     STATUS )
*+
*  Name:
*     IRQ_SBADB

*  Purpose:
*     Set pixels `bad' which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_SBADB( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     IRQ_COMP should be called before this routine to produce the
*     compiled quality expression identified by IDQ. The QUALITY
*     component of the NDF to which the quality expression refers (see
*     IRQ_COMP argument LOCS) is mapped as a one dimensional vector.
*     The supplied array VEC must correspond pixel-for-pixel with the
*     mapped QUALITY vector.  All pixels which hold a QUALITY
*     satisfying the quality expression are found. If HELD is true,
*     then the corresponding pixels in VEC are set to the `bad' value
*     (other pixels are left unaltered). If HELD is false, the
*     corresponding pixels in VEC are left as they are, but all the
*     other pixels in VEC are set to the `bad' value. ALLBAD and NOBAD
*     indicate if the output VEC values are either all bad or all good.
*
*     Note, if the QUALITY component of the NDF is mapped for WRITE or
*     UPDATE access on entry to this routine, an error is reported.

*  Arguments:
*     IDQ = INTEGER (Given)
*        An identifier for a compiled quality expression, produced by
*        routine IRQ_COMP. This identifier determines the NDF to which
*        the expression refers.
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set `bad'. Otherwise, those
*        pixels which don't hold such a quality are set `bad'.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC. An error is reported if
*        this is not the same as the total number of pixels in the NDF
*        determined by IDQ.
*     VEC( SIZE ) = BYTE (Given and Returned)
*        The data to be set `bad', depending on the corresponding
*        quality values stored in the NDF. It must be the same size as
*        the NDF, and must correspond pixel-for-pixel with the
*        vectorised NDF. Pixels which are not explicitly set `bad' by
*        this routine retain the values they had on entry.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with `bad'
*        values, and false if any returned pixel values are not `bad'.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with `bad'
*        values. False if any `bad' pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council.
*     Copyright (C) 2002, 2004 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     17-JAN-2002 (DSB):
*        Made generic.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Global Variables:
      INCLUDE 'IRQ_COM'          ! IRQ common blocks.
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
*        QCM_INDF( IRQ__MAXQ ) = INTEGER (Read)
*           Cloned NDF identifiers for the NDFs to which each quality
*           expression refers.
*        QCM_MSPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding bit masks.
*        QCM_MXSTK( IRQ__MAXQ ) = INTEGER (Read)
*           Maximum stack size needed to evaluate quality expression.
*        QCM_NMASK( IRQ__MAXQ ) = INTEGER (Read)
*           No. of quality masks needed to evaluate the quality
*           expression.
*        QCM_NOPC( IRQ__MAXQ ) = INTEGER (Read)
*           No. of operations needed to evaluate the quality expression.
*        QCM_OPPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding op. codes.
*        QCM_VALID( IRQ__MAXQ ) = LOGICAL (Read)
*           True if the corresponding compiled quality expression
*           identifier is valid (i.e. in use).

*  Arguments Given:
      INTEGER IDQ
      LOGICAL HELD
      INTEGER SIZE

*  Arguments Returned:
      BYTE VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NDFSIZ             ! Total number of pixels in NDF.
      INTEGER QPNT               ! Pointer to mapped QUALITY array.
      CHARACTER WLOC*(DAT__SZLOC)! Locator for temporary workspace.
      INTEGER WPNT               ! Pointer to mapped workspace.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the IRQ identifier is not valid, report an error.
      IF( IDQ .LT. 1 .OR. IDQ .GT. IRQ__MAXQ ) THEN
         STATUS = IRQ__INVID

      ELSE IF( .NOT. QCM_VALID( IDQ ) ) THEN
         STATUS = IRQ__INVID

      END IF

      IF( STATUS .EQ. IRQ__INVID ) THEN
         CALL ERR_REP( 'IRQ_SBADB_ERR1', 'IRQ_SBADB: Invalid '//
     :                 'IRQ identifier supplied', STATUS )
      END IF

*  Map the QUALITY component of the NDF.
      CALL NDF_MAP( QCM_INDF( IDQ ), 'QUALITY', '_UBYTE', 'READ', QPNT,
     :              NDFSIZ, STATUS )

*  Check that the supplied vector is the same size as the NDF.
      IF( NDFSIZ .NE. SIZE .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__INCOM
         CALL ERR_REP( 'IRQ_SBADB_ERR2', 'IRQ_SBADB: Supplied '//
     :                 'vector and NDF have different sizes.', STATUS )
      END IF

*  Obtain mapped workspace for the evaluation stack.
      CALL IRQ1_TEMP( '_LOGICAL', 1, QCM_MXSTK( IDQ )*SIZE, WLOC,
     :               STATUS )
      CALL DAT_MAPV( WLOC, '_LOGICAL', 'WRITE', WPNT, NDFSIZ, STATUS )

*  Create the pixel mask.
      IF( STATUS .EQ. SAI__OK ) THEN
         CALL IRQ1_SBAD1B( HELD, QCM_NMASK( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_MSPNT( IDQ ) ) ), 
     :                    QCM_NOPC( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_OPPNT( IDQ ) ) ), 
     :                    QCM_MXSTK( IDQ ),
     :                    SIZE, %VAL( CNF_PVAL( QPNT ) ), 
     :                    %VAL( CNF_PVAL( WPNT ) ), VEC,
     :                    ALLBAD, NOBAD, STATUS )
      END IF

*  Release the work space.
      CALL IRQ1_ANTMP( WLOC, STATUS )

*  Unmap the quality array.
      CALL NDF_UNMAP( QCM_INDF( IDQ ), 'QUALITY', STATUS )

      END
      SUBROUTINE IRQ_SBADUB( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD,
     :                     STATUS )
*+
*  Name:
*     IRQ_SBADUB

*  Purpose:
*     Set pixels `bad' which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_SBADUB( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     IRQ_COMP should be called before this routine to produce the
*     compiled quality expression identified by IDQ. The QUALITY
*     component of the NDF to which the quality expression refers (see
*     IRQ_COMP argument LOCS) is mapped as a one dimensional vector.
*     The supplied array VEC must correspond pixel-for-pixel with the
*     mapped QUALITY vector.  All pixels which hold a QUALITY
*     satisfying the quality expression are found. If HELD is true,
*     then the corresponding pixels in VEC are set to the `bad' value
*     (other pixels are left unaltered). If HELD is false, the
*     corresponding pixels in VEC are left as they are, but all the
*     other pixels in VEC are set to the `bad' value. ALLBAD and NOBAD
*     indicate if the output VEC values are either all bad or all good.
*
*     Note, if the QUALITY component of the NDF is mapped for WRITE or
*     UPDATE access on entry to this routine, an error is reported.

*  Arguments:
*     IDQ = INTEGER (Given)
*        An identifier for a compiled quality expression, produced by
*        routine IRQ_COMP. This identifier determines the NDF to which
*        the expression refers.
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set `bad'. Otherwise, those
*        pixels which don't hold such a quality are set `bad'.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC. An error is reported if
*        this is not the same as the total number of pixels in the NDF
*        determined by IDQ.
*     VEC( SIZE ) = BYTE (Given and Returned)
*        The data to be set `bad', depending on the corresponding
*        quality values stored in the NDF. It must be the same size as
*        the NDF, and must correspond pixel-for-pixel with the
*        vectorised NDF. Pixels which are not explicitly set `bad' by
*        this routine retain the values they had on entry.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with `bad'
*        values, and false if any returned pixel values are not `bad'.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with `bad'
*        values. False if any `bad' pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     17-JAN-2002 (DSB):
*        Made generic.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Global Variables:
      INCLUDE 'IRQ_COM'          ! IRQ common blocks.
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
*        QCM_INDF( IRQ__MAXQ ) = INTEGER (Read)
*           Cloned NDF identifiers for the NDFs to which each quality
*           expression refers.
*        QCM_MSPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding bit masks.
*        QCM_MXSTK( IRQ__MAXQ ) = INTEGER (Read)
*           Maximum stack size needed to evaluate quality expression.
*        QCM_NMASK( IRQ__MAXQ ) = INTEGER (Read)
*           No. of quality masks needed to evaluate the quality
*           expression.
*        QCM_NOPC( IRQ__MAXQ ) = INTEGER (Read)
*           No. of operations needed to evaluate the quality expression.
*        QCM_OPPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding op. codes.
*        QCM_VALID( IRQ__MAXQ ) = LOGICAL (Read)
*           True if the corresponding compiled quality expression
*           identifier is valid (i.e. in use).

*  Arguments Given:
      INTEGER IDQ
      LOGICAL HELD
      INTEGER SIZE

*  Arguments Returned:
      BYTE VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NDFSIZ             ! Total number of pixels in NDF.
      INTEGER QPNT               ! Pointer to mapped QUALITY array.
      CHARACTER WLOC*(DAT__SZLOC)! Locator for temporary workspace.
      INTEGER WPNT               ! Pointer to mapped workspace.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the IRQ identifier is not valid, report an error.
      IF( IDQ .LT. 1 .OR. IDQ .GT. IRQ__MAXQ ) THEN
         STATUS = IRQ__INVID

      ELSE IF( .NOT. QCM_VALID( IDQ ) ) THEN
         STATUS = IRQ__INVID

      END IF

      IF( STATUS .EQ. IRQ__INVID ) THEN
         CALL ERR_REP( 'IRQ_SBADUB_ERR1', 'IRQ_SBADUB: Invalid '//
     :                 'IRQ identifier supplied', STATUS )
      END IF

*  Map the QUALITY component of the NDF.
      CALL NDF_MAP( QCM_INDF( IDQ ), 'QUALITY', '_UBYTE', 'READ', QPNT,
     :              NDFSIZ, STATUS )

*  Check that the supplied vector is the same size as the NDF.
      IF( NDFSIZ .NE. SIZE .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__INCOM
         CALL ERR_REP( 'IRQ_SBADUB_ERR2', 'IRQ_SBADUB: Supplied '//
     :                 'vector and NDF have different sizes.', STATUS )
      END IF

*  Obtain mapped workspace for the evaluation stack.
      CALL IRQ1_TEMP( '_LOGICAL', 1, QCM_MXSTK( IDQ )*SIZE, WLOC,
     :               STATUS )
      CALL DAT_MAPV( WLOC, '_LOGICAL', 'WRITE', WPNT, NDFSIZ, STATUS )

*  Create the pixel mask.
      IF( STATUS .EQ. SAI__OK ) THEN
         CALL IRQ1_SBAD1UB( HELD, QCM_NMASK( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_MSPNT( IDQ ) ) ), 
     :                    QCM_NOPC( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_OPPNT( IDQ ) ) ), 
     :                    QCM_MXSTK( IDQ ),
     :                    SIZE, %VAL( CNF_PVAL( QPNT ) ), 
     :                    %VAL( CNF_PVAL( WPNT ) ), VEC,
     :                    ALLBAD, NOBAD, STATUS )
      END IF

*  Release the work space.
      CALL IRQ1_ANTMP( WLOC, STATUS )

*  Unmap the quality array.
      CALL NDF_UNMAP( QCM_INDF( IDQ ), 'QUALITY', STATUS )

      END
      SUBROUTINE IRQ_SBADD( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD,
     :                     STATUS )
*+
*  Name:
*     IRQ_SBADD

*  Purpose:
*     Set pixels `bad' which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_SBADD( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     IRQ_COMP should be called before this routine to produce the
*     compiled quality expression identified by IDQ. The QUALITY
*     component of the NDF to which the quality expression refers (see
*     IRQ_COMP argument LOCS) is mapped as a one dimensional vector.
*     The supplied array VEC must correspond pixel-for-pixel with the
*     mapped QUALITY vector.  All pixels which hold a QUALITY
*     satisfying the quality expression are found. If HELD is true,
*     then the corresponding pixels in VEC are set to the `bad' value
*     (other pixels are left unaltered). If HELD is false, the
*     corresponding pixels in VEC are left as they are, but all the
*     other pixels in VEC are set to the `bad' value. ALLBAD and NOBAD
*     indicate if the output VEC values are either all bad or all good.
*
*     Note, if the QUALITY component of the NDF is mapped for WRITE or
*     UPDATE access on entry to this routine, an error is reported.

*  Arguments:
*     IDQ = INTEGER (Given)
*        An identifier for a compiled quality expression, produced by
*        routine IRQ_COMP. This identifier determines the NDF to which
*        the expression refers.
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set `bad'. Otherwise, those
*        pixels which don't hold such a quality are set `bad'.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC. An error is reported if
*        this is not the same as the total number of pixels in the NDF
*        determined by IDQ.
*     VEC( SIZE ) = DOUBLE PRECISION (Given and Returned)
*        The data to be set `bad', depending on the corresponding
*        quality values stored in the NDF. It must be the same size as
*        the NDF, and must correspond pixel-for-pixel with the
*        vectorised NDF. Pixels which are not explicitly set `bad' by
*        this routine retain the values they had on entry.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with `bad'
*        values, and false if any returned pixel values are not `bad'.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with `bad'
*        values. False if any `bad' pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     17-JAN-2002 (DSB):
*        Made generic.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Global Variables:
      INCLUDE 'IRQ_COM'          ! IRQ common blocks.
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
*        QCM_INDF( IRQ__MAXQ ) = INTEGER (Read)
*           Cloned NDF identifiers for the NDFs to which each quality
*           expression refers.
*        QCM_MSPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding bit masks.
*        QCM_MXSTK( IRQ__MAXQ ) = INTEGER (Read)
*           Maximum stack size needed to evaluate quality expression.
*        QCM_NMASK( IRQ__MAXQ ) = INTEGER (Read)
*           No. of quality masks needed to evaluate the quality
*           expression.
*        QCM_NOPC( IRQ__MAXQ ) = INTEGER (Read)
*           No. of operations needed to evaluate the quality expression.
*        QCM_OPPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding op. codes.
*        QCM_VALID( IRQ__MAXQ ) = LOGICAL (Read)
*           True if the corresponding compiled quality expression
*           identifier is valid (i.e. in use).

*  Arguments Given:
      INTEGER IDQ
      LOGICAL HELD
      INTEGER SIZE

*  Arguments Returned:
      DOUBLE PRECISION VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NDFSIZ             ! Total number of pixels in NDF.
      INTEGER QPNT               ! Pointer to mapped QUALITY array.
      CHARACTER WLOC*(DAT__SZLOC)! Locator for temporary workspace.
      INTEGER WPNT               ! Pointer to mapped workspace.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the IRQ identifier is not valid, report an error.
      IF( IDQ .LT. 1 .OR. IDQ .GT. IRQ__MAXQ ) THEN
         STATUS = IRQ__INVID

      ELSE IF( .NOT. QCM_VALID( IDQ ) ) THEN
         STATUS = IRQ__INVID

      END IF

      IF( STATUS .EQ. IRQ__INVID ) THEN
         CALL ERR_REP( 'IRQ_SBADD_ERR1', 'IRQ_SBADD: Invalid '//
     :                 'IRQ identifier supplied', STATUS )
      END IF

*  Map the QUALITY component of the NDF.
      CALL NDF_MAP( QCM_INDF( IDQ ), 'QUALITY', '_UBYTE', 'READ', QPNT,
     :              NDFSIZ, STATUS )

*  Check that the supplied vector is the same size as the NDF.
      IF( NDFSIZ .NE. SIZE .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__INCOM
         CALL ERR_REP( 'IRQ_SBADD_ERR2', 'IRQ_SBADD: Supplied '//
     :                 'vector and NDF have different sizes.', STATUS )
      END IF

*  Obtain mapped workspace for the evaluation stack.
      CALL IRQ1_TEMP( '_LOGICAL', 1, QCM_MXSTK( IDQ )*SIZE, WLOC,
     :               STATUS )
      CALL DAT_MAPV( WLOC, '_LOGICAL', 'WRITE', WPNT, NDFSIZ, STATUS )

*  Create the pixel mask.
      IF( STATUS .EQ. SAI__OK ) THEN
         CALL IRQ1_SBAD1D( HELD, QCM_NMASK( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_MSPNT( IDQ ) ) ), 
     :                    QCM_NOPC( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_OPPNT( IDQ ) ) ), 
     :                    QCM_MXSTK( IDQ ),
     :                    SIZE, %VAL( CNF_PVAL( QPNT ) ), 
     :                    %VAL( CNF_PVAL( WPNT ) ), VEC,
     :                    ALLBAD, NOBAD, STATUS )
      END IF

*  Release the work space.
      CALL IRQ1_ANTMP( WLOC, STATUS )

*  Unmap the quality array.
      CALL NDF_UNMAP( QCM_INDF( IDQ ), 'QUALITY', STATUS )

      END
      SUBROUTINE IRQ_SBADI( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD,
     :                     STATUS )
*+
*  Name:
*     IRQ_SBADI

*  Purpose:
*     Set pixels `bad' which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_SBADI( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     IRQ_COMP should be called before this routine to produce the
*     compiled quality expression identified by IDQ. The QUALITY
*     component of the NDF to which the quality expression refers (see
*     IRQ_COMP argument LOCS) is mapped as a one dimensional vector.
*     The supplied array VEC must correspond pixel-for-pixel with the
*     mapped QUALITY vector.  All pixels which hold a QUALITY
*     satisfying the quality expression are found. If HELD is true,
*     then the corresponding pixels in VEC are set to the `bad' value
*     (other pixels are left unaltered). If HELD is false, the
*     corresponding pixels in VEC are left as they are, but all the
*     other pixels in VEC are set to the `bad' value. ALLBAD and NOBAD
*     indicate if the output VEC values are either all bad or all good.
*
*     Note, if the QUALITY component of the NDF is mapped for WRITE or
*     UPDATE access on entry to this routine, an error is reported.

*  Arguments:
*     IDQ = INTEGER (Given)
*        An identifier for a compiled quality expression, produced by
*        routine IRQ_COMP. This identifier determines the NDF to which
*        the expression refers.
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set `bad'. Otherwise, those
*        pixels which don't hold such a quality are set `bad'.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC. An error is reported if
*        this is not the same as the total number of pixels in the NDF
*        determined by IDQ.
*     VEC( SIZE ) = INTEGER (Given and Returned)
*        The data to be set `bad', depending on the corresponding
*        quality values stored in the NDF. It must be the same size as
*        the NDF, and must correspond pixel-for-pixel with the
*        vectorised NDF. Pixels which are not explicitly set `bad' by
*        this routine retain the values they had on entry.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with `bad'
*        values, and false if any returned pixel values are not `bad'.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with `bad'
*        values. False if any `bad' pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     17-JAN-2002 (DSB):
*        Made generic.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Global Variables:
      INCLUDE 'IRQ_COM'          ! IRQ common blocks.
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
*        QCM_INDF( IRQ__MAXQ ) = INTEGER (Read)
*           Cloned NDF identifiers for the NDFs to which each quality
*           expression refers.
*        QCM_MSPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding bit masks.
*        QCM_MXSTK( IRQ__MAXQ ) = INTEGER (Read)
*           Maximum stack size needed to evaluate quality expression.
*        QCM_NMASK( IRQ__MAXQ ) = INTEGER (Read)
*           No. of quality masks needed to evaluate the quality
*           expression.
*        QCM_NOPC( IRQ__MAXQ ) = INTEGER (Read)
*           No. of operations needed to evaluate the quality expression.
*        QCM_OPPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding op. codes.
*        QCM_VALID( IRQ__MAXQ ) = LOGICAL (Read)
*           True if the corresponding compiled quality expression
*           identifier is valid (i.e. in use).

*  Arguments Given:
      INTEGER IDQ
      LOGICAL HELD
      INTEGER SIZE

*  Arguments Returned:
      INTEGER VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NDFSIZ             ! Total number of pixels in NDF.
      INTEGER QPNT               ! Pointer to mapped QUALITY array.
      CHARACTER WLOC*(DAT__SZLOC)! Locator for temporary workspace.
      INTEGER WPNT               ! Pointer to mapped workspace.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the IRQ identifier is not valid, report an error.
      IF( IDQ .LT. 1 .OR. IDQ .GT. IRQ__MAXQ ) THEN
         STATUS = IRQ__INVID

      ELSE IF( .NOT. QCM_VALID( IDQ ) ) THEN
         STATUS = IRQ__INVID

      END IF

      IF( STATUS .EQ. IRQ__INVID ) THEN
         CALL ERR_REP( 'IRQ_SBADI_ERR1', 'IRQ_SBADI: Invalid '//
     :                 'IRQ identifier supplied', STATUS )
      END IF

*  Map the QUALITY component of the NDF.
      CALL NDF_MAP( QCM_INDF( IDQ ), 'QUALITY', '_UBYTE', 'READ', QPNT,
     :              NDFSIZ, STATUS )

*  Check that the supplied vector is the same size as the NDF.
      IF( NDFSIZ .NE. SIZE .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__INCOM
         CALL ERR_REP( 'IRQ_SBADI_ERR2', 'IRQ_SBADI: Supplied '//
     :                 'vector and NDF have different sizes.', STATUS )
      END IF

*  Obtain mapped workspace for the evaluation stack.
      CALL IRQ1_TEMP( '_LOGICAL', 1, QCM_MXSTK( IDQ )*SIZE, WLOC,
     :               STATUS )
      CALL DAT_MAPV( WLOC, '_LOGICAL', 'WRITE', WPNT, NDFSIZ, STATUS )

*  Create the pixel mask.
      IF( STATUS .EQ. SAI__OK ) THEN
         CALL IRQ1_SBAD1I( HELD, QCM_NMASK( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_MSPNT( IDQ ) ) ), 
     :                    QCM_NOPC( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_OPPNT( IDQ ) ) ), 
     :                    QCM_MXSTK( IDQ ),
     :                    SIZE, %VAL( CNF_PVAL( QPNT ) ), 
     :                    %VAL( CNF_PVAL( WPNT ) ), VEC,
     :                    ALLBAD, NOBAD, STATUS )
      END IF

*  Release the work space.
      CALL IRQ1_ANTMP( WLOC, STATUS )

*  Unmap the quality array.
      CALL NDF_UNMAP( QCM_INDF( IDQ ), 'QUALITY', STATUS )

      END
      SUBROUTINE IRQ_SBADR( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD,
     :                     STATUS )
*+
*  Name:
*     IRQ_SBADR

*  Purpose:
*     Set pixels `bad' which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_SBADR( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     IRQ_COMP should be called before this routine to produce the
*     compiled quality expression identified by IDQ. The QUALITY
*     component of the NDF to which the quality expression refers (see
*     IRQ_COMP argument LOCS) is mapped as a one dimensional vector.
*     The supplied array VEC must correspond pixel-for-pixel with the
*     mapped QUALITY vector.  All pixels which hold a QUALITY
*     satisfying the quality expression are found. If HELD is true,
*     then the corresponding pixels in VEC are set to the `bad' value
*     (other pixels are left unaltered). If HELD is false, the
*     corresponding pixels in VEC are left as they are, but all the
*     other pixels in VEC are set to the `bad' value. ALLBAD and NOBAD
*     indicate if the output VEC values are either all bad or all good.
*
*     Note, if the QUALITY component of the NDF is mapped for WRITE or
*     UPDATE access on entry to this routine, an error is reported.

*  Arguments:
*     IDQ = INTEGER (Given)
*        An identifier for a compiled quality expression, produced by
*        routine IRQ_COMP. This identifier determines the NDF to which
*        the expression refers.
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set `bad'. Otherwise, those
*        pixels which don't hold such a quality are set `bad'.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC. An error is reported if
*        this is not the same as the total number of pixels in the NDF
*        determined by IDQ.
*     VEC( SIZE ) = REAL (Given and Returned)
*        The data to be set `bad', depending on the corresponding
*        quality values stored in the NDF. It must be the same size as
*        the NDF, and must correspond pixel-for-pixel with the
*        vectorised NDF. Pixels which are not explicitly set `bad' by
*        this routine retain the values they had on entry.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with `bad'
*        values, and false if any returned pixel values are not `bad'.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with `bad'
*        values. False if any `bad' pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     17-JAN-2002 (DSB):
*        Made generic.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Global Variables:
      INCLUDE 'IRQ_COM'          ! IRQ common blocks.
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
*        QCM_INDF( IRQ__MAXQ ) = INTEGER (Read)
*           Cloned NDF identifiers for the NDFs to which each quality
*           expression refers.
*        QCM_MSPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding bit masks.
*        QCM_MXSTK( IRQ__MAXQ ) = INTEGER (Read)
*           Maximum stack size needed to evaluate quality expression.
*        QCM_NMASK( IRQ__MAXQ ) = INTEGER (Read)
*           No. of quality masks needed to evaluate the quality
*           expression.
*        QCM_NOPC( IRQ__MAXQ ) = INTEGER (Read)
*           No. of operations needed to evaluate the quality expression.
*        QCM_OPPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding op. codes.
*        QCM_VALID( IRQ__MAXQ ) = LOGICAL (Read)
*           True if the corresponding compiled quality expression
*           identifier is valid (i.e. in use).

*  Arguments Given:
      INTEGER IDQ
      LOGICAL HELD
      INTEGER SIZE

*  Arguments Returned:
      REAL VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NDFSIZ             ! Total number of pixels in NDF.
      INTEGER QPNT               ! Pointer to mapped QUALITY array.
      CHARACTER WLOC*(DAT__SZLOC)! Locator for temporary workspace.
      INTEGER WPNT               ! Pointer to mapped workspace.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the IRQ identifier is not valid, report an error.
      IF( IDQ .LT. 1 .OR. IDQ .GT. IRQ__MAXQ ) THEN
         STATUS = IRQ__INVID

      ELSE IF( .NOT. QCM_VALID( IDQ ) ) THEN
         STATUS = IRQ__INVID

      END IF

      IF( STATUS .EQ. IRQ__INVID ) THEN
         CALL ERR_REP( 'IRQ_SBADR_ERR1', 'IRQ_SBADR: Invalid '//
     :                 'IRQ identifier supplied', STATUS )
      END IF

*  Map the QUALITY component of the NDF.
      CALL NDF_MAP( QCM_INDF( IDQ ), 'QUALITY', '_UBYTE', 'READ', QPNT,
     :              NDFSIZ, STATUS )

*  Check that the supplied vector is the same size as the NDF.
      IF( NDFSIZ .NE. SIZE .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__INCOM
         CALL ERR_REP( 'IRQ_SBADR_ERR2', 'IRQ_SBADR: Supplied '//
     :                 'vector and NDF have different sizes.', STATUS )
      END IF

*  Obtain mapped workspace for the evaluation stack.
      CALL IRQ1_TEMP( '_LOGICAL', 1, QCM_MXSTK( IDQ )*SIZE, WLOC,
     :               STATUS )
      CALL DAT_MAPV( WLOC, '_LOGICAL', 'WRITE', WPNT, NDFSIZ, STATUS )

*  Create the pixel mask.
      IF( STATUS .EQ. SAI__OK ) THEN
         CALL IRQ1_SBAD1R( HELD, QCM_NMASK( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_MSPNT( IDQ ) ) ), 
     :                    QCM_NOPC( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_OPPNT( IDQ ) ) ), 
     :                    QCM_MXSTK( IDQ ),
     :                    SIZE, %VAL( CNF_PVAL( QPNT ) ), 
     :                    %VAL( CNF_PVAL( WPNT ) ), VEC,
     :                    ALLBAD, NOBAD, STATUS )
      END IF

*  Release the work space.
      CALL IRQ1_ANTMP( WLOC, STATUS )

*  Unmap the quality array.
      CALL NDF_UNMAP( QCM_INDF( IDQ ), 'QUALITY', STATUS )

      END
      SUBROUTINE IRQ_SBADW( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD,
     :                     STATUS )
*+
*  Name:
*     IRQ_SBADW

*  Purpose:
*     Set pixels `bad' which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_SBADW( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     IRQ_COMP should be called before this routine to produce the
*     compiled quality expression identified by IDQ. The QUALITY
*     component of the NDF to which the quality expression refers (see
*     IRQ_COMP argument LOCS) is mapped as a one dimensional vector.
*     The supplied array VEC must correspond pixel-for-pixel with the
*     mapped QUALITY vector.  All pixels which hold a QUALITY
*     satisfying the quality expression are found. If HELD is true,
*     then the corresponding pixels in VEC are set to the `bad' value
*     (other pixels are left unaltered). If HELD is false, the
*     corresponding pixels in VEC are left as they are, but all the
*     other pixels in VEC are set to the `bad' value. ALLBAD and NOBAD
*     indicate if the output VEC values are either all bad or all good.
*
*     Note, if the QUALITY component of the NDF is mapped for WRITE or
*     UPDATE access on entry to this routine, an error is reported.

*  Arguments:
*     IDQ = INTEGER (Given)
*        An identifier for a compiled quality expression, produced by
*        routine IRQ_COMP. This identifier determines the NDF to which
*        the expression refers.
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set `bad'. Otherwise, those
*        pixels which don't hold such a quality are set `bad'.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC. An error is reported if
*        this is not the same as the total number of pixels in the NDF
*        determined by IDQ.
*     VEC( SIZE ) = INTEGER*2 (Given and Returned)
*        The data to be set `bad', depending on the corresponding
*        quality values stored in the NDF. It must be the same size as
*        the NDF, and must correspond pixel-for-pixel with the
*        vectorised NDF. Pixels which are not explicitly set `bad' by
*        this routine retain the values they had on entry.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with `bad'
*        values, and false if any returned pixel values are not `bad'.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with `bad'
*        values. False if any `bad' pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     17-JAN-2002 (DSB):
*        Made generic.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Global Variables:
      INCLUDE 'IRQ_COM'          ! IRQ common blocks.
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
*        QCM_INDF( IRQ__MAXQ ) = INTEGER (Read)
*           Cloned NDF identifiers for the NDFs to which each quality
*           expression refers.
*        QCM_MSPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding bit masks.
*        QCM_MXSTK( IRQ__MAXQ ) = INTEGER (Read)
*           Maximum stack size needed to evaluate quality expression.
*        QCM_NMASK( IRQ__MAXQ ) = INTEGER (Read)
*           No. of quality masks needed to evaluate the quality
*           expression.
*        QCM_NOPC( IRQ__MAXQ ) = INTEGER (Read)
*           No. of operations needed to evaluate the quality expression.
*        QCM_OPPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding op. codes.
*        QCM_VALID( IRQ__MAXQ ) = LOGICAL (Read)
*           True if the corresponding compiled quality expression
*           identifier is valid (i.e. in use).

*  Arguments Given:
      INTEGER IDQ
      LOGICAL HELD
      INTEGER SIZE

*  Arguments Returned:
      INTEGER*2 VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NDFSIZ             ! Total number of pixels in NDF.
      INTEGER QPNT               ! Pointer to mapped QUALITY array.
      CHARACTER WLOC*(DAT__SZLOC)! Locator for temporary workspace.
      INTEGER WPNT               ! Pointer to mapped workspace.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the IRQ identifier is not valid, report an error.
      IF( IDQ .LT. 1 .OR. IDQ .GT. IRQ__MAXQ ) THEN
         STATUS = IRQ__INVID

      ELSE IF( .NOT. QCM_VALID( IDQ ) ) THEN
         STATUS = IRQ__INVID

      END IF

      IF( STATUS .EQ. IRQ__INVID ) THEN
         CALL ERR_REP( 'IRQ_SBADW_ERR1', 'IRQ_SBADW: Invalid '//
     :                 'IRQ identifier supplied', STATUS )
      END IF

*  Map the QUALITY component of the NDF.
      CALL NDF_MAP( QCM_INDF( IDQ ), 'QUALITY', '_UBYTE', 'READ', QPNT,
     :              NDFSIZ, STATUS )

*  Check that the supplied vector is the same size as the NDF.
      IF( NDFSIZ .NE. SIZE .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__INCOM
         CALL ERR_REP( 'IRQ_SBADW_ERR2', 'IRQ_SBADW: Supplied '//
     :                 'vector and NDF have different sizes.', STATUS )
      END IF

*  Obtain mapped workspace for the evaluation stack.
      CALL IRQ1_TEMP( '_LOGICAL', 1, QCM_MXSTK( IDQ )*SIZE, WLOC,
     :               STATUS )
      CALL DAT_MAPV( WLOC, '_LOGICAL', 'WRITE', WPNT, NDFSIZ, STATUS )

*  Create the pixel mask.
      IF( STATUS .EQ. SAI__OK ) THEN
         CALL IRQ1_SBAD1W( HELD, QCM_NMASK( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_MSPNT( IDQ ) ) ), 
     :                    QCM_NOPC( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_OPPNT( IDQ ) ) ), 
     :                    QCM_MXSTK( IDQ ),
     :                    SIZE, %VAL( CNF_PVAL( QPNT ) ), 
     :                    %VAL( CNF_PVAL( WPNT ) ), VEC,
     :                    ALLBAD, NOBAD, STATUS )
      END IF

*  Release the work space.
      CALL IRQ1_ANTMP( WLOC, STATUS )

*  Unmap the quality array.
      CALL NDF_UNMAP( QCM_INDF( IDQ ), 'QUALITY', STATUS )

      END
      SUBROUTINE IRQ_SBADUW( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD,
     :                     STATUS )
*+
*  Name:
*     IRQ_SBADUW

*  Purpose:
*     Set pixels `bad' which satisfy a given quality expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_SBADUW( IDQ, HELD, SIZE, VEC, ALLBAD, NOBAD, STATUS )

*  Description:
*     IRQ_COMP should be called before this routine to produce the
*     compiled quality expression identified by IDQ. The QUALITY
*     component of the NDF to which the quality expression refers (see
*     IRQ_COMP argument LOCS) is mapped as a one dimensional vector.
*     The supplied array VEC must correspond pixel-for-pixel with the
*     mapped QUALITY vector.  All pixels which hold a QUALITY
*     satisfying the quality expression are found. If HELD is true,
*     then the corresponding pixels in VEC are set to the `bad' value
*     (other pixels are left unaltered). If HELD is false, the
*     corresponding pixels in VEC are left as they are, but all the
*     other pixels in VEC are set to the `bad' value. ALLBAD and NOBAD
*     indicate if the output VEC values are either all bad or all good.
*
*     Note, if the QUALITY component of the NDF is mapped for WRITE or
*     UPDATE access on entry to this routine, an error is reported.

*  Arguments:
*     IDQ = INTEGER (Given)
*        An identifier for a compiled quality expression, produced by
*        routine IRQ_COMP. This identifier determines the NDF to which
*        the expression refers.
*     HELD = LOGICAL (Given)
*        If true then those VEC pixels which hold a quality satisfying
*        the supplied quality expression are set `bad'. Otherwise, those
*        pixels which don't hold such a quality are set `bad'.
*     SIZE = INTEGER (Given)
*        The total number of pixels in VEC. An error is reported if
*        this is not the same as the total number of pixels in the NDF
*        determined by IDQ.
*     VEC( SIZE ) = INTEGER*2 (Given and Returned)
*        The data to be set `bad', depending on the corresponding
*        quality values stored in the NDF. It must be the same size as
*        the NDF, and must correspond pixel-for-pixel with the
*        vectorised NDF. Pixels which are not explicitly set `bad' by
*        this routine retain the values they had on entry.
*     ALLBAD = LOGICAL (Returned)
*        Returned true if all pixels in VEC are returned with `bad'
*        values, and false if any returned pixel values are not `bad'.
*     NOBAD = LOGICAL (Returned)
*        Returned true if no pixels in VEC are returned with `bad'
*        values. False if any `bad' pixel values are returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     17-JAN-2002 (DSB):
*        Made generic.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Global Variables:
      INCLUDE 'IRQ_COM'          ! IRQ common blocks.
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
*        QCM_INDF( IRQ__MAXQ ) = INTEGER (Read)
*           Cloned NDF identifiers for the NDFs to which each quality
*           expression refers.
*        QCM_MSPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding bit masks.
*        QCM_MXSTK( IRQ__MAXQ ) = INTEGER (Read)
*           Maximum stack size needed to evaluate quality expression.
*        QCM_NMASK( IRQ__MAXQ ) = INTEGER (Read)
*           No. of quality masks needed to evaluate the quality
*           expression.
*        QCM_NOPC( IRQ__MAXQ ) = INTEGER (Read)
*           No. of operations needed to evaluate the quality expression.
*        QCM_OPPNT( IRQ__MAXQ ) = INTEGER (Read)
*           Pointer to mapped array holding op. codes.
*        QCM_VALID( IRQ__MAXQ ) = LOGICAL (Read)
*           True if the corresponding compiled quality expression
*           identifier is valid (i.e. in use).

*  Arguments Given:
      INTEGER IDQ
      LOGICAL HELD
      INTEGER SIZE

*  Arguments Returned:
      INTEGER*2 VEC( SIZE )
      LOGICAL ALLBAD
      LOGICAL NOBAD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NDFSIZ             ! Total number of pixels in NDF.
      INTEGER QPNT               ! Pointer to mapped QUALITY array.
      CHARACTER WLOC*(DAT__SZLOC)! Locator for temporary workspace.
      INTEGER WPNT               ! Pointer to mapped workspace.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the IRQ identifier is not valid, report an error.
      IF( IDQ .LT. 1 .OR. IDQ .GT. IRQ__MAXQ ) THEN
         STATUS = IRQ__INVID

      ELSE IF( .NOT. QCM_VALID( IDQ ) ) THEN
         STATUS = IRQ__INVID

      END IF

      IF( STATUS .EQ. IRQ__INVID ) THEN
         CALL ERR_REP( 'IRQ_SBADUW_ERR1', 'IRQ_SBADUW: Invalid '//
     :                 'IRQ identifier supplied', STATUS )
      END IF

*  Map the QUALITY component of the NDF.
      CALL NDF_MAP( QCM_INDF( IDQ ), 'QUALITY', '_UBYTE', 'READ', QPNT,
     :              NDFSIZ, STATUS )

*  Check that the supplied vector is the same size as the NDF.
      IF( NDFSIZ .NE. SIZE .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__INCOM
         CALL ERR_REP( 'IRQ_SBADUW_ERR2', 'IRQ_SBADUW: Supplied '//
     :                 'vector and NDF have different sizes.', STATUS )
      END IF

*  Obtain mapped workspace for the evaluation stack.
      CALL IRQ1_TEMP( '_LOGICAL', 1, QCM_MXSTK( IDQ )*SIZE, WLOC,
     :               STATUS )
      CALL DAT_MAPV( WLOC, '_LOGICAL', 'WRITE', WPNT, NDFSIZ, STATUS )

*  Create the pixel mask.
      IF( STATUS .EQ. SAI__OK ) THEN
         CALL IRQ1_SBAD1UW( HELD, QCM_NMASK( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_MSPNT( IDQ ) ) ), 
     :                    QCM_NOPC( IDQ ),
     :                    %VAL( CNF_PVAL( QCM_OPPNT( IDQ ) ) ), 
     :                    QCM_MXSTK( IDQ ),
     :                    SIZE, %VAL( CNF_PVAL( QPNT ) ), 
     :                    %VAL( CNF_PVAL( WPNT ) ), VEC,
     :                    ALLBAD, NOBAD, STATUS )
      END IF

*  Release the work space.
      CALL IRQ1_ANTMP( WLOC, STATUS )

*  Unmap the quality array.
      CALL NDF_UNMAP( QCM_INDF( IDQ ), 'QUALITY', STATUS )

      END
