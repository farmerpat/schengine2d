; does this break it? it seemed more appropriate
; as i am guess that require-extension is a stronger
; stmt thant use...
; TODO: find out
;(require-extension sdl2 coops)

;(require-extension sdl2)
;(require-extension sdl2-image)
;(require-extension coops)
;(require-extension miscmacros)

(use
  (prefix sdl2 sdl2:)
  (prefix sdl2-image img:)
  coops
)

(define-class <Vector2> ()
  (
   (x initform: 0 reader: get-x writer: set-x! )
   (y initform: 0 reader: get-y writer: set-y! )
  )
)

(define-class <GameObject> ()
  (
   (pos initform: (make <Vector2> 'x 0 'y 0) reader: get-pos writer: set-pos!)
  )
)

(define-method (get-pos-x (go <GameObject>))
  (get-x (get-pos go))
)

(define-method (get-pos-y (go <GameObject>))
  (get-y (get-pos go))
)

; to be overridden by children that have something to render...
; i think the approach with all the flags and such was convoluted
; it seems to make more sense to have all the methods on GameObject.
; that way, scene can just loop over its gameobjects and call
; each method that it has to, not caring about types, because
; we aren't limited by type the same way we are in c++.
; like our list of GOs can contain GOs and children of GOs.

; i do not yet know if i will have to provide methods for
; all children even if they don't have work to do
; the purpose of such methods would simply be to
; call-next-method if it doesn't happen automatically (WHICH I SHOULD TEST)

; call-next-method provides insane flexibility.
; you can't call a parent overriden method in c++
; to my knowledge

; box2d doesn't seem to be available as an egg.
; can either write my own phsyics, or i can port
; https://github.com/dharmatech/box2d-lite ,
; and make it an egg. that seems good.
; wonder about licensing. it's apache2
;(define-method (render! (go <GameObject>) window) '())

; these get defined implicitly by using define-method:
; https://wiki.call-cc.org/eggref/4/coops#generic-procedures
(define-generic (render! renderer))
(define-generic (destroy!))

;(define-method (render! (go <GameObject>) renderer) '())
(define-method (render! (go <GameObject>) renderer)
  (printf "<GameObject> render!~%"))

(define-method (destroy! (go <GameObject>))
  (printf "<GameObject> destroy!~%"))

;; maybe this is more of a factory than a constructor...
(define <GameObject>-constructor
  ; maybe we just add a lot of optional arguments,
  ; or maybe we we can override this a bunch instead
  (lambda (posX posY)
    (let ((v (make <Vector2> 'x posX 'y posY)))
      (make <GameObject> 'pos v))))

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
    (sdl2:render-copy! renderer (get-texture s) source-rect dest-rect))
)



;; TODO: actually figure out the relationship between textures/surfaces/renders/window etc
;(define (draw-scene!)
  ;(set! (sdl2:render-draw-color window-renderer) (sdl2:make-color 80 80 80))
  ;(sdl2:render-fill-rect! window-renderer (sdl2:make-rect 0 0 800 600))

  ;(let ((source-rect (sdl2:make-rect 0 0 64 64))
        ;(dest-rect (sdl2:make-rect 100 100 64 64)))
    ;(sdl2:render-copy! window-renderer sprite-texture source-rect dest-rect)
    ;;(sdl2:render-copy! window-renderer sprite-texture)
  ;)

  ;(let ((rect (sdl2:make-rect 200 200 32 32)))
    ;; set draw color...
    ;(set! (sdl2:render-draw-color window-renderer) (sdl2:make-color 0 0 0))
    ;(sdl2:render-fill-rect! window-renderer rect)
  ;)

  ;(sdl2:render-present! window-renderer)
;)

(define <Sprite>-constructor
  ; maybe we just add a lot of optional arguments,
  ; or maybe we we can override this a bunch instead
  (lambda (posX posY textureW textureH img window-renderer)
    (let* ((v (make <Vector2> 'x posX 'y posY))
           (sprite (make <Sprite> 'pos v 'texture-width textureW 'texture-height textureH 'img-file-name img))
           )
           ;; TODO: OBVIOUSLY MAKE SURE THE FILE EXISTS FIRST...
           ;(surface (img:load (get-img-file-name sprite)))
           ;(texture (sdl2:create-texture-from-surface* window-renderer surface)))

      ; do we want a pointer instead?
      ; can we even have one?
      (set-surface! sprite (img:load (get-img-file-name sprite)))
      (set-texture! sprite (sdl2:create-texture-from-surface* window-renderer (get-surface sprite)))

      ;(set-surface! sprite surface)
      ;(set-texture! sprite texture)
    sprite)
  )
)

(define-method (destroy! before: (s <Sprite>))
  ;(if (get-renderer s)
    ;(sdl2:destroy-renderer! (get-renderer s))
  ;)

  (if (get-texture s)
    ;; we don't have to do this if its not a pointer...
    ;; for some reason getting  unbound variable: sdl2:create-texture-from-surface*...
    (sdl2:destroy-texture! (get-texture s))
  )
)
