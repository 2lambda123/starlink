/*
*+
*  Name:
*     REMSKY

*  Purpose:
*     Remove sky background from SCUBA-2 data

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_remsky( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This command can be used to investigate the sky signal from a SCUBA-2 time
*     series file.

*  ADAM Parameters:
*     BPM = NDF (Read)
*          Group of files to be used as bad pixel masks. Each data file
*          specified with the IN parameter will be masked. The corresponding
*          previous mask for a subarray will be used. If there is no previous
*          mask the closest following will be used. It is not an error for
*          no mask to match. A NULL parameter indicates no mask files to be
*          supplied. [!]
*     FIT = CHAR (Read)
*          Type of fit to be carried out for the PLANE sky removal
*          method. Choices are Mean, Slope (to fit in elevation only)
*          or Plane
*     GROUP = LOGICAL (Read)
*          If true, group related files together for processing as a
*          single data set, else process each file independently
*     IN = NDF (Read)
*          Input file(s)
*     METHOD = CHAR (Read)
*          Sky removal method, either POLY or PLANE
*     MSG_FILTER = _CHAR (Read)
*          Control the verbosity of the application. Values can be
*          NONE (no messages), QUIET (minimal messages), NORMAL,
*          VERBOSE, DEBUG or ALL. [NORMAL]
*     OUT = NDF (Write)
*          Output file(s)
*     OUTFILES = LITERAL (Write)
*          The name of text file to create, in which to put the names of
*          all the output NDFs created by this application (one per
*          line). If a null (!) value is supplied no file is created. [!]

*  Related Applications:
*     SMURF: EXTINCTION, MAKEMAP;
*     SURF: REMSKY

*  Notes:
*     - The iterative map-maker will calculate the sky signal itself and this
*     command should not be used if that variant of the map-maker is to be used.

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (JAC, Hawaii)
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-02-16 (AGG):
*        Initial test version
*     2006-12-20 (TIMJ):
*        Open related files in UPDATE mode to prevent overwrite of propogated 
*        components
*     2008-04-17 (EC):
*        Modified smf_grp_related interface
*     2008-04-18 (EC):
*        Modified smf_grp_related interface
*     2008-04-30 (TIMJ):
*        Tidy up logic (no longer need to trap for SMF__FLATN.
*        Update data file title.
*     2008-07-22 (TIMJ):
*        Use kaplibs for group param in/out. Handle darks.
*     2008-12-12 (TIMJ):
*        Add BPM masking.
*     2009-03-30 (TIMJ):
*        Add OUTFILES parameter.
*     {enter_further_changes_here}

*  Notes:
*     At the moment no check is made on whether the extinction
*     correction has already been applied.

*  Copyright:
*     Copyright (C) 2006, 2008 University of British Columbia.
*     Copyright (C) 2006 Particle Physics and Astronomy Research Council.
*     Copyright (C) 2008-2009 Science and Technology Facilities Council.
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

/* Standard includes */
#include <string.h>
#include <stdio.h>

/* Starlink includes */
#include "prm_par.h"
#include "sae_par.h"
#include "ast.h"
#include "ndf.h"
#include "mers.h"
#include "par.h"
#include "star/ndg.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "smurflib.h"
#include "smurf_par.h"
#include "libsmf/smf_err.h"

/* Simple default string for errRep */
#define FUNC_NAME "smurf_remsky"
#define TASK_NAME "REMSKY"
#define LEN__METHOD 20

void smurf_remsky( int * status ) {

  /* Local Variables */
  smfArray *bpms = NULL;     /* Bad pixel masks */
  smfArray *darks = NULL;    /* Dark data */
  Grp *fgrp = NULL;          /* Filtered group, no darks */
  size_t i;                  /* Loop counter */
  Grp *igrp = NULL;          /* Input group */
  smfData *odata = NULL;     /* Output data struct */
  Grp *ogrp = NULL;          /* Output group */
  size_t outsize;            /* Total number of NDF names in the output group */
  size_t size;               /* Number of files in input group */

  char method[LEN__METHOD];  /* String for sky subtraction method */
  char fittype[LEN__METHOD]; /* String for PLANE method fit type */

  smfArray *relfiles = NULL; /* Array of related files */
  int group = 0;             /* Parameter to determine whether or not
                                to group related files */
  smfGroup *ogroup = NULL;   /* Group storing related files */

  /* Main routine */
  ndfBegin();

  /* Read the input file */
  kpg1Rgndf( "IN", 0, 1, "", &igrp, &size, status );

  /* Filter out darks */
  smf_find_darks( igrp, &fgrp, NULL, 1, SMF__NULL, &darks, status );

  /* input group is now the filtered group so we can use that and
     free the old input group */
  size = grpGrpsz( fgrp, status );
  grpDelet( &igrp, status);
  igrp = fgrp;
  fgrp = NULL;

  if (size > 0) {
    /* Get output file(s) */
    kpg1Wgndf( "OUT", igrp, size, size, "More output files required...",
               &ogrp, &outsize, status );
  } else {
    msgOutif(MSG__NORM, " ","All supplied input frames were DARK,"
             " nothing to sky remove", status );
  }

  if (*status != SAI__OK) goto CLEANUP;

  /* Get group of pixel masks and read them into a smfArray */
  smf_request_mask( "BPM", &bpms, status );

  /* Get sky subtraction METHOD */
  parChoic( "METHOD", "PLANE", "Plane, Polynomial", 1,  method, 
            LEN__METHOD, status);

  /* Do we want to group related files? */
  parGet0l( "GROUP", &group, status);

  /* Get desired plane-fitting method */
  if ( strncmp( method, "PL", 2 ) == 0 ) {
    /* Timeslice-based sky removal */
    parChoic( "FIT", "SLOPE", "Mean, Slope, Plane", 
              1, fittype, LEN__METHOD, status);
  }

  if (*status != SAI__OK) goto CLEANUP;

  if ( group ) {
    /* Propagate input files to output */
    for (i=1; i<=size; i++) {
      /* This seems inefficient but it works */
      smf_open_and_flatfield( igrp, ogrp, i, darks, &odata, status );
      /* Mask out bad pixels - mask data array not quality array */
      smf_apply_mask( odata, NULL, bpms, SMF__BPM_DATA, status );
      smf_close_file( &odata, status);
    }
    /* Group output files together now that they exist */
    smf_grp_related( ogrp, outsize, 1, 0, NULL, &ogroup, NULL, status );
    if ( *status == SAI__OK ) {
      /* Open and process related files */
      for (i=0; i<ogroup->ngroups; i++) {
        smf_open_related( ogroup, i, "UPDATE", &relfiles, status );
        smf_subtract_plane( NULL, relfiles, fittype, status );
        smf_close_related( &relfiles, status );
      }
    }
    smf_close_smfGroup( &ogroup, status );
  } else {
    for (i=1; i<=size && *status == SAI__OK; i++) {
      /* Flatfield - if necessary */
      smf_open_and_flatfield( igrp, ogrp, i, darks, &odata, status );

      /* Mask out bad pixels - mask data array not quality array */
      smf_apply_mask( odata, NULL, bpms, SMF__BPM_DATA, status );

      if (*status != SAI__OK) {
        /* Tell the user which file it was... */
        msgSeti("I",i);
        errRep(TASK_NAME, "Unable to open file ^I", status);
      }
      if ( *status == SAI__OK ) {
        if ( strncmp( method, "POLY", 4 ) == 0 ) {
          /* Bolometer-based sky removal */
          smf_subtract_poly( odata, NULL, 0, status );
          /* Check status */
        } else if ( strncmp( method, "PLAN", 4 ) == 0 ) {
          /* Timeslice-based sky removal */
          smf_subtract_plane( odata, NULL, fittype, status );
        } else {
          *status = SAI__ERROR;
          msgSetc("M", method);
          errRep(TASK_NAME, "Unsupported method, ^M. Possible programming error.", status);
        }
      }

      /* Set character labels */
      smf_set_clabels( "Sky-removed",NULL, NULL, odata->hdr, status);
      smf_write_clabels( odata, status );

      /* Tidy */
      smf_close_file( &odata, status );
    }
  }

  /* Write out the list of output NDF names, annulling the error if a null
     parameter value is supplied. */
  if( *status == SAI__OK ) {
    grpList( "OUTFILES", 0, 0, NULL, ogrp, status );
    if( *status == PAR__NULL ) errAnnul( status );
  }

  /* Tidy up after ourselves: release the resources used by the grp routines  */
 CLEANUP:
  if (darks) smf_close_related( &darks, status );
  if (bpms) smf_close_related( &bpms, status );
  grpDelet( &igrp, status);
  grpDelet( &ogrp, status);

  ndfEnd( status );
}
