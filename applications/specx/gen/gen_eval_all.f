*  History:
*      1 Aug 2000 (ajc):
*        Change TYPE * to PRINT *
*        Unused VALUE
*        Drop through on bad given IERR to avoid crashes
*-----------------------------------------------------------------------

      SUBROUTINE gen_eval_all (ierr)

*  If we reach the end of the expression or subexpression then we know
*  we can go ahead and execute all operators remaining on the stack

      IMPLICIT none

*     Formal parameters:

      INTEGER*4 ierr

*     Operand and operator stacks

      INCLUDE  'eval_ae4.inc'

*     Local variables:

*  Ok, go..

      if ( ierr .ne. 0 ) return

D     Print *, '-- gen_eval_all --'
D     PRINT *, '   lev, nopr(lev), ntopr =', lev, nopr(lev), ntopr

      DO WHILE (nopr(lev).gt.0)
D       PRINT *, 'calling do_op for operator ', oper(ntopr)
        CALL gen_do_op (oper(ntopr), ierr)
        IF (ierr.ne.0) RETURN
        nopr(lev)  = nopr(lev)  - 1
        ntopr      = ntopr      - 1
D       PRINT *, 'do_op completed, new value of ntopr =', ntopr
      END DO

      RETURN
      END
