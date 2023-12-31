#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "ast.h"
#include "f77.h"
#include "sae_par.h"
#include "mers.h"
#include "star/one.h"
#include <tcl.h>
#include <tk.h>

static FILE *fd = NULL;

static char *Envir( const char *, int * );
static void SetVar( Tcl_Interp *, char *, char *, int, int * );
static const char *GetVar( Tcl_Interp *, char *, int, int * );
static void SetSVar( Tcl_Interp *, const char *, const char *, int, int * );
static void GetSVar( Tcl_Interp *, const char *, char *, int, int * );
static void SetIVar( Tcl_Interp *, const char *, int, int * );
static void SetRVar( Tcl_Interp *, const char *, float, int * );
static void SetLVar( Tcl_Interp *, const char *, LOGICAL(a), int * );
static void GetLVar( Tcl_Interp *, const char *, LOGICAL(a), int * );
static void GetIVar( Tcl_Interp *, const char *, int *, int * );
static void GetRVar( Tcl_Interp *, const char *, float *, int * );
static void sink( const char * );

F77_SUBROUTINE(kps1_tkast)( INTEGER(IAST), CHARACTER(TITLE),
                            INTEGER(FULL), CHARACTER(PNAME), INTEGER(STATUS)
                            TRAIL(TITLE) TRAIL(PNAME) ){
/*
*+
*  Name:
*     KPS1_TKAST

*  Purpose:
*     Displays an AST Object using a Tk interface.

*  Language:
*     Starlink C

*  Description:
*     This C function creates a Tcl interpreter to execute the Tcl script
*     which implements the GUI for the TK AST browser.

*  Parameters:
*     IAST = INTEGER (Given)
*        AST Pointer to the Object to be displayed.
*     TITLE = CHARACTER * ( * ) (Given)
*        A text string to display with the Object.
*     FULL = INTEGER (Given)
*        The value to use for the AST "Full" attribute when displaying
*        the Object.
*     PNAME = CHARACTER * ( * ) (Given)
*        The file name of the executable program currently running.
*        Required for Tcl initialisation.
*     STATUS = INTEGER (Given and Returned)
*        The inherited global status.

*  Copyright:
*     Copyright (C) 1997, 2002, 2004 Central Laboratory of the Research Councils.
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     DSB: David Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     PWD: Peter W. Draper (JAC, Durham University)
*     {enter_new_authors_here}

*  History:
*     4-MAR-1997 (DSB):
*        Original version.
*     3-JUL-2002 (DSB):
*        Replaced use of tmpnam with mkstemp.
*     2-SEP-2004 (TIMJ):
*        Use sae_par.h for good/bad status
*     4-OCT-2004 (DSB):
*        Renamed from kpg1_tkast to kps1_tkast and moved from kaplibs to
*        kappa.
*     4-OCT-2004 (TIMJ):
*        Fix compiler warnings
*     3-APR-2008 (PWD):
*        Added PNAME argument and call to Tcl_FindExecutable.
*        Removed dead support for Tk 4.0.
*     12-MAY-2011 (TIMJ):
*        Use errRepf natively rather than F77_CALL(err_rep)
*     {enter_further_changes_here}

*-
*/

   GENPTR_INTEGER(IAST)
   GENPTR_CHARACTER(TITLE)
   GENPTR_INTEGER(FULL)
   GENPTR_CHARACTER(PNAME)
   GENPTR_INTEGER(STATUS)

   AstChannel *chan;
   Tcl_Interp *interp = NULL;
   char fname[ 255 ];
   char script[1024];
   int ifd;

/* Check the global status. */
   if( *STATUS != SAI__OK ) return;

/* Set the executable name. Required if we want Tcl to locate itself
   without a TCL_LIBRARY definition. Usually argv[0]. */
   if ( strlen( PNAME ) > 0 ) {
       Tcl_FindExecutable( PNAME );
   }

/* Get a unique temporary file name. This file is used to store the object
   dumps. All this complication is needed
   to avoid the warning message generated by the linker on RH 7 Linux
   resulting from the use of the simpler "tmpnam" function. */
   one_strlcpy( fname, "tkastXXXXXX", sizeof(fname), STATUS );
   ifd = mkstemp( fname );
   if( ifd == -1 ){
      *STATUS = SAI__ERROR;
      errRep( "", "Unable to create a temporary \"tkast\" file name.",
              STATUS );
      return;
   } else {
      close( ifd );
      remove( fname );
   }

/* Open the temporary text file. */
   fd = fopen( fname, "w" );
   if( fd ){

/* Create a Channel through which the AST Objects can be written out. */
      chan = astChannel( NULL, sink, "comment=1" );
      astSetI( chan, "full", *FULL );

/* Dump the object. */
      astWrite( chan, astI2P( *IAST ) );

/* Annul the channel, and close the file. */
      chan = astAnnul( chan );
      fclose( fd );
      fd = NULL;

/* Report an error if anything went wrong in AST. */
      if( !astOK ) {
         *STATUS = SAI__ERROR;
         errRep( "", "An error has been reported by the AST library.", STATUS );

/* Otherwise, create a TCL interpreter. */
      } else {
         interp = Tcl_CreateInterp();
      }

/* Store the name of the temprary file in Tcl variable "FILE". */
      SetVar( interp, "FILE", fname, TCL_LEAVE_ERR_MSG, STATUS );

/* Store the supplied title string in Tcl variable TITLE. */
      SetSVar( interp, "TITLE", TITLE, TITLE_length, STATUS );

/* Initialise Tcl and Tk commands. */
      if( *STATUS == SAI__OK ) {

         if( Tcl_Init( interp ) != TCL_OK ) {
            *STATUS = SAI__ERROR;
            errRep("", "Failed to initialise Tcl commands.", STATUS );
            errRepf( "", "%s", STATUS, Tcl_GetStringResult(interp) );
         } else if( Tk_Init( interp ) != TCL_OK ) {
            *STATUS = SAI__ERROR;
            errRep( "", "Failed to initialise Tk commands.", STATUS );
            errRepf( "", "%s", STATUS, Tcl_GetStringResult(interp) );
         }
      }

/* Execute the TCL script. This should be $KAPPA_DIR/tkast.tcl */
      one_strlcpy( script, Envir( "KAPPA_DIR", STATUS ), sizeof(script), STATUS );
      if( *STATUS == SAI__OK ){
        one_strlcat( script, "/tkast.tcl", sizeof(script), STATUS );

         if( Tcl_EvalFile( interp, script ) != TCL_OK ){
            *STATUS = SAI__ERROR;
            errRep( "", "Failed to execute the TCL script...", STATUS );
            errRepf( "", "%s", STATUS, Tcl_GetStringResult(interp) );

/* If succesfull, loop infinitely, waiting for commands to execute.  When
   there are no windows left, the loop exits. NOTE, it seems that an
   "exit" command in the tcl script causes the current process to be
   killed. In order to shutdown the script and return control to this
   procedure, use "destroy ." in the script instead of "exit". */
         } else {
            Tk_MainLoop();
         }
      }

/* Delete the TCL interpreter. */
      if( interp && *STATUS == SAI__OK ) Tcl_DeleteInterp( interp );

/* Remove the temporary file. */
      remove( fname );

/* Report an error if the temporary file could not be opened. */
   } else {
      *STATUS = SAI__ERROR;
      errRep( "", "File to open temporary text file to hold dumps of AST Objects.", STATUS );
   }

}


static char *Envir( const char *var, int *STATUS ){
/*
*+
*  Name:
*     Envir

*  Purpose:
*     Get an environment variable.

*  Language:
*     Starlink C

*  Description:
*     A pointer to the a string holding the value of the specified
*     environment variable is returned. A NULL pointer is returned an an
*     error is reported if the variable does not exist.

*  Parameters:
*     var
*        The variable name.
*     STATUS
*        A pointer to the global status value.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/
   char *ret;

   if( *STATUS != SAI__OK || !var ) return NULL;

   ret = getenv( var );
   if( !ret ) {
      *STATUS = SAI__ERROR;
      errRepf( "",  "Failed to get environment variable \"%s\".", STATUS,
               var );
   }

   return ret;
}

static void SetVar( Tcl_Interp *interp,  char *name,  char *value,
             int flags, int *STATUS ){
/*
*+
*  Name:
*     SetVar

*  Purpose:
*     Sets a Tcl variable.

*  Language:
*     Starlink C

*  Description:
*     This is equivalent to the Tcl function Tcl_SetVar, except that
*     it checks the global status before executing, and reports an error
*     if anything goes wrong.

*  Parameters:
*     As for Tcl_SetVar, except for addition of final STATUS argument.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   if( *STATUS != SAI__OK ) return;

   if( !Tcl_SetVar( interp, name, value, flags) ){
      *STATUS = SAI__ERROR;
      errRepf( "", "Error setting TCL variable \"%s\".", STATUS, name );
      errRepf( "", "%s", STATUS, Tcl_GetStringResult(interp) );
   }
}

static const char *GetVar( Tcl_Interp *interp,  char *name,  int flags, int *STATUS ){
/*
*+
*  Name:
*     GetVar

*  Purpose:
*     Gets a Tcl variable.

*  Language:
*     Starlink C

*  Description:
*     This is equivalent to the Tcl function Tcl_GetVar, except that
*     it checks the global status before executing, and reports an error
*     if anything goes wrong.

*  Parameters:
*     As for Tcl_GetVar, except for addition of final STATUS argument.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   const char *ret;

   if( *STATUS != SAI__OK ) return NULL;

   ret = Tcl_GetVar( interp, name, flags );
   if ( !ret ) {
      *STATUS = SAI__ERROR;
      errRepf( "", "Error getting TCL variable \"%s\".", STATUS, name );
      errRepf( "", "%s", STATUS, Tcl_GetStringResult(interp) );
   }

   return ret;

}

static void SetSVar( Tcl_Interp *interp, const char *var, const char *string,
               int len, int *STATUS ) {
/*
*+
*  Name:
*     SetSVar

*  Purpose:
*     Store an F77 string in a Tcl variable.

*  Language:
*     Starlink C

*  Description:
*     This function stores the supplied F77 string in the specified Tcl
*     variable, appending a trailing null character.

*  Parameters:
*     interp = Tcl_Interp * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     string = const char * (Given)
*        The string to store.
*     len = int (Given)
*        The length of the string to be stored, excluding any trailing
*        null.
*     STATUS = int * (Given and Returned)
*        The inherited status.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   char *buf;

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Allocate memory to hold a null-terminated copy of the supplied F77
   string. */
   buf = astMalloc ( sizeof(*buf)*(size_t) ( len + 1 ) );

/* If successful, copy the string, and append a trailing null character. */
   if ( buf ) {
      memcpy( buf, string, len );
      buf[ len ] = 0;

/* Set the Tcl variable value. */
      SetVar( interp, (char *) var, buf, TCL_LEAVE_ERR_MSG, STATUS );

/* Free the memory. */
      astFree( buf );

/* Report an error if the memory could not be allocated. */
   } else {
      *STATUS = SAI__ERROR;
      errRepf("", "Unable to allocate %d bytes of memory. ", STATUS, len + 1 );
      errRepf("", "Failed to initialise Tcl variable \"%s\".", STATUS, var );
   }

}

static void GetSVar( Tcl_Interp *interp, const char *var, char *string,
              int len, int *STATUS ) {
/*
*+
*  Name:
*     GetSVar

*  Purpose:
*     Get an F77 string from a Tcl variable.

*  Language:
*     Starlink C

*  Description:
*     This function gets a string from the specified Tcl
*     variable, and stores it in the supplied F77 character variable.

*  Parameters:
*     interp = Tcl_Interp * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     string = char * (Returned)
*        The F77 string to receive the value.
*     len = int (Given)
*        The length of the F77 string.
*     STATUS = int * (Given and Returned)
*        The inherited status.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   const char *tp;
   int n;
   int i;

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Get a pointer to the null-terminated string Tcl variable value. */
   tp = GetVar( interp, (char *) var, TCL_LEAVE_ERR_MSG, STATUS );

/* If succesful, initialise the returned F77 string to hold blanks, and
   then copy the required number of characters form the Tcl variable
   string. */
   if ( tp ) {
      for( i = 0; i < len; i++ ) string[ i ] = ' ';
      n = strlen( tp );
      if( len < n ) n = len;
      memcpy( string, tp, n );
   }

}

static void SetIVar( Tcl_Interp *interp, const char *var, int val, int *STATUS ) {
/*
*+
*  Name:
*     SetIVar

*  Purpose:
*     Store an integer in a Tcl variable.

*  Language:
*     Starlink C

*  Description:
*     This function stores the integer in the specified Tcl variable.

*  Parameters:
*     interp = Tcl_Interp * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     val = int (Given)
*        The value to store.
*     STATUS = int * (Given and Returned)
*        The inherited status.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   char text[80];

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Format the integer value and store the resulting string in the
   Tcl variable. */
   sprintf( text, "%d", val );
   SetVar( interp, (char *) var, text, TCL_LEAVE_ERR_MSG, STATUS );

}

static void SetRVar( Tcl_Interp *interp, const char *var, float val, int *STATUS ) {
/*
*+
*  Name:
*     SetRVar

*  Purpose:
*     Store a floating point value in a Tcl variable.

*  Language:
*     Starlink C

*  Description:
*     This function stores the supplied value in the specified Tcl variable.

*  Parameters:
*     interp = Tcl_Interp * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     val = float (Given)
*        The value to store.
*     STATUS = int * (Given and Returned)
*        The inherited status.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   char text[80];

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Format the value and store the resulting string in the Tcl variable. */
   sprintf( text, "%g", val );
   SetVar( interp, (char *) var, text, TCL_LEAVE_ERR_MSG, STATUS );

}

static void SetLVar( Tcl_Interp *interp, const char *var, LOGICAL(valptr), int *STATUS ) {
/*
*+
*  Name:
*     SetLVar

*  Purpose:
*     Store an F77 LOGICAL value in a Tcl variable.

*  Language:
*     Starlink C

*  Description:
*     This function stores the supplied value in the specified Tcl variable.

*  Parameters:
*     interp = Tcl_Interp * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     valptr = LOGICAL (Given)
*        A pointer to the value to store.
*     STATUS = int * (Given and Returned)
*        The inherited status.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   GENPTR_LOGICAL(val)

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Store the value. */
   SetVar( interp, (char *) var, ( F77_ISTRUE(*valptr) ? "1" : "0" ),
           TCL_LEAVE_ERR_MSG, STATUS );

}

static void GetLVar( Tcl_Interp *interp, const char *var, LOGICAL(valptr), int *STATUS ) {
/*
*+
*  Name:
*     GetLVar

*  Purpose:
*     Retrieve a Tcl variable value and store it in an F77 LOGICAL
*     variable.

*  Language:
*     Starlink C

*  Parameters:
*     interp = Tcl_Interp * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     valptr = LOGICAL (Returned)
*        A pointer to the F77 variable to receive the returned value.
*     STATUS = int * (Given and Returned)
*        The inherited status.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   GENPTR_LOGICAL(val)
   const char *tp;

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Get a pointer to the text string holding the Tcl variable value. */
   tp = GetVar( interp, (char *) var, TCL_LEAVE_ERR_MSG, STATUS );

/* Tcl uses zero to represent false, and non-zero to represent true. */
   if ( tp && !strcmp( tp, "0" ) ) {
      *valptr = F77_FALSE;
   } else {
      *valptr = F77_TRUE;
   }
}

static void GetRVar( Tcl_Interp *interp, const char *var, float *valptr, int *STATUS ) {
/*
*+
*  Name:
*     GetRVar

*  Purpose:
*     Retrieve a Tcl variable value and store it in a float.

*  Language:
*     Starlink C

*  Parameters:
*     interp = Tcl_Interp * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     valptr = float * (Returned)
*        A pointer to the variable to receive the returned value.
*     STATUS = int * (Given and Returned)
*        The inherited status.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   const char *tp;

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Get a pointer to the Tcl variable value string. */
   tp = GetVar( interp, (char *) var, TCL_LEAVE_ERR_MSG, STATUS );

/* If ok, extract a floating point value from it. Report an error if the
   conversion fails.  */
   if ( tp ) {
      if( sscanf( tp, "%g", valptr ) != 1 ) {
         *STATUS = SAI__ERROR;
         errRepf( "", "\"%s\" is not a floating point value.", STATUS, tp );
         errRepf( "", "Failed to obtained a value for Tcl variable \"%s\".", STATUS, var );
      }
   }
}

static void GetIVar( Tcl_Interp *interp, const char *var, int *valptr, int *STATUS ) {
/*
*+
*  Name:
*     GetIVar

*  Purpose:
*     Retrieve a Tcl variable value and store it in an integer.

*  Language:
*     Starlink C

*  Parameters:
*     interp = Tcl_Interp * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     valptr = int * (Returned)
*        A pointer to the variable to receive the returned value.
*     STATUS = int * (Given and Returned)
*        The inherited status.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*-
*/

   const char *tp;

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Get a pointer to the Tcl variable value string. */
   tp = GetVar( interp, (char *) var, TCL_LEAVE_ERR_MSG, STATUS );

/* If ok, extract an integer value from it. Report an error if the
   conversion fails.  */
   if ( tp ) {
      if( sscanf( tp, "%d", valptr ) != 1 ) {
         *STATUS = SAI__ERROR;
         errRepf( "", "\"%s\" is not an integer value.", STATUS, tp );
         errRepf( "", "Failed to obtained a value for Tcl variable \"%s\".", STATUS, var );
      }
   }
}


static void sink( const char *text ){
/* Sink function for use with astChannel. */
   if( fd && text ) fprintf( fd, "%s\n", text );
}
