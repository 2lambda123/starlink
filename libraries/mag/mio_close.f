      SUBROUTINE MIO_CLOSE(TD, STATUS)
*+
*  Name:
*     MIO_CLOSE
 
*  Purpose:
*     close magnetic tape.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL MIO_CLOSE(TD, STATUS)
 
*  Description:
*     Close the tape with the specified tape descriptor.
 
*  Arguments:
*     TD=INTEGER (Given)
*        A variable containing the tape descriptor.
*     STATUS=INTEGER (Given and Returned)
*        Variable holding the status value.   If the routine fails to
*        complete, this variable will be set to an appropriate error number.
*        If this variable is not SAI__OK on input, then the routine will
*        still attempt to execute, but will return with STATUS set to the
*        import value.
*        N.B. This routine does not report its own errors.
 
*  Algorithm:
*     The tape descriptor is checked for validity, and the tape is checked to
*     see if it is open.  Any buffers yet to be written to the tape are flushed
*     and the channel to the tape drive is released using ioc_close
*     The relevant MIO_BUF and MIO_FIL table entries are released.
 
*  Authors:
*     Sid Wright (UCL::SLW)
*     Jon Fairclough (RAL::IPMAF)
*     {enter_new_authors_here}
 
*  History:
*     30-Jul-1980: Original. (UCL::SLW)
*     10-May-1983: Tidy up for Starlink version. (UCL::SLW)
*     22-Nov-1984: Modified MIO_BUF (RAL::IPMAF)
*     15-Nov-1991: Changed to new style prologue (RAL::KFH)
*           Replaced tabs by spaces in end-of-line comments (RAL::KFH)
*           Changed any fac_$name into fac1_name (RAL::KFH)
*           Inserted IMPLICIT NONE (RAL::KFH)
*     15_Jan-1992: Changed to use ioc_close for Unix version. (RAL::KFH)
*     22-Jan-1993:  Change include file names
*           Convert code to uppercase using SPAG (RAL::BKM)
*     {enter_further_changes_here}
 
*  Notes:
*     This is the Unix version
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE
 
*  Global Constants:
      INCLUDE 'SAE_PAR'         ! Standard SAE constants
      INCLUDE 'MIO_SYS'         ! MIO Internal Constants
      INCLUDE 'MIO_ERR'         ! MIO Errors
 
*  Arguments Given:
      INTEGER TD                ! tape descriptor
 
*  Status:
      INTEGER STATUS            ! status return
 
*  External References:
      EXTERNAL MIO1_BLK          ! Block data subprogram that
                                 ! initializes MIOINT
*  Global Variables:
      INCLUDE 'MIOBUF_CMN'
      INCLUDE 'MIOFIL_CMN'
 
*  Local Variables:
      INTEGER ISTAT             ! local status value
      INTEGER MAGCN             ! tape channel number
 
*.
 
 
D      print *,'mio_close:status,td',status,td
*    Initialised ?
      IF ( .NOT.MIOINT ) CALL MIO_START(STATUS)
 
      ISTAT = STATUS
      STATUS = SAI__OK
*    Check for valid Tape Descriptor
      IF ( TD.LT.1 .OR. TD.GT.MIO__MXDEV ) THEN
         STATUS = MIO__ILLTD
      ELSE IF ( MFREE(TD) ) THEN
         STATUS = MIO__NTOPN
      ELSE
*      Flush buffers if necessary
         CALL MIO_FLUSH(TD, STATUS)
*      Close the tape
         CALL MIO1_CHAN(TD, MAGCN, STATUS)
         CALL IOC_CLOSE(MAGCN, STATUS)
 
         IF ( STATUS.EQ.SAI__OK ) THEN
 
*       Record current state
            MFREE(TD) = .TRUE.
            MNAME(TD) = ' '
            MTRANS(TD) = ' '
            MACMOD(TD) = ' '
            MCHAN(TD) = 0
            MRECSZ(TD) = 0
            MBLKSZ(TD) = 0
            MNBYTE(TD) = 0
         END IF
 
      END IF
 
      IF ( STATUS.EQ.SAI__OK ) STATUS = ISTAT
 
D      print *,'mio_close:status',status
      END
