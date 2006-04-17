      SUBROUTINE KPG1_CPNDI( NDIM, LBNDI, UBNDI, IN, LBNDO, UBNDO, OUT, 
     :                         EL, STATUS )
*+
*  Name:
*     KPG1_CPNDI

*  Purpose:
*     Copy a section of an n-dimensional array

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_CPNDI( NDIM, LBNDI, UBNDI, IN, LBNDO, UBNDO, OUT, EL,
*                        STATUS )

*  Description:
*     This routine copies a specified section of the supplied 
*     n-dimensional array (IN) to an output array (OUT).

*  Arguments:
*     NDIM = INTEGER (Given) 
*        The number of axes.
*     LBNDI( NDIM ) = INTEGER (Given) 
*        The lower pixel index bounds of the IN array.
*     UBNDI( NDIM ) = INTEGER (Given) 
*        The upper pixel index bounds of the IN array.
*     IN( * ) = INTEGER (Given)
*        The input array. Bounds given by LBNDI and UBNDI.
*     LBNDO( NDIM ) = INTEGER (Given) 
*        The lower pixel index bounds of the area of the IN array to be 
*        copied to OUT. 
*     UBNDO( NDIM ) = INTEGER (Given) 
*        The upper pixel index bounds of the area of the IN array to be 
*        copied to OUT. 
*     OUT( * ) = INTEGER (Returned)
*        The output array. Bounds given by LBNDO and UBNDO.
*     EL = INTEGER (Returned)
*        The number of elements in the output array. Derived from LBNDO
*        and UBNDO. 
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*    -  If the output array is not completely contained within the input
*    array, then the sections of the output array which fall outside the 
*    input arrays will be filled with bad values.

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils.
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
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     30-JUN-1999 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants

*  Arguments Given:
      INTEGER NDIM
      INTEGER LBNDI( NDIM )
      INTEGER UBNDI( NDIM )
      INTEGER IN( * )
      INTEGER LBNDO( NDIM )
      INTEGER UBNDO( NDIM )

*  Arguments Returned:
      INTEGER OUT( * )
      INTEGER EL

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER CDIM( NDF__MXDIM)  ! Dimensions of overlap region
      INTEGER CLBND( NDF__MXDIM) ! Lower bounds of overlap region 
      INTEGER CUBND( NDF__MXDIM) ! Upper bounds of overlap region 
      INTEGER IIN                ! Index into vectorised input array
      INTEGER IOUT               ! Index into vectorised output array
      INTEGER ISTRID( NDF__MXDIM)! Axis strides in input array
      INTEGER J                  ! Axis index
      INTEGER OSTRID( NDF__MXDIM)! Axis strides in output array
      INTEGER PIX( NDF__MXDIM )  ! Pixel indices of next pixel to copy
      LOGICAL MORE               ! More pixels to copy?
      LOGICAL OVLAP              ! Is there any overlap between o/p and i/p?
      LOGICAL WITHIN             ! Is o/p array completly within i/p aray?
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get the bounds of the area common to the input and output arrays.
*  Also set a flag if the entire output array falls within the input 
*  array (i.e. if no part of the output array falls outside the input
*  array). Also set a flag if there is any overlap between the input 
*  and output arrays (i.e. if the entire output array does not fall
*  outside the input array).
      WITHIN = .TRUE.
      OVLAP = .TRUE. 

      DO J = 1, NDIM

         IF( LBNDO( J ) .LT. LBNDI( J ) ) THEN
            CLBND( J ) = LBNDI( J ) 
            WITHIN = .FALSE.
         ELSE
            CLBND( J ) = LBNDO( J ) 
         END IF
       
         IF( UBNDO( J ) .GT. UBNDI( J ) ) THEN
            CUBND( J ) = UBNDI( J ) 
            WITHIN = .FALSE.
         ELSE
            CUBND( J ) = UBNDO( J ) 
         END IF

         IF( CLBND( J ) .GT. CUBND( J ) ) OVLAP = .FALSE.

      END DO

*  Now set up the strides for each axis in the output array. To 
*  increase axis J by one in OUT move forward by OSTRID( J ) elements 
*  in the vectorised array.
      OSTRID( 1 ) = 1
      DO J = 1, NDIM - 1
         OSTRID( J + 1 ) = OSTRID( J )*( UBNDO( J ) - LBNDO( J ) + 1 )
      END DO

*  Store the number of elements in the output array.
      EL = OSTRID( NDIM )*( UBNDO( NDIM ) - LBNDO( NDIM ) + 1 )

*  Only the section of the output array which falls within the input array
*  will have values copied to it. The rest of the output array needs to
*  be filled with bad values. Fill the entire output array with bad
*  values now, and then replace these bad values as required. We only
*  need to do this if some part of the output array falls outside the
*  input arrays.
      IF( .NOT. WITHIN .OR. .NOT. OVLAP ) THEN
         DO IOUT = 1, EL
            OUT( IOUT ) = VAL__BADI
         END DO
      END IF

*  Skip to the end if there is no overlap between the input and 
*  output arrays, returning the bad values stored above.
      IF( OVLAP ) THEN

*  Set up the strides for each axis in the input array. To increase 
*  axis I by one in IN, move forward by ISTRID( I ) elements in the 
*  vectorised array.
         ISTRID( 1 ) = 1
         DO J = 1, NDIM - 1
            ISTRID( J + 1 ) = ISTRID( J )*( UBNDI( J ) - 
     :                                      LBNDI( J ) + 1 )
         END DO

*  Store the dimensions of the area to be copied.
         DO J = 1, NDIM
            CDIM( J ) = CUBND( J ) - CLBND( J ) + 1 
         END DO

*  Find the index within the input vectorised array corresponding to the
*  the first pixel within the section to be copied. Also, find the index 
*  within the output vectorised array corresponding to the the first 
*  pixel within the section to be copied. Also, store the indices of the
*  first pixel to be copied.
         IIN = 1
         IOUT = 1
         DO J = 1, NDIM
            IIN = IIN + ( CLBND( J ) - LBNDI( J ) )*ISTRID( J )
            IOUT = IOUT + ( CLBND( J ) - LBNDO( J ) )*OSTRID( J )
            PIX( J ) = CLBND( J )
         END DO

*  Loop round every pixel in the area to be copied.
         MORE = .TRUE.
         DO WHILE( MORE )

*  Copy the current pixel.
            OUT( IOUT ) = IN( IIN )

*  Get the index on the first axis of the next pixel to be copied.
            PIX( 1 ) = PIX( 1 ) + 1            

*  Correpondingly increase the vectorised indices.
            IOUT = IOUT + 1
            IIN = IIN + 1

*  If we are now beyond the end of this axis, increment the next axis by
*  one and reset this axis to the lower bound. Do this until an axis does
*  not overflow, or the final axis has overflowed.
            J = 1
            DO WHILE( PIX( J ) .GT. CUBND( J ) .AND. MORE )

*  Reset the pixel index on this axis to the lower bound.
               PIX( J ) = CLBND( J )

*  This has moved us backwards by CDIM( J ) pixels on axis J. Reduce the
*  vector indices in the input and output arrays to take account of this.
               IIN = IIN - CDIM( J )*ISTRID( J )
               IOUT = IOUT - CDIM( J )*OSTRID( J )

*  Move on to the next axis.
               J = J + 1

*  If there are no more axes to increment, we have reached the end of the 
*  array, so leave the loops.
               IF( J .GT. NDIM ) THEN
                  MORE = .FALSE.

*  Otherwise...
               ELSE

*  Increment the pixel index on this new axis by 1.
                  PIX( J ) = PIX( J ) + 1

*  Increase the vector indices in the input and output arrays to take 
*  account of this move of one pixel.
                  IOUT = IOUT + OSTRID( J )
                  IIN = IIN + ISTRID( J )
               END IF               

            END DO

         END DO

      END IF

      END 
