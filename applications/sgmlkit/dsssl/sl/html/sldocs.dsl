<!-- -*- mode: sgml; sgml-parent-document: ("sl\.dsl" "CODEGROUP" '("PROGRAMCODE" "CODEGROUP")); -*- -->

<routine>
<routinename>process-html-document
<description>
<p>As this stylesheet's sole direct output, produce a string
which consists of the file-name-root, a colon, and a
space-separated list of the types which the generated HTML has
linked to.

<p>All the rest of the output goes to an entity generated by
<funcname/html-document/
<returnvalue type=sosofo>A sosofo which produces output to stdout,
then generates an HTML file
<codebody>
(define (process-html-document)
  (make sequence
    (if stream-output			; no info if output to stdout
	(empty-sosofo)
	(let ((extlist (if (and %link-extension-list%
				(not suppress-printable))
			   (apply string-append
				  (map (lambda (l)
					 (string-append (car l) " "))
				       %link-extension-list%))
			   "")))
	  (literal (string-append (root-file-name) ":" extlist ":"))))
    (html-document
     (process-node-list (getdocinfo 'title))
     (process-matching-children 'docbody))))

<routine>
<description>
These are the document element types.
<codebody>
(element sug (process-html-document))
(element sun (process-html-document))
(element ssn (process-html-document))
(element sc  (process-html-document))
(element sg  (process-html-document))
(element sgp (process-html-document))
(element mud (process-html-document))


<routine>
<description>Flow-object constructors for the head

<codebody>

;(element title
;  (literal (normalise-string (data (current-node)))))
(element title
  (process-children))
;(element displaytitle
;  (process-children))

(element authorlist
  (process-children))

(element otherauthors
  (let ((a (children (current-node))))
    (if (node-list-empty? a)
	(empty-sosofo)
	(node-list-reduce a
			  (lambda (res i)
			    (sosofo-append res
					   (make sequence
					     (process-node-list i)
					     (literal "; "))))
			  (literal "With: ")))))

(mode make-html-author-links
  (element author
    (let ((email (attribute-string "email")))
      (if email
	  (make empty-element
	    gi: "link"
	    attributes: (list (list "rev" "made")
			      (list "href" email)
			      (list "title" (data (current-node)))))
	  (empty-sosofo)))))

;; In the default mode, make author a link to the author details,
;; if either of the webpage or email attributes is present
(element author
  (let* ((webpage (attribute-string (normalize "webpage") (current-node)))
	 (link (cond (webpage)
		     ((attribute-string (normalize "email")
					 (current-node))
		       (string-append "mailto:"
				      (attribute-string (normalize "email")
							(current-node))))
		     (else #f))))
      (if link
	  (make element gi: "A"
		attributes: (list (list "HREF" link))
		(literal (normalise-string (data (current-node)))))
	  (literal (normalise-string (data (current-node)))))))



<routine>
<description>
Flow-object constructors for the document body

<p>Process the docbody element by creating a `title page', using
information from the docinfo element, then doing <funcname/process-children/
to format the document content.

<p>Need to have a think about exactly what dates and release information
are shown at the top of the document.

<codebody>
(element docbody
  (let* ((tsosofo (process-node-list (getdocinfo 'title)))
	 (authors (children (getdocinfo 'authorlist)))
	 (rel (document-release-info))
	 (vers (car (cdr (cdr (cdr rel)))))
	 (reldate (if (car (cdr rel))
		      (format-date (car (cdr rel)))
		      "not released"))
	 (docref (getdocnumber))
	 (copyright (getdocinfo 'copyright))
	 (coverimage (getdocinfo 'coverimage))
	 )
    (make sequence
      (make element gi: "a" attributes: '(("name" "xref_"))
	    (make element gi: "TABLE"
	    attributes: '(("WIDTH" "100%"))
	    (make sequence
	      (make element gi: "TR"
		    (make element gi: "TD"
			  attributes: (list (list "COLSPAN" "2")
					    (list "ALIGN" "CENTER"))
			  (make element gi: "H1"
				tsosofo)))
	      (if docref
		  (make element gi: "TR"
			(make sequence
			  (make element gi: "TD"
				attributes: (list (list "ALIGN"	"RIGHT")
						  (list "WIDTH" "50%"))
				(make element gi: "EM"
				      (literal "Document")))
			  ;; (make element gi: "TD"
			  ;; (literal docref))
			  (make element gi: "TD"
				(make sequence
				  (literal docref)
				  (literal (if vers
				      (string-append "." vers)
				      ""))))
			  ))
		  (empty-sosofo))
	      (make element gi: "TR"
		    (make sequence
		      (make element gi: "TD"
			    attributes: '(("ALIGN" "RIGHT"))
			    (make element gi: "EM"
				      (literal "Author")))
		      (make element gi: "TD"
			    (node-list-reduce
			     authors
			     (lambda (result a)
			       (sosofo-append
				result
				(make sequence
				  (process-node-list a)
				  (make empty-element gi: "BR"))))
			     (empty-sosofo)))))
	      (make element gi: "TR"
		    (make sequence
		      (make element gi: "TD"
			    attributes: '(("ALIGN" "RIGHT"))
			    (make element gi: "EM"
				      (literal "Release date")))
		      (make element gi: "TD"
			      (literal reldate))))
	      (if (and %starlink-banner% (not suppress-banner))
		  (make element gi: "TR"
			(make element gi: "TD"
			      attributes: (list (list "ALIGN" "CENTER")
						(list "COLSPAN" "2"))
			      (make element gi: "SMALL"
				    %starlink-banner%)))
		  (empty-sosofo)))))
      (if coverimage
	  (make element gi: "table"
		attributes: '(("width" "100%")
			      ("border" "1"))
		(make element gi: "tr"
		      (make element gi: "td"
			    attributes: '(("align" "center"))
			    (process-node-list coverimage))))
	  (empty-sosofo))
      (process-children)
      (if copyright
	  (make element gi: "p"
		(process-node-list copyright))
	  (empty-sosofo))
      (if (and %link-extension-list% (not suppress-printable))
	  (make element gi: "p"
		(literal "Printable version")
		(apply sosofo-append
		       (map (lambda (l)
			      (make sequence
				(literal " : ")
				(make element gi: "a"
				      attributes: (list (list "href"
							      (string-append
							       (root-file-name)
							       "." (car l)))
							(list "title"
							      (cdr l)))
				      (literal (cdr l)))))
			    %link-extension-list%)))
	  (empty-sosofo)))))

(element abstract
  (make sequence
    (make empty-element gi: "hr")
    (make element
      gi: "P"
      (make element
	gi: "STRONG"
	(literal "Abstract: ")))
    (make element
      gi: "BLOCKQUOTE"
      (process-children))
    (make empty-element gi: "hr")))


