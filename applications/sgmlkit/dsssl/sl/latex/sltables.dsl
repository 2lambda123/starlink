<!-- $Id$ -->

<!--
<docblock>
<title>LaTeX Tables
<description>The Starlink General DTD uses the OASIS Exchange Table
Model subset of the CALS table model (see
<url>http://www.oasis-open.org/html/a503.htm</url> for discussion and
<url>http://www.oasis-open.org/html/publtext.htm</url> for public
texts).

<p>The Exchange Table Model can be customised.  The only such
customisations at present are: replace the optional TITLE element with
a required CAPTION; add implied ID and EXPORT attributes to the TABLE;
extend the table entry model to include phrase markup.


<authorlist>
<author id=ng affiliation='Glasgow'>Norman Gray

<copyright>Copyright 1999, Particle Physics and Astronomy Research Council

<codegroup id=code.tables>
<title>Tables
<description>I've aimed to support all of the <em/structure/ of this table
model below, but not necessarily to support all of the attributes at
first.
-->


;; Return the node-list of colspecs, or #f if we're not in a tgroup
(define (get-colspecs #!optional (nd (current-node)))
  (let ((tg (if (string=? (gi nd) (normalize "tgroup"))
		nd
		(ancestor (normalize "tgroup") nd))))
    (if (node-list-empty? tg)
	#f
	(select-elements (children tg)
			 (normalize "colspec")))))
;; get column number of column with supplied name, or #f if none such exists
(define (get-column-number #!key (colspec #f)
				 (name #f)
				 (nd (current-node)))
  (let* ((cs-l (and (not colspec)
		    (get-colspecs nd)))
	 (cs (or colspec
		 (and cs-l
		      (node-list-first ;just in case there are two
		       (node-list-filter
			(lambda (n)
			  (string=? name
				    (attribute-string (normalize "colname")
						      n)))
			cs-l))))))
    (if (or (not cs)
	    (node-list-empty? cs))
	#f				;no such node
    (let loop ((n cs)
	       (inc 0))
      (if (node-list-empty? n)
	  inc
	  (if (attribute-string (normalize "colnum") n)
	      (+ (string->number (attribute-string (normalize "colnum") n))
		 inc)
	      (loop (ipreced n)
		    (+ inc 1))))))))

(element table
  (let ((float (attribute-string (normalize "float"))))
    (if (and float
	     (string=? float "float"))
	(make environment name: "table"
	      parameters: `(,%latex-float-spec%)
	      (process-matching-children 'tabular)
	      (process-matching-children 'caption))
	(make environment brackets: '("{" "}")
	      (make empty-command name: "SetCapType"
		    parameters: '("table"))
	      (process-matching-children 'tabular)
	      (process-matching-children 'caption)))))

;; TABULAR
;; Supported attributes colsep, frame (in tgroup), rowsep (in row)
;; Unsuported: pgwide
(element tabular
  (process-matching-children 'tgroup))

;; process a colspec `cs' given a pair default `def'.
;; Result should be a pair ("l|r|c" . "| or empty")
(define (proc-colspec cs def)
  (let ((colsep (attribute-string (normalize "colsep") cs))
	(align (attribute-string (normalize "align") cs)))
    (cons (if align
	      (case align
		(("left" "center" "justify") "l")
		(("right") "r")
		(("center") "c")
		(("char")
		 (error "colspec: align=char not supported"))
		(else
		 (error (string-append
			 "colspec: unrecognised alignment type ("
			 align ")"))))
	      (car def))
	  (if colsep
	      (if (= (string->number colsep) 0)
		  ""
		  "|")
	      (cdr def)))))

;; TGROUP
;; Supported attributes: colsep, cols, align, rowsep
;; Unsupported: (none)
(element tgroup
  (let* ((colno-str (attribute-string (normalize "cols") (current-node)))
	 (colno (if colno-str
		    (string->number colno-str)
		    (error "tgroup: required cols attribute missing")))
	 (tgroup-colsep (attribute-string (normalize "colsep")))
	 (colsep-str (or tgroup-colsep
			 (attribute-string (normalize "colsep")
					   (parent (current-node)) ;tabular
					   )))
	 (def-colsep (if (and colsep-str (= (string->number colsep-str) 0))
			 ""
			 "|"))		;default colsep present
	 (def-align-att (attribute-string (normalize "align") (current-node)))
	 ;; FIXME include p column specifiers somehow
	 (def-align (if def-align-att
			(case (case-fold-down def-align-att)
			  (("left" "justify") "l")
			  (("right") "r")
			  (("center") "c")
			  (("char")
			   (error "tgroup: char alignment not supported"))
			  (else
			   (error (string-append
				   "tgroup: unrecognised alignment ("
				   def-align-att ")"))))
			"l"))		;default
	 ;; form a list of pairs of (colspec, "| or nothing")
	 (def-colspec (let loop ((n colno)
				 (res '()))
			(if (<= n 0)
			    res
			    (loop (- n 1)
				  (append res
					  `((,def-align . ,def-colsep)))))))
	 (colspec-l-tmp (let loop ((res '()) ;result list
				(def-l def-colspec) ;list of spec to process
				(cs-l	;list of colspecs
				 (node-list->list (get-colspecs))))
		       (if (null? def-l)
			   res
			   (if (and (not (null? cs-l))
				    (= (get-column-number colspec: (car cs-l))
				       (+ (length res) 1)))
			       (loop (append res `(,(proc-colspec (car cs-l)
							       (car def-l))))
				     (cdr def-l)
				     (cdr cs-l))
			       (loop (append res `(,(car def-l)))
				     (cdr def-l)
				     cs-l)))))
	 (colspec-l (let ((l (reverse colspec-l-tmp)))
		      (reverse (append `((,(caar l) . ""))
				     (cdr l)))))
	 (colspec-string (apply string-append
				(map (lambda (p)
				       (string-append (car p) (cdr p)))
				     colspec-l)))
	 (border (let ((bspec (inherited-element-attribute-string
			       (normalize "tabular")
			       (normalize "frame")
			       (current-node))))
		   ;; produce a list containing #t when the (top bottom sides)
		   ;; are to have a border
		   (if bspec
		       (case bspec
			 (("top")    '(#t #f #f))
			 (("bottom") '(#f #t #f))
			 (("topbot") '(#t #t #f))
			 (("all")    '(#t #t #t))
			 (("sides")  '(#f #f #t))
			 (("none")   '(#f #f #f))
			 (else
			  (error (string-append
				  "tabular: illegal frame spec ("
				  bspec ")"))))
		       '(#f #f #f))))	;no frame by default
	 )
    (make environment name: "tabular"
	  parameters: (list (string-append (if (caddr border) "|" "")
					   colspec-string
					   (if (caddr border) "|" "")))
	  (if (car border)
	      (make empty-command name: "hline")
	      (empty-sosofo))
	  (process-children)
	  (if (cadr border)
	      (make empty-command name: "hline")
	      (empty-sosofo)))))

;; COLSPEC
;; Supported attributes: align, colname, colnum, colsep,
;; Unsupported: char, charoff, colwidth, rowsep
(element colspec
  ;; Nothing to display
  (empty-sosofo))

;; ROW
;; Supported attributes: rowsep
;; Unsupported: valign
(element row
  (let ((tgroup-cols (string->number
		      (inherited-element-attribute-string (normalize "tgroup")
							  (normalize "cols")
							  (current-node))))
	(actual-elements (node-list-length (children (current-node))))
	(rowsep-string
	 (or (attribute-string (normalize "rowsep"))
	     (attribute-string (normalize "rowsep")
			       (ancestor (normalize "tgroup")))
	     (attribute-string (normalize "rowsep")
			       (ancestor (normalize "tabular"))))))
    (if (<= actual-elements tgroup-cols)
	(make sequence
	  (process-children-trim)
	  (if (and (not (last-sibling?)) ;do we add a line below
		   rowsep-string
		   (not (= (string->number rowsep-string) 0)))
	      (make empty-command name: "hline")
	      (empty-sosofo)))
	(error (string-append
		"Row "
		(number->string (child-number (current-node)))
		" of table has more than "
		(number->string tgroup-cols)
		" rows, as declared")))))

;; THEAD & TBODY
;; Supported attributes: none
;; Unsupported: valign
(element thead
  (make sequence
    (process-children)
    (make empty-command name: "hline")))

(element tbody
  (process-children))

;; ENTRY
;; Supported attributes: colname, namest, nameend
;; Unsupported: align, char, charoff, colsep, morerows, rowsep, valign
(element entry
  (let* ((colname (attribute-string (normalize "colname")))
	 (namest (attribute-string (normalize "namest")))
	 (nameend (attribute-string (normalize "nameend")))
	 (start-col (or (and colname
			     (get-column-number name: colname))
			(and namest
			     (get-column-number name: namest))))
	 (amp-prefix (and start-col
			  (let loop ((n start-col))
			    (if (> n (child-number (current-node)))
				(string-append "&" (loop (- n 1)))
				"")))))
    (make sequence
      (if amp-prefix
	  (make fi data: amp-prefix)
	  (empty-sosofo))
      (if (and namest nameend)
	  (let ((sep (- (get-column-number name: nameend)
			(get-column-number name: namest)
			-1)))
	    (make command name: "multicolumn"
		  parameters: `(,(number->string sep) "c")
		  (process-children-trim)))
	  (process-children-trim))
      (if (last-sibling? (current-node))
	  (make fi data: "\\\\
")
	  (make fi data: "&")))))




<![IGNORE[
<routine>
<description>All the flow-object constructors
<codebody>
(element table
  (let ((float (attribute-string (normalize "float"))))
    (if float
	(make environment name: "table"
	      (process-matching-children 'tabular)
	      (process-matching-children 'caption))
	(make sequence
	  (process-matching-children 'tabular)
	  (process-matching-children 'caption)))))

(element tabular
  (process-matching-children 'tgroup))

(element tgroup
  (let* ((colno (table-colno))
	 (colspec (and colno
		       (let loop ((n (cadr colno))
				  (str ""))
			 (if (<= n 0)
			     str
			     (loop (- n 1) (string-append str "l")))))))
    (if colno
	(make environment name: "tabular"
	      parameters: (list colspec)
	      (process-children))
	(error "Can't find column number"))))

(element colspec
  ;; Merely discard these at present
  (empty-sosofo))

(element row
  (let ((colno (table-colno))
	(actual-elements (node-list-length (children (current-node)))))
    (if (<= actual-elements (cadr colno))
	(process-children-trim)
	(error (string-append
		"Row "
		(number->string (child-number (current-node)))
		" of table has more than "
		(number->string (cadr colno))
		" rows, as declared")))))

(element thead
  (make sequence
    (process-children)
    (make empty-command name: "hline")))

(element tbody
  (process-children))

(element entry
  (make sequence
    (process-children-trim)
    (if (last-sibling? (current-node))
	(make fi data: "\\\\")
	(make fi data: "&"))))


]]>
