      SUBROUTINE COF_T2HDS( FUNIT, LOC, STATUS )
*+
*  Name:
*     COF_T2HDS

*  Purpose:
*     Converts an FITS binary or ASCII table into an HDS structure.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL COF_T2HDS( FUNIT, LOC, STATUS )

*  Description:
*     This routine converts a FITS binary-table or ASCII-table extension
*     into an existing HDS structure.

*  Arguments:
*     FUNIT = INTEGER (Given)
*        Logical-unit number of the FITS file.
*     LOC = CHARACTER * ( * ) (Given)
*        The HDS locator of the structure to contain the components
*        derived from the table.
*        structure.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Prior Requirements:
*     -  The FITS file should already have been opened by FITSIO, and
*     the current HDU is a BINTABLE or TABLE extension.
*     [routine_prior_requirements]...

*  Notes:
*     -  The conversion from table columns to NDF objects is as
*     follows:
*

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     AJC: Alan J. Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1997 February 28 (MJC):
*        Original version.
*     2002 March 13 (AJC):
*        Adjust dimensions for multi-dimensional CHARACTER arrays
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants
      INCLUDE 'NDF_PAR'          ! NDF__ constants

*  Arguments Given:
      INTEGER FUNIT
      CHARACTER * ( * ) LOC

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER FITSOK             ! Value of good FITSIO status
      PARAMETER( FITSOK = 0 )

*  Local Variables:
      LOGICAL BAD                ! Column array contains bad values?
      CHARACTER * ( 10 ) BTYPE ! Column TFORM data type
      CHARACTER * ( DAT__SZNAM ) COLNAM ! Column name
      INTEGER COLNUM             ! Column number
      CHARACTER * ( 48 ) COMENT  ! Comment describing column's meaning
      INTEGER CPOS               ! Character pointer in string
      CHARACTER * ( DAT__SZTYP ) CTYPE ! Column HDS data type
      INTEGER DATCOD             ! FITSIO data-type code
      CHARACTER * ( DAT__SZLOC ) DLOC ! Locator to the DATA component
      INTEGER DIMS( NDF__MXDIM + 1) ! Dimensions of the column
                                    ! +1 allows for character string length as
                                    ! first dimension for _CHAR arrays
      INTEGER I                  ! Dimensions index
      INTEGER EL                 ! Number of rows in the table
      INTEGER FSTAT              ! FITSIO status
      CHARACTER * ( 8 ) KEYWRD   ! FITS header keyword
      INTEGER NDIM               ! Dimensionality of a column
      INTEGER NFIELD             ! Number of fields in table
      INTEGER NV                 ! Number of values in a column
      INTEGER PNTR               ! Pointer to a mapped column array
      INTEGER REPEAT             ! Number of values in a field
      CHARACTER * ( 8 ) SCAKEY   ! TSCALn keyword name
      LOGICAL THERE              ! Header keyword is present?
      INTEGER WIDTH              ! Width of a character field
      CHARACTER * ( 8 )  ZERKEY  ! TZEROn keyword name

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the FITSIO status.  It's not the same as the Starlink
*  status, which is reset by the fixed part.
      FSTAT = FITSOK

*  Define the shape of the Table.
*  ==============================

*  Obtain the number of elements.
      CALL COF_GKEYI( FUNIT, 'NAXIS2', THERE, EL, COMENT, STATUS )

*  Obtain the number of fields in the table.
      CALL COF_GKEYI( FUNIT, 'TFIELDS', THERE, NFIELD, COMENT, STATUS )

      IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Write each column to the data structure.
*  ========================================

*  Loop through all the fields.
      DO COLNUM = 1, NFIELD

*  Find the column name.
*  =====================

*  Obtain the name of the column.  First form the name of the name
*  keyword for this column.
         CALL FTKEYN( 'TTYPE', COLNUM, KEYWRD, FSTAT )
         CALL COF_GKEYC( FUNIT, KEYWRD, THERE, COLNAM, COMENT, STATUS )

         IF ( THERE ) THEN

*  Find the data type of the output data column.
*  =============================================

*  Determine whether or not scaling is to be applied.  Find the data
*  type required for the output array based upon the number of
*  significant digits in the TSCALn and TZEROn keywords.  If these have
*  values of 1.0D0 and 0.0D0 respectively either explicitly, or because
*  one or both are absent, then the data type can be set to the null
*  string.  This instructs later code to use the data type specified by
*  the TFORMn keyword or the default _REAL when there is no TFORMn
*  keyword.
            CALL FTKEYN( 'TSCAL', COLNUM, SCAKEY, FSTAT )
            CALL FTKEYN( 'TZERO', COLNUM, ZERKEY, FSTAT )
            CTYPE = ' '
            CALL COF_DSTYP( FUNIT, SCAKEY, ZERKEY, CTYPE, STATUS )

*  Obtain the data type of the column, when the type has not been
*  specificed by the presence of TSCALn and TZEROn keywords.
            IF ( CTYPE .EQ. ' ' ) THEN
               CALL FTKEYN( 'TFORM', COLNUM, KEYWRD, FSTAT )
               CALL COF_GKEYC( FUNIT, KEYWRD, THERE, BTYPE, COMENT,
     :                         STATUS )

*  Convert the table type into an HDS type.
               IF ( THERE ) THEN
                  CALL COF_BN2HT( BTYPE, CTYPE, STATUS )
               ELSE
                  CTYPE = '_REAL'
               END IF
            END IF

*  Obtain the  count and width if it's a string.
            CALL FTGTCL( FUNIT, COLNUM, DATCOD, REPEAT, WIDTH, FSTAT )

*  Check for an error.  Flush the error stack.
            IF ( FSTAT .GT. FITSOK ) THEN
               CALL COF_FIOER( FSTAT, 'COF_T2HDS_SHAPE', 'FTGTCL',
     :           'Error obtaining the shape of column '//KEYWRD,
     :           STATUS )
               GOTO 999
            END IF

*  Append a string's length to the HDS type.
            IF ( CTYPE( 1:5 ) .EQ. '_CHAR' ) THEN
               CTYPE = '_CHAR*'
               CPOS = 6
               CALL CHR_PUTI( WIDTH, CTYPE, CPOS )

*  Redefine the repeat count to be the number of elements in each entry
*  in the column.
               REPEAT = REPEAT / WIDTH
            END IF

*  Define the dimensions of the column.  There should be a TDIMn card
*  whenever the array is multi-dimensional.  If the card is missing, the
*  array will be treated as a vector of length given by TFORMn
*  (=REPEAT).
            IF ( REPEAT .GT. 1 ) THEN
               CALL FTGTDM( FUNIT, COLNUM, DAT__MXDIM+1, NDIM, DIMS,
     :                      FSTAT )
               IF ( ( NDIM .GT. 2 ) .AND.
     :              ( CTYPE(1:5) .EQ. '_CHAR' ) ) THEN
*  The first dimension is the CHARACTER width - remove it
                  DO I = 2, NDIM
                     DIMS(I - 1) = DIMS(I)
                  END DO
                  NDIM = NDIM - 1
               END IF
               
*  Dealing with a scalar.
            ELSE
               NDIM = 0
            END IF

*  If there is more than one row in the table, the array dimensionality
*  has to be enlarged by one, and the additional dimension appended.
            IF ( EL .GT. 1 ) THEN
               NDIM = NDIM + 1
               DIMS( NDIM ) = EL
            END IF
            NV = REPEAT * EL

*  Have to treat scalars different from arrays, because the dimension
*  array is passed as 0.
            IF ( NDIM .EQ. 0 ) THEN

*  Create the scalar component of the extension, and get a locator to
*  the component.
               CALL DAT_NEW( LOC, COLNAM, CTYPE, 0, 0, STATUS )
               CALL DAT_FIND( LOC, COLNAM, DLOC, STATUS )

*  Map the scalar component for writing.
               IF ( CTYPE( 1:5 ) .EQ. '_CHAR' ) THEN
                  CALL DAT_MAPC( DLOC, 'WRITE', 0, 0, PNTR, STATUS )
               ELSE
                  CALL DAT_MAP( DLOC, CTYPE, 'WRITE', 0, 0, PNTR,
     :                          STATUS )
               END IF
            ELSE

*  Create the array component of the extension, and get a locator to the
*  component.
               CALL DAT_NEW( LOC, COLNAM, CTYPE, NDIM, DIMS, STATUS )
               CALL DAT_FIND( LOC, COLNAM, DLOC, STATUS )

*  Map the array component for writing.
               IF ( CTYPE( 1:5 ) .EQ. '_CHAR' ) THEN
                  CALL DAT_MAPC( DLOC, 'WRITE', NDIM, DIMS, PNTR,
     :                           STATUS )
               ELSE
                  CALL DAT_MAP( DLOC, CTYPE, 'WRITE', NDIM, DIMS, PNTR,
     :                          STATUS )
               END IF
            END IF

*  Read the column into the data array.  Call the appropriate routine
*  for the chosen type.  Null values are substituted with magic values,
*  except for strings, where the exisiting null value is retained
*  verbatim.
            IF ( CTYPE .EQ. '_UBYTE' ) THEN
               CALL FTGCVB( FUNIT, COLNUM, 1, 1, NV, VAL__BADUB,
     :                      %VAL( PNTR ), BAD, FSTAT )

            ELSE IF ( CTYPE .EQ. '_WORD' ) THEN
               CALL FTGCVI( FUNIT, COLNUM, 1, 1, NV, VAL__BADW,
     :                      %VAL( PNTR ), BAD, FSTAT )
      
            ELSE IF ( CTYPE .EQ. '_INTEGER' ) THEN
               CALL FTGCVJ( FUNIT, COLNUM, 1, 1, NV, VAL__BADI,
     :                      %VAL( PNTR ), BAD, FSTAT )
      
            ELSE IF ( CTYPE .EQ. '_REAL' ) THEN
               CALL FTGCVE( FUNIT, COLNUM, 1, 1, NV, VAL__BADR,
     :                      %VAL( PNTR ), BAD, FSTAT )
      
            ELSE IF ( CTYPE .EQ. '_DOUBLE' ) THEN
               CALL FTGCVD( FUNIT, COLNUM, 1, 1, NV, VAL__BADD,
     :                      %VAL( PNTR ), BAD, FSTAT )
      
            ELSE IF ( CTYPE( 1:5 ) .EQ. '_CHAR' ) THEN
               CALL FTGCVS( FUNIT, COLNUM, 1, 1, NV, ' ',
     :                      %VAL( PNTR ), BAD, FSTAT,
     :                      %VAL( 1 ), %VAL( WIDTH ) )
      
            END IF

*  Tidy the locator to the DATA component.
            CALL DAT_ANNUL( DLOC, STATUS )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.  Annul active locators.
            IF ( FSTAT .GT. FITSOK ) THEN
               CALL COF_FIOER( FSTAT, 'COF_T2HDS_VALUES', 'FTGCVx',
     :           'Error writing the values for column '//KEYWRD,
     :           STATUS )
               GOTO 999
            END IF

         END IF

*  Exit if something has gone wrong.  Use an error context to help
*  pinpoint the problem.  Tidy the locator.
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL MSG_SETC( 'COLUMN', KEYWRD )
            CALL ERR_REP( 'COF_T2HDS_ERR',
     :        'An error occurred when transferring column ^COLUMN of '/
     :        /'the FITS table.', STATUS )
            GOTO 999
         END IF

      END DO

  999 CONTINUE

      END
