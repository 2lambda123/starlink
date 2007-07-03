/*
*+
*  Name:
*     sc2sim_getobsmode

*  Purpose:
*     Calculate obs enumerated type from string

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     obsMode sc2sim_getobsmode ( char *name, int *status )

*  Arguments:
*     name = char* (Given)
*        String containing name of observing mode
*     status = int* (Given and Returned)
*        Pointer to global status.  

*  Return Value:
*     obsMode = enumerated type of SCUBA2 observing mode (defined in
*     sc2sim_struct.h)

*  Description:
*     Given a string for the observation return the enumerated value
*     as defined in sc2sim_struct.h. 

*  Authors:
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History :
*     2006-03-28 (EC):
*        Original
*     2006-07-20 (JB):
*        Split from dsim.c
*     2006-11-21 (JB):
*        Add liss mode
*     2007-07-03 (EC): 
*        Made enumerated types more readable / fixed up null return value

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research
*     Council. University of British Columbia. All Rights Reserved.

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
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Standard includes */
#include <string.h>

/* SC2SIM includes */
#include "sc2sim.h"

obsMode sc2sim_getobsmode( char *name, int *status ) {
   /* Check status */
   if ( !StatusOkP(status) ) return MODE__NONE;

   if( strcmp( name, "STARE" ) == 0 ) return MODE__STARE;
   else if( strcmp( name, "DSTARE" ) == 0 ) return MODE__DSTARE;
   else if( strcmp( name, "DREAM" ) == 0 ) return MODE__DREAM;
   else if( strcmp( name, "PONG" ) == 0 ) return MODE__PONG;
   else if( strcmp( name, "POLSPIN" ) == 0 ) return MODE__POLSPIN;
   else if( strcmp( name, "HEATRUN" ) == 0 ) return MODE__HEATRUN;
   else if( strcmp( name, "BOUS" ) == 0 ) return MODE__BOUS;
   else if( strcmp( name, "SINGLESCAN" ) == 0 ) return MODE__SINGLESCAN;
   else if( strcmp( name, "LISS" ) == 0 ) return MODE__LISS;
   else return MODE__NONE;

}
