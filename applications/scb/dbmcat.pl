#!/usr/local/bin/perl -w 

#+
#  Name:
#     dbmcat.pl

#  Purpose:
#     Examine StarIndex files.

#  Language:
#     Perl 5

#  Invocation:
#     dbmcat.pl filename
#     dbmcat.pl filename key ...

#  Description:
#     This utility is for examining the DBM files representing StarIndex
#     objects used to store the indexes used by the SCB package for 
#     indexing files and routines.
#
#     It is not required for any part of the package operation, but is
#     provided for manual examination of these files.  It will mainly 
#     be useful for debugging, but may also be useful (in combination
#     with, for instance, grep(1)) for making more flexible queries
#     of the index files than are permitted by the 'type=regex' 
#     argument of the scb.pl extractor program.
#
#     It can be used in two modes: if the name of the index only is
#     specified, then every record in the index is printed (in an 
#     unpredictable order); the format is
#
#        key    => value value value ...
#
#     where the values are file locations using the logical pathnames
#     as used in the rest of the SCB package.  There may be one or more
#     values, and they are separated by spaces.

#  Arguments:
#     filename
#        Name of the index file.  This is the name of the index as 
#        submitted to the StarIndex::new() routine, i.e. without 
#        whatever file extensions (.db, .dir, ...) may appear when
#        the file is actually written.  The full path must be given.
#     key
#        One or more keys of the index may be specified.  They must be 
#        exact.

#  Notes:

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     03-DEC-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

use strict;
use vars;

#  Required package.

use StarIndex;

#  Name of this program.

my $self = $0;
$self =~ s%.*/%%;

#  Set usage message.

my $usage = "Usage:  $self dbm-file [key ...]\n";

#  Exit if there are no command line arguments.

die $usage unless (@ARGV);

#  Get name of index file.

my $indexfile = shift;

#  Open index for reading.

my $index = StarIndex->new($indexfile, 'read');


#  If keys have been specified, pull them out one by one and print key,
#  (list of values) pairs.  The get() method returns a whole list of 
#  values for in each call.

if (@ARGV) {
   my ($key, $value);
   while ($key = shift) {
      $value = join " ", $index->get($key);
      printf "%-20s => %s\n", $key, $value;
   }
}

#  Otherwise, iterate through index.  The each() method gives one key
#  and one value, but all the values for one key will be returned 
#  adjacent to each other.  To build up each list of values, keep 
#  calling each() until the key is different from last time.

else {
   my $lastkey = '';
   my ($key, $value);
   while (($key, $value) = $index->each()) {
      unless ($key eq $lastkey) {
         print "\n" if ($lastkey);   #  Not first time round.
         printf "%-20s =>", $key;
      }
      print " ", $value;
      $lastkey = $key;
   }
   print "\n";
}

# $Id$
