; csc -c -j sprite sprite.scm

(module sprite *
  (import chicken scheme)
  (use
    (prefix sdl2 sdl2:)
    (prefix sdl2-image img:)
    extras
    miscmacros
    debug
    srfi-4
    srfi-99
    game-object
    2d-primitives
  )

  (reexport srfi-99)

  (declare (uses game-object))
  (declare (unit sprite))

  (define-record-property image-file-name)
  (define-record-property image-file-name!)
  (define-record-property surface)
  (define-record-property surface!)
  (define-record-property texture)
  (define-record-property texture!)
  (define-record-property texture-origin)
  (define-record-property texture-origin!)
  (define-record-property texture-width)
  (define-record-property texture-width!)
  (define-record-property texture-height)
  (define-record-property texture-height!)

  (define SPRITE
    (make-rtd
      'sprite
      '#((mutable image-file-name)
         (mutable surface)
         (mutable texture)
         (mutable texture-origin)
         (mutable texture-width)
         (mutable texture-height))

      #:parent GAME_OBJECT
      #:property image-file-name 'image-file-name
      #:property image-file-name!
      (lambda (rt)
        (lambda (new-image-file-name)
          ; validate this
          (set! (image-file-name rt) new-image-file-name)))

      #:property surface 'surface
      #:property surface!
      (lambda (rt)
        (lambda (new-surface)
          ; validate this
          (set! (surface rt) new-surface)))

      #:property texture 'texture
      #:property texture!
      (lambda (rt)
        (lambda (new-texture)
          (set! (texture rt) new-texture)))

      #:property texture-origin 'texture-origin
      #:property texture-origin!
      (lambda (rt)
        (lambda (new-texture-origin)
          (set! (texture-origin rt) new-texture-origin)))

      #:property texture-width 'texture-width
      #:property texture-width!
      (lambda (rt)
        (lambda (new-texture-width)
          (set! (texture-width rt) new-texture-width)))

      #:property texture-height 'texture-height
      #:property texture-height!
      (lambda (rt)
        (lambda (new-texture-height)
          (set! (texture-height rt) new-texture-height)))

      ; does sprite have to implement this since
      ; its defined as a record property?
      ; test to find out!
      ; it turns out that it doesn't have to implement it
      ; what if its children what to use it?
      #:property receive-event!
      (lambda (rt)
        (lambda (event)
          '()))

      #:property render!
      (lambda (rt)
        (lambda (window-renderer)
          (let ((source-rect (sdl2:make-rect (vect:x (texture-origin rt))
                                             (vect:y (texture-origin rt))
                                             (texture-width rt)
                                             (texture-height rt)))
                (dest-rect (sdl2:make-rect (vect:x (pos rt))
                                           (vect:y (pos rt))
                                           (texture-width rt)
                                           (texture-height rt))))
            (sdl2:render-copy! window-renderer (texture rt) source-rect dest-rect))))

      #:property destroy!
      (lambda (rt)
        (lambda ()
          (display "im the destroyer of SPRITEs")
          (newline)
          ; how call parent?
          ; seems like we can't
          ))))

  (define (sprite? rt)
    ((rtd-predicate SPRITE) rt))

  (define make-sprite
    (case-lambda
      (() (make-sprite-nil-args))
      ((ifn tw th wr) (make-sprite-quadruple-args ifn tw th wr))))

  (define make-sprite-nil-args
    (lambda ()
      ((rtd-constructor SPRITE)
       ; game-object's:
       ; pos
       (vect:create 0 0)
       ; body
       #f
       ; sprite's
       ; image-file-name
       ""
       ; surface
       #f
       ; texture
       #f
       ; texture-origin
       (vect:create 0 0)
       ; texture-width
       0
       ; texture-height
       0)))

  ; ! b/c we are setting texture and surface even though they aren't passed in
  (define make-sprite-quadruple-args
    (lambda (image-file-name texture-width texture-height window-renderer)
      ; afterwards, how about initializing the texture/surface?
      (let ((sprite ((rtd-constructor SPRITE)
                     (vect:create 0 0) #f
                     image-file-name #f #f (vect:create 0 0)
                     texture-width texture-height)))
        ((surface! sprite)
         (img:load image-file-name))
        ((texture! sprite)
         (sdl2:create-texture-from-surface* window-renderer (surface sprite)))
       sprite))))
