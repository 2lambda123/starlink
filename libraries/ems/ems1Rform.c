/*
*+
*  Name:
*     EMS1RFORM

*  Purpose:
*     Reformat the given text to a new width.

*  Language:
*     Starlink ANSI C

*  Invocation:
*     ems1Rform( text, maxlen, iposn, string, strlength )

*  Description:
*     This subroutine is called repeatedly to reformat the given
*     text string to a new width (given by maxlen). The returned line always
*     has a ragged right margin. The text in the returned string is formatted
*     to end at a word end. A word in this context is a contiguous
*     string of non-blank characters.

*  Arguments:
*     text = char* (Given)
*        The character variable which contains the text to be
*        reformatted. Leading blanks are preserved.
*     maxlen = const int (Given)
*        Maximum width of output string
*     iposn = int* (Given and Returned)
*        On entry, this argument specifies the character position in
*        TEXT from which to start generating the next returned line.
*        It is given as the number of characters from the first
*        character in TEXT. If a value less than 1 is used, then 1 will
*        be used. If a value greater than the declared length of the
*        returned string is given, the returned string is initialised to
*        blank space and IPOSN is reset to zero.
*
*        On exit, this argument is set to one more than the position
*        in TEXT of the last blank character which appears in the
*        returned line STRING (i.e. the position at which the
*        generation of the next output line should start). When the end
*        of the given string is reached, IPOSN is returned set to zero.
*     string = char* (Returned)
*        The returned line of text, left justified. The length of this
*        argument defines the maximum length of the returned line.
*     strlength = int* (Returned)
*        The used length of STRING.

*  Notes:
*     -  This routine should be called repeatedly to generate
*     successive returned lines from the given text.  Initially, the
*     pointer IPOSN should be set to unity; it will be updated after
*     each call, ready to generate the next returned line. A value of
*     zero is returned for IPOSN when there is no more text to
*     process. Trailing blanks in the given text are ignored, multiple
*     blanks between words are maintained, a single blank is dropped in
*     multiple blanks which occur at a new returned line.

*  Authors:
*     PCTR: P.C.T. Rees (STARLINK)
*     AJC: A.J. Chipperfield (STARLINK)
*     RTP: R.T. Platon (STARLINK)
*     PWD: Peter W. Draper (JAC, Durham University)
*     {enter_new_authors_here}

*  History:
*     11-APR-1991 (PCTR):
*        Original FORTRAN version.
*     14-FEB-2001 (RTP):
*        Rewritten in C based on the Fortran routine EMS1_PFORM
*      6-MAR-2001 (AJC):
*        Added maxlen argument
*        Copy strings not assign pointers
*     21-SEP-2001 (AJC):
*        Handle case of no suitable break on line.
*        Correct calculation of ilast (-1)
*      7-DEC-2005 (PWD):
*        Return blank string and zero IPOSN when the input IPOSN is
*        greater than the length of STRING (as per description of 
*        IPOSN in prologue).
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

#include <string.h>
#include "ems1.h"                    /* EMS_ Internal functions */
#include "ems_sys.h"

void ems1Rform( const char *text, const int maxlen, int *iposn, char *string,
                int *strlength  ) {
   int ilast;              /* Last allowed index of the substring */
   int iplen;              /* Used length of the given text */
   int istart;             /* Start index of substring */

   TRACE("ems1Rform");

/*  Get the declared lengths of the given and returned character
 *  variables. */
   iplen = strlen( text );

/*  If the given string is not empty and the starting position does not
 *  lie beyond the end of the given text, then there is potentially
 *  something to return. */
   if ( ( iplen > 0 ) && ( *iposn < iplen ) ) {

/*     if the starting position is before the beginning of the string,
 *     advance it to the first character position. */
      if ( *iposn < 0 ) *iposn=0;

/*     Initialise the start index, ISTART, and the allowed length,
 *     ILAST, of the given string. */
      istart = *iposn;
      ilast = istart + maxlen - 1;

/*     Check whether the entire given substring will fit into the
 *     returned string. */
      if ( ilast > iplen ) {
/*        The given substring can fit into the returned string, assign
 *        the returned string and update the returned pointer. */
         (void)strcpy( string, &text[ istart ] );
         *strlength = iplen - istart;
         *iposn = 0;

      } else {
/*        Loop backwards through the given substring to find the last
 *        blank space that will fit into the returned string. */
         for ( *iposn = ilast; *iposn >= istart; (*iposn)-- ) {
            if ( text[ *iposn ] == ' ' ) break;
         }
/*        If no space was found output the whole chunk */
         if ( *iposn <= istart ) *iposn = ilast;

/*        Assign the returned string and update the returned string
 *        length and character pointer. */
         *iposn = *iposn + 1;
         (void)strncpy(
                string, (char*)&text[ istart ],(size_t)(*iposn-istart) );
         string[*iposn-istart] = '\0';
         *strlength = *iposn - istart;
      }
   }
   else if ( ( iplen > 0 ) && ( *iposn >= iplen ) ) {
/*     Cannot print beyond end of string, set result to blank and iposn to
 *     zero as per contract */
       string = "";
       *iposn = 0;
   }

   return;
}
