      SUBROUTINE MIO1_CHAN(TD, CHAN, STATUS)
*+
*  Name:
*     MIO1_CHAN
 
*  Purpose:
*     get channel from tape descriptor.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL MIO1_CHAN(TD, CHAN, STATUS)
 
*  Description:
*     The channel associated with the given tape descriptor is returned.
 
*  Arguments:
*     TD=INTEGER (Given)
*        The input relative tape descriptor
*     CHAN=INTEGER (Returned)
*        returned output channel number
*     STATUS=INTEGER (Given and Returned)
*        Variable holding the status value.   If this variable is not
*        SAI__OK on input, then the routine will return without action.  If
*        the routine fails to complete, this variable will be set to an
*        appropriate error number.
 
*  Algorithm:
*     The relative tape descriptor, TD, is validated and then used as an index
*     into the MIO_FIL Common Block to obtain the channel number therein.
 
*  Authors:
*     Sid Wright (UCL::SLW)
*     {enter_new_authors_here}
 
*  History:
*     30-Jul-1980: Original. (UCL::SLW)
*     10-May-1983: Tidy up for Starlink version. (UCL::SLW)
*     15-Nov-1991: Changed to new style prologue (RAL::KFH)
*           Replaced tabs by spaces in end-of-line comments (RAL::KFH)
*           Changed any fac_$name into fac1_name (RAL::KFH)
*           Inserted IMPLICIT NONE (RAL::KFH)
*     22-Jan-1993:  Change include file names
*           Convert code to uppercase using SPAG (RAL::BKM)
*     {enter_further_changes_here}
 
*  Notes:
*     Formerly known as MIO_$CHAN
 
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
 
*  Arguments Returned:
      INTEGER CHAN              ! tape device channel
*    Status return :
      INTEGER STATUS            ! status return
 
*  External References:
      EXTERNAL MIO1_BLK          ! Block data subprogram that
                                 ! initializes MIOINT
*  Global Variables:
      INCLUDE 'MIOFIL_CMN'      ! MIO library states
 
*.
 
 
*    Allowed to execute ?
      IF ( STATUS.NE.SAI__OK ) RETURN
 
      IF ( TD.LT.1 .OR. TD.GT.MIO__MXDEV ) THEN
         STATUS = MIO__ILLTD
      ELSE IF ( MFREE(TD) ) THEN
         STATUS = MIO__NTOPN
      ELSE
         CHAN = MCHAN(TD)
      END IF
 
D      print *,'mio1_chan:td,chan,status',td,chan,status
      RETURN
      END
