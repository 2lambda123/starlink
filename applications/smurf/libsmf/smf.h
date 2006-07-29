/*
*+
*  Name:
*     smf.h

*  Purpose:
*     Prototypes for the libsmf library

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Header File

*  Invocation:
*     #include "smf.h"

*  Description:
*     Prototypes used by the libsmf functions.

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (JAC, Hawaii)
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2005-09-27 (AGG):
*        Initial test version
*     2005-11-04 (AGG):
*        Add smf_open_file, smf_fits_rdhead and smf_fits_crchan
*     2005-11-07 (TIMJ):
*        Alphabetize.
*        Add smf_tslice_ast, add smf_fits_getI
*     2005-11-28 (TIMJ):
*        Add smf_close_file
*     2005-12-05 (AGG)
*        Add smf_flatfield and smf_check_flat
*     2005-12-06 (AGG)
*        Add smf_flatten
*     2005-12-09 (AGG)
*        Add smf_clone_data
*     2006-01-09 (AGG)
*        Add smf_tslice and smf_insert_tslice
*     2006-01-10 (AGG)
*        Add smf_scale_tau and smf_fits_getF
*     2006-01-24 (TIMJ):
*        Add smf_fits_getS
*     2006-01-24 (AGG):
*        Change floats to doubles in smf_correction_extintion, smf_scale_tau
*     2006-01-25 (AGG):
*        Add smf_dtype_check_fatal
*     2006-01-25 (TIMJ):
*        Add smf_malloc, smf_free.
*        Remove smf_fits_rdhead
*     2006-01-25 (TIMJ):
*        Add smf_create_*
*        Add smf_construct_*
*        Add smf_dtype_tostring
*     2006-01-27 (TIMJ):
*        Change API for smf_construct_smfFile, smf_construct_smfDA
*        and smf_construct_smfHead.
*     2006-02-02 (EC):
*        Add smf_mapbounds
*        Add smf_rebinmap
*     2006-02-03 (AGG):
*        Change API for smf_scale_tau, smf_correct_extinction
*     2006-02-17 (AGG):
*        Add smf_subtract_poly
*     2006-02-24 (AGG):
*        Add smf_subtract_plane
*     2006-03-23 (AGG):
*        Update API for smf_rebinmap, smf_construct_smfData, smf_construct_smfHead
*        Add smf_mapbounds approx, smf_deepcopy_smfHead & smf_deepcopy_smfData
*     2006-03-28 (AGG):
*        Update API for smf_deepcopy_smfData, add smf_deepcopy_smfDA
*     2006-03-30 (AGG):
*        Add smf_deepcopy_smfFile
*     2006-04-05 (AGG):
*        - Change API for smf_deepcopy_smfDA to accept a smfData
*          rather than smfDA
*        - Add smf_check_smfData, smf_check_smfDA, smf_check_smfFile and
*          smf_check_smfHead
*     2006-04-21 (AGG):
*        - Change API for smf_check_smfData, smf_deepcopy_smfData
*        - Add history to smf_construct_smfData
*        - Add smf_history_add, smf_history_read
*     2006-05-01 (EC):
*        - Add smf_mapcoordinates
*     2006-05-09 (AGG):
*        Add smf_get_xloc and smf_get_ndfid
*     2006-05-09 (EC):
*        Renamed smf_mapcoord to smf_calc_mapcoord
*     2006-07-07 (AGG):
*        Add smf_grp_related, smf_construct_smfGroup,
*        smf_open_related, smf_close_related and smf_close_smfGroup
*     2006-07-11 (EC):
*        Add smf_model_create, smf_model_getnames
*     2006-07-26 (TIMJ):
*        Replace sc2head with JCMTState.
*     2006-07-28 (TIMJ):
*        Add tswcs argument to smf_construct_smfHead
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
*     University of British Columbia.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#ifndef SMF_DEFINED
#define SMF_DEFINED

#include "ast.h"
#include "smurf_typ.h"
#include "star/grp.h"
#include "smf_typ.h"

void smf_addto_smfArray( smfArray *ary, const smfData *data, int *status );

void smf_boxcar1 ( double *series, const int ninpts, int window, int *status);

void smf_calc_stats( const smfData *data, const char *mode, const int index,
                     int lo, int hi, double *mean, double *sigma, 
		     int *status);

double smf_calc_covar ( const smfData *data, const int i, const int j,
			int lo, int hi, int *status);

void smf_calc_mapcoord( smfData *data, AstFrameSet *outfset, int *lbnd_out,
                        int *ubnd_out, int *status );

double smf_calc_wvm( const smfHead *hdr, int *status );

void smf_check_flat ( const smfData *data, int *status );

void smf_check_smfData ( const smfData *idata, smfData *odata, const int flags,
			 int *status );

void smf_check_smfDA ( const smfData *idata, smfData *odata, int *status );

void smf_check_smfFile ( const smfData *idata, smfData *odata, int *status );

void smf_check_smfHead ( const smfData *idata, smfData *odata, int *status );

void smf_clone_data ( const smfData *idata, smfData **odata, int *status );

void smf_close_file( smfData **, int *status);

void smf_close_mapcoord( smfData *data, int *status );

void smf_close_related( smfArray **relfiles, int *status );

void smf_close_smfGroup( smfGroup **group, int *status );

void smf_correct_extinction( smfData *data, const char *method, 
			     const int quick, double tau, int *status);

smfData *
smf_construct_smfData( smfData * tofill, smfFile * file, smfHead * hdr, 
		       smfDA * da, smf_dtype dtype, void * pntr[3], 
		       const dim_t dims[], int ndims,
		       int virtual, int ncoeff, double *poly, 
		       AstKeyMap *history, int * status );
smfDA *
smf_construct_smfDA( smfDA * tofill, double * flatcal,
		     double * flatpar, const char * flatname, int nflat,
		     int * status );
smfFile *
smf_construct_smfFile(smfFile * tofill, int ndfid, int isSc2store,
		      int isTstream, const char * name,
		      int * status );
smfHead *
smf_construct_smfHead( smfHead * tofill,
		       AstFrameSet * wcs, AstFrameSet * tswcs,
                       AstFitsChan * fitshdr,
		       JCMTState * allState,
		       dim_t curframe, dim_t nframes, int * status );

smfGroup * 
smf_construct_smfGroup( Grp *igrp, int **subgroups, const int ngroups, 
			const int nrelated, int *status );

smfArray *smf_create_smfArray( const size_t size, int *status );

smfData* smf_create_smfData( int flags, int * status );

smfFile* smf_create_smfFile( int * status );

smfHead* smf_create_smfHead( int * status );

smfDA*   smf_create_smfDA( int * status );

smfHead * smf_deepcopy_smfHead ( const smfHead *old, int * status);

smfData * smf_deepcopy_smfData ( const smfData *old, const int rawconvert, 
				 const int flags, int * status);

smfDA * smf_deepcopy_smfDA ( const smfData *old, int * status);

smfFile * smf_deepcopy_smfFile ( const smfFile *old, int * status );

int smf_dtype_check( const smfData* data, const char * type, smf_dtype itype,
		     int *status );

void smf_dtype_check_fatal( const smfData* data, const char * type, 
                            smf_dtype itype, int *status );

smf_dtype smf_dtype_fromstring( const char * dtype, int * status );

char *smf_dtype_string( const smfData* data, int * status );

size_t smf_dtype_size( const smfData* data, int * status );

void smf_fit_poly(const smfData *data, const int order, double *poly,  
                  int *status);

void smf_fits_crchan( int nfits, char * headrec, AstFitsChan ** fits, 
                      int *status);

/* Do not return result since we want the interface to remain the same when a
   string is required. If we return a string we must know who should free it */
void smf_fits_getI( const smfHead * hdr, const char * cardname, int * result, 
		    int * status );
void smf_fits_getD( const smfHead * hdr, const char * cardname, 
                    double * result, int * status );
void smf_fits_getF( const smfHead * hdr, const char * cardname, 
                    float * result, int * status );
void smf_fits_getS( const smfHead * hdr, const char * cardname, 
                    char result[70], size_t len, int * status );

void smf_flatfield ( const smfData *idata, smfData **odata, const int flags, 
                     int *status );

void smf_flatten ( smfData *data, int *status );

void smf_free( void * pntr, int * status );

int smf_get_ndfid ( const HDSLoc *loc, const char *name, const char *accmode, 
		    const char *state, const char *dattype, const int ndims, 
		    const int *lbnd, const int *ubnd, int *status );

HDSLoc *smf_get_xloc ( const smfData *data, const char *extname, 
			const char *extype, const char *accmode, 
			const int ndims, const int *dims, int *status );

void smf_grp_related( Grp *igrp, const int grpsize, const int grpbywave, 
		      smfGroup **group, int *status );

void smf_history_add( smfData* data, const char * appl, 
			const char * text, int *status);

int smf_history_check( const smfData* data, const char * appl, int *status);

void smf_history_read( smfData* data, int *status);

void smf_history_write( const smfData* data, const char * appl, 
			const char * text, int *status);

void smf_insert_tslice ( smfData **idata, smfData *tdata, int index, 
                         int *status );

void smf_iteratemap( Grp *igrp, AstKeyMap *keymap,
 		     double *map, double *variance, double *weights,
	 	     int msize, int *status );

void * smf_malloc( size_t nelem, size_t bytes_per_elem, int zero, 
                   int * status );

void smf_mapbounds( Grp *igrp,  int size, char *system, double lon_0, 
		    double lat_0, int flag, double pixsize, int *lbnd_out, 
		    int *ubnd_out, AstFrameSet **outframeset, int *status );

void smf_mapbounds_approx( Grp *igrp,  int size, char *system, double lon_0, 
		    double lat_0, int flag, double pixsize, int *lbnd_out, 
		    int *ubnd_out, AstFrameSet **outframeset, int *status );

void smf_model_create( Grp *igrp, smf_modeltype mtype, Grp **mgrp, 
		       int *status);

void smf_model_getname( smf_modeltype type, const char *name, int *status);

void smf_open_and_flatfield ( Grp *igrp, Grp *ogrp, int index, 
			      smfData **ffdata, int *status);

void smf_open_file( Grp * igrp, int index, char * mode, int withHdr,
		    smfData ** data, int *status);

void smf_open_mapcoord( smfData *data, int *status );

void smf_open_newfile( Grp * igrp, int index, smf_dtype dtype, const int ndims, 
		       const dim_t dims[], int flags, smfData ** data, 
		       int *status);

void smf_open_related( const smfGroup *group, const int subindex, smfArray **relfiles, 
		       int *status );

void smf_rebinmap( smfData *data, int index, int size, 
                   AstFrameSet *outframeset, int *lbnd_out, int *ubnd_out,
                   double *map, double *variance,
		   double *weights, int *status );

double smf_scale_tau ( const double tauwvm, const char *filter, int *status);

void smf_scanfit( smfData *data, int order, int *status );

void smf_simplerebinmap( double *data, double *variance, int *lut, int dsize, 
			 int flags, double *map, double *mapweight, 
			 double *mapvar, int msize, int *status );

void smf_subtract_plane( smfData *data, const char *fittype, int *status);

void smf_subtract_poly( smfData *data, int *status );

void smf_tslice ( const smfData *idata, smfData **tdata, int index, 
                  int *status );

void smf_tslice_ast (smfData * data, int index, int needwcs, int * status );

#endif /* SMF_DEFINED */
