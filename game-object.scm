; csc -c -j game-object game-object.scm

(module game-object *
  (import chicken scheme)
  (use
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
            ; scale should be in a game manager?
            (let* ((body-pos (body-position (cp-body (body rt))))
                   ;(pos-x (* 100 (vect:x body-pos)))
                   ;(pos-y (* 100 (vect:y body-pos)))
                   (pos-x (* (*chipmunk->screen-factor*) (vect:x body-pos)))
                   (pos-y (* (*chipmunk->screen-factor*) (vect:y body-pos)))
                   (half-screen-width 512)
                   (half-screen-height 384)
                   (new-x 512)  ; new-x,new-y initialized for 0 case
                   (new-y 384))

              (cond ((positive? pos-x)
                     (set! new-x (+ half-screen-width pos-x)))
                    ((negative? pos-x)
                     (set! new-x (- half-screen-width (abs pos-x)))))
              (cond ((positive? pos-y)
                     (set! new-y (- half-screen-width pos-y)))
                    ((negative? pos-y)
                     (set! new-y (+ half-screen-width (abs pos-y)))))

              ;(printf "pos-x: ~A, new-x: ~A~%" pos-x new-x)
              ;(printf "pos-y: ~A, new-y: ~A~%" pos-y new-y)

              ((pos! rt)
               (vect:create
                 (inexact->exact (round new-x))
                 (inexact->exact (round new-y))))))))

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
