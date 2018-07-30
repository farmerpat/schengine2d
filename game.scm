(use
  (prefix sdl2 sdl2:)
  (prefix sdl2-image img:)
  miscmacros
  coops
  debug
)

(cond-expand
  ((not compiling)
   (begin
     ; (require "scene.scm")
     (printf "not compiling~%")))
  (else))

;(declare (uses game-object))
(declare (unit game))

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
    (scenes initform: '())
    (window initform: '() reader: get-window)
    (current-window-renderer initform: #f reader: get-current-window-renderer writer: set-current-window-renderer)
    (verbose-logging initform: #f reader: get-verbose-logging)
  )
)

(define (<Game>-constructor #!optional (title "Schengine") (w 1024) (h 768) (scenes '()))
  (let ((g (make <Game>)))
    (set-window-width! g w)
    (set-window-height! g h)
    (set-title! g title)
    g
  )
)

(define-generic (set-verbose-logging!))
(define-generic (clear-verbose-logging!))
(define-generic (set-do-quit!))
(define-generic (clear-do-quit!))
(define-generic (set-window!))
(define-generic (init!))
(define-generic (run!))
(define-generic (destroy!))
(define-generic (feed-input-to-current-scene))
(define-generic (render-current-scene))
(define-generic (process-physics-for-current-scene g))

(define-method (render-current-scene (g <Game>)) '())
(define-method (feed-input-to-current-scene (g <Game>)) '())
(define-method (process-physics-for-current-scene (g <Game>)) '())

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
        '(shown resizable)))))

; children should really override this...
; as it stands now the would want their
; method to be called before:
(define-method (init! (g <Game>))
  (sdl2:set-main-ready!)
  (sdl2:init! '(video events joystick))
  (define img-init-successful-formats (img:init! '(jpg png tif)))
  (printf "img-init-successful-formats: ~A~%" img-init-successful-formats)

  (on-exit sdl2:quit!)

  (current-exception-handler
    (let ((original-handler (current-exception-handler)))
      (lambda (exception)
        (sdl2:quit!)
        (original-handler exception))))
  (set-window! g))

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

      ;; /home/pconnelly/hacks/Pengine2D/Pengine2D/Game.cpp
      ;; const Uint8 *keyStates = SDL_GetKeyboardState(NULL);

      ;; do some work on the scene
      (feed-input-to-current-scene g)
      (process-physics-for-current-scene g)
      (render-current-scene g)
    )
  )

  (printf "im actually going to do real work~%")
  (destroy! g)
)

(define-method (destroy! (g <Game>))
  (printf "loop through all my scenes and call destroy! on them.~%")
  (printf "they will call destroy! on all their game-objects~%")
  (printf "which will destroy all their children.~%")
  (sdl2:destroy-window! (get-window g))
  (img:quit!)
  (sdl2:quit!)
)
