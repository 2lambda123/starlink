      SUBROUTINE COF_NHEAD( FUNIT, FILE, NCARD, STATUS )
*+
*  Name:
*     COF_NHEAD

*  Purpose:
*     Obtains the number of FITS headers in the current HDU.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL COF_NHEAD( FUNIT, FILE, NCARD, STATUS )

*  Description:
*     This routine merely obtains the number of FITS headers in the
*     current header and data unit.  It takes care of any error
*     status.  It exists because this code is needed by many
*     subroutines.

*  Arguments:
*     FUNIT = INTEGER (Given)
*        The FITSIO unit number for the FITS file.
*     FILE = CHARACTER * ( * ) (Given)
*        The name of the FITS file or device being converted.  This is
*     NCARD = INTEGER (Returned)
*        The number of FITS header cards in the current HDU.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Prior Requirements:
*     The FITS file must be open.

*  Copyright:
*     Copyright (C) 1997 Central Laboratory of the Research Councils.
*     Copyright (C) 2013 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1997 November 16 (MJC):
*        Original version.
*     18-DEC-1997 (DSB):
*        Added statement to initialise FSTAT to FITSOK.
*     2013 August 12 (MJC):
*        Allow for blank headers immediately before the END card.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER FUNIT
      CHARACTER * ( * ) FILE

*  Arguments Returned:
      INTEGER NCARD

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Length of a string less trailing
                                 ! blanks

*  Local Constants:
      INTEGER FITSOK             ! Good status for FITSIO library
      PARAMETER( FITSOK = 0 )

*  Local Variables:
      CHARACTER*200 BUFFER       ! Buffer for error messages
      CHARACTER*80 CARD          ! Header card
      INTEGER FSTAT              ! FITSIO error status
      INTEGER KEYADD             ! Number of headers which can be added
      LOGICAL MORE               ! Reached the END card?
      INTEGER NCF                ! Number of characters in the file name

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Find the number of FITS headers.
      FSTAT = FITSOK
      CALL FTGHSP( FUNIT, NCARD, KEYADD, FSTAT )

      IF ( FSTAT .NE. FITSOK ) THEN

*  Get the length of the filename.
         NCF = CHR_LEN( FILE )

*  Report an error if something has gone wrong.
         BUFFER = 'Error obtaining the number of header cards from '/
     :            /'the FITS file '//FILE( :NCF )//'.'
         CALL CVG_FIOER( FSTAT, 'COF_NHEAD_NCARD',
     :                  'FTGHSP', BUFFER, STATUS )
      END IF

*  FTGHSP returns the number of headers excluding the END card and
*  blank headers before the END card.  Allow for any trailing blank
*  headers.
      MORE = .TRUE.
      DO WHILE ( MORE )
         NCARD = NCARD + 1
         CALL FTGREC( FUNIT, NCARD, CARD, FSTAT )

*  Assume that an error here is due to a lack of an END header and the
*  the headers are exhausted.
         IF ( FSTAT .NE. FITSOK ) THEN
            MORE = .FALSE.
            NCARD = NCARD - 1
            FSTAT = FITSOK
         ELSE IF ( CARD( 1:8 ) .EQ. 'END     ' ) THEN
            MORE = .FALSE.
            NCARD = NCARD - 1
         END IF
      END DO

      END
