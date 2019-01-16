;;;; vex.lisp

(in-package #:vex)

(defmacro local-idiom (symbol)
  "Shorthand macro to output the name of a Vex idiom in the local package."
  (let ((sym (intern (format nil "*~a-IDIOM*" (string-upcase symbol))
		     (string-upcase symbol))))
    (if (not (boundp sym))
	`(progn (defvar ,sym)
		,sym)
	sym)))

;; The idiom object defines a vector language instance with a persistent state.
(defclass idiom ()
  ((name :accessor idiom-name
    	 :initarg :name)
   (system :accessor idiom-system
	   :initform nil
	   :initarg :system)
   (utilities :accessor idiom-utilities
	      :initform nil
	      :initarg :utilities)
   (lexicons :accessor idiom-lexicons
	     :initform nil
	     :initarg :lexicons)
   (functions :accessor idiom-functions
	      :initform nil
	      :initarg :functions)
   (operators :accessor idiom-operators
	      :initform nil
	      :initarg :operators)
   (grammar-elements :accessor idiom-grammar-elements
		     :initform nil
		     :initarg :grammar-elements)
   (composer-opening-patterns :accessor idiom-composer-opening-patterns
			      :initform nil
			      :initarg :composer-opening-patterns)
   (composer-following-patterns :accessor idiom-composer-following-patterns
				:initform nil
				:initarg :composer-following-patterns)))

(defgeneric of-system (idiom property))
(defmethod of-system ((idiom idiom) property)
  "Retrieve a property of the idiom's system."
  (getf (idiom-system idiom) property))

(defgeneric of-utilities (idiom utility))
(defmethod of-utilities ((idiom idiom) utility)
  "Retrieve one of the idiom's utilities used for parsing and language processing."
  (getf (idiom-utilities idiom) utility))

(defgeneric of-functions (idiom key type))
(defmethod of-functions ((idiom idiom) key type)
  "Retrive one of the idiom's functions."
  (gethash key (getf (idiom-functions idiom) type)))

(defgeneric of-operators (idiom key type))
(defmethod of-operators ((idiom idiom) key type)
  "Retrive one of the idiom's operators."
  (gethash key (getf (idiom-operators idiom) type)))

(defgeneric of-lexicon (idiom lexicon glyph))
(defmethod of-lexicon (idiom lexicon glyph)
  "Check whether a character belongs to a given Vex lexicon."
  (member glyph (getf (idiom-lexicons idiom) lexicon)))

(defmacro boolean-op (operation)
  "Wrap a boolean operation for use in a vector language, converting the t or nil it returns to 1 or 0."
  (let ((omega (gensym)) (alpha (gensym)) (outcome (gensym)))
    `(lambda (,omega &optional ,alpha)
       (let ((,outcome (funcall (function ,operation) ,alpha ,omega)))
	 (if ,outcome 1 0)))))

(defmacro reverse-op (is-dyadic &optional operation)
  "Wrap a function so as to reverse the arguments passed to it, so (- 5 10) will result in 5."
  (let ((is-dyadic (if operation is-dyadic))
	(operation (if operation operation is-dyadic))
	(omega (gensym)) (alpha (gensym)))
    `(lambda (,omega &optional ,alpha)
       ,(if is-dyadic `(funcall (function ,operation) ,alpha ,omega)
	    `(if ,alpha (funcall (function ,operation) ,alpha ,omega)
		 (funcall (function ,operation) ,omega))))))

(defun process-lex-tests-for (symbol operator &key (mode :test))
  "Process a set of tests for Vex functions or operators."
  (let* ((tests (rest (assoc (intern "TESTS" (package-name *package*))
			     (rest operator))))
	 (props (rest (assoc (intern "HAS" (package-name *package*))
			     (rest operator))))
	 (heading (format nil "[~a] ~a~a~%" (first operator)
			  (if (getf props :title)
			      (getf props :title)
			      (if (getf props :titles)
				  (first (getf props :titles))))
			  (if (getf props :titles)
			      (concatenate 'string " / " (second (getf props :titles)))
			      ""))))
    (labels ((for-tests (tests &optional output)
	       (if tests (for-tests (rest tests)
				    (append output `((princ (format nil "  _ ~a" ,(cadr (first tests))))
						     ,@(cond ((and (eq :test mode)
								   (eql 'is (caar tests)))
							      `((is (,(intern (string-upcase symbol)
									      (package-name *package*))
								      ,(cadar tests))
								    ,(third (first tests))
								    :test #'equalp)))
							     ((and (eq :demo mode)
								   (eql 'is (caar tests)))
							      `((princ #\Newline)
								(let ((output
								       (,(intern (string-upcase symbol)
										 (package-name *package*))
									 (with (:state :output-printed :only))
									 ,(cadar tests))))
								  (princ (concatenate
									  'string "    "
									  (regex-replace-all
									   "[\\n]" output
									   (concatenate 'string (list #\Newline)
											"    "))))
								  (if (or (= 0 (length output))
									  (not (char=
										#\Newline
										(aref output (1- (length
												  output))))))
								      (princ #\Newline)))
								,@(if (rest tests)
								      `((princ #\Newline)))))))))
		   output)))
      (if tests (append `((princ ,(format nil "~%~a" heading)))
			(for-tests tests))))))

;; TODO: this is also April-specific, move it into spec
(defun process-general-tests-for (symbol test-set &key (mode :test))
  "Process specs for general tests not associated with a specific function or operator."
  `((princ ,(format nil "~%~a ~a" (cond ((string= "FOR" (string-upcase (first test-set)))
					 #\∇)
					((string= "FOR-PRINTED" (string-upcase (first test-set)))
					 #\⎕))
		    (second test-set)))
    (princ (format nil "~%  _ ~a~%" ,(third test-set)))
    ,(cond ((and (eq :test mode)
		 (string= "FOR" (string-upcase (first test-set))))
	    `(is (,(intern (string-upcase symbol) (package-name *package*))
		   ,(third test-set))
		 ,(fourth test-set)
		 :test #'equalp))
	   ((and (eq :demo mode)
		 (string= "FOR" (string-upcase (first test-set))))
	    `(let ((output (,(intern (string-upcase symbol) (package-name *package*))
					  (with (:state :output-printed :only))
			     ,(third test-set))))
	       (princ (concatenate 'string "    "
				   (regex-replace-all "[\\n]" output
						      (concatenate 'string (list #\Newline)  "    "))))
	       (if (or (= 0 (length output))
		       (not (char= #\Newline (aref output (1- (length output))))))
		   (princ #\Newline))))
	   ((and (eq :test mode)
		 (string= "FOR-PRINTED" (string-upcase (first test-set))))
	    `(is (,(intern (string-upcase symbol) (package-name *package*))
		   (with (:state :output-printed :only))
		   ,(third test-set))
		 ,(fourth test-set)
		 :test #'string=))
	   ((and (eq :demo mode)
		 (string= "FOR-PRINTED" (string-upcase (first test-set))))
	    `(princ (concatenate
		     'string "    "
		     (regex-replace-all "[\\n]"
					(,(intern (string-upcase symbol) (package-name *package*))
					  (with (:state :output-printed :only))
					  ,(third test-set))
					(concatenate 'string (list #\Newline)  "    "))))))))

(defmacro specify-vex-idiom (symbol &rest subspecs)
  "Wraps the idiom-spec macro for an initial specification of a Vex idiom."
  `(vex-idiom-spec ,symbol nil ,@subspecs))

(defmacro extend-vex-idiom (symbol &rest subspecs)
  "Wraps the idiom-spec macro for an extension of a Vex idiom."
  `(vex-idiom-spec ,symbol t ,@subspecs))

(defun merge-lexicons (source &optional target)
  "Combine two Vex symbol lexicons."
  (if (not source)
      target (merge-lexicons (cddr source)
			     (progn (setf (getf target (first source))
					  (append (getf target (first source))
						  (second source)))
				    target))))

(defun merge-options (source target)
  (let ((output (loop :for section :in target
		   :collect (let ((source-items (rest (assoc (first section) source)))
				  (pair-index 0)
				  ;; the osection values are copied from (rest section), otherwise it's
				  ;; effectively a pass-by-reference and changing osection will change section
				  (osection (loop :for item :in (rest section) :collect item)))
			      (loop :for (item-name item-value) :on source-items :while item-value
				 :do (if (evenp pair-index)
					 (setf (getf osection item-name) item-value))
				 (incf pair-index))
			      (cons (first section)
				    osection)))))
    (loop :for section :in source :when (not (assoc (first section) target))
       :do (setq output (cons section output)))
    output))

(defun build-doc-profile (symbol spec mode section-names)
  (let ((specs (loop :for subspec :in spec :when (or (string= "FUNCTIONS" (string-upcase (first subspec)))
						     (string= "OPERATORS" (string-upcase (first subspec)))
						     (string= "TEST-SET" (string-upcase (first subspec))))
		  :collect subspec)))
    (loop :for name :in section-names
       :append (let* ((subspec (find name specs :test (lambda (id form)
							(eq id (second (assoc :name (rest (second form)))))))))
		 (cons (if (eq :demo mode)
			   `(princ (format nil "~%~%∘○( ~a~%  ( ~a~%"
					   ,(getf (rest (assoc :demo-profile (cdadr subspec)))
						  :title)
					   ,(getf (rest (assoc :demo-profile (cdadr subspec)))
						  :description)))
			   `(princ (format nil "~%~%∘○( ~a )○∘~%"
					   ,(getf (rest (assoc :tests-profile (cdadr subspec)))
						  :title))))
		       (loop :for test-set :in (cddr subspec)
			  :append (funcall (if (or (string= "FUNCTIONS" (string-upcase (first subspec)))
						   (string= "OPERATORS" (string-upcase (first subspec))))
					       #'process-lex-tests-for
					       #'process-general-tests-for)
					   symbol test-set :mode mode)))))))

(defmacro vex-idiom-spec (symbol extension &rest subspecs)
  "Process the specification for a vector language and build functions that generate the code tree."
  (macrolet ((of-subspec (symbol-string)
	       `(rest (assoc (intern ,(string-upcase symbol-string) (package-name *package*))
			     subspecs)))
	     (build-lexicon () `(loop :for lexicon :in (getf (rest this-lex) :lexicons)
				   :do (if (not (getf lexicon-data lexicon))
					   (setf (getf lexicon-data lexicon) nil))
				   (if (not (member char (getf lexicon-data lexicon)))
				       (setf (getf lexicon-data lexicon)
					     (cons char (getf lexicon-data lexicon)))))))
    (let* ((symbol-string (string-upcase symbol))
	   (idiom-symbol (intern (format nil "*~a-IDIOM*" symbol-string)
				 (package-name *package*)))
	   (lexicon-data)
	   (lexicon-processor (getf (of-subspec utilities) :process-lexicon))
	   (function-specs
	    (loop :for subspec :in subspecs :when (string= "FUNCTIONS" (string-upcase (first subspec)))
	       :append (loop :for spec :in (cddr subspec)
			  :append (let ((glyph-chars (cons (character (first spec))
							   (mapcar #'character (getf (rest (second spec))
										     :aliases)))))
				    (loop :for char :in glyph-chars
				       :append (let ((this-lex (funcall (second lexicon-processor)
									:functions char (third spec))))
						 (build-lexicon)
						 `(,@(if (getf (getf (rest this-lex) :functions) :monadic)
							 `((gethash ,char (getf fn-specs :monadic))
							   ',(getf (getf (rest this-lex) :functions) :monadic)))
						     ,@(if (getf (getf (rest this-lex) :functions) :dyadic)
							   `((gethash ,char (getf fn-specs :dyadic))
							     ',(getf (getf (rest this-lex) :functions)
								     :dyadic)))
						     ,@(if (getf (getf (rest this-lex) :functions) :symbolic)
							   `((gethash ,char (getf fn-specs :symbolic))
							     ',(getf (getf (rest this-lex) :functions)
								     :symbolic))))))))))
	   (operator-specs
	    (loop :for subspec :in subspecs :when (string= "OPERATORS" (string-upcase (first subspec)))
	       :append (loop :for spec :in (cddr subspec)
			  :append (let ((glyph-chars (cons (character (first spec))
							   (mapcar #'character (getf (rest (second spec))
										     :aliases)))))
				    (loop :for char :in glyph-chars
				       :append (let ((this-lex (funcall (second lexicon-processor)
									:operators char (third spec))))
						 (build-lexicon)
						 (if (member :lateral-operators
							     (getf (rest this-lex) :lexicons))
						     `((gethash ,char (getf op-specs :lateral))
						       ,(getf (rest this-lex) :operators))
						     (if (member :pivotal-operators
								 (getf (rest this-lex) :lexicons))
							 `((gethash ,char (getf op-specs :pivotal))
							   ,(getf (rest this-lex) :operators))))))))))
	   (demo-forms (build-doc-profile symbol subspecs :demo (rest (assoc :demo (of-subspec doc-profiles)))))
	   (test-forms (build-doc-profile symbol subspecs :test (rest (assoc :test (of-subspec doc-profiles)))))
	   ;; note: the pattern specs are processed and appended in reverse order so that their ordering in the
	   ;; spec is intuitive, with more specific pattern sets such as optimization templates being included after
	   ;; less specific ones like the baseline grammar
	   (pattern-settings `((idiom-composer-opening-patterns ,idiom-symbol)
			       (append (idiom-composer-opening-patterns ,idiom-symbol)
				       (append ,@(loop :for pset :in (reverse (rest (assoc :opening-patterns
											   (of-subspec grammar))))
						    :collect `(funcall (function ,pset) ,idiom-symbol))))
			       (idiom-composer-following-patterns ,idiom-symbol)
			       (append (idiom-composer-following-patterns ,idiom-symbol)
				       (append ,@(loop :for pset :in (reverse (rest (assoc :following-patterns
											   (of-subspec grammar))))
						    :collect `(funcall (function ,pset) ,idiom-symbol))))))
	   (idiom-definition `(make-instance 'idiom :name ,(intern symbol-string "KEYWORD")))
	   (alt-sym (concatenate 'string symbol-string "-P"))
	   (elem (gensym)) (options (gensym)) (input-string (gensym)) (body (gensym))
	   (process (gensym)) (form (gensym)) (item (gensym)))
      `(progn ,@(if (not extension)
		    `((defvar ,idiom-symbol)
		      (setf ,idiom-symbol ,idiom-definition)))
	      (setf (idiom-system ,idiom-symbol)
		    (append (idiom-system ,idiom-symbol)
			    ,(cons 'list (of-subspec system)))
		    (idiom-utilities ,idiom-symbol)
		    (append (idiom-utilities ,idiom-symbol)
			    ,(cons 'list (of-subspec utilities)))
		    (idiom-lexicons ,idiom-symbol)
		    (merge-lexicons (idiom-lexicons ,idiom-symbol)
				    (quote ,lexicon-data))
		    (idiom-functions ,idiom-symbol)
		    (let ((fn-specs ,(if extension `(idiom-functions ,idiom-symbol)
					 `(list :monadic (make-hash-table)
						:dyadic (make-hash-table)
						:symbolic (make-hash-table)))))
		      (setf ,@function-specs)
		      fn-specs)
		    (idiom-operators ,idiom-symbol)
		    (let ((op-specs ,(if extension `(idiom-operators ,idiom-symbol)
					 `(list :lateral (make-hash-table)
						:pivotal (make-hash-table)))))
		      (setf ,@operator-specs)
		      op-specs))
	      ,@(if (assoc :elements (of-subspec grammar))
		    `((setf (idiom-grammar-elements ,idiom-symbol)
			    (loop :for ,elem
			       :in (funcall (function ,(second (assoc :elements (of-subspec grammar))))
					    ,idiom-symbol)
			       :append ,elem))))
	      (setf ,@pattern-settings)
	      ,@(if (not extension)
		    `((defmacro ,(intern symbol-string (package-name *package*))
			  (,options &optional ,input-string)
			;; this macro is the point of contact between users and the language, used to
			;; evaluate expressions and control properties of the language instance
			(cond ((and ,options (listp ,options)
				    (string= "TEST" (string-upcase (first ,options))))
			       `(progn (setq prove:*enable-colors* nil)
				       (plan ,(loop :for exp :in ',test-forms :counting (eql 'is (first exp))))
				       ,@',test-forms (finalize)
				       (setq prove:*enable-colors* t)))
			      ((and ,options (listp ,options)
				    (string= "DEMO" (string-upcase (first ,options))))
			       `(progn ,@',demo-forms "Demos complete!"))
			      ;; the (test) setting is used to run tests
			      (t `(progn ,(if (and ,input-string (assoc :space (rest ,options)))
					      `(defvar ,(second (assoc :space (rest ,options)))))
					 ;; TODO: defvar here should not be necessary since the symbol
					 ;; is set by vex-program if it doesn't exist, but a warning is displayed
					 ;; nonetheless, investigate this
					 ,(vex-program ,idiom-symbol
						       (if ,input-string
							   (if (string= "WITH" (string (first ,options)))
							       (rest ,options)
							       (error "Incorrect option syntax.")))
						       (eval (if ,input-string ,input-string ,options)))))))
		      (defmacro ,(intern alt-sym (package-name *package*))
			  (&rest ,options)
			(cons ',(intern symbol-string (package-name *package*))
			      (append (if (second ,options)
					  (if (not (member :print-to (assoc :state (cdar ,options))))
					      (list (cons (caar ,options)
							  (merge-options `((:state :print-to *standard-output*))
									 (cdar ,options))))
					      (list (first ,options)))
					  `((with (:state :print-to *standard-output*))))
				      (last ,options))))
		      (defmacro ,(intern (concatenate 'string "WITH-" symbol-string "-CONTEXT")
					 (package-name *package*))
			  (,options &rest ,body)
			(labels ((,process (,form)
				   (loop :for ,item :in ,form
				      :collect (if (and (listp ,item)
							(or (eql ',(intern symbol-string (package-name *package*))
								 (first ,item))
							    (eql ',(intern alt-sym (package-name *package*))
								 (first ,item))))
						   (list (first ,item)
							 (if (third ,item)
							     (cons (caadr ,item)
							 	   (merge-options (cdadr ,item)
										  ,options))
							     (cons 'with ,options))
							 (first (last ,item)))
						   (if (listp ,item)
						       (,process ,item)
						       ,item)))))
			  (cons 'progn (,process ,body))))))))))

(defun derive-opglyphs (glyph-list &optional output)
  "Extract a list of function/operator glyphs from part of a Vex language specification."
  (if (not glyph-list)
      output (derive-opglyphs (rest glyph-list)
			      (let ((glyph (first glyph-list)))
				(if (characterp glyph)
				    (cons glyph output)
				    (if (stringp glyph)
					(append output (loop :for char :below (length glyph)
							  :collect (aref glyph char)))))))))

(defun =vex-string (idiom meta &optional output special-precedent)
  "Parse a string of text, converting its contents into nested lists of Vex tokens."
  (labels ((?blank-character () (?satisfies (of-utilities idiom :match-blank-character)))
	   (?newline-character () (?satisfies (of-utilities idiom :match-newline-character)))
	   (?token-character () (?satisfies (of-utilities idiom :match-token-character)))
	   (=string (&rest delimiters)
	     (let ((lastc)
		   (delimiter))
	       (=destructure (_ content _)
		   (=list (?satisfies (lambda (c) (if (member c delimiters)
						      (setq delimiter c))))
			  ;; note: nested quotes must be checked backwards; to determine whether a delimiter
			  ;; indicates the end of the quote, look at previous character to see whether it is a
			  ;; delimiter, then check whether the current character is an escape character #\\
			  (=subseq (%any (?satisfies (lambda (char)
						       (if (or (not lastc)
							       (not (char= char delimiter))
							       (char= lastc #\\))
							   (setq lastc char))))))
			  (?satisfies (lambda (c) (char= c delimiter))))
		 content)))
	   (=vex-closure (boundary-chars &optional transform-by)
	     (let ((balance 1)
		   (char-index 0))
	       (=destructure (_ enclosed _)
		   (=list (?eq (aref boundary-chars 0))
			  ;; for some reason, the first character in the string is iterated over twice here,
			  ;; so the character index is checked and nothing is done for the first character
			  ;; TODO: fix this
			  (=transform (=subseq (%some (?satisfies (lambda (char)
								    (if (and (char= char (aref boundary-chars 0))
									     (< 0 char-index))
									(incf balance 1))
								    (if (and (char= char (aref boundary-chars 1))
									     (< 0 char-index))
									(incf balance -1))
								    (incf char-index 1)
								    (< 0 balance)))))
				      (if transform-by transform-by
					  (lambda (string-content)
					    (first (parse string-content (=vex-string idiom meta))))))
			  (?eq (aref boundary-chars 1)))
		 enclosed)))
	   (handle-axes (input-string)
	     (let ((each-axis (funcall (of-utilities idiom :process-axis-string)
				       input-string)))
	       (cons :axes (mapcar (lambda (string) (first (parse string (=vex-string idiom meta))))
				   each-axis))))
	   (handle-function (input-string)
	     (list :fn (list (first (parse input-string (=vex-string idiom meta)))))))

    (let ((olnchar))
      ;; the olnchar variable is needed to handle characters that may be functional or part
      ;; of a number based on their context; in APL it's the . character, which may begin a number like .5
      ;; or may work as the inner/outer product operator, as in 1 2 3+.×4 5 6.
      (symbol-macrolet ((functional-character-matcher
			 ;; this saves space below
			 (let ((ix 0))
			   (lambda (char)
			     (if (and (> 2 ix)
				      (funcall (of-utilities idiom :match-overloaded-numeric-character)
					       char))
				 (setq olnchar char))
			     (if (and olnchar (= 2 ix)
				      (not (digit-char-p char)))
				 (setq olnchar nil))
			     (incf ix 1)
			     (and (not (< 2 ix))
				  (or (of-lexicon idiom :functions char)
				      (of-lexicon idiom :operators char)))))))
	(=destructure (_ item _ break rest)
	    (=list (%any (?blank-character))
		   (%or (=vex-closure "()")
			(=vex-closure "[]" #'handle-axes)
			(=vex-closure "{}" #'handle-function)
			(=string #\' #\")
			(=transform (=subseq (%some (?satisfies functional-character-matcher)))
				    (lambda (string)
				      (let ((char (character string)))
					(if (not olnchar)
					    (append (list (if (of-lexicon idiom :operators char)
							      :op (if (of-lexicon idiom :functions char)
								      :fn)))
						    (if (of-lexicon idiom :operators char)
							(list (if (of-lexicon idiom :pivotal-operators char)
								  :pivotal :lateral)))
						    (list char))))))
			(=transform (=subseq (%some (?token-character)))
				    (lambda (string)
				      (funcall (of-utilities idiom :format-value)
					       (string-upcase (idiom-name idiom))
					       ;; if there's an overloaded token character passed in
					       ;; the special precedent, prepend it to the token being processed
					       meta (if (getf special-precedent :overloaded-num-char)
							(concatenate 'string (list (getf special-precedent
											 :overloaded-num-char))
								     string)
							string)))))
		   (%any (?blank-character))
		   (=subseq (%any (?newline-character)))
		   (=subseq (%any (?satisfies 'characterp))))
	  ;; (print (list :item item break rest))
	  (if (and (= 0 (length break))
		   (< 0 (length rest)))
	      (parse rest (=vex-string idiom meta (if output (if item (cons item output)
								 output)
						      (if item (list item)))
				       (if olnchar (list :overloaded-num-char olnchar))))
	      (list (if item (cons item output)
			output)
		    rest)))))))

(defmacro set-composer-elements (name with &rest params)
  "Specify basic language elements for a Vex composer."
  (let* ((with (rest with))
	 (tokens (getf with :tokens-symbol))
	 (idiom (getf with :idiom-symbol))
	 (space (getf with :space-symbol with))
	 (properties (getf with :properties-symbol))
	 (process (getf with :processor-symbol with)))
    `(defun ,(intern (string-upcase name) (package-name *package*)) (,idiom)
       (declare (ignorable ,idiom))
       (list ,@(loop :for param :in params
		  :collect `(list ,(intern (string-upcase (first param)) "KEYWORD")
				  (lambda (,tokens &optional ,properties ,process ,idiom ,space)
				    (declare (ignorable ,properties ,process ,idiom ,space))
				    ,(second param))))))))

(defun composer (idiom space tokens &optional precedent properties)
  "Compile processed tokens output by the parser into code according to an idiom's grammars and primitive elements."
  ;; (print (list :comp tokens precedent properties))
  (if (not tokens)
      (values precedent properties)
      (let ((processed)
	    (special-params (getf properties :special)))
	;; (print (list :prec precedent))
	;; (print (list :tokens-b precedent tokens))
	(loop :while (not processed)
	   :for pattern :in (if (not precedent)
				(vex::idiom-composer-opening-patterns idiom)
				(vex::idiom-composer-following-patterns idiom))
	   :when (or (not (getf special-params :omit))
		     (not (member (getf pattern :name)
				  (getf special-params :omit))))
	   ;; (print (list :pattern (getf pattern :name) precedent tokens properties))
	   :do (multiple-value-bind (new-processed new-props remaining)
		   (funcall (getf pattern :function)
			    tokens space (lambda (item &optional sub-props)
					   (declare (ignorable sub-props))
					   (composer idiom space item nil sub-props))
			    precedent properties)
		 ;; (if new-processed (princ (format nil "~%~%!!Found!! ~a ~%~a~%" new-processed
		 ;; 				      (list new-props remaining))))
		 (if new-processed (setq processed new-processed properties new-props tokens remaining))))
	(if special-params (setf (getf properties :special) special-params))
	(if (not processed)
	    (values precedent properties tokens)
	    (composer idiom space tokens processed properties)))))

(defmacro set-composer-patterns (name with &rest params)
  "Generate part of a Vex grammar from a set of parameters."
  (let* ((with (rest with))
	 (idiom (gensym)) (token (gensym)) (invalid (gensym)) (properties (gensym))
	 (space (or (getf with :space-symbol) (gensym)))
	 (precedent-symbol (getf with :precedent-symbol))
	 (precedent (or precedent-symbol (gensym)))
	 (process (or (getf with :process-symbol) (gensym)))
	 (sub-properties (or (getf with :properties-symbol) (gensym)))
	 (idiom-symbol (getf with :idiom-symbol)))
    `(defun ,(intern (string-upcase name) (package-name *package*)) (,idiom)
       (let ((,idiom-symbol ,idiom))
	 (declare (ignorable ,idiom-symbol))
	 (list ,@(loop :for param :in params
		    :collect `(list :name ,(intern (string-upcase (first param)) "KEYWORD")
				    :function (lambda (,token ,space ,process &optional ,precedent ,properties)
						(declare (ignorable ,precedent ,properties))
						(let ((,invalid)
						      (,sub-properties)
						      ,@(loop :for token :in (second param)
							   :when (not (keywordp (first token)))
							   :collect (list (first token) nil)))
						  ,@(build-composer-pattern (second param)
									    idiom-symbol token invalid properties
									    process space sub-properties)
						  (setq ,sub-properties (reverse ,sub-properties))
						  ;; reverse the sub-properties since they are consed into the list
						  (if (not ,invalid)
						      (values ,(third param)
							      ,(fourth param)
							      ,token)))))))))))

(defun build-composer-pattern (sequence idiom tokens-symbol invalid-symbol properties-symbol
			       process space sub-props)
  "Generate a pattern for language compilation from a set of specs entered as part of a grammar."
  (let ((item (gensym)) (item-props (gensym)) (remaining (gensym)) (matching (gensym))
	(collected (gensym)) (rem (gensym)) (initial-remaining (gensym)))
    (labels ((element-check (base-type)
	       `(funcall (getf (vex::idiom-grammar-elements ,idiom)
			       ,(intern (string-upcase (cond ((listp base-type) (first base-type))
							     (t base-type)))
					"KEYWORD"))
			 ,rem ,(cond ((listp base-type) `(quote ,(rest base-type))))
			 ,process ,idiom ,space))
	     (process-item (item-symbol item-properties)
	       (let ((multiple (getf item-properties :times))
		     (optional (getf item-properties :optional))
		     (element-type (getf item-properties :element))
		     (pattern-type (getf item-properties :pattern)))
		 (cond (pattern-type
			`(if (not ,invalid-symbol)
			     (multiple-value-bind (,item ,item-props ,remaining)
				 (funcall ,process ,tokens-symbol
					  ,@(if (and (listp (second item-properties))
						     (getf (second item-properties) :special))
						`((list :special ,(getf (second item-properties) :special)))))
			       (setq ,sub-props (cons ,item-props ,sub-props))
			       (if ,(cond ((getf pattern-type :type)
					   `(loop :for type :in (list ,@(getf pattern-type :type))
					       :always (member type (getf ,item-props :type))))
					  (t t))
				   (setq ,item-symbol ,item
					 ,tokens-symbol ,remaining)
				   (setq ,invalid-symbol t)))))
		       (element-type
			`(if (not ,invalid-symbol)
			     (let ((,matching t)
				   (,collected)
				   (,rem ,tokens-symbol)
				   (,initial-remaining ,tokens-symbol))
			       (declare (ignorable ,initial-remaining))
			       (loop ,@(if (eq :any multiple)
					   `(:while (and ,matching ,rem))
					   `(:for x from 0 to ,(if multiple (1- multiple) 0)))
				  :do (multiple-value-bind (,item ,item-props ,remaining)
					  ,(element-check element-type)
					;; only push the returned properties onto the list if the item matched
					(if (and ,item ,item-props (not (getf ,item-props :cancel-flag)))
					    (setq ,sub-props (cons ,item-props ,sub-props)))
					;; if a cancel-flag property is returned, void the collected items
					;; and reset the remaining items back to the original list of tokens
					(if (getf ,item-props :cancel-flag)
					    (setq ,rem ,initial-remaining
						  ,collected nil))
					;; blank the collection after a mismatch if a pattern is to be
					;; matched multiple times, as with :times N
					,(if (numberp multiple) `(if (not ,item) (setq ,collected nil)))
					(if (and ,item ,matching)
					    (setq ,collected (cons ,item ,collected)
						  ,rem ,remaining)
					    (setq ,matching nil))))
			       (if ,(if (not optional) collected t)
				   (setq ,item-symbol (if (< 1 (length ,collected))
							  ,collected (first ,collected))
					 ,tokens-symbol ,rem)
				   (setq ,invalid-symbol t))
			       (list :out ,item-symbol ,tokens-symbol ,collected ,optional))))))))
      (loop :for item :in sequence
	 :collect (let* ((item-symbol (first item)))
		    (if (keywordp item-symbol)
			(cond ((eq :with-preceding-type item-symbol)
			       `(setq ,invalid-symbol (loop :for item :in (getf ,properties-symbol :type)
							 :never (eq item ,(second item)))))
			      ((eq :rest item-symbol)
			       `(setq ,invalid-symbol (< 0 (length ,tokens-symbol)))))
			(let ((item-properties (rest item)))
			  (process-item item-symbol item-properties))))))))

(defun vex-program (idiom options &optional string meta)
  "Compile a set of expressions, optionally drawing external variables into the program and setting configuration parameters for the system."
  (let* ((state (rest (assoc :state options)))
	 (meta (if meta meta (if (assoc :space options)
				 (let ((meta-symbol (second (assoc :space options))))
				   (if (hash-table-p meta-symbol)
				       meta-symbol (if (boundp meta-symbol)
						       (symbol-value meta-symbol)
						       (setf (symbol-value meta-symbol)
							     (make-hash-table :test #'eq)))))
				 (make-hash-table :test #'eq))))
	 (state-persistent (rest (assoc :state-persistent options)))
	 (state-to-use) (system-to-use) (preexisting-vars))
    (labels ((assign-from (source dest)
	       (if source (progn (setf (getf dest (first source))
				       (second source))
				 (assign-from (cddr source) dest))
		   dest))
	     (process-lines (lines &optional output)
	       (if (= 0 (length lines))
		   output (destructuring-bind (out remaining)
			      (parse lines (=vex-string idiom meta))
			    (process-lines remaining (append output (list (composer idiom meta out))))))))

      (if (not (gethash :variables meta))
	  (setf (gethash :variables meta) (make-hash-table :test #'eq))
	  (setq preexisting-vars (loop :for vk :being :the :hash-values :of (gethash :variables meta)
				    :collect vk)))

      (if (not (gethash :values meta))
	  (setf (gethash :values meta) (make-hash-table :test #'eq)))

      (if (not (gethash :functions meta))
	  (setf (gethash :functions meta) (make-hash-table :test #'eq)))

      (if (not (gethash :system meta))
	  (setf (gethash :system meta) (idiom-system idiom)))

      ;; if the (:restore-defaults) setting is passed, the workspace settings will be restored
      ;; to the defaults from the spec
      (if (assoc :restore-defaults options)
	  (setf (getf (gethash :system meta) :state)
		(getf (gethash :system meta) :base-state)))
      
      (setq state (funcall (of-utilities idiom :preprocess-state-input)
			   state)
	    state-persistent (funcall (of-utilities idiom :preprocess-state-input)
				      state-persistent))

      (if state-persistent (setf (getf (gethash :system meta) :state)
				 (assign-from state-persistent (getf (gethash :system meta) :state))))

      (setf state-to-use (assign-from (getf (gethash :system meta) :base-state) state-to-use)
	    state-to-use (assign-from (getf (gethash :system meta) :state) state-to-use)
	    state-to-use (assign-from state-persistent state-to-use)
	    state-to-use (assign-from state state-to-use)
	    system-to-use (assign-from (gethash :system meta) system-to-use)
	    system-to-use (assign-from state system-to-use))

      (if string
	  (let* ((input-vars (getf state-to-use :in))
		 (output-vars (getf state-to-use :out))
		 (compiled-expressions (process-lines (funcall (of-utilities idiom :prep-code-string)
							       string)))
		 (var-symbols (loop :for key :being :the :hash-keys :of (gethash :variables meta)
				 :when (not (member (string (gethash key (gethash :variables meta)))
						    (mapcar #'first input-vars)))
				 :collect (list key (gethash key (gethash :variables meta)))))
		 (system-vars (funcall (of-utilities idiom :system-lexical-environment-interface)
				       state-to-use))
		 (vars-declared (loop :for key-symbol :in var-symbols
				   :when (not (member (string (gethash (first key-symbol)
								       (gethash :variables meta)))
						      (mapcar #'first input-vars)))
				   :collect (let* ((sym (second key-symbol))
						   (fun-ref (gethash sym (gethash :functions meta)))
						   (val-ref (gethash sym (gethash :values meta))))
					      (list sym (if (member sym preexisting-vars)
							    (if val-ref val-ref (if fun-ref fun-ref))
							    :undefined))))))
	    (if input-vars
		(loop :for var-entry :in input-vars
		   ;; TODO: move these APL-specific checks into spec
		   :do (if (gethash (intern (lisp->camel-case (first var-entry)) "KEYWORD")
				    (gethash :variables meta))
			   (rplacd (assoc (gethash (intern (lisp->camel-case (first var-entry)) "KEYWORD")
						   (gethash :variables meta))
					  vars-declared)
				   (list (second var-entry)))
			   (setq vars-declared (append vars-declared
						       (list (list (setf (gethash (intern (lisp->camel-case
											   (first var-entry))
											  "KEYWORD")
										  (gethash :variables meta))
									 (gensym))
								   (second var-entry))))))))
	    (let ((exps (append (funcall (if output-vars #'values
					     (funcall (of-utilities idiom :postprocess-compiled)
						      system-to-use))
					 compiled-expressions)
				;; if multiple values are to be output, add the (values) form at bottom
				(if output-vars
				    (list (cons 'values
						(mapcar (lambda (return-var)
							  (funcall (of-utilities idiom :postprocess-value)
								   (gethash (intern (lisp->camel-case return-var)
										    "KEYWORD")
									    (gethash :variables meta))
								   system-to-use))
							output-vars)))))))
	      (funcall (lambda (code) (if (not (assoc :compile-only options))
					  code `(quote ,code)))
		       (if (or system-vars vars-declared)
			   (funcall (of-utilities idiom :process-compiled-as-per-workspace)
				    (second (assoc :space options))
				    `(let* (,@system-vars ,@vars-declared)
				       (declare (ignorable ,@(mapcar #'first system-vars)
							   ,@(mapcar #'second var-symbols)))
				       ,@exps))
			   (if (< 1 (length exps))
			       `(progn ,@exps)
			       (first exps))))))))))
