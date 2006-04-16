 
      SUBROUTINE MAG1_ERNAM(NAME, STATUS)
*+
*  Name:
*     MAG1_ERNAM
 
*  Purpose:
*     report MAG error message to STARLINK environment.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL MAG1_ERNAM(NAME, STATUS)
 
*  Description:
*     An error is reported, based on the supplied name and MAG status value.
 
*  Arguments:
*     NAME=CHARACTER*(*) (Given)
*        Textual part of message
*     STATUS=INTEGER (Given and Returned)
*        The status value to be reported
 
*  Algorithm:
*     Use ERR_REP.
 
*  Copyright:
*     Copyright (C) 1983, 1991, 1993 Science & Engineering Research Council.
*     Copyright (C) 1995 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     Sid Wright (UCL::SLW)
*     {enter_new_authors_here}
 
*  History:
*     14-Jul-1983:  Original. (UCL::SLW)
*     14-Nov-1991:  Changed to new-style prologue (RAL::KFH)
*           Replaced tabs in end-of-line comments (RAL::KFH)
*           Replaced fac_$name by fac1_name (RAL::KFH)
*           Inserted implicit none (RAL::KFH)
*     22-Jan-1993:  Change include file names
*           Convert code to uppercase using SPAG (RAL::BKM)
*     29-Jun-1995:  Use FACER not ^STATUS (RAL::AJC)
*     {enter_further_changes_here}
 
*  Notes:
*     Formerly known as MAG_$ERNAM
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type definition:
      IMPLICIT NONE
 
*  Global Constants:
      INCLUDE 'SAE_PAR'         ! Standard SAE constants
 
*  Arguments Given:
      CHARACTER*(*) NAME        ! name
      INTEGER STATUS            ! status code
 
*.
 
 
      CALL MAG1_CODE(STATUS)
      CALL MSG_SETC('NAME', NAME)
      CALL ERR_FACER('STAT', STATUS)
      CALL ERR_REP('MAG_ERNAM', '^NAME : ^STAT', STATUS)
 
      RETURN
      END
