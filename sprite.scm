; csc -c -j sprite sprite.scm

; TDOO: init body record that can
; be static or dynamic and will contain chipmunk properties
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
    2d-primitives
  )

  (reexport srfi-99)

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
  (define-record-property render-texture!)
  (define-record-property destroy-resources!)

  (define SPRITE
    (make-rtd
      'sprite
      '#((mutable image-file-name)
         (mutable surface)
         (mutable texture)
         (mutable texture-origin)
         (mutable texture-width)
         (mutable texture-height))

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
          (if (sdl2:surface? new-surface)
              (set! (surface rt) new-surface))))

      #:property texture 'texture
      #:property texture!
      (lambda (rt)
        (lambda (new-texture)
          (if (sdl2:texture? new-texture)
              (set! (texture rt) new-texture))))

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

      #:property render-texture!
      (lambda (rt)
        ; check the types of these
        (lambda (pos window-renderer)
          (let ((source-rect (sdl2:make-rect (vect:x (texture-origin rt))
                                             (vect:y (texture-origin rt))
                                             (texture-width rt)
                                             (texture-height rt)))
                ;; offset so that when rendered, the center
                ;; of the texture appears at the game object
                ;; coordinates
                ;; ...this could be made optional or even
                ;; extended to the point of sfml's setOrigin
                (dest-rect (sdl2:make-rect (- (vect:x pos) (/ (texture-width rt) 2.0))
                                           (- (vect:y pos) (/ (texture-height rt) 2.0))
                                           (texture-width rt)
                                           (texture-height rt))))
            (sdl2:render-copy! window-renderer (texture rt) source-rect dest-rect))))

      #:property destroy-resources!
      (lambda (rt)
        (lambda ()
          (display "im the destroyer of SPRITEs")
          (newline)

          (when (sdl2:texture? (texture rt))
            (sdl2:destroy-texture! (texture rt)))

          (when (sdl2:surface? (surface rt))
            (sdl2:free-surface! (surface rt)))))))

  (define (sprite? rt)
    ((rtd-predicate SPRITE) rt))

  (define make-sprite
    (case-lambda
      (() (make-sprite-nil-args))
      ((ifn tw th wr) (make-sprite-quadruple-args ifn tw th wr))))

  (define make-sprite-nil-args
    (lambda ()
      ((rtd-constructor SPRITE)
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

  (define make-sprite-quadruple-args
    (lambda (image-file-name texture-width texture-height window-renderer)
      (let ((sprite ((rtd-constructor SPRITE)
                     image-file-name #f #f (vect:create 0 0)
                     texture-width texture-height)))
        ((surface! sprite)
         (img:load image-file-name))
        ((texture! sprite)
         (sdl2:create-texture-from-surface* window-renderer (surface sprite)))
        ; since we have texture-width/height,
        ; we can set the origin to the center

       sprite))))
