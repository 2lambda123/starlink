/*
 *+
 *  Name:
 *     sc2sim_getcurvepong

 *  Purpose:
 *     Get coordinates of full curve PONG pattern

 *  Language:
 *     Starlink ANSI C

 *  Type of Module:
 *     Subroutine

 *  Invocation:
 *     sc2sim_getcurvepong ( double angle, double width, double height,
 *                           double spacing, double vmax[2],
 *                           double samptime, int nmaps,
 *                           int *pongcount, double **posptr,
 *                           int *status )

 *  Arguments:
 *     angle = double (Given)
 *        Angle of pattern relative to the telescope axes in radians
 *        anticlockwise
 *     width = double (Given)
 *        Minimum width of PONG pattern (arcsec)
 *     height = double (Given)
 *        Minimum height of PONG pattern (arcsec)
 *     spacing = double (Given)
 *        Grid spacing in arcsec
 *     accel = double[2] (Given)
 *        Telescope accelerations (arcsec)
 *     vmax = double[2] (Given)
 *        Telescope maximum velocities (arcsec)
 *     samptime = double (Given)
 *        Sample interval in sec
 *     nmaps = int (Given)
 *        Number of cycles of the Pong pattern
 *     pongcount = int* (Returned)
 *        Number of positions in pattern
 *     posptr = double** (Returned)
 *        list of positions
 *     status = int* (Given and Returned)
 *        Pointer to global status.

 *  Description:
 *     The PONG pattern creates a grid of at least the required size
 *     (as specified by the width and height).  The vertices are determined
 *     from the supplied spacing.  The PONG pattern is a rectangular
 *     shape in which the number of vertices along each side share no
 *     common factors.
 *
 *     The grid coordinates generated have (0,0) at the pattern centre.
 *
 *     The pattern is rotated through the given angle to get coordinates
 *     relative to the axes of telescope motion. The telescope motion along
 *     the pattern is then computed and the positions at samptime intervals
 *     recorded.
 *
 *     The velocity of the scan is assumed to be constant and is the
 *     average of the specified x and y velocities.
 *
 *     The functions x(t) and y(t) are triangle functions with five terms
 *     each.  This creates a scan with reasonably 'straight' sweeps across
 *     the central region of the box, while allowing the corners to
 *     be "rounded" to avoid rapid changes in acceleration.
 *

 *  Authors:
 *     B.D.Kelly (ROE)
 *     J.Balfour (UBC)
 *     {enter_new_authors_here}

 *  History :
 *     2005-07-07 (BDK):
 *        Original
 *     2006-07-20 (JB):
 *        Split from dsim.c
 *     2006-10-03 (JB):
 *        Use triangle wave functions to create box scan of required
 *        height, width, and angle.
 *     2006-11-16 (JB):
 *        Use Straight PONG solution to approximate period.
 *     2006-11-22 (JB):
 *        Added multiple map cycle capabilities.
 *     2006-12-08 (JB):
 *        smf_free mapptr.
 *     2007-12-18 (AGG):
 *        Update to use new smf_free behaviour

 *  Copyright:
 *     Copyright (C) 2005-2006 Particle Physics and Astronomy Research
 *     Council. University of British Columbia. All Rights Reserved.

 *  Licence:
 *     This program is free software; you can redistribute it and/or
 *     modify it under the terms of the GNU General Public License as
 *     published by the Free Software Foundation; either version 3 of
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
#include <math.h>

/* SC2SIM includes */
#include "sc2sim.h"

/* SMURF includes */
#include "libsmf/smf.h"

void sc2sim_getcurvepong
(
 double angle,        /* angle of pattern relative to telescope
                         axes in radians anticlockwise (given) */
 double width,        /* minimum width of PONG pattern in arcsec (given) */
 double height,       /* minimum height of PONG pattern in arcsec (given) */
 double spacing,      /* grid spacing in arcsec (given) */
 double accel[2],     /* telescope accelerations (arcsec) (given) */
 double vmax[2],      /* telescope maximum velocities (arcsec/sec) (given) */
 double samptime,     /* sample interval in sec (given) */
 int nmaps,           /* number of cycles of the pattern */
 int *pongcount,      /* number of positions in pattern (returned) */
 double **posptr,     /* list of positions (returned) */
 int *status          /* global status (given and returned) */
 )

{
  /* Local variables */
  double amp_x;            /* amplitude of x(t) (arcsec) */
  double amp_y;            /* amplitude of y(t) (arcsec) */
  double cend[2];          /* ending coordinates in arcsec */
  double cstart[2];        /* starting coordinates in arcsec */
  int curroff;             /* index of next free slot in position list */
  double grid[1024][2];    /* array of vertex coordinates */
  int i;                   /* loop counter */
  double *mapptr;          /* list of positions for one map */
  int mcount;              /* number of positions in one map */
  int numvertices;         /* number of vertices (including start & end,
                              which are the same) */
  double period;           /* total time of scan (seconds) */
  double peri_x;           /* period of x(t) (seconds) */
  double peri_y;           /* period of y(t) (seconds) */
  double t_count;          /* time counter (seconds) */
  double tx;               /* temporary x value (arcsec) */
  double ty;               /* temporary y value (arcsec) */
  double vert_spacing;     /* spacing along the vertices (arcsec) */
  int x_numvert;           /* number of vertices along x axis */
  int y_numvert;           /* number of vertices along y axis */

  /* Check status */
  if ( !StatusOkP(status) ) return;

  /* Calculate how many vertices there must be in each direction,
     and how far apart they are */
  sc2sim_getpongvert ( width, height, spacing, &vert_spacing,
                       &x_numvert, &y_numvert, status );

  /* KLUDGE : Calculate the approximate periods (assuming a PONG scan with
     no "rounding" at the corners.  Use the code from the Straight PONG
     solution to determine the periods */

  sc2sim_getpongends ( width, height, spacing, grid, &numvertices, status );

  /* Rotate the grid coordinates */
  for ( i=0; i< numvertices; i++ ) {
    tx = grid[i][0] * cos(angle) - grid[i][1] * sin(angle);
    ty = grid[i][0] * sin(angle) + grid[i][1] * cos(angle);
    grid[i][0] = tx;
    grid[i][1] = ty;
  }

  mcount = 0;

  for ( i=0; i<numvertices - 1; i++ ) {
    cstart[0] = grid[i][0];
    cstart[1] = grid[i][1];
    cend[0] = grid[i+1][0];
    cend[1] = grid[i+1][1];
    sc2sim_getscansegsize ( samptime, cstart, cend, accel, vmax, &curroff,
                            status );
    mcount += curroff;
  }

  period = mcount * samptime;
  peri_x = period / y_numvert;
  peri_y = period / x_numvert;

  /* Determine the number of positions required for the pattern
     and allocate memory */
  mapptr = astCalloc( mcount*2, sizeof(*mapptr), 1 );

  /* Calculate the amplitudes of x(t) and y(t) */
  amp_x = ((double)(x_numvert) * vert_spacing) / 2.0;
  amp_y = ((double)(y_numvert) * vert_spacing) / 2.0;

  /* Get the positions using a triangle wave approximation for both
     x(t) and y(t), applying a Fourier expansion with the first five
     terms (1, 3, 5, 7, 9) so as to "round off" the corners */
  t_count = 0.0;

  for ( i = 0; ( i < mcount * 2 ); i++ ) {

    tx = ( ( 8.0 * amp_x ) / ( M_PI * M_PI ) ) *
      ( sin ( 2.0 * M_PI * t_count / peri_x ) -
        ( 1.0/9.0 * sin ( 6.0 * M_PI * t_count / peri_x ) ) +
        ( 1.0/25.0 * sin ( 10.0 * M_PI * t_count / peri_x ) ) -
        ( 1.0/49.0 * sin ( 14.0 * M_PI * t_count / peri_x ) ) +
        ( 1.0/81.0 * sin ( 18.0 * M_PI * t_count / peri_x ) ) );

    ty = ( ( 8.0 * amp_y ) / ( M_PI * M_PI ) ) *
      ( sin ( 2.0 * M_PI * t_count / peri_y ) -
        ( 1.0/9.0 * sin ( 6.0 * M_PI * t_count / peri_y ) ) +
        ( 1.0/25.0 * sin ( 10.0 * M_PI * t_count / peri_y ) ) -
        ( 1.0/49.0 * sin ( 14.0 * M_PI * t_count / peri_y ) ) +
        ( 1.0/81.0 * sin ( 18.0 * M_PI * t_count / peri_y ) ) );

    /* Apply the rotation angle and record the coordinates */
    mapptr[i] = tx * cos ( angle ) - ty * sin ( angle );
    i++;
    mapptr[i] = tx * sin ( angle ) + ty * cos ( angle );

    t_count += samptime;

  }

  /* Allocate memory for all n cycles of the pattern */
  *pongcount = mcount * nmaps;
  *posptr = astCalloc( (*pongcount) * 2, sizeof(**posptr), 1 );

  /* Copy the required number of cycles into the
     list of positions */
  for ( i = 0; i < *pongcount * 2; i++ ) {
    (*posptr)[i] = mapptr[i % (mcount * 2)];
  }

  mapptr = astFree( mapptr );

}
