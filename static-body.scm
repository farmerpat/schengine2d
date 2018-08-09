(module static-body *
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
  (declare (unit static-body))

  (define STATIC_BODY
    (make-rtd 'static-body '#() #:parent BODY))

  (define (static-body? rt)
    ((rtd-predicate STATIC_BODY) rt))

  (define make-static-body
    (case-lambda
      ((world) (make-static-body-single-arg world))
      ((world shape) (make-static-body-double-args world shape))))

  (define (make-static-body-single-arg world)
    ((rtd-constructor STATIC_BODY) world 'static #f 10 1 '() '()))

  ;; let the DYNAMIC_BODY then call init-body!
  (define (make-static-body-double-args world shape)
    (let ((body ((rtd-constructor STATIC_BODY) world 'static #f 0 0 '() '())))

    ))
