/*
*+
*  Name:
*     smf_fit_poly1d

*  Purpose:
*     Fit a polynomial to a 1d data set

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     void smf_fit_poly1d ( size_t order, size_t nelem, double clip, const double x[],
*                           const double y[], const double vary[], double coeffs[],
*                           double varcoeffs[], double polydata[], size_t *nused,
*                           int * status );

*  Arguments:
*     order = size_t (Given)
*        Order of polynomial to use for the fit.
*     nelem = size_t (Given)
*        Number of elements in x, y and dy.
*     clip = double (Given)
*        Sigma clipping level. The fit is calculated and then the standard deviation
*        of the residual is calculated. If there are any points greater than the
*        supplied clip level the points are removed and the polynomial refitted. This
*        continues until no points are removed. A value less than or equal to
*        zero disables clipping.
*     x = const double [] (Given)
*        X coordinates. If NULL the array index will be used.
*     y = const double [] (Given)
*        The data to fit. Must be of size nelem.
*     vary = const double [] (Given)
*        Variance of supplied data. Can be NULL for unweighted fit.
*     coeffs = double [] (Given & Returned)
*        Buffer of size order+1 to receive the coefficients of the fit.
*     varcoeffs = double [] (Given & Returned)
*        Buffer of size order+1 to receive the error in coefficients of the fit.
*        Can be NULL.
*     polydata = double [] (Given & Returned)
*        Evaluated polynomial at the x coordinates. Can be NULL. Must have
*        space for nelem points.
*     nused = size_t * (Returned)
*        Number of points used in the fit. Can be smaller than nelem if any
*        of the points are bad or if the points have been removed during
*        sigma clipping.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Fit a simple polynomial to a 1 dimensional dataset. The fit will be weighted
*     if variance is supplied.

*  Notes:
*     o Can handle bad values. A bad variance will result in zero weight.

*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2010-01-29 (TIMJ):
*        First version.
*     2010-02-04 (TIMJ):
*        Add better debugging reports for fits. Initialise all returned arrays to bad.
*        Handle NaN before returning.
*     2010-02-05 (TIMJ):
*        Add iterative sigma-clipping.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2010 Science and Technology Facilities Council.
*     All Rights Reserved.

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

#include "smf_typ.h"
#include "smf.h"
#include "smurf_par.h"

#include "mers.h"
#include "prm_par.h"
#include "sae_par.h"

#include "sc2da/sc2math.h"
#include "gsl/gsl_fit.h"
#include "gsl/gsl_multifit.h"

void smf__fit_poly1d ( size_t order, size_t nelem, const double x[], const double y[],
                       const double vary[], double coeffs[], double varcoeffs[],
                       double polydata[], size_t * nused, double * rchisq, int *status );



void smf_fit_poly1d ( size_t order, size_t nelem, double clip, const double x[],
                      const double y[], const double vary[], double coeffs[],
                      double varcoeffs[], double polydata[], size_t * nused,
                      int *status ) {
  size_t i;
  double rchisq;     /* Reduced chisq of fit */

  /* initialise to bad */
  for (i=0; i<order+1; i++) {
    coeffs[i] = VAL__BADD;
    if (varcoeffs) varcoeffs[i] = VAL__BADD;
    if (polydata) polydata[i] = VAL__BADD;
  }

  if (*status != SAI__OK) return;

  if ( clip <= 0.0 ) {

    smf__fit_poly1d ( order, nelem, x, y, vary, coeffs, varcoeffs, polydata, nused, &rchisq, status);

  } else {
    int iterating = 1;
    double *resid = NULL;
    double * pptr = polydata;
    double * polyptr = NULL;
    double * varptr = NULL;

    /* we need to calculate the polynomial expansion regardless */
    if (polydata) {
      pptr = polydata;
    } else {
      polyptr = smf_malloc( nelem, sizeof(*polyptr), 1, status );
      pptr = polyptr;
    }

    /* the easiest approach is to control the contents of the
       variance array so that we can set elements to bad
       as we clip them out. This is much better than copying
       x and y to new arrays and making sure that polydata
       is expanded properly afterwards. It does mean that
       we will always end up in the weighted branch even if
       there is no supplied variance. */
    varptr = smf_malloc( nelem, sizeof(*varptr), 0, status );
    if (varptr) {
      if (vary && varptr) {
        memcpy( varptr, vary, sizeof(*varptr) * nelem );
      } else {
        for (i=0; i< nelem; i++) {
          varptr[i] = 1.0; /* equal weighting */
        }
      }
    }

    resid = smf_malloc( nelem, sizeof(*resid), 0, status );

    /* we are clipping */
    while (iterating && *status == SAI__OK) {
      double mean;
      double stdev;
      size_t ngood;
      double thresh;
      size_t nclipped;
      size_t maxidx;
      double maxresid;
      double prevchisq = VAL__BADD;

      /* calculate the fit */
      smf__fit_poly1d ( order, nelem, x, y, varptr, coeffs, varcoeffs, pptr, nused, &rchisq, status);

      if (*nused == 0) {
        iterating = 0;
        break;
      }

      /* calculate the residuals */
      ngood = 0;
      maxresid = 0.0;
      maxidx = VAL__BADI;
      for (i=0; i<nelem; i++) {
        if ( y[i] != VAL__BADD && pptr[i] != VAL__BADD && varptr[i] != VAL__BADD
             && varptr[i] != 0.0 ) {
          resid[i] = y[i] - pptr[i];
          ngood++;
          if (resid[i] > maxresid) {
            maxresid = resid[i];
            maxidx = i;
          }
        } else {
          resid[i] = VAL__BADD;
        }
      }

      /* if there are now too few points for statistics we either let the fit
         through as is or we mark the fit as bad. For now let it through. */
      if ( ngood < SMF__MINSTATSAMP ) {
        iterating = 0;
        break;
      }

      /* calculate the standard deviation */
      smf_stats1D( resid, 1, nelem, NULL, 0, 0, &mean, &stdev, &ngood, status );

      /* see if any points are outside the clip range */
      thresh = clip * stdev;
      nclipped = 0;
      for ( i=0; i<nelem; i++) {
        //      if (resid[i] != VAL__BADD) printf("Resid[%zd] = %g\n",i, resid[i]);
        if (resid[i] != VAL__BADD && fabs(resid[i]) > thresh) {
          varptr[i] = VAL__BADD;
          nclipped++;
        }
      }

      if ( nclipped == 0 ) iterating = 0;
      prevchisq = rchisq;
    }

    /* clean up resources */
    if (polyptr) polyptr = smf_free( polyptr, status );
    if (resid) resid = smf_free( resid, status );
    if (varptr) varptr = smf_free( varptr, status );

  }

}

/* internal implementation to simplify the iterative clipping routine */

void smf__fit_poly1d ( size_t order, size_t nelem, const double x[], const double y[],
                       const double vary[], double coeffs[], double varcoeffs[],
                       double polydata[], size_t * nused, double * rchisq, int *status ) {

  const double * xx = NULL;
  double * xptr = NULL;
  size_t i;

  if (rchisq) *rchisq = VAL__BADD;

  /* initialise to bad in smf_fit_poly1d itself*/
  if (*status != SAI__OK) return;

  if (order == 0) {
    *status = SAI__ERROR;
    errRep( "", "smf_fit_poly1d does not calculate a simple mean", status );
    return;
  }

  if (order >= nelem) {
    *status = SAI__ERROR;
    errRepf( "", "Only %zd data points used for fitting, please use a smaller order than %zd",
             status, nelem, order);
    return;
  }

  /* Handle missing x coordinate */
  if (x) {
    xx = x;
  } else {
    xptr = smf_malloc( nelem, sizeof(*xptr), 0, status );
    for ( i = 0; i < nelem; i++) {
      xptr[i] = i;
    }
    xx = xptr;
  }

  /* Special case a first order linear regression */
  if (order == 1 ) {
    double c0, c1, cov00, cov01, cov11, chisq;
    size_t nrgood = 0;

    if (vary) {
      /* Space for the weights */
      double * w = smf_malloc( nelem, sizeof(*w), 0, status );

      /* weighted fit */
      for (i = 0; i < nelem; i++) {
        if ( vary[i] == VAL__BADD || y[i] == VAL__BADD || xx[i] == VAL__BADD ||
             vary[i] == 0.0 ) {
          w[i] = 0.0;
        } else {
          w[i] = 1.0 / vary[i];
          nrgood++;
        }
      }

      gsl_fit_wlinear( xx, 1, w, 1, y, 1, nelem,  &c0, &c1, &cov00, &cov01, &cov11, &chisq );

      w = smf_free( w, status );

    } else {
      /* We need some space to copy the data because we are worried about bad values
         for x and y */
      double * fx = smf_malloc( nelem, sizeof(*fx), 0, status );
      double * fy = smf_malloc( nelem, sizeof(*fy), 0, status );

      for (i = 0; i < nelem; i++) {
        if ( xx[i] != VAL__BADD && y[i] != VAL__BADD ) {
          fx[nrgood] = xx[i];
          fy[nrgood] = y[i];
          nrgood++;
        }
      }

      gsl_fit_linear( fx, 1, fy, 1, nrgood, &c0, &c1, &cov00, &cov01, &cov11, &chisq );

      fx = smf_free( fx, status );
      fy = smf_free( fy, status );
    }

    /* copy the result */
    coeffs[0] = (isnan(c0) ? VAL__BADD : c0 );
    coeffs[1] = (isnan(c1) ? VAL__BADD : c1 );

    if (varcoeffs) {
      varcoeffs[0] = (isnan(cov00) ? VAL__BADD : cov00);
      varcoeffs[1] = (isnan(cov11) ? VAL__BADD : cov11);
    }

    /* evaluate the polynomial */
    if (polydata) {
      double y_err;
      for (i = 0; i<nelem; i++) {
        gsl_fit_linear_est( xx[i], c0, c1, cov00, cov01, cov11, &(polydata[i]), &y_err);
        if (isnan(polydata[i])) polydata[i] = VAL__BADD;
      }
    }

    *rchisq = chisq / ( nrgood - order );

    /* Report the fit details */
    if (msgFlevok( MSG__DEBUG2, status ) ) {
      msgOutiff( MSG__DEBUG2, "", "Best fit (%s) = %g + %g X  Reduced chisq = %f (%zd / %zd values)",
                 status, (vary ? "weighted" : "unweighted"), c0, c1, *rchisq, nrgood, nelem );
    }

    if (nused) *nused = nrgood;

  } else {
    const int use_sc2math = 0;

    if ( use_sc2math && order == 3 ) {
      /* unweighted fit using sc2math for a cubic */
      double *var = NULL;
      if (varcoeffs) {
        var = varcoeffs;
      } else {
        var = smf_malloc( order+1, sizeof(*var), 1, status );
      }
      sc2math_cubfit( nelem, (double*)x, (double*)y, coeffs, var, status);
      if (var && !varcoeffs) var = smf_free( var, status );

      /* sc2math assumes all the points are good so if we seriously
         want to continue with this option we really need to filter the
         data as for the other techniques. */
      if (nused) *nused = nelem;

    } else {
      /* GSL method */
      size_t k;
      gsl_vector * mcoeffs = NULL;
      gsl_matrix * mcov = NULL;
      size_t ncoeff = order + 1;
      gsl_vector * W = NULL;
      gsl_matrix * X = NULL;
      gsl_vector * Y = NULL;
      gsl_multifit_linear_workspace *work = NULL;
      double chisq;
      size_t nrgood = 0;

      /* allocate space */
      work = gsl_multifit_linear_alloc( nelem, ncoeff );
      X = gsl_matrix_alloc( nelem, ncoeff );
      Y = gsl_vector_alloc( nelem );
      W = gsl_vector_alloc( nelem );
      mcoeffs = gsl_vector_alloc( ncoeff );
      mcov = gsl_matrix_alloc( ncoeff, ncoeff );

      /* copy data into vectors */
      for (i = 0; i<nelem; i++) {
        double w;

        /* coordinates */
        for ( k = 0; k<ncoeff; k++) {
          double xik = (double) pow(xx[i], k);
          gsl_matrix_set( X, i, k, xik );
        }

        /* data */
        gsl_vector_set( Y, i, y[i] );

        /* weight - this is where we handle bad values */
        if (y[i] == VAL__BADD || xx[i] == VAL__BADD) {
          w = 0.0;
        } else if (vary) {
          if ( vary[i] == VAL__BADD || vary[i] == 0.0 ) {
            w = 0.0;
          } else {
            w = 1.0 / vary[i];
            nrgood++;
          }
        } else {
          nrgood++;
          w = 1.0;  /* equal weighting */
        }
        gsl_vector_set( W, i, w );

      }

      /* Carry out fit */
      gsl_multifit_wlinear( X, W, Y, mcoeffs, mcov, &chisq, work );

      *rchisq = chisq / ( nrgood - order );

      /* Report the fit details */
      if (msgFlevok( MSG__DEBUG2, status ) ) {
        msgFmt( "POLY", "%g +", gsl_vector_get(mcoeffs,(0)));
        for (k = 1; k<ncoeff; k++) {
          msgFmt( "POLY", " %g", gsl_vector_get(mcoeffs,(k)));
          if (k>1) {
            msgFmt( "POLY", " X^%zd", k);
          } else {
            msgSetc( "POLY", " X");
          }
          if (k<ncoeff-1) msgSetc( "POLY", " +");
        }
        msgOutiff( MSG__DEBUG2, "", "Best fit (%s) = ^POLY  Reduced chisq = %f (%zd / %zd values)",
                   status, (vary ? "weighted" : "unweighted"), *rchisq, nrgood, nelem );
      }

      if (nused) *nused = nrgood;

      /* Store coefficients */
      for (k=0; k<ncoeff; k++) {
        coeffs[k] = gsl_vector_get( mcoeffs, k );
        if(isnan(coeffs[k])) coeffs[k] = VAL__BADD;
        if (varcoeffs) {
          varcoeffs[k] = gsl_matrix_get( mcov, k, k );
          if (isnan(varcoeffs[k])) varcoeffs[k] = VAL__BADD;
        }
      }

      /* tidy up */
      gsl_multifit_linear_free( work );
      gsl_matrix_free( X );
      gsl_vector_free( Y );
      gsl_vector_free( W );
      gsl_vector_free( mcoeffs );
      gsl_matrix_free( mcov );
    }


    if (polydata) {
      for (i=0; i<nelem; i++) {
        size_t j;
        polydata[i] = coeffs[0];
        for ( j = 1; j <= order; j++) {
          polydata[i] += coeffs[j] * pow(xx[i], j );
        }
      }
    }

  }

  if (xptr) xptr = smf_free( xptr, status );

}
