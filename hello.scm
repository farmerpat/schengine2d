;(require-extension sdl2)
;(require-extension sdl2-image)
;(require-extension coops)
;(require-extension miscmacros)

(use
  (prefix sdl2 sdl2:)
  (prefix sdl2-image img:)
  miscmacros
  coops
  debug
)

; why is does this think its img:load if i declared a prefix up there?

;;; Initialize the parts of SDL that we need.
(sdl2:set-main-ready!)
(sdl2:init! '(video events joystick))
(define img-init-successful-formats (img:init! '(jpg png tif)))
(printf "img-init-successful-formats: ~A~%" img-init-successful-formats)

;; Automatically call sdl2:quit! when program exits normally.
(on-exit sdl2:quit!)

;; Call sdl2:quit! and then call the original exception handler if an
;; unhandled exception reaches the top level.
(current-exception-handler
  (let ((original-handler (current-exception-handler)))
    (lambda (exception)
      (sdl2:quit!)
      (original-handler exception))))

(printf "Compiled with SDL version ~A~N" (sdl2:compiled-version))
(printf "Running with SDL version ~A~N" (sdl2:current-version))
(printf "Using sdl2 egg version ~A~N" (sdl2:egg-version))

(load "classes.scm")

;;; Create a new window.
(define window
  (sdl2:create-window!
    "SDL Basics"                         ; title
    'centered  100                       ; x, y
    800  600                             ; w, h
    '(shown resizable)))                 ; flag

(printf "~A~%" window)

(define window-renderer (sdl2:create-renderer! window))

(define debug? (make-parameter #t))

;(debug
(define ship-sprite (<Sprite>-constructor 200 200 64 64 "ship.png" window-renderer))
;)

;(let ((surface (img:load (get-img-file-name ship-sprite))))
  ;(printf "letted surface: ~A~~%" surface)
  ;(set-surface! ship-sprite surface))

;(let ((texture (sdl2:create-texture-from-surface* (sdl2:get-renderer window) (get-surface ship-sprite))))
  ;(set-texture! ship-sprite texture))

;(printf "~A~%" ship-sprite)
;(printf "~A~%" (get-surface ship-sprite))
;(printf "~A~%" (get-texture ship-sprite))

(define (draw-scene!)
  (set! (sdl2:render-draw-color window-renderer) (sdl2:make-color 80 80 80))
  (sdl2:render-fill-rect! window-renderer (sdl2:make-rect 0 0 800 600))

  ;(let ((source-rect (sdl2:make-rect 0 0 64 64))
        ;(dest-rect (sdl2:make-rect 100 100 64 64)))
    ;(sdl2:render-copy! window-renderer sprite-texture source-rect dest-rect)
  ;)

  (let ((rect (sdl2:make-rect 500 500 32 32)))
    ; set draw color...
    (set! (sdl2:render-draw-color window-renderer) (sdl2:make-color 0 0 0))
    (sdl2:render-fill-rect! window-renderer rect)
  )

  (render! ship-sprite window-renderer)
  (sdl2:render-present! window-renderer)
)

;(define (draw-scene!)
  ;(let ((window-surf (sdl2:window-surface window)))
    ;;; Clear the whole screen using a blue background color
    ;(sdl2:fill-rect! window-surf #f (sdl2:make-color 0 80 160))
    ;;; Draw the smileys
    ;(draw-obj! smiley2 window-surf)
    ;(draw-obj! smiley1 window-surf)
    ;;; Refresh the screen
    ;(sdl2:update-window-surface! window))
  ;)

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

(destroy! ship-sprite)
(sdl2:destroy-window! window)
(img:quit!)
(sdl2:quit!)
