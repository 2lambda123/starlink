      SUBROUTINE KPS1_MSS( IGRP, NNDF, COMP, ILEVEL, NGOOD, PIXS, 
     :                     STATUS )
*+
*  Name:
*     KPS1_MSS

*  Purpose:
*     Gets good pixels at a given point from a group of NDFs.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     KPS1_MSS( IGRP, NNDF, COMP, ILEVEL, NGOOD, PIXS, STATUS )

*  Description:
*     The user is asked for the coordinates of a point in the current
*     coordinate systems of a group of NDFs.  For each NDF in a given 
*     group which contains this point, the pixel value at that point
*     is returned in an array.

*  Arguments:
*     IGRP = INTEGER (Given)
*        The GRP identifier of a group of NDFs to be examined.
*     NNDF = INTEGER (Given)
*        The number of NDFs in the group (size of IGRP).
*     COMP = CHARACTER * ( * ) (Given)
*        The component of the NDFs which is to be interrogated.  May
*        be Data, Variance, Error or Quality. 
*     ILEVEL = INTEGER (Given)
*        If 1 nothing is printed. If 2 print statistics. If 3, print 
*        statistics and pixel values.
*     NGOOD = INTEGER (Returned)
*        The number of good pixels found.
*     PIXS( * ) = DOUBLE PRECISION (Returned)
*        The good pixels from the NDFs.  Only the first NGOOD elements
*        are filled.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     MBT: Mark Taylor (Starlink)
*     {enter_new_authors_here}

*  History:
*     4-DEC-2001 (MBT):
*        Original version.

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST system declarations
      INCLUDE 'GRP_PAR'          ! GRP public constants
      INCLUDE 'NDF_PAR'          ! NDF system constants
      INCLUDE 'PRM_PAR'          ! VAL__BADx constants
      
*  Arguments Given:
      INTEGER IGRP
      INTEGER NNDF
      CHARACTER COMP * ( * )
      INTEGER ILEVEL

*  Arguments Returned:
      INTEGER NGOOD
      DOUBLE PRECISION PIXS( * )

*  Status:
      INTEGER STATUS

*  Local Variables:
      CHARACTER BUF * ( AST__SZCHR ) ! Buffer
      CHARACTER DMN0 * ( AST__SZCHR ) ! Domain of current Frame
      CHARACTER NAME * ( GRP__SZNAM ) ! Name of NDF
      DOUBLE PRECISION BPOS( NDF__MXDIM ) ! Pixel position in base Frame
      DOUBLE PRECISION CPOS( NDF__MXDIM ) ! Pixel position in current Frame
      INTEGER BDIM( NDF__MXDIM ) ! Dimensionality of base Frame
      INTEGER EL                 ! Number of pixels
      INTEGER I                  ! Loop variable
      INTEGER IAT                ! Position in string buffer
      INTEGER J                  ! Loop variable
      INTEGER IFRM0              ! AST pointer to current Frame of WCS
      INTEGER INDF               ! NDF identifier for this NDF
      INTEGER INDF0              ! NDF identifier for the first NDF
      INTEGER INDF1              ! NDF identifier for 1-pixel NDF section
      INTEGER IPCOMP             ! Pointer to mapped array component
      INTEGER IWCS               ! AST pointer to WCS FrameSet of this NDF
      INTEGER IWCS0              ! AST pointer to WCS FrameSet of first NDF
      INTEGER LBND( NDF__MXDIM ) ! Lower bounds of NDF
      INTEGER NBDIM              ! Dimensionality of base Frame of this NDF
      INTEGER NCDIM              ! Dimensionality of current Frame of this NDF
      INTEGER NCDIM0             ! Dimensionality of current Frame of first NDF
      INTEGER NDIM               ! Dimensionaliry of NDF
      INTEGER PPOS( NDF__MXDIM ) ! Pixel coordinates of chosen pixel
      INTEGER UBND( NDF__MXDIM ) ! Upper bounds of NDF
      LOGICAL OK                 ! Is pixel within NDF?

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Open the first NDF in the list which will be used as a reference
*  NDF for some general setup.
      CALL NDG_NDFAS( IGRP, 1, 'READ', INDF0, STATUS )

*  Get the WCS FrameSet of the reference NDF.
      CALL KPG1_GTWCS( INDF0, IWCS0, STATUS )

*  Get its current Frame.
      IFRM0 = AST_GETFRAME( IWCS0, AST__CURRENT, STATUS )

*  Get its current Domain.
      DMN0 = AST_GETC( IFRM0, 'DOMAIN', STATUS )

*  Get the dimensionality of its current Frame.
      NCDIM0 = AST_GETI( IFRM0, 'NAXES', STATUS )

*  Ensure that there is no default position.
      DO I = 1, NCDIM0
         CPOS( I ) = AST__BAD
      END DO

*  Get the position at which the statistics will be gathered.
      CALL KPG1_GTPOS( 'POS', IFRM0, .FALSE., CPOS, 0.0D0, STATUS )

*  Write an introductory message, if necessary.
      IF( ILEVEL .GT 1 ) THEN
         CALL MSG_BLANK( STATUS )
         BUF = ' '
         IAT = 0
         CALL CHR_APPND( '(', BUF, IAT )
         IAT = IAT + 1
         DO I = 1, NCDIM0
            CALL CHR_APPND( AST_FORMAT( IFRM0, I, CPOS( I ), STATUS ),
     :                      BUF, IAT )
            IF ( I .LT. NCDIM0 ) THEN
               CALL CHR_APPND( ',', BUF, IAT )
            END IF
            IAT = IAT + 1
         END DO
         CALL CHR_APPND( ')', BUF, IAT )
         CALL MSG_SETC( 'POS', BUF( 1:IAT ) )
         CALL MSG_OUT( ' ', ' Pixel statistics at position ^POS ' //
     :                 'in current Frame.', STATUS )
      END IF

*  Write headings if necessary.
      IF ( ILEVEL .GE. 3 ) THEN
         CALL MSG_BLANK( STATUS )
         BUF = ' '
         BUF( 5: ) = 'NDF'
         BUF( 30: ) = 'Domain'
         BUF( 50: ) = 'Pixel value'
         CALL MSG_OUT( ' ', BUF, STATUS )
         BUF = ' '
         BUF( 5: ) = '---'
         BUF( 30: ) = '------'
         BUF( 50: ) = '-----------'
         CALL MSG_OUT( ' ', BUF, STATUS )
      END IF

*  Loop over each NDF getting the value for the selected position for 
*  each one.
      NGOOD = 0
      DO I = 1, NNDF

*  Open the NDF (unless it is the first one, which we have already opened).
         IF ( I .EQ. 1 ) THEN
            INDF = INDF0
         ELSE
            CALL NDG_NDFAS( IGRP, I, 'READ', INDF, STATUS )
         END IF

*  Get the dimensions of the NDF, including the dimensionality of its
*  base Frame.
         CALL NDF_DIM( INDF, NDF__MXDIM, BDIM, NBDIM, STATUS )

*  Get its WCS FrameSet.
         CALL KPG1_GTWCS( INDF, IWCS, STATUS )

*  Get the dimensionality of the current Frame.
         NCDIM = AST_GETI( IWCS, 'NAXES', STATUS )

*  Check that this is consistent with the dimensionality of the 
*  reference NDF.
         IF ( NCDIM .NE. NCDIM0 ) THEN
            CALL GRP_GET( IGRP, 1, 1, NAME, STATUS )
            CALL MSG_SETC( 'NDF1', NAME )
            CALL GRP_GET( IGRP, I, 1, NAME, STATUS )
            CALL MSG_SETC( 'NDF2', NAME )
            STATUS = SAI__ERROR 
            CALL ERR_REP( 'KPS1_MSS_ERR1:', 
     :                    'Current Frames of ^NDF1 ' //
     :                    'and ^NDF2 have different ' //
     :                    'dimensionalities.', STATUS )
            GO TO 999
         END IF

*  Locate the position in the base (GRID-domain) Frame of the NDF which
*  corresponds to the selected position.
         CALL AST_TRANN( IWCS, 1, NCDIM, 1, CPOS, .FALSE., NBDIM,
     :                   1, BPOS, STATUS )

*  Determine the pixel coordinates of the point to which this position
*  corresponds, and check whether it is within the bounds of the NDF.
         CALL NDF_BOUND( INDF, NDF__MXDIM, LBND, UBND, NDIM, STATUS )
         OK = .TRUE.
         DO J = 1, NDIM
            PPOS( J ) = ANINT( BPOS( J ) ) + LBND( J ) - 1
            OK = OK .AND. PPOS( J ) .GE. LBND( J )
     :              .AND. PPOS( J ) .LE. UBND( J )
         END DO

*  If the point is within the bounds of the NDF, we will want to retrieve
*  and store its value.
         IF ( OK ) THEN

*  Create an NDF section containing just this one pixel.
            CALL NDF_SECT( INDF, NDIM, PPOS, PPOS, INDF1, STATUS )

*  Map the relevant NDF component.
            CALL NDF_MAP( INDF1, COMP, '_DOUBLE', 'READ', IPCOMP,
     :                    EL, STATUS )

*  Extract the single pixel value.
            CALL KPG1_RETRD( EL, 1, %VAL( IPCOMP ), PIXS( NGOOD + 1 ), 
     :                       STATUS )

*  Check if this pixel is good.
            IF ( PIXS( NGOOD + 1 ) .NE. VAL__BADD ) THEN

*  If so, bump the number of collected pixels.
               NGOOD = NGOOD + 1

*  Record value.
               CALL MSG_SETD( 'VALUE', PIXS( NGOOD ) )

*  If the pixel is bad, record this information.
            ELSE
               CALL MSG_SETC( 'VALUE', '<BAD>' )
            END IF

*  Annul the NDF and its section.
            CALL NDF_ANNUL( INDF, STATUS )
            CALL NDF_ANNUL( INDF1, STATUS )

*  If the pixel was outside the NDF, record this information.
         ELSE
            CALL MSG_SETC( 'VALUE', '<OUTSIDE NDF>' )
         END IF

*  Log to user if required.
         IF ( ILEVEL .GE. 3 ) THEN
            BUF = ' '
            CALL GRP_GET( IGRP, I, 1, BUF( 5: ), STATUS )
            BUF( 29: ) = ' ' // AST_GETC( IWCS, 'DOMAIN', STATUS )
            CALL MSG_LOAD( ' ', ' ^VALUE', BUF( 49: ), IAT, STATUS )
            CALL MSG_OUT( ' ', BUF, STATUS )
         END IF
        
      END DO

*  Write summary information.
      IF ( ILEVEL .GE. 3 ) THEN
         CALL MSG_BLANK( STATUS )
      END IF

      IF( ILEVEL .GE. 2 ) THEN
         CALL MSG_SETI( 'NGOOD', NGOOD )
         CALL MSG_OUT( ' ', ' Number of non-bad pixels:  ^NGOOD',
     :                 STATUS )
         CALL MSG_BLANK( STATUS )
      END IF

*  Error exit label.
  999 CONTINUE

      END
