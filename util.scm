; this is currently just a scratch
; pad for trying to find a syntax
; that makes describing records
; less boring...
; README:
; https://wiki.call-cc.org/man/4/Macros#explicit-renaming-macros

(define-syntax t1
  (er-macro-transformer
    (lambda (e r c?)
      `(quote ,(cdr  e)))))

; (make-s2d-record 'game-object '#( (mutable pos) (mutable body)) #:property apples 'apples)
(define-syntax make-s2d-record
  (er-macro-transformer
    (lambda (e r c?)
      (let* ((params (cdr e))
             (rtd-name (car params))
             (f (first e))
             (s (second e))
             (t (third e))
             ; rtd-fields is a quoted vector
             (rtd-fields (cadr params))
             (fields-list (vector->list (second rtd-fields)))
             (additional-properties (if (> (length params) 2) (drop params 2) '())))
        `(list "aps:" ',additional-properties )))))

;(define-syntax make-s2d-record
  ;(er-macro-transformer
    ;(lambda (e r c?)
      ;(let* ((params (cdr e))
             ;(rtd-name (car params))
             ;; rtd-fields is a quoted vector
             ;(rtd-fields (cadr params))
             ;(additional-properties (if (> (length params) 2) (caddr params) '())))
        ;`(vector->list ,rtd-fields)))))

(define rec-exp
  '(game-object
     '#((mutable pos b)
        (mutable body g))

     ;#:parent foo
     ;#:property w/e
     ; (lambda ())...
     )
  )

(define-syntax t2
  (er-macro-transformer
    (lambda (e r c?)
      `(quote ,(cdr e)))))


