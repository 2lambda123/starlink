      subroutine fibdisp( STATUS )
*+
* Name:
*    FIBDISP

* Invocation:
*    CALL FIBDISP( STATUS )
*
* Purpose:
*    To analyse a fibre cube.

* Description:
*    This cube should have been created using FIB2CUBE. Options available
*    include displaying planes of the cube and profiles and fitting
*    Gaussians etc. to these profiles.

* Parameters:
*    CUBE = FILE (Read)
*        Cube for display
*          This should be a file produced by FIB2CUBE, containing
*          a .FIBRE structure.
*    YSTART = REAL (Read)
*        analysis lower limit
*            The data between the limits ystart and yend is extracted
*            and the resultant spectrum is used to locate the lines.
*    YEND = REAL (Read)
*        analysis upper limit
*            The data between the limits ystart and yend is extracted
*            and the resultant spectrum is used to locate the lines.
*    YBLOCK = REAL (Read)
*        Enter analysis x-sect width
*            Each window is of this width (except perhaps the final one).
*    TSTART = REAL (Read)
*        analysis lower limit
*            The data between the limits tstart and tend is extracted
*            and the resultant spectrum is used to locate the lines.
*    TEND = REAL (Read)
*        analysis upper limit
*            The data between the limits tstart and tend is extracted
*            and the resultant spectrum is used to locate the lines.
*    TBLOCK = REAL (Read)
*        Enter analysis blocking width in 3rd dimension
*            Each window is of this width (except perhaps the final one).
*    DEVICE = CHARACTER (Read)
*        Device for display
*    ITERATION = INTEGER*2 (Read)
*        New value of itteration
*    OUTABLE = FILE (Write)
*        Name for EXTATIC file
*    VCORR = REAL (Read)
*        correction to apply to radial velocities
*    TOLS = CHARACTER (Read)
*        For use in batch only
*    FITRAT = REAL (Read)
*        Ratio of widths, heights, or separation, for double fits
*    CALRAT = INTEGER (Read)
*        Ratio of number of iteration to default
*    OUTPUT = FILE (Write)
*        Name for output file
*    FIT_MODEL = CHARACTER (Read)
*        Model of fit to perform
*    LOW = REAL (Read)
*        Minimum value for display
*    HIGH = REAL (Read)
*        Maximum value for display
*    ABSORPTION = LOGICAL (Read)
*        Allow fitting of absorption lines
*    BOUNDS = LOGICAL (Read)
*        Perform bounded fits to lines (in batch)
*    HARDCOPY = LOGICAL (Read)
*        produce hardcopy plots of fits from cube
*    TABLE = LOGICAL (Read)
*        produce table of fits from cube
*    PRINT = LOGICAL (Read)
*        Produce print out of rotation curves
*    SHAPE = LOGICAL (Read)
*        Carry out shape analysis
*    KEEP_ITT = LOGICAL (Read)
*        Keep itteration files'
*    FIT = LOGICAL (Read)
*        perform fitting
*    AIC = LOGICAL (Read)
*        Use Akiakes information criterion for fitting
*    WEIGHTS = LOGICAL (Read)
*        Use weights for fitting
*    PRFITS = LOGICAL (Read)
*        Print out details of fitting
*    FULL = LOGICAL (Read)
*        Print out full details of fits in table
*
* Subroutine/functions referenced:
*     ACCRES           : Access results structure
*     DATA_WINDOW      : Automatic fitting of Gaussians etc.
*     FIBMEN           : Main menu
*     FIBOUT           : Create various output
*     FIBSLFIL         : Take a slice through the cube and write it to a file
*     FIBSLICE         : Take slice through cube and plot it
*     APPLY_TOLS       : Set/apply tolerances
*     GTPROF           : Analyse line profile
*     HEXDISPS         : Display plane of sorted "cube" (hexagonal array)
*     HEXPRARR         : Display array of profiles (hexagonal array)
*     MAPCUBE          : Map data arrays
*     RECTDISPS        : Display plane of sorted "cube" (rectangular array)
*     RECTPRARR        : Display array of profiles (rectangular array)
*
*     GETWORK          : Get virtual memory
*     GET_VM           : Get virtual memory (mixed data types)
*     GR_INIT          : Initialise graphics common blocks
*
*     DSA_AXIS_RANGE   : Get axis limits
*     DSA_FREE_WORKSPACE (DSA): Free workspace
*     DSA_GET_RANGE    : Get min/max of main data array
*     PAR_GIVEN (PAR)(l): Find out parameter given on command line
*     PAR_QNUM (PAR)(l): Get number from user
*     PAR_RDCHAR  (PAR): Get character string from user
*     PAR_RDKEY   (PAR): Get key parameter response from user
*     PAR_WRUSER  (PAR): Write character string to user

* Authors:
*   TNW: T.N.Wilkins Manchester, Cambridge from 2/89
*   ACD: A C Davenhall Edinburgh

* History:
*   TNW 1988 Original version
*   TNW 29/11/88 Changed to use GETWORK
*   TNW 20/12/88 To remove directory name from file name
*   TNW 17/1/89 Addition of parameter FIT
*   TNW 14/12/89 Order of menu changed
*    "  3/9/91 Change to call of FIBSLFIL
*    "  28/5/92 Change to call of FIBOUT
*   Set iteration in FIBMEN, TNW 30/9/93
*   ACD 18/12/00 made data types consistent in call to FIBMEN
*-
      implicit none
      character ftype*10
      integer chr_len,tlen,i,len1
      integer misptr,plane
      integer iwork
      integer status
      integer start,stop
      include 'SAE_PAR'
      include 'arc_dims'
      integer ref,iopt,slot2,slot3,nels,pstat,tst,tend
      integer iwork1,iwork2,iwork3,get_parnum,ival1,ival2
      integer iter4

* Array type, 1=rect, 2=hex.

      integer atype
      real value,size,xr(2),yr(2),datmin,datmax
      character*79 chars,limtyp*1
      logical loop,disp,limit,par_given
      logical firstout,fit,par_quest,par_qnum,qstat
      integer OPT_PLRES, OPT_PLDAT, OPT_PROF, OPT_HSLI, OPT_VSLI,
     :       OPT_XFIL, OPT_CHECK, OPT_TOTAL, OPT_LIMIT,
     :       OPT_TOLS, OPT_LOOK, OPT_DEL, OPT_DEF, OPT_OUT, OPT_EXIT,
     :       OPT_AUTO, OPT_CUBAN
      parameter (OPT_PLRES = 1, OPT_PLDAT = 2, OPT_PROF = 3,
     :           OPT_HSLI= 4, OPT_VSLI = 5, OPT_XFIL = 6,
     :           OPT_CHECK = 9, OPT_TOTAL = 10, OPT_LIMIT = 11,
     :           OPT_TOLS = 12, OPT_LOOK = 13, OPT_DEL = 14,
     :           OPT_DEF = 15, OPT_OUT = 16, OPT_EXIT = 17,
     :           OPT_AUTO = 18, OPT_CUBAN = 19)
      include 'PRM_PAR'
      character dynamic_chars

* Fitting control common block

      include 'opt_cmn'

      include 'DYNAMIC_MEMORY'
      equivalence (dynamic_mem,dynamic_chars)

      line_count = 1

      status = SAI__OK

      call gr_init
      call arc_init(.false.)
      call read_defaults(status)

* Get fitting parameters

      call par_rdkey('keep_itt',.false.,keep_itt)
      call par_rdkey('prfits',.true.,prfits)

* Get number to multiply default numbers of iterations

      if(par_given('calrat')) then
        call par_rdval('calrat',0.01,100.0,1.0,' ',calrat)
      else
        calrat = 1.0
      end if

      call par_rdkey('fit',.true.,fit)

      firstout = .true.
      limit = .false.
      disp = .false.
      status = SAI__OK

*   Open dsa system and input spectrum, and get its name

      call two_open('cube',3,status)

* Map data arrays
*
*  Note that XPTR is the array index for the array which corresponds
*  to X in a spatial sense, likewise YPTR. D_XPTR is the pointer index
*  to the wavelengths array. This means that at present D_XPTR corresponds
*  to the .X.DATA array, XPTR to .Y.DATA and YPTR to .T.DATA. The names
*  X, Y, T will eventually be replaced for the axis arrays, when the
*  axix are refered to by number only.

      call mapcube(ftype,.false.,.false.,status)
      if(status.ne.SAI__OK) then
        goto 500
      end if

      tlen = chr_len(ftype)
      if(ftype(:tlen).eq.'RECT') then
        atype = 1
      else if(ftype(:tlen).eq.'HEX') then
        atype = 2
      else
        atype = 0
      end if

      if(atype.eq.1) then
        limtyp = ' '
      else
        limtyp = 'U'
      end if

      if(batch) then
        if(fit) then
          call data_window(status)
        end if
      else
        nels = spdim1*spdim2*val__nbw
        if(atype.eq.1) then
          nels = nels + spdim1*spdim2*val__nbr
        else if(atype.eq.2) then
          nels = nels * 2
        end if
        call getvm(nels,ref,slot2,status)
        if(atype.eq.2) then
          misptr = ref + spdim1*spdim2*val__nbw
        end if
      end if

* Get range of main data array

      call dsa_get_range('data',datmin,datmax,status)

      loop = .not.batch
      do while(loop)
        iter4 = iteration
        call fibmen(iopt,limit,iter4,status)
        iteration = iter4
        if(status.ne.SAI__OK) then
          loop = .false.
        else if(iopt.eq.OPT_PLRES) then

*    Display plane of results cube

          plane = 0
          do while(plane.eq.SAI__OK)
            call par_qstr('Parameter ("??" for help)?',' ',.false.,
     :        .false.,chars)
            if(chars(:2).eq.'??') then

*         List parameters

              len1 = 0
*              tst = parptr
              do i = 1, mxpars
	      start=((i-1)*10)+1
	      stop= start+9
*                tend = tst + 9
*                call chr_putc(dynamic_chars(tst:tend),chars,len1)
                call chr_putc(parval(start:stop),chars,len1)
                if((len1.ge.60).or.(i.eq.mxpars)) then
                  call par_wruser(chars(:len1),pstat)
                  len1 = 0
                else
                  call chr_putc(' ',chars,len1)
                end if
                tst = tst + 10
              end do
              call par_wruser('Note that this is case-sensitive',pstat)
            else

*          Get plane corresponding to parameter

              plane = get_parnum(chars(:chr_len(chars)))
            end if
          end do
          if(atype.eq.2) then

* If "HEX" then display with hexagonal matrix

            call hexdisps(%VAL(d_rptr),mxpars,
     :          dynamic_mem(misptr),plane,dynamic_mem(xdptr),
     :          dynamic_mem(xptr),dynamic_mem(yptr),size,xr,yr,limit,
     :          disp,.true.,%VAL(staptr))
          else if(atype.eq.1) then

* Display using GKS cell array

            iwork = ref + spdim1 * spdim2 * val__nbw
            call rectdisps(%VAL(d_rptr),mxpars,
     :           dynamic_mem(xptr),dynamic_mem(yptr),dynamic_mem(iwork)
     :          ,plane,xr,yr,limit,disp,.true.,%VAL(staptr))
          end if
        else if(iopt.eq.OPT_PLDAT) then

*   Display plane of data

* Get plane of cube to display

          qstat = par_qnum('plane',1.0,real(wavdim),1.0,.true.,'pixels',
     :          value)
          plane = nint(value)
          if(atype.eq.2) then

* If "HEX" then display with hexagonal matrix

            call hexdisps(dynamic_mem(d_sptr),wavdim,
     :         dynamic_mem(misptr),plane,dynamic_mem(xdptr),
     :         dynamic_mem(xptr),dynamic_mem(yptr),size,xr,yr,limit,
     :         disp,.false.,%VAL(staptr))
          else if(atype.eq.1) then

* Display using GKS cell array

            iwork = ref + spdim1 * spdim2 * val__nbw
            call rectdisps(dynamic_mem(d_sptr),wavdim,
     :            dynamic_mem(xptr),dynamic_mem(yptr),
     :            dynamic_mem(iwork),plane,xr,yr,limit,disp,.false.
     :           ,%VAL(staptr))
          end if

        else if((iopt.ge.3).and.(iopt.le.7)) then

          if(.not.disp) then

*   Attempt to do an action requiring display of array, when this is not
*   available

            call par_wruser(
     :'Use CHECK, TOTAL, DATA or RESULTS option to provide a means of',
     :        pstat)
            call par_wruser('choosing profiles',pstat)

          else if(iopt.eq.OPT_PROF) then

*   Look at line profiles

            call gtprof(dynamic_mem(ref),dynamic_mem(d_sptr),
     :         dynamic_mem(xptr),dynamic_mem(yptr),dynamic_mem(xdptr)
     :        ,%VAL(totptr),atype.eq.2,status)
            disp = .false.

          else if(iopt.eq.OPT_HSLI) then

*    Take horizontal slice through data

            nels = spdim1*2+(spdim1*wavdim)
            call getwork(nels,'int',iwork1,slot3,status)
            if(status.eq.SAI__OK) then
              iwork2 = iwork1+spdim1*val__nbi
              iwork3 = iwork2+spdim1*val__nbi
              call fibslice(dynamic_mem(d_sptr),spdim1,spdim2,wavdim,
     :             dynamic_mem(iwork1),dynamic_mem(iwork2),spdim1,
     :             dynamic_mem(xptr),dynamic_mem(yptr),
     :             dynamic_mem(xdptr),.true.,atype.eq.2,
     :             dynamic_mem(iwork3),size)
              call dsa_free_workspace(slot3,status)
            end if
            disp = .false.
          else if(iopt.eq.OPT_VSLI) then
            nels = spdim2*2+(spdim2*wavdim)
            call getwork(nels,'int',iwork1,slot3,status)
            if(status.eq.SAI__OK) then
              iwork2 = iwork1+spdim2*val__nbi
              iwork3 = iwork2+spdim2*val__nbi

*    Take vertical slice through data

              call fibslice(dynamic_mem(d_sptr),spdim1,spdim2,wavdim,
     :              dynamic_mem(iwork1),dynamic_mem(iwork2),spdim2,
     :              dynamic_mem(xptr),dynamic_mem(yptr),
     :              dynamic_mem(xdptr),.false.,atype.eq.2,
     :              dynamic_mem(iwork3),size)
              call dsa_free_workspace(slot3,status)
            end if
            disp = .false.
          else if(iopt.eq.OPT_XFIL) then

*   Create file from X cut through cube

            nels = spdim1*2
            call getwork(nels,'int',iwork1,slot3,status)
            if(status.eq.SAI__OK) then
              iwork2 = iwork1+spdim1*val__nbi
              call fibslfil(dynamic_mem(iwork1),dynamic_mem(iwork2),
     :              spdim1,dynamic_mem(xptr),dynamic_mem(yptr),
     :              dynamic_mem(xdptr),.true.,atype.eq.2,size)
              call dsa_free_workspace(slot3,status)
            end if
          else

*   if(iopt.eq.7) then - but it must be so don't test

*   Create file from Y cut through cube

            nels = spdim2*2
            call getwork(nels,'int',iwork1,slot3,status)
            if(status.eq.SAI__OK) then
              iwork2 = iwork1+spdim2*val__nbi
              call fibslfil(dynamic_mem(iwork1),dynamic_mem(iwork2),
     :                spdim1,dynamic_mem(xptr),dynamic_mem(yptr),
     :                dynamic_mem(xdptr),.false.,atype.eq.2,size)
              call dsa_free_workspace(slot3,status)
            end if
          end if

        else if(iopt.eq.OPT_CHECK) then

*   Check-display line profiles as an array

          disp = par_quest('Softcopy plot?',.true.)
          if(atype.eq.2) then
            call hexprarr(dynamic_mem(d_sptr),%VAL(totptr),
     :           dynamic_mem(xdptr),dynamic_mem(xptr),dynamic_mem(yptr)
     :           ,size,xr,yr,limit,disp,.true.,datmin,datmax,1)
          else
            call rectprarr(dynamic_mem(d_sptr),dynamic_mem(xptr),
     :            dynamic_mem(yptr),%VAL(totptr),xr,yr,limit,
     :            disp,.true.,datmin,datmax,1)
          end if
        else if(iopt.eq.OPT_TOTAL) then

*   Display total intensity

          if(atype.eq.2) then
            call hexdisps(%VAL(totptr),1,
     :           dynamic_mem(misptr),1,dynamic_mem(xdptr),
     :           dynamic_mem(xptr),dynamic_mem(yptr),size,xr,yr,limit,
     :           disp,.false.,%VAL(staptr))
          else
            iwork = ref + spdim1 * spdim2 * val__nbw
            call rectdisps(%VAL(totptr),1,
     :           dynamic_mem(xptr),dynamic_mem(yptr),dynamic_mem(iwork)
     :           ,1,xr,yr,limit,disp,.false.,%VAL(staptr))
          end if
        else if(iopt.eq.OPT_LIMIT) then

*     Toggle limiting of range of data to consider, get range if we
*     switch it on.

          limit = .not.limit
          if(limit) then
            call dsa_axis_range('data',2,limtyp,.false.,xr(1),xr(2),
     :            ival1,ival2,status)
            call dsa_axis_range('data',3,limtyp,.false.,yr(1),yr(2),
     :            ival1,ival2,status)
            call canaxlim(2)
            call canaxlim(3)
          end if
        else if(iopt.eq.OPT_TOLS) then

*   Apply/set tolerances

          call apply_tols(.false.,status)

        else if(iopt.eq.OPT_LOOK) then

*   Look at values of results block

          call look(%VAL(d_rptr),.true.,%VAL(staptr)
     :                  ,%VAL(d_vptr))

        else if(iopt.eq.OPT_DEL) then

*   Delete bad fits

          call delfit(%VAL(d_rptr),mxpars,spdim1,spdim2,nyp,disp,
     :       dynamic_mem(xptr),dynamic_mem(yptr),dynamic_mem(xdptr),
     :       atype.eq.2)

        else if(iopt.eq.OPT_DEF) then

*    Define

*          call new_anal(dynamic_chars(idsptr:idsend),
          call new_anal(idstring,
     :       %VAL(d_wptr),%VAL(d_cptr),status)

        else if(iopt.eq.OPT_OUT) then

*    Output options

          call fibout(firstout,atype.eq.2,status)

        else if(iopt.eq.OPT_EXIT) then

*    Exit

          loop = .false.
        else if(iopt.eq.OPT_AUTO) then

*    Fit Gaussians etc. to data

          call data_window(status)

        else if(iopt.eq.OPT_CUBAN) then

*    Cuban-style display etc. This is better for large data files, since
*    is easier to move around.

          call cuban(dynamic_mem(xptr),dynamic_mem(yptr),atype.eq.2,
     :         disp,size,dynamic_mem(d_sptr),dynamic_mem(xdptr),
     :         %VAL(totptr),datmin,datmax,
     :         %VAL(staptr),status)

        end if
      end do
      if(batch) then

*    Output options-batch mode

        call fibout(firstout,atype.eq.2,status)
      end if

* Close graphics

      call clgrap

* Close files

  500 continue
      call unmap_res(status)
      call dsa_close(status)
      end
