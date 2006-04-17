/*
*+
*  Name:
*     merswrap.h

*  Purpose:
*     Prototypes for public interface.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Engineering Research Council.
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
*     AJC: Alan Chipperfield (Starlink)
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     16-APR-2006 (TIMJ):
*        Add prolog.

*-
*/


#ifndef MERSWRAP_DEFINED
#define MERSWRAP_DEFINED

void errAnnul( int *status );

void errBegin( int *status );

void errClear( int *status );

void errEnd( int *status );

void errFacer( const char *token,
               int *status );

void errFioer( const char *token,
               int iostat );

void errFlbel( int *status );

void errFlush( int *status );

void errLevel( int *level );

void errLoad( char *param,
              int param_length,
              int *parlen,
              char *opstr,
              int opstr_length,
              int *oplen,
              int *status );

void errMark( void );

void errOut( const char *param,
             const char *text,
             int *status );

void errRep( const char *param,
             const char *text,
             int *status );

void errRlse( void );

void errStart( void );

void errStat( int *status );

void errStop( int *status );

void errSyser( const char *token,
               int systat );

void errTune( const char *param,
              int value,
              int *status );

void msgBell( int *status );

void msgBlank( int *status );

void msgFmtc( const char *token,
              const char *format,
              const char *cvalue );

void msgFmtd( const char *token,
              const char *format,
              double dvalue );

void msgFmti( const char *token,
              const char *format,
              int ivalue );

void msgFmtl( const char *token,
              const char *format,
              int lvalue );

void msgFmtr( const char *token,
              const char *format,
              float rvalue );

void msgIfget( const char *pname,
               int *status );

void msgIflev( int *filter );

void msgIfset( int filter,
               int *status );

void msgLoad( const char *param,
              const char *text,
              char *opstr,
              int opstr_length,
              int *oplen,
              int *status );

void msgOut( const char *param,
             const char *text,
             int *status );

void msgOutif( int prior,
               const char *param,
               const char *text,
               int *status );

void msgRenew( void );

void msgSetc( const char *token,
              const char *cvalue );

void msgSetd( const char *token,
              double dvalue );

void msgSeti( const char *token,
              int ivalue );

void msgSetl( const char *token,
              int lvalue );

void msgSetr( const char *token,
              float rvalue );

void msgSync( int *status );

void msgTune( const char *param,
              int value,
              int *status );

#endif  /* MERSWRAP_DEFINED */
