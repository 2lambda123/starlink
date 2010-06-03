/*
*+
*  Name:
*     smf_cso2filt_tau

*  Purpose:
*     Convert tau referenced to the CSO to a filter tau value

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     double smf_cso2filt_tau( const smfHead *hdr, double csotau,
*                              AstKeyMap * extpars, int * status );

*  Arguments:
*     hdr = const smfHead* (Given)
*        Header struct from data struct
*     csotau = double (Given)
*        225GHz tau value. Will be obtained from the header if it
*        is VAL__BADD.
*     extpars = AstKeyMap * (Given)
*        AST keymap containing the parameters required to convert
*        the tau (on the CSO scale) to the current filter. Must
*        contain the "taurelation" key which itself will be a keymap
*        containing the parameters for the specific filter.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine returns the optical depth for the given SCUBA-2
*     filter based on the supplied CSO tau value.

*  Notes:
*     - Returns a value of VAL__BADD if status is set bad on entry
*     - The tau relation is formulated as:
*          tau_filt = a ( tau_cso + b )
*       and the keymap should contain an entry named "taurelation_FILT"
*       containing "a" and "b".
*     - The routine will not attempt to guess a tau relation.

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-12-16 (TIMJ):
*        Initial version
*     2010-06-02 (TIMJ):
*        Add external extinction parameters. No longer calls smf_scale_tau.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2008,2010 Science and Technology Facilities Council.
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

/* Starlink includes */
#include "sae_par.h"
#include "prm_par.h"
#include "mers.h"

/* SMURF includes */
#include "smf.h"

double smf_cso2filt_tau( const smfHead *hdr, double csotau, AstKeyMap * extpars, int *status) {
  double coeffs[2];        /* Tau relation coefficients */
  char filter[81];         /* somewhere for the filter name */
  int nvals;               /* Number of elements in keymap item */
  double tau = VAL__BADD;  /* return filter tau */
  AstKeyMap * taumap = NULL; /* tau relation keymap */


  if (*status != SAI__OK) return tau;

  /* do we need to get our own value */
  if (csotau == VAL__BADD) {
    csotau = smf_calc_meantau( hdr, status );
  }

  /* Get the filter name */
  smf_fits_getS( hdr, "FILTER", filter, sizeof(filter), status);

  /* The supplied keymap is the "ext" entry from the config file so we first need
     to get the "taurelation" keymap */
  astMapGet0A( extpars, "TAURELATION", &taumap );

  /* Now look for the filter */
  if (astMapGet1D( taumap, filter, 2, &nvals, coeffs )) {
    tau = coeffs[0] * ( csotau + coeffs[1] );

  } else {
    if (*status == SAI__OK) *status = SAI__ERROR;
    errRepf( "", "Unable to obtain tau scaling for filter '%s'",
             status, filter );
  }

  return tau;
}
