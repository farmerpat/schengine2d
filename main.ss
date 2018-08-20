(import (chezscheme)
        (sdl2))

(define *quit* (make-parameter #f))

(sdl-library-init)
(define retval  (sdl-init (sdl-initialization 'video 'events)))

(define window (sdl-create-window "test" 50 50 800 600 (sdl-window-flags 'shown)))

(define renderer (sdl-create-renderer window -1 (sdl-renderer-flags 'accelerated)))
(define bmp-surface (sdl-load-bmp "ship.bmp"))
(define img-texture (sdl-create-texture-from-surface renderer bmp-surface))

(define gen-rect
  (case-lambda
    ((gw gh) (gen-rect 0 0 gw gh))
    ((gx gy gw gh)
     (new-struct sdl-rect-t (x gx) (y gy) (w gw) (h gh)))))

(define src-rect
  (gen-rect 64 64))

(define dest-rect
  (gen-rect 200 200 64 64))

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

;; does this become get-event-kbd-event ?
;; it think it does.
;; as mentioned above, figure out how to
;; auto-generate this stuff as soon as possible.
(define (get-kbd-event event)
  (ftype-&ref sdl-event-t (key) event))

;; same as type in parent sdl-event-t
(define (get-kbd-event-type kbd-event-ptr)
  (ftype-ref sdl-keyboard-event-t (type) kbd-event-ptr))

;; sdl-keysym-t
(define (get-kbd-event-keysym kbd-event-ptr)
  (ftype-&ref sdl-keyboard-event-t (keysym) kbd-event-ptr))

(define (get-keysym-key-code ksm)
  (ftype-&ref sdl-keysym-t (sym) ksm))

(define (get-keysym-scancode ksm)
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

(define (generate-kbd-code-predicate sym)
  (lambda (kbd-event)
    (let* ((ksym (get-kbd-event-keysym kbd-event))
           (key-code-ptr (get-keysym-key-code ksym))
           (code (ftype-ref int () key-code-ptr)))
      (if (eq? (sdl-keycode sym) code) #t #f))))

(define kbd-event-code-escape? (generate-kbd-code-predicate 'escape))

(define (esc-key-handler event)
  (when (is-key-down-event? event)
    (let ((kbe (get-kbd-event event)))
     (if (ftype-pointer? kbe)
         (if (kbd-event-code-escape? kbe)
             (*quit* #t))))))

(register-event-handler esc-key-handler)

(let game-loop ()
 (sdl-render-copy renderer img-texture src-rect dest-rect)
 (sdl-render-present renderer)
 (sdl-poll-event event)
 (pass-event-to-event-handlers event)

 (if (not (*quit*))
     (game-loop)))

(sdl-destroy-window window)
(sdl-destroy-texture img-texture)
(sdl-destroy-renderer renderer)
(sdl-quit)

(scheme-start (lambda fns '()))
