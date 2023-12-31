/*
*+
* Name:
*    gsdFind

* Purpose:
*    Find GSD item by name.

* Language:
*    ANSI C

* Type of Module:
*    C function.

* Invocation:
*    int gsdFind( const GSDFileDesc *file_dsc, const GSDItemDesc *item_dsc,
*       char *name, int *itemno,
*       char *unit, char *type, char *array );

* Prototype:
*    available via #include "gsd.h"
 *    int gsdFind( const GSDFileDesc *file_dsc, const GSDItemDesc *item_dsc,
 *       char *name, int *itemno,
 *       char *unit, char *type, char *array );

* Description:
*    This routine looks up the GSD item specified by its name and returns the
*    number of the item. This routine also returns the unit string, the type
*    specification and the array flag.

* Arguments:
*    const GSDFileDesc *file_dsc (Given)
*       The GSD file descriptor related to the file opened on fptr.
*    const GSDItemDesc *item_dsc (Given)
*       The array of GSD item descriptors related to the file opened on fptr.
*    char *data_ptr (Given)
*       The buffer with all the data from the GSD file opened on fptr.
*    char *name (Given)
*       The name of the item. This should be an array of 16 characters (char
*       name[16]) and a null-terminated string.
*    int *itemno (Returned)
*       The number of the item in the GSD file.
*    char *unit (Returned)
*       The unit of the item. This should be an array of 11 characters (char
*       name[11]) and will be a null-terminated string.
*    char *type (Returned)
*       The data type of the item. This is a single character and one of
*       B, L, W, I, R, D, C.
*    char *array (Returned)
*       The array flag. This is a single character and true (false) if the
*       item is (is not) and array.

* Returned value:
*    int gsdFind();
*       Status.
*        -[1:] If the named item cannot be found.
*        -[0:] Otherwise.

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

* Authors:
*    jhf: Jon Fairclough (UKTH)
*    rp: Rachael Padman (MRAO)
*    hme: Horst Meyerdierks (UoE, Starlink)
*    timj: Tim Jenness (JAC, Hawaii)

* History:
*    08 Sep 1986 (jhf):
*       Original.
*    28 Jul 1987 (jhf):
*       Make comparison caseless.
*    21 Jan 1988 (jhf):
*       Improve code modularisation.
*    17 Jul 1994 (rp):
*       Adaption to Remo's C code.
*    02 Dec 1994 (hme):
*       Translation to C. Interface revised.
*    04 Jul 2008 (timj):
*       use proper GSD structs rather than void. use const.

* Copyright:
*    Copyright (C) 2008 Science and Technology Facilities Council.
*    Copyright (C) 1986-1999 Particle Physics and Astronomy Research Council.
*    All Rights Reserved.
*-
*/

#include <stdio.h>
#include <string.h>
#include "gsd1.h"
#include "gsd.h"

/*:
 */

int gsdFind( const GSDFileDesc *file_dsc, const GSDItemDesc *item_dsc,
             const char name[], int *itemno,
             char *unit, char *type, char *array )
{
   static char dtypes[] = "BLWIRDC";
   int  status;
   char tname[GSD_SZCHAR+1]; /* temp string for consting */

/*.
 */

   /* Copy from input const string to temporary buffer for use by
      gsd1_getval */
   strncpy(tname, name, GSD_SZCHAR );
   tname[GSD_SZCHAR] = '\0';

/* Only access the header in this routine with MODE=1 --- i.e. Remo's
 * route for finding the item number given the name. Then use MODE=2
 * access in GSD_GET... routines.  Possibly more complicated than
 * necessary, but retains compatibility with the GSD library itself.
 */
   status = gsd1_getval( file_dsc, item_dsc, NULL, 1, 0, tname,
      itemno, 0, 0, NULL );
   if ( status < 0 ) { status = 1; goto abort; }
   else                status = 0;

/* Set other returned values.
 */
   *array = ( (item_dsc+(*itemno)-1)->array != 0 );
   *type  = dtypes[(item_dsc+(*itemno)-1)->data_type-1];
   (void) memcpy( unit, (item_dsc+(*itemno)-1)->unit, 10 ); unit[10] = '\0';

/* Return.
 */
   abort:
   return status;
}
