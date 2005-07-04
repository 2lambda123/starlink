/*
*class++
*  Name:
*     TimeFrame

*  Purpose:
*     Time coordinate system description.

*  Constructor Function:
c     astTimeFrame
f     AST_TIMEFRAME

*  Description:
*     A TimeFrame is a specialised form of one-dimensional Frame which 
*     represents various coordinate systems used to describe positions in
*     time.
*
*     A TimeFrame represents a moment in time as either an Modified Julian 
*     Date (MJD), a Julian Date (JD), a Besselian epoch or a Julian epoch,
*     as determined by the System attribute. Optionally, a zero point can be 
*     specified (using attribute TimeOrigin) which results in the TimeFrame 
*     representing time offsets from the specified zero point.
*
*     Even though JD and MJD are defined as being in units of days, the
*     TimeFrame class allows other units to be used (via the Unit attribute) 
*     on the basis of simple scalings (60 seconds = 1 minute, 60 minutes = 1 
*     hour, 24 hours = 1 day, 365.25 days = 1 year). Likewise, Julian epochs 
*     can be described in units other than the usual years. Besselian epoch 
*     are always represented in units of (tropical) years.
*
*     The TimeScale attribute allows the time scale to be specified (that
*     is, the physical proces used to define the rate of flow of time).
*     MJD, JD and Julian epoch can be used to represent a time in any
*     supported time scale. However, Besselian epoch may only be used with the 
*     "TT" (Terrestrial Time) time scale. The list of supported time scales
*     includes universal time and siderial time. Strictly, these represent 
*     angles rather than time scales, but are included in the list since
*     they are in common use and are often thought of as time scales.
*
*     When a time value is formatted it can be formated either as a simple
*     floating point value, or as a Gregorian date (see the Format
*     attribute).

*  Inheritance:
*     The TimeFrame class inherits from the Frame class.

*  Attributes:
*     In addition to those attributes common to all Frames, every
*     TimeFrame also has the following attributes:
*
*     - AlignTimeScale: Time scale in which to align TimeFrames
*     - ClockLat: Geodetic latitude of observer/clock
*     - ClockLon: Geodetic longitude of observer/clock
*     - TimeOrigin: The zero point for TimeFrame axis values
*     - TimeScale: The timescale used by the TimeFrame
*
*     Several of the Frame attributes inherited by the TimeFrame class 
*     refer to a specific axis of the Frame (for instance Unit(axis), 
*     Label(axis), etc). Since a TimeFrame is strictly one-dimensional,
*     it allows these attributes to be specified without an axis index.
*     So for instance, "Unit" is allowed in place of "Unit(1)".

*  Functions:
c     In addition to those functions applicable to all Frames, the
c     following functions may also be applied to all TimeFrames:
f     In addition to those routines applicable to all Frames, the
f     following routines may also be applied to all TimeFrames:
*
c     - astCurrentTime: Return the current system time
f     - AST_CURRENTTIME: Return the current system time

*  Copyright:
*     <COPYRIGHT_STATEMENT>

*  Authors:
*     NG: Norman Gray (Starlink)
*     DSB: David Berry (Starlink)

*  History:
*    XX-Aug-2003 (NG):
*       Original version, drawing heavily on specframe.c.
*    20-MAY-2005 (NG):
*       Merged into main AST system.
*    25-MAY-2005 (DSB):
*       Extensive modifications to add extra timescales, unit support,
*       support for relative times, etc, and to make it more like the
*       other AST Frame classes.
*class--
*/

/* Module Macros. */
/* ============== */
/* Set the name of the class we are implementing. This indicates to
   the header files that define class interfaces that they should make
   "protected" symbols available. */
#define astCLASS TimeFrame

/* Define the first and last acceptable System values. */
#define FIRST_SYSTEM AST__MJD
#define LAST_SYSTEM AST__BEPOCH

/* Define the first and last acceptable TimeScale values. */
#define FIRST_TS AST__TAI
#define LAST_TS AST__TCG

/* Macros which return the maximum and minimum of two values. */
#define MAX(aa,bb) ((aa)>(bb)?(aa):(bb))
#define MIN(aa,bb) ((aa)<(bb)?(aa):(bb))

/* Macro to check for equality of floating point values. We cannot
   compare bad values directory because of the danger of floating point
   exceptions, so bad values are dealt with explicitly. */
#define EQUAL(aa,bb) (((aa)==AST__BAD)?(((bb)==AST__BAD)?1:0):(((bb)==AST__BAD)?0:(fabs((aa)-(bb))<=1.0E3*MAX((fabs(aa)+fabs(bb))*DBL_EPSILON,DBL_MIN))))

/* The supported time scales fall into two groups. Time scales in the
   first group depend on the clock position. That is, transformation
   between a time scale in one group and a timescale in the other group 
   requires the clock position, as does transformation between two time 
   scales within the first group. Define a macro which tests if a given 
   timescale belongs to the first group. */
#define CLOCK_SCALE(ts) \
      ( ( ts == AST__LMST || \
          ts == AST__LAST || \
          ts == AST__TDB || \
          ts == AST__TCB ) ? 1 : 0 )

/* Header files. */
/* ============= */
/* Interface definitions. */
/* ---------------------- */
#include "error.h"               /* Error reporting facilities */
#include "memory.h"              /* Memory allocation facilities */
#include "unit.h"                /* Units management facilities */
#include "object.h"              /* Base Object class */
#include "timemap.h"             /* Time coordinate Mappings */
#include "frame.h"               /* Parent Frame class */
#include "skyframe.h"            /* Celestial coordinate frames */
#include "timeframe.h"           /* Interface definition for this class */
#include "mapping.h"             /* Coordinate Mappings */
#include "cmpmap.h"              /* Compound Mappings */
#include "unitmap.h"             /* Unit Mappings */
#include "shiftmap.h"            /* Shift of origins */
#include "slalib.h"              /* SlaLib interface */


/* Error code definitions. */
/* ----------------------- */
#include "ast_err.h"             /* AST error codes */

/* C header files. */
/* --------------- */
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stddef.h>
#include <math.h>
#include <time.h>

/* Module Variables. */
/* ================= */
/* Define the class virtual function table and its initialisation flag as
   static variables. */
static AstTimeFrameVtab class_vtab; /* Virtual function table */
static int class_init = 0;          /* Virtual function table initialised? */

/* Define a variable to hold a SkyFrame which will be used for formatting
   and unformatting angular values. */
static AstSkyFrame *skyframe;      

/* Pointers to parent class methods which are used or extended by this
   class. */
static AstSystemType (* parent_getalignsystem)( AstFrame * );
static AstSystemType (* parent_getsystem)( AstFrame * );
static double (* parent_gap)( AstFrame *, int, double, int * );
static const char *(* parent_abbrev)( AstFrame *, int, const char *, const char *, const char * );
static const char *(* parent_format)( AstFrame *, int, double );
static const char *(* parent_getattrib)( AstObject *, const char * );
static const char *(* parent_getdomain)( AstFrame * );
static const char *(* parent_getlabel)( AstFrame *, int );
static const char *(* parent_getsymbol)( AstFrame *, int );
static const char *(* parent_gettitle)( AstFrame * );
static const char *(* parent_getunit)( AstFrame *, int );
static double (* parent_getepoch)( AstFrame * );
static int (* parent_match)( AstFrame *, AstFrame *, int **, int **, AstMapping **, AstFrame ** );
static int (* parent_subframe)( AstFrame *, AstFrame *, int, const int *, const int *, AstMapping **, AstFrame ** );
static int (* parent_testattrib)( AstObject *, const char * );
static int (* parent_unformat)( AstFrame *, int, const char *, double * );
static void (* parent_clearattrib)( AstObject *, const char * );
static void (* parent_clearsystem)( AstFrame * );
static void (* parent_overlay)( AstFrame *, const int *, AstFrame * );
static void (* parent_setattrib)( AstObject *, const char * );
static void (* parent_setmaxaxes)( AstFrame *, int );
static void (* parent_setminaxes)( AstFrame *, int );
static void (* parent_setsystem)( AstFrame *, AstSystemType );
static void (* parent_setunit)( AstFrame *, int, const char * );

/* Prototypes for Private Member Functions. */
/* ======================================== */
static AstMapping *MakeMap( AstTimeFrame *, AstSystemType, AstSystemType, AstTimeScaleType, AstTimeScaleType, double, double, const char *, const char *, const char * );
static AstSystemType GetAlignSystem( AstFrame * );
static AstSystemType SystemCode( AstFrame *, const char * );
static AstSystemType ValidateSystem( AstFrame *, AstSystemType, const char * );
static AstTimeScaleType TimeScaleCode( const char * );
static const char *DefUnit( AstSystemType, const char *, const char * );
static const char *GetDomain( AstFrame * );
static const char *GetLabel( AstFrame *, int );
static const char *GetSymbol( AstFrame *, int );
static const char *GetTitle( AstFrame * );
static const char *GetUnit( AstFrame *, int );
static const char *SystemLabel( AstSystemType );
static const char *SystemString( AstFrame *, AstSystemType );
static const char *TimeScaleString( AstTimeScaleType );
static double CurrentTime( AstTimeFrame * );
static double FromMJD( AstTimeFrame *, double );
static double GetEpoch( AstFrame * );
static double GetTimeOriginCur( AstTimeFrame * );
static double ToMJD( AstSystemType, double );
static double ToUnits( AstTimeFrame *, const char *, double, const char * );
static int DateFormat( const char *, int * );
static int GetActiveUnit( AstFrame * );
static int MakeTimeMapping( AstTimeFrame *, AstTimeFrame *, AstTimeFrame *, int, AstMapping ** );
static int Match( AstFrame *, AstFrame *, int **, int **, AstMapping **, AstFrame ** );
static int SubFrame( AstFrame *, AstFrame *, int, const int *, const int *, AstMapping **, AstFrame ** );
static int TestActiveUnit( AstFrame * );
static void Dump( AstObject *, AstChannel * );
static void OriginScale( AstTimeFrame *, AstTimeScaleType, const char * );
static void OriginSystem( AstTimeFrame *, AstSystemType, const char * );
static void Overlay( AstFrame *, const int *, AstFrame * );
static void SetMaxAxes( AstFrame *, int );
static void SetMinAxes( AstFrame *, int );
static void SetUnit( AstFrame *, int, const char * );
static void VerifyAttrs( AstTimeFrame *, const char *, const char *, const char * );
static AstMapping *ToMJDMap( AstSystemType, double );
static int Unformat( AstFrame *, int, const char *, double * );
static const char *Abbrev( AstFrame *, int, const char *, const char *, const char * );
static double Gap( AstFrame *, int, double, int * );

static AstSystemType GetSystem( AstFrame * );
static void SetSystem( AstFrame *, AstSystemType );
static void ClearSystem( AstFrame * );

static double GetTimeOrigin( AstTimeFrame * );
static int TestTimeOrigin( AstTimeFrame * );
static void ClearTimeOrigin( AstTimeFrame * );
static void SetTimeOrigin( AstTimeFrame *, double );

static const char *GetAttrib( AstObject *, const char * );
static int TestAttrib( AstObject *, const char * );
static void ClearAttrib( AstObject *, const char * );
static void SetAttrib( AstObject *, const char * );

static AstTimeScaleType GetAlignTimeScale( AstTimeFrame * );
static int TestAlignTimeScale( AstTimeFrame * );
static void ClearAlignTimeScale( AstTimeFrame * );
static void SetAlignTimeScale( AstTimeFrame *, AstTimeScaleType );

static AstTimeScaleType GetTimeScale( AstTimeFrame * );
static int TestTimeScale( AstTimeFrame * );
static void ClearTimeScale( AstTimeFrame * );
static void SetTimeScale( AstTimeFrame *, AstTimeScaleType );

static double GetClockLat( AstTimeFrame * );
static int TestClockLat( AstTimeFrame * );
static void ClearClockLat( AstTimeFrame * );
static void SetClockLat( AstTimeFrame *, double );

static double GetClockLon( AstTimeFrame * );
static int TestClockLon( AstTimeFrame * );
static void ClearClockLon( AstTimeFrame * );
static void SetClockLon( AstTimeFrame *, double );

/* Member functions. */
/* ================= */
static const char *Abbrev( AstFrame *this_frame, int axis,  const char *fmt, 
                           const char *str1, const char *str2 ) {
/*
*  Name:
*     Abbrev

*  Purpose:
*     Abbreviate a formatted Frame axis value by skipping leading fields.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *Abbrev( AstFrame *this, int axis, const char *fmt, 
*                         const char *str1, const char *str2 )

*  Class Membership:
*     TimeFrame member function (over-rides the astAbbrev protected
*     method inherited from the Frame class).

*  Description:
*     This function compares two Frame axis values that have been
*     formatted (using astFormat) and determines if they have any
*     redundant leading fields (i.e. leading fields in common which
*     can be suppressed when tabulating the values or plotting them on
*     the axis of a graph).

*  Parameters:
*     this
*        Pointer to the Frame.
*     axis
*        The number of the Frame axis for which the values have been
*        formatted (axis numbering starts at zero for the first axis).
*     fmt
*        Pointer to a constant null-terminated string containing the
*        format specification used to format the two values.
*     str1
*        Pointer to a constant null-terminated string containing the
*        first formatted value.
*     str1
*        Pointer to a constant null-terminated string containing the
*        second formatted value.

*  Returned Value:
*     A pointer into the "str2" string which locates the first
*     character in the first field that differs between the two
*     formatted values.
*
*     If the two values have no leading fields in common, the returned
*     value will point at the start of string "str2". If the two
*     values are equal, it will point at the terminating null at the
*     end of this string.

*  Notes:
*     - This function assumes that the format specification used was
*     the same when both values were formatted and that they both
*     apply to the same Frame axis.
*     - A pointer to the start of "str2" will be returned if this
*     function is invoked with the global error status set, or if it
*     should fail for any reason.
*-
*/

/* Local Variables: */
   const char *p1;               
   const char *p2;               
   const char *result;           
   int df;
   int nc1;
   int nc2;
   int ndp;            

/* Initialise. */
   result = str2;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Validate the axis index. */
   astValidateAxis( this_frame, axis, "astAbbrev" );

/* Use the parent astAbbrev function unless the Format attribute indicates 
   that axis values are to be formatted as multi-field date/time strings. */
   df = DateFormat( fmt, &ndp );
   if( !df ) {
      result = (*parent_abbrev)( this_frame, axis,  fmt, str1, str2 );

/* Otherwise. */
   } else {

/* Initialise pointers to the start of the next field in each string
   (skip leading spaces). */
      p1 = str1;
      p2 = str2;
      while( *p1 && isspace( *p1 ) ) p1++;
      while( *p2 && isspace( *p2 ) ) p2++;
            
/* Check the entire string */
      result = p2;
      while( *p1 && *p2 ) {

/* Each field in a date/time field consists of digits only. Find the
   number of leading digits in each string */
         nc1 = strspn( p1, "0123456789" );
         nc2 = strspn( p2, "0123456789" );

/* If the next field has different lengthsin the two strings, or of the 
   content of the fields differ, break out of th eloop, leaving "result"
   pointing to the start of the current field. */
         if( nc1 != nc2 || strncmp( p1, p2, nc1 ) ) {
            break;

/* If the next field is identical in the two strings, skip to the
   character following the end of the field. */
         } else {
            p1 += nc1;
            p2 += nc2;

/* Skip inter-field (non-numeric) delimiters. */
            p1 += strcspn( p1, "0123456789" );
            p2 += strcspn( p2, "0123456789" );
         }

/* Prepare to check the next field. */
         result = p2;
      }
   }

/* If an error occurred, clear the returned value. */
   if ( !astOK ) result = str2;

/* Return the result. */
   return result;
}

static int DateFormat( const char *fmt, int *ndp ){
/*
*  Name:
*     DateFormat

*  Purpose:
*     Determine if TimeFrame values should be formatted as a date.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     int DateFormat( const char *fmt, int *ndp )

*  Class Membership:
*     TimeFrame member function 

*  Description:
*    This function returns a flag indicating if the supplied Format string
*    requires the TimeFrame value to be formatted as a date and/or time of 
*    day.

*  Parameters:
*     fmt
*        Pointer to Format string.
*     ndp
*        A pointer to an integer in which is returned a value indicating
*        if a time is required as well as a date. A value of -1 will be
*        returned in no time is required, otherwise the returned value will 
*        equal the number of decimal places required for the seconds field.

*  Returned Value:
*     Non-zero if the formatted TimeFrame value should include a date.

*/

/* Local Variables: */
   const char *c;
   int result;

/* Initialise  */
   result = 0;
   *ndp = -1;

/* Check the Format string */
   if( fmt ) {

/* Find the first non-white character */
      c = fmt;
      while( *c && isspace( *c ) ) c++;

/* If the first non-white character starts the string "iso" 
   assume a date is required. If so see if a time is also required 
   (indicated by 1 dot following) and how many seconds of precision are 
   required (the interegr following the dot). */
      if( !strncmp( c, "iso", 3 ) ) {
         result = 1;
         if( 1 != sscanf( c, "iso.%d", ndp ) ) *ndp = -1;
      }
   }

   return result;
}

static void ClearAttrib( AstObject *this_object, const char *attrib ) {
/*
*  Name:
*     ClearAttrib

*  Purpose:
*     Clear an attribute value for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void ClearAttrib( AstObject *this, const char *attrib )

*  Class Membership:
*     TimeFrame member function (over-rides the astClearAttrib protected
*     method inherited from the Frame class).

*  Description:
*     This function clears the value of a specified attribute for a
*     TimeFrame, so that the default value will subsequently be used.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     attrib
*        Pointer to a null terminated string specifying the attribute
*        name.  This should be in lower case with no surrounding white
*        space.

*  Notes:
*     - This function uses one-based axis numbering so that it is
*     suitable for external (public) use.
*/

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to the TimeFrame structure */
   char *new_attrib;             /* Pointer value to new attribute name */
   int len;                      /* Length of attrib string */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_object;

/* Obtain the length of the "attrib" string. */
   len = strlen( attrib );

/* Check the attribute name and clear the appropriate attribute. */

/* First look for axis attributes defined by the Frame class. Since a
   TimeFrame has only 1 axis, we allow these attributes to be specified
   without a trailing "(axis)" string. */
   if ( !strcmp( attrib, "direction" ) || 
        !strcmp( attrib, "bottom" ) ||
        !strcmp( attrib, "top" ) ||
        !strcmp( attrib, "format" ) ||
        !strcmp( attrib, "label" ) ||
        !strcmp( attrib, "symbol" ) ||
        !strcmp( attrib, "unit" ) ) {

/* Create a new attribute name from the original by appending the string
   "(1)" and then use the parent ClearAttrib method. */
      new_attrib = astMalloc( len + 4 );
      if( new_attrib ) {
         memcpy( new_attrib, attrib, len );
         memcpy( new_attrib + len, "(1)", 4 ); 
         (*parent_clearattrib)( this_object, new_attrib );
         new_attrib = astFree( new_attrib );
      }

/* AlignTimeScale. */
/* --------------- */
   } else if ( !strcmp( attrib, "aligntimescale" ) ) {
      astClearAlignTimeScale( this );

/* ClockLat. */
/* ------- */
   } else if ( !strcmp( attrib, "clocklat" ) ) {
      astClearClockLat( this );

/* ClockLon. */
/* ------- */
   } else if ( !strcmp( attrib, "clocklon" ) ) {
      astClearClockLon( this );

/* TimeOrigin. */
/* ---------- */
   } else if ( !strcmp( attrib, "timeorigin" ) ) {
      astClearTimeOrigin( this );

/* TimeScale. */
/* ---------- */
   } else if ( !strcmp( attrib, "timescale" ) ) {
      astClearTimeScale( this );

/* If the attribute is not recognised, pass it on to the parent method
   for further interpretation. */
   } else {
      (*parent_clearattrib)( this_object, attrib );
   }
}

static void ClearSystem( AstFrame *this_frame ) {
/*
*  Name:
*     ClearSystem

*  Purpose:
*     Clear the System attribute for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void ClearSystem( AstFrame *this_frame )

*  Class Membership:
*     TimeFrame member function (over-rides the astClearSystem protected
*     method inherited from the Frame class).

*  Description:
*     This function clears the System attribute for a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*/

/* Local Variables: */
   AstSystemType oldsys;         /* System before clearing */
   AstTimeFrame *this;           /* Pointer to TimeFrame structure */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* Save the original system */
   oldsys = astGetSystem( this_frame );

/* Use the parent ClearSystem method to clear the System value. */
   (*parent_clearsystem)( this_frame );

/* Do nothing more if the system has not actually changed. */
   if( astGetSystem( this_frame ) != oldsys ) {

/* Modify the TimeOrigin value to use the new System */
      OriginSystem( this, oldsys, "astClearSystem" );

/* Clear attributes which have system-specific defaults. */
      astClearLabel( this_frame, 0 );
      astClearSymbol( this_frame, 0 );
      astClearTitle( this_frame );

/* If the old system was BEPOCH also clear units and timescale. This is
   because we need to ensure that TimeScale=TT and Unit=yr will be used
   in future (these are the only acceptable values for System=BEPOCH). */
      if( oldsys == AST__BEPOCH ) {
         astClearUnit( this_frame, 0 );
         astClearTimeScale( (AstTimeFrame *) this_frame );
      }
   }
}

static void ClearTimeScale( AstTimeFrame *this ) {
/*
*+
*  Name:
*     astClearTimeScale

*  Purpose:
*     Clear the TimeScale attribute for a TimeFrame.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "timeframe.h"
*     void astClearTimeScale( AstTimeFrame *this )

*  Class Membership:
*     TimeFrame virtual function 

*  Description:
*     This function clears the TimeScale attribute for a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*-
*/

/* Check the global error status. */
   if ( !astOK ) return;

/* If the System is currently set to BEPOCH, then the TimeScale will
   either be set to TT or will be unset (since SetTimeScale will not
   allow any other value than TT if the System is BEPOCH). Therefore, if
   System is BEPOCH, we will not need to modify the TimeOrigin value,
   since it will already be appropriate. Otherwise, we modify the
   TimeOrigin value stored in the TimeFrame structure to refer to the 
   default timescale (TAI or TT). */
   if( astGetSystem( this ) != AST__BEPOCH ) OriginScale( this, AST__TAI, 
                                                     "astClearTimeScale" );

/* Store a bad value for the timescale in the TimeFrame structure. */
   this->timescale = AST__BADTS;
}

static double CurrentTime( AstTimeFrame *this ){
/*
*++
*  Name:
c     astCurrentTime
f     AST_CURRENTTIME

*  Purpose:
*     Return the current system time.

*  Type:
*     Public virtual function.

*  Synopsis:
c     #include "timeframe.h"
c     double astCurrentTime( AstTimeFrame *this )
f     RESULT = AST_CURRENTTIME( THIS, STATUS )

*  Class Membership:
*     TimeFrame method.

*  Description:
c     This function 
f     This routine 
*     returns the current system time, represented in the form specified
*     by the supplied TimeFrame. That is, the returned floating point
*     value should be interpreted using the attribute values of the
*     TimeFrame. This includes System, TimeOrigin, TimeScale, and Unit.

*  Parameters:
c     this
f     THIS = INTEGER (Given)
*        Pointer to the TimeFrame.
f     STATUS = INTEGER (Given and Returned)
f        The global status.

*  Returned Value:
c     astCurrentTime()
f     AST_CURRENTTIME = DOUBLE
c        A TimeFrame axis value representing the current system time.

*  Notes:
*     - Values of AST__BAD will be returned if this function is
c     invoked with the AST error status set, or if it should fail for
f     invoked with STATUS set to an error value, or if it should fail for
*     any reason.
*     - It is assumes that the system time (returned by the C time()
*     function) follows the POSIX standard, representing a continuous 
*     monotonic increasing count of SI seconds since the epoch 00:00:00 
*     UTC 1 January 1970 AD (equivalent to TAI with a constant offset).
*     Resolution is one second.
*     - An error will be reported if the TimeFrame has a TimeScale value
*     which cannot be converted to TAI (e.g. "angular" systems such as
*     UT1, GMST, LMST and LAST).
*     - Any inaccuracy in the system clock will be reflected in the value
*     returned by this function.
*--
*/

/* Local Constants: */

/* The Unix epoch (00:00:00 UTC 1 January 1970 AD) as an absolute MJD in
   the UTC timescale. */
#define UNIX_EPOCH 40587.0
   
/* Local Variables: */
   AstMapping *map;
   double result;
   double systime;
   double utc_epoch;   
   static double tai_epoch;   
   static int init = 0;   

/* Initialise. */
   result = AST__BAD;

/* Check the global error status. */
   if ( !astOK ) return result;

/* If not already done, convert the Unix Epoch (00:00:00 UTC 1 January
   1970 AD) from UTC to TAI. */
   if( !init ) {
      map = MakeMap( this, AST__MJD, AST__MJD, AST__UTC, AST__TAI,
                     0.0, 0.0, "d", "d", "astCurrentTime" );
      utc_epoch = UNIX_EPOCH;
      astTran1( map, 1, &utc_epoch, 1, &tai_epoch );
      map = astAnnul( map );
      if( astOK ) init = 1;
   }

/* Get a Mapping from the system time (TAI seconds relative to "tai_epoch")
   to the system represented by the supplied TimeFrame. */
   map = MakeMap( this, AST__MJD, astGetSystem( this ), 
                  AST__TAI, astGetTimeScale( this ),
                  tai_epoch, astGetTimeOrigin( this ),
                  "s", astGetUnit( this, 0 ), "astCurrentTime" );
   if( !map ) {
      astError( AST__INCTS, "astCurrentTime(%s): Cannot convert the "
                "current system time to the required timescale (%s).",
                astGetClass( this ), 
                TimeScaleString( astGetTimeScale( this ) ) );

/* Get the system time. The "time" function returns a "time_t" which may be
   encoded in any way. We use "difftime" to convert this into a floating
   point number of seconds by taking the difference between the current
   time and zero time. This assumes nothing about the structure of a
  "time_t" except that zero can be cast into a time_t representing
   the epoch. */
   } else {
      systime = difftime( time( NULL ), (time_t) 0 );

/* Use the Mapping to convert the time into the requied system. */
      astTran1( map, 1, &systime, 1, &result );

/* Free resources */
      map = astAnnul( map );
   }

/* Set result to AST__BAD if an error occurred. */
   if( !astOK ) result = AST__BAD;   

/* Return the result. */
   return result;

/* Undefine local constants */
#undef UNIX_EPOCH 

}

static const char *DefUnit( AstSystemType system, const char *method,
                            const char *class ){
/*
*  Name:
*     DefUnit

*  Purpose:
*     Return the default units for a time coordinate system type.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *DefUnit( AstSystemType system, const char *method,
*                          const char *class )

*  Class Membership:
*     TimeFrame member function.

*  Description:
*     This function returns a textual representation of the default 
*     units associated with the specified time coordinate system.

*  Parameters:
*     system
*        The time coordinate system.
*     method
*        Pointer to a string holding the name of the calling method.
*        This is only for use in constructing error messages.
*     class 
*        Pointer to a string holding the name of the supplied object class.
*        This is only for use in constructing error messages.

*  Returned Value:
*     A string describing the default units. This string follows the
*     units syntax described in FITS WCS paper I "Representations of world
*     coordinates in FITS" (Greisen & Calabretta).

*  Notes:
*     - A NULL pointer is returned if this function is invoked with
*     the global error status set or if it should fail for any reason.
*/

/* Local Variables: */
   const char *result;           /* Value to return */

/* Initialize */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get an identifier for the default units. */
   if( system == AST__MJD ) {
      result = "d";
   } else if( system == AST__JD ) {
      result = "d";
   } else if( system == AST__BEPOCH ) {
      result = "yr";
   } else if( system == AST__JEPOCH ) {
      result = "yr";

/* Report an error if the coordinate system was not recognised. */
   } else {
      astError( AST__SCSIN, "%s(%s): Corrupt %s contains illegal System "
                "identification code (%d).", method, class, class, 
                (int) system );
   }

/* Return the result. */
   return result;
}

static const char *Format( AstFrame *this_frame, int axis, double value ) {
/*
*  Name:
*     Format

*  Purpose:
*     Format a coordinate value for a TimeFrame axis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *Format( AstFrame *this, int axis, double value )

*  Class Membership:
*     TimeFrame member function (over-rides the astFormat method inherited
*     from the Frame class).

*  Description:
*     This function returns a pointer to a string containing the formatted
*     (character) version of a coordinate value for a TimeFrame axis. The
*     formatting applied is that specified by a previous invocation of the
*     astSetFormat method. A suitable default format is applied if necessary.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     axis
*        The number of the axis (zero-based) for which formatting is to be
*        performed.
*     value
*        The coordinate value to be formatted, in radians.

*  Returned Value:
*     A pointer to a null-terminated string containing the formatted value.

*  Notes:
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstMapping *map;       
   AstSystemType sys;
   AstTimeFrame *this;    
   AstTimeScaleType ts;   
   char *d;    
   static char buf[ 200 ];
   static char tbuf[ 100 ];
   char sign[ 2 ];
   const char *fmt;    
   const char *result;    
   const char *u;
   double fd;
   double mjd;            
   double off;
   int df;
   int id;
   int ihmsf[ 4 ];    
   int im;
   int iy;
   int j;
   int ndp;               
   int tlen;

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* Validate the axis index. */
   (void) astValidateAxis( this, axis, "astFormat" );

/* If the format string does not indicate a date/time format, invoke the
   parent Format method. */
   fmt = astGetFormat( this, 0 );
   df = DateFormat( fmt, &ndp );
   if( !df ) {
      result = (*parent_format)( this_frame, axis, value );

/* Otherwise, format the value as a date/time */
   } else {

/* Convert the value to an absolute MJD in units of days. */
      ts = astGetTimeScale( this );
      sys = astGetSystem( this );
      off = astGetTimeOrigin( this );
      u = astGetUnit( this, 0 );
      map = MakeMap( this, sys, AST__MJD, ts, ts, off, 0.0, u, "d", 
                     "astFormat" );
      if( map ) {
         astTran1( map, 1, &value, 1, &mjd );
         map = astAnnul( map );

/* If no time fields will be produced, round to the nearest day. */
         if( ndp < 0 ) mjd = (int) ( mjd + 0.5 );

/* Convert the MJD into a set of numeric date fields, plus day fraction,
   and format them. */
         slaDjcl( mjd, &iy, &im, &id, &fd, &j );
         d = buf;
         d += sprintf( d, "%4d-%2.2d-%2.2d", iy, im, id );

/* If required, convert the day fraction into a set of numerical time
   fields. */
         if( ndp >= 0 ) {
            slaDd2tf( ndp, fd, sign, ihmsf );

/* Format the time fields. */
            if( ndp > 0 ) {
               tlen = sprintf( tbuf, " %2.2d:%2.2d:%2.2d.%*.*d", ihmsf[0],
                             ihmsf[1], ihmsf[2], ndp, ndp, ihmsf[3] );
            } else {
               tlen = sprintf( tbuf, " %2.2d:%2.2d:%2.2d", ihmsf[0],
                             ihmsf[1], ihmsf[2] );
            }

/* Add in the formatted time. */
            d += sprintf( d, "%s", tbuf );

         }
         result = buf;         
      }
   }

/* If an error occurred, clear the returned value. */
   if ( !astOK ) result = NULL;

/* Return the result. */
   return result;
}

static double FromMJD( AstTimeFrame *this, double oldval ){
/*
*
*  Name:
*     FromMJD

*  Purpose:
*     Convert a supplied MJD value to the System of the supplied TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     double FromMJD( AstTimeFrame *this, double oldval )

*  Class Membership:
*     TimeFrame member function 

*  Description:
*     This function converts the supplied time value from an MJD to 
*     the System of the supplied TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     oldval
*        The value to be converted. It is assume to be an absolute MJD
*        value (i.e. zero offset) in units of days.

*  Returned Value:
*     The converted value (with zero offset), in the default units
*     associated with the System of "this".

*/

/* Local Variables: */
   AstTimeMap *timemap;
   AstSystemType newsys;
   double args[ 2 ];
   double result;              
   
/* Initialise. */
   result = AST__BAD;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get the System attribute from the supplied TimeFrame. */
   newsys = astGetSystem( this );

/* If this is MJD just return the value unchanged. */
   if( newsys == AST__MJD ) {
      result = oldval;

/* Otherwise create a TimeMap wich converts from the MJD to the required
   system, and use it to transform the supplied value. */
   } else {
      timemap = astTimeMap( 0, "" );

/* The supplied and returned values are assumed to have zero offset.*/
      args[ 0 ] = 0.0;
      args[ 1 ] = 0.0;

/* If required, add a TimeMap conversion which converts from MJD to the
   new system. */
      if( newsys == AST__JD ) {
         astTimeAdd( timemap, "MJDTOJD", args );

      } else if( newsys == AST__JEPOCH ) {
         astTimeAdd( timemap, "MJDTOJEP", args );

      } else if( newsys == AST__BEPOCH ) {
         astTimeAdd( timemap, "MJDTOBEP", args );
      }

/* Use the TimeMap to convert the supplied value. */
      astTran1( timemap, 1, &oldval, 1, &result );

/* Free resources */
      timemap = astAnnul( timemap );

   }

/* Return the result */
   return result;
}


static double Gap( AstFrame *this_frame, int axis, double gap, int *ntick ) {
/*
*  Name:
*     Gap

*  Purpose:
*     Find a "nice" gap for tabulating Frame axis values.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     double Gap( AstFrame *this, int axis, double gap, int *ntick )

*  Class Membership:
*     TimeFrame member function (over-rides the astGap protected
*     method inherited from the Frame class).

*     This function returns a gap size which produces a nicely spaced
*     series of formatted values for a Frame axis, the returned gap
*     size being as close as possible to the supplied target gap
*     size. It also returns a convenient number of divisions into
*     which the gap can be divided.

*  Parameters:
*     this
*        Pointer to the Frame.
*     axis
*        The number of the axis (zero-based) for which a gap is to be found.
*     gap
*        The target gap size.
*     ntick
*        Address of an int in which to return a convenient number of
*        divisions into which the gap can be divided.

*  Returned Value:
*     The nice gap size.

*  Notes:
*     - A value of zero is returned if the target gap size is zero.
*     - A negative gap size is returned if the supplied gap size is negative.
*     - A value of zero will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Variables: */
   AstMapping *map;
   AstTimeFrame *this;           
   AstTimeScaleType ts;
   const char *fmt;
   double mjdgap;
   double result;           
   double xin[2];
   double xout[2];
   int df;
   int ndp;

/* Initialise. */
   result = 0.0;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Validate the axis index. */
   astValidateAxis( this_frame, axis, "astGap" );

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* Use the parent astGap function unless the Format attribute indicates 
   that axis values are to be formatted as multi-field date/time strings. */
   fmt = astGetFormat( this, 0 );
   df = DateFormat( fmt, &ndp );
   if( !df ) {
      result = (*parent_gap)( this_frame, axis, gap, ntick );

/* Otherwise. */
   } else {
     
/* Get a Mapping which converts TimeFrame values to MJD values. */
      ts = astGetTimeScale( this );
      map = MakeMap( this, astGetSystem( this ), AST__MJD, ts, ts, 
                     astGetTimeOrigin( this ), 0.0, astGetUnit( this, 0 ), 
                     "d", "astGap" );
      if( map ) {

/* Use it to transform two TimeFrame times to MJD. The first is the
   current time, and the second is the current time plus the target gap. */
         xin[ 0 ] = astCurrentTime( this );
         xin[ 1 ] = xin[ 0 ] + gap;    
         astTran1( map, 2, xin, 1, xout );

/* Find the target MJD gap. */
         mjdgap = xout[ 1 ] - xout[ 0 ];

/* If it is 1 year or more, use the parent astGap method to find a nice
   number of years, and convert back to days. */
         if( mjdgap >= 365.25 ) {
            mjdgap = 365.25*(*parent_gap)( this_frame, axis, mjdgap/365.25, ntick );

/* If it is more than 19 days use 1 year. */
         } else if( mjdgap > 19.0 ) {
            mjdgap = 365.25;
            *ntick = 4;

/* If it is more than 0.5 of a day use 1 day. */
         } else if( mjdgap > 0.5 ) {
            mjdgap = 1.0;
            *ntick = 4;

/* Otherwise, if the format indicates that no time field is allowed, 
   use 1 day. */
         } else if( ndp < 0 ) {
            mjdgap = 1.0;
            *ntick = 2;

/* Otherwise (i.e. if the target gap is 0.5 day or less and the format 
   indicates that a time field is allowed), choose a value which looks
   nice. */
         } else if( mjdgap >= 6.0/24.0 ) {    /* 12 hours */
            mjdgap = 12.0/24.0;
            *ntick = 4;
    
         } else if( mjdgap >= 3.0/24.0 ) {     /* 6 hours */
            mjdgap = 6.0/24.0;
            *ntick = 3;
    
         } else if( mjdgap >= 1.0/24.0 ) {     /* 2 hours */
            mjdgap = 2.0/24.0;
            *ntick = 4;
    
         } else if( mjdgap >= 15.0/1440.0 ) {  /* 30 minutes */
            mjdgap = 30.0/1440.0;
            *ntick = 3;
    
         } else if( mjdgap >= 5.0/1440.0 ) {  /* 10 minutes */
            mjdgap = 10.0/1440.0;
            *ntick = 5;
    
         } else if( mjdgap >= 0.5/1440.0 ) {   /* 1 minute */
            mjdgap = 1.0/1440.0;
            *ntick = 4;

         } else if( mjdgap >= 15.0/86400.0 ) { /* 30 seconds */
            mjdgap = 30.0/86400.0;
            *ntick = 3;
    
         } else if( mjdgap >= 5.0/86400.0 ) { /* 10 seconds */
            mjdgap = 10.0/86400.0;
            *ntick = 5;
    
         } else if( mjdgap >= 0.5/86400.0 ) {  /* 1 second */
            mjdgap = 1.0/86400.0;
            *ntick = 4;
    
         } else {                              /* Less than 1 second */
            mjdgap = 86400.0*(*parent_gap)( this_frame, axis, mjdgap/86400.0, ntick );

         }              

/* Convert the MJD gap back into the system of the supplied TimeFrame. */
         xout[ 1 ] = xout[ 0 ] + mjdgap;
         astTran1( map, 2, xout, 0, xin );
         result = xin[ 1 ] - xin[ 0 ];

/* Free resources */
         map = astAnnul( map );

/* If no Mapping could be found, use the parent astGap method. */
      } else {
         result = (*parent_gap)( this_frame, axis, gap, ntick );
      }
   }

/* If an error occurred, clear the returned value. */
   if ( !astOK ) result = 0.0;

/* Return the result. */
   return result;
}

static int GetActiveUnit( AstFrame *this_frame ) {
/*
*  Name:
*     GetActiveUnit

*  Purpose:
*     Obtain the value of the ActiveUnit flag for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     int GetActiveUnit( AstFrame *this_frame ) 

*  Class Membership:
*     TimeFrame member function (over-rides the astGetActiveUnit protected
*     method inherited from the Frame class).

*  Description:
*    This function returns the value of the ActiveUnit flag for a
*    TimeFrame, which is always 1.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     The value to use for the ActiveUnit flag (1).

*/
   return 1;
}

static const char *GetAttrib( AstObject *this_object, const char *attrib ) {
/*
*  Name:
*     GetAttrib

*  Purpose:
*     Get the value of a specified attribute for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *GetAttrib( AstObject *this, const char *attrib )

*  Class Membership:
*     TimeFrame member function (over-rides the protected astGetAttrib
*     method inherited from the Frame class).

*  Description:
*     This function returns a pointer to the value of a specified
*     attribute for a TimeFrame, formatted as a character string.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     attrib
*        Pointer to a null-terminated string containing the name of
*        the attribute whose value is required. This name should be in
*        lower case, with all white space removed.

*  Returned Value:
*     - Pointer to a null-terminated string containing the attribute
*     value.

*  Notes:
*     - This function uses one-based axis numbering so that it is
*     suitable for external (public) use.
*     - The returned string pointer may point at memory allocated
*     within the TimeFrame, or at static memory. The contents of the
*     string may be over-written or the pointer may become invalid
*     following a further invocation of the same function or any
*     modification of the TimeFrame. A copy of the string should
*     therefore be made if necessary.
*     - A NULL pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Constants: */
#define BUFF_LEN 50              /* Max. characters in result buffer */

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to the TimeFrame structure */
   AstTimeScaleType ts;          /* Time scale */
   char *new_attrib;             /* Pointer value to new attribute name */
   const char *result;           /* Pointer value to return */
   double dval;                  /* Attribute value */
   int len;                      /* Length of attrib string */
   static char buff[ BUFF_LEN + 1 ]; /* Buffer for string result */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_object;

/* Obtain the length of the attrib string. */
   len = strlen( attrib );

/* Compare "attrib" with each recognised attribute name in turn,
   obtaining the value of the required attribute. If necessary, write
   the value into "buff" as a null-terminated string in an appropriate
   format.  Set "result" to point at the result string. */

/* First look for axis attributes defined by the Frame class. Since a
   TimeFrame has only 1 axis, we allow these attributes to be specified
   without a trailing "(axis)" string. */
   if ( !strcmp( attrib, "direction" ) || 
        !strcmp( attrib, "bottom" ) ||
        !strcmp( attrib, "top" ) ||
        !strcmp( attrib, "format" ) ||
        !strcmp( attrib, "label" ) ||
        !strcmp( attrib, "symbol" ) ||
        !strcmp( attrib, "unit" ) ) {

/* Create a new attribute name from the original by appending the string
   "(1)" and then use the parent GetAttrib method. */
      new_attrib = astMalloc( len + 4 );
      if( new_attrib ) {
         memcpy( new_attrib, attrib, len );
         memcpy( new_attrib + len, "(1)", 4 ); 
         result = (*parent_getattrib)( this_object, new_attrib );
         new_attrib = astFree( new_attrib );
      }

/* AlignTimeScale. */
/* --------------- */
/* Obtain the AlignTimeScale code and convert to a string. */
   } else if ( !strcmp( attrib, "aligntimescale" ) ) {
      ts = astGetAlignTimeScale( this );
      if ( astOK ) {
         result = TimeScaleString( ts );

/* Report an error if the value was not recognised. */
         if ( !result ) {
            astError( AST__SCSIN,
                     "astGetAttrib(%s): Corrupt %s contains invalid AlignTimeScale "
                     "identification code (%d).", astGetClass( this ), 
                     astGetClass( this ), (int) ts );
         }
      }

/* ClockLat. */
/* ------- */
   } else if ( !strcmp( attrib, "clocklat" ) ) {
      dval = astGetClockLat( this );
      if ( astOK ) {

/* Display absolute value preceeded by "N" or "S" as appropriate. */
         if( dval < 0 ) {         
            (void) sprintf( buff, "S%s",  astFormat( skyframe, 1, -dval ) );
         } else {
            (void) sprintf( buff, "N%s",  astFormat( skyframe, 1, dval ) );
         }
         result = buff;
      }

/* ClockLon. */
/* ------- */
   } else if ( !strcmp( attrib, "clocklon" ) ) {
      dval = astGetClockLon( this );
      if ( astOK ) {

/* Put into range +/- PI. */
         dval = slaDrange( dval );

/* Temporarily make the SkyFrame use degrees for longitude axis. */
         astSetAsTime( skyframe, 0, 0 );

/* Display absolute value preceeded by "E" or "W" as appropriate. */
         if( dval < 0 ) {         
            (void) sprintf( buff, "W%s",  astFormat( skyframe, 0, -dval ) );
         } else {
            (void) sprintf( buff, "E%s",  astFormat( skyframe, 0, dval ) );
         }
         result = buff;

/* Make the SkyFrame use hours for longitude axis again. */
         astSetAsTime( skyframe, 0, 1 );

      }

/* TimeOrigin. */
/* ----------- */
   } else if ( !strcmp( attrib, "timeorigin" ) ) {
      dval = GetTimeOriginCur( this );
      if( astOK ) {
         (void) sprintf( buff, "%.*g", DBL_DIG, dval );
         result = buff;
      }

/* TimeScale. */
/* ---------- */
/* Obtain the TimeScale code and convert to a string. */
   } else if ( !strcmp( attrib, "timescale" ) ) {
      ts = astGetTimeScale( this );
      if ( astOK ) {
         result = TimeScaleString( ts );

/* Report an error if the value was not recognised. */
         if ( !result ) {
            astError( AST__SCSIN,
                     "astGetAttrib(%s): Corrupt %s contains invalid TimeScale "
                     "identification code (%d).", astGetClass( this ), 
                     astGetClass( this ), (int) ts );
         }
      }

/* If the attribute name was not recognised, pass it on to the parent
   method for further interpretation. */
   } else {
      result = (*parent_getattrib)( this_object, attrib );
   }

/* Return the result. */
   return result;

/* Undefine macros local to this function. */
#undef BUFF_LEN
}

static double GetTimeOriginCur( AstTimeFrame *this ) {
/*
*  Name:
*     GetTimeOriginCur

*  Purpose:
*     Obtain the TimeOrigin attribute for a TimeFrame in current units.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     double GetTimeOriginCur( AstTimeFrame *this )

*  Class Membership:
*     TimeFrame virtual function 

*  Description:
*     This function returns the TimeOrigin attribute for a TimeFrame, in
*     the current units of the TimeFrame. The protected astGetTimeOrigin
*     method can be used to obtain the time origin in the defaultunits of 
*     the TimeFrame's System.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     The TimeOrigin value, in the units, system and timescale specified
*     by the current values of the Unit, System and TimeScale attributes
*     within "this".

*  Notes:
*     - AST__BAD is returned if this function is invoked with
*     the global error status set or if it should fail for any reason.
*/

/* Local Variables: */
   AstMapping *map;
   const char *cur;
   const char *def;
   double result;         
   double defval;

/* Initialise. */
   result = AST__BAD;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get the value in the default units */
   result = astGetTimeOrigin( this );

/* If non-zero we convert to the current units.*/
   if( result != 0.0 && result != AST__BAD ) {

/* Get the default units for the TimeFrame's System. */
      def = DefUnit( astGetSystem( this ), "astGetTimeOrigin", "TimeFrame" );

/* Get the current units from the TimeFrame. */
      cur = astGetUnit( this, 0 );

/* If the units differ, get a Mapping from default to current units. */
      if( cur && def ){
         if( strcmp( cur, def ) ) {
            map = astUnitMapper( def, cur, NULL, NULL );

/* Report an error if the units are incompatible. */
            if( !map ) {
               astError( AST__BADUN, "%s(%s): The current units (%s) are not suitable "
                         "for a TimeFrame.", "astGetTimeOrigin", astGetClass( this ), 
                         cur );

/* Otherwise, transform the stored origin value.*/
            } else {
               defval = result;
               astTran1( map, 1, &defval, 1, &result );
               map = astAnnul( map );
            }
         }
      }
   }

/* Return the result. */
   return result;
}

static const char *GetDomain( AstFrame *this_frame ) {
/*
*  Name:
*     GetDomain

*  Purpose:
*     Obtain a pointer to the Domain attribute string for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *GetDomain( AstFrame *this )

*  Class Membership:
*     TimeFrame member function (over-rides the astGetDomain protected
*     method inherited from the Frame class).

*  Description:
*    This function returns a pointer to the Domain attribute string
*    for a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     A pointer to a constant null-terminated string containing the
*     Domain value.

*  Notes:
*     - The returned pointer or the string it refers to may become
*     invalid following further invocation of this function or
*     modification of the TimeFrame.
*     - A NULL pointer is returned if this function is invoked with
*     the global error status set or if it should fail for any reason.
*/

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to TimeFrame structure */
   const char *result;           /* Pointer value to return */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* If a Domain attribute string has been set, invoke the parent method
   to obtain a pointer to it. */
   if ( astTestDomain( this ) ) {
      result = (*parent_getdomain)( this_frame );

/* Otherwise, provide a pointer to a suitable default string. */
   } else {
      result = "TIME";
   }

/* Return the result. */
   return result;
}

static double GetEpoch( AstFrame *this_frame ) {
/*
*  Name:
*     GetEpoch

*  Purpose:
*     Get a value for the Epoch attribute of a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     double GetEpoch( AstFrame *this )

*  Class Membership:
*     TimeFrame member function (over-rides the astGetEpoch method
*     inherited from the Frame class).

*  Description:
*     This function returns a value for the Epoch attribute of a
*     TimeFrame.  

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     The Epoch attribute value.

*  Notes:
*     - A value of AST__BAD will be returned if this function is invoked
*     with the global error status set or if it should fail for any
*     reason.
*/

/* Local Variables: */
   AstMapping *map;
   AstSystemType sys;
   AstTimeFrame *this;
   AstTimeScaleType ts;
   const char *u;
   double oldval;
   double result;   

/* Initialise. */
   result = AST__BAD;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* If an Epoch attribute value has been set, invoke the parent method
   to obtain it. */
   if ( astTestEpoch( this ) ) {
      result = (*parent_getepoch)( this_frame );

/* Otherwise, if the TimeOrigin value is set in the TimeFrame,
   return it, converted to an absolute TDB MJD. */
   } else if( astTestTimeOrigin( this ) ){

/* Get the required properties of the TimeFrame. */
      oldval = astGetTimeOrigin( this );
      ts = astGetTimeScale( this );
      sys = astGetSystem( this );
      u = DefUnit( sys, "astGetEpoch", "TimeFrame" );

/* Epoch is defined as a TDB value. If the timescale is stored in an angular 
   timescale such as UT1, then we would not normally be able to convert it
   to TDB since knowledge of DUT1 is required (the difference between UTC
   and UT1). Since the default Epoch value is not critical we assume a DUT1 
   value of zero in this case. We first map the stored value to UT1 then 
   from UTC to TDB (using the approximation UT1 == UTC). */
      if( ts == AST__UT1 || ts == AST__GMST || 
          ts == AST__LAST || ts == AST__LMST ) {
         map = MakeMap( this, sys, AST__MJD, ts, AST__UT1, 0.0, 0.0, u,
                        "d", "astGetEpoch" );
         if( map ) {
            astTran1( map, 1, &oldval, 1, &result );
            map = astAnnul( map );

/* Update the values to use when converting to TBD. */
            oldval = result;
            ts = AST__UTC;
            sys = AST__MJD;
            u = "d";

         } else if( astOK ) {
            astError( AST__INTER, "astGetEpoch(%s): No Mapping from %s to "
                      "UT1 (AST internal programming error).", 
                      astGetClass( this ), TimeScaleString(  ts ) );
         }
      }

/* Now convert to TDB */
      map = MakeMap( this, sys, AST__MJD, ts, AST__TDB, 0.0, 0.0, u,
                     "d", "astGetEpoch" );
      if( map ) {
         oldval = astGetTimeOrigin( this );
         astTran1( map, 1, &oldval, 1, &result );
         map = astAnnul( map );

      } else if( astOK ) {
         astError( AST__INTER, "astGetEpoch(%s): No Mapping from %s to "
                   "TDB (AST internal programming error).", 
                   astGetClass( this ), TimeScaleString(  ts ) );
      }

/* Otherwise, return the default Epoch value from the parent Frame. */
   } else {
      result =  (*parent_getepoch)( this_frame );
   }

/* Return the result. */
   return result;
}

static const char *GetLabel( AstFrame *this, int axis ) {
/*
*  Name:
*     GetLabel

*  Purpose:
*     Access the Label string for a TimeFrame axis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *GetLabel( AstFrame *this, int axis )

*  Class Membership:
*     TimeFrame member function (over-rides the astGetLabel method inherited
*     from the Frame class).

*  Description:
*     This function returns a pointer to the Label string for a specified axis
*     of a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     axis
*        Axis index (zero-based) identifying the axis for which information is
*        required.

*  Returned Value:
*     Pointer to a constant null-terminated character string containing the
*     requested information.

*  Notes:
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Constants: */
#define BUFF_LEN 200             /* Max characters in result string */

/* Local Variables: */
   AstMapping *map;              /* Mapping between units */
   AstSystemType system;         /* Code identifying type of time coordinates */
   char *new_lab;                /* Modified label string */
   const char *result;           /* Pointer to label string */
   int ndp;                      /* Number of decimal places for seconds field */
   static char buff[ BUFF_LEN + 1 ]; /* Buffer for result string */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise. */
   result = NULL;

/* Validate the axis index. */
   astValidateAxis( this, axis, "astGetLabel" );

/* Check if a value has been set for the required axis label string. If so,
   invoke the parent astGetLabel method to obtain a pointer to it. */
   if ( astTestLabel( this, axis ) ) {
      result = (*parent_getlabel)( this, axis );

/* Otherwise, provide a suitable default label. */
   } else {

/* If the Format attribute indicates that time values will be formatted
   as dates, then choose a suitable label. */
      if( DateFormat( astGetFormat( this, 0 ), &ndp ) ) {
         result = ( ndp >= 0 ) ? "Date/Time" : "Date";

/* Otherwise, identify the time coordinate system described by the 
   TimeFrame. */
      } else {        
         system = astGetSystem( this );

/* If OK, supply a pointer to a suitable default label string. */
         if ( astOK ) {
            result = strcpy( buff, SystemLabel( system ) );
            buff[ 0 ] = toupper( buff[ 0 ] );

/* Modify this default to take account of the current value of the Unit 
   attribute, if set. */
            if( astTestUnit( this, axis ) ) {

/* Find a Mapping from the default Units for the current System, to the 
   units indicated by the Unit attribute. This Mapping is used to modify
   the existing default label appropriately. For instance, if the default
   units is "yr" and the actual units is "log(yr)", then the default label
   of "Julian epoch" is changed to "log( Julian epoch )". */
               map = astUnitMapper( DefUnit( system, "astGetLabel", 
                                             astGetClass( this ) ),
                                    astGetUnit( this, axis ), result,
                                    &new_lab );
               if( new_lab ) {
                  result = strcpy( buff, new_lab );
                  new_lab = astFree( new_lab );
               }

/* Annul the unused Mapping. */
               if( map ) map = astAnnul( map );
            }
         }
      }
   }

/* Return the result. */
   return result;

/* Undefine macros local to this function. */
#undef BUFF_LEN

}

static const char *GetSymbol( AstFrame *this, int axis ) {
/*
*  Name:
*     GetSymbol

*  Purpose:
*     Obtain a pointer to the Symbol string for a TimeFrame axis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *GetSymbol( AstFrame *this, int axis )

*  Class Membership:
*     TimeFrame member function (over-rides the astGetSymbol method inherited
*     from the Frame class).

*  Description:
*     This function returns a pointer to the Symbol string for a specified axis
*     of a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     axis
*        Axis index (zero-based) identifying the axis for which information is
*        required.

*  Returned Value:
*     Pointer to a constant null-terminated character string containing the
*     requested information.

*  Notes:
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Constants: */
#define BUFF_LEN 200             /* Max characters in result string */

/* Local Variables: */
   AstMapping *map;              /* Mapping between units */
   AstSystemType system;         /* Code identifying type of sky coordinates */
   char *new_sym;                /* Modified symbol string */
   const char *result;           /* Pointer to symbol string */
   static char buff[ BUFF_LEN + 1 ]; /* Buffer for result string */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise. */
   result = NULL;

/* Validate the axis index. */
   astValidateAxis( this, axis, "astGetSymbol" );

/* Check if a value has been set for the required axis symbol string. If so,
   invoke the parent astGetSymbol method to obtain a pointer to it. */
   if ( astTestSymbol( this, axis ) ) {
      result = (*parent_getsymbol)( this, axis );

/* Otherwise, identify the sky coordinate system described by the TimeFrame. */
   } else {
      system = astGetSystem( this );

/* If OK, supply a pointer to a suitable default Symbol string. */
      if ( astOK ) {

         if( system == AST__MJD ) {
	    result = "MJD";
         } else if( system == AST__JD ) {
	    result = "JD";
         } else if( system == AST__BEPOCH ) {
	    result = "BEP";
         } else if( system == AST__JEPOCH ) {
	    result = "JEP";

/* Report an error if the coordinate system was not recognised. */
         } else {
	    astError( AST__SCSIN, "astGetSymbol(%s): Corrupt %s contains "
		      "invalid System identification code (%d).", 
                      astGetClass( this ), astGetClass( this ), (int) system );
         }

/* Modify this default to take account of the current value of the Unit 
   attribute, if set. */
         if( astTestUnit( this, axis ) ) {

/* Find a Mapping from the default Units for the current System, to the 
   units indicated by the Unit attribute. This Mapping is used to modify
   the existing default symbol appropriately. For instance, if the default
   units is "yr" and the actual units is "log(yr)", then the default symbol
   of "JEP" is changed to "log( JEP )". */
            map = astUnitMapper( DefUnit( system, "astGetSymbol", 
                                          astGetClass( this ) ),
                                 astGetUnit( this, axis ), result,
                                 &new_sym );
            if( new_sym ) {
               result = strcpy( buff, new_sym );
               new_sym = astFree( new_sym );
            }

/* Annul the unused Mapping. */
            if( map ) map = astAnnul( map );

         }
      }
   }

/* Return the result. */
   return result;

/* Undefine macros local to this function. */
#undef BUFF_LEN
}

static AstSystemType GetAlignSystem( AstFrame *this_frame ) {
/*
*  Name:
*     GetAlignSystem

*  Purpose:
*     Obtain the AlignSystem attribute for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "Specframe.h"
*     AstSystemType GetAlignSystem( AstFrame *this_frame )

*  Class Membership:
*     TimeFrame member function (over-rides the astGetAlignSystem protected
*     method inherited from the Frame class).

*  Description:
*     This function returns the AlignSystem attribute for a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     The AlignSystem value.

*/

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to TimeFrame structure */
   AstSystemType result;         /* Value to return */

/* Initialise. */
   result = AST__BADSYSTEM;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* If a AlignSystem attribute has been set, invoke the parent method to obtain 
   it. */
   if ( astTestAlignSystem( this ) ) {
      result = (*parent_getalignsystem)( this_frame );

/* Otherwise, provide a suitable default. */
   } else {
      result = AST__MJD;
   }

/* Return the result. */
   return result;
}

static AstTimeScaleType GetAlignTimeScale( AstTimeFrame *this ) {
/*
*+
*  Name:
*     astGetAlignTimeScale

*  Purpose:
*     Obtain the AlignTimeScale attribute for a TimeFrame.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "timeframe.h"
*     AstTimeScaleType GetAlignTimeScale( AstTimeFrame *this )

*  Class Membership:
*     TimeFrame virtual function 

*  Description:
*     This function returns the System attribute for a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     The System value.

*  Notes:
*     - AST__BADTS is returned if this function is invoked with
*     the global error status set or if it should fail for any reason.
*-
*/

/* Local Variables: */
   AstTimeScaleType result;         
   AstTimeScaleType ts;

/* Initialise. */
   result = AST__BADTS;

/* Check the global error status. */
   if ( !astOK ) return result;

/* If a value has been set, return it. */
   if( this->aligntimescale != AST__BADTS ) {
      result = this->aligntimescale;

/* Otherwise, return a default depending on the current TimeScale value */
   } else {
      ts = astGetTimeScale( this );
      if ( ts == AST__UT1 || ts == AST__LAST || ts == AST__LMST || ts == AST__GMST ) {
         result = AST__UT1;
      } else {
         result = AST__TAI;
      }

   }

/* Return the result. */
   return result;
}

static AstSystemType GetSystem( AstFrame *this_frame ) {
/*
*  Name:
*     GetSystem

*  Purpose:
*     Obtain the System attribute for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     AstSystemType GetSystem( AstFrame *this_frame )

*  Class Membership:
*     TimeFrame member function (over-rides the astGetSystem protected
*     method inherited from the Frame class).

*  Description:
*     This function returns the System attribute for a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     The System value.

*  Notes:
*     - AST__BADSYSTEM is returned if this function is invoked with
*     the global error status set or if it should fail for any reason.
*/

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to TimeFrame structure */
   AstSystemType result;         /* Value to return */

/* Initialise. */
   result = AST__BADSYSTEM;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* If a System attribute has been set, invoke the parent method to obtain 
   it. */
   if ( astTestSystem( this ) ) {
      result = (*parent_getsystem)( this_frame );

/* Otherwise, provide a suitable default. */
   } else {
      result = AST__MJD;
   }

/* Return the result. */
   return result;
}

static AstTimeScaleType GetTimeScale( AstTimeFrame *this ) {
/*
*+
*  Name:
*     astGetTimeScale

*  Purpose:
*     Obtain the TimeScale attribute for a TimeFrame.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "timeframe.h"
*     AstTimeScaleType GetTimeScale( AstTimeFrame *this )

*  Class Membership:
*     TimeFrame virtual function 

*  Description:
*     This function returns the System attribute for a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     The System value.

*  Notes:
*     - AST__BADTS is returned if this function is invoked with
*     the global error status set or if it should fail for any reason.
*-
*/

/* Local Variables: */
   AstTimeScaleType result;         

/* Initialise. */
   result = AST__BADTS;

/* Check the global error status. */
   if ( !astOK ) return result;

/* If a value has been set, return it. */
   if( this->timescale != AST__BADTS ) {
      result = this->timescale;

/* Otherwise, return a default depending on the current System value. */
   } else {
      if ( astGetSystem( this ) == AST__BEPOCH ) {
         result = AST__TT;
      } else {
         result = AST__TAI;
      }

   }

/* Return the result. */
   return result;
}

static const char *GetTitle( AstFrame *this_frame ) {
/*
*  Name:
*     GetTitle

*  Purpose:
*     Obtain a pointer to the Title string for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *GetTitle( AstFrame *this_frame )

*  Class Membership:
*     TimeFrame member function (over-rides the astGetTitle method inherited
*     from the Frame class).

*  Description:
*     This function returns a pointer to the Title string for a TimeFrame.
*     A pointer to a suitable default string is returned if no Title value has
*     previously been set.

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     Pointer to a null-terminated character string containing the requested
*     information.

*  Notes:
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Constants: */
#define BUFF_LEN 200             /* Max characters in result string */

/* Local Variables: */
   AstSystemType system;         /* Code identifying type of coordinates */
   AstTimeScaleType ts;          /* Time scale value */
   AstTimeFrame *this;           /* Pointer to TimeFrame structure */
   const char *fmt;              /* Pointer to original Format string */
   const char *result;           /* Pointer to result string */
   double orig;                  /* Time origin (seconds) */
   int fmtSet;                   /* Was Format attribute set? */
   int nc;                       /* No. of characters added */
   int ndp;                      /* Number of decimal places */
   int pos;                      /* Buffer position to enter text */
   static char buff[ BUFF_LEN + 1 ]; /* Buffer for result string */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise. */
   result = NULL;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* See if a Title string has been set. If so, use the parent astGetTitle
   method to obtain a pointer to it. */
   if ( astTestTitle( this ) ) {
      result = (*parent_gettitle)( this_frame );

/* Otherwise, we will generate a default Title string. Obtain the values of the
   TimeFrame's attributes that determine what this string will be. */
   } else {
      system = astGetSystem( this );
      orig = GetTimeOriginCur( this );
      ts = astGetTimeScale( this );
      if ( astOK ) {
         result = buff;

/* Begin with the system's default label. */
         pos = sprintf( buff, "%s", SystemLabel( system ) );
         buff[ 0 ] = toupper( buff[ 0 ] );

/* Append the time scale code, if a value has been set for the timescale. 
   Do not do this if the system is BEPOCH since BEPOCH can only be used
   with the TT timescale. */
         if( system != AST__BEPOCH && astTestTimeScale( this ) ) {
            nc = sprintf( buff + pos, " [%s]", TimeScaleString( ts ) );
            pos += nc;
         }

/* If a non-zero offset has been specified, and the Format attribute does
   not indicate a date string (which is always absolute), include the
   offset now as a date/time string. */
         fmt = astGetFormat( this, 0 );
         if( orig != 0.0 && !DateFormat( fmt, &ndp ) ) {

/* Save the Format attribute, and then temporarily set it to give a date/time 
   string. */
            fmtSet = astTestFormat( this, 0 );
            astSetFormat( this, 0, "iso.0" );

/* Format the origin value as an absolute time and append it to the
   returned title string. Note, the origin always corresponds to a
   TimeFrame axis value of zero. */
            nc = sprintf( buff+pos, " offset from %s", 
                          astFormat( this, 0, 0.0 ) );
            pos += nc;

/* Re-instate the original Format value. */
            if( fmtSet ) {
               astSetFormat( this, 0, fmt );                        
            } else {
               astClearFormat( this, 0 );
            }
         }
      }
   }

/* If an error occurred, clear the returned pointer value. */
   if ( !astOK ) result = NULL;

/* Return the result. */
   return result;

/* Undefine macros local to this function. */
#undef BUFF_LEN
}

static const char *GetUnit( AstFrame *this_frame, int axis ) {
/*
*  Name:
*     astGetUnit

*  Purpose:
*     Obtain a pointer to the Unit string for a TimeFrame's axis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *GetUnit( AstFrame *this_frame, int axis )

*  Class Membership:
*     TimeFrame member function (over-rides the astGetUnit method inherited
*     from the Frame class).

*  Description:
*     This function returns a pointer to the Unit string for a specified axis
*     of a TimeFrame. If the Unit attribute has not been set for the axis, a
*     pointer to a suitable default string is returned instead.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     axis
*        The number of the axis (zero-based) for which information is required.

*  Returned Value:
*     A pointer to a null-terminated string containing the Unit value.

*  Notes:
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to the TimeFrame structure */
   AstSystemType system;         /* The TimeFrame's System value */
   const char *result;           /* Pointer value to return */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* Validate the axis index. */
   astValidateAxis( this, axis, "astGetUnit" );

/* If a value has been set for the Unit attribute, use the parent 
   GetUnit method to return a pointer to the required Unit string. */
   if( astTestUnit( this, axis ) ){
      result = (*parent_getunit)( this_frame, axis );

/* Otherwise, identify the time coordinate system described by the 
   TimeFrame. */
   } else {
      system = astGetSystem( this );

/* Return a string describing the default units. */
      result = DefUnit( system, "astGetUnit", astGetClass( this ) );
   }

/* If an error occurred, clear the returned value. */
   if ( !astOK ) result = NULL;

/* Return the result. */
   return result;
}

void astInitTimeFrameVtab_(  AstTimeFrameVtab *vtab, const char *name ) {
/*
*+
*  Name:
*     astInitTimeFrameVtab

*  Purpose:
*     Initialise a virtual function table for a TimeFrame.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "timeframe.h"
*     void astInitTimeFrameVtab( AstTimeFrameVtab *vtab, const char *name )

*  Class Membership:
*     TimeFrame vtab initialiser.

*  Description:
*     This function initialises the component of a virtual function
*     table which is used by the TimeFrame class.

*  Parameters:
*     vtab
*        Pointer to the virtual function table. The components used by
*        all ancestral classes will be initialised if they have not already
*        been initialised.
*     name
*        Pointer to a constant null-terminated character string which contains
*        the name of the class to which the virtual function table belongs (it 
*        is this pointer value that will subsequently be returned by the Object
*        astClass function).
*-
*/

/* Local Variables: */
   AstFrameVtab *frame;          /* Pointer to Frame component of Vtab */
   AstObjectVtab *object;        /* Pointer to Object component of Vtab */

#ifdef DEBUG
   int pm;     /* See astSetPermMem in memory.c */
#endif

/* Check the local error status. */
   if ( !astOK ) return;

/* Initialize the component of the virtual function table used by the
   parent class. */
   astInitFrameVtab( (AstFrameVtab *) vtab, name );

/* Store a unique "magic" value in the virtual function table. This
   will be used (by astIsATimeFrame) to determine if an object belongs
   to this class.  We can conveniently use the address of the (static)
   class_init variable to generate this unique value. */
   vtab->check = &class_init;

/* Initialise member function pointers. */
/* ------------------------------------ */
/* Store pointers to the member functions (implemented here) that
   provide virtual methods for this class. */

   vtab->ClearAlignTimeScale = ClearAlignTimeScale;
   vtab->TestAlignTimeScale = TestAlignTimeScale;
   vtab->GetAlignTimeScale = GetAlignTimeScale;
   vtab->SetAlignTimeScale = SetAlignTimeScale;

   vtab->ClearClockLat = ClearClockLat;
   vtab->TestClockLat = TestClockLat;
   vtab->GetClockLat = GetClockLat;
   vtab->SetClockLat = SetClockLat;

   vtab->ClearClockLon = ClearClockLon;
   vtab->TestClockLon = TestClockLon;
   vtab->GetClockLon = GetClockLon;
   vtab->SetClockLon = SetClockLon;

   vtab->ClearTimeOrigin = ClearTimeOrigin;
   vtab->TestTimeOrigin = TestTimeOrigin;
   vtab->GetTimeOrigin = GetTimeOrigin;
   vtab->SetTimeOrigin = SetTimeOrigin;

   vtab->ClearTimeScale = ClearTimeScale;
   vtab->TestTimeScale = TestTimeScale;
   vtab->GetTimeScale = GetTimeScale;
   vtab->SetTimeScale = SetTimeScale;

   vtab->CurrentTime = CurrentTime;

/* Save the inherited pointers to methods that will be extended, and
   replace them with pointers to the new member functions. */
   object = (AstObjectVtab *) vtab;
   frame = (AstFrameVtab *) vtab;

   parent_clearattrib = object->ClearAttrib;
   object->ClearAttrib = ClearAttrib;
   parent_getattrib = object->GetAttrib;
   object->GetAttrib = GetAttrib;
   parent_setattrib = object->SetAttrib;
   object->SetAttrib = SetAttrib;
   parent_testattrib = object->TestAttrib;
   object->TestAttrib = TestAttrib;

   parent_getdomain = frame->GetDomain;
   frame->GetDomain = GetDomain;

   parent_getsystem = frame->GetSystem;
   frame->GetSystem = GetSystem;
   parent_setsystem = frame->SetSystem;
   frame->SetSystem = SetSystem;
   parent_clearsystem = frame->ClearSystem;
   frame->ClearSystem = ClearSystem;

   parent_getalignsystem = frame->GetAlignSystem;
   frame->GetAlignSystem = GetAlignSystem;

   parent_getlabel = frame->GetLabel;
   frame->GetLabel = GetLabel;

   parent_getsymbol = frame->GetSymbol;
   frame->GetSymbol = GetSymbol;

   parent_gettitle = frame->GetTitle;
   frame->GetTitle = GetTitle;

   parent_getepoch = frame->GetEpoch;
   frame->GetEpoch = GetEpoch;

   parent_getunit = frame->GetUnit;
   frame->GetUnit = GetUnit;

   parent_setunit = frame->SetUnit;
   frame->SetUnit = SetUnit;

   parent_match = frame->Match;
   frame->Match = Match;

   parent_overlay = frame->Overlay;
   frame->Overlay = Overlay;

   parent_setmaxaxes = frame->SetMaxAxes;
   frame->SetMaxAxes = SetMaxAxes;

   parent_setminaxes = frame->SetMinAxes;
   frame->SetMinAxes = SetMinAxes;

   parent_subframe = frame->SubFrame;
   frame->SubFrame = SubFrame;

   parent_format = frame->Format;
   frame->Format = Format;

   parent_unformat = frame->Unformat;
   frame->Unformat = Unformat;

/* Abbreviation of date fields doesn't look quite right at the moment, so
   supress it. 

   parent_abbrev = frame->Abbrev;
   frame->Abbrev = Abbrev;

*/

   parent_gap = frame->Gap;
   frame->Gap = Gap;

/* Store replacement pointers for methods which will be over-ridden by new
   member functions implemented here. */
   frame->GetActiveUnit = GetActiveUnit;
   frame->TestActiveUnit = TestActiveUnit;
   frame->ValidateSystem = ValidateSystem;
   frame->SystemString = SystemString;
   frame->SystemCode = SystemCode;

/* Declare the copy constructor, destructor and class dump
   function. */
   astSetDump( vtab, Dump, "TimeFrame",
               "Description of time coordinate system" );

/* Create an FK5 J2000 SkyFrame which will be used for formatting and 
   unformatting sky positions, etc. */
#ifdef DEBUG
   pm = astSetPermMem( 1 );
#endif

   skyframe = astSkyFrame( "system=FK5,equinox=J2000" );

#ifdef DEBUG
   astSetPermMem( pm );
#endif


}

static AstMapping *MakeMap( AstTimeFrame *this, AstSystemType sys1, 
                            AstSystemType sys2, AstTimeScaleType ts1, 
                            AstTimeScaleType ts2, double off1, double off2,
                            const char *unit1, const char *unit2,
                            const char *method ){
/*
*  Name:
*     MakeMap

*  Purpose:
*     Make a Mapping between stated timescales and systems.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     AstMapping *MakeMap( AstTimeFrame *this, AstSystemType sys1, 
*                          AstSystemType sys2, AstTimeScaleType ts1, 
*                          AstTimeScaleType ts2, double off1, double off2,
*                          const char *unit1, const char unit2,
*                          const char *method )

*  Class Membership:
*     TimeFrame member function 

*  Description:
*     This function creates a Mapping from a stated pair of System and
*     TimeScale to another stated pair.

*  Parameters:
*     this
*        A TimeFrame which specifies the clock position (for both input
*        and output).
*     sys1
*        The input System.
*     sys2
*        The output System.
*     ts1
*        The input System.
*     ts2
*        The output System.
*     off1
*        The axis offset used with the input, in the defaults units
*        associated with "sys1".
*     off2
*        The axis offset used with the output, in the defaults units
*        associated with "sys2".
*     unit1
*        The input units.
*     unit2
*        The output units.
*     method
*        A string containing the method name to include in error messages.

*  Returned Value:
*     A pointer to the new Mapping. NULL if the timescales were
*     incompatible.

*/


/* Local Variables: */
   AstMapping *result;
   AstMapping *tmap;
   AstMapping *tmap2;
   AstMapping *umap;
   AstMapping *umap1;
   AstMapping *umap2;
   AstTimeMap *timemap;
   AstTimeScaleType cmn;
   const char *du;
   double args[ 3 ];
   double shift;
   int ok;           

/* Check the global error status. */
   result = NULL;
   if ( !astOK ) return result;

/* If the timescales are equal... */
   if( ts1 == ts2 ) {

/* and the time systems are equal... */
      if( sys1 == sys2 ) {

/* and the time offsets are equal... */
         if( EQUAL( off1, off2 ) ) {

/* and the units are equal, return a UnitMap. */
            if( !strcmp( unit1, unit2 ) ) {
               result = (AstMapping *) astUnitMap( 1, "" );            

/* If only the units differ, return the appropriate units Mapping. */
            } else {
               result = astUnitMapper( unit1, unit2, NULL, NULL );
            }

/* If the time offsets differ... */
         } else {

/* Transform the difference in offsets from the default units associated
   with the (common) system, to the units associated with the output. */
            shift = off1 - off2;
            du = DefUnit( sys1, method, "TimeFrame" );
            if( du && strcmp( du, unit2 ) && shift != 0.0 ) {
               umap = astUnitMapper( DefUnit( sys1, method, "TimeFrame" ), 
                                     unit2, NULL, NULL );
               astTran1( umap, 1, &shift, 1, &shift );
               umap = astAnnul( umap );
            }

/* Create a ShiftMap to apply the shift. */
            result = (AstMapping *) astShiftMap( 1, &shift, "" );            

/* If the input and output units also differ, include the appropriate units 
   Mapping. */
            if( strcmp( unit1, unit2 ) ) {
               umap = astUnitMapper( unit1, unit2, NULL, NULL );
               tmap = (AstMapping *) astCmpMap( umap, result, 1, "" );
               umap = astAnnul( umap );
               astAnnul( result );
               result = tmap;
            }
         }
      }
   }

/* If the systems and/or timescales differ, we convert first from the
   input frame to a common frame, then from the common frame to the output
   frame. */
   if( !result ) {

/* First, a Mapping from the input units to the default units for the
   input System (these are the units expected by the TimeMap conversions). */
      umap1 = astUnitMapper( unit1, DefUnit( sys1, method, "TimeFrame" ), 
                             NULL, NULL );

/* Now create a null TimeMap. */
      timemap = astTimeMap( 0, "" );

/* Store the input time offsets to use. They correspond to the same moment in
   time (the second is the MJD equivalent of the first). */
      args[ 0 ] = off1;
      args[ 1 ] = ToMJD( sys1, off1 );

/* Add a conversion from the input System to MJD. */
      if( sys1 == AST__JD ) {
         astTimeAdd( timemap, "JDTOMJD", args );

      } else if( sys1 == AST__JEPOCH ) {
         astTimeAdd( timemap, "JEPTOMJD", args );
   
      } else if( sys1 == AST__BEPOCH ) {
         astTimeAdd( timemap, "BEPTOMJD", args );
      }

/* All timescale conversions require the input (MJD) offset as the first 
   argument. In general, the clock longitude and latitude are also
   needed. */
      args[ 0 ] = args[ 1 ];
      args[ 1 ] = astGetClockLon( this );
      args[ 2 ] = astGetClockLat( this );

/* If the input and output timescales differ, now add a conversion from the 
   input timescale to TAI or UT1 (note which is used). */
      ok = 1;
      if( ts1 != ts2 ) {
         if( ts1 == AST__TAI ) {
            cmn = AST__TAI;
       
         } else if( ts1 == AST__UTC ) {
            cmn = AST__TAI;
            astTimeAdd( timemap, "UTCTOTAI", args );
       
         } else if( ts1 == AST__TT ) {
            cmn = AST__TAI;
            astTimeAdd( timemap, "TTTOTAI", args );
       
         } else if( ts1 == AST__TDB ) {
            cmn = AST__TAI;
            astTimeAdd( timemap, "TDBTOTT", args );
            astTimeAdd( timemap, "TTTOTAI", args );
       
         } else if( ts1 == AST__TCG ) {
            cmn = AST__TAI;
            astTimeAdd( timemap, "TCGTOTT", args );
            astTimeAdd( timemap, "TTTOTAI", args );
       
         } else if( ts1 == AST__TCB ) {
            cmn = AST__TAI;
            astTimeAdd( timemap, "TCBTOTDB", args );
            astTimeAdd( timemap, "TDBTOTT", args );
            astTimeAdd( timemap, "TTTOTAI", args );
       
         } else if( ts1 == AST__UT1 ) {
            cmn = AST__UT1;
       
         } else if( ts1 == AST__GMST ) {
            cmn = AST__UT1;
            astTimeAdd( timemap, "GMSTTOUT", args );
       
         } else if( ts1 == AST__LAST ) {
            cmn = AST__UT1;
            astTimeAdd( timemap, "LASTTOLMST", args );
            astTimeAdd( timemap, "LMSTTOGMST", args );
            astTimeAdd( timemap, "GMSTTOUT", args );
      
         } else if( ts1 == AST__LMST ) {
            cmn = AST__UT1;
            astTimeAdd( timemap, "LMSTTOGMST", args );
            astTimeAdd( timemap, "GMSTTOUT", args );
         }

/* Now add a conversion to the output timescale (if possible). */
         ok = 0;
         if( ts2 == AST__TAI ) {
            if( cmn == AST__TAI ) ok = 1;
      
         } else if( ts2 == AST__UTC ) {
            if( cmn == AST__TAI ){
               ok = 1;
               astTimeAdd( timemap, "TAITOUTC", args );
            }
      
         } else if( ts2 == AST__TT ) {
            if( cmn == AST__TAI ){
               ok = 1;
               astTimeAdd( timemap, "TAITOTT", args );
            }
      
         } else if( ts2 == AST__TDB ) {
            if( cmn == AST__TAI ){
               ok = 1;
               astTimeAdd( timemap, "TAITOTT", args );
               astTimeAdd( timemap, "TTTOTDB", args );
            }
      
         } else if( ts2 == AST__TCG ) {
            if( cmn == AST__TAI ){
               ok = 1;
               astTimeAdd( timemap, "TAITOTT", args );
               astTimeAdd( timemap, "TTTOTCG", args );
            }
      
         } else if( ts2 == AST__TCB ) {
            if( cmn == AST__TAI ){
               ok = 1;
               astTimeAdd( timemap, "TAITOTT", args );
               astTimeAdd( timemap, "TTTOTDB", args );
               astTimeAdd( timemap, "TDBTOTCB", args );
            }
      
         } else if( ts2 == AST__UT1 ) {
            if( cmn == AST__UT1 ) ok = 1;
      
         } else if( ts2 == AST__GMST ) {
            if( cmn == AST__UT1 ){
               ok = 1;
               astTimeAdd( timemap, "UTTOGMST", args );
            }
      
         } else if( ts2 == AST__LAST ) {
            if( cmn == AST__UT1 ){
               ok = 1;
               astTimeAdd( timemap, "UTTOGMST", args );
               astTimeAdd( timemap, "GMSTTOLMST", args );
               astTimeAdd( timemap, "LMSTTOLAST", args );
            }
      
         } else if( ts2 == AST__LMST ) {
            if( cmn == AST__UT1 ){
               ok = 1;
               astTimeAdd( timemap, "UTTOGMST", args );
               astTimeAdd( timemap, "GMSTTOLMST", args );
            }
         }
      } 

/* Add a conversion from MJD to the output System, if needed. */
      args[ 1 ] = off2;
      if( sys2 == AST__MJD ) {
         if( args[ 0 ] != off2 ) astTimeAdd( timemap, "MJDTOMJD", args ); 
   
      } else if( sys2 == AST__JD ) {
         astTimeAdd( timemap, "MJDTOJD", args );
   
      } else if( sys2 == AST__JEPOCH ) {
         astTimeAdd( timemap, "MJDTOJEP", args );
   
      } else if( sys2 == AST__BEPOCH ) {
         astTimeAdd( timemap, "MJDTOBEP", args );
      }

/* Now, create a Mapping from the default units for the output System (these 
   are the units produced by the TimeMap conversions) to the requested
   output units. */
      umap2 = astUnitMapper( DefUnit( sys2, method, "TimeFrame" ), unit2, 
                             NULL, NULL );

/* If OK, combine the Mappings in series. Note, umap1 and umap2 should
   always be non-NULL because the suitablity of units strings is checked 
   within OriginSystem - called from within SetSystem. */
      if( umap1 && umap2 && ok ) {
         tmap = (AstMapping *) astCmpMap( umap1, timemap, 1, "" );      
         tmap2 = (AstMapping *) astCmpMap( tmap, umap2, 1, "" );      
         tmap = astAnnul( tmap );
         result = astSimplify( tmap2 );
         tmap2 = astAnnul( tmap2 );
      } else {
         result = NULL;
      }
   
/* Free remaining resources */
      if( umap1 ) umap1 = astAnnul( umap1 );
      if( umap2 ) umap2 = astAnnul( umap2 );
      timemap = astAnnul( timemap );
   }

/* Return NULL if an error has occurred. */
   if( !astOK ) result = astAnnul( result );

/* Return the result. */
   return result;

}

static int MakeTimeMapping( AstTimeFrame *target, AstTimeFrame *result,
                            AstTimeFrame *align_frm, int report, 
                            AstMapping **map ) {
/*
*  Name:
*     MakeTimeMapping

*  Purpose:
*     Generate a Mapping between two TimeFrames.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     int MakeTimeMapping( AstTimeFrame *target, AstTimeFrame *result,
*                          AstTimeFrame *align_frm, int report, 
*                          AstMapping **map ) {

*  Class Membership:
*     TimeFrame member function.

*  Description:
*     This function takes two TimeFrames and generates a Mapping that
*     converts between them, taking account of differences in their
*     coordinate systems, offsets, timescales, units, etc.

*  Parameters:
*     target
*        Pointer to the first TimeFrame.
*     result
*        Pointer to the second TimeFrame.
*     align_frm
*        A TimeFrame defining the system and time scale in which to 
*        align the target and result TimeFrames. The AlignSystem and
*        AlignTimeScale attributes are used for this purpose.
*     report
*        Should errors be reported if no match is possible? These reports
*        will describe why no match was possible.
*     map
*        Pointer to a location which is to receive a pointer to the
*        returned Mapping. The forward transformation of this Mapping
*        will convert from "target" coordinates to "result"
*        coordinates, and the inverse transformation will convert in
*        the opposite direction (all coordinate values in radians).

*  Returned Value:
*     Non-zero if the Mapping could be generated, or zero if the two
*     TimeFrames are sufficiently un-related that no meaningful Mapping
*     can be produced (albeit an "unmeaningful" Mapping will be returned
*     in this case, which will need to be annulled).

*  Notes:
*     A value of zero is returned if this function is invoked with the
*     global error status set or if it should fail for any reason.
*/

/* Local Variables: */
   AstMapping *map1;             /* Intermediate Mapping */
   AstMapping *map2;             /* Intermediate Mapping */
   AstMapping *tmap;             /* Intermediate Mapping */
   AstSystemType sys1;           /* Code to identify input system */
   AstSystemType sys2;           /* Code to identify output system */
   AstTimeScaleType align_ts;    /* Alignment time scale */
   AstTimeScaleType ts1;         /* Input time scale */
   AstTimeScaleType ts2;         /* Output time scale */
   const char *align_unit;       /* Units used for alignment */
   const char *u1;               /* Input target units */
   const char *u2;               /* Output target units */
   double align_off;             /* Axis offset */
   double off1;                  /* Input axis offset */
   double off2;                  /* Output axis offset */
   int arclk;                    /* Align->result depends on clock position? */
   int clkdiff;                  /* Do target and result clock positions differ? */
   int match;                    /* Mapping can be generated? */
   int taclk;                    /* Target->align depends on clock position? */

/* Check the global error status. */
   if ( !astOK ) return 0;

/* Initialise the returned values. */
   match = 0;
   *map = NULL;

/* Get the required properties of the input (target) TimeFrame */
   sys1 = astGetSystem( target );
   ts1 = astGetTimeScale( target );
   off1 = astGetTimeOrigin( target );
   u1 = astGetUnit( target, 0 );

/* Get the required properties of the output (result) TimeFrame */
   sys2 = astGetSystem( result );
   ts2 = astGetTimeScale( result );
   off2 = astGetTimeOrigin( result );
   u2 = astGetUnit( result, 0 );

/* Get the timescale in which alignment is to be performed. The alignment
   System does not matter since they all supported time systems are linearly 
   related, and so the choice of alignment System has no effect on the total 
   Mapping. We arbitrarily choose MJD as the alignment System (if needed). */
   align_ts = astGetAlignTimeScale( align_frm );

/* The main difference between this function and the MakeMap function is
   that this function takes account of the requested alignment frame. But
   the alignment Frame only makes a difference to the overall Mapping if
   1) the clock positions are different in the target and result Frame,
   and 2) one or both of the Mappings to or from the alignment frame depends 
   on the clock position. If either of these 2 conditions is not met,
   then the alignment frame can be ignored, and the simpler MakeMap function
   can be called. See if the clock positions differ. */
   clkdiff = ( astGetClockLon( target ) != astGetClockLon( result ) ||
               astGetClockLat( target ) != astGetClockLat( result ) );

/* See if the Mapping from target to alignment frame depends on the clock
   position. */
   taclk = CLOCK_SCALE( ts1 ) || CLOCK_SCALE( align_ts );

/* See if the Mapping from alignment to result frame depends on the clock
   position. */
   arclk = CLOCK_SCALE( align_ts ) || CLOCK_SCALE( ts2 );

/* If the alignment frame can be ignored, use MakeMap */
   if( !clkdiff || !( taclk || arclk ) ) {
      *map = MakeMap( target, sys1, sys2, ts1, ts2, off1, off2, u1, u2, 
                      "astSubFrame" );
      if( *map ) match = 1;

/* Otherwise, we create the Mapping in two parts; first a Mapping from
   the target Frame to the alignment Frame (using the target clock
   position), then a Mapping from the alignment Frame to the results
   Frame (using the result clock position). */
   } else {

/* Create a Mapping from target units/system/timescale/offset to MJD in 
   the alignment timescale with default units and offset equal to the MJD
   equivalent of the target offset. */
      align_off = ToMJD( sys1, off1 );
      align_unit = DefUnit( AST__MJD, "MakeTimeMap", "TimeFrame" );
      map1 = MakeMap( target, sys1, AST__MJD, ts1, align_ts, off1, align_off, 
                      u1, align_unit, "MakeTimeMap" );

/* Report an error if the timescales were incompatible. */
      if( !map1 ){
         match = 0;
         if( report && astOK ) {
            astError( AST__INCTS, "astMatch(%s): Alignment in requested "
                   "timescale (%s) is not possible since one or both of the "
                   "TimeFrames being aligned refer to the %s timescale.",
                   astGetClass( target ), TimeScaleString( align_ts ),
                   TimeScaleString( ts1 ) );
         }
      }   

/* We now create a Mapping converts from the alignment System (MJD), 
   TimeScale and offset to the result coordinate system. */
      map2 = MakeMap( result, AST__MJD, sys2, align_ts, ts2, align_off, off2, 
                      align_unit, u2, "MakeTimeMap" );

/* Report an error if the timescales were incompatible. */
      if( !map2 ){
         match = 0;
         if( report && astOK ) {
            astError( AST__INCTS, "astMatch(%s): Alignment in requested "
                   "timescale (%s) is not possible since one or both of the "
                   "TimeFrames being aligned refer to the %s timescale.",
                   astGetClass( result ), TimeScaleString( align_ts ),
                   TimeScaleString( ts2 ) );
         }
      }   

/* Combine these two Mappings. */
      if( map1 && map2 ) {
         match = 1;
         tmap = (AstMapping *) astCmpMap( map1, map2, 1, "" );
         *map = astSimplify( tmap );
         tmap = astAnnul( tmap );
      }
   
/* Free resources. */
      if( map1 ) map1 = astAnnul( map1 );
      if( map2 ) map2 = astAnnul( map2 );
   }

/* If an error occurred, annul the returned Mapping and clear the returned 
   values. */
   if ( !astOK ) {
      *map = astAnnul( *map );
      match = 0;
   }

/* Return the result. */
   return match;
}

static int Match( AstFrame *template_frame, AstFrame *target,
                  int **template_axes, int **target_axes, AstMapping **map,
                  AstFrame **result ) {
/*
*  Name:
*     Match

*  Purpose:
*     Determine if conversion is possible between two coordinate systems.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     int Match( AstFrame *template, AstFrame *target,
*                int **template_axes, int **target_axes,
*                AstMapping **map, AstFrame **result )

*  Class Membership:
*     TimeFrame member function (over-rides the protected astMatch method
*     inherited from the Frame class).

*  Description:
*     This function matches a "template" TimeFrame to a "target" Frame and
*     determines whether it is possible to convert coordinates between them.
*     If it is, a mapping that performs the transformation is returned along
*     with a new Frame that describes the coordinate system that results when
*     this mapping is applied to the "target" coordinate system. In addition,
*     information is returned to allow the axes in this "result" Frame to be
*     associated with the corresponding axes in the "target" and "template"
*     Frames from which they are derived.

*  Parameters:
*     template
*        Pointer to the template TimeFrame. This describes the coordinate 
*        system (or set of possible coordinate systems) into which we wish to 
*        convert our coordinates.
*     target
*        Pointer to the target Frame. This describes the coordinate system in
*        which we already have coordinates.
*     template_axes
*        Address of a location where a pointer to int will be returned if the
*        requested coordinate conversion is possible. This pointer will point
*        at a dynamically allocated array of integers with one element for each
*        axis of the "result" Frame (see below). It must be freed by the caller
*        (using astFree) when no longer required.
*
*        For each axis in the result Frame, the corresponding element of this
*        array will return the index of the template TimeFrame axis from 
*        which it is derived. If it is not derived from any template 
*        TimeFrame axis, a value of -1 will be returned instead.
*     target_axes
*        Address of a location where a pointer to int will be returned if the
*        requested coordinate conversion is possible. This pointer will point
*        at a dynamically allocated array of integers with one element for each
*        axis of the "result" Frame (see below). It must be freed by the caller
*        (using astFree) when no longer required.
*
*        For each axis in the result Frame, the corresponding element of this
*        array will return the index of the target Frame axis from which it
*        is derived. If it is not derived from any target Frame axis, a value
*        of -1 will be returned instead.
*     map
*        Address of a location where a pointer to a new Mapping will be
*        returned if the requested coordinate conversion is possible. If
*        returned, the forward transformation of this Mapping may be used to
*        convert coordinates between the "target" Frame and the "result"
*        Frame (see below) and the inverse transformation will convert in the
*        opposite direction.
*     result
*        Address of a location where a pointer to a new Frame will be returned
*        if the requested coordinate conversion is possible. If returned, this
*        Frame describes the coordinate system that results from applying the
*        returned Mapping (above) to the "target" coordinate system. In
*        general, this Frame will combine attributes from (and will therefore
*        be more specific than) both the target and the template Frames. In
*        particular, when the template allows the possibility of transformaing
*        to any one of a set of alternative coordinate systems, the "result"
*        Frame will indicate which of the alternatives was used.

*  Returned Value:
*     A non-zero value is returned if the requested coordinate conversion is
*     possible. Otherwise zero is returned (this will not in itself result in
*     an error condition).

*  Notes:
*     -  A value of zero will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.

*  Implementation Notes:
*     This implementation addresses the matching of a TimeFrame class 
*     object to any other class of Frame. A TimeFrame will match any class 
*     of TimeFrame (i.e. possibly from a derived class) but will not match 
*     a less specialised class of Frame.
*/

/* Local Variables: */
   AstFrame *frame0;             /* Pointer to Frame underlying axis 0 */
   AstTimeFrame *template;       /* Pointer to template TimeFrame structure */
   int iaxis0;                   /* Axis index underlying axis 0 */
   int match;                    /* Coordinate conversion possible? */

/* Initialise the returned values. */
   *template_axes = NULL;
   *target_axes = NULL;
   *map = NULL;
   *result = NULL;
   match = 0;

/* Check the global error status. */
   if ( !astOK ) return match;

/* Obtain a pointer to the template TimeFrame structure. */
   template = (AstTimeFrame *) template_frame;

/* Obtain pointers to the primary Frame which underlies the target axis. */
   astPrimaryFrame( target, 0, &frame0, &iaxis0 );

/* The first criterion for a match is that this Frame must be a TimeFrame 
   (or from a class derived from TimeFrame). */
   match = astIsATimeFrame( frame0 );

/* Annul the Frame pointers used in the above tests. */
   frame0 = astAnnul( frame0 );

/* The next criterion for a match is that the template matches as a
   Frame class object. This ensures that the number of axes (1) and
   domain, etc. of the target Frame are suitable. Invoke the parent
   "astMatch" method to verify this. */
   if( match ) {
      match = (*parent_match)( template_frame, target,
                               template_axes, target_axes, map, result );
   }

/* If a match was found, annul the returned objects, which are not
   needed, but keep the memory allocated for the axis association
   arrays, which we will re-use. */
   if ( astOK && match ) {
      *map = astAnnul( *map );
      *result = astAnnul( *result );
   }

/* If the Frames still match, we next set up the axis association
   arrays. */
   if ( astOK && match ) {
      (*template_axes)[ 0 ] = 0;
      (*target_axes)[ 0 ] = 0;

/* Use the target's "astSubFrame" method to create a new Frame (the
   result Frame) with a copy of of the target axis. This process also 
   overlays the template attributes on to the target Frame and returns a 
   Mapping between the target and result Frames which effects the required 
   coordinate conversion. */
      match = astSubFrame( target, template, 1, *target_axes, *template_axes,
                           map, result );

/* If an error occurred, or conversion to the result Frame's coordinate 
   system was not possible, then free all memory, annul the returned 
   objects, and reset the returned value. */
      if ( !astOK || !match ) {
         *template_axes = astFree( *template_axes );
         *target_axes = astFree( *target_axes );
         if( *map ) *map = astAnnul( *map );
         if( *result ) *result = astAnnul( *result );
         match = 0;
      }
   }

/* Return the result. */
   return match;
}

static void OriginScale( AstTimeFrame *this, AstTimeScaleType newts,
                         const char *method ){
/*
*  Name:
*     OriginScale

*  Purpose:
*     Convert the TimeOrigin in a TimeFrame to a new timescale.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void OriginScale( AstTimeFrame *this, AstTimeScaleType newts,
*                       const char *method )

*  Class Membership:
*     TimeFrame member function 

*  Description:
*     This function converts the value of the TimeOrigin attribute stored
*     within a supplied TimeFrame from the timescale currently associated
*     with the TimeFrame, to the new timescale indicated by "newts".

*  Parameters:
*     this
*        Point to the TimeFrame. On entry, the TimeOrigin value is
*        assumed to refer to the timescale given by the astGetTimeScale
*        method. On exit, the TimeOrigin value refers to the timescale 
*        supplied in "newts". The TimeScale attribute of the TimeFrame
*        should then be modified in order to keep things consistent.
*     newts
*        The timescale to which the TimeOrigin value stored within "this"
*        should refer on exit. 
*     method
*        Pointer to a string holding the name of the method to be
*        included in any error messages. 

*/


/* Local Variables: */
   AstMapping *map;
   AstSystemType sys;
   AstTimeScaleType oldts;
   const char *u;
   double newval;
   double oldval;

/* Check the global error status. */
   if ( !astOK ) return;

/* Do nothing if the TimeOrigin attribute has not been assigned a value. */
   if( astTestTimeOrigin( this ) ) {

/* Do nothing if the Scale will not change. */
      oldts = astGetTimeScale( this );
      if( newts != oldts ) {

/* Create a Mapping to perform the TimeScale change. */
         sys = astGetSystem( this );
         u = DefUnit( sys, method, "TimeFrame" ), 
         map = MakeMap( this, sys, sys, oldts, newts, 0.0, 0.0, u, u, 
                        method );

/* Use the Mapping to convert the stored TimeOrigin value. */
         if( map ) {
            oldval = astGetTimeOrigin( this );
            astTran1( map, 1, &oldval, 1, &newval );

/* Store the new value */
            astSetTimeOrigin( this, newval );

/* Free resources */
            map = astAnnul( map );

         } else if( astOK ) {
            astError( AST__INCTS, "%s(%s): Cannot convert the TimeOrigin "
                      "value to a different timescale because of "
                      "incompatible time scales.", method, 
                      astGetClass( this ) );
         }
      }
   }
}

static void OriginSystem( AstTimeFrame *this, AstSystemType oldsys, 
                          const char *method ){
/*
*  Name:
*     OriginSystem

*  Purpose:
*     Convert the TimeOrigin in a TimeFrame to a new System.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void OriginSystem( AstTimeFrame *this, AstSystemType oldsys, 
*                        const char *method )

*  Class Membership:
*     TimeFrame member function 

*  Description:
*     This function converts the value of the TimeOrigin attribute stored
*     within a supplied TimeFrame from its original System, etc, to the 
*     System, etc, currently associated with the TimeFrame.

*  Parameters:
*     this
*        Point to the TimeFrame. On entry, the TimeOrigin value is
*        assumed to refer to the System given by "oldsys", etc. On exit, the
*        TimeOrigin value refers to the System returned by the astGetSystem 
*        method, etc.
*     oldsys
*        The System to which the TimeOrigin value stored within "this"
*        refers on entry. 
*     method
*        A string containing the method name for error messages.

*/

/* Local Variables: */
   AstMapping *map;
   AstSystemType newsys;
   AstTimeScaleType ts;
   const char *oldu;
   const char *newu;
   double newval;
   double oldval;

/* Check the global error status. */
   if ( !astOK ) return;

/* Do nothing if the TimeOrigin attribute has not been assigned a value. */
   if( astTestTimeOrigin( this ) ) {

/* Do nothing if the System has not changed. */
      newsys = astGetSystem( this );
      if( oldsys != newsys ) {

/* Create a Mapping to perform the System change. */
         ts = astGetTimeScale( this );
         oldu = DefUnit( oldsys, method, "TimeFrame" ), 
         newu = DefUnit( newsys, method, "TimeFrame" ), 
         map = MakeMap( this, oldsys, newsys, ts, ts, 0.0, 0.0, oldu, newu, 
                        method );

/* Use the Mapping to convert the stored TimeOrigin value. */
         if( map ) {
            oldval = astGetTimeOrigin( this );
            astTran1( map, 1, &oldval, 1, &newval );

/* Store the new value */
            astSetTimeOrigin( this, newval );

/* Free resources */
            map = astAnnul( map );

         } else if( astOK ) {
            astError( AST__INCTS, "%s(%s): Cannot convert the TimeOrigin "
                      "value to a different System because of incompatible "
                      "time scales.", method, astGetClass( this ) );
         }
      }
   }
}

static void Overlay( AstFrame *template, const int *template_axes,
                     AstFrame *result ) {
/*
*  Name:
*     Overlay

*  Purpose:
*     Overlay the attributes of a template TimeFrame on to another Frame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void Overlay( AstFrame *template, const int *template_axes,
*                   AstFrame *result )

*  Class Membership:
*     TimeFrame member function (over-rides the protected astOverlay method
*     inherited from the Frame class).

*  Description:
*     This function overlays attributes of a TimeFrame (the "template") on to
*     another Frame, so as to over-ride selected attributes of that second
*     Frame. Normally only those attributes which have been specifically set
*     in the template will be transferred. This implements a form of
*     defaulting, in which a Frame acquires attributes from the template, but
*     retains its original attributes (as the default) if new values have not
*     previously been explicitly set in the template.
*
*     Note that if the result Frame is a TimeFrame and a change of time
*     coordinate system occurs as a result of overlaying its System
*     attribute, then some of its original attribute values may no
*     longer be appropriate (e.g. the Title, or attributes describing
*     its axes). In this case, these will be cleared before overlaying
*     any new values.

*  Parameters:
*     template
*        Pointer to the template TimeFrame, for which values should have been
*        explicitly set for any attribute which is to be transferred.
*     template_axes
*        Pointer to an array of int, with one element for each axis of the
*        "result" Frame (see below). For each axis in the result frame, the
*        corresponding element of this array should contain the (zero-based)
*        index of the template axis to which it corresponds. This array is used
*        to establish from which template axis any axis-dependent attributes
*        should be obtained.
*
*        If any axis in the result Frame is not associated with a template
*        axis, the corresponding element of this array should be set to -1.
*     result
*        Pointer to the Frame which is to receive the new attribute values.

*  Returned Value:
*     void

*  Notes:
*     -  In general, if the result Frame is not from the same class as the
*     template TimeFrame, or from a class derived from it, then attributes may
*     exist in the template TimeFrame which do not exist in the result Frame. 
*     In this case, these attributes will not be transferred.
*/


/* Local Variables: */
   const char *new_class;        /* Pointer to template class string */
   const char *old_class;        /* Pointer to result class string */
   const char *method;           /* Pointer to method string */
   AstSystemType new_system;     /* Code identifying new cordinates */
   AstSystemType old_system;     /* Code identifying old coordinates */
   int resetSystem;              /* Was the template System value cleared? */
   int timeframe;                /* Result Frame is a TimeFrame? */

/* Check the global error status. */
   if ( !astOK ) return;

/* Initialise strings used in error messages. */
   new_class = astGetClass( template );   
   old_class = astGetClass( result );   
   method = "astOverlay";

/* Get the old and new systems. */
   old_system = astGetSystem( result );
   new_system = astGetSystem( template );

/* If the result Frame is a TimeFrame, we must test to see if overlaying its
   System attribute will change the type of coordinate system it describes. 
   Determine the value of this attribute for the result and template 
   TimeFrames. */
   resetSystem = 0;
   timeframe = astIsATimeFrame( result );
   if( timeframe ) {

/* If the coordinate system will change, any value already set for the result
   TimeFrame's Title, etc,  will no longer be appropriate, so clear it. */
      if ( new_system != old_system ) {
         astClearTitle( result );
         astClearLabel( result, 0 );
         astClearSymbol( result, 0 );
      }

/* If the result Frame is not a TimeFrame, we must temporarily clear the
   System value since the System values used by this class are only
   appropriate to this class. */
   } else {
      if( astTestSystem( template ) ) {
         astClearSystem( template );
         resetSystem = 1;
      }
   }

/* Invoke the parent class astOverlay method to transfer attributes inherited
   from the parent class. */
   (*parent_overlay)( template, template_axes, result );

/* Reset the System value if necessary */
   if( resetSystem ) astSetSystem( template, new_system );

/* Check if the result Frame is a TimeFrame or from a class derived from
   TimeFrame. If not, we cannot transfer TimeFrame attributes to it as it is
   insufficiently specialised. In this case simply omit these attributes. */
   if ( timeframe && astOK ) {

/* Define macros that test whether an attribute is set in the template and,
   if so, transfers its value to the result. */
#define OVERLAY(attribute) \
   if ( astTest##attribute( template ) ) { \
      astSet##attribute( result, astGet##attribute( template ) ); \
   }

/* Use the macro to transfer each TimeFrame attribute in turn. Note,
   SourceVRF must be overlayed before SourceVel. Otherwise the stored value 
   for SourceVel would be changed from the default SourceVRF to the specified
   SourceVRF when SourceVRF was overlayed. */
      OVERLAY(AlignTimeScale)
      OVERLAY(ClockLat)
      OVERLAY(ClockLon)
      OVERLAY(TimeOrigin)
      OVERLAY(TimeScale)
   }

/* Undefine macros local to this function. */
#undef OVERLAY
}

static void SetAttrib( AstObject *this_object, const char *setting ) {
/*
*  Name:
*     SetAttrib

*  Purpose:
*     Set an attribute value for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void SetAttrib( AstObject *this, const char *setting )

*  Class Membership:
*     TimeFrame member function (extends the astSetAttrib method inherited from
*     the Mapping class).

*  Description:
*     This function assigns an attribute value for a TimeFrame, the attribute
*     and its value being specified by means of a string of the form:
*
*        "attribute= value "
*
*     Here, "attribute" specifies the attribute name and should be in lower
*     case with no white space present. The value to the right of the "="
*     should be a suitable textual representation of the value to be assigned
*     and this will be interpreted according to the attribute's data type.
*     White space surrounding the value is only significant for string
*     attributes.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     setting
*        Pointer to a null terminated string specifying the new attribute
*        value.

*  Returned Value:
*     void

*  Notes:
*     This protected method is intended to be invoked by the Object astSet
*     method and makes additional attributes accessible to it.
*/

/* Local Vaiables: */
   AstTimeFrame *this;           /* Pointer to the TimeFrame structure */
   AstTimeScaleType ts;          /* time scale type code */
   char *a;                      /* Pointer to next character */
   char *new_setting;            /* Pointer value to new attribute setting */
   double dval;                  /* Double atribute value */
   double mjd;                   /* MJD read from setting */
   double origin;                /* TimeOrigin value */
   int ival;                     /* Integer attribute value */
   int len;                      /* Length of setting string */
   int namelen;                  /* Length of attribute name in setting */
   int nc;                       /* Number of characters read by astSscanf */
   int off2;                     /* Modified offset of attribute value */
   int off;                      /* Offset of attribute value */
   int rep;                      /* Original error reporting state */
   int sign;                     /* Sign of longitude value */
   int ulen;                     /* Used length of setting string */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_object;

/* Obtain the length of the setting string. */
   len = strlen( setting );

/* Obtain the used length of the setting string. */
   ulen = astChrLen( setting );

/* Test for each recognised attribute in turn, using "astSscanf" to parse the
   setting string and extract the attribute value (or an offset to it in the
   case of string values). In each case, use the value set in "nc" to check
   that the entire string was matched. Once a value has been obtained, use the
   appropriate method to set it. */

/* First look for axis attributes defined by the Frame class. Since a
   TimeFrame has only 1 axis, we allow these attributes to be specified
   without a trailing "(axis)" string. */
   if ( !strncmp( setting, "direction=", 10 ) || 
        !strncmp( setting, "bottom=", 7 ) ||
        !strncmp( setting, "top=", 4 ) ||
        !strncmp( setting, "format=", 7 ) ||
        !strncmp( setting, "label=", 6 ) ||
        !strncmp( setting, "symbol=", 7 ) ||
        !strncmp( setting, "unit=", 5 ) ) {

/* Create a new setting string from the original by appending the string
   "(1)" to the end of the attribute name and then use the parent SetAttrib 
   method. */
      new_setting = astMalloc( len + 4 );
      if( new_setting ) {
         memcpy( new_setting, setting, len + 1 );
         a = strchr( new_setting, '=' );
         namelen = a - new_setting;
         memcpy( a, "(1)", 4 );
         a += 3;
         strcpy( a, setting + namelen );
         (*parent_setattrib)( this_object, new_setting );
         new_setting = astFree( new_setting );
      }

/* AlignTimeScale. */
/* --------------- */
   } else if ( nc = 0,
        ( 0 == astSscanf( setting, "aligntimescale=%n%*s %n", &off, &nc ) )
        && ( nc >= len ) ) {

/* Convert the string to a TimeScale code before use. */
      ts = TimeScaleCode( setting + off );
      if ( ts != AST__BADTS ) {
         astSetAlignTimeScale( this, ts );

/* Report an error if the string value wasn't recognised. */
      } else {
         astError( AST__ATTIN, "astSetAttrib(%s): Invalid time scale "
                   "description \"%s\".", astGetClass( this ), setting+off );
      }

/* ClockLat. */
/* ------- */
   } else if ( nc = 0,
              ( 0 == astSscanf( setting, "clocklat=%n%*s %n", &off, &nc ) )
              && ( nc >= 7 ) ) {

/* If the first character in the value string is "N" or "S", remember the
   sign of the value and skip over the sign character. Default is north
   (+ve). */
      off2 = off;
      if( setting[ off ] == 'N' || setting[ off ] == 'n' ) {
         off2++;
         sign = +1;
      } else if( setting[ off ] == 'S' || setting[ off ] == 's' ) {
         off2++;
         sign = -1;
      } else {
         sign = +1;
      } 

/* Convert the string to a radians value before use. */
      ival = astUnformat( skyframe, 1, setting + off2, &dval );
      if ( ival == ulen - off2  ) {
         astSetClockLat( this, dval*sign );

/* Report an error if the string value wasn't recognised. */
      } else {
         astError( AST__ATTIN, "astSetAttrib(%s): Invalid value for "
                   "ClockLat (observers latitude) \"%s\".", astGetClass( this ), 
                   setting + off );
      }

/* ClockLon. */
/* ------- */
   } else if ( nc = 0,
              ( 0 == astSscanf( setting, "clocklon=%n%*s %n", &off, &nc ) )
              && ( nc >= 7 ) ) {

/* If the first character in the value string is "E" or "W", remember the
   sign of the value and skip over the sign character. Default is east
   (+ve). */
      off2 = off;
      if( setting[ off ] == 'E' || setting[ off ] == 'e' ) {
         off2++;
         sign = +1;
      } else if( setting[ off ] == 'W' || setting[ off ] == 'w' ) {
         off2++;
         sign = -1;
      } else {
         sign = +1;
      } 

/* Convert the string to a radians value before use (temporarily make the 
   SkyFrame use degrees for longitude axis). */
      astSetAsTime( skyframe, 0, 0 );
      ival = astUnformat( skyframe, 0, setting + off2, &dval );
      astSetAsTime( skyframe, 0, 1 );
      if ( ival == ulen - off2  ) {
         astSetClockLon( this, dval*sign );

/* Report an error if the string value wasn't recognised. */
      } else {
         astError( AST__ATTIN, "astSetAttrib(%s): Invalid value for "
                   "ClockLon (observers longitude) \"%s\".", astGetClass( this ), 
                   setting + off );
      }

/* TimeOrigin */
/* ---------- */

/* Floating-point without any units indication - assume the current Unit 
   value. */
   } else if ( nc = 0,
        ( 1 == astSscanf( setting, "timeorigin= %lg %n", &dval, &nc ) )
        && ( nc >= len ) ) {

      astSetTimeOrigin( this, ToUnits( this, astGetUnit( this, 0 ), dval,
                                       "astSetTimeOrigin" ) );

/* Floating-point with units. */
   } else if ( nc = 0,
        ( 1 == astSscanf( setting, "timeorigin= %lg %n%*s %n", &dval, &off, &nc ) )
        && ( nc >= len ) ) {

/* Defer error reporting in case a date string was given which starts
   with a floating point number, then convert the supplied value to the
   default units for the TimeFrame's System. */
      rep = astReporting( 0 );
      origin = ToUnits( this, setting + off, dval, "astSetTimeOrigin" );
      if( !astOK ) astClearStatus;
      astReporting( rep );

/* If the origin was converted, store it. */
      if( origin != AST__BAD ) {
         astSetTimeOrigin( this, origin );

/* Otherwise, interpret the string as a date. Convert first to MJD then to 
   default system. */
      } else if ( nc = 0,
           ( 0 == astSscanf( setting, "timeorigin=%n%*[^\n]%n", &off, &nc ) )
           && ( nc >= len ) ) {
         mjd = astReadDateTime( setting + off );
         if ( astOK ) {
            astSetTimeOrigin( this, FromMJD( this, mjd ) );

/* Report contextual information if the conversion failed. */
         } else {
            astError( AST__ATTIN, "astSetAttrib(%s): Invalid TimeOrigin value "
                      "\"%s\" given.", astGetClass( this ), setting + off );
         }
      }

/* String (assumed to be a date). Convert first to MJD then to default
   system. */
   } else if ( nc = 0,
        ( 0 == astSscanf( setting, "timeorigin=%n%*[^\n]%n", &off, &nc ) )
        && ( nc >= len ) ) {
      mjd = astReadDateTime( setting + off );
      if ( astOK ) {
         astSetTimeOrigin( this, FromMJD( this, mjd ) );

/* Report contextual information if the conversion failed. */
      } else {
         astError( AST__ATTIN, "astSetAttrib(%s): Invalid TimeOrigin value "
                   "\"%s\" given.", astGetClass( this ), setting + off );
      }

/* TimeScale. */
/* ---------- */
   } else if ( nc = 0,
              ( 0 == astSscanf( setting, "timescale=%n%*s %n", &off, &nc ) )
              && ( nc >= len ) ) {

/* Convert the string to a TimeScale code before use. */
      ts = TimeScaleCode( setting + off );
      if ( ts != AST__BADTS ) {
         astSetTimeScale( this, ts );

/* Report an error if the string value wasn't recognised. */
      } else {
         astError( AST__ATTIN, "astSetAttrib(%s): Invalid time scale "
                   "description \"%s\".", astGetClass( this ), setting + off );
      }

/* Pass any unrecognised setting to the parent method for further
   interpretation. */
   } else {
      (*parent_setattrib)( this_object, setting );
   }
}

static void SetMaxAxes( AstFrame *this_frame, int maxaxes ) {
/*
*  Name:
*     SetMaxAxes

*  Purpose:
*     Set a value for the MaxAxes attribute of a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void SetMaxAxes( AstFrame *this, int maxaxes )

*  Class Membership:
*     TimeFrame member function (over-rides the astSetMaxAxes method
*     inherited from the Frame class).

*  Description:
*     This function sets the MaxAxes value for a TimeFrame to 1, which 
*     is the only valid value for a TimeFrame, regardless of the value 
*     supplied.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     maxaxes
*        The new value to be set (ignored).

*  Returned Value:
*     void.
*/

/* Check the global error status. */
   if ( !astOK ) return;

/* Use the parent astSetMaxAxes method to set a value of 1. */
   (*parent_setmaxaxes)( this_frame, 1 );
}

static void SetMinAxes( AstFrame *this_frame, int minaxes ) {
/*
*  Name:
*     SetMinAxes

*  Purpose:
*     Set a value for the MinAxes attribute of a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void SetMinAxes( AstFrame *this, int minaxes )

*  Class Membership:
*     TimeFrame member function (over-rides the astSetMinAxes method
*     inherited from the Frame class).

*  Description:
*     This function sets the MinAxes value for a TimeFrame to 1, which is 
*     the only valid value for a TimeFrame, regardless of the value 
*     supplied.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     minaxes
*        The new value to be set (ignored).

*  Returned Value:
*     void.
*/

/* Check the global error status. */
   if ( !astOK ) return;

/* Use the parent astSetMinAxes method to set a value of 1. */
   (*parent_setminaxes)( this_frame, 1 );
}

static void SetSystem( AstFrame *this_frame, AstSystemType newsys ) {
/*
*  Name:
*     SetSystem

*  Purpose:
*     Set the System attribute for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void SetSystem( AstFrame *this_frame, AstSystemType newsys )

*  Class Membership:
*     TimeFrame member function (over-rides the astSetSystem protected
*     method inherited from the Frame class).

*  Description:
*     This function sets the System attribute for a TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     newsys
*        The new System value to be stored.

*/

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to TimeFrame structure */
   AstSystemType oldsys;         /* Original System value */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* If we are changing the System to BEPOCH, set the Unit attribute to
   "yr" and TimeScale to "TT". */ 
   if( newsys == AST__BEPOCH ) {
      astSetUnit( this_frame, 0, "yr" );
      astSetTimeScale( (AstTimeFrame *) this_frame, AST__TT );
   }

/* Save the original System value */
   oldsys = astGetSystem( this_frame );

/* Use the parent SetSystem method to store the new System value. */
   (*parent_setsystem)( this_frame, newsys );

/* If the system has changed... */
   if( oldsys != newsys ) {

/* Modify the stored TimeOrigin. */
      OriginSystem( this, oldsys, "astSetSystem" );

/* Clear all attributes which have system-specific defaults. */
      astClearLabel( this_frame, 0 );
      astClearSymbol( this_frame, 0 );
      astClearTitle( this_frame );
   }
}

static void SetTimeScale( AstTimeFrame *this, AstTimeScaleType value ) {
/*
*+
*  Name:
*     astSetTimeScale

*  Purpose:
*     Set the TimeScale attribute for a TimeFrame.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "timeframe.h"
*     void astSetTimeScale( AstTimeFrame *this, AstTimeScaleType value )

*  Class Membership:
*     TimeFrame virtual function 

*  Description:
*     This function set a new value for the TimeScale attribute for a 
*     TimeFrame.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     value
*        The new value.

*-
*/

/* Check the global error status. */
   if ( !astOK ) return;

/* Verify the supplied timescale value */
   if( value < FIRST_TS || value > LAST_TS ) {
      astError( AST__ATTIN, "%s(%s): Bad value (%d) given for TimeScale "
                "attribute.", "astSetTimeScale", astGetClass( this ), 
                (int) value );

/* Report an error if System is set to BEPOCH and an in appropriate
   TimeScale was supplied. */
   } else if( astGetSystem( this ) == AST__BEPOCH && 
              value != AST__TT ) {
      astError( AST__ATTIN, "%s(%s): Supplied TimeScale (%s) cannot be "
                "used because the %s represents Besselian Epoch which "
                "is defined in terms of TT.", "astSetTimeScale",
                astGetClass( this ), TimeScaleString( value ),
                astGetClass( this ) );

/* Otherwise set the new TimeScale */
   } else {

/* Modify the TimeOrigin value stored in the TimeFrame structure to refer 
   to the new timescale. */
      OriginScale( this, value, "astSetTimeScale" );

/* Store the new value for the timescale in the TimeFrame structure. */
      this->timescale = value;

   }
}

static void SetUnit( AstFrame *this_frame, int axis, const char *value ) {
/*
*  Name:
*     astSetUnit

*  Purpose:
*     Set a pointer to the Unit string for a TimeFrame's axis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void SetUnit( AstFrame *this_frame, int axis, const char *value )

*  Class Membership:
*     TimeFrame member function (over-rides the astSetUnit method inherited
*     from the Frame class).

*  Description:
*     This function stores a pointer to the Unit string for a specified axis
*     of a TimeFrame. It also stores the string in the "usedunits" array
*     in the TimeFrame structure, in the element associated with the
*     current System.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     axis
*        The number of the axis (zero-based) for which information is required.
*     unit
*        The new string to store.
*/

/* Local Variables: */
   AstTimeFrame *this;

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* Validate the axis index. */
   astValidateAxis( this, axis, "astSetUnit" );

/* Report an error if System is set to BEPOCH and an in appropriate
   Unit was supplied. */
   if( astGetSystem( this ) == AST__BEPOCH && strcmp( "yr", value ) ) {
      astError( AST__ATTIN, "astSetUnit(%s): Supplied Unit (%s) cannot "
                "be used because the %s represents Besselian Epoch which "
                "is defined in units of years (yr).", astGetClass( this ),
                value, astGetClass( this ) );

/* Otherwise use the parent SetUnit method to store the value in the Axis
   structure */
   } else {
      (*parent_setunit)( this_frame, axis, value );
   }
}

static AstTimeScaleType TimeScaleCode( const char *ts ) {
/*
*  Name:
*     TimeScaleCode

*  Purpose:
*     Convert a string into a time scale type code.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     AstTimeScaleType TimeScaleCode( const char *ts )

*  Class Membership:
*     TimeFrame member function.

*  Description:
*     This function converts a string used for the external description of 
*     a time scale into a TimeFrame time scale type code  (TimeScale attribute 
*     value). It is the inverse of the TimeScaleString function.

*  Parameters:
*     ts
*        Pointer to a constant null-terminated string containing the
*        external description of the time scale.

*  Returned Value:
*     The TimeScale type code.

*  Notes:
*     - A value of AST__BADTS is returned if the time scale 
*     description was not recognised. This does not produce an error.
*     - A value of AST__BADTS is also returned if this function
*     is invoked with the global error status set or if it should fail
*     for any reason.
*/

/* Local Variables: */
   AstTimeScaleType result;      /* Result value to return */

/* Initialise. */
   result = AST__BADTS;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Match the timescale string against each possibility and assign the
   result. */
   if ( astChrMatch( "TAI", ts ) ) {
      result = AST__TAI;

   } else if ( astChrMatch( "UTC", ts ) ) {
      result = AST__UTC;

   } else if ( astChrMatch( "UT1", ts ) ) {
      result = AST__UT1;

   } else if ( astChrMatch( "GMST", ts ) ) {
      result = AST__GMST;

   } else if ( astChrMatch( "LAST", ts ) ) {
      result = AST__LAST;

   } else if ( astChrMatch( "LMST", ts ) ) {
      result = AST__LMST;

   } else if ( astChrMatch( "TT", ts ) ) {
      result = AST__TT;

   } else if ( astChrMatch( "TDB", ts ) ) {
      result = AST__TDB;

   } else if ( astChrMatch( "TCG", ts ) ) {
      result = AST__TCG;

   } else if ( astChrMatch( "TCB", ts ) ) {
      result = AST__TCB;

   }

/* Return the result. */
   return result;
}

static const char *TimeScaleString( AstTimeScaleType ts ) {
/*
*  Name:
*     TimeScaleString

*  Purpose:
*     Convert a time scale type code into a string.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *TimeScaleString( AstTimeScaleType ts )

*  Class Membership:
*     TimeFrame member function.

*  Description:
*     This function converts a TimeFrame time scale type code (TimeScale 
*     attribute value) into a string suitable for use as an external 
*     representation of the time scale type.

*  Parameters:
*     ts
*        The time scale type code.

*  Returned Value:
*     Pointer to a constant null-terminated string containing the
*     textual equivalent of the type code supplied.

*  Notes:
*     - A NULL pointer value is returned if the time scale
*     code was not recognised. This does not produce an error.
*     - A NULL pointer value is also returned if this function is
*     invoked with the global error status set or if it should fail
*     for any reason.
*/

/* Local Variables: */
   const char *result;           /* Pointer value to return */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Match the timescale value against each possibility and convert to a
   string pointer. */
   switch ( ts ) {

   case AST__TAI:
      result = "TAI";
      break;

   case AST__UTC:
      result = "UTC";
      break;

   case AST__UT1:
      result = "UT1";
      break;

   case AST__GMST:
      result = "GMST";
      break;

   case AST__LAST:
      result = "LAST";
      break;

   case AST__LMST:
      result = "LMST";
      break;

   case AST__TT:
      result = "TT";
      break;

   case AST__TDB:
      result = "TDB";
      break;

   case AST__TCB:
      result = "TCB";
      break;

   case AST__TCG:
      result = "TCG";
      break;

   }

/* Return the result pointer. */
   return result;
}

static int SubFrame( AstFrame *target_frame, AstFrame *template,
                     int result_naxes, const int *target_axes,
                     const int *template_axes, AstMapping **map,
                     AstFrame **result ) {
/*
*  Name:
*     SubFrame

*  Purpose:
*     Select axes from a TimeFrame and convert to the new coordinate 
*     system.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     int SubFrame( AstFrame *target, AstFrame *template,
*                   int result_naxes, const int *target_axes,
*                   const int *template_axes, AstMapping **map,
*                   AstFrame **result )

*  Class Membership:
*     TimeFrame member function (over-rides the protected astSubFrame 
*     method inherited from the Frame class).

*  Description:
*     This function selects a requested sub-set (or super-set) of the axes
*     from a "target" TimeFrame and creates a new Frame with copies of
*     the selected axes assembled in the requested order. It then
*     optionally overlays the attributes of a "template" Frame on to the
*     result. It returns both the resulting Frame and a Mapping that
*     describes how to convert between the coordinate systems described by
*     the target and result Frames. If necessary, this Mapping takes
*     account of any differences in the Frames' attributes due to the
*     influence of the template.

*  Parameters:
*     target
*        Pointer to the target TimeFrame, from which axes are to be 
*        selected.
*     template
*        Pointer to the template Frame, from which new attributes for the
*        result Frame are to be obtained. Optionally, this may be NULL, in
*        which case no overlaying of template attributes will be performed.
*     result_naxes
*        Number of axes to be selected from the target Frame. This number may
*        be greater than or less than the number of axes in this Frame (or
*        equal).
*     target_axes
*        Pointer to an array of int with result_naxes elements, giving a list
*        of the (zero-based) axis indices of the axes to be selected from the
*        target TimeFrame. The order in which these are given determines
*        the order in which the axes appear in the result Frame. If any of the
*        values in this array is set to -1, the corresponding result axis will
*        not be derived from the target Frame, but will be assigned default
*        attributes instead.
*     template_axes
*        Pointer to an array of int with result_naxes elements. This should
*        contain a list of the template axes (given as zero-based axis indices)
*        with which the axes of the result Frame are to be associated. This
*        array determines which axes are used when overlaying axis-dependent
*        attributes of the template on to the result. If any element of this
*        array is set to -1, the corresponding result axis will not receive any
*        template attributes.
*
*        If the template argument is given as NULL, this array is not used and
*        a NULL pointer may also be supplied here.
*     map
*        Address of a location to receive a pointer to the returned Mapping.
*        The forward transformation of this Mapping will describe how to
*        convert coordinates from the coordinate system described by the target
*        TimeFrame to that described by the result Frame. The inverse
*        transformation will convert in the opposite direction.
*     result
*        Address of a location to receive a pointer to the result Frame.

*  Returned Value:
*     A non-zero value is returned if coordinate conversion is possible
*     between the target and the result Frame. Otherwise zero is returned and
*     *map and *result are returned as NULL (but this will not in itself
*     result in an error condition). In general, coordinate conversion should
*     always be possible if no template Frame is supplied but may not always
*     be possible otherwise.

*  Notes:
*     -  A value of zero will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.

*  Implementation Notes:
*     -  This implementation addresses the selection of axes from a 
*     TimeFrame object. This results in another object of the same class 
*     only if the single TimeFrame axis is selected exactly once. 
*     Otherwise, the result is a Frame class object which inherits the 
*     TimeFrame's axis information (if appropriate) but none of the other 
*     properties of a TimeFrame.
*     -  In the event that a TimeFrame results, the returned Mapping will 
*     take proper account of the relationship between the target and result 
*     coordinate systems.
*     -  In the event that a Frame class object results, the returned Mapping
*     will only represent a selection/permutation of axes.

*  Implementation Deficiencies:
*     -  Any axis selection is currently permitted. Probably this should be
*     restricted so that each axis can only be selected once. The
*     astValidateAxisSelection method will do this but currently there are bugs
*     in the CmpFrame class that cause axis selections which will not pass this
*     test. Install the validation when these are fixed.
*/

/* Local Variables: */
   AstTimeFrame *target;      /* Pointer to the TimeFrame structure */
   AstTimeFrame *temp;        /* Pointer to copy of target TimeFrame */
   AstTimeFrame *align_frm;   /* Frame in which to align the TimeFrames */
   int match;                 /* Coordinate conversion is possible? */

/* Initialise the returned values. */
   *map = NULL;
   *result = NULL;
   match = 0;

/* Check the global error status. */
   if ( !astOK ) return match;

/* Obtain a pointer to the target TimeFrame structure. */
   target = (AstTimeFrame *) target_frame;

/* Result is a TimeFrame. */
/* -------------------------- */
/* Check if the result Frame is to have one axis obtained by selecting
   the single target TimeFrame axis. If so, the result will also be 
   a TimeFrame. */
   if ( ( result_naxes == 1 ) && ( target_axes[ 0 ] == 0 ) ) {

/* Form the result from a copy of the target. */
      *result = astCopy( target );

/* If required, overlay the template attributes on to the result TimeFrame.
   Also choose the Frame which defined the alignment system and time scale 
   (via its AlignSystem and AlignTimeScale attributes) in which to align the 
   two TimeFrames. This is the template (if there is a template). */
      if ( template ) {
         astOverlay( template, template_axes, *result );
         if( astIsATimeFrame( template ) ) {
            align_frm = astClone( template );
         } else {
            align_frm = astClone( target );
         }

/* If no template was supplied, align in the System and TimeScale of the
   target. */
      } else {
         VerifyAttrs( target, "convert between different time systems", 
                      "TimeScale", "astMatch" );
         align_frm = astClone( target );
      }

/* Generate a Mapping that takes account of changes in the sky coordinate
   system (equinox, epoch, etc.) between the target TimeFrame and the result
   TimeFrame. If this Mapping can be generated, set "match" to indicate that
   coordinate conversion is possible. */
      match = ( MakeTimeMapping( target, (AstTimeFrame *) *result, 
                align_frm, 0, map ) != 0 );

/* Free resources. */
      align_frm = astAnnul( align_frm );

/* Result is not a TimeFrame. */
/* ------------------------------ */
/* In this case, we select axes as if the target were from the Frame
   class.  However, since the resulting data will then be separated
   from their enclosing TimeFrame, default attribute values may differ
   if the methods for obtaining them were over-ridden by the TimeFrame
   class. To overcome this, we ensure that these values are explicitly
   set for the result Frame (rather than relying on their defaults). */
   } else {

/* Make a temporary copy of the target TimeFrame. We will explicitly
   set the attribute values in this copy so as not to modify the original. */
      temp = astCopy( target );

/* Define a macro to test if an attribute is set. If not, set it
   explicitly to its default value. */
#define SET(attribute) \
   if ( !astTest##attribute( temp ) ) { \
      astSet##attribute( temp, astGet##attribute( temp ) ); \
   }

/* Set attribute values which apply to the Frame as a whole and which
   we want to retain, but whose defaults are over-ridden by the
   TimeFrame class. */
      SET(Domain)
      SET(Title)

/* Define a macro to test if an attribute is set for axis zero (the only
   axis of a TimeFrame). If not, set it explicitly to its default value. */
#define SET_AXIS(attribute) \
   if ( !astTest##attribute( temp, 0 ) ) { \
      astSet##attribute( temp, 0, \
                         astGet##attribute( temp, 0 ) ); \
   }

/* Use this macro to set explicit values for all the axis attributes
   for which the TimeFrame class over-rides the default value. */
      SET_AXIS(Label)
      SET_AXIS(Symbol)
      SET_AXIS(Unit)

/* Clear attributes which have an extended range of values allowed by
   this class. */
      astClearSystem( temp );

/* Invoke the astSubFrame method inherited from the Frame class to
   produce the result Frame by selecting the required set of axes and
   overlaying the template Frame's attributes. */
      match = (*parent_subframe)( (AstFrame *) temp, template,
                                  result_naxes, target_axes, template_axes,
                                  map, result );

/* Delete the temporary copy of the target TimeFrame. */
      temp = astDelete( temp );
   }

/* If an error occurred or no match was found, annul the returned
   objects and reset the returned result. */
   if ( !astOK || !match ) {
      if( *map ) *map = astAnnul( *map );
      if( *result ) *result = astAnnul( *result );
      match = 0;
   }

/* Return the result. */
   return match;

/* Undefine macros local to this function. */
#undef SET
#undef SET_AXIS
}

static AstSystemType SystemCode( AstFrame *this, const char *system ) {
/*
*  Name:
*     SystemCode

*  Purpose:
*     Convert a string into a coordinate system type code.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     AstSystemType SystemCode( AstFrame *this, const char *system )

*  Class Membership:
*     TimeFrame member function (over-rides the astSystemCode method
*     inherited from the Frame class).

*  Description:
*     This function converts a string used for the external description of 
*     a coordinate system into a TimeFrame coordinate system type code 
*     (System attribute value). It is the inverse of the astSystemString 
*     function.

*  Parameters:
*     this
*        The Frame.
*     system
*        Pointer to a constant null-terminated string containing the
*        external description of the sky coordinate system.

*  Returned Value:
*     The System type code.

*  Notes:
*     - A value of AST__BADSYSTEM is returned if the sky coordinate
*     system description was not recognised. This does not produce an
*     error.
*     - A value of AST__BADSYSTEM is also returned if this function
*     is invoked with the global error status set or if it should fail
*     for any reason.
*/

/* Local Variables: */
   AstSystemType result;      /* Result value to return */

/* Initialise. */
   result = AST__BADSYSTEM;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Match the "system" string against each possibility and assign the
   result. */
   if ( astChrMatch( "MJD", system ) || astChrMatch( "Modified Julian Date", system ) ) {
      result = AST__MJD;

   } else if ( astChrMatch( "JD", system ) || astChrMatch( "Julian Date", system ) ) {
      result = AST__JD;

   } else if ( astChrMatch( "BEPOCH", system ) || astChrMatch( "Besselian Epoch", system ) ) {
      result = AST__BEPOCH;

   } else if ( astChrMatch( "JEPOCH", system ) || astChrMatch( "Julian Epoch", system ) ) {
      result = AST__JEPOCH;

   }

/* Return the result. */
   return result;
}

static const char *SystemLabel( AstSystemType system ) {
/*
*  Name:
*     SystemLabel

*  Purpose:
*     Return a label for a coordinate system type code.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *SystemLabel( AstSystemType system )

*  Class Membership:
*     TimeFrame member function.

*  Description:
*     This function converts a TimeFrame coordinate system type code
*     (System attribute value) into a descriptive string for human readers.

*  Parameters:
*     system
*        The coordinate system type code.

*  Returned Value:
*     Pointer to a constant null-terminated string containing the
*     textual equivalent of the type code supplied.

*  Notes:
*     - A NULL pointer value is returned if the sky coordinate system
*     code was not recognised. This does not produce an error.
*     - A NULL pointer value is also returned if this function is
*     invoked with the global error status set or if it should fail
*     for any reason.
*/

/* Local Variables: */
   const char *result;           /* Pointer value to return */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Match the "system" value against each possibility and convert to a
   string pointer. */
   switch ( system ) {

   case AST__MJD:
      result = "Modified Julian Date";
      break;

   case AST__JD:
      result = "Julian Date";
      break;

   case AST__JEPOCH:
      result = "Julian Epoch";
      break;

   case AST__BEPOCH:
      result = "Besselian Epoch";
      break;

   }

/* Return the result pointer. */
   return result;
}

static const char *SystemString( AstFrame *this, AstSystemType system ) {
/*
*  Name:
*     SystemString

*  Purpose:
*     Convert a coordinate system type code into a string.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     const char *SystemString( AstFrame *this, AstSystemType system )

*  Class Membership:
*     TimeFrame member function (over-rides the astSystemString method
*     inherited from the Frame class).

*  Description:
*     This function converts a TimeFrame coordinate system type code
*     (System attribute value) into a string suitable for use as an
*     external representation of the coordinate system type.

*  Parameters:
*     this
*        The Frame.
*     system
*        The coordinate system type code.

*  Returned Value:
*     Pointer to a constant null-terminated string containing the
*     textual equivalent of the type code supplied.

*  Notes:
*     - A NULL pointer value is returned if the sky coordinate system
*     code was not recognised. This does not produce an error.
*     - A NULL pointer value is also returned if this function is
*     invoked with the global error status set or if it should fail
*     for any reason.
*/

/* Local Variables: */
   const char *result;           /* Pointer value to return */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Match the "system" value against each possibility and convert to a
   string pointer. (Where possible, return the same string as would be
   used in the FITS WCS representation of the coordinate system). */
   switch ( system ) {

   case AST__MJD:
      result = "MJD";
      break;

   case AST__JD:
      result = "JD";
      break;

   case AST__JEPOCH:
      result = "JEPOCH";
      break;

   case AST__BEPOCH:
      result = "BEPOCH";
      break;
   }

/* Return the result pointer. */
   return result;
}

static int TestActiveUnit( AstFrame *this_frame ) {
/*
*  Name:
*     TestActiveUnit

*  Purpose:
*     Test the ActiveUnit flag for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     int TestActiveUnit( AstFrame *this_frame ) 

*  Class Membership:
*     TimeFrame member function (over-rides the astTestActiveUnit protected
*     method inherited from the Frame class).

*  Description:
*    This function test the value of the ActiveUnit flag for a TimeFrame, 
*    which is always "unset". 

*  Parameters:
*     this
*        Pointer to the TimeFrame.

*  Returned Value:
*     The result of the test (0).

*/
   return 0;
}

static int TestAttrib( AstObject *this_object, const char *attrib ) {
/*
*  Name:
*     TestAttrib

*  Purpose:
*     Test if a specified attribute value is set for a TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     int TestAttrib( AstObject *this, const char *attrib )

*  Class Membership:
*     TimeFrame member function (over-rides the astTestAttrib protected
*     method inherited from the Frame class).

*  Description:
*     This function returns a boolean result (0 or 1) to indicate whether
*     a value has been set for one of a TimeFrame's attributes.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     attrib
*        Pointer to a null terminated string specifying the attribute
*        name.  This should be in lower case with no surrounding white
*        space.

*  Returned Value:
*     One if a value has been set, otherwise zero.

*  Notes:
*     - This function uses one-based axis numbering so that it is
*     suitable for external (public) use.
*     - A value of zero will be returned if this function is invoked
*     with the global status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to the TimeFrame structure */
   char *new_attrib;             /* Pointer value to new attribute name */
   int len;                      /* Length of attrib string */
   int result;                   /* Result value to return */

/* Initialise. */
   result = 0;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_object;

/* Obtain the length of the attrib string. */
   len = strlen( attrib );

/* Check the attribute name and test the appropriate attribute. */

/* First look for axis attributes defined by the Frame class. Since a
   TimeFrame has only 1 axis, we allow these attributes to be specified
   without a trailing "(axis)" string. */
   if ( !strcmp( attrib, "direction" ) || 
        !strcmp( attrib, "bottom" ) ||
        !strcmp( attrib, "top" ) ||
        !strcmp( attrib, "format" ) ||
        !strcmp( attrib, "label" ) ||
        !strcmp( attrib, "symbol" ) ||
        !strcmp( attrib, "unit" ) ) {

/* Create a new attribute name from the original by appending the string
   "(1)" and then use the parent TestAttrib method. */
      new_attrib = astMalloc( len + 4 );
      if( new_attrib ) {
         memcpy( new_attrib, attrib, len );
         memcpy( new_attrib + len, "(1)", 4 ); 
         result = (*parent_testattrib)( this_object, new_attrib );
         new_attrib = astFree( new_attrib );
      }

/* AlignTimeScale. */
/* --------------- */
   } else if ( !strcmp( attrib, "aligntimescale" ) ) {
      result = astTestAlignTimeScale( this );

/* ClockLat. */
/* ------- */
   } else if ( !strcmp( attrib, "clocklat" ) ) {
      result = astTestClockLat( this );

/* ClockLon. */
/* ------- */
   } else if ( !strcmp( attrib, "clocklon" ) ) {
      result = astTestClockLon( this );

/* TimeOrigin. */
/* --------- */
   } else if ( !strcmp( attrib, "timeorigin" ) ) {
      result = astTestTimeOrigin( this );

/* TimeScale. */
/* ---------- */
   } else if ( !strcmp( attrib, "timescale" ) ) {
      result = astTestTimeScale( this );

/* If the attribute is not recognised, pass it on to the parent method
   for further interpretation. */
   } else {
      result = (*parent_testattrib)( this_object, attrib );
   }

/* Return the result, */
   return result;
}

static double ToMJD( AstSystemType oldsys, double oldval ){
/*
*  Name:
*     ToMJD

*  Purpose:
*     Convert a time value from TimeFrame's System to MJD.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     double ToMJD( AstSystemType oldsys, double oldval ){

*  Class Membership:
*     TimeFrame member function 

*  Description:
*     This function converts the supplied value from the supplied System 
*     to an MJD.

*  Parameters:
*     oldsys
*        The System in which the oldval is supplied.
*     oldval
*        The value to convert, assumed to be in the default units
*        associated with "oldsys".

*  Returned Value:
*     The MJD value corresponding to "oldval"

*  Notes:
*     - Both old and new value are assumed to be absolute (i.e. have zero
*     offset).

*/

/* Local Variables; */
   AstMapping *map;
   double result;              
   
/* Initialise. */
   result = AST__BAD;

/* Check the global error status. */
   if ( !astOK ) return result;

/* If the old system is MJD just return the value unchanged. */
   if( oldsys == AST__MJD ) {
      result = oldval;

/* Otherwise create a TimeMap wich converts from the TimeFrame system to
   MJD, and use it to transform the supplied value. */
   } else {
      map = ToMJDMap( oldsys, 0.0 );

/* Use the TimeMap to convert the supplied value. */
      astTran1( map, 1, &oldval, 1, &result );

/* Free resources */
      map = astAnnul( map );

   }

/* Return the result */
   return result;
}

static AstMapping *ToMJDMap( AstSystemType oldsys, double off ){
/*
*  Name:
*     ToMJDMap

*  Purpose:
*     Create a Mapping from a specified System to MJD.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     AstMapping *ToMJDMap( AstSystemType oldsys, double off ){

*  Class Membership:
*     TimeFrame member function 

*  Description:
*     This function creates a Mapping which converts from the supplied
*     system and offset to absolute MJD.

*  Parameters:
*     oldsys
*        The System in which the oldval is supplied.
*     off
*        The axis offset used with the old System, assumed to be in the
*        default system associated with oldsys.

*  Returned Value:
*     The Mapping.

*/

/* Local Variables; */
   AstTimeMap *timemap;
   double args[ 2 ];
   
/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Create a null TimeMap */
   timemap = astTimeMap( 0, "" );

/* Set the offsets for the supplied and returned values. */
   args[ 0 ] = off;
   args[ 1 ] = 0.0;

/* If required, add a TimeMap conversion which converts from the TimeFrame
   system to MJD. */
   if( oldsys == AST__MJD ) {
/*      if( off != 0.0 ) astTimeAdd( timemap, "MJDTOMJD", args ); */
      astTimeAdd( timemap, "MJDTOMJD", args );

   } else if( oldsys == AST__JD ) {
      astTimeAdd( timemap, "JDTOMJD", args );

   } else if( oldsys == AST__JEPOCH ) {
      astTimeAdd( timemap, "JEPTOMJD", args );

   } else if( oldsys == AST__BEPOCH ) {
      astTimeAdd( timemap, "BEPTOMJD", args );
   }

/* Return the result */
   return (AstMapping *) timemap;
}

static double ToUnits( AstTimeFrame *this, const char *oldunit, double oldval,
                       const char *method ){
/*
*
*  Name:
*     ToUnits

*  Purpose:
*     Convert a supplied time value to the default units of the supplied TimeFrame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     double ToUnits( AstTimeFrame *this, const char *oldunit, double oldval,
*                     const char *method )

*  Class Membership:
*     TimeFrame member function 

*  Description:
*     This function converts the supplied time value from the supplied
*     units to the default units associated with the supplied TimeFrame's
*     System.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     oldunit
*        The units in which "oldval" is supplied.
*     oldval
*        The value to be converted.
*     method
*        Pointer to a string holding the name of the method to be
*        included in any error messages. 

*  Returned Value:
*     The converted value.

*/

/* Local Variables: */
   AstMapping *map;
   const char *defunit;
   double result;              
   
/* Initialise. */
   result = AST__BAD;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get default units associated with the System attribute of the supplied
   TimeFrame, and find a Mapping from the old units to the default. */
   defunit = DefUnit( astGetSystem( this ), method, "TimeFrame" );
   map = astUnitMapper( oldunit, defunit, NULL, NULL );
   if( map ) {

/* Use the Mapping to convert the supplied value. */
      astTran1( map, 1, &oldval, 1, &result );

/* Free resources. */
      map = astAnnul( map );

/* Report an error if no conversion is possible. */
   } else if( astOK ){
      astError( AST__BADUN, "%s(%s): Cannot convert the supplied attribute "
                "value from units of %s to %s.", method, astGetClass( this ), 
                 oldunit, defunit );
   }

/* Return the result */
   return result;
}

static int Unformat( AstFrame *this_frame, int axis, const char *string,
                     double *value ) {
/*
*  Name:
*     Unformat

*  Purpose:
*     Read a formatted coordinate value for a TimeFrame axis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     int Unformat( AstFrame *this, int axis, const char *string,
*                   double *value )

*  Class Membership:
*     TimeFrame member function (over-rides the public astUnformat
*     method inherited from the Frame class).

*  Description:
*     This function reads a formatted coordinate value for a TimeFrame
*     axis (supplied as a string) and returns the equivalent numerical
*     value as a double. It also returns the number of characters read
*     from the string.

*  Parameters:
*     this
*        Pointer to the TimeFrame.
*     axis
*        The number of the TimeFrame axis for which the coordinate
*        value is to be read (axis numbering starts at zero for the
*        first axis).
*     string
*        Pointer to a constant null-terminated string containing the
*        formatted coordinate value.
*     value
*        Pointer to a double in which the coordinate value read will
*        be returned.

*  Returned Value:
*     The number of characters read from the string to obtain the
*     coordinate value.

*  Notes:
*     - Any white space at the beginning of the string will be
*     skipped, as also will any trailing white space following the
*     coordinate value read. The function's return value will reflect
*     this.
*     - A function value of zero (and no coordinate value) will be
*     returned, without error, if the string supplied does not contain
*     a suitably formatted value.
*     - The string "<bad>" is recognised as a special case and will
*     generate the value AST__BAD, without error. The test for this
*     string is case-insensitive and permits embedded white space.
*     - A function result of zero will be returned and no coordinate
*     value will be returned via the "value" pointer if this function
*     is invoked with the global error status set, or if it should
*     fail for any reason.
*/

/* Local Variables: */
   AstMapping *map;
   AstTimeFrame *this;
   AstTimeScaleType ts1;
   AstTimeScaleType ts2;
   const char *c;
   char *old_fmt; 
   char *str;
   const char *txt; 
   double mjd;
   double val1;
   int l;
   int lt;
   int nc1;
   int nc;            
   int ndp;
   int rep;

/* Initialise. */
   nc = 0;

/* Check the global error status. */
   if ( !astOK ) return nc;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_frame;

/* Validate the axis index. */
   (void) astValidateAxis( this, axis, "astUnformat" );

/* First attempt to read the value using the parent unformat method, and
   note how many characters were used. We temporarily clear the Format 
   attribute if it has been set to a date format, since the parent Frame 
   class does not understand date format.*/
   txt = astGetFormat( this, axis );
   if( DateFormat( txt, &ndp ) ) {
       old_fmt = astStore( NULL, txt, strlen( txt ) + 1 );
       astClearFormat( this, axis );
   } else {
       old_fmt = NULL;
   }

   nc1 = (*parent_unformat)( this_frame, axis, string, &val1 );

/* Re-instate the original Format */
   if( old_fmt ) {
      astSetFormat( this,axis, old_fmt );
      old_fmt = astFree( old_fmt );
   }

/* The astReadDateTime function (defined within frame.c) does not allow
   for any extra text to be appended to the end of the formatted date/time
   (AST__BAD is returned if any such extra text is present). But astUnformat 
   is contracted to allow such text. So we need to make multiple attempts
   at reading the date/time in order to find the longest leading string
   which gives a non-bad value. First take a copy of the supplied string 
   si we can terminate it at any point we wish. */
   l = astChrLen( string );
   str = astStore( NULL, string, l + 1 );

/* Now attempt to read an ISO date from the start of the string. We
   switch off error reporting to avoid reports of unsuitable syntax. */
   rep = astReporting( 0 );

/* Attempt to read a date/time from the whol string. If this fails
   terminate the string in order to make it one character shorter and try
   again. */
   for( lt = l; lt > 0; lt-- ) {
      str[ lt ] = 0;
      mjd = astReadDateTime( str );
      if( !astOK ) astClearStatus;
      if( mjd != AST__BAD ) break;
   }

/* Re-instate error reporting. */
   astReporting( rep );

/* Free resources. */
   str = astFree( str );

/* If the whole non-blank start of the string was consumed, add on any
   trailing white space. */
   if( lt >= l ) lt = strlen( string );

/* If no date/time could be read, or if reading the value as a
   floating point value was at least as good, return the floating point
   value (assumed to be in the system and units of the TimeFrame. */
   if( mjd == AST__BAD || nc1 >= l ) {
      *value = val1;      
      nc = nc1;

/* Otherwise, if a date/time was read convert it to the TimeFrame system,
   etc. */
   } else if( mjd != AST__BAD ) {

/* Save the number of character read from the supplied string. */
      nc = lt;

/* We require a value in the timescale of the supplied TimeFrame. Get
   this TimeScale. */
      ts2 = astGetTimeScale( this );

/* If the supplied string gave the date/time as a Besselian epoch, the
   input timescale is TT, otherwise it is assumed to be the TimeScale of
   the TimeFrame. Locate the first non-space character. */
      c = string;
      while( *c && isspace( *c ) ) c++;

/* If the first non-space is a "B", assuming a TT timescale. Otherwise
   assume the timescale of the supplied TimeFrame. */
      ts1 = ( *c == 'B' || *c == 'b' ) ? AST__TT : ts2;

/* Create the Mapping and use it to transform the mjd value. */
      map = MakeMap( this, AST__MJD, astGetSystem( this ), ts1, ts2, 
                     0.0, astGetTimeOrigin( this ), "d", 
                     astGetUnit( this, 0 ), "astFormat" );
      if( map ) {
         astTran1( map, 1, &mjd, 1, value );
         map = astAnnul( map );
      } else {
         astError( AST__INCTS, "astUnformat(%s): Cannot convert the "
                "supplied date/time string (%s) to the required "
                "timescale (%s).", astGetClass( this ), string, 
                TimeScaleString( ts2 ) );
      }        
   }

/* Return the number of characters read. */
   return nc;
}

static int ValidateSystem( AstFrame *this, AstSystemType system, const char *method ) {
/*
*
*  Name:
*     ValidateSystem

*  Purpose:
*     Validate a value for a Frame's System attribute.

*  Type:
*     Protected virtual function.

*  Synopsis:
*     #include "timeframe.h"
*     int ValidateSystem( AstFrame *this, AstSystemType system, 
*                         const char *method )

*  Class Membership:
*     TimeFrame member function (over-rides the astValidateSystem method
*     inherited from the Frame class).

*  Description:
*     This function checks the validity of the supplied system value.
*     If the value is valid, it is returned unchanged. Otherwise, an
*     error is reported and a value of AST__BADSYSTEM is returned.

*  Parameters:
*     this
*        Pointer to the Frame.
*     system
*        The system value to be checked. 
*     method
*        Pointer to a constant null-terminated character string
*        containing the name of the method that invoked this function
*        to validate an axis index. This method name is used solely
*        for constructing error messages.

*  Returned Value:
*     The validated system value.

*  Notes:
*     - A value of AST__BADSYSTEM will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Variables: */
   AstSystemType result;              /* Validated system value */

/* Initialise. */
   result = AST__BADSYSTEM;

/* Check the global error status. */
   if ( !astOK ) return result;

/* If the value is out of bounds, report an error. */
   if ( system < FIRST_SYSTEM || system > LAST_SYSTEM ) {
         astError( AST__AXIIN, "%s(%s): Bad value (%d) given for the System "
                   "attribute of a %s.", method, astGetClass( this ),
                   (int) system, astGetClass( this ) );

/* Otherwise, return the supplied value. */
   } else {
      result = system;
   }

/* Return the result. */
   return result;
}

static void VerifyAttrs( AstTimeFrame *this, const char *purp, 
                         const char *attrs, const char *method ) {
/*
*  Name:
*     VerifyAttrs

*  Purpose:
*     Verify that usable attribute values are available.

*  Type:
*     Private function.

*  Synopsis:
*     #include "timeframe.h"
*     void VerifyAttrs( AstTimeFrame *this, const char *purp, 
*                       const char *attrs, const char *method  )

*  Class Membership:
*     TimeFrame member function 

*  Description:
*     This function tests each attribute listed in "attrs". It returns
*     without action if 1) an explicit value has been set for each attribute
*     or 2) the UseDefs attribute of the supplied TimeFrame is non-zero.
*
*     If UseDefs is zero (indicating that default values should not be
*     used for attributes), and any of the named attributes does not have
*     an explicitly set value, then an error is reported.

*  Parameters:
*     this
*        Pointer to the TimeFrame. 
*     purp
*        Pointer to a text string containing a message which will be
*        included in any error report. This shouldindicate the purpose
*        for which the attribute value is required. 
*     attrs
*        A string holding a space separated list of attribute names.
*     method
*        A string holding the name of the calling method for use in error
*        messages.

*/

/* Local Variables: */
   const char *a;
   const char *desc;
   const char *p;
   int len;
   int set;
   int state;

/* Check inherited status */
   if( !astOK ) return;

/* If the TimeFrame has a non-zero value for its UseDefs attribute, then
   all attributes are assumed to have usable values, since the defaults 
   will be used if no explicit value has been set. So we only need to do
   any checks if UseDefs is zero. */
   if( !astGetUseDefs( this ) ) {   

/* Loop round the "attrs" string identifying the start and length of each
   non-blank word in the string. */
      state = 0;
      p = attrs;
      while( 1 ) {
         if( state == 0 ) {
            if( !isspace( *p ) ) {
               a = p;
               len = 1;
               state = 1;
            }
         } else {
            if( isspace( *p ) || !*p ) {
   
/* The end of a word has just been reached. Compare it to each known
   attribute value. Get a flag indicating if the attribute has a set
   value, and a string describing the attribute.*/
               if( len > 0 ) {

                  if( !strncmp( "ClockLat", a, len ) ) {
                     set = astTestClockLat( this );
                     desc = "clock latitude";

                  } else if( !strncmp( "ClockLon", a, len ) ) {
                     set = astTestClockLon( this );
                     desc = "clock longitude";

                  } else if( !strncmp( "TimeOrigin", a, len ) ) {
                     set = astTestTimeOrigin( this );
                     desc = "time offset";

                  } else if( !strncmp( "TimeScale", a, len ) ) {
                     set = astTestTimeScale( this );
                     desc = "time scale";

                  } else {
                     astError( AST__INTER, "VerifyAttrs(TimeFrame): "
                               "Unknown attribute name \"%.*s\" supplied (AST "
                               "internal programming error).", len, a );
                  }

/* If the attribute does not have a set value, report an error. */
                  if( !set && astOK ) {
                     astError( AST__NOVAL, "%s(%s): Cannot %s.", method,
                               astGetClass( this ), purp );
                     astError( AST__NOVAL, "No value has been set for "
                               "the AST \"%.*s\" attribute (%s).", len, a,
                               desc );
                  }

/* Continue the word search algorithm. */
               }
               len = 0;
               state = 0;
            } else {
               len++;
            }
         }
         if( !*(p++) ) break;
      }
   }
}

/* Functions which access class attributes. */
/* ---------------------------------------- */
/*
*att++
*  Name:
*     ClockLat

*  Purpose:
*     The geodetic latitude of the observer/clock

*  Type:
*     Public attribute.

*  Synopsis:
*     String.

*  Description:
*     This attribute specifies the geodetic latitude of the observer's
*     clock, in degrees. It is used only when converting between certain
*     time scales (TDB, TCB, LMST, LAST). The default value for the attribute 
*     is zero. 

*     The value is stored internally in radians, but is converted to and 
*     from a degrees string for access. Some example input formats are: 
*     "22:19:23.2", "22 19 23.2", "22:19.387", "22.32311", "N22.32311", 
*     "-45.6", "S45.6". As indicated, the sign of the latitude can 
*     optionally be indicated using characters "N" and "S" in place of the 
*     usual "+" and "-". When converting the stored value to a string, the 
*     format "[s]dd:mm:ss" is used, when "[s]" is "N" or "S".

*  Applicability:
*     TimeFrame
*        All TimeFrames have this attribute.

*att--
*/
/* The geodetic latitude of the observer (radians). Clear the ClockLat value by
   setting it to AST__BAD, returning zero as the default value. Any value is 
   acceptable. */
astMAKE_CLEAR(TimeFrame,ClockLat,clocklat,AST__BAD)
astMAKE_GET(TimeFrame,ClockLat,double,0.0,((this->clocklat!=AST__BAD)?this->clocklat:0.0))
astMAKE_SET(TimeFrame,ClockLat,double,clocklat,value)
astMAKE_TEST(TimeFrame,ClockLat,(this->clocklat!=AST__BAD))


/*
*att++
*  Name:
*     ClockLon

*  Purpose:
*     The geodetic longitude of the observer/clock

*  Type:
*     Public attribute.

*  Synopsis:
*     String.

*  Description:
*     This attribute specifies the geodetic (or equivalently, geocentric)
*     longitude of the observer's clock, in degrees, measured positive 
*     eastwards. It is used only when converting between certain time 
*     scales (TDB, TCB, LMST, LAST). See also attribute ClockLat. The default 
*     value is zero.
*
*     The value is stored internally in radians, but is converted to and 
*     from a degrees string for access. Some example input formats are: 
*     "155:19:23.2", "155 19 23.2", "155:19.387", "155.32311", "E155.32311", 
*     "-204.67689", "W204.67689". As indicated, the sign of the longitude can 
*     optionally be indicated using characters "E" and "W" in place of the 
*     usual "+" and "-". When converting the stored value to a string, the 
*     format "[s]ddd:mm:ss" is used, when "[s]" is "E" or "W" and the 
*     numerical value is chosen to be less than 180 degrees.

*  Applicability:
*     TimeFrame
*        All TimeFrames have this attribute.

*att--
*/
/* The geodetic longitude of the observer (radians). Clear the ClockLon value by 
   setting it to AST__BAD, returning zero as the default value. Any value is 
   acceptable. */
astMAKE_CLEAR(TimeFrame,ClockLon,clocklon,AST__BAD)
astMAKE_GET(TimeFrame,ClockLon,double,0.0,((this->clocklon!=AST__BAD)?this->clocklon:0.0))
astMAKE_SET(TimeFrame,ClockLon,double,clocklon,value)
astMAKE_TEST(TimeFrame,ClockLon,(this->clocklon!=AST__BAD))

/*
*att++
*  Name:
*     TimeOrigin

*  Purpose:
*     The zero point for TimeFrame axis values

*  Type:
*     Public attribute.

*  Synopsis:
*     Floating point.

*  Description:
*     This specifies the origin from which all time values are measured.
*     The default value (zero) results in the TimeFrame describing
*     absolute time values in the system given by the System attribute
*     (e.g. MJD, Julian epoch, etc). If a TimeFrame is to be used to
*     describe elapsed time since some origin, the TimeOrigin attribute 
*     should be set to hold the required origin value. The TimeOrigin value 
*     stored inside the TimeFrame structure is modified whenever TimeFrame 
*     attribute values are changed so that it refers to the original moment 
*     in time. 
*
*  Input Formats:
*     The formats accepted when setting a TimeOrigin value are listed
*     below. They are all case-insensitive and are generally tolerant
*     of extra white space and alternative field delimiters:
*
*     - Besselian Epoch: Expressed in decimal years, with or without
*     decimal places ("B1950" or "B1976.13" for example).
*
*     - Julian Epoch: Expressed in decimal years, with or without
*     decimal places ("J2000" or "J2100.9" for example).
*
*     - Units: An unqualified decimal value is interpreted as a value in
*     the system specified by the TimeFrame's System attribute, in the
*     units given by the TimeFrame's Unit attribute. Alternatively, an 
*     appropriate unit string can be appended to the end of the floating 
*     point value ("123.4 d" for example), in which case the supplied value 
*     is scaled into the units specified by the Unit attribute.
*
*     - Julian Date: With or without decimal places ("JD 2454321.9" for
*     example).
*
*     - Modified Julian Date: With or without decimal places
*     ("MJD 54321.4" for example).
*
*     - Gregorian Calendar Date: With the month expressed either as an
*     integer or a 3-character abbreviation, and with optional decimal
*     places to represent a fraction of a day ("1996-10-2" or
*     "1996-Oct-2.6" for example). If no fractional part of a day is
*     given, the time refers to the start of the day (zero hours).
*
*     - Gregorian Date and Time: Any calendar date (as above) but with
*     a fraction of a day expressed as hours, minutes and seconds
*     ("1996-Oct-2 12:13:56.985" for example). The date and time can be 
*     separated by a space or by a "T" (as used by ISO8601 format).

*  Output Format:
*     When enquiring TimeOrigin values, the returned formatted floating
*     point value represents a value in the TimeFrame's System, in the unit 
*     specified by the TimeFrame's Unit attribute.

*  Applicability:
*     TimeFrame
*        All TimeFrames have this attribute.

*att--
*/
/* The time origin, stored internally in the default units associated
   with the current System value. Clear the TimeOrigin value  by setting it 
   to AST__BAD, which gives 0.0 as the default value. Any value is acceptable. */
astMAKE_CLEAR(TimeFrame,TimeOrigin,timeorigin,AST__BAD)
astMAKE_GET(TimeFrame,TimeOrigin,double,0.0,((this->timeorigin!=AST__BAD)?this->timeorigin:0.0))
astMAKE_SET(TimeFrame,TimeOrigin,double,timeorigin,value)
astMAKE_TEST(TimeFrame,TimeOrigin,( this->timeorigin != AST__BAD ))

/*
*att++
*  Name:
*     AlignTimeScale

*  Purpose:
*     Time scale to use when aligning TimeFrames.

*  Type:
*     Public attribute.

*  Synopsis:
*     String.

*  Description:
*     This attribute controls how a TimeFrame behaves when it is used (by
c     astFindFrame or astConvert) as a template to match another (target)
f     AST_FINDFRAME or AST_CONVERT) as a template to match another (target)
*     TimeFrame. It identifies the time scale in which alignment is 
*     to occur. See the TimeScale attribute for a desription of the values 
*     which may be assigned to this attribute. The default AlignTimeScale 
*     value depends on the current value of TimeScale: if TimeScale is
*     UT1, GMST, LMST or LAST, the default for AlignTimeScale is UT1, for all
*     other TimeScales the default is TAI.
*
c     When astFindFrame or astConvert is used on two TimeFrames (potentially 
f     When AST_FindFrame or AST_CONVERT is used on two TimeFrames (potentially 
*     describing different time coordinate systems), it returns a Mapping 
*     which can be used to transform a position in one TimeFrame into the
*     corresponding position in the other. The Mapping is made up of the
*     following steps in the indicated order:
*
*     - Map values from the system used by the target (MJD, JD, etc) to the 
*     system specified by the AlignSystem attribute.
*
*     - Map these values from the target's time scale to the time scale 
*     specified by the AlignTimeScale attribute.
*
*     - Map these values from the time scale specified by the AlignTimeScale 
*     attribute, to the template's time scale.
*
*     - Map these values from the system specified by the AlignSystem 
*     attribute, to the system used by the template.

*  Applicability:
*     TimeFrame
*        All TimeFrames have this attribute.

*att--
*/
astMAKE_TEST(TimeFrame,AlignTimeScale,( this->aligntimescale != AST__BADTS ))
astMAKE_CLEAR(TimeFrame,AlignTimeScale,aligntimescale,AST__BADTS)
astMAKE_SET(TimeFrame,AlignTimeScale,AstTimeScaleType,aligntimescale,(
            ( ( value >= FIRST_TS ) && ( value <= LAST_TS ) ) ?
                 value :
                 ( astError( AST__ATTIN, "%s(%s): Bad value (%d) "
                             "given for AlignTimeScale attribute.",
                             "astSetAlignTimeScale", astGetClass( this ), (int) value ),

/* Leave the value unchanged on error. */
                                            this->aligntimescale ) ) )

/*
*att++
*  Name:
*     TimeScale

*  Purpose:
*     Time scale.

*  Type:
*     Public attribute.

*  Synopsis:
*     String.

*  Description:
*     This attribute identifies the time scale to which the time axis values 
*     of a TimeFrame refer, and may take any of the values listed in the 
*     "Time Scales" section (below). Note, conversions which require 
*     knowledge of DUT1 (the difference between UT1 and UTC) are not currently
*     supported. This means that UT1 can only be converted to the other 
*     angle-based scales such as GMST, LMST and LAST. An error will be reported
*     about "incompatible timescales" if an attempt is made to convert
*     between an angle-based timescale and any of the other time scales.
*
*     The default TimeScale value depends on the current System value; if
*     the current TimeFrame system is "Besselian epoch" the default is
*     "TT", otherwise it is "TAI". Note, if the System attribute is set
*     so that the TimeFrame represents Besselian Epoch, then an error
*     will be reported if an attempt is made to set the TimeScale to 
*     anything other than TT.

*  Applicability:
*     TimeFrame
*        All TimeFrames have this attribute.

*  Time Scales:
*     The TimeFrame class supports the following TimeScale values (all are
*     case-insensitive):
*
*     - "TAI" - International Atomic Time
*     - "UTC" - Coordinated Universal Time
*     - "UT1" - Universal Time
*     - "GMST" - Greenwich Mean Sidereal Time
*     - "LAST" - Local Apparent Sidereal Time
*     - "LMST" - Local Mean Sidereal Time
*     - "TT" - Terrestrial Time
*     - "TDB" - Barycentric Dynamical Time
*     - "TCB" - Barycentric Coordinate Time
*     - "TCG" - Geocentric Coordinate Time
*
*     An very informative description of these and other time scales is
*     available at http://www.ucolick.org/~sla/leapsecs/timescales.html.

*  UTC Warnings:
*     UTC should ideally be expressed using separate hours, minutes and 
*     seconds fields (or at least in seconds for a given date) if leap seconds 
*     are to be taken into account. Since the TimeFrame class represents 
*     each moment in time using a single floating point number (the axis value)
*     there will be an ambiguity during a leap second. Thus an error of up to 
*     1 second can result when using AST to convert a UTC time to another 
*     time scale if the time occurs within a leap second. Leap seconds 
*     occur at most twice a year, and are introduced to take account of 
*     variation in the rotation of the earth. The most recent leap second 
*     occurred on 1st January 1999. Although in the vast majority of cases 
*     leap second ambiguities won't matter, there are potential problems in 
*     on-line data acquisition systems and in critical applications involving 
*     taking the difference between two times. 

*att--
*/
astMAKE_TEST(TimeFrame,TimeScale,( this->timescale != AST__BADTS ))

/* Copy constructor. */
/* ----------------- */

/* Destructor. */
/* ----------- */

/* Dump function. */
/* -------------- */
static void Dump( AstObject *this_object, AstChannel *channel ) {
/*
*  Name:
*     Dump

*  Purpose:
*     Dump function for TimeFrame objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Dump( AstObject *this, AstChannel *channel )

*  Description:
*     This function implements the Dump function which writes out data
*     for the TimeFrame class to an output Channel.

*  Parameters:
*     this
*        Pointer to the TimeFrame whose data are being written.
*     channel
*        Pointer to the Channel to which the data are being written.
*/

/* Local Variables: */
   AstTimeFrame *this;           /* Pointer to the TimeFrame structure */
   AstTimeScaleType ts;          /* TimeScale attribute value */
   const char *sval;             /* Pointer to string value */
   double dval;                  /* Double value */
   int set;                      /* Attribute value set? */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the TimeFrame structure. */
   this = (AstTimeFrame *) this_object;

/* Write out values representing the instance variables for the
   TimeFrame class.  Accompany these with appropriate comment strings,
   possibly depending on the values being written.*/

/* In the case of attributes, we first use the appropriate (private)
   Test...  member function to see if they are set. If so, we then use
   the (private) Get... function to obtain the value to be written
   out.

   For attributes which are not set, we use the astGet... method to
   obtain the value instead. This will supply a default value
   (possibly provided by a derived class which over-rides this method)
   which is more useful to a human reader as it corresponds to the
   actual default attribute value.  Since "set" will be zero, these
   values are for information only and will not be read back. */

/* TimeScale. */
/* ---------- */
   set = TestTimeScale( this );
   ts = set ? GetTimeScale( this ) : astGetTimeScale( this );

/* If set, convert explicitly to a string for the external
   representation. */
   sval = "";
   if ( set ) {
      if ( astOK ) {
         sval = TimeScaleString( ts );

/* Report an error if the TimeScale value was not recognised. */
         if ( !sval ) {
            astError( AST__SCSIN,
                     "%s(%s): Corrupt %s contains invalid time scale "
                     "identification code (%d).", "astWrite", 
                     astGetClass( channel ), astGetClass( this ), (int) ts );
         }
      }

/* If not set, use astGetAttrib which returns a string value using
   (possibly over-ridden) methods. */
   } else {
      sval = astGetAttrib( this_object, "timescale" );
   }

/* Write out the value. */
   astWriteString( channel, "TmScl", set, 1, sval, "Time scale" );

/* AlignTimeScale. */
/* --------------- */
   set = TestAlignTimeScale( this );
   ts = set ? GetAlignTimeScale( this ) : astGetAlignTimeScale( this );

/* If set, convert explicitly to a string for the external representation. */
   if ( set ) {
      if ( astOK ) {
         sval = TimeScaleString( ts );

/* Report an error if the TimeScale value was not recognised. */
         if ( !sval ) {
            astError( AST__SCSIN,
                     "%s(%s): Corrupt %s contains invalid alignment time "
                     "scale identification code (%d).", "astWrite", 
                     astGetClass( channel ), astGetClass( this ), (int) ts );
         }
      }

/* If not set, use astGetAttrib which returns a string value using
   (possibly over-ridden) methods. */
   } else {
      sval = astGetAttrib( this_object, "aligntimescale" );
   }

/* Write out the value. */
   astWriteString( channel, "ATmScl", set, 0, sval, "Alignment time scale" );

/* ClockLat. */
/* --------- */
   set = TestClockLat( this );
   dval = set ? GetClockLat( this ) : astGetClockLat( this );
   astWriteDouble( channel, "ClLat", set, 0, dval, "Observers geodetic latitude (rads)" );

/* ClockLon. */
/* --------- */
   set = TestClockLon( this );
   dval = set ? GetClockLon( this ) : astGetClockLon( this );
   astWriteDouble( channel, "ClLon", set, 0, dval, "Observers geodetic longitude (rads)" );

/* TimeOrigin. */
/* ----------- */
   set = TestTimeOrigin( this );
   dval = set ? GetTimeOrigin( this ) : astGetTimeOrigin( this );
   astWriteDouble( channel, "TmOrg", set, 0, dval, "Time offset" );

}

/* Standard class functions. */
/* ========================= */
/* Implement the astIsATimeFrame and astCheckTimeFrame functions using the 
   macros defined for this purpose in the "object.h" header file. */
astMAKE_ISA(TimeFrame,Frame,check,&class_init)
astMAKE_CHECK(TimeFrame)

AstTimeFrame *astTimeFrame_( const char *options, ... ) {
/*
*+
*  Name:
*     astTimeFrame

*  Purpose:
*     Create a TimeFrame.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "timeframe.h"
*     AstTimeFrame *astTimeFrame( const char *options, ... )

*  Class Membership:
*     TimeFrame constructor.

*  Description:
*     This function creates a new TimeFrame and optionally initialises its
*     attributes.

*  Parameters:
*     options
*        Pointer to a null terminated string containing an optional
*        comma-separated list of attribute assignments to be used for
*        initialising the new TimeFrame. The syntax used is the same as for the
*        astSet method and may include "printf" format specifiers identified
*        by "%" symbols in the normal way.
*     ...
*        If the "options" string contains "%" format specifiers, then an
*        optional list of arguments may follow it in order to supply values to
*        be substituted for these specifiers. The rules for supplying these
*        are identical to those for the astSet method (and for the C "printf"
*        function).

*  Returned Value:
*     A pointer to the new TimeFrame.

*  Notes:
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*-

*  Implementation Notes:
*     - This function implements the basic TimeFrame constructor which
*     is available via the protected interface to the TimeFrame class.
*     A public interface is provided by the astTimeFrameId_ function.
*/

/* Local Variables: */
   AstMapping *um;               /* Mapping from default to actual units */
   AstTimeFrame *new;            /* Pointer to new TimeFrame */
   AstSystemType s;              /* System */
   const char *u;                /* Units string */
   va_list args;                 /* Variable argument list */

/* Check the global status. */
   if ( !astOK ) return NULL;

/* Initialise the TimeFrame, allocating memory and initialising the virtual
   function table as well if necessary. */
   new = astInitTimeFrame( NULL, sizeof( AstTimeFrame ), !class_init, 
                           &class_vtab, "TimeFrame" );

/* If successful, note that the virtual function table has been initialised. */
   if ( astOK ) {
      class_init = 1;

/* Obtain the variable argument list and pass it along with the options string
   to the astVSet method to initialise the new TimeFrame's attributes. */
      va_start( args, options );
      astVSet( new, options, args );
      va_end( args );

/* Check the Units are appropriate for the System. */
      u = astGetUnit( new, 0 );
      s = astGetSystem( new );
      um = astUnitMapper( DefUnit( s, "astTimeFrame", "TimeFrame" ), 
                          u, NULL, NULL );
      if( um ) {
         um = astAnnul( um );
      } else {
         astError( AST__BADUN, "astTimeFrame: Inappropriate units (%s) "
                   "specified for a %s axis.", u, SystemLabel( s ) );
      }      

/* If an error occurred, clean up by deleting the new object. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return a pointer to the new TimeFrame. */
   return new;
}

AstTimeFrame *astInitTimeFrame_( void *mem, size_t size, int init,
                                 AstTimeFrameVtab *vtab, const char *name ) {
/*
*+
*  Name:
*     astInitTimeFrame

*  Purpose:
*     Initialise a TimeFrame.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "timeframe.h"
*     AstTimeFrame *astInitTimeFrame( void *mem, size_t size, int init,
*                                     AstFrameVtab *vtab, const char *name )

*  Class Membership:
*     TimeFrame initialiser.

*  Description:
*     This function is provided for use by class implementations to
*     initialise a new TimeFrame object. It allocates memory (if
*     necessary) to accommodate the TimeFrame plus any additional data
*     associated with the derived class. It then initialises a
*     TimeFrame structure at the start of this memory. If the "init"
*     flag is set, it also initialises the contents of a virtual function
*     table for a TimeFrame at the start of the memory passed via the
*     "vtab" parameter.

*  Parameters:
*     mem
*        A pointer to the memory in which the TimeFrame is to be
*	created. This must be of sufficient size to accommodate the
*	TimeFrame data (sizeof(TimeFrame)) plus any data used by
*	the derived class. If a value of NULL is given, this function
*	will allocate the memory itself using the "size" parameter to
*	determine its size.
*     size
*        The amount of memory used by the TimeFrame (plus derived
*	class data). This will be used to allocate memory if a value of
*	NULL is given for the "mem" parameter. This value is also stored
*	in the TimeFrame structure, so a valid value must be supplied
*	even if not required for allocating memory.
*     init
*        A logical flag indicating if the TimeFrame's virtual function
*	table is to be initialised. If this value is non-zero, the
*	virtual function table will be initialised by this function.
*     vtab
*        Pointer to the start of the virtual function table to be
*	associated with the new TimeFrame.
*     name
*        Pointer to a constant null-terminated character string which
*	contains the name of the class to which the new object belongs
*	(it is this pointer value that will subsequently be returned by
*	the astGetClass method).

*  Returned Value:
*     A pointer to the new TimeFrame.

*  Notes:
*     -  A null pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*-
*/

/* Local Variables: */
   AstTimeFrame *new;        /* Pointer to the new TimeFrame */

/* Check the global status. */
   if ( !astOK ) return NULL;

/* If necessary, initialise the virtual function table. */
   if ( init ) astInitTimeFrameVtab( vtab, name );

/* Initialise a 1D Frame structure (the parent class) as the first component
   within the TimeFrame structure, allocating memory if necessary. */
   new = (AstTimeFrame *) astInitFrame( mem, size, 0,
                                        (AstFrameVtab *) vtab, name, 1 );

   if ( astOK ) {

/* Initialise the TimeFrame data. */
/* ----------------------------- */
/* Initialise all attributes to their "undefined" values. */
      new->clocklat = AST__BAD;
      new->clocklon = AST__BAD;
      new->timeorigin = AST__BAD;
      new->timescale = AST__BADTS;
      new->aligntimescale = AST__BADTS;

/* If an error occurred, clean up by deleting the new object. */
      if ( !astOK ) new = astDelete( new );

   }

/* Return a pointer to the new object. */
   return new;
}

AstTimeFrame *astLoadTimeFrame_( void *mem, size_t size,
                                 AstTimeFrameVtab *vtab, 
                                 const char *name, AstChannel *channel ) {
/*
*+
*  Name:
*     astLoadTimeFrame

*  Purpose:
*     Load a TimeFrame.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "timeframe.h"
*     AstTimeFrame *astLoadTimeFrame( void *mem, size_t size,
*                                      AstTimeFrameVtab *vtab, 
*                                      const char *name, AstChannel *channel )

*  Class Membership:
*     TimeFrame loader.

*  Description:
*     This function is provided to load a new TimeFrame using data read
*     from a Channel. It first loads the data used by the parent class
*     (which allocates memory if necessary) and then initialises a
*     TimeFrame structure in this memory, using data read from the
*     input Channel.

*  Parameters:
*     mem
*        A pointer to the memory into which the TimeFrame is to be
*        loaded.  This must be of sufficient size to accommodate the
*        TimeFrame data (sizeof(TimeFrame)) plus any data used by
*        derived classes. If a value of NULL is given, this function
*        will allocate the memory itself using the "size" parameter to
*        determine its size.
*     size
*        The amount of memory used by the TimeFrame (plus derived class
*        data).  This will be used to allocate memory if a value of
*        NULL is given for the "mem" parameter. This value is also
*        stored in the TimeFrame structure, so a valid value must be
*        supplied even if not required for allocating memory.
*
*        If the "vtab" parameter is NULL, the "size" value is ignored
*        and sizeof(AstTimeFrame) is used instead.
*     vtab
*        Pointer to the start of the virtual function table to be
*        associated with the new TimeFrame. If this is NULL, a pointer
*        to the (static) virtual function table for the TimeFrame class
*        is used instead.
*     name
*        Pointer to a constant null-terminated character string which
*        contains the name of the class to which the new object
*        belongs (it is this pointer value that will subsequently be
*        returned by the astGetClass method).
*
*        If the "vtab" parameter is NULL, the "name" value is ignored
*        and a pointer to the string "TimeFrame" is used instead.

*  Returned Value:
*     A pointer to the new TimeFrame.

*  Notes:
*     - A null pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*-
*/

/* Local Variables: */
   AstTimeFrame *new;            /* Pointer to the new TimeFrame */
   char *sval;                   /* Pointer to string value */

/* Initialise. */
   new = NULL;

/* Check the global error status. */
   if ( !astOK ) return new;

/* If a NULL virtual function table has been supplied, then this is
   the first loader to be invoked for this TimeFrame. In this case the
   TimeFrame belongs to this class, so supply appropriate values to be
   passed to the parent class loader (and its parent, etc.). */
   if ( !vtab ) {
      size = sizeof( AstTimeFrame );
      vtab = &class_vtab;
      name = "TimeFrame";

/* If required, initialise the virtual function table for this class. */
      if ( !class_init ) {
         astInitTimeFrameVtab( vtab, name );
         class_init = 1;
      }
   }

/* Invoke the parent class loader to load data for all the ancestral
   classes of the current one, returning a pointer to the resulting
   partly-built TimeFrame. */
   new = astLoadFrame( mem, size, (AstFrameVtab *) vtab, name,
                       channel );
   if ( astOK ) {

/* Read input data. */
/* ================ */
/* Request the input Channel to read all the input data appropriate to
   this class into the internal "values list". */
       astReadClassData( channel, "TimeFrame" );

/* Now read each individual data item from this list and use it to
   initialise the appropriate instance variable(s) for this class. */

/* In the case of attributes, we first read the "raw" input value,
   supplying the "unset" value as the default. If a "set" value is
   obtained, we then use the appropriate (private) Set... member
   function to validate and set the value properly. */

/* TimeScale. */
/* ---------- */
/* Set the default and read the external representation as a string. */
       new->timescale = AST__BADTS;
       sval = astReadString( channel, "tmscl", NULL );

/* If a value was read, convert from a string to a TimeScale code. */
       if ( sval ) {
          if ( astOK ) {
             new->timescale = TimeScaleCode( sval );

/* Report an error if the value wasn't recognised. */
             if ( new->timescale == AST__BADTS ) {
                astError( AST__ATTIN,
                          "astRead(%s): Invalid time scale description "
                          "\"%s\".", astGetClass( channel ), sval );
             }
          }

/* Free the string value. */
          sval = astFree( sval );
       }

/* AlignTimeScale. */
/* --------------- */
/* Set the default and read the external representation as a string. */
       new->aligntimescale = AST__BADTS;
       sval = astReadString( channel, "atmscl", NULL );

/* If a value was read, convert from a string to a TimeScale code. */
       if ( sval ) {
          if ( astOK ) {
             new->aligntimescale = TimeScaleCode( sval );

/* Report an error if the value wasn't recognised. */
             if ( new->aligntimescale == AST__BADTS ) {
                astError( AST__ATTIN,
                          "astRead(%s): Invalid alignment time scale "
                          "description \"%s\".", astGetClass( channel ), sval );
             }
          }

/* Free the string value. */
          sval = astFree( sval );
       }

/* ClockLat. */
/* ------- */
      new->clocklat = astReadDouble( channel, "cllat", AST__BAD );
      if ( TestClockLat( new ) ) SetClockLat( new, new->clocklat );

/* ClockLon. */
/* ------- */
      new->clocklon = astReadDouble( channel, "cllon", AST__BAD );
      if ( TestClockLon( new ) ) SetClockLon( new, new->clocklon );

/* TimeOrigin. */
/* --------- */
      new->timeorigin = astReadDouble( channel, "tmorg", AST__BAD );
      if ( TestTimeOrigin( new ) ) SetTimeOrigin( new, new->timeorigin );

/* If an error occurred, clean up by deleting the new TimeFrame. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return the new TimeFrame pointer. */
   return new;
}

/* Virtual function interfaces. */
/* ============================ */
/* These provide the external interface to the virtual functions defined by
   this class. Each simply checks the global error status and then locates and
   executes the appropriate member function, using the function pointer stored
   in the object's virtual function table (this pointer is located using the
   astMEMBER macro defined in "object.h").

   Note that the member function may not be the one defined here, as it may
   have been over-ridden by a derived class. However, it should still have the
   same interface. */

void astSetTimeScale_( AstTimeFrame *this, AstTimeScaleType value ){
   if ( !astOK ) return;
   (**astMEMBER(this,TimeFrame,SetTimeScale))(this,value);
}

void astClearTimeScale_( AstTimeFrame *this ){
   if ( !astOK ) return;
   (**astMEMBER(this,TimeFrame,ClearTimeScale))(this);
}

AstTimeScaleType astGetAlignTimeScale_( AstTimeFrame *this ) {
   if ( !astOK ) return AST__BADTS;
   return (**astMEMBER(this,TimeFrame,GetAlignTimeScale))(this);
}

AstTimeScaleType astGetTimeScale_( AstTimeFrame *this ) {
   if ( !astOK ) return AST__BADTS;
   return (**astMEMBER(this,TimeFrame,GetTimeScale))(this);
}

double astCurrentTime_( AstTimeFrame *this ){
   if ( !astOK ) return AST__BAD;
   return (**astMEMBER(this,TimeFrame,CurrentTime))(this);
}
   


/* Special public interface functions. */
/* =================================== */
/* These provide the public interface to certain special functions
   whose public interface cannot be handled using macros (such as
   astINVOKE) alone. In general, they are named after the
   corresponding protected version of the function, but with "Id"
   appended to the name. */

/* Public Interface Function Prototypes. */
/* ------------------------------------- */
/* The following functions have public prototypes only (i.e. no
   protected prototypes), so we must provide local prototypes for use
   within this module. */
AstTimeFrame *astTimeFrameId_( const char *, ... );

/* Special interface function implementations. */
/* ------------------------------------------- */
AstTimeFrame *astTimeFrameId_( const char *options, ... ) {
/*
*++
*  Name:
c     astTimeFrame
f     AST_TIMEFRAME

*  Purpose:
*     Create a TimeFrame.

*  Type:
*     Public function.

*  Synopsis:
c     #include "timeframe.h"
c     AstTimeFrame *astTimeFrame( const char *options, ... )
f     RESULT = AST_TIMEFRAME( OPTIONS, STATUS )

*  Class Membership:
*     TimeFrame constructor.

*  Description:
*     This function creates a new TimeFrame and optionally initialises
*     its attributes.
*
*     A TimeFrame is a specialised form of one-dimensional Frame which 
*     represents various coordinate systems used to describe positions in
*     time.
*
*     A TimeFrame represents a moment in time as either an Modified Julian 
*     Date (MJD), a Julian Date (JD), a Besselian epoch or a Julian epoch,
*     as determined by the System attribute. Optionally, a zero point can be 
*     specified (using attribute TimeOrigin) which results in the TimeFrame 
*     representing time offsets from the specified zero point.
*
*     Even though JD and MJD are defined as being in units of days, the
*     TimeFrame class allows other units to be used (via the Unit attribute) 
*     on the basis of simple scalings (60 seconds = 1 minute, 60 minutes = 1 
*     hour, 24 hours = 1 day, 365.25 days = 1 year). Likewise, Julian epochs 
*     can be described in units other than the usual years. Besselian epoch 
*     are always represented in units of (tropical) years.
*
*     The TimeScale attribute allows the time scale to be specified (that
*     is, the physical proces used to define the rate of flow of time).
*     MJD, JD and Julian epoch can be used to represent a time in any
*     supported time scale. However, Besselian epoch may only be used with the 
*     "TT" (Terrestrial Time) time scale. The list of supported time scales
*     includes universal time and siderial time. Strictly, these represent 
*     angles rather than time scales, but are included in the list since
*     they are in common use and are often thought of as time scales.
*
*     When a time value is formatted it can be formated either as a simple
*     floating point value, or as a Gregorian date (see the Format
*     attribute).

*  Parameters:
c     options
f     OPTIONS = CHARACTER * ( * ) (Given)
c        Pointer to a null-terminated string containing an optional
c        comma-separated list of attribute assignments to be used for
c        initialising the new TimeFrame. The syntax used is identical to
c        that for the astSet function and may include "printf" format
c        specifiers identified by "%" symbols in the normal way.
c        If no initialisation is required, a zero-length string may be
c        supplied.
f        A character string containing an optional comma-separated
f        list of attribute assignments to be used for initialising the
f        new TimeFrame. The syntax used is identical to that for the
f        AST_SET routine. If no initialisation is required, a blank
f        value may be supplied.
c     ...
c        If the "options" string contains "%" format specifiers, then
c        an optional list of additional arguments may follow it in
c        order to supply values to be substituted for these
c        specifiers. The rules for supplying these are identical to
c        those for the astSet function (and for the C "printf"
c        function).
f     STATUS = INTEGER (Given and Returned)
f        The global status.

*  Returned Value:
c     astTimeFrame()
f     AST_TIMEFRAME = INTEGER
*        A pointer to the new TimeFrame.

*  Notes:
*     - When conversion between two TimeFrames is requested (as when
c     supplying TimeFrames to astConvert),
f     supplying TimeFrames AST_CONVERT),
*     account will be taken of the nature of the time coordinate systems 
*     they represent, together with any qualifying time scale, offset,
*     unit, etc. The AlignSystem and AlignTimeScale attributes will also be 
*     taken into account. 
*     - A null Object pointer (AST__NULL) will be returned if this
c     function is invoked with the AST error status set, or if it
f     function is invoked with STATUS set to an error value, or if it
*     should fail for any reason.
*--

*  Implementation Notes:
*     - This function implements the external (public) interface to
*     the astTimeFrame constructor function. It returns an ID value
*     (instead of a true C pointer) to external users, and must be
*     provided because astTimeFrame_ has a variable argument list which
*     cannot be encapsulated in a macro (where this conversion would
*     otherwise occur).
*     - The variable argument list also prevents this function from
*     invoking astTimeFrame_ directly, so it must be a
*     re-implementation of it in all respects, except for the final
*     conversion of the result to an ID value.
*/

/* Local Variables: */
   AstMapping *um;               /* Mapping from default to actual units */
   AstTimeFrame *new;            /* Pointer to new TimeFrame */
   AstSystemType s;              /* System */
   const char *u;                /* Units string */
   va_list args;                 /* Variable argument list */

/* Check the global status. */
   if ( !astOK ) return NULL;

/* Initialise the TimeFrame, allocating memory and initialising the virtual
   function table as well if necessary. */
   new = astInitTimeFrame( NULL, sizeof( AstTimeFrame ), !class_init, 
                           &class_vtab, "TimeFrame" );

/* If successful, note that the virtual function table has been initialised. */
   if ( astOK ) {
      class_init = 1;

/* Obtain the variable argument list and pass it along with the options string
   to the astVSet method to initialise the new TimeFrame's attributes. */
      va_start( args, options );
      astVSet( new, options, args );
      va_end( args );

/* Check the Units are appropriate for the System. */
      u = astGetUnit( new, 0 );
      s = astGetSystem( new );
      um = astUnitMapper( DefUnit( s, "astTimeFrame", "TimeFrame" ), 
                          u, NULL, NULL );
      if( um ) {
         um = astAnnul( um );
      } else {
         astError( AST__BADUN, "astTimeFrame: Inappropriate units (%s) "
                   "specified for a %s axis.", u, SystemLabel( s ) );
      }      

/* If an error occurred, clean up by deleting the new object. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return an ID value for the new TimeFrame. */
   return astMakeId( new );
}















