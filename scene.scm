; csc -c -j scene scene.scm

(module scene *
  (import chicken scheme)
  (use
    (prefix sdl2 sdl2:)
    (prefix sdl2-image img:)
      extras
      miscmacros
      debug
      game-object
      sprite
      srfi-99
      srfi-13
      world)

  (reexport srfi-99)

  ;(cond-expand
    ;((not compiling)
     ;(begin
       ;(require "game-object.scm")))
    ;(else))

  (declare (uses game-object))
  (declare (uses world))
  (declare (unit scene))

  (define-record-property name)
  (define-record-property name!)
  (define-record-property game-objects)
  (define-record-property game-objects!)
  (define-record-property world)
  (define-record-property world!)
  (define-record-property add-game-object!)
  (define-record-property remove-game-object!)
  (define-record-property event-handler)
  (define-record-property event-handler!)
  (define-record-property pass-event-to-game-objects!)
  (define-record-property render-game-objects!)
  (define-record-property update-game-object-bodies!)
  (define-record-property init-world!)
  (define-record-property step-physics)
  (define-record-property destroy-game-objects!)

  (define SCENE
    (make-rtd
      'scene
      '#((mutable name)
         (mutable game-objects)
         (mutable world)
         (mutable event-handler))

      #:property name 'name
      #:property name!
      (lambda (rt)
        (lambda (new-name)
          (if (string? new-name)
            (set! (name rt) new-name))))

      #:property game-objects 'game-objects
      #:property game-objects!
      (lambda (rt)
        (lambda (new-game-objects)
          (when (list? new-game-objects)
            (set! (game-objects rt) new-game-objects))))

      #:property world 'world
      #:property world!
      (lambda (rt)
        (lambda (new-world)
          ; validate me!
          (set! (world rt) new-world)))

      #:property pass-event-to-game-objects!
      (lambda (rt)
        (lambda (event)
          (map (lambda (go)
                 ((receive-event! go) event))
               (game-objects rt))))

      #:property render-game-objects!
      (lambda (rt)
        (lambda (window-renderer)
          (map (lambda (go)
                 ((render! go) window-renderer))
               (game-objects rt))))

      #:property init-world!
      (lambda (rt)
        (lambda ()
          ((world! rt) (make-world))))

      #:property step-physics
      (lambda (rt)
        (lambda (dt)
          ; chipmunk recommends using a fixed dt...
          ; can try that now that we are flushing events
          ; instead of waiting for them, and/or
          ; can try making current-window-renderer with
          ; '(present-vsync) flag
          (if (world? (world rt))
              ((step (world rt)) dt))))

      #:property update-game-object-bodies!
      (lambda (rt)
        (lambda ()
          (map (lambda (go)
                 ((sync-pos-to-body! go)))
               (game-objects rt))))

      #:property add-game-object!
      (lambda (rt)
        (lambda (go)
          ; validate me!
          (set! (game-objects rt) (cons go (game-objects rt)))))

      #:property remove-game-object!
      (lambda (rt)
        (lambda (target-name)
          ; why can't I just let this predicate
          ; lambda and capture target-name?
          ; TODO: learn more about scheme
          (define (pred go)
            (if (string= (name go) target-name) #t #f))
          (pred (make-game-object))))

      #:property event-handler 'event-handler
      #:property event-handler!
      (lambda (rt)
        (lambda (new-event-handler)
          (if (procedure? new-event-handler)
              (set! (event-handler rt) new-event-handler))))

      #:property destroy-game-objects!
      (lambda (rt)
        (lambda ()
          ; this is the same paradigm as render-game-objects!
          ; e.g. it could be abstracted away
          (map (lambda (go)
                 ((destroy! go)))
               (game-objects rt))))
      ))

  (define (scene? rt)
    ((rtd-predicate SCENE) rt))

  (define make-scene
    (case-lambda
      (() (make-scene-nil-args))
      ((name) (make-scene-single-arg name))
      ((n gos) (make-scene-double-arg n gos))
      ((n gos w) (make-scene-triple-arg n gos w))
      ((n gos w eh) (make-scene-quadruple-arg n gos w eh))))

  (define make-scene-nil-args
    (lambda ()
      ((rtd-constructor SCENE) "" '() #f (lambda () '()))))

  (define make-scene-single-arg
    (lambda (name)
      ((rtd-constructor SCENE) name '() #f (lambda () '()))))

  (define make-scene-double-arg
    (lambda (name game-objects)
      ((rtd-constructor SCENE) name game-objects #f (lambda () '()))))

  (define make-scene-triple-arg
    (lambda (name game-objects world)
      ((rtd-constructor SCENE) name game-objects world (lambda () '()))))

  (define make-scene-quadruple-arg
    (lambda (name game-objects world event-handler)
      ((rtd-constructor SCENE) name game-objects world event-handler))))
