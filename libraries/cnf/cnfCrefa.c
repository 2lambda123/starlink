#include <stdlib.h>		 /* Standard C run-time library		    */
#include "f77.h"                 /* CNF macros and prototypes               */

F77_CHARACTER_ARG_TYPE *cnfCrefa( int length, int ndims, const int *dims )

/*
*+
*  Name:
*     cnfCrefa

*  Purpose:
*     Create a Fortran CHARACTER array and return a pointer to it.

*  Language:
*     ANSI C

*  Invocation:
*     pointer = cnfCrefa( length, ndims, dims )

*  Description:
*     Create a temporary Fortran CHARACTER arry and return a pointer to it.
*     The space allocated is sufficient to contain an array with the given
*     dimensions, of strings "length" characters long. The strings are not 
*     initialised.
*     

*  Arguments:
*     int length (Given)
*        The maximum length of the strings in characters.
*     int ndims (Given)
*        The number of dimensions
*     const int *dims (Given)
*        A pointer to the dimensions

*  Returned Value:
*     F77_CHARACTER_ARG_TYPE *cnfCrefa
*        A pointer to the storage that has been allocated by this routine.

*  Notes:
*     -  The pointer may not point directly at the string of characters.
*        It is the thing required to be passed with the CHARACTER_ARRAY_ARG
*        macro to a Fortran routine.
*     -  If the routine could not create the space, then it returns a
*        null pointer.

*  Copyright:
*     Copyright (C) 1996 CCLRC

*  Authors:
*     AJC: Alan Chipperfield (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     22-MAY-1996 (AJC):
*        Original version.
*     24-SEP-1998 (AJC):
*        Specify const int * for dimensions
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*...........................................................................*/

{
/* Local Variables:							    */
   int size;         /* Space required */
   int i;            /* Loop counter */                         

/* Find the space required                                                  */
   size = length; 
   for ( i=0; i<ndims; i++ ) size *= *(dims+i);

/* Allocate the space and return a pointer to it			    */
   return (F77_CHARACTER_ARG_TYPE *)malloc( (size_t)( size ) );

}

