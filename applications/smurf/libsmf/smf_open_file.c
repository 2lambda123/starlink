/*
 *+
 *  Name:
 *     smf_open_file

 *  Purpose:
 *     Low-level file access function

 *  Language:
 *     Starlink ANSI C

 *  Type of Module:
 *     Library routine

 *  Invocation:
 *     smf_open_file( const Grp * ingrp, size_t index, const char * mode, 
 *                    int flags, smfData ** data, int *status);

 *  Arguments:
 *     ingrp = const Grp * (Given)
 *        NDG group identifier
 *     index = size_t (Given)
 *        Index corresponding to required file in group
 *     mode = const char * (Given)
 *        File access mode
 *     flags = int (Given)
 *        Bitmask controls which components are opened. If 0 open everything.
 *     data = smfData ** (Returned)
 *        Pointer to pointer smfData struct to be filled with file info and data
 *        Should be freed using smf_close_file. Will be NULL if this routine completes
 *        with error.
 *     status = int* (Given and Returned)
 *        Pointer to global status.

 *  Description:
 *     This is the main routine to open data files. The routine finds
 *     the filename from the input Grp and index, and opens the
 *     file. The smfData struct is populated, along with the associated
 *     smfFile, smfHead and smfDA & smfDream (if necessary). The
 *     history is read and stored for future reference.

 *  Notes:
 *     - If a file has no FITS header then a warning is issued
 *     - JCMTState is NULL for non-time series data
 *     - The following bit flags defined in smf_typ.h are used for "flags" par:
 *       SMF__NOCREATE_HEAD: Do not allocate smfHead
 *       SMF__NOCREATE_DATA: Do not map DATA/VARIANCE/QUALITY
 *       SMF__NOFIX_METADATA: Do not fix metadata using smf_fix_metadata

 *  Authors:
 *     Andy Gibb (UBC)
 *     Tim Jenness (JAC, Hawaii)
 *     Edward Chapin (UBC)
 *     David Berry (JAC, UCLan)
 *     Malcolm J. Currie (Starlink)
 *     {enter_new_authors_here}

 *  History:
 *     2005-11-03 (AGG):
 *        Initial test version
 *     2005-11-07 (TIMJ):
 *        Need to cache locator to FRAMEDATA
 *     2005-11-23 (TIMJ):
 *        Use HDSLoc for locator
 *     2005-11-28 (TIMJ):
 *        Malloc sc2head
 *     2005-12-01 (EC):
 *        Fixed up error determining data types
 *     2005-12-05 (TIMJ):
 *        Store isTstream flag for smf_close_file
 *     2005-12-05 (AGG):
 *        Add status check on retrieving FITS hdr
 *     2005-12-14 (TIMJ):
 *        Now sets a reference counter
 *     2006-01-26 (TIMJ):
 *        Use smf_create_smfData
 *        Use smf_dtype_fromstring
 *     2006-01-27 (TIMJ):
 *        - Open raw data read only
 *        - Read in full time series headers into smfHead during sc2store
 *        - Copy flatfield information into struct and close raw file
 *        - read all time series headers into struct even when not sc2store
 *        - No longer need to store xloc locator
 *     2006-02-17 (AGG):
 *        Add reading of SCANFIT coefficients
 *     2006-03-03 (AGG):
 *        Return a NULL pointer if the group is undefined
 *     2006-03-23 (AGG);
 *        Store the number of frames (timeslices) in the smfData struct
 *     2006-03-24 (TIMJ):
 *        Fix bug where allsc2heads wasn't being set
 *     2006-04-21 (AGG):
 *        Add history read
 *     2006-05-16 (AGG):
 *        Change msgOut to msgOutif
 *     2006-05-19 (EC):
 *        Map Q&V if not present before when mode is WRITE
 *     2006-05-24 (AGG):
 *        Add status check in case SCANFIT extension doesn't exist
 *     2006-06-08 (AGG):
 *        Set correct data type for QUALITY to fix HDS error
 *     2006-06-12 (EC):
 *        NULL pointers associated with .SMURF.MAPCOORD extension
 *     2006-06-30 (EC):
 *        Now NULL pointers in smf_create_smf*, changed to .SCU2RED.MAPCOORD
 *     2006-07-26 (TIMJ):
 *        sc2head no longer used. Use JCMTState instead.
 *     2006-07-28 (TIMJ):
 *        Use new API for sc2store_headrmap. Read cube WCS into tswcs.
 *     2006-07-31 (TIMJ):
 *        Use SC2STORE__MAXFITS.
 *        Calculate "instrument".
 *    2006-08-24 (AGG):
 *        Read and store DREAM parameters (from RAW data only at present)
 *     2006-09-05 (JB):
 *        Check to make sure file exists
 *     2006-09-05 (EC):
 *        Call aztec_fill_smfHead, smf_telpos_get
 *     2006-09-07 (EC):
 *        Added code to isNDF=0 case to handle compressed AzTEC data
 *     2006-09-15 (AGG):
 *        Insert code for opening and storing DREAM parameters
 *     2006-09-21 (AGG):
 *        Check that we have a DREAM extension before attempting to access it
 *     2006-09-21 (AGG):
 *        Move the instrument-specific stuff until after hdr->nframes has
 *        been assigned (nframes is needed by acs_fill_smfHead).
 *     2006-12-20 (TIMJ):
 *        Clean up some error handling.
 *     2007-02-07 (EC):
 *        - renamed isNDF to isFlat to be less confusing
 *        - only issue a warning if data not 2d or 3d to handle iterative
 *          map-maker model containers.
 *     2007-03-28 (TIMJ):
 *        - Annul SCU2RED locator even if SCANFIT is not present
 *        - Noting Ed's comment that isFlat is less confusing, I disagree
 *          because isNDF applied to non-SCUBA2 data
 *     2007-05-29 (AGG):
 *        Check if data type is _REAL and map as _DOUBLE
 *     2007-10-29 (EC):
 *        Add flag controlling header read.
 *     2007-10-31 (TIMJ):
 *        Use size_t following changes to sc2store.
 *     2007-11-28 (EC):
 *        Add check for TORDERED keyword in FITS header
 *     2007-11-28 (TIMJ):
 *        Raw data is now _WORD and can be _INTEGER
 *     2007-12-02 (AGG):
 *        Do not map DATA/VARIANCE/QUALITY if SMF__NOCREATE_DATA flag is set
 *     2008-01-25 (EC):
 *        -removed check for TORDERED FITS keyword
 *        -Added check for SMF__NOCREATE_HEAD when extracting DREAM parameters
 *     2008-02-08 (EC):
 *        -In general map QUALITY unless SMF__NOCREATE_QUALITY set, or
 *         QUALITY doesn't exist, and access mode READ
 *     2008-03-07 (AGG):
 *        Read/create quality names extension
 *     2008-03-10 (AGG):
 *        Factor out quality names code into new routine
 *     2008-04-23 (EC):
 *        Read time series WCS even if the data is raw
 *     2008-04-30 (TIMJ):
 *        Support reading of units, title and data label.
 *     2008-05-01 (DSB):
 *        Ensure AST issues warnings if it tries to return undefined
 *        keyword values via the astGetFits<X> functions.
 *     2008-05-28 (TIMJ):
 *        Make sure return pointer is initialised to NULL even if status is
 *        bad on entry.
 *     2008-06-20 (DSB):
 *        Ensure that sc2store_rdtstream never maps the data array or dark
 *        squid values if the SMF__NOCREATE_DATA flag is supplied.
 *     2008-07-10 (TIMJ):
 *        Read dark squid information.
 *     2008-07-18 (TIMJ):
 *        Use size_t
 *     2008-07-24 (TIMJ):
 *        Calculate obs mode.
 *     2008-07-28 (TIMJ):
 *        Calculate and store steptime
 *     2008-07-31 (TIMJ):
 *        Free any resources if there is an error opening the file.
 *     2008-12-02 (DSB):
 *        Avoid use of astIsUndef functions.
 *     2009-04-06 (TIMJ):
 *        Improve the step time guess to take into account RTS_NUM.
 *        The only guaranteed way to "guess" is to read the embedded XML configuration.
 *     2009-05-26 (TIMJ):
 *        Move TCS_TAI fix up to smf_fix_metadata
 *     2009-08-25 (MJC):
 *        Add star/irq.h include as it is no longer in star/kaplibs.h.
 *     {enter_further_changes_here}

 *  Copyright:
 *     Copyright (C) 2007-2009 Science and Technology Facilities Council.
 *     Copyright (C) 2005-2007 Particle Physics and Astronomy Research Council.
 *     Copyright (C) 2005-2008 University of British Columbia.
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

/* Standard includes */
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"
#include "star/ndg.h"
#include "ndf.h"
#include "ast.h"
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"
#include "mers.h"
#include "star/irq.h"
#include "star/kaplibs.h"
#include "kpg_err.h"
#include "irq_err.h"
#include "prm_par.h"

/* SC2DA includes */
#include "sc2da/sc2store.h"
#include "sc2da/sc2ast.h"

/* SMURF includes */
#include "libacsis/acsis.h"
#include "libaztec/aztec.h"

static char * smf__read_ocsconfig ( int ndfid, int *status);

#define FUNC_NAME "smf_open_file"

void smf_open_file( const Grp * igrp, size_t index, const char * mode,
                    int flags, smfData ** data, int *status) {

  char dtype[NDF__SZTYP+1];  /* String for DATA type */
  int indf;                  /* NDF identified for input file */
  int ndfdims[NDF__MXDIM];   /* Array containing size of each axis of array */
  int ndims;                 /* Number of dimensions in data */
  int qexists;               /* Boolean for presence of QUALITY component */
  int vexists;               /* Boolean for presence of VARIANCE component */
  int itexists;              /* Boolean for presence of other components */
  char filename[GRP__SZNAM+1]; /* Input filename, derived from GRP */
  char *pname;               /* Pointer to input filename */
  void *outdata[] = { NULL, NULL, NULL }; /* Array of pointers to
                                             output data components:
                                             one each for DATA,
                                             QUALITY and VARIANCE */
  int isFlat = 1;            /* Flag to indicate if file flatfielded */
  int isTseries = 0;         /* Flag to specify whether the data are
                                in time series format */
  smf_dtype itype = SMF__NULL; /* Data type for DATA (and VARIANCE) array(s) */
  size_t i;                  /* Loop counter */
  int nout;                  /* Number of output pixels */
  int **ptdata;              /* Pointer to raw time series data (DATA cpt) */
  int *rawts;                /* Raw time series via sc2store */
  smfFile *file = NULL;      /* pointer to smfFile struct */
  smfHead *hdr = NULL;       /* pointer to smfHead struct */
  smfDA *da = NULL;          /* pointer to smfDA struct, initialize to NULL */

  HDSLoc *tloc = NULL;       /* Locator to the NDF JCMTSTATE extension */
  HDSLoc *xloc = NULL;       /* Locator to time series headers,
                                SCANFIT coeffs and DREAM parameters*/

  /* Flatfield parameters */
  double * flatcal = NULL;
  double * flatpar = NULL;
  int * dksquid = NULL;
  int **pdksquid = NULL;
  JCMTState *tmpState = NULL;

  /* DREAM parameters */
  int *jigvert = NULL;       /* Pointer to jiggle vertices in DREAM pattern */
  double *jigpath = NULL;    /* Pointer to jiggle path */
  smfDream *dream = NULL;    /* Pointer to DREAM parameters */
  size_t nsampcycle;         /* Number of positions in jiggle path */
  size_t nvert;              /* Number of vertices in DREAM pattern */
  int jigvndf;               /* NDF identifier for jiggle vertices */
  int jigpndf;               /* NDF identifier for SMU path */
  smfData *jigvdata = NULL;  /* Jiggle vertex data */
  smfData *jigpdata = NULL;  /* SMU path data */

  /* Pasted from readsc2ndf */
  size_t colsize;               /* number of pixels in column */
  char fitsrec[SC2STORE__MAXFITS*80+1];   /* FITS headers read from sc2store */
  size_t nfits;              /* number of FITS headers */
  size_t nframes;            /* number of frames */
  size_t rowsize;            /* number of pixels in row (returned) */
  int createflags = 0;       /* Flags for smf_create_smfData */

  int gndf;                  /* General purpose NDF identifier (SCU2RED & DREAM) */
  int place;                 /* NDF placeholder for SCANFIT extension */
  int npoly;                 /* Number points in polynomial coeff array */
  void *tpoly[1] = { NULL }; /* Temp array of void for ndfMap */
  double *poly = NULL;       /* Pointer to array of polynomial coefficients */
  double *opoly;             /* Pointer to store in output struct */
  int npdims;                /* Number of dimensions in the polynomial array */
  int pdims[NDF__MXDIM];     /* Size of each dimension */

  IRQLocs *qlocs = NULL;     /* Named quality resources */
  char xname[DAT__SZNAM+1];  /* Name of extension holding quality names */

  /* make sure return pointer is initialised */
  *data = NULL;

  if ( *status != SAI__OK ) return;

  /* Return a null pointer to the smfData if the input grp is null */
  if ( igrp == NULL ) {
    *data = NULL;
    return;
  }

  /* Get filename from the group */
  pname = filename;
  grpGet( igrp, index, 1, &pname, SMF_PATH_MAX, status);

  /* Return the NDF identifier */
  if (*status == SAI__OK) {
    ndgNdfas( igrp, index, mode, &indf, status );
    if ( indf == NDF__NOID ) {
      if (*status == SAI__OK) *status = SAI__ERROR;
      msgSetc( "FILE", filename );
      errRep("", FUNC_NAME ": Could not locate file ^FILE", status);
      return;
    }
    msgSetc( "F", filename );
    msgOutif(MSG__DEBUG, "", "Opening file ^F", status);
  }

  /* Determine the dimensions of the DATA component */
  ndfDim( indf, NDF__MXDIM, ndfdims, &ndims, status );

  /* Check type of DATA and VARIANCE arrays (they should both be the same!) */
  ndfType( indf, "DATA,VARIANCE", dtype, NDF__SZTYP+1, status);

  /* Check dimensionality: 2D is a .In image, 3D is a time series */
  if (ndims == 2) {
    if (strncmp(dtype, "_REAL", 5) == 0) {
      /* Change _REAL to _DOUBLE */
      msgOutif( MSG__DEBUG, "", 
                "Input file is _REAL, will map as _DOUBLE for internal handling", 
                status );
      strncpy( dtype, "_DOUBLE", NDF__SZTYP+1 );
    }
    isFlat = 1;    /* Data have been flat-fielded */
    isTseries = 0; /* Data are not in time series format */
  } else if (ndims == 3) { /* Time series data */
    /* Check if raw timeseries - _WORD, _UWORD or _INTEGER */
    /* Note that _INTEGER may or may not have been flatfielded */
    if ( (strncmp(dtype, "_WORD", 5) == 0 ) ||     /* Compressed */
         (strncmp(dtype, "_INTEGER", 7) == 0 ) ||  /* Uncompressed */
         (strncmp(dtype, "_UWORD", 6) == 0 ) ) {   /* Old format */
      isFlat = 0;  /* Data have not been flatfielded */
    } else {
      /* Note that the data should be of type _DOUBLE here */
      isFlat = 1;  /* Data have been flatfielded */
    }
    isTseries = 1; /* Data are in time series format */
  } else {
    /* Report a warning due to non-standard dimensions for file */
    if ( *status == SAI__OK) {
      msgSeti( "NDIMS", ndims);
      msgOutif(MSG__DEBUG," ", 
               "Number of dimensions in output, ^NDIMS is not equal to 2 or 3",
               status);
      /* Data is neither flat-fielded nor standard time-series data. However
         in this context "flat" data is really just data that doesn't
         need to be de-compressed using the sc2store library, so we set 
         isFlat to true */
      isTseries = 0;
      isFlat = 1;
    }
  }

  /* Now we need to create some structures */
  if (flags & SMF__NOCREATE_HEAD) createflags |= SMF__NOCREATE_HEAD;
  if (isFlat) createflags |= SMF__NOCREATE_DA;

  /* Allocate memory for the smfData */
  *data = smf_create_smfData( createflags, status );

  /* If all's well, proceed */
  if ( *status == SAI__OK) {
    file = (*data)->file;
    hdr = (*data)->hdr;

    /* If we have timeseries data then look for and read polynomial
       scan fit coefficients */
    if ( isTseries ) {
      ndfXstat( indf, "SCU2RED", &itexists, status );
      if ( itexists) {
        ndfXloc( indf, "SCU2RED", "READ", &xloc, status );
        if ( xloc == NULL ) {
          if ( *status == SAI__OK) {
            *status = SAI__ERROR;
            errRep("", FUNC_NAME ": Unable to obtain an HDS locator to the "
                   "SCU2RED extension, despite its existence", status);
          }
        }
        ndfOpen( xloc, "SCANFIT", "READ", "OLD", &gndf, &place, status );
        /* Check status here in case not able to open NDF */
        if ( *status == SAI__OK ) {
          if ( gndf == NDF__NOID ) {
            *status = SAI__ERROR;
            errRep("", FUNC_NAME ": Unable to obtain an NDF identifier for "
                   "the SCANFIT coefficients", status);
          } else {
            /* Read and store the polynomial coefficients */
            ndfMap( gndf, "DATA", "_DOUBLE", "READ", &tpoly[0], &npoly, 
                    status );
            poly = tpoly[0];
            ndfDim( gndf, NDF__MXDIM, pdims, &npdims, status );
            (*data)->ncoeff = pdims[2];
            /* Allocate memory for poly coeffs & copy over */
            opoly = smf_malloc( npoly, sizeof( *opoly ), 0, status);
            memcpy( opoly, poly, npoly*sizeof( *opoly ) );
            (*data)->poly = opoly;
          }
          /* Release these resources immediately as they're not needed */
          ndfAnnul( &gndf, status );
        } else {
          /* If status is bad, then the SCANFIT extension does not
             exist. This is not fatal so annul the error */
          errAnnul(status);
          msgOutif(MSG__DEBUG," ", 
                   "SCU2RED exists, but not SCANFIT - continuing", 
                   status);
        }
        /* Annul the locator */
        datAnnul( &xloc, status );

      } else {
        msgOutif(MSG__DEBUG," ", 
                 "File has no SCU2RED extension: no DA-processed data present", 
                 status);
      }
    }

    if (isFlat) {

      /* Map the DATA, VARIANCE and QUALITY if requested */
      if ( !(flags & SMF__NOCREATE_DATA) ) {
        ndfState( indf, "QUALITY", &qexists, status);
        ndfState( indf, "VARIANCE", &vexists, status);

        /* If access mode is READ, map the QUALITY array only if it
           already existed, and SMF__NOCREATE_QUALITY is not set. However,
           if the access mode is not READ, create QUALITY by default. 
           Map first so that QUALITY can be used to mask DATA when it is
           map'd */

        if ( !(flags & SMF__NOCREATE_QUALITY) && 
             ( qexists || strncmp(mode,"READ",4) ) ) {

          if ( qexists ) {
            irqFind( indf, &qlocs, xname, status );
            if ( *status == SAI__OK ) {
              msgOutif(MSG__DEBUG, "", "Quality names defined in file", status);
            } else if (*status == IRQ__NOQNI) {
              errAnnul( status );
              msgOutif( MSG__DEBUG, "", 
                        "QUALITY present but no quality names extension in file", 
                        status );
              smf_create_qualname( mode, indf, &qlocs, status );
            }
            /* Last step, map quality */
            ndfMap( indf, "QUALITY", "_UBYTE", mode, &outdata[2], &nout, 
                    status );
          } else {
            /* If no QUALITY, then first check for quality names and
               create if not present */
            irqFind( indf, &qlocs, xname, status );
            if ( *status == IRQ__NOQNI && strncmp(mode,"READ",4) ) {
              errAnnul(status);
              smf_create_qualname( mode, indf, &qlocs, status );
            } else {
              msgOutif(MSG__DEBUG, "", 
                       "File has quality names extension but no QUALITY", 
                       status);
            }
            /* Attempt to create QUALITY component - assume we have
               write or update access at this point */
            ndfMap( indf, "QUALITY", "_UBYTE", "WRITE", &outdata[2], &nout, 
                    status );
          }
          /* Done with quality names so free resources */
          irqRlse( &qlocs, status );
        }
        /* Always map DATA if we get this far */
        ndfMap( indf, "DATA", dtype, mode, &outdata[0], &nout, status );

        /* Default behaviour is to map VARIANCE only if it exists already. */
        if (vexists) {
          ndfMap( indf, "VARIANCE", dtype, mode, &outdata[1], &nout, status );
        }

      }

      if ( !(flags & SMF__NOCREATE_HEAD) ) {

        /* Read the units and data label */
        ndfCget( indf, "UNITS", hdr->units, SMF__CHARLABEL, status );
        ndfCget( indf, "LABEL", hdr->dlabel, SMF__CHARLABEL, status );
        ndfCget( indf, "TITLE", hdr->title, SMF__CHARLABEL, status );

        /* Read the FITS headers */
        kpgGtfts( indf, &(hdr->fitshdr), status );
        /* Just continue if there are no FITS headers */
        if ( *status == KPG__NOFTS ) {
          errRep("", FUNC_NAME ": File has no FITS header - continuing but "
                 "this may cause problems later", status );
          errAnnul( status );
        }

        /* Determine the instrument - assume that header fixups are not required for this */
        hdr->instrument = smf_inst_get( hdr, status );

        /* and work out the observing mode (again, hope that headers are right) */
        if (hdr->fitshdr) smf_calc_mode( hdr, status );

        /* If not time series, then we can retrieve the stored WCS
           info. Note that the JCMTState parameter is filled ONLY for
           time series data */
        if ( !isTseries ) {
          ndfGtwcs( indf, &(hdr->wcs), status);
          hdr->nframes = 1;
        } else {
          /* Get the time series WCS */
          ndfGtwcs( indf, &(hdr->tswcs), status );

          /* Get the obsidss */
          if( hdr->fitshdr ) {
            (void )smf_getobsidss( hdr->fitshdr, NULL, 0, hdr->obsidss, 
                                   sizeof(hdr->obsidss), status );
          }

          /* Need to get the location of the extension for STATE parsing */
          ndfXloc( indf, JCMT__EXTNAME, "READ", &tloc, status );

          /* Only read the state header if available */
          if( *status == SAI__OK ) {
            /* Re-size the arrays in the JCMTSTATE extension to match the
               pixel index bounds of the NDF. The resized arrays are stored in
               a new temporary HDS object, and the old locator is annull. */
            sc2store_resize_head( indf, &tloc, &xloc, status );

            /* And need to map the header making sure we have the right 
               components for this instrument. */
            nframes = ndfdims[2];
            sc2store_headrmap( xloc, nframes, hdr->instrument, status );

            /* Malloc some memory to hold all the time series data */
            hdr->allState = smf_malloc( nframes, sizeof(*(hdr->allState)),
                                        1, status );

            /* Loop over each element, reading in the information */
            tmpState = hdr->allState;
            for (i=0; i<nframes; i++) {
              sc2store_headget(i, &(tmpState[i]), status);
            }
            hdr->nframes = nframes;
            /* Unmap the headers */
            sc2store_headunmap( status );
          } else if (*status==NDF__NOEXT) {
            /* If the header just wasn't there, annul status and continue */
            errAnnul( status );
            msgOutif( MSG__DEBUG, "", 
                      FUNC_NAME 
                      ": File has not JCMTState information continuing anyways",
                      status );
          }

          /* Annul the locator in any case */
          if( xloc ) datAnnul( &xloc, status );

          /* Read the OCS configuration xml */
          hdr->ocsconfig = smf__read_ocsconfig( indf, status );

          /* Metadata corrections - hide the messages by default.
             Only correct time series data at the moment.
          */
          if ( !(flags & SMF__NOFIX_METADATA) ) smf_fix_metadata( MSG__VERB, *data, status );

        }

        /* Determine and store the telescope location in hdr->telpos */
        smf_telpos_get( hdr, status );

        /* Store the INSTAP values */
        smf_instap_get( hdr, status );

        /* On the basis of the instrument, we know need to fill in some
           additional header parameters. Some of these may be constants,
           whereas others may involve more file access. Currently we use
           a simple switch statement. We could modify this step to use
           vtables of function pointers.
        */
        switch ( hdr->instrument ) {
        case INST__ACSIS:
          acs_fill_smfHead( hdr, indf, status );
          break;
        case INST__AZTEC:
          aztec_fill_smfHead( hdr, NDF__NOID, status );
          break;
        default:
          break;
          /* SCUBA-2 has nothing special here because the focal plane
             coordinates are derived using an AST polyMap */
        }

      }
      /* Establish the data type */
      itype = smf_dtype_fromstring( dtype, status );

      /* Store NDF identifier and set isSc2store to false */
      if (*status == SAI__OK) {
        file->ndfid = indf;
        file->isSc2store = 0;
        file->isTstream = isTseries;
      }
    } else {
      /* Get the time series WCS if header exists */
      if( hdr ) {
        ndfGtwcs( indf, &(hdr->tswcs), status );
      }

      /* Read the OCS configuration xml whilst we have the file open */
      if ( !(flags & SMF__NOCREATE_HEAD) ) hdr->ocsconfig = smf__read_ocsconfig( indf, status );

      /* OK, we have raw data. Close the NDF because
         sc2store_rdtstream will open it again */
      ndfAnnul( &indf, status );

      /* Read time series data from file */
      da = (*data)->da;
      if (*status == SAI__OK && da == NULL) {
        *status = SAI__ERROR;
        errRep("", FUNC_NAME ": Internal programming error. Status good but "
               "no DA struct allocated", status);
      }

      /* decide if we are storing header information */
      tmpState = NULL;

      /* If access to the data is not required, pass NULL pointers to
         sc2store_rdtstream. Otherwise, use pointers to the relavent buffers. */
      if ( flags & SMF__NOCREATE_DATA ) {
        ptdata = NULL;
        pdksquid = NULL;
      } else {
        ptdata = &rawts;
        pdksquid = &dksquid;
      }

      /* Read time series data from file */
      sc2store_force_initialised( status );
      sc2store_rdtstream( pname, "READ", SC2STORE_FLATLEN,
                          SC2STORE__MAXFITS, 
                          &nfits, fitsrec, &colsize, &rowsize, 
                          &nframes, &(da->nflat), da->flatname,
                          &tmpState, ptdata, pdksquid, 
                          &flatcal, &flatpar, &jigvert, &nvert, &jigpath, 
                          &nsampcycle, status);
      if (ptdata) outdata[0] = rawts;

      if (*status == SAI__OK) {
        /* Free header info if no longer needed */
        if ( (flags & SMF__NOCREATE_HEAD) && tmpState != NULL) {
          /* can not use smf_free */
          free( tmpState );
          tmpState = NULL;
        } else {
          hdr->allState = tmpState;
        }

        /* Malloc local copies of the flatfield information.
           This allows us to close the file immediately so that
           we do not need to worry about sc2store only allowing
           a single file at a time */
        da->flatcal = smf_malloc( colsize * rowsize * da->nflat, 
                                  sizeof(*(da->flatcal)), 0, status );
        da->flatpar = smf_malloc( da->nflat, sizeof(*(da->flatpar)), 0, status);

        /* Now copy across from the mapped version */
        if (da->flatcal != NULL) memcpy(da->flatcal, flatcal,
                                        sizeof(*(da->flatcal))*colsize*
                                        rowsize* da->nflat);
        if (da->flatpar != NULL) memcpy(da->flatpar, flatpar,
                                        sizeof(*(da->flatpar))* da->nflat);

        /* and dark squid */
        if (dksquid) {

          da->dksquid = smf_malloc( rowsize * nframes, sizeof(*(da->dksquid)), 
                                    0, status );

          if (da->dksquid) memcpy( da->dksquid, dksquid,
                                   sizeof(*(da->dksquid)) * rowsize * nframes );
          
        }

        /* Create a FitsChan from the FITS headers */
        if ( !(flags & SMF__NOCREATE_HEAD) ) {
          smf_fits_crchan( nfits, fitsrec, &(hdr->fitshdr), status); 

          /* Instrument must be SCUBA-2 */
          /* hdr->instrument = INST__SCUBA2; */

          /* ---------------------------------------------------------------*/
          /* WARNING: This has been duplicated from the "isFlat" case to
             accomodate AzTEC data that was written using sc2sim_ndfwrdata.
             In principle AzTEC data should not be compressed, in which case
             the above assertion "Instrument must be SCUBA-2" would be 
             correct, and the following code is unnecessary. */

          /* Determine the instrument */
          hdr->instrument = smf_inst_get( hdr, status );

          if (hdr->fitshdr) {
            /* and work out the observing mode */
            smf_calc_mode( hdr, status );
	  
            /* Get the obsidss */
            (void )smf_getobsidss( hdr->fitshdr, NULL, 0, hdr->obsidss, 
                                   sizeof(hdr->obsidss), status );
          }

          /* Metadata corrections - hide the messages by default */
          if ( !(flags & SMF__NOFIX_METADATA) ) smf_fix_metadata( MSG__VERB, *data, status );

          /* Determine and store the telescope location in hdr->telpos */
          smf_telpos_get( hdr, status );

          /* Store the INSTAP values */
          smf_instap_get( hdr, status );

          /* On the basis of the instrument, we know need to fill in some
             additional header parameters. Some of these may be constants,
             whereas others may involve more file access. Currently we use
             a simple switch statement. We could modify this step to use
             vtables of function pointers.
          */
          switch ( hdr->instrument ) {
          case INST__ACSIS:
            acs_fill_smfHead( hdr, indf, status );
            break;
          case INST__AZTEC:
            aztec_fill_smfHead( hdr, NDF__NOID, status );
            break;
          default:
            break;
            /* SCUBA-2 has nothing special here because the focal plane
               coordinates are derived using an AST polyMap */
          }

          /* ---------------------------------------------------------------*/
        }

        /* Raw data type is integer */
        itype = SMF__INTEGER;

        /* Verify that ndfdims matches row, col, nframes */
        /* Should probably inform user of the filename too */
        if (ndfdims[SC2STORE__ROW_INDEX] != (int)colsize) {
          msgSeti( "NR", colsize);
          msgSeti( "DIMS", ndfdims[0]);
          *status = SAI__ERROR;
          errRep( "", FUNC_NAME ": Number of input rows not equal to the "
                  "number of output rows (^NR != ^DIMS)",status);
        }
        if (ndfdims[SC2STORE__COL_INDEX] != (int)rowsize) {
          msgSeti( "NC", rowsize);
          msgSeti( "DIMS", ndfdims[1]);
          *status = SAI__ERROR;
          errRep( "", FUNC_NAME ":Number of input columns not equal to the "
                  "number of output columns (^NR != ^DIMS)",status);
        }
        if (ndfdims[2] != (int)nframes) {
          msgSeti( "NF", nframes);
          msgSeti( "DIMS", ndfdims[2]);
          *status = SAI__ERROR;
          errRep( "", FUNC_NAME ": Number of input timeslices not equal to "
                  "the number of output timeslices (^NF != ^DIMS)",status);
        } else {
          if ( !(flags & SMF__NOCREATE_HEAD) ) {
            hdr->nframes = nframes;
          }
        }

        /* Set flag to indicate data read by sc2store_() */
        file->isSc2store = 1;

        /* and it is a time series */
        file->isTstream = 1;

        /* Store DREAM parameters */
        if ( !(flags & SMF__NOCREATE_HEAD) ) {
          dream = smf_construct_smfDream( *data, nvert, nsampcycle, jigvert, 
                                          jigpath, status );
          (*data)->dream = dream;
        }
      }

      /* Close the file */
      sc2store_free( status );

    }
    /* Store info in smfData struct */
    if (*status == SAI__OK) {
      (*data)->dtype = itype;
      strncpy(file->name, pname, SMF_PATH_MAX);

      /* Store the data in the smfData struct if needed */
      if ( !(flags & SMF__NOCREATE_DATA) ) {
        for (i=0; i<3; i++) {
          ((*data)->pntr)[i] = outdata[i];
        }
      }
      /* Store the dimensions and the size of each axis */
      (*data)->ndims = ndims;
      for (i=0; i< (size_t)ndims; i++) {
        ((*data)->dims)[i] = (dim_t)ndfdims[i];
      }
    }
    /* Store DREAM parameters for flatfielded data if they exist. This
       has to be done here as these methods rely on information in the
       main smfData struct. First retrieve jigvert and jigpath from
       file */ 
    if ( isTseries && isFlat && !(flags & SMF__NOCREATE_HEAD) ) {
      /* Obtain locator to DREAM extension if we have DREAM data */
      xloc = smf_get_xloc( *data, "DREAM", "DREAM_PAR", "READ", 0, 0, status );
      /* If it's NULL then we don't have dream data */
      if ( xloc != NULL ) {
        jigvndf = smf_get_ndfid( xloc, "JIGVERT", "READ", "OLD", "", 0, NULL, 
                                 NULL, status);
        if ( jigvndf == NDF__NOID) {
          if (*status == SAI__OK ) {
            *status = SAI__ERROR;
            errRep("", FUNC_NAME ": Unable to obtain NDF ID for JIGVERT", 
                   status);
          }
        } else {
          smf_open_ndf( jigvndf, "READ", filename, SMF__INTEGER, &jigvdata, status);
        }
        jigpndf = smf_get_ndfid( xloc, "JIGPATH", "READ", "OLD", "", 0, NULL, 
                                 NULL, status);
        if ( jigpndf == NDF__NOID) {
          if (*status == SAI__OK ) {
            *status = SAI__ERROR;
            errRep("", FUNC_NAME ": Unable to obtain NDF ID for JIGPATH", 
                   status);
          }
        } else {
          smf_open_ndf( jigpndf, "READ", filename, SMF__DOUBLE, &jigpdata, status);
        }
        if ( jigvdata != NULL ) {
          jigvert = (jigvdata->pntr)[0];
          nvert = (int)(jigvdata->dims)[0];
        } else {
          if (*status == SAI__OK ) {
            *status = SAI__ERROR;
            errRep("", FUNC_NAME ": smfData for jiggle vertices is NULL", 
                   status);
          }
        }
        if ( jigpdata != NULL ) {
          jigpath = (jigpdata->pntr)[0];
          nsampcycle = (int)(jigpdata->dims)[0];
        } else {
          if (*status == SAI__OK ) {
            *status = SAI__ERROR;
            errRep("", FUNC_NAME ": smfData for SMU path is NULL", status);
          }
        }

        dream = smf_construct_smfDream( *data, nvert, nsampcycle, jigvert, 
                                        jigpath, status );
        (*data)->dream = dream;
    
        /* Free up the smfDatas for jigvert and jigpath */
        if ( jigvert != NULL ) {
          smf_close_file( &jigvdata, status );
        }
        if ( jigpath != NULL ) {
          smf_close_file( &jigpdata, status );
        }
        datAnnul( &xloc, status );
      }
    }
  }
  /* Read and store history */
  smf_history_read( *data, status );

  /* Store the STEPTIME in the hdr - assumes that smf_fix_metadata has fixed things
     up or complained. */
  if ( hdr &&  (hdr->instrument!=INST__NONE) ) {
    double steptime = VAL__BADD;
    smf_getfitsd( hdr, "STEPTIME", &steptime, status );
    hdr->steptime = steptime;
  }

  /* free resources on error */
  if (*status != SAI__OK) {
    smf_close_file( data, status );
  }

}

/* Private routine for opening up a file and reading the OCS config.
   Returned value must be freed if non-NULL.
 */

static char * smf__read_ocsconfig ( int ndfid, int *status) {
  char * ocscfg = NULL;
  if (*status != SAI__OK) return ocscfg;

  /* Read the OCS configuration XML if available */
  if ( ndfid != NDF__NOID ) {
    int isthere = 0;
    ndfXstat( ndfid, "JCMTOCS", &isthere, status );
    if (isthere) {
      HDSLoc * jcmtocs = NULL;
      HDSLoc * configloc = NULL;
      size_t size;
      size_t clen;
      hdsdim dims[1];
      ndfXloc( ndfid, "JCMTOCS", "READ", &jcmtocs, status );
      datFind( jcmtocs, "CONFIG", &configloc, status );
      datAnnul( &jcmtocs, status );
      datSize( configloc, &size, status );
      datClen( configloc, &clen, status );
      /* allocate it slightly bigger in case the config *just* fits
         in SIZE * CLEN characters and we can't terminate it. Also
         initialise it so that we can walk back from the end */
      ocscfg = smf_malloc( size + 1, clen, 1, status );
      ocscfg[0] = '\0'; /* just to make sure */
      dims[0] = size;
      datGetC( configloc, 1, dims, ocscfg, clen, status );
      /* _CHAR buffer will not be terminated */
      cnfImprt( ocscfg, (size * clen) + 1, ocscfg );
      datAnnul( &configloc, status );
    }
  }
  return ocscfg;
}
