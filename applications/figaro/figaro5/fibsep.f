      subroutine fibsep( STATUS )
*+
* Name:
*    FIBSEP

* Invocation:
*    CALL FIBSEP( STATUS )

* Purpose:
*     Isolate output from different fibres

* Description:
*     Handles an 'FIBSEP' command, producing an image on any suitable
*     device. The user can then select fibres at either end (in the Y
*     direction), and give a number. The program then will locate the
*     fibre spectra in between. This assumes that a correction has been
*     made previously for S-distortion. Originally based on the routine
*     IMAGE.
*
* Parameters:
*     IMAGE = FILE (Read)
*        The name of the input image
*     YSTART = REAL (Read)
*        The first Y value to be displayed.
*     YEND = REAL (Read)
*        The last Y value to be displayed.
*     XSTART = REAL (Read)
*        The first X value to be displayed.
*     XEND = REAL (Read)
*        The last X value to be displayed.
*             X and Y are the horizontal and vertical directions
*             - as displayed - respectively.  The first value for each
*             is 1.
*     LOW = REAL (Read)
*        The minimum count level for the display, for
*             the first image.
*     HIGH = REAL (Read)
*        The maximum count level for the display, for
*             the first image.
*     PLOTDEV = CHARACTER (Read)
*        The name of the plotting device
*     OUTPUT = FILE (Write)
*        The name of the output image
*     LOG = LOGICAL (Read)
*        To take logarithms of the image to display it

* History:
*      1988 T.N.Wilkins Manchester, based on HIMAGE, which in turn was
*      based on the FIGARO function IMAGE written by Keith Shortridge.
*      29/11/88 TNW Changed to use getwork
*      AJH Replace dsa_map.. access modes from 'r' to 'READ'
*-
      implicit none
*
*     High and low limits
*
      include 'PRM_PAR'
      include 'SAE_PAR'
*
*     Local variables
*
      integer ndim,dims(3),nl,ni,ixst,idims(2)
      integer i,nelm
      integer status,start,ichst,ichen,ixen,zptr
      integer nxp,nyp,tstart,flev,nlevs
      integer nfound,yest,yeen,slot,dyn_element
      real centre(200),widths(200)
      logical plog,old
      real low,high,dummy1,dummy2
      integer iwork,lu
      character chars*64,ffile*72
      include 'DYNAMIC_MEMORY'
*
*     Initial values
*
*
*     Get the object name
*
      status = SAI__OK
      call dsa_open(status)
      call dsa_input('image','image',status)
*
*     Assuming this is a file name, open it (it may not be open)
*     and assume that the actual data is the .Z.DATA component.
*
*     We now have an object name, start to find out about it.
*
      call dsa_data_size('image',3,ndim,dims,nelm,status)
      if (status.ne.SAI__OK)  then
        go to 500
      end if
      if (ndim.ne.2) then
        call par_wruser('This is not an image',status)
        go to 500
      end if
*
      nl=dims(1)
      ni=dims(2)
      call dsa_map_data('image','READ','float',start,slot,status)

*  (value of slot here not used later)

      if (status.ne.SAI__OK)  then
        go to 500
      end if
      start = dyn_element(start)
      call gr_init
      call par_rdkey('old',.false.,old)
      if(old) then
        call par_rdchar('file','fibres.lis',ffile)
        call dsa_open_text_file(ffile,' ','old',.false.,lu,chars,
     :     status)
        read(lu,'(i5)')nfound
        do i = 1, nfound
          read(lu,'(e12.5)')centre(i)
          read(lu,'(e12.5)')widths(i)
        end do
        call dsa_free_lu(lu,status)
      else
*
*     Get parameters for display
*
        call dsa_axis_range('image',1,' ',.false.,dummy1,dummy2,ichst,
     :     ichen,status)
        call dsa_axis_range('image',2,' ',.false.,dummy1,dummy2,ixst,
     :     ixen,status)
        call par_rdval('LOW',VAL__MINR,VAL__MAXR,0.,' ',low)
        call par_rdval('HIGH',VAL__MINR,VAL__MAXR,1000.,' ',high)
        nxp = ichen-ichst+1
        nyp = ixen-ixst+1
        call par_rdkey('LOG',.false.,plog)

* Display image
* =============

* Read in device to plot on

        call get_grey('DEVICE',status)
        if(status.ne.SAI__OK) goto 500

*  Check colour facilities

        call pgqcol(flev,nlevs)

* Perform greyscale plotting in this

        tstart = start + 4*(ixst-1)*nl
        call getwork(nxp*nyp,'int',iwork,slot,status)
        if(status.ne.SAI__OK) goto 500
        call pgenv(real(ichst),real(ichen),real(ixst),real(ixen),0,-2)
        call gryplt(dynamic_mem(tstart),dynamic_mem(iwork),nl,nyp,nxp,
     :        ichst,nlevs,low,high,.false.,plog,4)
        call dsa_free_workspace(slot,status)

* Get user to indicate end points with a cursor, and locate the fibre
* spectra from these.

        call findfib(dynamic_mem(start),nl,ni,ichst,ixst,centre,nfound,
     :            widths)
        call par_rdchar('file','fibres.lis',ffile)
        call dsa_open_text_file(ffile,' ','new',.true.,lu,chars,status)
        write(lu,'(i5)')nfound
        do i = 1, nfound
          write(lu,'(e12.5)')centre(i)
          write(lu,'(e12.5)')widths(i)
        end do
        call dsa_free_lu(lu,status)
      end if

* Get name of output file

      call dsa_output('output','output','image',1,0,status)
      idims(1) = nl
      idims(2) = nfound
      call dsa_reshape_data('output','image',2,idims,status)
      call dsa_reshape_axis('output',1,'image',1,1,idims,status)
      call dsa_reshape_axis('output',2,'image',2,1,idims(2),status)
      call dsa_map_data('output','WRITE','float',zptr,slot,status)
      if(status.ne.SAI__OK) then
        goto 500
      end if
      zptr = dyn_element(zptr)

* Copy data to output file

      yest = nint(centre(1) - widths(1)*2.0)
      yeen = nint((centre(1) + widths(1)*1.5 + centre(2)
     :    - widths(2)*1.5)*0.5)
      call fig_xtract(dynamic_mem(start),nl,ni,yest,yeen,
     :       dynamic_mem(zptr))
      do i = 2, nfound-1
        yest = yeen
        yeen = nint((centre(i) + widths(i)*1.5 + centre(i+1)
     :      - widths(i+1)*1.5)*0.5)
        call fig_xtract(dynamic_mem(start),nl,ni,yest,yeen,
     :    dynamic_mem((i-1)*4*nl+zptr))
      end do
      yeen = nint(centre(nfound) + widths(nfound)*2.0)
      call fig_xtract(dynamic_mem(start),nl,ni,yest,yeen,
     :    dynamic_mem(zptr+(nfound-1)*4*nl))
*
*     Tidy up
*
  500 continue
      call dsa_close(status)
      end
