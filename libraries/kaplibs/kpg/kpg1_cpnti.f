      SUBROUTINE KPG1_CPNTI( PNNDF, PNTIT, NDIM, DIMS, ARRAY, NULL,
     :                         STATUS )
*+
*  Name:
*     KPG1_CPNTx
 
*  Purpose:
*     Creates a primitive NDF with a title via the parameter system.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_CPNTx( PNNDF, PNTIT, NDIM, DIMS, ARRAY, NULL, STATUS )
 
*  Description:
*     This routine packages a common series of NDF calls when creating
*     a primitive NDF, whose name is obtained from the parameter system,
*     and also obtaining its title from the parameter system.  The need
*     to handle an optional output file via the null character is
*     catered.  The data type of the NDF data array is the same as the
*     supplied array.  An NDF context is started and ended within this
*     routine.
 
*  Arguments:
*     PNNDF = CHARACTER * ( * ) (Given)
*        The ADAM parameter name to obtain the name of the output NDF.
*     PNTIT = CHARACTER * ( * ) (Given)
*        The ADAM parameter name to obtain the title of the output NDF.
*     NDIM = INTEGER (Given)
*        The number of dimensions in the NDF's data array.
*     DIMS( NDIM ) = INTEGER (Given)
*        The dimensions of the NDF's data array.
*     ARRAY( * ) = ? (Given)
*        The array to be placed in the primitive NDF's data array.
*     NULL = LOGICAL (Given)
*        If true a null value returned by either parameter GET is
*        annulled.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate. The
*     data array supplied to the routine must have the data type
*     specified.
 
*  Implementation Deficiencies:
*     More sophisticated parameters to offer more flexibility.  For
*     example, to return the NDF identifier for other operations and
*     not call NDF_END.
*     {routine_deficiencies}...
 
*  [optional_subroutine_items]...
*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council.
*     Copyright (C) 2004 Central Laboratory of the Research Councils.
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
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}
 
*  History:
*     1991 June 28 (MJC):
*        Original version.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     {enter_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PAR_ERR'          ! Parameter-system error constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
 
*  Arguments Given:
      CHARACTER * ( * ) PNNDF
      CHARACTER * ( * ) PNTIT
      INTEGER NDIM
      INTEGER DIMS( NDIM )
      INTEGER ARRAY( * )
      LOGICAL NULL
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER
     :  EL,                      ! Number of elements in the data array
     :  IERR,                    ! Location of first conversion error
                                 ! (not used)
     :  NDFO,                    ! NDF identifier
     :  NERR,                    ! Number of conversion errors
                                 ! (not used)
     :  OPNTR( 1 )               ! Pointer to the data array
 
*.
 
*    Check the inherited global status.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*    Start a new error context.
 
      CALL ERR_MARK
 
*    Start a new NDF context.
 
      CALL NDF_BEGIN
 
*    Create a new NDF.
 
      CALL LPG_CREP( PNNDF, '_INTEGER', NDIM, DIMS, NDFO, STATUS )
 
*    Map the data array.  Wrap to prevent line overflow when the token
*    is expanded.
 
      CALL KPG1_MAP( NDFO, 'Data', '_INTEGER', 'WRITE', OPNTR, EL,
     :              STATUS )
 
*    Get the title for the NDF.
 
      CALL NDF_CINP( PNTIT, NDFO, 'TITLE', STATUS )
 
*    Write the array to the file's data array.  There can be no
*    conversion errors so they are not checked.
 
      CALL VEC_ITOI( .FALSE., EL, ARRAY, %VAL( CNF_PVAL( OPNTR( 1 ) ) ),
     :                   IERR, NERR, STATUS )
 
*    Handle the null case invisibly.
 
      IF ( NULL .AND. STATUS .EQ. PAR__NULL ) CALL ERR_ANNUL( STATUS )
 
*    Close down the NDF system.
 
      CALL NDF_END( STATUS )
 
*    Release the new error context.
 
      CALL ERR_RLSE
 
      END
