      SUBROUTINE NDFCOPY( STATUS )
*+
*  Name:
*     NDFCOPY

*  Purpose:
*     Copies an NDF (or NDF section) to a new location.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL NDFCOPY( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application copies an NDF to a new location.  By supplying an
*     NDF section as input it may be used to extract a subset, or to
*     change the size or dimensionality of an NDF. A second NDF may
*     also be supplied to act as a shape template, and hence to define
*     the region of the first NDF which is to be copied.
*
*     Any unused space will be eliminated by the copying operation
*     performed by this routine, so it may be used as a way of
*     compressing NDF structures from which components have been
*     deleted.  This ability also makes NDFCOPY a useful alternative to
*     SETBOUND in cases where an NDF's size is to be reduced.

*  Usage:
*     ndfcopy in out

*  ADAM Parameters:
*     IN = NDF (Read)
*        The input NDF (or section) which is to be copied.
*     LIKE = NDF (Read)
*        This parameter may be used to supply an NDF to be used as a
*        shape template during the copying operation.  If such a
*        template is supplied, then its shape will be used to select a
*        matching section from the input NDF before copying takes
*        place.  By default, no template will be used and the shape of
*        the output NDF will therefore match that of the input NDF (or
*        NDF section). [!]
*     OUT = NDF (Write)
*        The output NDF data structure.
*     TITLE = LITERAL (Read)
*        A title for the output NDF.  A null value (the default) will
*        cause the title of the NDF supplied for parameter IN to be
*        used instead. [!]
*     TRIM = _LOGICAL (Read)
*        If TRUE, then the number of pixel axes in the output NDF will be
*        reduced if necessary to remove any pixel axes which span only a
*        single pixel. For instance if "stokes" is a 3D data cube with 
*        pixel bounds (1:100,-50:40,1:3), and the parameter IN is given the 
*        value "stokes(,,2)", then the dimensionality of the output depends 
*        on the setting of TRIM: if TRIM=NO the output is 3D with pixel 
*        bounds (1:100,-50:40,2:2) and if TRIM=YES the output is 2D with 
*        pixel bounds (1:100,-50:40). In this example, the third pixel 
*        axis spans only a single pixel and is consequently removed if 
*        TRIM=YES.  [FALSE]
*     TRIMWCS = _LOGICAL (Read)
*        This parameter is only accessed if parameter TRIM is TRUE. It
*        controls the number of axes in the current WCS co-ordinate Frame
*        of the output NDF. If TRIMWCS=YES, then the current Frame in the 
*        output NDF will have the same number of axes as there are pixel
*        axes in the output NDF. If this involves removing axes, then the
*        axes to retain are specified by parameter USEAXIS. If TRIMWCS=NO
*        then all axes are retained in the current WCS Frame of the
*        output NDF. Using the example in the description of the TRIM
*        parameter, if the input NDF "stokes" has a 3D current WCS Frame 
*        with axes (Ra,Dec,Stokes) and TRIMWSC=YES, then an axis will be
*        removed from the current Frame to make it 2 dimensional (that
*        is, to match the number of pixel axes remaining after the
*        removal of insignificant pixel axes). The choice of which two
*        axes to retain is controlled by parameter USEAXIS. If, on the
*        other hand, TRIMWCS was set to FALSE, then the output NDF would
*        still have two pixel axes, but the current WCS Frame would retain 
*        all three axes from the input NDF. If one or more current Frame 
*        axes are removed, the transformation from the current Frame to 
*        pixel Frame may become undefined resulting in some WCS operations 
*        being unusable. The inverse of this transformation (from pixel 
*        Frame to current Frame) is unchanged however. [TRUE]
*     USEAXIS = LITERAL (Read)
*        This parameter is only accessed if TRIM and TRIMWCS are both TRUE
*        and some axes need to be removed from the current WCS Frame of
*        the output NDF. It gives the axes which are to be retained in
*        the current WCS Frame of the output NDF. Each axis can be 
*        specified either by giving its index within the Current Frame 
*        of the input NDF in the range 1 to the number of axes in the Frame, 
*        or by giving its symbol. The dynamic default selects the axes with 
*        the same indices as the pixel axes being copied. The value should 
*        be given as a comma separated list. []

*  Examples:
*     ndfcopy infile outfile
*        Copies the contents of the NDF structure infile to the new
*        structure outfile.  Any unused space will be eliminated during
*        the copying operation.
*     ndfcopy in=data1(3:40,-3:17) out=data2 title="Extracted section"
*        Copies the section (3:40,-3:17) of the NDF called data1 to a
*        new NDF called data2.  The output NDF is assigned the new title
*        "Extracted section", which replaces the title derived from the
*        input NDF.
*     ndfcopy galaxy newgalaxy like=oldgalaxy
*        Copies a section of the NDF called galaxy to form a new NDF
*        called newgalaxy.  The section which is copied will correspond
*        in shape with the template oldgalaxy.  Thus, after the copying
*        operation, both newgalaxy and oldgalaxy will have the same
*        pixel-index bounds.
*     ndfcopy aa(20~11,20~11) bb like=aa
*        Copies from the NDF section consisting of an 11x11 pixel
*        region of aa centred on pixel (20,20), into a new NDF called
*        bb.  The shape of the region copied is made to match the
*        original shape of aa.  The effect is to extract the selected
*        square region of pixels into a new NDF of the same shape as
*        the original, setting the surrounding region to the bad-pixel
*        value.

*  Implementation Status:
*     If present, an NDF's TITLE, LABEL, UNITS, DATA, VARIANCE,
*     QUALITY, AXIS WCS and HISTORY components are copied by this routine,
*     together with all extensions.  The output NDF's title may be
*     modified, if required, by specifying a new value via the TITLE
*     parameter.

*  Related Applications:
*     KAPPA: SETBOUND; Figaro: ISUBSET.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     27-FEB-1991 (RFWS):
*        Original version.
*     19-MAR-1991 (RFWS):
*        Added the LIKE parameter to allow the use of a shape template.
*     22-MAR-1991 (RFWS):
*        Added the TITLE parameter.
*     1995 April 24 (MJC):
*        Made usage and examples lowercase.  Added Related Applications.
*     5-JUN-1998 (DSB):
*        Added propagation of the WCS component.
*     12-APR-2000 (DSB):
*        Added TRIM, TRIMWCS and USEAXIS parameters.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PAR_ERR'          ! PAR_ error codes
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'DAT_PAR'          ! HDS_ public constants
      INCLUDE 'AST_PAR'          ! AST functions and constants

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER COMP(3)*(DAT__SZNAM)! NDF array component names
      CHARACTER LOC1*(DAT__SZLOC)! Locator to the output NDF
      CHARACTER LOC2*(DAT__SZLOC)! Locator to output AXIS array
      CHARACTER LOC2C*(DAT__SZLOC)! Locator to a single output AXIS structure
      CHARACTER LOC3*(DAT__SZLOC)! Locator to the input NDF
      CHARACTER LOC4*(DAT__SZLOC)! Locator to input AXIS array
      CHARACTER LOC4C*(DAT__SZLOC)! Locator to a single input AXIS structure
      CHARACTER LOC5*(DAT__SZLOC)! Locator to AXIS component
      CHARACTER NAME*(DAT__SZNAM)! Name of AXIS component
      CHARACTER TYPE*(DAT__SZTYP)! Numerical type of array component
      INTEGER DIM( NDF__MXDIM )  ! NDF dimensions
      INTEGER EL                 ! No. of elements in mapped array
      INTEGER I                  ! Loop index
      INTEGER IERR               ! Index of first numerical error
      INTEGER IP1                ! Pointer to mapped input array
      INTEGER IP2                ! Pointer to mapped output array
      INTEGER IWCS               ! WCS FrameSet for output
      INTEGER IWCS2              ! WCS FrameSet from input
      INTEGER LBND( NDF__MXDIM ) ! Template NDF lower bounds
      INTEGER NCOMP              ! No. of components in AXIS structure
      INTEGER NDF1               ! Input NDF identifier
      INTEGER NDF2               ! Template NDF identifier
      INTEGER NDF3               ! Output NDF identifier
      INTEGER NDFT               ! Temporary NDF identifier
      INTEGER NDIM               ! Number of template dimensions
      INTEGER NERR               ! Number of numerical errors
      INTEGER NEWAX              ! New output axis index
      INTEGER OLDAX              ! Old output axis index
      INTEGER SDIM( NDF__MXDIM ) ! Indices of significant pixel axes
      INTEGER SIGDIM             ! No. of significant pixel indices
      INTEGER SLBND( NDF__MXDIM )! Significant axis lower bounds
      INTEGER SUBND( NDF__MXDIM )! Significant axis upper bounds
      INTEGER UBND( NDF__MXDIM ) ! Template NDF upper bounds
      LOGICAL BAD                ! Any bad values in the array component?
      LOGICAL THERE              ! Does object exists?
      LOGICAL TRIM               ! Remove insignificant pixel axes?
      LOGICAL TRMWCS             ! Remove corresponding WCS axes?

      DATA COMP /'DATA', 'VARIANCE', 'QUALITY' /
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Begin an NDF context.
      CALL NDF_BEGIN

*  Obtain the input NDF.
      CALL LPG_ASSOC( 'IN', 'READ', NDF1, STATUS )
      IF ( STATUS .EQ. SAI__OK ) THEN

*  Defer error reporting and attempt to obtain a second NDF to act as a
*  shape template.
         CALL ERR_MARK
         CALL LPG_ASSOC( 'LIKE', 'READ', NDF2, STATUS )

*  Interpret a null value as indicating that a template should not be
*  used.
         IF ( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )

*  If a template was supplied, then obtain its bounds and select a
*  matching section from the input NDF.  Annul the original input NDF
*  identifier and replace it with the section identifier.
         ELSE
            CALL NDF_BOUND( NDF2, NDF__MXDIM, LBND, UBND, NDIM, STATUS )
            CALL NDF_SECT( NDF1, NDIM, LBND, UBND, NDFT, STATUS )
            CALL NDF_ANNUL( NDF1, STATUS )
            NDF1 = NDFT
         END IF
         CALL ERR_RLSE
      END IF

*  See if pixel axes spanning a single pixel are to be removed.
      CALL PAR_GET0L( 'TRIM', TRIM, STATUS )

*  If not, copy all components from the input NDF (or section) to create 
*  the output NDF.
      IF( .NOT. TRIM ) THEN
         CALL LPG_PROP( NDF1,
     :               'Title,Label,Units,Data,Variance,Quality,Axis,' //
     :               'History,WCS', 'OUT', NDF3, STATUS )

*  Otherwise, we do not need to copy the array comnponents, or the WCS or
*  AXIS components since we will be copying these explicitly.
      ELSE
         CALL LPG_PROP( NDF1, 'Title,Label,Units,History', 'OUT', NDF3, 
     :                  STATUS )

*  See if the current WCS co-ordinate Frame is to be modified so that it
*  has the same number of axes as the pixel Frame.
         CALL PAR_GET0L( 'TRIMWCS', TRMWCS, STATUS )

*  Find the number of significant axes (i.e. axes panning more than 1
*  pixel). First find the number of dimensions.
         CALL NDF_DIM( NDF1, NDF__MXDIM, DIM, NDIM, STATUS )

*  Loop round each dimension, counting the significant axes.
         SIGDIM = 0
         DO I = 1, NDIM
            IF ( DIM( I ) .GT. 1 ) SIGDIM = SIGDIM + 1
         END DO

*  Get the trimmed WCS FrameSet to be stored in the output NDF. 
         CALL KPG1_ASGET( NDF1, SIGDIM, .TRUE., TRMWCS, .FALSE., SDIM, 
     :                    SLBND, SUBND, IWCS, STATUS )

*  The above call will have copied the NDF Title to the WCS current Frame
*  Title if the Frame had no Title set. We want this application to do a
*  straight copy, so this behaviour is not what we want. CHeck the Title
*  attribute in the original input WCS current Frame, and if not set, clear
*  the Title in the WCS FrameSet returned above.
         CALL KPG1_GTWCS( NDF1, IWCS2, STATUS )
         IF( .NOT. AST_TEST( IWCS2, 'Title', STATUS ) ) THEN
            CALL AST_CLEAR( IWCS, 'Title', STATUS )
         END IF

*  Modify the bounds of the output NDF so that the significant axes
*  span axes 1 to SIGDIM.
         CALL NDF_SBND( SIGDIM, SLBND, SUBND, NDF3, STATUS ) 

*  We now need to copy any AXIS structures into the output NDF so that 
*  they refer to the re-ordered axes. 
         CALL NDF_STATE( NDF1, 'AXIS', THERE, STATUS )
         IF( THERE ) THEN

*  Since we will be using HDS to modify the output NDF, we need to take
*  care that the internal representation of the NDF stored within the
*  common blocks of the NDF library does not get out of step with the 
*  actual HDS structure of the NDF. For this reason, we get an HDS
*  locator to the NDF and then annul the NDF identifier. We will
*  re-import the modified NDF back into the NDF library once all the
*  changes have been made. Before annulling the NDF, we need to map the
*  DATA array to put it into a defined state since we are not allowed to
*  release an NDF with an undefined DATA array.
            CALL NDF_MAP( NDF3, 'DATA', '_BYTE', 'WRITE', IP2, EL, 
     :                    STATUS ) 
            CALL NDF_LOC( NDF3, 'READ', LOC1, STATUS ) 
            CALL DAT_PRMRY( .TRUE., LOC1, .TRUE., STATUS ) 
            CALL NDF_ANNUL( NDF3, STATUS )

*  Create a new array of axis structures within the output NDF, and get a 
*  locator to it.
            CALL DAT_NEW( LOC1, 'AXIS', 'AXIS', 1, SIGDIM, STATUS ) 
            CALL DAT_FIND( LOC1, 'AXIS', LOC2, STATUS )

*  Get a locator to the array of AXIS structures in the input NDF.
            CALL NDF_LOC( NDF1, 'READ', LOC3, STATUS ) 
            CALL DAT_FIND( LOC3, 'AXIS', LOC4, STATUS ) 

*  Loop round each re-ordered axis in the output NDF.
            DO NEWAX = 1, SIGDIM
               OLDAX = SDIM( NEWAX )

*  Get locators to the appropriate cells of the old and new AXIS arrays.
               CALL DAT_CELL( LOC2, 1, NEWAX, LOC2C, STATUS ) 
               CALL DAT_CELL( LOC4, 1, OLDAX, LOC4C, STATUS ) 

*  Copy all components of the old axis structure into the new axis
*  structure.
               CALL DAT_NCOMP( LOC4C, NCOMP, STATUS ) 
               DO I = 1, NCOMP
                  CALL DAT_INDEX( LOC4C, I, LOC5, STATUS ) 
                  CALL DAT_NAME( LOC5, NAME, STATUS ) 
                  CALL DAT_COPY( LOC5, LOC2C, NAME, STATUS ) 
                  CALL DAT_ANNUL( LOC5, STATUS ) 
               END DO

*  Annul the locators to the cells.
               CALL DAT_ANNUL( LOC4C, STATUS )
               CALL DAT_ANNUL( LOC2C, STATUS )

            END DO

*  Re-import the modified NDF into the NDF Library.
            CALL NDF_FIND( LOC1, ' ', NDF3, STATUS )

*  Annul the remaining Locators.
            CALL DAT_ANNUL( LOC4, STATUS )
            CALL DAT_ANNUL( LOC3, STATUS )
            CALL DAT_ANNUL( LOC2, STATUS )
            CALL DAT_ANNUL( LOC1, STATUS )

         END IF

*  Store the new WCS FrameSet in the output NDF.
         CALL NDF_PTWCS( IWCS, NDF3, STATUS )

*  Now copy the array components from input to output.
         DO I = 1, 3
            CALL NDF_STATE( NDF1, COMP( I ), THERE, STATUS ) 
            IF( THERE ) THEN
   
               CALL NDF_TYPE( NDF1, COMP( I ), TYPE, STATUS )
               CALL NDF_MAP( NDF1, COMP( I ), TYPE, 'READ', IP1, EL, 
     :                       STATUS ) 
               CALL NDF_BAD( NDF1, COMP( I ), .FALSE., BAD, STATUS ) 
               CALL NDF_MAP( NDF3, COMP( I ), TYPE, 'WRITE', IP2, EL, 
     :                       STATUS ) 
   
               IF( TYPE .EQ. '_DOUBLE' ) THEN
                  CALL VEC_DTOD( BAD, EL, %VAL( IP1 ), %VAL( IP2 ), 
     :                           IERR, NERR, STATUS )
   
               ELSE IF( TYPE .EQ. '_REAL' ) THEN
                  CALL VEC_RTOR( BAD, EL, %VAL( IP1 ), %VAL( IP2 ), 
     :                           IERR, NERR, STATUS )
   
               ELSE IF( TYPE .EQ. '_INTEGER' ) THEN
                  CALL VEC_ITOI( BAD, EL, %VAL( IP1 ), %VAL( IP2 ), 
     :                           IERR, NERR, STATUS )
   
               ELSE IF( TYPE .EQ. '_WORD' ) THEN
                  CALL VEC_WTOW( BAD, EL, %VAL( IP1 ), %VAL( IP2 ), 
     :                           IERR, NERR, STATUS )
   
               ELSE IF( TYPE .EQ. '_UWORD' ) THEN
                  CALL VEC_UWTOUW( BAD, EL, %VAL( IP1 ), %VAL( IP2 ), 
     :                             IERR, NERR, STATUS )
   
               ELSE IF( TYPE .EQ. '_BYTE' ) THEN
                  CALL VEC_BTOB( BAD, EL, %VAL( IP1 ), %VAL( IP2 ), 
     :                           IERR, NERR, STATUS )
   
               ELSE IF( TYPE .EQ. '_UBYTE' ) THEN
                  CALL VEC_UBTOUB( BAD, EL, %VAL( IP1 ), %VAL( IP2 ), 
     :                             IERR, NERR, STATUS )
               END IF

            END IF

         END DO

      END IF

*  Obtain a new title for the output NDF.
      CALL NDF_CINP( 'TITLE', NDF3, 'Title', STATUS )

*  End the NDF context.
      CALL NDF_END( STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'NDFCOPY_ERR',
     :     'NDFCOPY: Error copying an NDF to a new location.', STATUS )
      END IF

      END
