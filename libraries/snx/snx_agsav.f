
      SUBROUTINE snx_AGSAV (HEAP)

*+
*
*  - - - - - -
*   A G S A V
*  - - - - - -
*
*  Save the current state of the NCAR AUTOGRAPH system.
*
*  All of AUTOGRAPH's important variables are stored in
*  an array supplied by the caller, to be restored later
*  in the same program by the snx_AGRES routine.
*
*  Returned:
*     HEAP    r()     array containing the saved variables
*
*  HEAP must be at least 2606 elements long.  This number
*  may change if the COMMON layouts etc in NCAR are altered.
*
*  Called:  AGINIT, GETSET, PLOTIT
*
*  (The native NCAR routines AGSAVE and AGRSTR perform save
*  and restore via a file;  they can therefore be used to
*  maintain AUTOGRAPH context from one program execution to
*  another.)
*
*  P T Wallace   Starlink   April 1986
*
*+

      IMPLICIT NONE

      REAL HEAP(*)

      INTEGER IHEAP,I

*  AUTOGRAPH variables
      REAL QFRA,QSET,QROW,QIXY,QWND,QBAC,SVAL(2),
     :     XLGF,XRGF,YBGF,YTGF,XLGD,XRGD,YBGD,YTGD,SOGD,
     :     XMIN,XMAX,QLUX,QOVX,QCEX,XLOW,XHGH,
     :     YMIN,YMAX,QLUY,QOVY,QCEY,YLOW,YHGH,
     :     QDAX(4),QSPA(4),PING(4),PINU(4),FUNS(4),QBTD(4),
     :     BASD(4),QMJD(4),QJDP(4),WMJL(4),WMJR(4),QMND(4),
     :     QNDP(4),WMNL(4),WMNR(4),QLTD(4),QLED(4),QLFD(4),
     :     QLOF(4),QLOS(4),DNLA(4),WCLM(4),WCLE(4),
     :     QODP,QCDP,WOCD,WODQ,QDSH(26),
     :     QDLB,QBIM,FLLB(10,8),QBAN,
     :     QLLN,TCLN,QNIM,FLLN(6,16),QNAN,
     :     XLGW,XRGW,YBGW,YTGW,XLUW,XRUW,YBUW,YTUW,
     :     XLCW,XRCW,YBCW,YTCW,WCWP,HCWP,SCWP,
     :     XBGA(4),YBGA(4),UBGA(4),XNDA(4),YNDA(4),UNDA(4),
     :     QBTP(4),BASE(4),QMNT(4),QLTP(4),QLEX(4),QLFL(4),
     :     QCIM(4),QCIE(4),RFNL(4),WNLL(4),WNLR(4),WNLB(4),
     :     WNLE(4),QLUA(4),
     :     RBOX(6),DBOX(6,4),SBOX(6,4)
      COMMON /AGCONP/ QFRA,QSET,QROW,QIXY,QWND,QBAC,SVAL,
     :                XLGF,XRGF,YBGF,YTGF,XLGD,XRGD,YBGD,YTGD,SOGD,
     :                XMIN,XMAX,QLUX,QOVX,QCEX,XLOW,XHGH,
     :                YMIN,YMAX,QLUY,QOVY,QCEY,YLOW,YHGH,
     :                QDAX,QSPA,PING,PINU,FUNS,QBTD,
     :                BASD,QMJD,QJDP,WMJL,WMJR,QMND,
     :                QNDP,WMNL,WMNR,QLTD,QLED,QLFD,
     :                QLOF,QLOS,DNLA,WCLM,WCLE,
     :                QODP,QCDP,WOCD,WODQ,QDSH,
     :                     QDLB,QBIM,FLLB,QBAN,
     :                QLLN,TCLN,QNIM,FLLN,QNAN,
     :                XLGW,XRGW,YBGW,YTGW,XLUW,XRUW,YBUW,YTUW,
     :                XLCW,XRCW,YBCW,YTCW,WCWP,HCWP,SCWP,
     :                XBGA,YBGA,UBGA,XNDA,YNDA,UNDA,
     :                QBTP,BASE,QMNT,QLTP,QLEX,QLFL,
     :                QCIM,QCIE,RFNL,WNLL,WNLR,WNLB,
     :                WNLE,QLUA,
     :                RBOX,DBOX,SBOX
      INTEGER ISLD,MWCL,MWCM,MWCE,MDLA,MWCD,MWDQ,INIF
      REAL SMRL
      COMMON /AGORIP/ SMRL,ISLD,MWCL,MWCM,MWCE,MDLA,MWCD,MWDQ,
     :                INIF
      INTEGER LNIC,INCH(2,50),LNCA,INCA
      COMMON /AGCHR1/ LNIC,INCH,LNCA,INCA
      CHARACTER*1 CHRA(2000)
      COMMON /AGCHR2/ CHRA

*  Block definitions for quick copying
      INTEGER NR1
      PARAMETER (NR1=485)
      REAL RBL1(NR1)
      EQUIVALENCE (QFRA,RBL1(1))

      INTEGER NI1
      PARAMETER (NI1=8)
      INTEGER IBL1(NI1)
      EQUIVALENCE (ISLD,IBL1(1))

      INTEGER NI2
      PARAMETER (NI2=103)
      INTEGER IBL2(NI2)
      EQUIVALENCE (LNIC,IBL2(1))

      INTEGER NC
      PARAMETER (NC=2000)

      INTEGER NR2
      PARAMETER (NR2=8)
      REAL RBL2(NR2)
      INTEGER LL



*  If initialization has not yet been done, do it.
      IF (INIF.EQ.0) CALL AGINIT

*  Save the /AGCONP/ block
      IHEAP=1
      DO 100 I=1,NR1
         HEAP(IHEAP)=RBL1(I)
         IHEAP=IHEAP+1
 100     CONTINUE

*  Save the /AGORIP/ block
      HEAP(IHEAP)=SMRL
      IHEAP=IHEAP+1
      DO 200 I=1,NI1
         HEAP(IHEAP)=FLOAT(IBL1(I))
         IHEAP=IHEAP+1
 200     CONTINUE

*  Save the /AGCHR1/ block
      DO 300 I=1,NI2
         HEAP(IHEAP)=FLOAT(IBL2(I))
         IHEAP=IHEAP+1
 300     CONTINUE

*  Save the /AGCHR2/ block
      DO 400 I=1,NC
         HEAP(IHEAP)=FLOAT(ICHAR(CHRA(I)))
         IHEAP=IHEAP+1
 400     CONTINUE

*  Save the SPPS coordinate system parameters
      CALL PLOTIT(0,0,2)
      CALL GETSET(RBL2(1),RBL2(2),RBL2(3),RBL2(4),
     :            RBL2(5),RBL2(6),RBL2(7),RBL2(8),LL)
      DO 500 I=1,NR2
         HEAP(IHEAP)=RBL2(I)
         IHEAP=IHEAP+1
 500     CONTINUE
      HEAP(IHEAP)=FLOAT(LL)

      END
