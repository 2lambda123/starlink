      SUBROUTINE POLWRTCL( STATUS )
*+
*  Name:
*     POLWRTCL

*  Purpose:
*     Creates a text file holding the contents of a specified catalogue in 
*     the form of a Tcl code frament which can be used in a Tcl applications
*     such as GAIA.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL POLWRTCL( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application creates a description of a POLPACK catalogue which 
*     can be used by the Tcl applications such as the GAIA polarimetry 
*     toolbox. The description includes the bulk data.
*
*     The desciption of the catalogue is written to an output text file
*     and takes the form of a Tcl code fragment which assigns values to
*     the following Tcl variables:
*
*      gotwcs_  : Set to 1 if RA/DEC columns are available, or 0 if
*                 not.
*      ra_col_  : If got_wcs is non-zero, ra_col is the index (zero based)
*                 of the RA column.
*      dec_col_ : If got_wcs is non-zero, dec_col is the index (zero based)
*                 of the DEC column.
*      x_col_   : The index (zero based) of the X pixel co-ordinate column
*      y_col_   : The index (zero based) of the Y pixel co-ordinate column
*      id_col_  : The index (zero based) of the column holding integer row IDs.
*      headings_: A Tcl list holding the column headings.
*      xlo_     : The minimum X pixel index value in the data
*      ylo_     : The minimum Y pixel index value in the data
*      xhi_     : The maximum X pixel index value in the data
*      yhi_     : The maximum Y pixel index value in the data
*      ncol_    : The number of columns in the catalogue
*      nrow_    : The number of rows in the catalogue
*      data_    : A Tcl list of rows. Each row is itself a Tcl list of
*                 column values.
*      ra_      : A central RA value in h:m:s format (may be blank)
*      dec_     : A central DEC value in d:m:s format (may be blank)
*      xrefpix_ : The pixel offset to ra_/dec_ from the bottom-left corner of
*                 the bounding box.
*      yrefpix_ : The pixel offset to ra_/dec_ from the bottom-left corner of
*                 the bounding box.
*      nxpix_   : No of pixels in X in bounding box 
*      nypix_   : No of pixels in Y in bounding box 
*      secpix_  : An estimate of the pixel size in arcseconds
*      equinox_ : The equinox for the RA and DEC values in the file 
*                 (e.g. "2000" - may be blank)
*      epoch_   : The epoch of observation for the RA and DEC values 
*      fmts_    : A list of Tcl formats specifications, one for each column.
*                 Column values are formatted with this format.
*      hfmts_   : A list of Tcl formats specifications, one for each column.
*                 Column headings are formatted with this format.

*  Usage:
*     polwrtcl in out 

*  ADAM Parameters:
*     IN = LITERAL (Read)
*        The name of the input catalogue. 
*        if none is provided.
*     OUT = LITERAL (Read)
*        The name of the output text file.
*     TRANS = _LOGICAL (Read)
*        If TRUE, translate column names as specified by parameters I,
*        DI, Q, DQ, etc. Otherwise, these parameters are ignored. [FALSE]
*     I = LITERAL (Read)
*        The name to be given to the column within the output text file 
*        holding the I data. To avoid any renaming of columns, retain the 
*        default value for all the following parameters. ["I"]
*     DI = LITERAL (Read)
*        The name to be given to the column within the output text file 
*        holding the DI data. ["DI"]
*     Q = LITERAL (Read)
*        The name to be given to the column within the output text file 
*        holding the Q data. ["Q"]
*     DQ = LITERAL (Read)
*        The name to be given to the column within the output text file 
*        holding the DQ data. ["DQ"]
*     U = LITERAL (Read)
*        The name to be given to the column within the output text file 
*        holding the U data. ["U"]
*     DU = LITERAL (Read)
*        The name to be given to the column within the output text file 
*        holding the DQ data. ["DU"]
*     V = LITERAL (Read)
*        The name to be given to the column within the output text file 
*        holding the V data. ["V"]
*     DV = LITERAL (Read)
*        The name to be given to the column within the output text file 
*        holding the DV data. ["DV"]

*  Copyright:
*     Copyright (C) 2000 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     6-SEP-2000 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*  Type Definitions:
      IMPLICIT NONE              ! no default typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST_ constants and function declarations
      INCLUDE 'CAT_PAR'          ! CAT_ constants 
      INCLUDE 'PRM_PAR'          ! VAL__ constants 
      INCLUDE 'CAT_ERR'          ! CAT_ error constants 

*  Status:
      INTEGER STATUS

*  Local Constants:
      INTEGER MXCOL
      PARAMETER ( MXCOL = 30 )

      INTEGER MXBAT
      PARAMETER ( MXBAT = 40000 )

      CHARACTER SYSTEM*3
      PARAMETER ( SYSTEM = 'FK5' )

      CHARACTER EQUINOX*5
      PARAMETER ( EQUINOX = 'J2000' )

      DOUBLE PRECISION DEQNOX
      PARAMETER ( DEQNOX = 2000.0 )

      CHARACTER RDHFMT*5
      PARAMETER ( RDHFMT = '%-16s' )

      CHARACTER RDFMT*7
      PARAMETER ( RDFMT = '%-16.8g' )

      CHARACTER XYFMT*6
      PARAMETER ( XYFMT = '%-8.1f' )

      CHARACTER XYHFMT*4
      PARAMETER ( XYHFMT = '%-8s' )

      CHARACTER FMT*7
      PARAMETER ( FMT = '%-13.6g' )

      CHARACTER HFMT*5
      PARAMETER ( HFMT = '%-13s' )


*  Local Variables:
      CHARACTER BJ*1             ! Besselian or Julian epoch
      CHARACTER DI*20            ! Name of the column in REF holding DI values
      CHARACTER DQ*20            ! Name of the column in REF holding DQ values
      CHARACTER DU*20            ! Name of the column in REF holding DU values
      CHARACTER DV*20            ! Name of the column in REF holding DV values
      CHARACTER EPOCH*50         ! Epoch specifier in i/p catalogue
      CHARACTER EQN*50           ! Equinox specifier in i/p catalogue
      CHARACTER FIELDS( 5 )*50   ! Individual fields of catalogue specification
      CHARACTER FNAME*80
      CHARACTER H*15             ! A translated column name
      CHARACTER HEAD( MXCOL + 2 )*15! Column names within the output catalogue
      CHARACTER I*20             ! Name of the column in REF holding I values
      CHARACTER Q*20             ! Name of the column in REF holding Q values
      CHARACTER TEXT*512         ! O/p text buffer
      CHARACTER U*20             ! Name of the column in REF holding U values
      CHARACTER V*20             ! Name of the column in REF holding V values
      DOUBLE PRECISION DEPOCH    ! Epoch
      DOUBLE PRECISION DEQN      ! Input equinox
      INTEGER BFRM               ! Base Frame from input WCS FrameSet
      INTEGER CI                 ! CAT identifier for input catalogue
      INTEGER DECCOL            ! Index of DEC column within output catalogue 
      INTEGER FD                 ! FIO identifier for output file
      INTEGER FS                 ! An AST FrameSet pointer
      INTEGER GA( 2 )            ! CAT id.s for i/p cols giving o/p RA/DEC
      INTEGER GCOL( MXCOL + 2 )  ! CAT id.s for o/p columns within i/p catalogue
      INTEGER GI                 ! A CAT component identifier
      INTEGER IAT                ! Used length of TEXT
      INTEGER ICOL               ! Column index
      INTEGER IFRM               ! Index of SkyFrame
      INTEGER IPW1               ! Pointer to work space
      INTEGER IPW2               ! Pointer to work space
      INTEGER IPW3               ! Pointer to work space
      INTEGER ITEMP              ! Temporary storage
      INTEGER IWCS               ! The WCS FrameSet from the input catalogue
      INTEGER MAP                ! AST Mapping used to create new RA/DEC values
      INTEGER NCOL               ! No. of columns in output catalogue
      INTEGER NROW               ! No. of rows in output catalogue
      INTEGER RACOL              ! Index of RA column within output catalogue 
      INTEGER SKYFRM             ! An AST SkyFrame pointer
      INTEGER SZBAT              ! Size of each batch
      INTEGER XCOL               ! Index of X column within output catalogue 
      INTEGER YCOL               ! Index of Y column within output catalogue 
      LOGICAL GOTRD              ! Will o/p catalogue have RA and DEC columns?
      LOGICAL MAKERD             ! Will we be creating new RA/DEC o/p columns?
      LOGICAL NULL               ! Is the stored value null?
      LOGICAL TRANS              ! Translate column names?
      LOGICAL VERB               ! Verose errors required?
      REAL LBND( 2 )             ! Lower bounds of X/Y bounding box
      REAL UBND( 2 )             ! Upper bounds of X/Y bounding box
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  See if the user wants verbose error messages.
      CALL KPG1_VERB( VERB, 'POLPACK', STATUS )

*  Open the input catalogue, and get its name.
      CALL CTG_ASSO1( 'IN', VERB, 'READ', CI, FIELDS, STATUS )

*  Get the number of rows in the catalogue.
      CALL CAT_TROWS( CI, NROW, STATUS ) 

*  Get the number of columns in the supplied catalogue.
      CALL CAT_TCOLS( CI, CAT__GPHYS, NCOL, STATUS ) 
      IF( NCOL .GT. MXCOL .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'N', NCOL )
         CALL MSG_SETI( 'M', MXCOL )
         CALL ERR_REP( 'POLWRTCL_ERR1', 'Too many columns (^N) in '//
     :                 'catalogue ''$IN''. No more than ^M are '//
     :                 'allowed.', STATUS )
      END IF

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Get a list of column identifiers and headings from the input catalogue. 
*  Note, the indices of the X, Y, RA and DEC columns. 
      XCOL = 0
      YCOL = 0
      RACOL = 0
      DECCOL = 0

      DO ICOL = 1, NCOL

         CALL CAT_TNDNT( CI, CAT__FITYP, ICOL, GCOL( ICOL ), STATUS  )
         CALL CAT_TIQAC( GCOL( ICOL ), 'NAME', HEAD( ICOL ), STATUS )

         IF( HEAD( ICOL ) .EQ. 'X' ) THEN
            XCOL = ICOL

         ELSE IF( HEAD( ICOL ) .EQ. 'Y' ) THEN
            YCOL = ICOL

         ELSE IF( HEAD( ICOL ) .EQ. 'RA' ) THEN
            RACOL = ICOL

         ELSE IF( HEAD( ICOL ) .EQ. 'DEC' ) THEN
            DECCOL = ICOL

         END IF

      END DO

*  Abort if no X or Y column was found.
      IF( STATUS .EQ. SAI__OK ) THEN 
         IF( XCOL .EQ. 0 ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'POLWRTCL_ERR2', 'Input catalogue ''$IN'' '//
     :                    'has no ''X'' column.', STATUS )
            GO TO 999

         ELSE IF( YCOL .EQ. 0 ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'POLWRTCL_ERR3', 'Input catalogue ''$IN'' '//
     :                    'has no ''Y'' column.', STATUS )
            GO TO 999
         END IF
      END IF

*  Re-arrange them so that X become column 1 in the output catalogue.
      ITEMP = GCOL( XCOL )
      DO ICOL = XCOL, 2, -1 
         HEAD( ICOL ) = HEAD( ICOL - 1 )
         GCOL( ICOL ) = GCOL( ICOL - 1 )
      END DO
      HEAD( 1 ) = 'X'
      GCOL( 1 ) = ITEMP

      IF( YCOL .LT. XCOL ) YCOL = YCOL + 1
      IF( RACOL .GT.0 .AND. RACOL .LT. XCOL ) RACOL = RACOL + 1
      IF( DECCOL .GT.0 .AND. DECCOL .LT. XCOL ) DECCOL = DECCOL + 1
      XCOL = 1

*  Re-arrange them so that Y become column 2 in the output catalogue.
      ITEMP = GCOL( YCOL )
      DO ICOL = YCOL, 3, -1 
         HEAD( ICOL ) = HEAD( ICOL - 1 )
         GCOL( ICOL ) = GCOL( ICOL - 1 )
      END DO
      HEAD( 2 ) = 'Y'
      GCOL( 2 ) = ITEMP

      IF( RACOL .GT.0 .AND. RACOL .LT. YCOL ) RACOL = RACOL + 1
      IF( DECCOL .GT.0 .AND. DECCOL .LT. YCOL ) DECCOL = DECCOL + 1
      YCOL = 2

*  Assume for the moment that the output catalogue will contain RA/DEC
*  columns.
      GOTRD = .TRUE.

*  Assume for the moment that we do not need to create RA DEC columns
*  because usable ones already exist in the catalogue.
      MAKERD = .FALSE.

*  Abort if an error has occurred.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  If the catalogue contains columns holding RA/DEC coordinates...
      IF( RACOL .GT. 0 .AND. DECCOL .GT. 0 ) THEN

*  See if the catalogue contains an EPOCH parameter. 
         CALL CAT_TIDNT( CI, 'EPOCH', GI, STATUS ) 
         IF( STATUS .EQ. CAT__NOCMP ) THEN
            CALL ERR_ANNUL( STATUS )
            EPOCH = ' '
         ELSE IF( STATUS .EQ. SAI__OK ) THEN
            CALL CAT_EGT0F( GI, EPOCH, NULL, STATUS )
            CALL CAT_TRLSE( GI, STATUS )
         END IF                     

*  Get their equinox from the catalogue EQUINOX parameter. Assume default if 
*  no value is available.
         CALL CAT_TIDNT( CI, 'EQUINOX', GI, STATUS ) 
         IF( STATUS .EQ. CAT__NOCMP ) THEN
            CALL ERR_ANNUL( STATUS )

*  If available, get its formatted value.
         ELSE IF( STATUS .EQ. SAI__OK ) THEN
            CALL CAT_EGT0F( GI, EQN, NULL, STATUS )
            CALL CAT_TRLSE( GI, STATUS )

*  Abort if an error has occurred.
            IF( STATUS .NE. SAI__OK ) GO TO 999

*  If null, continue with the assumption of the default.
            IF( .NOT. NULL ) THEN

*  Extract any B/J specifier in the first character.
               BJ = EQN( 1:1 )
               CALL CHR_UCASE( BJ )
               IF( BJ .EQ. 'B' .OR. BJ .EQ. 'J' ) THEN
                  EQN( 1:1 ) = ' '
               ELSE 
                  BJ = ' '
               END IF

*  Extract the numerical value.
               CALL CHR_CTOD( EQN, DEQN, STATUS )

*  Assume default if the numerical EQUNOX string was bad.
               IF( STATUS .NE. SAI__OK ) THEN
                  CALL MSG_SETC( 'EQ', EQUINOX )
                  CALL ERR_REP( 'POLWRTCL_ERR3', 'Bad EQUINOX value '//
     :                          '''^E'' found in catalogue ''$IN''. '//
     :                          'Assuming a value of ^EQ.', STATUS )
                  CALL ERR_FLUSH( STATUS )

*  Otherwise...
               ELSE 

*  If no B/J specifier was included, use the 1984 rule.
                  IF( BJ .EQ. ' ' ) THEN
                     IF( DEQN .LT. 1984.0 ) THEN
                        BJ = 'B' 
                     ELSE
                        BJ = 'J'
                     END IF
                  END IF

*  The existing RA/DEC values are only directly usable if they have the
*  required equinox.  Otherwise we create new RA/DEC columns by mapping the 
*  existing RA/DEC columns. Set flags to indicate this.
                  IF( BJ .NE. 'J' .OR. DEQN .NE. DEQNOX ) THEN
                     MAKERD = .TRUE.

*  Save identifiers for the columns within the input catalogue from which
*  the new RA and DEC columns will be derived.
                     GA( 1 ) = GCOL( RACOL )
                     GA( 2 ) = GCOL( DECCOL )

*  Create a default AST SkyFrame.
                     SKYFRM = AST_SKYFRAME( ' ', STATUS )
                  
*  Assume supplied RA/DEC values are FK5 if a Julian equinox was supplied. 
*  FK4 otherwise.
                     IF( BJ .EQ. 'J' ) THEN
                        CALL AST_SETC( SKYFRM, 'SYSTEM', 'FK5', STATUS )
                     ELSE 
                        CALL AST_SETC( SKYFRM, 'SYSTEM', 'FK5', STATUS )
                     END IF

*  Set the equinox of the SkyFrame.
                     CALL AST_SETC( SKYFRM, 'EQUINOX', EQN, STATUS )

*  If the catalogue contains an EPOCH parameter, copy its value to the 
*  SkyFrame. Otherwise, retrieve the default epoch value.
                     IF( EPOCH .NE. ' ' ) THEN
                        CALL AST_SETC( SKYFRM, 'EPOCH', EPOCH, STATUS )
                     ELSE
                        EPOCH = AST_GETC( SKYFRM, 'EPOCH', STATUS )
                     END IF

*  Find a Mapping from the supplied system to the required system.
                     FS = AST_FINDFRAME( SKYFRM, AST_SKYFRAME( 
     :                                   'System='//SYSTEM//
     :                                   ',Equinox='//EQUINOX, 
     :                                   STATUS ), ' ', STATUS ) 
               
                     MAP = AST_GETMAPPING( FS, AST__BASE, AST__CURRENT,
     :                                     STATUS )

                  END IF
               END IF
            END IF
         END IF

*  If the catalogue does not contain RA/DEC columns...
      ELSE         

*  Assume for the moment that the output catalogue will not contain
*  RA/DEC columns.
         GOTRD = .FALSE.

*  See if the catalogue has a WCS FrameSet 
         CALL POL1_GTCTW( CI, IWCS, STATUS )

*  If so, check the Base Frame is two dimensional and has axis symbols 
*  of "X" and "Y". If not, annul the FrameSet since it cannot be used.
         IF( IWCS .NE. AST__NULL ) THEN
            BFRM = AST_GETFRAME( IWCS, AST__BASE, STATUS )

            IF( AST_GETI( BFRM, 'NAXES', STATUS ) .NE. 2 ) THEN
               CALL AST_ANNUL( IWCS, STATUS )

            ELSE IF( AST_GETC( BFRM, 'SYMBOL(1)', STATUS ) .NE. 'X' .OR.
     :             AST_GETC( BFRM, 'SYMBOL(2)', STATUS ) .NE. 'Y' ) THEN
               CALL AST_ANNUL( IWCS, STATUS )

*  See if the FrameSet contains a SKY Frame. If the input has more than 2
*  axes (there will often be a third axis 'stokes'), this call will
*  look for a SkyFrame within the CmpFrame and append a copy of it to the
*  end of the FrameSet so that the following call to AST_CONVERT will be
*  able to use it.
            ELSE
               CALL KPG1_ASFFR( IWCS, 'SKY', IFRM, STATUS )
               IF( IFRM .EQ. AST__NOFRAME ) THEN
                  CALL AST_ANNUL( IWCS, STATUS )
               END IF
            END IF
         END IF


*  If the FrameSet passed the above tests...
         IF( IWCS .NE. AST__NULL ) THEN

*  Attempt to get a FrameSet connecting X/Y to RA/DEC.
            CALL AST_SETI( IWCS, 'CURRENT', 
     :                     AST_GETI( IWCS, 'BASE', STATUS ),
     :                     STATUS )
            FS = AST_CONVERT( IWCS, AST_SKYFRAME( 
     :                        'System='//SYSTEM//',Equinox='//EQUINOX, 
     :                        STATUS ), ' ', STATUS ) 

*  If succesfull...
            IF( FS .NE. AST__NULL ) THEN

*  Get the epoch of the SkyFrame.
               EPOCH = AST_GETC( FS, 'EPOCH', STATUS )

*  Get the Mapping from X/Y to RA/DEC.
               MAP = AST_GETMAPPING( FS, AST__BASE, AST__CURRENT, 
     :                               STATUS )

*  Set the flags to indicate that new RA/DEC columns should be created on 
*  the basis of existing X/Y columns. 
               MAKERD = .TRUE.
               GOTRD = .TRUE.

*  Save identifiers for the columns within the input catalogue from which
*  the new RA and DEC columns will be derived.
               GA( 1 ) = GCOL( XCOL )
               GA( 2 ) = GCOL( YCOL )

*  Append RA DEC columns to the column headings arrays.
               HEAD( NCOL + 1 ) = 'RA'
               GCOL( NCOL + 1 ) = CAT__NOID
               RACOL = NCOL + 1

               HEAD( NCOL + 2 ) = 'DEC'
               GCOL( NCOL + 2 ) = CAT__NOID
               DECCOL = NCOL + 2

               NCOL = NCOL + 2
            END IF

         END IF

      END IF

*  If the output catalogue will contain RA and DEC columns, re-arrange the 
*  column headings so that RA and DEC are columns 3 and 4.
      IF( GOTRD ) THEN
         ITEMP = GCOL( RACOL )
         DO ICOL = RACOL, 4, -1 
            HEAD( ICOL ) = HEAD( ICOL - 1 )
            GCOL( ICOL ) = GCOL( ICOL - 1 )
         END DO
         HEAD( 3 ) = 'RA'
         GCOL( 3 ) = ITEMP
   
         IF( DECCOL .LT. RACOL ) DECCOL = DECCOL + 1
         RACOL = 3

         ITEMP = GCOL( DECCOL )
         DO ICOL = DECCOL, 5, -1 
            HEAD( ICOL ) = HEAD( ICOL - 1 )
            GCOL( ICOL ) = GCOL( ICOL - 1 )
         END DO
         HEAD( 4 ) = 'DEC'
         GCOL( 4 ) = ITEMP
   
         DECCOL = 4

      END IF

*  Open the output text file.
      CALL FIO_ASSOC( 'OUT', 'WRITE', 'LIST', 256, FD, STATUS )
      CALL FIO_FNAME( FD, FNAME, STATUS ) 
      CALL MSG_SETC( 'F', FNAME )

*  Write X & Y column numbers (zero based) to the output text file.
      TEXT = 'set x_col_ '
      IAT = 11
      CALL CHR_PUTI( XCOL - 1, TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

      TEXT = 'set y_col_ '
      IAT = 11
      CALL CHR_PUTI( YCOL - 1, TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

*  Write a flag to the output text file indicating if RA/DEC values 
*  are available. If they are, write the RA and DEC column indices out.
      IF( GOTRD ) THEN
         TEXT = 'set ra_col_ '
         IAT = 12
         CALL CHR_PUTI( RACOL - 1, TEXT, IAT )
         CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

         TEXT = 'set dec_col_ '
         IAT = 13
         CALL CHR_PUTI( DECCOL - 1, TEXT, IAT )
         CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

         CALL FIO_WRITE( FD, 'set gotwcs_ 1', STATUS )
      ELSE
         CALL FIO_WRITE( FD, 'set gotwcs_ 0', STATUS )
      END IF

*  Write out the index of the row ID column. This is an extra column
*  added by this application.
      TEXT = 'set id_col_ '
      IAT = 12
      CALL CHR_PUTI( NCOL, TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

*  See if column names are to be translated.
      CALL PAR_GET0L( 'TRANS', TRANS, STATUS )

*  If so, get the names of the columns holding the Stokes parameters and 
*  their errors.
      IF( TRANS ) THEN
         CALL PAR_GET0C( 'I', I, STATUS )
         CALL PAR_GET0C( 'Q', Q, STATUS )
         CALL PAR_GET0C( 'U', U, STATUS )
         CALL PAR_GET0C( 'V', V, STATUS )
         CALL PAR_GET0C( 'DI', DI, STATUS )
         CALL PAR_GET0C( 'DQ', DQ, STATUS )
         CALL PAR_GET0C( 'DU', DU, STATUS )
         CALL PAR_GET0C( 'DV', DV, STATUS )
      END IF

*  Write a list of the column headings out to the text file, translating
*  the column names.
      CALL FIO_WRITE( FD, 'set headings_ { \\', STATUS )

      DO ICOL = 1, NCOL
         TEXT = '   '
         IAT = 3

         IF( .NOT. TRANS ) THEN 
            H = HEAD( ICOL ) 
         ELSE IF( HEAD( ICOL ) .EQ. 'I' ) THEN 
            H = I
         ELSE IF( HEAD( ICOL ) .EQ. 'DI' ) THEN 
            H = DI
         ELSE IF( HEAD( ICOL ) .EQ. 'Q' ) THEN 
            H = Q
         ELSE IF( HEAD( ICOL ) .EQ. 'DQ' ) THEN 
            H = DQ
         ELSE IF( HEAD( ICOL ) .EQ. 'U' ) THEN 
            H = U
         ELSE IF( HEAD( ICOL ) .EQ. 'DU' ) THEN 
            H = DU
         ELSE IF( HEAD( ICOL ) .EQ. 'V' ) THEN 
            H = V
         ELSE IF( HEAD( ICOL ) .EQ. 'DV' ) THEN 
            H = DV
         ELSE
            H = HEAD( ICOL )
         END IF

         CALL CHR_APPND( H, TEXT, IAT )
         CALL CHR_APPND( ' \\', TEXT, IAT )
         CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )
      END DO

      CALL FIO_WRITE( FD, ' ID }', STATUS )

*  Write a list of the heading formats out to the text file.
      CALL FIO_WRITE( FD, 'set hfmts_ { \\', STATUS )

      DO ICOL = 1, NCOL + 1
         TEXT = '   '
         IAT = 3
         IF( ICOL .EQ. XCOL .OR. ICOL .EQ. YCOL ) THEN
            CALL CHR_APPND( XYHFMT, TEXT, IAT )
         ELSE IF( ICOL .EQ. RACOL .OR. ICOL .EQ. DECCOL ) THEN
            CALL CHR_APPND( RDHFMT, TEXT, IAT )
         ELSE 
            CALL CHR_APPND( HFMT, TEXT, IAT )
         END IF
         CALL CHR_APPND( ' \\', TEXT, IAT )
         CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )
      END DO

      CALL FIO_WRITE( FD, '}', STATUS )

*  Write a list of the column formats out to the text file.
      CALL FIO_WRITE( FD, 'set fmts_ { \\', STATUS )

      DO ICOL = 1, NCOL + 1
         TEXT = '   '
         IAT = 3
         IF( ICOL .EQ. XCOL .OR. ICOL .EQ. YCOL ) THEN
            CALL CHR_APPND( XYFMT, TEXT, IAT )
         ELSE IF( ICOL .EQ. RACOL .OR. ICOL .EQ. DECCOL ) THEN
            CALL CHR_APPND( RDFMT, TEXT, IAT )
         ELSE 
            CALL CHR_APPND( FMT, TEXT, IAT )
         END IF
         CALL CHR_APPND( ' \\', TEXT, IAT )
         CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )
      END DO

      CALL FIO_WRITE( FD, '}', STATUS )

*  Write out the number of rows and columns. Add one on for the ID column
*  added by thgis program.
      TEXT = 'set nrow_ '
      IAT = 10
      CALL CHR_PUTI( NROW, TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

      TEXT = 'set ncol_ '
      IAT = 10
      CALL CHR_PUTI( NCOL + 1, TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

*  Write out the equinox.
      TEXT = 'set equinox_ '
      IAT = 13
      CALL CHR_PUTD( DEQNOX, TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

*  Write out the epoch.
      TEXT = 'set epoch_ '
      IAT = 12
      IF( EPOCH .NE. ' ' ) THEN
         CALL CHR_APPND( EPOCH, TEXT, IAT )
      ELSE
         CALL CHR_APPND( EPOCH, '" "', IAT )
      END IF
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

*  Determine the size of each batch.
      SZBAT = MIN( NROW, MXBAT )

*  Allocate work space.
      CALL PSX_CALLOC( SZBAT*2, '_DOUBLE', IPW1, STATUS )
      CALL PSX_CALLOC( SZBAT*2, '_DOUBLE', IPW2, STATUS )
      IF( GOTRD ) THEN
         CALL PSX_CALLOC( SZBAT*( NCOL - 4 ), '_REAL', IPW3, STATUS )
      ELSE
         CALL PSX_CALLOC( SZBAT*( NCOL - 2 ), '_REAL', IPW3, STATUS )
      END IF

*  Write values to the output file.
      CALL POL1_WRTCL( CI, GOTRD, MAKERD, MAP, NCOL, GCOL, NROW, 
     :                 FD, SZBAT, LBND, UBND, %VAL( IPW1 ), 
     :                 %VAL( IPW2 ), %VAL( IPW3 ), STATUS )

*  Free the work space.
      CALL PSX_FREE( IPW1, STATUS )
      CALL PSX_FREE( IPW2, STATUS )
      CALL PSX_FREE( IPW3, STATUS )

*  Write the bounding box out to the output text file.
      TEXT = 'set xlo_ '
      IAT = 9
      CALL CHR_PUTI( NINT( 0.5 + LBND( 1 ) ), TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

      TEXT = 'set xhi_ '
      IAT = 9
      CALL CHR_PUTI( NINT( 0.5 + UBND( 1 ) ), TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

      TEXT = 'set ylo_ '
      IAT = 9
      CALL CHR_PUTI( NINT( 0.5 + LBND( 2 ) ), TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

      TEXT = 'set yhi_ '
      IAT = 9
      CALL CHR_PUTI( NINT( 0.5 + UBND( 2 ) ), TEXT, IAT )
      CALL FIO_WRITE( FD, TEXT( : IAT ), STATUS )

*  Arrive here if an error occurs.
 999  CONTINUE

*  Close the output text file.
      CALL FIO_ANNUL( FD, STATUS )

*  Close the input catalogue.
      CALL CAT_TRLSE( CI, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'POLWRTCL_ERR', 'POLWRTCL: Error producing a '//
     :                 'Tcl description of a polarization catalogue.',
     :                 STATUS )
      END IF

      END
