      SUBROUTINE KPS1_RORAD( NUMRA, XSIZE, YSIZE, XEXT, YEXT, ARRAY,
     :                         STATUS )
*+
*  Name:
*     KPS1_RORAx

*  Purpose:
*     Rotates a subsection of 2-dimnensional array by 90, 180 or 270
*     degrees.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_RORAx( NUMRA, XSIZE, YSIZE, XEXT, YEXT, ARRAY, STATUS )

*  Description:
*     The XEXT by YEXT section of the input 2-dimensional array ARRAY,
*     of dimensions XSIZE, YSIZE, is rotated through NUMRA right angles
*     in the clockwise direction.  ARRAY will hold the rotated data on
*     exit from the routine.

*  Arguments:
*     NUMRA = INTEGER (Given)
*        Number of right-angles through which the data array will be
*        rotated.
*     XSIZE = INTEGER (Given)
*        First dimension of the data array to be rotated.
*     YSIZE = INTEGER (Given)
*        Second dimension of the data array to be rotated.
*     XEXT = INTEGER (Given)
*        First dimension extent of the data array to be rotated.
*     YEXT = INTEGER (Given)
*        Second dimension extent of the data array to be rotated.
*     ARRAY( XSIZE, YSIZE ) = ? (Given and Returned)
*        Contains data to be rotated on entry to the routine and is
*        returned containing the rotated data.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     If no error on entry then
*        If no. of right angles to rotate is 1 then
*           Perform 90 degree rotate clockwise
*           For x from 1 to half the maximum extent to be rotated
*              For y from x to maximum extent to be rotated - x
*                                  save becomes array( xswap,     y )
*                 array( xswap,     y ) becomes array( yswap, xswap )
*                 array( yswap, xswap ) becomes array(     x, yswap )
*                 array(     x, yswap ) becomes array(     y,     x )
*                 array(     y,     x ) becomes save
*                 Where xswap is the maximum extent to be rotated +1 - x
*                 and   yswap is the maximum extent to be rotated +1 - y
*              End for
*           End for
*        Elseif number of right angles to rotate is 2 then
*           Perform 180 degree rotate
*           For y from 1 to half the maximum extent to be rotated
*              For x from 1 to the first dimension extent to be rotated
*                                  save becomes array(     x,     y )
*                 array(     x,     y ) becomes array( xswap, yswap )
*                 array( xswap, yswap ) becomes save
*                 where xswap is the first dimension extent + 1 - x
*                 and   yswap is the second dimension extent + 1 - y
*              End for
*           End for
*           If maximum extent to be rotated is an odd number then
*              Set y to half maximum extent plus one
*              For x from 1 to half the first dimension extent to be
*                rotated
*                              save becomes array(     x, y )
*                 array(     x, y ) becomes array( xswap, y )
*                 array( xswap, y ) becomes save
*                 where xswap is the first dimension extent + 1 - x
*              End for
*           End if
*        Elseif no. of right angles to rotate is 3 then
*           Perform 90 degree rotate anti-clockwise, equivalent to 270
*             degree rotate clockwise
*           For x from 1 to half the maximum extent to be rotated
*              For y from x to the maximum extent to be rotated - x
*                                  save becomes array(     y,     x )
*                 array(     y,     x ) becomes array(     x, yswap )
*                 array(     x, yswap ) becomes array( yswap, xswap )
*                 array( yswap, xswap ) becomes array( xswap,     y )
*                 array( xswap,     y ) becomes save
*                 where xswap is the maximum extent to be rotated +1 - x
*                 and   yswap is the maximum extent to be rotated +1 - y
*              End for
*           End for
*        Else
*           Number of right angles to rotate is incorrect
*           Set status and report error
*        Endif
*     Endif

*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate.  The
*     ARRAY argument must have the data type specified.
*     - If the number of right-angles for rotation is not 1, 2, or 3
*     then STATUS will be set to SAI__ERROR and an error reported.

*  Copyright:
*     Copyright (C) 1983-1984, 1986, 1988-1989 Science & Engineering
*     Research Council. Copyright (C) 1995 Central Laboratory of the
*     Research Councils. All Rights Reserved.

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
*     DB: Dave Baines (ROE)
*     MJC: Malcolm J. Currie (Starlink)
*     {enter_new_authors_here}

*  History:
*     27/07/1983 (DB):
*        Original version.
*     17/02/1984 (DB):
*        Documentation brought up to date.
*     1986 September 9 (MJC):
*        Renamed parameters section to arguments and tidied.
*     1988 Jun 22 (MJC):
*        Added identification to error reporting plus an
*        extra status check.
*     1989 August 7 (MJC):
*        Passed array dimensions as separate variables.
*     1995 May 16 (MJC):
*        Made generic from ROTAS2.  Used an SST prologue and modern
*        variable declarations.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing allowed
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SAE global constants
 
*  Arguments Given:
      INTEGER XSIZE
      INTEGER YSIZE
      INTEGER XEXT
      INTEGER YEXT
      INTEGER NUMRA
 
*  Arguments Given and Returned:
      DOUBLE PRECISION ARRAY( XSIZE, YSIZE )
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER HRANGE             ! Half of MRANGE, i.e. half of max.
                                 ! extent to be rotated
      INTEGER MRANGE             ! Maximum of XEXT and YEXT
      DOUBLE PRECISION SAVE               ! Saves a value from array during the
                                 ! rotation
      INTEGER X                  ! Index to array element, first  dim
      INTEGER XSWAP              ! Index to rotated element position,
                                 ! first dimension
      INTEGER Y                  ! Index to array element, second  "
      INTEGER YSWAP              ! Index to rotated element position,
                                 ! second dimension
*.
 
*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      IF ( NUMRA .EQ. 1 ) THEN
 
*  Rotate 90 degrees clockwise.
*  ============================
         MRANGE = MAX( XEXT, YEXT )
         HRANGE = MRANGE / 2
         DO X = 1 , HRANGE
            XSWAP = MRANGE + 1 - X
 
            DO Y = X, MRANGE - X
               YSWAP = MRANGE + 1 - Y
 
*  Swap the values using an intermediate variable.
               SAVE = ARRAY( XSWAP, Y )
               ARRAY( XSWAP, Y ) = ARRAY( YSWAP, XSWAP )
               ARRAY( YSWAP, XSWAP ) = ARRAY( X, YSWAP )
               ARRAY( X, YSWAP ) = ARRAY( Y, X )
               ARRAY( Y, X ) = SAVE
            END DO
         END DO
 
      ELSE IF ( NUMRA .EQ. 2 ) THEN
 
*  Rotate through 180 degrees.
*  ===========================
         HRANGE = YEXT / 2
         DO Y = 1, HRANGE
            YSWAP = YEXT + 1 - Y
 
            DO X = 1, XEXT
               XSWAP = XEXT + 1 - X
 
*  Swap the values using an intermediate variable.
               SAVE = ARRAY( X, Y )
               ARRAY( X, Y ) = ARRAY( XSWAP, YSWAP )
               ARRAY( XSWAP, YSWAP ) = SAVE
            END DO
         END DO
 
*  Check for an odd Y dimension.  If there is one, there is an extra
*  row to rotate.
         IF ( MOD( YEXT, 2 ) .NE. 0 ) THEN
 
            Y = HRANGE + 1
            DO X = 1, XEXT / 2
               XSWAP = XEXT + 1 - X
 
*  Swap the values using an intermediate variable.
               SAVE = ARRAY( X, Y )
               ARRAY( X, Y ) = ARRAY( XSWAP, Y )
               ARRAY( XSWAP, Y ) = SAVE
            END DO
         END IF
 
      ELSE IF ( NUMRA .EQ. 3 ) THEN
 
*  Rotate 90 degrees anticlockwise, equivalent to 270 degrees clockwise.
*  =====================================================================
         MRANGE = MAX( XEXT, YEXT )
         HRANGE = MRANGE / 2
         DO  X = 1, HRANGE
            XSWAP = MRANGE + 1 - X
 
            DO  Y = X, MRANGE - X
               YSWAP = MRANGE + 1 - Y
 
*  Swap the values using an intermediate variable.
               SAVE = ARRAY( Y, X )
               ARRAY( Y, X ) = ARRAY( X, YSWAP )
               ARRAY( X, YSWAP ) = ARRAY( YSWAP, XSWAP )
               ARRAY( YSWAP, XSWAP ) = ARRAY( XSWAP, Y )
               ARRAY( XSWAP, Y ) = SAVE
            END DO
         END DO
      ELSE
 
*  Number of clockwise right-angles to be rotated is wrong so report an
*  error.
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'NUMRA', NUMRA )
         CALL ERR_REP( 'KPS1_RORAx_MRANGL',
     :     'KPS1_RORAx: The number of right-angle rotations cannot be '/
     :     /'^NUMRA (programming error).', STATUS )
      END IF
 
      END
