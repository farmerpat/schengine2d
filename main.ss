(import (chezscheme)
        (sdl2))

;; move all this stuff to "scratch.lisp" or something
;; these generators return prcedures that can tag a variable number of
;; arguments, the first of which must be a symbol, which specifies what
;; the caller would like of the "object"
;; .. e.g.
;(define go (generate-game-object 300 300 (generate-sprite "ship.png" 64 64)))
;(display (go 'g-pos)) ; get the position of x
;(display (go 'g-sprite)) ; get the sprite of x, if it has one.
;(go 's-sprite (generate-hero-sprite))
;> (go 'type)
;'game-object

;; predicate defined for convenience
;; e.g.
;;(define (game-object? ob)
  ;;(eq? (ob 'type) 'game-object))
;(game-object? go)
;#t
;(define bullet (generate-game-object 300 300 (generate-sprite "bullet.png" 3 30)))

;(define (generate-bullet-sprite)
  ;(generate-sprite "bullet.png" 3 30))

;(define (generate-bullet pos)
  ;(generate-game-object pos (generate-bullet-sprite)))

; etc..

;; could also add macros like
;;  ; or set me in with-sdl before with-window...
;; like maybe with-sdl defines all that stuff in local scope...
;; _ will be ignored. we just don't want
;; to break convention of first argument becoming
;; a symbol to be used by expressions inside its body...
;(with-sdl (_ flags-specified-above) ;; (sdl-library-init)
  ;(with-window-params ; could be used be other macros like (with-my-specific-params...
    ;(*window-title* "my title!")
    ;(with-window (window);;(sdl-create-window (*window-title*) ...)
      ;(with-other-things...))))

;; all of these ideas came about because i started asking myself
;; different questions. I asked mysql "what kind of a language
;; do you want to write a game in?"

; thunderchez/ffi-utils.scm line 130 for great example
; (sdl-window-flags) => 0
; (sdl-window-flags 'opengl) => 2

(define *quit* (make-parameter #f))

(sdl-library-init)
(define retval  (sdl-init (sdl-initialization 'video 'events)))
(display retval)
(newline)

(define window (sdl-create-window "test" 50 50 800 600 (sdl-window-flags 'shown)))

(display "window: ")
(display window)
(newline)

(define renderer (sdl-create-renderer window -1 (sdl-renderer-flags 'accelerated)))
(define bmp-surface (sdl-load-bmp "ship.bmp"))
(define img-texture (sdl-create-texture-from-surface renderer bmp-surface))

(display "renderer: ")
(display renderer)
(newline)
(display "bmp-surface: ")
(display bmp-surface)
(newline)
(display "img-texture: ")
(display img-texture)
(newline)

;; make syntax (gen-rect x y w h) or something.
;; this is a lot of typing.
(define gen-rect
  (case-lambda
    ((gw gh) (gen-rect 0 0 gw gh))
    ((gx gy gw gh)
     (new-struct sdl-rect-t (x gx) (y gy) (w gw) (h gh)))))

(define src-rect
  (gen-rect 64 64))

(define dest-rect
  (gen-rect 200 200 64 64))

(display "src-rect: ")
(display src-rect)
(newline)
(display "dest-rect: ")
(display dest-rect)
(newline)

;(define (event-loop)
  ;(sdl-poll-event)
  ;(cond
   ;((sdl-event-none?) '())
   ;((sdl-event-quit?) (*quit* #t))
   ;((sdl-event-drop-text?) (printf (sdl-event-drop-file))
                           ;(event-loop))
   ;((sdl-event-key-down? SDLK-Q) (*quit* #t))
   ;((sdl-event-key-down? SDLK-ESCAPE) (*quit* #t))
   ;(else (event-loop))))

;(*quit* #t)

(define (sdl-common-event-t? ob)
  (and (ftype-pointer? ob)
       (ftype-pointer? sdl-common-event-t ob)))

(define (sdl-event-t? ob)
  (and (ftype-pointer? ob)
       (ftype-pointer? sdl-event-t ob)))

(define event
  (new-struct sdl-event-t))

(define (get-type event)
  (if (ftype-pointer? event)
      (ftype-ref sdl-event-t (type) event)))

(define (get-type-symbol event)
  (if (ftype-pointer? event)
      (sdl-event-type-ref (get-type event))))

(define (is-window-event? event)
  (eq? 'windowevent (get-type-symbol event)))

(define (is-quit-event? event)
  (eq? 'quit (get-type-symbol event)))

(define (is-key-down-event? event)
  (eq? 'keydown (get-type-symbol event)))

(define (is-key-up-event? event)
  (eq? 'keyup (get-type-symbol event)))

(define (get-kbd-event event)
  (ftype-&ref sdl-event-t (key) event))

;; same as type in parent sdl-event-t
(define (get-kbd-event-type kbd-event-ptr)
  (ftype-ref sdl-keyboard-event-t (type) kbd-event-ptr))

;; sdl-keysym-t
(define (get-keysym kbd-event-ptr)
  (ftype-&ref sdl-keyboard-event-t (keysym) kbd-event-ptr))

(define (keysym-get-key-code ksm)
  (ftype-&ref sdl-keysym-t (sym) ksm))

(define (keysym-get-scancode ksm)
  (ftype-&ref sdl-keysym-t (scancode) ksm))

(define *event-handlers* (make-parameter '()))

(define (register-event-handler eh)
  (*event-handlers* (cons eh (*event-handlers*))))

(define (call-all-with-arg lst arg)
  (cond ((null? lst) '())
        ((procedure? (car lst))
         ((car lst) arg)
         (call-all-with-arg (cdr lst) arg))))

(define (pass-event-to-event-handlers event)
  (call-all-with-arg (*event-handlers*) event))

(define (q-key-handler event)
  (if (is-key-down-event? event)
      (begin
        (display "thats key down!")
        (*quit* #t))))

(register-event-handler q-key-handler)

;; think about ways of abstracting or generalizing
;; event types and

;(define (get-key event)
  ;(if (ftype-pointer? event)
      ;(ftype-&ref sdl-keyboard-event-t (key) event)))

      ;(ftype-ref sdl-keyboard-event-t (key) event)

(let loop ()

 ;(el)
 ;; these rects...
 (sdl-render-copy renderer img-texture src-rect dest-rect)
 (sdl-render-present renderer)
 (sdl-poll-event event)

;; > (ftype-ref sdl-event-t (type) event)
;;512
;; > (ftype-&ref sdl-event-t (common) event)
;;#<ftype-pointer sdl-common-event-t 94049724148464>
;; > (ftype-ref sdl-common-event-t (ftype-&ref sdl-event-t (common) event))
;; > (define my-event-common (ftype-&ref sdl-event-t (common) event))
;; > (ftype-pointer? sdl-common-event-t my-event-common)
;;#t
;; > (ftype-ref sdl-common-event-t (type) my-event-common)
;;512
;;
;;(eq? 'windowevent (get-type-symbol event))

 ;(error "new_test.ss" "Eaauugh!" "i'm the irritant!")
 ;(sdl-delay 10000)
 ;; delay 500 ?

 (pass-event-to-event-handlers event)

 (if (not (*quit*)) (loop)))

(sdl-destroy-window window)
(sdl-destroy-texture img-texture)
(sdl-destroy-renderer renderer)
(sdl-quit)

(scheme-start (lambda fns '()))
