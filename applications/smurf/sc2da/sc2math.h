#ifndef HEADGEN___src_sc2math_sc2math_h
#define HEADGEN___src_sc2math_sc2math_h 
 
 
/*+  sc2math_convolve - convolve a dataset with a filter */

void sc2math_convolve
(
int filtlen,      /* number of elements in filter (given) */
int filtmid,      /* index of filter centre (given) */
double *filter,     /* convolving filter (given) */
int datalen,      /* length of dataset (given) */
double *input,      /* input dataset (given) */
double *output,     /* convolved dataset (returned) */
int *status       /* global status (given and returned) */
);

/*+ sc2math_cubfit - fit a set of values with a cubic */

void sc2math_cubfit 
( 
int npts,                 /* number of data points (given) */
double *x,                /* observed values (given) */
double *y,                /* observed values (given) */
double *coeffs,           /* coefficients of fit (returned) */
double *variances,        /* variances of fit (returned) */
int *status               /* global status (given and returned) */
);

/*+ sc2math_fitsky - fit a sky baseline for each bolometer */

void sc2math_fitsky
(
int cliptype,       /* type of sigma clipping (given) */
int nboll,          /* number of bolometers (given) */
int nframes,        /* number of frames in scan (given) */
int ncoeff,         /* number of coefficients (given) */
double *inptr,      /* measurement values (given) */
double *coptr,      /* coefficients of fit (returned) */
int *status         /* global status (given and returned) */
);

/*+ sc2math_flatten - apply flat field correction to set of frames */

void sc2math_flatten
(
int nboll,          /* number of bolometers (given) */
int nframes,        /* number of frames in scan (given) */
char *flatname,     /* name of flatfield algorithm (given) */
int nflat,          /* number of flatfield parameters (given) */
double *fcal,       /* calibration coefficients (given) */
double *fpar,       /* calibration parameters (given) */
double *inptr,      /* measurement values (given and returned) */
int *status         /* global status (given and returned) */
);

/*+ sc2math_linfit - straight line fit */

void sc2math_linfit
(
int np,               /* number of points (given) */
double x[],           /* X data (given) */
double y[],           /* Y data (given) */
double wt[],          /* weights (given) */
double *grad,         /* slope (returned) */
double *cons,         /* offset (returned) */
int *status           /* global status (given and returned) */
);

/*+  sc2math_martin - spike removal from chop-scan data */

void sc2math_martin
(
double period,       /* chop period in samples (given) */
int maxlen,        /* length of signal (given) */
double *signal,      /* signal to be cleaned (given and returned) */
char *badscan,      /* record of spikes removed (returned) */
int *nbad,         /* number of points removed (returned) */
int *status        /* global status (given and returned) */
);

/*+  sc2math_matinv - invert a symmetric matrix */

void sc2math_matinv 
( 
int norder,          /* degree of matrix (given) */
double array[10][10],  /* given matrix, its inverse is returned 
                         (given and returned) */
double *det,           /* determinant of ARRAY (returned) */
int *status          /* global status (given and returned) */
);

/*+ sc2math_recurfit - fit a set of values with outlier rejection */

void sc2math_recurfit 
( 
int despike,            /* flag for spike removal (given) */
int npts,               /* number of data points (given) */
int nterms,             /* number of combined waveforms (given) */
double *standard_waves,   /* values of standard waveforms (given) */
double *standard_weights, /* if volts[j] is not to be used, 
                            standard_weights[j] = 0.0, otherwise
                            standard_weights[j] = 1.0 (given) */
double *volts,            /* observed values (given) */
double *used_weights,     /* if volts[j] was not used, 
                            used_weights[j] = 0.0, otherwise 
                            used_weights[j] = 1.0 (returned) */
double *fitted_volts,     /* combined waveform computed from the fit 
                            (returned) */
double *coeffs,           /* coefficients of fit (returned) */
double *variances,        /* variances of fit (returned) */
int *nbad,              /* number of points rejected as suspected
                            "spikes" (returned) */
int *status             /* status must be 0 on entry. 
                            If no valid fit was found, SAI__ERROR is
                            returned (given and returned) */
);

/*+  sc2math_regres - multiple linear regression fit */

void sc2math_regres 
( 
int npts,      /* number of data points (given) */
int nterms,    /* number of combined waveforms (given) */
double *x,       /* values of standard waveforms (given) */
double *y,       /* observed values (given) */
double *weight,  /* weight for each observed value (given) */
double *yfit,    /* values of Y computed from the fit (returned) */
double *a0,      /* constant term in fit (returned) */
double *a,       /* coefficients of fit (returned) */
double *sigma0,  /* standard deviation of A0 (returned) */
double *sigmaa,  /* array of standard deviations for coefficients
                   (returned) */
double *r,       /* array of linear correlation coefficients 
                   (returned) */
double *rmul,    /* multiple linear correlation coefficient (returned) */
double *chisqr,  /* reduced chi square for fit (returned) */
double *ftest,   /* value of F for test of fit (returned) */
double *perr,    /* probable error in deviation of a single point from
                   the fit (returned) */
int *status    /* status must be OK on entry
                   on exit, STATUS = OK => fit ok
                   STATUS = DITS__APP_ERROR => exact fit (no noise) 
                   (given and returned) */
);

/*+  sc2math_remsine - remove sine wave from scan data */

void sc2math_remsine
(
int phase,        /* position in scan corresponding to zero phase 
                      of the superimposed sine (given) */
double period,      /* period in samples of the sine wave (given) */
int scanlen,      /* length of scan (given) */
double *scan,       /* the time series of measurements (given and 
                      returned) */
double *amplitude,  /* amplitude of the sine wave (returned) */
int *status       /* global status (given and returned) */
);

/*+ sc2math_setcal - set flatfield calibration for a bolometer */

void sc2math_setcal
( 
int nboll,         /* total number of bolometers (given) */
int bol,           /* number of current bolometer (given) */
int numsamples,    /* number of data samples (given) */
double values[],   /* measurements by bolometer (given) */
int ncal,          /* number of calibration measurements (given) */
double heat[],     /* calibration heater settings (given) */
double calval[],   /* calibration measurements for all bolometers (given) */
double lincal[2],  /* calibration parameters (returned) */
int *status        /* global status (given and returned) */
);

/*+ sc2math_sigmaclip - do sigma clipping on a straight-line fit */

void sc2math_sigmaclip
(
int type,             /* 0 for double sided clip, 
                        >0 positive clip, 
                        <0 negative clip (given) */
int np,               /* number of points (given) */
double x[],           /* X data (given) */
double y[],           /* Y data (given) */
double wt[],          /* weights (given) */
double *grad,         /* slope (returned) */
double *cons,         /* offset (returned) */
int *status           /* global status (given and returned) */
);

/*+  sc2math_sinedemod - sine wave demodulate a signal */

void sc2math_sinedemod 
( 
int length,          /* length of the signal array (given) */
double *sine,          /* sine wave (given) */
double *cosine,        /* cosine wave (given) */
double *signal,        /* signal (given) */
double *amplitude,     /* modulation amplitude (returned) */
double *phase,         /* phase of signal (returned) */
int *status          /* global status (given and returned) */
);

/*+  sc2math_wavegen - generate sine and cosine signals */

void sc2math_wavegen 
( 
double period,                 /* period in array elements (given) */
int length,                  /* length of arrays (given) */
double *sine,                  /* generated sine wave (returned) */
double *cosine,                /* generated cosine wave (returned) */
int *status                  /* global status (given and returned) */
);

/*+ dsolve_get_cycle - Return data for a single measurement cycle */

void sc2math_get_cycle 
(
int cur_cycle,    /* current cycle number (given) */
int nsam_cycle,   /* number of samples per cycle (given) */
int ncycle,       /* total number of cycles (given) */
int r_nbol,       /* number of bolometers (given) */
double drdata[],  /* full raw data set (given) */
double sbuf[],    /* data for the current cycle (returned) */
int *status       /* global status (given and returned) */
);
 
/*+ lsq_choles - Factorize symmetric positive definite matrix */

void sc2math_choles 
( 
int n,         /* Dimension of the matrix (given) */
double a[],    /* Square matrix of NxN values.
                  Only the lower-left triangle is given and returned.
                  (given and returned) */
int *loc,      /* Diagonal index in A giving the problem or the lowest value.
                  (returned) */
double *dmin,  /* Lowest value or problem value (returned) */
int *ierr      /* Error code
                   0 : Normal return.
                   1 : There is loss of significance.
                  -1 : Matrix not positive definite.
                  (returned) */
);

/*+ lsq_cholesky - Invert matrix according to the Cholesky method */

void sc2math_cholesky 
(
int nunkno,     /* The number of unknowns (given) */
double lmat[],  /* The lower left triangle of the equation matrix.
                   This is a 1 dimensional array of dimension
                   NUNKNO*(NUNKNO+1)/2 which must be filled before the
                   call of this routine, and which is changed into the
                   inverse matrix (given and returned) */
int *loc,       /* Index nr in LMAT giving the lowest value.
                   This must be a diagonal element (returned) */
double *dmin,   /* Lowest value or problem value of the diagonal element
                   with index nr LOC (returned) */
int *err        /* Possible error code in factorizing the matrix (returned) */
);

/*+ lsq_eq0  - Make equation matrix */

void sc2math_eq0 
(
int nunkno,        /* The number of unknowns (given) */
double lcoef[],    /* The known values (given) */
double lmat[]      /* equation matrix (given and returned) */
);

/*+ lsq_invpdm - Invert positive definite matrix */

void sc2math_invpdm 
(
int n,       /* Dimension of the matrix (given) */
double a[]   /* Square Matrix with NxN points.
                Only the lower-left triangle is given.
                (given and returned) */
);

/*+ lsq_msv - Multiply matrix with column vector */

void sc2math_msv 
(
int m,        /* Number of unknowns (given) */
double s[],   /* Lower left triangle of a symmetric matrix of MxM (given) */
double v[],   /* Vector with dimension M (given) */
double x[]    /* Vector with dimension M with the result (returned) */
);

/*+ lsq_sol - Solution of least square fit */

void sc2math_sol 
(
int nunkno,      /* The number of unknowns (given) */
int nequ,        /* The number of observed points (given) */
double lmat[],   /* lower left triangle of inverted equation matrix
                    (given) */
double lvec[],   /* array containing the known vector (given) */
double lssum,    /* The sum of the square of known terms (given) */
double *lme,     /* Quality measure of the Least Square Solution (returned) */
double lmex[],   /* rms errors of the vector of solutions (returned) */
double lsol[]    /* solved parameters of the Least Square Solution
                    (returned) */
);

/*+ lsq_vec - Make known vector */

void sc2math_vec 
(
int nunkno,        /* The number of unknowns (given) */
double lcoef[],    /* The known values (given) */
double lknow,      /* The measured point, or observed value (given) */
double lvec[],     /* array to contain the known vector 
                      (given and returned) */ 
double *lssum      /* sum of the square of known terms (returned) */
);

/*+ dream_smupath - Calculate the path positions of the SMU */

void sc2math_smupath 
(
int nvert,           /* number of vertices in the jiggle pattern, 
                        implemented are :
                        =1 : No visit of points.
                        At the moment a circle but that does not work !
                        =4 : Visit 4 points on a square.
                        =5 : Visit 5 points on a '+'
                        =8 : Visit 8 points on a star. (This is the best)
                        (given) */
double vertex_t,     /* Time for movement between vertices in msec (given) */
int jig_vert[][2],   /* Table with relative vertex coordinates in time
                        (given) */
double jig_stepx,    /* The step size in -X- direction between Jiggle
                        positions in arcsec (given) */
double jig_stepy,    /* The step size in -Y- direction between Jiggle
                        positions in arcsec (given) */
int movecode,        /* The code for the SMU waveform that determines the
                        SMU motion (given) */
int nppp,            /* The number of calculated coordinates in the path
                        between 2 successive vertices (given) */
double sample_t,     /* time between samples in msec (given) */
double smu_offset,   /* smu timing offset in msec (given) */
int pathsz,          /* maximum no of path points (given) */
double jigpath[][2], /* Buffer containing the X and Y coordinates of each
                        point in the path of the SMU during the Jiggle in
                        units of arcsec (returned) */
int *status          /* global status (given and returned) */
);

/*+ dream_smupos - Calculate the SMU position at an instant */

void sc2math_smupos
(
double t,           /* Time from start of pattern in msec (given) */
double vertex_t,    /* Time for movement between vertices in msec (given) */
int movecode,       /* The code for the SMU waveform that determines the
                       SMU motion (given) */
int nvert,          /* number of vertices in the DREAM pattern (given) */
double vertxy[][2], /* Table of vertex offsets in arcsec (given) */
double *x,          /* calculated X-position (returned) */
double *y,          /* calculated Y-position (returned) */
int *status         /* global status (given and returned) */
);

/*+ map_gridext - Calculate the extent of the sky grid */

void sc2math_gridext
(
int ngrid,           /* Number of grid positions within the jiggle area
                        (given) */
int gridpts[][2],    /* Table with relative grid offsets for a single
                        bolometer (given) */
int *xmin,           /* Grid limit in X-dir (returned) */
int *xmax,           /* Grid limit in X-dir (returned) */
int *ymin,           /* Grid limit in Y-dir (returned) */
int *ymax,           /* Grid limit in Y-dir (returned) */
int *status          /* global status (given and returned) */
);

/*+ weight_conval - Calculate a value of the convolution function */

double sc2math_conval 
(
int conv_shape,     /* Code for convolution function (given) */
double conv_sig,    /* Convolution function parameter (given) */
double dx,          /* Distance from the centre in X (given) */
double dy,          /* Distance from the centre in Y (given) */
int *status         /* global status (given and returned) */
);

/*+ map_interpwt - Calculate the weight matrix for spatial interpolation */

void sc2math_interpwt 
(
int npath,           /* Nr of rows (given) */
int ngrid,            /* Nr of columns (given) */
int conv_shape,      /* Code for convolution function (given) */
double conv_sig,     /* Convolution function parameter (given) */
double calc_t,       /* Time per path point in millisec (given) */
double tbol,         /* Bolometer time constant in millisec (given) */
double jigpath[][2], /* Table with jiggle path pos (given) */
int jigpts[][2],     /* Table with grid positions (given) */
double b[],          /* the weight factors (returned) */
int *status          /* (given and returned) */
);
 
/*+ weight_pathwts - Pixel weights for SMU path */

void sc2math_pathwts 
(
int conv_shape,       /* Code for convolution function (given) */
double conv_sig,      /* Convolution function parameter (given) */
int npath,            /* Nr of rows in wtpix (given) */
double jigpath[][2],  /* Table with jiggle path pos. (given) */
int ncol,             /* Nr of columns in wtpix (given) */
int gridpts[][2],     /* Table with grid positions (given) */
double wtpix[],       /* Matrix with pixel weights (returned) */
int *status           /* global status (given and returned) */
);

/*+ weight_response - Calculate the response value */

void sc2math_response
(
double f[],   /* Input function (given) */
double w[],   /* Impulse response function (given) */
int wdim,     /* Dimension of W (given) */
int ix,       /* Index corresponding to response (given) */
double *r     /* Response value (returned) */
);

/*+ dream_trace - provide a flag for debugging level */

int sc2math_trace
( 
int value       /* trace level (given) */
);


#endif
