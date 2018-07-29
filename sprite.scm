; compile me with
; csc -c -j sprite sprite.scm
;
; most recently compiled with:
; csc -c -j sprite sprite.scm 
; csc -s sprite.import.scm
; similaryly for game-object


;(module sprite *
  ;(import chicken scheme)
  (use
    (prefix sdl2 sdl2:)
    (prefix sdl2-image img:)
    miscmacros
    coops
    debug
  )
    ;; think this should be import:
    ;game-object
    ;;
    ;; a la:
    ;; https://stackoverflow.com/questions/38986942/how-do-i-get-this-chicken-scheme-code-to-compile :
    ;;; Only import the module; we take care of loading the code above,
    ;;; or in the linking step when compiling.  If we had (use test-b),
    ;;; the library would be searched for at runtime.
    ;;; Alternatively, (use test-b) here, but add (register-feature! 'test-b)
    ;;; to test-b.scm, which prevents the runtime from attempting to load test-b.
    ;;;(import test-b)
  ;)

  ;(declare (uses sdl2))
  ;(declare (uses sdl2-image))
  ;(declare (uses miscmacros))
  ;(declare (uses coops))
  ;(declare (uses debug))
  (declare (uses game-object))
  (declare (unit sprite))

  ; how do?
  ; must chicken-install eggs for this build?
  ;(declare (uses game-object))

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
;)
