#if !defined( OBJECT_INCLUDED )  /* Include this file only once */
#define OBJECT_INCLUDED
/*
*++
*  Name:
*     object.h

*  Type:
*     C include file.

*  Purpose:
*     Define the interface to the Object class.

*  Invocation:
*     #include "object.h"

*  Description:
*     This include file defines the interface to the Object class and
*     provides the type definitions, function prototypes and macros,
*     etc.  needed to use this class.

*     The Object class is the base class from which all other classes
*     in the AST library are derived. This class provides all the
*     basic Object behaviour and Object manipulation facilities
*     required throughout the library. There is no Object constructor,
*     however, as Objects on their own are not of much use.

*  Inheritance:
*     The Object base class does not inherit from any other class.

*  Attributes Over-Ridden:
*     None.

*  New Attributes Defined:
*     Class (string)
*        This is a read-only attribute containing the name of the
*        class to which an Object belongs.
*     ID (string)
*        An identification string which may be used to identify the
*        Object (e.g.) in debugging output, or when stored in an
*        external medium such as a data file. There is no restriction
*        on the string's contents. The default is an empty string.
*     Ident (string)
*        Like ID, this is an identification string which may be used 
*        to identify the Object. Unlike ID, Ident is transferred when an
*        Object is copied.
*     UseDefs (int)
*        Should default values be used for unset attributes?
*     Nobject (integer)
*        This is a read-only attribute which gives the total number of
*        Objects currently in existence in the same class as the
*        Object given. It does not include Objects which belong to
*        derived (more specialised) classes. This value is mainly
*        intended for debugging, as it can be used to show whether
*        Objects which should have been deleted have, in fact, been
*        deleted.
*     ObjSize (int)
*        The in-memory size of the Object in bytes.
*     RefCount (integer)
*        This is a read-only Attribute which gives the "reference
*        count" (the number of active pointers) associated with an
*        Object. It is modified whenever pointers are created or
*        annulled (by astClone or astAnnul/astEnd for example) and
*        includes the initial pointer issued when the Object was
*        created. If the reference count for an Object falls to zero
*        as the result of annulling a pointer to it, then the Object
*        will be deleted.

*  Methods Over-Ridden:
*     None.

*  New Methods Defined:
*     Public:
*        astAnnul
*           Annul a pointer to an Object.
*        astClear
*           Clear attribute values for an Object.
*        astClone
*           Clone a pointer to an Object.
*        astCopy
*           Copy an Object.
*        astDelete
*           Delete an Object.
*        astExempt
*           Exempt an Object pointer from AST context handling
*        astExport
*           Export an Object pointer to an outer context.
*        astGet<X>, where <X> = C, D, F, I, L
*           Get an attribute value for an Object.
*        astSet
*           Set attribute values for an Object.
*        astSet<X>, where <X> = C, D, F, I, L
*           Set an attribute value for an Object.
*        astShow
*           Display a textual representation of an Object on standard output.
*        astTest
*           Test if an attribute value is set for an Object.
*        astTune
*           Get or set the value of a global AST tuning parameter.
*
*     Protected:
*        astAnnulId
*           Annul an external ID for an Object (for use from protected code
*           which must handle external IDs).
*        astClearAttrib
*           Clear the value of a specified attribute for an Object.
*        astClearID
*           Clear the value of the ID attribute for an Object.
*        astClearIdent
*           Clear the value of the Ident attribute for an Object.
*        astCast
*           Return a deep copy of an object, cast into an instance of a
*           parent class.
*        astDump
*           Write an Object to a Channel.
*        astEqual
*           Are two Objects equivalent?
*        astGetAttrib
*           Get the value of a specified attribute for an Object.
*        astGetClass (deprecated synonym astClass)
*           Obtain the value of the Class attribute for an Object.
*        astGetID
*           Obtain the value of the ID attribute for an Object.
*        astGetIdent
*           Obtain the value of the Ident attribute for an Object.
*        astGetNobject
*           Obtain the value of the Nobject attribute for an Object.
*        astGetRefCount
*           Obtain the value of the RefCount attribute for an Object.
*        astSetAttrib
*           Set the value of a specified attribute for an Object.
*        astSetCopy
*           Declare a copy constructor for an Object.
*        astSetDelete
*           Declare a destructor for an Object.
*        astSetDump
*           Declare a dump function for an Object.
*        astSetVtab
*           Chaneg the virtual function table associated with an Object.
*        astSetID
*           Set the value of the ID attribute for an Object.
*        astSetIdent
*           Set the value of the Ident attribute for an Object.
*        astTestAttrib
*           Test if a specified attribute value is set for an Object.
*        astTestID
*           Test whether the ID attribute for an Object is set.
*        astTestIdent
*           Test whether the Ident attribute for an Object is set.
*        astVSet
*           Set values for an Object's attributes.

*  Other Class Functions:
*     Public:
*        astBegin
*           Begin a new AST context.
*        astEnd
*           End an AST context.
*        astIsAObject
*           Test class membership.
*        astVersion
*           Returns the AST library version number.
*        astEscapes
*           Remove escape sequences from returned text strings?
*        astP2I
*           Retrieve an int from a pointer.
*        astI2P
*           Pack an int into a pointer.
*
*     Protected:
*        astCheckObject
*           Validate class membership.
*        astInitObject
*           Initialise an Object.
*        astInitObjectVtab
*           Initialise the virtual function table for the Object class.
*        astLoadObject
*           Load an Object.
*        astMakeId
*           Issue an identifier for an Object.
*        astMakePointer
*           Obtain a true C pointer from an Object identifier.

*  Macros:
*     Public:
*        AST__NULL
*           Null Object pointer value.
*        AST__VMAJOR
*           The AST library major version number.
*        AST__VMINOR
*           The AST library minor version number.
*        AST__RELEASE 
*           The AST library release number.
*
*     Protected:
*        astEQUAL
*           Compare two doubles for equality.
*        astMAX
*           Return maximum of two values.
*        astMIN
*           Return minimum of two values.
*        astMAKE_CHECK
*           Implement the astCheck<Class>_ function for a class.
*        astMAKE_CLEAR
*           Implement a method to clear an attribute value for a class.
*        astMAKE_GET
*           Implement a method to get an attribute value for a class.
*        astMAKE_ISA
*           Implement the astIsA<Class>_ function for a class.
*        astMAKE_SET
*           Implement a method to set an attribute value for a class.
*        astMAKE_TEST
*           Implement a method to test if an attribute has been set for a
*           class.
*        astMEMBER
*           Locate a member function.

*  Type Definitions:
*     Public:
*        AstObject
*           Object type.
*
*     Protected:
*        AstObjectVtab
*           Object virtual function table type.

*  Feature Test Macros:
*     AST_CHECK_CLASS
*        If the AST_CHECK_CLASS macro is defined, then Object class
*        checking is enabled for all internal function invocations
*        within the AST library. Otherwise, this checking is
*        omitted. This macro should normally be defined as a compiler
*        option during library development and debugging, but left
*        undefined for software releases, so as to improve
*        peformance. Class checking by the AST public interface is not
*        affected by this macro.
*     astCLASS
*        If the astCLASS macro is undefined, only public symbols are
*        made available, otherwise protected symbols (for use in other
*        class implementations) are defined. This macro also affects
*        the reporting of error context information, which is only
*        provided for external calls to the AST library.
*     astFORTRAN77
*        If the astFORTRAN77 macro is defined, reporting of error
*        context information is suppressed. This is necessary when
*        implementing foreign language interfaces to the AST library, as
*        otherwise the file names and line numbers given would refer
*        to the interface implementation rather than the user's own
*        code.

*  Copyright:
*     Copyright (C) 1997-2006 Council for the Central Laboratory of the
*     Research Councils

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public Licence as
*     published by the Free Software Foundation; either version 2 of
*     the Licence, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public Licence for more details.
*     
*     You should have received a copy of the GNU General Public Licence
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (Starlink)
*     DSB: David S. Berry (Starlink)

*  History:
*     30-JAN-1996 (RFWS):
*        Original version.
*     19-APR-1996 (RFWS):
*        Added macros for implementing attribute access methods.
*     3-JUL-1996 (RFWS):
*        Added new definitions to support the external interface.
*     10-SEP-1996 (RFWS):
*        Added loader and related facilities.
*     30-MAY-1997 (RFWS):
*        Add the ID attribute.
*     14-JUL-1997 (RFWS):
*        Add astExempt function.
*     20-JAN-1998 (RFWS):
*        Make the astClear and astVSet methods virtual.
*     15-SEP-1999 (RFWS):
*        Made the astAnnulId function accessible to protected code.
*     3-APR-2001 (DSB):
*        Added Ident attribute.
*     8-JAN-2003 (DSB):
*        Added protected astInitObjectVtab method.
*     30-APR-2003 (DSB):
*        Added macros AST__VMAJOR, AST__VMINOR and AST__RELEASE.
*        Added astVersion function.
*     7-FEB-2004 (DSB):
*        Added astEscapes function.
*     11-MAR-2005 (DSB):
*        Added UseDefs attribute.
*     7-FEB-2006 (DSB):
*        Added astTune function.
*     14-FEB-2006 (DSB):
*        Added ObjSize attribute.
*     23-FEB-2006 (DSB):
*        Moved AST__TUNULL from this file to memory.h.
*     10-MAY-2006 (DSB):
*        Added astEQUAL, astMAX and astMIN.
*     26-MAY-2006 (DSB):
*        Make all system includes unconditional, so that makeh is not
*        confused when creating ast.h.
*     22-JUN-2007 (DSB):
*        - Make astVSet return a pointer to dynamic memory holding the 
*        expanded setting string.
*        - Add ast astSetVtab and astCast.
*--
*/

/* Include files. */
/* ============== */
/* Configuration results. */
/* ---------------------- */
#include <config.h>

/* Interface definitions. */
/* ---------------------- */
#include "error.h"               /* Error reporting facilities */
#include "version.h"             /* Version number macros */

/* C header files. */
/* --------------- */
#include <stddef.h>
#include <stdarg.h>
#include <float.h>
#include <stdio.h>

/* Macros. */
/* ======= */

/*
*+
*  Name:
*     astINVOKE

*  Type:
*     Protected macro.

*  Purpose:
*     Invoke an AST function.

*  Synopsis:
*     #include "object.h"
*     astINVOKE(rettype,function)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     This macro expands to an invocation of an AST function, together
*     with any additional actions required to support it.  The actual
*     expansion depends on whether the macro is expanded in internal
*     code (astCLASS defined) or external code (astCLASS undefined)
*     and it therefore hides the differences between these two
*     interfaces.

*  Parameters:
*     rettype
*        A character to indicate the type of result returned by the function:
*
*        V
*           The function returns a value (including void or a pointer
*           value, but excluding an Object pointer). astINVOKE will
*           return the value unchanged.
*        O
*           The function returns an Object pointer. astINVOKE will
*           convert it to an Object identifier if necessary.
*        F
*           The function returns a function pointer. astINVOKE will
*           return it unchanged. This is typically used when the
*           function has a variable argument list. In this case the
*           function name is passed to astINVOKE without its argument
*           list and a pointer to the function is returned which can
*           then be supplied with an argument list. This avoids the
*           need to define a macro with a variable number of arguments
*           (which isn't allowed).
*     function
*        A normal invocation of the function returning the required
*        result.  In the case of a variable argument list, the
*        argument list should be omitted so that the function is not
*        invoked but a function pointer is returned that may then be
*        used to invoke it.

*  Examples:
*     #define astGetNobject(this) \
*             astINVOKE(V,astGetNobject_(astCheckObject(this)))
*        Defines a macro to invoke the astGetNobject_ function which
*        returns an int.
*     #define astClone(this) \
*             astINVOKE(O,astClone_(astCheckObject(this)))
*        Defines a macro to invoke the astClone_ function which
*        returns an Object pointer.
*     #define astSet astINVOKE(F,astSet_)
*        Defines a macro to invoke the astSet_ function which has a
*        variable argument list and returns void. The macro result is
*        a pointer to the astSet_ function. This function must perform
*        its own argument validation, as (e.g) astCheckObject cannot
*        be invoked on its arguments via a macro.

*  Notes:
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

/* Define astINVOKE, which records the current file and line number
   (in case of error) using astAt, and then invokes the function
   supplied as an argument of the astRetV_, astRetO_ or astRetF_
   macro.

   Suppress reporting of the file and line number from internal code
   and from foreign language interfaces by not using astAt in these
   cases. */
#if defined(astCLASS) || defined(astFORTRAN77)
#define astINVOKE(rettype,function) astRet##rettype##_(function)
#else
#define astINVOKE(rettype,function) \
astERROR_INVOKE(astRet##rettype##_(function))
#endif

/* astRetF_ and astRetV_ currently do nothing. */
#define astRetF_(x) (x)
#define astRetV_(x) (x)

/* However, astRetO_ converts a pointer to an ID if necessary. */
#if defined(astCLASS)
#define astRetO_(x) ((void *)(x))
#else
#define astRetO_(x) ((void *)astMakeId_((AstObject *)(x)))
#endif

/*
*+
*  Name:
*     astINVOKE_CHECK
*     astINVOKE_ISA

*  Type:
*     Protected macros.

*  Purpose:
*     Invoke the astCheck<Class>_ and astIsA<Class>_ functions.

*  Synopsis:
*     #include "object.h"
*     astINVOKE_CHECK(class,this)
*     astINVOKE_ISA(class,this)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     These macros expand to invocations of the standard
*     astCheck<Class>_ and astIsA<Class>_ functions for a class.

*  Parameters:
*     class
*        The name (not the type) of the class for which the function
*        is to be invoked.
*     this
*        The "this" argument (the Object pointer) to be passed to the
*        function.

*  Notes:
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

/* For the public interface (and also internally if AST_CHECK_CLASS is
   defined), define astINVOKE_CHECK to invoke the astCheck<Class>
   function. */
#if !defined(astCLASS) || defined(AST_CHECK_CLASS)
#define astINVOKE_CHECK(class,this) \
astCheck##class##_((Ast##class *)astEnsurePointer_(this))

/* For the internal interface, astINVOKE_CHECK omits the
   astCheck<class> function (unless AST_CHECK_CLASS is defined). */
#else
#define astINVOKE_CHECK(class,this) ((Ast##class *)astEnsurePointer_(this))
#endif

/* Define astINVOKE_ISA to invoke the astIsA<Class> function. */
#if defined(astCLASS)            /* Protected */
#define astINVOKE_ISA(class,this) \
astIsA##class##_((const Ast##class *)(this))
#else                            /* Public */
#define astINVOKE_ISA(class,this) \
astINVOKE(V,astIsA##class##_((const Ast##class *)astEnsurePointer_(this)))
#endif

/* The astEnsurePointer_ macro ensures a true C pointer, converting
   from an ID if necessary. */
#if defined(astCLASS)            /* Protected */
#define astEnsurePointer_(x) ((void *)(x))
#else                            /* Public */
#define astEnsurePointer_(x) ((void *)astMakePointer_((AstObject *)(x)))
#endif

#if defined(astCLASS)            /* Protected */
/*
*+
*  Name:
*     astMAKE_CHECK

*  Type:
*     Protected macro.

*  Purpose:
*     Implement the astCheck<Class>_ function for a class.

*  Synopsis:
*     #include "object.h"
*     astMAKE_CHECK(class)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     This macro expands to an implementation of the public astCheck<Class>_
*     function (q.v.) which validates membership of a specified class.

*  Parameters:
*     class
*        The name (not the type) of the class whose membership is to be
*        validated.

*  Notes:
*     -  This macro is provided so that class definitions can easiy
*     implement the astCheck<Class>_ function, which is essentially the same
*     for each class apart for a change of name.
*     -  To avoid problems with some compilers, you should not leave any white
*     space around the macro arguments.
*-
*/

#ifndef MEM_DEBUG

/* Define the macro. */
#define astMAKE_CHECK(class) \
\
/* Declare the function (see the object.c file for a prologue). */ \
Ast##class *astCheck##class##_( Ast##class *this ) { \
\
/* Check the global error status. */ \
   if ( !astOK ) return this; \
\
/* Check if the object is a class member. */ \
   if ( !astIsA##class( this ) ) { \
\
/* If not, but the pointer was valid (which means it identifies an Object \
   of some sort), then report more information about why this Object is \
   unsuitable. */ \
      if ( astOK ) { \
         astError( AST__OBJIN, "Pointer to " #class " required, but pointer " \
                   "to %s given.", astGetClass( this ) ); \
      } \
   } \
\
/* Return the pointer value supplied. */ \
   return this; \
}

/* Define the macro with memory debugging facilities. */
#else

#define astMAKE_CHECK(class) \
\
/* Declare the function (see the object.c file for a prologue). */ \
Ast##class *astCheck##class##_( Ast##class *this ) { \
\
   char buf[100]; \
\
/* Check the global error status. */ \
   if ( !astOK ) return this; \
\
/* Check if the object is a class member. */ \
   if ( !astIsA##class( this ) ) { \
\
/* If not, but the pointer was valid (which means it identifies an Object \
   of some sort), then report more information about why this Object is \
   unsuitable. */ \
      if ( astOK ) { \
         astError( AST__OBJIN, "Pointer to " #class " required, but pointer " \
                   "to %s given.", astGetClass( this ) ); \
      }\
\
   } else { \
\
/* Call the astMemoryUse function to report it if the memory block is \
   being watched. */ \
      sprintf( buf, "checked (refcnt: %d)", astGetRefCount_( (AstObject *) this ) ); \
      astMemoryUse( this, buf ); \
   } \
\
/* Return the pointer value supplied. */ \
   return this; \
}
#endif
#endif

#if defined(astCLASS)            /* Protected */
/*
*+
*  Name:
*     astMAKE_CLEAR

*  Purpose:
*     Implement a method to clear an attribute value for a class.

*  Type:
*     Protected macro.

*  Synopsis:
*     #include "object.h"
*     astMAKE_CLEAR(class,attribute,component,assign)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     This macro expands to an implementation of a private member function of
*     the form:
*
*        static void Clear<Attribute>( Ast<Class> *this )
*
*     and an external interface function of the form:
*
*        void astClear<Attribute>_( Ast<Class> *this )
*
*     which implement a method for clearing a specified attribute value for
*     a class.

*  Parameters:
*     class
*        The name (not the type) of the class to which the attribute belongs.
*     attribute
*        The name of the attribute to be cleared, as it appears in the function
*        name (e.g. Label in "astClearLabel").
*     component
*        The name of the class structure component that holds the attribute
*        value.
*     assign
*        An expression that evaluates to the value to assign to the component
*        to clear its value.

*  Examples:
*     astMAKE_CLEAR(MyStuff,Flag,flag,-1)
*        Implements the astClearFlag method for the MyStuff class which
*        operates by setting the "flag" structure component to -1 to indicate
*        that it has no value.

*  Notes:
*     -  To avoid problems with some compilers, you should not leave any white
*     space around the macro arguments.
*-
*/

/* Define the macro. */
#define astMAKE_CLEAR(class,attribute,component,assign) \
\
/* Private member function. */ \
/* ------------------------ */ \
static void Clear##attribute( Ast##class *this ) { \
\
/* Check the global error status. */ \
   if ( !astOK ) return; \
\
/* Assign the "clear" value. */ \
   this->component = (assign); \
} \
\
/* External interface. */ \
/* ------------------- */ \
void astClear##attribute##_( Ast##class *this ) { \
\
/* Check the global error status. */ \
   if ( !astOK ) return; \
\
/* Invoke the required method via the virtual function table. */ \
   (**astMEMBER(this,class,Clear##attribute))( this ); \
}   
#endif

#if defined(astCLASS)            /* Protected */
/*
*+
*  Name:
*     astMAKE_GET

*  Purpose:
*     Implement a method to get an attribute value for a class.

*  Type:
*     Protected macro.

*  Synopsis:
*     #include "object.h"
*     astMAKE_GET(class,attribute,type,bad_value,assign)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     This macro expands to an implementation of a private member function of
*     the form:
*
*        static <Type> Get<Attribute>( Ast<Class> *this )
*
*     and an external interface function of the form:
*
*        <Type> astGet<Attribute>_( Ast<Class> *this )
*
*     which implement a method for getting a specified attribute value for a
*     class.

*  Parameters:
*     class
*        The name (not the type) of the class to which the attribute belongs.
*     attribute
*        The name of the attribute whose value is to be obtained, as it
*        appears in the function name (e.g. Label in "astGetLabel").
*     type
*        The C type of the attribute.
*     bad_value
*        A constant value to return if the global error status is set, or if
*        the function fails.
*     assign
*        An expression that evaluates to the value to be returned.

*  Examples:
*     astMAKE_GET(MyStuff,Flag,int,0,( this->flag == 1 ))
*        Implements the astGetFlag method for the MyStuff class which operates
*        by examining the integer "flag" structure component and comparing it
*        with the value 1 to see if it is set. A value of 0 is returned if the
*        method fails to complete successfully.

*  Notes:
*     -  To avoid problems with some compilers, you should not leave any white
*     space around the macro arguments.
*-
*/

/* Define the macro. */
#define astMAKE_GET(class,attribute,type,bad_value,assign) \
\
/* Private member function. */ \
/* ------------------------ */ \
static type Get##attribute( Ast##class *this ) { \
   type result;                  /* Result to be returned */ \
\
/* Check the global error status. */ \
   if ( !astOK ) return (bad_value); \
\
/* Assign the result value. */ \
   result = (assign); \
\
/* Check for errors and clear the result if necessary. */ \
   if ( !astOK ) result = (bad_value); \
\
/* Return the result. */ \
   return result; \
} \
/* External interface. */ \
/* ------------------- */  \
type astGet##attribute##_( Ast##class *this ) { \
\
/* Check the global error status. */ \
   if ( !astOK ) return (bad_value); \
\
/* Invoke the required method via the virtual function table. */ \
   return (**astMEMBER(this,class,Get##attribute))( this ); \
}
#endif

#if defined(astCLASS)            /* Protected */
/*
*+
*  Name:
*     astMAKE_ISA

*  Type:
*     Protected macro.

*  Purpose:
*     Implement the astIsA<Class>_ function for a class.

*  Synopsis:
*     #include "object.h"
*     astMAKE_ISA(class)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     This macro expands to an implementation of the public
*     astIsA<Class>_ function (q.v.) which checks membership of a
*     specified class.

*  Parameters:
*     class
*        The name (not the type) of the class whose membership is to be
*        tested.
*     parent
*        The name of the parent class.
*     check
*        The name of the component in the class virtual function table
*        which holds the "magic number" that uniquely identifies the
*        class. Normally this is called "check".
*     magic
*        The value of the "magic number" (may be an expression).

*  Notes:
*     - This macro is provided so that class definitions can easiy
*     implement the astIsA<Class>_ function, which is essentially the
*     same for each class apart for a change of name.
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

/* Define the macro. */
#define astMAKE_ISA(class,parent,check,magic) \
\
/* Declare the function (see the object.c file for a prologue). */ \
int astIsA##class##_( const Ast##class *this ) { \
\
/* Local Variables: */ \
   int isa = 0;                  /* Is object a member? */ \
\
/* To test if the object is correctly constructed, we first test if it is a \
   member of the parent class. This improves the security of the test by \
   checking the object structure from the base Object class downwards \
   (without this, the "magic numbers" that identify classes might be \
   encountered by accident or we might address parts of the Object which \
   don't exist). */ \
   if ( astIsA##parent( this ) ) { \
\
/* Obtain the Object's size and check it is adequate for an object of the \
   proposed type (this avoids any attempt to access derived class data that \
   doesn't exist and therefore lies outside the memory allocated for the \
   object). */ \
      if ( ( (AstObject *) this )->size >= sizeof( Ast##class ) ) { \
\
/* If OK, see whether the check component in the object's virtual function \
   table matches the expected "magic" value. */ \
         isa = ( *astMEMBER(this,class,check) == (magic) ); \
      } \
   } \
\
/* Return the result. */ \
   return isa; \
}
#endif

#if defined(astCLASS)            /* Protected */
/*
*+
*  Name:
*     astMAKE_SET

*  Purpose:
*     Implement a method to set an attribute value for a class.

*  Type:
*     Protected macro.

*  Synopsis:
*     #include "object.h"
*     astMAKE_SET(class,attribute,type,component,assign)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     This macro expands to an implementation of a private member function of
*     the form:
*
*        static void Set<Attribute>( Ast<Class> *this, <Type> value )
*
*     and an external interface function of the form:
*
*        void astSet<Attribute>_( Ast<Class> *this, <Type> value )
*
*     which implement a method for setting a specified attribute value for a
*     class.

*  Parameters:
*      class
*         The name (not the type) of the class to which the attribute belongs.
*      attribute
*         The name of the attribute to be set, as it appears in the function
*         name (e.g. Label in "astSetLabel").
*      type
*         The C type of the attribute.
*      component
*         The name of the class structure component that holds the attribute
*         value.
*      assign
*         An expression that evaluates to the value to be assigned to the
*         component.

*  Examples:
*     astMAKE_SET(MyStuff,Flag,int,flag,( value != 0 ))
*        Implements the astSetFlag method for the MyStuff class which operates
*        by setting the "flag" structure component to 0 or 1 depending on
*        whether the "value" parameter is non-zero or not.

*  Notes:
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

/* Define the macro. */
#define astMAKE_SET(class,attribute,type,component,assign) \
\
/* Private member function. */ \
/* ------------------------ */ \
static void Set##attribute( Ast##class *this, type value ) { \
\
/* Check the global error status. */ \
   if ( !astOK ) return; \
\
/* Store the new value in the structure component. */ \
   this->component = (assign); \
} \
\
/* External interface. */ \
/* ------------------- */ \
void astSet##attribute##_( Ast##class *this, type value ) { \
\
/* Check the global error status. */ \
   if ( !astOK ) return; \
\
/* Invoke the required method via the virtual function table. */ \
   (**astMEMBER(this,class,Set##attribute))( this, value ); \
}
#endif

#if defined(astCLASS)            /* Protected */
/*
*+
*  Name:
*     astMAKE_TEST

*  Purpose:
*     Implement a method to test if an attribute has been set for a class.

*  Type:
*     Protected macro.

*  Synopsis:
*     #include "object.h"
*     astMAKE_TEST(class,attribute,assign)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     This macro expands to an implementation of a private member function of
*     the form:
*
*        static int Test<Attribute>( Ast<Class> *this )
*
*     and an external interface function of the form:
*
*        int astTest<Attribute>_( Ast<Class> *this )
*
*     which implement a method for testing if a specified attribute has been
*     set for a class.

*  Parameters:
*      class
*         The name (not the type) of the class to which the attribute belongs.
*      attribute
*         The name of the attribute to be tested, as it appears in the function
*         name (e.g. Label in "astTestLabel").
*      assign
*         An expression that evaluates to 0 or 1, to be used as the returned
*         value.

*  Examples:
*     astMAKE_TEST(MyStuff,Flag,( this->flag != -1 ))
*        Implements the astTestFlag method for the MyStuff class which operates
*        by testing the "flag" structure component to see if it is set to a
*        value other than -1.

*  Notes:
*     -  To avoid problems with some compilers, you should not leave any white
*     space around the macro arguments.
*-
*/

/* Define the macro. */
#define astMAKE_TEST(class,attribute,assign) \
\
/* Private member function. */ \
/* ------------------------ */ \
static int Test##attribute( Ast##class *this ) { \
   int result;                   /* Value to return */ \
\
/* Check the global error status. */ \
   if ( !astOK ) return 0; \
\
/* Assign the result value. */ \
   result = (assign); \
\
/* Check for errors and clear the result if necessary. */ \
   if ( !astOK ) result = 0; \
\
/* Return the result. */ \
   return result; \
} \
/* External interface. */ \
/* ------------------- */ \
int astTest##attribute##_( Ast##class *this ) { \
\
/* Check the global error status. */ \
   if ( !astOK ) return 0; \
\
/* Invoke the required method via the virtual function table. */ \
   return (**astMEMBER(this,class,Test##attribute))( this ); \
}
#endif

#if defined(astCLASS)            /* Protected */
/*
*+
*  Name:
*     astMEMBER

*  Purpose:
*     Locate a member function.

*  Type:
*     Protected macro.

*  Synopsis:
*     #include "object.h"
*     astMEMBER(this,class,method)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     This macro evaluates to the address where the pointer to a
*     specified Object member function is stored. Typically, this will
*     be used to obtain a pointer to the member function so that it
*     can be invoked. It may also be used to assign a new function
*     pointer so that a derived class can re-define a virtual function
*     and hence over-ride an inherited method.

*  Parameters:
*     this
*        Pointer to an Object belonging to the class for which the
*        virtual function is required. This must either be the class
*        that originally defined the method, or one derived from it.
*     class
*        Name of the class that originally defined the method. This
*        may differ from (i.e. be an ancestor of) the class to which
*        "this" belongs.
*     method
*        Name of the method whose member function is to be located.

*  Returned Value:
*     The address where the member function pointer is stored (the
*     type of the result is determined by the type of the member
*     function itself).

*  Examples:
*     astMEMBER(this,Gnome,astFish)
*        Returns the address where the pointer to the function that
*        implements the astFish method for the "this" object is
*        stored. The Gnome class should be where the astFish method
*        was first defined (i.e. from where it was inherited by
*        "this").
*     (**astMEMBER(this,Gnome,astFish))( this, arg1, arg2 );
*        Invokes the virtual function that implements the astFish
*        method for object "this" and passes it additional arguments
*        "arg2" and "arg2".  Again, Gnome should be the class that
*        originally defined the astFish method.
*     *astMEMBER(this,Gnome,astFish) = myFish;
*        Stores a pointer to the myFish function so that it replaces
*        the virtual function that previously implemented the astFish
*        method for the "this" object. Note that all objects in the
*        same class as "this" are affected, but objects in class
*        "class" are not affected (unless it happens to be the class
*        to which "this" belongs).

*  Notes:
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

/* Define the macro. This functions by (a) casting the Object pointer
   to type (AstObject *) and locating the Object's virtual function
   table (b) casting the table pointer to the correct type
   (AstClassVtab *) for the class in which the method pointer resides,
   (c) locating the component holding the member function pointer, and
   (d) taking its address. */
#define astMEMBER(this,class,method) \
(&((Ast##class##Vtab*)((AstObject*)(this))->vtab)->method)
#endif

/*
*+
*  Name:
*     astPROTO_CHECK
*     astPROTO_ISA

*  Type:
*     Protected macros.

*  Purpose:
*     Prototype the astCheck<Class>_ and astIsA<Class>_ functions.

*  Synopsis:
*     #include "object.h"
*     astPROTO_CHECK(class)
*     astPROTO_ISA(class)

*  Class Membership:
*     Defined by the Object class.

*  Description:
*     These macros expands to function prototypes for the
*     astCheck<Class>_ and astIsA<Class>_ functions (q.v.) which
*     validate and test for membership of a specified class.

*  Parameters:
*     class
*        The name (not the type) of the class whose membership is to
*        be validated.

*  Notes:
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

/* Define the macros. */
#define astPROTO_CHECK(class) Ast##class *astCheck##class##_( Ast##class * );
#define astPROTO_ISA(class) int astIsA##class##_( const Ast##class * );

/* Macros which return the maximum and minimum of two values. */
#define astMAX(aa,bb) ((aa)>(bb)?(aa):(bb))
#define astMIN(aa,bb) ((aa)<(bb)?(aa):(bb))

/* Check for equality of floating point values. We cannot compare bad values 
   directly because of the danger of floating point exceptions, so bad 
   values are dealt with explicitly. */
#define astEQUAL(aa,bb) (((aa)==AST__BAD)?(((bb)==AST__BAD)?1:0):(((bb)==AST__BAD)?0:(fabs((aa)-(bb))<=1.0E5*astMAX((fabs(aa)+fabs(bb))*DBL_EPSILON,DBL_MIN))))

/* AST__NULL. */
/* ---------- */
/* Define the AST__NULL macro, which evaluates to a null Object
   pointer. */
#define AST__NULL (astI2P(0))


/* Type Definitions. */
/* ================= */

/* Object structure. */
/* ----------------- */
/* This structure contains all information that is unique to each object in
   the class (e.g. its instance variables). */
typedef struct AstObject {

/* Attributes specific to objects in this class. */
   unsigned long check;          /* Check value to identify Objects */
   size_t size;                  /* Amount of memory used by Object */
   struct AstObjectVtab *vtab;   /* Pointer to virtual function table */
   char dynamic;                 /* Memory allocated dynamically? */
   int ref_count;                /* Number of active pointers to the Object */
   char *id;                     /* Pointer to ID string */
   char *ident;                  /* Pointer to Ident string */
   char usedefs;                 /* Use default attribute values? */
} AstObject;

/* Virtual function table. */
/* ----------------------- */
/* The virtual function table makes a forward reference to the
   AstChannel structure which is not defined until "channel.h" is
   included (below). Hence make a preliminary definition available
   now. */
struct AstChannel;

/* This table contains all information that is the same for all
   objects in the class (e.g. pointers to its virtual functions). */
#if defined(astCLASS)            /* Protected */
typedef struct AstObjectVtab {

/* Properties specific to this class. */
   const char *( *GetID )( AstObject * );
   const char *( *GetIdent )( AstObject * );
   const char *(* GetAttrib)( AstObject *, const char * );
   int (* TestAttrib)( AstObject *, const char * );
   int (* TestID)( AstObject * );
   int (* TestIdent)( AstObject * );
   void (* Clear)( AstObject *, const char * );
   void (* ClearAttrib)( AstObject *, const char * );
   void (* ClearID)( AstObject * );
   void (* ClearIdent)( AstObject * );
   void (* Dump)( AstObject *, struct AstChannel * );
   int (* Equal)( AstObject *, AstObject * );
   void (* SetAttrib)( AstObject *, const char * );
   void (* SetID)( AstObject *, const char * );
   void (* SetIdent)( AstObject *, const char * );
   void (* Show)( AstObject * );
   void (* VSet)( AstObject *, const char *, char **, va_list );

   int (* GetObjSize)( AstObject * );

   int (* TestUseDefs)( AstObject * );
   int (* GetUseDefs)( AstObject * );
   void (* SetUseDefs)( AstObject *, int );
   void (* ClearUseDefs)( AstObject * );

   const char *class;            /* Pointer to class name string */
   void (** delete)( AstObject * ); /* Pointer to array of destructors */
   void (** copy)( const AstObject *, AstObject * ); /* Copy constructors */
   void (** dump)( AstObject *, struct AstChannel * ); /* Dump functions */
   const char **dump_class;      /* Dump function class string pointers */
   const char **dump_comment;    /* Dump function comment string pointers */
   int ndelete;                  /* Number of destructors */
   int ncopy;                    /* Number of copy constructors */
   int ndump;                    /* Number of dump functions */
   int nobject;                  /* Number of active objects in the class */
   int nfree;                    /* No. of entries in "free_list" */
   AstObject **free_list;        /* List of pointers for freed Objects */
} AstObjectVtab;
#endif

/* More include files. */
/* =================== */
/* The interface to the Channel class must be included here (after the
   type definitions for the Object class) because "channel.h" itself
   includes this file ("object.h"), although "object.h" refers to the
   AstChannel structure above. This seems a little strange at first,
   but is simply analogous to making a forward reference to a
   structure type when recursively defining a normal C structure
   (except that here the definitions happen to be in separate include
   files). */
#include "channel.h"

/* Function prototypes. */
/* ==================== */
/* Prototypes for standard class functions. */
/* ---------------------------------------- */
astPROTO_CHECK(Object)           /* Validate class membership */
astPROTO_ISA(Object)             /* Test class membership */

/* NB. There is no constructor function for this class. */

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
AstObject *astInitObject_( void *, size_t, int, AstObjectVtab *,
                           const char * );

/* Vtab Initialiser. */
void astInitObjectVtab_( AstObjectVtab *, const char * );

/* Loader. */
AstObject *astLoadObject_( void *, size_t, AstObjectVtab *,
                           const char *, AstChannel *channel );
#endif

/* Prototypes for other class functions. */
/* ------------------------------------- */
#if !defined(astCLASS)           /* Public */
void astBegin_( void );
void astEnd_( void );
#endif

AstObject *astI2P_( int );
AstObject *astMakeId_( AstObject * );
AstObject *astMakePointer_( AstObject * );
int astP2I_( AstObject * );
int astVersion_( void );
int astEscapes_( int );
int astTune_( const char *, int );

/* Prototypes for member functions. */
/* -------------------------------- */
#if defined(astCLASS)            /* Protected */
AstObject *astAnnul_( AstObject * );
AstObject *astDelete_( AstObject * );
void astSet_( void *, const char *, ... );

#else                            /* Public */
AstObject *astDeleteId_( AstObject * );
void astExemptId_( AstObject * );
void astExportId_( AstObject * );
void astSetId_( void *, const char *, ... );
#endif

AstObject *astAnnulId_( AstObject * );
AstObject *astClone_( AstObject * );
AstObject *astCopy_( const AstObject * );
const char *astGetC_( AstObject *, const char * );
double astGetD_( AstObject *, const char * );
float astGetF_( AstObject *, const char * );
int astGetI_( AstObject *, const char * );
int astTest_( AstObject *, const char * );
long astGetL_( AstObject *, const char * );
void astClear_( AstObject *, const char * );
void astSetC_( AstObject *, const char *, const char * );
void astSetD_( AstObject *, const char *, double );
void astSetF_( AstObject *, const char *, float );
void astSetI_( AstObject *, const char *, int );
void astSetL_( AstObject *, const char *, long );
void astShow_( AstObject * );

#if defined(astCLASS)            /* Protected */

AstObject *astCast_( AstObject *, AstObject * );

int astGetObjSize_( AstObject * );

int astTestUseDefs_( AstObject * );
int astGetUseDefs_( AstObject * );
void astSetUseDefs_( AstObject *, int );
void astClearUseDefs_( AstObject * );

const char *astGetAttrib_( AstObject *, const char * );
const char *astGetClass_( const AstObject * );
const char *astGetID_( AstObject * );
const char *astGetIdent_( AstObject * );
int astEqual_( AstObject *, AstObject * );
int astGetNobject_( const AstObject * );
int astGetRefCount_( const AstObject * );
int astTestAttrib_( AstObject *, const char * );
int astTestID_( AstObject * );
int astTestIdent_( AstObject * );
void astClearAttrib_( AstObject *, const char * );
void astClearID_( AstObject * );
void astClearIdent_( AstObject * );
void astDump_( AstObject *, AstChannel * );
void astSetAttrib_( AstObject *, const char * );
void astSetCopy_( AstObjectVtab *, void (*)( const AstObject *, AstObject * ) );
void astSetDelete_( AstObjectVtab *, void (*)( AstObject * ) );
void astSetDump_( AstObjectVtab *, void (*)( AstObject *, AstChannel * ), const char *, const char * );
void astSetVtab_( AstObject *, AstObjectVtab * );
void astSetID_( AstObject *, const char * );
void astSetIdent_( AstObject *, const char * );
void astVSet_( AstObject *, const char *, char **, va_list );
#endif

/* Function interfaces. */
/* ==================== */
/* These macros are wrap-ups for the functions defined by this class
   to make them easier to invoke (e.g. to avoid type mis-matches when
   passing pointers to objects from derived classes). */

/* Interfaces to standard class functions. */
/* --------------------------------------- */
/* Check class membership. */
#define astCheckObject(this) astINVOKE_CHECK(Object,this)

/* Test class membership. */
#define astIsAObject(this) astINVOKE_ISA(Object,this)

/* NB. There is no constructor function for this class. */

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
#define astInitObject(mem,size,init,vtab,name) \
astINVOKE(O,astInitObject_(mem,size,init,vtab,name))

/* Vtab Initialiser. */
#define astInitObjectVtab(vtab,name) astINVOKE(V,astInitObjectVtab_(vtab,name))

/* Loader. */
#define astLoadObject(mem,size,vtab,name,channel) \
astINVOKE(O,astLoadObject_(mem,size,vtab,name,astCheckChannel(channel)))
#endif

/* Interfaces to other class functions. */
/* ------------------------------------ */
#if !defined(astCLASS)           /* Public */
#define astBegin astINVOKE(V,astBegin_())
#define astEnd astINVOKE(V,astEnd_())
#endif

#define astVersion astVersion_()
#define astEscapes(int) astEscapes_(int)
#define astTune(name,val) astTune_(name,val)
#define astI2P(integer) ((void *)astI2P_(integer))
#define astMakeId(pointer) ((void *)astMakeId_((AstObject *)(pointer)))
#define astMakePointer(id) ((void *)astMakePointer_((AstObject *)(id)))
#define astP2I(pointer) astP2I_((AstObject *)(pointer))

/* Interfaces to member functions. */
/* ------------------------------- */
/* Here we make use of astCheckObject (et al.) to validate Object
   pointers before use. This provides a contextual error report if a
   pointer to the wrong sort of object is supplied. In the case of an
   external caller, it also performs the required conversion from an
   Object identifier to a true C pointer. */

/* These functions require special treatment for external use because
   they handle Object identifiers and their resources explicitly, and
   must therefore be passed identifier values without conversion to C
   pointers. */
#if defined(astCLASS)            /* Protected */
#define astAnnul(this) astINVOKE(O,astAnnul_(astCheckObject(this)))
#define astAnnulId(this) astINVOKE(O,astAnnulId_((AstObject *)(this)))
#define astDelete(this) astINVOKE(O,astDelete_(astCheckObject(this)))
#define astSet astINVOKE(F,astSet_)

#else                            /* Public */
#define astAnnul(this) astINVOKE(O,astAnnulId_((AstObject *)(this)))
#define astDelete(this) astINVOKE(O,astDeleteId_((AstObject *)(this)))
#define astExempt(this) astINVOKE(V,astExemptId_((AstObject *)(this)))
#define astExport(this) astINVOKE(V,astExportId_((AstObject *)(this)))
#define astSet astINVOKE(F,astSetId_)
#endif

#define astClear(this,attrib) \
astINVOKE(V,astClear_(astCheckObject(this),attrib))
#define astClone(this) astINVOKE(O,astClone_(astCheckObject(this)))
#define astCopy(this) astINVOKE(O,astCopy_(astCheckObject(this)))
#define astGetC(this,attrib) \
astINVOKE(V,astGetC_(astCheckObject(this),attrib))
#define astGetD(this,attrib) \
astINVOKE(V,astGetD_(astCheckObject(this),attrib))
#define astGetF(this,attrib) \
astINVOKE(V,astGetF_(astCheckObject(this),attrib))
#define astGetI(this,attrib) \
astINVOKE(V,astGetI_(astCheckObject(this),attrib))
#define astGetL(this,attrib) \
astINVOKE(V,astGetL_(astCheckObject(this),attrib))
#define astSetC(this,attrib,value) \
astINVOKE(V,astSetC_(astCheckObject(this),attrib,value))
#define astSetD(this,attrib,value) \
astINVOKE(V,astSetD_(astCheckObject(this),attrib,value))
#define astSetF(this,attrib,value) \
astINVOKE(V,astSetF_(astCheckObject(this),attrib,value))
#define astSetI(this,attrib,value) \
astINVOKE(V,astSetI_(astCheckObject(this),attrib,value))
#define astSetL(this,attrib,value) \
astINVOKE(V,astSetL_(astCheckObject(this),attrib,value))
#define astShow(this) \
astINVOKE(V,astShow_(astCheckObject(this)))
#define astTest(this,attrib) \
astINVOKE(V,astTest_(astCheckObject(this),attrib))

#if defined(astCLASS)            /* Protected */

#define astGetObjSize(this) astINVOKE(V,astGetObjSize_(astCheckObject(this)))

#define astClearUseDefs(this) astINVOKE(V,astClearUseDefs_(astCheckObject(this)))
#define astTestUseDefs(this) astINVOKE(V,astTestUseDefs_(astCheckObject(this)))
#define astGetUseDefs(this) astINVOKE(V,astGetUseDefs_(astCheckObject(this)))
#define astSetUseDefs(this,val) astINVOKE(V,astSetUseDefs_(astCheckObject(this),val))

#define astClearAttrib(this,attrib) \
astINVOKE(V,astClearAttrib_(astCheckObject(this),attrib))
#define astClearID(this) astINVOKE(V,astClearID_(astCheckObject(this)))
#define astClearIdent(this) astINVOKE(V,astClearIdent_(astCheckObject(this)))
#define astDump(this,channel) \
astINVOKE(V,astDump_(astCheckObject(this),astCheckChannel(channel)))
#define astEqual(this,that) \
astINVOKE(V,((this==that)||astEqual_(astCheckObject(this),astCheckObject(that))))
#define astGetAttrib(this,attrib) \
astINVOKE(V,astGetAttrib_(astCheckObject(this),attrib))
#define astGetClass(this) astINVOKE(V,astGetClass_((const AstObject *)(this)))
#define astGetID(this) astINVOKE(V,astGetID_(astCheckObject(this)))
#define astGetIdent(this) astINVOKE(V,astGetIdent_(astCheckObject(this)))
#define astGetNobject(this) astINVOKE(V,astGetNobject_(astCheckObject(this)))
#define astGetRefCount(this) astINVOKE(V,astGetRefCount_(astCheckObject(this)))
#define astSetAttrib(this,setting) \
astINVOKE(V,astSetAttrib_(astCheckObject(this),setting))
#define astSetCopy(vtab,copy) \
astINVOKE(V,astSetCopy_((AstObjectVtab *)(vtab),copy))
#define astSetDelete(vtab,delete) \
astINVOKE(V,astSetDelete_((AstObjectVtab *)(vtab),delete))
#define astSetDump(vtab,dump,class,comment) \
astINVOKE(V,astSetDump_((AstObjectVtab *)(vtab),dump,class,comment))
#define astSetVtab(object,vtab) \
astINVOKE(V,astSetVtab_((AstObject *)object,(AstObjectVtab *)(vtab)))
#define astCast(this,obj) \
astINVOKE(V,astCast_((AstObject *)(this),(AstObject *)(obj)))
#define astSetID(this,id) astINVOKE(V,astSetID_(astCheckObject(this),id))
#define astSetIdent(this,id) astINVOKE(V,astSetIdent_(astCheckObject(this),id))
#define astVSet(this,settings,text,args) \
astINVOKE(V,astVSet_(astCheckObject(this),settings,text,args))
#define astTestAttrib(this,attrib) \
astINVOKE(V,astTestAttrib_(astCheckObject(this),attrib))
#define astTestID(this) astINVOKE(V,astTestID_(astCheckObject(this)))
#define astTestIdent(this) astINVOKE(V,astTestIdent_(astCheckObject(this)))

/* Deprecated synonym. */
#define astClass(this) astGetClass(this)
#endif
#endif
