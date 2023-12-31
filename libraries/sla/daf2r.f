      SUBROUTINE sla_DAF2R (IDEG, IAMIN, ASEC, RAD, J)
*+
*     - - - - - -
*      D A F 2 R
*     - - - - - -
*
*  Convert degrees, arcminutes, arcseconds to radians
*  (double precision)
*
*  Given:
*     IDEG        int       degrees
*     IAMIN       int       arcminutes
*     ASEC        dp        arcseconds
*
*  Returned:
*     RAD         dp        angle in radians
*     J           int       status:  0 = OK
*                                    1 = IDEG outside range 0-359
*                                    2 = IAMIN outside range 0-59
*                                    3 = ASEC outside range 0-59.999...
*
*  Notes:
*     1)  The result is computed even if any of the range checks
*         fail.
*     2)  The sign must be dealt with outside this routine.
*
*  P.T.Wallace   Starlink   23 August 1996
*
*  Copyright (C) 1996 Rutherford Appleton Laboratory
*
*  License:
*    This program is free software; you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation; either version 2 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program (see SLA_CONDITIONS); if not, write to the
*    Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
*    Boston, MA  02110-1301  USA
*
*-

      IMPLICIT NONE

      INTEGER IDEG,IAMIN
      DOUBLE PRECISION ASEC,RAD
      INTEGER J

*  Arc seconds to radians
      DOUBLE PRECISION AS2R
      PARAMETER (AS2R=0.484813681109535994D-5)



*  Preset status
      J=0

*  Validate arcsec, arcmin, deg
      IF (ASEC.LT.0D0.OR.ASEC.GE.60D0) J=3
      IF (IAMIN.LT.0.OR.IAMIN.GT.59) J=2
      IF (IDEG.LT.0.OR.IDEG.GT.359) J=1

*  Compute angle
      RAD=AS2R*(60D0*(60D0*DBLE(IDEG)+DBLE(IAMIN))+ASEC)

      END
