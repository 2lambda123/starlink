/* - AMS_MAC - macro definitions for adam message system */

#define MXQUEUE      32
#define FIXED_NUM_Q      6      /* number of fixed task queues */
#define REC_MXQUEUE      (FIXED_NUM_Q + MESSYS__MXTRANS)
                        /* maximum number of queues */

#define CHARNIL ((char *)0)



/*+  AMS_CHECKTRANS */

/*   Method :
      A macro which checks that a transaction number is legal (between 0
      and MESSYS__MXTRANS) and that it is being used (transfree[messid]
      == false) setting status to MESSYS__BADMESS/MESSYS__NOMESS/SAI__OK
      as appropriate
*/
#define AMS_checktrans(messid,status)  \
   if ((messid) < 0 || (messid) >= MESSYS__MXTRANS) \
     (*(status)) = MESSYS__BADMESS; \
   else if (transfree[(messid)]  == true) \
     (*(status)) = MESSYS__NOMESS; \
   else (*(status)) = SAI__OK;


/*+  AMS_CHECKTRANSACTIVE */
/*   Method :
      Check that a transaction number is legal (between 0 and
      MESSYS__MXTRANS) being used, and that the transaction is active
      (that it has an acknowledge queue) setting *status to
      MESSYS__BADMESS/MESSYS_NOMESS/SAI__OK as appropriate
*/
#define AMS_checktransactive(messid, status) \
   if ( (messid) < 0  || (messid) >= MESSYS__MXTRANS  ) \
     (*(status)) = MESSYS__BADMESS; \
   else if (transfree[(messid)] == true) \
     (*(status)) = MESSYS__NOMESS; \
   else if (t_trans[(messid)].this_task_ack_q == MESSYS__NULL_Q ) \
     (*(status)) = MESSYS__NOMESS; \
   else (*(status)) = SAI__OK;


/*+  AMS_CHECKPATHOPEN */
/*   Method :
      Check that a path is legal (between 0 and MESSYS__MAXPATH) and that
      it is open (pathfree[path] == false) setting status to
      MESSYS__BADPATH/ MESSYS__NONEXIST/SAI__OK as appropriate.
*/
#define AMS_checkpathopen(path,status) \
   if ( (path) < 0 || (path) >= MESSYS__MXPATH ) \
     (*(status)) = MESSYS__BADPATH; \
   else if( pathfree[(path)] == true ) \
     (*(status)) = MESSYS__NONEXIST; \
   else (*(status)) = SAI__OK;


/*+  AMS_CHECKPATH */
/*   Method :
      Check that a path is legal (between 0 and MESSYS__MAXPATH) setting
      status to MESSYS__BADPATH or SAI__OK
*/
#define AMS_checkpath(path,status) \
   if ( (path) < 0 || (path) >= MESSYS__MXPATH ) \
     (*(status)) = MESSYS__BADPATH; \
   else (*(status)) = SAI__OK;
