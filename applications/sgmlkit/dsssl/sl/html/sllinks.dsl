<!-- 

$Id$

<docblock>
<title>Inter- and Intra-document cross references for HTML
<description>
Support the various cross reference elements

<p>Note that, despite the intricate HyTime setup in the DTD, the
implementations here currently have the semantics built in, and
ignore the HyTime attributes!

<authorlist>
<author id=ng affiliation='Glasgow'>Norman Gray

<copyright>Copyright 1999, Particle Physics and Astronomy Research Council

<codegroup id='code.links'>
<title>Support cross references

-->

<routine>
<description>
<p>REF is a simple reference to another element in the same document.
Check that the target is a member of the list <funcname>target-element-list</>.
<p>If the target is a member of the list returned by
<funcname>section-element-list</>, then make the section reference by
calling <funcname>make-section-reference</>; otherwise, process the
target in mode <code>section-reference</>.
<p>Once we have obtained the element pointed to by the ID,
check to see if it is a <funcname>mapid</> element, and if it is,
immediately resolve the indirection.
<codebody>
(element ref
  (let* ((target-id (attribute-string (normalize "id")
				      (current-node)))
	 (tmp-target (node-list-or-false (element-with-id target-id)))
	 (target (if (and tmp-target
			  (string=? (gi tmp-target)
				    (normalize "mapid")))
		     (element-with-id (attribute-string (normalize "to")
							tmp-target))
		     tmp-target))
	 (linktext (data (current-node)))
	 )
    (if (and target
	     (member (gi target) (ref-target-element-list)))
	(make element
	  gi: "a"
	  attributes: (list (list "href" (href-to target)))
	  ;(with-mode section-reference
	  ;  (process-node-list target))
	  (if (string=? linktext "")
	      (if (member (gi target) (section-element-list))
		  (make-section-reference target: target specify-type: #t
					  short-ref: %short-crossrefs%)
		  (with-mode section-reference
		    (process-node-list target)))
	      (literal linktext))
	  )
	(if target
	    (error (string-append
		    "stylesheet can't link to elements of type "
		    (gi target)
		    " (ID " target-id ")"
		    ))
	    (error (string-append
		    "Can't find element with ID " target-id " in this document"
		    ))))))

;;; The following mode section-reference definition of REF (and the
;;; similar ones for DOCXREF, WEBREF and URL) is for dealing with
;;; DISPLAYTITLEs.  There's a problem using these, since DISPLAYTITLEs
;;; within the section names which are used as link text make an extra
;;; link within the link text!  The plan is that these simpler
;;; versions of the cross-referencing elements would be used in these
;;; contexts.
;;;
;;; This works, but I've since tentatively removed the DISPLAYTITLE
;;; element from the DTD.
; (mode section-reference
;   (element ref
;     (let ((target (element-with-id (attribute-string (normalize "id")
; 						     (current-node))))
; 	  (linktext (attribute-string (normalize "text")
; 				      (current-node))))
;       (if (member (gi target) (ref-target-element-list))
; 	  (if linktext
; 	      (literal linktext)	;override generation of link text
; 	      (if (member (gi target) (section-element-list))
; 		  (make-section-reference target: target specify-type: #t)
; 		  (with-mode section-reference
; 		    (process-node-list target))))
; 	  (error (string-append
; 		  "The stylesheet is presently unable to link to elements of type "
; 	          (gi target)))))))

(define ($make-dummy-link$ fpi #!optional (linktext #f))
  (let* ((els (parse-fpi fpi))
	 (descrip (query-parse-fpi 'text-description els))
	 (docnum (and descrip
		      (car (reverse (tokenise-string descrip)))))
	 (docparts (and docnum
			(tokenise-string docnum
					 isbdy?: (lambda (l)
						   (if (char=? (car l) #\/)
						       (cdr l)
						       #f)))))
	 (href (and docparts
		    (if (= (length docparts) 2)
			(string-append %starlink-document-server%
				       (case-fold-down (car docparts))
				       (cadr docparts)
				       ".htx/"
				       (case-fold-down (car docparts))
				       (cadr docparts)
				       ".html#xref_")
			#f))))
    (if href
	(make element gi: "a"
	      attributes: (list (list "href" href))
	      (literal (or linktext docnum)))
	#f)))

<routine>
<description>The <code>docxref</> element has a required attribute
giving the document which is to be referred to, and an optional
attribute giving an ID within that document.  The target of the link
should be a document marked up according to the <code>documentsummary</>
DTD.  In fact, that DTD is a base architecture of the Starlink General
DTD, so we could get the same effect by linking to the actual document
and extracting the <code>documentsummary</> architectural instance.
However, the <funcname>sgml-parse</> function in DSSSL isn't defined as
being able to do that; there is a Jade patch which allows it to do
that, which I hope to build into a Starlink version of Jade when I
can.

<p>Once we have obtained the element pointed to by the ID,
check to see if it is a <funcname>mapid</> element, and if it is,
immediately resolve the indirection.

<p>This rule invokes the <funcname>get-link-policy-target</> function to check
that the target of the link conforms to the policy -- if it doesn't,
it produces an <funcname>error</>.

<p>The rule uses the <code>mk-docxref</> mode to process the target element.

<codebody>
(element docxref
  (let* ((xrefent (attribute-string (normalize "doc") (current-node)))
	 ;; At one time, I extracted the entity's system id here.
	 ;; It's not clear why I did this, as the only apparent use to
	 ;; which I put it was to check whether it existed, and object
	 ;; vigourously if it did.  I don't know why I had such a
	 ;; downer on system ids in the entity declaration -- if I
	 ;; decide that this is, after all, a good thing to forbid,
	 ;; then perhaps I can put some explanation in next time.
	 ;(xrefent-sysid (and xrefent
	 ;	     (entity-system-id xrefent)))
	 (xrefent-gen-sysid (and xrefent
				 (entity-generated-system-id xrefent)))
	 (docelem (and xrefent-gen-sysid
		       (document-element-from-entity xrefent)
		       ))
	 (xrefid (attribute-string (normalize "loc") (current-node)))
	 ;; xreftarget is the element the docxref refers to, or #f if
	 ;; attribute LOC is implied or the document doesn't have such
	 ;; an ID
	 (tmp-xreftarget (and xrefid
			      docelem
			      (node-list-or-false (element-with-id xrefid
								   docelem))))
	 (xreftarget (if (and tmp-xreftarget
			      (string=? (gi tmp-xreftarget)
					(normalize "mapid")))
			 (element-with-id (attribute-string (normalize "to")
							    tmp-xreftarget)
					  docelem)
			 tmp-xreftarget))
	 (xrefurl (and xreftarget
		       (get-link-policy-target xreftarget)))
	 (linktext (attribute-string (normalize "text")
				     (current-node))))
    (if (and xrefent-gen-sysid
	     docelem
	     (string=? (gi docelem)
		       (normalize "documentsummary"))) ; sanity check...
	(if xreftarget
	    (if (car xrefurl)	; link to element by id
		(error (car xrefurl)) ; violated policy - complain
		(make element gi: "a"
		      attributes: (list (list "href"
					      (cdr xrefurl)))
		      (if linktext
			  (literal linktext)
			  (make sequence
			    (with-mode mk-docxref
			      (process-node-list (document-element
						  xreftarget)))
			    (literal ": ")
			    (with-mode section-reference
			      (process-node-list xreftarget))))))
	    (make element gi: "a"	; link to whole document
		  attributes:
		  (list (list "href"
			      (let ((url (attribute-string
					  (normalize "urlpath") docelem)))
				(if url
				    ;; Add the #xref_ fragment which
				    ;; hlink needs.  If this URL was
				    ;; obtained from a urlpath
				    ;; attribute, then this is
				    ;; required.  If not, then we're
				    ;; probably linking to a document
				    ;; which originated as SGML, but
				    ;; put in the fragment all the
				    ;; same, since hlink will remain
				    ;; in use in the medium term.
				    (string-append %starlink-document-server%
						   url "#xref_")
				    ;(href-to docelem reffrag: #f)
				    (href-to docelem force-frag: "xref_")
				    ))))
		  (if linktext
		      (literal linktext)
		      (with-mode mk-docxref
			(process-node-list docelem)))))
	(let ((xrefent-pubid (and xrefent
				  (entity-public-id xrefent))))
	  (cond
	   (docelem (error (string-append "DOCXREF: target " xrefent
					  " has document type " (gi docelem)
					  ": expected "
					  (normalize "documentsummary"))))
	   ;;(xrefent-sysid (error (string-append "DOCXREF: entity " xrefent
	   ;;				      " has a SYSTEM id")))
	   (xrefent-gen-sysid (error (string-append
				      "DOCXREF: Couldn't parse " xrefent
				      " (gen-sys-id " xrefent-gen-sysid ")")))
	   (xrefent-pubid (or ($make-dummy-link$ xrefent-pubid linktext)
			      (error (string-append
				      "DOCXREF: couldn't make sense of FPI '"
				      xrefent-pubid "'"))))
	   (xrefent (error (string-append "DOCXREF: entity " xrefent
					  " has no PUBLIC identifier")))
	   ;;(xrefent (string-append
	   ;;   "DOCXREF: Couldn't generate sysid for entity "
	   ;;	   xrefent))
	   (else (error "DOCXREF: missing DOC attribute")))))))


; (mode section-reference
;   (element docxref
;     (let* ((xrefent (attribute-string (normalize "doc") (current-node)))
; 	   (docelem (and xrefent
; 			 (document-element
; 			  (sgml-parse (entity-generated-system-id xrefent)))))
; 	   (linktext (attribute-string (normalize "text")
; 				       (current-node))))
;       (if (string=? (gi docelem)
; 		    (normalize "documentsummary")) ; sanity check...
; 	  (if xrefent
; 	      (if linktext
; 		  (literal linktext)	;override generation of link text
; 		  (with-mode mk-docxref
; 		    (process-node-list docelem)))
; 	      (error "No value for docxref's DOC attribute"))
; 	  (error (string-append "DOCXREF target " xrefent
; 				" has document type " (gi docelem)
; 				": expected DOCUMENTSUMMARY"))))))

(mode mk-docxref
  (element documentsummary
    (process-matching-children 'docinfo))
  (element docinfo
    (if %short-crossrefs%
	(literal (getdocnumber))
	(let ((dn (getdocnumber))
	      (dtitle (getdocinfo 'title)))
	  (make sequence
	    (literal (string-append dn ", "))
	    (make element gi: "cite"
		  (process-node-list dtitle)))))))

<routine>
<description><code>webref</> elements are simply transformed into HTML
<code>A</> elements, and <code>url</> elements into <code>A</> elements with
the URL as link text
<codebody>
(element url
  (make element gi: "code"
	(make sequence
	  (literal "<")
	  (if (attribute-string (normalize "nolink") (current-node))
	      (process-children)
	      (make element gi: "a"
		    attributes: (list (list "href" (trim-data (current-node))))
		    (process-children)))
	  (literal ">"))))

(element webref
  (make element gi: "a"
    attributes: (list (list "href" (attribute-string (normalize "url")
						     (current-node)))
		      (list "title" (normalise-string (data (current-node)))))
    (process-children)))

; (mode section-reference
;   (element url
;     (make element gi: "code"
; 	(make sequence
; 	  (literal "<")
; 	  (process-children)
; 	  (literal ">"))))
;   (element webref
;     (process-children)))

