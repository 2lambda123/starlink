
*+
*  Name:
*    cat0_putxt

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
*    Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*    02110-1301, USA

*-
      SUBROUTINE CAT0_PUTXT (BCKTYP, CI, CLASS, TEXT, STATUS)
      IMPLICIT NONE
      INTEGER BCKTYP, CI, STATUS
      CHARACTER CLASS*(*), TEXT*(*)
      INCLUDE 'CAT_PAR'
      INCLUDE 'CAT1_PAR'

      IF (STATUS .NE. CAT__OK) RETURN

      IF (BCKTYP .EQ. CAT__BKFIT) THEN
         CALL CAT3_PUTXT (CI, CLASS, TEXT, STATUS)
      ELSE IF (BCKTYP .EQ. CAT__BKSTL) THEN
         CALL CAT5_PUTXT (CI, CLASS, TEXT, STATUS)
      ELSE IF (BCKTYP .EQ. CAT__BKTST) THEN
         CALL CAT6_PUTXT (CI, CLASS, TEXT, STATUS)
      END IF

      END
