/*
*+
*  Name:
*     fobject.c

*  Purpose:
*     Define a FORTRAN 77 interface to the AST Object class.

*  Type of Module:
*     C source file.

*  Description:
*     This file defines FORTRAN 77-callable C functions which provide
*     a public FORTRAN 77 interface to the Object class.

*  Routines Defined:
*     AST_ANNUL
*     AST_BEGIN
*     AST_CLEAR
*     AST_CLONE
*     AST_COPY
*     AST_DELETE
*     AST_END
*     AST_ESCAPES
*     AST_EXEMPT
*     AST_EXPORT
*     AST_GET(C,D,I,L,R)
*     AST_ISAOBJECT
*     AST_NULL
*     AST_SET 
*     AST_SET(C,D,I,L,R)
*     AST_SHOW
*     AST_VERSION 
*     AST_LISTISSUED   (only if macro DEBUG is defined)
*     AST_SETWATCHID   (only if macro DEBUG is defined)
*     AST_TUNE

*  Copyright:
*     <COPYRIGHT_STATEMENT>

*  Authors:
*     RFWS: R.F. Warren-Smith (Starlink)
*     DSB: David S. Berry (Starlink)

*  History:
*     20-JUN-1996 (RFWS):
*        Original version.
*     9-SEP-1996 (RFWS):
*        Added AST_SHOW.
*     11-DEC-1996 (RFWS):
*        Added AST_NULL.
*     14-JUL-1997 (RFWS):
*        Add AST_EXEMPT function.
*     30-APR-2003 (DSB):
*        Add AST_VERSION function.
*     7-FEB-2004 (DSB):
*        Add AST_ESCAPES function.
*     27-JAN-2005 (DSB):
*        Added AST_LISTISSUED and AST_SETWATCHID so that DEBUG facilities
*        can be used from fortran.
*     7-FEB-2006 (DSB):
*        Added AST_TUNE.
*-
*/

/* Define the astFORTRAN77 macro which prevents error messages from
   AST C functions from reporting the file and line number where the
   error occurred (since these would refer to this file, they would
   not be useful). */
#define astFORTRAN77

/* Header files. */
/* ============= */
#include "f77.h"                 /* FORTRAN <-> C interface macros (SUN/209) */
#include "c2f77.h"               /* F77 <-> C support functions/macros */
#include "error.h"               /* Error reporting facilities */
#include "memory.h"              /* Memory handling facilities */
#include "object.h"              /* C interface to the Object class */

F77_SUBROUTINE(ast_annul)( INTEGER(THIS),
                           INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)

   astAt( "AST_ANNUL", NULL, 0 );
   astWatchSTATUS(
      *THIS = astP2I( astAnnul( astI2P( *THIS ) ) );
   )
}

F77_SUBROUTINE(ast_begin)( INTEGER(STATUS) ) {

   astAt( "AST_BEGIN", NULL, 0 );
   astWatchSTATUS(
      astBegin;
   )
}

F77_SUBROUTINE(ast_clear)( INTEGER(THIS),
                           CHARACTER(ATTRIB),
                           INTEGER(STATUS)
                           TRAIL(ATTRIB) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(ATTRIB)
   char *attrib;

   astAt( "AST_CLEAR", NULL, 0 );
   astWatchSTATUS(
      attrib = astString( ATTRIB, ATTRIB_length );
      astClear( astI2P( *THIS ), attrib );
      astFree( attrib );
   )
}

F77_INTEGER_FUNCTION(ast_clone)( INTEGER(THIS),
                                 INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)
   F77_INTEGER_TYPE(RESULT);

   astAt( "AST_CLONE", NULL, 0 );
   astWatchSTATUS(
      RESULT = astP2I( astClone( astI2P( *THIS ) ) );
   )
   return RESULT;
}

F77_INTEGER_FUNCTION(ast_version)( ) {
   astAt( "AST_VERSION", NULL, 0 );
   return astVersion;
}

F77_INTEGER_FUNCTION(ast_escapes)( INTEGER(NEWVAL),
                                   INTEGER(STATUS) ) {
   GENPTR_INTEGER(NEWVAL)
   F77_INTEGER_TYPE(RESULT);

   astAt( "AST_ESCAPES", NULL, 0 );
   astWatchSTATUS(
      RESULT = astEscapes( *NEWVAL );
   )
   return RESULT;
}

F77_INTEGER_FUNCTION(ast_copy)( INTEGER(THIS),
                                INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)
   F77_INTEGER_TYPE(RESULT);

   astAt( "AST_COPY", NULL, 0 );
   astWatchSTATUS(
      RESULT = astP2I( astCopy( astI2P( *THIS ) ) );
   )
   return RESULT;
}

F77_SUBROUTINE(ast_delete)( INTEGER(THIS),
                            INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)

   astAt( "AST_DELETE", NULL, 0 );
   astWatchSTATUS(
      *THIS = astP2I( astDelete( astI2P( *THIS ) ) );
   )
}

F77_SUBROUTINE(ast_end)( INTEGER(STATUS) ) {

   astAt( "AST_END", NULL, 0 );
   astWatchSTATUS(
      astEnd;
   )
}

F77_SUBROUTINE(ast_exempt)( INTEGER(THIS),
                            INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)

   astAt( "AST_EXEMPT", NULL, 0 );
   astWatchSTATUS(
      astExempt( astI2P( *THIS ) );
   )
}

F77_SUBROUTINE(ast_export)( INTEGER(THIS),
                            INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)

   astAt( "AST_EXPORT", NULL, 0 );
   astWatchSTATUS(
      astExport( astI2P( *THIS ) );
   )
}

#define MAKE_GETX(name,code,TYPE,CODE,type) \
F77_##TYPE##_FUNCTION(ast_get##code)( INTEGER(THIS), \
                                      CHARACTER(ATTRIB), \
                                      INTEGER(STATUS) \
                                      TRAIL(ATTRIB) ) { \
   GENPTR_INTEGER(THIS) \
   GENPTR_CHARACTER(ATTRIB) \
   F77_##TYPE##_TYPE(RESULT); \
   char *attrib; \
\
   astAt( name, NULL, 0 ); \
   astWatchSTATUS( \
      attrib = astString( ATTRIB, ATTRIB_length ); \
      RESULT = astGet##CODE( astI2P( *THIS ), attrib ); \
      astFree( attrib ); \
   ) \
   return RESULT; \
}

MAKE_GETX("AST_GETD",d,DOUBLE,D,double)
MAKE_GETX("AST_GETI",i,INTEGER,L,long)
MAKE_GETX("AST_GETR",r,REAL,D,double)

/* NO_CHAR_FUNCTION indicates that the f77.h method of returning a
   character result doesn't work, so add an extra argument instead and
   wrap this function up in a normal FORTRAN 77 function (in the file
   object.f). */
#if NO_CHAR_FUNCTION
F77_SUBROUTINE(ast_getc_a)( CHARACTER(RESULT),
#else
F77_SUBROUTINE(ast_getc)( CHARACTER_RETURN_VALUE(RESULT),
#endif
                          INTEGER(THIS),
                          CHARACTER(ATTRIB),
                          INTEGER(STATUS)
#if NO_CHAR_FUNCTION
                          TRAIL(RESULT)
#endif
                          TRAIL(ATTRIB) ) {
   GENPTR_CHARACTER(RESULT)
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(ATTRIB)
   char *attrib;
   const char *result; 
   int i;

   astAt( "AST_GETC", NULL, 0 );
   astWatchSTATUS(
      attrib = astString( ATTRIB, ATTRIB_length );
      result = astGetC( astI2P( *THIS ), attrib );
      i = 0;
      if ( astOK ) {             /* Copy result */
         for ( ; result[ i ] && i < RESULT_length; i++ ) {
            RESULT[ i ] = result[ i ];
         }
      }
      while ( i < RESULT_length ) RESULT[ i++ ] = ' '; /* Pad with blanks */
      astFree( attrib );
   )
}

F77_LOGICAL_FUNCTION(ast_getl)( INTEGER(THIS),
                                CHARACTER(ATTRIB),
                                INTEGER(STATUS)
                                TRAIL(ATTRIB) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(ATTRIB)
   F77_LOGICAL_TYPE(RESULT);
   char *attrib;

   astAt( "AST_GETL", NULL, 0 );
   astWatchSTATUS(
      attrib = astString( ATTRIB, ATTRIB_length );
      RESULT = astGetL( astI2P( *THIS ), attrib ) ? F77_TRUE : F77_FALSE;
      astFree( attrib );
   )
   return RESULT;
}

F77_LOGICAL_FUNCTION(ast_isaobject)( INTEGER(THIS),
                                     INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)
   F77_LOGICAL_TYPE(RESULT);

   astAt( "AST_ISAOBJECT", NULL, 0 );
   astWatchSTATUS(
      RESULT = astIsAObject( astI2P( *THIS ) ) ? F77_TRUE : F77_FALSE;
   )
   return RESULT;
}

F77_SUBROUTINE(ast_null)( void ) {}

/* Omit the C variable length argument list here. */
F77_SUBROUTINE(ast_set)( INTEGER(THIS),
                         CHARACTER(SETTING),
                         INTEGER(STATUS)
                         TRAIL(SETTING) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(SETTING)
   char *setting;
   int i;

   astAt( "AST_SET", NULL, 0 );
   astWatchSTATUS(
      setting = astString( SETTING, SETTING_length );

/* Change ',' to '\n' (which is what astSet normally does to its second
   argument internally to separate the fields). This then allows "setting"
   to be provided as an additional string value to be formatted using "%s".
   This avoids interpretation of its contents (e.g. '%') as C format
   specifiers. */
      if ( astOK ) {
         for ( i = 0; setting[ i ]; i++ ) {
            if ( setting[ i ] == ',' ) setting[ i ] = '\n';
         }
      }
      astSet( astI2P( *THIS ), "%s", setting );
      astFree( setting );
   )
}

#define MAKE_SETX(name,code,TYPE,CODE,type) \
F77_SUBROUTINE(ast_set##code)( INTEGER(THIS), \
                               CHARACTER(ATTRIB), \
                               TYPE(VALUE), \
                               INTEGER(STATUS) \
                               TRAIL(ATTRIB) ) { \
   GENPTR_INTEGER(THIS) \
   GENPTR_CHARACTER(ATTRIB) \
   GENPTR_##TYPE(VALUE) \
   char *attrib; \
\
   astAt( name, NULL, 0 ); \
   astWatchSTATUS( \
      attrib = astString( ATTRIB, ATTRIB_length ); \
      astSet##CODE( astI2P( *THIS ), attrib, *VALUE ); \
      astFree( attrib ); \
   ) \
}

MAKE_SETX("AST_SETD",d,DOUBLE,D,double)
MAKE_SETX("AST_SETR",r,REAL,D,double)
MAKE_SETX("AST_SETI",i,INTEGER,L,long)

F77_SUBROUTINE(ast_setc)( INTEGER(THIS),
                          CHARACTER(ATTRIB),
                          CHARACTER(VALUE),
                          INTEGER(STATUS)
                          TRAIL(ATTRIB)
                          TRAIL(VALUE) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(ATTRIB)
   GENPTR_CHARACTER(VALUE)
   char *attrib, *value;

   astAt( "AST_SETC", NULL, 0 );
   astWatchSTATUS(
      attrib = astString( ATTRIB, ATTRIB_length );
      value = astString( VALUE, VALUE_length );
      astSetC( astI2P( *THIS ), attrib, value );
      astFree( attrib );
      astFree( value );
   )
}

F77_SUBROUTINE(ast_setl)( INTEGER(THIS),
                          CHARACTER(ATTRIB),
                          LOGICAL(VALUE),
                          INTEGER(STATUS)
                          TRAIL(ATTRIB) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(ATTRIB)
   GENPTR_LOGICAL(VALUE)
   char *attrib;

   astAt( "AST_SETL", NULL, 0 );
   astWatchSTATUS(
      attrib = astString( ATTRIB, ATTRIB_length );
      astSetI( astI2P( *THIS ), attrib, F77_ISTRUE( *VALUE ) ? 1 : 0 );
      astFree( attrib );
   )
}

F77_SUBROUTINE(ast_show)( INTEGER(THIS),
                          INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)

   astAt( "AST_SHOW", NULL, 0 );
   astWatchSTATUS(
      astShow( astI2P( *THIS ) );
   )
}

F77_LOGICAL_FUNCTION(ast_test)( INTEGER(THIS),
                                CHARACTER(ATTRIB),
                                INTEGER(STATUS)
                                TRAIL(ATTRIB) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(ATTRIB)
   F77_LOGICAL_TYPE(RESULT);
   char *attrib;

   astAt( "AST_TEST", NULL, 0 );
   astWatchSTATUS(
      attrib = astString( ATTRIB, ATTRIB_length );
      RESULT = astTest( astI2P( *THIS ), attrib ) ? F77_TRUE : F77_FALSE;
      astFree( attrib );
   )
   return RESULT;
}

#ifdef DEBUG

F77_SUBROUTINE(ast_listissued)( CHARACTER(TEXT)
                                TRAIL(TEXT) ) {
   GENPTR_CHARACTER(TEXT)
   char *text;

   astSetPermMem( 1 );
   text = astString( TEXT, TEXT_length );
   astSetPermMem( 0 );
   astListIssued( text );
   astFree( text );
}

F77_SUBROUTINE(ast_setwatchid)( INTEGER(ID) ) {
   GENPTR_INTEGER(ID)
   astSetWatchId( *ID );
}


F77_INTEGER_FUNCTION(ast_tune)( CHARACTER(NAME),
                                INTEGER(VALUE),
                                INTEGER(STATUS) 
                                TRAIL(NAME) ) {
   GENPTR_INTEGER(VALUE)
   GENPTR_CHARACTER(NAME)
   F77_INTEGER_TYPE(RESULT);
   char *name;

   astAt( "AST_TUNE", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      RESULT = astTune( name, *VALUE );
      name = astFree( name );
   )
   return RESULT;
}



#endif



