/*
*+
*  Name:
*     REMSKY

*  Purpose:
*     Top-level SKY removal implementation

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
*     This is the main routine implementing the sky removal task.

*  ADAM Parameters:
*     IN = NDF (Read)
*          Input file(s)
*     METHOD = CHAR (Read)
*          Sky removal method, either POLY or PLANE
*     GROUP = LOGICAL (Read)
*          If true, group related files together for processing as a
*          single data set, else process each file independently
*     FIT = CHAR (Read)
*          Type of fit to be carried out for the PLANE sky removal
*          method. Choices are Mean, Slope (to fit in elevation only)
*          or Plane
*     OUT = NDF (Write)
*          Output file(s)

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2006-02-16 (AGG):
*        Initial test version
*     2006-12-20 (TIMJ):
*        Open related files in UPDATE mode to prevent overwrite of propogated components
*     {enter_further_changes_here}

*  Notes:
*     At the moment no check is made on whether the extinction
*     correction has already been applied.

*  Copyright:
*     Copyright (C) 2006 University of British Columbia and the Particle Physics
*     and Astronomy Research Council. All Rights Reserved.

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
  int flag;                  /* Flag for how group is terminated */
  int i;                     /* Loop counter */
  Grp *igrp = NULL;          /* Input group */
  smfData *odata = NULL;     /* Output data struct */
  Grp *ogrp = NULL;          /* Output group */
  int outsize;               /* Total number of NDF names in the output group */
  int size;                  /* Number of files in input group */

  char method[LEN__METHOD];  /* String for sky subtraction method */
  char fittype[LEN__METHOD]; /* String for PLANE method fit type */

  smfArray *relfiles = NULL; /* Array of related files */
  int group = 0;             /* Parameter to determine whether or not
				to group related files */
  smfGroup *ogroup = NULL;   /* Group storing related files */

  int indf;
  int outndf;
  void *outdata[1];         /* Pointer to array of output mapped pointers*/
  int nout;

  /* Main routine */
  ndfBegin();

  /* Read the input file */
  ndgAssoc( "IN", 1, &igrp, &size, &flag, status );

  /* Get output file(s): assumes a 1:1 correspondence between input
     and output files */
  ndgCreat( "OUT", igrp, &ogrp, &outsize, &flag, status );

  /* Check the Grp sizes are the same */
  if ( outsize != size ) {
    msgSeti("S",size);
    msgSeti("O",outsize);
    *status = SAI__ERROR;
    errRep( FUNC_NAME, "Size of output group, ^O != size of input group, ^S", status);
  }

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

  if ( group ) {
    /* Propagate input files to output */
    for (i=1; i<=size; i++) {
      /* This seems inefficient but it works */
      smf_open_and_flatfield( igrp, ogrp, i, &odata, status );
      smf_close_file( &odata, status);
    }
    /* Group output files together now that they exist */
    smf_grp_related( ogrp, outsize, 1, &ogroup, status );
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
    for (i=1; i<=size; i++) {
      /* Flatfield - if necessary */
      smf_open_and_flatfield( igrp, ogrp, i, &odata, status );

      if (*status == SMF__FLATN) {
	errAnnul( status );
	msgOutif(MSG__VERB, "",
		 TASK_NAME ": Data are already flatfielded", status);
      } else if ( *status == SAI__OK) {
	msgOutif(MSG__VERB," ","Flatfield applied", status);
      } else {
	/* Tell the user which file it was... */
	msgSeti("I",i);
	errRep(TASK_NAME, "Unable to flatfield data from the ^I th file", status);
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
    }
  }

  /* Tidy up after ourselves: release the resources used by the grp routines  */
  grpDelet( &igrp, status);
  grpDelet( &ogrp, status);

  ndfEnd( status );
}
