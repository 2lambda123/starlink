 
      SUBROUTINE MIO_WTM(TD, STATUS)
*+
*  Name:
*     MIO_WTM
 
*  Purpose:
*     Write Tape Mark (EOF).
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL MIO_WTM(TD, STATUS)
 
*  Description:
*     Write an End-of-File mark on the tape.
 
*  Arguments:
*     TD=INTEGER (Given)
*        A variable containing the tape descriptor.
*     STATUS=INTEGER (Given and Returned)
*        Variable holding the status value.   If this variable is not
*        SAI__OK on input, then the routine will return without action.  If
*        the routine fails to complete, this variable will be set to an
*        appropriate error number.
*        N.B. This routine does not report its own errors.
 
*  Algorithm:
*     Check for a valid tape descriptor and that the tape is open, if so, the
*     tape descriptor is used to obtain a tape channel and the ioc_weof
*     routine is used to write a tapemark.
 
*  Authors:
*     Sid Wright (UCL::SLW)
*     Jack Giddings (UCL::JRG)
*     {enter_new_authors_here}
 
*  History:
*     06-Aug-1980: Original. (UCL::SLW)
*     01-FEB-1983: Fortran 77 Version. (UCL::JRG)
*     10-May-1983: Tidy up for Starlink version. (UCL::SLW)
*     14-Jul-1986: Check return status of QIOW. (RAL::AJC)
*     15-Nov-1991: Changed to new style prologue (RAL::KFH)
*           Replaced tabs by spaces in end-of-line comments (RAL::KFH)
*           Changed any fac_$name into fac1_name (RAL::KFH)
*           Inserted IMPLICIT NONE (RAL::KFH)
*     17-Jan-1992: Changed to use ioc_weof for Unix version.
*     22-Jan-1993:  Change include file names
*           Convert code to uppercase using SPAG (RAL::BKM)
*     {enter_further_changes_here}
 
*  Notes:
*     This is the Unix version.
 
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
 
*  Local Variables:
      INTEGER MAGCN             ! channel number
 
*.
 
 
D      print *,'mio_wtm:status,td',status,td
      IF ( STATUS.EQ.SAI__OK ) THEN
         CALL MIO1_CHAN(TD, MAGCN, STATUS)
         IF ( STATUS.EQ.SAI__OK ) CALL IOC_WEOF(MAGCN, STATUS)
      END IF
 
D      print *,'mio_wtm:status',status
      END
