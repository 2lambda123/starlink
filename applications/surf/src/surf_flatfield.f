      SUBROUTINE REDS_FLATFIELD (STATUS)
*+
*  Name:
*     FLATFIELD

*  Purpose:
*     Routine to flatfield demodulated SCUBA data 

*  Language:
*     Starlink Fortran 77
 
*  Type of Module:
*     ADAM A-task
 
*  Invocation:
*     CALL REDS_FLATFIELD( STATUS )
 
*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status

*  Description:
*     This routine flatfields SCUBA demodulated data. 
*

*  Usage:
*     flatfield in out

*  ADAM parameters:
*     IN = NDF (Read)
*        The name of the NDF containing the demodulated data to be flatfielded.
*        This should already have been run through the REDUCE_SWITCH application.
*     OUT = NDF (Write)
*        The name of the NDF the flatfielded data are to be written to.

*  Examples:
*     flatfield redsw flat
*        This will flatfield the data from redsw.sdf and write it to flat.sdf

*  Notes:
*     The input data must have been REDUCE-SWITCHed.

*  Algorithm:
*        The data array of the IN file should have dimensions (N_BOLS,N_POS) 
*     for most observing modes, where N_BOLS was the number of bolometers 
*     measured and N_POS the number of times they were measured. In PHOTOM 
*     mode the data array will have dimensions (N_BOLS,N_POS,3), where the 
*     last dimension reflects the 3 different reduction algorithms used by 
*     the REDUCE_SWITCH application depending which `beam' the bolometer was 
*     assumed to be working in.
*        The identities of the bolometers taking the data are read from the
*     .MORE.SCUBA.BOL_CHAN and .MORE.SCUBA.BOL_ADC arrays in the IN file
*     and the appropriate flatfield values read from the .MORE.SCUBA.BOL_CALB
*     array. The data for each bolometer are multiplied by the corresponding
*     flatfield value and written to the OUT file.
*        The application will not run on input files that have not previously
*     been processed by the REDUCE_SWITCH application or which have already
*     had FLATFIELD run on them.

*  Implementation Status:
*     -Bad pixel handling is performed.

*  Authors:
*     JFL: J.Lightfoot (ROE)
*     TIMJ: T. Jenness (JACH)

*  History:
*     $Id$
*     18-JUN-1996: Original version.
*     $Log$
*     Revision 1.7  1996/11/02 01:39:40  timj
*     Remove space from History : header
*
c Revision 1.6  1996/11/02  01:23:28  timj
c Change name to FLATFIELD
c
c Revision 1.5  1996/10/31  18:22:55  timj
c Added modern Starlink header.
c
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-

*    Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'                ! SSE global definitions
      INCLUDE 'DAT_PAR'                ! Data-system constants
      INCLUDE 'REDS_SYS'               ! REDS constants

*    Status :
      INTEGER STATUS

*    Local Constants :
      INTEGER     MAX_DIM              ! max number of dims in array
      PARAMETER (MAX_DIM = 4)

*    Local variables :
      BYTE             BADBIT          ! Bad bit mask
      INTEGER          BOL_ADC (SCUBA__NUM_CHAN * SCUBA__NUM_ADC)
                                       ! A/D numbers of bolometers measured in
                                       ! input file
      REAL             BOL_CALB (SCUBA__NUM_CHAN, SCUBA__NUM_ADC)
                                       ! flat-field values for bolometers
      INTEGER          BOL_CHAN (SCUBA__NUM_CHAN * SCUBA__NUM_ADC)
                                       ! channel numbers of bolometers measured
                                       ! in input file
      INTEGER          BOL_QUAL (SCUBA__NUM_CHAN, SCUBA__NUM_ADC)
                                       ! quality of bolometers
      INTEGER          DIM (MAX_DIM)   ! array dimensions
      INTEGER          DIMX (MAX_DIM)  ! expected array dimensions
      CHARACTER*80     FITS (SCUBA__MAX_FITS)
                                       ! array of FITS keywords
      CHARACTER*80     FLAT            ! name of file that originally contained
                                       ! the flatfield
      LOGICAL          FLATFIELD       ! .TRUE. if the FLATFIELD application
                                       ! has been run on the input data
      INTEGER          I               ! DO loop index
      CHARACTER*(DAT__SZLOC) IN_FITSX_LOC
                                       ! locator to FITS extension in input
                                       ! file
      CHARACTER*(DAT__SZLOC) IN_LOC    ! locator of item in input file
      INTEGER          IN_NDF          ! NDF index of input file
      CHARACTER*(DAT__SZLOC) IN_SCUBAX_LOC
                                       ! locator to SCUBA extension in input
                                       ! file
      CHARACTER*(DAT__SZLOC) IN_SCUCDX_LOC
                                       ! locator to SCUCD extension in input
                                       ! file
      INTEGER          ITEMP           ! scratch integer
      INTEGER          NDIM            ! the number of dimensions in an array
      INTEGER          NREC            ! number of history records in input file
      INTEGER          N_BEAM          ! number of 'beams' in input data array
      INTEGER          N_BOL           ! number of bolometers measured in input
                                       ! array
      INTEGER          N_FITS          ! number of items in FITS array
      INTEGER          N_POS           ! number of positions measured in input
                                       ! file
      CHARACTER*40     OBJECT          ! name of object
      CHARACTER*40     OBSERVING_MODE  ! observing mode of input file
      INTEGER          OUT_D_PTR       ! pointer to data array in OUT file
      INTEGER          OUT_NDF         ! NDF index of output file
      INTEGER          OUT_Q_PTR       ! pointer to quality array in OUT file
      INTEGER          OUT_V_PTR       ! pointer to variance array in OUT file
      LOGICAL          REDUCE_SWITCH   ! .TRUE. if REDUCE_SWITCH application
                                       ! has been run on input file
      INTEGER          RUN_NUMBER      ! run number of input file
      CHARACTER*80     STEMP           ! scratch string
*.

      IF (STATUS .NE. SAI__OK) RETURN

*  start up the NDF system and read in the input demodulated file

      CALL NDF_BEGIN

      CALL NDF_ASSOC ('IN', 'READ', IN_NDF, STATUS)

* Read in badbit mask
      CALL NDF_BB(IN_NDF, BADBIT, STATUS)


*  get some general descriptive parameters of the observation

      CALL NDF_XLOC (IN_NDF, 'FITS', 'READ', IN_FITSX_LOC, STATUS)
      CALL NDF_XLOC (IN_NDF, 'SCUBA', 'READ', IN_SCUBAX_LOC, STATUS)
      CALL NDF_XLOC (IN_NDF, 'SCUCD', 'READ', IN_SCUCDX_LOC, STATUS)

      CALL DAT_SIZE (IN_FITSX_LOC, ITEMP, STATUS)
      IF (ITEMP .GT. SCUBA__MAX_FITS) THEN
         IF (STATUS .EQ. SAI__OK) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP (' ', 'REDS_FLATFIELD: input file contains '//
     :        'too many FITS items', STATUS)
         END IF
      END IF

      CALL DAT_GET1C (IN_FITSX_LOC, SCUBA__MAX_FITS, FITS, N_FITS,
     :  STATUS)

      CALL SCULIB_GET_FITS_I (SCUBA__MAX_FITS, N_FITS, FITS, 'RUN',
     :  RUN_NUMBER, STATUS)
      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS, 'OBJECT',
     :  OBJECT, STATUS)
      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS, 'MODE',
     :  OBSERVING_MODE, STATUS)
      CALL CHR_UCASE (OBSERVING_MODE)

      CALL MSG_SETC ('OBJECT', OBJECT)
      CALL MSG_SETC ('MODE', OBSERVING_MODE)
      CALL MSG_SETI ('RUN', RUN_NUMBER)
      CALL MSG_OUT (' ', 'REDS: run ^RUN was a ^MODE observation '//
     :  'of ^OBJECT', STATUS)

*  check that the history of the file is OK

      IF (STATUS .EQ. SAI__OK) THEN
         CALL NDF_HNREC (IN_NDF, NREC, STATUS)
         IF (STATUS .NE. SAI__OK) THEN
            CALL ERR_ANNUL (STATUS)
            NREC = 0
         END IF

         REDUCE_SWITCH = .FALSE.
         FLATFIELD = .FALSE.

         IF (NREC .GT. 0) THEN
            DO I = 1, NREC
               CALL NDF_HINFO (IN_NDF, 'APPLICATION', I, STEMP,
     :           STATUS)
               CALL CHR_UCASE (STEMP)
               IF (STEMP .EQ. 'REDUCE_SWITCH') THEN
                  REDUCE_SWITCH = .TRUE.
               ELSE IF (STEMP .EQ. 'FLATFIELD') THEN
                  FLATFIELD = .TRUE.
               END IF
            END DO
         END IF

         IF (STATUS .EQ. SAI__OK) THEN
            IF (.NOT. REDUCE_SWITCH) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP (' ', 'REDS_FLATFIELD: the '//
     :           'REDUCE_SWITCH application has not been run on '//
     :           'the input file', STATUS)
            END IF

            IF (FLATFIELD) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP (' ', 'REDS_FLATFIELD: the '//
     :           'FLATFIELD application has already been run on '//
     :           'the input file', STATUS)
            END IF
         END IF
      END IF

*  get the number of bolometers and the name of the flatfield 

      CALL SCULIB_GET_FITS_I (SCUBA__MAX_FITS, N_FITS, FITS, 'N_BOLS',
     :  N_BOL, STATUS)
      CALL SCULIB_GET_FITS_C (SCUBA__MAX_FITS, N_FITS, FITS, 'FLAT',
     :  FLAT, STATUS)

*  check the dimensions of the input data array

      CALL NDF_DIM (IN_NDF, MAX_DIM, DIM, NDIM, STATUS)

      IF (STATUS .EQ. SAI__OK) THEN
         IF (OBSERVING_MODE .EQ. 'PHOTOM') THEN
            IF ((NDIM .NE. 3)                  .OR.
     :          (DIM(1) .NE. N_BOL)            .OR.
     :          (DIM(2) .LT. 1)                .OR.
     :          (DIM(3) .NE. SCUBA__MAX_BEAM)) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETI ('NDIM', NDIM)
               CALL MSG_SETI ('DIM1', DIM(1))
               CALL MSG_SETI ('DIM2', DIM(2))
               CALL MSG_SETI ('DIM3', DIM(3))
               CALL ERR_REP (' ', 'REDS_FLATFIELD: main data '//
     :           'array has bad dimensions - (^NDIM) ^DIM1 ^DIM2 '//
     :           '^DIM3', STATUS)
            END IF
         ELSE
            IF ((NDIM .NE. 2)       .OR.
     :          (DIM(1) .LT. N_BOL) .OR.
     :          (DIM(2) .LT. 1))    THEN
               STATUS = SAI__ERROR
               CALL MSG_SETI ('NDIM', NDIM)
               CALL MSG_SETI ('DIM1', DIM(1))
               CALL MSG_SETI ('DIM2', DIM(2))
               CALL ERR_REP (' ', 'REDS_FLATFIELD: main data '//
     :           'array has bad dimensions (^NDIM) ^DIM1, ^DIM2', 
     :           STATUS)
            END IF
         END IF
      END IF

      N_POS = DIM (2)
      IF (OBSERVING_MODE .EQ. 'PHOTOM') THEN
         N_BEAM = SCUBA__MAX_BEAM
      ELSE
	 N_BEAM = 1
      END IF

*  get the bolometer description arrays

      CALL DAT_FIND (IN_SCUBAX_LOC, 'BOL_CALB', IN_LOC, STATUS)
      NDIM = 2
      DIMX (1) = SCUBA__NUM_CHAN
      DIMX (2) = SCUBA__NUM_ADC
      CALL DAT_GETNR (IN_LOC, NDIM, DIMX, BOL_CALB, DIM, STATUS)
      CALL DAT_ANNUL (IN_LOC, STATUS)

      IF (STATUS .EQ. SAI__OK) THEN
         IF ((NDIM .NE. 2)                 .OR.
     :       (DIM(1) .NE. SCUBA__NUM_CHAN) .OR.
     :       (DIM(2) .NE. SCUBA__NUM_ADC)) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI ('NDIM', NDIM)
            CALL MSG_SETI ('DIM1', DIM(1))
            CALL MSG_SETI ('DIM2', DIM(2))
            CALL ERR_REP (' ', 'REDS_FLATFIELD: .SCUBA.BOL_CALB '//
     :        'array has bad dimensions - (^NDIM) ^DIM1 ^DIM2',
     :        STATUS)
         END IF
      END IF

      CALL DAT_FIND (IN_SCUBAX_LOC, 'BOL_QUAL', IN_LOC, STATUS)
      NDIM = 2
      DIMX (1) = SCUBA__NUM_CHAN
      DIMX (2) = SCUBA__NUM_ADC
      CALL DAT_GETNI (IN_LOC, NDIM, DIMX, BOL_QUAL, DIM, STATUS)
      CALL DAT_ANNUL (IN_LOC, STATUS)

      IF (STATUS .EQ. SAI__OK) THEN
         IF ((NDIM .NE. 2)                 .OR.
     :       (DIM(1) .NE. SCUBA__NUM_CHAN) .OR.
     :       (DIM(2) .NE. SCUBA__NUM_ADC)) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI ('NDIM', NDIM)
            CALL MSG_SETI ('DIM1', DIM(1))
            CALL MSG_SETI ('DIM2', DIM(2))
            CALL ERR_REP (' ', 'REDS_FLATFIELD: .SCUBA.BOL_QUAL '//
     :        'array has bad dimensions - (^NDIM) ^DIM1 ^DIM2',
     :        STATUS)
         END IF
      END IF

      CALL DAT_FIND (IN_SCUBAX_LOC, 'BOL_CHAN', IN_LOC, STATUS)
      CALL DAT_GET1I (IN_LOC, SCUBA__NUM_CHAN * SCUBA__NUM_ADC,
     :  BOL_CHAN, ITEMP, STATUS)
      CALL DAT_ANNUL (IN_LOC, STATUS)

      IF (STATUS .EQ. SAI__OK) THEN
         IF (ITEMP .NE. N_BOL) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP (' ', 'REDS_FLATFIELD: dimension of '//
     :        '.SCUBA.BOL_CHAN does not match main data array',
     :        STATUS)
         END IF
      END IF

      CALL DAT_FIND (IN_SCUBAX_LOC, 'BOL_ADC', IN_LOC, STATUS)
      CALL DAT_GET1I (IN_LOC, SCUBA__NUM_CHAN * SCUBA__NUM_ADC,
     :  BOL_ADC, ITEMP, STATUS)
      CALL DAT_ANNUL (IN_LOC, STATUS)

      IF (STATUS .EQ. SAI__OK) THEN
         IF (ITEMP .NE. N_BOL) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP (' ', 'REDS_FLATFIELD: dimension of '//
     :        '.SCUBA.BOL_ADC does not match main data array',
     :        STATUS)
         END IF
      END IF

*  OK, propagate the input ndf to the output

      CALL NDF_PROP (IN_NDF, 'DATA,QUALITY,VARIANCE', 'OUT',
     :  OUT_NDF, STATUS)

*  map the output data arrays (map QUALITY first so that it doesnt
*  automatically mask DATA and VARIANCE)

      CALL NDF_MAP (OUT_NDF, 'QUALITY', '_UBYTE', 'UPDATE',
     :  OUT_Q_PTR, ITEMP, STATUS)
      CALL NDF_MAP (OUT_NDF, 'DATA', '_REAL', 'UPDATE', OUT_D_PTR,
     :  ITEMP, STATUS)
      CALL NDF_MAP (OUT_NDF, 'VARIANCE', '_REAL', 'UPDATE', OUT_V_PTR,
     :  ITEMP, STATUS)
 
* Bad bit mask
      CALL NDF_SBB(BADBIT, OUT_NDF, STATUS)

*  flatfield the data 

      CALL MSG_SETC ('FLAT', FLAT)
      CALL MSG_OUT (' ', 'REDS: applying flatfield from ^FLAT', STATUS)

      IF (STATUS .EQ. SAI__OK) THEN
         CALL SCULIB_FLATFIELD_DATA (N_BOL, N_POS, N_BEAM,
     :     %val(OUT_D_PTR), %val(OUT_V_PTR), %val(OUT_Q_PTR),
     :     BOL_CHAN, BOL_ADC, SCUBA__NUM_CHAN, SCUBA__NUM_ADC, 
     :     BOL_CALB, BOL_QUAL, STATUS)
      END IF

*  annul locators and array identifiers and close the file

      CALL DAT_ANNUL (IN_FITSX_LOC, STATUS)
      CALL DAT_ANNUL (IN_SCUBAX_LOC, STATUS)
      CALL DAT_ANNUL (IN_SCUCDX_LOC, STATUS)

      CALL NDF_ANNUL (IN_NDF, STATUS)
      CALL NDF_ANNUL (OUT_NDF, STATUS)

      CALL NDF_END (STATUS)
 
      END
