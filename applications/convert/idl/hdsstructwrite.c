/*+
* Name:
*    hdsstructwrite

*  Purpose:
*     To write an IDL structure to an HDS file with a corresponding structure

*  Language:
*     C

*  Invocation:
*     Call from C
*     int hdsstructwrite( char *toploc, char *data, char **taglist, 
*                     int numtags, int ndims, int dims[],
*                     IDL_VPTR var, int *status )

*  Arguments:
*     toploc = char * (Given)
*        An HDS locator to an HDS structure component in which the new
*        component is to be created.
*     data = char * (Given)
*        pointer to the data area for the IDL structure
*     taglist = cahr ** (Given)
*        pointer to list of tagnames for the IDL structure
*     numtags = int (Given)
*        The number of tags in the IDL structure
*     ndims = int (Given)
*        The number of dimensions
*     dims = int * (Given)
*        The dimensions
*     var = IDL_VPTR (Given)
*        Variable containing data description
*     status = int * (Given and Returned)
*        The Starlink global status

*  Description:

*  Pitfalls:
*     [pitfall_description]...

*  Notes:
*     -  {noted_item}
*     [routine_notes]...

*  External Routines Used:
*     SAE
*        sae_par.h
*     HDS
*        hds.h
*        datVec
*        datCell
*        datAnnul
*        datNew
*        datFind

*  Implementation Deficiencies:
*     -  {deficiency}
*     [routine_deficiencies]...

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils

*  Authors:
*     AJC: A.J.Chipperfield (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*      12-OCT-1999 (AJC):
*        Original version.
*      25-FEB-2000 (AJC):
*        Extend long, integer or byte named LOGICAL_X -> _LOGICAL
*     {enter_further_changes_here}

*  Bugs:
*     -  {description_of_bug}
*     {note_new_bugs_here}
*-
*/
#include <stdio.h>
#include "export.h"
#include "sae_par.h"
#include "hds.h"

void getobjectdetails( IDL_VPTR var, void *data, char **taglist,
                    char hdstype[], int *numtags,
                    int *ndims, int dims[], int *elt_len, int *status );

char** tagstrip( char *prefix, char** taglist );

void hdsprimwrite( char *toploc, char *hdstype, int ndims, int dims[],
                    void *data, int *status );

void hdsstructwrite( char *toploc, char *data, char **taglist, int numtags,
                     int ndims, int dims[],
                     IDL_VPTR var, int *status ) {

IDL_StructDefPtr sdef;
IDL_VPTR cmpvar;
IDL_LONG offset;
char *tagname;
int tagno;
int cellno;
int starttag;                  /* 1 if first tag is HDSSTRUCTYPE */

/* values pertaining to the structure component */
int cmpnumtags;                /* No of tags */
int cmpndims;                  /* No. of dimensions */
int cmpdims[DAT__MXDIM];       /* Dimensions */
char objhdstype[DAT__SZTYP+1];
char cmphdstype[DAT__SZTYP+1];
char cmploc[DAT__SZLOC+1];
char vecloc[DAT__SZLOC+1];
char **cmptaglist;
char *cmpdata;
int cmpelt_len;

      if ( *status != SAI__OK ) return;
      sdef = var->value.s.sdef;

/* If it's a structure array, vectorise it */
      if ( ndims ) idlDatVec( toploc, vecloc, status );

/* If OK do for each tag */
      if ( *status == SAI__OK ) {

         starttag = strcmp(taglist[0],"HDSSTRUCTYPE")?0:1;
         cellno = 1;
         for (tagno=starttag;tagno<numtags;tagno++) {

/*    Get the tagname */
            tagname = taglist[tagno];

/*    Get the tag info */
            offset = IDL_StructTagInfoByIndex( 
               sdef, tagno, IDL_MSG_LONGJMP, &cmpvar );
            cmpdata = data + offset;

            cmptaglist = tagstrip( tagname, taglist );

/*    Get the sub-object details, create the required HDS object and fill it */
            getobjectdetails( cmpvar, cmpdata, cmptaglist, objhdstype, 
               &cmpnumtags, &cmpndims, cmpdims, &cmpelt_len, status );

/*    Set the HDS component type - */
/*    if the tagname starts 'LOGICAL_', make any integer type as _LOGICAL. */
            strcpy( cmphdstype, objhdstype );
            if ( !strncmp( tagname, "LOGICAL_", 8 ) ) {
               if ( !strcmp( objhdstype, "_UBYTE" ) ||
                    !strcmp( objhdstype, "_WORD" ) ||
                    !strcmp( objhdstype, "_INTEGER" ) ) {
                  strcpy( cmphdstype, "_LOGICAL" );
                  tagname = taglist[tagno]+8;
               }
            }

/* Get the new HDS object */
/* If we have a structure array, don't create a new HDS component but */
/* locate the next cell */
            if ( ndims ) {
               idlDatCell( vecloc, 1, &cellno, cmploc, status );
               cellno++;
            } else {
               idlDatNew( 
                  toploc, tagname, cmphdstype, cmpndims, cmpdims, status );
               idlDatFind( toploc, tagname, cmploc, status );
            }

/* Now fill the new object */
/* Non-zero cmpnumtags means the component is a structure */
            if ( cmpnumtags ) {
/*    We have a sub structure */
               hdsstructwrite( cmploc, cmpdata, cmptaglist,
                 cmpnumtags, cmpndims, cmpdims, cmpvar, status );

            } else {
/*    We have a primitive */
               hdsprimwrite( cmploc, objhdstype, cmpndims, cmpdims, cmpdata, 
                 status );
            }

/*    Clean up for this component */
            free( cmptaglist );
            idlDatAnnul( cmploc, status );

         } /* end for each tag */

/* Annul vecloc if it was obtained */
         if ( ndims ) idlDatAnnul( vecloc, status );

      } /* end top locator got OK */

      return;
}
