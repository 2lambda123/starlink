/*
 *  Name:
 *     imgInGen

 *  Purpose:
 *     Obtains access to an input image using a specific type.

 *  Language:
 *     ANSI C

 *  Invocation:
 *     imgIn?( param, nx, ny, ip, status )

 *  Description:
 *     This C function sets up the required arguments and calls the
 *     Fortran subroutine img_in[x].
 *     On return, values are converted back to C form if necessary.
 *
 *     This version is the generic form for the float, double, int,
 *     short, unsigned short, char and unsigned char versions. Just
 *     include this in the appropriate stub after setting the 
 *     values of the macros:
 *
 *        IMG_F77_TYPE   = (r|d|l|i|w|uw|b|ub)
 *        IMG_FULL_C_TYPE   = (float|double|short etc.)
 *        IMG_SHORT_C_TYPE   = (F|D|I|S|US|B|UB)
 *
 *     The IMG_F77_TYPE essentially names the fortran version of this
 *     routine to invoke.

 *  Arguments:
 *     param = char * (Given)
 *        Parameter name (case insensitive).
 *     nx = int * (Returned)
 *        Size of the first dimension of the image (in pixels).
 *     ny = int * (Returned)
 *        Size of the second dimension of the image (in pixels).
 *     ip = ? ** (Returned)
 *        Pointer to the image data.
 *     status = int * (Given and Returned)
 *        The global status.

 *  Authors:
 *     The orginal version was generated automatically from the
 *     Fortran source of img_inr by the Perl script fcwrap.
 *     PDRAPER: Peter W. Draper (STARLINK - Durham University)
 *     {enter_new_authors_here}

 *  History:
 *     17-May-1996 (fcwrap):
 *        Original version
 *     24-May-1996 (PDRAPER):
 *        Added code to handle pointer arrays correctly. Made into
 *        generic include file. 
 *     10-JUN-1996 (PDRAPER):
 *        Converted to use more C-like names:
 *     21-APR-1999 (PDRAPER):
 *        Changed to export pointer array using CNF macros (64 bit
 *        changes).
 *     {enter_changes_here}

 *-
 */


IMG_IN( IMG_F77_TYPE ) ( CHARACTER(param),
                         INTEGER(nx),
                         INTEGER(ny),
                         POINTER_ARRAY(ip),
                         INTEGER(status)
                         TRAIL(param) );

IMGIN( IMG_SHORT_C_TYPE ) ( char *param,
                            int *nx,
                            int *ny,
                            IMG_FULL_C_TYPE **ip,
                            int *status ) 
{
  DECLARE_CHARACTER_DYN( fparam );
  DECLARE_POINTER_ARRAY_DYN( fip );
  int nparam;
  
  F77_CREATE_CHARACTER( fparam, strlen( param ) );
  F77_EXPORT_CHARACTER( param, fparam, fparam_length );
  
  /*  Count the number of input parameters and create enough space for
      the corresponding Fortran pointers */
  nparam = img1CountParams( param, status );
  F77_CREATE_POINTER_ARRAY( fip, nparam );
  F77_ASSOC_POINTER_ARRAY( fip, ip );

  IMGIN_CALL( IMG_F77_TYPE ) ( CHARACTER_ARG(fparam),
                               INTEGER_ARG(nx),
                               INTEGER_ARG(ny),
                               POINTER_ARRAY_ARG(fip),
                               INTEGER_ARG(status)
                               TRAIL_ARG(fparam) );
  
  /*  Now copy the addresses back to to C pointers */
  F77_IMPORT_POINTER_ARRAY( fip, ip, nparam );

  F77_FREE_POINTER( fip );
  F77_FREE_CHARACTER( fparam );

  return;
}
/* $Id$ */
