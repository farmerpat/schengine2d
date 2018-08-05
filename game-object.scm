; csc -c -j game-object game-object.scm

(module game-object *
  (import chicken scheme)
  (use
    extras
    2d-primitives
    sprite
    srfi-4
    srfi-99)
  ; reexport just for now until this solidfies,
  ; as it fascilitates poking and prodding...
  (reexport srfi-99)

  (declare (unit game-object))

  (define-record-property pos)

  (define-record-property pos!)
  ;(define-record-property children)
  ;(define-record-property add-child!)
  ; etc...

  ; body could be a record that is a wrapper around
  ; a chipmunk body
  (define-record-property body)
  (define-record-property body!)
  (define-record-property sprite)
  (define-record-property sprite!)
  (define-record-property render!)
  (define-record-property receive-event!)
  (define-record-property destroy!)

  (define GAME_OBJECT
    (make-rtd
      'game-object
      '#((mutable pos) (mutable body) (mutable sprite))

      #:property pos 'pos
      #:property pos!
      (lambda (rt)
        (lambda (new-pos)
          (if (number-vector? new-pos)
              (if (f32vector? new-pos)
                  (set! (pos rt) new-pos)))))

      #:property body 'body
      #:property body!
      (lambda (rt)
        (lambda (new-body)
          (set! (body rt) new-body)))

      #:property sprite 'sprite
      #:property sprite!
      (lambda (rt)
        (lambda (new-sprite)
          (if (sprite? new-sprite)
              (set! (sprite rt) new-sprite))))

      #:property render!
      (lambda (rt)
        (lambda (window-renderer)
          (when (sprite? (sprite rt))
            ((render-texture! (sprite rt)) (pos rt) window-renderer))))

      #:property receive-event!
      (lambda (rt)
        (lambda (event)
          '()))

      #:property destroy!
      (lambda (rt)
        (lambda ()
          (if (sprite? (sprite rt))
              ((destroy-resources! (sprite rt))))
          (display "im the destroyer of GAME_OBJECTs")
          (newline)))))

  (define (game-object? rt)
    ((rtd-predicate GAME_OBJECT) rt))

  ; since we apparently can't override functions,
  ; we will have to dispatch on argument list...
  (define make-game-object-nil-args
    (lambda ()
      ((rtd-constructor GAME_OBJECT) (vect:create 0 0) #f #f)))

  (define make-game-object-single-arg
    (lambda (pos)
      (if (and (number-vector? pos) (f32vector? pos))
          ((rtd-constructor GAME_OBJECT) pos #f #f))))

  (define make-game-object-double-arg
    (lambda (pos body)
      (if (and (number-vector? pos) (f32vector? pos))
          ((rtd-constructor GAME_OBJECT) pos body #f))))

  (define make-game-object
    (case-lambda
      (() (make-game-object-nil-args))
      ((pos) (make-game-object-single-arg pos))
      ((pos body) (make-game-object-double-arg pos body)))))
