/*
*class++
*  Name:
*     SkyAxis

*  Purpose:
*     Store celestial axis information.

*  Constructor Function:
*     None.

*  Description:
*     The SkyAxis class is used to store information associated with a
*     particular axis of a SkyFrame. It is used internally by the AST
*     library and has no constructor function. You should encounter it
c     only within textual output (e.g. from astWrite).
f     only within textual output (e.g. from AST_WRITE).

*  Inheritance:
*     The SkyAxis class inherits from the Axis class.

*  Copyright:
*     <COPYRIGHT_STATEMENT>

*  Authors:
*     RFWS: R.F. Warren-Smith (Starlink)
*     DSB: B.S. Berry (Starlink)

*  History:
*     1-MAR-1996 (RFWS):
*        Original version.
*     19-APR-1996 (RFWS):
*        Tidied up, etc.
*     8-MAY-1996 (RFWS):
*        Remove leading minus sign from formatted HMS string if all
*        fields are zero.
*     9-MAY-1996 (RFWS):
*        Fixed bug in rounding of fractional parts of HMS strings and
*        improved algorithm to cope gracefully with requests for
*        excessive numbers of decimal places.
*     13-MAY-1996 (RFWS):
*        Over-ride the astGetAxisDirection method so that a SkyAxis
*        with the AsTime attribute set is displayed in reverse by
*        default.
*     17-MAY-1996 (RFWS):
*        Change AxisNorm to return a bad coordinate value if a bad
*        value is given.
*     11-SEP-1996 (RFWS):
*        Added AxisGap and DHmsGap (written by DSB).
*     26-FEB-1998 (RFWS):
*        Over-ride the astAxisUnformat method.
*     6-MAR-1998 (RFWS):
*        Add formatting options to omit degrees/hours field and change
*        all affected functions.
*     10-AUG-2000 (DSB):
*        Fixed bug in DHmsFormat which could cause (for instance) a formatted 
*        galactic longitude value of zero to be formated as "-0.-0".
*     29-AUG-2001 (DSB):
*        Added AxisDistance and AxisOffset.

*class--
*/

/* Module Macros. */
/* ============== */
/* Set the name of the class we are implementing. This indicates to the header
   files that define class interfaces that they should make "protected"
   symbols available. */
#define astCLASS SkyAxis

/* Header files. */
/* ============= */
#include "ast_err.h"             /* Error code definitions */

/* Interface definitions. */
/* ---------------------- */
#include "slalib.h"              /* SLALIB interface */
#include "error.h"               /* Error reporting facilities */
#include "memory.h"              /* Memory allocation facilities */
#include "pointset.h"            /* Sets of points (for AST__BAD) */
#include "axis.h"                /* Axis (parent) class interface */
#include "skyaxis.h"             /* Interface definition for this class */

/* C header files. */
/* --------------- */
#include <ctype.h>
#include <limits.h>
#include <math.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Module Variables. */
/* ================= */
/* Define the class virtual function table and its initialisation flag as
   static variables. */
static AstSkyAxisVtab class_vtab; /* Virtual function table */
static int class_init = 0;       /* Virtual function table initialised? */

/* Pointers to parent class methods which are extended by this class. */
static const char *(* parent_getattrib)( AstObject *, const char * );
static const char *(* parent_getaxislabel)( AstAxis * );
static const char *(* parent_getaxissymbol)( AstAxis * );
static const char *(* parent_getaxisunit)( AstAxis * );
static int (* parent_testattrib)( AstObject *, const char * );
static int (*parent_getaxisdirection)( AstAxis *this );
static void (* parent_axisoverlay)( AstAxis *, AstAxis * );
static void (* parent_clearattrib)( AstObject *, const char * );
static void (* parent_setattrib)( AstObject *, const char * );

/* External Interface Function Prototypes. */
/* ======================================= */
/* The following functions have public prototypes only (i.e. no
   protected prototypes), so we must provide local prototypes for use
   within this module. */
AstSkyAxis *astSkyAxisId_( const char *, ... );

/* Prototypes for Private Member Functions. */
/* ======================================== */
static const char *AxisAbbrev( AstAxis *, const char *, const char * );
static const char *AxisFormat( AstAxis *, double );
static const char *GetAttrib( AstObject *, const char * );
static const char *GetAxisFormat( AstAxis * );
static const char *GetAxisLabel( AstAxis * );
static const char *GetAxisSymbol( AstAxis * );
static const char *GetAxisUnit( AstAxis * );
static const char *DHmsFormat( const char *, double );
static const char *DHmsUnit( const char *, int );
static double AxisGap( AstAxis *, double, int * );
static double AxisDistance( AstAxis *, double, double );
static double AxisOffset( AstAxis *, double, double );
static double DHmsGap( const char *, double, int * );
static int AxisUnformat( AstAxis *, const char *, double * );
static int GetAxisAsTime( AstSkyAxis * );
static int GetAxisDirection( AstAxis * );
static int GetAxisIsLatitude( AstSkyAxis * );
static int TestAttrib( AstObject *, const char * );
static int TestAxisAsTime( AstSkyAxis * );
static int TestAxisFormat( AstAxis * );
static int TestAxisIsLatitude( AstSkyAxis * );
static void AxisNorm( AstAxis *, double * );
static void AxisOverlay( AstAxis *, AstAxis * );
static void ClearAttrib( AstObject *, const char * );
static void ClearAxisAsTime( AstSkyAxis * );
static void ClearAxisFormat( AstAxis * );
static void ClearAxisIsLatitude( AstSkyAxis * );
static void Copy( const AstObject *, AstObject * );
static void Delete( AstObject * );
static void Dump( AstObject *, AstChannel * );
static void InitVtab( AstSkyAxisVtab * );
static void ParseDHmsFormat( const char *, char *, int *, int *, int *, int *, int *, int *, int * );
static void SetAttrib( AstObject *, const char * );
static void SetAxisAsTime( AstSkyAxis *, int );
static void SetAxisFormat( AstAxis *, const char * );
static void SetAxisIsLatitude( AstSkyAxis *, int );

/* Member functions. */
/* ================= */
static const char *AxisAbbrev( AstAxis *this_axis,
                               const char *str1, const char *str2 ) {
/*
*  Name:
*     astAxisAbbrev

*  Purpose:
*     Abbreviate a formatted SkyAxis value by skipping leading fields.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *AxisAbbrev( AstAxis *this,
*                             const char *str1, const char *str2 )

*  Class Membership:
*     SkyAxis member function (over-rides the protected astAxisAbbrev
*     method inherited from the Axis class).

*  Description:
*     This function compares two SkyAxis values that have been
*     formatted (using astAxisFormat) and determines if they have any
*     redundant leading fields (i.e. leading fields in common which
*     can be suppressed when tabulating the values or plotting them on
*     the axis of a graph).

*  Parameters:
*     this
*        Pointer to the SkyAxis.
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
*     the same when both values were formatted.
*     - A pointer to the start of "str2" will be returned if this
*     function is invoked with the global error status set, or if it
*     should fail for any reason.
*/

/* Local Variables: */
   const char *result;           /* Result pointer to return */
   int delim1;                   /* First character is a delimiter? */
   int delim2;                   /* Second character is a delimiter? */
   int i;                        /* Loop counter for string characters */
   int same;                     /* Same characters? */

/* Initialise. */
   result = str2;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Loop to inspect corresponding characters from each string. */
   for ( i = 0; ; i++ ) {

/* Determine if the two characters are the same and whether each is a
   delimiter character. */
      same = ( str1[ i ] == str2[ i ] );
      delim1 = !strchr( "+-0123456789.", str1[ i ] );
      delim2 = !strchr( "+-0123456789.", str2[ i ] );

/* Test to see if the end of a field has been reached. This will be
   the case if both strings contain the same delimiter character at
   this point, or if either string terminates at this point while the
   other one contains a delimiter, or if both strings terminate at
   this point. */
      if ( ( delim1 && same ) ||
           ( !str1[ i ] && delim2 ) || ( !str2[ i ] && delim1 ) ||
           ( !str1[ i ] && !str2[ i ] ) ) {

/* Once the end of a field has been found, advance the result pointer
   to the delimiter at its end in "str2". */
         result = str2 + i;

/* If the delimiter is not the end of the string, move on to the start
   of the next field. */
         if ( *result ) result++;

/* If we have not found a delimiter in both strings, then check that
   the two characters are the same. If not, we have a differing field,
   so quit looping. */
      } else if ( !same ) {
         break;
      }

/* Quit looping once the end if either string is reached. */
      if ( !str1[ i ] || !str2[ i ] ) break;
   }

/* Return the result. */
   return result;
}

static double AxisDistance( AstAxis *this_axis, double v1, double v2 ) {
/*
*  Name:
*     astAxisDistance

*  Purpose:
*     Find the distance between two axis values.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     AxisDistance( AstAxis *this, double v1, double v2 )

*  Class Membership:
*     SkyAxis member function (over-rides the protected astAxisDistance
*     method inherited from the Axis class).

*  Description:
*     This function returns a signed value representing the axis increment 
*     from axis value v1 to axis value v2.
*
*     For a SkyAxis, the angular difference between the two supplied axis 
*     values is normalized into the range +PI to -PI.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     v1
*        The first axis value
*     v2
*        The second axis value

*  Returned Value:
*     The axis increment from v1 to v2.

*  Notes:
*     - A value of AST__BAD is returned if either axis value is AST__BAD.
*     - A value of AST__BAD will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   double result;                /* Returned gap size */

/* Initialise. */
   result = AST__BAD;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Check both axis values are OK, and form the returned increment,
   normalizing it into the range +PI to -PI. */
   if( v1 != AST__BAD && v2 != AST__BAD ) result = slaDrange( v2 - v1 );

/* Return the result. */
   return result;

/* Return the result. */
   return result;
}

static const char *AxisFormat( AstAxis *this_axis, double value ) {
/*
*  Name:
*     AxisFormat

*  Purpose:
*     Format a coordinate value for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *AxisFormat( AstAxis *this, double value )

*  Class Membership:
*     SkyAxis member function (over-rides the astAxisFormat method inherited
*     from the Axis class).

*  Description:
*     This function returns a pointer to a string containing the formatted
*     (character) version of a coordinate value for a SkyAxis. The formatting
*     applied is that specified by a previous invocation of the
*     astSetAxisFormat method. A suitable default format is applied if
*     necessary.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     value
*        The coordinate value to be formatted (in radians).

*  Returned Value:
*     A pointer to a null-terminated string containing the formatted value.

*  Notes:
*     -  The returned string pointer may point at memory allocated within
*     the SkyAxis object, or at static memory. The contents of the string may
*     be over-written or the pointer may become invalid following a further
*     invocation of the same function or deletion of the SkyAxis. A copy of the
*     string should therefore be made if necessary.
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   const char *fmt;              /* Pointer to format specifier */
   const char *result;           /* Pointer to result string */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise. */
   result = NULL;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Obtain a pointer to the format specifier to be used. Note we use a private
   member function to obtain this (not a method) in case derived classes have
   extended the syntax of this string. */
   fmt = GetAxisFormat( this_axis );

/* Format the value and obtain a pointer to the result string. */
   if ( astOK ) result = DHmsFormat( fmt, value );

/* Return the result. */
   return result;
}

static double AxisGap( AstAxis *this_axis, double gap, int *ntick ) {
/*
*  Name:
*     AxisGap

*  Purpose:
*     Find a "nice" gap for tabulating SkyAxis values.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     double AxisGap( AstAxis *this, double gap, int *ntick ) 

*  Class Membership:
*     SkyAxis member function (over-rides the protected astAxisGap
*     method inherited from the Axis class).

*  Description:
*     This function returns a gap size in radians which produces a
*     nicely spaced series of formatted SkyAxis values, the returned
*     gap size being as close as possible to the supplied target gap
*     size. It also returns a convenient number of divisions into
*     which the gap can be divided.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     gap
*        The target gap size.
*     ntick
*        Address of an int in which to return a convenient number of
*        divisions into which the gap can be divided.

*  Returned Value:
*     The nice gap size.

*  Notes:
*     - The returned gap size is influenced by the format string
*     specified for the SkyAxis by a previous invocation of the
*     astSetAxisFormat method. A suitable default format is used if
*     necessary.
*     - A value of zero is returned if the supplied gap size is zero.
*     - A negative gap size is returned if the supplied gap size is negative.
*     - A value of zero will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   const char *fmt;              /* Pointer to Format string */
   double result;                /* Returned gap size */

/* Initialise. */
   result = 0.0;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Obtain a pointer to the format string to be used. Note we use a
   private member function to obtain this (not a method) in case
   derived classes have extended the syntax of this string. */
   fmt = GetAxisFormat( this_axis );

/* Obtain the closest "nice" gap size. */
   if ( astOK ) result = DHmsGap( fmt, gap, ntick );

/* Return the result. */
   return result;
}

static void AxisNorm( AstAxis *this_axis, double *value ) {
/*
*  Name:
*     AxisNorm

*  Purpose:
*     Normalise a SkyAxis coordinate value.

*  Type:
*     Public virtual function.

*  Synopsis:
*     #include "skyaxis.h"
*     void AxisNorm( AstAxis *this, double *value )

*  Class Membership:
*     SkyAxis member function (over-rides the astAxisNorm method inherited
*     from the Axis class).

*  Description:
*     This function converts a SkyAxis coordinate value which might
*     potentially be unsuitable for display to a user (for instance,
*     may lie outside the expected range of values) into an acceptable
*     alternative value suitable for display.
*
*     For a SkyAxis that is a longitude axis, values are wrapped into
*     the range zero to 2*pi, while for a latitude axis, they are
*     wrapped into the range -pi to +pi. The astAxisIsLatitude method
*     is used to determine which algorithm to apply.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     value
*        Pointer to the coordinate value to be normalised, which will
*        be modified in place.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   int is_latitude;              /* SkyAxis is a latitude axis? */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* If the coordinate value is bad, then return it
   unchanged. Otherwise, determine if the SkyAxis is a latitude
   axis. */
   if ( *value != AST__BAD ) {
      is_latitude = astGetAxisIsLatitude( this );

/* Wrap the value into the appropriate range. */
      if ( astOK ) *value = is_latitude ? slaDrange( *value ) :
                                          slaDranrm( *value );
   }
}

static double AxisOffset( AstAxis *this_axis, double v1, double dist ) {
/*
*
*  Name:
*     astAxisOffset

*  Purpose:
*     Add an increment onto a supplied axis value.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     AxisOffset( AstSkyAxis *this, double v1, double dist ) 

*  Class Membership:
*     SkyAxis member function (over-rides the protected astAxisOffset
*     method inherited from the Axis class).

*  Description:
*     This function returns an axis value formed by adding a signed axis
*     increment onto a supplied axis value.
*
*     For a SkyFrame, the result is normalized into the correct angular 
*     range (+PI to -PI for latitude axes, and 0 to 2*PI for longitude axes).

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     v1
*        The supplied axis value
*     dist
*        The axis increment

*  Returned Value:
*     The axis value which is the specified increment away from v1.

*  Notes:
*     - A value of AST__BAD is returned if either axis value is AST__BAD.
*     - A value of AST__BAD will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Variables: */
   double result;                /* Returned gap size */

/* Initialise. */
   result = AST__BAD;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Check both axis values are OK, and form the returned axis value. */
   if( v1 != AST__BAD && dist != AST__BAD ) {
      result = v1 + dist;
      AxisNorm( this_axis, &result );
   }

/* Return the result. */
   return result;
}

static void AxisOverlay( AstAxis *template_axis, AstAxis *result ) {
/*
*  Name:
*     AxisOverlay

*  Purpose:
*     Overlay the attributes of a template SkyAxis on to another Axis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     void AxisOverlay( AstAxis *template, AstAxis *result )

*  Class Membership:
*     SkyAxis member function (over-rides the astAxisOverlay method inherited
*     from the Axis class).

*  Description:
*     This function overlays attributes of a SkyAxis (the "template") on to
*     another Axis, so as to over-ride selected attributes of that second
*     Axis. Normally only those attributes which have been specifically set
*     in the template will be transferred. This implements a form of
*     defaulting, in which an Axis acquires attributes from the template, but
*     retains its original attributes (as the default) if new values have not
*     previously been explicitly set in the template.

*  Parameters:
*     template
*        Pointer to the template SkyAxis, for which values should have been
*        explicitly set for any attribute which is to be transferred.
*     result
*        Pointer to the Axis which is to receive the new attribute values.

*  Returned Value:
*     void
*/

/* Local Variables: */
   AstSkyAxis *template;         /* Pointer to the SkyAxis structure */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the template SkyAxis structure. */
   template = (AstSkyAxis *) template_axis;

/* Invoke the parent astAstOverlay method to overlay inherited attributes. */
   (*parent_axisoverlay)( template_axis, result );

/* Test if the "result" Axis is a SkyAxis (if not, it cannot acquire any
   further attributes, so there is nothing more to do). */
   if ( astIsASkyAxis( result ) && astOK ) {

/* Overlay the Format attribute if it is set in the template. Note that we
   use private member functions (not methods) to access the Format value, since
   derived classes may extend the syntax of this string and we should not
   overlay a string whose syntax cannot be interpreted by the result Axis. */
      if ( TestAxisFormat( template_axis ) ) {
         SetAxisFormat( result, GetAxisFormat( template_axis ) );
      }

/* Overlay the AsTime attribute in the same way, but this time using methods
   to access it. */
      if ( astTestAxisAsTime( template ) ) {
         astSetAxisAsTime( result, astGetAxisAsTime( template ) );
      }

/* Also overlay the IsLatitude attribute. */
      if ( astTestAxisIsLatitude( template ) ) {
         astSetAxisIsLatitude( result, astGetAxisIsLatitude( template ) );
      }
   }
}

static void ClearAttrib( AstObject *this_object, const char *attrib ) {
/*
*  Name:
*     ClearAttrib

*  Purpose:
*     Clear an attribute value for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     void ClearAttrib( AstObject *this, const char *attrib )

*  Class Membership:
*     SkyAxis member function (over-rides the astClearAttrib protected
*     method inherited from the Axis class).

*  Description:
*     This function clears the value of a specified attribute for a
*     SkyAxis, so that the default value will subsequently be used.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     attrib
*        Pointer to a null-terminated string specifying the attribute
*        name.  This should be in lower case with no surrounding white
*        space.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_object;

/* Check the attribute name and clear the appropriate attribute. */

/* AsTime. */
/* ------- */
   if ( !strcmp( attrib, "astime" ) ) {
      astClearAxisAsTime( this );

/* IsLatitude. */
/* ----------- */
   } else if ( !strcmp( attrib, "islatitude" ) ) {
      astClearAxisIsLatitude( this );

/* If the attribute is still not recognised, pass it on to the parent
   method for further interpretation. */
   } else {
      (*parent_clearattrib)( this_object, attrib );
   }
}

static void ClearAxisFormat( AstAxis *this_axis ) {
/*
*  Name:
*     ClearAxisFormat

*  Purpose:
*     Clear the Format attribute for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     void ClearAxisFormat( AstAxis *this )

*  Class Membership:
*     SkyAxis member function (over-rides the astClearAxisFormat method
*     inherited from the Axis class).

*  Description:
*     This function clears the Format attribute of a SkyAxis, as if no value
*     had ever been set for it.

*  Parameters:
*     this
*        Pointer to the SkyAxis.

*  Returned Value:
*     void
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Free any memory allocated to hold the Format string and reset the string
   pointer to NULL. */
   this->skyformat = astFree( this->skyformat );
}

static const char *DHmsFormat( const char *fmt, double value ) {
/*
*  Name:
*     DHmsFormat

*  Purpose:
*     Format a value representing degrees/hours, minutes and seconds.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *DHmsFormat( const char *fmt, double value )

*  Class Membership:
*     SkyAxis member function.

*  Description:
*     This function formats a value representing an angle in radians
*     into a text string giving degrees/hours, minutes and seconds
*     according to a format specifier supplied. See the "Format
*     Specifier" section for details of the formats available.

*  Parameters:
*     fmt
*        Pointer to a null terminated string containing the format
*        specifier.
*     double
*        The value to be formatted (in radians).

*  Returned Value:
*     Pointer to a null terminated character string containing the
*     formatted value.

*  Format Specifier:
*     The format specifier supplied via the "fmt" parameter should
*     contain zero or more of the following characters to specify the
*     format required.  These characters may occur in any order, but
*     the following is recommended for clarity:
*
*     '+'
*        Indicates that a plus sign should be prefixed to positive
*        values. By default, no plus sign is used.
*     'z'
*        Indicates that leading zeros should be prefixed to the value
*        so that the first field is always of constant width, as would
*        be required in a fixed-width table. (Leading zeros are always
*        prefixed to any fields that follow.) By default, no leading
*        zeros are added.
*     'i'
*        Use the standard ISO field separator (a colon) between
*        fields. This is the default behaviour.
*     'b'
*        Use a blank to separate fields.
*     'l'
*        Use a letter ('d'/'h', 'm' or 's' as appropriate) to separate
*        and identify fields.
*     'd'
*        Express the value as an angle and include a degrees
*        field. Expressing the value as an angle is also the default
*        behaviour if neither 'h' nor 't' is given, and expressing it
*        in degrees is the default if neither 'm' nor 's' is given.
*     'h'
*        Express the value as a time instead of an angle (where 24
*        hours correspond to 360 degrees) and include an hours
*        field. Expressing times in hours is the default if 't' is
*        given without either 'm' or 's'.
*     'm'
*        Include a minutes field. By default this is not included.
*     's'
*        Include a seconds field. By default this is not
*        included. This request is ignored if 'd' or 'h' is given,
*        unless a minutes field is also included.
*     't'
*        Express the value as a time instead of an angle (where 24
*        hours correspond to 360 degrees). This option is ignored if
*        either 'd' or 'h' is given and is intended for use in cases
*        where the value is to be expressed purely in minutes and/or
*        seconds of time (no hours field). If 't' is given without
*        'd', 'h', 'm' or 's' being present, then it is equivalent to
*        'h'.
*     '.'
*        Indicates that decimal places are to be given for the final
*        field in the formatted string (whichever field this is). The
*        '.' should be followed immediately by a positive integer
*        which gives the number of decimal places required. By
*        default, no decimal places are given.
*
*     Format specifiers are not case sensitive. If several characters
*     make conflicting requests (e.g. if both 'i' and 'l' appear in a
*     format specifier), then the character occurring last takes
*     precedence, except that 'd' and 'h' always override 't'.

*  Notes:
*     - The result string may be stored in static memory. Its contents
*     may be over-written or the returned pointer may become invalid
*     following a further invocation of this function. A copy of the
*     string should therefore be made if necessary.
*     - A NULL pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.

*  Acknowledgements:
*     - This function is a close approximation to a Fortran 77 routine
*     written by Clive Davenhall which implements the system of format
*     specifiers for angles described in his document on the CAT
*     catalogue access library (Starlink User Note 181). Some minor
*     improvements have been made to ensure better behaviour when
*     results are rounded to a specified number of decimal places.
*/

/* Local Constants: */
#define BUFF_LEN 70              /* Max. characters in result string */

/* Local Variables: */
   char sep;                     /* Field separator character */
   const char *result;           /* Pointer to result string */
   double absvalue;              /* Absolute value in radians */
   double fract;                 /* Fractional part of final field */
   double idh;                   /* Integer number of degrees/hours */
   double ifract;                /* Fractional part expressed as an integer */
   double imin;                  /* Integer number of minutes */
   double isec;                  /* Integer number of seconds */
   double shift;                 /* Factor for rounding fractional part */
   double test;                  /* Test value to determine rounding */
   int as_time;                  /* Format the value as a time? */
   int dh;                       /* Degrees/hours field required? */
   int lead_zero;                /* Add leading zeros? */
   int min;                      /* Minutes field required? */
   int ndp;                      /* Number of decimal places */
   int plus;                     /* Add leading plus sign? */
   int pos;                      /* Position to add next character */
   int positive;                 /* Value is positive (or zero)? */
   int sec;                      /* Seconds field required? */
   int stat;                     /* SLALIB status */
   static char buff[ BUFF_LEN + 1 ]; /* Buffer for result string */
   static double deg2rad;        /* Degrees to radians conversion factor */
   static double hr2rad;         /* Hours to radians conversion factor */
   static int init = 0;          /* Conversion factors initialised? */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise. */
   result = NULL;

/* Check if a bad coordinate value has been given and return an
   appropriate string. */
   if ( value == AST__BAD ) {
      result = "<bad>";

/* Otherwise, if not done previously, use SLALIB to obtain conversion
   factors between hours/degrees and radians. Do this only once. */
   } else {
      if ( !init ) {
         slaDtf2r( 1, 0, 0.0, &hr2rad, &stat );
         slaDaf2r( 1, 0, 0.0, &deg2rad, &stat );
         init = 1;
      }

/* Parse the format specifier. */
      ParseDHmsFormat( fmt, &sep, &plus, &lead_zero, &as_time, &dh, &min, &sec,
                       &ndp );

/* Break the value into fields. */
/* ---------------------------- */
/* Restrict the number of decimal places requested, if necessary, so
   that under the worst case the buffer for the result string is not
   likely to overflow. */
      if ( astOK ) {
         if ( ( ndp + 11 ) > BUFF_LEN ) ndp = BUFF_LEN - 11;

/* Some operating systems have a "minus zero" value (for instance 
   "-1.2*0" would give "-0"). This value is numerically equivalent to
   zero, but is formated as "-0" instead of "0". The leading minus sign
   confuses the following code, and so ensure now that all zero values
   are the usual  "+0". */
         if ( value == 0.0 ) value = 0.0;

/* Determine if the value to be formatted is positive and obtain its
   absolute value in radians. */
         positive = ( value >= 0.0 );
         absvalue = positive ? value : -value;

/* Convert this to an absolute number of degrees or hours, as
   required. */
         fract = absvalue / ( as_time ? hr2rad : deg2rad );

/* If a degrees/hours field is required, extract the whole number of
   degrees/hours and the remaining fractional part of a
   degree/hour. */
         idh = 0.0;
         if ( dh ) fract = modf( fract, &idh );

/* If a minutes field is required, convert the value remaining to
   minutes and extract the whole number of minutes and the remaining
   fractional part of a minute. */
         imin = 0.0;
         if ( min ) fract = modf( fract * 60.0, &imin );

/* If a seconds field is required, convert the value remaining to
   seconds (allowing for the absence of a minutes field if necessary)
   and extract the whole number of seconds and the remaining
   fractional part of a second. */
         isec = 0.0;
         if ( sec ) {
            if ( !min ) fract *= 60.0;
            fract = modf( fract * 60.0, &isec );
         }

/* Round to the required number of decimal places. */
/* ----------------------------------------------- */
/* We must now round the fractional part (of whichever field) to the
   required number of decimal places. Calculate the power of 10 that
   brings the least significant digit into the units column. Scale the
   fractional part by this factor and truncate to an integer (but
   stored as a double to prevent possible integer overflow if the
   number of decimal places is excessive). */
         shift = pow( 10.0, (double) ndp );
         ifract = floor( fract * shift );

/* Next we must determine if truncation was adequate, or whether we
   should round upwards instead. This process is more subtle than it
   seems because if a value with a 5 as the final digit is converted
   to radians and then back again, it may no longer end in 5 (because
   it cannot be represented exactly in radians) and so may round
   either up or down. If we want to recover the original (textual)
   value, we must compare the value we are formatting not with a test
   value whose last digit is 5, but with the closest number to this
   that can be represented exactly in radians.

   To do this, we add 0.5 to our truncated value, divide by the scale
   factor (to get the truncated fractional part, but now with a
   trailing digit 5 appended) and then combine this fractional part
   with the value of all the other fields. Finally, we convert this
   test value back into radians. */
         test = ( 0.5 + ifract ) / shift;
         if ( sec ) test = ( isec + test ) / 60.0;
         if ( min ) {
            test = ( imin + test ) / 60.0;
         } else if ( sec ) {
            test /= 60.0;
         }
         if ( dh ) test += idh;
         test *= ( as_time ? hr2rad : deg2rad );

/* We now compare the absolute value we are formatting with this test
   value.  If it is not smaller than it, we should have rounded up
   instead of truncating the final digit of the fractional part, so
   increment the integer representation of the truncated fractional
   part by 1.0 to compensate. */
         if ( absvalue >= test ) ifract += 1.0;

/* Divide by the scale factor to obtain the correctly rounded
   fractional part.  Then check if this fractional part is 1.0. If so,
   rounding has caused it to overflow into the units column of the
   final field, so clear the fractional part. */
         fract = ( ifract / shift );
         if ( fract >= 1.0 ) {
            ifract = 0.0;

/* If a seconds field is present, propagate the overflow up through
   each field in turn, but omitting fields which are not required. Be
   careful about possible rounding errors when comparing integer
   values stored as double. */
            if ( sec ) {
               isec += 1.0;
               if ( ( floor( isec + 0.5 ) > 59.5 ) && min ) {
                  isec = 0.0;
                  imin += 1.0;
                  if ( ( floor( imin + 0.5 ) > 59.5 ) && dh ) {
                     imin = 0.0;
                     idh += 1.0;
                  }
               }

/* Omit the seconds field if it is not present. */
            } else if ( min ) {
               imin += 1.0;
               if ( ( floor( imin + 0.5 ) > 59.5 ) && dh ) {
                  imin = 0.0;
                  idh += 1.0;
               }

/* If only the degree/hour field is present, simply increment it. */
            } else {
               idh += 1.0;
            }
         }

/* Construct the result string. */
/* ---------------------------- */
/* We now have the value of each field and the information about how
   they are to be formatted, so we can combine them into the required
   string. */

/* If each field is either not required or equal to zero, disregard
   any sign. */
         if ( !positive && ( !dh || floor( idh + 0.5 ) < 0.5 ) &&
                           ( !min || floor( imin + 0.5 ) < 0.5 ) &&
                           ( !sec || floor( isec + 0.5 ) < 0.5 ) &&
                           ( floor( ifract + 0.5 ) < 0.5 ) ) {
            positive = 1;
         }

/* Use "pos" to identify where the next character should be
   added. Insert a leading '+' or '-' sign if required. */
         pos = 0;
         if ( !positive ) {
            buff[ pos++ ] = '-';
         } else if ( plus ) {
            buff[ pos++ ] = '+';
         }

/* Use "sprintf" to format the degrees/hours field, if required. Set
   the minimum field width according to whether padding with leading
   zeros is required and whether the value represents hours (2 digits)
   or degrees (3 digits). */
         if ( dh ) {
            pos += sprintf( buff + pos, "%0*.0f",
                            lead_zero ? ( as_time ? 2 : 3 ) : 1, idh );

/* If letters are being used as field separators, and there are more
   fields to follow, append "d" or "h" as necessary. */
            if ( ( sep == 'l' ) && ( min || sec ) ) {
               buff[ pos++ ] = ( as_time ? 'h' : 'd' );
            }
         }

/* If a minutes field is required, first add an appropriate non-letter
   field separator if needed. */
         if ( min ) {
            if ( ( sep != 'l' ) && dh ) buff[ pos++ ] = sep;

/* Then format the minutes field with a leading zero to make it two
   digits if necessary. */
            pos += sprintf( buff + pos, "%0*.0f", ( dh || lead_zero ) ? 2 : 1,
                            imin );

/* If letters are being used as field separators, and there is another
   field to follow, append "m". */
            if ( ( sep == 'l' ) && sec ) buff[ pos++ ] = 'm';
         }

/* Similarly, if a seconds field is required, first add an appropriate
   non-letter field separator if needed. */
         if ( sec ) {
            if ( ( sep != 'l' ) && ( dh || min ) ) buff[ pos++ ] = sep;

/* Then format the seconds field with a leading zero to make it two
   digits if necessary. */
            pos += sprintf( buff + pos, "%0*.0f",
                            ( dh || min || lead_zero ) ? 2 : 1, isec );
         }

/* If decimal places are needed, add a decimal point followed by the
   integer representation of the correctly rounded fractional part,
   padded with leading zeros if necessary. */
         if ( ndp > 0 ) {
            buff[ pos++ ] = '.';
            pos += sprintf( buff + pos, "%0*.0f", ndp, ifract );
         }

/* If letters are being used as separators, append the appropriate one
   to the final field. */
         if ( sep == 'l' ) {
            buff[ pos++ ] = ( sec ? 's' : ( min ? 'm' :
                                                  ( as_time ? 'h' : 'd' ) ) );
         }

/* Terminate the result string and return a pointer to it. */
         buff[ pos ] = '\0';
         result = buff;
      }
   }

/* Return the result. */
   return result;

/* Undefine macros local to this function. */
#undef BUFF_LEN
}

static double DHmsGap( const char *fmt, double gap, int *ntick ) {
/*
*  Name:
*     DHmsGap

*  Purpose:
*     Find a "nice" gap for formatted SkyAxis values.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     double DHmsGap( const char *fmt, double gap, int *ntick )

*  Class Membership:
*     SkyAxis member function.

*  Description:
*     This function returns a gap size in radians which produces a
*     nicely spaced series of formatted SkyAxis values, the returned
*     gap size being as close as possible to the supplied target gap
*     size. It also returns a convenient number of divisions into
*     which the gap can be divided.

*  Parameters:
*     fmt
*        Pointer to a constant null-terminated string containing the
*        format specifier which will be used to format the SkyAxis
*        values.
*     double
*        The target gap size.
*     ntick
*        Address of an int in which to return a convenient number of
*        divisions into which the gap can be divided.

*  Returned Value:
*     The nice gap size.

*  Notes:
*     - A value of zero is returned if the target gap size is zero.
*     - A negative gap size is returned if the supplied gap size is
*     negative.
*     - A value of zero will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Constants: */
#define BUFF_LEN 50              /* Length of character buffer */

/* Local Variables: */
   char buff[ BUFF_LEN + 1 ];    /* Buffer for formatted scaled "nice" value */
   char sep;                     /* Field separator character */
   const double *table;          /* Pointer to nice gap table */
   const int *nticks;            /* Pointer to number of subdivisions table */
   double field_value[ 3 ];      /* Formatted field values in radians */
   double scale;                 /* Power of ten scaling factor */
   double scaled_table_value;    /* Scaled "nice" value to test against */
   int as_time;                  /* Format the value as a time? */
   int decimal;                  /* Use nice decimal gap value? */
   int dh;                       /* Degrees/hours field required? */
   int field;                    /* ID of most significant formatted field */
   int i;                        /* Look-up-table index */
   int iter;                     /* Iteration count */
   int lead_zero;                /* Add leading zeros? */
   int min;                      /* Minutes field required? */
   int ndp;                      /* Number of decimal places */
   int plus;                     /* Add leading plus sign? */
   int positive;                 /* Value is positive (or zero)? */
   int sec;                      /* Seconds field required? */
   int stat;                     /* SLALIB status */
   static double deg2rad;        /* Degrees to radians conversion factor */
   static double hr2rad;         /* Hours to radians conversion factor */
   static int init = 0;          /* Conversion factors initialised? */

/* Local Data: */
/* ----------- */
/* Table of nice decimal gaps. */
   const double dec_table[] = { 1.0, 2.0, 4.0, 5.0, 10.0, -1.0 };
   const int dec_nticks[] =   { 5,   4,   4,   5,   5 };

/* Table of nice degrees gaps. */
   const double deg_table[] =
      { 1.0, 2.0, 5.0, 10.0, 30.0, 45.0, 60.0, 90.0, 180.0, 360.0, -1.0 };
   const int deg_nticks[] =
      { 4,   4,   5,   5,    6,    3,    6,    3,    3,     4 };

/* Table of nice hours gaps. */
   const double hr_table[] = { 1.0, 2.0, 3.0, 6.0, 12.0, 24.0, -1.0 };
   const int hr_nticks[] =   { 4,   4,   6,   6,   4,    4 };

/* Table of nice minutes or seconds gaps. */
   const double minsec_table[] = { 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, -1.0 };
   const int minsec_nticks[] =   { 4,   4,   5,   5,    6,    4 };

/* Check the global error status. */
   if ( !astOK ) return 0.0;

/* Check that the supplied gap size is not zero. */
   if ( gap != 0.0 ) {
   
/* If not done previously, use SLALIB to obtain conversion factors
   between hours/degrees and radians. Do this only once. */
      if ( !init ) {
         slaDtf2r( 1, 0, 0.0, &hr2rad, &stat );
         slaDaf2r( 1, 0, 0.0, &deg2rad, &stat );
         init = 1;
      }

/* Parse the format specifier. */
      ParseDHmsFormat( fmt, &sep, &plus, &lead_zero, &as_time, &dh, &min, &sec,
                       &ndp );

/* If OK, calculate the value of each formatted field in radians. */
      if ( astOK ) {
         field_value[ 0 ] = ( as_time ? hr2rad : deg2rad );
         field_value[ 1 ] = field_value[ 0 ] / 60.0;
         field_value[ 2 ] = field_value[ 0 ] / 3600.0;

/* Determine if the suggested gap size is positive and obtain its
   absolute value. */
         positive = ( gap >= 0.0 );
         if ( !positive ) gap = -gap;

/* Perform two iterations to determine the optimum gap value. This is
   because the method of choosing the gap value depends on the initial
   value.  If a nice decimal gap is chosen on the first iteration,
   this may round the suggested gap value downwards, making it
   preferable to choose the gap value using a different method on the
   second iteration. */
         for ( iter = 0; iter < 2; iter++ ) {

/* Decide which is the most significant field that the suggested gap
   value will occupy when formatted. Also decide whether to use a
   special "nice" gap value specific to that field, or simply to use a
   generic nice decimal gap value. Perform all tests on the gap size
   in radians, so as to avoid any rounding problems from conversion
   into degrees/hours, minutes or seconds. */
            decimal = 0;

/* Suggested values exceeding one degree/hour. */
/* ------------------------------------------- */
            if ( gap > field_value[ 0 ] ) {

/* If a degree/hour field is present, use a special gap value, unless
   the suggested value exceeds the normal range of this field (in
   which case use a decimal gap). */
               if ( dh ) {
                  field = 1;
                  decimal = ( gap > ( field_value[ 0 ] *
                                      ( as_time ? 24.0 : 360.0 ) ) );

/* If the most significant field is not degrees/hours, then its normal
   range will be exceeded, so use a decimal gap. */
               } else if ( min ) {
                  field = 2;
                  decimal = 1;
               } else {
                  field = 3;
                  decimal = 1;
               }

/* Suggested values exceeding one minute. */
/* -------------------------------------- */
            } else if ( gap > field_value[ 1 ] ) {

/* If a minutes field is present, the suggested value will lie within
   its normal range, so use a special gap value. */
               if ( min ) {
                  field = 2;

/* Otherwise, if the most significant field is seconds, its normal
   range will be exceeded, so use a decimal gap value. */
               } else if ( sec ) {
                  field = 3;
                  decimal = 1;

/* If only a degrees/hours field is present, then only digits after
   the decimal point can be affected, so use a decimal gap value. */
               } else {
                  field = 1;
                  decimal = 1;
               }

/* Suggested values exceeding one second. */
/* -------------------------------------- */
            } else if ( gap > field_value[ 2 ] ) {

/* If a seconds field is present, the suggested value will lie within
   its normal range, so use a special gap value. */
               if ( sec ) {
                  field = 3;

/* If the least significant field is degrees/hours or minutes, then
   only digits after the decimal point can be affected, so use a
   decimal gap value. */
               } else if ( min ) {
                  field = 2;
                  decimal = 1;
               } else {
                  field = 1;
                  decimal = 1;
               }

/* Suggested values less than one second. */
/* -------------------------------------- */
            } else {

/* Only digits after the decimal point can be affected, so decide
   which is the least significant field present and use a decimal
   gap. */
               if ( sec ) {
                  field = 3;
               } else if ( min ) {
                  field = 2;
               } else {
                  field = 1;
               }
               decimal = 1;
            }

/* If a decimal gap value is required, select the appropriate table of
   gap values and numbers of subdivisions. */
            if ( decimal ) {
               table = dec_table;
               nticks = dec_nticks;

/* Find a power of ten divisor which scales the suggested value (when
   formatted) into the range 1.0 to 10.0. */
               scale = pow( 10.0,
                            floor( log10( gap / field_value[ field - 1 ] ) ) );

/* Look the scaled value up in the table, comparing values in radians
   to avoid rounding problems due to conversion to/from
   degrees/radians, etc. */
               for ( i = 0; table[ i + 1 ] > 0.0; i++ ) {

/* We must be careful about rounding errors here. If, for example, we
   read in a value of 0.15 as the suggested gap value, the scaled
   "nice" value we would be comparing it with would be 0.1 times the
   values in the nice values table. The relevant value in this table
   is 1.5 (i.e. 0.5 * ( 1.0 + 2.0 ) ), so we would compute 0.1 * 1.5
   as the test value. However, this is probably not equal (to machine
   precision) to the number that results when a formatted value of
   0.15 is read, because 0.1 isn't exactly representable. Since it is
   the formatted appearance of the numbers which matters, we want a
   new scaled nice table containing the numbers that result from
   reading the formatted values 0.1, 0.2, etc. To achieve this effect,
   we format the scaled table value using the default floating point
   precision (which rounds to a relatively small number of decimal
   digits) and then read the value back again. */
                  (void ) sprintf( buff, "%g", scale *
                                   0.5 * ( table[ i ] + table[ i + 1 ] ) );
                  (void) sscanf( buff, "%lf", &scaled_table_value );

/* Now test the suggested gap value against the scaled table value. */
                  if ( gap < ( field_value[ field - 1 ] *
                               scaled_table_value ) ) break;
               }

/* Return the nice gap value and the number of subdivisions. */
               gap = scale * field_value[ field - 1 ] * table[ i ];
               if ( ntick ) *ntick = nticks[ i ];

/* If a special gap value appropriate to the field is required, then
   select the table of gap values and numbers of subdivisions
   according to which field we are considering and whether it contains
   degrees or hours. */
            } else {
               if ( field == 1 ) {
                  if ( as_time ) {
                     table = hr_table;
                     nticks = hr_nticks;
                  } else {
                     table = deg_table;
                     nticks = deg_nticks;
                  }
               } else {
                  table = minsec_table;
                  nticks = minsec_nticks;
               }

/* Search the table for a suitable gap. We do not need to format and
   unformat the test value here (as we did above) because the table
   values are being used literally and not being scaled. */
               for ( i = 0; table[ i + 1 ] > 0.0; i++ ) {
                  if ( gap < ( field_value[ field - 1 ] *
                               0.5 * ( table[ i ] + table[ i + 1 ] ) ) ) break;
               }

/* Return the nice gap value and the number of subdivisions. */
               gap = field_value[ field - 1 ] * table[ i ];
               if ( ntick ) *ntick = nticks[ i ];
            }
         }

/* After iterations are complete, restore the original sign. */
         if ( !positive ) gap = -gap;
      }
   }
   
/* If an error occurred, clear the returned value. */
   if ( !astOK ) gap = 0.0;

/* Return the result. */
   return gap;

/* Undefine macros local to this function */
#undef BUFF_LEN
}

static const char *DHmsUnit( const char *fmt, int output ) {
/*
*  Name:
*     DHmsUnit

*  Purpose:
*     Generate a unit string to describe a formatted angle or time.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *DHmsUnit( const char *fmt, int output )

*  Class Membership:
*     SkyAxis member function.

*  Description:
*     This function generates a string that may be used to describe
*     either (a) the units of an angle or time that has been formatted
*     for output using the DHmsFormat function, or (b) a suitable
*     format to be used for an angle or time that is to be supplied as
*     an input coordinate value.

*  Parameters:
*     fmt
*        Pointer to a null terminated string containing the format
*        specifier used to format coordinate values. For details of
*        the syntax of this string, see the DHmsFormat function.
*     output
*        If non-zero, the returned string will be in a form suitable
*        for describing the units/format of output produced using
*        DHmsFormat.
*
*        If zero, the returned string will be in a form suitable for
*        describing a suggested input format, which will subsequently
*        be read using AxisUnformat.

*  Returned Value:
*     Pointer to a null terminated string containing the unit description.

*  Notes:
*     - The result string may be stored in static memory. Its contents
*     may be over-written or the returned pointer may become invalid
*     following a further invocation of this function. A copy of the
*     string should therefore be made if necessary.
*     - A NULL pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Constants: */
#define BUFF_LEN 17              /* Max. characters in result string */

/* Local Variables: */
   char dpchar;                  /* Character to indicate decimal places */
   char sep;                     /* Field separator character */
   const char *result;           /* Pointer to result string */
   const int maxdp = 6;          /* Maximum number of decimal places to show */
   int as_time;                  /* Value formatted as a time? */
   int dh;                       /* Degrees/hours field required? */
   int dp;                       /* Loop counter for decimal places */
   int lead_zero;                /* Add leading zeros? */
   int min;                      /* Minutes field required? */
   int ndp;                      /* Number of decimal places */
   int plus;                     /* Leading plus sign required? */
   int pos;                      /* Position to add next character */
   int sec;                      /* Seconds field required? */
   static char buff[ BUFF_LEN + 1 ]; /* Buffer for result string */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Parse the format specifier. */
   ParseDHmsFormat( fmt, &sep, &plus, &lead_zero, &as_time, &dh, &min, &sec,
                    &ndp );

/* If the units string is required to describe formatted output and
   the field separators are letters (e.g. giving "01h23m45s" or
   "012d34m56s"), then the units will already be clear so return a
   pointer to an empty units string. */
   if ( astOK ) {
      if ( output && sep == 'l' ) {
         result = "";

/* Otherwise, if the units string is required to describe formatted
   output and there is only one field present, then select an
   appropriate string. */
      } else if ( output && dh && !min && !sec ) {
         result = as_time ? "hours" : "degrees";

      } else if ( output && !dh && min && !sec ) {
         result = as_time ? "minutes of time" : "arcminutes";

      } else if ( output && !dh && !min && sec ) {
         result = as_time ? "seconds of time" : "arcseconds";

/* If there is more than one field present, or we want to describe how
   to supply formatted input, then we will generate a units string of
   the general form "ddd:mm:ss.sss" or "hh:mm:ss.s" or
   similar. Initialise the output character count and the character to
   be used to represent decimal places. */
      } else {
         pos = 0;
         dpchar = 'd';

/* Decide which field separator to use (use a space if letters were
   requested since it is easier to input). */
         if ( sep == 'l' ) sep = ' ';

/* Start with the "ddd" or "hh" field, if required, and update the
   decimal places character appropriately. */
         if ( dh ) {
            pos += sprintf( buff, "%s", as_time ? "hh" : "ddd" );
            dpchar = as_time ? 'h' : 'd';
         }

/* If a minutes field is present, add a separator if necessary and
   "mm" and update the decimal places character. */
         if ( min ) {
            if ( dh ) buff[ pos++ ] = sep;
            buff[ pos++ ] = 'm';
            buff[ pos++ ] = 'm';
            dpchar = 'm';
         }

/* Repeat this process for the seconds field, if present. */
         if ( sec ) {
            if ( dh || min ) buff[ pos++ ] = sep;
            buff[ pos++ ] = 's';
            buff[ pos++ ] = 's';
            dpchar = 's';
         }

/* If decimal places are present, add a decimal point and then loop to
   add further instances of the decimal places character to represent
   the digits that follow. */
         if ( ndp > 0 ) {
            buff[ pos++ ] = '.';
            for ( dp = 0; dp < ndp; dp++ ) {
               if ( dp < maxdp ) {
                  buff[ pos++ ] = dpchar;

/* After showing the maximum number of decimal places, simply add an
   ellipsis and quit (otherwise the result gets boring to look at). */
               } else {
                  buff[ pos - 1 ] = '.';
                  buff[ pos - 2 ] = '.';
                  buff[ pos - 3 ] = '.';
                  break;
               }
	    }
         }

/* Terminate the result string and return a pointer to it. */
         buff[ pos ] = '\0';
         result = buff;
      }
   }

/* Return the result. */
   return result;

/* Undefine macros local to this function. */
#undef BUFF_LEN
}

static const char *GetAttrib( AstObject *this_object, const char *attrib ) {
/*
*  Name:
*     GetAttrib

*  Purpose:
*     Get the value of a specified attribute for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *GetAttrib( AstObject *this, const char *attrib )

*  Class Membership:
*     SkyAxis member function (over-rides the protected astGetAttrib
*     method inherited from the Axis class).

*  Description:
*     This function returns a pointer to the value of a specified
*     attribute for a SkyAxis, formatted as a character string.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     attrib
*        Pointer to a null-terminated string containing the name of
*        the attribute whose value is required. This name should be in
*        lower case, with all white space removed.

*  Returned Value:
*     - Pointer to a null-terminated string containing the attribute
*     value.

*  Notes:
*     - The returned string pointer may point at memory allocated
*     within the SkyAxis, or at static memory. The contents of the
*     string may be over-written or the pointer may become invalid
*     following a further invocation of the same function or any
*     modification of the SkyAxis. A copy of the string should
*     therefore be made if necessary.
*     - A NULL pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Constants: */
#define BUFF_LEN 50              /* Max. characters in result buffer */

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   const char *result;           /* Pointer value to return */
   int as_time;                  /* AsTime attribute value */
   int is_latitude;              /* IsLatitude attribute value */
   static char buff[ BUFF_LEN + 1 ]; /* Buffer for string result */

/* Initialise. */
   result = NULL;

/* Check the global error status. */   
   if ( !astOK ) return result;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_object;

/* Compare "attrib" with each recognised attribute name in turn,
   obtaining the value of the required attribute. If necessary, write
   the value into "buff" as a null-terminated string in an appropriate
   format.  Set "result" to point at the result string. */

/* AsTime. */
/* ------- */
   if ( !strcmp( attrib, "astime" ) ) {
      as_time = astGetAxisAsTime( this );
      if ( astOK ) {
         (void) sprintf( buff, "%d", as_time );
         result = buff;
      }

/* IsLatitude. */
/* ----------- */
   } else if ( !strcmp( attrib, "islatitude" ) ) {
      is_latitude = astGetAxisIsLatitude( this );
      if ( astOK ) {
         (void) sprintf( buff, "%d", is_latitude );
         result = buff;
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

static int GetAxisDirection( AstAxis *this_axis ) {
/*
*  Name:
*     GetAxisDirection

*  Purpose:
*     Obtain the value of the Direction attribute for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     int GetAxisDirection( AstAxis *this )

*  Class Membership:
*     SkyAxis member function (over-rides the astGetAxisDirection method
*     inherited from the Axis class).

*  Description:
*     This function returns a value for the Direction attribute of a SkyAxis.
*     This attribute indicates in which direction the SkyAxis's values should
*     increase when represented on a graph (1 for the conventional direction,
*     0 for reverse direction).

*  Parameters:
*     this
*        Pointer to the SkyAxis.

*  Returned Value:
*     Zero or one, according to the attribute setting. A suitable default
*     value is supplied if necessary.

*  Notes:
*     -  A value of zero will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Variables. */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   int result;                   /* Result to be returned */

/* Check the global error status. */
   if ( !astOK ) return 0;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Check if a value has been set for the Direction attribute. If so, obtain
   this value. */
   if ( astTestAxisDirection( this ) ) {
      result = (*parent_getaxisdirection)( this_axis );

/* Otherwise, supply a default of 1 unless the SkyAxis values are being
   formatted as times (instead of angles) by default. */
   } else {
      result = !astGetAxisAsTime( this );
   }

/* If an error occurred, clear the result value. */
   if ( !astOK ) result = 0;

/* Return the result. */
   return result;
}

static const char *GetAxisFormat( AstAxis *this_axis ) {
/*
*  Name:
*     GetAxisFormat

*  Purpose:
*     Obtain a pointer to the Format attribute for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *GetAxisFormat( AstAxis *this )

*  Class Membership:
*     SkyAxis member function (over-rides the astGetAxisFormat method inherited
*     from the Axis class).

*  Description:
*     This function returns a pointer to the Format attribute associated with
*     a SkyAxis and provides a suitable default if necessary. This string
*     attribute contains the format specifier that will be interpreted by the
*     astAxisFormat method when formatting a value for the SkyAxis. The default
*     Format may depend on other attribute settings, in particular on the
*     Digits and AsTime attributes.

*  Parameters:
*     this
*        Pointer to the SkyAxis.

*  Returned Value:
*     Pointer to the Format string (null terminated).

*  Notes:
*     -  The pointer returned may point at memory allocated within the SkyAxis
*     object, or at static memory. The contents of the string may be
*     over-written or the pointer may become invalid following a further
*     invocation of the same function, deletion of the SkyAxis, or assignment
*     of a new Format value. A copy of the string should therefore be made if
*     necessary.
*     -  This function will return a NULL pointer if it is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Constants: */
#define BUFF_LEN 50              /* Max. characters in result string */

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   const char *result;           /* Pointer to result string */
   int as_time;                  /* Format SkyAxis values as times? */
   int digits;                   /* Number of digits of precision */
   static char buff[ BUFF_LEN + 1 ]; /* Buffer for result string */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise. */
   result = NULL;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Obtain a pointer to the Format string stored in the SkyAxis structure. Note
   we do not use a method to obtain this, because we want a string with a
   syntax appropriate to this class, and derived classes may have extended the
   syntax. */
   result = this->skyformat;

/* If no Format string has been set, we must generate a default one. Determine
   how many digits of precision are to be used by default and whether the
   SkyAxis values are to be formatted as times (instead of angles). */
   if ( !result ) {
      digits = astGetAxisDigits( this );
      as_time = astGetAxisAsTime( this );
      if ( astOK ) {

/* If formatting values as times, use the number of digits to select an
   appropriate Format string and obtain a pointer to it. */
         if ( as_time ) {
            if ( digits <= 2 ) {
               result = "h";
	    } else if ( digits == 3 ) {
               result = "hm";
	    } else if ( digits == 4 ) {
               result = "hm";
	    } else if ( digits == 5 ) {
               result = "hms";
	    } else if ( digits == 6 ) {
               result = "hms";

/* Construct the Format string in a buffer if necessary. */
            } else {
               (void) sprintf( buff, "hms.%d", digits - 6 );
               result = buff;
   	    }

/* Similarly, select a Format for expressing an angle if necessary. */
         } else {
            if ( digits <= 3 ) {
               result = "d";
   	    } else if ( digits == 4 ) {
               result = "dm";
   	    } else if ( digits == 5 ) {
               result = "dm";
   	    } else if ( digits == 6 ) {
               result = "dms";
   	    } else if ( digits == 7 ) {
               result = "dms";
            } else {
               (void) sprintf( buff, "dms.%d", digits - 7 );
               result = buff;
   	    }
	 }
      }
   }

/* Return the result. */
   return result;   

/* Undefine macros local to this function. */
#undef BUFF_LEN
}

static const char *GetAxisLabel( AstAxis *this_axis ) {
/*
*  Name:
*     GetAxisLabel

*  Purpose:
*     Obtain a pointer to the Label attribute for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *GetAxisLabel( AstAxis *this )

*  Class Membership:
*     SkyAxis member function (over-rides the astGetAxisLabel method inherited
*     from the Axis class).

*  Description:
*     This function returns a pointer to the Label attribute associated with
*     a SkyAxis and provides a suitable default if necessary. This string
*     attribute specifies the label to be attached to the SkyAxis when it is
*     represented in (e.g.) a graph. It is intended purely for interpretation
*     by human readers and not by software.

*  Parameters:
*     this
*        Pointer to the SkyAxis.

*  Returned Value:
*     Pointer to the Label string (null terminated).

*  Notes:
*     -  The pointer returned may point at memory allocated within the SkyAxis
*     object, or at static memory. The contents of the string may be
*     over-written or the pointer may become invalid following a further
*     invocation of the same function, deletion of the SkyAxis, or assignment
*     of a new Label value. A copy of the string should therefore be made if
*     necessary.
*     -  This function will return a NULL pointer if it is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   const char *result;           /* Pointer value to be returned */
   int as_time;                  /* SkyAxis values formatted as times? */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise. */
   result = NULL;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Test if the Label attribute is set. If so, use the parent astGetAxisLabel
   method to get a pointer to it. */
   if ( astTestAxisLabel( this ) ) {
      result = (*parent_getaxislabel)( this_axis );

/* Otherwise, return a pointer to a suitable default string, using the result
   of the astGetAxisAsTime method to determine whether a string describing
   time or angle is more appropriate. */
   } else {
      as_time = astGetAxisAsTime( this );
      if ( !astTestAxisIsLatitude( this ) ) {
         result = as_time ? "Angle on sky expressed as time" :
                            "Angle on sky";
      } else if ( astGetAxisIsLatitude( this ) ) {
         result = as_time ? "Sky latitude expressed as time" :
                            "Sky latitude";
      } else {
         result = as_time ? "Sky longitude expressed as time" :
                            "Sky longitude";
      }
   }

/* If an error occurred, clear the result pointer. */
   if ( !astOK ) result = NULL;

/* Return the result. */
   return result;
}

static const char *GetAxisSymbol( AstAxis *this_axis ) {
/*
*  Name:
*     GetAxisSymbol

*  Purpose:
*     Obtain a pointer to the Symbol attribute for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *GetAxisSymbol( AstAxis *this )

*  Class Membership:
*     SkyAxis member function (over-rides the astGetAxisSymbol method inherited
*     from the Axis class).

*  Description:
*     This function returns a pointer to the Symbol attribute associated with
*     a SkyAxis and provides a suitable default if necessary. This string
*     attribute specifies the symbol to be used to represent coordinate values
*     for the SkyAxis in "short form", such as in algebraic expressions where a
*     full description would be inappropriate.

*  Parameters:
*     this
*        Pointer to the SkyAxis.

*  Returned Value:
*     Pointer to the Symbol string (null terminated).

*  Notes:
*     -  The pointer returned may point at memory allocated within the SkyAxis
*     object, or at static memory. The contents of the string may be
*     over-written or the pointer may become invalid following a further
*     invocation of the same function, deletion of the SkyAxis, or assignment
*     of a new Symbol value. A copy of the string should therefore be made if
*     necessary.
*     -  This function will return a NULL pointer if it is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   const char *result;           /* Pointer value to return */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise. */
   result = NULL;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Test if the Symbol attribute is set. If so, use the parent astGetAxisSymbol
   method to get a pointer to it. */
   if ( astTestAxisSymbol( this ) ) {
      result = (*parent_getaxissymbol)( this_axis );

/* If a value has been set for the IsLatitude attribute, use it to decide
   whether to use "delta" (for latitude) or "alpha" (for longitude). */
   } else if ( astTestAxisIsLatitude( this ) ) {
      result = astGetAxisIsLatitude( this ) ? "delta" : "alpha";

/* Otherwise, use the AsTime attribute to decide whether the SkyAxis is
   likely to be a longitude or latitude axis (the former usually having values
   formatted as times). */
   } else {
      result = astGetAxisAsTime( this ) ? "alpha" : "delta";
   }

/* If an error occurred, clear the result pointer. */
   if ( !astOK ) result = NULL;

/* Return the result. */
   return result;
}

static const char *GetAxisUnit( AstAxis *this_axis ) {
/*
*  Name:
*     GetAxisUnit

*  Purpose:
*     Obtain a pointer to the Unit attribute for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     const char *GetAxisUnit( AstAxis *this )

*  Class Membership:
*     SkyAxis member function (over-rides the astGetAxisUnit method inherited
*     from the Axis class).

*  Description:
*     This function returns a pointer to the Unit attribute associated with
*     a SkyAxis and provides a suitable default if necessary. This string
*     attribute describes the unit used to represent formatted coordinate
*     values on the SkyAxis. 

*  Parameters:
*     this
*        Pointer to the SkyAxis.

*  Returned Value:
*     Pointer to the Unit string (null terminated).

*  Notes:
*     -  The pointer returned may point at memory allocated within the SkyAxis
*     object, or at static memory. The contents of the string may be
*     over-written or the pointer may become invalid following a further
*     invocation of the same function, deletion of the SkyAxis, or assignment
*     of a new Unit value. A copy of the string should therefore be made if
*     necessary.
*     -  This function will return a NULL pointer if it is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   const char *fmt;              /* Pointer to format specifier */
   const char *result;           /* Pointer to result string */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise */
   result = NULL;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Test if the Unit attribute is set. If so, invoke the parent astGetAxisUnit
   method to obtain a pointer to it. */
   if ( astTestAxisUnit( this ) ) {
      result = (*parent_getaxisunit)( this_axis );

/* If we must provide a default, obtain a pointer to the format specifier used
   to format SkyAxis values. Use a private member function (not a method) to
   access this, in case derived classes have extended the syntax of this
   string. */
   } else {
      fmt = GetAxisFormat( this_axis );

/* Use the format specifier to generate a matching default Unit string and
   obtain a pointer to it. */
      if ( astOK ) result = DHmsUnit( fmt, 1 );
   }

/* Return the result. */
   return result;
}

static void InitVtab( AstSkyAxisVtab *vtab ) {
/*
*  Name:
*     InitVtab

*  Purpose:
*     Initialise a virtual function table for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     void InitVtab( AstSkyAxisVtab *vtab )

*  Class Membership:
*     SkyAxis member function.

*  Description:
*     This function initialises the component of a virtual function
*     table which is used by the SkyAxis class.

*  Parameters:
*     vtab
*        Pointer to the virtual function table. The components used by
*        all ancestral classes should already have been initialised.
*/

/* Local Variables: */
   AstAxisVtab *axis;            /* Pointer to Axis component of Vtab */
   AstObjectVtab *object;        /* Pointer to Object component of Vtab */

/* Check the local error status. */
   if ( !astOK ) return;

/* Store a unique "magic" value in the virtual function table. This
   will be used (by astIsASkyAxis) to determine if an object belongs
   to this class.  We can conveniently use the address of the (static)
   class_init variable to generate this unique value. */
   vtab->check = &class_init;

/* Initialise member function pointers. */
/* ------------------------------------ */
/* Store pointers to the member functions (implemented here) that provide
   virtual methods for this class. */
   vtab->ClearAxisAsTime = ClearAxisAsTime;
   vtab->ClearAxisIsLatitude = ClearAxisIsLatitude;
   vtab->GetAxisAsTime = GetAxisAsTime;
   vtab->GetAxisIsLatitude = GetAxisIsLatitude;
   vtab->SetAxisAsTime = SetAxisAsTime;
   vtab->SetAxisIsLatitude = SetAxisIsLatitude;
   vtab->TestAxisAsTime = TestAxisAsTime;
   vtab->TestAxisIsLatitude = TestAxisIsLatitude;

/* Save the inherited pointers to methods that will be extended, and
   replace them with pointers to the new member functions. */
   object = (AstObjectVtab *) vtab;
   axis = (AstAxisVtab *) vtab;

   parent_clearattrib = object->ClearAttrib;
   object->ClearAttrib = ClearAttrib;
   parent_getattrib = object->GetAttrib;
   object->GetAttrib = GetAttrib;
   parent_setattrib = object->SetAttrib;
   object->SetAttrib = SetAttrib;
   parent_testattrib = object->TestAttrib;
   object->TestAttrib = TestAttrib;

   parent_axisoverlay = axis->AxisOverlay;
   axis->AxisOverlay = AxisOverlay;
   parent_getaxisdirection = axis->GetAxisDirection;
   axis->GetAxisDirection = GetAxisDirection;
   parent_getaxislabel = axis->GetAxisLabel;
   axis->GetAxisLabel = GetAxisLabel;
   parent_getaxissymbol = axis->GetAxisSymbol;
   axis->GetAxisSymbol = GetAxisSymbol;
   parent_getaxisunit = axis->GetAxisUnit;
   axis->GetAxisUnit = GetAxisUnit;

/* Store replacement pointers for methods which will be over-ridden by
   new member functions implemented here. */
   axis->AxisAbbrev = AxisAbbrev;
   axis->AxisFormat = AxisFormat;
   axis->AxisGap = AxisGap;
   axis->AxisDistance = AxisDistance;
   axis->AxisOffset = AxisOffset;
   axis->AxisNorm = AxisNorm;
   axis->AxisUnformat = AxisUnformat;
   axis->ClearAxisFormat = ClearAxisFormat;
   axis->GetAxisFormat = GetAxisFormat;
   axis->SetAxisFormat = SetAxisFormat;
   axis->TestAxisFormat = TestAxisFormat;

/* Declare the destructor, copy constructor and dump function. */
   astSetDelete( vtab, Delete );
   astSetCopy( vtab, Copy );
   astSetDump( vtab, Dump, "SkyAxis", "Celestial coordinate axis" );
}

static void ParseDHmsFormat( const char *fmt, char *sep, int *plus,
                             int *lead_zero, int *as_time, int *dh, int *min,
                             int *sec, int *ndp ) {
/*
*  Name:
*     ParseDHmsFormat

*  Purpose:
*     Parse a format specifier for degrees/hours, minutes and seconds.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     void ParseDHmsFormat( const char *fmt, char *sep, int *plus,
*                           int *lead_zero, int *as_time, int *dh, int *min,
*                           int *sec, int *ndp )

*  Class Membership:
*     SkyAxis member function.

*  Description:
*     This function parses a SkyAxis format specifier which describes
*     how to convert an angle in radians into a text string with
*     separate fields for degrees/hours, minutes and seconds.

*  Parameters:
*     fmt
*        Pointer to a null terminated string containing the format
*        specifier.  For details of the syntax of this string, see the
*        DHmsFormat function.
*     sep
*        Pointer to a location in which a single character will be
*        returned to indicate which separator should be used to
*        separate the fields.  The returned value will be one of ' '
*        (use a blank as the separator), ':' (use a colon as the
*        separator) or 'l' (use one of the letters "hdms" as
*        appropriate).
*     plus
*        Pointer to an int in which a boolean value will be returned
*        to indicate if a plus sign should be prefixed to positive
*        values.
*     lead_zero
*        Pointer to an int in which a boolean value will be returned
*        to indicate if leading zeros should be prefixed to the value
*        so that the first field is always of constant (maximum)
*        width, as would be required in a fixed-width table. Leading
*        zeros are always prefixed to any fields that follow.
*     as_time
*        Pointer to an int in which a boolean value will be returned
*        to indicate whether the value is to be formatted as a time
*        (e.g. in hours) rather than as an angle (in degrees).
*     dh
*        Pointer to an int in which a boolean value will be returned
*        to indicate whether a degrees or hours field is required.
*     min
*        Pointer to an int in which a boolean value will be returned
*        to indicate whether a minutes field is required.
*     sec
*        Pointer to an int in which a boolean value will be returned
*        to indicate whether a seconds field is required.
*     ndp
*        Pointer to an int in which to return the number of digits
*        required following the decimal point in the final field. A
*        value of zero indicates that the decimal point should be
*        omitted.

*  Returned Value:
*     void

*  Acknowledgements:
*     - This function is a close approximation to a Fortran 77 routine
*     written by Clive Davenhall which implements the system of format
*     specifiers for angles described in his document on the CAT
*     catalogue access library (Starlink User Note 181). It supports
*     the same format specifiers.
*/

/* Local Variables: */
   int decpos;                   /* Offset of decimal point */
   int i;                        /* Loop counter for format characters */
   int ndpval;                   /* Number of decimal places required */

/* Check the global error status. */
   if ( !astOK ) return;

/* Initialise. */
   *as_time = -1;
   *lead_zero = 0;
   *dh = 0;
   *min = 0;
   *ndp = 0;
   *plus = 0;
   *sec = 0;
   *sep = ':';
   decpos = -1;

/* Loop to inspect and classify each character. */
   for ( i = 0; fmt[ i ]; i++ ) {
      switch ( fmt[ i ] ) {

/* Note if a '+' sign is needed. */
         case '+':
            *plus = 1;
            break;

/* Note if leading zeros are needed. */
         case 'Z': case 'z':
            *lead_zero = 1;
            break;

/* Set the required separator. */
         case 'I': case 'i':
            *sep = ':';
            break;
         case 'B': case 'b':
            *sep = ' ';
            break;
         case 'L': case 'l':
            *sep = 'l';
            break;

/* Note if the value is to be formatted as a time (but not if a
   degrees or hours field has already been specified). */
         case 'T': case 't':
            if ( *as_time == -1 ) *as_time = 1;
            break;

/* Note if a degrees or hours field is required (and hence whether the
   value is to be formatted as a time or an angle). */
         case 'H': case 'h':
            *dh = 1;
            *as_time = 1;
            break;
         case 'D': case 'd':
            *dh = 1;
            *as_time = 0;
            break;

/* Note if a minutes field is required. */
         case 'M': case 'm':
            *min = 1;
            break;

/* Note if a seconds field is required. */
         case 'S': case 's':
            *sec = 1;
            break;

/* Note if decimal places are required. */
	 case '.':
            decpos = i;
      }
   }

/* Format the value as an angle by default. */
   if ( *as_time == -1 ) *as_time = 0;

/* Use degrees (or hours) as the default field. */
   if ( !*min && !*sec ) *dh = 1;

/* Omit the seconds field if the degrees/hours field is present but
   the minutes field is not. */
   if ( *dh && !*min ) *sec = 0;

/* If decimal places are required, attempt to read the integer value
   following the decimal point which specifies how many. If
   successful, and a valid (positive) result was obtained, note its
   value. */
   if ( ( decpos >= 0 ) && ( decpos < ( i - 1 ) ) ) {
      if ( sscanf( fmt + decpos + 1, "%d", &ndpval ) == 1 ) {
         if ( ndpval > 0 ) *ndp = ndpval;
      }
   }
}

static void SetAttrib( AstObject *this_object, const char *setting ) {
/*
*  Name:
*     SetAttrib

*  Purpose:
*     Set an attribute value for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     void SetAttrib( AstObject *this, const char *setting )

*  Class Membership:
*     SkyAxis member function (over-rides the astSetAttrib method
*     inherited from the Axis class).

*  Description:
*     This function assigns an attribute value for a SkyAxis, the
*     attribute and its value being specified by means of a string of
*     the form:
*
*        "attribute= value "
*
*     Here, "attribute" specifies the attribute name and should be in
*     lower case with no white space present. The value to the right
*     of the "=" should be a suitable textual representation of the
*     value to be assigned and this will be interpreted according to
*     the attribute's data type.  White space surrounding the value is
*     only significant for string attributes.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     setting
*        Pointer to a null terminated string specifying the new
*        attribute value.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   int as_time;                  /* Format values as times? */
   int is_latitude;              /* SkyAxis is a latitude axis? */
   int len;                      /* Length of setting string */
   int nc;                       /* Number of characters read by sscanf */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_object;

/* Obtain the length of the setting string. */
   len = (int) strlen( setting );

/* Test for each recognised attribute in turn, using "sscanf" to parse
   the setting string and extract the attribute value (or an offset to
   it in the case of string values). In each case, use the value set
   in "nc" to check that the entire string was matched. Once a value
   has been obtained, use the appropriate method to set it. */

/* AsTime. */
/* ------- */
   if ( nc = 0,
        ( 1 == sscanf( setting, "astime= %d %n", &as_time, &nc ) )
        && ( nc >= len ) ) {
      astSetAxisAsTime( this, as_time );

/* IsLatitude. */
/* ----------- */
   } else if ( nc = 0,
        ( 1 == sscanf( setting, "islatitude= %d %n", &is_latitude, &nc ) )
        && ( nc >= len ) ) {
      astSetAxisIsLatitude( this, is_latitude );

/* Pass any unrecognised attribute setting to the parent method for further
   interpretation. */
   } else {
      (*parent_setattrib)( this_object, setting );
   }
}

static void SetAxisFormat( AstAxis *this_axis, const char *format ) {
/*
*  Name:
*     SetAxisFormat

*  Purpose:
*     Set a value for the Format attribute of a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     void SetAxisFormat( AstAxis *this, const char *format )

*  Class Membership:
*     SkyAxis member function (over-rides the astSetAxisFormat method inherited
*     from the Axis class).

*  Description:
*     This function sets a new value for the Format attribute of a SkyAxis.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     format
*        Pointer to a null terminated string containing the new Format value.

*  Returned Value:
*     void

*  Notes:
*     -  For details of the syntax of the Format string, see the DHmsFormat
*     function.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* Store a pointer to a copy of the Format string in the SkyAxis structure. */
   this->skyformat = astStore( this->skyformat, format,
                               strlen( format ) + (size_t) 1 );
}

static int TestAttrib( AstObject *this_object, const char *attrib ) {
/*
*  Name:
*     TestAttrib

*  Purpose:
*     Test if a specified attribute value is set for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     int TestAttrib( AstObject *this, const char *attrib )

*  Class Membership:
*     SkyAxis member function (over-rides the astTestAttrib protected
*     method inherited from the Axis class).

*  Description:
*     This function returns a boolean result (0 or 1) to indicate
*     whether a value has been set for one of a SkyAxis' attributes.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     attrib
*        Pointer to a null-terminated string specifying the attribute
*        name.  This should be in lower case with no surrounding white
*        space.

*  Returned Value:
*     One if a value has been set, otherwise zero.

*  Notes:
*     - A value of zero will be returned if this function is invoked
*     with the global status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   int result;                   /* Result value to return */

/* Initialise. */
   result = 0;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_object;

/* Check the attribute name and test the appropriate attribute. */

/* AsTime. */
/* ------- */
   if ( !strcmp( attrib, "astime" ) ) {
      result = astTestAxisAsTime( this );

/* IsLatitude. */
/* ----------- */
   } else if ( !strcmp( attrib, "islatitude" ) ) {
      result = astTestAxisIsLatitude( this );

/* If the attribute is still not recognised, pass it on to the parent
   method for further interpretation. */
   } else {
      result = (*parent_testattrib)( this_object, attrib );
   }

/* Return the result, */
   return result;
}

static int TestAxisFormat( AstAxis *this_axis ) {
/*
*  Name:
*     TestAxisFormat

*  Purpose:
*     Test if a value has been set for the Format attribute of a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     int TestAxisFormat( AstAxis *this )

*  Class Membership:
*     SkyAxis member function (over-rides the astTestAxisFormat method
*     inherited from the Axis class).

*  Description:
*     This function returns 0 or 1 to indicate whether a value has been set
*     for the Format attribute of a SkyAxis.

*  Parameters:
*     this
*        Pointer to the SkyAxis.

*  Returned Value:
*     Zero if no Format value has been set, otherwise one.

*  Notes:
*     -  This function will return a value of zero if it is invoked with the
*     global error status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   int result;                   /* Result to be returned */

/* Check the global error status. */
   if ( !astOK ) return 0;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_axis;

/* The Format string has been set if the pointer to it is not NULL. */
   result = ( this->skyformat != NULL );

/* Return the result. */
   return result;
}

static int AxisUnformat( AstAxis *this_axis, const char *string,
                         double *value ) {
/*
*  Name:
*     AxisUnformat

*  Purpose:
*     Read a formatted coordinate value for a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     int AxisUnformat( AstAxis *axis, const char *string, double *value )

*  Class Membership:
*     SkyAxis member function (over-rides the astAxisUnformat method
*     inherited from the Axis class).

*  Description:
*     This function reads a formatted coordinate value for a SkyAxis
*     (supplied as a string) and returns the equivalent numerical
*     value as a double. It also returns the number of characters read
*     from the string.

*  Parameters:
*     this
*        Pointer to the SkyAxis.
*     string
*        Pointer to a constant null-terminated string containing the
*        formatted coordinate value.
*     value
*        Pointer to a double in which the coordinate value read will be
*        returned (in radians).

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
*-
*/

/* Local Constants: */
#define FMT_LEN 50               /* Length of format buffer */

/* Local Variables: */
   char fmtbuf[ FMT_LEN + 1 ];   /* Buffer for C format specification */
   char fmtsep;                  /* Format field separator character */
   char last_sep;                /* Previous separator character */
   char sep;                     /* Separator character */
   char sep_used;                /* Separator character being used */
   char sign[ 2 ];               /* Sign character as string */
   const char *field_start[ 3 ]; /* Pointer to start of each field */
   const char *fmt;              /* Pointer to SkyAxis Format string */
   const char *s;                /* Pointer to current reading position */
   const char *string_start;     /* Pointer to first significant character */
   double field[ 3 ];            /* Field values */
   double testval;               /* Value to test for invalid fields */
   int angle_or_time;            /* Value known to be angle or time? */
   int as_time;                  /* Value is a time (else an angle)? */
   int decimal;                  /* Decimal point in field? */
   int dh;                       /* Hours field required? */
   int field_id[ 3 ];            /* Field identification (0 = don't know) */
   int final;                    /* Final field read? */
   int good_sep;                 /* Separator character valid? */
   int i;                        /* Loop counter for characters */
   int ifield;                   /* Loop counter for fields */
   int lead_zero;                /* Add leading zeros? */
   int len;                      /* Significant length of string */
   int match;                    /* Character pattern matches? */
   int min;                      /* Minutes field required? */
   int n;                        /* Number of characters read by sscanf */
   int nc;                       /* Total no. characters read */
   int nchar;                    /* Number of characters in erroneous value */
   int ndp;                      /* Number of decimal places */
   int next_id;                  /* Next field ID to use (0 = don't know) */
   int nfield;                   /* Number of fields read */
   int nread;                    /* No. characters read for current field */
   int plus;                     /* Add leading plus sign? */
   int positive;                 /* Value is positive? */
   int sec;                      /* Seconds field required? */
   int sep_angle_or_time;        /* Separator indicates angle or time? */
   int sep_field_id;             /* Field ID from separator (0 = don't know) */
   int sep_index;                /* Index of separator character in table */
   int sep_len;                  /* Length of separator plus trailing space */
   int stat;                     /* SLALIB status */
   int suffix_sep;               /* Field has a suffix separator? */
   static double deg2rad;        /* Degrees to radians conversion factor */
   static double hr2rad;         /* Hours to radians conversion factor */
   static int init = 0;          /* Conversion factors initialised? */

/* Local Data: */
   const char *sep_list =        /* List of separator characters recognised */
              " :hHdDmM'sS\"";

   const int angle_or_time_list[] = /* Whether separator indicates angle or
                                       time (1 or 2). Zero => don't know. */
             { 0, 0, 2, 2, 1, 1, 0, 0, 1, 0, 0, 1 };

   const int field_id_list[] =   /* Whether separator identifies previous field
                                    (1, 2, or 3). Zero => doesn't identify. */
             { 0, 0, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3 };

   const double fieldvalue[ 3 ] = /* Nominal field values (degrees/hours) */
                { 1.0, 1.0 / 60.0, 1.0 / 3600.0 };

/* Initialise. */
   nc = 0;

/* Check the global error status. */
   if ( !astOK ) return nc;

/* If not done previously, use SLALIB to obtain conversion factors
   between hours/degrees and radians. Do this only once. */
   if ( !init ) {
      slaDtf2r( 1, 0, 0.0, &hr2rad, &stat );
      slaDaf2r( 1, 0, 0.0, &deg2rad, &stat );
      init = 1;
   }

/* Obtain the SkyAxis Format string and parse it to determine the
   default choice of input format. Use a private method to obtain the
   Format string, in case the syntax has been over-ridden by a derived
   class. */
   fmt = GetAxisFormat( this_axis );
   ParseDHmsFormat( fmt, &fmtsep, &plus, &lead_zero, &as_time, &dh, &min, &sec,
                    &ndp );

/* Initialise a pointer into the string and advance it to the first
   non-white space character. Save a copy of this pointer. */
   if ( astOK ) {
      s = string;
      while ( isspace( (int) *s ) ) s++;
      string_start = s;

/* Read sign information. */
/* ---------------------- */
/* Attempt to read an optional sign character ("+" or "-"), possibly
   surrounded by white space. Set a flag to indicate if the returned
   value should be positive or not. Increment the string pointer to
   the next significant character. */
   positive = 1;
      n = 0;
      if ( 1 == sscanf( s, " %1[+-] %n", sign, &n ) ) {
         positive = ( *sign == '+' );
         s += n;
      }

/* Loop to read field information. */
/* ------------------------------- */
/* Initialise, then loop to read the values of up to three fields and
   to identify the separators that accompany them. */
      angle_or_time = 0;
      last_sep = '\0';
      next_id = 0;
      nfield = 0;
      sep_used = '\0';
      suffix_sep = 0;
      for ( ifield = 0; ifield < 3; ifield++ ) {

/* Set the default field value. */
         field[ ifield ] = 0.0;

/* If a prefix separator was identified for the second and subsequent
   fields (when the previous field was being read), then step over the
   prefix, including any following white space. */
         if ( ifield && !suffix_sep ) s += sep_len;

/* Note where in the input string the field's numerical value
   starts. */
         field_start[ ifield ] = s;

/* Each field must consist of a string of digits, possibly surrounded
   by white space, except that an optional decimal point may also be
   present (in which case it indicates the final field). Since we want
   to exclude signs, exponents, etc. from these fields, we must first
   identify a valid sequence of digits, before attempting to read them
   as a number. Start by assuming that we will find a decimal
   point. */
         decimal = 1;

/* Match a field and obtain its value. */
/* ----------------------------------- */
/* Look for a character sequence like "12.345", or similar, setting a
   flag to identify a match. */
         n = 0;
         match = ( 0 == sscanf( s, "%*[0123456789].%*[0123456789]%n", &n ) )
                   && n;

/* If that failed, then look for a sequence like "12.", or similar. */
         if ( !match ) {
            n = 0;
            match = ( 0 == sscanf( s, "%*[0123456789].%n", &n ) ) && n;
         }

/* If that also failed, then look for a sequence like ".12", or similar. */
         if ( !match ) {
            n = 0;
            match = ( 0 == sscanf( s, ".%*[0123456789]%n", &n ) ) && n;
         }

/* If that also failed, then look for a sequence containing digits only. */
         if ( !match ) {
            n = 0;
            match = ( 0 == sscanf( s, "%*[0123456789]%n", &n ) ) && n;

/* Note we have not found a decimal point. */
            decimal = 0;
         }

/* If we identified a suitable sequence of characters above, we will
   now read them as a number. To prevent any subsequent characters
   being included as part of this number, the field width must be
   restricted to the length of the sequence we found. Write a format
   specification to read a double with this field width, followed by
   optional white space, and to return the total number of characters
   read. */
         nread = 0;
         if ( match ) {
            (void) sprintf( fmtbuf, "%%%dlf %%n", n );

/* Use this format specification to read the field value. If
   successful, increment the string pointer to the next significant
   character. */
            if ( 1 == sscanf( s, fmtbuf, field + ifield, &nread ) ) s += nread;
         }

/* Note the total number of characters read up to the end of the
   numerical value in this field (including any following white
   space). */
         nc = s - string;
      
/* Identify the following separator. */
/* --------------------------------- */
/* We will now attempt to identify the field separator (if any) which
   follows the field we have just read. By default, we behave as if
   the separator is a space. Note we have actually found a space (at
   least) if extra white space characters were read as part of the
   field value above. */
         sep = ' ';
         good_sep = ( nread > n );

/* Look for one of the recognised separator characters. If one is
   found, save a copy of it and note we appear (so far) to have a
   valid separator. */
         sep_len = 0;
         if ( *s && strchr( sep_list, *s ) ) {
            sep = *s;
            good_sep = 1;

/* Set "sep_len" to the number of characters associated with the
   separator. This includes any following white space. */
            while ( isspace( (int) s[ ++sep_len ] ) );
         }

/* Identify the separator character by looking it up in the separator
   list (this just uses a space if no valid separator has been
   found). */
         sep_index = strchr( sep_list, sep ) - sep_list;

/* Determine if the separator can be used to identify the field which
   preceded it and if it allows us to determine whether an angle or a
   time is being read. Both of these properties are specified in data
   tables (with zero indicating that the separator didn't supply any
   information). */
         sep_field_id = field_id_list[ sep_index ];
         sep_angle_or_time = angle_or_time_list[ sep_index ];

/* Validate the separator. */
/* ----------------------- */
/* Now perform further checks that the separator is valid
   (i.e. conforms to the required syntax). If it appears to identify
   the previous field (i.e. is a "suffix" separator like "m" or "s"),
   then it is valid only if its field ID is no less than the ID value
   that would be used next, based on previous fields (if any), and no
   less than the current field number. This ensures that fields occur
   in the correct order without duplication. */
         if ( good_sep ) {
            if ( sep_field_id ) {
               good_sep = ( sep_field_id >= next_id ) &&
                          ( sep_field_id > ifield );

/* Otherwise (i.e. we appear to have a "prefix" separator like ":" or
   " "), it is valid if it is the first one used, or if it matches the
   previous one used. Keep a note of the first such separator used for
   checking subsequent ones. */
            } else {
               good_sep = !sep_used || ( sep == sep_used );
               if ( !sep_used ) sep_used = sep;
            }
         }

/* If the separator seems OK and we don't yet know whether we are reading
   an angle or a time, then use whatever information the separator
   provides about this. */
         if ( good_sep ) {
            if ( !angle_or_time ) {
               angle_or_time = sep_angle_or_time;

/* If we already know whether we are reading an angle or a time and
   the current separator also contains information about this, then
   check that these sources of information are compatible. This
   prevents inconsistent use of angle/time field separators. */
            } else {
               good_sep = !sep_angle_or_time ||
                          ( sep_angle_or_time == angle_or_time );
            }
         }

/* Update the count of characters read for this field and note if we
   have identified a valid suffix separator. */
         if ( good_sep ) nread += sep_len;
         suffix_sep = good_sep && sep_field_id;

/* Identify which field was read. */
/* ------------------------------ */
/* If we have a valid suffix separator, store the field ID. Also make
   a note of the ID to use for the next field. */
         if ( suffix_sep ) {
            field_id[ ifield ] = sep_field_id;
            next_id = sep_field_id + 1;

/* Step over the separator (plus any following white space) and update
   the total number of characters read (prefix separators are not
   accounted for until we start to read the next field). */
            s += sep_len;
            nc = s - string;;

/* If the separator does not identify the current field, then assign a
   field ID based on the previous field (if any). Update the ID to use
   for the next field, if known. */
         } else {
            field_id[ ifield ] = next_id;
            if ( next_id ) next_id++;
         }

/* Count fields and exit when done. */
/* -------------------------------- */
/* If no characters have been read for the current field, then
   disregard the field if: (a) it is the first one (i.e. there is
   nothing to read), or (b) it follows a white space separator
   (because trailing space does not delimit an extra field). In either
   case, we have now read all the fields. Otherwise, increment the
   count of fields read. */
         final = 0;
         if ( !nread && ( !ifield || isspace( (int) last_sep ) ) ) {
            final = 1;
         } else {
            nfield++;
         }

/* We have also read all the fields if: (a) the last one contained a
   decimal point, or (b) the next character is not a valid field
   separator, or (c) we have read the seconds field so the next field
   ID would exceed 3. */
         final = final || decimal || !good_sep || ( next_id > 3 );

/* Quit reading if we have read the final field. Otherwise, save the
   separator character and attempt to read the next field. */
         if ( final ) break;
         last_sep = sep;
      }

/* Complete the identification of fields. */
/* -------------------------------------- */
/* Although we have propagated field IDs from earlier ones to later
   ones in the loop above, we have still not done the reverse. This
   means there there may still be some leading fields which have not
   been positively identified (i.e. still have a field ID of zero). In
   fact, all the fields we have read might still be unidentified at
   this point. */

/* Calculate the field ID that would apply to the final field we have
   read in the absence of any other information. This depends on the
   number of leading fields that are expected to be missing. */
      next_id = nfield + ( dh ? 0 : ( min ? 1 : 2 ) );
      if ( next_id > 3 ) next_id = 3;

/* Loop through the fields in reverse order, propagating any positive
   identifications backwards towards the first field. If no fields
   have been positively identified, then they are simply numbered
   consecutively based on the value calculated above. */
      for ( ifield = nfield - 1; ifield >= 0; ifield-- ) {
         if ( field_id[ ifield ] ) {
            next_id = field_id[ ifield ] - 1;
         } else {
            field_id[ ifield ] = next_id--;
         }
      }

/* Handle inability to read any value. */
/* ----------------------------------- */
/* If no fields were read, then check to see if we are trying to read
   the string "<bad>" (or similar) possibly surrounded by, or
   containing, white space. If so, return the coordinate value
   AST__BAD. */
      if ( !nfield ) {
         if ( n = 0,
              ( 0 == sscanf( string, " < %*1[Bb] %*1[Aa] %*1[Dd] > %n", &n )
                && n ) ) {
            *value = AST__BAD;
            nc = n;

/* If the string still cannot be read, then return a function value of
   zero. */
         } else {
            nc = 0;
         }

/* Finally determine angle or time. */
/* -------------------------------- */
/* If one or more fields have been read, check if we know whether to
   interpret the value as an angle or a time (if not, we continue to
   use the default choice obtained from the SkyAxis Format string). */
      } else {
         if ( angle_or_time ) as_time = ( angle_or_time == 2 );

/* Validate field values. */
/* ---------------------- */
/* If OK, check all fields except the first one for a valid value (we
   allow the first field to be unconstrained, so that angles and times
   outside the conventional ranges can be represented). We only need
   to test for values over 60.0, since negative values can't be
   read. */
         if ( astOK ) {
            for ( ifield = 1; ifield < nfield; ifield++ ) {
               if ( field[ ifield ] >= 60.0 ) {

/* If a suspect field is found, we must now re-read it. This is
   because values like "59.9999..." are valid, even if they round up
   to 60, whereas "60" isn't. To distinguish these cases, we read the
   digits that occur before the decimal point (if any). Determine how
   many such digits there are. */
                  n = 0;
                  if ( ( 0 == sscanf( field_start[ ifield ],
                                      "%*[0123456789]%n", &n ) ) && n ) {

/* If there are none (this shouldn't happen), the field is
   valid. Otherwise, construct a format specification to read these
   digits as a floating point number. */
                     (void) sprintf( fmtbuf, "%%%dlf", n );

/* Read the digits and compare the result with 60.0. Report an error
   and quit if necessary, limiting the string length in the error
   message to include just the significant characters in the value
   read. */
                     if ( ( 1 == sscanf( field_start[ ifield ], fmtbuf,
                                         &testval ) )
                          && ( testval >= 60.0 ) ) {
                        nchar = nc - ( string_start - string );
                        for ( i = len = 0; i < nchar; i++ ) {
                           if ( !isspace( (int) string_start[ i ] ) ) {
                              len = i + 1;
                           }
                        }
                        astError( AST__UNFER, "Invalid %s%s value in sky "
                                  "coordinate \"%.*s\".", as_time ? "" : "arc",
                                  ( field_id[ ifield ] == 2 ) ? "minutes" :
                                                                "seconds",
                                  len, string_start );
                        break;
                     }
                  }
               }
            }
         }

/* Calculate final result. */
/* ----------------------- */
/* If OK, calculate the result by summing the field values and converting
   to radians. */
         if ( astOK ) {
            *value = 0.0;
            for ( ifield = 0; ifield < nfield; ifield++ ) {
               *value += field[ ifield ] *
                         fieldvalue[ field_id[ ifield ] - 1 ] *
                         ( as_time ? hr2rad : deg2rad );
            }

/* Change sign if necessary. */
            if ( !positive ) *value = - *value;
         }
      }
   }

/* If an error occurred, set the number of characters read to zero. */
   if ( !astOK ) nc = 0;

/* Return the number of characters read. */
   return nc;

/* Undefine macros local to this function. */
#undef FMT_LEN
}

/* Functions which access class attributes. */
/* ---------------------------------------- */
/* Implement member functions to access the attributes associated with the
   SkyAxis class using the macros defined for this purpose in the "object.h"
   file. For a description of each attribute, see the class interface (in the
   associated .h file). */

/* AsTime. */
/* ------- */
/* The value is constrained to be -INT_MAX, 0 or 1, with -INT_MAX for
   "undefined". The default value is 0 unless the "IsLatitude"
   attribute has been explicitly set to 0, in which case "AsTime"
   defaults to 1. */
astMAKE_CLEAR(SkyAxis,AxisAsTime,as_time,-INT_MAX)
astMAKE_GET(SkyAxis,AxisAsTime,int,0,( ( this->as_time != -INT_MAX ) ?
                                       this->as_time :
                                       ( astTestAxisIsLatitude( this ) &&
                                         !astGetAxisIsLatitude( this ) ) ))
astMAKE_SET(SkyAxis,AxisAsTime,int,as_time,( value != 0 ))
astMAKE_TEST(SkyAxis,AxisAsTime,( this->as_time != -INT_MAX ))

/* IsLatitude. */
/* ----------- */
/* The value is constrained to be -INT_MAX, 0 or 1, with -INT_MAX for
   "undefined". The default value is 0. */
astMAKE_CLEAR(SkyAxis,AxisIsLatitude,is_latitude,-INT_MAX)
astMAKE_GET(SkyAxis,AxisIsLatitude,int,0,( this->is_latitude != -INT_MAX ?
                                           this->is_latitude : 0 ))
astMAKE_SET(SkyAxis,AxisIsLatitude,int,is_latitude,( value != 0 ))
astMAKE_TEST(SkyAxis,AxisIsLatitude,( this->is_latitude != -INT_MAX ))

/* Copy constructor. */
/* ----------------- */
static void Copy( const AstObject *objin, AstObject *objout ) {
/*
*  Name:
*     Copy

*  Purpose:
*     Copy constructor for SkyAxis objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Copy( const AstObject *objin, AstObject *objout )

*  Description:
*     This function implements the copy constructor for SkyAxis objects.

*  Parameters:
*     objin
*        Pointer to the object to be copied.
*     objout
*        Pointer to the object being constructed.

*  Returned Value:
*     void

*  Notes:
*     -  This constructor makes a deep copy.
*/

/* Local Variables: */
   AstSkyAxis *in;                  /* Pointer to input SkyAxis */
   AstSkyAxis *out;                 /* Pointer to output SkyAxis */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain pointers to the input and output SkyAxis structures. */
   in = (AstSkyAxis *) objin;
   out = (AstSkyAxis *) objout;

/* For safety, first clear any references to the input memory from
   the output SkyAxis. */
   out->skyformat = NULL;

/* Make copies of the allocated strings. */
   if ( in->skyformat ) out->skyformat = astStore( NULL, in->skyformat,
                                       strlen( in->skyformat ) + (size_t) 1 );

/* If an error occurred, clean up by freeing all memory allocated above. */
   if ( !astOK ) {
      out->skyformat = astFree( out->skyformat );
   }
}

/* Destructor. */
/* ----------- */
static void Delete( AstObject *obj ) {
/*
*  Name:
*     Delete

*  Purpose:
*     Destructor for SkyAxis objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Delete( AstObject *obj )

*  Description:
*     This function implements the destructor for SkyAxis objects.

*  Parameters:
*     obj
*        Pointer to the object to be deleted.

*  Returned Value:
*     void

*  Notes:
*     This function attempts to execute even if the global error status is
*     set.
*/

/* Local Variables: */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) obj;

/* Free all allocated memory. */
   this->skyformat = astFree( this->skyformat );
}

/* Dump function. */
/* -------------- */
static void Dump( AstObject *this_object, AstChannel *channel ) {
/*
*  Name:
*     Dump

*  Purpose:
*     Dump function for SkyAxis objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Dump( AstObject *this, AstChannel *channel )

*  Description:
*     This function implements the Dump function which writes out data
*     for the SkyAxis class to an output Channel.

*  Parameters:
*     this
*        Pointer to the SkyAxis whose data are being written.
*     channel
*        Pointer to the Channel to which the data are being written.
*/

/* Local Variables: */
   AstAxis *this_axis;           /* Pointer to Axis structure */
   AstSkyAxis *this;             /* Pointer to the SkyAxis structure */
   const char *sval;             /* Pointer to string value */
   int ival;                     /* Integer value */
   int set;                      /* Attribute value set? */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the SkyAxis structure. */
   this = (AstSkyAxis *) this_object;

/* Write out values representing the instance variables for the
   SkyAxis class.  Accompany these with appropriate comment strings,
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

/* Format. */
/* ------- */
/* We must write out the Format value stored locally as it over-rides
   that provided by the Axis class. */
   this_axis = (AstAxis *) this;
   set = TestAxisFormat( this_axis );
   sval = set ? GetAxisFormat( this_axis ) : astGetAxisFormat( this );
   astWriteString( channel, "Format", set, 0, sval, "Format specifier" );

/* IsLatitude. */
/* ----------- */
   set = TestAxisIsLatitude( this );
   ival = set ? GetAxisIsLatitude( this ) : astGetAxisIsLatitude( this );
   astWriteInt( channel, "IsLat", set, 0, ival,
                ival ? "Latitude axis (not longitude)" :
                       "Longitude axis (not latitude)" );

/* AsTime. */
/* ------- */
   set = TestAxisAsTime( this );
   ival = set ? GetAxisAsTime( this ) : astGetAxisAsTime( this );
   astWriteInt( channel, "AsTime", set, 0, ival,
                ival ? "Display values as times (not angles)" :
                       "Display values as angles (not times)" );
}

/* Standard class functions. */
/* ========================= */
/* Implement the astIsASkyAxis and astCheckSkyAxis functions using the macros
   defined for this purpose in the "object.h" header file. */
astMAKE_ISA(SkyAxis,Axis,check,&class_init)
astMAKE_CHECK(SkyAxis)

AstSkyAxis *astSkyAxis_( const char *options, ... ) {
/*
*+
*  Name:
*     astSkyAxis

*  Purpose:
*     Create a SkyAxis.

*  Type:
*     Public function.

*  Synopsis:
*     #include "skyaxis.h"
*     AstSkyAxis *astSkyAxis( const char *options, ... )

*  Class Membership:
*     SkyAxis constructor.

*  Description:
*     This function creates a new SkyAxis and optionally initialises its
*     attributes.

*  Parameters:
*     options
*        Pointer to a null terminated string containing an optional
*        comma-separated list of attribute assignments to be used for
*        initialising the new SkyAxis. The syntax used is the same as for the
*        astSet method and may include "printf" format specifiers identified
*        by "%" symbols in the normal way.
*     ...
*        If the "options" string contains "%" format specifiers, then an
*        optional list of arguments may follow it in order to supply values to
*        be substituted for these specifiers. The rules for supplying these
*        are identical to those for the astSet method (and for the C "printf"
*        function).

*  Returned Value:
*     A pointer to the new SkyAxis.

*  Notes:
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*-
*/

/* Local Variables: */
   AstSkyAxis *new;              /* Pointer to new SkyAxis */
   va_list args;                 /* Variable argument list */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise the SkyAxis, allocating memory and initialising the
   virtual function table as well if necessary. */
   new = astInitSkyAxis( NULL, sizeof( AstSkyAxis ), !class_init, &class_vtab,
                         "SkyAxis" );

/* If successful, note that the virtual function table has been
   initialised. */
   if ( astOK ) {
      class_init = 1;

/* Obtain the variable argument list and pass it along with the
   options string to the astVSet method to initialise the new SkyAxis'
   attributes. */
      va_start( args, options );
      astVSet( new, options, args );
      va_end( args );

/* If an error occurred, clean up by deleting the new object. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return a pointer to the new SkyAxis. */
   return new;
}

AstSkyAxis *astSkyAxisId_( const char *options, ... ) {
/*
*  Name:
*     astSkyAxisId_

*  Purpose:
*     Create a SkyAxis.

*  Type:
*     Private function.

*  Synopsis:
*     #include "skyaxis.h"
*     AstSkyAxis *astSkyAxisId_( const char *options, ... )

*  Class Membership:
*     SkyAxis constructor.

*  Description:
*     This function implements the external (public) interface to the
*     astSkyAxis constructor function. It returns an ID value (instead
*     of a true C pointer) to external users, and must be provided
*     because astSkyAxis_ has a variable argument list which cannot be
*     encapsulated in a macro (where this conversion would otherwise
*     occur).
*
*     The variable argument list also prevents this function from
*     invoking astSkyAxis_ directly, so it must be a re-implementation
*     of it in all respects, except for the final conversion of the
*     result to an ID value.

*  Parameters:
*     As for astSkyAxis_.

*  Returned Value:
*     The ID value associated with the new SkyAxis.
*/

/* Local Variables: */
   AstSkyAxis *new;              /* Pointer to new SkyAxis */
   va_list args;                 /* Variable argument list */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise the SkyAxis, allocating memory and initialising the
   virtual function table as well if necessary. */
   new = astInitSkyAxis( NULL, sizeof( AstSkyAxis ), !class_init, &class_vtab,
                         "SkyAxis" );

/* If successful, note that the virtual function table has been
   initialised. */
   if ( astOK ) {
      class_init = 1;

/* Obtain the variable argument list and pass it along with the
   options string to the astVSet method to initialise the new SkyAxis'
   attributes. */
      va_start( args, options );
      astVSet( new, options, args );
      va_end( args );

/* If an error occurred, clean up by deleting the new object. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return an ID value for the new SkyAxis. */
   return astMakeId( new );
}

AstSkyAxis *astInitSkyAxis_( void *mem, size_t size, int init,
                             AstSkyAxisVtab *vtab, const char *name ) {
/*
*+
*  Name:
*     astInitSkyAxis

*  Purpose:
*     Initialise a SkyAxis.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "skyaxis.h"
*     AstSkyAxis *astInitSkyAxis( void *mem, size_t size, int init,
*                                 AstSkyAxisVtab *vtab, const char *name )

*  Class Membership:
*     SkyAxis initialiser.

*  Description:
*     This function is provided for use by class implementations to initialise
*     a new SkyAxis object. It allocates memory (if necessary) to accommodate
*     the SkyAxis plus any additional data associated with the derived class.
*     It then initialises a SkyAxis structure at the start of this memory. If
*     the "init" flag is set, it also initialises the contents of a virtual
*     function table for a SkyAxis at the start of the memory passed via the
*     "vtab" parameter.

*  Parameters:
*     mem
*        A pointer to the memory in which the SkyAxis is to be created. This
*        must be of sufficient size to accommodate the SkyAxis data
*        (sizeof(SkyAxis)) plus any data used by the derived class. If a value
*        of NULL is given, this function will allocate the memory itself using
*        the "size" parameter to determine its size.
*     size
*        The amount of memory used by the SkyAxis (plus derived class data).
*        This will be used to allocate memory if a value of NULL is given for
*        the "mem" parameter. This value is also stored in the SkyAxis
*        structure, so a valid value must be supplied even if not required for
*        allocating memory.
*     init
*        A logical flag indicating if the SkyAxis's virtual function table is
*        to be initialised. If this value is non-zero, the virtual function
*        table will be initialised by this function.
*     vtab
*        Pointer to the start of the virtual function table to be associated
*        with the new SkyAxis.
*     name
*        Pointer to a constant null-terminated character string which contains
*        the name of the class to which the new object belongs (it is this
*        pointer value that will subsequently be returned by the astClass
*        method).

*  Returned Value:
*     A pointer to the new SkyAxis.

*  Notes:
*     -  A NULL pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*-
*/

/* Local Variables: */
   AstSkyAxis *new;              /* Pointer to the new SkyAxis */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Initialise an Axis structure (the parent class) as the first component
   within the SkyAxis structure, allocating memory if necessary. */
   new = (AstSkyAxis *) astInitAxis( mem, size, init, (AstAxisVtab *) vtab,
                                     name );

/* If necessary, initialise the virtual function table. */
/* ---------------------------------------------------- */
   if ( init ) InitVtab( vtab );
   if ( astOK ) {

/* Initialise the SkyAxis data. */
/* ---------------------------- */
/* Initialise all attributes to their "undefined" values. */
      new->as_time = -INT_MAX;
      new->is_latitude = -INT_MAX;
      new->skyformat = NULL;

/* If an error occurred, clean up by deleting the new SkyAxis. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return a pointer to the new SkyAxis. */
   return new;
}

AstSkyAxis *astLoadSkyAxis_( void *mem, size_t size, int init,
                             AstSkyAxisVtab *vtab, const char *name,
                             AstChannel *channel ) {
/*
*+
*  Name:
*     astLoadSkyAxis

*  Purpose:
*     Load a SkyAxis.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "skyaxis.h"
*     AstSkyAxis *astLoadSkyAxis( void *mem, size_t size, int init,
*                                 AstSkyAxisVtab *vtab, const char *name,
*                                 AstChannel *channel )

*  Class Membership:
*     SkyAxis loader.

*  Description:
*     This function is provided to load a new SkyAxis using data read
*     from a Channel. It first loads the data used by the parent class
*     (which allocates memory if necessary) and then initialises a
*     SkyAxis structure in this memory, using data read from the input
*     Channel.
*
*     If the "init" flag is set, it also initialises the contents of a
*     virtual function table for a SkyAxis at the start of the memory
*     passed via the "vtab" parameter.

*  Parameters:
*     mem
*        A pointer to the memory into which the SkyAxis is to be
*        loaded.  This must be of sufficient size to accommodate the
*        SkyAxis data (sizeof(SkyAxis)) plus any data used by derived
*        classes. If a value of NULL is given, this function will
*        allocate the memory itself using the "size" parameter to
*        determine its size.
*     size
*        The amount of memory used by the SkyAxis (plus derived class
*        data).  This will be used to allocate memory if a value of
*        NULL is given for the "mem" parameter. This value is also
*        stored in the SkyAxis structure, so a valid value must be
*        supplied even if not required for allocating memory.
*
*        If the "vtab" parameter is NULL, the "size" value is ignored
*        and sizeof(AstSkyAxis) is used instead.
*     init
*        A boolean flag indicating if the SkyAxis's virtual function
*        table is to be initialised. If this value is non-zero, the
*        virtual function table will be initialised by this function.
*
*        If the "vtab" parameter is NULL, the "init" value is ignored
*        and the (static) virtual function table initialisation flag
*        for the SkyAxis class is used instead.
*     vtab
*        Pointer to the start of the virtual function table to be
*        associated with the new SkyAxis. If this is NULL, a pointer
*        to the (static) virtual function table for the SkyAxis class
*        is used instead.
*     name
*        Pointer to a constant null-terminated character string which
*        contains the name of the class to which the new object
*        belongs (it is this pointer value that will subsequently be
*        returned by the astGetClass method).
*
*        If the "vtab" parameter is NULL, the "name" value is ignored
*        and a pointer to the string "SkyAxis" is used instead.

*  Returned Value:
*     A pointer to the new SkyAxis.

*  Notes:
*     - A null pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*-
*/

/* Local Variables: */
   AstSkyAxis *new;              /* Pointer to the new SkyAxis */

/* Initialise. */
   new = NULL;

/* Check the global error status. */
   if ( !astOK ) return new;

/* If a NULL virtual function table has been supplied, then this is
   the first loader to be invoked for this SkyAxis. In this case the
   SkyAxis belongs to this class, so supply appropriate values to be
   passed to the parent class loader (and its parent, etc.). */
   if ( !vtab ) {
      size = sizeof( AstSkyAxis );
      init = !class_init;
      vtab = &class_vtab;
      name = "SkyAxis";
   }

/* Invoke the parent class loader to load data for all the ancestral
   classes of the current one, returning a pointer to the resulting
   partly-built SkyAxis. */
   new = astLoadAxis( mem, size, init, (AstAxisVtab *) vtab, name, channel );

/* If required, initialise the part of the virtual function table used
   by this class. */
   if ( init ) InitVtab( vtab );

/* Note if we have successfully initialised the (static) virtual
   function table owned by this class (so that this is done only
   once). */
   if ( astOK ) {
      if ( ( vtab == &class_vtab ) && init ) class_init = 1;

/* Read input data. */
/* ================ */
/* Request the input Channel to read all the input data appropriate to
   this class into the internal "values list". */
      astReadClassData( channel, "SkyAxis" );

/* Now read each individual data item from this list and use it to
   initialise the appropriate instance variable(s) for this class. */

/* In the case of attributes, we first read the "raw" input value,
   supplying the "unset" value as the default. If a "set" value is
   obtained, we then use the appropriate (private) Set... member
   function to validate and set the value properly. */

/* Format. */
/* ------- */
/* Note that string values do not require any additional processing. */
      new->skyformat = astReadString( channel, "format", NULL );

/* IsLatitude. */
/* ----------- */
      new->is_latitude = astReadInt( channel, "islat", -INT_MAX );
      if ( TestAxisIsLatitude( new ) ) {
         SetAxisIsLatitude( new, new->is_latitude );
      }

/* AsTime. */
/* ------- */
      new->as_time = astReadInt( channel, "astime", -INT_MAX );
      if ( TestAxisAsTime( new ) ) SetAxisAsTime( new, new->as_time );

/* If an error occurred, clean up by deleting the new SkyAxis. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return the new SkyAxis pointer. */
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

/* (No more to define at present.) */
