/*
*+
*  Name:
*     smf_obsmode_str

*  Purpose:
*     Return string representation of observation mode enum

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     const char * smf_obsmode_str( smf_obsmode mode, int * status );

*  Arguments:
*     type = smf_obsmode (Given)
*        Obsmode code to convert to string.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:
*     const char* = Pointer to constant string corresponding to obs mode
*                   Can be NULL pointer if type is unrecognized.

*  Description:
*     This function returns a string representation of the underlying
*     observing type. Returns NULL pointer if the data type is not recognized.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-07-24 (TIMJ):
*        Initial version, copied from smf_dtype_str.

*  Notes:
*     - See also smf_dtype_str, smf_obstype_str

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     Copyright (C) 2006 Particle Physics and Astronomy Research Council.
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

/* System includes */
#include <string.h>

/* Starlink includes */
#include "ast.h"
#include "sae_par.h"
#include "mers.h"

/* SMURF includes */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

/* Simple default string for errRep */
#define FUNC_NAME "smf_obsmode_str"

const char * smf_obsmode_str( smf_obsmode mode, int * status ) {

  /* Set a default value */
  const char * retval = NULL;
  
  /* Check entry status */
  if (*status != SAI__OK) return retval;

  /* now switch on data type */
  switch( mode ) {
  case SMF__OBS_NULL:
    retval = NULL;
    break;
  case SMF__OBS_DREAM:
    retval = "dream";
    break;
  case SMF__OBS_STARE:
    retval = "stare";
    break;
  case SMF__OBS_SCAN:
    retval = "scan";
    break;
  default:
    retval = NULL;
  }

  return retval;
}
