      SUBROUTINE MIO_START(STATUS)
*+
*  Name:
*     MIO_START
 
*  Purpose:
*     Initialise MIO System.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL MIO_START(STATUS)
 
*  Description:
*     Initialise Common blocks.
 
*  Arguments:
*     STATUS=INTEGER ( **** NOT USED **** )
*        Variable to hold the status value
*        N.B. This routine does not report its own errors.
 
*  Algorithm:
*     Initialize the MIO_BUF and MIO_FIL tables.
 
*  Authors:
*     Sid Wright (UCL::SLW)
*     Jon Fairclough (RAL::IPMAF)
*     {enter_new_authors_here}
 
*  History:
*     30-Jul-1980: Original. (UCL::SLW)
*     10-May-1983: Tidy up for Starlink version. (UCL::SLW)
*     21-Nov-1984: Altered MIO_BUF. (RAL::IPMAF)
*        3-Dec-1984: Mioint flag set (RAL::IPMAF)
*     15-Nov-1991:  Changed to new style prologue (RAL::KFH)
*           Replaced tabs by spaces in end-of-line comments (RAL::KFH)
*           Changed any fac_$name into fac1_name (RAL::KFH)
*           Inserted IMPLICIT NONE (RAL::KFH)
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE
 
*  Global Constants:
      INCLUDE 'SAE_PAR'         ! Standard SAE constants
      INCLUDE 'MIO_SYS'         ! MIO Internal symbols and errors.
 
*  Arguments Returned:
 
*  Status:
      INTEGER STATUS            ! status return
 
*  External References:
      EXTERNAL MIO1_BLK          ! Block data subprogram that
                                 ! initializes MIOINT
*  Global Variables:
      INCLUDE 'MIOBUF_CMN'
      INCLUDE 'MIOFIL_CMN'
 
*  Local Variables:
      INTEGER I                 ! loop index
 
*.
 
*
      IF ( MIOINT ) RETURN
*
*    set up file desciptors etc.
      DO 100 I = 1, MIO__MXDEV
         MFREE(I) = .TRUE.
         MCHAN(I) = 0
         MNAME(I) = ' '
         MTRANS(I) = ' '
         MACMOD(I) = ' '
         MRECSZ(I) = 0
         MBLKSZ(I) = 0
         MNBYTE(I) = 0
 100  CONTINUE
      MIOINT = .TRUE.
 
      RETURN
      END
