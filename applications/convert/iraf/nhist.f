      subroutine nhist (im, nlin, nchars)
      logical Memb(1)
      integer*2 Memc(1)
      integer*2 Mems(1)
      integer Memi(1)
      integer*4 Meml(1)
      real Memr(1)
      double precision Memd(1)
      complex Memx(1)
      equivalence (Memb, Memc, Mems, Memi, Meml, Memr, Memd, Memx)
      common /Mem/ Memd
      integer im
      integer nlin
      integer nchars
      integer szlin
      integer sp
      integer rp
      integer hist
      save
         call smark (sp)
         call salloc (hist, 1023 , 2)
         call amovc (memc((((im+200 +485)-1)*2+1)) , memc(hist), 1023 )
         nlin = 0
         szlin = 0
         rp=hist
110      if (.not.(memc(rp) .ne. 0)) goto 112
            if (.not.( memc(rp) .eq. 10 )) goto 120
               nlin = nlin + 1
               szlin = 0
               goto 121
120         continue
               szlin = szlin + 1
121         continue
111         rp=rp+1
            goto 110
112      continue
         if (.not.( szlin .ne. 0 )) goto 130
            nlin = nlin + 1
130      continue
         nchars = rp - hist
         call sfree(sp)
100      return
      end
