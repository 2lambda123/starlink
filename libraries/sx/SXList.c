#include <stdio.h>
#include "sx.h"

#define MAX_NAMES 10
#define BUF_SIZE 256

Error m_SXList( Object *in, Object*out){
/*
*+
*  Name:
*     SXList

*  Purpose:
*     write values from a field or list to a text file

*  Language:
*     ANSI C

*  Syntax:
*     nrec = SXList( input, file, append, names );

*  Classification:
*     Import and Export

*  Description:
*     The SXList module writes numerical or string values to an output
*     text "file". The values may be obtained from a field, or they may be
*     specified explicitly as a list. Each record written to the "file"
*     contains one item from the list, or one item from each of the
*     field components specified by "names", layed out as a series of
*     columns.
*
*     It is not an error to give a null "input", but nothing will be
*     written to the file.
*    
*     If no value is supplied for "file" then the list will be displayed 
*     in the message window.
*
*     If "append" is set to 1, the output will be appended to any
*     existing "file" with the given name. A new file will be created if
*     none exists. If "append" is set to 0, a new file is created every
*     time, potentially over-writing an existing file.

*  Parameters:
*     input = field or value or value list or string or string list (Given)
*        input field or list [none]
*     file = string (Given)
*        name of the text file [(Message Window)]
*     append = integer (Given)
*        1 to append to existing file, 0 to create new file [0]
*     names = string or string list (Given)
*        the field components to list ["data"]
*     nrec = integer (Returned)
*        the number of records written to the file

*  Examples:
*     In this example, the "data" and "positions" components from a field are
*     written out to a text file called "dump.dat". The file starts with a 
*     header containing 3 comment lines:
*
*        input = Import("/usr/lpp/dx/samples/data/CO2.general");
*        frame17 = Select(input,17);
*        SXList({"#","# Positions and data","#"},"dump.dat",0);
*        SXList(frame17,"dump.dat",1,{"positions","data"});

*  Returned Value:
*     OK, unless an error occurs in which case ERROR is returned and the
*     DX error code is set.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     12-SEP-1995 (DSB):
*        Original version
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

/*  Local Variables. */

      int     append;
      Array   array;
      char    buf[BUF_SIZE];
      char   *c;
      Category cat;
      char    cr='\n';
      int     el;
      FILE   *fd;
      char   *file;
      int     i;
      int     j;
      int     len;
      int     n;
      int     nel[MAX_NAMES];
      char   *name;
      int     ndim[MAX_NAMES];
      char   *p;
      void   *pnt[MAX_NAMES];
      int     rank;
      Type    type[MAX_NAMES];   
  

/*  Return without doing anything if no "input" object has been supplied. */

      if( !in[0] ) return( OK );


/*  Get a value for the "file" object. */

      if( !in[1] ){
         file = NULL;

      } else {
         file = DXGetString( (String) in[1] );
         if( !file ){
            DXSetError( ERROR_BAD_PARAMETER, "unable to get string parameter \"file\".");
            goto error;
         }
      }


/*  Get a value for the "append" object */

      if( !in[2] ){
         append = 0;
      } else {
         if( !SXGet0is( "append", in[2], 1, 0, 0, NULL, &append, NULL ) ) goto error;
      }


/*  Open the file, if specified. */

      if( file ){
         if( append ){
            fd = fopen( file, "a" );
         } else {
            fd = fopen( file, "w" );
         }

         if( !fd ) {
            DXSetError( ERROR_BAD_PARAMETER, "cannot open output text file \"%s\".", file );
            goto error;
         }

      }


/*  If the input object is a field... */
      switch( DXGetObjectClass( in[0] ) ){
      case CLASS_FIELD:


/*  Get the components listed in the "names" object and obtain information 
 *  about them. */

         n = 0;
         len = 0;
         name = "data";
         while( DXExtractNthString( in[3], n, &name ) || n == 0 ){

            if( n > MAX_NAMES ){
               DXSetError( ERROR_BAD_PARAMETER, "too many names (>%d) given",
                           MAX_NAMES );
               goto error;
            }

            array = (Array) DXGetComponentValue( (Field) in[0], name );
            if( !array ){         
               DXSetError( ERROR_MISSING_DATA, "no \"%s\" component found",
                           name );
               goto error;
            }

            DXGetArrayInfo( array, &nel[n], &type[n], &cat, &rank, &ndim[n] );
            if( cat != CATEGORY_REAL ){
               DXSetError( ERROR_MISSING_DATA, "non-REAL data encountered" );
               goto error;
            }
            if( rank > 1 ){
               DXSetError( ERROR_MISSING_DATA, "data encountered with rank > 1" );
               goto error;
            }
            if( rank == 0 ) ndim[n] = 1;

            pnt[n] = (void *) DXGetArrayData( array );
            if( len < nel[n] ) len = nel[n];

            n++;
 
         }


         break;


/*  If the supplied object is an array...*/

      case CLASS_ARRAY:


/*  Get information about the array. */

         DXGetArrayInfo( (Array) in[0], &nel[0], &type[0], &cat, &rank, &ndim[0] );
         if( cat != CATEGORY_REAL ){
            DXSetError( ERROR_MISSING_DATA, "non-REAL data encountered" );
            goto error;
         }
         if( rank > 1 ){
            DXSetError( ERROR_MISSING_DATA, "data encountered with rank > 1" );
            goto error;
         }
         if( rank == 0 ) ndim[0] = 1;

         pnt[0] = (void *) DXGetArrayData( (Array) in[0] );

         n = 1;
         len = nel[0];

         break;

/*  If the input object is a single string... */
      case CLASS_STRING:
         pnt[0] = (void *) DXGetString( (String) in[0] );
         ndim[0] = 0;
         while( *(((char *) pnt[0]) + ndim[0]++ ) );
         type[0] = TYPE_STRING;
         len = 1;
         n = 1;
         nel[0] = 1;

         break;


/*  Report an error if the input object is neither a field or an array. */

      default:
         DXSetError( ERROR_BAD_PARAMETER, "\"input\" is of wrong class");   
         goto error;

      }


/*  On each output line, display one item from each of the "n" arrays */

      for( el=0; el <len; el++ ){
         p = buf;
         for( i=0; i<n; i++ ){

            if( type[i] == TYPE_STRING ){
               if( p - buf >= BUF_SIZE - ndim[i] ){
                  DXSetError( ERROR_UNEXPECTED, "output record is too wide");
                  goto error;
               }
               if( el < nel[i] ){

                  sprintf( p, "%-*s", ndim[i], (char *)pnt[i] );
                  ( (char *) pnt[i]) += ndim[i];

               } else {
                  sprintf( p, "%*c", ndim[i], ' ' );
               } 
               while( *(++p) ); 


            } else {
               for( j=0; j<ndim[i]; j++ ){

                  if( type[i] == TYPE_BYTE ){
                     if( p - buf >= BUF_SIZE - 10 ){
                        DXSetError( ERROR_UNEXPECTED, "output record is too wide");
                        goto error;
                     }
                     if( el < nel[i] ){
                        sprintf( p, "%- 5d", *(((char *)pnt[i])++) );
                     } else {
                        sprintf( p, "%5c", ' ' );
                     }
                     while( *(++p) ); 

                  } else if( type[i] == TYPE_INT ){
                     if( p - buf >= BUF_SIZE - 24 ){
                        DXSetError( ERROR_UNEXPECTED, "output record is too wide");
                        goto error;
                     }
                     if( el < nel[i] ){
                        sprintf( p, "%- 12d", *(((int *)pnt[i])++) );
                     } else {
                        sprintf( p, "%12c", ' ' );
                     }
                     while( *(++p) ); 

                  } else if( type[i] == TYPE_FLOAT ){
                     if( p - buf >= BUF_SIZE - 26 ){
                        DXSetError( ERROR_UNEXPECTED, "output record is too wide");
                        goto error;
                     }
                     if( el < nel[i] ){
                        sprintf( p, "%- 13.6g", *(((float *)pnt[i])++) );
                     } else {
                        sprintf( p, "%13c", ' ' );
                     }
                     while( *(++p) ); 

                  } else if( type[i] == TYPE_DOUBLE ){
                     if( p - buf >= BUF_SIZE - 26 ){
                        DXSetError( ERROR_UNEXPECTED, "output record is too wide");
                        goto error;
                     }
                     if( el < nel[i] ){
                        sprintf( p, "%- 13.6g", *(((double *)pnt[i])++) );
                     } else {
                        sprintf( p, "%13c", ' ' );
                     }
                     while( *(++p) ); 

                  } else {
                     DXSetError( ERROR_UNEXPECTED, "cannot print data of supplied type");
                     goto error;
                  }

               }

            }

         }

         if( file ){
            if( fwrite( buf, sizeof( char ), p-buf, fd ) != p-buf ){
               DXSetError( ERROR_UNEXPECTED, "error writing to file");
               goto error;
            }

            fwrite( &cr, sizeof( char ), 1, fd );

         } else {
            p = NULL;
            DXMessage("%s",buf);
         }


      }


/*  Create an output object to hold the number of records written. */

      out[0] = (Object) DXNewArray( TYPE_INT, CATEGORY_REAL, 0 );
      if( out[0] ) DXAddArrayData( (Array) out[0], 0, 1, &len );


/*  Close the output file and return. */

      if( file ) fclose( fd );

      return( OK );

error:
      if( file ) fclose( fd );
      return( ERROR );

}
