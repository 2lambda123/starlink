#ifndef MERSWRAP_DEFINED
#define MERSWRAP_DEFINED

void errAnnul( int *status );

void errBegin( int *status );

void errClear( int *status );

void errEnd( int *status );

void errFacer( const char *token,
               int *status );

void errFioer( const char *token,
               int iostat );

void errFlbel( int *status );

void errFlush( int *status );

void errLevel( int *level );

void errLoad( char *param,
              int param_length,
              int *parlen,
              char *opstr,
              int opstr_length,
              int *oplen,
              int *status );

void errMark( void );

void errOut( const char *param,
             const char *text,
             int *status );

void errRep( const char *param,
             const char *text,
             int *status );

void errRlse( void );

void errStart( void );

void errStat( int *status );

void errStop( int *status );

void errSyser( const char *token,
               int systat );

void errTune( const char *param,
              int value,
              int *status );

void msgBell( int *status );

void msgBlank( int *status );

void msgFmtc( const char *token,
              const char *format,
              const char *cvalue );

void msgFmtd( const char *token,
              const char *format,
              double dvalue );

void msgFmti( const char *token,
              const char *format,
              int ivalue );

void msgFmtl( const char *token,
              const char *format,
              int lvalue );

void msgFmtr( const char *token,
              const char *format,
              float rvalue );

void msgIfget( const char *pname,
               int *status );

void msgIflev( int *filter );

void msgIfset( int filter,
               int *status );

void msgLoad( const char *param,
              const char *text,
              char *opstr,
              int opstr_length,
              int *oplen,
              int *status );

void msgOut( const char *param,
             const char *text,
             int *status );

void msgOutif( int prior,
               const char *param,
               const char *text,
               int *status );

void msgRenew( void );

void msgSetc( const char *token,
              const char *cvalue );

void msgSetd( const char *token,
              double dvalue );

void msgSeti( const char *token,
              int ivalue );

void msgSetl( const char *token,
              int lvalue );

void msgSetr( const char *token,
              float rvalue );

void msgSync( int *status );

void msgTune( const char *param,
              int value,
              int *status );

#endif  /* MERSWRAP_DEFINED */
