      SUBROUTINE SCULIB_PUT_FITS_C (MAX_FITS, N_FITS, FITS, NAME,
     :  VALUE, COMMENT, STATUS)
*+
*  Name:
*     SCULIB_PUT_FITS_C

*  Purpose:
*     write a string to a FITS item specified

*  Description:
*     This routine  writes a FITS character item into a character array
*     ready to be written out to the .MORE.FITS structure in an NDF file.
*     An error will be reported and bad status returned if the name of the
*     FITS item is blank or more than 8 characters long. An error will also
*     occur if the FITS character array is full.

*  Invocation:
*     CALL SCULIB_PUT_FITS_C (MAX_FITS, N_FITS, FITS, NAME, VALUE,
*    :  COMMENT, STATUS)

*  Arguments:
*     MAX_FITS                       = INTEGER (Given)
*           the size of the FITS array
*     N_FITS                         = INTEGER (Given and returned)
*           the number of FITS items currently in the FITS array
*     FITS (MAX_FITS)                = CHARACTER*80 (Given and returned)
*           array containing the FITS items
*     NAME                           = CHARACTER*(*) (Given)
*           the name of the FITS item to be written
*     VALUE                          = CHARACTER*(*) (Given)
*           the value to be assigned to the item
*     COMMENT                        = CHARACTER*(*) (Given)
*           a comment applying to the FITS item
*     STATUS                         = INTEGER (Given and returned)
*           global status


*  Authors:
*     J.Lightfoot (jfl@roe.ac.uk)
*     T.Jenness (timj@jach.hawaii.edu)

*  Copyright:
*     Copyright (C) 1995,1996,1997,1998,1999 Particle Physics and Astronomy
*     Research Council. All Rights Reserved.

*  Method:

*  Deficiencies:

*  Bugs:


*  History:
*     $Id$
*     15-AUG-1995: original version
*     $Log$
*     Revision 1.5  2000/06/03 03:08:45  timj
*     Correctly recognise the END keyword
*
*     Revision 1.4  1999/08/19 03:37:18  timj
*     Header tweaks to ease production of SSN72 documentation.
*
*     Revision 1.3  1999/08/03 19:35:19  timj
*     Add copyright message to header.
*     Convert old header style to new.
*
*     Revision 1.2  1997/10/16 19:48:08  timj
*     Make sure the comment character is always included in the string.
*
*    endhistory

*-


*  Type Definitions:
      IMPLICIT NONE

*  Global constants:
      INCLUDE 'SAE_PAR'

*  Arguments Given:
      INTEGER MAX_FITS
      CHARACTER*(*) NAME
      CHARACTER*(*) VALUE
      CHARACTER*(*) COMMENT

*  Arguments Given & Returned:
      INTEGER N_FITS
      CHARACTER*(80) FITS (MAX_FITS)

*  Arguments Returned:

*  Status:
      INTEGER STATUS

*  External references:
      INTEGER CHR_LEN                      ! CHR used string length function

*  Global variables:

*  Local Constants:

*  Local variables:
      INTEGER CPTR                         ! index of start of comment
      INTEGER NCHAR                        ! used length of VALUe

*  Internal References:

*  Local data:

*.

      IF (STATUS .NE. SAI__OK) RETURN

      IF (N_FITS .LE. 0) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP (' ', 'SCULIB_PUT_FITS_C: bad input value of '//
     :     'N_FITS', STATUS)
      ELSE IF (N_FITS+1 .GT. MAX_FITS) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP (' ', 'SCULIB_PUT_FITS_C: size of FITS array '//
     :     'has been exceeded', STATUS)
      ELSE IF (CHR_LEN(NAME) .GT. 8) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETC ('NAME', NAME)
         CALL ERR_REP (' ', 'SCULIB_PUT_FITS_C: invalid name for '//
     :     'FITS item - ^NAME', STATUS)
      ELSE IF (CHR_LEN(NAME) .EQ. 0) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP (' ', 'SCULIB_PUT_FITS_C: blank name given '//
     :     'for FITS item', STATUS)
      ELSE IF (FITS(N_FITS) .NE. 'END') THEN
         STATUS = SAI__ERROR
         CALL ERR_REP(' ','SCULIB_PUT_FITS_C: Last card was not END',
     :        STATUS)
      ELSE
*     This will overwrite the existing END card
         FITS (N_FITS) = NAME
         FITS (N_FITS)(9:11) = '= '''
         FITS (N_FITS)(12:) = VALUE

         NCHAR = CHR_LEN (VALUE)
         IF (NCHAR .LT. 8) THEN
            NCHAR = 8
         ELSE IF (NCHAR .GT. 66) THEN
            NCHAR = 66
         END IF
         FITS (N_FITS)(NCHAR+12:NCHAR+12) = ''''

         CPTR = MAX (32,NCHAR+14)

*     The fits string MUST include the comment character
         FITS (N_FITS)(CPTR:CPTR) = '/'

         IF (CPTR+2 .LE. 80) THEN
            FITS (N_FITS)(CPTR+2:) = COMMENT
         END IF

*     Increment the number of keywords
         N_FITS = N_FITS + 1

*     Rewrite the END card
         FITS(N_FITS) = 'END'

      END IF
      END
