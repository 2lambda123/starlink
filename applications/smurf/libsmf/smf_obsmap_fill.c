/*
*+
*  Name:
*     smf_obsmap_fill

*  Purpose:
*     Extract descriptive information from an observation information and store in AstKeyMap

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     SMURF subroutine

*  Invocation:
*     smf_obsmap_fill( const smfData * data, AstKeyMap * obsmap,
*                      AstKeyMap * objmap, int * status);

*  Arguments:
*     data = const smfData * (Given)
*        A particular data file. Ignored if the information from this
*        OBSID has already been stored.
*     obsmap = AstKeyMap * (Given)
*        Key map to receive information. A new key map is stored using the
*        OBSID as key.
*     objmap = AstKeyMap * (Given)
*        KeyMap with keys of object name. The values are irrelevant. Used to
*        track unique object names.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Extracts information from an observation and stores it in an AstKeyMap
*     indexed by OBSID. Can be used to report observation information to the user.
*     Also stores object information in simple AstKeyMap.

*  See Also:
*     smf_obsmap_report for writing observation to the user once filled in with
*     all information.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2009-04-24 (TIMJ):
*        Initial version. Some code relocated from smf_find_darks.
*     2009-05-21 (TIMJ):
*        Store SWMODE
*     2009-05-25 (TIMJ):
*        Store SIMULATE information

*  Copyright:
*     Copyright (C) 2008, 2009 Science and Technology Facilities Council.
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

/* System includes */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "msg_par.h"
#include "star/one.h"
#include "ast.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

void smf_obsmap_fill( const smfData * data, AstKeyMap * obsmap, AstKeyMap * objmap,
                      int * status ) {

  char object[SZFITSCARD]; /* Object name */
  char obsid[SZFITSCARD]; /* Observation ID */
  AstKeyMap * obsinfo = NULL; /* observation information */


  if (*status != SAI__OK) return;

  /* if there is no hdr we can not index it in the reported summary */
  if (data->hdr && data->hdr->fitshdr) {

    /* Get observation ID and see if we already have an entry in the map */
    (void)smf_getobsidss( data->hdr->fitshdr, obsid, sizeof(obsid), NULL, 0, status );
    /* As of 20080718 OBSID is not unique per obs so chop off date*/
    obsid[22] = '\0';

    if (!astMapHasKey(obsmap, obsid )) {
      int itemp;

      /* Create a sub keymap and populate it */
      obsinfo = astKeyMap( " " );
      /* fill with default value in case undefined */
      one_strlcpy( object, "<undefined>", sizeof(object), status );
      smf_getfitss( data->hdr, "OBJECT", object, sizeof(object),
                    status );
      astMapPut0C( obsinfo, "OBJECT", object, NULL );
      astMapPut0I( obsinfo, "OBSMODE", data->hdr->obsmode, NULL );
      astMapPut0I( obsinfo, "OBSTYPE", data->hdr->obstype, NULL );
      astMapPut0I( obsinfo, "SWMODE", data->hdr->swmode, NULL );
      smf_fits_getI( data->hdr, "OBSNUM", &itemp, status );
      astMapPut0I( obsinfo, "OBSNUM", itemp, NULL );
      smf_fits_getI( data->hdr, "UTDATE", &itemp, status );
      astMapPut0I( obsinfo, "UTDATE", itemp, NULL );
      smf_fits_getL( data->hdr, "SIMULATE", &itemp, status );
      astMapPut0I( obsinfo, "SIMULATE", itemp, NULL );

      /* store information in the global observation map
         and also track how many distinct objects we have */
      astMapPut0A( obsmap, obsid, obsinfo, NULL );
      astMapPut0I( objmap, object, 0, NULL );
    }
  }

  return;
}
