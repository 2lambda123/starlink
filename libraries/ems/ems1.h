/*+
 *  Name:
 *     ems1.h

 *  Purpose:
 *     EMS_ C internal header file.

 *  Language:
 *     Starlink ANSI C

 *  Description:
 *     This include file contains the function prototypes for all 
 *     EMS C internal routines.

 *  Authors:
 *     RTP: R.T.Platon (STARLINK)
 *     {enter_new_authors_here}

 *  History:
 *     14-FEB-2001 (RTP):
 *        Original version.
 *      2-MAR-2001 (AJC):
 *        Correct various returned variables to pointers
 *        Add maxlen to ems1Putc
 *     13-AUG-2001 (AJC):
 *        Correct ems1Flush(int status) to (int *status)
 *     {enter_changes_here}

 *  Bugs:
 *     {note_any_bugs_here}

 *-
 */

#ifndef EMS1_DEFINED
#define EMS1_DEFINED
#include "ems_sys.h"

void ems1Emark( void );

void ems1Erlse( void );

void ems1Estor( const char *param, int plen, const char *msg, int mlen,
        int *status);

void ems1Fcerr( char *errstr, int *errnum_p );

void ems1Flush( int *status );

void ems1Form( const char *text, const int, Logical clean,
        char *opstr, int *oplen, int *status );

void ems1Gesc( const char *escchr, const char *string, int *iposn );

void ems1Get_facility_error ( unsigned int errcode, char **facility_name,
        char **error_ident, char **error_text );

void ems1Gnam( const char *string, int *iposn, char *name, int *namlen,
        int *status);

Logical ems1Gtok( const char *namstr, char *tokval, int *tkvlen );

Logical ems1Gepnd ( void );

void ems1Kerr( void );

void ems1Ktok (void);

void ems1Mpop( void );

void ems1Mpush( void );

void ems1Mrerr( const char *text, int *status );

void ems1Mutc( const char *cvalue, char *string, int iposn, int *status );

void ems1Mform( const char *text, int iposn, char *string, int strlength  );

void ems1Prerr( const char *text, int *status );

void ems1Putc( const char *cvalue, const int maxlen, char *string, int *iposn,
              int *status );

void ems1Rform( const char *text, const int maxlen, int *iposn, char *string,
                int *strlength  );

void ems1Serr( char *errstr, int errlen, int *errnum_p );

int ems1Starf( char *envar, char *relpath, char *acmode, 
              char **filename, int *pathlen );

void ems1Stok( const char *token, const char *string );

#endif	/* EMS1_DEFINED */
