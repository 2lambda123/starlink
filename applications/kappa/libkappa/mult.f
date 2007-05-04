      SUBROUTINE MULT( STATUS )
*+
*  Name:
*     MULT

*  Purpose:
*     Multiplies two NDF data structures.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL MULT( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     The routine multiplies two NDF data structures pixel-by-pixel to
*     produce a new NDF.

*  Usage:
*     mult in1 in2 out

*  ADAM Parameters:
*     IN1 = NDF (Read)
*        First NDF to be multiplied.
*     IN2 = NDF (Read)
*        Second NDF to be multiplied.
*     OUT = NDF (Write)
*        Output NDF to contain the product of the two input NDFs.
*     TITLE = LITERAL (Read)
*        Value for the title of the output NDF.  A null value will cause
*        the title of the NDF supplied for parameter IN1 to be used
*        instead. [!]

*  Examples:
*     mult a b c
*        This multiplies the NDF called a by the NDF called b, to make
*        the NDF called c.  NDF c inherits its title from a.
*     mult out=c in1=a in2=b title="Normalised spectrum"
*        This multiplies the NDF called a by the NDF called b, to make
*        the NDF called c.  NDF c has the title "Normalised spectrum".

*  Notes:
*     If the two input NDFs have different pixel-index bounds, then
*     they will be trimmed to match before being multiplied.  An error
*     will result if they have no pixels in common.

*  Related Applications:
*     KAPPA: ADD, CADD, CDIV, CMULT, CSUB, DIV, MATHS, SUB.

*  Implementation Status:
*     -  This routine correctly processes the AXIS, DATA, QUALITY,
*     LABEL, TITLE, HISTORY, WCS and VARIANCE components of an NDF data
*     structure and propagates all extensions.
*     -  The UNITS component is propagated only if it has the same value
*     in both input NDFs.
*     -  Processing of bad pixels and automatic quality masking are
*     supported.
*     -  All non-complex numeric data types can be handled.
*     Calculations will be performed using either real or double
*     precision arithmetic, whichever is more appropriate.  If the
*     input NDF structures contain values with other data types, then
*     conversion will be performed as necessary.

*  Copyright:
*     Copyright (C) 1990, 1992 Science & Engineering Research Council.
*     Copyright (C) 1995, 1998, 2004 Central Laboratory of the Research
*     Councils. All Rights Reserved.

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
*     RFWS: R.F. Warren-Smith (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     9-APR-1990 (RFWS):
*        Original version.
*     1992 January 15 (MJC):
*        Added Usage and Examples items.
*     1995 September 12 (MJC):
*        Title inherited by default.  Usage and examples to lowercase.
*        Added Related Applications.
*     5-JUN-1998 (DSB):
*        Added propagation of the WCS component.
*     2004 September 3 (TIMJ):
*        Use CNF_PVAL
*     5-MAY-2007 (DSB):
*        Propagate the Unit value if it is the same in both NDFs.
*     {enter_further_changes_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER CLIST*30         ! List of NDF components to copy
      CHARACTER COMP*13          ! NDF component list to be mapped
      CHARACTER DTYPE*( NDF__SZFTP ) ! Data type for output components
      CHARACTER FORM*( NDF__SZFRM ) ! Form of the NDF
      CHARACTER ITYPE*( NDF__SZTYP ) ! Data type for processing
      CHARACTER UNIT1*30         ! Units string from NDF1
      CHARACTER UNIT2*30         ! Units string from NDF2
      INTEGER EL                 ! Number of mapped elements
      INTEGER NDF1               ! Identifier for 1st NDF (input)
      INTEGER NDF2               ! Identifier for 2nd NDF (input)
      INTEGER NDF3               ! Identifier for 3rd NDF (output)
      INTEGER NERR               ! Number of errors
      INTEGER PNTR1( 2 )         ! Pointers to 1st NDF mapped arrays
      INTEGER PNTR2( 2 )         ! Pointers to 2nd NDF mapped arrays
      INTEGER PNTR3( 2 )         ! Pointers to 3rd NDF mapped arrays
      LOGICAL BAD                ! Need to check for bad pixels?
      LOGICAL VAR                ! Process variance?
      LOGICAL VAR1               ! Variance component in 1st input NDF?
      LOGICAL VAR2               ! Variance component in 2nd input NDF?

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an NDF context.
      CALL NDF_BEGIN

*  Obtain identifiers for the two input NDFs.
      CALL LPG_ASSOC( 'IN1', 'READ', NDF1, STATUS )
      CALL LPG_ASSOC( 'IN2', 'READ', NDF2, STATUS )

*  Trim the input pixel-index bounds to match.
      CALL NDF_MBND( 'TRIM', NDF1, NDF2, STATUS )

*  See if the Units are the same.
      UNIT1 = ' '
      CALL NDF_CGET( NDF1, 'Unit', UNIT1, STATUS )
      UNIT2 = ' '
      CALL NDF_CGET( NDF2, 'Unit', UNIT2, STATUS )

*  Determine the list of components to be propagated from NDF1. We only
*  propagate the Unit component if it is the same in both input NDFs.
      IF( UNIT1 .EQ. UNIT2 .AND. UNIT1 .NE. ' ' ) THEN
         CLIST = 'WCS,Axis,Quality,Unit'
      ELSE
         CLIST = 'WCS,Axis,Quality'
      END IF 

*  Create a new output NDF based on the first input NDF. Propagate the
*  WCS, axis and quality components.
      CALL LPG_PROP( NDF1, CLIST, 'OUT', NDF3, STATUS )

*  See whether a variance component is defined in both the input NDFs
*  and set the list of components to be processed accordingly.
      CALL NDF_STATE( NDF1, 'Variance', VAR1, STATUS )
      CALL NDF_STATE( NDF2, 'Variance', VAR2, STATUS )
      VAR = VAR1 .AND. VAR2
      IF ( VAR ) THEN
         COMP = 'Data,Variance'
      ELSE
         COMP = 'Data'
      END IF

*  Determine which data type to use to process the input arrays and set
*  an appropriate data type in the output NDF.
      CALL NDF_MTYPE('_INTEGER,_REAL,_DOUBLE',
     :                NDF1, NDF2, COMP, ITYPE, DTYPE, STATUS )
      CALL NDF_STYPE( DTYPE, NDF3, COMP, STATUS )

*  Map the input and output arrays.
      CALL KPG1_MAP( NDF1, COMP, ITYPE, 'READ', PNTR1, EL, STATUS )
      CALL KPG1_MAP( NDF2, COMP, ITYPE, 'READ', PNTR2, EL, STATUS )
      CALL KPG1_MAP( NDF3, COMP, ITYPE, 'WRITE', PNTR3, EL, STATUS )

*  Merge the bad pixel flag values for the input arrays to see if
*  checks for bad pixels are needed.
      CALL NDF_MBAD( .TRUE., NDF1, NDF2, COMP, .FALSE., BAD, STATUS )

*  Select the appropriate routine for the data type being processed and
*  multiply the arrays.

*  Integer data...
      IF ( ITYPE .EQ. '_INTEGER' ) THEN
         CALL KPG1_MULI( BAD, VAR, EL,
     :                   %VAL( CNF_PVAL( PNTR1( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR1( 2 ) ) ),
     :                   %VAL( CNF_PVAL( PNTR2( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR2( 2 ) ) ),
     :                   %VAL( CNF_PVAL( PNTR3( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR3( 2 ) ) ),
     :                   NERR, STATUS )

*  Real data...
      ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
         CALL KPG1_MULR( BAD, VAR, EL,
     :                   %VAL( CNF_PVAL( PNTR1( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR1( 2 ) ) ),
     :                   %VAL( CNF_PVAL( PNTR2( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR2( 2 ) ) ),
     :                   %VAL( CNF_PVAL( PNTR3( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR3( 2 ) ) ),
     :                   NERR, STATUS )

*  Double precision data...
      ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
         CALL KPG1_MULD( BAD, VAR, EL,
     :                   %VAL( CNF_PVAL( PNTR1( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR1( 2 ) ) ),
     :                   %VAL( CNF_PVAL( PNTR2( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR2( 2 ) ) ),
     :                   %VAL( CNF_PVAL( PNTR3( 1 ) ) ), 
     :                   %VAL( CNF_PVAL( PNTR3( 2 ) ) ),
     :                   NERR, STATUS )
      END IF

*  See if there may be bad pixels in the output arrays and set the
*  output bad pixel flag value accordingly unless the output NDF is
*  primitive.
      BAD = BAD .OR. ( NERR .NE. 0 )
      CALL NDF_FORM( NDF3, 'Data', FORM, STATUS )

      IF ( FORM .NE. 'PRIMITIVE' ) THEN
         CALL NDF_SBAD( BAD, NDF3, 'Data', STATUS )
      END IF

*  Obtain a title for the output NDF.
      CALL NDF_CINP( 'TITLE', NDF3, 'Title', STATUS )
      
*  End the NDF context.
      CALL NDF_END( STATUS )

*  If an error occurred, then report context information.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'MULT_ERR',
     :   'MULT: Error multiplying two NDF data structures.', STATUS )
      END IF

      END
