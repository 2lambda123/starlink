<!--

Title:
  Starlink General DTD: LaTeX stylesheet for document elements

Author:
  Norman Gray, Glasgow (NG)

History:
  19 April 1999 (initial version)

Copyright 1999, 2004, Council for the Central Laboratory of the Research Councils

$Id$
-->

<routine>
<routinename>$latex-section$
<description>Simple function which should be called for all sectioning
commands.
<returnvalue type=sosofo>Produces a sosofo which creates the section heading.
<argumentlist>
<parameter>section-cmd
  <type>string
  <description>LaTeX command to format the title
<parameter keyword default="#t">children
  <type>boolean
  <description>If true, then invoke <funcname>process-children</funcname>, too. 
  It would be necessary to switch this off if there is some reason why
  the element contents should <em>not</em> be taken to be the section contents.
<codebody>
(define ($latex-section$ section-cmd #!key (children #t))
  (make sequence
    (make-latex-command name: section-cmd
	  (with-mode section-reference
	    (process-node-list (current-node))))
;     (if (attribute-string "indexkey")
;         (make element gi: "TeXML" attributes: '(("escape" "0"))
;               (make-latex-command name: "index"
;                     (literal
;                      (string-append
;                       (trim-data (current-node))
;                       (if (attribute-string "range")
;                           ;; generate makeindex range specifiers -- probably
;                           ;; a bad idea, but the user seems to want them...
;                           (if (string=? (attribute-string "range") "open")
;                               "|("
;                               "|)")
;                           "")))))
;         (empty-sosofo))
    (if children
	(process-children)
	(empty-sosofo))))

<routine>
<description>
Section constructors

<codebody>
(element sect
  (let ((in-appx? (have-ancestor? (normalize "appendices") (current-node))))
    (make sequence
      (if (if in-appx? appendix-samepage section-samepage)
	  (empty-sosofo)
	  (make-latex-empty-command name: "clearpage"))
      ($latex-section$ "section"))))
(element subsect ($latex-section$ "subsection"))
(element subsubsect ($latex-section$ "subsubsection"))
(element subsubsubsect ($latex-section$ "paragraph"))
;(element appendices ($latex-section$ "section"))

;; Discard the subhead, in general.
;; This is so we can call (process-children) on sections, and only process
;; the body.  We only need to go inside the subhead when we're in 
;; section-reference mode.
(element subhead
  (empty-sosofo))

