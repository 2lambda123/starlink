/*
*+
*  Name:
*     one_strlcat

*  Purpose:
*     Starlink compliant wrapper around the BSD strlcat function.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Description:
*     The strlcat function is similar to the strncat function except
*     that it guarantees to nul terminate the destination string
*     and returns the number of characters that will have been copied.
*     This wrapper function provides standard Starlink inherited status
*     semantics.

*  Invocation:
*     len = one_strlcat( char * dest, const char * src,
*                        size_t sizedest, int * status );

*  Arguments:
*     dest = char * (Returned)
*        Destination buffer for "src". Must be nul-terminated.
*        If status is bad on entry, "dest" will not be touched.
*     src = const char * (Given)
*        String to be appended onto "dest".
*     sizedest = size_t (Given)
*        The actual buffer size of "dest" including space for a nul.
*     status = int * (Given and Returned)
*        Inherited status. Will be set to ONE__TRUNC if the string
*        was truncated on copy.

*  Returned Value:
*     size_t retval
*        Length of the string after appending. Will either be
*        the length of the source string plus destination string 
*        or one less than the size of the destination buffer if truncation
*        was detected.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-07-11 (TIMJ):
*        Initial version.

*  Notes:
*     - This is for use from C only. 
*     - If available the system strlcat routine will be used.

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}

*-
*/

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "ems.h"
#include "one.h"
#include "one_err.h"
#include "sae_par.h"

#include <stdlib.h>

/* Use local or remote strlcpy */
#if HAVE_STRLCPY
#  include <string.h>
#else
size_t strlcat( char * dst, const char * src, size_t size);
#include "strlcat.c"
#endif


size_t
one_strlcat( char * dest, const char * src, size_t size, int * status ) {
  size_t retval = 0;
  
  if (*status != SAI__OK) return retval;

  /* Trap null pointers - since strlcat won't */
  if (!dest) {
    *status = SAI__ERROR;
    emsRep( " ", "one_strlcat: Destination string is a NULL pointer "
            "(possible programming error)", status);
  }
  if (!src) {
    *status = SAI__ERROR;
    emsRep( " ", "one_strlcat: Source string is a NULL pointer "
            "(possible programming error)", status);
  }

  /* BSD function */
  retval = strlcat( dest, src, size );

  if (retval >= size) {
    *status = ONE__TRUNC;
    emsSetc("SRC", src);
    emsSeti("I", (int)size);
    emsSeti("S", (int)retval);
    emsRep( " ", "Truncated string when appending characters into buffer "
           "of size ^I (needed ^S characters)", status);
    /* return the actual length of the new string - we know it was truncated
       so just return the size that is actually relevant */
    retval = size - 1;
  }
  
  return retval;
}
