*+  IXCONV - Computes convolution of two images to produce a third
      SUBROUTINE IXCONV( STATUS )
*
*    Description :
*
*     Takes two input datasets

*    Parameters :
*
*    Method :
*
*     - Move the first input into the centre of the real part of an array X
*       and remove its average. Zero the imaginary part.
*     - Move the second input into the centre of the real part of an array Y
*       and remove its average. Zero the imaginary part.
*     - Find the FFT of X and Y, FX and FY
*     - Compute the convolution of FX and FY, FC
*     - Untransform FC to find the convolution C
*     - Restore DC level if required and rotate so that zero lag is in the
*       centre of the output
*
*    Deficiencies :
*
*     No account is taken of data quality, other than to warn of its
*     presence.
*
*    Bugs :
*
*    Authors :
*
*     Gerry Skinner (BHVAD::GKS)
*     David J. Allan (JET-X,University of Birmingham)
*
*    History :
*
*     22 Apr 94           Created from SLIMSAM Version 19 (GKS)
*      3 May 94 : V10     Unix version using Double precision FFT as thats the
*                         only NAG library available
*      3 May 94 : V11     Use alternative NAG routine with no silly limit on
*                         sizes which have large prime factors
*     10 Jun 94 : V1.8-0  Imported into Asterix - cut workspace requirements
*                         drastically. (DJA)
*     29 Nov 94 : V1.8-1  Fixed memory corruption bug (DJA)
*     20 Mar 95 : V1.8-2  Trap case where dataset1==2 (DJA)
*     10 Nov 95 : V2.0-0  ADI port (DJA)
*
*    Type Definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'ADI_PAR'
      INCLUDE 'PRM_PAR'
*
*    Status :
*
      INTEGER STATUS
*
*    Functions :
*
      INTEGER			CHR_LEN
*
*    Local variables :
*
      CHARACTER*132             HTXT(8)			! History text
      CHARACTER*40		XUNITS, YUNITS		! Axis units
      CHARACTER*70              XLABEL, YLABEL  	! Axis labels

      REAL			AVX			! Average of 1st dataset
      REAL 			AVY			! Average of 2nd dataset
      REAL 			RESTORE			! DC restore value
      REAL			SPARR(2)		! Spaced array vars
      REAL			XBASE, XSCALE		! X axis scaling
      REAL			YBASE, YSCALE		! Y axis scaling

      INTEGER			BID			! Binned dataset id
      INTEGER			NLINES			! Amount of history

      INTEGER 				IDUM,M3,N3           ! Output dimensions
      INTEGER DIMS1(ADI__MXDIM)           ! dimensions found in input array
      INTEGER DIMS2(ADI__MXDIM)           ! dimensions found in input array
      INTEGER ODIMS(ADI__MXDIM)           ! dimensions for output
      INTEGER NDIMS1                  ! number found (should be 2)
      INTEGER NDIMS2                  ! number found (should be 2)

      INTEGER WPTR_XR                  ! Pointer to work area XR
      INTEGER WPTR_XI                  ! Pointer to work area
      INTEGER WPTR_YR                  ! Pointer to work area
      INTEGER WPTR_YI                  ! Pointer to work area
      INTEGER WPTR_ZR                  ! Pointer to work area
      INTEGER WPTR_ZI                  ! Pointer to work area
      INTEGER WPTR_TM                  ! Pointer to work area TRIGM
      INTEGER WPTR_TN                  ! Pointer to work area TRIGN
      INTEGER WPTR_S                   ! Pointer to main work area

      INTEGER 			DPTR_1			! First dataset's data
      INTEGER 			DPTR_2			! Second dataset's data
      INTEGER 			IFAIL			! NAG status code
      INTEGER			IFID1			! Input dataset 1
      INTEGER			IFID2			! Input dataset 2
      INTEGER 			ODPTR			! Output data pointer
      INTEGER			OFID			! Output dataset
      INTEGER 			ONDIM                  	! Output dimensionality
      INTEGER 			SIZE			! Size of work arrays

      LOGICAL 			CYCLIC			! Cyclic mode?
      LOGICAL 			DC_RESTORE		! Restore DC level?
      LOGICAL 			OK			! General validity test
      LOGICAL                   QOK1, QOK2		! Quality present?
      LOGICAL			SAME			! Datasets are the same
*
*    Version :
*
      CHARACTER*30		VERSION
        PARAMETER 		( VERSION = 'IXCONV Version 2.0-0' )
*-

*  Version announcement
      CALL MSG_PRNT( VERSION )

*  Initialise
      CALL AST_INIT()

*  Open first input dataset
      CALL USI_ASSOC( 'INP1', 'BinDS', 'READ', IFID1, STATUS )
      CALL BDI_CHK( IFID1, 'Data', OK, STATUS )
      CALL BDI_GETSHP( IFID1, ADI__MXDIM, DIMS1, NDIMS1, STATUS )
      IF ( OK ) THEN
        IF ( NDIMS1 .NE. 2 ) THEN
          STATUS = SAI__ERROR
          CALL ERR_REP( ' ', 'First input is not 2-D', STATUS )
        ELSE
          CALL BDI_MAPR( IFID1, 'Data', 'READ', DPTR_1, STATUS )
        END IF
      ELSE
        CALL ERR_REP( ' ', 'Invalid data in first dataset', STATUS )
      END IF
      CALL BDI_CHK( IFID1, 'Quality', QOK1, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Open 2nd input dataset
      CALL USI_ASSOC( 'INP2', 'BinDS', 'READ', IFID2, STATUS )
      CALL BDI_CHK( IFID2, 'Data', OK, STATUS )
      CALL BDI_GETSHP( IFID2, ADI__MXDIM, DIMS2, NDIMS2, STATUS )
      IF (OK) THEN
        IF (NDIMS2.NE.2) THEN
          STATUS = SAI__ERROR
          CALL ERR_REP( ' ', 'Second input is not 2-D', STATUS )
        ELSE
          CALL BDI_MAPR( IFID2, 'Data', 'READ', DPTR_2, STATUS )
        END IF
      ELSE
        CALL ERR_REP( ' ', 'Invalid data in second dataset', STATUS )
      END IF
      CALL BDI_CHK( IFID2, 'Quality', QOK2, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Warn if quality present
      IF ( QOK1 .OR. QOK2 ) THEN
        CALL MSG_PRNT( 'WARNING : IXCONV is ignoring quality arrays '/
     :                 /'present in one or both inputs' )
      END IF

*  Is a cyclic or non-cyclic convolution required?
      IF ( (DIMS1(1).NE.DIMS2(1)) .OR. (DIMS1(2).NE.DIMS2(2)) ) THEN
        CALL MSG_SETI( 'NX', DIMS1(1) )
        CALL MSG_SETI( 'NY', DIMS1(2) )
        CALL MSG_PRNT( 'Dimensions of dataset 1 are ^NX by ^NY' )
        CALL MSG_SETI( 'NX', DIMS2(1) )
        CALL MSG_SETI( 'NY', DIMS2(2) )
        CALL MSG_PRNT( 'Dimensions of dataset 2 are ^NX by ^NY' )
        CALL MSG_PRNT(
     :   ' Dimensions are not same, so convolution will be non-cyclic' )
        CYCLIC=.FALSE.
      ELSE
        CALL MSG_SETI( 'NX', DIMS1(1) )
        CALL MSG_SETI( 'NY', DIMS1(2) )
        CALL MSG_PRNT( 'The dimensions of both inputs are ^NX by ^NY' )
        CALL USI_GET0L( 'CYCLIC', CYCLIC, STATUS )
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Set up OP dimensions
      ONDIM = 2
      IF ( CYCLIC ) THEN
        ODIMS(1) = DIMS1(1)
        ODIMS(2) = DIMS1(2)
      ELSE
        ODIMS(1) = DIMS1(1)+DIMS2(1)
        ODIMS(2) = DIMS1(2)+DIMS2(2)
      END IF
      M3 = ODIMS(1)
      N3 = ODIMS(2)

*  Create new data array etc
      CALL BDI_NEW( 'BinDS', ONDIM, ODIMS, 'REAL', BID, STATUS )
      CALL BDI_SETDST( BID, 'CONVOLUTION', STATUS )
      CALL USI_CREAT( 'OUT', BID, OFID, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Get input axes - if not regular assume pixels
      CALL BDI_AXGET1R( IFID1, 1, 'SpacedData', 2, SPARR, IDUM, STATUS )
      XBASE = SPARR(1)
      XSCALE = SPARR(2)
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL ERR_ANNUL( STATUS )
        XBASE = 0.5
        XSCALE = 1.0
        XLABEL = '1st axis'
        XUNITS = 'pixels'
        CALL MSG_PRNT( 'Unable to get X axis data, assuming pixels...' )
      ELSE
        CALL BDI_AXGET0C( IFID1, 1, 'Label', XLABEL, STATUS )
        CALL BDI_AXGET0C( IFID1, 1, 'Units', XUNITS, STATUS )
      END IF
      CALL BDI_AXGET1R( IFID1, 2, 'SpacedData', 2, SPARR, IDUM, STATUS )
      YBASE = SPARR(1)
      YSCALE = SPARR(2)
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL ERR_ANNUL( STATUS )
        YBASE = 0.5
        YSCALE = 1.0
        YLABEL = '2nd axis'
        YUNITS = 'pixels'
        CALL MSG_PRNT( 'Unable to get Y axis data, assuming pixels...' )
      ELSE
        CALL BDI_AXGET0C( IFID1, 2, 'Label', YLABEL, STATUS )
        CALL BDI_AXGET0C( IFID1, 2, 'Units', YUNITS, STATUS )
      END IF

*  Create axes
      CALL BDI_AXPUT0C( OFID, 1, 'Label', 'Lag in '//XLABEL, STATUS )
      CALL BDI_AXPUT0C( OFID, 2, 'Label', 'Lag in '//YLABEL, STATUS )
      CALL BDI_AXPUT0C( OFID, 1, 'Units', XUNITS, STATUS )
      CALL BDI_AXPUT0C( OFID, 2, 'Units', YUNITS, STATUS )
      XBASE = REAL(-M3)/2.0 + 0.5
      YBASE = REAL(-N3)/2.0 + 0.5
      IF ( .NOT. CYCLIC ) THEN
        XBASE = XBASE - 0.5
        YBASE = YBASE - 0.5
      END IF
      SPARR(1) = XBASE*XSCALE
      SPARR(2) = XSCALE
      CALL BDI_AXPUT1R( OFID, 1, 'SpacedData', 2, SPARR, STATUS )
      SPARR(1) = YBASE*YSCALE
      SPARR(2) = YSCALE
      CALL BDI_AXPUT1R( OFID, 1, 'SpacedData', 2, SPARR, STATUS )

*    Size of scratch arrays
      SIZE = M3*N3

*    Are the datasets the same?
      SAME = (DPTR_1.EQ.DPTR_2)

*    Copy X to (centre of) X_Real, removing average; zero X_imaginary
      CALL DYN_MAPD( 2, ODIMS, WPTR_XR, STATUS )
      CALL IXCONV_COPY2( DIMS1(1), DIMS1(2), %VAL(DPTR_1), M3, N3,
     :                   %VAL(WPTR_XR), AVX, STATUS )
c      CALL BDI_UNMAPDATA( IFID1, STATUS )

*    Fill X_Imaginary array with zeroes
      CALL DYN_MAPD( 2, ODIMS, WPTR_XI, STATUS )
      CALL ARR_INIT1D( 0.0D0, M3*N3, %VAL(WPTR_XI), STATUS )

*  Copy Y to (centre of) Y_Real, removing average
      CALL DYN_MAPD( 2, ODIMS, WPTR_YR, STATUS )
      IF ( SAME ) THEN
        CALL ARR_COP1D( M3*N3, %VAL(WPTR_XR), %VAL(WPTR_YR), STATUS )
        AVY = AVX
      ELSE
        CALL IXCONV_COPY2( DIMS2(1), DIMS2(2), %VAL(DPTR_2), M3, N3,
     :                   %VAL(WPTR_YR), AVY, STATUS )
      END IF
      CALL BDI_UNMAP( IFID2, 'Data', DPTR_2, STATUS )

*  Fill Y_Imaginary array with zeroes
      CALL DYN_MAPD( 2, ODIMS, WPTR_YI, STATUS )
      CALL ARR_INIT1D( 0.0D0, M3*N3, %VAL(WPTR_YI), STATUS )

*  Trigm
      CALL DYN_MAPD( 1, 2*M3, WPTR_TM, STATUS )

*  Trign
      CALL DYN_MAPD( 1, 2*N3, WPTR_TN, STATUS )

*  Work
      CALL DYN_MAPD( 1, 2*M3*N3, WPTR_S, STATUS )

*  Do FFT on X array
      CALL MSG_PRNT( 'Transforming first input...' )
      IFAIL=0
      CALL C06FUF( M3, N3, %VAL(WPTR_XR), %VAL(WPTR_XI), 'I',
     :             %VAL(WPTR_TM), %VAL(WPTR_TN), %VAL(WPTR_S), IFAIL )
      IF ( IFAIL .NE. 0 ) THEN
        CALL MSG_SETI( 'IFAIL', IFAIL )
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'Error ^IFAIL in NAG routine C06FUF',
     :                STATUS )
        GOTO 99
      END IF

*  Do FFT on Y array
      CALL MSG_PRNT( 'Transforming second input...' )
      IF ( SAME ) THEN
        CALL ARR_COP1D( M3*N3, %VAL(WPTR_XR), %VAL(WPTR_YR), STATUS )
        CALL ARR_COP1D( M3*N3, %VAL(WPTR_XI), %VAL(WPTR_YI), STATUS )
      ELSE
        CALL C06FUF( M3, N3, %VAL(WPTR_YR), %VAL(WPTR_YI), 'S',
     :             %VAL(WPTR_TM), %VAL(WPTR_TN), %VAL(WPTR_S), IFAIL )
        IF ( IFAIL .NE. 0 ) THEN
          CALL MSG_SETI( 'IFAIL', IFAIL )
          STATUS = SAI__ERROR
          CALL ERR_REP( ' ', 'Error ^IFAIL in NAG routine C06FUF',
     :                  STATUS )
          GOTO 99
        END IF
      END IF

*  Perform convolution. We write our output into the WPTR_S array which is
*  big enough to hold both the real and imaginary parts of Z
      WPTR_ZR = WPTR_S
      WPTR_ZI = WPTR_S + ODIMS(1)*ODIMS(2)*VAL__NBD
      CALL MSG_PRNT( 'Cross-correlating...' )
      CALL IXCONV_SCALE( M3, N3, %VAL(WPTR_XR), %VAL(WPTR_XI),
     :                    %VAL(WPTR_YR), %VAL(WPTR_YI),
     :                    %VAL(WPTR_ZR), %VAL(WPTR_ZI), STATUS )

*  Get rid of first dataset workspace
      CALL DYN_UNMAP( WPTR_XR, STATUS )
      CALL DYN_UNMAP( WPTR_XI, STATUS )

*  Second dataset workspace becomes output workspace after copying ZR,ZI from
*  WPTR_S into the Y arrays
      CALL ARR_COP1D( M3*N3, %VAL(WPTR_ZR), %VAL(WPTR_YR), STATUS )
      CALL ARR_COP1D( M3*N3, %VAL(WPTR_ZI), %VAL(WPTR_YI), STATUS )
      WPTR_ZR = WPTR_YR
      WPTR_ZI = WPTR_YI

*  Tranform to create output
      CALL MSG_PRNT( 'Untransforming...' )
      CALL C06FUF( M3, N3, %VAL(WPTR_ZR), %VAL(WPTR_ZI), 'S',
     :             %VAL(WPTR_TM), %VAL(WPTR_TN), %VAL(WPTR_S), IFAIL )
      IF ( IFAIL .NE. 0 ) THEN
        CALL MSG_SETI( 'IFAIL', IFAIL )
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'Error ^IFAIL in NAG routine C06FUF',
     :                STATUS )
        GOTO 99
      END IF

*  Unmap workspace (everything except WPTR_ZR)
      CALL DYN_UNMAP( WPTR_TM, STATUS )
      CALL DYN_UNMAP( WPTR_TN, STATUS )
      CALL DYN_UNMAP( WPTR_S, STATUS )
      CALL DYN_UNMAP( WPTR_ZI, STATUS )

*  Inform user of averages
      CALL MSG_SETR( 'AVX', AVX )
      CALL MSG_PRNT( 'The average of dataset 1 was ^AVX' )
      CALL MSG_SETR( 'AVY', AVY )
      CALL MSG_PRNT( 'The average of dataset 2 was ^AVY' )

*  Copy result to output, adding back in mean if required. At same time
*  rotate the array being copied so that zero shift is at centre.
      CALL USI_GET0L( 'DC_RESTORE', DC_RESTORE, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99
      IF ( DC_RESTORE ) THEN
        RESTORE = AVX*AVY*M3*N3
      ELSE
        RESTORE = 0.0
      END IF

*  Map the output data array
      CALL BDI_MAPR( OFID, 'Data', 'WRITE', ODPTR, STATUS )

*  Bit of history here
      CALL HSI_ADD( OFID, VERSION, STATUS )
      HTXT(1) = 'Input 1 : {INP1}'
      HTXT(2) = 'Input 2 : {INP2}'
      IF ( CYCLIC ) THEN
        HTXT(3) = 'Cyclic convolution'
      ELSE
        HTXT(3) = 'Non-Cyclic convolution'
      END IF
      IF ( DC_RESTORE ) THEN
        HTXT(3) = HTXT(3)(:CHR_LEN(HTXT(3)))//', DC level restored'
      ELSE
        HTXT(3) = HTXT(3)(:CHR_LEN(HTXT(3)))//', DC level not restored'
      END IF
      NLINES = 7
      CALL USI_TEXT( 3, HTXT, NLINES, STATUS )
      CALL HSI_PTXT( OFID, NLINES, HTXT, STATUS )

*  Copy the results to the output dataset. This is now a copy from double
*  precision to single
      CALL IXCONV_COPY3( RESTORE, M3, N3, %VAL(WPTR_ZR),
     :                   %VAL(ODPTR), STATUS )

*  Remove last bit of workspace
      CALL DYN_UNMAP( WPTR_ZR, STATUS )

*  Exit
 99   CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END


*+  IXCONV_SCALE - Cross-corelation of 2d arrays by FFT
      SUBROUTINE IXCONV_SCALE( M, N, XR, XI, YR, YI, ZR, ZI, STATUS )
*
*  Description :
*     Performs cross-corelation of 2d arrays by FFT

*  Method :
*     Removes mean from X and Y in copying them to work area
*     Then makes calls to NAG routines

*  Deficiencies :
*     Horribly inefficient - it copies real data into its own complex
*     arrays, of which 2 in and one out are needed

*  Authors :
*     BHVAD::GKS

*  History :
*     25-Nov-92 Initial version
*     22-Apr-94 This version to go in Asterix program
*      3-May-94 Changes on going to Unix

*  Type Definitions :
      IMPLICIT NONE

*    Global constants :
      INCLUDE 'SAE_PAR'

*    Status :
      INTEGER STATUS

*    Import :
	INTEGER M,N 		    ! Array size
        DOUBLE PRECISION XR(M,N)    ! Input array 1
        DOUBLE PRECISION XI(M,N)    ! Imaginary part - must be zeroed
        DOUBLE PRECISION YR(M,N)    ! Input array 2
        DOUBLE PRECISION YI(M,N)    ! Imaginary part - must be zeroed

*    Export :
      DOUBLE PRECISION 		ZR(M,N)   		! Result - real part
      DOUBLE PRECISION 		ZI(M,N)    		! Result - imag part

*    Local variables :
      INTEGER			I, J
      DOUBLE PRECISION 		SCALEFAC
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Multiply transforms
      SCALEFAC = SQRT(REAL(M*N))
      DO J=1,N
        DO I=1,M
          ZR(I,J)=SCALEFAC*( XR(I,J)*YR(I,J)+XI(I,J)*YI(I,J) )
          ZI(I,J)=SCALEFAC*( XR(I,J)*YI(I,J)-XI(I,J)*YR(I,J) )
	END DO
      END DO

      END

*+
        SUBROUTINE IXCONV_COPY2( MA,NA, A, MB,NB, B, AV, STATUS )

* Copy A to B, subtracting mean
* If B is bigger than A then array is placed in middle and
* remainder is zeroed
* Input is single precision; output double

        IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'

*    Status :
      INTEGER STATUS

* import
        INTEGER MA,NA                          ! length of input array
        REAL A(MA,NA)                              ! array to be copied
        INTEGER MB,NB                          ! length of input array

* export
        DOUBLE PRECISION B(MB,NB)              ! the Output array
        REAL AV                                ! The average subtracted

* local variables
        INTEGER I,J
	INTEGER I2,J2
        REAL S
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Sum of input
      CALL ARR_SUM1R( NA*MA, A, S, STATUS )
      AV = S/REAL(MB*NB)

*    Default OP to -AV
      IF ((MA.LT.MB).OR.(NA.LT.NB)) THEN
        CALL ARR_INIT1D( DBLE(-AV), MB*NB, B, STATUS )
      ELSE
        CALL ARR_INIT1D( 0.0, MB*NB, B, STATUS )
      END IF

*    Copy to middle
      I2 = (MB-MA)/2
      J2 = (NB-NA)/2
      DO J=1,NA
        DO I=1,MA
          B(I+I2,J+J2)=B(I+I2,J+J2)+A(I,J)
        END DO
      END DO

      END


*+
        SUBROUTINE IXCONV_COPY3(ADDIN,M,N,A,B,STATUS)

* Copy A to B, with half period cyclic shift to put ACF spike in middle
* and adding back in mean or whatever
* Input is double precison, output single
        IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'

*    Status :
      INTEGER STATUS

* import
        REAL ADDIN
	INTEGER M
        INTEGER N                              ! length of arrays
        DOUBLE PRECISION A(0:M-1,0:N-1)        ! array to be copied

* export
        REAL B(0:M-1,0:N-1)                    ! the Output array

* local variables
        INTEGER I,J
	INTEGER M2,N2
	INTEGER J2
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

	M2=M/2
	N2=N/2

	DO J=0,N-1
          J2=MOD(J+N2,N)
	  DO I=0,M-1
             B(MOD(I+M2,M),J2)=A(I,J)+ADDIN
	  END DO
	END DO

        END
