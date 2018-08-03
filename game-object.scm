; csc -c -j game-object game-object.scm

(module game-object *
  (import chicken scheme)
  (use
    ;coops
    extras
    2d-primitives
    srfi-4
    srfi-99)
  ; reexport just for now until this solidfies,
  ; as it fascilitates poking and prodding...
  (reexport srfi-99)

  (declare (unit game-object))

  (define-record-property pos)
  (define-record-property pos!)
  ; body could be a record that is a wrapper around
  ; a chipmunk body
  (define-record-property body)
  (define-record-property body!)
  (define-record-property render!)
  (define-record-property destroy!)

  (define GAME_OBJECT
    (make-rtd
      'game-object
      '#((mutable pos) (mutable body))

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

      #:property render!
      (lambda (rt)
        (lambda ()
          (display "i am game-object's render!")
          (newline)))

      #:property destroy!
      (lambda (rt)
        (lambda ()
          (display "im the destroyer of GAME_OBJECTs")
          (newline)))))

  (define make-game-object
    (lambda ()
      ((rtd-constructor GAME_OBJECT) (vect:create 0 0) #f)))

  )

#|

  (define-class <Vector2> ()
    ((x initform: 0 reader: get-x writer: set-x!)
     (y initform: 0 reader: get-y writer: set-y!)))

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
  ; and we can call parent implementations of generics!

  ; box2d doesn't seem to be available as an egg.
  ; can either write my own phsyics, or i can port
  ; https://github.com/dharmatech/box2d-lite ,
  ; and make it an egg. that seems good.
  ; wonder about licensing. it's apache2

  ; these get defined implicitly by using define-method:
  ; https://wiki.call-cc.org/eggref/4/coops#generic-procedures
  (define-generic (render! renderer))
  (define-generic (destroy!))

  (define-method (render! (go <GameObject>) renderer)
    (printf "<GameObject> render!~%"))

  (define-method (destroy! (go <GameObject>))
    (printf "<GameObject> destroy!~%"))

  (define <GameObject>-constructor
    ; maybe we just add a lot of optional arguments,
    ; or maybe we we can override this a bunch instead
    (lambda (posX posY)
      (let ((v (make <Vector2> 'x posX 'y posY)))
        (make <GameObject> 'pos v))))

; consider replacing -constructor with:
;$<ClassName>$

; and destructor would be:
;~<ClassName>~
; this might work if each class's shared __detroy! (or whatever) method
; is called by ~<ClassName>~ and ClassNames's implemenation of __destroy!
; does the real work and is defined as before: so that ParentClasse's __destroy
; method is called if applicable.
;
; it would be cool if this were part of coops. i wonder if
; i can cobble something together as is, or if going amop
; would work. I don't even know what that is, but it seems
; relevent somehow
;
; calls itself before: its parent. the only thing it does is
|#
