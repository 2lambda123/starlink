      SUBROUTINE SURF_SCAN_RLB (STATUS)
*+
*  Name:
*     SCAN_RLB

*  Purpose:
*     Remove the linear baseline from SCAN/MAP data

*  Language:
*     Starlink Fortran 77
 
*  Type of Module:
*     ADAM A-task
 
*  Invocation:
*     CALL SURF_SCAN_RLB( STATUS )
 
*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status
 
*  Description:
*     This routine removes a linear baseline from each scan.
*     It does this by fitting a straight line to the scan ends and then
*     removing this from the entire scan.

*  Usage:
*     scan_rlb in out

*  ADAM Parameters:
*     CHOP = INTEGER (Read)
*        The basline fit is calculated over regions CHOP arcseconds from the
*        scan ends. This region should be as large as possible but should
*        only include baseline regions -- any scan that includes a source 
*        detection within CHOP arcseconds of the scan ends will be rendered
*        useless.
*        The default value is the chop throw.
*     IN = NDF (Read)
*        The name of the input file containing demodulated SCUBA data.
*     MSG_FILTER = CHAR (Read)
*        The messaging level. Default is NORM. There are no verbose messages.
*     OUT = NDF (Write)
*        The name of the output file to contain the processed data.
*     RLB = INTEGER (Read)
*        This parameter governs whether the baseline fit is removed from the
*        input data or stored instead of the data. If RLB is .TRUE. the
*        corrected data are returned. If RLB is .FALSE. the fit is returned.

*  Examples:
*     scan_rlb infile \
*        Remove linear baslines from each scan using basline regions the
*        same size as the chop. Write the results to the default output file.


*  Authors:
*     JFL: John Lightfoot (jfl@roe.ac.uk)
*     TIMJ: Tim Jenness (timj@jach.hawaii.edu)
*     {enter_new_authors_here}

*    History :
*     $Id$
*     21-SEP-1995: original version.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}

*-


*    Type Definitions:
      IMPLICIT NONE

*    Global constants:
      INCLUDE 'SAE_PAR'                 ! SSE global definitions
      INCLUDE 'DAT_PAR'                 ! for DAT__SZLOC
      INCLUDE 'SURF_PAR'                ! REDS constants
      INCLUDE 'MSG_PAR'                 ! for MSG__ constants

*    Status:
      INTEGER STATUS

*    Local Constants:
      INTEGER MAXDIM
      PARAMETER (MAXDIM = 4)
      CHARACTER * 10 TSKNAME            ! Name of task
      PARAMETER (TSKNAME = 'SCAN_RLB')

*    Local variables:
      LOGICAL      ABORTED              ! .TRUE. if observation was
                                        ! aborted
      BYTE         BADBIT               ! Bad bit mask
      CHARACTER*15 CHOP_COORDS          ! coordinate system of chop
      CHARACTER*15 CHOP_FUN             ! chop mode used in observation
      INTEGER      CHOP_SIZE            ! Chop in pixels
      REAL         CHOP_THROW           ! chopper throw (arcsec)
      INTEGER      DIM (MAXDIM)         ! the dimensions of an array
      LOGICAL      DORLB                ! Perform the subtraction
      LOGICAL      EXTINCTION           ! .TRUE. if the EXTINCTION application
                                        ! has already been run on the 
                                        ! input file
      CHARACTER*80 FITS (SCUBA__MAX_FITS)
                                        ! array of FITS keyword lines
      CHARACTER*132 FNAME               ! Input filename
      INTEGER      I                    ! DO loop variable
      INTEGER      INDF                 ! NDF identifier of input file
      INTEGER      ITEMP                ! scratch integer
      INTEGER      IN_DATA_PTR          ! pointer to data array of input file
      INTEGER      IN_DEM_PNTR_PTR      ! pointer to input .SCUBA.DEM_PNTR
      CHARACTER*(DAT__SZLOC) IN_FITSX_LOC
                                        ! locator to FITS extension in input
                                        ! file
      INTEGER      IN_QUALITY_PTR       ! pointer to quality array in input
                                        ! file
      CHARACTER*(DAT__SZLOC) IN_SCUBAX_LOC
                                        ! locator to SCUBA extension in input
                                        ! file
      INTEGER      IN_VARIANCE_PTR      ! pointer to variance array in input
                                        ! file
      INTEGER      LAST_EXP             ! exposure where abort occurred
      INTEGER      LAST_INT             ! integration where abort occurred
      INTEGER      LAST_MEAS            ! measurement where abort occurred
      INTEGER      NDIM                 ! the number of dimensions in an array
      INTEGER      NREC                 ! number of history records in file
      INTEGER      N_BOL                ! number of bolometers measured 
      INTEGER      N_EXPOSURES          ! number of exposures per integration
      INTEGER      N_FITS               ! number of FITS lines read from file
      INTEGER      N_INTEGRATIONS       ! number of integrations per measurement
      INTEGER      N_MEASUREMENTS       ! number of measurements in the file
      INTEGER      N_POS                ! the total number of positions measured
      CHARACTER*30 OBJECT               ! name of object observed
      CHARACTER*15 OBSERVING_MODE       ! type of observation
      CHARACTER*132 OUTFILE             ! Output filename
      INTEGER      OUTNDF               ! NDF identifier of output file
      INTEGER      OUT_DATA_PTR         ! pointer to data array in output
      INTEGER      OUT_QUALITY_PTR      ! pointer to quality array in output 
      INTEGER      OUT_VARIANCE_PTR     ! pointer to variance array in output
      LOGICAL      REDUCE_SWITCH        ! .TRUE. if REDUCE_SWITCH has been run
      INTEGER      RUN_NUMBER           ! run number of observation
      REAL         SAMPLE_DX            ! sample spacing along scans
      CHARACTER*15 SAMPLE_MODE          ! SAMPLE_MODE of observation
      CHARACTER*80 STATE                ! 'state' of SCUCD at end of
                                        ! observation
      CHARACTER*80 STEMP                ! scratch string
      CHARACTER * (10) SUFFIX_STRINGS(SCUBA__N_SUFFIX) ! Suffix for OUT

*  Local Data:
      DATA SUFFIX_STRINGS /'!_rlb','b','_rlb'/
*.

      IF (STATUS .NE. SAI__OK) RETURN

*     Set the MSG output level (for use with MSG_OUTIF)
      CALL MSG_IFGET('MSG_FILTER', STATUS)

*  start up the NDF system and read in the demodulated data file

      CALL NDF_BEGIN

      CALL NDF_ASSOC ('IN', 'READ', INDF, STATUS)

*     Get the name of the filename associated with 'IN'

      CALL SCULIB_GET_FILENAME('IN', FNAME, STATUS)

* Read in badbit mask
      CALL NDF_BB(INDF, BADBIT, STATUS)

*  get some general descriptive parameters of the observation

      CALL NDF_XLOC (INDF, 'FITS', 'READ', IN_FITSX_LOC, STATUS)
      CALL NDF_XLOC (INDF, 'SCUBA', 'READ', IN_SCUBAX_LOC, STATUS)

      CALL DAT_SIZE (IN_FITSX_LOC, ITEMP, STATUS)
      IF (ITEMP .GT. SCUBA__MAX_FITS) THEN
         IF (STATUS .EQ. SAI__OK) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETC('TASK', TSKNAME)
            CALL ERR_REP (' ', '^TASK: input file '//
     :        'contains too many FITS items', STATUS)
         END IF
      END IF
      CALL DAT_GET1C (IN_FITSX_LOC, SCUBA__MAX_FITS, FITS, N_FITS,
     :  STATUS)
      CALL DAT_ANNUL (IN_FITSX_LOC, STATUS)

      CALL SCULIB_GET_FITS_I (SCUBA__MAX_FITS, N_FITS, FITS, 'RUN', 
     :  RUN_NUMBER, STATUS)
      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS, 'OBJECT',
     :  OBJECT, STATUS)
      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS, 'MODE',
     :  OBSERVING_MODE, STATUS)
      CALL CHR_UCASE (OBSERVING_MODE)
      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS, 
     :  'SAM_MODE', SAMPLE_MODE, STATUS)
      CALL CHR_UCASE (SAMPLE_MODE)
      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS,
     :  'CHOP_CRD', CHOP_COORDS, STATUS)
      CALL CHR_UCASE (CHOP_COORDS)

*  check that the observation was suitable for RESTORE

      IF (STATUS .EQ. SAI__OK) THEN
         IF (OBSERVING_MODE .NE. 'MAP') THEN
            STATUS = SAI__ERROR
            CALL MSG_SETC('TASK', TSKNAME)
            CALL ERR_REP (' ', '^TASK: file does not contain '//
     :        'data for a MAP observation', STATUS)
         ELSE IF (SAMPLE_MODE .NE. 'RASTER') THEN
            STATUS = SAI__ERROR
            CALL MSG_SETC('TASK', TSKNAME)
            CALL ERR_REP (' ', '^TASK: map was not obtained '//
     :        'with RASTER sampling', STATUS)
         END IF
      END IF

      CALL MSG_SETC ('OBJECT', OBJECT)
      CALL MSG_SETI ('RUN', RUN_NUMBER)
      CALL MSG_SETC ('PKG', PACKAGE)
      CALL MSG_OUTIF (MSG__NORM, ' ', 
     :     '^PKG: run ^RUN was a MAP observation '//
     :     'of object ^OBJECT', STATUS)

*  check that the history of the input file is OK

      IF (STATUS .EQ. SAI__OK) THEN
         CALL NDF_HNREC (INDF, NREC, STATUS)
         IF (STATUS .NE. SAI__OK) THEN
            CALL ERR_ANNUL (STATUS)
            NREC = 0
         END IF

         REDUCE_SWITCH = .FALSE.
         EXTINCTION = .FALSE.

         IF (NREC .GT. 0) THEN
            DO I = 1, NREC
               CALL NDF_HINFO (INDF, 'APPLICATION', I, STEMP, STATUS)
               CALL CHR_UCASE (STEMP)
               IF (STEMP .EQ. 'REDUCE_SWITCH') THEN
                  REDUCE_SWITCH = .TRUE.
               ELSE IF (STEMP .EQ. 'EXTINCTION') THEN
                  EXTINCTION = .TRUE.
               END IF
            END DO
         END IF

         IF (STATUS .EQ. SAI__OK) THEN
            IF (.NOT. REDUCE_SWITCH) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETC('TASK', TSKNAME)
               CALL ERR_REP (' ', '^TASK: the '//
     :           'REDUCE_SWITCH application has not been run '//
     :           'on the input file', STATUS)
            END IF

*            IF (EXTINCTION) THEN
*               STATUS = SAI__ERROR
*               CALL MSG_SETC('TASK', TSKNAME)
*               CALL ERR_REP (' ', '^TASK: the '//
*     :           'EXTINCTION application has already been run '//
*     :           'on the input file. RESTORE should be run before '//
*     :           'EXTINCTION', STATUS)
*            END IF
         END IF
      END IF

*  get some other FITS items needed for this stage of reduction

      CALL SCULIB_GET_FITS_R (SCUBA__MAX_FITS, N_FITS, FITS, 'SAM_DX',
     :  SAMPLE_DX, STATUS)
      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS, 'CHOP_FUN',
     :  CHOP_FUN, STATUS)
      CALL CHR_UCASE (CHOP_FUN)
      CALL SCULIB_GET_FITS_R (SCUBA__MAX_FITS, N_FITS, FITS, 'CHOP_THR',
     :  CHOP_THROW, STATUS)

*     Ask for the chop throw

      CALL PAR_DEF0R('CHOP', CHOP_THROW, STATUS)
      CALL PAR_GET0R('CHOP', CHOP_THROW, STATUS)

*  find out if the observation was aborted

      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS, 'STATE',
     :  STATE, STATUS)
      CALL CHR_UCASE (STATE)
      ABORTED = .FALSE.
      IF (INDEX(STATE,'ABORTING') .NE. 0) THEN
         ABORTED = .TRUE.
      END IF

*  check the data dimensions 

      CALL NDF_DIM (INDF, MAXDIM, DIM, NDIM, STATUS)

      IF (STATUS .EQ. SAI__OK) THEN
         IF ((NDIM .NE. 2) .OR.
     :       (DIM(1) .LT. 1) .OR.
     :       (DIM(2) .LT. 1)) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI ('NDIM', NDIM)
            CALL MSG_SETI ('DIM1', DIM(1))
            CALL MSG_SETI ('DIM2', DIM(2))
            CALL MSG_SETC('TASK', TSKNAME)
            CALL ERR_REP (' ', '^TASK: main data '//
     :        'array has bad dimensions - (^NDIM) ^DIM1 ^DIM2', STATUS)
         END IF
      END IF

      N_BOL = DIM (1)
      N_POS = DIM (2)

*     map the input arrays

      CALL NDF_MAP (INDF, 'QUALITY', '_UBYTE', 'READ',
     :     IN_QUALITY_PTR, ITEMP, STATUS)
      CALL NDF_MAP (INDF, 'DATA', '_REAL', 'READ', IN_DATA_PTR,
     :     ITEMP, STATUS)
      CALL NDF_MAP (INDF, 'VARIANCE', '_REAL', 'READ', IN_VARIANCE_PTR,
     :     ITEMP, STATUS)


*  map the DEM_PNTR array and check its dimensions

      CALL SCULIB_GET_DEM_PNTR(3, IN_SCUBAX_LOC,
     :     IN_DEM_PNTR_PTR, ITEMP, N_EXPOSURES, N_INTEGRATIONS, 
     :     N_MEASUREMENTS, STATUS)

      CALL MSG_SETI ('N_E', N_EXPOSURES)
      CALL MSG_SETI ('N_I', N_INTEGRATIONS)
      CALL MSG_SETI ('N_M', N_MEASUREMENTS)
      CALL MSG_SETC ('PKG', PACKAGE)

      IF (.NOT. ABORTED) THEN
         CALL MSG_OUTIF (MSG__NORM, ' ', 
     :        '^PKG: file contains data for ^N_E '//
     :        'exposure(s) in ^N_I integration(s) in '//
     :        '^N_M measurement(s)', STATUS)
      ELSE

*  get the exposure, integration, measurement numbers at which the
*  abort occurred

         CALL SCULIB_GET_FITS_I (SCUBA__MAX_FITS, N_FITS, FITS,
     :     'EXP_NO', LAST_EXP, STATUS)
         CALL SCULIB_GET_FITS_I (SCUBA__MAX_FITS, N_FITS, FITS,
     :     'INT_NO', LAST_INT, STATUS)
         CALL SCULIB_GET_FITS_I (SCUBA__MAX_FITS, N_FITS, FITS,
     :     'MEAS_NO', LAST_MEAS, STATUS)

         CALL MSG_OUTIF (MSG__NORM, ' ', 
     :        '^PKG: the observation should have '//
     :        'had ^N_E exposure(s) in ^N_I integrations in ^N_M '//
     :        'measurement(s)', STATUS)
         CALL MSG_SETI ('N_E', LAST_EXP)
         CALL MSG_SETI ('N_I', LAST_INT)
         CALL MSG_SETI ('N_M', LAST_MEAS)
         CALL MSG_OUTIF (MSG__NORM,' ', 
     :        ' - However, the observation was '//
     :        'ABORTED during exposure ^N_E of integration ^N_I '//
     :        'of measurement ^N_M', STATUS)
      END IF         

*     Generate a default name for the output file
      CALL SCULIB_CONSTRUCT_OUT(FNAME, SUFFIX_ENV, SCUBA__N_SUFFIX,
     :     SUFFIX_OPTIONS, SUFFIX_STRINGS, OUTFILE, STATUS)

*     set the default
      CALL PAR_DEF0C('OUT', OUTFILE, STATUS)

*  now open the output NDF, propagating it from the input file

      CALL NDF_PROP (INDF, 'Units,Axis', 'OUT', OUTNDF, STATUS)

*  map the various components of the output data array

      CALL NDF_MAP (OUTNDF, 'QUALITY', '_UBYTE', 'WRITE',
     :  OUT_QUALITY_PTR, ITEMP, STATUS)
      CALL NDF_MAP (OUTNDF, 'DATA', '_REAL', 'WRITE', 
     :  OUT_DATA_PTR, ITEMP, STATUS)
      CALL NDF_MAP (OUTNDF, 'VARIANCE', '_REAL', 'WRITE',
     :  OUT_VARIANCE_PTR, ITEMP, STATUS)

* Bad bit mask
      CALL NDF_SBB(BADBIT, OUTNDF, STATUS)

*     Allow for the fit to be stored rather than simply the
*     data with the fit subtracted. Gives you more flexibility later
*     since can use the Kappa command SUB to do the subtraction if
*     required.

      CALL PAR_GET0L('RLB', DORLB, STATUS)


*  now go through the various exposures in the observation

      IF (STATUS .EQ. SAI__OK) THEN

         CHOP_SIZE = INT(CHOP_THROW / SAMPLE_DX)


*       Remove a linear baseline

         CALL SCULIB_REMOVE_LINEAR_BASELINE(DORLB, N_EXPOSURES,
     :        N_INTEGRATIONS, N_MEASUREMENTS,
     :        %val(IN_DEM_PNTR_PTR), N_BOL, N_POS, 
     :        %val(IN_DATA_PTR), %VAL(IN_VARIANCE_PTR),
     :        %val(IN_QUALITY_PTR), CHOP_SIZE, CHOP_SIZE,
     :        %val(OUT_DATA_PTR), %val(OUT_VARIANCE_PTR),
     :        %val(OUT_QUALITY_PTR), BADBIT, STATUS)

      END IF

*  tidy up


      CALL NDF_UNMAP (OUTNDF, '*', STATUS)
      CALL NDF_UNMAP (INDF, '*', STATUS)

      CALL CMP_UNMAP (IN_SCUBAX_LOC, 'DEM_PNTR', STATUS)

      CALL DAT_ANNUL (IN_SCUBAX_LOC, STATUS)

      CALL NDF_ANNUL (INDF, STATUS)
      CALL NDF_ANNUL (OUTNDF, STATUS)

      CALL NDF_END (STATUS)

      END
