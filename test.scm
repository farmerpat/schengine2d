; does this break it? it seemed more appropriate
; as i am guess that require-extension is a stronger
; stmt thant use...
; TODO: find out
;(require-extension sdl2 coops)
; having require-extension here is apparently the
; equivalent to using a -require-extension argument to csc

(use
  (prefix sdl2 sdl2:)
  (prefix sdl2-image img:)
  srfi-99
  miscmacros
  coops
)

(define-record-property invariant)
(define-record-property property-names)

(define OBJECT
  (make-rtd
    'object
    '#()
     #:property invariant #t
     #:property property-names
       (lambda (obj)
         (sort-symbols
           '(invariant property-names)))
  )
)

(define object? (rtd-predicate OBJECT))

(define (sort-symbols symlist)
  (sort
    symlist
    (lambda (x y)
      (string-ci<=? (symbol->string x) (symbol->string y)))
  )
)

(define-record-property get-pos)
(define-record-property set-pos!)

(define GAME_OBJECT
  (make-rtd
    'game-object
    '#((mutable pos))
    #:parent OBJECT
    #:property invariant
      (lambda (rt)
        (if (and
              (list? (get-pos rt))
              (= (length (get-pos rt)) 2)
              (number? (car (get-pos rt)))
              (number? (cadr (get-pos rt))))
          '(and
              (list? (get-pos rt))
              (= (length (get-pos rt)) 2)
              (number? (car (get-pos rt)))
              (number? (cadr (get-pos rt))))
          #f
        )
      )

    #:property get-pos 'pos
    #:property set-pos!
      (lambda (rt)
        (lambda (new-pos)
          (if (and
                (list? new-pos)
                (= (length new-pos) 2)
                (number? (car new-pos))
                (number? (cadr new-pos)))
            (set! (get-pos rt) new-pos)
            (error "list of two numbers expected" new-pos))))
  )
)

(define (GameObject pos)
  (let ((result ((rtd-constructor GAME_OBJECT) pos)))
    (if (invariant result)
      result
      (error 'GameObject "invariant broken"))))

(define (game-object? go)
  (and ((rtd-predicate GAME_OBJECT) go)
       (if (invariant go) #t #f)))

(define-record-printer (GAME_OBJECT rt out)
  (fprintf out "#(game-object pos: ~A~%)" (get-pos rt)))

(define go (GameObject '(200 200)))

(printf "go pos: ~A~%" (get-pos go))

(sdl2:set-main-ready!)
(sdl2:init! '(video events joystick))
(img:init! '(jpg png tif))

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

;;; Create a new window.
(define window
  (sdl2:create-window!
    "SDL Basics"                         ; title
    'centered  100                       ; x, y
    800  600                             ; w, h
    '(shown resizable)))                 ; flag

(define window-renderer (sdl2:create-renderer! window))

(define sprite-surface (img:load "ship.png"))
; must destroy after the fact...
(define sprite-texture (sdl2:create-texture-from-surface* window-renderer sprite-surface))

;; TODO: actually figure out the relationship between textures/surfaces/renders/window etc
(define (draw-scene!)
  (let ((window-surf (sdl2:window-surface window)))
    ;; Clear the whole screen using a grey background color
    ;(sdl2:fill-rect! window-surf #f (sdl2:make-color 80 80 80))

    (set! (sdl2:render-draw-color window-renderer) (sdl2:make-color 80 80 80))
    (sdl2:render-fill-rect! window-renderer (sdl2:make-rect 0 0 800 600))

    (let ((source-rect (sdl2:make-rect 0 0 64 64))
          (dest-rect (sdl2:make-rect 100 100 64 64)))
      (sdl2:render-copy! window-renderer sprite-texture source-rect dest-rect)
      ;(sdl2:render-copy! window-renderer sprite-texture)
    )

    (let ((rect (sdl2:make-rect 200 200 32 32)))
      ; set draw color...
      (set! (sdl2:render-draw-color window-renderer) (sdl2:make-color 0 0 0))
      (sdl2:render-fill-rect! window-renderer rect)
    )

    (sdl2:render-present! window-renderer)
    ;; global window...yucky
    ;(sdl2:update-window-surface! window)
  )
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
      )
    )
  )
)

(sdl2:destroy-texture! sprite-texture)
(sdl2:destroy-window! window)
(img:quit!)
; should be called automatically b/c (on-exit sdl2:quit!) above
;(sdl2:quit!)
