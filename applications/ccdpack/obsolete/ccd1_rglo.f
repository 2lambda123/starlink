      SUBROUTINE CCD1_RGLO( GOTLG2, LOGTO, GOTLGN, LOGNAM, GOTADC,
     :                      ADC, GOTNOI, RNOISE, GOTEXT, EXTENT,
     :                      GOTBDS, BOUNDS, NBOUND, GOTDIR, DIRECT,
     :                      GOTDEF, DEFER, GOTMSK, MSKNAM, GOTSAT,
     :                      SATUR, GOTSPR, SETSAT, GOTSVL, SATVAL,
     :                      GOTPRE, PRESER, GOTGEN, GENVAR, GOTNAM,
     :                      NDFS, GOTSET, USESET, GOTFLA, FLAT, GOTBIA,
     :                      BIAS, GOTCAL, CAL, STATUS )

*+
*  Name:
*     CCD1_RGLO

*  Purpose:
*     To report the global parameters.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_RGLO( GOTLG2, LOGTO, GOTLGN, LOGNAM, GOTADC,
*                     ADC, GOTNOI, RNOISE, GOTEXT, EXTENT,
*                     GOTBDS, BOUNDS, NBOUND, GOTDIR, DIRECT,
*                     GOTDEF, DEFER, GOTMSK, MSKNAM, GOTSAT,
*                     SATUR, GOTSPR, SETSAT, GOTSVL, SATVAL,
*                     GOTPRE, PRESER, GOTGEN, GENVAR, GOTNAM,
*                     NDFS, GOTSET, USESET, GOTFLA, FLAT, GOTBIA, BIAS,
*                     GOTCAL, CAL, STATUS )

*  Description:
*     The routine writes out the global parameters as set up by
*     CCDSETUP and accessed by CCDSHOW to the user echoing the values
*     to the log file if it has been initialised.

*  Arguments:
*     GOTLG2 = LOGICAL (Given)
*        Whether we have a LOGTO value or not. This specifies where
*        logfile information will be written.
*     LOGTO = CHARACTER * ( * ) (Given)
*        Where logfile information will be written to.
*     GOTLGN = LOGICAL (Given)
*        Whether we have a LOGFILE value or not.
*     LOGNAM = CHARACTER * ( * ) (Given)
*        The name of the logfile is one is being used.
*     GOTADC = LOGICAL (Given)
*        Whether an ADC factor has been given or not.
*     ADC = DOUBLE PRECISION (Given)
*        The ADC conversion factor.
*     GOTNOI = LOGICAL (Given)
*        Set true if the readout noise value has been set.
*     RNOISE = DOUBLE PRECISION (Given)
*        The readout noise value.
*     GOTEXT = LOGICAL (Given)
*        Set true if the CCD extent has been set.
*     EXTENT( 4 )= INTEGER(Given)
*        The values of the extent of the useful CCD area, in pixel
*        coordinates..
*     GOTBDS = LOGICAL (Given)
*        Set true if the bias strips values have been set.
*     BOUNDS( NBOUND ) = INTEGER (Given)
*        Upper and lower bounds of the bias strips (in pairs along the
*        readout direction).
*     NBOUND = INTEGER (Given)
*        The number of bounds.
*     GOTDIR = LOGICAL (Given)
*        Set true if the readout direction has been set.
*     DIRECT = INTEGER (Given)
*        The readout direction (1 or 2).
*     GOTDEF = LOGICAL (Given)
*        Set true if the deferred charage value has been set.
*     DEFER = DOUBLE PRECISION (Given)
*        The deferred charge value.
*     GOTMSK = LOGICAL (Given)
*        Set true if the mask file has been set.
*     MSKNAM = CHARACTER * ( * ) (Given)
*        The name of the mask file.
*     GOTSAT = LOGICAL (Given)
*        Set true if a preference for detecting saturated pixels
*        has been given.
*     SATUR = LOGICAL (Given)
*        Whether or not to detect saturated pixels.
*     GOTSPR = LOGICAL (Given)
*        Set true if a preference for how to handle satured pixels
*        has been given.
*     SETSAT = LOGICAL (Given)
*        Whether or not saturated pixels will be set to the saturation
*        value.
*     GOTSVL = LOGICAL (Given)
*        Set true of a saturation value has been supplied.
*     SATVAL = DOUBLE PRECISION (Given)
*        The saturation value.
*     GOTPRE = LOGICAL (Given)
*        Set true if preserve data type has been set.
*     PRESER = LOGICAL (Given)
*        Flag indicating whether the input data is to be preserved on
*        output whenever possible.
*     GOTGEN = LOGICAL (Given)
*        Set true if variances are to be generated flag is set.
*     GENVAR = LOGICAL (Given)
*        Flag indicating whether the variances are to be generated.
*     GOTNAM = LOGICAL (Given)
*        Set true if INLIST prompts mode is specified.
*     NDFS = LOGICAL (Given)
*        Flag indicating whether INLIST prompts expect NDF names or not.
*     GOTSET = LOGICAL (Given)
*        Set true if USESET is specified.
*     USESET = LOGICAL (Given)
*        Flag indicating whether to use Set header info if available.
*     GOTFLA = LOGICAL (Given)
*        Set true if a global flatfield name exists.
*     FLAT = CHARACTER * ( * ) (Given)
*        Name of the global flatfield.
*     GOTBIA = LOGICAL (Given)
*        Set true if a global bias name exists.
*     BIAS = CHARACTER * ( * ) (Given)
*        Name of the global bias.
*     GOTCAL = LOGICAL (Given)
*        Set true if a global calibration name exists.
*     CAL = CHARACTER * ( * ) (Given)
*        Name of the global calibration NDF.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     MBT: Mark Taylor (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-APR-1992 (PDRAPER):
*        Original version.
*     20-JUL-1993 (PDRAPER):
*        Added version 1.0 parameter NDFNAMES and LOGTO, LOGFILE.
*     22-JUL-1993 (PDRAPER):
*        Added global frame names.
*     28-JAN-1994 (PDRAPER):
*        Added saturation extensions.
*     17-MAR-1995 (PDRAPER):
*        Now writes deferred charge as DBLE value.
*     26-MAR-2001 (MBT):
*        Added USESET parameter.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Status:
      INTEGER STATUS             ! Global status

*  Arguments Given:
      CHARACTER * ( * ) BIAS
      CHARACTER * ( * ) CAL
      CHARACTER * ( * ) FLAT
      CHARACTER * ( * ) LOGNAM
      CHARACTER * ( * ) LOGTO
      CHARACTER * ( * ) MSKNAM
      DOUBLE PRECISION ADC
      DOUBLE PRECISION DEFER
      DOUBLE PRECISION RNOISE
      DOUBLE PRECISION SATVAL
      INTEGER BOUNDS( 4 )
      INTEGER DIRECT
      INTEGER EXTENT( 4 )
      INTEGER NBOUND
      LOGICAL GENVAR
      LOGICAL GOTADC
      LOGICAL GOTBDS
      LOGICAL GOTBIA
      LOGICAL GOTCAL
      LOGICAL GOTDEF
      LOGICAL GOTDIR
      LOGICAL GOTEXT
      LOGICAL GOTFLA
      LOGICAL GOTGEN
      LOGICAL GOTLG2
      LOGICAL GOTLGN
      LOGICAL GOTMSK
      LOGICAL GOTNAM
      LOGICAL GOTNOI
      LOGICAL GOTPRE
      LOGICAL GOTSAT
      LOGICAL GOTSET
      LOGICAL GOTSPR
      LOGICAL GOTSVL
      LOGICAL NDFS
      LOGICAL PRESER
      LOGICAL SATUR
      LOGICAL SETSAT
      LOGICAL USESET

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Write out the values which have been set.

*  ADC conversion factor.
      IF ( GOTADC ) THEN
         CALL MSG_SETR( 'RGLO_ADC', REAL( ADC ) )
         CALL CCD1_MSG( ' ',
     :'  Global ADC factor                             : ^RGLO_ADC',
     :   STATUS )
      END IF

*  Extent of CCD useful area.
      IF ( GOTEXT ) THEN
         CALL MSG_SETI( 'RGLO_B1', EXTENT( 1 ) )
         CALL MSG_SETI( 'RGLO_B2', EXTENT( 2 ) )
         CALL MSG_SETI( 'RGLO_B3', EXTENT( 3 ) )
         CALL MSG_SETI( 'RGLO_B4', EXTENT( 4 ) )
         CALL CCD1_MSG( ' ',
     :'  Global output NDF extent (xmin:xmax,ymin:ymax):'//
     :' (^RGLO_B1:^RGLO_B2,^RGLO_B3:^RGLO_B4)', STATUS )
      END IF

*  Readout noise value.
      IF ( GOTNOI ) THEN
         CALL MSG_SETR( 'RNOISE_VAL', REAL( RNOISE ) )
         CALL CCD1_MSG( ' ',
     :'  Global readout noise (ADUs)                   : ^RNOISE_VAL',
     :   STATUS )
      END IF

*  Bias strip bounds.
      IF ( GOTBDS ) THEN
         CALL MSG_SETI( 'RGLO_B1', BOUNDS( 1 ) )
         CALL MSG_SETI( 'RGLO_B2', BOUNDS( 2 ) )
         IF ( NBOUND .GT. 2 ) THEN
            CALL MSG_SETI( 'RGLO_B3', BOUNDS( 3 ) )
            CALL MSG_SETI( 'RGLO_B4', BOUNDS( 4 ) )
            CALL CCD1_MSG( ' ',
     :'  Global bias strip bounds                      : '//
     :'(^RGLO_B1:^RGLO_B2,^RGLO_B3:^RGLO_B4) ', STATUS )
         ELSE
            CALL CCD1_MSG( ' ',
     :'  Global bias strip bounds                      :'//
     :' (^RGLO_B1:^RGLO_B2)', STATUS )
         END IF
      END IF

*  Readout direction.
      IF ( GOTDIR ) THEN
         IF ( DIRECT .EQ. 1 ) THEN
            CALL MSG_SETC( 'RGLO_DIREC', 'X' )
         ELSE
            CALL MSG_SETC( 'RGLO_DIREC', 'Y' )
         END IF
         CALL CCD1_MSG( ' ',
     :'  Global readout direction                      : ^RGLO_DIREC',
     :   STATUS )
      END IF

*  Deferred charge value.
      IF ( GOTDEF ) THEN
         CALL MSG_SETD( 'RGLO_DEFER', DEFER )
         CALL CCD1_MSG( ' ',
     :'  Global deferred charge value (ADUs)           : ^RGLO_DEFER',
     :   STATUS )
      END IF

*  Name of the mask file
      IF ( GOTMSK ) THEN
         CALL MSG_SETC( 'RGLO_MASK', MSKNAM )
         CALL CCD1_MSG( ' ', '  Global data mask : ^RGLO_MASK',
     :                  STATUS )
      END IF

*  Saturated value processing.
      IF (  GOTSAT ) THEN

*  Will be looking for saturated values.
         IF ( .NOT. SATUR ) THEN 
            CALL CCD1_MSG( ' ', '  Not looking for saturated pixels',
     :                     STATUS )
         ELSE
            CALL CCD1_MSG( ' ', '  Looking for saturated pixels',
     :                     STATUS )
            IF ( GOTSVL ) THEN

*  Report the saturation value.
               CALL MSG_SETD( 'SATVAL', SATVAL )
               CALL CCD1_MSG( ' ',
     :'  Global saturation value                       : ^SATVAL',
     :   STATUS )
            END IF

*  Say what saturation preferences are.
            IF ( GOTSPR ) THEN
               IF ( SETSAT ) THEN 

*  Saturated pixels set to saturation value.
                  CALL CCD1_MSG( ' ',
     :'  Saturated pixels will be set to saturation value', STATUS )
               ELSE
                  CALL CCD1_MSG( ' ',
     :'  Saturated pixels will be set to BAD value', STATUS )
               END IF
            END IF
         END IF
      END IF

*  Name of master bias.
      IF ( GOTBIA ) THEN
         CALL MSG_SETC( 'RGLO_BIAS', BIAS )
         CALL CCD1_MSG( ' ', '  Global master bias : ^RGLO_BIAS',
     :                  STATUS )
      END IF

*  Name of master flatfield.
      IF ( GOTFLA ) THEN
         CALL MSG_SETC( 'RGLO_FLAT', FLAT )
         CALL CCD1_MSG( ' ', '  Global master flatfield : ^RGLO_FLAT',
     :                  STATUS )
      END IF

*  Name of master calibration frame.
      IF ( GOTCAL ) THEN
         CALL MSG_SETC( 'RGLO_CAL', CAL )
         CALL CCD1_MSG( ' ',
     :   '  Global (general) calibration NDF : ^RGLO_CAL', STATUS )
      END IF

*  Whether data type will be presered on output from calculations.
      IF ( GOTPRE ) THEN
         IF ( PRESER ) THEN
            CALL CCD1_MSG( ' ', '  Data types will be preserved',
     :                     STATUS )
         ELSE
            CALL CCD1_MSG( ' ', '  Data types will not be preserved',
     :                     STATUS )
         END IF
      END IF

*  Whether variances will be generated.
      IF ( GOTGEN ) THEN
         IF ( GENVAR ) THEN
            CALL CCD1_MSG( ' ', '  Variances will be generated',
     :                     STATUS )
         ELSE
            CALL CCD1_MSG( ' ', '  Variances will not be generated',
     :                     STATUS )
         END IF
      END IF

*  How will INLIST parameters be interpreted.
      IF ( GOTNAM ) THEN
         IF ( NDFS ) THEN
            CALL CCD1_MSG( ' ',
     :      '  Position lists will be associated with NDFs', STATUS )
         ELSE
            CALL CCD1_MSG( ' ',
     :      '  Position list names will be accessed directly', STATUS )
         END IF
      END IF

*  Will we use Set header info.
      IF ( GOTSET ) THEN
         IF ( USESET ) THEN
            CALL CCD1_MSG( ' ',
     :'  CCDPACK Set header information will be used if available',
     :      STATUS )
         ELSE
            CALL CCD1_MSG( ' ',
     :'  CCDPACK Set header information will be ignored',
     :      STATUS )
         END IF
      END IF

*  Where log system information will be written to.
      IF ( GOTLG2 ) THEN
          CALL CCD1_MSG( ' ', ' ', STATUS )
         IF ( LOGTO .EQ. 'BOTH' ) THEN 
            CALL CCD1_MSG( ' ',
     :'  Log information will be written to log file and terminal',
     :      STATUS )

*  Add the name of the logfile.
            IF ( GOTLGN ) THEN
               CALL MSG_SETC( 'LOGNAM', LOGNAM )
               CALL CCD1_MSG( ' ', '  Name of log file : ^LOGNAM',
     :                        STATUS )
            END IF

         ELSE IF ( LOGTO .EQ. 'TERMINAL' ) THEN
            CALL CCD1_MSG( ' ',
     :'  Log information written to terminal only', STATUS )

         ELSE IF ( LOGTO .EQ. 'LOGFILE' ) THEN
            CALL CCD1_MSG( ' ',
     :'  Log information will be written to log file only', STATUS )
            IF ( GOTLGN ) THEN
               CALL MSG_SETC( 'LOGNAM', LOGNAM )
               CALL CCD1_MSG( ' ', '  Name of log file : ^LOGNAM',
     :                        STATUS )
            END IF

         ELSE IF ( LOGTO .EQ. 'NEITHER' ) THEN 
            CALL CCD1_MSG( ' ',
     :'  Log information will not be written', STATUS )
         END IF
      END IF

      END
* $Id$
