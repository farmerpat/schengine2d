;(declare (uses sprite))
;(declare (uses world))
;(declare (uses scene))
;(declare (unit game))

;; TODO: start processing game object children
; if we run csi from the same directory our .import.scm files are located
; for our project's modules, this will work as expected with ,l game.scm
(use
  ;(import chicken scheme)
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
  ;chipmunk
  physics
)

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
(define-record-property render-current-scene)
(define-record-property feed-input-to-current-scene)
(define-record-property process-physics-for-current-scene)

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
       (mutable do-quit))

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
        ;(set! (current-window-renderer rt) (sdl2:create-renderer! (window rt) -1 '(present-vsync)))))
              ;(sdl2:create-renderer! (window rt) -1 '(present-vsync))

    #:property game-init!
    (lambda (rt)
      (lambda ()
        (sdl2:set-main-ready!)
        (sdl2:init! '(video events joystick))
        (define img-init-successful-formats (img:init! '(jpg png tif)))
        (printf "img-init-successful-formats: ~A~%" img-init-successful-formats)
        ; what is this is can we have some kind of a global tear down
        ; that will destroy all pointers that register with it?
        ; that would be neato
        (on-exit sdl2:quit!)

        (let ((original-handler (current-exception-handler)))
         (current-exception-handler
           (lambda (exception)
             (sdl2:quit!)
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
          ; setting dt
          ;((process-physics-for-current-scene rt) dt)
          ((process-physics-for-current-scene rt) 0.0005)
          ((render-current-scene rt))
          (sdl2:render-present! (current-window-renderer rt))))
        ((shutdown-sdl! rt))))

    #:property shutdown-sdl!
    (lambda (rt)
      (lambda ()
        (sdl2:destroy-window! (window rt))
        (img:quit!)
        (sdl2:quit!)))
    )
  )

(define make-game
  (lambda ()
    ((rtd-constructor GAME)
     1024 768 "schengine" '()
     #f #f #f #f #f)))

(define example
  (lambda ()
    (let ((g (make-game)))
     (printf "did make things~%")
     ((title! g) "example_title")
     ((game-init! g))

     (let* ((world (make-world))
            (ship (make-game-object (vect:create 512 300)))
            (ship2 (make-game-object (vect:create 512 100)))
            (first-scene (make-scene "_test_scene_name_" '() world))
            (sprite (spr:make-sprite "ship.png" 64 64 (current-window-renderer g)))
            (sprite2 (spr:make-sprite "ship.png" 64 64 (current-window-renderer g)))
            (ship-body
              (make-boxed-dynamic-body
                world
                (* (*screen->chipmunk-factor*) 64)
                (* (*screen->chipmunk-factor*)  64)
                1

              )
            )
            (ship-body2
              (make-boxed-dynamic-body
                world
                (* (*screen->chipmunk-factor*) 64)
                (* (*screen->chipmunk-factor*)  64)
                10

              )
            )
            (ground (create-segment-shape
                      (space-static-body (space world))
                      (screen-pos->chipmunk-pos (vect:create 0.0 760.0))
                      (screen-pos->chipmunk-pos (vect:create 1024.0 760.0))
                      1.0))) ;;; thought the formerly 0 "radius" was throwing it..nah

       (printf "converted scaled 64: ~A~%" (* 64 (*screen->chipmunk-factor*)))
       (printf "converted p1: ~A~%" (screen-pos->chipmunk-pos (vect:create 0.0 760.0)))
       (printf "converted p2: ~A~%" (screen-pos->chipmunk-pos (vect:create 1024.0 760.0)))
       ; why not have #:property add-shape on world?
       ; don't wat to duplicate work, but still...
       (space-add-shape (space world) ground)
       (set! (shape-friction ground) 1.0)
       ;; these magic numbers have to be replaced
       ;; see if there are constants defined alreayd
       ;; in chicken-chipmunk, or just make my own
       ;; and stick them on world.
       (set! (shape-collision-type ground) 2)

       (set! (shape-friction (box-shape ship-body)) 0.3)
       (set! (shape-friction (box-shape ship-body2)) 0.5)
       (set! (shape-collision-type (box-shape ship-body)) 1)
       (set! (shape-collision-type (box-shape ship-body2)) 1)

       ;(dump-shape ground "ground")
       ;(dump-body (cp-body ship-body) "ship-body")
       ;(dump-shape (box-shape ship-body) "ship-body-shape")

       ((sprite! ship) sprite)
       ((sprite! ship2) sprite2)

       ((body! ship) ship-body #t)
       ((body! ship2) ship-body2 #t)

       (define ship-max-x 8.0)
       (define ship-min-x -8.0)

       (body-apply-force
         (cp-body ship-body)
         (vect:create 0.0 10.0)
         (vect:create 0.0 0.0))

       ;(display (space-collision-handlers (space world)))
       ;(newline)
       ; its seems less than ideal that the default
       ; behavior when two shapes, for which there is
       ; not an explicitly set handler for those two
       ; shape-collision-type(s), collide, the system
       ; barfs and dies.
       ; maybe it tries looking up a hash table entry
       ; and it just fails when it can't find one.
       ; if so, I could change it to supply defaults
       ; that are just (lambda (a b) #t). returning
       ; #t allows the default behavior to take place
       ; (e.g. whatever then engine would normally do)
       ; ...or some such thing
       (space-add-collision-handler
         (space world)
         1
         1
         ; collision begin
         (lambda (a b ) #t)
         ; presolve
         (lambda (a b) #t)
         ; postsolve
         (lambda (a b) #t)
         ; separate-func
         (lambda (a b) #t))

       (space-add-collision-handler
         (space world)
         1
         2
         ; collision begin
         (lambda (a b ) #t)
         ; presolve
         (lambda (a b) #t)
         ; postsolve
         (lambda (a b) #t)
         ; separate-func
         (lambda (a b) #t))

       ;((event-handler! ship)
        ;(lambda (e)
          ;(case (sdl2:event-type e)
            ;((key-down)
             ;(begin ;;(display (sdl2:keyboard-event-sym e))
                    ;;;(newline)
                    ;(case (sdl2:keyboard-event-sym e)
                      ;((left a)
                       ;(begin
                         ;;; will have to call
                         ;;; body-reset-forces or
                         ;;; something on all the
                         ;;; bodies somewhere
                         ;;; we shouldn't be applying force
                         ;;; if its velocity is over a maximum
                         ;(let ((current-x-vel (vect:x (body-force (cp-body ship-body)))))
                          ;; e.g. -4 > -8
                          ;(when (> current-x-vel ship-min-x)
                            ;;; as we approach ship-min-x, we should taper this...
                            ;(let ((x-force (+ ship-min-x (abs current-x-vel))))
                             ;(body-apply-force
                               ;(cp-body ship-body)
                               ;(vect:create x-force 0.0)
                               ;(vect:create 0.0 0.0)))))))
                      ;((right d)
                       ;(begin
                         ;(body-apply-force
                           ;(cp-body ship-body)
                           ;(vect:create 4.0 0.0)
                           ;(vect:create 0.0 0.0)))))))
            ;((key-up)
             ;(begin
               ;(case (sdl2:keyboard-event-sym e)
                 ;((left a)
                  ;(begin
                    ;(display "left release")
                    ;(newline)

                    ;;(display "force before reset-forces: ")
                    ;;(display (body-force (cp-body ship-body)))
                    ;;(newline)
                    ;(body-reset-forces (cp-body ship-body))
                    ;;(display "force after reset-forces: ")
                    ;;(display (body-force (cp-body ship-body)))
                    ;;(newline)

                    ;))
                 ;((right d)
                  ;(begin
                    ;(display "right release")
                    ;(newline)
                    ;;; what if we make x the opposite of what it is now?
                    ;(let ((new-x (* -1 (vect:x (body-velocity (cp-body ship-body))))))
                     ;(printf "new-x: ~A~%" new-x)
                     ;(body-reset-forces (cp-body ship-body))
                     ;(body-apply-force
                       ;(cp-body ship-body)
                       ;;(vect:create -4.0 0.0)
                       ;(vect:create new-x 0.0)
                       ;(vect:create 0.0 0.0)))
                    ;))))))))

       ((game-objects! first-scene) (list ship ship2))
       (set! (current-scene g) first-scene)
       ((scenes! g) (list first-scene))

       ;; lets try a collision handler...
       ((add-collision-handler! world) (lambda (args) (display "fyf")(newline)))
       ((run! g))))))

(define (dump-body b title)
  (printf "~%")
  (printf "Dumping Body ~A~%" title)
  (printf "body ~A~%" b)
  (printf "body-mass: ~A~%" (body-mass b))
  (printf "body-moment ~A~%" (body-moment b))
  (printf "body-velocity ~A~%" (body-velocity b))
  (printf "body-force ~A~%" (body-force b))
  (printf "body-angle: ~A~%" (body-angle b))
  ; broken in chicken-chipmunk.. references cpBodyGetAngleVel
  ; instead of cpBodyGetAngularVelocity
  ; TODO: fix it.
  ;(printf "body-angle-velocity: ~A~%" (body-angle-velocity b))
  (printf "body-torque: ~A~%" (body-torque b))
  (printf "body-rotation: ~A~%" (body-rotation b))
  (printf "body-velocity-limit: ~A~%" (body-velocity-limit b))
  (printf "body-angular-velocity-limit: ~A~%" (body-angular-velocity-limit b))

  ; this is a segmentation violation for some reason
  ;(printf "body-space: ~A~%" (body-space b))
  (printf "~%"))

(define (dump-shape s title)
  (printf "~%")
  (printf "Dumping Shape ~A~%" title)
  (printf "shape ~A~%" s)
  (printf "shape-body: ~A~%" (shape-body s))
  (printf "shape-bb: ~A~%" (shape-bb s))
  (printf "shape-sensor: ~A~%" (shape-sensor s))
  (printf "shape-elasticity: ~A~%" (shape-elasticity s))
  (printf "shape-friction: ~A~%" (shape-friction s))
  (printf "shape-surface-velocity: ~A~%" (shape-surface-velocity s))
  (printf "shape-collision-type: ~A~%" (shape-collision-type s))
  (printf "shape-group: ~A~%" (shape-group s))
  (printf "shape-layers: ~A~%" (shape-layers s))
  (printf "~%"))

(example)
