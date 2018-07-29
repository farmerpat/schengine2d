
;(module game-object *
  ;(import chicken scheme)
  (use coops)

  (declare (unit game-object))
  ;(declare (uses coops))

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
;)
