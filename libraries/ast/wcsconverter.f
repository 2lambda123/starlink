      PROGRAM WCSCONVERTER

*  Usage:
*     WCSCONVERTER <in file> <encoding> <out file>

*  Description:
*     Reads a FrameSet from "in file" (as a FITS header if possible, 
*     otherwise as an AST dump of a FrameSet), and writes out the 
*     FrameSet to "out file" using the specifie encoding.

*  Parameters:
*     in file
*        A text file containing fits headers or an AST dump of a FrameSet.
*     encoding
*        The name of a FITS encoding (e.g. "FITS-WCS", "NATIVE", etc), or
*        "AST".
*     out file
*        The output file. Contains an AST dump of the FrameSet if
*        "encoding" is "AST", or a set of FITS header cards otherwise.


      IMPLICIT NONE
      INCLUDE 'AST_PAR'
      EXTERNAL SOURCE, SINK

      INTEGER STATUS, FC, OBJECT, IARGC, CHAN, CHR_LEN
      CHARACTER FILE*80, OFILE*80, LINE*255, TEXT*80, ENCODING*50

*
* Check command line arguments have been supplied.
*
      IF( IARGC() .LT. 3 ) THEN
         WRITE(*,*) 'Usage: wcsconverter <in file> <encoding> '//
     :              '<out file>'
         RETURN
      END IF

* 
* Create a FitsChan to store the FITS headers.
*
      STATUS = 0
      FC = AST_FITSCHAN( AST_NULL, AST_NULL, ' ', STATUS )

*
* Open the input text file.
*
      CALL GETARG( 1, FILE )
      OPEN( UNIT=10, FILE=FILE, STATUS='OLD' )

*
* Read each line out of the text file and store it in the FitsChan.
*
      CALL ERR_MARK

      DO WHILE( .TRUE. )
         READ( 10, '(A)', END = 10 ) LINE
         CALL AST_PUTFITS( FC, LINE, 0, STATUS )
      END DO

 10   CLOSE( 10 )

*
* Attempt to read an Object form the FIitsChan.
*
      CALL AST_CLEAR( FC, 'CARD', STATUS )
      OBJECT = AST_READ( FC, STATUS )

      IF( STATUS .NE. 0 ) CALL ERR_ANNUL( STATUS )
      CALL ERR_RLSE

* If no object was read, attempt to read an object from the text file as
* an AST dump.
      IF( OBJECT .EQ. AST__NULL ) THEN
         CALL AST_ANNUL( FC, STATUS )
         OPEN( UNIT=10, FILE=FILE, STATUS='OLD' )
         CHAN = AST_CHANNEL( SOURCE, AST_NULL, ' ', STATUS )
         OBJECT = AST_READ( CHAN, STATUS )
         CALL AST_ANNUL( CHAN, STATUS )
         CLOSE( 10 )          
      END IF

*
* Abort if no object was read.
*
      IF( OBJECT .EQ. AST__NULL ) THEN
         WRITE(*,*) 'wcsconverter: no WCS could be read from ',
     :              file( : chr_len( file ) )
         RETURN


*
* Otherwise write out the object using the specified encoding.
*
      ELSE
         CALL GETARG( 3, OFILE )
         CALL DELETEFILE( OFILE )

         CALL GETARG( 2, ENCODING )
         IF( ENCODING .EQ. 'AST' ) THEN
            OPEN( UNIT=10, FILE=OFILE, STATUS='NEW' )
            CHAN = AST_CHANNEL( AST_NULL, SINK, ' ', STATUS )
            IF( AST_WRITE( CHAN, OBJECT, STATUS ) .NE. 1 ) THEN
               WRITE(*,*) 'wcsconverter: WCS read from ',
     :                    file( : chr_len( file ) ),' could not be '//
     :                    'converted to ',
     :                    encoding( : chr_len(encoding ) ),' format.'
            END IF
            CALL AST_ANNUL( CHAN, STATUS )
            CLOSE( 10 )          

         ELSE
            OPEN( UNIT=10, FILE=OFILE, STATUS='NEW' )
            IF( FC .EQ. AST__NULL ) THEN
               FC = AST_FITSCHAN( AST_NULL, AST_NULL, ' ', STATUS )
            END IF
            CALL AST_SETC( FC, 'ENCODING', ENCODING, STATUS )
            CALL AST_CLEAR( FC, 'CARD', STATUS )

            IF( AST_WRITE( FC, OBJECT, STATUS ) .NE. 1 ) THEN
               WRITE(*,*) 'wcsconverter: WCS read from ',
     :                    file( : chr_len( file ) ),' could not be '//
     :                    'converted to ',
     :                    encoding( : chr_len(encoding ) ),' format.'
            ELSE
               CALL AST_CLEAR( FC, 'CARD', STATUS )
               DO WHILE( AST_FINDFITS( FC, '%f', LINE, .TRUE., 
     :                   STATUS ) )
                 WRITE(10,'(A)') LINE( : 80 )
               END DO
            END IF
            CLOSE( 10 )          

            CALL AST_ANNUL( FC, STATUS )


         END IF
         CALL AST_ANNUL( OBJECT, STATUS )
      END IF


      END


*
*  Delete a file if it exists.
*
      SUBROUTINE DELETEFILE( FILNAM )
      IMPLICIT NONE

      CHARACTER FILNAM*(*)
      LOGICAL EXISTS

      INQUIRE ( FILE   = FILNAM,
     :          EXIST  = EXISTS )

      IF( EXISTS ) THEN
         OPEN ( UNIT=10, FILE=FILNAM, STATUS='OLD' )
         CLOSE ( 10, STATUS='DELETE' )
      END IF

      END


*
*  SOURCE FUNCTION FOR AST_CHANNEL.
*
      SUBROUTINE SOURCE( STATUS )
      IMPLICIT NONE
      INTEGER STATUS
      CHARACTER BUFFER*200
      READ( 10, '(A)', END=99 ) BUFFER
      CALL AST_PUTLINE( BUFFER, LEN( BUFFER ), STATUS )
      RETURN
 99   CALL AST_PUTLINE( BUFFER, -1, STATUS )
      END

*
*  SINK FUNCTION FOR AST_CHANNEL.
*
      SUBROUTINE SINK( STATUS )
      IMPLICIT NONE
      INTEGER STATUS, L
      CHARACTER BUFFER*200

      CALL AST_GETLINE( BUFFER, L, STATUS )
      IF( L .GT. 0 ) WRITE( 10, '(A)' ) BUFFER( : L )

      END
