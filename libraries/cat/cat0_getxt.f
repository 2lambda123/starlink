
*+
*  Name:
*    cat0_getxt

*  Copyright:
*    Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*    All Rights Reserved.

*  Licence:
*    This program is free software; you can redistribute it and/or
*    modify it under the terms of the GNU General Public License as
*    published by the Free Software Foundation; either version 2 of
*    the License, or (at your option) any later version.
*    
*    This program is distributed in the hope that it will be
*    useful,but WITHOUT ANY WARRANTY; without even the implied
*    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*    PURPOSE. See the GNU General Public License for more details.
*    
*    You should have received a copy of the GNU General Public License
*    along with this program; if not, write to the Free Software
*    Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*    02111-1307, USA

*-
      SUBROUTINE CAT0_GETXT (BCKTYP, CI, FINISH, CLASS, TEXT, STATUS)
      IMPLICIT NONE
      INTEGER BCKTYP, CI, STATUS
      LOGICAL FINISH
      CHARACTER CLASS*(*), TEXT*(*)
      INCLUDE 'CAT_PAR' 
      INCLUDE 'CAT1_PAR' 

      IF (STATUS .NE. CAT__OK) RETURN

      IF (BCKTYP .EQ. CAT1__BKFIT) THEN
         CALL CAT3_GETXT (CI, FINISH, CLASS, TEXT, STATUS)
      ELSE IF (BCKTYP .EQ. CAT1__BKSTL) THEN
         CALL CAT5_GETXT (CI, FINISH, CLASS, TEXT, STATUS)
      ELSE IF (BCKTYP .EQ. CAT1__BKTST) THEN
         CALL CAT6_GETXT (CI, FINISH, CLASS, TEXT, STATUS)
      END IF

      END
