/*+
 * Name:
 *    run_specx

 * Purpose:
 *    Sets up signal handling and runs the Specx main routine.
 
 * Language:
 *    ANSI C

 * Description:
 *    This function sets up handlers for
 floating point exception (SIGFPE),
 access violatyions (SIGSEGV), and interupt (SIGINT) signals,
 *    and then 
 *    activates the main Specx Fortran subroutine. The signal handling is 
 *    done is C because there seems to be no way of doing a long jump in 
 *    fortran (i.e. a GOTO from one subroutine back to a place in a higher 
 *    level subroutine). The standard C library functions "longjmp" and 
 *    "setjmp" are therefore used for this purpose. There is a restriction on 
 *    the use of these library functions in that the function into which the 
 *    jump is to be made must still be active at the time of the jump (i.e. it 
 *    must not have returned). The only place to put a function so that it is 
 *    guaranteed not to have returned is at the very top level (the scl_main.f 
 *    routine would have done were it not for the fact that the destination of 
 *    the jump must be written in C). For this reason, it is necessary to put 
 *    a C layer on top of the main dipso subroutine.

 * Notes:
 *    To produce the executable, this function must first be compiled
 *    to produce an object module ("cc -c run_specx.c"), and then linked in
 *    with the other Specx routines using f77
 *    ("f77 -o specx run_specx.o scl_main.f ...").

 * Authors:
 *    dsb: David Berry (STARLINK)
 *    hme: Horst Meyerdierks (UoE, Starlink)
 *    {enter_new_authors_here}

 * History:
 *    20 Sep 1994 (dsb):
 *       Original version.
 *    05 Oct 1995 (hme):
 *       Copied and adapted from Dipso for use in Specx.
 *    {enter_changes_here}

 * Bugs:
 *    {note_any_bugs_here}

*-
*/


#include <signal.h>
#include <setjmp.h>
#include "f77.h"

#if defined (sun4_Solaris)

#include <floatingpoint.h>


#elif defined( alpha_OSF1 ) || defined( mips )

#define main MAIN__   
void for_rtl_init_( int*, char **);
int for_rtl_finish_( void );


#elif defined( sun4 )

#include <floatingpoint.h>
#define main MAIN_



#endif

void hand1( int );
void hand2( int );
struct sigaction act, oact;

extern F77_SUBROUTINE(scl_main)( INTEGER(n) );
extern F77_SUBROUTINE(ndf_end)( INTEGER(status) );
extern F77_SUBROUTINE(hds_stop)( INTEGER(status) );


/*  Global Variables: */
jmp_buf here;      

/*  Entry Point: */
void main( int argc, char *argv[])
{

/*  Local Variables: */
      DECLARE_INTEGER(n);


/*  Initialise the fortran run-time-library data structures (OSF + mips). */

#if defined( alpha_OSF1 ) || defined( mips )
      for_rtl_init_( &argc, argv );


/*  Initialise the fortran run-time-library data structures (sun). */

#elif defined( sun4 ) || defined ( sun4_Solaris )
      f_init();

/*  Switch off ieee floating point exception handling, so that it doesn't
 *  interfere with the handling set up by the following calls to "signal".
 */
      ieee_handler( "set", "common", SIGFPE_ABORT );
      nonstandard_arithmetic();
 
#endif

/*  Use the setjmp function to define here to be the place to which the
 *  signal handling function will jump when a signal is detected. Zero is
 *  returned on the first invocation of setjmp. If a signal is detected,
 *  a jump is made into setjmp which then returns a positive signal 
 *  identifier. */
      n = setjmp( here );


/*  Set up handlers for the signals we want to catch. If any of these
 *  signals occur, the function "hand" will be called.
 *  One requirement in Specx is to catch user interrupts via Ctrl-C.
 *  These should in effect be ignored. The other requirement is that
 *  signals that abort Specx should cause NDF and HDS to be closed down
 *  properly so that open HDS files are not corrupted.
 *  The first requirement has been addressed by Remo Tilanus and the
 *  list of signals is (explanation after Nemeth et al., p. 65):
 *  SIGHUP   hangup, generated when terminal disconnects
 *  SIGINT   interrupt (Ctrl-C)
 *  SIGQUIT  quit
 *  SIGILL   illegal instruction
 *  SIGTRAP  trace trap
 *  SIGABRT  IOT trap - abort process
 *  SIGFPE   arithmetic exception
 *  SIGBUS   bus error
 *  SIGSEGV  segmentation violation
 *  SIGSYS   bad argument to system call
 *  Other signals that by default terminate the process are:
 *  SIGEMT    EMT trap - EMT instruction
 *  SIGKILL   kill
 *  SIGPIPE   write on pipe with no reader
 *  SIGALRM   alarm clock timeout
 *  SIGTERM   software termination signal
 *  SIGXCPU   CPU time limit exceeded
 *  SIGXFSZ   file size limit exceeded
 *  SIGVTALRM virtual time alarm
 *  SIGPROF   profiling timer alarm
 *  SIGUSR1   first user-defined signal
 *  SIGUSR2   second user-defined signal
 */
      act.sa_handler = hand1;
      act.sa_flags = 0;
      sigemptyset (&act.sa_mask);
      sigemptyset (&oact.sa_mask);
      sigaction( SIGHUP,   &act, &oact );
      sigaction( SIGINT,   &act, &oact );
      sigaction( SIGQUIT,  &act, &oact );
      sigaction( SIGILL,   &act, &oact );
      sigaction( SIGTRAP,  &act, &oact );
      sigaction( SIGABRT,  &act, &oact );
      sigaction( SIGFPE,   &act, &oact );
      sigaction( SIGBUS,   &act, &oact );
      sigaction( SIGSEGV,  &act, &oact );
      sigaction( SIGSYS,   &act, &oact );

      act.sa_handler = hand2;
      sigaction( SIGEMT,   &act, &oact );
      sigaction( SIGKILL,  &act, &oact );
      sigaction( SIGPIPE,  &act, &oact );
      sigaction( SIGALRM,  &act, &oact );
      sigaction( SIGTERM,  &act, &oact );
      sigaction( SIGXCPU,  &act, &oact );
      sigaction( SIGXFSZ,  &act, &oact );
      sigaction( SIGVTALRM,&act, &oact );
      sigaction( SIGPROF,  &act, &oact );
      sigaction( SIGUSR1,  &act, &oact );
      sigaction( SIGUSR2,  &act, &oact );

/*  Now call the specx main routine, passing zero on the initial entry, but
 *  a positive signal identifier if a subsequent entry is being made as a
 *  result of a trapped signal. */
      F77_CALL(scl_main)( INTEGER_ARG( &n )  );

/*  Free the data structures used by the fortran run-time-library */

#if defined( alpha_OSF1 ) || defined( mips )

      for_rtl_finish_();

#elif defined( sun4 ) || defined ( sun4_Solaris )

      f_exit();

#endif


}




/*+
 * Name:
 *    hand1

 * Purpose:
 *    Called when an ignorable exception or interrupt occured.
 
 * Language:
 *    ANSI C

 * Description:
 *    This function is called when an exception or interrupt
 *    signal is detected. It just jumps back to the location defined by
 *    the global variable "here", returning the signal value.

 * Authors:
 *    DSB: David Berry (STARLINK)
 *    {enter_new_authors_here}

 * History:
 *    20-SEP-1994 (DSB):
 *       Original version.
 *    {enter_changes_here}

 * Bugs:
 *    {note_any_bugs_here}

*-

/*  Entry point: */
void hand1( int sig )
{
   sigset_t set;
/*
** Give info on exception. This information was obtained
** from the signal man pages and <sys/signal.h>
*/
  if( sig ==  1 )
    printf( "\n\n Signal 1 (sighup): hangup\n\n" );
  else if( sig ==  2 )
    printf( "\n\n Signal 2 (sigint): interrupt (rubout)\n\n" );
  else if( sig ==  3 )
    printf( "\n\n Signal 3 (sigquit): quit (ascii fs)\n\n" );
  else if( sig ==  4 )
    printf( "\n\n Signal 4 (sigill): illegal instruction\n\n" );
  else if( sig ==  8 )
    printf( "\n\n Signal 8 (sigfpe): floating point exception\n\n" );
  else if( sig ==  9 )
    printf( "\n\n Signal 9 (sigkill): kill (cannot be caught or ignored)\n\n");
  else if( sig == 10 )
    printf( "\n\n Signal 10 (sigbus): bus error\n\n" );
  else if( sig == 11 )
    printf( "\n\n Signal 11 (sigsegv): segmentation violation\n\n" );
  else if( sig == 12 )
    printf( "\n\n Signal 12 (sigsys): bad argument to system call\n\n" );
  else if( sig == 15 )
    printf( "\n\n Signal 15 (sigterm): termination signal from kill\n\n" );
  else if( sig == 26 )
    printf( "\n\n Signal 26 (sigttin): background tty read attempted\n\n" );
  else if( sig == 27 )
    printf( "\n\n Signal 27 (sigttou): background tty write attempted\n\n" );
  else if( sig == 30 )
    printf( "\n\n Signal 30 (sigxcpu): exceeded cpu limit\n\n" );
  else if( sig == 31 )
    printf( "\n\n Signal 31 (sigxfsz): exceeded file size limit\n\n" );
  else
    printf( "\n\n Exception %d detected by signal handler\n\n", sig );

/*
** Unblock SIGBLOCK e.g. set by readline.
*/
   sigprocmask (SIG_SETMASK, &set, (sigset_t *)NULL);
   longjmp( here, sig);
}




/*+
 * Name:
 *    hand2

 * Purpose:
 *    Called when an inevitable exception or interrupt occured.
 
 * Language:
 *    ANSI C

 * Description:
 *    This function is called when an exception or interrupt
 *    signal is detected. It calls NDF_END and HDS_STOP before exit().

 * Authors:
 *    hme: Horst Meyerdierks (UoE, Starlink)
 *    {enter_new_authors_here}

 * History:
 *    05 Oct 1995 (hme):
 *       Original version.
 *    {enter_changes_here}

 * Bugs:
 *    {note_any_bugs_here}

*-

/*  Entry point: */
void hand2( int sig )
{
   F77_INTEGER_TYPE status = 0;

   F77_CALL(ndf_end)(&status);
   F77_CALL(hds_stop)(&status);

   exit(sig);
}
