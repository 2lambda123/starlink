package Scb;

#+
#  Name:
#     Scb.pm

#  Purpose:
#     Module containing utility routines for source code browser programs.

#  Language:
#     Perl 5

#  Invocation:
#     use Scb;

#  Description:
#     Utility routines and global variables for source code browser
#     and indexer programs.  Via their definitions in this module
#     the locations of various files and directories are determined.
#     Both build-time (via the mk script) and run-time values of 
#     some environment variables affect these locations, as documented
#     in the "Global variables" section.

#  Notes:
#     This module reports errors using the routine &main::error 
#     (this is to make sensible handling of exceptions easier),
#     if it exists.  Otherwise such errors will be reported using die().

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Set up export of names into main:: namespace.

use Exporter;
@ISA = qw/Exporter/;

#  Names of routines and variables defined here to be exported.

@EXPORT = qw/tarxf mkdirp popd pushd chdir cwd starpack rmrf parsetag taggable 
             $incdir $srcdir $bindir $scb_tmpdir $scbindex_tmpdir $indexdir
             $mimetypes_file
             $htxserver
             $docslisfile
             @indexes 
             %tagged %tagger/;

@EXPORT_OK = qw/error/;

#  Declare all variables explicitly.

use strict 'vars';
use vars qw/ $incdir $srcdir $bindir $scb_tmpdir $scbindex_tmpdir $indexdir
             $mimetypes_file
             $htxserver
             $docslisfile
             @indexes 
             %tagger %tagged/;

#  Map error handler routine to that from the main:: namespace.

sub error { defined (&main::error) ? &main::error (@_) : die (@_) }

#  Includes.

#  By overriding the standard Perl 'chdir' with the one from the Cwd 
#  module, the PWD environment variable is kept up to date.  We then 
#  provide our own cwd using PWD.  If PWD isn't set initially we set it.
#  Using PWD is preferable to using &Cwd::cwd, because the latter gives
#  the actual directory location instead of the location we've asked to
#  go to; the actual one can be in some weird symlinked place that the 
#  automounter umounts while we're not looking, which causes trouble
#  if we try to go back there some time.

use Cwd 'chdir';
sub cwd { $ENV{'PWD'} ||= Cwd::cwd }

########################################################################
#  Global variables.
########################################################################

#  The capitalised variable names in this section may be replaced by
#  environment variables or mk script variables by the makefile at 
#  build time.  The sequences "$VARIABLE_NAME" are substituted for 
#  by sed(1), so it is important that the quoting syntax (in the pre-
#  build files) is not modified in these assignments.  Since the mk 
#  script/makefile modify these files at build time, if you are looking
#  at the built version of this script it may look confusing.  The
#  pre-build version can be seen by extracting the script directly
#  from the scb_source.tar tar file.
#
#  The script is written so that it works in its pre-build form also, 
#  using default values.
#
#  Some of the values determined by build-time environment variables
#  (or pre-build defaults) can be overridden at run-time by environment 
#  variables of the same name, if they exist and have a value.

#  Starlink source tree directory locations.

my $STARLINK = "/star"; 
my $SCB_SOURCES = "$STARLINK/sources"; 

my $star = "$STARLINK";
$srcdir = $ENV{'SCB_SOURCES'} || "$SCB_SOURCES";
$bindir = "$star/bin";
$incdir = "$star/include";
$docslisfile = "$star/docs/docs_lis";

#  Temporary directory locations.

my $SCB_BROWSER_TMP = "/usr/tmp/scb";
my $SCB_INDEXER_TMP = "/usr/tmp/scbindex";
$scb_tmpdir      = $ENV{'SCB_BROWSER_TMP'} || "$SCB_BROWSER_TMP";
$scbindex_tmpdir = $ENV{'SCB_INDEXER_TMP'} || "$SCB_INDEXER_TMP";

#  System file locations.

my $SCB_DIR = ".";
$mimetypes_file = "$SCB_DIR" . "/mime.types"; 

#  HTX server base URL

my $HTX_SERVER = "http://star-www.rl.ac.uk/cgi-bin/htxserver";
$htxserver = "$HTX_SERVER";

#  Index file locations.

my $SCB_INDEX = cwd;
$indexdir = $ENV{'SCB_INDEX'} || "$SCB_INDEX" || cwd;

#  Names of indexes (independent name spaces).
#     By adding entries to this list, additional name spaces for indexing 
#     may be added, for instance to index callable routines in a different
#     language such as Tcl.  The indexing program (and possibly the browsing 
#     program) would need to be modified to take advantage of these.
#
#     Current indexes are:
#        func:  Routine names as used by Un*x C/fortran compilers.
#        file:  File names (includes special 'package#' records).

@indexes = qw/func file/;

#  Language-specific tagging routines.
#     Both the indexer and the extractor programs must be able to identify
#     certain points in the source code.  This is done by calling 
#     language-specific tagging routines using the sequence:
#
#        use Scb.pm;
#        $tagged = &{$tagger{$ftype}} ($sourcefh, $ftype);
#
#     where $ftype is the file type (usually the filename extension), as
#     given in the keys to %tagger below.  The mapping from file type 
#     to tagging routine is done here, by setting the %tagger hash.
#
#     New tagging routines may be written, or the ones supplied may be
#     replaced as desired (the existing ones are not very efficient, 
#     especiallly with respect to memory, for large files).  
#     The remainder of this comment block documents the interface 
#     between the tagging routines and the rest of the package 
#     for anybody wishing to do this.
#
#     The interface is fairly simple: the tagging routine must take the 
#     filehandle from which the raw source code may be read as its first
#     argument (and may optionally read the second argument to tell it 
#     the file type), and must return the tagged source code.  
#     The tagged source is a kind of stripped down 
#     HTML; it should be the same as the raw source, with the following 
#     anchor tags added:
#
#        <a name=''> tags identifying function/subroutine definitions, 
#        <a href=''> tags identifying function/subroutine calls, 
#        <a href='INCLUDE-'> tags identifying references to files.
#
#     Additionally, any '<' or '&' characters in the source must be 
#     replaced by '&lt;' and '&amp;' respectively (replacement of '>'
#     by '&gt;' is optional).
#
#     Closing </a> tags MUST be supplied (as per the HTML DTD, despite 
#     the fact that this is often disregarded for <a name=''> tags).  
#     Thus if the raw source is supplied as:
#
#        #include "header.h"
#        int code (int argc, char **argv) {
#           (void) do_stuff();
#        }
#
#     then calling the tagger function should return:
#
#        #include "<a href='INCLUDE-header.h'>header.h</a>"
#        int <a name='code'>code</a> (int argc, char **argv) {
#           (void) <a href='do_stuff'>do_stuff</a>();
#        }
#        
#     Note that the values of the href attributes are not URLs or even
#     unique references, merely the name under which the file has been
#     indexed.  It is the job of the extractor program to map the names
#     in the hrefs to actual URLs where required.  The function index 
#     names can be anything, as long as a function whose definition is 
#     marked with an <a name=''> tag gets referred to using the same 
#     name when it causes an <a href=''> tag.  Files referred to 
#     (presumably include files or similar) must have index names 
#     consisting of the literal 'INCLUDE-' followed by the bare name 
#     of the file - this filename must not contain the path, only the 
#     filename itself.
#
#     The function index names currently used are the same as the names 
#     used by the Unix linker (on the supported platforms), i.e. for C
#     the function name as it appears in the source code, and for Fortran 
#     the function/subroutine name in lower case, followed by an 
#     underscore.  If a tagger were written for a language (e.g. Perl or
#     Tcl) with a separate namespace from C and the things which can be 
#     linked with it, it would need to use a separate index from the 
#     'func' one currently used.  There are hooks in the indexer and 
#     extractor programs for this.

use YyTag;

my( $ctag, $ftag ) = ( \&YyTag::ctag, \&YyTag::fortrantag );

%tagger = ( 
            c   => $ctag,
            h   => $ctag,
            C   => $ctag,
            cc  => $ctag,
            cpp => $ctag,
            cxx => $ctag,

            f   => $ftag,
            gen => $ftag,
          );


########################################################################
#  Local variables.
########################################################################

#  Define necessary shell commands.
#  Note: this is used in a CGI program, so you should be sure that these 
#  commands do what they ought to, for security reasons.
#  In the case that this is being used from a CGI program, the path 
#  $ENV{'PATH'} should have been stripped down to a minimum 
#  ('/bin:/usr/bin' is probably sufficient).

my $tar = "tar";
my $cat = "cat";
my $zcat = "uncompress -c";
my $gzcat = "gzip -dc";


########################################################################
#  Subroutines.
########################################################################


########################################################################
sub taggable {

#+
#  Name:
#     taggable

#  Purpose:
#     Determine if tagging should be attempted on a given file.

#  Language:
#     Perl 5

#  Invocation:
#     $retval = $taggable ($location);

#  Description:
#     This Boolean function returns whether tagging should be attempted
#     on a given filename.  It decides this on the basis of whether there
#     is an appropriate tagging routine available, whether effectively
#     the same file has been tagged already, and whether it matches
#     a list of files which have been marked explicitly to avoid.
#
#     Calling this routine constitutes an assertion that tagging will
#     be done, if the return value is true.  Thus, if it is called again
#     on a file with the same name, since the last time %tagged was cleared, 
#     it will return false.
#
#     The list of which files have already been tagged is the global
#     hash %tagged, which may be cleared by other routines.
#     In fact it may be a good idea to clear this periodically if it can
#     be done safely, so that it doesn't take up too much memory.

#  Arguments:
#     $location = string.
#        Logical pathname of the file whose taggability is to be assessed.

#  Return value:
#     $retval = boolean.
#        True if tagging should be attempted on this file; else false.

#  Notes:

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     04-NOV-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get arguments.

   my $location = shift;

#  Generate the name of the file as it would be if it were outside all the
#  tar files.

   my $untarloc = $location;
   $untarloc =~ s%[^/#>]+>%%g;

#  Get filename extension.

   my $ext = '';
   $ext = $1 if ($location =~ /\.([^.]+)$/);

#  A file is presumed taggable until found untaggable.

   my $retval = 1;

#  A tagging routine must exist.

   $retval &&= defined $tagger{$ext};

#  A file which ultimately lives in the same place must not have been 
#  tagged already (since the %tagger hash was last cleared - it is the
#  responsibility of the calling routine to clear this at appropriate
#  points).

   $retval &&= !exists $tagged{$untarloc};

#  If this is going to be tagged mark it as such (calling this routine 
#  constitutes an assertion that the tagging will be done).

   $tagged{$untarloc} = 1 if $retval;
   
   return $retval;
}


########################################################################
sub tarxf {

#+
#  Name:
#     tarxf

#  Purpose:
#     Extract files from a tar archive.

#  Language:
#     Perl 5

#  Invocation:
#     @fextracted = tarxf ($tarfile)
#     @fextracted = tarxf ($tarfile, @files)

#  Description:
#     Extracts either all files, or a list of named files, from the 
#     named tar archive into their archived positions relative to the
#     current directory, just as tar(1).  The tar archive may however
#     be compressed using gzip(1) or compress(1).
#
#     If an error occurs during execution of the extraction, an error 
#     message is printed, and the routine returns with an empty list
#     of files.

#  Arguments:
#     $tarfile = string.
#        Name of the tar archive.  If it ends '.Z' or '.gz' it is 
#        supposed to be compressed using compress(1) or gzip(1) 
#        respectively.
#     @files = list of strings (optional).
#        If present, @files contains a list of filenames to be extracted
#        from the tar archive.  An error results if any cannot be extracted.
#        If absent, all files will be extracted.

#  Return value:
#     @fextracted = list of strings.
#        List of files successfully extracted.

#  Notes:
#     To accomodate differences which exist between the output of tar 
#     on different platforms with the 'xv' flags, the list of extracted
#     files is generated in a separate step from doing the extraction
#     itself.  This may be somewhat wasteful.

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameters.

   my ($tarfile, @files) = @_;

#  Check the tarfile name for shell metacharacters; since it becomes
#  part of a string passed to the shell, and especially since this may
#  run as part of a CGI program, it would be bad (though rather unlikely)
#  to have a tar file with a name like 'archive;rm *;.tar'.  This is
#  rather a paranoid thing to do, since there is no reason to suppose
#  that there will be tar files with pathological names; in particular
#  their names are not under control of anybody apart from the maintainer
#  of the $srcdir source code tree.  But better safe than sorry.

   if ($tarfile =~ /[;&|><` ]/) {
      error "Dangerous tar file name: $tarfile",
         "The filename given is badly formed.  For security reasons " .
         "execution has been aborted.";
   }   

#  Define a (possibly null) compression filter.

   $tarfile =~ /\.tar(\.?.*)$/;
   my $ext = $1;
   my %filter = (
                  ''    => $cat,
                  '.Z'  => $zcat,
                  '.gz' => $gzcat,
                );

#  Unpack the tar file, reading the list of file names into a list.
#  If an error occurs print a warning message.

   my $command = "$filter{$ext} $tarfile | $tar xf - " . join ' ', @files;
   if (system $command) {
      print STDERR "  !!! $command failed: $!\n";
      return wantarray ? () : undef;
   }

#  In list context, generate and return list of regular files extracted.
#  Otherwise, return the null value.

   if (wantarray) {
      my @extracted;
      $command = "$filter{$ext} $tarfile | $tar tf - " . join ' ', @files;
      open TAR, "$command|" or error "$command failed: $!\n";
      while (<TAR>) {
         chomp;
         push @extracted, $_ if (-f $_);
      }
      close TAR             or error "$command failed: $!\n";
      return @extracted;
   }
   else {
      return undef;
   }
}


########################################################################
sub mkdirp {

#+
#  Name:
#     mkdirp

#  Purpose:
#     Make directory and parents if necessary.

#  Language:
#     Perl 5

#  Invocation:
#     mkdirp ($dir, $mode)

#  Description:
#     Creates the given directory and, if required, its parents (like
#     mkdir -p).  Any directories created are given the specified 
#     access mode (in this respect it differs from the mkdir(1) command).
#     Directories which already exist are not modified.
#     The routine exits using the 'error' routine if any of the creations
#     fails.  The given access mode is not modified by the current umask.

#  Arguments:
#     $dir = string.
#        Filename of the directory to be created.
#     $mode = integer.
#        Access mode (presumably in octal) for creation of new directories.

#  Return value:

#  Notes:

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     03-NOV-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get arguments.

   my ($dir, $mode) = @_;
   $dir .= '/';

#  Change umask so that mode supplied to mkdir is not modified, saving the
#  old value.

   my $umask = umask 0;

#  Step through directory name a ('/'-delimited) element at a time, creating
#  any which don't already exist.

   my $element;
   for (my $i = 0; $i >= 0;  $i = index ($dir, '/', $i+1)) {
      $element = substr $dir, 0, $i;
      unless (-d $element || $element eq '') {
         mkdir $element, $mode or error "mkdir $dir: $!";
      }
   }

#  Restore old umask.

   umask $umask;
}


########################################################################
sub starpack {

#+
#  Name:
#     starpack

#  Purpose:
#     Identify the Starlink package name from a logical path.

#  Language:
#     Perl 5

#  Invocation:
#     $package = starpack ($location);

#  Description:
#     Returns the name of the Starlink package into which a logical
#     pathname points.  This is the part before the first '#' sign,
#     so that e.g.:
#
#        starpack ("ndf#ndf_source.tar>ndf_open.f")  eq  'ndf'

#  Arguments:
#     $location = string.
#        Logical pathname of file.

#  Return value:
#     $package = string.
#        Name of the package.  If no package is identified, the empty
#        string (not undef) is returned.

#  Notes:

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameter.

   my $location = shift;

#  Pattern match to find package identifier.

   $location =~ m%^([^/>#]+)#%;

#  Return value.

   return $1 || '';
}

########################################################################
sub rmrf {

#+
#  Name:
#     rmrf

#  Purpose:
#     Remove a directory.

#  Language:
#     Perl 5

#  Invocation:
#     rmrf ($dir);

#  Description:
#     This routine deletes a single directory and all its subdirectories.
#     It examines its arguments rather carefully to try to avoid any 
#     unintentional deletions.
#     This is entirely a precautionary measure - it is never expected 
#     that this function will be called with dangerous arguments, but
#     (especially since it may run under CGI control) it seems prudent
#     to be as safe as possible.
#     If anything looks untoward, an error is generated and the user
#     directed to this routine.  Amongst other things, the target
#     directory is checked to see whether it looks like the name of
#     something which has temporary files in it; according to naming
#     conventions this might innocently fail to be the case.  In that
#     case that check can be modified or removed.

#  Arguments:
#     $dir = string.
#        Single word giving the relative or absolute pathname of a 
#        directory.

#  Return value:

#  Notes:
#     If an exception is generated, it is handled using die() rather
#     than error(), since this routine may be called by error, and
#     we don't want to get into an infinite loop.

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameter.

   my $dir = shift;

#  Assemble command (by presenting a list, rather than a string, to
#  system() we guarantee that no shell processing will be done on 
#  the arguments).

   my @cmd = ("/bin/rm", "-rf", "$dir");
   my $cmd = join ' ', @cmd;

#  Form a very cautious opinion of whether it is safe to proceed.

   my $ok = 1
         && ($dir =~ /te*mp|junk|scratch/i)
         && ($dir !~ /[&|<> ;]/)
         && ($dir !~ /\.\./)
   ;

#  Execute the command or exit with error message.

   if ($ok) {
      system (@cmd) and die "Error in $cmd: $!\n";
   }
   else {
      die "Internal: command $cmd may be dangerous - see Scb::rmrf\n";
   }
}


########################################################################
#  Saved variable for pushd and popd.

my @dirstack;

########################################################################
sub pushd {

#+
#  Name:
#     pushd

#  Purpose:
#     Change directory and push old one to stack.

#  Language:
#     Perl 5

#  Invocation:
#     pushd ($dir);

#  Description:
#     This function does the same as its C shell namesake, changing
#     directory to the value given by its argument and pushing the 
#     current directory onto a stack whence it can be recalled by 
#     a subsequent popd.

#  Arguments:
#     $dir = string.
#        Directory to change to.

#  Return value:

#  Notes:

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameter.

   my $dir = shift;

#  Save current directory.

   push @dirstack, cwd;

#  Change to new directory.

   chdir $dir or error "chdir $dir: $!\n";
}

########################################################################
sub popd {

#+
#  Name:
#     popd

#  Purpose:
#     Change to previous directory on stack.

#  Language:
#     Perl 5

#  Invocation:
#     popd;

#  Description:
#     This function does the same as its C shell namesake, popping a
#     directory from the stack and changing to it.

#  Arguments:

#  Return value:

#  Notes:

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get directory name from stack.

   my $dir = pop @dirstack or error "Directory stack is empty\n";

#  Change to directory.

   chdir $dir or error "chdir $dir: $!\n";
}


########################################################################
sub parsetag {  

#+
#  Name:
#     parsetag

#  Purpose:
#     Parse an SGML-like tag.

#  Language:
#     Perl 5

#  Invocation:
#     %tag = parsetag ($tag);

#  Description:
#     Examines an SGML-like tag and returns a hash containing the name
#     and attributes.  A start tag will look like
#
#        <tagname att1='val1' att2=val2 att3>  (start tag)
#
#     and will yield a tag hash:
#
#        Start => 'tagname'
#        End   => ''
#        att1  => 'val1'
#        att2  => 'val2'
#        att3  => undef
#
#     and an end tag will look like
#
#        </tagname>
#
#     and will yield a tag hash:
#
#        Start => ''
#        End   => 'tagname'
#
#     Thus one of the hash keys 'Start' and 'End' will have an empty 
#     string value, and the other will have a non-empty string value.
#     End tags can have attributes too but usually don't.  Parsing is
#     as per usual in SGML/HTML, in particular:
#     
#        - Attribute names are case insensitive (always returned lower case)
#        - Attribute value may be ''- or ""-delimited, or be a single
#             alphanumeric word without delimiters, or be nonexistent

#  Arguments:
#     $tag = string.

#  Return value:
#     %tag = hash of strings.
#        Parsed content of tag.  See above.

#  Notes:

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameter.

   my $tag = shift;

#  Initialise 'Start' and 'End' pseudo-attributes.

   my %tag = (Start => '', End => '');
  
#  Identify tag name, and whether it is starting or ending.

   $tag =~ m%<(/?)\s*(\w+)\s*%g
      or error "Internal: '$tag' doesn't look like a tag.\n";
   $tag{ $1 ? 'End' : 'Start' } = lc $2;

#  Work through tag, writing attribute-value pairs to %tag hash.

   while ($tag =~ m%(\w+)\s*(?:=\s*(?:(["'])(.*?)\2|(\w*)))?%g) {
      $tag{lc $1} = $3 || $4;
   }

#  Return tag hash.

   return %tag;
}



1;

# $Id$
