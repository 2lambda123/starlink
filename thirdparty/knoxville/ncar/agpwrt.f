C
C ---------------------------------------------------------------------
C
      SUBROUTINE AGPWRT (XPOS,YPOS,CHRS,NCHS,ISIZ,IORI,ICEN)
C
      CHARACTER*(*) CHRS
C
C This routine just passes its arguments along to the character-drawing
C routine PWRIT, in the system plot package.  By substituting his/her
C own version of AGPWRT, the user can cause a fancier character-drawer
C to be used.
C
      CALL PWRIT (XPOS,YPOS,CHRS,NCHS,ISIZ,IORI,ICEN)
C
C Done.
C
      RETURN
C
      END
