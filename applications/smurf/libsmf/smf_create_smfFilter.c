/*
*+
*  Name:
*     smf_create_smfFilter

*  Purpose:
*     Allocate an empty smfFilter structure

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     pntr = smf_create_smfFilter( smfData *template, int *status );

*  Arguments:
*     template = smfData * (Given)
*        Pointer to smfData to obtain dim and df
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:
*     Pointer to newly created smfFilter. NULL on error.

*  Description: This function allocates memory for a smfFilter
*     structure. The length and frequency step size are determined,
*     but the buffer itself is not initialized. Depending on the type
*     of filter the buffer may be either real- or complex-valued.
*     Here it is initialized to NULL - it will get allocated by
*     smf_filter_* routines.

*  Notes:

*  Authors:
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2008-06-05 (EC):
*        Initial version
*     2008-06-11 (EC):
*        Enable the use of 1-D templates
*     2008-06-12 (EC):
*        -Switch to split real/imaginary arrays for smfFilter
*     2008-06-18 (EC):
*        Fixed error in calculation of df (frequency steps)
*     2008-06-23 (EC):
*        Generate WCS that can be used when writing filter to an NDF
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 Particle Physics and Astronomy Research
*     Council. University of British Columbia. All Rights Reserved.

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
#include <stdlib.h>
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_create_smfFilter"

smfFilter *smf_create_smfFilter( smfData *template, int *status ) {

  AstFrame *cframe=NULL;        /* Current real/imag frame */
  AstUnitMap *cmapping=NULL;    /* Mapping from grid to cframe */
  AstCmpFrame *curframe2d=NULL; /* Current Frame for 2-d FFT */
  smfFilter *filt=NULL;         /* Pointer to returned struct */
  AstCmpMap *fftmapping=NULL;   /* Mapping from GRID to curframe2d */
  AstShiftMap *zshiftmapping=NULL;  /* Map to shift origin of GRID */
  AstZoomMap *scalemapping=NULL;/* Scale grid coordinates by df */
  AstSpecFrame *specframe=NULL; /* Current Frame of 1-D spectrum */
  AstCmpMap *specmapping=NULL;  /* Mapping from GRID to FREQ */
  double steptime;              /* Length of a sample in seconds */
  double zshift;                /* Amount by which to shift origin */

  if (*status != SAI__OK) return NULL;

  filt = smf_malloc( 1, sizeof(smfFilter), 0, status );

  if( *status == SAI__OK ) {
    filt->real = NULL;
    filt->imag = NULL;
    filt->isComplex = 0;
    filt->wcs = NULL;

    if( template ) {
      if( template->ndims == 3 ) {
        if( template->isTordered ) { /* T is 3rd axis if time-ordered */
          filt->ntslice = template->dims[2];
        } else {                     /* T is 1st axis if time-ordered */
          filt->ntslice = template->dims[0];
        }

      } else if( template->ndims == 1 ) {
        /* If 1-d data, only one axis to choose from */
        filt->ntslice = template->dims[0];
      } else {
        *status = SAI__ERROR;
        errRep( FUNC_NAME, "smfData template is not 3d", status );
      }

      if( *status == SAI__OK ) {

        /* The actual length is ntslice/2+1 because the input bolo data is
           real; FFTW optimizes memory usage in this case since the
           negative frequencies in the transform contain the same
           information as the positive frequencies */
        filt->dim = filt->ntslice/2+1;

        if( template->hdr ) {
          /* Figure out length of a sample in order to calculate df */
          smf_fits_getD(template->hdr, "STEPTIME", &steptime, status);
          
          if( *status == SAI__OK ) {

            /* Start an AST context */
            astBegin;

            /* Frequency step in Hz */
            filt->df = 1. / (steptime * (double) filt->ntslice); 

            /* Create a new FrameSet containing a 2d base GRID frame */

            filt->wcs = astFrameSet( astFrame( 2, "Domain=GRID" ), "" );

            /* The current frame will have freq. along first axis, and
               real/imag coefficients along the other */

            specframe = astSpecFrame( "System=freq,Unit=Hz,StdOfRest=Topocentric" );
            cframe = astFrame( 1, "Domain=GRID" );
            curframe2d = astCmpFrame( specframe, cframe, "" ); 

            /* The mapping from 2d grid coordinates to (frequency, coeff) is
               accomplished with a shift and a zoommap for the 1st dimension,
               and a unit mapping for the other */

            zshift = -1;
            zshiftmapping = astShiftMap( 1, &zshift, "" ); 
            scalemapping = astZoomMap( 1, filt->df, "" );
            specmapping = astCmpMap( zshiftmapping, scalemapping, 1, "" );
            
            cmapping = astUnitMap( 1, "" );

            fftmapping = astCmpMap( specmapping, cmapping, 0, "" );

            /* Add the curframe2d with the fftmapping to the frameset */
            astAddFrame( filt->wcs, AST__BASE, fftmapping, curframe2d );

            /* Export the frameset before ending the AST context */
            astExport( filt->wcs );
            astEnd;
          }



        } else {
          *status = SAI__ERROR;
          errRep( FUNC_NAME, 
                  "No hdr associated with template, can't determine step time", 
                  status );
        }
      }
    } else {
      *status = SAI__ERROR;
      errRep( FUNC_NAME, "NULL smfData template", status );
    }
  }

  /* If we have bad status free filt */
  if( *status != SAI__OK ) {
    filt = smf_free( filt, status );
  }

  return filt;
}
