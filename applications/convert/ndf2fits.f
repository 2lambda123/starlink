      SUBROUTINE NDF2FITS( STATUS )
*+
*  Name:
*     NDF2FITS

*  Purpose:
*     Converts NDFs into FITS files.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL NDF2FITS( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application converts one or more NDF datasets into
*     FITS-format files.  NDF2FITS stores any variance and quality
*     information in IMAGE extensions (`sub-files') within the FITS
*     file; and it uses binary tables to hold any NDF-extension data
*     present, except for the FITS-airlock extension, which may be
*     merged into the output FITS file's headers.

*     You can select which NDF array components to export to the FITS
*     file, and choose the data type of the data and variance arrays.
*     You can control whether or not to propagate extensions and
*     history information.

*  Usage:
*     ndf2fits in out [comp] [bitpix] [origin]

*  ADAM Parameters:
*     BITPIX = LITERAL (Read)
*        The FITS bits-per-pixel (BITPIX) value for each conversion.
*        This specifies the data type of the output FITS file.
*        Permitted values are: 8 for unsigned byte, 16 for signed word,
*        32 for integer, -32 for real, -64 for double precision.  There
*        are two other special values.  BITPIX=0 will cause the output
*        file to have the data type equivalent to that of the input
*        NDF.  BITPIX=-1 requests that the output file has the data
*        type corresponding to the value of the BITPIX keyword in the
*        NDF's FITS extension.  If the extension or BITPIX keyword is
*        absent, the output file takes the data type of the input
*        array.
*
*        BITPIX must be enclosed in double quotes and may be a list of 
*        comma-separated values to be applied to each conversion in
*        turn.  An error results if more values than the number of input
*        NDFs  are supplied.  If too few are given, the last value in 
*        the list applied to all the conversions.  The given values must
*        be in the file may be used.  If more than one line is required
*        to enter the information at a prompt then place a "-" at the
*        end of each line where a continuation line is desired.  [0]
*     COMP = LITERAL (Read)
*        The list of array components to attempt to transfer to each
*        FITS file.  The acceptable values are "D" for the main data
*        array "V" for variance, "Q" for quality, or any permutation
*        thereof.  The special value "A" means all components, i.e.
*        COMP="DVQ". Thus COMP="VD" requests that both the data array
*        and variance are to be converted if present.  During
*        processing at least one, if not all, of the requested
*        components must be present, otherwise an error is reported and
*        processing turns to the next input NDF.  If the data component
*        is in the list, it will always be processed first into the
*        FITS primary array.  The order of the variance and quality
*        in COMP decides the order they will appear in the FITS file.

*        COMP may be a list of comma-separated values to be applied to
*        each conversion in turn.  The list must be enclosed in double
*        quotes.  An error results if more values than the number of
*        input NDFs are supplied.  If too few are given, the last value
*        in the list is applied to the remainder of the NDFs; thus a 
*        single value is applied to all the conversions.  The given 
*        values must be in the same order as that of the input NDFs.
*        Indirection through a text file may be used.  If more than one
*        line is required to enter the information at a prompt then 
*        place a "-" at the end of each line where a continuation line
*        is desired.  ["A"]
*     ENCODING = LITERAL (Read)
*        Controls the FITS keywords which will be used to encode the 
*        World Co-ordinate System (WCS) information within the FITS 
*        header. The value supplied should be one of the encodings listed
*        in the "World Co-ordinate Systems" section below. In addition, 
*        the value "Auto" may also be supplied, in which case a suitable
*        default encoding is chosen based on the contents of the NDFs
*        FITS extension and WCS component.  ["Auto"]
*     IN = LITERAL (Read)
*        The names of the NDFs to be converted into FITS format.  It
*        may be a list of NDF names or direction specifications
*        separated by commas and enclosed in double quotes.  NDF names
*        may include wild-cards ("*", "?").  Indirection may occur
*        through text files (nested up to seven deep).  The indirection
*        character is "^".  If extra prompt lines are required, append
*        the continuation character "-" to the end of the line. 
*        Comments in the indirection file begin with the character "#".
*     NATIVE = _LOGICAL (Read)
*        If a TRUE value is given for parameter NATIVE, then World
*        Co-ordinate System (WCS) information will be written to the 
*        FITS header in the form of a `native' encoding (see "World
*        Co-ordinate Systems" below).  This will be in addition to the
*        encoding specified using parameter ENCODING, and will usually
*        result in two descriptions of the WCS information being stored
*        in the FITS header (unless the ENCODING parameter produces a
*        native encoding in which case only one native encoding is
*        stored in the header).  Including a native encoding in the
*        header will enable other AST-based software (such as FITS2NDF)
*        to reconstruct the full details of the WCS information.  The
*        other non-native encodings will usually result in some
*        information being lost.  [FALSE]
*     ORIGIN = LITERAL (Read)
*        The origin of the FITS files.  This becomes the value of the
*        ORIGIN keyword in the FITS headers.  If a null value is given
*        it defaults to "Starlink Project, U.K.".
*        [!]
*     OUT = LITERAL (Write)
*        The names for the output FITS files.  These may be enclosed in
*        double quotes and specified as a list of comma-separated names,
*        or they may be created automatically on the basis of the input
*        NDF names. To do this, the string supplied for this parameter
*        should include an asterisk "*". This character is a token which 
*        represents the name of the corresponding input NDF, but with a 
*        file type of ".fit" instead of ".sdf", and with no directory
*        specification. Thus, simply supplying "*" for this parameter
*        will create a group of output files in the current directory
*        with the same names as the input NDFs, but with file type
*        ".fit". You can also specify some simple editing to be
*        performed.  For instance, "new-*|.fit|.fits|" will add the
*        string "new-" to the start of every file name, and will
*        substitute the string ".fits" for the original string ".fit".
*     PROEXTS = _LOGICAL (Read)
*        If TRUE, the NDF extensions (other than the FITS extension)
*        are propagated to the FITS files as FITS binary-table
*        extensions, one per structure of the hierarchy.  [FALSE]
*     PROFITS = _LOGICAL (Read)
*        If TRUE, the contents of the FITS extension of the NDF are
*        merged with the header information derived from the standard
*        NDF components.  See the Notes for details of the merger. 
*        [TRUE]
*     PROHIS = _LOGICAL (Read)
*        If TRUE, any NDF history records are written to the primary
*        FITS header as HISTORY cards.  These follow the mandatory
*        headers and any merged FITS-extension headers (see parameter
*        PROFITS).  [TRUE]

*  Examples:
*     ndf2fits horse logo.fit d
*        This converts the NDF called horse to the FITS file called
*        logo.fit.  The data type of the FITS primary data array matches
*        that of the NDF's data array.  The FITS extension in the NDF
*        is merged into the FITS header of logo.fit.
*     ndf2fits horse logo.fit d proexts
*        This converts the NDF called horse to the FITS file called
*        logo.fit.  The data type of the FITS primary data array matches
*        that of the NDF's data array.  The FITS extension in the NDF
*        is merged into the FITS header of logo.fit.  In addition any
*        NDF extensions (apart from FITS) are turned into binary tables.
*        that follow the primary header and data unit.
*     ndf2fits horse logo.fit noprohis
*        This converts the NDF called horse to the FITS file called
*        logo.fit.  The data type of the FITS primary data array matches
*        that of the NDF's data array.  The FITS extension in the NDF
*        is merged into the FITS header of logo.fit.  Should horse
*        contain variance and quality arrays, these are written in IMAGE
*        extensions.  Any history information in the NDF is not relayed
*        to the FITS file.
*     ndf2fits "data/a*z" * comp=v noprofits bitpix=-32
*        This converts the NDFs with names beginning with "a" and ending
*        in "z" in the directory called data into FITS files of the same
*        name and with a file extension called .fit.  The variance
*        array becomes the data array of each FITS file.  The data type
*        of the FITS primary data array single-precision floating
*        point.  Any FITS extension in the NDF is ignored.
*     ndf2fits "abc,def" "jvp1.fit,jvp2.fit" comp=d  bitpix="16,-64"
*        This converts the NDFs called abc and def into FITS files
*        called jvp1.fit and jvp2.fit respectively.  The data type of
*        the FITS primary data array is signed integer words in
*        jvp1.fit, and double-precision floating point in jvp2.fit.  The
*        FITS extension in each NDFs is merged into the FITS header of
*        the corresponding FITS file.
*     ndf2fits horse logo.fit d native encoding="fits-wcs"
*        This is the same as the first example except that the
*        co-ordinate system information stored in the NDF's WCS
*        component is written to the FITS file twice; once using the
*        FITS-WCS headers, and once using a special set of `native'
*        keywords recognised by the AST library (see SUN/210).  The
*        native encoding provides a `loss-free' means of transferring
*        co-ordinate system information (i.e. no information is lost;
*        other encodings may cause information to be lost).  Only
*        applications based on the AST library (such as FITS2NDF) 
*        are able to interpret native encodings.

*  Notes:
*     The rules for the conversion are as follows:
*     -  The NDF main data array becomes the primary data array of the
*     FITS file if it is in value of parameter COMP, otherwise the first
*     array defined by parameter COMP will become the primary data
*     array.  A conversion from floating point to integer or to a
*     shorter integer type will cause the output array to be scaled and
*     offset, the values being recorded in keywords BSCALE and BZERO.
*     There is an offset (keyword BZERO) applied to signed byte and
*     unsigned word types to make them unsigned-byte and signed-word
*     values respectively in the FITS array (this is because FITS does
*     not support these data types).
*     -  The FITS keyword BLANK records the bad values for integer
*     output types.  Bad values in floating-point output arrays are
*     denoted by IEEE not-a-number values. 
*     -  The NDF's quality and variance arrays appear in individual
*     FITS IMAGE extensions immediately following the primary header
*     and data unit, unless that component already appears as the
*     primary data array.  The quality array will always be written as
*     an unsigned-byte array in the FITS file, regardless of the value
*     of the parameter BITPIX.
*     -  Here are details of the processing of standard items from the
*     NDF into the FITS header, listed by FITS keyword.
*        SIMPLE, EXTEND, PCOUNT, GCOUNT --- all take their default
*          values.
*        BITPIX, NAXIS, NAXISn --- are derived directly from the NDF
*          data array;
*        CRVALn, CDELTn, CRPIXn, CTYPEn, CUNITn --- are derived from
*          the NDF WCS component if possible (see "World Co-ordinate
*          Systems").  If this is not possible, and if PROFITS is TRUE, 
*          then they are copied from the NDF FITS extension.
*        OBJECT, LABEL, BUNIT --- the values held in the NDF's title,
*          label, and units components respectively are used if
*          they are defined; otherwise any values found in the FITS
*          extension are used (provided parameter PROFITS is TRUE).
*        DATE --- is created automatically.
*        ORIGIN --- inherits any existing ORIGIN card in the NDF FITS
*          extension, unless you supply a value through parameter
*          ORIGIN other than the default "Starlink Project, U.K."
*        EXTNAME --- is the array-component name when the EXTNAME
*          appears in the primary header or an IMAGE extension.  In a
*          binary-table derived from an NDF extension, EXTNAME is the
*          path of the extension within the NDF, the path separator
*          being the usual dot.  The path includes the indices to
*          elements of any array structures present; the indices are in
*          a comma-separated list within parentheses.
*        EXTLEVEL --- is the level in the hierarchical structure of the
*          extensions.  Thus a top-level extension has value 1,
*          sub-components of this extension have value 2 and so on.
*        EXTTYPE --- is the data type of the NDF extension used to
*          create a binary table.
*        EXTSHAPE --- is the shape of the NDF extension used to
*          create a binary table.  It is a comma-separated list of the
*          dimensions, and is 0 when the extension is not an array.
*        HDUCLAS1, HDUCLASn --- "NDF" and the array-component name
*          respectively.
*        LBOUNDn --- is the pixel origin for the nth dimension when
*          any of the pixel origins is not equal to 1.  (This is not a
*          standard FITS keyword.)
*        XTENSION, BSCALE, BZERO, BLANK and END --- are not propagated
*          from the NDF's FITS extension.  XTENSION will be set for
*          any extension.  BSCALE and BZERO will be defined based on
*          the chosen output data type in comparison with the NDF
*          array's type, but cards with values 1.0 and 0.0 respectively
*          are written to reserve places in the header section.  These
*          `reservation' cards are for efficiency and they can always
*          be deleted later.  BLANK is set to the Starlink standard bad
*          value corresponding to the type specified by BITPIX, but only
*          for integer types and not for the quality array.  It appears
*          regardless of whether or not there are bad values actually
*          present in the array; this is for the same efficiency reasons
*          as before.  The END card terminates the FITS header.
*       HISTORY headers are propagated from the FITS extension when
*          PROFITS is TRUE, and from the NDF history component when
*          PROHIS is TRUE.
*     -  Extension information may be transferred to the FITS file when
*     PROEXTS is TRUE.  The whole hierarchy of extensions is propagated
*     in order.  This includes substructures, and arrays of extensions
*     and substructures.  However, at present, any extension structure
*     containing only substructures is not propagated itself (as
*     zero-column tables are not permitted), although its
*     substructures may be converted.
*
*     Each extension or substructure creates a one-row binary table,
*     where the columns of the table correspond to the primitive
*     (non-structure) components.  The name of each column is the
*     component name.  The column order is the same as the component
*     order.  The shapes of multi-dimensional arrays are recorded using
*     the TDIMn keyword, where n is the column number.  The HEASARCH
*     convention for specifying the width of character arrays (keyword
*     TFORMn='rAw', where r is the total number of characters in the
*     column and w is the width of an element) is used.  The EXTNAME,
*     EXTTYPE, EXTSHAPE and EXTLEVEL keywords (see above) are written
*     to the binary-table header.

*  World Co-ordinate Systems:
*     Any co-ordinate system information stored in the WCS component of
*     the NDF is written to the FITS header using one of the following
*     encoding systems (the encodings used are determined by parameters
*     ENCODING and NATIVE):
*
*        "FITS-IRAF" --- This uses keywords CRVALi CRPIXi, CDi_j, and
*        the system commonly used by IRAF.  It is described in the
*        document "World Coordinate Systems Representations Within the
*        FITS Format" by R.J. Hanisch and D.G. Wells, 1988, available by
*        ftp from fits.cv.nrao.edu /fits/documents/wcs/wcs88.ps.Z. 
*
*        "FITS-WCS" --- This is the proposed FITS standard WCS encoding
*        scheme described in the paper "Representation of celestial
*        coordinates in FITS"
*        (http://www.cv.nrao.edu/fits/documents/wcs/wcs.html).  It is
*        very similar to "FITS-IRAF" but supports a wider range of
*        projections and co-ordinate systems.  Once the standard has
*        been agreed, this encoding should be understood by any 
*        FITS-WCS compliant software and it is likely to be adopted
*        widely for FITS data in future. 
*
*        "FITS-PC" --- This uses keywords CRVALi, CDELTi, CRPIXi, 
*        PCiiijjj, etc., as described in a previous (now superseded)
*        draft of the above FITS world co-ordinate system paper by
*        E.W.Greisen and M.Calabretta.
*
*        "FITS-AIPS" --- This uses conventions described in the document
*        "Non-linear Coordinate Systems in AIPS" by Eric W. Greisen
*        (revised 9th September, 1994), available by ftp from
*        fits.cv.nrao.edu /fits/documents/wcs/aips27.ps.Z.  It is
*        currently employed by the AIPS data-analysis facility (amongst
*        others), so its use will facilitate data exchange with AIPS. 
*        This encoding uses CROTAi and CDELTi keywords to describe axis
*        rotation and scaling.
*
*        "FITS-AIPS++" --- This is an extension to FITS-AIPS which allows
*        the use of a wider range of celestial projections, as used by
*        the AIPS++ project.
*	    
*        "DSS" --- This is the system used by the Digital Sky Survey,
*        and uses keywords AMDXn, AMDYn, PLTRAH, etc.
*
*        "NATIVE" --- This is the native system used by the AST library 
*        (see SUN/210) and provides a loss-free method for transferring
*        WCS information between AST-based application.  It allows more
*        complicated WCS information to be stored and retrieved than any
*        of the other encodings.
*
*     Values for FITS keywords generated by the above encodings will
*     always be used in preference to any corresponding keywords found 
*     in the FITS extension (even if PROFITS is TRUE). If this is not
*     what is required, the WCS component of the NDF should be erased
*     using the KAPPA command ERASE before running NDF2FITS.  Note, if 
*     PROFITS is TRUE, then any WCS-related keywords in the FITS
*     extension which are not replaced by keywords derived from the WCS
*     component may appear in the output FITS file.  If this causes a
*     problem, then PROFITS should be set to FALSE or the offending
*     keywords removed using KAPPA FITSEDIT, for example.

*  Special Formats:
*     In the general case, NDF extensions (excluding the FITS extension)
*     may be converted to one-row binary tables in the FITS file when
*     parameter PROEXTS is TRUE.  This preserves the information, but it
*     may not be accessible to the recipient's FITS reader.  Therefore,
*     in some cases it is desirable to understand the meanings of
*     certain NDF extensions, and create standard FITS products for
*     compatibility.
*
*     At present only one product is supported, but others may be added
*     as required.
*
*
*     o AAO 2dF
*
*     Standard processing is used except for the 2dF FIBRES extension
*     and its constituent structures.  The NDF may be restored from the
*     created FITS file using FITS2NDF.  The FIBRES extension converts
*     to the second binary table in the FITS file (the NDF_CLASS
*     extension appears in the first).
*
*     To propagate the OBJECT substructure, NDF2FITS creates a binary
*     table of constant width (224 bytes) with one row per fibre.  The
*     total number of rows is obtained from component NUM_FIBRES.  If a
*     possible OBJECT component is missing from the NDF, a null column
*     is written for that component.  The columns inherit the data
*     types of the OBJECT structure's components.  Column meanings and
*     units are assigned based upon information in the reference given
*     below.
*
*     The FIELD structure components are converted into additional
*     keywords of the same name in the binary-table header, with the
*     exception that components with names longer than 8 characters
*     have abbreviated keywords: UNALLOCxxx become UNAL-xxx (xxx=OBJ,
*     GUI, or SKY), CONFIGMJD becomes CONFMJD, and xSWITCHOFF become
*     xSWTCHOF (x=X or Y).  If any FIELD component is missing it is
*     ignored.
*
*     Keywords for the extension level, name, and type appear in the
*     binary-table header.

*  References:
*     Bailey, J.A. 1997, 2dF Software Report 14, version 0.5.
*     NASA Office of Standards and Technology, 1994, "A User's Guide
*       for the Flexible Image Transport System (FITS)", version 3.1.
*     NASA Office of Standards and Technology, 1995, "Definition of
*       the Flexible Image Transport System (FITS)", version 1.1.

*  Related Applications:
*     CONVERT: FITS2NDF; KAPPA: FITSDIN, FITSIN.

*  Implementation Deficiencies:
*     - There is no support for FITS World Co-ordinate Systems.
*     [routine_deficiencies]...

*  Implementation Status:
*     - All NDF data types are supported.

*  [optional_A_task_items]...
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1994 June 3 (MJC):
*        Original version.
*     1996 September 16 (MJC):
*        Corrected usage of CTYPEn (was CRTYPEn) and introduced CUNITn
*        for axis units.  Also writes CRPIXn FITS keyword when the NDF
*        has linear axis centres.
*     1997 January 13 (MJC):
*        Added PROHIS parameter and hence the ability to propagate
*        history information from the HISTORY component of the NDF
*        to the FITS headers.  NDFs from AAO's 2dF instrument are
*        recognised and the NDF extensions are converted into a
*        special binary table with one row per fibre.
*     1997 November 16 (MJC):
*        Modified to propagate the revised 2dF extensions.  Thus the
*        OBJECT extension generates wider binary tables (from 210 to
*        224 bytes).  Now propagates primitive NDF extensions to binary
*        tables.
*     18-DEC-1997 (DSB):
*        Added support for the NDF WCS component.
*     1997 January 6 (MJC):
*        Correct prologe for DATE and ORIGIN.
*      2-FEB-1998 (DSB):
*        Add ENCODING examples
*      9-NOV-1998 (DSB):
*        Added FITS-IRAF encoding. Replaced the ENCODINGS parameter with
*        the NATIVE parameter.
*     22-JUN-1999 (DSB):
*        Added ENCODING parameter
*     7-MAR-2000 (DSB):
*        Report an error if no usable input NDFs are supplied.
*     11-APR-2000 (DSB):
*        Added FITS-PC and FITS-AIPS encodings. Default encoding (if
*        ENCODING=AUTO) is now chosen on the basis of the contents of 
*        the FITS extension (because DSS and FITS-WCS can both now
*        be used to encode a TAN projection and so we need to look at
*        what encoding was used in the original data to make the choice).
*     21-AUG-2000 (DSB):
*        Converted to use NDG to access the input NDFs.
*     11-JUL-2004 (DSB):
*        Added FITS-AIPS++ encoding.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! Data-system constants
      INCLUDE 'DAT_ERR'          ! Data-system error constants
      INCLUDE 'PAR_ERR'          ! PAR_ error constants
      INCLUDE 'NDF_PAR'          ! NDF_ constants
      INCLUDE 'MSG_PAR'          ! MSG_ constants
      INCLUDE 'GRP_PAR'          ! GRP_ constants

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      LOGICAL CHR_INSET          ! True if string is one of a set
      CHARACTER * ( 2 ) CHR_NTH  ! Ordinal abbreviation

*  Local Constants:
      CHARACTER * ( 25 ) ACPERM  ! Valid permutations for the array
                                 ! components
      PARAMETER ( ACPERM = 'A,D,V,Q,DV,VD,DQ,QD,VQ,QV' )

      INTEGER BLOCKF             ! Blocking factor
      PARAMETER ( BLOCKF = 1 )

*  Local Variables:
      INTEGER ACGRP              ! Group identifier of COMPs
      INTEGER ADDED              ! Number of items added to a group
      CHARACTER * ( 8 ) ARRPRE( 3 ) ! Names of selected and present
                                 ! array components
      LOGICAL AVALID             ! True if supplied COMP is one of the
                                 ! allowed permutations
      INTEGER BITPIX             ! BITPIX code
      INTEGER BPGRP              ! Group identifier of BITPIXs
      CHARACTER * ( 3 ) CBP      ! Character form of a BITPIX value
      LOGICAL CFLAG              ! True if a group requires further
                                 ! input via continuation lines
      CHARACTER * ( 3 ) COMPS    ! Array-component code
      LOGICAL DATSEL             ! True if DATA component was selected
      CHARACTER * ( 10 ) ENCOD   ! FITS encoding requested for WCS info
      INTEGER FGROUP             ! Group identifier of default list of
                                 ! FITS files
      CHARACTER * ( 255 ) FILNAM ! Name of FITS file
      LOGICAL GOOD               ! True if all group values are valid
      INTEGER I                  ! Loop counter
      INTEGER IFILE              ! Loop counter for each input NDF
      INTEGER IGRP2              ! Group identifier of input NDFs
      INTEGER IGRP3              ! Group identifier of input purged NDFs
      INTEGER NAC                ! Number of COMP values
      INTEGER NAPRES             ! Number of array components requested
                                 ! and present in the NDF
      LOGICAL NATIVE             ! Include a NATIVE encoding of WCS info?
      INTEGER NBP                ! Number of BITPIX values
      INTEGER NDF                ! NDF identifier
      INTEGER NIFILE             ! Number of NDF files
      INTEGER NOFILE             ! Number of output files
      INTEGER OGROUP             ! Group identifier of output FITS files
      CHARACTER * ( 68 ) ORIGIN  ! Place of origin of the FITS file
      LOGICAL PROEXT             ! True if the other extensions are
                                 ! propagated
      LOGICAL PROFIT             ! True if the FITS extension is
                                 ! propagated
      LOGICAL PROHIS             ! True if history information is
                                 ! propagated
      LOGICAL QUAPRE             ! True if the QUA:LITY component is
                                 ! present
      LOGICAL QUASEL             ! True if QUALITY was selected
      LOGICAL VARPRE             ! True if the VARIANCE component is
                                 ! present
      LOGICAL VARSEL             ! True if VARIANCE was selected

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get file list and check the number of specifications.
*  =====================================================
*  Get a group containing the names of the NDFs to be processed.
      CALL CON_RGNDF( 'IN', 0, 1, '  Give more NDFs...', 
     :                 IGRP2, NIFILE, STATUS )

*  Tidy up and exit if something went wrong.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL GRP_DELET( IGRP2, STATUS )
         GOTO 999
      END IF

*  Purge any duplication from the NDFs.
      CALL GRP_PURGE( IGRP2, IGRP3, STATUS )

*  Finished with the second group so delete it.
      CALL GRP_DELET( IGRP2, STATUS )

*  Find the number of NDFs after the purge.
      CALL GRP_GRPSZ( IGRP3, NIFILE, STATUS )

*  Report an error if the group is empty.
      IF( NIFILE .EQ. 0 .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'NDF2FITS_NOFILES', 'NDF2FITS: No usable '//
     :                 'input NDFs supplied.', STATUS )
      END IF

*  Tidy up and exit if something went wrong.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL GRP_DELET( IGRP3, STATUS )
         GOTO 999
      END IF

*  At this point the output group contains the paths and names of the
*  NDFs to be processed.  Tell the user how many have been found to help
*  them supply the appropriate number of BITPIX and output file names.
      CALL MSG_SETI( 'NF', NIFILE )
      IF ( NIFILE .NE. 1 ) THEN
         CALL MSG_OUTIF( MSG__NORM, 'NOFILES', '^NF NDFs selected.',
     :                   STATUS )
      ELSE
         CALL MSG_OUTIF( MSG__NORM, 'NOFILES', '^NF NDF selected.',
     :                   STATUS )
      END IF

*  Form default list of FITS filenames.
*  ====================================

*  Create a new group to contain the output file names.
      CALL GRP_NEW( 'Default output files', FGROUP, STATUS )

*  For the group containing the list of NDFs, substitute the ".fit"
*  file extension for the existing ".sdf" extension, and remove any
*  section-defining text.  Store the modified names in the group
*  just created.
      CALL CON_GEXCH( IGRP3, '.fit', FGROUP, STATUS )

*  Tidy up and exit.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL GRP_DELET( IGRP3, STATUS )
         CALL GRP_DELET( FGROUP, STATUS )
         GOTO 999
      END IF

*  Get the names of the FITS files.
*  ================================
*
*  Use GRP to get a list of wildcarded filenames.

*  Create a new group to contain the input file names.
      CALL GRP_NEW( 'Output files', OGROUP, STATUS )

*  Allow for continuation lines.
      CFLAG = .TRUE.
      DO WHILE ( CFLAG .AND. STATUS .EQ. SAI__OK )

*  Get the list of output file names from the environment.  Allow
*  modification of the input file names.
         CALL GRP_GROUP( 'OUT', FGROUP, OGROUP, NOFILE, ADDED, CFLAG,
     :                   STATUS )

*  Cancel the parameter association in order to get more group values
*  through the parameter, unless there are no more to obtain.
         IF ( CFLAG ) CALL PAR_CANCL( 'OUT', STATUS )
      END DO

*  Finished with the group of default output file names.
      CALL GRP_DELET( FGROUP, STATUS )

*  Tidy up and exit if something went wrong.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL GRP_DELET( OGROUP, STATUS )
         CALL GRP_DELET( IGRP3, STATUS )
         GOTO 999
      END IF

*  Check that the number of input files matches the number of input
*  files.
      IF ( NOFILE .NE. NIFILE ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NI', NIFILE )
         CALL MSG_SETI( 'NO', NOFILE )
         CALL ERR_REP( 'NDF2FITS_FILECOUNT',
     :     'NDF2FITS: The number of output files (^NO) does not '/
     :     /'equal the number of input NDFs (^NI).', STATUS )

*  Tidy up and exit.
         CALL GRP_DELET( OGROUP, STATUS )
         CALL GRP_DELET( IGRP3, STATUS )
         GOTO 999
      END IF

*  Get the BITPIXs.
*  ================
*  Loop until all values are acceptable.
      GOOD = .FALSE.
  100 CONTINUE
      IF ( .NOT. GOOD ) THEN

*  Create a new group to contain the input BITPIXs.
         CALL GRP_NEW( 'BITPIX values', BPGRP, STATUS )

*  Allow for continuation lines.
         CFLAG = .TRUE.
         DO WHILE ( CFLAG .AND. STATUS .EQ. SAI__OK )

*  Get the list of BITPIXs from the environment.
            CALL GRP_GROUP( 'BITPIX', GRP__NOID, BPGRP, NBP, ADDED,
     :                      CFLAG, STATUS )

*  Cancel the parameter association in order to get more group values
*  through the parameter, unless there are no more to obtain.
            IF ( CFLAG ) CALL PAR_CANCL( 'BITPIX', STATUS )
         END DO

*  Tidy up and exit.
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL GRP_DELET( BPGRP, STATUS )
            CALL GRP_DELET( OGROUP, STATUS )
            CALL GRP_DELET( IGRP3, STATUS )
            GOTO 999
         END IF

*  Assume that the values are good for the moment.
         GOOD = .TRUE.

*  Validate the values.  First get each value, convert it to an integer,
*  and then testing that is has one of the acceptable values (0,8,16,32,
*  -32,-64).
         DO I = 1, NBP
            CALL GRP_GET( BPGRP, I, 1, CBP, STATUS )

            CALL CHR_CTOI( CBP, BITPIX, STATUS )
            IF ( ( BITPIX .NE. -1 .AND. MOD( BITPIX, 8 ) .NE. 0 )
     :           .OR. BITPIX .LT. -64 .OR. BITPIX .GT. 32
     :           .OR. STATUS .NE. SAI__OK ) THEN

*  Report an error.  When there has been a status error during
*  conversion, report the character string, otherwise report the integer
*  value.
               CALL MSG_SETI( 'I', I )
               CALL MSG_SETC( 'TH', CHR_NTH( I ) )
               IF ( STATUS .NE. SAI__OK ) THEN
                  CALL MSG_SETC( 'GM', CBP )
               ELSE
                  CALL MSG_SETI( 'GM', BITPIX )
               END IF
               CALL MSG_OUT( 'BITPIX_ERR',
     :           'The ^I^TH value "^GM" is not one of the acceptable '/
     :           /'BITPIX values: 0,-1,8,16,32,-32,-64.', STATUS )

*  Let the user have another go.  So cancel the parameter value and
*  delete the group.
               CALL PAR_CANCL( 'BITPIX', STATUS )
               CALL GRP_DELET( BPGRP, STATUS )
               GOOD = .FALSE.
               GOTO 100
            END IF
         END DO
      END IF

*  There are some special cases.  A single value means apply it to all
*  files.  If there are too few, the last value is used for the
*  remainder.  If there are too many, an error results.
      IF ( NBP .GT. NIFILE ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NI', NIFILE )
         CALL MSG_SETI( 'NB', NBP )
         CALL ERR_REP( 'NDF2FITS_FILECOUNT',
     :     'NDF2FITS: The number of BITPIX values (^NB) exceeds '/
     :     /'the number of input NDFs (^NI).', STATUS )

*  Tidy up and exit.
         CALL GRP_DELET( BPGRP, STATUS )
         CALL GRP_DELET( OGROUP, STATUS )
         CALL GRP_DELET( IGRP3, STATUS )
         GOTO 999

*  Extend the group by duplication to give the same number of values
*  as input files.  The last value is duplicated.
      ELSE IF ( NBP .LT. NIFILE ) THEN

*  Obtain the last value.
         CALL GRP_GET( BPGRP, NBP, 1, CBP, STATUS )

*  Extend the original group by adding the required number of values.
*  This may not be as efficient as having an array but it avoids getting
*  workspace or having a fixed-length array.
         DO I = NBP + 1, NIFILE
            CALL GRP_GRPEX( CBP, GRP__NOID, BPGRP, NBP, ADDED,
     :                      CFLAG, STATUS )
         END DO
      END IF

*  Get the Arrays.
*  ===============

*  Loop until all values are acceptable.
      GOOD = .FALSE.
  120 CONTINUE
      IF ( .NOT. GOOD ) THEN

*  Create a new group to contain the input array-component codes.
         CALL GRP_NEW( 'NDF array components', ACGRP, STATUS )

*  Make the group case-insensitive.
         CALL GRP_SETCS( ACGRP, .FALSE., STATUS )

*  Allow for continuation lines.
         CFLAG = .TRUE.
         DO WHILE ( CFLAG .AND. STATUS .EQ. SAI__OK )

*  Get the list of the array components from the environment.
            CALL GRP_GROUP( 'COMP', GRP__NOID, ACGRP, NAC, ADDED,
     :                      CFLAG, STATUS )

*  Cancel the parameter association in order to get more group values
*  through the parameter, unless there are no more to obtain.
            IF ( CFLAG ) CALL PAR_CANCL( 'COMP', STATUS )
         END DO

*  Tidy up and exit.
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL GRP_DELET( ACGRP, STATUS )
            CALL GRP_DELET( BPGRP, STATUS )
            CALL GRP_DELET( OGROUP, STATUS )
            CALL GRP_DELET( IGRP3, STATUS )
            GOTO 999
         END IF

*  Assume that the values are good for the moment.
         GOOD = .TRUE.

*  Validate the values.
         DO I = 1, NAC
            CALL GRP_GET( ACGRP, I, 1, COMPS, STATUS )

*  Determine if it is one of the acceptable permutations.
            AVALID = CHR_INSET( ACPERM, COMPS )
            IF ( .NOT. AVALID ) THEN

*  Report an error.
               CALL MSG_SETI( 'I', I )
               CALL MSG_SETC( 'TH', CHR_NTH( I ) )
               CALL MSG_SETC( 'GM', COMPS )
               CALL MSG_OUT( 'COMPS_ERR',
     :           'The ^I^TH value "^GM" is not one of the acceptable '/
     :           /'COMP values: A,D,V,Q,DV,DQ,QV.', STATUS )

*  Let the user have another go.  So cancel the parameter value and
*  delete the group.
               CALL PAR_CANCL( 'COMP', STATUS )
               CALL GRP_DELET( ACGRP, STATUS )
               GOOD = .FALSE.
               GOTO 120
            END IF
         END DO

*  There are some special cases.  A single value means apply it to all
*  files.  If there are too few, the last value is used for the
*  remainder.  If there are too many, an error results.
         IF ( NAC .GT. NIFILE ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI( 'NI', NIFILE )
            CALL MSG_SETI( 'NA', NAC )
            CALL ERR_REP( 'NDF2FITS_FILECOUNT',
     :        'NDF2FITS: The number of COMP values (^NA) exceeds '/
     :        /'the number of input NDFs (^NI).', STATUS )

*  Tidy up and exit.
            CALL GRP_DELET( ACGRP, STATUS )
            CALL GRP_DELET( BPGRP, STATUS )
            CALL GRP_DELET( OGROUP, STATUS )
            CALL GRP_DELET( IGRP3, STATUS )
            GOTO 999

*  Extend the group by duplication to give the same number of values
*  as input files.  The last value is duplicated.
         ELSE IF ( NAC .LT. NIFILE ) THEN

*  Obtain the last value.
            CALL GRP_GET( ACGRP, NAC, 1, COMPS, STATUS )

*  Extend the original group by adding the required number of values.
*  This may not be as efficient as having an array but it avoids getting
*  workspace or having a fixed-length array.
            DO I = NAC + 1, NIFILE
               CALL GRP_GRPEX( COMPS, GRP__NOID, ACGRP, NAC, ADDED,
     :                         CFLAG, STATUS )
            END DO
         END IF
      END IF

*  Obtain some global parameter values.
*  ====================================

*  Get the string for the ORIGIN keyword.  Null means use the default.
      CALL PAR_GET0C( 'ORIGIN', ORIGIN, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         ORIGIN = ' '
      END IF

*  Determine whether or not the FITS extension is to be merged.
      CALL PAR_GET0L( 'PROFITS', PROFIT, STATUS )

*  Determine whether or not other extensions are to be propagated.
      CALL PAR_GET0L( 'PROEXTS', PROEXT, STATUS )

*  Determine whether or not the HISTORY component is to be propagated.
      CALL PAR_GET0L( 'PROHIS', PROHIS, STATUS )

*  Abort if there has been an error.
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Get the AST encoding to use when converting WCS information to FITS
*  headers. If a null "auto" is supplied, the choice is made automatically.
*  Convert the "auto" string to a blank string which is recognised by the 
*  lower level routines.
      CALL PAR_CHOIC( 'ENCODING', 'Auto', 'Auto,FITS-IRAF,FITS-WCS,'//
     :                'FITS-PC,FITS-AIPS,FITS-AIPS++,DSS,NATIVE', 
     :                .FALSE., ENCOD, STATUS )
      IF( ENCOD .EQ. 'AUTO' ) ENCOD = ' '

*  See if a NATIVE encoding of the WCS component is to be included in
*  the FITS header, along with the encoding selected above.
      CALL PAR_GET0L( 'NATIVE', NATIVE, STATUS )

*  Process each file.
*  ==================
      DO IFILE = 1, NIFILE

*  Obtain the values for the parameters.
*  =====================================

*  Find the output NDF name.
         CALL GRP_GET( OGROUP, IFILE, 1, FILNAM, STATUS )

*  Find the BITPIX and convert it to an integer value.
         CALL GRP_GET( BPGRP, IFILE, 1, CBP, STATUS )
         CALL CHR_CTOI( CBP, BITPIX, STATUS )

*  Find the arrays to propagate to the NDF.
         CALL GRP_GET( ACGRP, IFILE, 1, COMPS, STATUS )

*  Access the NDF.
*  ===============
         CALL NDG_NDFAS( IGRP3, IFILE, 'READ', NDF, STATUS )

*  Generate the component list.
*  ============================

*  Convert the code meaning all to the code for each of the array
*  components.
         IF ( COMPS .EQ. 'A' ) COMPS = 'DVQ'

*  Assign a couple of useful variables.
         QUASEL = INDEX( COMPS, 'Q' ) .NE. 0
         VARSEL = INDEX( COMPS, 'V' ) .NE. 0

*  Assume for the moment that none of the requested array components is
*  present.  However, there is always a data array, so if this is one
*  of the requested components, then the flag will always be true.
         DATSEL = INDEX( COMPS, 'D' ) .NE. 0

*  Find what arrays are present in the NDF.  Initialise the counter of
*  the array components.
         IF ( DATSEL ) THEN
            NAPRES = 1
            ARRPRE( NAPRES ) = 'DATA'
         ELSE
            NAPRES = 0
         END IF

*  See whether or not variance is requested, and is present.
         IF ( VARSEL ) THEN
            CALL NDF_STATE( NDF, 'VARIANCE', VARPRE, STATUS )

*  It is so add it to the list of components.
            IF ( VARPRE ) THEN
               NAPRES = NAPRES + 1
               ARRPRE( NAPRES ) = 'VARIANCE'
            END IF
         END IF

*  See whether or not variance is requested, and is present.
         IF ( QUASEL ) THEN
            CALL NDF_STATE( NDF, 'QUALITY', QUAPRE, STATUS )

*  It is so add it to the list of components.
            IF ( QUAPRE ) THEN
               NAPRES = NAPRES + 1
               ARRPRE( NAPRES ) = 'QUALITY'
            END IF
         END IF

*  Report inconsistencies between the requested and present components.
*  ====================================================================

*  None are present.
*  -----------------

*  See if any of the requested arrays is present.
         IF ( NAPRES .EQ. 0 ) THEN
            STATUS = SAI__ERROR

*  Create tokens for the error message.  The data array will always be
*  present in an NDF, and so would have caused an error when it was
*  opened, so only test for the QUALITY and VARIANCE arrays.
            CALL MSG_SETI( 'I', IFILE )
            CALL MSG_SETC( 'TH', CHR_NTH( IFILE ) )
            CALL NDF_MSG( 'INDF', NDF )
            IF ( VARSEL .AND. QUASEL ) THEN
               CALL ERR_REP( 'NDF2FITS_NOCOMPB',
     :           'Neither of the selected VARIANCE and QUALITY '/
     :           /'array components are present in the ^I^TH NDF '/
     :           /'(^INDF).', STATUS )

            ELSE IF ( VARSEL ) THEN
               CALL ERR_REP( 'NDF2FITS_NOCOMPV',
     :           'The selected VARIANCE array component is not '/
     :           /'present in the ^I^TH NDF (^INDF).', STATUS )

            ELSE IF ( QUASEL ) THEN
               CALL ERR_REP( 'NDF2FITS_NOCOMPQ',
     :           'The selected QUALITY array component is not '/
     :           /'present in the ^I^TH NDF (^INDF).', STATUS )
            END IF

*  Indicate that the FITS file has not been produced.
            CALL ERR_REP( 'NDF2FITS_NOCOMP',
     :        'The output FITS file has not been produced.', STATUS )

*  Flush the error, as this needs to be regarded as fatal by the
*  on-the-fly conversion, but there may be further NDFs to convert
*  outside of this context.
            CALL ERR_FLUSH( STATUS )

*  Leave a blank line to separate sets of error messages and warnings.
            CALL MSG_BLANK( STATUS )


*  Some but not all are missing.
*  -----------------------------

*  Issue a warning error message if not all of the requested array
*  components are present, but continue to process.
         ELSE IF ( ( QUASEL .AND. .NOT. QUAPRE ) .OR.
     :             ( VARSEL .AND. .NOT. VARPRE ) ) THEN

*  Assign some tokens to make the error messages more useful.
            CALL MSG_SETI( 'I', IFILE )
            CALL MSG_SETC( 'TH', CHR_NTH( IFILE ) )
            CALL NDF_MSG( 'NDF', NDF )

*  The text of the warning message depends on which components were
*  selected, but were not present in the NDF.
            IF ( ( QUASEL .AND. .NOT. QUAPRE ) .AND.
     :           ( VARSEL .AND. .NOT. VARPRE ) ) THEN
              CALL MSG_OUT( 'NDFCOMPS_ERR',
     :           'The ^I^TH NDF (^NDF) does not have the selected '/
     :           /'QUALITY and VARIANCE components.', STATUS )

            ELSE IF ( QUASEL .AND. .NOT. QUAPRE ) THEN
               CALL MSG_OUT( 'NDFCOMPS_ERR',
     :            'The ^I^TH NDF (^NDF) does not have the selected '/
     :            /'QUALITY component.', STATUS )

            ELSE IF ( VARSEL .AND. .NOT. VARPRE ) THEN
               CALL MSG_OUT( 'NDFCOMPS_ERR',
     :           'The ^I^TH NDF (^NDF) does not have the selected '/
     :           /'VARIANCE component.', STATUS )

            END IF

*  Indicate that the FITS file will be produced regardless.
            CALL MSG_OUT( 'NDF2FITS_NOCOMP2',
     :        'The output FITS file will be produced for the '/
     :        /'remaining array components that were specified.',
     :        STATUS )

*  Leave a blank line to separate sets of error messages and warnings.
            CALL MSG_BLANK( STATUS )

*  Convert the NDF.
*  ================

*  Finally convert the NDF to the FITS file, as best we can.
            CALL COF_NDF2F( NDF, FILNAM, NAPRES, ARRPRE, BITPIX, BLOCKF,
     :                      ORIGIN, PROFIT, PROEXT, PROHIS, ENCOD, 
     :                      NATIVE, STATUS )
         ELSE

*  Convert the NDF to the FITS file.
            CALL COF_NDF2F( NDF, FILNAM, NAPRES, ARRPRE, BITPIX, BLOCKF,
     :                      ORIGIN, PROFIT, PROEXT, PROHIS, ENCOD, 
     :                      NATIVE, STATUS )
         END IF

*  Tidy the NDF.
         CALL NDF_ANNUL( NDF, STATUS )
      END DO

*  Delete the groups.
      CALL GRP_DELET( ACGRP, STATUS )
      CALL GRP_DELET( BPGRP, STATUS )
      CALL GRP_DELET( OGROUP, STATUS )
      CALL GRP_DELET( IGRP3, STATUS )

 999  CONTINUE

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'NDF2FITS_ERR',
     :     'NDF2FITS: Error converting an NDF into a FITS file.',
     :     STATUS )
      END IF

      END
