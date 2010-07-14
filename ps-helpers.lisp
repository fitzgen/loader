(require 'parenscript)
(in-package :ps)

;; Not a macro, but totally helpful when developing.
(defun compile-ps-file-to (infile outfile)
  (with-open-file (f outfile :direction :output :if-exists nil)
    (if (null f)
      (progn (delete-file outfile)
             (compile-ps-file-to infile outfile))
      (progn (format f "~A" (ps-compile-file infile))
             t))))

;; Helper for multiple macros; makes JS functions implicitly return the result
;; of their last expression, just like CL.
(defun insert-return (forms)
  (cond ((null forms) nil)
        ((null (cdr forms)) `((return ,(car forms))))
        (t (cons (car forms)
                 (insert-return (cdr forms))))))

;; Named function creation (with implicit return).
(defmacro+ps defn ((name &rest args) &body body)
  `(defun ,name ,args
     ,@(insert-return body)))

;; Anonymous function with an implicit return and the anaphoric binding `recur`
;; to `arguments.callee`.
(defmacro+ps func ((&rest args) &body body)
  `(lambda ,args
     (var recur (@ arguments callee))
     ,@(insert-return body)))

;; The built in `with-slots` macro uses symbol-macrolet which doesn't work for
;; symbols in the function calling position (probably b/c CL won't play nice
;; since its a Lisp-2). Because of that, I created my own that does expand
;; symbols in the function position.
(defmacro+ps w/slots ((&rest slots) object &body body)
  (let ((obj (ps-gensym)))
    (labels ((slot? (symb) (some #'(lambda (s)
                                     (eq s symb))
                                 slots))
             (replace-slots-in-tree (tree) (cond ((null tree) '())
                                                 ((symbolp tree) (if (slot? tree)
                                                                     `(@ ,obj ',tree)
                                                                   tree))
                                                 ((consp tree) (cons (replace-slots-in-tree (car tree))
                                                                     (replace-slots-in-tree (cdr tree))))
                                                 (t tree))))
      `(progn (var ,obj ,object)
              ,@(replace-slots-in-tree body)))))

;; Create a new scope (self-invoking function) and optionally import globals to
;; the local namespace. The symbol `exports` is anaphorically bound to `window`
;; if we are in a browser environment, and `exports` if we are in a Common JS
;; environment.
(defmacro+ps w/scope ((&rest imports) &body body)
  `((func ,(mapcar #'car imports)
      (var exports (if (=== (typeof window) "undefined")
                       exports
                     window))
      ,@body)
    ,@(mapcar #'cadr imports)))

;; I prefer Scheme's `set!` over CL's `setf` from a purely aesthetic point of
;; view.
(defmacro+ps set! (&rest args)
  `(setf ,@args))

;; Create a let-binding out of `bindings`, and then if all the new bindings are
;; truthy, evaluate `then-form`, otherwise evaluate `else-form`.
(defmacro+ps if-let (bindings &body (then-form &optional (else-form nil)))
  (let ((vars (mapcar #'car bindings))
        (forms (mapcar #'cadr bindings)))
    `((lambda ,vars
        (return (if (and ,@vars)
                    ,then-form
                  ,else-form)))
        ,@forms)))

;; NOTE: By convention, all of my asynchronous macros end with the hash
;; character (#).

;; Syntactical sugar around setTimeout.
;;
;;     (after# (200)
;;       (@@ console (log "hello")))
;;
;; expands to
;;
;;     (set-timeout (func ()
;;                    (@@ console (log "hello")))
;;                  200)
;;
;; Also, `repeat-timeout` is anaphorically bound as a symbol macro to
;; `(set-timeout recur ms)` where ms is the original milliseconds timeout will
;; delay.
(defmacro+ps after# ((ms) &body body)
  `(set-timeout (func ()
                  (symbol-macrolet ((repeat-timeout (set-timeout recur ,ms)))
                    ,@body))
                ,ms))

;; Begin a set-timeout loop that will run `body` once, sometime in the
;; future when `test` becomes true.
(defmacro+ps once-when# (test &body body)
  `(after# (25)
     (if ,test
         (progn ,@body)
       repeat-timeout)))

;; The same as `once-when#`, except that the body will keep being run as long as
;; `test` is true, not just once.
(defmacro+ps always-when# (test &body body)
  `(once-when# ,test
     (progn ,@body repeat-timeout)))

;; Quick, helpful shortcut to `chain`, which does chaining of methods and
;; properties.
;;
;;     (@@ ($ "a") (css "padding" "5px") (text "Hello!"))
;;
;; becomes
;;
;;     $('a').css('padding', '5px').text('Hello!');
(defmacro+ps @@ (&rest args)
  `(chain ,@args))