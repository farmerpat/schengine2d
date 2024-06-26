; csc -c -j game-object game-object.scm

(module game-object *
  (import chicken scheme)
  (use
    (prefix sdl2 sdl2:)
    extras
    2d-primitives
    sprite
    body
    schengine-util
    chipmunk
    srfi-4
    srfi-99)
  ; reexport just for now until this solidfies,
  ; as it fascilitates poking and prodding...
  (reexport srfi-99)

  (declare (uses schengine-util sprite body))
  (declare (unit game-object))

  (define *default-event-handler* (make-parameter (lambda (e) '())))

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
  (define-record-property sync-pos-to-body!)
  (define-record-property receive-event!)
  (define-record-property destroy!)
  (define-record-property event-handler)
  (define-record-property event-handler!)

  (define GAME_OBJECT
    (make-rtd
      'game-object
      '#((mutable pos) (mutable body) (mutable sprite) (mutable event-handler))

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
        (lambda (new-body #!optional (set-position #f))
          (set! (body rt) new-body)
          (if set-position
              (let ((new-body-pos (screen-pos->chipmunk-pos (pos rt))))
               (set! (body-position (cp-body (body rt))) new-body-pos)))))

      #:property sprite 'sprite
      #:property sprite!
      (lambda (rt)
        (lambda (new-sprite)
          (if (sprite? new-sprite)
              (set! (sprite rt) new-sprite))))

      #:property event-handler 'event-handler
      #:property event-handler!
      (lambda (rt)
        (lambda (new-handler)
          (if (procedure? new-handler)
              (set! (event-handler rt) new-handler))))

      #:property render!
      (lambda (rt)
        (lambda (window-renderer)
          (when (sprite? (sprite rt))
            ((render-texture! (sprite rt)) (pos rt) window-renderer))))

      ; if body-x > 0, go-x == half_screen_width + go-x
      ; if body-x < 0, go-x == half_screen_width - abs(go-x)
      ; if body-y > 0, go-y == half_screen_height - y
      ; if body-y < 0, go-y == half-screen-height + abs(go-y)
      ; TODO: simplify this
      #:property sync-pos-to-body!
      (lambda (rt)
        (lambda ()
          (when (body? (body rt))
            (let* ((body-pos (body-position (cp-body (body rt))))
                   (converted-pos (chipmunk-pos->screen-pos body-pos)))
              ((pos! rt) converted-pos)))))

      #:property receive-event!
      (lambda (rt)
        (lambda (event)
          ((event-handler rt) event)))

      #:property destroy!
      (lambda (rt)
        (lambda ()
          (when (sprite? (sprite rt))
            ((destroy-resources! (sprite rt)))
            ((sprite! rt) #f))
          (display "im the destroyer of GAME_OBJECTs")
          (newline)))))

  (define (game-object? rt)
    ((rtd-predicate GAME_OBJECT) rt))

  ; since we apparently can't override functions,
  ; we will have to dispatch on argument list...
  (define make-game-object-nil-args
    (lambda ()
      ((rtd-constructor GAME_OBJECT)
       (vect:create 0 0)
       #f
       #f
       (*default-event-handler*))))

  (define make-game-object-single-arg
    (lambda (pos)
      (if (and (number-vector? pos) (f32vector? pos))
          ((rtd-constructor GAME_OBJECT) pos #f #f (*default-event-handler*)))))

  (define make-game-object-double-arg
    (lambda (pos body)
      (if (and (number-vector? pos) (f32vector? pos))
          ((rtd-constructor GAME_OBJECT) pos body #f (*default-event-handler*)))))

  (define make-game-object
    (case-lambda
      (() (make-game-object-nil-args))
      ((pos) (make-game-object-single-arg pos))
      ((pos body) (make-game-object-double-arg pos body)))))
