      SUBROUTINE THRSR( INARR, DIMS, THRLO, THRHI, NEWLO, NEWHI,
     :                   OUTARR, STATUS )
*+
*  Name:
*     THRSR

*  Purpose:
*     Threshold an array of data

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     SUBROUTINE

*  Invocation:
*     CALL THRSR( INARR, OUTARR, DIMS, THRLO, THRHI, NEWLO, NEWHI,
*     :             STATUS )

*  Description:
*     Takes an array of data and sets all values above a defined upper
*     threshold to a new defined value, and sets all those below a
*     defined lower threshold to another defined value. In practice,
*     all values outside the two thresholds may be set to zero, for
*     example.

*  Arguments:
*     INARR( DIMS )  =  REAL( READ )
*         Input data to be thresholded
*     DIMS  =  INTEGER( READ )
*         Dimension of input and output data arrays
*     THRLO  =  REAL( READ )
*         Upper threshold level
*     THRHI  =  REAL( READ )
*         Lower threshold level
*     NEWLO  =  REAL( READ )
*         Value to which pixels below THRLO will be set
*     NEWHI  =  REAL( READ )
*         Value to which pixels above THRHI will be set
*     OUTARR( DIMS )  =  REAL( WRITE )
*         Output thresholded data
*     STATUS  = INTEGER( READ )
*         Global status parameter

*  Algorithm:
*     Check for error on entry
*     If o.k.  then
*        For all pixels of input array
*           If pixel is invalid then
*              Copy input value straight into output value
*           Else if value less than lower threshold THRLO
*              Set new value to NEWLO
*           Else if value higher than upper threshold THRHI
*              Set new value to NEWHI
*           Else
*              Copy input value straight into output value
*           Endif
*        Endfor
*     Endif
*     Return

*  Copyright:
*     Copyright (C) 1982, 1985-1986 Science & Engineering Research
*     Council. All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     B.D.Kelly (ROE::BDK)
*     Mark McCaughrean UoE (REVA::MJM)
*     Malcolm Currie RAL (UK.AC.RL.STAR::CUR)
*     {enter_new_authors_here}

*  History:
*     29-JAN-1982 (ROE::BDK):
*        : First implementation
*     04-JUN-1985: : Revised to take status parameter, to take different
*                : new values for upper and lower thresholds, and
*                : redocumented SSE / ADAM style (REVA::MJM)
*                : (Also changed last section - seemed crazy)
*     02-SEP-1985 (REVA::MJM):
*        : Renamed THRESHSUB
*     03-JUL-1986 (REVA::MJM):
*        : Revised implementation and documentation
*     1986 Aug 18: Renamed from THRESHSUB, reordered arguments (2nd to
*                  7th), generalised to any array; tidied and nearly
*                  conformed to Starlink standards (RL.STAR::CUR).
*     1986 Sep 5 : Renamed parameters section to arguments, applied
*                  bad-pixel handling (RL.STAR::CUR).
*     1986 Nov 12: Made a generic routine (RL.STAR::CUR).
*     {enter_further_changes_here}

*  Bugs:
*     None known.
*     {note_new_bugs_here}

*-

*  Type Definitions:
 
      IMPLICIT  NONE              ! no default typing allowed
 
*  Global Constants:
 
      INCLUDE  'SAE_PAR'          ! SSE global definitions
      INCLUDE 'PRM_PAR'           ! PRIMDAT public constants
 
*  Arguments Given:
 
      INTEGER
     :    DIMS
 
      REAL
     :    INARR( DIMS ),
     :    THRLO,
     :    THRHI,
     :    NEWLO,
     :    NEWHI
 
*  Arguments Returned:
 
      REAL
     :    OUTARR( DIMS )
 
*  Status:
 
      INTEGER  STATUS
 
*  Local Variables:
 
      INTEGER  J                  ! counter
 
*.
*    check status on entry - return if not o.k.
 
      IF ( STATUS .EQ. SAI__OK ) THEN
 
*       loop round all pixels in input image
 
         DO  J  =  1, DIMS
 
*          check for invalid pixel
 
            IF ( INARR( J ) .EQ. VAL__BADR ) THEN
               OUTARR( J ) =  VAL__BADR
 
*          check input array value and act accordingly
 
            ELSE IF ( INARR( J ) .GT. THRHI ) THEN
 
*             input pixel value is greater than upper threshold - set
*             output pixel to given replacement value
 
               OUTARR( J )  =  NEWHI
 
            ELSE IF ( INARR( J ) .LT. THRLO ) THEN
 
*             input pixel value is less than lower threshold - set
*             output pixel to given replacement value
 
               OUTARR( J )  =  NEWLO
 
            ELSE
 
*             input pixel value lies between thresholds - just copy
*             it into output pixel
 
               OUTARR( J )  =  INARR( J )
 
*          end of check to see where input pixel value lies in range
 
            END IF
 
*       end of loop round all pixels
 
         END DO
      END IF
 
*    end
 
      END
