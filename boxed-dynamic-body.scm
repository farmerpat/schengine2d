(module boxed-dynamic-body *
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
    dynamic-body

  )

  (reexport srfi-99)
  (reexport body)

  (declare (uses body))
  (declare (uses dynamic-body))
  (declare (unit boxed-dynamic-body))

  (define-record-property body-width)
  (define-record-property body-width!)
  (define-record-property body-height)
  (define-record-property body-height!)
  (define-record-property box-shape)
  (define-record-property box-shape!)

  (define BOXED_DYNAMIC_BODY
    (make-rtd 'boxed-dynamic-body
      '#((mutable body-width) (mutable body-height) (mutable box-shape))
      #:parent DYNAMIC_BODY

      #:property body-width 'body-width
      #:property body-width!
      (lambda (rt)
        (lambda (new-body-width)
          (if (and (number? new-body-width) (positive? new-body-width))
              (set! (body-width rt) new-body-width))))

      #:property body-height 'body-height
      #:property body-height!
      (lambda (rt)
        (lambda (new-body-height)
          (if (and (number? new-body-height) (positive? new-body-height))
              (set! (body-height rt) new-body-height))))

      #:property box-shape 'box-shape
      #:property box-shape!
      (lambda (rt)
        (lambda (new-box-shape)
          ;; find out what predicate is applicable
          (set! (box-shape rt) new-box-shape)))

    )
  )

  (define (boxed-dynamic-body? rt)
    ((rtd-predicate BOXED_DYNAMIC_BODY) rt))

  ; none of these are setting the position based
  ; on the position of the game-object parent...
  ; we should be setting pos somewhere
  (define make-boxed-dynamic-body
    (case-lambda
      ((world width height)
       (make-boxed-dynamic-body-triple-args world width height))
      ((world width height mass)
       (make-boxed-dynamic-body-quadruple-args world width height mass))))

  (define (make-boxed-dynamic-body-triple-args world width height)
    ((rtd-constructor BOXED_DYNAMIC_BODY) world 'dynamic #f 10 1 '() '() width height #f))

  (define (make-boxed-dynamic-body-quadruple-args world w h m)
    (let* ((moment (moment-for-box m w h))
           (bdb ((rtd-constructor BOXED_DYNAMIC_BODY)
                 world 'dynamic #f m moment '() '() w h #f)))
      ((init-body! bdb))
      (let ((shape (create-box-shape-new (cp-body bdb) w h)))
       ((box-shape! bdb) shape)
       (space-add-shape (space world) shape)
       bdb))))
