/*   MSP - message system protocol
     History :
      28Aug 1991: hack version using sockets  (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
      08Jul 1994: default ADAM_USER to ~/adam (AJC)
      15Sep 1995: create ADAM_USER directory if necessary (AJC)
      12Feb 1996: FRIG TO ALLOW ICL TO WORK WITH TASKS LINKED
                  WITH PREVIOUS VERSION AMS_SYS.H see *FRIG*
                  where overlong messages may be received (AJC)
      14Sep 1999: Remove (with #if 0) declaration of exit handler.
                  It must now be done at a higher level. (DLT)
      2 Jul 2004: Now use mkfifo if available. Fix bug in mknod call (TIMJ)
      26Jul 2004: Use plain file instead of FIFO when mknod and mkfifo
                  not available  (PWD)
      29Dec 2005: Fix compiler warnings (TIMJ)
                  Remove code that sets exit handler (TIMJ)
*/

#if HAVE_CONFIG_H
#  include <config.h>
#endif

#include <sys/time.h>
#include <sys/types.h> 
#include <sys/stat.h> 
#include <sys/socket.h> 
#include <netinet/in.h> 
#include <sys/un.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <sys/file.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <dirent.h>
#include <memory.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include "sae_par.h"
#include "sock.h"

#include "msp_par.h"
#include "msp_err.h"
#include "msp.h"
#include "msp_static.h"

#define MSP__MXQUEUES 100
#define MSP__MXSOCKETS 32
#define MSP__FREE -1
#define MSP__LOCAL -2
#define MSP__EXTERNAL -3

#define MAXPATH 100


/*   The msp message structure. This is passed between processes and
     also added to a queue at the receiving end. Some of the structure
     components are only relevant when it is being passed, or when it is
     on a queue */

struct msp_msg {
    receiveq_type destination_q;      /* target queue in this task */
    sendq_type reply_q;               /* reply queue in other task */
    int msg_size;                     /* actual size of msg_text */
    char msg_buffer[MSP__MXMSGSZ];    /* message */
    struct msp_msg *next;             /* pointer to next queue entry */
};




/*   The array of message queues */

static struct msp_msg *(queues[MSP__MXQUEUES]);  /* queue */

static int queue_used[MSP__MXQUEUES];            /* flags for queues allocated
                                                    */

/*   Stack of empty messages - this is an optimisation, the system only
     uses malloc() to get space for a message if it has to */

static struct msp_msg *msg_stack;


static int mysockets[MSP__MXSOCKETS];       /* list of open sockets */

static int socket_used[MSP__MXSOCKETS];     /* flags for currently-active
                                               sockets */

static char rendezvous[MAXPATH];            /* name of rendezvous file */

static char adam_user[MAXPATH];             /* directory for creating msp
                                               files */


static char my_name[32];                    /* name of this task */

/*
*+
*  Name:
*     msp1_mkdir

*  Purpose:
*     To create the specified directory - equivalent to shell command
*     mkdir -p directory

*  Language:
*     C

*  Invocation:
*     int msp1_mkdir( char *dir )

*  Description:
*     Creates the required directory if possible. No error is reported if
*     the directory exists already. Any intermediate directories which are
*     created have permission u+wx regardless of the user's umask value.
*     If succesful 0 is returned; in the event of a failure error messages 
*     are reported using EMS and non-zero returned.

*  Arguments:
*     dir = *char (Given)
*        String containing the directory name

*  Returned value:
*     0 on success
*     non-zero on failure

*  Authors:
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     10-MAY-1995 (AJC):
*        Original version.
*     {enter_changes_here}


*  Bugs:
*     {note_any_bugs_here}

*-
*/      

int msp1_mkdir( char *dir )
{
char *buff;
int status;
char path[200];
char *s;
char *tmpdir;
mode_t mode;
struct stat statb;

/* Add final / to dir to ensure at least once through the for loop */
   if ( ( buff = (char *)malloc ( strlen(dir) + 2 ) ) != NULL ) {
      strcpy( buff, dir );
      strcat( buff, "/" );
      status = 0;

/* If buff begins with / copy it to path as strtok will ignore it */
      if ( *buff == '/' ) {
         strcpy( path, "/" ); 
      } else {
         *path = '\0';
      }
/* Now for each component ensure the directory exists */
      for ( s = buff;
          ( ( ( tmpdir = strtok( s, "/" ) ) != NULL ) && !status );
          s = NULL ) {
             
          strcat( path, tmpdir );
          if ( !stat( path, &statb ) ) {
/* File exists check it's a directory */
             if ( ! ( statb.st_mode & S_IFDIR ) ) {
/* Not a directory */
                status = -1;
             }
          } else {
/* Failed to get file info
 * Maybe because the file doesn't exist
 * Try to make the directory anyway
 */
             if ( mkdir ( path, S_IRWXU | S_IRWXG | S_IRWXO ) ) {
/*         error in creating dir */
                status = errno;
             } else {
                stat( path, &statb );
                mode = statb.st_mode & 07777;
                chmod( path, mode | S_IRWXU );
             }
          }
          strcat( path, "/" );
      }
      free( buff );

   } else {
/* malloc failed */
      status = errno;
   }          

   return status;

}

/*
*+
*  Name:
*     msp1_admus

*  Purpose:
*     To obtain a string defining the ADAM_USER directory

*  Language:
*     C 

*  Invocation:
*     status =  msp1_admus( admusr, aulen )

*  Description:
*     This is the UNIX version.
*     The routine translates environment variable ADAM_USER
*     If there is no translation, environment variable HOME is translated
*     and subdirectory /adam of it is used.
*     If neither of these are successful, a null string is returned.

*  Arguments:
*     admusr = *char (Given)
*        Pointer to string where the definition of the ADAM_USER directory
*
*     aulen = int (Given)
*        The maximum length for the admusr string.

*  Return Value:
*     returns 0 if successful
*             MSP__ADMUS if failure

*  Authors:
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     12-MAY-1995 (AJC):
*        Original version.
*     {enter_changes_here}


*  Bugs:
*     {note_any_bugs_here}

*-
*/

int msp1_admus( char *admusr, int aulen )
{

int status;
char *tmp;
struct stat statb;

   status = 0;

/*  Attempt the translation of ADAM_USER.
 *  If it didn't work, use ~/adam
 */
   if ( ( tmp = getenv( "ADAM_USER" ) ) != NULL ) {
      if ( (int)strlen(tmp) < aulen-1 ) {
        strcpy( admusr, tmp );
      } else {
        status = MSP__ADMUS;
      }
   } else {
      if ( (int)strlen(tmp=getenv("HOME") ) < aulen-6 ) {
         strcpy( admusr, tmp );
         strcat( admusr, "/adam" );
      } else {
         status = MSP__ADMUS;
      }
   }

/*  If status is still good,
 */
   if ( !status ) {
/*  Ensure that the directory exists
 */
      if ( !stat ( admusr, &statb ) ) {
/* File exists - check it's a directory */
         if ( ! ( statb.st_mode & S_IFDIR ) ) {
/* Not a directory */
            status = MSP__ADMUS;
         }
      } else {
/* Failed to get file info
 * Maybe because the file doesn't exist
 * Try to make the directory anyway
 */
         if ( msp1_mkdir( admusr ) ) {
            status = MSP__ADMUS;
         }
      }
   }
   return status;
}

/*
 *+
 *  Name:
 *     msp1_mkrvous

 *  Purpose:
 *     To create a rendezvous file using a plain file.

 *  Language:
 *     C

 *  Invocation:
 *     int msp1_mkrvous( char *fname )

 *  Description:
 *     Creates the given file which should be the name of a rendezvous
 *     file that advertizes the relationship between a task and the 
 *     port number that should be used to communicate with it. Normally
 *     a rendezvous file is created as a FIFO using mknod or mkfifo, but
 *     a plain file will also do. The file is created and its permissions 
 *     are set as if a FIFO (for consistency, no other reason I know).
 *     If succesful 0 is returned, otherwise a -1 is returned.

 *  Arguments:
 *     fname = *char (Given)
 *        String containing the full file name.

 *  Returned value:
 *     0 on success
 *     -1 on failure


 *  Authors:
 *     PWD: Peter W. Draper (Starlink, Durham University)
 *     {enter_new_authors_here}

 *  History:
 *     29-JUL-2004 (PWD):
 *        Original version. Maybe this could replace all rendezvous creation.
 *     {enter_changes_here}

 *-
 */
int msp1_mkrvous( const char *fname )
{
   FILE* fd;

   if ( fname == NULL ) {
      return -1;
   }
   fd = fopen( fname, "a" );
   if ( fd == NULL ) {
      return -1;
   }
   fclose( fd );
   chmod( fname, S_IRWXU );
   return 0;
}



/*=  MSP_ACCEPT - accept an incoming connection request */

static void msp_accept
(
int *status          /* global status (given and returned) */
)

/*   Method :
      Find an unused sockets slot the use the accept() call to bind it to
      a connection to the other task.
     Authors :
      B.D.Kelly
     History :
      15Mar 1994: original (BDK)
      12Apr 1994: make the function static (BDK)
*/

{
   int j;                              /* loop counter */
   int found;                          /* loop controller */
   socklen_t namelen;                  /* length of client address */
   struct sockaddr_in client_address;  /* incoming connection details */


   if ( *status != SAI__OK ) return;


/*   Locate an unused socket slot */

   found = 0;
   for ( j=0; j<MSP__MXSOCKETS; j++ )
   {
      if ( socket_used[j] == 0 )
      {
         found = 1;
         break;
      }
   }

   if ( found == 1 )
   {

/*   accept the call */

      namelen = sizeof ( client_address );
      mysockets[j] = accept ( mysockets[0], (struct sockaddr*)
        &client_address, &namelen );
      if ( mysockets[j] == -1 )
      {
         *status = MSP__BADCONNECT;
      }
      else
      {
         socket_used[j] = 1;
      }

   }
   else
   {
      *status = MSP__FULL;
   }
}


/*=  MSP_CHECKSOCK - check a socket number is in use */

void msp_checksock 
(
int sock,            /* a socket number (given) */
int *status          /* global status (given and returned) */
)

/*   Method :
      Check the socket number is on the active list.
     Authors :
      B.D.Kelly
     History :
      13May 1994: original (BDK)
*/

{
   int found;        /* flag for finding socket */
   int j;            /* loop counter */


   if ( *status != SAI__OK ) return;

   found = 0;

   for ( j=0; j<MSP__MXSOCKETS; j++ )
   {
      if ( socket_used[j] == 1 )
      {
         if ( mysockets[j] == sock )
         {
            found = 1;
            break;
         }
      }
   }
   if ( found == 0 )
   {
      *status = MSP__SOCKFAIL;
   }
}



/*+  MSP_CLOSE_TASK_QUEUE - close communications with another task */

void msp_close_task_queue
(
sendq_type qid,      /* a send queue to the other task */
int *status          /* global status (given and returned) */
)

/*   Method :
      Close the communications socket and remove the socket from the msp
      list.

      This routine should only be called once per other task, otherwise
      there is the possiblity of wrongly closing a socket which has been
      reused.
     Authors :
      B.D.Kelly
     History :
      29Mar 1994: original (BDK)
*/

{
   int j;

   if ( *status != SAI__OK ) return;

   for ( j=0; j<MSP__MXSOCKETS; j++ )
   {
      if ( ( socket_used[j] == 1 ) &&
        ( mysockets[j] == qid.connection ) )
      {
         socket_used[j] = 0;
         close ( mysockets[j] );
      }
   }
}


/*+  MSP_CREATE_LOCALQ - create a queue for local messages */

void msp_create_localq
(
sendq_type *sendq,   /* created send queue (returned) */
receiveq_type *qid,  /* created receive queue (returned) */
int *status          /* global status (given and returned) */
)

/*   Method :
      socketpair() creates a pair of unix domain sockets corresponding to
      both ends of a connection. Keep one of these for receiving messages
      and return the other as part of a sendq.
     Authors :
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
*/

{
   int istat;                  /* local status */
   int j;                      /* loop counter */
   int found;                  /* loop controller */
   int pair[2];                /* pair of sockets created */
   int fileflags;              /* original state of socket */

   if ( *status != SAI__OK ) return;


/*   Locate an unused queue */

   found = 0;
   for ( j=0; j<MSP__MXQUEUES; j++ )
   {
      if ( queue_used[j] == MSP__FREE )
      {
         found = 1;
         break;
      }
   }

   if ( found == 1 )
   {

      *qid = j;

/*   find a free slot for the receive socket */

      found = 0;
      for ( j=0; j<MSP__MXSOCKETS; j++ )
      {
         if ( socket_used[j] == 0 )
         {
            found = 1;
            break;
         }
      }

      if ( found == 1 )
      {

/*   Need to create a stream pipe for communication from this task to
     itself. Set the send-end to nonblocking. */

         istat = socketpair ( AF_UNIX, SOCK_STREAM, 0, pair );
         if ( istat == 0 )
         {
            socket_used[j] = 1;
            mysockets[j] = pair[0];
            sendq->connection = pair[1];
            sendq->ack_queue = *qid;
            queue_used[*qid] = MSP__LOCAL;
            queues[*qid] = 0;
            fileflags = fcntl ( pair[1], F_GETFL, 0 );
            if ( fileflags == -1 )
            {
               perror ( "GETFL error" );
            }
            else
            {
               istat = fcntl ( pair[1], F_SETFL, fileflags | FNDELAY );
/*                 istat = 1;
                 istat = ioctl ( pair[1], FIONBIO, &istat ); */
               if ( istat == -1 )
               {
                  perror ( "SETFL error" );
               }
            }
         }
         else
         {
            *status = MSP__LOCFAIL;
         }
      }
      else
      {
         *status = MSP__FULL;
      }

   }
   else
   {
      *status = MSP__FULL;
   }
}


/*+  MSP_CREATE_RECEIVEQ - create a queue for receiving messages */

void msp_create_receiveq
(
receiveq_type *qid,  /* created queue identifier (returned) */
int *status          /* global status (given and returned) */
)

/*   Method :
      Search for an unused queue and allocate it, returning its identifier.
     Authors :
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
*/

{
   int j;             /* loop counter */
   int found;         /* loop controller */

   if ( *status != SAI__OK ) return;


/*   Locate an unused queue */

   found = 0;
   for ( j=0; j<MSP__MXQUEUES; j++ )
   {
      if ( queue_used[j] == MSP__FREE )
      {
         found = 1;
         break;
      }
   }

   if ( found == 1 )
   {
      queue_used[j] = MSP__EXTERNAL;
      queues[j] = 0;
      *qid = j;
   }
   else
   {
      *status = MSP__FULL;
   }
}


/*+  MSP_DELETE_QUEUE - delete a queue */

void msp_delete_queue
(
receiveq_type qid,  /* identifier of queue to be deleted (given) */
int *status         /* global status (given and returned) */
)

/*   Method :
      If the queue has any messages on it discard them, then mark the
      queue as free.
     Authors :
      J.A.Cooke
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
*/

{
   struct msp_msg *ptr;    /* pointer for traversing queue */
   struct msp_msg *oldptr; /* pointer for traversing queue */
   int id;                 /* copy of queue identifier */


   if ( *status != SAI__OK ) return;

/*   Discard any messages currently on it and mark the queue as unused */

   id = (int) qid;

   if ( ( id >= 0 ) && ( id < MSP__MXQUEUES ) )
   {
      ptr = queues[id];

      if ( ptr != 0 )
      {
         while ( ptr->next != 0 )
         {
            oldptr = ptr;
            ptr = oldptr->next;
            free ( oldptr );
         }
         free ( ptr );
         queues[id] = 0;
      }

      queue_used[id] = MSP__FREE;
   }
   else
   {
      *status = MSP__QUENOTACT;
   }

}



/*+  MSP_ENTER_TASK - register this task with MSP */

void msp_enter_task
(
char *task_name,         /* name of this task (given) */
receiveq_type *commandq, /* command queue for this task (returned) */
int *status              /* global status (given and returned) */
)

/*   Method :
      Initialise global arrays, then search for an unused internet
      sockets port number. The socket bound to this port number is added
      to the list of sockets to be watched for messages.

      The task advertises its port number to other tasks by creating a
      file in the $ADAM_USER directory with a filename constructed from
      this task name and the port number. If environment variable ADAM_USER
      is not defined, directory adam in the user's home directory is used.
     Authors :
      J.A.Cooke
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
*/

{
   int istat;                        /* local status */
   int j;                            /* loop counter */
   struct sockaddr_in connect_addr;  /* description of socket for
                                        incoming connection requests */
   char string[80];                  /* error messages */
   int portno;                       /* this task's port number */

   if ( *status != SAI__OK ) return;


/*   Remember name for future use */

   strcpy ( my_name, task_name );

/*   Get the directory name to be used for creating and locating files
     associated with sockets and the rendezvous files.
     Creates the directory if necessary */

    if ( msp1_admus( adam_user, MAXPATH) ) {
      sprintf ( string, "%s aborting, failed creating directory %s",
        my_name, adam_user );
      perror ( string );
      exit(1);
    }

/*   Mark all queues as inactive */

   for ( j=0; j<MSP__MXQUEUES; j++ )
   {
      queue_used[j] = MSP__FREE;
      queues[j] = 0;
   }

/*   The free message stack is empty */

   msg_stack = 0;

/*   Mark all socket stores as inactive */

   for ( j=0; j<MSP__MXSOCKETS; j++ )
   {
      socket_used[j] = 0;
   }

/*   Create the socket for receiving connection requests */

   mysockets[0] = socket ( AF_INET, SOCK_STREAM, 0);

   if ( mysockets[0] < 0 ) 
   {
      sprintf ( string, "%s aborting, failed in opening listen socket",
        my_name );
      perror ( string );
      exit(1);
   }
   socket_used[0] = 1;

/*   Setup the addressing. */

   memset ( &connect_addr, 0, sizeof(connect_addr) );
   connect_addr.sin_family = AF_INET;
   connect_addr.sin_addr.s_addr = htonl ( INADDR_ANY );

/*   Repeatedly try port numbers until a free one found */

   for ( portno = 5001; portno < 5100; portno++ )
   {
      connect_addr.sin_port = htons ( portno );
      istat = bind ( mysockets[0], (struct sockaddr *) &connect_addr,
        sizeof(connect_addr) );
      if ( istat == 0 )
      {
         break;
      }
   }

   if ( istat != 0 )
   {
      sprintf ( string, "%s aborting, failed in binding listen socket",
        my_name );
      perror ( string );
      exit(1);
   }

/*   Tell the system this socket is for connection requests.
     5 is the standard number of queued connection requests allowed */

   istat = listen ( mysockets[0], 5 );
   if ( istat != 0 )
   {
      sprintf ( string, "%s aborting, failed in listening",
        my_name );
      perror ( string );
      exit(1);
   }

/*   create task rendezvous file with a name of the form 
     ADAM_USER/<taskname>_<portnumber> */

   sprintf ( rendezvous, "%s/%s_%d", adam_user, task_name, portno );

#if __CYGWIN32__
   /* mknod and mkfifo are dummies, so test works, but cannot be used */
   istat = msp1_mkrvous( rendezvous );
#elif HAVE_MKFIFO
   istat = mkfifo ( rendezvous, S_IRWXU );
#elif HAVE_MKNOD
   istat = mknod ( rendezvous, S_IFIFO | S_IRWXU, 0 );
#else
   /* Actually this can be just a plain file */
   istat = msp1_mkrvous( rendezvous );
#endif

   if ( istat < 0 ) 
   {
      sprintf ( string, "%s aborting, failed creating task rendezvous file",
        my_name );
      perror ( string );
      exit(1);
   }

/*   Create the command queue */

   queues[0] = 0;
   queue_used[0] = MSP__EXTERNAL;
   *commandq = 0;

}


/*+  MSP_EXIT - exit handler */

void msp_exit
( 
void
)

/*   Method :
      Remove all the known queues and associated files.
     Authors :
      B.D.Kelly
     History :
      08Mar 1994: original (BDK)
      05Dec 1994: Make global - intended for error processing only
*/

{
   int j;         /* loop counter */

/*   Remove the rendezvous file */

   (void) unlink ( rendezvous);

   for ( j=0; j<MSP__MXSOCKETS; j++ )
   {
      if ( socket_used[j] == 1 )
      {
         close ( mysockets[j] );
      }
   }
}

/*=  MSP_GET_TASKPORT - get task identifier */

static void msp_get_taskport
(
char *filedir,        /* name of directory for rendezvous files (given) */
char *taskname,       /* task name (given) */
int *taskport,        /* port number of task (returned) */
int *status           /* global status (given and returned) */
)

/*   Method :
      Search the rendezvous directory for a file with the right name. The
      part of the filename following "_" is the port number.
     Authors :
      J.A.Cooke
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      12Apr 1994: make the function static (BDK)
*/

{
   struct dirent *dp;        /* pointer to directory entry */
   DIR *dirp;                /* pointer to directory */
   char filename[MAXPATH];   /* filename in directory */
   char *cptr;

   if ( *status != SAI__OK ) return;


   dirp = opendir ( filedir );

   for ( dp=readdir(dirp); dp!=NULL; dp=readdir(dirp) ) 
   {
      strcpy ( filename, dp->d_name );
      cptr = strrchr(filename, '_');
      if ( cptr != NULL ) 
      {
         *cptr = '\0';
         if ( strcmp ( filename, taskname ) == 0 ) 
         {
            cptr++;
            if ( isdigit ( *cptr ) != 0 )
            {
               *taskport = atoi( cptr );
               closedir ( dirp );
               return;
            }
         }
      }
   }

/*   if it gets here it's not found it */

   closedir ( dirp );
   *taskport = -1;
   *status = MSP__NOTFOUND;
}



/*+  MSP_GET_TASK_QUEUE - get the command queue of a named task */

void msp_get_task_queue
(
char *task_name,    /* name of task (given) */
sendq_type *qid,    /* task command queue (returned) */
int *status         /* global status (given and returned) */
)

/*   Method :
      Get the internet port number of the named task and connect to it.
      Add the connected socket to the list to be watched for messages.
     Authors :
      J.A.Cooke
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
*/

{
   char filedir[MAXPATH];            /* name of rendezvous directory */
   int found;                        /* loop controller */
   int istat;                        /* local status */
   int j;                            /* loop counter */
   int taskport = 0;                 /* port number of task */
   struct hostent hostentstruct;     /* network data structure for this
                                        machine */
   struct hostent *hostentptr;       /* pointer to network data structure
                                        */
   struct sockaddr_in connect_addr;  /* structure for connection request */


   if ( *status != SAI__OK ) return;


/*   Locate an unused socket slot */

   found = 0;
   for ( j=0; j<MSP__MXSOCKETS; j++ )
   {
      if ( socket_used[j] == 0 )
      {
         found = 1;
         break;
      }
   }

   if ( found == 1 )
   {

/*   Need to connect to another task. Find its portid */

      strcpy ( filedir, adam_user );

      msp_get_taskport ( filedir, task_name, &taskport, status );

      if ( *status == SAI__OK )
      {

/*   Get network data structure for this machine */

         hostentptr = gethostbyname ( "localhost" );
         hostentstruct = *hostentptr;

/*   Construct the data structure for the connection request to the given
     port number on THIS machine */

         memset ( &connect_addr, 0, sizeof(connect_addr) );
         connect_addr.sin_family = AF_INET;
         connect_addr.sin_addr = *((struct in_addr *) hostentstruct.h_addr);
         connect_addr.sin_port = htons ( taskport );

         mysockets[j] = socket ( AF_INET, SOCK_STREAM, 0 );
         if ( mysockets[j] != -1 )
         {

/*   Connect */

            istat = connect ( mysockets[j], (struct sockaddr *) &connect_addr,
              sizeof(connect_addr) );
            if ( istat == 0 )
            {

/*   The "sendq" is composed of the socket and the other task's receive
     queue number (which for the commandq is always ZERO ) */

               socket_used[j] = 1;
               qid->connection = mysockets[j];
               qid->ack_queue = 0;
            }
            else
            {
               *status = MSP__SOCKINIT;
            }
         }
         else
         {
            *status = MSP__SOCKINIT;
         }
      }
   }
   else
   {
      *status = MSP__FULL;
   }
}


/*=  MSP_INPUT - get a message from any of the input sockets */

static void msp_input
(
int waitflag,         /* wait flag (given) */
int *status           /* global status (given and returned) */
)

/*   Method :
      Look for input available on any of the input sockets. If input is
      available, read a message and put it onto the relevant message queue.
     Authors :
      J.A.Cooke
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
      29Mar 1994: use the msg_stack stack (BDK)
      30Mar 1994: use msp_select() (BDK)
      12Apr 1994: make the function static (BDK)
*/

{
   int q = 0;                   /* socket number on which data available */
   int nready;                  /* no. of sockets with data available */
   char string[80];             /* error messages */
   struct msp_msg * new_entry;  /* pointer to new queue member */
   struct msp_msg * ptr;        /* pointer to queue members */


   if ( *status != SAI__OK ) return;


/*   Look for input available */

   msp_select ( waitflag, &nready, &q, status );

   if ( nready > 0 ) 
   {

/*   at least one message present, get it and return */

      if ( q==0 )
      {

/*   Incoming connection call */

         msp_accept ( status );
      }
      else
      {

/*   Get an empty message buffer or create one */

         if ( msg_stack != 0 )
         {
            new_entry = msg_stack;
            msg_stack = new_entry->next;
         }
         else
         {

            new_entry = (struct msp_msg *) 
              malloc ( sizeof (struct msp_msg) );

            if ( new_entry == 0 )
            {
               sprintf ( string, 
                 "%s aborting, failed malloc", my_name );
               perror ( string );
               exit(1);
            }
         }

/*   Read the message */
         sock_read ( mysockets[q], sizeof(struct msp_msg), 
           (char *)new_entry, status );

         if ( *status == SAI__OK )
         {

/*   Add it to the relevant receive queue */

            new_entry->reply_q.connection = mysockets[q];
            if ( ( new_entry->destination_q >= 0 ) &&
              ( new_entry->destination_q < MSP__MXQUEUES ) )
            {
               if ( queue_used[new_entry->destination_q] != MSP__FREE )
               {
                  ptr = queues[new_entry->destination_q];
                  if ( ptr == 0 )
                  {

/*   Queue is currently empty, add the new message at its head */

                     ptr = new_entry;
                     ptr->next = 0;
                     queues[new_entry->destination_q] = ptr;
                  }
                  else
                  {
                     while ( ptr->next != 0 )
                     {
                        ptr = ptr->next;
                     }
                     ptr->next = new_entry;
                     new_entry->next = 0;
                  }
               }
               else
               {
                  *status = MSP__QUENOTACT;
                  new_entry->next = msg_stack;
                  msg_stack = new_entry;
               }
            }
            else
            {
               *status = MSP__QUENOTACT;
               new_entry->next = msg_stack;
               msg_stack = new_entry;
            }
         }
         else
         {

/*   Error reading from socket, close it and release the message space */
   printf ( "%s - msp_input: error reading sock on q = %d\n", my_name, q );
            close ( mysockets[q] );
            socket_used[q] = 0;
            new_entry->next = msg_stack;
            msg_stack = new_entry;
   printf ( "%s - closing socket no. %d\n", my_name, q );
         }
      }
   } 
}


/*+  MSP_MKCOMQ - return a task's command q given any send q */

void msp_mkcomq
(
sendq_type replyq,    /* a reply queue for a task (given) */
sendq_type *commandq, /* command queue for the task (returned) */
int *status           /* global status (given and returned) */
)

/*   Method :
      If the given reply queue is valid, generate the corresponding
      command queue.
     Authors :
      B.D.Kelly
     History :
      13May 1994: original (BDK)
*/

{

   if ( *status != SAI__OK ) return;

   msp_checksock ( replyq.connection, status );

   if ( *status == SAI__OK )
   {
      commandq->connection = replyq.connection;
      commandq->ack_queue = 0;
   }

}


/*+  MSP_MKNUMQ - return a numbered send q given any send q */

void msp_mknumq
(
sendq_type replyq,    /* a reply queue for a task (given) */
int number,           /* other task's reply number (given) */
sendq_type *numq,     /* reply queue for given number (returned) */
int *status           /* global status (given and returned) */
)

/*   Method :
      The the given reply queue is valid, generate the reply queue
      corresponding to the given number.
     Authors :
      B.D.Kelly
     History :
      13May 1994: original (BDK)
*/

{

   if ( *status != SAI__OK ) return;

   msp_checksock ( replyq.connection, status );

   if ( *status == SAI__OK )
   {
      numq->connection = replyq.connection;
      numq->ack_queue = number;
   }

}


/*+  MSP_RECEIVE_MESSAGE - receive a message on one of a list of queues */

void msp_receive_message
(
receiveq_type *qarr,  /* array of queue identifiers (given) */
int nqueues,          /* number of queues (given) */
int waitflag,         /* wait flag (given) */
int maxlen,           /* maximum length of message (given) */
char msgbody[],       /* received message (returned) */
int *actlen,          /* size of received message (returned) */
receiveq_type *qid,   /* identifier of queue used (returned) */
sendq_type *replyq,   /* reply queue for message (returned) */
int *status           /* global status (given and returned) */
)

/*   Method :
      Search the members of the internal array of queues corresponding to
      the given queue identifiers. If a message is found, return it. If
      no message is found, input a message and then recheck the array of
      queues. This is performed just once if the wait_flag is zero,
      otherwise it is repeated until a message is found.
     Authors :
      J.A.Cooke
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
      29Mar 1994: use the msg_stack stack (BDK)
*/

{
   int found;            /* loop controller */
   int j;                /* loop counter */
   struct msp_msg *ptr;  /* queue processing pointer */
   int tried_input;      /* flag to avoid repeated input attempts if
                          waitflag is 0 */


   if ( *status != SAI__OK ) return;


   found = 0;
   tried_input = 0;

   while ( found == 0 )
   {

/*   Search the internal queues for a message */

      for ( j=0; j<nqueues; j++ )
      {
         *qid = qarr[j];
         if ( ( (int)*qid >= 0 ) && ( (int)*qid < MSP__MXQUEUES ) )
         {
            if ( queue_used[(int)*qid] != MSP__FREE )
            {
               ptr = queues[(int)*qid];
               if ( ptr != 0 )
               {

/*   Found a message, take it off the front of the queue and put the
     buffer on the free list */

/*FRIG                  if ( ptr->msg_size <= maxlen )
  replaced by: */
                  if ( ptr->msg_size <= (maxlen + 5*sizeof(int)) )
/*FRIG end */
                  {
/*FRIG                     memcpy ( msgbody, ptr->msg_buffer, ptr->msg_size );
                           *actlen = ptr->msg_size;
  replaced by: */
                     *actlen = (ptr->msg_size <= maxlen)?ptr->msg_size:maxlen;
                     memcpy ( msgbody, ptr->msg_buffer, *actlen );
/*FRIG end */
                     *replyq = ptr->reply_q;
                     queues[(int)*qid] = ptr->next;
                     ptr->next = msg_stack;
                     msg_stack = ptr;
                  }
                  else
                  {
   printf ( "msp_receive - bad message size = %d\n", ptr->msg_size );
                     *status = MSP__RECLEN;
                  }
                  found = 1;
                  break;
               }
            }
            else
            {
               *status = MSP__BADQUEUE;
               found = 1;
               break;
            }
         }
         else
         {
            *status = MSP__BADQUEUE;
            found = 1;
            break;
         }
      }

      if ( found == 0 )
      {

         if ( ( waitflag == 0 ) && ( tried_input == 1 ) )
         {

/*   We've been round the loop once and failed, give up */

            *status = MSP__NONE;
         }

/*   Nothing on the queues, get input from sockets */

         msp_input ( waitflag, status );

         if ( *status != SAI__OK )
         {
            break;
         }
         tried_input = 1;
      }
   }

}


/*=  MSP_SELECT - look for a message on any of the input sockets */

static void msp_select
(
int waitflag,         /* wait flag (given) */
int *nready,          /* no. of sockets with data (returned) */
int *q_number,        /* no. of first queue with data (returned) */
int *status           /* global status (given and returned) */
)

/*   Method :
      Generate an "fd_set" bit array from the list of active sockets and
      wait on them all using select(). If the select() returns because of
      a signal, restart it.
     Authors :
      B.D.Kelly
     History :
      30Mar 1994: original (BDK)
      12Apr 1994: make the function static (BDK)
*/

{
   fd_set read_mask;            /* read mask for select() */
   struct timeval wait;         /* time structure for select() */
   int q;                       /* loop counter */
   int valid;                   /* flag indicating there are sockets in
                                   use */


   if ( *status != SAI__OK ) return;


/*   determine which file descriptors to watch from the queue array */

   FD_ZERO ( &read_mask );
   valid = 0;

   for ( q = 0; q<MSP__MXSOCKETS; q++ ) 
   {
      if ( socket_used[q] == 1 )
      {
         FD_SET ( mysockets[q], &read_mask );
         valid = 1;
      }
   }

   for ( ; ; )
   {
      *nready = 0;

      if ( ( waitflag == 1 ) && ( valid == 1 ) )
      {

/*   wait on queues with infinite timeout */

         *nready = select(FD_SETSIZE, &read_mask, (fd_set *) 0,
           (fd_set *) 0, (struct timeval *) 0);
      }

      else if ( ( waitflag == 0 ) && ( valid == 1 ) )
      {

/*   do a poll and return with message, or none if none ready */

         wait.tv_sec = 0;
         wait.tv_usec = 0;

         *nready = select(FD_SETSIZE, &read_mask, (fd_set *) 0,
           (fd_set *) 0, &wait);
      }

      if ( *nready >= 0 ) 
      {
         break;
      }
      else if ( errno != EINTR )
      {
/*   error condition */

         perror ( "after select() call" );
         exit(1);
      }
      else
      {

/*   Interrupted by a signal which has (hopefully) been handled by a
     signal handler. Repeat the select(). */

      }
   }

   if ( *nready > 0 ) 
   {

/*   at least one message present, identify the queue */

      for ( q=0; q<MSP__MXSOCKETS; q++ ) 
      {
         if ( FD_ISSET ( mysockets[q], &read_mask ) ) 
         {
            *q_number = q;
            break;
         }
      }
   } 
   else if ( *nready == 0 ) 
   {

/*   no messages, set status and return */

      *status = MSP__NONE;

   } 
}


/*+  MSP_SEND_MESSAGE - send a message on a queue */

void msp_send_message
(
char msgbody[],        /* message to be sent (given) */
int msglen,            /* length of message to be sent (given) */
sendq_type sendq,      /* queue identifer to be used (given) */
receiveq_type replyq,  /* reply queue to be associated with the message 
                          (given) */
int *status            /* global status (given and returned) */
)

/*   Method :
      Construct the message into a data structure and send it.
     Authors :
      J.A.Cooke
      B.D.Kelly
     History :
      28Aug 1991: original prototype (JAC) 
      07Mar 1994: revised version (BDK)
      14Mar 1994: changed to use STREAM sockets (BDK)
*/

{
   int sendskt;                /* socket used for sending */
   struct msp_msg message;     /* message sent */
   int istat;                  /* local status */

   if ( *status != SAI__OK ) return;

   if ( msglen <= MSP__MXMSGSZ )
   {
      message.msg_size = msglen;
      message.reply_q.ack_queue = replyq;
      message.destination_q = sendq.ack_queue;
      memcpy(message.msg_buffer, msgbody, msglen);

      sendskt = sendq.connection;

      sock_write ( sendskt, sizeof(struct msp_msg), 
        (char*)&message, status );
      if ( *status != SAI__OK )
      {
      *status = MSP__SENDLEN;
         istat = SAI__OK;
         msp_close_task_queue ( sendq, &istat );
      }
   }
   else
   {
 printf ( "%s - msp_send: message too long = %d\n", my_name, msglen );
      *status = MSP__SENDLEN;
   }
}


