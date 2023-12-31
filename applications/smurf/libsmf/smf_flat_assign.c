/*
*+
*  Name:
*     smf_flat_assign

*  Purpose:
*     Copy flatfield parameters to a smfDA from a flatfield smfData

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_flat_assign ( int use_da, smf_flatmeth flatmeth, double refres,
*                       const smfData * powval, const smfData * bolval,
*                       smfData * updata, int *status );

*  Arguments:
*     use_da = int (Given)
*        If true smfDA information will be copied from bolval's smfDA. If false
*        smfDA information will be copied from the main data arrays of bolval
*        and powval.
*     flatmeth = smf_flatmeth (Given)
*        Flatfield method. Only used if use_da is false.
*     refres = double (Given)
*        Reference resistor value used to calculate the flatfield. Will be ignored
*        if the smfDA is being accessed.
*     powval = const smfData * (Given)
*        Power values to be copied into the flatpar entry of smfDA. The size of
*        powval will correspond to the "nflat" entry of smfDA. Can be NULL if
*        use_da is true.
*     bolval = const smfData * (Given)
*        If use_da is true, the smfDA structure will be used. If use_da is false
*        the data array will be copied to the flatcal entry. If a smfDA is present
*        it will be assumed to contain heater values and other flatfield information
*        that will also be copied (if non-null).
*     updata = smfData * (Given)
*        The smfData to receive the updated flatfield information. "heatval" will
*        only be updated if present in bolval, otherwise it will be left unchanged.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Assigns new flatfield information to a smfData. Copied either from
*     a reference smfDA supplied inside a smfData or copied from two smfDatas
*     containing the flatfield solution (as generated by smf_flat_smfData).

*  Notes:
*     - Does not touch non-flatfield components of the output smfDA.
*     - Creates a smfDA if not present.

*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2010-03-10 (TIMJ):
*        Original version
*     2010-03-16 (TIMJ):
*        Update the FLAT fits header
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2010 Science and Technology Facilities Council.
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
*     Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
*     MA 02110-1301, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#include "smf_typ.h"
#include "smf.h"
#include "smurf_par.h"

#include "star/one.h"
#include "mers.h"
#include "prm_par.h"
#include "sae_par.h"

void smf_flat_assign ( int use_da, smf_flatmeth inflatmeth, double inrefres,
                       const smfData * powval, const smfData * bolval,
                       smfData * updata, int *status ) {

  dim_t nbols = 0;        /* Number of bolometers */
  smfDA * outda = NULL;    /* Pointer to output smfDA */

  /* Local copies of incoming flatfield values */
  double * flatcal = NULL;
  smf_flatmeth flatmeth = SMF__FLATMETH_NULL;
  double * flatpar = NULL;
  int nflat = 0;
  double * heatval = NULL;
  dim_t nheat = 0;
  double refres = VAL__BADD;

  if (*status != SAI__OK) return;

  if (!bolval) {
    *status = SAI__ERROR;
    errRep( "", "flat_assign: bolval is a NULL pointer (possible programming error)",
            status );
    return;
  }

  if (use_da) {
    smfDA * inda = NULL;

    if (!bolval->da) {
      *status = SAI__ERROR;
      errRep( "", "flat_assign: No smfDA in supplied bolval (possible programming error)",
              status );
      return;
    }

    /* Get values from incoming smfDA */
    inda = bolval->da;
    nflat = inda->nflat;
    nheat = inda->nheat;
    flatcal = inda->flatcal;
    flatpar = inda->flatpar;
    heatval = inda->heatval;
    flatmeth = inda->flatmeth;
    refres = inda->refres;

  } else {
    smfDA * bolda = NULL;

    if (!powval) {
      *status = SAI__ERROR;
      errRep( "", "flat_assign: powval is a NULL pointer (possible programming error)",
              status );
      return;
    }

    /* Get values from the smfDatas */
    flatmeth = inflatmeth;
    refres = inrefres;
    nflat = (int) (bolval->dims)[2];
    flatpar = (powval->pntr)[0];
    flatcal = (bolval->pntr)[0];

    /* see if bolval has a smfDA */
    bolda = bolval->da;
    if (bolda) {
      heatval = bolda->heatval;
      nheat = bolda->nheat;
    }

  }

  /* Number of bolometers comes from bolval */
  nbols = (bolval->dims)[0] * (bolval->dims)[1];

  /* Get the output smfDA. smf_construct_smfDA should really use astRealloc
     if called when it already has values. */
  outda = updata->da;
  if (!outda) {
    outda = smf_create_smfDA( status );
  }

  if (*status == SAI__OK) {
    outda->nflat = nflat;
    outda->flatmeth = flatmeth;
    outda->refres = refres;

    outda->flatcal = astRealloc( outda->flatcal, nbols * nflat * sizeof(*(outda->flatcal)) );
    outda->flatpar = astRealloc( outda->flatpar, nflat * sizeof(*(outda->flatpar)) );
    /* optional */
    if (heatval && nheat) {
      outda->nheat = nheat;
      outda->heatval = astRealloc( outda->heatval, nheat * sizeof(*(outda->heatval)) );
      if (outda->heatval) memcpy( outda->heatval, heatval, nheat * sizeof(*heatval));
    }

    if (*status == SAI__OK) {
      memcpy( outda->flatcal, flatcal, nbols * nflat * sizeof(*flatcal) );
      memcpy( outda->flatpar, flatpar, nflat * sizeof(*flatpar) );
    }

    /* if we have a filename in bolval copy it to the FLAT FITS header */
    if ( bolval->file && strlen(bolval->file->name) && updata->hdr && updata->hdr->fitshdr ) {
      char buffer[SZFITSTR];
      int oplen = 0;
      errMark();
      smf_smfFile_msg( bolval->file, "FILE", 1, "<none>" );
      msgLoad( "", "^FILE", buffer, sizeof(buffer), &oplen, status );
      errRlse();
      smf_fits_updateS( updata->hdr, "FLAT", buffer,
                        "Name of flat-field file", status );
    }

  }

  return;

}
