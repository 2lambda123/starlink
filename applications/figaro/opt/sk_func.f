      subroutine sk_func(iflag,m,n,xc,rc,ajc,ljc,miw,liw,wn,niw)
*+
* Name:
*    SK_FUNC

* Invocation:
*    CALL SK_FUNC(IFLAG,M,N,XC,RC,AJC,LJC,MIW,LIW,WN,NIW)

* Purpose:
*  Residuals/derivatives routine for use with E04GBF.

* Description:
*  Residuals/derivatives routine for use with E04GBF.
*  routine to evaluate the residuals and their first derivatives
*  for Skew Gaussian model.
*  This routine is also suitable for use when E04FCV is used instead
*  of E04HEV as it can deal with IFLAG=0 as well as IFLAG=2
*  i.e. NO DERVATRIVES. This removed, 4/10/90.

* History:
*  TNW 25/10/90 Weighting added (had only applied to SK before!)
*   "  18/9/91  Separate function
*
* Arguments:
*   M = INTEGER (Given)
*        Number of data points
*   N = INTEGER (Given)
*        Number of parameters
*   XC(M) = DOUBLE PRECISION ARRAY (Given)
*        Fit parameters
*   LJC = INTEGER (Given)
*        =M
*   LIW = INTEGER (Given)
*
*   NIW = INTEGER (Given)
*
*   RC(M) = DOUBLE PRECISION ARRAY (Returned)
*        Residuals of fit?
*   AJC(LJC,N) = DOUBLE PRECISION ARRAY (Returned)
*        Derivatives
*   IFLAG = INTEGER (Not used)
*   MIW(LIW) = INTEGER ARRAY (Not used)
*   WN(NIW) = DOUBLE PRECISION ARRAY (Not used)
*
*
      implicit none
      include 'opt_cmn'
*-
      integer m,n,liw,ljc,niw
      integer iflag
      double precision wn(niw),ajc(ljc,n)
      double precision rc(m),xc(n)
      integer miw(liw)
      include 'DYNAMIC_MEMORY'

      call sk_fun(m,n,xc,rc,ajc,dynamic_mem(dataptr)
     :            ,dynamic_mem(densptr),dynamic_mem(weightptr) )
      end
