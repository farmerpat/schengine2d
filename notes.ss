;; note to self:
;; (eval-when (compile load eval)
;; ...)
;; is a thing.

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

;; define a piece of syntax that creates
;; these predicates for every sdl-*-t
;; its given, as a list.
;; in general, I could create a series
;; of macros that create wrappers
;; around all this gross foreign- stuff
(define (sdl-common-event-t? ob)
  (and (ftype-pointer? ob)
       (ftype-pointer? sdl-common-event-t ob)))

;; think about ways of abstracting or generalizing
;; event types and their handlers
