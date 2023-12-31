      SUBROUTINE TCNSMT (IERROR)
C
C LATEST REVISION        JUNE 1984
C
C PURPOSE                TO PROVIDE A SIMPLE DEMONSTRATION OF
C                        CONRECSMTH AND TO TEST CONRECSMTH ON A SINGLE
C                        PROBLEM
C
C USAGE                  CALL TCNSMT (IERROR)
C
C ARGUMENTS
C
C ON OUTPUT              IERROR
C                          AN INTEGER VARIABLE
C                          = 0, IF THE TEST WAS SUCCESSFUL,
C                          = 1, OTHERWISE
C
C I/O                    IF THE TEST IS SUCCESSFUL, THE MESSAGE
C
C                          CONRECSMTH TEST SUCCESSFUL  . . . SEE PLOT TO
C                          VERIFY PERFORMANCE
C
C                        IS PRINTED ON UNIT 6.
C                        IN ADDITION, TWO FRAMES CONTAINING THE CONTOUR
C                        PLOT ARE PRODUCED ON THE MACHINE GRAPHICS
C                        DEVICE.  IN ORDER TO DETERMINE IF THE TEST
C                        WAS SUCCESSFUL, IT IS NECESSARY TO EXAMINE
C                        THESE PLOTS.
C
C PRECISION              SINGLE
C
C
C LANGUAGE               FORTRAN
C
C ALGORITHM              THE FUNCTION
C                          Z(X,Y) = X + Y + 1./((X-.1)**2+Y**2+.09)
C                                   -1./((X+.1)**2+Y**2+.09)
C                        FOR X = -1. TO +1. IN INCREMENTS OF .1 AND
C                            Y = -1.2 TO +1.2 IN INCREMENTS OF .1
C                        IS COMPUTED.
C                        TCNSMT CALLS SUBROUTINES EZCNTR, CONREC, AND
C                        WTSTR TO DRAW TWO LABELLED CONTOUR PLOTS OF THE
C                        ARRAY Z.
C
C PORTABILITY            ANSI FORTRAN77 STANDARD
C
C
C Z CONTAINS THE VALUES TO BE PLOTTED.
C
      REAL            Z(21,25)
C
C SPECIFY COORDINATES FOR PLOT TITLES.  ON AN ABSTRACT GRID WHERE
C THE INTEGER COORDINATES RANGE FROM 0.0 TO 1.0, THE VALUES TX AND TY
C DEFINE THE CENTER OF THE TITLE STRING.
C
      DATA TX/0.42676/, TY/0.97656/
C
C
C INITIALIZE ERROR PARAMETER
C
      IERROR = 0
C
C FILL TWO DIMENSIONAL ARRAY TO BE PLOTTED
C
      DO  20 I=1,21
         X = .1*FLOAT(I-11)
         DO  10 J=1,25
            Y = .1*FLOAT(J-13)
            Z(I,J) = X+Y+1./((X-.10)**2+Y**2+.09)-
     1               1./((X+.10)**2+Y**2+.09)
   10    CONTINUE
   20 CONTINUE
C
C SELECT NORMAIZATION TRANS NUMBER TO WRITE TITLES
C
      CALL GSELNT (0)
C
C ENTRY EZCNTR REQUIRES ONLY THE ARRAY NAME AND ITS DIMENSIONS
C
C THE TITLE FOR THIS PLOT IS
C
C  DEMONSTRATION PLOT FOR EZCNTR ENTRY OF CONRECSMTH
C
      CALL WTSTR (TX,TY,
     1           'DEMONSTRATION PLOT FOR EZCNTR ENTRY OF CONRECSMTH',
     2           2,0,0)
      CALL EZCNTR (Z,21,25)
C
C
C ENTRY CONREC ALLOWS USER SPECIFICATION OF PLOT PARAMETERS, IF DESIRED
C
C IN THIS EXAMPLE, THE LOWEST CONTOUR LEVEL (-4.5), THE HIGHEST CONTOUR
C LEVEL (4.5), AND THE INCREMENT BETWEEN CONTOUR LEVELS (0.3) ARE
C SPECIFIED.
C
C THE TITLE FOR THIS PLOT IS
C
C  DEMONSTRATION PLOT FOR CONREC ENTRY OF CONRECSMTH
C
      CALL WTSTR (TX,TY,
     1           'DEMONSTRATION PLOT FOR CONREC ENTRY OF CONRECSMTH',
     2           2,0,0)
      CALL CONREC (Z,21,21,25,-4.5,4.5,.3,0,0,0)
      CALL FRAME
C
      WRITE (6,1001)
      RETURN
C
 1001 FORMAT (' CONRECSMTH TEST SUCCESSFUL',24X,
     1        'SEE PLOT TO VERIFY PERFORMANCE')
C
C
C---------------------------------------------------------------------
C
C REVISION HISTORY
C
C     JUNE 1984                  CONVERTED TO FORTRAN 77 AND GKS
C
C---------------------------------------------------------------------
      END
