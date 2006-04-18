#define _POSIX_SOURCE 1		 /* Declare POSIX source */
/*
*+
*  Name:
*     ndf_adam

*  Purpose:
*     Implement the public C interface to the ADAM NDF_ library.

*  Language:
*     ANSI C

*  Description:
*     This module implements C-callable wrappers for the public
*     routines that are specific to the ADAM version of the NDF_
*     library.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils.

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
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     AJC: Alan Chipperfield (STARLINK, RAL)
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     <{enter_new_authors_here}>

*  History:
*     1-OCT-1998 (AJC):
*        Original version.
*     1-OCT-1998 (RFWS):
*        Incorporated into the NDF_ library.
*     <{enter_further_changes_here}>
*-
*/

/* Macro definitions for this module. */
/* ================================== */
/* These are work-arounds for problems with "const" handling by
   CNF. They should be removed when these problems are fixed. */
#define fix_F77_EXPORT_CHARACTER(a,b,c) F77_EXPORT_CHARACTER(((char *)(a)),(b),(c));
#define fix_F77_EXPORT_INTEGER_ARRAY(a,b,c) F77_EXPORT_INTEGER_ARRAY(((int *)(a)),(b),(c));

/* Header files. */
/* ============= */
/* C run-time library header files. */
#include <string.h>             /* String handling */

/* External interface header files. */
#include "f77.h"                /* C<-->Fortran interface macros */
#include "dat_par.h"            /* Hierarchical Data System (HDS) */

/* Internal header files. */
#include "ndf.h"                /* NDF_ library public interface */

/* Wrapper function implementations. */
/* ================================= */
F77_SUBROUTINE(ndf_assoc)( CHARACTER(param),
                           CHARACTER(mode),
                           INTEGER(indf),
                           INTEGER(status)
                           TRAIL(param)
                           TRAIL(mode) );

void ndfAssoc( const char *param,
               const char *mode,
               int *indf,
               int *status ) {

DECLARE_CHARACTER_DYN(fparam);
DECLARE_CHARACTER_DYN(fmode);
DECLARE_INTEGER(findf);
DECLARE_INTEGER(fstatus);

   F77_CREATE_CHARACTER( fparam, strlen( param ) );
   fix_F77_EXPORT_CHARACTER( param, fparam, fparam_length );
   F77_CREATE_CHARACTER( fmode, strlen( mode ) );
   fix_F77_EXPORT_CHARACTER( mode, fmode, fmode_length );
   F77_EXPORT_INTEGER( *status, fstatus );

   F77_CALL(ndf_assoc)( CHARACTER_ARG(fparam),
                        CHARACTER_ARG(fmode),
                        INTEGER_ARG(&findf),
                        INTEGER_ARG(&fstatus)
                        TRAIL_ARG(fparam)
                        TRAIL_ARG(fmode) );

   F77_FREE_CHARACTER( fparam );
   F77_FREE_CHARACTER( fmode );
   F77_IMPORT_INTEGER( findf, *indf );
   F77_IMPORT_INTEGER( fstatus, *status );

   return;
}

F77_SUBROUTINE(ndf_cinp)( CHARACTER(param),
                          INTEGER(indf),
                          CHARACTER(comp),
                          INTEGER(status)
                          TRAIL(param)
                          TRAIL(comp) );

void ndfCinp( const char *param,
              int indf,
              const char *comp,
              int *status ) {

DECLARE_CHARACTER_DYN(fparam);
DECLARE_INTEGER(findf);
DECLARE_CHARACTER_DYN(fcomp);
DECLARE_INTEGER(fstatus);

   F77_CREATE_CHARACTER( fparam, strlen( param ) );
   fix_F77_EXPORT_CHARACTER( param, fparam, fparam_length );
   F77_EXPORT_INTEGER( indf, findf );
   F77_CREATE_CHARACTER( fcomp, strlen( comp ) );
   fix_F77_EXPORT_CHARACTER( comp, fcomp, fcomp_length );
   F77_EXPORT_INTEGER( *status, fstatus );

   F77_CALL(ndf_cinp)( CHARACTER_ARG(fparam),
                       INTEGER_ARG(&findf),
                       CHARACTER_ARG(fcomp),
                       INTEGER_ARG(&fstatus)
                       TRAIL_ARG(fparam)
                       TRAIL_ARG(fcomp) );

   F77_FREE_CHARACTER( fparam );
   F77_FREE_CHARACTER( fcomp );
   F77_IMPORT_INTEGER( fstatus, *status );

   return;
}

F77_SUBROUTINE(ndf_creat)( CHARACTER(param),
                           CHARACTER(ftype),
                           INTEGER(ndim),
                           INTEGER_ARRAY(lbnd),
                           INTEGER_ARRAY(ubnd),
                           INTEGER(indf),
                           INTEGER(status)
                           TRAIL(param)
                           TRAIL(ftype) );

void ndfCreat( const char *param,
               const char *ftype,
               int ndim,
               const int lbnd[],
               const int ubnd[],
               int *indf,
               int *status ) {

DECLARE_CHARACTER_DYN(fparam);
DECLARE_CHARACTER_DYN(fftype);
DECLARE_INTEGER(fndim);
DECLARE_INTEGER_ARRAY_DYN(flbnd);
DECLARE_INTEGER_ARRAY_DYN(fubnd);
DECLARE_INTEGER(findf);
DECLARE_INTEGER(fstatus);

   F77_CREATE_CHARACTER( fparam, strlen( param ) );
   fix_F77_EXPORT_CHARACTER( param, fparam, fparam_length );
   F77_CREATE_CHARACTER( fftype, strlen( ftype ) );
   fix_F77_EXPORT_CHARACTER( ftype, fftype, fftype_length );
   F77_EXPORT_INTEGER( ndim, fndim );
   F77_CREATE_INTEGER_ARRAY( flbnd, ndim );
   fix_F77_EXPORT_INTEGER_ARRAY( lbnd, flbnd, ndim );
   F77_CREATE_INTEGER_ARRAY( fubnd, ndim );
   fix_F77_EXPORT_INTEGER_ARRAY( ubnd, fubnd, ndim );
   F77_EXPORT_INTEGER( *status, fstatus );

   F77_CALL(ndf_creat)( CHARACTER_ARG(fparam),
                        CHARACTER_ARG(fftype),
                        INTEGER_ARG(&fndim),
                        INTEGER_ARRAY_ARG(flbnd),
                        INTEGER_ARRAY_ARG(fubnd),
                        INTEGER_ARG(&findf),
                        INTEGER_ARG(&fstatus)
                        TRAIL_ARG(fparam)
                        TRAIL_ARG(fftype) );

   F77_FREE_CHARACTER( fparam );
   F77_FREE_CHARACTER( fftype );
   F77_FREE_INTEGER( flbnd );
   F77_FREE_INTEGER( fubnd );
   F77_IMPORT_INTEGER( findf, *indf );
   F77_IMPORT_INTEGER( fstatus, *status );

   return;
}

F77_SUBROUTINE(ndf_crep)( CHARACTER(param),
                          CHARACTER(ftype),
                          INTEGER(ndim),
                          INTEGER_ARRAY(ubnd),
                          INTEGER(indf),
                          INTEGER(status)
                          TRAIL(param)
                          TRAIL(ftype) );

void ndfCrep( const char *param,
              const char *ftype,
              int ndim,
              const int ubnd[],
              int *indf,
              int *status ) {

DECLARE_CHARACTER_DYN(fparam);
DECLARE_CHARACTER_DYN(fftype);
DECLARE_INTEGER(fndim);
DECLARE_INTEGER_ARRAY_DYN(fubnd);
DECLARE_INTEGER(findf);
DECLARE_INTEGER(fstatus);

   F77_CREATE_CHARACTER( fparam, strlen( param ) );
   fix_F77_EXPORT_CHARACTER( param, fparam, fparam_length );
   F77_CREATE_CHARACTER( fftype, strlen( ftype ) );
   fix_F77_EXPORT_CHARACTER( ftype, fftype, fftype_length );
   F77_EXPORT_INTEGER( ndim, fndim );
   F77_CREATE_INTEGER_ARRAY( fubnd, ndim );
   fix_F77_EXPORT_INTEGER_ARRAY( ubnd, fubnd, ndim );
   F77_EXPORT_INTEGER( *status, fstatus );

   F77_CALL(ndf_crep)( CHARACTER_ARG(fparam),
                       CHARACTER_ARG(fftype),
                       INTEGER_ARG(&fndim),
                       INTEGER_ARRAY_ARG(fubnd),
                       INTEGER_ARG(&findf),
                       INTEGER_ARG(&fstatus)
                       TRAIL_ARG(fparam)
                       TRAIL_ARG(fftype) );

   F77_FREE_CHARACTER( fparam );
   F77_FREE_CHARACTER( fftype );
   F77_FREE_INTEGER( fubnd );
   F77_IMPORT_INTEGER( findf, *indf );
   F77_IMPORT_INTEGER( fstatus, *status );

   return;
}

F77_SUBROUTINE(ndf_exist)( CHARACTER(param),
                           CHARACTER(mode),
                           INTEGER(indf),
                           INTEGER(status)
                           TRAIL(param)
                           TRAIL(mode) );

void ndfExist( const char *param,
               const char *mode,
               int *indf,
               int *status ) {

DECLARE_CHARACTER_DYN(fparam);
DECLARE_CHARACTER_DYN(fmode);
DECLARE_INTEGER(findf);
DECLARE_INTEGER(fstatus);

   F77_CREATE_CHARACTER( fparam, strlen( param ) );
   fix_F77_EXPORT_CHARACTER( param, fparam, fparam_length );
   F77_CREATE_CHARACTER( fmode, strlen( mode ) );
   fix_F77_EXPORT_CHARACTER( mode, fmode, fmode_length );
   F77_EXPORT_INTEGER( *status, fstatus );

   F77_CALL(ndf_exist)( CHARACTER_ARG(fparam),
                        CHARACTER_ARG(fmode),
                        INTEGER_ARG(&findf),
                        INTEGER_ARG(&fstatus)
                        TRAIL_ARG(fparam)
                        TRAIL_ARG(fmode) );

   F77_FREE_CHARACTER( fparam );
   F77_FREE_CHARACTER( fmode );
   F77_IMPORT_INTEGER( findf, *indf );
   F77_IMPORT_INTEGER( fstatus, *status );

   return;
}

F77_SUBROUTINE(ndf_prop)( INTEGER(indf1),
                          CHARACTER(clist),
                          CHARACTER(param),
                          INTEGER(indf2),
                          INTEGER(status)
                          TRAIL(clist)
                          TRAIL(param) );

void ndfProp( int indf1,
              const char *clist,
              const char *param,
              int *indf2,
              int *status ) {

DECLARE_INTEGER(findf1);
DECLARE_CHARACTER_DYN(fclist);
DECLARE_CHARACTER_DYN(fparam);
DECLARE_INTEGER(findf2);
DECLARE_INTEGER(fstatus);

   F77_EXPORT_INTEGER( indf1, findf1 );
   F77_CREATE_CHARACTER( fclist, strlen( clist ) );
   fix_F77_EXPORT_CHARACTER( clist, fclist, fclist_length );
   F77_CREATE_CHARACTER( fparam, strlen( param ) );
   fix_F77_EXPORT_CHARACTER( param, fparam, fparam_length );
   F77_EXPORT_INTEGER( *status, fstatus );

   F77_CALL(ndf_prop)( INTEGER_ARG(&findf1),
                       CHARACTER_ARG(fclist),
                       CHARACTER_ARG(fparam),
                       INTEGER_ARG(&findf2),
                       INTEGER_ARG(&fstatus)
                       TRAIL_ARG(fclist)
                       TRAIL_ARG(fparam) );

   F77_FREE_CHARACTER( fclist );
   F77_FREE_CHARACTER( fparam );
   F77_IMPORT_INTEGER( findf2, *indf2 );
   F77_IMPORT_INTEGER( fstatus, *status );

   return;
}
