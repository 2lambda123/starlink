<!-- Common parameterisation.

     $Id$

     This file collects together parameters which control various
     aspects of the generation of documents, which are common to all
     stylesheets.  All the things documented as `functions' below are
     really parameters.

     Note that a feature of Jade is that if the argument <code/-V
     variable/ is given on the command line, then that variable is set to
     <code>#t</>, overriding any setting within the stylesheet.  The
     parameters which are described as `boolean' below can be set in this
     way.

     If you want to change any other parameters, then make a copy of this
     file called, say, params-mod.dsl, modify it to suit your needs, and
     create a catalogue file in the same directory which has an line like:

         PUBLIC "-//Starlink//TEXT DSSSL Common Parameterisation//EN" 
             ../dsssl/sl/commonslparams.dsl

     (but all on a single line), giving the path to the parameterisation file,
     relative to the catalog.  Then adjust your $SGML_CATALOG_FILES
     environment variable to put this catalogue file early in the path.
     -->

<routine>
<routinename>%stylesheet-version%
<description>Version string
<codebody>
(define %stylesheet-version% "Starlink SGML Kit, version 0.7-12");%%VERSION%%

<routine>
<routinename>show-element-ids
<purpose>Display exported IDs
<description>
If true, then display exported IDs in section (etc) titles.  This is
useful for preparing a version of a document which you refer to while
working on it, or another which refers to it often.
<returnvalue type=boolean>True if we are to display exported ids.
<codebody>
(define show-element-ids #f)

<routine>
<routinename>%short-crossrefs%
<purpose>Generate shorter crossrefs
<description>If true, this will make the down-converter generate shorter 
link texts for cross-references.
<returnvalue type=boolean>Return true to generate short references
<codebody>
(define %short-crossrefs%
  #t)

<routine>
<routinename>suppress-manifest
<purpose>Turn off generation of manifest
<description>
If true, this will suppress the generation of a manifest, even if the variable 
<funcname>%latex-manifest%</> or <funcname>%html-manifest</> is given.
(This option can conveniently be set with <code>-V suppress-manifest</> on the 
Jade command line).
<returnvalue type=boolean>True if the manifest is to be suppressed
<codebody>
(define suppress-manifest #f)

<routine>
<routinename>%starlink-decl-entity%
<purpose>Pointer to Starlink SGML declaration
<description>
<p>Entity name which refers to the Starlink declaration.  This has to
be declared <em>somewhere</>: the default is declared in the General DTD.
<returnvalue type=string>Entity name, which will be resolved to a
     system-id elsewhere.
<codebody>
(define %starlink-decl-entity% "starlink.decl")
;; defined in DTD to point to "-//Starlink//TEXT Starlink Declaration//EN"

(define %xml-decl-entity% "xml.decl")

<routine>
<routinename>%copyright-string%
<description>Standard copyright string, unless overridden.
<returnvalue type=string>Text of copyright string.
<codebody>
(define %copyright-string%
  "Copyright 1999, Central Laboratories for the Research Councils")

<routine>
<routinename>%display-programcode-elements%
<purpose>List of programcode routineprologue elements to be displayed.
<description>This is a list of the GIs of the elements which are to be
displayed, if present in the document, when routineprologues are
formatted.  If "diytopic" is present in this list, it represents all
the diytopic elements, which are formatted together.
<p>Although one might expect the "purpose" element to appear here,
it is normally displayed using formatting different to that of
other elements in this list, so is best handled explicitly by 
formatting routines.
<returnvalue type='list of strings'>List of string names of element
types.
<codebody>
(define %display-programcode-elements%
  '("description"
    "invocation"
    "argumentlist"			;shouldn't have both argumentlist
    "parameterlist"			;and parameterlist in same prologue
    "returnvalue"
    "examplelist"
    "implementationstatus"
    "authorlist"
    "diytopic")
  ;; Alternative is
  ;;'("routinename" "purpose" "description" "returnvalue"
  ;;  "argumentlist" "parameterlist" "authorlist" "history"
  ;;  "usage" "invocation" "examplelist"
  ;;  "diytopic"
  ;;  "implementationstatus" "bugs")
  )
