      SUBROUTINE SETAXIS( STATUS )
*+
*  Name:
*     SETAXIS

*  Purpose:
*     Sets values for an axis array component within an NDF data
*     structure.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL SETAXIS( STATUS )

*  Description:
*     This routine modifies the values of an axis array component or
*     system within an NDF data structure.  There are a number of
*     options (see parameter MODE).  They permit the deletion of the
*     axis system, or an individual variance or width component; the
*     replacement of one or more individual values; assignment of the
*     whole array using Fortran-like mathematical expressions, or values
*     in a text file, or to pixel co-ordinates.
*      
*     If an AXIS structure does not exist, a new one whose centres are
*     pixel co-ordinates is created before any modification.

*  Usage:
*     setaxis ndf dim mode [comp] { file=?
*                                 { index=? newval=?
*                                 { exprs=?
*                                 mode

*  ADAM Parameters:
*     COMP = LITERAL (Read)
*        The name of the NDF axis array component to be modified.  The
*        choices are: "Centre", "Data", "Error", "Width" or "Variance".
*        "Data" and "Centre" are synonyms and selects the axis centres.
*        "Variance" is the variance of the axis centres, i.e. measures
*        the uncertainty of the axis-centre values.  "Error" is the
*        alternative to "Variance" and causes the square of the
*        supplied error values to be stored.  "Width" selects the axis
*        width array.  ["Data"]
*     DIM = _INTEGER (Read)
*        The axis dimension for which the array component is to be
*        modified.  There are separate arrays for each NDF dimension.
*        The value must lie between 1 and the number of dimensions of
*        the NDF.  This defaults to 1 for a 1-dimensional NDF.  DIM is
*        not accessed when COMP="Centre" and MODE="Delete".  The
*        suggested default is the current value. []
*     EXPRS = LITERAL (Read)
*        A Fortran-like arithmetic expression giving the value to be
*        assigned to each element of the axis array specified by
*        parameter COMP.  The expression may just contain a constant
*        for the axis widths or variances, but the axis-centre values
*        must vary.  In the latter case and whenever a constant value
*        is not required, there are two tokens available---INDEX and
*        CENTRE---either or both of which may appear in the expression.
*        INDEX represents the pixel index of the corresponding array
*        element, and CENTRE represents the existing axis centres.
*        Either the CENTRE or the INDEX token must appear in the
*        expression when modifying the axis centres.  All of the
*        standard Fortran-77 intrinsic functions are available for use
*        in the expression, plus a few others (see SUN/61 for details
*        and an up-to-date list).
*
*        Here are some examples.  Suppose the axis centres are being
*        changed, then EXPRS="INDEX-0.5" gives pixel co-ordinates,
*        EXPRS="2.3 * INDEX + 10" would give a linear axis at offset 10
*        and an increment of 2.3 per pixel, EXPRS="LOG(INDEX*5.2)"
*        would give a logarithmic axis, and EXPRS="CENTRE+10" would add
*        ten to all the array centres.  If COMP="Width", EXPRS=0.96
*        would set all the widths to 0.96, and EXPRS="SIND(INDEX-30)+2"
*        would assign the widths to two plus the sine of the pixel
*        index with respect to index 30 measured in degrees.
*
*        EXPRS is only accessed when MODE="Expression".
*     FILE = FILENAME (Read)
*        Name of the text file containing the free-format axis data.
*        This parameter is only accessed if MODE="File".  The
*        suggested default is the current value.
*     INDEX = _INTEGER (Read)
*        The pixel index of the array element to change.  A null value
*        (!) terminates the loop during multiple replacements.  This
*        parameter is only accessed when MODE="Edit".  The suggested
*        default is the current value.
*     MODE = LITERAL (Read)
*        The mode of the modification.  It can be one of the following:
*
*           "Delete"     - Deletes the array, unless COMP="Data" or
*                          "Centre" whereupon the whole axis structure
*                          is deleted.
*           "Edit"       - Allows the modification of individual
*                          elements within the array.
*           "Expression" - Allows a mathematical expression to define
*                          the array values.  See parameter EXPRS.
*           "File"       - The array values are read in from a
*                          free-format text file.
*           "Pixel"      - The axis centres are set to pixel
*                          co-ordinates.  This is only available when
*                          COMP="Data" or "Centre".
*
*        The suggested default is the current value.
*     NDF = NDF (Read and Write)
*        The NDF data structure in which an axis array component is to
*        be modified.
*     NEWVAL = LITERAL (Read)
*        Value to substitute in the array element.  The range of
*        allowed values depends on the data type of the array being
*        modified.  NEWVAL="Bad" instructs that the bad value
*        appropriate for the array data type be substituted.  Placing
*        NEWVAL on the command line permits only one element to be
*        replaced.  If there are multiple replacements, a null value
*        (!) terminates the loop.  This parameter is only accessed when
*        MODE="Edit".
*     TYPE = LITERAL (Read)
*        The data type of the modified axis array.  TYPE can be either
*        "_REAL" or "_DOUBLE".  It is only accessed for MODE="File",
*        "Expression", or "Pixel".  The default is the current data
*        type of the array component if it exists, otherwise it is
*        "_REAL". []

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Examples:
*     setaxis ff mode=delete
*        This erases the axis structure from the NDF called ff.
*     setaxis abell4 1 expr exprs="CENTRE + 0.1 * (INDEX-1)"
*        This modifies the axis centres along the first axis in the NDF
*        called abell4.  The new centre values are spaced by 0.1 more
*        per element than previously.
*     setaxis cube 3 expr error exprs="25.3+0.2*MOD(INDEX,8)"
*        This modifies the axis errors along the third axis in the NDF
*        called cube.  The new errors values are given by the
*        expression "25.3+0.2*MOD(INDEX,8)", in other words the noise
*        has a constant term (25.3), and a cyclic ramp component of
*        frequency 8 pixels.
*     setaxis spectrum mode=file file=spaxis.dat
*        This assigns the axis centres along the first axis in the
*        1-dimensional NDF called spectrum.  The new centre values are
*        read from the free-format text file called spaxis.dat.
*     setaxis ndf=plate3 dim=2 mode=pixel
*        This assigns pixel co-ordinates to the second axis's centres
*        in the NDF called plate3.
*     setaxis datafile 2 expression exprs="centre" type=_real
*        This modifies the data type of axis centres along the second
*        dimension of the NDF called datafile to be _REAL.
*     setaxis cube 2 edit index=3 newval=129.916
*        This assigns the value 129.916 to the axis centre at index 3
*        along the second axis of the NDF called cube.
*     setaxis comp=width ndf=cube dim=1 mode=edit index=-16 newval=1E-05
*        This assigns the value 1.0E-05 to the axis width at index -16
*        along the first axis of the NDF called cube.

*  Notes:
*     -  An end-of-file error results when MODE="File" and the file
*     does not contain sufficient values to assign to the whole array.
*     In this case the axis array is unchanged.  A warning is given if
*     there are more values in a file record than are needed to complete
*     the axis array.
*     -  An invalid expression when MODE="Expression" results in an
*     error and the axis array is unchanged.
*     -  The chapter entitled "The Axis Coordinate System" in SUN/33
*     describes the NDF axis co-ordinate system and is recommended
*     reading especially if you are using axis widths.
*     -  There is no check, apart from constraints on parameter NEWVAL,
*     that the variance is not negative and the widths are positive.

*  File Format:
*     The format is quite flexible.  The number of axis-array values
*     that may appear on a line is variable; the values are separated
*     by at least a space, comma, tab or carriage return.  A line can
*     have up to 255 characters.  In addition a record may have
*     trailing comments designated by a hash or exclamation mark.  Here
*     is an example file, though a more regular format would be clearer
*     for the human reader (say 10 values per line with commenting).
*
*         # Axis Centres along second dimension
*         -3.4 -0.81
*         .1 3.3 4.52 5.6 9 10.5 12.  15.3   18.1  20.2
*         23 25.3 ! a comment
*         26.8,27.5 29. 30.76  32.1 32.4567
*          35.2 37.
*         <EOF>

*  Related Applications:
*     KAPPA: AXCONV, AXLABEL, AXUNITS; Figaro: LXSET, LYSET.

*  Implementation Status:
*     Processing is in single- or double-precision floating point.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1995 April 24 (MJC):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF__ constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'PRM_PAR'          ! VAL__ error constants
      INCLUDE 'PAR_PAR'          ! PAR__ constants
      INCLUDE 'PAR_ERR'          ! PAR__ error constants

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Significant length of a string
      CHARACTER * ( 2 ) CHR_NTH  ! Ordinal abbreviation
      EXTERNAL CHR_NTH

*  Local Constants:
      INTEGER SZEXP              ! Length of an expression
      PARAMETER ( SZEXP = 132 )

*  Local Variables:
      INTEGER ACTVAL             ! State of parameter NEWVAL
      INTEGER AXPNTR( 1 )        ! Pointer to mapped array component
      CHARACTER * ( VAL__SZD ) CVALUE ! Replacement value as obtained
      CHARACTER * ( 8 ) COMP     ! Name of array component to analyse
      CHARACTER * ( NDF__SZTYP ) DEFTYP ! Default processing type
      DOUBLE PRECISION DVALUE    ! Replacement value for d.p. data
      INTEGER EL                 ! Number of mapped values
      CHARACTER * ( SZEXP ) EXPRS ! Variance expression
      INTEGER FD                 ! File descriptor
      CHARACTER * ( SZEXP + 22 ) FOR( 1 ) ! Forward transformation
      INTEGER FPNTR              ! Pointer to work array for reading the
                                 ! file
      INTEGER IAXIS              ! Dimension to modify
      INTEGER IERR               ! First conversion error (dummy=0)
      INTEGER IMAP               ! Compiled mapping identifier
      CHARACTER * ( 6 ) INV( 2 ) ! Inverse transformation
      INTEGER LBND( NDF__MXDIM ) ! Lower bounds of the NDF
      INTEGER LCOMP              ! Length of component name
      INTEGER LEXP               ! Length of expression
      CHARACTER * ( DAT__SZLOC ) LOCTR ! Transformation locator
      LOGICAL LOOP               ! Loop for another section to replace
      CHARACTER * ( 8 ) MCOMP    ! Component name for mapping arrays
      CHARACTER * ( 10 ) MODE    ! Mode of the modification
      INTEGER NDF                ! NDF identifier
      INTEGER NDIM               ! Number of dimensions of NDF
      INTEGER NERR               ! Number of conversion errors (dummy=0)
      INTEGER NIN                ! Number of inverse expressions
      INTEGER NSUBS              ! Number of token substitutions
      INTEGER PIND               ! Pixel index of element to change
      INTEGER PNTRW              ! Pointer to mapped pixel indices
                                 ! and/or axis centres (work space)
      REAL RVALUE                ! Replacement value for real data
      LOGICAL SUBCEN             ! Substitute array centres in exprs?
      LOGICAL SUBIND             ! Substitute pixel indices in exprs?
      CHARACTER * ( 4 ) SUGDEF   ! Suggested default
      LOGICAL THERE              ! Axis system or component exists?
      CHARACTER * ( NDF__SZTYP ) TYPE ! Numeric type for processing
      INTEGER UBND( NDF__MXDIM ) ! Upper bounds of the NDF

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Start a NDF context.
      CALL NDF_BEGIN

*  Obtain an identifier for the NDF to be modified.
      CALL NDF_ASSOC( 'NDF', 'UPDATE', NDF, STATUS )

*  Find the number of dimensions, and bounds in the NDF.
      CALL NDF_BOUND( NDF, NDF__MXDIM, LBND, UBND, NDIM, STATUS )

*  Obtain the array component to modify.  Derive the mapping component
*  name, and equate the synonym.
      CALL PAR_CHOIC( 'COMP', 'Data', 'Centre,Data,Error,Width,'/
     :                /'Variance', .FALSE., COMP, STATUS )
      MCOMP = COMP
      IF ( COMP .EQ. 'ERROR' ) THEN
         COMP = 'VARIANCE'
      ELSE IF ( COMP .EQ. 'DATA' ) THEN
         COMP = 'CENTRE'
         MCOMP = 'CENTRE'
      END IF

*  Obtain the mode of the modification.  Note that the "Pixel" option
*  is only available for the axis centres.
      IF ( COMP .EQ. 'CENTRE' .OR. COMP .EQ. 'DATA' ) THEN
         CALL PAR_CHOIC( 'MODE', 'Expression', 'Delete,Edit,'/
     :                   /'Expression,File,Pixel', .FALSE., MODE,
     :                   STATUS )
      ELSE
         CALL PAR_CHOIC( 'MODE', 'Expression', 'Delete,Edit,'/
     :                   /'Expression,File', .FALSE., MODE, STATUS )
      END IF

*  Find which axis to modify only if there is more than one and the
*  selection is not to delete the axis system
      IAXIS = 1
      IF ( ( MODE .NE. 'DELETE' .OR. COMP .NE. 'CENTRE' ) .AND.
     :     NDIM .GT. 1 ) CALL PAR_GDR0I( 'DIM', 1, 1, NDIM, .FALSE.,
     :                   IAXIS, STATUS )

      IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Check that the axis system exists.  If it does not, create a pixel
*  co-ordinate system.
      CALL NDF_STATE( NDF, 'Axis', THERE, STATUS )
      IF ( .NOT. THERE ) CALL NDF_ACRE( NDF, STATUS )

*  Obtain the default data type for the component.  Find the current
*  data type of the component and use that where possible.  Note that
*  only floating-point types are allowed, so convert an integer type
*  to _REAL.
      CALL NDF_ASTAT( NDF, COMP, IAXIS, THERE, STATUS )
      IF ( THERE ) THEN
         CALL NDF_ATYPE( NDF, COMP, IAXIS, DEFTYP, STATUS )
         IF ( DEFTYP .NE. '_REAL' .AND. DEFTYP .NE. '_DOUBLE' )
     :      DEFTYP = '_REAL'
      ELSE
         DEFTYP = '_REAL'
      END IF

*  Process the array component in the desired mode.
*
*  Delete mode.
*  ============
      IF ( MODE .EQ. 'DELETE' ) THEN

*  The whole axis structure goes if the component is the axis-centre
*  array.
         IF ( COMP .EQ. 'CENTRE' ) THEN
            CALL NDF_RESET( NDF, 'Axis', STATUS )

*  Delete the individual array component.
         ELSE
            CALL NDF_AREST( NDF, COMP, IAXIS, STATUS )

         END IF

*  Edit mode.
*  ==========
      ELSE IF ( MODE .EQ. 'EDIT' ) THEN

*  Cannot edit a non-existent component.  Issue an error message and
*  exit.
         IF ( .NOT. THERE ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETC( 'CMP', COMP )
            CALL MSG_SETI( 'N', IAXIS )
            CALL MSG_SETC( 'TH', CHR_NTH( IAXIS ) )
            CALL ERR_REP( 'SETAXIS_ERR3', 'There is no ^CMP array '/
     :        /'along the ^N^TH dimension to edit.', STATUS )
            GOTO 999
         END IF

*  Determine whether or not to loop.  Looping does not occur if the
*  NEWVAL is given on the command line, i.e. it is already in the active
*  state.
         CALL PAR_STATE( 'NEWVAL', ACTVAL, STATUS )

*  Map the array component of the axis in update mode.
         TYPE = DEFTYP
         CALL NDF_AMAP( NDF, MCOMP, IAXIS, TYPE, 'Update', AXPNTR, EL,
     :                  STATUS )

         LOOP = .TRUE.
         DO WHILE ( STATUS .EQ. SAI__OK .AND. LOOP )

*  Do not loop if the value was given on the command line.
            LOOP = ACTVAL .NE. PAR__ACTIVE

*  Obtain the section.
            CALL PAR_GDR0I( 'INDEX', VAL__BADI, LBND( IAXIS ),
     :                      UBND( IAXIS ), .FALSE., PIND, STATUS )

*  Shift the origin to element 1.
            PIND = PIND + 1 - LBND( IAXIS )

*  Perform the replacement.
*  ========================
*
*  The replacement value and routine are type dependent, so call
*  the appropriate data type.

*  Real
*  ----
            IF ( TYPE .EQ. '_REAL' ) THEN

*  Get the replacement value.  The range depends on the processing data
*  type.
               SUGDEF = 'Junk'
               CALL PAR_MIX0R( 'NEWVAL', SUGDEF, VAL__MINR, VAL__MAXR,
     :                         'Bad', .FALSE., CVALUE, STATUS )

*  Convert the returned string to a numerical value.
               IF ( CVALUE .EQ. 'BAD' ) THEN
                  RVALUE = VAL__BADR
               ELSE
                  CALL CHR_CTOR( CVALUE, RVALUE, STATUS )
               END IF

*  Replace the element with the new value.
               CALL KPG1_STORR( EL, PIND, RVALUE, %VAL( AXPNTR( 1 ) ),
     :                          STATUS )

*  Double precision
*  ----------------
            ELSE IF ( TYPE .EQ. '_DOUBLE' ) THEN
               SUGDEF = 'Junk'
               CALL PAR_MIX0D( 'NEWVAL', SUGDEF, VAL__MIND, VAL__MAXD,
     :                         'Bad', .FALSE., CVALUE, STATUS )

*  Convert the returned string to a numerical value.
               IF ( CVALUE .EQ. 'BAD' ) THEN
                  DVALUE = VAL__BADD
               ELSE
                  CALL CHR_CTOD( CVALUE, DVALUE, STATUS )
               END IF

*  Replace the element with the new value.
               CALL KPG1_STORD( EL, PIND, DVALUE, %VAL( AXPNTR( 1 ) ),
     :                          STATUS )
            END IF

*  Annul a null status as this is expected, and closes the loop.
            IF ( STATUS .EQ. PAR__NULL ) THEN
               CALL ERR_ANNUL( STATUS )
               LOOP = .FALSE.

*  Cancel the previous values of NEWVAL and INDEX for the loop.
            ELSE IF ( LOOP .AND. STATUS .EQ. SAI__OK ) THEN
               CALL NDG_CANCL( 'INDEX', STATUS )
               CALL NDG_CANCL( 'NEWVAL', STATUS )
            END IF

*  End of the do-while loop for the elements.
         END DO

*  Unmap the axis array.  Note that 'Error' is not allowed as the
*  component.
         CALL NDF_AUNMP( NDF, COMP, IAXIS, STATUS )

*  Expression mode.
*  ================
      ELSE IF ( MODE .EQ. 'EXPRESSION' ) THEN

*  Obtain the type of the output array.
         CALL PAR_CHOIC( 'TYPE', DEFTYP, '_REAL,_DOUBLE', .FALSE., TYPE,
     :                   STATUS ) 

*  Obtain the expression relating variance values to data values.
         CALL PAR_GET0C( 'EXPRS', EXPRS, STATUS )

*  Get the character lengths of the expression and the component.
         IF ( STATUS .NE. SAI__OK ) GOTO 999
         LCOMP = CHR_LEN( COMP ) 
         LEXP = MAX( 1, CHR_LEN( EXPRS ) )

*  Find out whether or not the INDEX token appears in the expression by
*  attempting to replace each name in turn by itself and seeing if a
*  substitution results.
         SUBIND = .FALSE.
         CALL TRN_STOK( 'INDEX', 'INDEX', EXPRS( : LEXP ), NSUBS,
     :                  STATUS )

*  Record whether or not there is a substitution to be made.
         SUBIND = NSUBS .NE. 0

*  Find out whether or not the CENTRE token appears in the expression by
*  attempting to replace each name in turn by itself and seeing if a
*  substitution results.
         SUBCEN = .FALSE.
         CALL TRN_STOK( 'CENTRE', 'CENTRE', EXPRS( : LEXP ), NSUBS,
     :                  STATUS )

*  Record whether or not there is a substitution to be made.
         SUBCEN = NSUBS .NE. 0
         IF ( STATUS .NE. SAI__OK ) GO TO 999

*  If there is neither an INDEX nor a CENTRE token and the component is
*  the array of axis centres, this is an error.  Report it and exit.
         IF ( COMP .EQ. 'CENTRE' .AND.
     :        .NOT. ( SUBIND .OR. SUBCEN ) ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'SETAXIS_ERR2', 'The expression must '/
     :        /'contain the INDEX or CENTRE tokens for the axis '/
     :        /'centres.', STATUS )
            GOTO 999

*  There must be one inverse for the transformation.  This is the index
*  because it is always defined.
         ELSE IF ( .NOT. ( SUBIND .OR. SUBCEN ) ) THEN
            SUBIND = .TRUE.

         END IF

*  Set up the required transformations.  To avoid a duplicate name,
*  we can use CENTRE as a token and the forward variable.
         IF ( COMP( 1:6 ) .EQ. 'CENTRE' ) THEN
            FOR( 1 ) = 'COORD = ' // EXPRS( : LEXP )
         ELSE
            FOR( 1 ) = COMP( : LCOMP ) // ' = ' // EXPRS( : LEXP )
         END IF

         NIN = 0
         IF ( SUBIND ) THEN
            NIN = NIN + 1
            INV( NIN ) = 'INDEX'
         END IF
         IF ( SUBCEN ) THEN
            NIN = NIN + 1
            INV( NIN ) = 'CENTRE'
         END IF

*  Create a temporary transformation structure.  Use an elastic data
*  type for processing to cope with double-precision processing.
         CALL TRN_NEW( NIN, 1, FOR, INV, '_REAL:',
     :                 'INDEX --> ' // COMP( : LCOMP ), ' ', ' ',
     :                 LOCTR, STATUS )

*  Compile the transformation to give a mapping identifier.  Then delete
*  the temporary transformation structure.
         CALL TRN_COMP( LOCTR, .TRUE., IMAP, STATUS )
         CALL TRN1_ANTMP( LOCTR, STATUS )

*  Add context information at this point if an error occurs.
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL ERR_REP( 'SETVAR_COMP',
     :        'Error in %EXPRS expression.', STATUS )

         ELSE

*  Obtain the number of elements.
            EL = UBND( IAXIS ) - LBND( IAXIS ) + 1

*  Get some workspace for the pixel indices and centres.
            IF ( SUBIND .OR. SUBCEN )
     :         CALL PSX_CALLOC( NIN * EL, TYPE, PNTRW, STATUS )

            IF ( SUBIND ) THEN

*  Fill the first EL elements with the indices (in the appropriate
*  floating point).
               IF ( TYPE .EQ. '_REAL' ) THEN
                  CALL KPG1_ELNMR( LBND( IAXIS ), UBND( IAXIS ), EL,
     :                             %VAL( PNTRW ), STATUS )

               ELSE IF ( TYPE .EQ. '_DOUBLE' ) THEN
                  CALL KPG1_ELNMD( LBND( IAXIS ), UBND( IAXIS ), EL,
     :                             %VAL( PNTRW ), STATUS )
               END IF
            END IF

            IF ( SUBCEN ) THEN

*  Map the axis centres.
               CALL NDF_AMAP( NDF, 'Centre', IAXIS, TYPE, 'READ',
     :                        AXPNTR, EL, STATUS )

*  copy the input data into the NIN'th row of the appropriate work
*  array (considered as 2-dimensional), using the appropriate routine
*  for the data type.
               IF ( TYPE .EQ. '_REAL' ) THEN
                  CALL KPG1_PROWR( EL, %VAL( AXPNTR( 1 ) ), NIN,
     :                             %VAL( PNTRW ), STATUS )

               ELSE IF ( TYPE .EQ. '_DOUBLE' ) THEN
                  CALL KPG1_PROWD( EL, %VAL( AXPNTR( 1 ) ), NIN,
     :                             %VAL( PNTRW ), STATUS )

               END IF

*  Unmap the centres.
               CALL NDF_AUNMP( NDF, 'Centre', IAXIS, STATUS )
            END IF

*  Reset any pre-existing axis-array component and set its data type
*  to the chosen data type.
            IF ( COMP .NE. 'CENTRE' ) CALL NDF_AREST( NDF, COMP, IAXIS,
     :        STATUS )
            CALL NDF_ASTYP( TYPE, NDF, COMP, IAXIS, STATUS )

*  Map the array component for write access.
            CALL NDF_AMAP( NDF, MCOMP, IAXIS, TYPE, 'WRITE', AXPNTR,
     :                     EL, STATUS )

*  Calculate the new array values, using the appropriate precision.
*  There may be bad pixels to be checked for during the calculations.

*  Real
*  ----
            IF ( TYPE .EQ. '_REAL' ) THEN
               CALL TRN_TRNR( .TRUE., EL, NIN, EL, %VAL( PNTRW ), IMAP,
     :                        EL, 1, %VAL( AXPNTR( 1 ) ), STATUS )

*  Double precision
*  ----------------
            ELSE IF ( TYPE .EQ. '_DOUBLE' ) THEN
               CALL TRN_TRND( .TRUE., EL, NIN, EL, %VAL( PNTRW ), IMAP,
     :                        EL, 1, %VAL( AXPNTR( 1 ) ), STATUS )
            END IF

*  Annul the compiled mapping.
            CALL TRN_ANNUL( IMAP, STATUS )

*  Free the workspace.
            CALL PSX_FREE( PNTRW, STATUS )

*  Unmap the array.  Note that 'Error' is not allowed as the component.
            CALL NDF_AUNMP( NDF, COMP, IAXIS, STATUS )

         END IF

*  File mode.
*  ==========
      ELSE IF ( MODE .EQ. 'FILE' ) THEN

*  Obtain the type of the output array.
         CALL PAR_CHOIC( 'TYPE', DEFTYP, '_REAL,_DOUBLE', .FALSE.,
     :                   TYPE, STATUS ) 

*  Attempt to obtain and open a free-format data file.
         CALL FIO_ASSOC( 'FILE', 'READ', 'LIST', 0, FD, STATUS )
         IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Reset any pre-existing axis-array component and set its data type to
*  the chosen data type.
         IF ( COMP .NE. 'CENTRE' ) CALL NDF_AREST( NDF, COMP, IAXIS,
     :     STATUS )
         CALL NDF_ASTYP( TYPE, NDF, COMP, IAXIS, STATUS )

*  Map the array component for writing.
         CALL NDF_AMAP( NDF, MCOMP, IAXIS, TYPE, 'WRITE', AXPNTR, EL,
     :                  STATUS )

*  Append sequentially each value to the vector.  Choose the
*  appropriate subroutine for the data type.
         IF ( TYPE .EQ. '_DOUBLE' ) THEN
            CALL KPS1_TRNDD( FD, EL, %VAL( AXPNTR( 1 ) ), STATUS )

         ELSE IF ( TYPE .EQ. '_REAL' ) THEN
            CALL KPS1_TRNDR( FD, EL, %VAL( AXPNTR( 1 ) ), STATUS )

         END IF

*  Unmap the array.  Note that 'Error' is not allowed as the component.
         CALL NDF_AUNMP( NDF, COMP, IAXIS, STATUS )

*  Close free-format data file.
         CALL FIO_ANNUL( FD, STATUS )

*  Pixel mode.
*  ===========
      ELSE IF ( MODE .EQ. 'PIXEL' ) THEN

*  Obtain the type of the output array.
         CALL PAR_CHOIC( 'TYPE', DEFTYP, '_REAL,_DOUBLE', .FALSE.,
     :                   TYPE, STATUS ) 

*  Specify the number of elements along the axis.
         EL = UBND( IAXIS ) - LBND( IAXIS ) + 1

*  Obtain workspace in which to read the file.  This is insurance in cas
*  the file has in sufficient values or some other error.
         CALL PSX_CALLOC( EL, TYPE, FPNTR, STATUS )

*  Write the pixel co-ordinates to the array from block floating point
*  (step size one, offset lower bound - 0.5).  Use the appropriate
*  subroutine for the data type.
         IF ( TYPE .EQ. '_DOUBLE' ) THEN
            CALL KPG1_SSAZD( EL, 1.0D0, DBLE( LBND( IAXIS ) ) - 0.5D0,
     :                       %VAL( FPNTR ), STATUS )

         ELSE IF ( TYPE .EQ. '_REAL' ) THEN
            CALL KPG1_SSAZR( EL, 1.0D0, DBLE( LBND( IAXIS ) ) - 0.5D0,
     :                       %VAL( FPNTR ), STATUS )

         END IF

*  Only if the reading was successful do we tamper with the array
*  component.
         IF ( STATUS .EQ. SAI__OK ) THEN

*  Reset any pre-existing axis-centre component and set its data type
*  to the chosen data type.
            IF ( COMP .NE. 'CENTRE' ) CALL NDF_AREST( NDF, COMP, IAXIS,
     :        STATUS )
            CALL NDF_ASTYP( TYPE, NDF, COMP, IAXIS, STATUS )

*  Map the array component for writing.
            CALL NDF_AMAP( NDF, MCOMP, IAXIS, TYPE, 'WRITE', AXPNTR, EL,
     :                     STATUS )

*  Copy the work array into the axis array component.  Since there are
*  no type conversions, the bad value need not be checked.  Call the
*  appropriate routine for the data type.
            IF ( TYPE .EQ. '_DOUBLE' ) THEN
               CALL VEC_DTOD( .FALSE., EL, %VAL( FPNTR ),
     :                        %VAL( AXPNTR( 1 ) ), IERR, NERR, STATUS )

            ELSE IF ( TYPE .EQ. '_REAL' ) THEN
               CALL VEC_RTOR( .FALSE., EL, %VAL( FPNTR ),
     :                        %VAL( AXPNTR( 1 ) ), IERR, NERR, STATUS )

            END IF

*  Unmap the array.  Note that 'Error' is not allowed as the component.
            CALL NDF_AUNMP( NDF, COMP, IAXIS, STATUS )

         END IF

*  Free the work array.
         CALL PSX_FREE( FPNTR, STATUS )
      END IF

  999 CONTINUE

*  Free the NDF resources.
      CALL NDF_END( STATUS )

*  Write the closing error message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'SETAXIS_ERR',
     :     'SETAXIS: Error modifying an axis array component of an '/
     :     /'NDF.', STATUS )
      END IF

      END
