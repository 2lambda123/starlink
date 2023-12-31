      SUBROUTINE NDG_NDFCP( IGRP, INDEX, FTYPE, NDIM, UBND, INDF,
     :                      STATUS )
*+
*  Name:
*     NDG_NDFCP

*  Purpose:
*     Obtain an NDF identifier for a new primitive NDF.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDG_NDFCP( IGRP, INDEX, FTYPE, NDIM, UBND, INDF, STATUS )

*  Description:
*     The routine returns an NDF identifier for a new primitive NDF created
*     with the specified attributes. The name of the new NDF is held
*     at a given index within a given group. It is equivalent to NDF_CREP.

*  Arguments:
*     IGRP = INTEGER (Given)
*        A GRP identifier for a group holding the names of NDFs. This
*        will often be created using NDG_CREAT, but groups created "by
*        hand" using GRP directly can also be used.
*     INDEX = INTEGER (Given)
*        The index within the group at which the name of the NDF to be
*        created is stored.
*     FTYPE = CHARACTER * ( * ) (Given)
*        Type of the NDF's DATA component (e.g. '_REAL'). Note that
*        complex types are not permitted when creating a primitive NDF.
*     NDIM = INTEGER (Given)
*        Number of NDF dimensions.
*     UBND( NDIM ) = INTEGER (Given)
*        Upper pixel-index bounds of the NDF (the lower bound of each
*        dimension is taken to be 1).
*     INDF = INTEGER (Returned)
*        NDF identifier.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2010-2011 Science & Technology Facilities Council.
*     Copyright (C) 1999 Central Laboratory of the Research Councils.
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
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
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     DSB: D.S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     24-AUG-1999 (DSB):
*        Original version.
*     7-MAR-2006 (DSB):
*        Switch off interpretation of shell metacharacters by HDS.
*     2010-03-18 (TIMJ):
*        Use PSX_WORDEXP instead of ONE_SHELL_ECHO
*     2011-03-08 (TIMJ):
*        Use ONE_WORDEXP_NOGLOB
*     25-SEP-2020 (DSB):
*        Changed to be a thin wrapper round NDG_NDFCP8.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants

*  Arguments Given:
      INTEGER IGRP
      INTEGER INDEX
      CHARACTER FTYPE*(*)
      INTEGER NDIM
      INTEGER UBND( NDIM )

*  Arguments Returned:
      INTEGER INDF

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I
      INTEGER*8 UBND8( NDF__MXDIM )
*.

*  Set an initial value for the INDF argument.
      INDF = NDF__NOID

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Convert the supplied INTEGER bounds to INTEGER*8
      DO I = 1, NDIM
         UBND8( I ) = UBND( I )
      END DO

*  Call the 8-byte version of this routine.
      CALL NDG_NDFCP8( IGRP, INDEX, FTYPE, NDIM, UBND8, INDF, STATUS )

      END
