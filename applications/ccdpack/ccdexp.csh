#!/bin/csh -f

#  Wrapper routine for CCDEXP to unset the ICL_TASK_NAME variable
#  so we can run from cl (and presumably Tcl).
unsetenv ICL_TASK_NAME
$CCDPACK_DIR/ccdexp in=$1 table=$CCDPACK_DIR/export.table
exit
# $Id$
