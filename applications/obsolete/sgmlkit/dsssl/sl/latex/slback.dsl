<!DOCTYPE programcode PUBLIC "-//Starlink//DTD DSSSL Source Code 0.7//EN" [
  <!ENTITY common.dsl		SYSTEM "../common/slcommon.dsl" SUBDOC>
  <!ENTITY lib.dsl		SYSTEM "../lib/sllib.dsl" SUBDOC>
  <!ENTITY commonparams.dsl	PUBLIC "-//Starlink//TEXT DSSSL Common Parameterisation//EN">
  <!ENTITY params.dsl		PUBLIC "-//Starlink//TEXT DSSSL LaTeX Parameterisation//EN">
]>
<!-- $Id$ -->

<docblock>
<title>Backmatter in LaTeX
<description>Support the backmatter elements.  Reasonably simple in
LaTeX, because there's little cross-referencing to do.  The only
wrinkle is that we want to produce the printed documentation in a
single LaTeX pass, so we need to generate the bibliography `by hand'
in a separate Jade pass.

<authorlist>
<author id=ng affiliation='Glasgow'>Norman Gray

<copyright>Copyright 1999, Particle Physics and Astronomy Research Council

<codegroup id=code.back>
<title>Support backmatter

<routine>
<description>Declare Jade extension
<codebody>
(define read-entity
  (external-procedure "UNREGISTERED::James Clark//Procedure::read-entity"))
(declare-flow-object-class fi
  "UNREGISTERED::James Clark//Flow Object Class::formatting-instruction")

<routine>
<description>
Support backmatter elements.
<codebody>

;(element backmatter
;  (make sequence
;    ;;(make command name: "section"
;    ;;  (literal "Notes, etc"))
;    (make-bibliography)
;    (make-updatelist)))
(element backmatter
  (empty-sosofo))

(define (make-backmatter)
  (make sequence
    (make-bibliography)
    (make-index)
    (make-updatelist)))

(mode section-reference
  (element backmatter
    (make-section-reference title: (literal "Notes, etc..."))))

<routine>
<description>
Support notes very simply as footnotes.  Don't put them in the backmatter
in fact
<codebody>
(element note
  (make command name: "footnote"
	(process-children)))

<routine>
<description>
Bibliography support.  The citation can be handled very simply -- just
emit the citation key, bracketed.  For the bibliography itself, simply
read in the <code>.bbl</code> file we hope has been generated by a previous
Jade pass.
<codebody>
(element citation
  (make sequence
    (literal "[")
    (process-children)
    (literal "]")))

(define (hasbibliography?)
  (get-bibliography-name))

;; Return bibliography name or #f
(define (get-bibliography-name)
  (let ((bm (getdocbody 'backmatter)))
    (and bm
	 (attribute-string (normalize "bibliography") bm))))

(define (make-bibliography)
  (let* ((bibcontents (and (hasbibliography?)
			   (read-entity (string-append (root-file-name)
						       ".latexbib.bbl")))))
    (if bibcontents
	(make sequence
	  (make empty-command name: "section"
		parameters: '("Bibliography"))
	  (make fi data: bibcontents))
	(empty-sosofo))))

<routine>
<description>
Index support.  Very simple -- just emit an <code>\\index</code>
command.  We can only process the index after a LaTeX run, and
specifically not as part of the backmatter processing below.  We
cannot, therefore, automake index processing here.
<codebody>
(element index
  (make command name: "index"
        (literal
         (string-append
          (trim-data (current-node))
          (cond
           ((attribute-string "range")  ; generate makeindex range specifiers
            (if (string=? (attribute-string "range"))
                "|)"
                "|)"))
           ((attribute-string "seealso")
            (string-append "|seealso{" (attribute-string "seealso") "}"))
           (else
            ""))))))

(define (make-index)
  (let ((indexents (select-elements
                    (select-by-class (descendants (document-element))
                                     'element)
                    (normalize "index"))))
    (if (node-list-empty? indexents)
        (empty-sosofo)
        (let ((indfilename (string-append (index-file-name) ".ind")))
          (make sequence
            (make command name: "IfFileExists"
                  (literal indfilename))
            (make environment brackets: '("{" "}")
                  (make empty-command name: "input"
                        parameters: `(,indfilename)))
            (make environment brackets: '("{" "}")
                  (make command name: "typeout"
                        (literal
                         (string-append
                          "No index file " indfilename
                          ": run \"makeindex " (index-file-name)
                          "\", and re-LaTeX " (index-file-name))))))))))

<routine>
<description>
Process the history element in the docbody.  Present it in reverse order
(ie, newest first), including in the distribution and change elements any
update elements which refer to them.
<codebody>
(define (make-updatelist)
  (if (getdocinfo 'history)
      (make sequence
	(make empty-command name: "section"
	      parameters: '("Change history"))
	(with-mode extract-updatelist
	  (process-node-list (getdocinfo 'history))))
      (empty-sosofo)))


(mode extract-updatelist
  (element history
      (node-list-reduce (children (current-node))
			(lambda (last el)
			  (sosofo-append (process-node-list el)
					 last))
			(empty-sosofo)))
  (element version
    (make sequence
      (make command name: "subsection*"
	    (literal "Version " (attribute-string (normalize "number"))))
      (make paragraph
	    (process-node-list (element-with-id
				(attribute-string (normalize "author"))))
	    (literal ", "
		     (format-date (attribute-string (normalize "date")))))
      (collect-updates (literal "Changes in version "
				(attribute-string (normalize "number"))))))

  (element distribution
    (collect-updates (literal "Distribution "
			      (attribute-string (normalize "string")))))

  (element change
    (collect-updates (literal
		      "Change "
		      (format-date (attribute-string (normalize "date"))))))

  (element update
    (make sequence
      (make empty-command name: "item")
      (make environment brackets: '("[" "]")
	    (let ((linktarget (ancestor-member (current-node)
					       (target-element-list))))
	      (with-mode section-reference
		(process-node-list linktarget))))
      (process-children)))
  )

(define (collect-updates title)
  (let* ((allupdates (get-updates))
	 (myvid (attribute-string (normalize "versionid")))
	 (selupdates (and myvid
			  (node-list-or-false
			   (select-elements
			    allupdates
			    (list (normalize "update")
				  (list (normalize "versionid")
					myvid)))))))
    (make sequence
      (make command name: "subsection*"
	    title)
      (make paragraph
	    (process-node-list (element-with-id
				(attribute-string (normalize "author"))))
	    (literal ", "
		     (format-date (attribute-string (normalize "date")))))
      (process-children)
      (if selupdates
	  (make environment name: "description"
		(process-node-list selupdates))
	  (empty-sosofo)))))

(element update				; ignore in default mode
  (empty-sosofo))


<codereference doc="lib.dsl" id="code.lib">
<title>Library code
<description>
<p>Some of this library code is from the standard, some from Norm
Walsh's stylesheet, other parts from me

<codereference doc="common.dsl" id="code.common">
<title>Common code
<description>
<p>Code which is common to both the HTML and print stylesheets.

<codegroup id=back.main use="code.common code.lib">
<title>Preprocess backmatter
<description>This part of the stylesheet is standalone, and may be used
to process a document and extract those parts of the document (such as 
bibliography references) which require preprocessing.

<routine>
<description>
Extract the bibliography to a LaTeX .aux file, ready for processing
by BibTeX.
<codebody>
(declare-flow-object-class entity
  "UNREGISTERED::James Clark//Flow Object Class::entity")
(declare-flow-object-class fi
  "UNREGISTERED::James Clark//Flow Object Class::formatting-instruction")
;;(define debug
;;  (external-procedure "UNREGISTERED::James Clark//Procedure::debug"))


;; Read in the parameter file
&commonparams.dsl;
&params.dsl;

(root
    (make sequence
      (make fi data: (string-append (root-file-name) ":"))
      (get-bibliography)))

(define (get-bibliography)
  (let* ((kids (select-by-class (descendants (document-element)) 'element))
	 (citations (select-elements kids (normalize "citation")))
	 ;;(bibelement (select-elements kids (normalize "bibliography")))
	 (bm (getdocbody 'backmatter))
	 (bibname (and bm
		       (attribute-string (normalize "bibliography") bm)))
	 )
    (if (node-list-empty? citations)
	(empty-sosofo)
	(make entity system-id: (string-append (root-file-name)
					       ".latexbib.aux")
	      (make fi data: "\\relax
")
	      (process-node-list citations)
	      (if bibname
		  (make fi data: (string-append "\\bibdata{" bibname "}
\\bibstyle{plainlatex}
"))
		  (error "Citations but no BIBLIOGRAPHY in document"))
	      ;;(if (node-list-empty? bibelement)
	      ;;  (error "Citations but no BIBLIOGRAPHY in document")
	      ;;  (process-node-list bibelement))
	      ))))

(element citation
  (make fi data: (string-append "\\citation{" (trim-data (current-node)) "}
")))

