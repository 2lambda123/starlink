/*
 *+
 *  Name:
 *     subpar.c

 *  Purpose:
 *     C interface to Fortran SUBPAR routines.

 *  Language:
 *     Starlink ANSI C

 *  Copyright:
 *     Copyright (C) 2008, 2009 Science and Technology Facilities Council.
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
 *     TIMJ: Tim Jenness (JAC, Hawaii)
 *     DSB: David S Berry (JAC, UCLan)
 *     {enter_new_authors_here}

 *  History:
 *     19-JUL-2008 (TIMJ):
 *        Initial version. Don't worry about MUTEXes.
 *     27-NOV-2008 (DSB):
 *        Use a mutex to prevent more than one Fortran routine being run
 *        at any one time.
 *     31-JUL-2009 (TIMJ):
 *        Add subParGet0l
 *     12-MAY-2011 (DSB):
 *        Remove the mutex previously used to prevent more than one Fortran
 *        routine being run at any one time. This is now done by CNF via
 *        the F77_LOCK macro.

 *  Bugs:
 *     {note_any_bugs_here}

 *-
*/

#include <config.h>

#include "f77.h"

#include "subpar.h"

F77_SUBROUTINE(subpar_findpar)( CHARACTER(NAME), INTEGER(NAMECODE),
				INTEGER(STATUS) TRAIL(NAME) );

void subParFindpar( const char * name, size_t * namecode, int * status ) {

  DECLARE_CHARACTER_DYN(NAME);
  DECLARE_INTEGER(NAMECODE);
  DECLARE_INTEGER(STATUS);

  F77_CREATE_EXPORT_CHARACTER(name, NAME);
  F77_EXPORT_INTEGER( *status, STATUS );

  F77_LOCK( F77_CALL(subpar_findpar)( CHARACTER_ARG(NAME),
			    INTEGER_ARG(&NAMECODE),
			    INTEGER_ARG(&STATUS)
			    TRAIL_ARG(NAME) ); )

  F77_FREE_CHARACTER(NAME);
  F77_IMPORT_INTEGER( NAMECODE, *namecode );
  F77_IMPORT_INTEGER( STATUS, *status );

  return;
}

F77_SUBROUTINE(subpar_get0c)( INTEGER(NAMECODE), CHARACTER(CVALUE),
			      INTEGER(STATUS) TRAIL(CVALUE) );


void subParGet0c( size_t namecode, char *cvalue, size_t cvalue_length,
		  int * status ) {
  DECLARE_INTEGER(NAMECODE);
  DECLARE_CHARACTER_DYN(CVALUE);
  DECLARE_INTEGER(STATUS);

  F77_EXPORT_INTEGER( namecode, NAMECODE );
  F77_CREATE_CHARACTER( CVALUE, cvalue_length - 1 );
  F77_EXPORT_INTEGER( *status, STATUS );

  F77_LOCK( F77_CALL(subpar_get0c)( INTEGER_ARG(&NAMECODE), CHARACTER_ARG(CVALUE),
			  INTEGER_ARG(&STATUS) TRAIL_ARG(CVALUE) ); )

  F77_IMPORT_CHARACTER( CVALUE, CVALUE_length, cvalue );
  F77_FREE_CHARACTER( CVALUE );
  F77_IMPORT_INTEGER( STATUS, *status );

  return;
}

F77_SUBROUTINE(subpar_get0l)( INTEGER(NAMECODE), LOGICAL(LVALUE),
			      INTEGER(STATUS) );


void subParGet0l( size_t namecode, int *lvalue, int * status ) {
  DECLARE_INTEGER(NAMECODE);
  DECLARE_LOGICAL(LVALUE);
  DECLARE_INTEGER(STATUS);

  F77_EXPORT_INTEGER( namecode, NAMECODE );
  F77_EXPORT_INTEGER( *status, STATUS );

  F77_LOCK( F77_CALL(subpar_get0l)( INTEGER_ARG(&NAMECODE), LOGICAL_ARG(&LVALUE),
			  INTEGER_ARG(&STATUS) ); )

  F77_IMPORT_LOGICAL( LVALUE, *lvalue );
  F77_IMPORT_INTEGER( STATUS, *status );

  return;
}

F77_SUBROUTINE(subpar_getkey)( INTEGER(NAMECODE), CHARACTER(KEYWORD),
			      INTEGER(STATUS) TRAIL(KEYWORD) );


void subParGetkey( size_t namecode, char *keyword, size_t keyword_length,
		  int * status ) {
  DECLARE_INTEGER(NAMECODE);
  DECLARE_CHARACTER_DYN(KEYWORD);
  DECLARE_INTEGER(STATUS);

  F77_EXPORT_INTEGER( namecode, NAMECODE );
  F77_CREATE_CHARACTER( KEYWORD, keyword_length - 1 );
  F77_EXPORT_INTEGER( *status, STATUS );

  F77_LOCK( F77_CALL(subpar_getkey)( INTEGER_ARG(&NAMECODE), CHARACTER_ARG(KEYWORD),
			  INTEGER_ARG(&STATUS) TRAIL_ARG(KEYWORD) ); )

  F77_IMPORT_CHARACTER( KEYWORD, KEYWORD_length, keyword );
  F77_FREE_CHARACTER( KEYWORD );
  F77_IMPORT_INTEGER( STATUS, *status );

  return;
}

/* Note that REFLEN is supplied, not returned, in the C interface. */

F77_LOGICAL_FUNCTION(subpar_gref)( INTEGER(NAMECODE), CHARACTER(REFSTR),
                                   INTEGER(REFLEN) TRAIL(REFSTR) );

int subParGref( size_t namecode, char * refstr, size_t reflen ) {
  DECLARE_INTEGER(NAMECODE);
  DECLARE_CHARACTER_DYN(REFSTR);
  DECLARE_INTEGER(REFLEN);
  int retval = 0;

  F77_EXPORT_INTEGER( namecode, NAMECODE );
  F77_CREATE_CHARACTER( REFSTR, reflen - 1 );

  F77_LOCK( retval = F77_CALL(subpar_gref)( INTEGER_ARG(&NAMECODE),
                                  CHARACTER_ARG(REFSTR),
                                  INTEGER_ARG(&REFLEN)
                                  TRAIL_ARG(REFSTR) ); )

  F77_IMPORT_CHARACTER( REFSTR, REFSTR_length, refstr );
  F77_FREE_CHARACTER( REFSTR );

  return retval;
}

F77_SUBROUTINE(subpar_state)( INTEGER(NAMECODE), INTEGER(STATE), INTEGER(STATUS) );

void subParState( size_t namecode, int * state, int * status ) {
  DECLARE_INTEGER(NAMECODE);
  DECLARE_INTEGER(STATE);
  DECLARE_INTEGER(STATUS);

  F77_EXPORT_INTEGER( namecode, NAMECODE );
  F77_EXPORT_INTEGER( *status, STATUS );

  F77_LOCK( F77_CALL(subpar_state)( INTEGER_ARG(&NAMECODE),
			  INTEGER_ARG(&STATE),
			  INTEGER_ARG(&STATUS) ); )

  F77_IMPORT_INTEGER( STATE, *state );
  F77_IMPORT_INTEGER( STATUS, *status );
}

F77_SUBROUTINE(subpar_sync)(INTEGER(STATUS));

void subParSync( int * status ) {
  DECLARE_INTEGER(STATUS);

  F77_EXPORT_INTEGER( *status, STATUS );
  F77_LOCK( F77_CALL(subpar_sync)( INTEGER_ARG(&STATUS) ); )
  F77_IMPORT_INTEGER( STATUS, *status );

  return;
}

F77_SUBROUTINE(subpar_wrerr)(CHARACTER(STRING),INTEGER(STATUS) TRAIL(STRING));

void subParWrerr( const char * string, int * status ) {
  DECLARE_CHARACTER_DYN(STRING);
  DECLARE_INTEGER(STATUS);

  F77_CREATE_EXPORT_CHARACTER(string, STRING);
  F77_EXPORT_INTEGER( *status, STATUS );

  F77_LOCK( F77_CALL(subpar_wrerr)( CHARACTER_ARG(STRING),
			  INTEGER_ARG(&STATUS)
			  TRAIL_ARG(STRING) ); )

  F77_FREE_CHARACTER(STRING);
  F77_IMPORT_INTEGER( STATUS, *status );

  return;
}

F77_SUBROUTINE(subpar_wrmsg)(CHARACTER(STRING),INTEGER(STATUS) TRAIL(STRING));

void subParWrmsg( const char * string, int * status ) {
  DECLARE_CHARACTER_DYN(STRING);
  DECLARE_INTEGER(STATUS);

  F77_CREATE_EXPORT_CHARACTER(string, STRING);
  F77_EXPORT_INTEGER( *status, STATUS );

  F77_LOCK( F77_CALL(subpar_wrmsg)( CHARACTER_ARG(STRING),
			  INTEGER_ARG(&STATUS)
			  TRAIL_ARG(STRING) ); )

  F77_FREE_CHARACTER(STRING);
  F77_IMPORT_INTEGER( STATUS, *status );

  return;
}
