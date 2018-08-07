(module dynamic-body *
  (import scheme chicken)
  (use
    extras
    miscmacros
    debug
    srfi-99
    world
    lolevel
    chipmunk
    body

  )

  (reexport srfi-99)
  (reexport body)

  (declare (uses body))
  (declare (unit dynamic-body))

  (define DYNAMIC_BODY
    (make-rtd 'dynamic-body '#() #:parent BODY))

  (define (dynamic-body? rt)
    ((rtd-predicate DYNAMIC_BODY) rt))

  (define make-dynamic-body
    (case-lambda
      ((world) (make-dynamic-body-single-arg world))
      ((world mass moment) (make-dynamic-body-triple-args world mass moment))))

  (define (make-dynamic-body-single-arg world)
    ((rtd-constructor DYNAMIC_BODY) world 'dynamic #f 10 1 '() '()))

  ;; let the DYNAMIC_BODY then call init-body!
  (define (make-dynamic-body-triple-args world mass moment)
    ((rtd-constructor DYNAMIC_BODY) world 'dynamic #f mass moment '() '())))
