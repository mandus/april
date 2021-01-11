;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8; Package:April -*-
;;;; grammar.lisp

(in-package #:april)

"This file contains the specification of April's basic grammar elements, including the basic language components - array, function and operator - and the patterns comprising those elements that make up the language's strucures."

(defun process-value (tokens properties process idiom space)
  (multiple-value-bind (axes this-item remaining)
      (extract-axes process tokens)
    ;; (print (list :tt tokens properties process idiom space preceding-props))
    ;; TODO: add a passthrough value mode for symbols that are being assigned!
    ;; this is the only way to get them assignable after the first time
    (cond ((and (listp this-item)
		(not (or (eq :fn (first this-item))
			 (eq :op (first this-item)))))
	   ;; if the item is a closure, evaluate it and return the result
	   (multiple-value-bind (output out-properties)
	       (funcall process this-item)
	     (if (eq :array (first (getf out-properties :type)))
		 (progn (setf (getf out-properties :type)
			      (cons (first (getf out-properties :type))
				    (cons :enclosed (rest (getf out-properties :type)))))
			(values output out-properties remaining))
		 (values nil nil tokens))))
	  ;; process the empty vector expressed by the [⍬ zilde] character
	  ((eq :empty-array this-item)
	   (values (make-array 0)
		   (list :type '(:array :empty))
		   (rest tokens)))
	  ;; process numerical values
	  ((and (numberp this-item)
		(or (not (getf properties :type))
		    (eq :number (first (getf properties :type)))))
	   (values this-item (list :type '(:array :number))
		   (rest tokens)))
	  ;; process string values
	  ((and (stringp this-item)
		(or (not (getf properties :type))
		    (eq :string (first (getf properties :type)))))
	   (values this-item (list :type '(:array :string))
		   remaining))
	  ;; process scalar character values
	  ((and (characterp this-item)
		(or (not (getf properties :type))
		    (eq :character (first (getf properties :type)))))
	   (values this-item (list :type '(:array :character))
		   remaining))
	  ;; process symbol-referenced values
	  ((and (symbolp this-item)
		(or (member this-item '(⍵ ⍺) :test #'eql)
		    (getf properties :symbol-overriding)
		    (not (is-workspace-function this-item)))
		(or (not (is-workspace-operator this-item))
		    (getf properties :symbol-overriding))
		(not (member (intern (string-upcase this-item))
			     (rest (assoc :function (idiom-symbols idiom)))))
		(not (member this-item '(⍺⍺ ⍵⍵) :test #'eql))
		(or (not (getf properties :type))
		    (eq :symbol (first (getf properties :type)))))
	   (values (if (not (member (intern (string-upcase this-item))
				    (rest (assoc :function (idiom-symbols idiom)))))
		       this-item (intern (string-upcase this-item)))
		   (list :axes axes :type '(:symbol))
		   remaining))
	  ;; if the pattern is set to cancel upon encountering a pivotal operator,
	  ;; it will do so and throw the appropriate cancellation flag
	  ((and (getf properties :cancel-if)
		(eq :pivotal-composition (getf properties :cancel-if))
		(listp this-item)
		(eq :op (first this-item))
		(eq :pivotal (second this-item)))
	   (values nil '(:cancel-flag :pivotal-composition)
		   tokens))
	  (t (values nil nil tokens)))))

(defun process-function (tokens properties process idiom space)
  ;; (print (list :iio tokens properties))
  ;; (destructuring-bind (this-item &rest remaining)
  (let ((this-item (first tokens))
	(remaining (rest tokens)))
    (if (listp this-item)
	;; process a function specification starting with :fn
	(if (or (eq :fn (first this-item))
		;; if marked as an operator, check whether the character is one entered as both
		;; a function and an operator; such functions must be dyadic
		(and (eq :op (first this-item))
		     (or (of-lexicon idiom :dyadic-functions (third this-item))
			 (of-lexicon idiom :symbolic-functions (third this-item)))
		     ;; check that the following item is a value and not a function, otherwise it
		     ;; must be an operator - TODO: remove this clause, checking the following item
		     ;; should be part of a grammar pattern, not an element processor
		     (or (not remaining)
			 (and (not (listp (first remaining)))
			      (or (not (symbolp (first remaining)))
				  (is-workspace-value (first remaining))))
		 ;; this clause is needed in case of an index-referenced value being passed
			 ;; as the function's left value, i.e. v←⍳5 ⋄ v[4]/7 8
			 (and (listp (first remaining))
			      (eq :axes (caar remaining))
			      (symbolp (second remaining))))))
	    (let ((fn (first (last this-item)))
		  (obligate-dyadic (and (eq :op (first this-item))
					(of-lexicon idiom :dyadic-functions (third this-item))))
		  (overloaded-operator (and (eq :op (first this-item))
					    (or (of-lexicon idiom :dyadic-functions (third this-item))
						(of-lexicon idiom :symbolic-functions (third this-item))))))
	      (cond ((and (characterp fn)
			  (or (not (getf properties :glyph))
			      (and (char= fn (aref (string (getf properties :glyph)) 0)))))
		     (values fn (list :type (append '(:function :glyph)
						    (if overloaded-operator '(:overloaded-operator))))
			     remaining))
		    ((and (listp fn)
			  (not (getf properties :glyph)))
		     (let* ((polyadic-args (if (and (listp (first (last (first fn))))
						    (eq :axes (caar (last (first fn)))))
					       (mapcar #'caar (cdar (last (first fn))))))
			    (fn (if (not polyadic-args)
				    fn (cons (butlast (first fn) 1)
					     (rest fn))))
			    (symbols-used (glean-symbols-from-tokens fn space))
			    (is-inline-operator
			     (intersection '(⍺⍺ ⍵⍵) (rest (assoc :args symbols-used)))))
		       (if is-inline-operator (values nil nil tokens)
			   (values (output-function (if (= 1 (length fn))
							(list (funcall process fn))
							(mapcar process fn))
						    polyadic-args symbols-used)
				   (list :type '(:function :closure)
					 :obligate-dyadic obligate-dyadic)
				   remaining))))
		    (t (values nil nil tokens))))
	    ;; process sub-list in case it is a functional expression like (+∘*),
	    ;; but don't do this if looking for a specific functional glyph
	    (if (not (getf properties :glyph))
	    	(multiple-value-bind (output out-properties)
	    	    (funcall process this-item)
	    	  (if (eq :function (first (getf out-properties :type)))
	    	      (progn (setf (getf out-properties :type)
	    			   (cons (first (getf out-properties :type))
	    				 (cons :enclosed (rest (getf out-properties :type)))))
	    		     (values output properties remaining))
	    	      (values nil nil tokens)))
	    	(values nil nil tokens))
	    )
	(if (and (symbolp this-item)
		 (not (getf properties :glyph)))
	    (cond ((or (is-workspace-function this-item)
		       (get-workspace-alias space this-item))
		   ;; process workspace-aliased lexical functions, as when f←+ has been set
		   (values (if (not (get-workspace-alias space this-item))
			       this-item (get-workspace-alias space this-item))
			   (list :type '(:function :referenced))
			   remaining))
		  ((member this-item '(⍵⍵ ⍺⍺))
		   (values this-item (list :type '(:function :operator-reference))
			   remaining))
		  ((member (intern (string-upcase this-item))
			   (rest (assoc :function (idiom-symbols idiom))))
		   (values (list 'function (getf (rest (assoc :function (idiom-symbols idiom)))
						 (intern (string-upcase this-item))))
			   (list :type '(:function :referenced))
			   remaining))
		  (t (values nil nil tokens)))))))

(defun process-operator (tokens properties process idiom space)
  (let ((this-item (first tokens)) (remaining (rest tokens)))
    (if (listp this-item)
	(if (eq :op (first this-item))
	    ;; process an operator token, allowing specification of the valence,
	    ;; either :lateral or :pivotal
	    (destructuring-bind (op-type op-symbol)
		(rest this-item)
	      (let ((valid-by-valence (or (not (getf properties :valence))
					  (eq op-type (getf properties :valence)))))
		(cond ((and valid-by-valence (getf properties :glyph))
		       (if (char= op-symbol (aref (string (getf properties :glyph)) 0))
			   (values op-symbol (list :type (list :operator op-type))
				   remaining)
			   (values nil nil tokens)))
		      (valid-by-valence (values op-symbol (list :type (list :operator op-type))
						remaining))
		      (t (values nil nil tokens)))))
	    (if (and (eql :fn (first this-item))
		     (listp (first (last this-item))))
		(let* ((fn (first (last this-item)))
		       (symbols-used (glean-symbols-from-tokens fn space))
		       (is-inline-operator (intersection '(⍺⍺ ⍵⍵) (rest (assoc :args symbols-used))))
		       (is-pivotal-operator (member '⍵⍵ (rest (assoc :args symbols-used)))))
		  (if is-inline-operator
		      (values (output-function (if (= 1 (length fn))
						   (list (funcall process fn))
						   (mapcar process fn))
					       nil symbols-used)
			      (list :type (list :operator :closure
						(if is-pivotal-operator :pivotal :lateral)))
			      remaining)
		      (values nil nil tokens)))
		(values nil nil tokens)))
	(if (symbolp this-item)
	    ;; if the operator is represented by a symbol, it is a user-defined operator
	    ;; and the appropriate variable name should be verified in the workspace
	    (let* ((symbol-string (string this-item))
		   (type-to-find (getf properties :valence))
		   (lop-string (if (eq :lateral (getf properties :valence))
				   (concatenate 'string "𝕆𝕃∇" symbol-string)))
		   (pop-string (if (eq :pivotal (getf properties :valence))
				   (concatenate 'string "𝕆ℙ∇" symbol-string)))
		   (bound-op (if (and lop-string (fboundp (intern lop-string space)))
				 (intern lop-string)
				 (if (and pop-string (fboundp (intern pop-string space)))
				     (intern pop-string)))))
	      (if bound-op
		  (values bound-op (list :type (list :operator (or (getf properties :valence)
								   (if (fboundp (intern pop-string space))
								       :pivotal :lateral))))
			  remaining)
		  (values nil nil tokens)))))))

(defun composer-pattern-value (tokens space process &optional precedent properties preceding-properties)
  (declare (ignorable precedent properties preceding-properties))
  (let ((axes) (value-elements) (value-props) (stopped)
	(items tokens) (item (first tokens)) (rest-items (rest tokens)))
    (labels ((axes-enclose (item axes)
	       (if (not axes) item (enclose-axes item axes))))
      (progn (if (and (listp item) (eql :axes (first item)))
    		 (setq axes (list (loop :for axis :in (rest item) :collect (funcall process axis)))
    		       items rest-items item (first items) rest-items (rest items)))
	     (loop :while (not stopped)
		:do (or (if (and (listp item) (eq :axes (first item)))
			    ;; if axes are encountered, process the axes and the preceding
			    ;; value as a new value
			    (multiple-value-bind (output properties remaining)
				(funcall process items)
			      (if (eq :array (first (getf properties :type)))
				  (setq items remaining item (first items) rest-items (rest items)
					value-elements (cons output value-elements)
					value-props (cons properties value-props)
					stopped t))))
			(if (and (listp item) (not (member (first item) '(:op :fn :axes))))
			    ;; if a closure is encountered, recurse to process it
			    (multiple-value-bind (output properties remaining) (funcall process item)
			      (if (eq :array (first (getf properties :type)))
				  (setq items rest-items item (first items) rest-items (rest items)
					value-elements (cons output value-elements)
					value-props (cons properties value-props)))))
			(multiple-value-bind (value-out value-properties)
			    (process-value (list item) properties process *april-idiom* space)
			  (if value-out (setq items rest-items item (first items) rest-items (rest items)
					      value-elements (cons value-out value-elements)
					      value-props (cons value-properties value-props))))
			(setq stopped t))))
      (if value-elements
	  (values (axes-enclose (output-value space (if (< 1 (length value-elements))
							value-elements (first value-elements))
					      value-props)
				axes)
		  '(:type (:array :explicit))
		  items)
	  (values nil nil tokens)))))

(defmacro assign-axes (symbol process item items rest-items)
  (let ((axis (gensym)))
    `(if (and (listp ,item) (eql :axes (first ,item)))
	 (setq ,symbol (list (loop :for ,axis :in (rest ,item) :collect (funcall ,process ,axis)))
    	       ,items ,rest-items ,item (first ,items) ,rest-items (rest ,items)))))

(defmacro assign-element (symbol-form symbol-props function process properties space item items rest-items)
  (let ((form-out (gensym)) (form-properties (gensym)))
    `(multiple-value-bind (,form-out ,form-properties)
	 (,function (list ,item) ,properties ,process *april-idiom* ,space)
       (if ,form-out
	   (setq ,symbol-form ,form-out ,symbol-props ,form-properties
    		 ,items ,rest-items ,item (first ,items) ,rest-items (rest ,items))))))

(defmacro assign-subprocessed (symbol-form symbol-props process properties item items rest-items)
  (let ((form-out (gensym)) (form-properties (gensym)) (remaining (gensym)))
    `(multiple-value-bind (,form-out ,form-properties ,remaining)
	 (funcall ,process ,items ,properties)
       (setq ,symbol-form ,form-out ,symbol-props ,form-properties
    	     ,items ,remaining ,item (first ,items) ,rest-items (rest ,items)))))

(defun composer-pattern-function (tokens space process &optional precedent properties preceding-properties)
  (declare (ignorable precedent properties preceding-properties))
  ;; (print (list :aat tokens))
  (let ((axes) (function-form) (function-props)
	(items tokens) (item (first tokens)) (rest-items (rest tokens)))
    (progn (assign-axes axes process item items rest-items)
	   (assign-element function-form function-props process-function process
			   nil space item items rest-items))
    (let ((is-function (or (not (member :overloaded-operator (getf function-props :type)))
			   (let ((next (if items (multiple-value-list (funcall process items)))))
			     ;; (print (list :next next remaining))
			     (not (member :function (getf (second next) :type)))))))
      ;; (print (list :iii item is-function))
      (if (and function-form is-function)
	  (values (if (or (not axes) (of-lexicon *april-idiom* :functions function-form))
		      (if (not (and (symbolp function-form) (is-workspace-function function-form)))
			  function-form `(function (inws ,function-form)))
		      `(apl-call :nafn (function ,(insym function-form)) ,@(first axes)))
		  (list :type (if (member :operator (getf function-props :type))
				  (list :operator :inline-operator
					(if (member :pivotal (getf function-props :type))
					    :pivotal :lateral))
				  '(:function :inline-function))
			:axes axes)
		  items)
	  (values nil nil tokens)))))

(defun composer-pattern-lateral-composition
    (tokens space process &optional precedent properties preceding-properties)
  (declare (ignorable precedent properties preceding-properties))
  ;; (print (list :tok tokens))
  (labels ((verify-lateral-operator-symbol (symbol)
	     (if (symbolp symbol) (let ((symbol (intern (concatenate 'string "𝕆𝕃∇" (string symbol)))))
				  (if (fboundp (intern (string symbol) space)) symbol)))))
    (let ((operator-axes) (operator-form) (operator-props) (operand-axes) (operand-form) (operand-props)
	  (symbol-referenced) (items tokens) (item (first tokens)) (rest-items (rest tokens))
	  (alpha (gensym)) (omega (gensym)))
      (if (and (listp item) (eq :fn (first item)))
	  (multiple-value-bind (operator-definition properties)
	      (process-operator (list item) properties process *april-idiom* space)
	    (if operator-definition (values operator-definition properties rest-items)))
	  (progn(assign-axes operator-axes process item items rest-items)
		 (setq symbol-referenced (verify-lateral-operator-symbol item))
		 (assign-element operator-form operator-props process-operator
				 process nil space item items rest-items)
		 (assign-axes operand-axes process item items rest-items)
		 (assign-subprocessed operand-form operand-props process
		 		      (list :special '(:omit (:value-assignment :function-assignment
		 					      :operation :operator-assignment))
		 			    :valence :lateral)
		 		      item items rest-items)
		 (if symbol-referenced
		     (values (list 'apl-compose :op (list 'inws symbol-referenced)
	  			   (if (listp operand-form)
	  			       operand-form
				       (if (characterp operand-form)
	  		    		   `(lambda (,omega &optional ,alpha)
	  		    		      (if ,alpha (apl-call :fn ,(resolve-function
									 :dyadic operand-form)
	  		    					   ,omega ,alpha)
	  		    			  (apl-call :fn ,(resolve-function
								  :monadic operand-form)
	  		    				    ,omega)))))
	  			   ;; TODO: implement operand axes
	  			   ;; operand-axes
	  			   )
	  		     '(:type (:function :operator-composed :lateral))
	  		     items)
		     (let ((operator (and (member :operator (getf operator-props :type))
	      				  (member :lateral (getf operator-props :type))
	      				  operator-form)))
		       (if operator (values (cons 'apl-compose
	      					  (cons (intern (string-upcase operator))
	      						(funcall (funcall (resolve-operator :lateral operator)
	      								  operand-form (first operand-axes))
	      							 (first operator-axes))))
	      				    '(:type (:function :operator-composed :lateral))
	      				    items)
			   (values nil nil tokens)))))))))

(defun composer-pattern-unitary-operation
    (tokens space process &optional precedent properties preceding-properties)
  (let ((operator-axes) (operator-form) (operator-props)
	(items tokens) (item (first tokens)) (rest-items (rest tokens)))
    (assign-axes operator-axes process item items rest-items)
    (assign-element operator-form operator-props process-operator process nil space item items rest-items)
    (let ((operator (and (member :operator (getf operator-props :type))
			 (member :unitary (getf operator-props :type))
			 operator-form)))
      (if (resolve-operator :unitary operator)
	  (values (funcall (resolve-operator :unitary operator) space (first operator-axes))
		  '(:type (:array :evaluated))
		  items)
	  (values nil nil tokens)))))

(defvar *composer-opening-patterns-new*)

(setq *composer-opening-patterns-new*
      (list (list :name :value :function #'composer-pattern-value)
	    (list :name :function :function #'composer-pattern-function)
	    (list :name :lateral-composition :function #'composer-pattern-lateral-composition)
	    (list :name :unitary-operator :function #'composer-pattern-unitary-operation)))

(set-composer-patterns
 composer-following-patterns-apl-standard
 (with :idiom-symbol idiom :space-symbol space :process-symbol process
       :properties-symbol properties :precedent-symbol precedent :pre-properties-symbol pre-properties)
 (value-assignment-by-function-result
  ;; match the assignment of a function result to a value, like a+←5
  ((:with-preceding-type :array)
   (assignment-operator :element (function :glyph ←))
   (fn-element :pattern (:type (:function) :special '(:omit (:value-assignment :function-assignment))))
   (symbol :element (array :symbol-overriding t)))
  (if (is-workspace-value symbol)
      (let ((fn-content (resolve-function :dyadic fn-element))
	    (fn-sym (or-functional-character fn-element :fn))
	    (symbol-axes (getf (third properties) :axes))
	    (function-axes (getf (first properties) :axes)))
	(if (not symbol-axes)
	    `(setq (inws ,symbol) (apl-call ,fn-sym ,fn-content (inws ,symbol) ,precedent
					    ,@(if function-axes `((list ,@(first function-axes))))))
	    (enclose-axes `(inws, symbol)
			  symbol-axes :set-by `(lambda (item item2) (apl-call ,fn-sym ,fn-content item item2))
			  :set precedent))))
  '(:type (:array :assigned :by-result-assignment-operator)))
 (selective-assignment
  ;; match a selective value assignment like (3↑x)←5
  ((:with-preceding-type :array)
   (assignment-function :element (function :glyph ←))
   (selection-form :pattern (:type (:array) :special '(:omit (:value-assignment)))))
  (if (and (listp selection-form) (eql 'apl-call (first selection-form)))
      (multiple-value-bind (sel-form sel-item placeholder set-form)
	  (generate-selection-form selection-form space)
	;; (print (list :sel sel-form selection-form))
	(if sel-form
	    ;; generate an array whose each cell is its row-major index, perform the subtractive function on
	    ;; it and then use assign-selected to assign new values to the cells at the remaining indices
	    ;; of the original array
	    (if sel-item
		(let ((item (gensym)) (indices (gensym)))
		  ;; `(let* ((,item ,sel-item)
		  ;; 	  (,placeholder (generate-index-array ,item))
		  ;; 	  (,indices (enclose ,sel-form))
		  ;; 	  ,@(if set-form `((,placeholder (make-array nil :initial-element
		  ;; 						     (assign-selected (disclose2 ,item)
		  ;; 								      ,indices ,precedent))))))
		  ;;    ,(or set-form `(setq ,sel-item (assign-selected ,sel-item ,indices ,precedent))))
		  `(apl-assign
		    ,sel-item
		    (let* ((,item ,sel-item)
			   (,placeholder (generate-index-array ,item))
			   (,indices (enclose ,sel-form))
			   ,@(if set-form `((,placeholder (make-array nil :initial-element
								      (assign-selected (disclose2 ,item)
										       ,indices ,precedent))))))
		      ,(or set-form `(assign-selected ,sel-item ,indices ,precedent))))
		  )
		`(let ((,placeholder ,precedent))
		   (setf ,set-form ,sel-form))))))
  '(:type (:array :assigned)))
 (value-assignment
  ;; match a value assignment like a←1 2 3, part of an array expression
  ((:with-preceding-type :array)
   (assignment-function :element (function :glyph ←))
   (symbol :element (array :symbol-overriding t)))
  (let ((axes (getf (second properties) :axes)))
    ;; ensure symbol(s) are not bound to function values in the workspace, and
    ;; define them as dynamic variables if they're unbound there
    (loop :for symbol :in (if (not (listp symbol)) (list symbol)
			      ;; remove symbols from (inws) unless they're bare and thus idiom-native
			      (mapcar (lambda (s) (if (not (listp s)) s (second s))) symbol))
       :do (if (is-workspace-function symbol)
	       (fmakunbound (intern (string symbol) space)))
	 (if (not (boundp (intern (string symbol) space)))
	     (progn (proclaim (list 'special (intern (string symbol) space)))
		    (set (intern (string symbol) space) nil))))
    (cond ((eql 'to-output symbol)
	   ;; a special case to handle ⎕← quad output
	   `(apl-output ,precedent :print-precision print-precision
			:print-to output-stream :print-assignment t))
	  ((eql 'output-stream symbol)
	   ;; a special case to handle ⎕ost← setting the output stream; the provided string
	   ;; is interned in the current working package
	   (if (stringp precedent)
	       ;; setq is used instead of apl-assign because output-stream is a lexical variable
	       `(setq output-stream ,(intern precedent (package-name *package*)))
	       (if (listp precedent)
		   (destructuring-bind (vector-symbol package-string symbol-string) precedent
		     (if (and (eql 'avector vector-symbol)
			      (stringp package-string)
			      (stringp symbol-string))
			 ;; if the argument is a vector of two strings like ('APRIL' 'OUT-STR'),
			 ;; intern the symbol like (intern "OUT-STR" "APRIL")
			 `(setq output-stream ,(intern symbol-string package-string))
			 (error "Invalid assignment to ⎕OST.")))
		   (error "Invalid assignment to ⎕OST."))))
	  (t (if (symbolp symbol)
		 (set-workspace-alias space symbol nil))
	     (let ((symbol (if (or (listp symbol) (member symbol *idiom-native-symbols*))
			       symbol (list 'inws symbol))))
	       (if axes (enclose-axes symbol axes :set precedent)
		   ;; enclose the symbol in (inws) so the (with-april-workspace) macro will corretly
		   ;; intern it, unless it's one of the system variables
		   `(apl-assign ,symbol ,precedent))))))
  '(:type (:array :assigned)))
 (function-assignment
  ;; match a function assignment like f←{⍵×2}, part of a functional expression
  ((:with-preceding-type :function)
   (assignment-function :element (function :glyph ←))
   (symbol :element (array :symbol-overriding t)))
  (let* ((inverted (if (listp precedent) (invert-function precedent)))
	 (inverted-symbol (if inverted (intern (concatenate 'string "𝕚∇" (string symbol))))))
    (if (is-workspace-value symbol)
	(makunbound (intern (string symbol) space)))
    (setf (symbol-function (intern (string symbol) space)) #'dummy-nargument-function)
    (if inverted (progn (if (is-workspace-value inverted-symbol)
			    (makunbound (intern (string inverted-symbol) space)))
			(setf (symbol-function (intern (string inverted-symbol) space))
			      #'dummy-nargument-function)))
    (if (characterp precedent)
	(if (or (resolve-function :monadic precedent)
		(resolve-function :dyadic precedent))
	    (progn (set-workspace-alias space symbol precedent)
		   (format nil "~a aliases ~a" symbol precedent)))
	(progn (set-workspace-alias space symbol nil)
	       `(setf (symbol-function (quote (inws ,symbol))) ,precedent
		      ,@(if inverted `((symbol-function (quote (inws ,inverted-symbol)))
				       ,inverted))))))
  '(:type (:function :assigned)))
 (operator-assignment
  ;; match an operator assignment like f←{⍵×2}, part of a functional expression
  ((:with-preceding-type :operator)
   (assignment-function :element (function :glyph ←))
   (symbol :element (array :symbol-overriding t)))
  (let* ((operator-type (getf (first pre-properties) :type))
	 (operator-symbol (intern (concatenate 'string (if (member :pivotal operator-type) "𝕆ℙ∇" "𝕆𝕃∇")
					       (string symbol)))))
    (if (is-workspace-value symbol)
	(makunbound (intern (string symbol) space)))
    (setf (symbol-function (intern (string operator-symbol) space)) #'dummy-nargument-function)
    (if (characterp precedent)
	(if (or (resolve-operator :lateral precedent)
		(resolve-operator :pivotal precedent))
	    (progn (set-workspace-alias space symbol precedent)
		   (format nil "~a aliases ~a" symbol precedent)))
	(progn (set-workspace-alias space symbol nil)
	       `(setf (symbol-function (quote (inws ,operator-symbol))) ,precedent))))
  '(:type (:operator :assigned)))
 (branch
  ;; match a branch-to statement like →1 or a branch point statement like 1→⎕
  ((:with-preceding-type :array)
   (branch-glyph :element (function :glyph →))
   (branch-from :element (array :cancel-if :pivotal-composition) :optional t :times :any)
   (determine-branch-by :element function :optional t :times 1))
  (progn
    (if (listp precedent)
	(if (loop :for item :in precedent :always (and (listp item) (eql 'inws (first item))))
	    (setq precedent (mapcar #'second precedent))
	    (if (eql 'inws (first precedent))
		(setq precedent (second precedent)))))
    (if (and branch-from (eql 'to-output precedent)) ;;(string= "TO-OUTPUT" (string precedent)))
	;; if this is a branch point statement like X→⎕, do the following:
	(if (integerp branch-from)
	    ;; if the branch is designated by an integer like 5→⎕
	    (let ((branch-symbol (gensym "AB"))) ;; AB for APL Branch
	      (setf *branches* (cons (list branch-from branch-symbol) *branches*))
	      branch-symbol)
	    ;; if the branch is designated by a symbol like doSomething→⎕
	    (if (symbolp branch-from)
		(progn (setf *branches* (cons branch-from *branches*))
		       branch-from)
		(error "Invalid left argument to →; must be a single integer value or a symbol.")))
	;; otherwise, this is a branch-to statement like →5 or →doSomething
	(if (or (integerp precedent)
		(symbolp precedent))
	    ;; if the target is an explicit symbol as in →mySymbol, or explicit index
	    ;; as in →3, just pass the symbol through
	    (list 'go precedent)
	    (if (loop :for item :in (rest precedent) :always (symbolp item)) ;;(symbolp (second item)))
		;; if the target is one of an array of possible destination symbols...
		(if (integerp branch-from)
		    ;; if there is an explicit index to the left of the arrow, grab the corresponding
		    ;; symbol unless the index is outside the array's scope, in which case a (list) is returned
		    ;; so nothing is done
		    (if (< 0 branch-from (length (rest precedent)))
			(list 'go (second (nth (1- branch-from) (rest precedent))))
			(list 'list))
		    ;; otherwise, there must be an expression to the left of the arrow, as with
		    ;; (3-2)→tagOne tagTwo, so pass it through for the postprocessor
		    (list 'go precedent branch-from))
		(list 'go precedent)))))
  '(:type (:branch)))
 (train-composition
  ;; match a train function composition like (-,÷)
  ((:with-preceding-type :function)
   (center :pattern (:type (:function) :special '(:omit (:value-assignment :function-assignment))))
   (left :pattern (:special '(:omit (:value-assignment :function-assignment)))))
  (destructuring-bind (right omega alpha center)
      (list precedent (gensym) (gensym)
 	    (if (listp center)
 		center (resolve-function :dyadic (if (not (symbolp center))
 						     center (intern (string center) space)))))
    ;; train composition is only valid when there is only one function in the precedent
    ;; or when continuing a train composition as for (×,-,÷)5
    (if (and center (or (= 1 (length pre-properties))
 			(and (member :train-composition (getf (first pre-properties) :type))
 			     (not (member :closed (getf (first pre-properties) :type))))))
 	;; functions are resolved here, failure to resolve indicates a value in the train
 	(let ((right-fn-monadic (if (and (listp right) (eql 'function (first right)))
 				    right (resolve-function :monadic right)))
 	      (right-fn-dyadic (if (and (listp right) (eql 'function (first right)))
 				   right (resolve-function :dyadic right)))
 	      (left-fn-monadic (if (and (listp left) (eql 'function (first left)))
 				   left (resolve-function :monadic left)))
 	      (left-fn-dyadic (if (and (listp left) (eql 'function (first left)))
 				  left (resolve-function :dyadic left))))
 	  `(lambda (,omega &optional ,alpha)
 	     (if ,alpha (apl-call ,(or-functional-character center :fn) ,center
 				  (apl-call ,(or-functional-character right :fn)
 					    ,right-fn-dyadic ,omega ,alpha)
 				  ,(if (not left-fn-dyadic)
 				       left `(apl-call ,(or-functional-character left :fn)
 						       ,left-fn-dyadic ,omega ,alpha)))
 		 (apl-call ,(or-functional-character center :fn) ,center
 			   (apl-call ,(or-functional-character right :fn) ,right-fn-monadic ,omega)
 			   ,(if (not left-fn-monadic)
 				left `(apl-call ,(or-functional-character left :fn)
 						,left-fn-monadic ,omega))))))))
  (list :type (list :function :train-composition (if (resolve-function :monadic left) :open :closed))))
 (pivotal-or-lateral-inline-composition
  ;; match a pivotal function composition like ×.+, part of a functional expression
  ;; it may come after either a function or an array, since some operators take array operands
  ((operator :element (operator :valence :pivotal))
   (left-operand :pattern (:special '(:omit (:value-assignment :function-assignment :operation)))))
  ;; the special :omit property makes it so that the pattern matching the operand may not be processed as
  ;; a value assignment, function assignment or operation, which allows for expressions like
  ;; fn←5∘- where an operator-composed function is assigned
  (let ((right-operand (insym precedent))
	(right-operand-axes (first (getf (first pre-properties) :axes)))
	(left-operand (insym left-operand))
	(left-operand-axes (first (getf (second properties) :axes)))
	(omega (gensym)) (alpha (gensym)))
    ;; get left axes from the left operand and right axes from the precedent's properties so the
    ;; functions can be properly curried if they have axes specified
    ;; (append (list 'apl-compose (intern (string-upcase operator)))
    ;; 	    (funcall (funcall (resolve-operator :pivotal operator)
    ;; 			      left-operand left-operand-axes right-operand right-operand-axes)
    ;; 		     right-operand left-operand)))
    ;; (cons 'apl-compose
	  ;; call the operator constructor on the output of the operand constructor which integrates axes
    (if (symbolp operator) `(apl-compose :op ,(list 'inws operator)
					 ,(if (listp left-operand)
					      left-operand (if (characterp left-operand)
							       `(lambda (,omega &optional ,alpha)
								  (if ,alpha
								      (apl-call :fn ,(resolve-function
										      :dyadic left-operand)
										,omega ,alpha)
								      (apl-call :fn ,(resolve-function
										      :monadic left-operand)
										,omega)))))
					 ,(if (listp right-operand)
					      left-operand (if (characterp right-operand)
							       `(lambda (,omega &optional ,alpha)
								  (if ,alpha
								      (apl-call :fn ,(resolve-function
										      :dyadic right-operand)
										,omega ,alpha)
								      (apl-call :fn ,(resolve-function
										      :monadic right-operand)
										,omega)))))
				       ;; TODO: implement operand axes
				       ;; operand-axes
				       )
	      (if (listp operator)
		  `(apl-call :fn (apl-compose :op ,operator
					      ,(if (listp left-operand)
						   left-operand (if (characterp left-operand)
								    `(lambda (,omega &optional ,alpha)
								       (if ,alpha
									   (apl-call :fn ,(resolve-function
											  :dyadic left-operand)
										     ,omega ,alpha)
									   (apl-call :fn ,(resolve-function
											   :monadic left-operand)
										     ,omega))))))
			     ,precedent)
		  (cons 'apl-compose
			(cons (intern (string-upcase operator))
			      (funcall (funcall (resolve-operator :pivotal operator)
						left-operand left-operand-axes right-operand right-operand-axes)
				       right-operand left-operand))))))
  '(:type (:function :operator-composed :pivotal)))
 (operation
  ;; match an operation on arrays like 1+1 2 3, ⍳9 or +/⍳5, these operations are the basis of APL
  ((:with-preceding-type :array)
   (fn-element :pattern (:type (:function) :special '(:omit (:value-assignment :function-assignment))))
   ;; the value match is canceled when encountering a pivotal operator composition on the left side
   ;; of the function element so that expressions like ÷.5 ⊢10 20 30 work properly
   (value :element (array :cancel-if :pivotal-composition) :optional t :times :any))
  (let ((fn-content (if (or (functionp fn-element)
			    (member fn-element '(⍺⍺ ⍵⍵))
			    (and (listp fn-element)
				 (eql 'function (first fn-element))))
			fn-element (resolve-function (if value :dyadic :monadic) (insym fn-element))))
	(fn-sym (or-functional-character fn-element :fn))
	(axes (getf (first properties) :axes)))
    `(apl-call ,fn-sym ,fn-content ,precedent
	       ,@(if value (list (output-value space value (rest properties))))
	       ,@(if axes `((list ,@(first axes))))))
  '(:type (:array :evaluated))))

