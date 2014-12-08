/*
*+
*  Name:
*     CALCQU

*  Purpose:
*     Calculate Q and U images from a set of time-series data files.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_calcqu( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This application creates a set of 2-dimensional Q and U images from
*     a set of SCUBA-2 fast-spinning polarimeter time series data files.
*     Each Q or U image is created from a block of time slices over which
*     the sky position of each bolometer does not change significantly (see
*     parameters ARCERROR, MAXSIZE and MINSIZE). The resulting set of Q
*     images can be combined subsequently using KAPPA:WCSMOSAIC, to form a
*     single Q image (normally, the "I" image should be used as the reference
*     image when running WCSMOSIAC). Likewise, the set of U images can be
*     combined in the same way. All the created Q and U images use the focal
*     plane Y axis as the reference direction. Since this direction may vary
*     from block to block due to sky rotation, the idividual Q and U images
*     should be processed using POLPACK:POLROTREF before combining them
*     using KAPPA:WCSMOSAIC, to ensure that they all use the same reference
*     direction.
*
*     The supplied time series data files are first flat-fielded, cleaned
*     and concatenated, before being used to create the Q and U images. The
*     Q and U values are determined from the Fourier component of each time
*     series corresponding to the frequency of the spinning half-waveplate
*     (6 - 12 Hz), and should be largely unaffected by signal at other
*     frequencies. For this reason, the cleaning specified by parameter
*     CONFIG should usually not include any filtering. There is an
*     option (see configuration parameter SUBMEAN) to subtract the mean
*     value from each time slice before using them to calculate Q and U.
*
*     Separate Q, U and I esimates are made for each half revolution of
*     the half-wave plate. The Data values in the returned NDFs are the
*     mean of these estimates. If there are four or more estimates per
*     bolometer, the output will also contain Variance values for each
*     bolometer (these variances represent the error on the final mean
*     value, not the variance of the individual values). A warning
*     message will be displayed if variances cannot be created due to
*     insufficient input data.

*     The current WCS Frame within the generated I, Q and U images will
*     be SKY (e.g. Right Ascension/Declination).

*  ADAM Parameters:
*     ARCERROR = _REAL (Read)
*        The maximum spatial drift allowed within a single Q or U image,
*        in arc-seconds. The default value is wavelength dependant, and
*        is equal to half the default pixel size used by smurf:makemap. []
*     CONFIG = GROUP (Read)
*        Specifies values for various configuration parameters. If the
*        string "def" (case-insensitive) or a null (!) value is supplied,
*        a set of default configuration parameter values will be used.
*
*        The supplied value should be either a comma-separated list of
*        strings or the name of a text file preceded by an up-arrow
*        character "^", containing one or more comma-separated lists of
*        strings. Each string is either a "keyword=value" setting, or
*        the name of a text file preceded by an up-arrow character "^".
*        Such text files should contain further comma-separated lists
*        which will be read and interpreted in the same manner (any blank
*        lines or lines beginning with "#" are ignored). Within a text
*        file, newlines can be used as delimiters, as well as commas.
*        Settings are applied in the order in which they occur within the
*        list, with later settings over-riding any earlier settings given
*        for the same keyword.
*
*        Each individual setting should be of the form:
*
*           <keyword>=<value>
*
*        The available parameters include the cleaning parameters used
*        by the SC2CLEAN and MAKEMAP commands, plus additional parameter
*        related to the calculation of Q and U. Further information
*        about all these parameters is available in the "Configuration
*        Parameters" appendix of SUN/258. Default values will be used for
*        any unspecified parameters. Assigning the value "<def>" (case
*        insensitive) to a keyword has the effect of resetting it to its
*        default value. Parameters not understood will trigger an error.
*        Use the "cleandk." namespace for configuring cleaning parameters
*        for the dark squids. [current value]
*     FIX = _LOGICAL (Read)
*        If TRUE, then attempt to fix up the data to take account of the
*        POL-2 triggering issue that causes extra POL_ANG values to be
*        introduced into JCMTSTATE. [FALSE]
*     FLATUSENEXT = _LOGICAL (Read)
*        If true the previous and following flatfield will be used to
*        determine the overall flatfield to apply to a sequence. If false
*        only the previous flatfield will be used. A null default will
*        use both flatfields for data when we did not heater track
*        at the end, and will use a single flatfield when we did heater
*        track. The parameter value is not sticky and will revert to
*        the default unless explicitly over-ridden. [!]
*     HARMONIC = _INTEGER (Read)
*        The Q and U values are derived from the fourth harmonic of the
*        half-wave plate rotation. However, to allow investigation of
*        other instrumental effects, it is possible instead to derive
*        equivalent quantities from any specified harmonic. These quantities
*        are calculated in exactly the same way as Q and U, but use the
*        harmonic specified by this parameter. They are stored in the
*        output NDFs given by the OUTQ, OUTU and OUTI parameters, in place
*        of the normal Q, U and I values. [4]
*     IN = NDF (Read)
*        Input file(s).
*     MAXSIZE = _INTEGER (Read)
*        The maximum number of time slices to include in any block. No upper
*        limit is imposed on block size if MAXSIZE is zero or negative. [0]
*     MINSIZE = _INTEGER (Read)
*        The minimum number of time slices that can be included in a block
*        No Q or U values are created for blocks that are shorter than
*        this value. No lower limit is imposed on block size if MINSIZE is
*        zero or negative. [200]
*     MSG_FILTER = _CHAR (Read)
*        Control the verbosity of the application. Values can be
*        NONE (no messages), QUIET (minimal messages), NORMAL,
*        VERBOSE, DEBUG or ALL. [NORMAL]
*     OUTI = LITERAL (Write)
*        The name of an output HDS container file containing the I images.
*        The NDFs within this container file are stored and named in the
*        same way as those in the "OUTQ" container file, but using "U"
*        insead of "Q" in the NDF names. No I images are created if a
*        null (!) value is supplied. [!]
*     OUTQ = LITERAL (Write)
*        The name of an output HDS container file containing the Q images.
*        Each image is held in a separate 2D NDF within the container file.
*        The NDF names will be "Q<i>_<s>_<c>", where "<i>" is the
*        integer one-based index of the time slice block from which the
*        image was made, "<s>" is the name of the subarray (e.g. "s4a",
*        etc), and "<c>" is an integer one-based chunk index.
*     OUTU = LITERAL (Write)
*        The name of an output HDS container file containing the U images.
*        The NDFs within this container file are stored and named in the
*        same way as those in the "OUTQ" container file, but using "U"
*        insead of "Q" in the NDF names.
*     RESIST = GROUP (Read)
*        A group expression containing the resistor settings for
*        each bolometer.  Usually specified as a text file using "^"
*        syntax. An example can be found in
*        $STARLINK_DIR/share/smurf/resist.cfg
*        [$STARLINK_DIR/share/smurf/resist.cfg]

*  Authors:
*     David S Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     27-JAN-2011 (DSB):
*        Original version.
*     4-SEP-2012 (DSB):
*        Added FIX parameter.
*     21-SEP-2012 (DSB):
*        Added OUTI parameter.
*     9-OCT-2012 (DSB):
*        Use a single consistent naming scheme for the output NDFs in all
*        situations.
*     8-JAN-2013 (DSB):
*        Added config parameters PASIGN, PAOFF and ANGROT.
*     15-JAN-2013 (DSB):
*        - Added ADAM parameters MAXSIZE and MINSIZE.
*        - Added config parameter SUBMEAN.
*     26-MAR-2013 (DSB):
*        Added ADAM parameter HARMONIC.
*     7-MAY-2013 (DSB):
*        Do not issue warnings about missing darks.
*     16-SEP-2013 (DSB):
*        Do not clean the data if config parameter "doclean" indicates it has
*        already been cleaned.
*     8-DEC-2015 (DSB):
*        Report fraction of data rejected due to short blocks.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2011-2013 Science and Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston,
*     MA 02110-1301, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <stdio.h>

/* Starlink includes */
#include "mers.h"
#include "msg_par.h"
#include "ndf.h"
#include "par.h"
#include "par_err.h"
#include "ast.h"
#include "sae_par.h"
#include "star/grp.h"
#include "star/ndg.h"
#include "star/atl.h"
#include "star/hdspar.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"
#include "smurf_par.h"
#include "smurflib.h"

void smurf_calcqu( int *status ) {

/* Local Variables: */
   AstFitsChan *fc;           /* Holds FITS headers for output NDFs */
   AstKeyMap *config;         /* Holds all cleaning parameters */
   AstKeyMap *dkpars;         /* Holds dark squid cleaning parameters */
   AstKeyMap *heateffmap = NULL; /* Heater efficiency data */
   AstKeyMap *sub_instruments;/* Indicates which instrument is being used */
   Grp *bgrp = NULL;          /* Group of base names for each chunk */
   Grp *igrp = NULL;          /* Group of input files */
   Grp *ogrp = NULL;          /* Group of output files  */
   Grp *sgrp = NULL;          /* Group of science files */
   HDSLoc *loci = NULL;       /* Locator for output I container file */
   HDSLoc *locq = NULL;       /* Locator for output Q container file */
   HDSLoc *locu = NULL;       /* Locator for output U container file */
   NdgProvenance *oprov;      /* Provenance to store in each output NDF */
   ThrWorkForce *wf;          /* Pointer to a pool of worker threads */
   char headval[ 81 ];        /* FITS header value */
   char ndfname[ 30 ];        /* Name of output Q or U NDF */
   char polcrd[ 81 ];         /* FITS 'POL_CRD' header value */
   char subarray[ 10 ];       /* Subarray name (e.g. "s4a", etc) */
   double angrot;             /* Angle from focal plane X axis to fixed analyser */
   double paoff;              /* WPLATE value corresponding to POL_ANG=0.0 */
   float arcerror;            /* Max acceptable error (arcsec) in one block */
   int block_end;             /* Index of last time slice in block */
   int block_start;           /* Index of first time slice in block */
   int dkclean;               /* Clean dark squids? */
   int doclean;               /* Clean science data? */
   int fix;                   /* Fix the POL-2 triggering issue? */
   int harmonic;              /* The requested harmonic */
   int iblock;                /* Index of current block */
   int iplace;                /* NDF placeholder for current block's I image */
   int ipolcrd;               /* Reference direction for waveplate angles */
   int maxsize;               /* Max no. of time slices in a block */
   int minsize;               /* Min no. of time slices in a block */
   int nc;                    /* Number of characters written to a string */
   int nskipped;              /* Number of skipped blocks */
   int pasign;                /* +1 or -1 indicating sense of POL_ANG value */
   int qplace;                /* NDF placeholder for current block's Q image */
   int skipped;               /* Number of skipped samples */
   int submean;               /* Subtract mean value from each time slice? */
   int total;                 /* Total number of time salices in sub-array */
   int uplace;                /* NDF placeholder for current block's U image */
   size_t ichunk;             /* Continuous chunk counter */
   size_t idx;                /* Subarray counter */
   size_t igroup;             /* Index for group of related input NDFs */
   size_t inidx;              /* Index into group of science input NDFs */
   size_t nchunk;             /* Number continuous chunks outside iter loop */
   size_t ssize;              /* Number of science files in input group */
   smfArray *concat = NULL;   /* Pointer to smfArray holding bolometer data */
   smfArray *dkarray = NULL;  /* Pointer to smfArray holding dark squid data */
   smfArray *flatramps = NULL;/* Flatfield ramps */
   smfData *data = NULL;      /* Concatenated data for one subarray */
   smfData *dkdata = NULL;    /* Concatenated dark squid data for one subarray */
   smfGroup *sgroup = NULL;   /* smfGroup corresponding to sgrp */

/* Check inhereited status */
   if( *status != SAI__OK ) return;

/* Start new AST and NDF contexts. */
   astBegin;
   ndfBegin();

/* Find the number of cores/processors available and create a work force
   holding the same number of threads. */
   wf = thrGetWorkforce( thrGetNThread( SMF__THREADS, status ), status );

/* Get a group of input files */
   kpg1Rgndf( "IN", 0, 1, "  Give more NDFs...", &igrp, &ssize, status );

/* Get a group containing just the files holding science data. */
   smf_find_science( wf, igrp, &sgrp, 0, NULL, NULL, 1, 1, SMF__NULL, NULL,
                     &flatramps, &heateffmap, NULL, status );

/* Check we have at least once science file. */
   ssize = grpGrpsz( sgrp, status );
   if( ssize == 0 ) {
      msgOutif( MSG__NORM, " ", "All supplied input frames were DARK.",
                status );
   } else {

/* See if a correction should be made for the POL2 triggering issue. */
      parGet0l( "FIX", &fix, status );

/* See what harmonic is to bused. */
      parGet0i( "HARMONIC", &harmonic, status );

/* Create HDS container files to hold the output NDFs. */
      datCreat( "OUTQ", "CALCQU", 0, 0, status );
      datCreat( "OUTU", "CALCQU", 0, 0, status );

/* Associate the locators with the structures. */
      datAssoc( "OUTQ", "WRITE", &locq, status );
      datAssoc( "OUTU", "WRITE", &locu, status );

/* The I images are optional. */
      if( *status == SAI__OK ) {
         datCreat( "OUTI", "CALCQU", 0, 0, status );
         datAssoc( "OUTI", "WRITE", &loci, status );
         if( *status == PAR__NULL ) {
            errAnnul( status );
            loci = NULL;
         }
      }

/* Group the input files so that all files within a single group have the
   same wavelength and belong to the same subscan of the same observation.
   Also identify chunks of data that are contiguous in time, and
   determine to which such chunk each group belongs. All this information
   is returned in a smfGroup structure ("*sgroup"). */
      smf_grp_related( sgrp, ssize, 1, 1, 0, NULL, NULL, NULL,
                       NULL, &sgroup, &bgrp, NULL, status );

/* Obtain the number of contiguous chunks. */
      if( *status == SAI__OK ) {
         nchunk = sgroup->chunk[ sgroup->ngroups - 1 ] + 1;
      } else {
         nchunk = 0;
      }

/* Indicate we have not yet found a value for the ARCERROR parameter. */
      arcerror = 0.0;

/* Loop over all contiguous chunks */
      for( ichunk = 0; ichunk < nchunk && *status == SAI__OK; ichunk++ ) {

/* Display the chunk number. */
            if( nchunk > 1 ) {
               msgOutiff( MSG__VERB, "", "   Doing chunk %d of %d.",
                          status, (int) ichunk + 1, (int) nchunk );
            }

/* Concatenate the data within this contiguous chunk. This produces a
   smfArray ("concat") containing a smfData for each subarray present in
   the chunk. Each smfData holds the concatenated data for a single
   subarray. */
         smf_concat_smfGroup( wf, NULL, sgroup, NULL, NULL, flatramps,
                              heateffmap, ichunk, 1, 1, NULL, 0, NULL, NULL,
                              NO_FTS, 0, 0, 0, &concat, NULL, status );

/* Get a KeyMap holding values for the configuration parameters. Since we
   sorted by wavelength when calling smf_grp_related, we know that all
   smfDatas in the current smfArray (i.e. chunk) will relate to the same
   wavelength. Therefore we can use the same parameters for all smfDatas in
   the current smfArray. */
         sub_instruments = smf_subinst_keymap( SMF__SUBINST_NONE,
                                               concat->sdata[ 0 ], NULL,
                                               0, status );
         config = kpg1Config( "CONFIG", "$SMURF_DIR/smurf_calcqu.def",
                               sub_instruments, 1, status );
         sub_instruments = astAnnul( sub_instruments );


/* Get the CALCQU specific parameters. */
         if( !astMapGet0I( config, "PASIGN", &pasign ) ) pasign = 1;
         msgOutiff( MSG__VERB, "", "PASIGN=%d", status, pasign );
         if( !astMapGet0D( config, "PAOFF", &paoff ) ) paoff = 0.0;
         msgOutiff( MSG__VERB, "", "PAOFF=%g", status, paoff );
         if( !astMapGet0D( config, "ANGROT", &angrot ) ) angrot = 90.0;
         msgOutiff( MSG__VERB, "", "ANGROT=%g", status, angrot );
         if( !astMapGet0I( config, "SUBMEAN", &submean ) ) submean = 0;
         msgOutiff( MSG__VERB, "", "SUBMEAN=%d", status, submean );
         if( !astMapGet0I( config, "DOCLEAN", &doclean ) ) doclean = 0;
         msgOutiff( MSG__VERB, "", "DOCLEAN=%d", status, doclean );

/* See if the dark squids should be cleaned. */
         if( !astMapGet0I( config, "DKCLEAN", &dkclean ) ) dkclean = 0;

/* If required, clean the dark squids now since we might need to use them to
   clean the bolometer data. */
         if( dkclean ) {

/* Create a smfArray containing the dark squid data. For each one, store
   a pointer to the main header so that smf_clean_smfArray can get at the
   JCMTState information. */
            dkarray = smf_create_smfArray( status );
            for( idx = 0; idx < concat->ndat && *status == SAI__OK; idx++ ) {
               data = concat->sdata[ idx ];
               if( data && data->da && data->da->dksquid ) {
                  dkdata = data->da->dksquid;
                  dkdata->hdr = data->hdr;
                  smf_addto_smfArray( dkarray, dkdata, status );
               }
            }

/* Clean the smfArray containing the dark squid data. Use the "CLEANDK.*"
   parameters. */
            (void) astMapGet0A( config, "CLEANDK", &dkpars );
            smf_clean_smfArray( wf, dkarray, NULL, NULL, NULL, dkpars, status );
            dkpars = astAnnul( dkpars );

/* Nullify the header pointers so that we don't accidentally close any. */
            if( dkarray ) {
               for( idx = 0; idx < dkarray->ndat; idx++ ) {
                  dkdata = dkarray->sdata[ idx ];
                  dkdata->hdr = NULL;
               }

/* Free the smfArray holding the dark squid data, but do not free the
   individual smfDatas within it. */
               dkarray->owndata = 0;
               smf_close_related( wf, &dkarray, status );
            }
         }

/* Now clean the bolometer data */
         if( doclean ) smf_clean_smfArray( wf, concat, NULL, NULL, NULL, config, status );

/* If required correct for the POL2 triggering issue. */
         if( fix ) smf_fix_pol2( wf, concat, status );

/* Loop round each sub-array in the current contiguous chunk of data. */
         for( idx = 0; idx < concat->ndat && *status == SAI__OK; idx++ ) {
            data = concat->sdata[ idx ];

/* Find the name of the subarray that generated the data. */
            smf_find_subarray( data->hdr, subarray, sizeof(subarray), NULL,
                               status );

/* Display the sub-array. */
            if( concat->ndat > 1 ) {
               msgOutiff( MSG__VERB, "", "   Doing sub-array %s.",
                          status, subarray );
            }

/* Create an empty provenance structure. Each input NDF that contributes
   to the current chunk and array will be added as an ancestor to this
   structure, which will later be stored in each output NDF created for
   this chunk and array. */
            oprov = ndgReadProv( NDF__NOID, "SMURF:CALCQU", status );

/* Indicate we do not yet have any FITS headers for the output NDFs */
            fc = NULL;

/* Indicate we do not yet know the coordinate reference frame for the
   half-waveplate angle. */
            polcrd[ 0 ] = 0;
            ipolcrd = 0;

/* Go through the smfGroup looking for groups of related input NDFs that
   contribute to the current chunk. */
            for( igroup = 0; igroup < sgroup->ngroups; igroup++ ) {
               if( sgroup->chunk[ igroup ] == ichunk ) {

/* Get the integer index into the GRP group (sgrp) that holds the input NDFs.
   This index identifies the input NDF that provides the data for the current
   chunk and subarray. This assumes that the order in which smf_concat_smfGroup
   stores arrays in the "concat" smfArray matches the order in which
   smf_grp_related stores arrays within the sgroup->subgroups. */
                  inidx = sgroup->subgroups[ igroup ][ idx ];

/* Add this input NDF as an ancestor into the output provenance structure. */
                  smf_accumulate_prov( NULL, sgrp, inidx, NDF__NOID,
                                       "SMURF:CALCQU", &oprov, status );

/* Merge the FITS headers from the current input NDF into the FitsChan
   that holds headers for the output NDFs. The merging retains only those
   headers which have the same value in all input NDFs. */
                  smf_fits_outhdr( data->hdr->fitshdr, &fc, status );

/* Get the polarimetry related FITS headers and check that all input NDFs
   have usabie values. */
                  headval[ 0 ] = 0;
                  smf_getfitss( data->hdr, "POL_MODE", headval,
                                sizeof(headval), status );
                  if( strcmp( headval, "CONSTANT" ) && *status == SAI__OK ) {
                     *status = SAI__ERROR;
                     grpMsg( "N", sgrp, inidx );
                     errRep( " ", "Input NDF ^N does not contain "
                             "polarimetry data obtained with a spinning "
                             "half-waveplate.", status );
                  }

                  headval[ 0 ] = 0;
                  smf_getfitss( data->hdr, "POLWAVIN", headval,
                                sizeof(headval), status );
                  if( strcmp( headval, "Y" ) && *status == SAI__OK ) {
                     *status = SAI__ERROR;
                     grpMsg( "N", sgrp, inidx );
                     errRep( " ", "Half-waveplate was not in the beam for "
                             "input NDF ^N.", status );
                  }

                  headval[ 0 ] = 0;
                  smf_getfitss( data->hdr, "POLANLIN", headval,
                                sizeof(headval), status );
                  if( strcmp( headval, "Y" ) && *status == SAI__OK ) {
                     *status = SAI__ERROR;
                     grpMsg( "N", sgrp, inidx );
                     errRep( " ", "Analyser was not in the beam for input "
                             "NDF ^N.", status );
                  }

                  if( polcrd[ 0 ] ) {
                     headval[ 0 ] = 0;
                     smf_getfitss( data->hdr, "POL_CRD", headval,
                                   sizeof(headval), status );
                     if( strcmp( headval, polcrd ) && *status == SAI__OK ) {
                        *status = SAI__ERROR;
                        errRep( " ", "Input NDFs have differing values for "
                                "FITS header 'POL_CRD'.", status );
                     }

                  } else {
                     smf_getfitss( data->hdr, "POL_CRD", polcrd,
                                   sizeof(polcrd), status );
                     if( !strcmp( polcrd, "FPLANE" ) ) {
                        ipolcrd = 0;
                     } else if( !strcmp( polcrd, "AZEL" ) ) {
                        ipolcrd = 1;
                     } else if( !strcmp( polcrd, "TRACKING" ) ) {
                        ipolcrd = 2;
                     } else if( *status == SAI__OK ) {
                        *status = SAI__ERROR;
                        msgSetc( "N", data->file->name );
                        msgSetc( "V", polcrd );
                        errRep( " ", "Input NDF ^N contains unknown value "
                                "'^V' for FITS header 'POL_CRD'.", status );
                     }
                  }
               }
            }

/* If not already done, get the maximum spatial drift (in arc-seconds) that
   can be tolerated whilst creating a single I/Q/U image. The default value is
   half the makemap default pixel size. Also get limits on the number of
   time slices in any block. */
            if( arcerror == 0.0 ) {
               parDef0d( "ARCERROR", 0.5*smf_calc_telres( data->hdr->fitshdr,
                                                          status ), status );
               parGet0r( "ARCERROR", &arcerror, status );

               parGet0i( "MAXSIZE", &maxsize, status );
               parGet0i( "MINSIZE", &minsize, status );
               if( maxsize > 0 && maxsize < minsize && *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  errRepf( "", "Value of parameter MAXSIZE (%d) is less "
                           "than value of parameter MINSIZE (%d)", status,
                           maxsize, minsize );
               }
            }

/* The algorithm that calculates I, Q and U assumes that all samples for a
   single bolometer measure flux from the same point on the sky. Due to
   sky rotation, this will not be the case - each bolometer will drift
   slowly across the sky. However, since the drift is (or should be)
   slow we can apply the I/Q/U algorithm to blocks of contiguous data over
   which the bolometers do not move significantly. We produce a separate
   I, Q and U image for each such block. The first block starts at the first
   time slice in the smfData. */
            block_start = 0;
            skipped = 0;
            nskipped = 0;
            total = 0;

/* Find the time slice at which the corner bolometers have moved
   a critical distance (given by parameter ARCERROR) from their
   positions at the start of the block. Then back off some time slices
   to ensure that the block holds an integral number of half-waveplate
   rotations. */
            block_end = smf_block_end( data, block_start, ipolcrd, arcerror,
                                       maxsize, status );

/* Loop round creating I/Q/U images for each block. Count them. */
            iblock = 0;
            while( block_end >= 0 && *status == SAI__OK ) {
               total += block_end - block_start + 1;

/* Skip very short blocks. */
               if( block_end - block_start > minsize ) {

/* Display the start and end of the block. */
                  msgOutiff( MSG__VERB, "", "   Doing time slice block %d "
                             "-> %d", status, (int) block_start,
                             (int) block_end );

/* Get the name for the Q NDF for this block. Start of with "Q" followed by
   the block index. */
                  iblock++;
                  nc = sprintf( ndfname, "Q%d", iblock );

/* Append the subarray name to the NDF name. */
                  nc += sprintf( ndfname + nc, "_%s", subarray );

/* Append the chunk index to the NDF name. */
                  nc += sprintf( ndfname + nc, "_%d", (int) ichunk );

/* Get NDF placeholder for the Q NDF. The NDFs are created inside the
   output container file. */
                  ndfPlace( locq, ndfname, &qplace, status );

/* The name of the U NDF is the same except the initial "Q" is changed to
   "U". */
                  ndfname[ 0 ] = 'U';
                  ndfPlace( locu, ndfname, &uplace, status );

/* The name of the I NDF is the same except the initial "Q" is changed to
   "I". */
                  if( loci ) {
                     ndfname[ 0 ] = 'I';
                     ndfPlace( loci, ndfname, &iplace, status );
                  } else {
                     iplace = NDF__NOPL;
                  }

/* Store the chunk and block numbers as FITS headers. */
                  atlPtfti( fc, "POLCHUNK", (int) ichunk, "Chunk index used by CALCQU", status );
                  atlPtfti( fc, "POLBLOCK", iblock, "Block index used by CALCQU", status );

/* Create the Q and U images for the current block of time slices from
   the subarray given by "idx", storing them in the output container
   file. */
                  smf_calc_iqu( wf, data, block_start, block_end, ipolcrd,
                                qplace, uplace, iplace, oprov, fc,
                                pasign, AST__DD2R*paoff, AST__DD2R*angrot,
                                submean, harmonic, status );

/* Warn about short blocks. */
               } else {
                  int blength = block_end - block_start - 1;
                  skipped += blength;
                  nskipped++;
                  msgOutiff( MSG__VERB, "", "   Skipping short block of %d "
                             "time slices (parameter MINSIZE=%d).", status,
                             blength, minsize );
               }

/* The next block starts at the first time slice following the previous
   block. */
               block_start = block_end + 1;

/* Find the time slice at which the corner bolometers have moved
   a critical distance (given by parameter ARCERROR) from their
   positions at the start of the block. Then back off some time slices
   to ensure that the block holds an integral number of half-waveplate
   rotations. This returns -1 if all time slices have been used. */
               block_end = smf_block_end( data, block_start, ipolcrd,
                                          arcerror, maxsize, status );
            }

/* Free resources */
            oprov = ndgFreeProv( oprov, status );
            fc = astAnnul( fc );

/* Report the fraction of the data that was skipped due to being in a
   short block. Only do this for the first sub-array as all sub-arrays will
   be the same. */
            double perc = 100.0 * (double) skipped / (double) total;
            if( idx == 0 && perc > 5.0 ) {
               msgOutf( "", "Warning: %g %% of the data from chunk %zu was "
                        "skipped because the telescope was moving too "
                        "fast. Reduce the MINSIZE parameter from its "
                        "current value of %d samples?", status, perc,
                        ichunk, minsize );

               int mlength = (double) skipped / nskipped;
               msgOutf( "", "The mean length of the skipped blocks was %d "
                        "samples.", status, mlength );
            }
         }
         config = astAnnul( config );

/* Close the smfArray. */
         smf_close_related( wf, &concat, status );
      }

/* Annul the locators for the output container files. */
      datAnnul( &locq, status );
      datAnnul( &locu, status );
      if( loci ) datAnnul( &loci, status );

/* The parameter system hangs onto a primary locator for each container
   file, so cancel the parameters to annul these locators. */
      datCancl( "OUTQ", status );
      datCancl( "OUTU", status );
      datCancl( "OUTI", status );
   }

/* Free resources. */
   smf_close_related( wf, &flatramps, status );

   if( igrp ) grpDelet( &igrp, status);
   if( sgrp ) grpDelet( &sgrp, status);
   if( bgrp ) grpDelet( &bgrp, status );
   if( ogrp ) grpDelet( &ogrp, status );
   if( sgroup ) smf_close_smfGroup( &sgroup, status );
   if (heateffmap) heateffmap = smf_free_effmap( heateffmap, status );

/* End the NDF and AST contexts. */
   ndfEnd( status );
   astEnd;

/* Issue a status indication.*/
   if( *status == SAI__OK ) {
     msgOutif( MSG__VERB, " ", "CALCQU succeeded.", status);
   } else {
     msgOutif( MSG__VERB, " ", "CALCQU failed.", status);
   }
}
