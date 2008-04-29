#include "star/hds.h"
#include "star/atl.h"
#include "ast.h"
#include "mers.h"
#include "sae_par.h"

void kpg1Ky2hd( AstKeyMap *keymap, HDSLoc *loc, int *status ){
/*
*  Name:
*     kpg1Ky2hd

*  Purpose:
*     Copy values from an AST KeyMap to a primitive HDS object.

*  Language:
*     C.

*  Invocation:
*     void kpg1Ky2hd( AstKeyMap *keymap, HDSLoc *loc, int *status )

*  Description:
*     This routine copies the contents of an AST KeyMap into a supplied 
*     HDS structure.

*  Arguments:
*     keymap 
*        An AST pointer to the KeyMap.
*     loc 
*        A locator for the HDS object into which the KeyMap contents
*        are to be copied.
*     status 
*        The inherited status.

*  Copyright:
*     Copyright (C) 2008 Science & Technology Facilities Council.
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
*     DSB: David S. Berry
*     {enter_new_authors_here}

*  History:
*     29-APR-2008 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}
*/

/* Local Varianles: */
   AstObject **objArray = NULL;
   AstObject *obj = NULL;
   HDSLoc *cloc = NULL;
   HDSLoc *dloc = NULL;
   const char *cval = NULL;
   const char *key;
   double dval;
   float fval;
   int i;
   int ival;
   int j;
   int lenc;
   int nval;
   int size;
   int type;
   int veclen;
   size_t el;
   void *pntr = NULL;

/* Check inherited status */
   if( *status != SAI__OK ) return;

/* Loop round each entry in the KeyMap. */
   size = astMapSize( keymap );
   for( i = 0; i < size; i++ ) {

/*  Get the key. the data type and the vector length for the current 
   KeyMap entry. */
      key = astMapKey( keymap, i );
      type = astMapType( keymap, key );
      veclen = astMapLength( keymap, key );

/* If the current entry holds one or more nested KeyMaps, then we call
   this function recursively to add them into a new HDS component. */
      if( type == AST__OBJECTTYPE ) {

/* First deal with scalar entries holding a single KeyMap. */
         if( veclen == 1 ) {
            datNew( loc, key, "KEYMAP_ENTRY", 0, NULL, status );
            datFind( loc, key, &cloc, status );

            (void) astMapGet0A( keymap, key, &obj );

            if( astIsAKeyMap( obj ) ) {
               kpg1Ky2hd( (AstKeyMap *) obj, cloc, status );

            } else if( *status == SAI__OK ) {
               *status = SAI__ERROR;
               errRep( "", "kpg1Ky2hd: Supplied KeyMap contains unusable AST "
                       "objects (programming error).", status );
            }

            datAnnul( &cloc, status );
         
/* Now deal with vector entries holding multiple KeyMaps. */
         } else {
            datNew( loc, key, "KEYMAP_ENTRY", 1, &veclen, status );
            datFind( loc, key, &cloc, status );

            objArray = astMalloc( sizeof( AstObject *) * (size_t)veclen );
            if( objArray ) {
               (void) astMapGet1A( keymap, key, veclen, &nval, objArray );

               for( j = 1; j <= veclen; j++ ) {                  
                  datCell( cloc, 1, &j, &dloc, status );

                  if( astIsAKeyMap( objArray[ j - 1 ] ) ) {
                     kpg1Ky2hd( (AstKeyMap *) objArray[ j - 1 ], dloc, status );

                  } else if( *status == SAI__OK ) {
                     *status = SAI__ERROR;
                     errRep( "", "kpg1Ky2hd: Supplied KeyMap contains unusable AST "
                             "objects (programming error).", status );
                  }

                  datAnnul( &dloc, status );
               }

               objArray = astFree( objArray );
            }

            datAnnul( &cloc, status );
         }

/* For primitive types... */
      } else if( type == AST__INTTYPE ){
         if( veclen == 1 ) {
            datNew0I( loc, key, status );
            datFind( loc, key, &cloc, status );
            (void) astMapGet0I( keymap, key, &ival );
            datPut0I( cloc, ival, status );
            datAnnul( &cloc, status );
         
         } else {
            datNew1I( loc, key, veclen, status );
            datFind( loc, key, &cloc, status );
            datMapV( cloc, "_INTEGER", "WRITE", &pntr, &el, status );
            (void) astMapGet1I( keymap, key, veclen, &nval, (int *) pntr );
            datUnmap( cloc, status );
            datAnnul( &cloc, status );
         }


      } else if( type == AST__DOUBLETYPE ){
         if( veclen == 1 ) {
            datNew0D( loc, key, status );
            datFind( loc, key, &cloc, status );
            (void) astMapGet0D( keymap, key, &dval );
            datPut0D( cloc, dval, status );
            datAnnul( &cloc, status );
         
         } else {
            datNew1D( loc, key, veclen, status );
            datFind( loc, key, &cloc, status );
            datMapV( cloc, "_DOUBLE", "WRITE", &pntr, &el, status );
            (void) astMapGet1D( keymap, key, veclen, &nval, (double *) pntr );
            datUnmap( cloc, status );
            datAnnul( &cloc, status );
         }

      } else if( type == AST__FLOATTYPE ){
         if( veclen == 1 ) {
            datNew0R( loc, key, status );
            datFind( loc, key, &cloc, status );
            (void) astMapGet0F( keymap, key, &fval );
            datPut0R( cloc, fval, status );
            datAnnul( &cloc, status );
         
         } else {
            datNew1R( loc, key, veclen, status );
            datFind( loc, key, &cloc, status );
            datMapV( cloc, "_REAL", "WRITE", &pntr, &el, status );
            (void) astMapGet1F( keymap, key, veclen, &nval, (float *) pntr );
            datUnmap( cloc, status );
            datAnnul( &cloc, status );
         }

      } else if( type == AST__STRINGTYPE ){
         lenc = astMapLenC( keymap, key );

         if( veclen == 1 ) {
            datNew0C( loc, key, lenc, status );
            datFind( loc, key, &cloc, status );
            (void) astMapGet0C( keymap, key, &cval );
            datPut0C( cloc, cval, status );
            datAnnul( &cloc, status );
         
         } else {
            datNew1C( loc, key, lenc, veclen, status );
            datFind( loc, key, &cloc, status );
            datMapV( cloc, "_REAL", "WRITE", &pntr, &el, status );
            (void) atlMapGet1S( keymap, key, veclen*lenc, lenc, &nval,
                                (char *) pntr, status );
            datUnmap( cloc, status );
            datAnnul( &cloc, status );
         }

      } else if( *status == SAI__OK ) {
         *status = SAI__ERROR;
         msgSeti( "T", type );
         errRep( "", "kpg1Ky2hd: Supplied KeyMap contains entries with "
                 "unusable data type (^T) (programming error).", status );
      }
   }
}



