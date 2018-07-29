; apparently (declare (uses _)) are more for static linking...

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
       (require "game-object.scm")
       (require "sprite.scm")))
    (else))

(declare (uses game-object))
(declare (uses sprite))

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

(printf "Compiled with SDL version ~A~N" (sdl2:compiled-version))
(printf "Running with SDL version ~A~N" (sdl2:current-version))
(printf "Using sdl2 egg version ~A~N" (sdl2:egg-version))

(define window
  (sdl2:create-window!
    ; title
    "SDL Basics"
    ; x
    'centered
    ; y
    100
    ; w
    800
    ; h
    600
    ; flag
    '(shown resizable)
  )
)

(define window-renderer (sdl2:create-renderer! window))

(define debug? (make-parameter #t))

;(debug
(define ship-sprite (<Sprite>-constructor 200 200 64 64 "ship.png" window-renderer))
;)

(define (draw-scene!)
  (set! (sdl2:render-draw-color window-renderer) (sdl2:make-color 80 80 80))
  (sdl2:render-fill-rect! window-renderer (sdl2:make-rect 0 0 800 600))

  (let ((rect (sdl2:make-rect 500 500 32 32)))
    (set! (sdl2:render-draw-color window-renderer) (sdl2:make-color 0 0 0))
    (sdl2:render-fill-rect! window-renderer rect)
  )

  (render! ship-sprite window-renderer)
  (sdl2:render-present! window-renderer)
)

;;; Restrict the window from being made too small or too big, for no
;;; reason except to demonstrate this feature.
(set! (sdl2:window-maximum-size window) '(1024 768))
(set! (sdl2:window-minimum-size window) '(200 200))

(printf "Window position: ~A, size: ~A, max size: ~A, min size: ~A~N"
        (receive (sdl2:window-position window))
        (receive (sdl2:window-size window))
        (receive (sdl2:window-maximum-size window))
        (receive (sdl2:window-minimum-size window)))

(let ((done #f)
      (verbose? #f))
  (while (not done)
    (let ((ev (sdl2:wait-event!)))
      (when verbose?
        (print ev))
      (case (sdl2:event-type ev)
        ;; Window exposed, resized, etc.
        ((window)
         (draw-scene!))

        ;; User requested app quit (e.g. clicked the close button).
        ((quit)
         (set! done #t))
        ((key-down)
         (case (sdl2:keyboard-event-sym ev)
           ;; Escape or Q quits the program
           ((escape q)
            (set! done #t))))

        ;;; Joystick added (plugged in)
        ;((joy-device-added)
         ;;; Open the joystick so we start receiving events for it.
         ;(sdl2:joystick-open! (sdl2:joy-device-event-which ev)))

        ;;; Mouse button pressed
        ;((mouse-button-down)
         ;;; Move smiley1 to the mouse position.
         ;(set! (obj-x smiley1) (sdl2:mouse-button-event-x ev))
         ;(set! (obj-y smiley1) (sdl2:mouse-button-event-y ev))
         ;(draw-scene!))

        ;;; Mouse cursor moved
        ;((mouse-motion)
         ;;; If any button is being held, move smiley1 to the cursor.
         ;;; This way it seems like you are dragging it around.
         ;(when (not (null? (sdl2:mouse-motion-event-state ev)))
           ;(set! (obj-x smiley1) (sdl2:mouse-motion-event-x ev))
           ;(set! (obj-y smiley1) (sdl2:mouse-motion-event-y ev))
           ;(draw-scene!)))

        ;; Keyboard key pressed.
        ;((key-down)
         ;(case (sdl2:keyboard-event-sym ev)
           ;;; Escape or Q quits the program
           ;((escape q)
            ;(set! done #t))

           ;;; V toggles verbose printing of events
           ;((v)
            ;(if verbose?
              ;(begin
                ;(print "Verbose OFF (events will not be printed)")
                ;(set! verbose? #f))
              ;(begin
                ;(print "Verbose ON (events will be printed)")
                ;(set! verbose? #t))))

           ;;; Space bar randomizes smiley colors
           ;((space)
            ;(randomize-smiley! smiley1)
            ;(randomize-smiley! smiley2)
            ;(draw-scene!))

           ;;; Arrow keys control smiley2
           ;((left)
            ;(dec! (obj-x smiley2) 20)
            ;(draw-scene!))
           ;((right)
            ;(inc! (obj-x smiley2) 20)
            ;(draw-scene!))
           ;((up)
            ;(dec! (obj-y smiley2) 20)
            ;(draw-scene!))
           ;((down)
            ;(inc! (obj-y smiley2) 20)
            ;(draw-scene!))))
      )
    )
  )
)

; this fails when compiled...
(destroy! ship-sprite)
(sdl2:destroy-window! window)
(img:quit!)
(sdl2:quit!)
