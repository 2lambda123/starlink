<!--
Title:
  Starlink stylesheet - sectioning

Author:
  Norman Gray, Glasgow (NG)

Revision history
  February 1999 (original version)

Copyright 1999, Particle Physics and Astronomy Research Council

$Id$
-->

<routine>
<routinename>$html-section-separator$
<description>If we are not chunking, then we need to separate sections
visually -- this emits a suitable sosofo.
<returnvalue type=sosofo>Empty sosofo or <code/HR/, depending on whether
we're chunking or not
<codebody>
(define ($html-section-separator$) 
  (if (or (chunking?)
	  (node-list=? (current-node) (document-element)))
      (empty-sosofo)
      (make empty-element gi: "HR")))

<routine>
<routinename>$html-section$
<description>Simple function which should be called for all sectioning 
commands which might be chunked.  The first child of the current node 
should be a subhead element (though in the older DocumentSummary DTD it
was just title).
<returnvalue type=sosofo>Either an HTML document, or else the contents of the
section ready to flow into whatever contains this.
<argumentlist>
<parameter optional default='($html-section-body$)'>bod
  <type>sosofo
  <description>The body of the section.
<codebody>
(define ($html-section$ #!optional (bod ($html-section-body$)))
;  (let ((title (node-list-first (children (current-node)))))
  (let* ((subhead (select-elements (children (current-node))
				   (normalize "subhead")))
	 (title (select-elements (children subhead)
				 (normalize "title"))))
    (if title
	(html-document (make formatting-instruction data: (data title))
		       bod)
	(error "Can't find title of section"))))

;(define ($html-section$ #!optional (bod ($html-section-body$)))
;   (html-document (with-mode section-reference
;                  (process-node-list (current-node)))
;                bod))


<routine>
<routinename>$html-section-body$
<description>A standard section body
<returnvalue type=sosofo>A standard layout for the body of a section
<codebody>
(define ($html-section-body$)
  (make sequence
    ($html-section-separator$)
    ($html-section-title$)
    (process-children)))

<routine>
<routinename>$html-section-title$
<description>
Returns a sosofo with the section heading, consisting of an Hn
element, enclosing an A element with a NAME attribute, enclosing
the section title.
<returnvalue type=sosofo>The section's title, including numbering if any
<codebody>
(define ($html-section-title$)
  (let (;(id (attribute-string (normalize "id") (current-node)))
	(id (href-to (current-node) frag-only: #t))
	)
    (make sequence
      (make element
	gi: (string-append "h" (number->string (sectlevel)))
	(if id
	    (make element
	      gi: "a"
	      attributes: (list (list "name" id))
	      (with-mode section-reference
		(process-node-list (current-node))))
	    (with-mode section-reference
	      (process-node-list (current-node))))))))

<routine>
<description>Rules for the various section elements in the DTD
<codebody>
(element sect ($html-section$))
(element subsect ($html-section$))
(element subsubsect ($html-section$))
(element subsubsubsect ($html-section$))
(element appendices ($html-section$))

;; Discard the subhead, in general.
;; This is so we can call (process-children) on sections, and only process
;; the body.  We only need to go inside the subhead when we're in 
;; section-reference mode.
(element subhead
  (empty-sosofo))
