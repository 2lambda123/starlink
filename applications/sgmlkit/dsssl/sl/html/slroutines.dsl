<!--
Title:
  Starlink stylesheet - routine list

Author:
  Norman Gray, Glasgow (NG)

Revision history
  February 1999 (original version)

Copyright 1999, Particle Physics and Astronomy Research Council

$Id$
-->

<routine>
<description>Constructors for the ROUTINELIST element
<codebody>
(mode section-reference
  ;;(element routinelist
  ;;  (make-section-reference title: (literal "Routine list")))
  (element routinelist
    (literal "Routine list"))
  (element codecollection
    (make-section-reference
     set-prefix: (literal (number->string (child-number)) " ")
     title: (with-mode routine-ref-get-reference
	      (process-codecollection (attribute-string (normalize "doc"))))))
  )


;; Routinelist is simple
(element routinelist ($html-section$ (process-children)))

;; Supporting the codecollection chunking/sectioning isn't as easy as with
;; the other such elements, because it doesn't have any children in this
;; document.  We have to do it rather more by hand, therefore.
;; Don't yet support the IDS attribute.
(element codecollection
  (let ((docent (attribute-string (normalize "doc"))))
    (if docent
	($html-section$ (with-mode routine-ref
			  (process-codecollection docent)))
	(error "codecollection: missing required doc attribute"))))

(define (process-codecollection docent)
  (if docent
      (let ((de (document-element-from-entity docent)))
	(if (node-list-empty? de)
	    (error (string-append "Couldn't get document element from doc "
				  docent))
	    (process-node-list de)))
      (empty-sosofo)))

(mode routine-ref-test
  (element programcode
    (literal "A program!")))

(mode routine-ref
  (element programcode
    (process-children))
  (element codegroup
    (make sequence
      (make empty-element gi: "hr")
      (make element gi: "h2"
	    (literal "Code group: ")
	    (with-mode routine-ref-get-reference
	      (process-children)))
      (process-children)))
  (element codereference
    (let ((ref-docelem (document-element-from-entity
			(attribute-string (normalize "doc")))))
      ;; possibly make this a link, in future
      (make sequence
	(make empty-element gi: "hr")
	(make element gi: "h2"
	      (literal "Code reference"))
	(make element gi: "p"
	      (make sequence
		(literal "Refers to ")
		(make element gi: "cite"
		      (with-mode routine-ref-get-reference
			(process-node-list ref-docelem)))))
	(process-children))))
  (element docblock
    (process-children))
  (element title
    (make element gi: "h1"
	  (process-children)))
  (element (codereference docblock title) ; discard, in this mode
    (empty-sosofo))			; (see mode routine-ref-get-reference)
  (element (codegroup docblock title)	; discard, in this mode
    (empty-sosofo))			; (see mode routine-ref-get-reference)
  (element authorlist
    (make sequence
      (make element gi: "h4"
	    (literal "Authors"))
      (make element gi: "ul"
	    (process-children))))
  (element author
    (let ((affil (attribute-string (normalize "affiliation")))
	  (id (attribute-string (normalize "id"))))
    (make element gi: "li"
	  (make sequence
	    (make element gi: "a"
		  attributes: (list (list "name" (string-append "AUTHOR_"
								id)))
		  (process-children))
	    (if affil
		(literal (string-append " (" affil ")"))
		(empty-sosofo))))))
  (element authorref
    (let* ((aut-id (attribute-string (normalize "id")))
	   (aut-el (and aut-id
			(element-with-id aut-id)))
	   (note (attribute-string (normalize "note"))))
      (if (and (not (node-list-empty? aut-el))
	       (string=? (gi aut-el) (normalize "author")))
	  (make element gi: "a"
		attributes: (list (list "href"
					(string-append "#AUTHOR_" aut-id)))
		(make sequence
		  (with-mode routine-ref-get-reference
		    (process-node-list aut-el))
		  (if note
		      (literal (string-append " (" note ")"))
		      (empty-sosofo))))
	  (error (string-append "ID " aut-id " is not an AUTHOR element")))))
  (element authornote
    (make sequence
      (make element gi: "em"
	    (process-children))))
  (element otherauthors
    (make element gi: "p"
	  (literal "Other contributors")
	  (make element gi: "ul"
		(process-children))))
  (element copyright
    (make sequence
      (make element gi: "h3"
	    (literal "Copyright"))
      (process-children)))
  (element history
    (make sequence
      (make element gi: "h3"
	    (literal "Change history"))
      (make element gi: "dl"
	    (process-children))))
  (element change
    (let ((auth-id (attribute-string (normalize "author")))
	  (date-str (attribute-string (normalize "date"))))
      (make sequence
	(make element gi: "dt"
	      (literal (string-append (data (element-with-id auth-id))
				      ", "
				      (format-date date-str))))
	(make element gi: "dd"
	      (process-children)))))
  (element routineprologue
    (let ((kids (nl-to-pairs (children (current-node)))))
      (make sequence
	(apply sosofo-append
	       (map (lambda (gi)
		      (let ((gi-and-nd (assoc (normalize gi) kids)))
			(if gi-and-nd
			    (process-node-list (cdr gi-and-nd))
			    (empty-sosofo))))
		    '("routinename" "purpose" "description" "returnvalue"
		      "argumentlist" "parameterlist" "authorlist" "history"
		      "usage" "invocation" "examplelist" "notelist"
		      "implementationstatus" "bugs"))))))
  (element routinename
    (make sequence
      (make element gi: "h3"
	    (process-children))))
  (element name
    (make element gi: "b"
	  (process-children)))
  (element othernames
    (let* ((names (children (current-node)))
	   (namelist (node-list-reduce
		      names
		      (lambda (res i)
			(if (string=? res "")
			    (data i)
			    (string-append res ", " (data i))))
		      "")))
      (literal (string-append " (also: " namelist ")"))))
  (element purpose
    (make element gi: "p"
	  (make sequence
	    (make element gi: "b"
		  (literal "Purpose: "))
	    (process-children))))
  (element description
    (process-children))
  (element returnvalue
    (let ((none-att (attribute-string (normalize "none")))
	  (type-att (attribute-string (normalize "type"))))
      (if none-att
	  (make element gi: "h4"
		(literal "No return value")) ;...and discard any data
	  (make sequence
	    (make element gi: "h4"
		  (literal "Return value"))
	    (if type-att
		(make element gi: "p"
		      (literal (string-append "Type: " type-att)))
		(empty-sosofo))
	    (process-children)))))
  (element argumentlist
    (let ((none-att (attribute-string (normalize "none"))))
      (if none-att
	  (make element gi: "h4"
		(literal "No arguments"))
	  (make sequence
	    (make element gi: "h4"
		  (literal "Argument list"))
	    (process-children)))))
  (element parameterlist
    (let ((none-att (attribute-string (normalize "none"))))
      (if none-att
	  (make element gi: "h4"
		(literal "No parameters"))
	  (make sequence
	    (make element gi: "h4"
		  (literal "Parameter list"))
	    (process-children)))))
  (element parameter
    (let* ((kids (children (current-node)))
	   (name (select-elements kids (normalize "name")))
	   (type (select-elements kids (normalize "type")))
	   (desc (select-elements kids (normalize "description")))
	   (opt-att (attribute-string (normalize "optional")))
	   (dir-att (attribute-string (normalize "direction"))))
      (make sequence
	(make element gi: "h5"
	      (process-node-list name)
	      (literal (string-append " (" (data type) ") " dir-att
				      (if opt-att
					  (string-append ", " opt-att)
					  ""))))
	(process-node-list desc))))
  (element usage
    (make sequence
      (make element gi: "h4"
	    (literal "Usage"))
      (process-children)))
  (element invocation
    (make sequence
      (make element gi: "h4"
	    (literal "Invocation"))
      (process-children)))
  (element implementationstatus
    (make sequence
      (make element gi: "h4"
	    (literal "Implementation Status"))
      (process-children)))
  (element bugs
    (make sequence
      (make element gi: "h4"
	    (literal "Bugs"))
      (process-children)))
  (element notelist
    (process-children))
  (element othernote
    (let ((kids (children (current-node))))
      (make sequence
	(make element gi: "h4"
	      (literal (data (node-list-first kids))))
	(process-node-list (node-list-rest kids)))))
  (element examplelist
    (make sequence
      (make element gi: "h4"
	    (literal "Examples"))
      (process-children)))
  (element example
    (make sequence
      (make element gi: "h5"
	  (literal "Example " (number->string (child-number (current-node)))))
      (make element gi: "code"
	    (process-children))))
  ;; The funcname element could be made more sophisticated, so that
  ;; it includes a link (possibly using the source-code browser) to
  ;; the function definition/documentation.
  (element funcname
    (make element gi: "code"
          (literal (string-append "(" (data (current-node)) ")"))))
  ;; discard the following elements, at present
  (element codebody
    (empty-sosofo))
  ;(element misccode
  ;  (empty-sosofo))
  )

;; Mode which includes assorted variants of the handlers above, designed
;; to extract information to which other handlers have made cross-reference.
(mode routine-ref-get-reference
  (default (empty-sosofo))
  (element programcode
    (process-matching-children 'docblock))
  (element docblock
    (process-matching-children 'title))
  (element title
    (process-children))
;  (element author
;    (let ((attrib (attribute-string (normalize "affiliation"))))
;    (make element gi: "li"
;	  (process-matching-children 'name)
;	  (if attrib
;	      (literal (string-append " (" attrib ")"))
;	      (empty-sosofo)))))
  (element name
    (process-children)))

