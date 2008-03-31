/*
*+
*  Name:
*     TIMESORT

*  Purpose:
*     Re-order the time slices in a raw data cube into increasing time.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_timesort( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine accepts as input one or more raw data cubes, spanned
*     by (frequency, detector number, time) axes. It sorts the time slices 
*     into monotonically increasing time value and writes the resulting 
*     data to a one or more new output NDFs. The ACSIS and JCMTSTATE 
*     extensions and the WCS component are modified along with the main
*     Data array, so that the resulting cube remains internally consistent.
*
*     The main reason for using this routine is to ensure that data has a
*     defined transformation from WCS coordinates to pixel coordinates.
*
*     There are two main modes, selected by parameter MERGE. If MERGE 
*     is FALSE, then the time slices in each input NDF are sorted
*     independently of the other NDFs, and each output NDF contains 
*     data only from the corresponding input NDF. If MERGE is TRUE, then 
*     the input NDFs are sorted into groups that contain NDFs from the same 
*     observation and sub-system (that is, all NDFs in a group have the
*     same value for the OBSIDSS FITS keyword). For each group, the time 
*     slices in all NDFs in the group are sorted into a single list. This 
*     list is then divided up into chunks (in a manner selected by parameter 
*     SIZELIMIT), and the time slices are written out sequentially to a 
*     number of output NDFs. If any time slice is present in more than one 
*     input NDF, then the data values for the two or more input time slices 
*     are merged into a single time slice.
*
*     MERGE = TRUE should be used to sort the time slices contained in a
*     set of sub-scans from a sub-system.

*  ADAM Parameters:
*     IN = NDF (Read)
*          A group of input NDFs, each holding raw time series data.
*     LIMITTYPE = LITERAL (Read)
*          Only accessed if parameter MERGE is set TRUE and a positive
*          value is supplied for SIZELIMIT. Specifies the units of the 
*          SIZELIMIT value. It must be one of:
*
*          - "SPECTRA": SIZELIMIT is the maximum number of spectra in each 
*          output NDF.
*          - "SLICES": SIZELIMIT is the maximum number of time slices in 
*          each output NDF.
*          - "FILESIZE": SIZELIMIT is the maximum number of megabytes of 
*          data in each output NDF.
*
*          Note, when using the FILESIZE option the specified file size
*          only includes the size of the Data and Variance components in
*          the NDF. Consequently, the actual file size may be a little
*          larger than the requested size because of the extra
*          information held in NDF extensions. ["FILESIZE"]
*     MERGE = _LOGICAL (Read)
*          If FALSE, then each input NDF is sorted independently of the
*          other input NDFs, and the sorted data for each input NDF is 
*          written to a separate output NDF. If TRUE, then the input NDFs 
*          are divided up into groups relating to different observations. 
*          Each such group is then further sub-divided up into groups
*          relating to sub-systems within the observation. Each group
*          then holds sub-scans from a single observation and sub-system.
*          All the time slices from every NDF in each such group are read 
*          into a single list, which is then sorted. The sorted data can 
*          be written out to a single large output file (one for each
*          observation sub-system), or can be split up into several 
*          smaller output files, as specified by the SIZELIMIT parameter. 
*          The dynamic default for this parameter is TRUE if two or more 
*          of the input NDFs refer to the same observation and sub-system
*          number, and FALSE otherwise. []
*     NOUT = _INTEGER (Write)
*          An output parameter in which is stored the total number of output 
*          NDFs created.
*     OUT = NDF (Write)
*          A group of output NDFs. If parameter MERGE is FALSE, then a
*          separate output NDF is created for each input NDF and so the
*          size of the supplied group should equal the number of input NDF.
*          If parameter MERGE is TRUE, then the number of output NDFs is
*          determined by the SIZELIMIT parameter. In this case, the number
*          of values in the supplied group should equal the number of
*          sub-systems represented in the input data. If a GRP modification 
*          element is used to specify the names, then the specified
*          modifiation will be applied to a set of names containing the
*          first input NDF for each sub-system. If all the input file
*          names conform to the usual naming convention of ACSIS raw time 
*          series files ("ayyyymmdd_nnnnn_nn_nnnn" with an optional arbitrary 
*          trailing suffix that must begin with an underscore) then each 
*          output NDF for a given sub-system will have an appropriately 
*          incremented value for the trailing "_nnnn" field. If any of
*          the input NDFs do not conform to the ACSIS file naming convention, 
*          the strings "_1", "_2", etc will be appended to the end of the 
*          supplied group of names to form the output NDF names.
*     SIZELIMIT = _INTEGER (Read)
*          Only accessed if parameter MERGE is set TRUE. It is a number that 
*          specifies the maximum size of each output NDF when merging data
*          from several input NDFs (see parameter MERGE). The minimum
*          number of output NDFs needed to hold all the input data will be
*          used. The final output NDF may be smaller than the specified
*          maximum size. The value given is either the file size in
*          megabytes, the number of time slices, or the number of spectra,
*          as specified by parameter LIMITTYPE. If a null (!) value is
*          supplied, then the number of output NDFs will be the same as
*          the number of input NDFs, and all output NDFs will have the
*          same size. If a negative or zero value is supplied, then a single 
*          output NDF will be created holding all the input data. [!]

*  Authors:
*     David Berry (JAC, UCLan)
*     {enter_new_authors_here}

*  History:
*     7-NOV-2007 (DSB):
*        Original version.
*     7-FEB-2008 (DSB):
*        Store provenance info in the output NDFs.
*     14-MAR-2008 (DSB):
*        Added sub-scan merging facility.
*     19-MAR-2008 (DSB):
*        Allow merging of sub-scans across sub-systems and observations. 
*        Change scheme for naming output files so that they conform to
*        the ACSIS file naming convention, if possible. Update FITS
*        headers NSUBSCAN and OBSEND in the output NDFs.

*  Copyright:
*     Copyright (C) 2007-2008 Science and Technology Facilities Council.
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
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/


#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <limits.h>
#include <string.h>
#include <stdio.h>

/* STARLINK includes */
#include "ast.h"
#include "mers.h"
#include "prm_par.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/hds.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "star/atl.h"
#include "star/kaplibs.h"
#include "par.h"

/* SMURF includes */
#include "libsmf/smf.h"

/* Number of ACSIS extension components that need to be re-ordered. */
#define NACSIS 3

void smurf_timesort( int *status ) {

/* Local Variables */
   AstFitsChan *fc = NULL;
   AstFrame *cfrm = NULL;     
   AstFrameSet *wcs = NULL;   
   AstKeyMap *km1;
   AstKeyMap *km2;
   AstKeyMap *obs_map = NULL;
   AstKeyMap *subscan_map = NULL;
   AstKeyMap *subsys_map = NULL;
   AstLutMap *lut = NULL;     
   AstMapping *map = NULL;    
   AstMapping *omap = NULL;   
   AstMapping *tmap = NULL;   
   Grp *igrp1 = NULL;         
   Grp *igrp2 = NULL;         
   Grp *igrp3 = NULL;         
   HDSLoc *loc1 = NULL;       
   HDSLoc *loc1c = NULL;      
   HDSLoc *loc2 = NULL;       
   HDSLoc *loc2c = NULL;      
   char *match = NULL;
   char *pname = NULL;
   char *qts_in;
   char *qts_out;
   char basename[ GRP__SZNAM + 1 ];
   char fullname[ GRP__SZNAM + 10 ];
   char ltbuf[ 11 ];                
   char name[ DAT__SZNAM + 1 ];
   char type[ DAT__SZTYP + 1 ];
   const char *comps = NULL;
   const char *dom;
   const char *key;
   const char *timeorg;
   const char *timescl;
   const char *timesys;
   const char *timeunt;
   double *grid = NULL;       
   double *tai = NULL;        
   double *tai_ptr = NULL;    
   double *taiout = NULL;
   float *dts_in;
   float *dts_out;
   float *vts_in;
   float *vts_out;
   int **sysrts = NULL;
   int *file_index = NULL;
   int *first = NULL;         
   int *index = NULL;         
   int *itimeout = NULL;
   int *ndfid = NULL;
   int *nsysrts = NULL;
   int *rts = NULL;
   int axes[ 2 ];             
   int conform;              
   int dims[ 3 ];             
   int el;                    
   int hasqual;
   int hasvar;
   int i;                     
   int iel;
   int ifile;                 
   int indf1;                 
   int indf1s;
   int indf2;                 
   int indf2s;
   int init;
   int iobs;
   int iout;
   int ioutname;
   int isubscan;
   int isubsys;
   int j;
   int k;
   int lbnd[ 3 ];
   int maxsyspop;
   int merge;                 
   int nchan;
   int ncomp;                 
   int ndet;
   int ndim;                  
   int nnout[ NDF__MXDIM ];     
   int nobs;
   int nout;
   int nrem;
   int nsubscan;
   int nsubsys;
   int nts_in;            
   int nts_out;
   int nullsizelimit;
   int ok;
   int outsize;               
   int place;
   int rts_num0;
   int rts_num;
   int rts_num_last;
   int size;                  
   int sizelimit;
   int slbnd[ 3 ];
   int sorted;                 
   int subnd[ 3 ];
   int there;                 
   int totout;
   int tslimit;
   int ubnd[ 3 ];
   size_t len;                
   size_t ntai;               
   void *ipin;                
   void *ipout;               
   void *ptr[2];              

/* NDF array component names */
   static char *comp[2] = {"DATA", "VARIANCE"}; 

/* ACSIS arrays to be re-ordered */
   static char *acsis[NACSIS] = {"RECEPPOS", "TSYS", "TRX" };

/* Check inherited status */
   if( *status != SAI__OK ) return;

/* Begin an NDF context (we do not begin an AST context since this is
   done within the calling monolith routine). */
   ndfBegin();

/* Get a group of input files */ 
   kpg1Rgndf( "IN", 0, 1, "  Give more NDFs...", &igrp1, &size, status );

/* Group the input NDFs according to OBSID, SUBSYSNR and NSUBSCAN values. 
   The groups are held in nested AST KeyMaps. Also returns the maximum number 
   of NDFs relating to any one sub-system, and a flag indicating if all input
   NDF names conformed to the naming convention for ACSIS raw time series
   files.  */
   obs_map = smf_groupscans( igrp1, size, &maxsyspop, &conform, &igrp3, 
                             status );

/* Initialise the number of output NDFs created. */
   totout = 0;

/* If two or more input NDFs refer to the same observation and sub-system, 
   use a default of TRUE for parameter MERGE. */
   parDef0l( "MERGE", ( maxsyspop > 1 ), status );

/* See if we are sorting each input file individually, or sorting the
   merged input data. */
   parGet0l( "MERGE", &merge, status );

/* First handle cases where we are sorting individual input files. */
/* =============================================================== */
   if( !merge ) {

/* Get a group of exactly "size" names for the output NDFs.  Base 
   modification elements on the group containing the input NDFs. */
      kpg1Wgndf( "OUT", igrp1, size, size, "  Give more NDFs...",
                 &igrp2, &outsize, status );

/* Loop round each input NDF. */
      for( ifile = 1; ifile <= size && *status == SAI__OK; ifile++ ) {
   
/* Tell the user which NDF is being processed. */
         msgSeti( "I", ifile );
         msgSeti( "N", size );
         msgOutif( MSG__VERB, "", "Processing NDF  ^I of ^N...", status );
   
/* Begin AST and NDF contexts for this pair of input and output NDFs. */
         astBegin;
         ndfBegin();
   
/* Get an NDF identifier for the input NDF. */
         ndgNdfas( igrp1, ifile, "READ", &indf1, status );
   
/* Get a locator to the JCMTSTATE extension. This will report an error if
   the extension does not exist. */
         ndfXloc( indf1, "JCMTSTATE", "READ", &loc1, status );
   
/* Map the TCS_TAI array in the JCMTSTATE extension. */
         datFind( loc1, "TCS_TAI", &loc1c, status );
         datMapV( loc1c, "_DOUBLE", "READ", (void **) &tai_ptr, &ntai, status );
   
/* Obtain a sorted index for the TCS_TAI values in the JCMTSTATE
   extension. */
         index = smf_sortd( ntai, tai_ptr, &sorted, status );
   
/* Free the TCS_TAI array now so that we can re-access the array later
   when we come to re-order each array in the JCMTSTATE extension. */
         datUnmap( loc1c, status );
         datAnnul( &loc1c, status );
   
/* Create the output NDF from the input NDF. If the input NDF TCS_TAI
   values are already sorted, propagate everything and pass on to the the
   next input NDF. Otherwise propagate everything except the data arrays
   and then go on to copy the re-ordered arrays into the output. */
         if( sorted ) {
            ndgNdfpr( indf1, "Data,Variance,Quality,Units,Axis,WCS,"
                      "NoExtension(Provenance)", igrp2, ifile, &indf2, status );
         } else {
            ndgNdfpr( indf1, "Units,Axis,WCS,NoExtension(Provenance)", igrp2, 
                      ifile, &indf2, status );
   
/* Get the pixel dimensions of the input NDF. Report an error if not
   three dimensional. */
            ndfDim( indf1, 3, dims, &ndim, status ); 
            if( ndim != 3 && *status == SAI__OK ) {
               *status = SAI__ERROR;
               ndfMsg( "NDF", indf1 );
               errRep( "", "Input NDF ^NDF is not 3 dimensional.", status );
            }        
   
/* Re-order the Data and Variance arrays (if they exist). */
            for( i = 0; i < 2 && *status == SAI__OK; i++ ) {
               ndfState( indf1, comp[ i ], &there, status ); 
               if( there ) {
                  ndfMap( indf1, comp[ i ], "_REAL", "READ", &ipin, &el, status );
                  ndfMap( indf2, comp[ i ], "_REAL", "WRITE", &ipout, &el, status );
                  smf_reorderr( (float *) ipin, ndim, dims, 2, index,
                                (float *) ipout, status );
               }
            }
   
/* Re-order every component of the JCMTSTATE extension. It is assumed
   that each component is an array in which the last axis corresponds to
   the time axis. First get a locator for the output JCMTSTATE extension. */
            ndfXloc( indf2, "JCMTSTATE", "UPDATE", &loc2, status );
   
/* Find out how many components there are in the JCMTSTATE extension, and
   then loop round them all, using a one-based component index. */
            datNcomp( loc1, &ncomp, status );
            for( i = 1; i <= ncomp && *status == SAI__OK; i++ ) {
   
/* Get locators for the current JCMTSTATE component in both input and
   output NDF. */
               datIndex( loc1, i, &loc1c, status );
               datIndex( loc2, i, &loc2c, status );
   
/* Determine the shape and type of the array component. */
               datShape( loc1c, 3, dims, &ndim, status );
               datType( loc1c, type, status );
   
/* Pass on if the component is scalar, or if the last dimension is not of
   the same length as the TCS_TAI array. */
               if( ndim > 0 && dims[ ndim - 1 ] == ntai ) {
   
/* Map the input and output arrays. */
                  datMap( loc1c, type, "READ", ndim, dims, &ipin, status );
                  datMap( loc2c, type, "WRITE", ndim, dims, &ipout, status );
   
/* Re-order the array. */
                  if( !strcmp( type, "_REAL" ) ) {
                     smf_reorderr( (float *) ipin, ndim, dims, ndim - 1, index,
                                   (float *) ipout, status );
   
                  } else if( !strcmp( type, "_DOUBLE" ) ) {
                     smf_reorderd( (double *) ipin, ndim, dims, ndim - 1, index,
                                   (double *) ipout, status );
   
                  } else if( !strcmp( type, "_INTEGER" ) ) {
                     smf_reorderi( (int *) ipin, ndim, dims, ndim - 1, index,
                                   (int *) ipout, status );
   
                  } else if( !strncmp( type, "_CHAR", 5 ) ) {
                     datLen( loc1c, &len, status );
                     smf_reorderc( (char *) ipin, len, ndim, dims, ndim - 1, 
                                   index, (char *) ipout, status );
   
                  } else if( *status == SAI__OK ) {
                     datName( loc1c, name, status );
                     *status = SAI__ERROR;
                     msgSetc( "COMP", name );
                     msgSetc( "TYPE", type );
                     errRep( "", "TIMESORT: Cannot re-order JCMTSTATE.^COMP."
                                 "^TYPE data type not yet supported.", status );
                  }
   
/* Unmap the mapped arrays. */
                  datUnmap( loc1c, status );
                  datUnmap( loc2c, status );
               }
   
/* Annul the component locators in the input and output NDFs. */
               datAnnul( &loc1c, status );
               datAnnul( &loc2c, status );
            }
   
/* Annul the JCMTSTATE locator for the output NDF. */
            datAnnul( &loc2, status );
         }

/* Increment the number of output NDFs created. */
         totout++;
   
/* Annul the JCMTSTATE locator for the input NDF. */
         datAnnul( &loc1, status );
   
/* Pass on if the input NDF does not have an ACSIS extension. */
         ndfXstat( indf1, "ACSIS", &there, status );     
         if( there ) {
   
/* We now re-order selected components of the ACSIS extension. First get a
   locator for the extension in both input and output NDFs. */
            ndfXloc( indf1, "ACSIS", "READ", &loc1, status );
            ndfXloc( indf2, "ACSIS", "UPDATE", &loc2, status );
   
/* Loop round each component to be re-ordered. */
            for( i = 0; i < NACSIS && *status == SAI__OK; i++ ) {
   
/* Get locators for the current ACSIS component in both input and
   output NDF. */
               datFind( loc1, acsis[ i ], &loc1c, status );
               datFind( loc2, acsis[ i ], &loc2c, status );
   
/* Determine the shape and type of the array component. */
               datShape( loc1c, 3, dims, &ndim, status );
               datType( loc1c, type, status );
   
/* Map the input and output arrays. */
               datMap( loc1c, type, "READ", ndim, dims, &ipin, status );
               datMap( loc2c, type, "WRITE", ndim, dims, &ipout, status );
   
/* Re-order the array. */
               if( !strcmp( type, "_REAL" ) ) {
                  smf_reorderr( (float *) ipin, ndim, dims, ndim - 1, index,
                                (float *) ipout, status );
   
               } else if( !strcmp( type, "_DOUBLE" ) ) {
                  smf_reorderd( (double *) ipin, ndim, dims, ndim - 1, index,
                                (double *) ipout, status );
   
               } else if( !strcmp( type, "_INTEGER" ) ) {
                  smf_reorderi( (int *) ipin, ndim, dims, ndim - 1, index,
                                (int *) ipout, status );
   
               } else if( !strncmp( type, "_CHAR", 5 ) ) {
                  datLen( loc1c, &len, status );
                  smf_reorderc( (char *) ipin, len, ndim, dims, ndim - 1, 
                                index, (char *) ipout, status );
   
               } else if( *status == SAI__OK ) {
                  datName( loc1, name, status );
                  *status = SAI__ERROR;
                  msgSetc( "COMP", name );
                  msgSetc( "TYPE", type );
                  errRep( "", "TIMESORT: Cannot re-order ACSIS.^COMP."
                              "^TYPE data type not yet supported.", status );
               }
   
/* Unmap the mapped arrays. */
               datUnmap( loc1c, status );
               datUnmap( loc2c, status );
   
/* Annul the component locators in the input and output NDFs. */
               datAnnul( &loc1c, status );
               datAnnul( &loc2c, status );
            }
   
/* Annul the ACSIS locator for the output NDF. */
            datAnnul( &loc2, status );
         }
   
/* Now modify the WCS in the output NDF. First get the existing WCS
   FrameSet from the output NDF. */
         ndfGtwcs( indf2, &wcs, status );
   
/* Get pointers to the current Frame, and the GRID->WCS Mapping. */
         cfrm = astGetFrame( wcs, AST__CURRENT );
         map = astGetMapping( wcs, AST__BASE, AST__CURRENT );
   
/* Split off the Mapping for the third (time) axis. */
         axes[ 0 ] = 3;
         astMapSplit( map, 1, axes, nnout, &tmap );
         if( tmap && astGetI( tmap, "Nout" ) == 1 ) {
   
/* Get a table of time values for every grid index, in order of increasing 
   time value. */
            grid = astMalloc( sizeof( double )*ntai );
            tai = astMalloc( sizeof( double )*ntai );
            for( i = 0; i < ntai; i++ ) grid[ i ] = index[ i ] + 1.0;
            astTran1( tmap, ntai, grid, 1, tai );
   
/* Create a LutMap holding these sorted time values. */
            lut = astLutMap( ntai, tai, 1.0, 1.0, "" );
   
/* Split off a Mapping for the other two axes. */
            axes[ 0 ] = 1;
            axes[ 1 ] = 2;
            astMapSplit( map, 2, axes, nnout, &omap );
            if( omap && astGetI( omap, "Nout" ) == 2 ) {
   
/* Put this Mapping in parallel with the time axis Mapping created above. */
               map = (AstMapping *) astCmpMap( omap, lut, 0, "" );
               
/* Remove the current Frame from the FrameSet, then add it back in again
   using the above Mapping to connect it to the GRID (base) Frame. */
               astRemoveFrame( wcs, AST__CURRENT );
               astAddFrame( wcs, AST__BASE, map, cfrm );
   
/* Store the modifed WCS FrameSet in the output NDF. */
               ndfPtwcs( wcs, indf2, status );
   
            }
   
/* Free resources. */
            grid = astFree( grid );
            tai = astFree( tai );
   
         }
   
/* Free remaining resources. */
         index = astFree( index );
         datAnnul( &loc1, status );
   
/* Record indf1 as a direct parent of indf2. */
         ndgPtprv( indf2, indf1, NULL, 0, "SMURF:TIMESORT", status );
   
/* End the AST and NDF contexts for this pair of input and output NDFs. */
         ndfEnd( status );
         astEnd;
   
/* If an error has occurred processing this input NDF, flush it and
   proceed with the next NDF. */
         if( *status != SAI__OK ) {
            msgSeti( "I", ifile );
            errRep( "", "TIMESORT: failed to process input NDF number ^I.", 
                    status );
            errFlush( status );
         }
      }

/* Free resources. */
      grpDelet( &igrp2, status );



/* Now handle cases where the input files are being merged. */
/* ======================================================== */
   } else if( *status == SAI__OK ){

/* Get the SIZELIMIT and LIMITTYPE parameters. */
      parGet0i( "SIZELIMIT", &sizelimit, status );      
      if( *status == SAI__OK ) {
         nullsizelimit = 0;
         if( sizelimit > 0 ) parChoic( "LIMITTYPE", "FILESIZE", 
                                       "FILESIZE,SPECTRA,SLICES", 0, ltbuf, 
                                       10, status );
      } else if( *status == PAR__NULL ) {
         errAnnul( status );
         nullsizelimit = 1;
      }
      
/* The "igrp3" group contains the names of NDFs containing the first 
   subscan in each observation/sub-system. Get a group of output base NDF
   names based on these files. These base names will be edited to create 
   the name to be used for each output subscan NDF. */
      grpGrpsz( igrp3, &outsize, status );
      kpg1Wgndf( "OUT", igrp3, outsize, outsize, "", &igrp2, &outsize, 
                 status );

/* Initialise the index of the next output base file name to use. */
      ioutname = 1;

/* Loop round all observations represented in the input data. */
      nobs = astMapSize( obs_map );
      for( iobs = 0; iobs < nobs; iobs++ ) {
         key = astMapKey( obs_map, iobs );
         astMapGet0A( obs_map, key, &subsys_map );

         if( nobs > 1 ) {
            msgSeti( "I", iobs + 1 );
            msgSeti( "N", nobs );
            msgSetc( "K", key );
            msgOutif( MSG__VERB, "", "Doing observation ^K (^I of ^N)...", 
                      status );
         }

/* Get the number of sub-systems for this observation. */
         nsubsys = astMapSize( subsys_map );

/* Allocate memory to hold the RTS_NUM values used for this sub-system. */
         nsysrts = astMalloc( sizeof( int )*nsubsys );
         sysrts = astMalloc( sizeof( int * )*nsubsys );
         if( sysrts ) {
            for( isubsys = 0; isubsys < nsubsys; isubsys++ ) {
               sysrts[ isubsys ] = NULL;
               nsysrts[ isubsys ] = 0;
            }
         }

/* Loop round all sub-systems represented in the current observation. */
         for( isubsys = 0; isubsys < nsubsys; isubsys++ ) {
            astBegin;
            ndfBegin();

            key = astMapKey( subsys_map, isubsys );
            astMapGet0A( subsys_map, key, &subscan_map );

            if( nsubsys > 1 && *status == SAI__OK ) {
               msgSeti( "I", isubsys + 1 );
               msgSeti( "N", nsubsys );
               msgSetc( "K", key );
               msgOutif( MSG__VERB, "", "Doing sub-system ^K (^I of ^N)...", 
                         status );
            }

/* Find how many scub-scans the current observation/sub-system has. */
            nsubscan = astMapSize( subscan_map );

/* Lists are created below that concatenate all the time slices from
   every input NDF (these lists are stored in AST KeyMaps, keyed by the
   name of the corresponding JCMTSTATE or ACSIS extension item). Allocate 
   an array to store the index of the first time slice within these lists 
   for each input file. */
            first = astMalloc( sizeof( int )*nsubscan );    

/* Allocate an array to store the NDF identifier for each input file. */
            ndfid = astMalloc( sizeof( int )*nsubscan );    

/* Create a KeyMap to hold JCMTSTATE data values. */
            km1 = astKeyMap( "" );

/* Create a KeyMap to hold ACSIS data values. */
            km2 = astKeyMap( "" );

/* Initialise a pointer to an array used to hold the index of the
   input NDF from which each time slice in the concatenated list of time
   slices was read. */
            file_index = NULL;

/* Initialise the total number of time slices currently in the lists of
   concatenated time slices. */
            nts_in = 0;

/* Assume for the moment that all input NDFs have Variance and Quality
   arrays. */
            hasvar = 1;
            hasqual = 1;

/* Loop round each input NDF in the current sub-system. */
            for( isubscan = 0; isubscan < nsubscan && *status == SAI__OK; isubscan++ ) {
               key = astMapKey( subscan_map, isubscan );

/* Get the one-based index of the input NDF within the input GRP group . */
               astMapGet0I( subscan_map, key, &ifile );

/* Begin an AST context for this input NDF. */
               astBegin;
   
/* Get an NDF identifier for the input NDF. */
               ndgNdfas( igrp1, ifile, "READ", &indf1, status );
               ndfid[ isubscan ] = indf1;

/* Tell the user which NDF is being processed. */
               ndfMsg( "F", indf1 );
               msgSeti( "I", isubscan + 1 );
               msgSeti( "N", nsubscan );
               msgOutif( MSG__VERB, "", "Reading headers from "
                         "^F (^I/^N)...", status );
   
/* Get the shape of the data array. */
               ndfDim( indf1, 3, dims, &ndim, status ); 
               if( ndim != 3 && *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  ndfMsg( "NDF", indf1 );
                  errRep( "", "Input NDF ^NDF is not 3 dimensional.", status );
               }        
      
/* If this is the first input file, store the number of channels and the 
   number of detectors in the data. */
               if( isubscan == 0 ) {
                  nchan = dims[ 0 ];
                  ndet = dims[ 1 ];
      
/* If this is not the first input file, check the number of channels and 
   detectors are the same as in the first input NDF. */
               } else if( dims[ 0 ] != nchan && *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  ndfMsg( "NDF", indf1 );
                  errRep( "", "The number of spectral channels in '^NDF' differs "
                          "from the first NDF.", status );
      
               } else if( dims[ 1 ] != ndet && *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  ndfMsg( "NDF", indf1 );
                  errRep( "", "The number of receptors in '^NDF' differs "
                          "from the first NDF.", status );
               }
      
/* If all input NDFs read so far have a Variance array, see if this one
   does too. */
               if( hasvar ) ndfState( indf1, "Variance", &hasvar, status );
      
/* If all input NDFs read so far have a Quality array, see if this one
   does too. */
               if( hasqual ) ndfState( indf1, "Quality", &hasqual, status );
      
/* Read all the data in the JCMTSTATE extension of the current input NDF,
   and append it to entries in the appropriate KeyMap. Each entry in the
   KeyMap has a name equal to the name of a component within the JCMTSTATE
   extension. The first NDF defines the components that are expected in a
   JCMTSTATE extension. If any subsequent NDF does not have any of the
   components read form the first NDF, then an error is reported. */
               smf_ext2km( indf1, "JCMTSTATE", km1, isubscan ? 2 : 1, 
                           status );
      
/* Similarly, record all the data in the ACSIS extension. */
               smf_ext2km( indf1, "ACSIS", km2, isubscan ? 2 : 1, status );
      
/* Store the index within the "rts" array of the first RTS value for this 
   file. */
               first[ isubscan ] = nts_in;
      
/* Increment the total number of time slices recorded.� */
               nts_in += dims[ 2 ];
      
/* Extend the "file_index" array and store the file index in every new 
   element. */
               file_index = astGrow( file_index, nts_in, sizeof( int ) );
               if( *status == SAI__OK ) {
                  for( i = nts_in - dims[ 2 ]; i < nts_in; i++ ) {
                     file_index[ i ] = isubscan;
                  }
               }
      
/* Get the WCS FrameSet from the input NDF. */
               ndfGtwcs( indf1, &wcs, status );
      
/* Get pointers to the current Frame, and the GRID->WCS Mapping. */
               cfrm = astGetFrame( wcs, AST__CURRENT );
               map = astGetMapping( wcs, AST__BASE, AST__CURRENT );
      
/* Report an error if the 3rd WCS axis is not a time axis. */
               dom = astGetC( cfrm, "Domain(3)" );
               if( dom && strcmp( dom, "TIME" ) ) {
                  if( *status == SAI__OK ) {
                     *status = SAI__ERROR;
                     ndfMsg( "N", indf1 );
                     errRep( "", "WCS axis 3 is not a time axis in \"^N\".",
                             status );
                  }
               }
      
/* If this is the first input NDF, record the main details of the time
   axis. */
               if( isubscan == 0 ) {
                  timesys = astGetC( cfrm, "System(3)" );
                  timescl = astGetC( cfrm, "TimeScale(3)" );
                  timeorg = astGetC( cfrm, "TimeOrigin(3)" );
                  timeunt = astGetC( cfrm, "Unit(3)" );
         
/* For later input NDFs, report an error if any of the details are
   different. */
               } else if( *status == SAI__OK ) {
                  if( strcmp( timesys, astGetC( cfrm, "System(3)" ) ) ) {
                     ndfMsg( "N", indf1 );
                     msgSetc( "T", astGetC( cfrm, "System(3)" ) );
                     *status = SAI__ERROR;
                     errRep( "", "Unexpected time system (^T) in \"^N\".",
                             status );
      
                  } else if( strcmp( timescl, astGetC( cfrm, "TimeScale(3)" ) ) ) {
                     ndfMsg( "N", indf1 );
                     msgSetc( "T", astGetC( cfrm, "TimeScale(3)" ) );
                     *status = SAI__ERROR;
                     errRep( "", "Unexpected time scale (^T) in \"^N\".",
                             status );
      
                  } else if( strcmp( timeorg, astGetC( cfrm, "TimeOrigin(3)" ) ) ) {
                     ndfMsg( "N", indf1 );
                     msgSetc( "T", astGetC( cfrm, "TimeOrigin(3)" ) );
                     *status = SAI__ERROR;
                     errRep( "", "Unexpected time origin (^T) in \"^N\".",
                             status );
      
                  } else if( strcmp( timeunt, astGetC( cfrm, "Unit(3)" ) ) ) {
                     ndfMsg( "N", indf1 );
                     msgSetc( "T", astGetC( cfrm, "Unit(3)" ) );
                     *status = SAI__ERROR;
                     errRep( "", "Unexpected time unit (^T) in \"^N\".",
                             status );
                  }
               }
      
/* Split off the Mapping for the third (time) axis. */
               axes[ 0 ] = 3;
               astMapSplit( map, 1, axes, nnout, &tmap );
               if( tmap && astGetI( tmap, "Nout" ) == 1 ) {
         
/* Get an array holding the time axis grid indices in the current input NDF. */
                  grid = astGrow( grid, dims[ 2 ], sizeof( double ) );
                  for( i = 0; i < dims[ 2 ]; i++ ) grid[ i ] = i + 1;
      
/* Expand the table of time values so that there is room for the time
   values from the current input NDF. */
                  tai = astGrow( tai, nts_in, sizeof( double ) );
      
/* Transform the grid indices to get the time axis values, appending them
   to the end of the "tai" array. */
                  astTran1( tmap, dims[ 2 ], grid, 1, tai + nts_in - dims[ 2 ] );
      
/* Report an error if the Mapping could not be split. */
               } else if( *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  ndfMsg( "N", indf1 );
                  errRep( "", "Unable to extract the time mapping from "
                          "the WCS FrameSet in \"^N\".", status );
               }            
      
/* Free resources. */
               astEnd;
            }
      
/* Get an array holding the list of concatenated RTS_NUM values read from
   the input NDFs. */
            rts = astMalloc( sizeof(int)*nts_in );
            if( !astMapGet1I( km1, "RTS_NUM", nts_in, &nts_in, rts ) ) {
               if( *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  errRep( "", "The first input NDF (and maybe others) did not "
                          "contain a JCMTSTATE.RTS_NUM array.", status );
               }
            }
      
/* Get an array holding an index of the "rts" and "file_index" arrays that 
   accesses the arrays in order of increasing rts_num value. */
            index = smf_sorti( nts_in, rts, &sorted, status );
      
/* Note the number of unique RTS_NUM values. */
            if( index ) {
               rts_num_last = -INT_MAX;
               nts_out = 0;
               for( j = 0; j < nts_in; j++ ) {
                  i = index[ j ];
                  rts_num = rts[ i ];
                  if( rts_num > rts_num_last ) nts_out++;
                  rts_num_last = rts_num;
               }
            }

/* Allocate an array to hold the output RTS_NUM values. */
            sysrts[ isubsys ] = astMalloc( sizeof( int )*nts_out );
            nsysrts[ isubsys ] = nts_out;
      
/* Get the required maximum output file size, and convert to a number of
   time slices. */
            nout = 0;
            if( nullsizelimit ) {
               nout = nsubscan;
               if( nout > 0 ) tslimit = nts_out/nout;
               if( nout*tslimit < nts_out ) tslimit++;

            } else {
               if( sizelimit <= 0 ) {
                  nout = 1;
                  tslimit = nts_out;
   
               } else {
                  if( !strcmp( ltbuf, "SPECTRA" ) ) {
                     if( ndet > 0 ) tslimit = sizelimit / ndet;
            
                  } else if( *status == SAI__OK && 
                             !strcmp( ltbuf, "FILESIZE" ) ) {
                     tslimit = sizelimit / 
                                 ( ndet*nchan*( VAL__NBR*( hasvar ? 2 : 1 ) + 
                                                ( hasqual ? VAL__NBUB : 0) ) );
                  }
               }
         
/*  Find the number of output NDFs needed. */
               if( tslimit > 0 ) nout = nts_out/tslimit;
               if( nout*tslimit < nts_out ) nout++;
            }
      
/* Store a list of NDF component names to be mapped. */
            if( hasvar ) {
               comps = "Data,Variance";
            } else {
               comps = "Data";
            }
      
/* Get the WCS FrameSet from the first input NDF. */
            if( ndfid ) ndfGtwcs( ndfid[ 0 ], &wcs, status );
      
/* Get pointers to the current Frame, and the GRID->WCS Mapping. */
            cfrm = astGetFrame( wcs, AST__CURRENT );
            map = astGetMapping( wcs, AST__BASE, AST__CURRENT );
      
/* Split off the Mapping for the first and second axes. */
            axes[ 0 ] = 1;
            axes[ 1 ] = 2;
            astMapSplit( map, 2, axes, nnout, &omap );
            if( !omap || astGetI( omap, "Nout" ) != 2 ) {
               if( *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  ndfMsg( "N", indf1 );
                  errRep( "", "Unable to extract the non-time mappings from "
                          "the WCS FrameSet in \"^N\".", status );
               }            
            }
      
/* Get the base name for the output NDFs created for this subsystem. */
            pname = basename;
            grpGet( igrp2, ioutname++, 1, &pname, GRP__SZNAM, status );
            basename[ astChrLen( basename ) ] = 0;

/* Initialise the bounds of each output NDF. */
            lbnd[ 0 ] = 1;
            lbnd[ 1 ] = 1;
            lbnd[ 2 ] = 1;
            ubnd[ 0 ] = nchan;
            ubnd[ 1 ] = ndet;
            ubnd[ 2 ] = tslimit;
      
/* Initialise the bounds of each section used to represent one time slice
   in the output NDF. */
            slbnd[ 0 ] = 1;
            slbnd[ 1 ] = 1;
            subnd[ 0 ] = nchan;
            subnd[ 1 ] = ndet;
      
/* The number of time slices remaining to be written out. */
            nrem = nts_out;
      
/* Initialise the index into the "index" array. "j" steps through the
   input time slices, from 0 to ( nts_in - 1 ).  The "index[j]" value
   also steps through the input time slices, but in order of increasing
   RTS_NUM value. */
            j = 0;
      
/* Loop round each output NDF. */
            itimeout = NULL;
            taiout = NULL;
            for( iout = 0; iout < nout && *status == SAI__OK; iout++ ) {
      
/* If all the input NDFs conform to the naming convention for ACSIS time
   series files, then the output NDF name for this subscan is formed by 
   replacing the trailing "_nnnn" sub-scan number in the base name with 
   the correct value for this output NDF. */
               if( conform ) {
                  sprintf( fullname, "%.4d", iout + 1 );
                  pname = fullname;
                  match = astChrSub( basename,
                                     "a\\d{8}_\\d{5}_\\d{2}_(\\d{4})_?", 
                                     (const char **) &pname, 1 );
                  if( match ) {
                     strcpy( fullname, match );
                     match = astFree( match );

                  } else if( *status == SAI__OK ) {
                     *status = SAI__ERROR;
                     msgSetc( "N", basename );
                     errRep( "", "File name \"^N\" has unexpected format " 
                             "(programming error).", status );
                  }

/* If any of the input NDFs do not conform to the naming convention for ACSIS 
   time series files, then the output NDF name for this subscan is formed by 
   appending "_n" to the end of the base name. */
               } else {
                  sprintf( fullname, "%s_%d", basename, iout + 1 );
               }

/* Create the output NDF by propagation from the first input NDF. */
               msgSetc( "N", fullname );
               msgOutif( MSG__VERB, "", "Opening output NDF \"^N\".", status );

               ndfPlace( NULL, fullname, &place, status );
               ndfScopy( ndfid[ 0 ], "Units,Axis,NoExtension(PROVENANCE)", 
                         &place, &indf2, status );
      
/* Increment the number of output NDFs created. */
               totout++;
   
/* Modify its shape. The last output NDF will probably not need to be the
   full size, so ensure no output NDF is bigger than it needs to be. */
               if( nrem < tslimit ) ubnd[ 2 ] = nrem;
               ndfSbnd( 3, lbnd, ubnd, indf2, status ); 
      
/* Ensure we have arrays large enough to hold the input time slice
   index and tai for each output time slice. */
               itimeout = astGrow( itimeout, ubnd[ 2 ], sizeof( int ) );
               taiout = astGrow( taiout, ubnd[ 2 ], sizeof( double ) );
      
/* Get the RTS_NUM value from the next input time slice. This value is
   also the RTS_NUM value for the next output time slice. */
               i = index[ j ];
               rts_num = rts[ i ];
      
/* Loop round each output time slice. */
               for( k = 0; k < ubnd[ 2 ]  && *status == SAI__OK; k++ ) {
      
/* Get a section of the output NDF covering this time slice. */
                  slbnd[ 2 ] = k + 1;
                  subnd[ 2 ] = k + 1;
                  ndfSect( indf2, 3, slbnd, subnd, &indf2s, status ); 
      
/* Map the required output NDF section array components. */
                  ndfMap( indf2s, comps, "_REAL", "WRITE", ptr, &el, 
                          status );
                  dts_out = ptr[ 0 ];
                  vts_out = hasvar ? ptr[ 1 ] : NULL;
         
                  if( hasqual ) {
                     ndfMap( indf2s, "Quality", "_UBYTE", "WRITE", ptr, 
                             &el, status );
                     qts_out = ptr[ 0 ];
                  } else {
                     qts_out = NULL;
                  }
      
/* Store the input time slice index for this output time slice. */
                  itimeout[ k ] = i;
      
/* Store the input time slice tai for this output time slice. */
                  taiout[ k ] = tai[ i ]; 
      
/* Store the RTS_NUM value for this output time slice. */
                  sysrts[ isubsys ][ k ] = rts_num;
      
/* Loop round all input time slices that refer to the same RTS_NUM value. */
                  init = 1;
                  rts_num0 = rts_num;
                  while( rts_num == rts_num0 ) {
      
/* Get the zero-based index of the input NDF from which the current RTS_NUM 
   value was read. */
                     isubscan = file_index[ i ];
      
/* Get a section of the input NDF covering this time slice. */
                     slbnd[ 2 ] = i  - first[ isubscan ] + 1;
                     subnd[ 2 ] = slbnd[ 2 ];
                     ndfSect( ndfid[ isubscan ], 3, slbnd, subnd, &indf1s, status ); 
      
/* Map the required input NDF section array components. */
                     ndfMap( indf1s, comps, "_REAL", "READ",  ptr, &el, status );
                     dts_in = ptr[ 0 ];
                     vts_in = hasvar ? ptr[ 1 ] : NULL;
         
                     if( hasqual ) {
                        ndfMap( indf1s, "Quality", "_UBYTE", "READ", ptr, 
                                &el, status );
                        qts_in = ptr[ 0 ];
                     } else {
                        qts_in = NULL;
                     }
      
/* Loop round all elements in the time slice. Copy any good array values 
   from input to output. */
                     for( iel = 0; iel < el; iel++ ) {
                        if( dts_in[ iel ] != VAL__BADR ) {
                           dts_out[ iel ] = dts_in[ iel ];
                           if( hasvar ) vts_out[ iel ] = vts_in[ iel ];
                           if( hasqual) qts_out[ iel ] = qts_in[ iel ];
      
                        } else if( init ) {
                           dts_out[ iel ] = VAL__BADR;
                           if( hasvar ) vts_out[ iel ] = VAL__BADR;
                           if( hasqual) qts_out[ iel ] = 0;
                        }
                     }
      
/* Annul the identifier for the current time slice in the input NDF. */
                     ndfAnnul( &indf1s, status );
      
/* Move on to the next input time slice. */
                     if( ++j < nts_in ) {
                        i = index[ j ];
                        rts_num = rts[ i ];
                        init = 0;
                     } else {
                        break;
                     }
                  }
      
/* Annul the identifier for the current time slice in the output NDF. */
                  ndfAnnul( &indf2s, status );
               }
      
/* Copy input JCMTSTATE values to the current output NDF. */
               smf_km2ext( indf2, "JCMTSTATE", km1, itimeout, status );
      
/* Copy input ACSIS values to the current output NDF. */
               smf_km2ext( indf2, "ACSIS", km2, itimeout, status );
      
/* Create a LutMap to hold the TAI value for each time slice in the
   current output NDF. */
               lut = astLutMap( ubnd[ 2 ], taiout, 1.0, 1.0, "" );
      
/* Put this Mapping in parallel with the Mapping for the other axes. */
               map = (AstMapping *) astCmpMap( omap, lut, 0, "" );
                     
/* Remove the current Frame from the WCS FrameSet, then add it back in again
   using the above Mapping to connect it to the GRID (base) Frame. */
               astRemoveFrame( wcs, AST__CURRENT );
               astAddFrame( wcs, AST__BASE, map, cfrm );
         
/* Store the modifed WCS FrameSet in the output NDF. */
               ndfPtwcs( wcs, indf2, status );
      
/* Record each input NDF as a direct parent of indf2. */
               for( isubscan = 0; isubscan < nsubscan; isubscan++ ) {
                  ndgPtprv( indf2, ndfid[ isubscan ], NULL, 0, "SMURF:TIMESORT", 
                            status );
               }
         
/* Reduce the number of time slices remaining to be written out. */
               nrem -= ubnd[ 2 ];
      
/* If this is the last sub-scan set the OBSEND FITS keyword value to "T". 
   Otherwise set it to "F". Also store the sub-scan number. */
               kpgGtfts( indf2, &fc, status );
               atlPtftl( fc, "OBSEND", ( nrem == 0 ), "True if file "
                         "is last in current observation", status );
               atlPtfti( fc, "NSUBSCAN", iout + 1, "Sub-scan number", status );
               kpgPtfts( indf2, fc, status );
               fc = astAnnul( fc );
               
/* Delete the output NDF if an error occurred. Otherwise, annul the
   output NDF identifier. */
               msgSetc( "N", fullname );
               msgOutif( MSG__VERB, "", "Closing output NDF \"^N\".", status );

               if( *status != SAI__OK ) {
                  ndfDelet( &indf2, status );
               } else {
                  ndfAnnul( &indf2, status );
               }
            }
      
/* Free resources. */
            ndfid = astFree( ndfid );
            taiout = astFree( taiout );
            itimeout = astFree( itimeout );
            first = astFree( first );
            index = astFree( index );
            file_index = astFree( file_index );
            grid = astFree( grid );
            tai = astFree( tai );

/* End the AST and NDF context. */
            ndfEnd( status );
            astEnd;
         }

/* Check that all output sub-systems for this observation have the same 
   list of RTS_NUM values. */
         ok = 1;
         for( isubsys = 0; ok && isubsys < nsubsys; isubsys++ ) {
            if( nsysrts[ isubsys ] != nsysrts[ 0 ] ) {
               ok = 0;
            } else {
               for( k = 0; k <  nsysrts[ 0 ]; k++ ) {
                  if( sysrts[ isubsys ][ k ] != sysrts[ 0 ][ k ] ){
                     ok = 0;
                     break;
                  } 
               }
            }
         }

/* Issue a warning if they do not. */
         if( !ok && *status == SAI__OK ) {
            msgSetc( "O", astMapKey( obs_map, iobs ) );
            msgOut( "", "WARNING: The RTS_NUM values in the output NDFs "
                    "for observation ^O are not the same in all sub-systems.", 
                    status );
         }

/* Free resources. */
         if( sysrts ) {
            for( isubsys = 0; isubsys < nsubsys; isubsys++ ) {
               sysrts[ isubsys ] = astFree( sysrts[ isubsys ] );
            }
         }
         sysrts = astFree( sysrts );   
         nsysrts = astFree( nsysrts );   

      }

      grpDelet( &igrp2, status);

   }

/* Write out the number of output NDFs. */
   parPut0i( "NOUT", totout, status );

/* Free resources. */
   obs_map = astAnnul( obs_map );
   grpDelet( &igrp1, status );
   grpDelet( &igrp3, status );

/* End the NDF context. */
   ndfEnd( status );

/* Issue a status indication.*/  
   if( *status == SAI__OK ) {
      msgOutif( MSG__VERB, "", "TIMESORT succeeded.", status);
   } else {
      msgOutif( MSG__VERB, "", "TIMESORT failed.", status);
   }
}
