      SUBROUTINE DSA_NAMED_INPUT( DSAREF, NDFNAM, STATUS )
*+
*  Name:
*     DSA_NAMED_INPUT

*  Purpose:
*     Open existing NDF for read access using a name.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL DSA_NAMED_INPUT( DSAREF, NDFNAM, STATUS )

*  Description:
*     This routine takes the name of an NDF. The NDF is then opened and
*     associated with the given reference name.
*
*     Contrary to earlier implementations, this routine gives only read
*     access to the NDF in question.
*
*     The NDF name can be a filename, a filename combined with an HDS
*     structure name within the file, and it can include an NDF section
*     specification. A full example might be
*
*        myfile.more.some.struct(5).data(:50,2.5:3.5,7,29.0)
*
*     Note that the following call sequence is frowned upon:
*
*        CALL PAR_RDCHAR()
*        CALL DSA_NAMED_INPUT()
*
*     The PAR_RDCHAR will cause inconsistencies in the
*     user interface. DSA_NAMED_* should be used if the application
*     genuinely knows the NDF name without consulting the parameter
*     system. Applications that use the above sequence should instead:
*
*        CALL DSA_INPUT()
*        CALL DSA_GET_ACTUAL_NAME()
*
*     In this sequence the NDF name is acquired from the parameter
*     system in a consistent way and then made available to the
*     application for output to the terminal, an ASCII file or a plot
*     label.

*  Arguments:
*     DSAREF = CHARACTER * ( * ) (Given)
*        The reference name to be associated with the opened NDF.
*        Only the first 16 characters are significant. The
*        name is case-insensitive.
*     NDFNAM = CHARACTER * ( * ) (Given)
*        The name of the NDF.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Implementation Status:
*     An NDF section cannot be opened if its base NDF has an N-dimensional
*     axis.

*  Authors:
*     ks: Keith Shortridge (AAO)
*     hme: Horst Meyerdierks (UoE, Starlink)
*     {enter_new_authors_here}

*  History:
*     15 Jun 1987 (ks):
*        Original version.
*     21 Jul 1988 (ks):
*        Additional common items initialised.
*     09 Sep 1988 (ks):
*        PARM_VALUE initialised.
*     28 Nov 1988 (ks):
*        Now uses DSA_INIT_REF_SLOT for initialisation.
*     15 Jan 1990 (ks):
*        Call to DSA_SET_FILE_TYPE added.
*     19 Jan 1990 (ks):
*        DSA_SET_FILE_TYPE is now a DSA__ routine.
*     15 Feb 1991 (ks):
*        Add new extension parameter to DSA_FNAME call.
*     21 Aug 1992 (ks):
*        Automatic portability modifications
*        ("INCLUDE" syntax etc) made.
*     29 Aug 1992 (ks):
*        "INCLUDE" filenames now upper case.
*     24 Nov 1995 (hme):
*        FDA library.
*     18 Jan 1996 (hme):
*        Change access mode to READ.
*     19 Feb 1996 (hme):
*        Refuse if NDF is not base NDF and has one or more N-D axes.
*        Translate between application-side status and Starlink status.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! Standard DAT constants
      INCLUDE 'NDF_PAR'          ! Standard NDF constants

*  Global Variables:
      INCLUDE 'DSA_COMMON'       ! DSA global variables

*  Arguments Given:
      CHARACTER * ( * ) DSAREF
      CHARACTER * ( * ) NDFNAM

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      LOGICAL ISBAS              ! Whether NDF is base NDF
      LOGICAL AXISND             ! Whether an axis is N-D
      INTEGER I                  ! Loop index
      INTEGER SLOT               ! Slot number
      INTEGER NDIM               ! NDF dimensionality
      INTEGER DIM( NDF__MXDIM )  ! Ignored
      CHARACTER * ( 16 ) REFUC   ! Given reference in upper case
      CHARACTER * ( DAT__SZNAM ) DELNAM ! Ignored
      CHARACTER * ( DAT__SZLOC ) DELLOC ! Ignored
      CHARACTER * ( DAT__SZLOC ) ARYLOC ! Ignored

*.

*  Check inherited global status.
      IF ( STATUS .NE. 0 ) RETURN

*  Begin error context and translate status.
      CALL ERR_MARK
      STATUS = SAI__OK

*  Upper case reference name.
      REFUC = DSAREF
      CALL CHR_UCASE( REFUC )

*  Try to find the reference, in order to check that the same name is
*  not used twice.
      DO 1 SLOT = 1, DSA__MAXREF
         IF ( DSA__REFUSD(SLOT) .AND.
     :        DSA__REFNAM(SLOT) .EQ. REFUC ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETC( 'FDA_T001', DSA__REFNAM(SLOT) )
            CALL ERR_REP( 'FDA_E034', 'DSA_NAMED_INPUT: ' //
     :         'Reference name ^FDA_T001 already in use.', STATUS )
            GO TO 500
         END IF
 1    CONTINUE

*  Find a free slot for the NDF identifier or placeholder.
      DO 2 SLOT = 1, DSA__MAXREF
         IF ( .NOT. DSA__REFUSD(SLOT) ) GO TO 3
 2    CONTINUE
         STATUS = SAI__ERROR
         CALL MSG_SETC( 'FDA_T001', REFUC )
         CALL ERR_REP( 'FDA_E035', 'DSA_NAMED_INPUT: ' //
     :      'No slot left for reference ^FDA_T001.', STATUS )
         GO TO 500
 3    CONTINUE

*  Open the named NDF for read-only access.
      CALL NDF_OPEN( DAT__ROOT, NDFNAM, 'READ',
     :   'OLD', DSA__REFID1(SLOT), DSA__REFPLC(SLOT), STATUS )

*  If NDF is a section.
      CALL NDF_ISBAS( DSA__REFID1(SLOT), ISBAS, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 500
      IF ( .NOT. ISBAS ) THEN

*     For each axis.
         CALL NDF_DIM( DSA__REFID1(SLOT), NDF__MXDIM, DIM,NDIM, STATUS )
         IF ( STATUS .NE. SAI__OK ) GO TO 500
         DO 4 I = 1, NDIM

*        If the axis is N-dimensional.
            CALL DSA1_AXISND( SLOT, I,
     :         AXISND, ARYLOC, DELLOC, DELNAM, STATUS )
            IF ( STATUS .NE. SAI__OK ) GO TO 500
            IF ( AXISND ) THEN

*           Annul the NDF and report an error.
               CALL DAT_ANNUL( ARYLOC, STATUS )
               CALL DAT_ANNUL( DELLOC, STATUS )
               CALL NDF_ANNUL( DSA__REFID1(SLOT), STATUS )
               STATUS = SAI__ERROR
               CALL MSG_SETC( 'FDA_T001', REFUC )
               CALL ERR_REP( 'FDA_E036', 'DSA_NAMED_INPUT: Cannot ' //
     :            'open NDF section with multi-dimensional axis. ' //
     :            'The reference in question is ^FDA_T001.', STATUS )
               GO TO 500

            END IF

 4       CONTINUE

      END IF

*  Fill in reference slot.
      IF ( STATUS .EQ. SAI__OK ) THEN
         DSA__REFUSD(SLOT) = .TRUE.
         DSA__REFBAD(SLOT) = .FALSE.
         DSA__REFQUA(SLOT) = .FALSE.
         DSA__REFID2(SLOT) = NDF__NOID
         DSA__REFDPT(SLOT) = 0
         DSA__REFQPT(SLOT) = 0
         DSA__REFNAM(SLOT) = REFUC
      END IF

*  Tidy up.
 500  CONTINUE

*  Translate status and end error context.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_FLUSH( STATUS )
         STATUS = 1
      ELSE
         STATUS = 0
      END IF
      CALL ERR_RLSE

*  Return.
      END
