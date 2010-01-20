/*
*+
*  Name:
*     smf_iteratemap

*  Purpose:
*     Iterative map-maker

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:

*     smf_iteratemap(smfWorkForce *wf, const Grp *igrp, const Grp *iterrootgrp,
*                    const Grp *bolrootgrp,
*                    AstKeyMap *keymap, const smfArray * darks,
*                    const smfArray *bbms,
*                    AstFrameSet *outfset, int moving, int *lbnd_out,
*                    int *ubnd_out, size_t maxmem, double *map,
*                    int *hitsmap, double *mapvar, double
*                    *weights, char data_units[], int *status );

*  Arguments:
*     wf = smfWorkForce * (Given)
*        Pointer to a pool of worker threads
*     igrp = const Grp* (Given)
*        Group of input data files
*     iterrootgrp = const Grp * (Given)
*        Root name to use for iteration output maps (if required). Can be a
*        path to an HDS container.
*     bolrootgrp = const Grp * (Given)
*        Root name to use for bolometer output maps (if required). Can be a
*        path to an HDS container.
*     keymap = AstKeyMap* (Given)
*        keymap containing parameters to control map-maker
*     darks = const smfArray * (Given)
*        Collection of dark frames. Can be NULL.
*     bbms = smfArray * (Given)
*        Masks for each subarray (e.g. returned by smf_reqest_mask call)
*     outfset = AstFrameSet* (Given)
*        Frameset containing the sky->output map mapping if calculating
*        pointing LUT on-the-fly
*     moving = int (Given)
*        Is coordinate system tracking moving object? (if outfset specified)
*     lbnd_out = double* (Given)
*        2-element array pixel coord. for the lower bounds of the output map
*        (if outfset specified)
*     maxmem = size_t (Given)
*        Maximum memory that me be used by smf_iteratemap (bytes)
*     map = double* (Returned)
*        The output map array
*     hitsmap = int* (Returned)
*        Number of samples that land in a pixel (ignore if NULL pointer)
*     mapvar = double* (Returned)
*        Variance of each pixel in map
*     weights = double* (Returned)
*        Relative weighting for each pixel in map
*     data_units = char[] (Returned)
*        Data units read from the first chunk. These may be different from
*        that read from raw data due to flatfielding. Should be a buffer
*        of at least size SMF__CHARLABEL.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function uses an iterative algorithm to separately estimate
*     the component of the bolometer signals that are astronomical signal,
*     atmospheric signal, and residual Gaussian noise, and creates a rebinned
*     map of the astronomical signal.
*
*  Authors:
*     EC: Edward Chapin (UBC)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     DSB: David Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2006-05-18 (EC):
*        Initial version.
*     2006-06-24 (EC):
*        Parameters given by keymap
*     2006-08-07 (TIMJ):
*        GRP__NOID is not a Fortran concept.
*     2006-08-16 (EC):
*        Intermediate step: Old routine works with new model container code
*     2007-02-07 (EC):
*        Fixed bugs in implementation of models, order of execution.
*     2007-02-08 (EC):
*        Changed location of AST model calculation
*        Fixed pointer bug for variance of residual in map estimate
*     2007-02-12 (EC)
*        Enabled dyanmic usage of model components using function pointers
*     2007-03-02 (EC)
*        Added noise estimation from residual
*        Fixed counter bug
*     2007-03-05 (EC)
*        Parse modelorder keyword in config file
*     2007-04-30 (EC)
*        Put map estimation in first chunk loop, only ast in second
*     2007-05-17 (EC)
*        Added missing status checks
*     2007-06-13 (EC):
*        - Use new DIMM binary file format
*     2007-06-14 (EC):
*        - If config file has exportndf set, export DIMM components to *.sdf
*     2007-07-10 (EC):
*        - Use smfGroups and smfArrays instead of groups and smfdatas
*        - fixed problem with function pointer type casting
*     2007-07-13 (EC):
*        - use arrays of pointers to all chunks to store modeldata/modelgroups
*     2007-07-20 (EC):
*        - fixed freeing of modeldata
*     2007-08-09 (EC):
*        - changed index order for model
*        - added memiter flag to config file - avoids doing file i/o
*     2007-08-17 (EC):
*        Added nofile flag to smf_model_create to avoid creating .dimm files
*        in memiter=1 case.
*     2007-11-15 (EC):
*        -Use smf_concat_smfGroup for memiter=1 case.
*        -Modified interface to hand projection from caller to concat_smfGroup
*        -Check for file name existence when calling smf_model_NDFexport
*     2007-11-15 (EC):
*        -Switch to bolo-ordering the data. Compiles but still buggy.
*     2007-12-14 (EC):
*        -set file access to UPDATE for model components (was READ)
*        -modified smf_calc_mapcoord interface
*     2007-12-18 (AGG):
*        Update to use new smf_free behaviour
*     2008-01-22 (EC):
*        Added hitsmap to interface
*     2008-01-25 (EC):
*        Handle non-flatfielded input data. Pointing LUT is now calculated
*        in smf_model_create rather than requiring calls to smf_calc_mapcoord.
*     2008-03-04 (EC):
*        -Modified model calculation to use smfDIMMData in interface
*        -Added QUAlity component
*     2008-04-03 (EC):
*        - Use QUALITY in map-maker
*        - Added data cleaning options to CONFIG file
*     2008-04-14 (EC):
*        - Fixed memory-deallocation (res/ast/qua...)
*        - Added QUALITY/VARIANCE to NDFexport
*     2008-04-16 (EC):
*        - Added outer loop to handle multiple cont. chunks for memiter=1 case
*     2008-04-17 (EC):
*        - Added maxlen to config file, modified smf_grp_related
*        - Use variance stored in NOI to estimate map
*        - Don't include VARIANCE of input files when concatenating
*        - Store VARIANCE (from NOI) in residual
*     2008-04-18 (EC):
*        Calculate and display chisquared for each chunk
*     2008-04-23 (EC):
*        - Added sample variance estimate for varmap
*        - Propagate header information to exported model components
*        - Added CHITOL config parameter to control stopping
*     2008-04-24 (EC):
*        - Improved status checking
*        - extra checks for valid pointers before exporting model components
*     2008-04-28 (EC):
*        - Added memory usage check
*     2008-04-29 (EC)
*        Check for VAL__BADD in map to avoid propagating to residual
*     2008-04-30 (EC)
*        - Undo EXTinction correction after calculating AST
*     2008-05-01 (EC)
*        - More intelligent auto-sizing of concantenated chunks
*     2008-05-02 (EC)
*        - Use different levels of verbosity in messages
*     2008-06-12 (EC)
*        - renamed smf_model_NDFexport smf_NDFexport
*        - added edge and notch frequency-domain filters
*     2008-07-03 (EC)
*        - Added padstart/padend to config files
*     2008-07-25 (TIMJ):
*        Pass darks through to smf_concat_smfGroup
*     2008-07-29 (TIMJ):
*        Steptime is now in smfHead.
*     2008-09-30 (EC):
*        Use smf_write_smfData instead of smf_NDFexport
*     2008-12-12 (EC):
*        Extra re-normalization required for GAIn model
*     2009-01-06 (EC):
*        -Added flagging of data during stationary telescope pointing
*        -apply bad pixel mask (BPM)
*     2009-01-12 (EC):
*        Move application of BPM into smf_concat_smfGroup
*     2009-03-09 (EC):
*        Don't need to call smf_calcmodel_gai because flatfield no longer
*        modified by smf_calcmodel_com
*     2009-03-20 (EC):
*        Added capability to calculate model components after AST. Use must
*        now explicitly give AST in MODELORDER keywordd from config file.
*     2009-04-15 (EC):
*        Factor cleaning parameter parsing into smf_get_cleanpar.
*     2009-04-16 (EC):
*        Option of exporting only certain model components to NDF
*     2009-04-17 (EC):
*        Factor filter generation out to smf_filter_fromkeymap
*     2009-04-20 (EC):
*        - Move flagging of stationary data to smf_model_create
*        - Optinally delete .DIMM files (deldimm=1 in CONFIG file)
*     2009-04-23 (EC):
*        Add numerous MSG__DEBUG timing messages
*     2009-09-30 (EC):
*        Fix bug in handling of AST model component and residuals
*     2009-10-06 (EC):
*        - don't automatically generate bad status if < SMF__MINSTATSAMP
*          good bolos (to enable single-detector maps)
*        - don't try to weight data at map-making stage if no noise estimate
*          is available
*     2009-10-25 (EC):
*        - Add back in option of using common-mode to flatfield data; need to
*          invert the GAIn once per iteration.
*        - add bolomap flag to config file (produce single-detector images)
*     2009-10-25 (TIMJ):
*        Add bolrootgrp argument to give us control of where the bolometer
*        maps go.
*     2009-10-28 (TIMJ):
*        Add data_units. Needed because we can only read data units after
*        the data have been flatfielded. Also check for consistency.
*     2009-11-10 (EC):
*        Add noexportsetbad dimmconfig parameter to set bad values in exported
*        files when SMF__Q_BADB bits set.
*     2009-11-12 (EC):
*        Add itermap and iterrootgrp to enable writing of intermediate maps
*        after each iteration (matching style of bolomap and bolrootgrp).
*     2009-11-13 (EC):
*        If chi^2 increases don't set converged flag; warn user.
*     2010-01-08 (AGG):
*        Change BPM to BBM.
*     2010-01-11 (EC):
*        Add fillgaps to data pre-processing (config file)
*     2010-01-12 (TIMJ):
*        Add facility for merging keymaps from config file.
*     2010-01-18 (EC):
*        Export data before dying if SMF__INSMP status set
*     2010-01-19 (DSB)
*        - Add dcthresh2 config parameter.
*     {enter_further_changes_here}

*  Notes:

*  Copyright:
*     Copyright (C) 2008-2010 Science and Technology Facilities Council.
*     Copyright (C) 2006 Particle Physics and Astronomy Research Council.
*     Copyright (C) 2006-2010 University of British Columbia.
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
*     MA 02111-1307, USA.

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#include <stdio.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"
#include "par_par.h"
#include "star/one.h"
#include "fftw3.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"
#include "jcmt/state.h"

/* Other includes */
#include "sys/time.h"


#define FUNC_NAME "smf_iteratemap"

void smf_iteratemap( smfWorkForce *wf, const Grp *igrp, const Grp *iterrootgrp,
                     const Grp *bolrootgrp,
                     AstKeyMap *keymap, const smfArray *darks,
                     const smfArray *bbms,
                     AstFrameSet *outfset, int moving, int *lbnd_out,
                     int *ubnd_out, size_t maxmem, double *map,
                     int *hitsmap, double *mapvar,
                     double *weights, char data_units[], int *status ) {

  /* Local Variables */
  size_t aiter;                 /* Actual iterations of sigma clipper */
  size_t apod=0;                /* Length of apodization window */
  smfArray **ast=NULL;          /* Astronomical signal */
  double *ast_data=NULL;        /* Pointer to DATA component of ast */
  smfGroup *astgroup=NULL;      /* smfGroup of ast model files */
  double badfrac;               /* Bad bolo fraction for flagging */
  int baseorder;                /* Order of poly for baseline fitting */
  int bolomap=0;                /* If set, produce single bolo maps */
  size_t bstride;               /* Bolometer stride */
  double *chisquared=NULL;      /* chisquared for each chunk each iter */
  double chitol=0;              /* chisquared change tolerance for stopping */
  size_t contchunk;             /* Which chunk in outer loop */
  int converged=0;              /* Has stopping criteria been met? */
  smfDIMMData dat;              /* Struct passed around to model components */
  smfData *data=NULL;           /* Temporary smfData pointer */
  dim_t dcbox=0;                /* Box size for fixing DC steps */
  int dcflag=0;                 /* Flag for dc step finder/repairer */
  double dcthresh;              /* Threshold for fixing primary DC steps */
  double dcthresh2;             /* Threshold for fixing secondary DC steps */
  int deldimm=0;                /* Delete temporary .DIMM files */
  int dimmflags;                /* Control flags for DIMM model components */
  int dofft=0;                  /* Set if freq. domain filtering the data */
  dim_t dsize;                  /* Size of data arrays in containers */
  double dtemp;                 /* temporary double */
  int exportNDF=0;              /* If set export DIMM files to NDF at end */
  int *exportNDF_which=NULL;    /* Which models in modelorder will be exported*/
  int noexportsetbad=0;         /* Don't set bad values in exported models */
  int fillgaps;                 /* If set perform gap filling */
  smfFilter *filt=NULL;         /* Pointer to filter struct */
  double flagstat;              /* Threshold for flagging stationary regions */
  double f_edgelow=0;           /* Freq. cutoff for low-pass edge filter */
  double f_edgehigh=0;          /* Freq. cutoff for high-pass edge filter */
  double f_notchlow[SMF__MXNOTCH]; /* Array low-freq. edges of notch filters */
  double f_notchhigh[SMF__MXNOTCH];/* Array high-freq. edges of notch filters */
  int f_nnotch=0;               /* Number of notch filters in array */
  dim_t goodbolo;               /* Number of good bolometers */
  int haveast=0;                /* Set if AST is one of the models */
  int haveext=0;                /* Set if EXT is one of the models */
  int havegai=0;                /* Set if GAI is one of the models */
  int havenoi=0;                /* Set if NOI is one of the models */
  smfHead *hdr=NULL;            /* Pointer to smfHead */
  dim_t i;                      /* Loop counter */
  int ii;                       /* Loop counter */
  dim_t idx=0;                  /* index within subgroup */
  smfGroup *igroup=NULL;        /* smfGroup corresponding to igrp */
  int isize;                    /* Number of files in input group */
  int iter;                     /* Iteration number */
  int itermap=0;                /* If set, produce maps each iteration */
  dim_t j;                      /* Loop counter */
  dim_t k;                      /* Loop counter */
  dim_t l;                      /* Loop counter */
  double *lastchisquared=NULL;  /* chisquared for last iter */
  smfArray **lut=NULL;          /* Pointing LUT for each file */
  int *lut_data=NULL;           /* Pointer to DATA component of lut */
  smfGroup *lutgroup=NULL;      /* smfGroup of lut model files */
  dim_t maxconcat;              /* Longest continuous chunk length in samples*/
  int maxiter=0;                /* Maximum number of iterations */
  dim_t maxlen=0;               /* Max chunk length in samples */
  int memiter=0;                /* If set iterate completely in memory */
  size_t memneeded;             /* Memory required for map-maker */
  smfArray ***model=NULL;       /* Array of pointers smfArrays for ea. model */
  smfGroup **modelgroups=NULL;  /* Array of group ptrs/ each model component */
  char *modelname=NULL;         /* Name of current model component */
  char modelnames[SMF_MODEL_MAX*4]; /* Array of all model components names */
  smf_modeltype *modeltyps=NULL;/* Array of model types */
  smf_calcmodelptr modelptr=NULL; /* Pointer to current model calc function */
  dim_t msize;                  /* Number of elements in map */
  char name[GRP__SZNAM+1];      /* Buffer for storing exported model names */
  dim_t nbolo;                  /* Number of bolometers */
  dim_t nchunks=0;              /* Number of chunks within iteration loop */
  size_t ncontchunks=0;         /* Number continuous chunks outside iter loop*/
  size_t nflag;                 /* Number of flagged detectors */
  int nm=0;                     /* Signed int version of nmodels */
  dim_t nmodels=0;              /* Number of model components / iteration */
  int numiter;                  /* Total number iterations */
  dim_t padEnd=0;               /* How many samples of padding at the end */
  dim_t padStart=0;             /* How many samples of padding at the start */
  char *pname=NULL;             /* Poiner to name */
  smfArray **qua=NULL;          /* Quality flags for each file */
  unsigned char *qua_data=NULL; /* Pointer to DATA component of qua */
  smfGroup *quagroup=NULL;      /* smfGroup of quality model files */
  int quit=0;                   /* flag indicates when to quit */
  int rebinflags;               /* Flags to control rebinning */
  smfArray **res=NULL;          /* Residual signal */
  double *res_data=NULL;        /* Pointer to DATA component of res */
  smfGroup *resgroup=NULL;      /* smfGroup of model residual files */
  double scalevar=0;            /* scale factor for variance */
  size_t spikeiter=0;           /* Number of iter for spike detection */
  double spikethresh;           /* Threshold for spike detection */
  double steptime;              /* Length of a sample in seconds */
  int temp;                     /* temporary signed integer */
  int *thishits=NULL;           /* Pointer to this hits map */
  double *thismap=NULL;         /* Pointer to this map */
  smf_modeltype thismodel;      /* Type of current model */
  double *thisweight=NULL;      /* Pointer to this weights map */
  double *thisvar=NULL;         /* Pointer to this variance map */
  size_t try;                   /* Try to concatenate this many samples */
  size_t tstride;               /* Time stride */
  struct timeval tv1, tv2;      /* Timers */
  int untilconverge=0;          /* Set if iterating to convergence */
  double *var_data=NULL;        /* Pointer to DATA component of NOI */
  int varmapmethod=0;           /* Method for calculating varmap */
  dim_t whichast=0;             /* Model index of AST (must be specified) */
  dim_t whichext=0;             /* Model index of EXT if present */
  dim_t whichgai=0;             /* Model index of GAI if present */
  dim_t whichnoi=0;             /* Model index of NOI if present */

  /* Main routine */
  if (*status != SAI__OK) return;

  /* Calculate number of elements in the map */
  if( (ubnd_out[0]-lbnd_out[0] < 0) || (ubnd_out[1]-lbnd_out[1] < 0) ) {
    *status = SAI__ERROR;
    msgSeti("L0",lbnd_out[0]);
    msgSeti("L1",lbnd_out[1]);
    msgSeti("U0",ubnd_out[0]);
    msgSeti("U1",ubnd_out[1]);
    errRep("", FUNC_NAME ": Invalid mapbounds: LBND=[^L0,^L1] UBND=[^U0,^U1]",
           status);
  }

  msize = (dim_t) (ubnd_out[0]-lbnd_out[0]+1) *
    (dim_t) (ubnd_out[1]-lbnd_out[1]+1);

  /* Get size of the input group */
  isize = grpGrpsz( igrp, status );

  /* Parse the CONFIG parameters stored in the keymap */
  if( *status == SAI__OK ) {
    /* Number of iterations */
    if( !astMapGet0I( keymap, "NUMITER", &numiter ) ) {
      numiter = -20;
    }

    if( numiter == 0 ) {
      *status = SAI__ERROR;
      errRep("", FUNC_NAME ": NUMITER cannot be 0", status);
    } else {
      if( numiter < 0 ) {
        /* If negative, iterate to convergence or abs(numiter), whichever comes
           first */
        maxiter = abs(numiter);
        untilconverge = 1;
      } else {
        /* Otherwise iterate a fixed number of times */
        maxiter = numiter;
        untilconverge = 0;
      }
    }

    /* Chisquared change tolerance for stopping */
    if( !astMapGet0D( keymap, "CHITOL", &chitol ) ) {
      chitol = 0.0001;
    }

    if( chitol <= 0 ) {
      *status = SAI__ERROR;
      msgSetd("CHITOL",chitol);
      errRep(FUNC_NAME,
             FUNC_NAME ": CHITOL is ^CHITOL, must be > 0", status);
    }

    /* Do iterations completely in memory - minimize disk I/O */
    if( !astMapGet0I( keymap, "MEMITER", &memiter ) ) {
      memiter = 0;
    }

    if( memiter ) {
      msgOutif(MSG__VERB, " ",
               FUNC_NAME ": MEMITER set; perform iterations in memory",
               status );
    } else {
      msgOutif(MSG__VERB, " ",
               FUNC_NAME ": MEMITER not set; perform iterations on disk",
               status );

      /* Should temporary .DIMM files be deleted at the end? */
      astMapGet0I( keymap, "DELDIMM", &deldimm );
    }

    /* Are we going to produce single-bolo maps? */
    if( !astMapGet0I( keymap, "BOLOMAP", &bolomap ) ) {
      bolomap = 0;
    }

    /* Are we going to produce maps for each iteration? */
    if( !astMapGet0I( keymap, "ITERMAP", &itermap ) ) {
      itermap = 0;
    }

    /* Are we going to set bad values in exported models? */
    if( !astMapGet0I( keymap, "NOEXPORTSETBAD", &noexportsetbad ) ) {
      noexportsetbad = 0;
    }

    /* Method to use for calculating the variance map */
    if( !astMapGet0I( keymap, "VARMAPMETHOD", &varmapmethod ) ) {
      varmapmethod = 0;
    }

    if( varmapmethod ) {
      msgOutif(MSG__VERB, " ",
               FUNC_NAME ": Will use sample variance to estimate"
               " variance map", status );
    } else {
      msgOutif(MSG__VERB, " ",
               FUNC_NAME ": Will use error propagation to estimate"
               " variance map", status );
    }


    /* Data-cleaning parameters (should match SC2CLEAN) */
    smf_get_cleanpar( keymap, &apod, &badfrac, &dcbox, &dcflag, &dcthresh,
                      &dcthresh2, NULL, &fillgaps, &f_edgelow,
                      &f_edgehigh, f_notchlow, f_notchhigh, &f_nnotch,
                      &dofft, &flagstat, &baseorder, &spikethresh,
                      &spikeiter, status ); 

    /* Maximum length of a continuous chunk */
    if( astMapGet0D( keymap, "MAXLEN", &dtemp ) ) {

      if( dtemp < 0.0 ) {
        /* Trap negative MAXLEN */
        *status = SAI__ERROR;
        errRep(FUNC_NAME, "Negative value for MAXLEN supplied.", status);
      } else if( dtemp == 0 ) {
        /* 0 is OK... gets ignored later */
        maxlen = 0;
      } else {
        /* Obtain sample length from header of first file in igrp */
        smf_open_file( igrp, 1, "READ", SMF__NOCREATE_DATA, &data, status );
        if( (*status == SAI__OK) && (data->hdr) ) {
          steptime = data->hdr->steptime;

          if( steptime > 0 ) {
            maxlen = (dim_t) (dtemp / steptime);
          } else {
            /* Trap invalid sample length in header */
            *status = SAI__ERROR;
            errRep(FUNC_NAME, "Invalid STEPTIME in FITS header.", status);
          }
        }
        smf_close_file( &data, status );
      }

    } else {
      maxlen = 0;
    }

    /* Padding */

    if( astMapGet0I( keymap, "PADSTART", &temp ) ) {
      if( temp < 0 ) {
        *status = SAI__ERROR;
        errRep(FUNC_NAME, "PADSTART cannot be < 0.", status );
      } else {
        padStart = (dim_t) temp;
      }
    } else {
      padStart = 0;
    }

    if( astMapGet0I( keymap, "PADEND", &temp ) ) {
      if( temp < 0 ) {
        *status = SAI__ERROR;
        errRep(FUNC_NAME, "PADEND cannot be < 0.", status );
      } else {
        padEnd = (dim_t) temp;
      }
    } else {
      padEnd = 0;
    }

    /* Type and order of models to fit from MODELORDER keyword */
    havenoi = 0;
    haveext = 0;

    if(astMapGet1C(keymap, "MODELORDER", 4, SMF_MODEL_MAX, &nm, modelnames)) {
      nmodels = (dim_t) nm;

      /* Allocate modeltyps */
      if( nmodels >= 1 ) {
        modeltyps = smf_malloc( nmodels, sizeof(*modeltyps), 1, status );
        /* Extra components for exportNDF_which for 'res', 'qua' */
        exportNDF_which = smf_malloc( nmodels+2, sizeof(*exportNDF_which),
                                      1, status );
      } else {
        msgOut(" ", FUNC_NAME ": No valid models in MODELORDER",
               status );
      }

      /* Loop over names and figure out enumerated type */
      for( i=0; (*status==SAI__OK)&&(i<nmodels); i++ ) {
        modelname = modelnames+i*4; /* Pointer to current name */
        thismodel = smf_model_gettype( modelname, status );

        if( *status == SAI__OK ) {
          modeltyps[i] = thismodel;

          /* set haveast/whichast */
          if( thismodel == SMF__AST ) {
            haveast = 1;
            whichast = i;
          }

          /* set havenoi/whichnoi */
          if( thismodel == SMF__NOI ) {
            havenoi = 1;
            whichnoi = i;
          }

          /* set haveext/whichext */
          if( thismodel == SMF__EXT ) {
            haveext = 1;
            whichext = i;
          }

          /* set havegai/whichgai */
          if( thismodel == SMF__GAI ) {
            havegai = 1;
            whichgai = i;
          }
        }
      }

    } else {
      *status = SAI__ERROR;
      errRep("", FUNC_NAME ": MODELORDER must be specified in config file!",
             status);
      nmodels = 0;
    }

    /* If !havenoi can't measure convergence, so turn off untilconverge */
    if( !havenoi ) {
    untilconverge = 0;
    }

    /* Fail if no AST model component was specified */
    if( !haveast ) {
      *status = SAI__ERROR;
      errRep("", FUNC_NAME ": AST must be member of MODELORDER in config file!",
             status);
    }


    /* Will we export components to NDF files at the end? */
    exportNDF = 0;
    if( (*status==SAI__OK) && astMapHasKey( keymap, "EXPORTNDF" ) ){
      /* There are two possibilities: (i) the user specified a "1" or
         a "0" indicating all or none of the models should be
         exported; or (ii) a vector containing the 3-character model
         names for each component that will be exported (same syntax as
         modelorder) */

      if(astMapGet1C(keymap, "EXPORTNDF", 4, SMF_MODEL_MAX, &nm, modelnames)) {
        /* Re-use variables used to parse MODELORDER. If there is a
         single element check to see if it is a single digit for the
         0/1 case. Otherwise try to find matches to each of the parsed
         MODELORDER components */

        if( (nm==1) && (strlen(modelnames)<3) ) {
          if( strtol(modelnames,NULL,10) == 1 ) {
            /* Export all of the model components */
            exportNDF = 1;
            for( i=0; (*status==SAI__OK)&&(i<nmodels); i++ ) {
              exportNDF_which[i] = 1;
            }
          }
        } else {
          /* Selectively export components */
          for( ii=0; (*status==SAI__OK)&&(ii<nm); ii++ ) {
            modelname = modelnames+ii*4; /* Pointer to current name */
            thismodel = smf_model_gettype( modelname, status );

            /* Check to see if thismodel matches something in modeltyps */
            for( j=0; (*status==SAI__OK)&&(j<nmodels); j++ ) {
              if( thismodel == modeltyps[j] ) {
                /* Found a hit -- export this model component */
                exportNDF = 1;
                exportNDF_which[j] = 1;

                /* Need to export RES as well if NOI is specified
                   since it becomes the variance component of the
                   residual file */
                if( thismodel == SMF__NOI ) {
                  exportNDF_which[nmodels]=1;
                }
              }
            }

            /* If the model type is 'qua' handle it here */
            if( thismodel == SMF__QUA ) {
              exportNDF = 1;
              /* Like noi, qua becomes quality component of res */
              exportNDF_which[nmodels]=1;
              exportNDF_which[nmodels+1]=1;
            }

            /* If the model type is 'res' handle it here */
            if( thismodel == SMF__RES ) {
              exportNDF = 1;
              exportNDF_which[nmodels]=1;
            }
          }
        }
      }
    }
  }

  /* Merge wavelength specific keymap entries - we need to know the wavelength
     regime of this data so we either open a file or we have a parameter
     passed in to smf_iteratemap from a previous file opening. Assumes
     that all input files are same wavelength. */
  smf_open_file( igrp, 1, "READ", SMF__NOCREATE_DATA, &data, status );
  if (*status == SAI__OK) {
    smf_subinst_t subinst;
    const char  *suffix = NULL;
    subinst = smf_calc_subinst( data->hdr, status );
    if (subinst == SMF__SUBINST_850) {
      suffix = "_850";
    } else if (subinst == SMF__SUBINST_450) {
      suffix = "_450";
    } else {
      if (*status == SAI__OK) {
        *status = SAI__ERROR;
        errRep( "", "Unrecognized sub-instrument", status );
      }
    }

    /* these are upper case by this point */
    smf_merge_keymaps( keymap, "FLT", suffix, status );
    smf_merge_keymaps( keymap, "COM", suffix, status );
    smf_merge_keymaps( keymap, "GAI", suffix, status );
    smf_merge_keymaps( keymap, "EXT", suffix, status );
    smf_merge_keymaps( keymap, "AST", suffix, status );
    smf_merge_keymaps( keymap, "NOI", suffix, status );
  }
  smf_close_file( &data, status );

  if( untilconverge ) {
    msgSeti("MAX",maxiter);
    msgOut(" ",
           FUNC_NAME ": Iterate to convergence (max ^MAX)",
           status );
    msgSetd("CHITOL",chitol);
    msgOut(" ",
           FUNC_NAME ": Stopping criteria is a change in chi^2 < ^CHITOL",
           status);
  } else {
    msgSeti("MAX",maxiter);
    msgOut(" ", FUNC_NAME ": ^MAX Iterations", status );
  }

  msgSeti("NUMCOMP",nmodels);
  msgOutif(MSG__VERB," ",
           FUNC_NAME ": ^NUMCOMP model components in solution: ",
           status);
  for( i=0; i<nmodels; i++ ) {
    msgSetc( "MNAME", smf_model_getname(modeltyps[i], status) );
    msgOutif(MSG__VERB,
             " ", "  ^MNAME", status );
  }

  /* Create an ordered smfGrp which keeps track of files corresponding to
     different subarrays (observed simultaneously), as well as time-ordering
     the files. Now added "chunk" to smfGroup as well -- this is used to
     concatenate _only_ continuous pieces of data. We subtract padStart
     and padEnd from maxlen since these also add to the file length. */

  smf_grp_related( igrp, isize, 1, maxlen-padStart-padEnd, &maxconcat,
                   &igroup, NULL, status );

  /* Once we've run smf_grp_related we know how many subarrays there
     are.  We also know the maximum length of a concatenated piece of
     data, and which model components were requested. Use this
     information to check that enough memory is available. */

  if( *status == SAI__OK ) {

    smf_checkmem_dimm( maxconcat, INST__SCUBA2, igroup->nrelated, modeltyps,
                       nmodels, maxmem, &memneeded, status );

    if( *status == SMF__NOMEM ) {
      /* If we need too much memory, generate a warning message and then try
         to re-group the files using smaller chunks */

      errAnnul( status );
      msgOut( " ", FUNC_NAME ": *** WARNING ***", status );
      msgSeti( "LEN", maxconcat );
      msgSeti( "AVAIL", maxmem/SMF__MB );
      msgSeti( "NEED", memneeded/SMF__MB );
      msgOut( " ", "  ^LEN continuous samples requires ^NEED Mb > ^AVAIL Mb",
              status );

      /* Try is meant to be the largest chunks of ~equal length that fit in
         memory */
      try = maxconcat / ((size_t) ((double) memneeded/maxmem)+1)+1;

      msgSeti( "TRY", try );
      msgOut( " ", "  Will try to re-group data in chunks < ^TRY samples long",
              status);
      msgOut( " ", FUNC_NAME ": ***************", status );

      /* Close igroup if needed before re-running smf_grp_related */

      if( igroup ) {
        smf_close_smfGroup( &igroup, status );
      }

      smf_grp_related( igrp, isize, 1, try, &maxconcat, &igroup, NULL, status );
    }
  }

  if( *status == SAI__OK ) {

    if( memiter ) {
      /* only one concatenated chunk within the iteration loop */
      nchunks = 1;

      /* however, there are multiple large continuous pieces outside the
         iteration loop */
      ncontchunks = igroup->chunk[igroup->ngroups-1]+1;
    } else {
      /* Otherwise number of chunks is just number of objects in the
         input group */
      nchunks = igroup->ngroups;

      /* No looping over larger continuous chunks outside the iteration loop */
      ncontchunks = 1;
    }

    if( memiter ) {
      msgSeti( "NCONTCHUNKS", ncontchunks );
      msgOutif(MSG__VERB," ",
               FUNC_NAME ": ^NCONTCHUNKS large continuous chunks outside"
               " iteration loop.", status);
    } else {
      msgSeti( "NCHUNKS", nchunks );
      msgOutif(MSG__VERB," ",
               FUNC_NAME ": ^NCHUNKS file chunks inside iteration loop.",
               status);
    }
  }


  /* There are two loops over files apart from the iteration. In the
     memiter=1 case the idea is to concatenate all continuous data
     into several large chunks, and iterate each one of those to
     completion without any file i/o. These are called
     "contchunk". Inside the iteration loop, if memiter=0, loop over
     each input file; those are called "chunk". Lots of file i/o,
     poorer map solution, but runs with less memory. */

  for( contchunk=0; contchunk<ncontchunks; contchunk++ ) {

    if( memiter ) {
      msgSeti("CHUNK", contchunk+1);
      msgSeti("NUMCHUNK", ncontchunks);
      msgOut( " ",
              FUNC_NAME ": Continuous chunk ^CHUNK / ^NUMCHUNK =========",
              status);
    }

    /*** TIMER ***/
    smf_timerinit( &tv1, &tv2, status );

    if( *status == SAI__OK ) {

      /* Setup the map estimate from the current contchunk. */
      if( contchunk == 0 ) {
        /* For the first chunk, calculate the map in-place */
        thismap = map;
        thishits = hitsmap;
        thisvar = mapvar;
        thisweight = weights;
      } else if( contchunk == 1 ) {
        /* Subsequent chunks are done in new map arrays and then added to
           the first */
        thismap = smf_malloc( msize, sizeof(*thismap), 0, status );
        thishits = smf_malloc( msize, sizeof(*thishits), 0, status );
        thisvar = smf_malloc( msize, sizeof(*thisvar), 0, status );
        thisweight = smf_malloc( msize, sizeof(*thisweight), 0, status );
      }

      if( memiter ) {

        /* If memiter=1 concat everything in this contchunk into a
           single smfArray. Note that the pointing LUT gets generated in
           smf_concat_smfGroup below. */

        msgSeti("C",contchunk+1);
        msgOutif(MSG__VERB," ",
                 FUNC_NAME ": Concatenating files in continuous chunk ^C",
                 status);

        /* Allocate length 1 array of smfArrays. */
        res = smf_malloc( nchunks, sizeof(*res), 1, status );

        /* Concatenate (no variance since we calculate it ourselves -- NOI) */
        smf_concat_smfGroup( wf, igroup, darks, bbms, contchunk, 1, 0, outfset,
                             moving, lbnd_out, ubnd_out, padStart, padEnd,
                             SMF__NOCREATE_VARIANCE, &res[0], status );

        /*** TIMER ***/
        msgOutiff( MSG__DEBUG, "", FUNC_NAME ": ** %f s concatenating data",
                   status, smf_timerupdate(&tv1,&tv2,status) );
      }
    }

    /* Check units */
    if (*status == SAI__OK) {
      smfData *tmpdata = res[0]->sdata[0];
      /* Check units are consistent */
      if (tmpdata && tmpdata->hdr) {
        smf_check_units( contchunk+1, data_units, tmpdata->hdr, status);
      }
    }

    /* Allocate space for the chisquared array */
    if( havenoi ) {
      chisquared = smf_malloc( nchunks, sizeof(*chisquared), 1, status );
      lastchisquared = smf_malloc( nchunks, sizeof(*chisquared), 1, status );
    }

    /* Create containers for time-series model components */
    msgOutif(MSG__VERB," ", FUNC_NAME ": Create model containers", status);

    /* Components that always get made */
    if( igroup && (*status == SAI__OK) ) {

      /* there is one smfArray for LUT, AST and QUA at each chunk */
      lut = smf_malloc( nchunks, sizeof(*lut), 1, status );
      ast = smf_malloc( nchunks, sizeof(*ast), 1, status );
      qua = smf_malloc( nchunks, sizeof(*qua), 1, status );

      if( memiter ) {
        /* If iterating in memory then RES has already been created from
           the concatenation of the input data. Create the other
           required models using res[0] as a template. Assert
           bolo-ordered data although the work has already been done at
           the concatenation stage. */

        smf_model_create( wf, NULL, res, nchunks, SMF__LUT, 0,
                          NULL, 0, NULL, NULL,
                          NULL, memiter,
                          memiter, lut, 0, keymap, status );

        smf_model_create( wf, NULL, res, nchunks, SMF__AST, 0,
                          NULL, 0, NULL, NULL,
                          NULL, memiter,
                          memiter, ast, 0, keymap, status );

        smf_model_create( wf, NULL, res, nchunks, SMF__QUA, 0,
                          NULL, 0, NULL, NULL,
                          NULL, memiter,
                          memiter, qua, flagstat, keymap, status );

        /* Since a copy of the LUT is still open in res[0] free it up here */
        for( i=0; i<res[0]->ndat; i++ ) {
          if( res[0]->sdata[i] ) {
            smf_close_mapcoord( res[0]->sdata[i], status );
          }
        }

      } else {
        /* If iterating using disk i/o need to create res and other model
           components using igroup as template. In this case the pointing
           LUT probably doesn't exist, so give projection information to
           smf_model_create. Also assert bolo-ordered template
           (in this case res). */

        res = smf_malloc( nchunks, sizeof(*res), 1, status );

        smf_model_create( wf, igroup, NULL, 0, SMF__RES, 0,
                          NULL, 0, NULL, NULL,
                          &resgroup, memiter,
                          memiter, res, 0, keymap, status );

        smf_model_create( wf, igroup, NULL, 0, SMF__LUT, 0,
                          outfset, moving, lbnd_out, ubnd_out,
                          &lutgroup, memiter,
                          memiter, lut, 0, keymap, status );

        smf_model_create( wf, igroup, NULL, 0, SMF__AST, 0,
                          NULL, 0, NULL, NULL,
                          &astgroup, memiter,
                          memiter, ast, 0, keymap, status );

        smf_model_create( wf, igroup, NULL, 0, SMF__QUA, 0,
                          NULL, 0, NULL, NULL,
                          &quagroup, memiter,
                          memiter, qua, flagstat, keymap, status );
      }
    }

    /*** TIMER ***/
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": ** %f s creating static models",
               status, smf_timerupdate(&tv1,&tv2,status) );

    /* Dynamic components */
    if( igroup && (nmodels > 0) && (*status == SAI__OK) ) {

      /* nmodel array of pointers to nchunk smfArray pointers */
      model = smf_malloc( nmodels, sizeof(*model), 1, status );

      if( memiter != 1 ) {
        /* Array of smfgroups (one for each dynamic model component) */
        modelgroups = smf_malloc( nmodels, sizeof(*modelgroups), 1, status );
      }

      for( i=0; i<nmodels; i++ ) {
        model[i] = smf_malloc( nchunks, sizeof(**model), 1, status );

        if( memiter ) {
          smf_model_create( wf, NULL, res, nchunks, modeltyps[i], 0,
                            NULL, 0, NULL, NULL,
                            NULL, memiter, memiter, model[i], 0, keymap,
                            status );

        } else {
          smf_model_create( wf, igroup, NULL, 0, modeltyps[i], 0,
                            NULL, 0, NULL, NULL, &modelgroups[i],
                            memiter, memiter, model[i], 0, keymap,
                            status );
        }
      }
    }

    /*** TIMER ***/
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": ** %f s creating dynamic models",
               status, smf_timerupdate(&tv1,&tv2,status) );

    /* Start the main iteration loop */
    if( *status == SAI__OK ) {

      /* Stuff pointers into smfDIMMData to pass around to model component
         solvers */

      memset( &dat, 0, sizeof(dat) ); /* Initialize structure */
      dat.res = res;
      dat.qua = qua;
      dat.lut = lut;
      dat.map = thismap;
      dat.hitsmap = thishits;
      dat.mapvar = thisvar;
      dat.mapweight = thisweight;
      dat.msize = msize;
      dat.chisquared = chisquared;
      if( havenoi ) {
        dat.noi = model[whichnoi];
      } else {
        dat.noi = NULL;
      }
      if( haveext ) {
        dat.ext = model[whichext];
      } else {
        dat.ext = NULL;
      }
      if( havegai ) {
        dat.gai = model[whichgai];
      } else {
        dat.gai = NULL;
      }
      quit = 0;
      iter = 0;
      while( !quit ) {
        msgSeti("ITER", iter+1);
        msgSeti("MAXITER", maxiter);
        msgOut(" ",
               FUNC_NAME ": Iteration ^ITER / ^MAXITER ---------------",
               status);

        /* Assume we've converged until we find a chunk that hasn't */
        if( iter > 0 ) {
          converged = 1;
        } else {
          converged = 0;
        }

        for( i=0; i<nchunks; i++ ) {
          if( !memiter ) {
            msgSeti("CHUNK", i+1);
            msgSeti("NUMCHUNK", nchunks);
            msgOut(" ", FUNC_NAME ": File chunk ^CHUNK / ^NUMCHUNK",
                   status);
          }

          /* Open model files here if looping on-disk. Otherwise everything
             is already open from the smf_model_create calls */

          if( !memiter ) {

            /* If memiter not set open this chunk here */
            smf_open_related_model( resgroup, i, "UPDATE", &res[i], status );
            smf_open_related_model( lutgroup, i, "UPDATE", &lut[i], status );
            smf_open_related_model( astgroup, i, "UPDATE", &ast[i], status );
            smf_open_related_model( quagroup, i, "UPDATE", &qua[i], status );

            for( j=0; j<nmodels; j++ ) {
              smf_open_related_model( modelgroups[j], i, "UPDATE",
                                      &model[j][i], status );
            }

            /*** TIMER ***/
            msgOutiff( MSG__DEBUG, "", FUNC_NAME
                       ": ** %f s opening model files",
                       status, smf_timerupdate(&tv1,&tv2,status) );
          }

          /* If first iteration pre-condition the data */
          if( iter == 0 ) {
            msgOut(" ", FUNC_NAME ": Pre-conditioning chunk", status);
            goodbolo=0; /* Initialize good bolo count for this chunk */
            for( idx=0; idx<res[i]->ndat; idx++ ) {
              /* Synchronize quality flags */

              data = res[i]->sdata[idx];
              qua_data = qua[i]->sdata[idx]->pntr[0];

              msgOutif(MSG__VERB," ", "  update quality", status);
              smf_update_quality( data, qua_data, 1, NULL, badfrac, status );

              if( baseorder >= 0 ) {
                msgOutif(MSG__VERB," ", "  fit polynomial baselines", status);
                smf_scanfit( data, qua_data, baseorder, status );

                msgOutif(MSG__VERB," ", "  remove polynomial baselines",
                         status);
                smf_subtract_poly( data, qua_data, 0, status );
              }

              /* Flag/repair bad detectors with DC steps in them */

              if( dcthresh && dcbox ) {
                msgOutif(MSG__VERB," ", "  find bolos with steps...", status);
                smf_correct_steps( wf, data, qua_data, dcthresh, dcthresh2, dcbox, 
                                   dcflag, &nflag, status );
                msgOutiff(MSG__VERB, "","  ...%li flagged\n", status, nflag);
              }

              if( spikethresh ) {
                msgOutif(MSG__VERB," ", "  flag spikes...", status);
                smf_flag_spikes( data, NULL, qua_data,
                                 ~(SMF__Q_JUMP|SMF__Q_STAT),
                                 spikethresh, spikeiter, 100,
                                 &aiter, &nflag, status );
                msgOutiff(MSG__VERB,"", "  ...found %li in %li iterations",
                          status, nflag, aiter );
              }

              if( fillgaps ) {
                msgOutif(MSG__VERB," ", "  gap filling", status);
                smf_fillgaps( wf, data, qua_data, SMF__Q_GAP, status );
              }
              
              if( apod ) {
                msgOutif(MSG__VERB," ", "  apodizing data", status);
                smf_apodize( data, qua_data, apod, status );
              }

              /* filter the data */
              filt = smf_create_smfFilter( data, status );
              smf_filter_fromkeymap( filt, keymap, &dofft, status );
              if( dofft ) {
                msgOutif( MSG__VERB," ", "  frequency domain filter", status );
                smf_filter_execute( NULL, data, filt, status );
              }
              filt = smf_free_smfFilter( filt, status );

              /* Count number of good bolometers in the file after flagging */
              smf_get_dims( data, NULL, NULL, &nbolo, NULL, NULL, &bstride,
                            NULL, status );

              for( j=0; (*status==SAI__OK)&&(j<nbolo); j++ ) {
                if( !(qua_data[j*bstride]&SMF__Q_BADB) ) {
                  goodbolo++;
                }
              }
            }

            /*** TIMER ***/
            msgOutiff( MSG__DEBUG, "", FUNC_NAME
                       ": ** %f s pre-conditioning data",
                       status, smf_timerupdate(&tv1,&tv2,status) );
          }

          msgOut(" ",
                 FUNC_NAME ": Calculate time-stream model components",
                 status);

          /* Call the model calculations in the desired order */
          if( *status == SAI__OK ) {

            /* If this is the first iteration just do all of the models up
               to AST. Subsequent iterations start at the first model after
               AST, and then loop back to the start */

            if( iter == 0 ) {
              l = 0;
            } else {
              l = whichast+1;
            }

            for( k=l; (*status==SAI__OK)&&((k%nmodels)!=whichast); k++ ) {
              /* Which model component are we on */
              j = k%nmodels;

              /* If this is the first model component and not the first
                 iteration, we need to undo EXTinction and GAIn (if used
                 for flatfielding) so that RES/NOI are in the correct
                 units. */

              if( (j==0) && (iter>0) ) {
                if( haveext ) {
                  msgOutiff( MSG__VERB, "",
                             "  ** undoing EXTinction from previous iteration",
                             status );
                  smf_calcmodel_ext( wf, &dat, i, keymap, model[whichext],
                                     SMF__DIMM_INVERT, status );
                }

                /*** TIMER ***/
                msgOutiff( MSG__DEBUG, "", FUNC_NAME
                           ": ** %f s undoing EXT",
                           status, smf_timerupdate(&tv1,&tv2,status) );

                if( havegai ) {
                  msgOutiff( MSG__VERB, "",
                             "  ** undoing GAIn from previous iteration",
                             status );
                  smf_calcmodel_gai( wf, &dat, i, keymap, model[whichgai],
                                     SMF__DIMM_INVERT, status );
                }

                /*** TIMER ***/
                msgOutiff( MSG__DEBUG, "", FUNC_NAME
                           ": ** %f s undoing GAI",
                           status, smf_timerupdate(&tv1,&tv2,status) );
              }

              /* Message stating which model we're in */
              msgSetc("MNAME", smf_model_getname(modeltyps[j],status));
              msgOutif(MSG__VERB," ", "  ^MNAME", status);
              modelptr = smf_model_getptr( modeltyps[j], status );

              /* Set up control flags for the model calculation */
              dimmflags = 0;

              if( iter==0 ) dimmflags |= SMF__DIMM_FIRSTITER;

              if( (iter==1) && (j>whichast) ) {
                /* In the case that AST is not the last model component,
                   the last models will not be calculated for the first time
                   until the start of the second iteration. */
                dimmflags |= SMF__DIMM_FIRSTITER;
              }

              if( *status == SAI__OK ) {
                (*modelptr)( wf, &dat, i, keymap, model[j], dimmflags, status );
              }

              /*** TIMER ***/
              msgOutiff( MSG__DEBUG, "", FUNC_NAME
                         ": ** %f s calculating model",
                         status, smf_timerupdate(&tv1,&tv2,status) );
            }
          }

          /* Once all the other model components have been calculated put the
             previous iteration of AST back into the residual. Note that
             even though we've moved signals out from the time streams into
             the map we don't zero AST here so that we can see how much it
             has changed within smf_calcmodel_ast. */

          msgOut(" ", FUNC_NAME ": Rebin residual to estimate MAP",
                 status);

          if( *status == SAI__OK ) {

            /* Loop over subgroup index (subarray) */
            for( idx=0; idx<res[i]->ndat; idx++ ) {

              /* Add last iter. of astronomical signal back in to residual */
              ast_data = (ast[i]->sdata[idx]->pntr)[0];
              res_data = (res[i]->sdata[idx]->pntr)[0];
              lut_data = (lut[i]->sdata[idx]->pntr)[0];
              qua_data = (qua[i]->sdata[idx]->pntr)[0];

              if( havenoi ) {
                var_data = (dat.noi[i]->sdata[idx]->pntr)[0];
              } else {
                var_data = NULL;
              }

              dsize = (ast[i]->sdata[idx]->dims)[0] *
                (ast[i]->sdata[idx]->dims)[1] * (ast[i]->sdata[idx]->dims)[2];

              for( k=0; k<dsize; k++ ) {
                if( !(qua_data[k]&SMF__Q_MOD) && (ast_data[k]!=VAL__BADD) ) {
                  res_data[k] += ast_data[k];
                }
              }

              /* Setup rebin flags */
              rebinflags = 0;
              if( (i == 0) && (idx == 0) ) {
                /* First call to rebin clears the arrays */
                rebinflags = rebinflags | AST__REBININIT;
              }

              if( (i == nchunks-1) && (idx == res[i]->ndat-1) ) {
                /* Final call to rebin re-normalizes */
                rebinflags = rebinflags | AST__REBINEND;
              }

              /* Rebin the residual + astronomical signal into a map */
              smf_rebinmap1( res[i]->sdata[idx],
                             dat.noi ? dat.noi[i]->sdata[idx] : NULL,
                             lut_data, qua_data, SMF__Q_GOOD, varmapmethod,
                             rebinflags, thismap, thisweight, thishits,
                             thisvar, msize, &scalevar, status );
            }

            /*** TIMER ***/
            msgOutiff( MSG__DEBUG, "", FUNC_NAME
                       ": ** %f s rebinning map",
                       status, smf_timerupdate(&tv1,&tv2,status) );

            /* If storing each iteration in an extension do it here if this
               was the last chunk of data to be added */

            if( itermap && (i == nchunks-1) ) {
               Grp *mgrp=NULL;        /* Temporary group to hold map name */
               smfData *imapdata=NULL;/* smfData for this iteration map */
               char tmpname[GRP__SZNAM+1]; /* temp name buffer */
               char tempstr[20];

               /* Create a name for this iteration map, take into
                  account the chunk number. Only required if we are
                  using a single output container. */

               pname = tmpname;
               grpGet( iterrootgrp, 1, 1, &pname, sizeof(tmpname), status );
               one_strlcpy( name, tmpname, sizeof(name), status );
               one_strlcat( name, ".", sizeof(name), status );
               if (ncontchunks > 1) {
                 sprintf(tempstr, "CH%02lu", contchunk);
                 one_strlcat( name, tempstr, sizeof(name), status );
               }
               sprintf( tempstr, "I%03i", iter+1 );
               one_strlcat( name, tempstr, sizeof(name), status );
               mgrp = grpNew( "itermap", status );
               grpPut1( mgrp, name, 0, status );

               msgOutf( "", "*** Writing map from this iteration to %s", status,
                        name );

               smf_open_newfile ( mgrp, 1, SMF__DOUBLE, 2, lbnd_out,
                                  ubnd_out, SMF__MAP_VAR, &imapdata, status);

               /* Copy over the signal and variance maps */
               if( *status == SAI__OK ) {
                 memcpy( imapdata->pntr[0], thismap, msize*sizeof(*thismap) );
                 memcpy( imapdata->pntr[1], thisvar, msize*sizeof(*thismap) );
               }

               /* Write WCS */
               smf_set_moving(outfset,status);
               ndfPtwcs( outfset, imapdata->file->ndfid, status );

               /* Clean up */
               if( mgrp ) grpDelet( &mgrp, status );
               smf_close_file( &imapdata, status );
            }
          }

          /* Close files here if memiter not set */

          if( !memiter ) {
            smf_close_related( &res[i], status );
            smf_close_related( &ast[i], status );
            smf_close_related( &lut[i], status );
            smf_close_related( &qua[i], status );

            for( j=0; j<nmodels; j++ ) {
              smf_close_related( &model[j][i], status );
            }

            /*** TIMER ***/
            msgOutiff( MSG__DEBUG, "", FUNC_NAME
                       ": ** %f s closing model files",
                       status, smf_timerupdate(&tv1,&tv2,status) );
          }

          /* Set exit condition if bad status was set */
          if( *status != SAI__OK ) i=isize+1;

          /* If NOI was present, we now have an estimate of chisquared */
          if( (*status==SAI__OK) && chisquared ) {

            if( (iter==0) && (whichnoi>whichast) ) {
              /* If NOI comes after AST in MODELORDER we can't check chi^2 or
                 convergence until next iteration. */
              msgOut( "",
                      FUNC_NAME ": Will calculate chi^2 next iteration",
                      status );
            } else {
              msgSeti("CHUNK",i+1);
              msgSetd("CHISQ",chisquared[i]);
              msgOut( " ",
                      FUNC_NAME ": *** CHISQUARED = ^CHISQ for chunk "
                      "^CHUNK", status);

              if( ((iter > 0)&&(whichnoi<whichast)) ||
                  ((iter > 1)&&(whichnoi>whichast)) ) {
                /* Again, we have to check if NOI was calculated at least
                   twice, which depends on NOI and AST in MODELORDER */

                double chidiff;   /* temporary variable to store diff */

                chidiff = chisquared[i]-lastchisquared[i];

                msgSetd("DIFF", chidiff);
                msgOut( " ",
                        FUNC_NAME ": *** change: ^DIFF", status );

                if( chidiff > 0 ) {
                  msgOut( " ", FUNC_NAME
                          ": ****** WARNING! CHISQUARED Increased ******",
                          status );
                }

                /* Check for the stopping criterion */
                if( untilconverge ) {
                  if( (chidiff > 0) || (-chidiff > chitol) ) {
                    /* Found a chunk that isn't converged yet */
                    converged=0;
                  }
                }
              } else {
                /* Can't converge until at least 2 consecutive chi^2... */
                converged=0;
              }

              /* Update lastchisquared */
              lastchisquared[i] = chisquared[i];

            }
          }
        }

        if( *status == SAI__OK ) {
          msgOut(" ", FUNC_NAME ": Calculate ast", status);

          for( i=0; i<nchunks; i++ ) {

            /* Open files if memiter not set - otherwise they are still open
               from earlier call */
            if( !memiter ) {
              smf_open_related_model( astgroup, i, "UPDATE", &ast[i], status );
              smf_open_related_model( resgroup, i, "UPDATE", &res[i], status );
              smf_open_related_model( lutgroup, i, "UPDATE", &lut[i], status );
              smf_open_related_model( quagroup, i, "UPDATE", &qua[i], status );

              /*** TIMER ***/
              msgOutiff( MSG__DEBUG, "", FUNC_NAME
                         ": ** %f s opening model files",
                         status, smf_timerupdate(&tv1,&tv2,status) );
            }

            /* Calculate the AST model component. It is a special model
               because it assumes that the map contains the best current
               estimate of the astronomical sky. It gets called in this
               separate loop since the map estimate gets updated by
               each chunk in the main model component loop */

            smf_calcmodel_ast( wf, &dat, i, keymap, ast, 0, status );

            /*** TIMER ***/
            msgOutiff( MSG__DEBUG, "", FUNC_NAME
                       ": ** %f s calculating AST",
                       status, smf_timerupdate(&tv1,&tv2,status) );

            /* Close files if memiter not set */
            if( !memiter ) {
              smf_close_related( &ast[i], status );
              smf_close_related( &res[i], status );
              smf_close_related( &lut[i], status );
              smf_close_related( &qua[i], status );

              /*** TIMER ***/
              msgOutiff( MSG__DEBUG, "", FUNC_NAME
                         ": ** %f s closing model files",
                         status, smf_timerupdate(&tv1,&tv2,status) );
            }
          }
        }

        /* Increment iteration counter */
        iter++;

        if( *status == SAI__OK ) {

          /* Check that we've exceeded maxiter */
          if( iter >= maxiter ) {
            quit = 1;
          }

          /* Check for convergence */
          if( untilconverge && converged ) {
            quit = 1;
          }

        } else {
          quit = 1;
        }
      }

      msgSeti("ITER",iter);
      msgOut( " ",
              FUNC_NAME ": ****** Completed in ^ITER iterations", status);
      if( untilconverge && converged ) {
        msgOut( " ",
                FUNC_NAME ": ****** Solution CONVERGED",
                status);
      }

      /* Create sub-maps for each bolometer if requested. We add AST back
         into the residual, and rebin that single for each detector that
         is flagged as being OK */

      if( bolomap && (*status == SAI__OK) ) {
        /* Currently only support memiter=1 case to avoid having to do
           a separate chunk loop. */
        if( !memiter ) {
          msgOut( "", FUNC_NAME
                  ": *** WARNING *** bolomap=1, but memiter=0", status );
        } else {
          /* Loop over subgroup index (subarray) */
          for( idx=0; idx<res[0]->ndat; idx++ ) {
            unsigned char *bolomask = NULL;
            double *bmapweight = NULL;
            int *bhitsmap = NULL;

            /* Pointers to everything we need */
            ast_data = (ast[0]->sdata[idx]->pntr)[0];
            res_data = (res[0]->sdata[idx]->pntr)[0];
            lut_data = (lut[0]->sdata[idx]->pntr)[0];
            qua_data = (qua[0]->sdata[idx]->pntr)[0];

            smf_get_dims( res[0]->sdata[idx], NULL, NULL, &nbolo, NULL,
                          &dsize, &bstride, NULL, status );

            /* Add ast back into res. Mask should match ast_calcmodel_ast. */

            for( k=0; k<dsize; k++ ) {
              if( !(qua_data[k]&SMF__Q_MOD) && (ast_data[k]!=VAL__BADD) ) {
                res_data[k] += ast_data[k];
              }
            }

            /* Make a copy of the quality at first time slice as a good
               bolo mask, and then set quality to SMF__Q_BADB. Later we
               will unset BADB for one bolo at a time to make individual
               maps. */

            bolomask = smf_malloc( nbolo, sizeof(*bolomask), 0, status );
            bmapweight = smf_malloc(msize,sizeof(*bmapweight),0,status);
            bhitsmap = smf_malloc(msize,sizeof(*bhitsmap),0,status);

            if( *status == SAI__OK ) {
              for( k=0; k<nbolo; k++ ) {
                bolomask[k] = qua_data[k*bstride];
                qua_data[k*bstride] = SMF__Q_BADB;
              }

              /* Identify good bolos in the copied mask and produce a map */
              for( k=0; (k<nbolo)&&(*status==SAI__OK); k++ ) {
                if( !(bolomask[k]&SMF__Q_BADB) ) {
                  Grp *mgrp=NULL;       /* Temporary group to hold map names */
                  smfData *mapdata=NULL;/* smfData for new map */
                  char tmpname[GRP__SZNAM+1]; /* temp name buffer */
                  char thisbol[20];     /* name particular to this bolometer */

                  /* Set the quality back to good for this single bolometer */
                  qua_data[k*bstride] = bolomask[k];

                  /* Create a name for the new map, take into account the
                     chunk number. Only required if we are using a single
                     output container. */
                  pname = tmpname;
                  grpGet( bolrootgrp, 1, 1, &pname, sizeof(tmpname), status );
                  one_strlcpy( name, tmpname, sizeof(name), status );
                  one_strlcat( name, ".", sizeof(name), status );
                  if (ncontchunks > 1) {
                    char tempstr[20];
                    sprintf(tempstr, "CH%02lu", contchunk);
                    one_strlcat( name, tempstr, sizeof(name), status );
                  }
                  sprintf( thisbol, "C%02luR%02lu",
                           (k % res[0]->sdata[idx]->dims[1])+1,   /* x-coord */
                           (k / res[0]->sdata[idx]->dims[1])+1 ); /* y-coord */
                  one_strlcat( name, thisbol, sizeof(name), status );
                  mgrp = grpNew( "bolomap", status );
                  grpPut1( mgrp, name, 0, status );

                  msgOutf( "", "*** Writing single bolo map %s", status,
                           name );

                  smf_open_newfile ( mgrp, 1, SMF__DOUBLE, 2, lbnd_out,
                                     ubnd_out, SMF__MAP_VAR, &mapdata, status);

                  /* Rebin the data for this single bolometer. Don't care
                     about variance weighting because all samples from
                     same detector are about the same. */

                  smf_rebinmap1( res[0]->sdata[idx],
                                 dat.noi ? dat.noi[0]->sdata[idx] : NULL,
                                 lut_data, qua_data,
                                 SMF__Q_GOOD, varmapmethod,
                                 AST__REBININIT | AST__REBINEND,
                                 mapdata->pntr[0],
                                 bmapweight, bhitsmap, mapdata->pntr[1], msize,
                                 NULL, status );

                  /* Set the bolo to bad quality again */
                  qua_data[k*bstride] = SMF__Q_BADB;

                  /* Write WCS */
                  smf_set_moving(outfset,status);
                  ndfPtwcs( outfset, mapdata->file->ndfid, status );

                  /* Clean up */
                  if( mgrp ) grpDelet( &mgrp, status );
                  smf_close_file( &mapdata, status );

                }
              }

              /* Set quality back to its original state */
              for( k=0; k<nbolo; k++ ) {
                bolomask[k] = qua_data[k*bstride];
                qua_data[k*bstride] = SMF__Q_BADB;
              }
            }

            /* Free up memory */
            if( bolomask ) bolomask = smf_free( bolomask, status );
            if( bmapweight ) bmapweight = smf_free( bmapweight, status );
            if( bhitsmap ) bhitsmap = smf_free( bhitsmap, status );

            /* Remove ast from res once again */
            for( k=0; k<dsize; k++ ) {
              if( !(qua_data[k]&SMF__Q_MOD) && (ast_data[k]!=VAL__BADD) ) {
                res_data[k] -= ast_data[k];
              }
            }
          }
        }
      }

      /* Export DIMM model components to NDF files.
         Note that we don't do LUT since it is originally an extension in the
         input flatfielded data.
         Also - check that a filename is defined in the smfFile! */

      if( exportNDF && ((*status == SAI__OK) || (*status == SMF__INSMP)) ) {

        errBegin( status );

        msgOut(" ", FUNC_NAME ": Export model components to NDF files.",
               status);

        for( i=0; i<nchunks; i++ ) {  /* Chunk loop */
          msgSeti("CHUNK", i+1);
          msgSeti("NUMCHUNK", nchunks);
          msgOutif(MSG__VERB," ", "  Chunk ^CHUNK / ^NUMCHUNK", status);

          /* Open each subgroup, loop over smfArray elements and export,
             then close subgroup. DIMM open/close not needed if memiter set.
             Note that QUA and NOI get stuffed into the QUALITY and
             VARIANCE components of the residual. Also notice that
             everything must be changed to time-ordered data before
             writing ICD-compliant files. */

          if( !memiter ) { /* Open if we're doing disk i/o */
            /* Fixed components */
            smf_open_related_model( resgroup, i, "UPDATE", &res[i], status );
            smf_open_related_model( quagroup, i, "UPDATE", &qua[i], status );
            smf_open_related_model( astgroup, i, "UPDATE", &ast[i], status );

            /* Dynamic components */
            for( j=0; j<nmodels; j++ ) {
              smf_open_related_model( modelgroups[j], i, "UPDATE",
                                      &model[j][i], status );
            }
          }

          /* Loop over subgroup (subarray), re-order, set bad values
             wherever a SMF__Q_BADB flag is encountered (if requested),
             and export */
          for( idx=0; idx<res[i]->ndat; idx++ ) {
            smf_dataOrder( qua[i]->sdata[idx], 1, status );
            smf_dataOrder( res[i]->sdata[idx], 1, status );
            smf_dataOrder( ast[i]->sdata[idx], 1, status );

            /* Get quality array strides for smf_update_valbad */
            smf_get_dims( qua[i]->sdata[idx], NULL, NULL, NULL, NULL, NULL,
                          &bstride, &tstride, status );

            for( j=0; j<nmodels; j++ ) {

              /* Check for existence of the model for this subarray - in
                 some cases, like COM, there is only a file for one subarray,
                 unlike RES from which the range of idx is derived */
              if( model[j][i]->sdata[idx] ) {
                smf_dataOrder( model[j][i]->sdata[idx], 1, status );
                if( *status == SMF__WDIM ) {
                  /* fails if not 3-dimensional data. Just annul and write out
                     data as-is. */
                  errAnnul(status);
                  model[j][i]->sdata[idx]->isTordered=1;
                }
              }
            }

            if( *status == SAI__OK ) {
              if( memiter ) {
                /* Pointer to the header in the concatenated data */
                hdr = res[i]->sdata[idx]->hdr;
              } else {
                /* Open the header of the original input file in memiter=0
                   case since it won't have been stored in the .DIMM files */
                smf_open_file( igrp, resgroup->subgroups[i][idx], "READ",
                               SMF__NOCREATE_DATA, &data, status );
                if( *status == SAI__OK ) {
                  hdr = data->hdr;
                }
              }
            }

            /* QUA becomes the quality component of RES. NOI becomes
               the variance component of RES if present. */
            if( *status == SAI__OK ) {
              if( havenoi ) {
                var_data = (model[whichnoi][i]->sdata[idx]->pntr)[0];
              } else {
                var_data = NULL;
              }

              qua_data = (qua[i]->sdata[idx]->pntr)[0];

              if( exportNDF_which[nmodels] ) {
                if( (res[i]->sdata[idx]->file->name)[0] ) {
                  smf_model_createHdr( res[i]->sdata[idx], SMF__RES, hdr,
                                       status );
                  smf_model_stripsuffix( res[i]->sdata[idx]->file->name,
                                         name, status );

                  /* if memiter=1, need to append "_res" to the name */
                  if( memiter ) {
                    one_strlcat( name, "_res", SMF_PATH_MAX+1, status );
                  }

                  if( !noexportsetbad ) {
                    smf_update_valbad( res[i]->sdata[idx], SMF__NUL,
                                       qua_data, 0, 0, SMF__Q_BADB, status );
                  }

                  smf_write_smfData( res[i]->sdata[idx],
                                     (havenoi && exportNDF_which[whichnoi]) ?
                                     dat.noi[i]->sdata[idx] : NULL,
                                     exportNDF_which[nmodels+1] ?
                                     qua_data : NULL, name, NULL, 0, NDF__NOID,
                                     status );
                } else {
                  msgOut( " ",
                          "SMF__ITERATEMAP: Can't export RES -- NULL filename",
                          status);
                }
              }

              if( exportNDF_which[whichast] ) {

                if( (ast[i]->sdata[idx]->file->name)[0] ) {
                  smf_model_createHdr( ast[i]->sdata[idx], SMF__AST, hdr,
                                       status );
                  smf_model_stripsuffix( ast[i]->sdata[idx]->file->name,
                                         name, status );

                  if( !noexportsetbad ) {
                    smf_update_valbad( ast[i]->sdata[idx], SMF__NUL,
                                       qua_data, 0, 0, SMF__Q_BADB, status );
                  }

                  smf_write_smfData( ast[i]->sdata[idx], NULL, NULL, name,
                                     NULL, 0, NDF__NOID, status );
                } else {
                  msgOut( " ",
                          "SMF__ITERATEMAP: Can't export AST -- NULL filename",
                          status);
                }
              }
            }

            /* Dynamic components excluding NOI/AST */
            for( j=0; j<nmodels; j++ )
              /* Remember to check again whether model[j][i]->sdata[idx] exists
                 for cases like COM */
              if( (*status == SAI__OK) && (modeltyps[j] != SMF__NOI) &&
                  (modeltyps[j] != SMF__AST) && model[j][i]->sdata[idx] &&
                  exportNDF_which[j] ) {
                if( (model[j][i]->sdata[idx]->file->name)[0] ) {
                  smf_model_createHdr( model[j][i]->sdata[idx], modeltyps[j],
                                       hdr,status );
                  smf_model_stripsuffix( model[j][i]->sdata[idx]->file->name,
                                         name, status );

                  if( !noexportsetbad ) {
                    smf_update_valbad( model[j][i]->sdata[idx], modeltyps[j],
                                       qua_data, bstride, tstride, SMF__Q_BADB,
                                       status );
                  }

                  smf_write_smfData( model[j][i]->sdata[idx], NULL, NULL, name,
                                     NULL, 0, NDF__NOID, status );
                } else {
                  msgSetc("MOD",smf_model_getname(modeltyps[j], status) );
                  msgOut( " ",
                          "SMF__ITERATEMAP: Can't export ^MOD: NULL filename",
                          status);
                }
              }

            /* Close the input file containing the header */
            if( !memiter ) {
              smf_close_file( &data, status );
            }
          }

          if( !memiter ) { /* Close files if doing disk i/o */
            smf_close_related( &res[i], status );
            smf_close_related( &qua[i], status );
            smf_close_related( &ast[i], status );

            for( j=0; j<nmodels; j++ ) {
              smf_close_related( &model[j][i], status );
            }
          }
        }

        /*** TIMER ***/
        msgOutiff( MSG__DEBUG, "", FUNC_NAME
                   ": ** %f s Exporting models",
                   status, smf_timerupdate(&tv1,&tv2,status) );

        errEnd( status );
      }
    }

    /* If we get here and there is a SMF__INSMP we probably flagged all
       of the data as bad for some reason. In a multi-chunk map it is
       annoying to have the whole thing die here. So, annul the error,
       warn the user, and then continue on... This will also help us
       to properly free up resources used by this chunk. */

    if( *status == SMF__INSMP ) {
      errAnnul( status );
      msgOut( "", " ************************* Warning! ************************* ", status );
      msgOut( "", " This data chunk failed due to insufficient good samples.",
              status );
      msgOut( "", " This is oftern due to strict bad-bolo flagging.", status );
      msgOut( "", " Annuling the bad status and trying to continue...", status);
      msgOut( "", " ************************************************************ ", status );
    } else {
      /* In the multiple contchunk case, add this map to the total if
         we got here with clean status */
      if( contchunk >= 1 ) {
        msgOut( " ", FUNC_NAME ": Adding map estimated from this continuous"
                " chunk to total", status);
        smf_addmap1( map, weights, hitsmap, mapvar, thismap, thisweight,
                     thishits, thisvar, msize, status );
      }
    }

    /* Cleanup things used specifically in this contchunk */
    if( !memiter && deldimm ) {
      msgOutif(MSG__VERB," ",
               FUNC_NAME ": Cleaning up " SMF__DIMM_SUFFIX " files",
               status);

      /* Delete temporary .DIMM files if requested */
      for( i=0; i<nchunks; i++ ) {               /* Loop over chunk */
        pname = name;

        /* static model components */
        for( j=0; (resgroup)&&(j<resgroup->nrelated); j++ ) {
          grpGet( resgroup->grp, resgroup->subgroups[i][j], 1, &pname,
                  GRP__SZNAM, status );
          if( *status == SAI__OK ) {
            remove(name);
          }
        }

        for( j=0; (lutgroup)&&(j<lutgroup->nrelated); j++ ) {
          grpGet( lutgroup->grp, lutgroup->subgroups[i][j], 1, &pname,
                  GRP__SZNAM, status );
          if( *status == SAI__OK ) {
            remove(name);
          }
        }

        for( j=0; (astgroup)&&(j<astgroup->nrelated); j++ ) {
          grpGet( astgroup->grp, astgroup->subgroups[i][j], 1, &pname,
                  GRP__SZNAM, status );
          if( *status == SAI__OK ) {
            remove(name);
          }
        }

        for( j=0; (quagroup)&&(j<quagroup->nrelated); j++ ) {
          grpGet( quagroup->grp, quagroup->subgroups[i][j], 1, &pname,
                  GRP__SZNAM, status );
          if( *status == SAI__OK ) {
            remove(name);
          }
        }

        /* dynamic model components */
        for( k=0; k<nmodels; k++ ) {
          for( j=0; (modelgroups[k])&&(j<(modelgroups[k])->nrelated); j++ ) {
            grpGet( (modelgroups[k])->grp, (modelgroups[k])->subgroups[i][j],
                    1, &pname, GRP__SZNAM, status );
            if( *status == SAI__OK ) {
              remove(name);
            }
          }
        }
      }
    }

    /* fixed model smfGroups */
    if( resgroup ) smf_close_smfGroup( &resgroup, status );
    if( astgroup ) smf_close_smfGroup( &astgroup, status );
    if( lutgroup ) smf_close_smfGroup( &lutgroup, status );
    if( quagroup ) smf_close_smfGroup( &quagroup, status );

    /* fixed model smfArrays */
    if( res ) {
      for( i=0; i<nchunks; i++ ) {
        if( res[i] ) smf_close_related( &res[i], status );
      }
      res = smf_free( res, status );
    }

    if( ast ) {
      for( i=0; i<nchunks; i++ ) {
        if( ast[i] ) smf_close_related( &ast[i], status );
      }
      ast = smf_free( ast, status );
    }

    if( lut ) {
      for( i=0; i<nchunks; i++ ) {
        if( lut[i] ) smf_close_related( &lut[i], status );
      }
      lut = smf_free( lut, status );
    }

    if( qua ) {
      for( i=0; i<nchunks; i++ ) {
        if( qua[i] ) smf_close_related( &qua[i], status );
      }
      qua = smf_free( qua, status );
    }

    /* dynamic model smfGroups */
    if( modelgroups ) {
      for( i=0; i<nmodels; i++ ) {
        if( modelgroups[i] ) smf_close_smfGroup( &modelgroups[i], status );
      }

      /* Free array of smfGroup pointers at this time chunk */
      modelgroups = smf_free( modelgroups, status );
    }

    /* dynamic model smfArrays */
    if( model ) {
      for( i=0; i<nmodels; i++ ) {
        if( model[i] ) {
          for( j=0; j<nchunks; j++ ) {
            /* Close each model component smfArray at each time chunk */
            if( model[i][j] )
              smf_close_related( &(model[i][j]), status );
          }

          /* Free array of smfArray pointers for this model */
          model[i] = smf_free( model[i], status );
        }
      }
      model = smf_free( model, status );
    }

    /* Free chisquared array */
    if( chisquared) chisquared = smf_free( chisquared, status );
    if( lastchisquared) lastchisquared = smf_free( lastchisquared, status );
  }

  /* The second set of map arrays get freed in the multiple contchunk case */
  if( thismap != map ) thismap = smf_free( thismap, status );
  if( thishits != hitsmap ) thishits = smf_free( thishits, status );
  if( thisvar != mapvar ) thisvar = smf_free( thisvar, status );
  if( thisweight != weights ) thisweight = smf_free( thisweight, status );

  if( modeltyps ) modeltyps = smf_free( modeltyps, status );
  if( exportNDF_which ) exportNDF_which = smf_free( exportNDF_which, status );

  if( igroup ) {
    smf_close_smfGroup( &igroup, status );
  }

  /* Ensure that FFTW doesn't have any used memory kicking around */
  fftw_cleanup();

}
