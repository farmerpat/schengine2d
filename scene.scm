; csc -c -j scene scene.scm

(module scene *
  (import chicken scheme)
  (use
    (prefix sdl2 sdl2:)
    (prefix sdl2-image img:)
      miscmacros
      coops
      debug
      game-object
      world)

  ;(cond-expand
    ;((not compiling)
     ;(begin
       ;(require "game-object.scm")))
    ;(else))

  (declare (uses game-object))
  (declare (uses world))
  (declare (unit scene))

  (define-class <Scene> ()
    ((name initform: "scene" reader: get-name writer: set-name!)
     (game-objects initform: '() reader: get-game-objects writer: set-game-objects!)
     (world initform: #f reader: get-world writer: set-world!)
     (_event-handler initform: (lambda (e) '()) reader: get-event-handler)))

  (define-method (set-event-handler! (s <Scene>) fn)
    (if (procedure? fn)
        (set! (slot-value s '_event-handler) fn)))

  (define-method (process-event (s <Scene>) e)
    ((get-event-handler s) e))

  (define-method (render-game-objects (s <Scene>) window-renderer)
    (map (lambda (go)
           (render! go window-renderer))
         (get-game-objects s)))

  (define-method (init-world! (s <Scene>))
    (set-world! s (make-world)))

  (define-method (step-physics (s <Scene>))
    ;; step my physics universe
    ;(step! (get-phsyics-world s))
    '())

  (define-method (add-game-object (s <Scene>) go)
    (when (eq? (class-of go) <GameObject>)
      (push! go (slot-value s 'game-objects))))

  (define-method (add-game-object (s <Scene>) go) (+ 2 2))

)
