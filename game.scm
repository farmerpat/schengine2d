; right now...
; csc -c -j game-object game-object.scm
; csc -c -j sprite sprite.scm
; csc -c -j scene scene.scm
; csi
; > ,l game.scm


;(declare (uses scene))
;(declare (uses sprite))
;(declare (unit game))

; if we run csi from the same directory our .import.scm files are located
; for our project's modules, this will work as expected with ,l game.scm
(use
  (prefix sdl2 sdl2:)
  (prefix sdl2-image img:)
  (prefix sprite spr:)
  miscmacros
  coops
  debug
  scene
)

(define-class <Game> ()
  (
   ; if a "caller" is passed into the constructor,
   ; we could enforce object permissions.
   ; meaning that instead of public and private (which i think
   ; we can sort of do by just not defining setters/getters to taste),
   ; only objects of certain classes could be allowed to interact
   ; with th object at all. macros could make this possible.
   ; trying to call a method on one of these "protected" objects
   ; could expand into a call grabs the current context or something...
   ; and somehow figures it out or maybe the caller is just passed in as a
   ; param to start...
    (window-width initform: 1024 reader: get-window-width writer: set-window-width!)
    (window-height initform: 768 reader: get-window-height writer: set-window-height!)
    (title initform: "Schengine" reader: get-title writer: set-title!)
    (do-quit initform: #f reader: get-do-quit)
    (scenes initform: '() reader: get-scenes writer: set-scenes!)
    (window initform: '() reader: get-window)
    (current-window-renderer initform: #f reader: get-current-window-renderer writer: set-current-window-renderer!)
    (current-scene initform: '() reader: get-current-scene writer: set-current-scene!)
    (verbose-logging initform: #f reader: get-verbose-logging)
  )
)

; need current-window-renderer and current-scene to be set....
(define (<Game>-constructor #!optional (title "Schengine") (w 1024) (h 768) (scenes '()))
  (let ((g (make <Game>)))
    (set-window-width! g w)
    (set-window-height! g h)
    (set-title! g title)
    (set-scenes! g scenes)
    g
  )
)

(define-method (render-current-scene (g <Game>))
  (when (eq? (class-of (get-current-scene g)) <Scene>)
    (render-game-objects (get-current-scene g) (get-current-window-renderer g))))

(define-method (feed-input-to-current-scene (g <Game>) event)
  (when (eq? (class-of (get-current-scene g)) <Scene>)
    (process-event (get-current-scene g) event)))

(define-method (process-physics-for-current-scene (g <Game>))
  (when (eq? (class-of (get-current-scene g)) <Scene>)
    (step-physics (get-current-scene g))))

(define-method (set-verbose-logging! (g <Game>))
  (set! (slot-value g 'verbose-logging) #t))

(define-method (clear-verbose-logging! (g <Game>))
  (set! (slot-value g 'verbose-logging) #f))

(define-method (set-do-quit! (g <Game>))
  (set! (slot-value g 'do-quit) #t))

(define-method (clear-do-quit! (g <Game>))
  (set! (slot-value g 'do-quit) #f))

(define-method (set-window! (g <Game>))
  (when (null? (get-window g))
    (set!
      (slot-value g 'window)
      (sdl2:create-window!
        (get-title g)
        ; x
        'centered
        ; y
        100
        (get-window-width g)
        (get-window-height g)
        '(shown resizable)))
    (set-current-window-renderer! g (sdl2:create-renderer! (get-window g)))))

; children should really override this...
; as it stands now the would want their
; method to be called before:
(define-method (init! (g <Game>))
  (sdl2:set-main-ready!)
  (sdl2:init! '(video events joystick))
  (define img-init-successful-formats (img:init! '(jpg png tif)))
  (printf "img-init-successful-formats: ~A~%" img-init-successful-formats)

  (on-exit sdl2:quit!)

  ; does this even work when not run globally?
  (let ((original-handler (current-exception-handler)))
    (current-exception-handler
      (lambda (exception)
        (sdl2:quit!)
        (original-handler exception))))
  (set-window! g))

(define-method (clear-screen! (g <Game>))
  (set! (sdl2:render-draw-color (get-current-window-renderer g)) (sdl2:make-color 80 80 80))
  (sdl2:render-fill-rect! (get-current-window-renderer g) (sdl2:make-rect 0 0 1024 768)))

(define-method (run! (g <Game>))
  ; dt?
  (while (not (get-do-quit g))
    (let ((e (sdl2:wait-event!)))
      (when (get-verbose-logging g)
        (print e))
      (case (sdl2:event-type e)
        ;; Window exposed, resized, etc.
        ((window)
         (render-current-scene g))

        ;; User requested app quit (e.g. clicked the close button).
        ((quit)
         (set! done #t))
        ((key-down)
         (case (sdl2:keyboard-event-sym e)
           ;; Escape or Q quits the program
           ((escape q)
            (set-do-quit! g)))))

      (clear-screen! g)
      (feed-input-to-current-scene g e)
      (process-physics-for-current-scene g)
      (render-current-scene g)

      (sdl2:render-present! (get-current-window-renderer g))
    )
  )

  (printf "im actually going to do real work~%")
  (destroy! g))

(define-method (destroy! (g <Game>))
  (printf "loop through all my scenes and call destroy! on them.~%")
  (printf "they will call destroy! on all their game-objects~%")
  (printf "which will destroy all their children.~%")
  (sdl2:destroy-window! (get-window g))
  (img:quit!)
  (sdl2:quit!))

(define example
  (lambda ()
    (let ((g (make <Game>)))
      (set-window-width! g 1024)
      (set-window-height! g 768)
      (set-title! g "_test_game_")
      (init! g)
      (let ((first-scene (make <Scene>))
            (sprite (spr:<Sprite>-constructor 200 200 64 64 "ship.png" (get-current-window-renderer g))))
        (set-name! first-scene "_test_game_")
        (set-game-objects! first-scene (list sprite))
        (set-current-scene! g first-scene)
        (set-scenes! g (list first-scene))
        (run! g)))))
