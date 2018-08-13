(module schengine-util *
  (import chicken scheme)
  (use 2d-primitives)

  (declare (unit schengine-util))
  ; create a procedure to update these.
  ; it could be called by a handler
  ; added to the window resize event.
  ; that seems hairy...
  (define *conversion-scale* (make-parameter 125.0))

  (define *half-screen-width* (make-parameter 512))
  (define *half-screen-height* (make-parameter 384))
  (define *screen->chipmunk-factor* (make-parameter (/ 1 (*conversion-scale*))))
  (define *chipmunk->screen-factor* (make-parameter (*conversion-scale*)))

  (define (screen-pos->chipmunk-pos screen-pos)
    (let* ((old-x (vect:x screen-pos))
           (old-y (vect:y screen-pos))
           (new-x 0)
           (new-y 0))
      (cond ((> old-x (*half-screen-width*))
             (set! new-x (- old-x (*half-screen-width*))))
            ((< old-x (*half-screen-width*))
             (set! new-x (* -1.0 (- (*half-screen-width*) (abs old-x))))))

      (cond ((> old-y (*half-screen-height*))
             (set! new-y (* -1 (- old-y (*half-screen-height*)))))
            ((< old-y (*half-screen-height*))
             (set! new-y (- (*half-screen-height*) old-y))))

      (vect:create
        (* (*screen->chipmunk-factor*) new-x)
        (* (*screen->chipmunk-factor*) new-y))))

  (define (chipmunk-pos->screen-pos screen-pos) '())
)
