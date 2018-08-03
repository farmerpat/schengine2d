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

      #:property render!
      (lambda (rt)
	(lambda (renderer)
	  (let ((source-rect (sdl2:make-rect (vect:x (texture-origin rt))
					     (vect:y (texture-origin rt))
					     (texture-width rt)
					     (texture-height rt)))
		(dest-rect (sdl2:make-rect (vect:x (pos rt))
					   (vect:y (pos rt))
					   (texture-width rt)
					   (texture-height rt))))
	    (sdl2:render-copy! renderer (texture s) source-rect dest-rect))))

      #:property destroy!
      (lambda (rt)
        (lambda ()
          (display "im the destroyer of SPRITEs")
          (newline)))))

  (define make-sprite
    (lambda ()
      ((rtd-constructor SPRITE) "" #f #f (vect:create 0 0) 0 0)))

  (define make-sprite
    (lambda (image-file-name texture-width texture-height)
      ; afterwards, how about initializing the texture/surface?
      ((rtd-constructor SPRITE) image-file-name #f #f (vect:create 0 0) texture-width texture-height)))
  )

#|
  (define-class <Sprite> (<GameObject>)
    (
      (img-file-name initform: "" reader: get-img-file-name writer: set-img-file-name!)
      (surface initform: #f reader: get-surface writer: set-surface!)
      (texture initform: #f reader: get-texture writer: set-texture!)
      (texture-origin initform: (make <Vector2>) reader: get-texture-origin writer: set-texture-origin!)
      (texture-width initform: 0 reader: get-texture-width writer: set-texture-width!)
      (texture-height initform: 0 reader: get-texture-height writer: set-texture-height!)
    )
  )

  (define-method (get-texture-origin-x (s <Sprite>))
    (get-x (get-texture-origin s))
  )

  (define-method (get-texture-origin-y (s <Sprite>))
    (get-y (get-texture-origin s))
  )

  ; like this, (render! s) only calls <Sprite>'s method... primary: qualifier is implied
  ;(define-method (render! (s <Sprite>) renderer)
    ;(printf "<Sprite> render!~%"))

  ; like this, (render! s) calls <GameObject>'s render! and then <Sprite>'s render
  ;(define-method (render! after: (s <Sprite>) renderer)
    ;(printf "<Sprite> render!~%"))

  ; like this, we have to call-next-method or it will act like primary...
  ; we can make it behave like after by putting call-next-method before
  ; the other work the method does, or we can make it behave like before
  ; by sticking call-next-method at the end of the method body.
  ;(define-method (render! around: (s <Sprite>) renderer)
    ;(printf "<Sprite> render!~%")
    ;(call-next-method))

  ; TODO: actually figure out the relationship between textures/surfaces/renders/window etc

  (define-method (render! (s <Sprite>) renderer)
    (let* ((textureX (get-texture-origin-x s))
           (textureY (get-texture-origin-y s))
           (textureW (get-texture-width s))
           (textureH (get-texture-height s))
           (source-rect (sdl2:make-rect textureX textureY textureW textureH))
           ; coords are top left instead of center methinks...
           ; which I don't like. plus if box2d comes into play, its easier
           ; to abstract the upper-left peice away and the user can envision
           ; sprites as having an origin at the center of the image

           (dest-rect (sdl2:make-rect (get-pos-x s) (get-pos-y s) textureW textureH)))
      (sdl2:render-copy! renderer (get-texture s) source-rect dest-rect)))

  (define <Sprite>-constructor
    (lambda (posX posY textureW textureH img window-renderer)
      (let* ((v (make <Vector2> 'x posX 'y posY))
             (sprite (make <Sprite> 'pos v 'texture-width textureW 'texture-height textureH 'img-file-name img)))
        ;; TODO: OBVIOUSLY MAKE SURE THE FILE EXISTS FIRST...
        (set-surface! sprite (img:load (get-img-file-name sprite)))
        (set-texture! sprite (sdl2:create-texture-from-surface* window-renderer (get-surface sprite)))
        sprite)
    )
  )

  (define-method (destroy! before: (s <Sprite>))
    (printf "<Sprite> destroy!~%")
    ;(if (get-renderer s)
      ;(sdl2:destroy-renderer! (get-renderer s))
    ;)

    (if (get-texture s)
      (printf "destroying texture~%")
      ;; we don't have to do this if its not a pointer...
      ;; for some reason getting  unbound variable: sdl2:create-texture-from-surface*...
      (sdl2:destroy-texture! (get-texture s))
    )
  )
|#
