/*
*+
*  Name:
*     fplot.c

*  Purpose:
*     Define a FORTRAN 77 interface to the AST Plot class.

*  Type of Module:
*     C source file.

*  Description:
*     This file defines FORTRAN 77-callable C functions which provide
*     a public FORTRAN 77 interface to the Plot class.

*  Routines Defined:
*     AST_BORDER
*     AST_CLIP
*     AST_CURVE
*     AST_GRID
*     AST_GRIDLINE
*     AST_ISAPLOT
*     AST_MARK
*     AST_PLOT
*     AST_POLYCURVE
*     AST_TEXT   
*     AST_GRFFUN

*  Copyright:
*     <COPYRIGHT_STATEMENT>

*  Authors:
*     DSB: D.S. Berry (Starlink)

*  History:
*     23-OCT-1996 (DSB):
*        Original version.
*     14-NOV-1996 (DSB):
*        Method names shortened. CrvBreak removed.
*     21-NOV-1996 (DSB):
*        Method names changed, CLIP argument NBND removed.
*     18-DEC-1996 (DSB):
*        Argument UP changed to single precision and NCOORD removed 
*        in AST_TEXT.
*     11-AUG-1998 (DSB):
*        Added AST_POLYCURVE.
*     9-JAN-2001 (DSB):
*        Change argument "in" for astMark and astPolyCurve from type
*        "const double (*)[]" to "const double *".
*     13-JUN-2001 (DSB):
*        Modified to add support for astGrfFun and EXTERNAL grf functions.
*/

/* Define the astFORTRAN77 macro which prevents error messages from
   AST C functions from reporting the file and line number where the
   error occurred (since these would refer to this file, they would
   not be useful). */
#define astFORTRAN77

#define MXSTRLEN 80              /* String length at which truncation starts
                                    within pgqtxt and pgptxt. */
/* Header files. */
/* ============= */
#include "ast_err.h"             /* AST error codes */
#include "f77.h"                 /* FORTRAN <-> C interface macros (SUN/209) */
#include "c2f77.h"               /* F77 <-> C support functions/macros */
#include "error.h"               /* Error reporting facilities */
#include "memory.h"              /* Memory handling facilities */
#include "plot.h"                /* C interface to the Plot class */
#include "grf.h"                 /* Low-level graphics interface */

/* Prototypes for external functions. */
/* ================================== */
/* This is the null function defined by the FORTRAN interface in
fobject.c. */
F77_SUBROUTINE(ast_null)( void );

static int FGAttrWrapper( AstPlot *, int, double, double *, int );
static int FGAxScaleWrapper( AstPlot *, float *, float * );
static int FGFlushWrapper( AstPlot * );
static int FGLineWrapper( AstPlot *, int, const float *, const float * );
static int FGMarkWrapper( AstPlot *, int, const float *, const float *, int );
static int FGQchWrapper( AstPlot *, float *, float *);
static int FGTextWrapper( AstPlot *, const char *, float, float, const char *, float, float );
static int FGTxExtWrapper( AstPlot *, const char *, float, float, const char *, float, float, float *, float * );

F77_LOGICAL_FUNCTION(ast_isaplot)( INTEGER(THIS),
                                   INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)
   F77_LOGICAL_TYPE(RESULT);

   astAt( "AST_ISAPLOT", NULL, 0 );
   astWatchSTATUS(
      RESULT = astIsAPlot( astI2P( *THIS ) ) ? F77_TRUE : F77_FALSE;
   )
   return RESULT;
}

F77_INTEGER_FUNCTION(ast_plot)( INTEGER(FRAME),
                                REAL_ARRAY(GRAPHBOX),
                                DOUBLE_ARRAY(BASEBOX),
                                CHARACTER(OPTIONS),
                                INTEGER(STATUS)
                                TRAIL(OPTIONS) ) {
   GENPTR_INTEGER(FRAME)
   GENPTR_REAL_ARRAY(GRAPHBOX)
   GENPTR_DOUBLE_ARRAY(BASEBOX)
   GENPTR_CHARACTER(OPTIONS)
   F77_INTEGER_TYPE(RESULT);
   char *options;
   int i;

   astAt( "AST_PLOT", NULL, 0 );
   astWatchSTATUS(
      options = astString( OPTIONS, OPTIONS_length );

/* Change ',' to '\n' (see AST_SET in fobject.c for why). */
      if ( astOK ) {
         for ( i = 0; options[ i ]; i++ ) {
            if ( options[ i ] == ',' ) options[ i ] = '\n';
         }
      }
      RESULT = astP2I( astPlot( astI2P( *FRAME ), GRAPHBOX, BASEBOX, 
                                "%s", options ) );
      astFree( options );
   )
   return RESULT;
}

F77_LOGICAL_FUNCTION(ast_border)( INTEGER(THIS),
                                  INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)
   F77_LOGICAL_TYPE(RESULT);

   astAt( "AST_BORDER", NULL, 0 );
   astWatchSTATUS(
      RESULT = astBorder( astI2P( *THIS ) ) ? F77_TRUE : F77_FALSE;
   )
   return RESULT;
}

F77_SUBROUTINE(ast_clip)( INTEGER(THIS),
                          INTEGER(IFRAME),
                          DOUBLE_ARRAY(LBND),
                          DOUBLE_ARRAY(UBND),
                          INTEGER(STATUS) ){
   GENPTR_INTEGER(THIS)
   GENPTR_INTEGER(IFRAME)
   GENPTR_DOUBLE_ARRAY(LBND)
   GENPTR_DOUBLE_ARRAY(UBND)

   astAt( "AST_CLIP", NULL, 0 );
   astWatchSTATUS(
      astClip( astI2P( *THIS ), *IFRAME, LBND, UBND );
   )
}

F77_SUBROUTINE(ast_gridline)( INTEGER(THIS),
                              INTEGER(AXIS),
                              DOUBLE_ARRAY(START),
                              DOUBLE(LENGTH),
                              INTEGER(STATUS) ){
   GENPTR_INTEGER(THIS)
   GENPTR_INTEGER(AXIS)
   GENPTR_DOUBLE_ARRAY(START)
   GENPTR_DOUBLE(LENGTH)

   astAt( "AST_GRIDLINE", NULL, 0 );
   astWatchSTATUS(
      astGridLine( astI2P( *THIS ), *AXIS, START, *LENGTH );
   )
}

F77_SUBROUTINE(ast_curve)( INTEGER(THIS),
                           DOUBLE_ARRAY(START),
                           DOUBLE_ARRAY(FINISH),
                           INTEGER(STATUS) ){
   GENPTR_INTEGER(THIS)
   GENPTR_DOUBLE_ARRAY(START)
   GENPTR_DOUBLE_ARRAY(FINISH)

   astAt( "AST_CURVE", NULL, 0 );
   astWatchSTATUS(
      astCurve( astI2P( *THIS ), START, FINISH );
   )
}

F77_SUBROUTINE(ast_grid)( INTEGER(THIS),
                          INTEGER(STATUS) ){
   GENPTR_INTEGER(THIS)

   astAt( "AST_GRID", NULL, 0 );
   astWatchSTATUS(
      astGrid( astI2P( *THIS ) );
   )
}

F77_SUBROUTINE(ast_mark)( INTEGER(THIS),
                          INTEGER(NMARK),
                          INTEGER(NCOORD),
                          INTEGER(INDIM),
                          DOUBLE_ARRAY(IN),
                          INTEGER(TYPE),
                          INTEGER(STATUS) ){
   GENPTR_INTEGER(THIS)
   GENPTR_INTEGER(NMARK)
   GENPTR_INTEGER(NCOORD)
   GENPTR_INTEGER(INDIM)
   GENPTR_DOUBLE_ARRAY(IN)
   GENPTR_INTEGER(TYPE)

   astAt( "AST_MARK", NULL, 0 );
   astWatchSTATUS(
      astMark( astI2P( *THIS ), *NMARK, *NCOORD, *INDIM,
               (const double *)IN, *TYPE );
   )
}

F77_SUBROUTINE(ast_polycurve)( INTEGER(THIS),
                               INTEGER(NPOINT),
                               INTEGER(NCOORD),
                               INTEGER(INDIM),
                               DOUBLE_ARRAY(IN),
                               INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_INTEGER(NPOINT)
   GENPTR_INTEGER(NCOORD)
   GENPTR_INTEGER(INDIM)
   GENPTR_DOUBLE_ARRAY(IN)

   astAt( "AST_POLYCURVE", NULL, 0 );
   astWatchSTATUS(
      astPolyCurve( astI2P( *THIS ), *NPOINT, *NCOORD, *INDIM,
                (const double *)IN );
   )
}

F77_SUBROUTINE(ast_text)( INTEGER(THIS),
                          CHARACTER(TEXT), 
                          DOUBLE_ARRAY(POS),
                          REAL_ARRAY(UP),
                          CHARACTER(JUST),
                          INTEGER(STATUS)
                          TRAIL(TEXT)
                          TRAIL(JUST) ){
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(TEXT)
   GENPTR_DOUBLE_ARRAY(POS)
   GENPTR_REAL_ARRAY(UP)
   GENPTR_CHARACTER(JUST) 
   char *text, *just;

   astAt( "AST_TEXT", NULL, 0 );
   astWatchSTATUS(
      text = astString( TEXT, TEXT_length );
      just = astString( JUST, JUST_length );
      astText( astI2P( *THIS ), text, POS, UP, just );
      (void) astFree( (void *) text );
      (void) astFree( (void *) just );
   )
}

F77_SUBROUTINE(ast_grffun)( INTEGER(THIS), CHARACTER(NAME), 
                            void (* FUN)(), INTEGER(STATUS)
                            TRAIL(NAME) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   char *name;
   void (* fun)();
   const char *class;      /* Object class */
   const char *method;     /* Current method */
   int ifun;               /* Index into grf function list */
   void (* wrapper)();     /* Wrapper function for C Grf routine*/

   method = "AST_GRFFUN";
   class = "Plot";

   astAt( "AST_GRFFUN", NULL, 0 );
   astWatchSTATUS(

/* Set the function pointer to NULL if a pointer to
   the null routine AST_NULL has been supplied. */
      fun = FUN;
      if ( fun == (void (*)()) F77_EXTERNAL_NAME(ast_null) ) {
         fun = NULL;
      }

      name = astString( NAME, NAME_length );
      astGrfFun( astI2P( *THIS ), name, fun );

      ifun = astGrfFunID( name, method, class );

      if( ifun == AST__GATTR ) {
         wrapper = (void (*)()) FGAttrWrapper;
      } else if( ifun == AST__GAXSCALE ) {
         wrapper = (void (*)()) FGAxScaleWrapper;
      } else if( ifun == AST__GFLUSH ) {
         wrapper = (void (*)()) FGFlushWrapper;
      } else if( ifun == AST__GLINE ) {
         wrapper = (void (*)()) FGLineWrapper;
      } else if( ifun == AST__GMARK ) {
         wrapper = (void (*)()) FGMarkWrapper;
      } else if( ifun == AST__GQCH ) {
         wrapper = (void (*)()) FGQchWrapper;
      } else if( ifun == AST__GTEXT ) {
         wrapper = (void (*)()) FGTextWrapper;
      } else if( ifun == AST__GTXEXT ) {
         wrapper = (void (*)()) FGTxExtWrapper;
      } else if( astOK ) {
         astError( AST__INTER, "%s(%s): AST internal programming error - "
                   "Grf function id %d not yet supported.", method, class,
                   ifun );
      }
      astGrfWrapper( astI2P( *THIS ), name, wrapper );
   )
}

static int FGAttrWrapper( AstPlot *this, int attr, double value, 
                          double *old_value, int prim ) {
   if ( !astOK ) return 0;
   return ( *(int (*)( INTEGER(attr), DOUBLE(value), DOUBLE(old_value),
                       INTEGER(prim) ))
                  this->grffun[ AST__GATTR ])(  INTEGER_ARG(&attr),
                                                DOUBLE_ARG(&value), 
                                                DOUBLE_ARG(old_value),  
                                                INTEGER_ARG(&prim) );
}

static int FGAxScaleWrapper( AstPlot *this, float *alpha, float *beta ) {
   if ( !astOK ) return 0;
   return ( *(int (*)( REAL(alpha), REAL(beta) ))
                  this->grffun[ AST__GAXSCALE ])( REAL_ARG(alpha),
                                                  REAL_ARG(beta) );
}

static int FGFlushWrapper( AstPlot *this ) {
   if ( !astOK ) return 0;
   return ( *(int (*)()) this->grffun[ AST__GFLUSH ])();
}

static int FGLineWrapper( AstPlot *this, int n, const float *x, 
                          const float *y ) {
   if ( !astOK ) return 0;
   return ( *(int (*)( INTEGER(n), REAL_ARRAY(x), REAL_ARRAY(y) ))
                  this->grffun[ AST__GLINE ])(  INTEGER_ARG(&n),
                                                REAL_ARRAY_ARG(x), 
                                                REAL_ARRAY_ARG(y) );
}

static int FGMarkWrapper( AstPlot *this, int n, const float *x, 
                          const float *y, int type ) {
   if ( !astOK ) return 0;
   return ( *(int (*)( INTEGER(n), REAL_ARRAY(x), REAL_ARRAY(y),
                       INTEGER(type) ))
                  this->grffun[ AST__GMARK ])(  INTEGER_ARG(&n),
                                                REAL_ARRAY_ARG(x), 
                                                REAL_ARRAY_ARG(y),
                                                INTEGER_ARG(&type) );
}

static int FGQchWrapper( AstPlot *this, float *chv, float *chh ) {
   if ( !astOK ) return 0;
   return ( *(int (*)( REAL(chv), REAL(chh) ))
                  this->grffun[ AST__GQCH ])( REAL_ARG(chv),
                                              REAL_ARG(chh) );
}

static int FGTextWrapper( AstPlot *this, const char *text, float x, float y,
                          const char *just, float upx, float upy ) {

   DECLARE_CHARACTER(LTEXT,MXSTRLEN);
   DECLARE_CHARACTER(LJUST,MXSTRLEN);
   int ftext_length;
   int fjust_length;

   if ( !astOK ) return 0;

   ftext_length = strlen( text );
   if( ftext_length > LTEXT_length ) ftext_length = LTEXT_length;
   astStringExport( text, LTEXT, ftext_length );

   fjust_length = strlen( just );
   if( fjust_length > LJUST_length ) fjust_length = LJUST_length;
   astStringExport( just, LJUST, fjust_length );

   return ( *(int (*)( CHARACTER(LTEXT), REAL(x), REAL(y),
                       CHARACTER(LJUST), REAL(upx), REAL(upy)
                       TRAIL(ftext) TRAIL(fjust) ) )
                  this->grffun[ AST__GTEXT ])( 
                                      CHARACTER_ARG(LTEXT),
                                      REAL_ARG(&x),
                                      REAL_ARG(&y), 
                                      CHARACTER_ARG(LJUST),
                                      REAL_ARG(&upx), 
                                      REAL_ARG(&upy) 
                                      TRAIL_ARG(ftext) 
                                      TRAIL_ARG(fjust) );
}

static int FGTxExtWrapper( AstPlot *this, const char *text, float x, float y,
                           const char *just, float upx, float upy, float *xb, 
                           float *yb ) {
   DECLARE_CHARACTER(LTEXT,MXSTRLEN);
   DECLARE_CHARACTER(LJUST,MXSTRLEN);
   int ftext_length;
   int fjust_length;

   if ( !astOK ) return 0;

   ftext_length = strlen( text );
   if( ftext_length > LTEXT_length ) ftext_length = LTEXT_length;
   astStringExport( text, LTEXT, ftext_length );

   fjust_length = strlen( just );
   if( fjust_length > LJUST_length ) fjust_length = LJUST_length;
   astStringExport( just, LJUST, fjust_length );

   return ( *(int (*)( CHARACTER(LTEXT), REAL(x), REAL(y),
                       CHARACTER(LJUST), REAL(upx), REAL(upy),
                       REAL_ARRAY(xb), REAL_ARRAY(yb) TRAIL(ftext) 
                       TRAIL(fjust) ) )
                  this->grffun[ AST__GTXEXT ])( 
                                                CHARACTER_ARG(LTEXT),
                                                REAL_ARG(&x),
                                                REAL_ARG(&y), 
                                                CHARACTER_ARG(LJUST),
                                                REAL_ARG(&upx), 
                                                REAL_ARG(&upy),
                                                REAL_ARRAY_ARG(xb),
                                                REAL_ARRAY_ARG(yb)
                                                TRAIL_ARG(ftext) 
                                                TRAIL_ARG(fjust) );
}

