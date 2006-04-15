/*
 *+
 *  Name:
 *     hdrInL
 
 *  Purpose:
 *     Reads "logical" header items.
 
 *  Language:
 *     ANSI C
 
 *  Invocation:
 *     hdrInL( param,
 *             xname,
 *             item,
 *             comp,
 *             value,
 *             status )
 
 *  Description:
 *     This C function sets up the required arguments and calls the
 *     Fortran subroutine hdr_inl.
 *     On return, values are converted back to C form if necessary.
 
 *  Arguments:
 *     param = char * (Given)
 *        Parameter name of the image (case insensitive).
 *     xname = char * (Given)
 *        Name of the extension ('FITS' or ' ' for FITS headers).
 *     item = char * (Given)
 *        Name of the header item.
 *     comp = int  (Given)
 *        The component of a multiple FITS header item ('HISTORY' and
 *        'COMMENT' items often have many occurrences). The number of
 *        components may be queried using the HDR_NUMB routine.
 *     value[] = int (Given and Returned)
 *        The values. These are  unmodified if the item doesn't exist.
 *     status = int * (Given and Returned)
 *        The global status.
 
*  Copyright:
*     Copyright (C) 1996 Central Laboratory of the Research Councils.
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
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

 *  Authors:
 *     The orginal version was generated automatically from the
 *     Fortran source of hdr_inl by the Perl script fcwrap.
 *     PDRAPER: Peter W. Draper (STARLINK - Durham University)
 *     {enter_new_authors_here}
 
 *  History:
 *     17-May-1996 (fcwrap):
 *        Original version
 *     22-May-1996 (PDRAPER):
 *        Converted to return an array of values.
 *     {enter_changes_here}
 
 *-
 */
#include <string.h>
#include <stdlib.h>
#include "cnf.h"
#include "f77.h"
#include "img1.h"
#include "sae_par.h"

F77_SUBROUTINE(hdr_inl)( CHARACTER(param),
                         CHARACTER(xname),
                         CHARACTER(item),
                         INTEGER(comp),
                         LOGICAL_ARRAY(value),
                         INTEGER(status)
                         TRAIL(param)
                         TRAIL(xname)
                         TRAIL(item) );

void hdrInL( char *param,
             char *xname,
             char *item,
             int comp,
             int *value,
             int *status ) {
  
  DECLARE_CHARACTER_DYN(fparam);
  DECLARE_CHARACTER_DYN(fxname);
  DECLARE_CHARACTER_DYN(fitem);
  F77_LOGICAL_TYPE *fvalue;
  int i;
  int nparam;


  /*  Count the number of parameters and create a Fortran logical
      array of the correct size */
  nparam = img1CountParams( param, status );
  fvalue = (F77_LOGICAL_TYPE *) malloc( nparam * sizeof(F77_LOGICAL_TYPE) );
  
  F77_CREATE_CHARACTER(fparam,strlen( param ));
  cnf_exprt( param, fparam, fparam_length );
  F77_CREATE_CHARACTER(fxname,strlen( xname ));
  cnf_exprt( xname, fxname, fxname_length );
  F77_CREATE_CHARACTER(fitem,strlen( item ));
  cnf_exprt( item, fitem, fitem_length );

  F77_CALL(hdr_inl)( CHARACTER_ARG(fparam),
                     CHARACTER_ARG(fxname),
                     CHARACTER_ARG(fitem),
                     INTEGER_ARG(&comp),
                     LOGICAL_ARRAY_ARG(fvalue),
                     INTEGER_ARG(status)
                     TRAIL_ARG(fparam)
                     TRAIL_ARG(fxname)
                     TRAIL_ARG(fitem) );
  
  F77_FREE_CHARACTER(fparam);
  F77_FREE_CHARACTER(fxname);
  F77_FREE_CHARACTER(fitem);
  
  /*  Convert the return values into C logical values */
  if ( *status == SAI__OK ) {
    for ( i = 0; i < nparam; i++ ) {
        if ( F77_ISFALSE( fvalue[i] ) ) { 
        value[i] = 0;
      } else {
        value[i] = 1;
      }
    }
  }
  free( fvalue );
  
  return;
}

/* $Id$ */
