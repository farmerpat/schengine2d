(module body *
  (import chicken scheme)
  (use
    extras
    miscmacros
    debug
    srfi-99
    world
    lolevel
    chipmunk
  )

  (reexport srfi-99)

  (declare (uses world))
  (declare (unit body))

  (define-record-property parent-world)
  (define-record-property parent-world!)
  (define-record-property type)
  (define-record-property type!)
  (define-record-property cp-body)
  (define-record-property cp-body!)
  (define-record-property cp-body-mass)
  (define-record-property cp-body-mass!)
  (define-record-property cp-body-moment)
  (define-record-property cp-body-moment!)
  (define-record-property cp-shapes)
  (define-record-property cp-shapes!)
  (define-record-property add-shape!)
  (define-record-property cp-fixtures)
  (define-record-property cp-fixtures!)
  (define-record-property add-fixture!)
  (define-record-property init-body!)

  (define BODY
    (make-rtd
      'body
      '#((mutable parent-world)
         (mutable type)
         (mutable cp-body)
         (mutable cp-body-mass)
         (mutable cp-body-moment)
         (mutable cp-shapes)
         (mutable cp-fixtures))

      #:property parent-world 'parent-world
      #:property parent-world!
      (lambda (rt)
        (lambda (new-parent-world)
          (if (world? new-parent-world)
              (set! (parent-world rt) new-parent-world))))

      #:property type 'type
      #:property type!
      (lambda (rt)
        (lambda (new-type)
          (if (or (equal? 'dynamic new-type)
                  (equal? 'static new-type))
              (set! (type rt) new-type))))

      #:property cp-body 'cp-body
      #:property cp-body!
      (lambda (rt)
        (lambda (new-cp-body #!optional (pos #f))
          ; TODO:
          ; really need to tag these or something
          ; or figure out the appropriate predicate...
          (if (pointer? new-cp-body)
              (set! (cp-body rt) new-cp-body)
              (if pos
                  (set! (body-position (cp-body rt)) pos)))))

      #:property cp-body-mass 'cp-body-mass
      #:property cp-body-mass!
      (lambda (rt)
        (lambda (new-mass)
          (if (number? new-mass)
              (set! (cp-body-mass rt) new-mass))))

      #:property cp-body-moment 'cp-body-moment
      #:property cp-body-moment!
      (lambda (rt)
        (lambda (new-moment)
          (if (number? new-moment)
              (set! (cp-body-moment! rt) new-moment))))

      #:property cp-shapes 'cp-shapes
      #:property cp-shapes!
      (lambda (rt)
        ; can i map/apply? "and" over a list of
        ; booleans and get a single result?
        (lambda (new-cp-shapes)
          ; if they're all valid shapes...
          (set! (cp-shapes rt) new-cp-shapes)))

      #:property add-shape!
      (lambda (rt)
        (lambda (new-shape)
          ; if its a shape
          ; push it
          ;; ...seriously..do it
          ;; this might not make any sense at all...
          ;; we create shapes by adding them to a body.
          ;; those calls return the created shapes as
          ;; the result. i chould just stick those
          ;; in here...
          ;; i think chipmunk provides iterators to get the
          ;; shapes, etc of a body. so this might not
          ;; be necessary at all.
          '()))

      #:property cp-fixtures 'cp-fixtures
      #:property cp-fixtures!
      (lambda (rt)
        (lambda (new-cp-fixtures)
          ; if they're all valid fixtures...
          (set! (cp-fixtures rt) new-cp-fixtures)))

      #:property add-fixture!
      (lambda (rt)
        (lambda (new-fixture)
          ; if its a valid fixture
          ; push it
          '()))

      ; this will ultimately initialize
      ; the body and add it to parent-world
      ; it will also iterate over
      ; the shapes and fixtures
      ; and add them to cp-body
      #:property init-body!
      (lambda (rt)
        (lambda ()
          ; why did I even put this in a let?
          (let ((b #f))
           (cond ((equal? (type rt) 'static)
                  (set! b (space-static-body (space (parent-world rt)))))
                 ((equal? (type rt) 'dynamic)
                  (set! b (create-body (cp-body-mass rt) (cp-body-moment rt)))))

           ((cp-body! rt) b)

           (when (and (body-rogue? (cp-body rt)) (equal? (type rt) 'dynamic))
             ;; do we have to add it when its static?
             ;; aren't we just adding a shape to the space's static body
             ;; or something?
             (space-add-body (space (parent-world rt)) (cp-body rt))))))
    )
  )

  (define (body? rt)
    ((rtd-predicate BODY) rt))

  (define make-body
    (case-lambda
      ((world) (make-body-single-arg world))
      ((world type) (make-body-double-arg world type))
      ((world type mass moment) (make-body-quadruple-arg world type mass moment))))

  (define (make-body-single-arg world)
    (when (world? world)
      ((rtd-constructor BODY) world 'dynamic #f 10 1 '() '())))

  (define (make-body-double-arg world type)
    (when (world? world)
      ((rtd-constructor BODY) world type #f 10 1 '() '())))

  (define (make-body-quadruple-arg world type mass moment)
    (display "type: ")
    (display type)
    (newline)
    (when (and (world? world) (number? mass) (number? moment)
               (positive? mass) (positive? moment))
      (let ((b ((rtd-constructor BODY) world type #f mass moment '() '())))
       ((init-body! b))
       b))))

#|
one approach would be to just extend the body record
into boxed-body, encircled-body, etc
one thing to consider is how we determine
what type of body it is
e.g. do we make boxed-static-body from boxed-body ?
or do we just make body-type be a property of
body and default to dynamic if it is not set
e.g. dynamic, kinematic, and static
...it doesn't seem to support cpBodyNewKinematic or cpBodyInitKinematic
...not sure if the chipmunk egg needs patched for it,
or the lib in the chicken egg is too old

for now just have type prop be either 'static or 'dynamic

for instance, we might have a descendant of body called
box-shaped-body...

example usage:

#;1> (use 2d-primitives)
#;2> (use chipmunk)
#;3> (define space (create-space))
#;4> (set! (space-gravity space) (vect:create 0.0 -9.8))
#;5> (define mass 50)
#;6> (define width 64)
#;7> (define height 64)
#;8> (define moment (moment-for-box mass width height))
#;10> (define body (create-body mass moment)))

      ; add the shape to the body and capture the shape as hitbox-shape
#;11> (define hitbox-shape (create-box-shape-new body width height))

      ; the shape can see the body
#;15> (body-position (shape-body hitbox-shape)))

      ; but afaik, the body cant see the shape
#;16> (body-shape shape-body)
********BARF**********
#;19> (space-add-body space body)
#;20> (define step-time 1/60)
#;21> (space-step space step-time)
#;22> (space-step space step-time)
#;23> (body-position body)
#f32(0.0 -0.002722222590819)

      ; it can, however (supposedly) see the space it belongs to
#;24> (body-space body)
******BARF***** (segmentation violation)...wut?
NOTE: a solid circle has an inner diameter of 0
NOTE: the positions of inner-diameter and outer-diameter are interchangeable
[float] moment-for-circle (float mass float inner-diameter float outer-diameter vect))
[float] moment-for-seqment (float mass vect endpoint-one vect endpoint-two))
[float] moment-for-box (float mass float width float height))

; thanks to me we have:
(create-box-shape-new body width height)
; it returns the shape it creates

; from chipmunk (and possibly just re-exported from physics)...
; from (%define-chipmunk-foreign-properties (body c-body) ...
; we get:

body-mass
body-moment
body-position
body-velocity
body-force
body-angle
body-angle-velocity
body-torque
body-rotation
body-velocity-limit
body-angular-velocity-limit
body-space


; from (%define-chipmunk-foreign-properties (space c-space)
; we get

space-iterations
space-gravity
space-damping
space-idle-speed-treshold
space-sleep-time-treshold
space-collision-slop
space-collision-bias
space-collision-persistence
space-current-time-step
space-locked?
space-static-body

; from (%define-chipmunk-foreign-methods (space c-space)
; we get

space-add-shape
space-add-body
space-add-static-shape
space-add-constraint
space-remove-shape
space-remove-body
space-remove-constraint
space-has-shape?
space-has-body?
space-has-constraint?
space-body->static
space-body->dynamic
space-reindex-shape
space-reindex-shapes-for-body
space-reindex-static


; from (%define-chipmunk-foreign-methods (body c-body)
; we get

body-reset-forces
body-apply-force
body-apply-impulse
body-sleeping?
body-activate
body-sleep
body-static?
; body-rogue returns true if body has never been added to a space.
body-rogue?


; from phsycis we have:

record-type: space-meta
procedures:
  (create-space)
  (space-bodies space)
  (space-shapes space)
  (space-bodies space)
  (space-each-body space func)
  (space-each-shape space func)
  (space-each-constraint space func)
  (space-add-body space body)
  (space-remove-body space body)
  (space-add-shape space shape)
  (space-add-static-shape space shape)
  (space-remove-shape space shape)
  (space-add-constraint space constraint)
  (space-remove-constraint space constraint)
  space-on-collision-begin
  space-on-collision-presolve
  space-on-collision-postsolve
  space-on-collision-seperate
  (space-add-collision-handler
    space
    collision-type-a collision-type-b
    begin-func presolve-func postsolve-func seperate-func
    #!rest data)
  (space-remove-collision-handler space collision-type-a collision-type-b)
  (space-add-poststep-callback space func key #!rest data)
  (space-step space dt)

record-type: body-meta
record-type: body-userdata

procedures:
  (define-high-wrappers
   low:body-free
   (make-body-meta #f)
   (create-body low:create-body)
   (create-static-body low:create-static-body))
; giving us create-body and create-static-body
; that map to chipmunk's create-body and create-static-body,
; respectively
; here's their arument lists:
(create-body mass moment-of-inertia)
(create-static-body)

more procedures:
(body-each-shape body func)
(body-each-constraint body func)
(body-each-arbiter body func)

record-type: shape-meta

procedures:
  (define-high-wrappers
   low:shape-free
   (make-shape-meta #f)
   (create-circle-shape low:create-circle-shape)
   (create-polygon-shape low:create-polygon-shape)
   (create-box-shape low:create-box-shape))
; giving us create-circle-shape, create-polygon-shape, and create-box-shape
; that map to...(as above)
; here's their arument lists:
(create-circle-shape body-to-attach-to radius center-of-gravity-offset)

; body is the body to attach the poly to,
; vertices is a list of vectors defining a convex hull with a clockwise winding,
; offset is the offset from the body’s center of gravity in body local coordinates.
; An assertion will be thrown the vertexes are not convex
; or do not have a clockwise winding.
(create-polygon-shape body vertices offset #!optional radius)

; its not created if !radius, so its not really optional
(create-box-shape body bounding-box #!optional radius)

record-type: shape-userdata
record-type: shape-group
record-type: shape-layers

more procedures:
 (polygon-shape-vertices shape)

record-type: constraint-meta
record-type: constraint-userdata

(define-high-wrappers
  low:constraint-free
  (make-constraint-meta #f)
  (create-pin-joint low:create-pin-joint)
  (create-slide-joint low:create-slide-joint)
  (create-pivot-joint-with-anchors low:create-pivot-joint-with-anchors)
  (create-pivot-joint-with-pivot low:create-pivot-joint-with-pivot)
  (create-groove-joint low:create-groove-joint)
  (create-damped-spring low:create-damped-spring)
  (create-damped-rotary-spring low:create-damped-rotary-spring)
  (create-rotary-limit-joint low:create-rotary-limit-joint)
  (create-ratchet-joint low:create-ratchet-joint)
  (create-gear-joint low:create-gear-joint)
  (create-simple-motor low:create-simple-motor))

; Layers are also a thing (physics.scm line 567)
; Groups are also a thing
; Queries are also a thing
|#
