; csc -c -j world world.scm

(module world *
  (import chicken scheme)
  (use
      miscmacros
      coops
      debug
      physics
      srfi-4
      2d-primitives
      srfi-99)
  ; reexport just for now until this solidfies,
  ; as it fascilitates poking and prodding...
  (reexport srfi-99)

  (declare (unit world))

  (define-record-property space)
  (define-record-property space!)
  (define-record-property step-time)
  (define-record-property step-time!)
  (define-record-property gravity)
  (define-record-property gravity!)
  (define-record-property init!)
  (define-record-property destructor)

  ;; add some validation to setters...
  (define WORLD
    (make-rtd
      'world
      '#((mutable space) (mutable step-time) (mutable gravity))
      #:property space 'space
      #:property space!
      (lambda (rt)
        (lambda (new-space)
          (set! (space rt) new-space)))

      #:property step-time 'step-time
      #:property step-time!
      (lambda (rt)
        (lambda (new-step-time)
          (set! (step-time rt) new-step-time)))

      #:property gravity 'gravity
      #:property gravity!
      (lambda (rt)
        (lambda (new-gravity)
          (set! (gravity rt) new-gravity)))

      #:property init!
      (lambda (rt)
        (lambda ()
          (let ((s (create-space)))
            ((space! rt) s)
            (if (number-vector? (gravity rt))
              (if (f32vector? (gravity rt))
                (set! (space-gravity (space rt)) (gravity rt)))))))

      #:property destructor
      (lambda (rt)
        (lambda ()
        (display "im the destroyer of WORLDs")
        (newline)))

    )
  )

  ; if we let ((w (rtd-constructor WORLD))),
  ; might be able to make destrctor go on
  ; "out of scope" callback for newly minted
  ; WORLDs...
  (define make-world
    (lambda (#!optional (auto-init #t))
      (let ((w ((rtd-constructor WORLD) #f 1/60 (vect:create 0 -9.8))))
        (if auto-init ((init! w)))
        w))))

;(define-class <World> ()
  ;((space initform: #f reader: get-space writer: set-space!)
   ;(step-time initform: 1/60 reader: get-step-time writer: set-step-time!)
   ;(gravity initform: (vect:create 0 -9.8) reader: get-gravity writer: set-gravity!)))

;; <World> has to be responsible for setting that
;; "you're out of scope" ballback
;; that calls space-free
;(define-method (init! (w <World>))
  ;(set-space! w (create-space))
  ;(if (number-vector? (get-gravity w))
    ;(if (f32vector? (get-gravity w))
      ;(set! (space-gravity (get-space w)) (get-gravity w)))))

;(define-method (step! (w <World>))
  ;(space-step (get-space w) (get-step-time w)))

;(define (<World>-constructor #!optional (auto-init #t))
  ;(let ((w (make <World>)))
    ;(if auto-init
      ;(init! w))
    ;w))
