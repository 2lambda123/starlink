C+
      SUBROUTINE DTA_RDVAR (NAME,NITEM,ITYPE,BUFFER,STATUS)
C
C     D T A _ R D V A R
C
C     Generic routine for reading from an object in the data
C     structure.  The number of items specified are copied
C     from the data structure starting at the location 
C     specified by the object name (which can also include
C     an array element specification).  If necessary, the
C     data will be converted into the format required by the
C     data structure definition.  Note that this routine cannot
C     be used to read into a character string.
C
C     Parameters -   (">" input, "<" output )
C
C     (>) NAME     (Character) The object name, in the standard
C                  data structure format.  Should end with a
C                  blank or the string end, and is case 
C                  insignificant.
C     (>) NITEM    (Integer) The number of elements to be
C                  read from the data structure.
C     (>) ITYPE    (Integer) The type code for the data to
C                  be read. Should be one of the TYP_DS..
C                  codes (not a conversion code).
C     (<) BUFFER   (Any numeric type) Receives the data read from
C                  the object.  Note that because of the variations in
C                  the way different compilers pass CHARACTER strings,
C                  this cannot be used for CHARACTER variables. 
C     (<) STATUS   (Integer) Returns a status code.
C                  0 => OK
C                  Lower level routines may return other error codes
C-
C     Subroutines / functions used -
C 
C     DTA_PRETR    (DTA_ package) Preliminary set up for data transfer
C     DTA_HDSERC   ( "      "   ) Convert HDS error code to DTA code
C     DTA_FILLUP   ( "      "   ) Fill a numeric array with zeros
C     DAT_GET      (HDS     "   ) Read data from structure component
C     DAT_ANNUL    ( "      "   ) Annul locator
C     EMS_BEGIN    (EMS_  "     ) Start a new reporting environment.
C     EMS_ANNUL    ( "    "     ) Clear current EMS error status.
C     EMS_END      ( "    "     ) End current reporting environment.
C
C     Common variables used -  None
C
C                                         KS / CIT 26th Oct 1982
C     Modified:
C
C     23rd Sept 1985  KS / AAO. Uses DTA_FMTCON instead of STL_FMTCON
C     17th March 1986 KS / AAO. Re-written to use HDS routines.  Call
C                     for character transfer now requires descriptor,
C                     not actual data.  Undefined data is returned as
C                     blanks or zeros.
C     10th Jan 1992.  KS / AAO.  Syntax of include statements changed to 
C                     remove VMS logical names and to use lower case, to 
C                     enable compilation on a SUN. Can no longer be used
C                     when BUFFER is a character string, because of the
C                     incompatible ways different compilers pass such
C                     strings.
C     24th Jan 1992.  KS / AAO. Calls to EMS added to control error reporting.
C     12th Mar 1993.  HME / UoE. Changed CHARACTER*15 to *(DAT__SZLOC).
C
C     Machine dependence:
C
C     Apart form the obvious use of VAX/VMS compiler syntax in places
C     (IMPLICIT NONE, etc), this routine makes the more subtle assumptions
C     that numeric arrays and scalars are passed by reference, and that
C     the zero value for any numeric type is just the appropriate number
C     of zero bytes - ie that DTA_FILLUP can set any array type to zero.
C+
      IMPLICIT NONE
C
C     Parameters -
C
      CHARACTER*(*) NAME
      INTEGER NITEM,ITYPE,BUFFER,STATUS
C
C     (Note, BUFFER can be defined as anything, since it is
C     only passed on to other routines.  Strictly, this routine assumes
C     that BUFFER will be the address of an array - ie it assumes that
C     the compiler passes numeric scalars and arrays by reference.)
C
C     DTA_ system parameters.  Used is -
C
C     DST_MAXDIM    Maximum allowed number of dimensions
C
      INCLUDE 'DTASDEF'
      INCLUDE 'DAT_PAR'
      INCLUDE 'SAE_PAR'
C
C     Local variables
C
      LOGICAL UNDEF,TEMPLOC
      INTEGER EMSTAT,NLDIM,LDIMS(DST_MAXDIM),STPOST
      CHARACTER HDSTYPE*16
      CHARACTER LOC*(DAT__SZLOC)
C
C     Set new EMS reporting environment
C
      EMSTAT=0
      CALL EMS_BEGIN(EMSTAT) 
C
C     Perform preliminary processing - check NAME, locate it
C     in structures, get suitable locator for transfer.
C
      CALL DTA_PRETR(NAME,NITEM,ITYPE,LOC,HDSTYPE,NLDIM,LDIMS,
     :                                    UNDEF,TEMPLOC,STATUS)
      IF (STATUS.NE.0)  GO TO 600
C
C     Read data into BUFFER, or set buffer to zeros if the 
C     object is undefined.
C
      IF (.NOT.UNDEF) THEN
         CALL DAT_GET(LOC,HDSTYPE,NLDIM,LDIMS,BUFFER,STATUS)
         IF (STATUS.NE.0) THEN
            CALL DTA_HDSERC(STATUS)
            GO TO 600
         END IF
      ELSE
         CALL DTA_FILLUP(ITYPE,NITEM,BUFFER)
      END IF
C
C     Tidy up afterwards, by annulling the locator used, if it
C     was flagged as temporary.
C
  600 CONTINUE
      IF (TEMPLOC) THEN
         STPOST=0
         CALL DAT_ANNUL(LOC,STPOST)
         IF (STATUS.EQ.0) THEN
            STATUS=STPOST
            CALL DTA_HDSERC(STATUS)
         END IF
      END IF
C
C     On way out, clear any EMS errors and revert to previous environment.
C
      EMSTAT=0
      CALL EMS_ANNUL(EMSTAT)
      CALL EMS_END(EMSTAT)
      END

