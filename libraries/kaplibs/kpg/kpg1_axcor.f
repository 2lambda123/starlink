      SUBROUTINE KPG1_AXCOR( LBND, UBND, AXIS, EL, VALUE, INDEX,
     :                       STATUS )
*+
*  Name:
*     KPG1_AXCOx
 
*  Purpose:
*     Obtains for an axis the axis indices given their values.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_AXCOx( LBND, UBND, AXIS, EL, VALUE, INDEX, STATUS )
 
*  Description:
*     This routine determines floating-point axis indices within an axis
*     array for a series of pixel co-ordinates.  It assumes that the
*     array is monotonic and approximately linear, since it uses linear
*     interpolation to derive the pixel indices.  This routine may be
*     used for arbitrary 1-d arrays in addition to axes, provided this
*     criterion is met.
*
*  Arguments:
*     LBND = INTEGER (Given)
*        The lower bound of the axis array.
*     UBND = INTEGER (Given)
*        The upper bound of the axis array.
*     AXIS( LBND:UBND ) = ? (Given)
*        The axis array.
*     EL = INTEGER (Given)
*        The number of indices whose values in the axis array are to be
*        found.
*     VALUE( EL ) = ? (Given)
*        The axis-array values.
*     INDEX( EL ) = ? (Returned)
*        The pixel co-ordinates of the values in the axis array.
*        Notice that this is in floating point as fractional positions
*        may be returned.  An index is set to the bad value when its
*        input co-ordinate lies outside the range of co-ordinates in
*        the axis.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for the data types real or double precision:
*     replace "x" in the routine name by R or D respectively, as
*     appropriate.  The axis array and co-ordinates, and the returned
*     indices should have this data type as well.
*     -  An error report is made and bad status returned should any
*     input co-ordinate lie outside the range of co-ordinates of
*     the axis.  Processing will continue through the list.
 
*  Implementation Deficiencies:
*     There is an optimisation that could be made, namely to sort the
*     co-ordinates, so that there is only one search through the axis
*     array.
 
*  [optional_subroutine_items]...
*  Copyright:
*     Copyright (C) 1993 Science & Engineering Research Council.
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
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1993 March 2 (MJC):
*        Original version?
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants
 
*  Arguments Given:
      INTEGER LBND
      INTEGER UBND
      INTEGER EL
 
      REAL AXIS( LBND:UBND )
      REAL VALUE( EL )
 
*  Arguments Returned:
      REAL INDEX( EL )
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER AEL                ! Number of axis elements
      REAL AXMAX              ! Maximum axis value
      REAL AXMIN              ! Minimum axis value
      LOGICAL BAD                ! True if an input value is out of
                                 ! bounds
      REAL FRAC               ! Fractional array index
      INTEGER I                  ! Loop counter
      INTEGER ITH                ! Index of the threshold element
      INTEGER LB                 ! Truncated pixel index
 
      REAL VALTH              ! Value at the threshold element
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Get the axis bounds.
      AEL = UBND - LBND + 1
      CALL KPG1_AXBNR( AEL, AXIS, AXMIN, AXMAX, STATUS )
 
*  Set the flag to indicate that none of the co-ordinates are out of
*  range.
      BAD = .FALSE.
      DO  I = 1, MAX( EL, 1 )
 
*  Check the element co-ordinate does not lie outside the bounds.  If it
*  does make an error report, but continue.
         IF ( VALUE( I ) .LT. AXMIN .OR. VALUE( I ) .GT. AXMAX ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETR( 'VALUE', VALUE( I ) )
            CALL MSG_SETI( 'I', I )
            CALL MSG_SETR( 'AXMIN', AXMIN )
            CALL MSG_SETR( 'AXMAX', AXMAX )
 
            CALL ERR_REP( 'KPG1_AXCOx_OUTBOUND',
     :        'The co-ordinate number ^I has a value ^VALUE that lies '/
     :        /'outside the bounds of the axis (^AXMIN to ^AXMAX).',
     :        STATUS )
 
*  Temporarily set the status to good so that the remaining points
*  may be converted to indices.  Record the fact so that a bad status
*  can be reset before exiting.
            STATUS = SAI__OK
            BAD = .TRUE.
 
*  Set the index value to be bad.
            INDEX( I ) = VAL__BADR
         ELSE
 
*  Find the index of the element just greater than the value.
            CALL KPG1_AXGVR( AEL, AXIS, VALUE( I ), ITH, VALTH,
     :                         STATUS )
 
*  The sign of ITH indicates the direction of increasing values. A
*  negative ITH means that the values decrease as pixel index increases.
*  Derive the index of the lower element nearest to the value.  Note
*  a shift of origin (equal to LBND-1) is also applied.
            IF ( ITH .GT. 0 ) THEN
               LB = ITH + LBND - 2
            ELSE
               LB = -ITH + LBND - 1
            END IF
 
*  Calculate the fractional position of the value assuming linear
*  interpolation.
            FRAC = ( VALUE( I ) - AXIS( LB ) ) /
     :             ( AXIS( LB + 1 ) - AXIS( LB ) )
 
*  Derive the floating-point index to be returned.
            INDEX( I ) = NUM_ITOR( LB ) + FRAC
         END IF
      END DO
 
*  Reset the status should any of the values be bad.
      IF ( BAD ) STATUS = SAI__ERROR
 
      END
