<!DOCTYPE programcode PUBLIC "-//Starlink//DTD DSSSL Source Code 0.6//EN" [
  <!ENTITY common.dsl		SYSTEM "../common/slcommon.dsl" SUBDOC>
  <!ENTITY lib.dsl		SYSTEM "../lib/sllib.dsl" SUBDOC>
  <!ENTITY commonparams.dsl	PUBLIC "-//Starlink//TEXT DSSSL Common Parameterisation//EN">
  <!ENTITY params.dsl		PUBLIC "-//Starlink//TEXT DSSSL HTML Parameterisation//EN">
]>
<!-- $Id$ -->

<docblock>
<title>Back-matter in HTML
<description>
Support the back-matter elements.  Support notes as endnotes, 
support bibliography citations using BibTeX as an external processor,
and support indexing (soon!) using makeindex.

<authorlist>
<author id=ng affiliation='Glasgow'>Norman Gray

<copyright>Copyright 1999, Particle Physics and Astronomy Research Council

<codegroup id='code.back'>
<title>Support back-matter

<routine>
<description>Declare Jade extension
<codebody>
(define read-entity
  (external-procedure "UNREGISTERED::James Clark//Procedure::read-entity"))
(declare-flow-object-class fi
  "UNREGISTERED::James Clark//Flow Object Class::formatting-instruction")
;;(define debug
;;  (external-procedure "UNREGISTERED::James Clark//Procedure::debug"))

<routine>
<description>
Support back-matter elements.  Changes here might need matching changes 
in mode make-manifest-mode in sl.dsl
<codebody>
(element backmatter
  (empty-sosofo))

(define (hasbackmatter?)
  (or (hasnotes?) (hasbibliography?) (hashistory?) (hasidindex?)))

;; Do NOT call this within the context of the document-element.  It
;; messes up big-time if (current-node) is the document-element.
(define (process-backmatter)
  (if (hasbackmatter?)
      (html-document (literal "Backmatter")
		     (make sequence
		       (make element gi: "ul"
			     (make-contents-backmatter))
		       (make-idindex)
		       (make-notecontents)
		       (make-bibliography)
		       (make-updatelist))
		     system-id: (backmatter-sys-id)
		     force-chunk?: #t
		     navbars?: #f)
      (empty-sosofo)))

(define (make-manifest-backmatter)
  (make sequence
    (if (hasbackmatter?)
	(make fi data: (string-append (backmatter-sys-id) "
"))
	(empty-sosofo))
    (if (hasnotes?)
	(make fi data: (string-append (notes-sys-id) "
"))
	(empty-sosofo))
    (if (hasbibliography?)
	(make fi data: (string-append (bibliography-sys-id) "
"))
	(empty-sosofo))
    (if (hashistory?)
	(make fi data: (string-append (updatelist-sys-id) "
"))
	(empty-sosofo))
    (if (hasidindex?)
	(make fi data: (string-append (idindex-sys-id) "
"))
	(empty-sosofo))))

;; This function caters for the possibility that _no_ backmatter 
;; needs to be generated.  Generally, the history
;; element requires at least one version, but a MUD may have 
;; no history element?
(define (make-contents-backmatter)
  (let* ((noteslist
	  (if (hasnotes?)
	      (make element gi: "li"
		    (make element gi: "a"
			  attributes:
			  (list (list "href" (string-append
					      (notes-sys-id)
					      "#" (notes-frag-id))))
			  (literal "Notes")))
	      #f))
	 (biblist
	  (if (get-bibliography-name)
	      (make element gi: "li"
		    (make element gi: "a"
			  attributes:
			  (list (list "href" (string-append
					      (bibliography-sys-id)
					      "#" (bibliography-frag-id))))
			  (literal "Bibliography")))
	      #f))
	 (updateslist
	  (if (hashistory?) ;(get-updates)
	      (make element gi: "li"
		    (make element gi: "a"
			  attributes:
			  (list (list "href" (string-append
					      (updatelist-sys-id)
					      "#" (updatelist-frag-id))))
			  (literal "Changes")))
	      #f
	      ))
	 (idindex
	  (if (hasidindex?)
	      (make element gi: "li"
		    (make element gi: "a"
			  attributes:
			  (list (list "href" (string-append
					      (idindex-sys-id)
					      "#" (idindex-frag-id))))
			  (literal "ID index")))
	      #f))
	 (contentslist (if (or noteslist biblist updateslist idindex)
			   (sosofo-append (or noteslist (empty-sosofo))
					  (or biblist (empty-sosofo))
					  (or updateslist (empty-sosofo))
					  (or idindex (empty-sosofo)))
			   #f)))
    (if contentslist
	(make element gi: "li"
	      (make element gi: "a"
		    attributes: (list (list "href" (backmatter-sys-id)))
		    (literal "Backmatter"))
	      (make element gi: "ul"
		    contentslist))
	(empty-sosofo))))

(define (backmatter-sys-id)
  (if (chunking?)
      (html-file uniq: "backmatter")
      (html-file target_nd: (document-element))))
(define (notes-sys-id)
  (if (chunking?)
      (html-file uniq: "notes")
      (html-file target_nd: (document-element))
      ))
(define (bibliography-sys-id)
  (if (chunking?)
      (html-file uniq: "bibliography")
      (html-file target_nd: (document-element))))
(define (updatelist-sys-id)
  (if (chunking?)
      (html-file uniq: "updates")
      (html-file target_nd: (document-element))))

(define (notes-frag-id) "xref__NOTES")
(define (bibliography-frag-id) "xref__BIBLIOGRAPHY")
(define (updatelist-frag-id) "xref__UPDATELIST")

(mode section-reference
  (element backmatter
    (empty-sosofo)))

<routine>
<description>
Support notes as endnotes.  
<codebody>
(define (hasnotes?)
  (not (node-list-empty? (get-notelist))))

;(mode section-reference
;  (element notecontents
;    (make-section-reference title: (literal "Notes"))))

(element note
  (let ((en (number->string (element-number (current-node)))))
    (make element gi: "small"
      (literal "[")
      (make element gi: "a"
	    attributes: (list (list "href" (string-append (notes-sys-id)
							  "#NOTETEXT" en))
			      (list "name" (string-append "NOTEREF" en)))
	    (literal (string-append "Note " en)))
      (literal "]"))))
(mode extract-notecontents
  (element note
    (let ((en (number->string (element-number (current-node)))))
      (make sequence
	(make element gi: "dt"
	      (make element gi: "a"
		    attributes: (list (list "href" (string-append
						    (href-to (current-node))
						    "#NOTEREF" en))
				      (list "name" (string-append
						    "NOTETEXT" en)))
		    (literal (string-append "Note " en))))
	(make element gi: "dd"
	      (process-children))))))

(define (get-notelist)
  (select-elements (select-by-class (descendants (getdocbody))
				    'element)
		   (normalize "note")))

(define (make-notecontents)
  (let ((notelist (get-notelist)))
    (if (node-list-empty? notelist)
	(empty-sosofo)
	(html-document (literal "Notes")
		       (make sequence
			 (make element gi: "h2"
			       (make element gi: "a"
				     attributes: (list (list "name"
							     (notes-frag-id)))
				     (literal "Notes")))
			 (make element gi: "dl"
			       (with-mode extract-notecontents
				 (process-node-list notelist))))
		       system-id: (notes-sys-id)
		       force-chunk?: #t
		       navbars?: #f))))

<routine>
<description>
Bibliography support.  The bibliography preprocessor (BibTeX) produces
an HTML DL element with entries referrable to by the bibkey, which is
the data of the CITATION element.
<codebody>
(define (hasbibliography?)
  (get-bibliography-name))

;; Return bibliography name or #f
(define (get-bibliography-name)
  (let ((bm (getdocbody 'backmatter)))
    (and bm
	 (attribute-string (normalize "bibliography") bm))))

(element citation
  (let ((bib-name (get-bibliography-name))
	(cit-data (trim-data (current-node))))
    (if bib-name
	(make element gi: "a"
	      attributes: (list (list "href" (string-append
					      (bibliography-sys-id)
					      "#"
					      cit-data)))
	      (literal (string-append "[" cit-data "]")))
	(error "Have CITATION but no BIBLIOGRAPHY"))))

(define (make-bibliography)
  (let* ((bibcontents (and (hasbibliography?)
			   (read-entity (string-append (root-file-name)
						       ".htmlbib.bbl")))))
    (if bibcontents
	(html-document (literal "Bibliography")
		       (make sequence
			 (make element gi: "h2"
			       (make element gi: "a"
				     attributes: (list (list "name"
							     (bibliography-frag-id)))
				     (literal "Bibliography")))
			 (make fi data: bibcontents))
		       system-id: (bibliography-sys-id)
		       force-chunk?: #t
		       navbars?: #f)
	(empty-sosofo))))

<routine>
<description>
Process the history element in the docbody.  Present it in reverse order
(ie, newest first), including in the distribution and change elements any
update elements which refer to them.
<codebody>
(define (hashistory?)
  (or (getdocinfo 'history)
      (get-updates)))

(define (make-updatelist)
  (if (hashistory?)
      (html-document (literal "Change history")
		     (make sequence
		       (make element gi: "h2"
			     (make element gi: "a"
				   attributes: (list (list "name"
							   (updatelist-frag-id)))
				   (literal "Change history")))
		       (with-mode extract-updatelist
			 (process-node-list (getdocinfo 'history))))
		     system-id: (updatelist-sys-id)
		     force-chunk?: #t
		     navbars?: #f)
      (empty-sosofo)))

;(define (make-updatelist)
;  (let ((updatelist (get-updates)))
;    (if (node-list-empty? updatelist)
;	(empty-sosofo)
;	(html-document (literal "Change history")
;		       (make sequence
;			 (make element gi: "h1"
;			       (literal "Change history"))
;			 (make element gi: "dl"
;			       (with-mode extract-updatelist
;				 (process-node-list updatelist))))
;		       system-id: (updatelist-sys-id)))))

;; Instead of 
;;
;;   (process-node-list
;;    (element-with-id (attribute-string (normalize "author"))))
;;
;; I tried using
;;
;;   (process-node-list (referent (attribute (normalize "author")
;;                                           (current-node))))
;;
;; but that didn't work, and (referent) always seemed to return an empty
;; node list.  I scoured through the property set, and referent seems to
;; have the value `node', so I don't understand what's wrong.  It's likely
;; related to the fact that if the "author" attribute had IDREFS declared
;; value, then this would have to return a list -- perhaps the return
;; value of referent has subnodes, or perhaps I'm just not understanding
;; property sets properly.  Note that the procedures used here are not
;; implemented as primitives in Jade, and have to be inserted: 
;; (node-list-property) from clause 10.2.3, (attribute) and (referent)
;; from clause 10.2.5.

(mode extract-updatelist
  (element history
      (node-list-reduce (children (current-node))
			(lambda (last el)
			  (sosofo-append (process-node-list el)
					 last))
			(empty-sosofo)))
  (element version
    (make sequence
      (make element gi: "h2"
	    (literal "Version " (attribute-string (normalize "number"))))
      (make element gi: "p"
	    (process-node-list (element-with-id
				(attribute-string (normalize "author"))))
	    (literal ", "
		     (format-date (attribute-string (normalize "date")))))
      (process-children)))
  (element distribution
    (collect-updates (literal "Distribution "
			      (attribute-string (normalize "string")))))
  (element change
    (collect-updates (literal
		      "Change "
		      (format-date (attribute-string (normalize "date"))))))
  (element update
    (make sequence
      (make element gi: "dt"
	    (let ((linktarget (ancestor-member (current-node)
					       (target-element-list))))
	      (make element gi: "a"
		    attributes: (list (list "href"
					    (href-to linktarget)))
		    (with-mode section-reference
		      (process-node-list linktarget)))))
      (make element gi: "dd"
	    (process-children)))
    )
  )

(element update				; ignore in default mode
  (empty-sosofo))

;; collect-updates can be called only within distribution or change
;; FO constructor.
(define (collect-updates title)
  (let* ((allupdates (get-updates))
	 (myvid (attribute-string (normalize "versionid")))
	 (selupdates (and myvid
			  allupdates
			  (node-list-or-false
			   (select-elements
			    allupdates
			    (list (normalize "update")
				  (list (normalize "versionid")
					myvid)))))))
    (make sequence
      (make element gi: "h3"
	    title)
      (make element gi: "p"
	    (process-node-list (element-with-id
				(attribute-string (normalize "author"))))
	    (literal ", "
		     (format-date (attribute-string (normalize "date")))))
      (process-children)
      (if selupdates
	  (make element gi: "dl"
		(process-node-list selupdates))
	  (empty-sosofo)))))

<routine>
<description>
Linking support.  Create a page listing all the exported IDs in the document,
so that document authors can find them in once place.
<codebody>
(define (hasidindex?)
  (not suppress-idindex))
(define (idindex-sys-id)
  (if (chunking?)
      (html-file uniq: "idindex")
      (html-file target_nd: (document-element))))
(define (idindex-frag-id) "xref__IDINDEX")
(define (make-idindex)
  (if suppress-idindex
      (empty-sosofo)
      (html-document
       (literal "ID Index")
       (let ((all-els (node-list-filter-by-gi
		       (select-by-class (descendants (getdocbody))
					'element)
		       (target-element-list))))
	 (make sequence
	   (make element gi: "h2"
		 (make element gi: "a"
		       attributes: (list (list "name" (idindex-frag-id)))
		       (literal "ID Index")))
	   (make element gi: "p"
		 (literal "Index of IDs in this document.  Exported IDs indicated ")
		 (make element gi: "strong"
		       (literal "like this.")))
	   (with-mode make-idindex-mode
	     (process-node-list all-els))))
       system-id: (idindex-sys-id)
       force-chunk?: #t
       navbars?: #f)))
(mode make-idindex-mode
  (default
    (let ((id (attribute-string (normalize "id") (current-node))))
      (if id
	  (let* ((export (attribute-string (normalize "export")
					   (current-node)))
		 (format (if export "strong" "em"))
		 (target (element-with-id id)))
	    (make element gi: "p"
		  (make sequence
		    (make element gi: format
			  (literal "<" (gi target) " id=")
			  (make element gi: "a"
				attributes:
				(list (list "href" (href-to target)))
				(literal id)))
		    (literal ">")
		    (with-mode section-reference
		      (process-node-list target)))))
	  (empty-sosofo))))
  (element sect
    (let ((id (attribute-string (normalize "id") (current-node))))
      (if id
	  (let* ((export (attribute-string (normalize "export")
					   (current-node)))
		 (format (if export "strong" "em"))
		 (target (element-with-id id)))
	    (make sequence
	      (make empty-element gi: "hr")
	      (make element gi: "h3"
		    (make sequence
		      (make element gi: format
			    (literal "<" "sect id=")
			    (make element gi: "a"
				  attributes:
				  (list (list "href" (href-to target))
					(list "name" (string-append
						      "xref__IDINDEX_" id)))
				  (literal id)))
		      (literal ">")
		      (with-mode section-reference
			(process-node-list target))))))
	  (empty-sosofo)))))
; nothing yet

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
(define debug
  (external-procedure "UNREGISTERED::James Clark//Procedure::debug"))

;; Read in the parameter file
&commonparams.dsl
&params.dsl;

(root
    (make sequence
      (make fi data: (string-append (root-file-name) ":"))
      (get-bibliography)))

(define (get-bibliography)
  (let* ((kids (select-by-class (descendants (getdocbody)) 'element))
	 (citations (select-elements kids (normalize "citation")))
	 ;(bibelement (select-elements kids (normalize "bibliography")))
	 (bibname (get-bibliography-name))
	 )
    (if bibname
	(if (node-list-empty? citations)
	    (empty-sosofo)
	    (make entity system-id: (string-append (root-file-name)
						   ".htmlbib.aux")
		  (make fi data: "\\relax
")
		  (process-node-list citations)
		  (if bibname
		      (make fi data: (string-append "\\bibdata{" bibname "}
\\bibstyle{plainhtml}
"))
		      (error "Citations but no BIBLIOGRAPHY in document"))
		  ;;(if (node-list-empty? bibelement)
		  ;;  (error "Citations but no BIBLIOGRAPHY in document")
		  ;;  (process-node-list bibelement))
	      ))
	(error "No backmatter in document, or bibliography not specified"))))

(element citation
  (make fi data: (string-append "\\citation{" (trim-data (current-node)) "}
")))

;(element bibliography
;  (make sequence
;    (make fi data: (string-append "\\bibdata{"
;				  (attribute-string "BIB" (current-node))
;				  "}
;"))
;    (make fi data: "\\bibstyle{plainhtml}
;")))
