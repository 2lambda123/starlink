#include <config.h>
#include "star/shl.h"
#include <stdlib.h>

#if HAVE_FC_MAIN
void FC_MAIN() {}
#endif

int main( int argc, char ** argv )
{
   return shl_standalone("SPECX", 1, argc, argv );
}
