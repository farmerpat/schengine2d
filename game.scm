
;; TODO: start processing game object children
; if we run csi from the same directory our .import.scm files are located
; for our project's modules, this will work as expected with ,l game.scm
(module game *
  (import chicken scheme)
  (use
    (prefix sdl2 sdl2:)
    (prefix sdl2-image img:)
    (prefix sprite spr:)
    srfi-99
    miscmacros
    debug
    game-object
    sprite
    scene
    2d-primitives
    world
    boxed-dynamic-body
    schengine-util
    physics
    extras
  )

  (declare (uses game-object))
  (declare (uses sprite))
  (declare (uses scene))
  (declare (uses world))
  (declare (unit game))

  (define-record-property window-width)
  (define-record-property window-width!)
  (define-record-property window-height)
  (define-record-property window-height!)
  (define-record-property title)
  (define-record-property title!)
  (define-record-property scenes)
  (define-record-property scenes!)
  (define-record-property window)
  (define-record-property current-window-renderer)
  (define-record-property current-scene)
  (define-record-property verbose-logging)
  (define-record-property set-verbose-logging!)
  (define-record-property clear-verbose-logging!)
  (define-record-property do-quit)
  (define-record-property set-do-quit!)
  (define-record-property clear-do-quit!)
  (define-record-property init-window!)
  (define-record-property game-init!)
  (define-record-property clear-screen!)
  (define-record-property run!)
  ; this name is clobbering other names, and that needs to be dealt with
  (define-record-property shutdown-sdl!)
  (define-record-property shutdown-current-scene!)
  (define-record-property render-current-scene)
  (define-record-property feed-input-to-current-scene)
  (define-record-property process-physics-for-current-scene)
  (define-record-property exit-handler)
  (define-record-property exit-handler-called)
  (define-record-property set-exit-handler-called!)
  (define-record-property clear-exit-handler-called!)

  (define *old-ticks* (make-parameter 0))

  (define (tick!)
    (let* ((new-ticks (sdl2:get-ticks))
           (dt (/ (- new-ticks (*old-ticks*)) 1000)))
      (*old-ticks* new-ticks)
      dt))

  (define GAME
    (make-rtd
      'game
      '#((mutable window-width)
         (mutable window-height)
         (mutable title)
         (mutable scenes)
         (mutable window)
         (mutable current-window-renderer)
         (mutable current-scene)
         (mutable verbose-logging)
         (mutable do-quit)
         (mutable exit-handler-called))

      ; consider changing all these rts to
      ; the record type name or something...
      #:property window-width 'window-width
      #:property window-width!
      (lambda (rt)
        (lambda (new-window-width)
          ; might validate if window has been initialized yet
          ; and refuse to allow change if so...
          (set! (window-width rt) new-window-width)))

      #:property window-height 'window-height
      #:property window-height!
      (lambda (rt)
        (lambda (new-window-height)
          ; might validate if window has been initialized yet
          ; and refuse to allow change if so...
          (set! (window-height rt) new-window-height)))

      #:property title 'title
      #:property title!
      (lambda (rt)
        (lambda (new-title)
          (set! (title rt) new-title)))

      #:property scenes 'scenes
      #:property scenes!
      (lambda (rt)
        (lambda (new-scenes)
          (if (list? new-scenes)
              (set! (scenes rt) new-scenes))))

      #:property window 'window
      #:property current-window-renderer 'current-window-renderer
      #:property current-scene 'current-scene
      #:property verbose-logging 'verbose-logging

      #:property set-verbose-logging!
      (lambda (rt)
        (lambda ()
          (set! (verbose-logging rt) #t)))

      #:property clear-verbose-logging!
      (lambda (rt)
        (lambda ()
          (set! (verbose-logging rt) #f)))

      #:property do-quit 'do-quit

      #:property set-do-quit!
      (lambda (rt)
        (lambda ()
          (set! (do-quit rt) #t)))

      #:property clear-do-quit!
      (lambda (rt)
        (lambda ()
          (set! (do-quit rt) #f)))

      #:property exit-handler-called 'exit-handler-called
      #:property set-exit-handler-called!
      (lambda (rt)
        (lambda ()
          (set! (exit-handler-called rt) #t)))

      #:property clear-exit-handler-called!
      (lambda (rt)
        (lambda ()
          (set! (exit-handler-called rt) #f)))

      #:property render-current-scene
      (lambda (rt)
        (lambda ()
          (when (scene? (current-scene rt))
            ((render-game-objects! (current-scene rt))
             (current-window-renderer rt)))))

      #:property feed-input-to-current-scene
      (lambda (rt)
        (lambda (e)
          (if (scene? (current-scene rt))
              ((pass-event-to-game-objects! (current-scene rt)) e))))

      #:property process-physics-for-current-scene
      (lambda (rt)
        (lambda (dt)
          (when (scene? (current-scene rt))
            ((step-physics (current-scene rt)) dt)
            ((update-game-object-bodies! (current-scene rt))))))

      #:property init-window!
      (lambda (rt)
        (lambda ()
          (set!
            (window rt)
            (sdl2:create-window!
              (title rt)
              'centered
              100
              (window-width rt)
              (window-height rt)
              '(shown resizable)))
          (set! (current-window-renderer rt) (sdl2:create-renderer! (window rt)))))
          ;(set! (current-window-renderer rt) (sdl2:create-renderer! (window rt) -1 '(present-vsync)))

      #:property game-init!
      (lambda (rt)
        (lambda ()
          (sdl2:set-main-ready!)
          (sdl2:init! '(video events joystick))
          (define img-init-successful-formats (img:init! '(jpg png tif)))
          (printf "img-init-successful-formats: ~A~%" img-init-successful-formats)
          (on-exit (exit-handler rt))

          (let ((original-handler (current-exception-handler)))
           (current-exception-handler
             (lambda (exception)
               (when (not (exit-handler-called rt))
                 ((set-exit-handler-called! rt))
                 ((exit-handler rt)))
               (original-handler exception))))

          ((init-window! rt))))

      ; this should obviously be more flexible
      #:property clear-screen!
      (lambda (rt)
        (lambda ()
          (set!
            (sdl2:render-draw-color (current-window-renderer rt))
            (sdl2:make-color 80 80 80))
          (sdl2:render-fill-rect!
            (current-window-renderer rt)
            (sdl2:make-rect 0 0 1024 768))))

      #:property run!
      (lambda (rt)
        (lambda ()
          (*old-ticks* (sdl2:get-ticks))

          (while (not (do-quit rt))
           (let (;(e (sdl2:wait-event!))
                 ; maybe this should be after event processing?
                 (dt (tick!)))

             (sdl2:pump-events!)
             (while (sdl2:has-events?)
               (let ((e (sdl2:poll-event!)))
                (case (sdl2:event-type e)
                  ((window)
                  ((render-current-scene rt)))
                  ((quit)
                   ((set-do-quit! rt)))
                  ((key-down)
                   (case (sdl2:keyboard-event-sym e)
                     ((escape q)
                      ((set-do-quit! rt))))))
                ;; this seems like the place for this...make sure
                ((feed-input-to-current-scene rt) e)
                (when (verbose-logging rt)
                  (print e))))

            ((clear-screen! rt))
            ; we can control overall speed by
            ; setting dt...iirc chipmunk recommends it
            ;((process-physics-for-current-scene rt) dt)
            ((process-physics-for-current-scene rt) 0.001)
            ((render-current-scene rt))
            (sdl2:render-present! (current-window-renderer rt))))
          ((exit-handler rt))))

      #:property shutdown-sdl!
      (lambda (rt)
        (lambda ()
          (sdl2:destroy-window! (window rt))
          (img:quit!)
          (sdl2:quit!)))

      #:property exit-handler
      (lambda (rt)
        (lambda ()
          (when (not (exit-handler-called rt))
            ((shutdown-current-scene! rt))
            ((shutdown-sdl! rt))
            ((set-exit-handler-called! rt)))))

      #:property shutdown-current-scene!
      (lambda (rt)
        (lambda ()
          (if (scene? (current-scene rt))
              ((destroy-game-objects! (current-scene rt))))))))

  (define make-game
    (lambda ()
      ((rtd-constructor GAME)
       1024 768 "schengine" '()
       #f #f #f #f #f #f)))
)
