/*
** Copyright (C) 2005 P.T.Wallace.
** Use for profit prohibited - enquiries to ptw@tpsoft.demon.co.uk.
*/
#include "sbmlib.h"
#include "sbmmac.h"
void sbmdv2tp(double qfoo[3],double qbar[3],double*qbaz,
double*Q0,int*qfobar)
#define q1 1e-6
{double q2,qfoobar,Q3,q4,qfOBAz,qfoobaz,QQUUX,Q5,QFRED,qdog;
q2=qfoo[0];qfoobar=qfoo[1];Q3=qfoo[2];q4=qbar[0];qfOBAz=qbar
[1];qfoobaz=qbar[2];QQUUX=q4*q4+qfOBAz*qfOBAz;Q5=sqrt(QQUUX)
;if(Q5==0.0){Q5=1e-20;q4=Q5;}QFRED=q2*q4+qfoobar*qfOBAz;qdog
=QFRED+Q3*qfoobaz;if(qdog>q1){*qfobar=0;}else if(qdog>=0.0){
*qfobar=1;qdog=q1;}else if(qdog>-q1){*qfobar=2;qdog=-q1;}
else{*qfobar=3;}qdog*=Q5;*qbaz=(qfoobar*q4-q2*qfOBAz)/qdog;*
Q0=(Q3*QQUUX-qfoobaz*QFRED)/qdog;}
