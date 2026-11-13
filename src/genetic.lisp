;;;; =========================================================================
;;;; FILE: genetic.lisp
;;;; PURPOSE: METHOD B - genetic algorithm (seedable stochastic search).
;;;;            chromosome : one slot per exam
;;;;            fitness    : the cost function (lower is better)
;;;;            selection  : tournament (k=3)
;;;;            crossover  : single point
;;;;            mutation   : random slot reassignment per exam
;;;;            elitism    : the best timetable always survives
;;;;
;;;; PROVIDES:   run-genetic
;;;; DEPENDS ON: utils.lisp (get-hash-keys, copy-hash),
;;;;             evaluation.lisp (evaluate-solution)
;;;; =========================================================================

(in-package #:exam-timetabling)

(defun run-genetic (exams slots conflicts
                    &key (pop-size 60)
                         (generations 150)
                         (mutation-rate 0.15)
                         (crossover-rate 0.85)
                         (slot-days nil)
                         (rooms nil)
                         (seed (get-internal-real-time)))
  "Method B (Section 4.4):
   Genetic Algorithm for exam timetabling:
   - Chromosome: Assignment of each exam to a time slot.
   - Cost Function: Whard * hard + Wsoft * soft (lower is fitter).
   - Selection: Tournament Selection (k=3).
   - Crossover: Single-point crossover.
   - Mutation: Gene-wise random slot reassignment.
   - Elitism: Best timetable survives to the next generation.
   - Seed: pass an integer to reproduce the same stochastic search."
  (unless (and (integerp pop-size) (> pop-size 0))
    (error "Population size must be a positive integer."))
  (unless (and (integerp generations) (> generations 0))
    (error "Generation count must be a positive integer."))
  (unless (and (realp mutation-rate) (<= 0 mutation-rate 1)
               (realp crossover-rate) (<= 0 crossover-rate 1))
    (error "Mutation and crossover rates must be between 0 and 1."))
  (when (and (plusp (hash-table-count exams)) (zerop (hash-table-count slots)))
    (error "Cannot run the genetic algorithm with exams but no time slots."))
  (let* ((slot-keys (sort (get-hash-keys slots) #'<))
         (exam-keys (sort (get-hash-keys exams) #'string<))
         (num-exams (length exam-keys))
         (population '())
         (total-evaluations 0)
         (gen-reached 0)
         (random-value (make-random-source seed)))

    (when (zerop num-exams)
      (return-from run-genetic
        (values (make-hash-table :test 'equal) 0 0 0 0 0)))

    ;; 1. Initialize random population
    (dotimes (i pop-size)
      (let ((ind (make-hash-table :test 'equal)))
        (dolist (e exam-keys)
          (setf (gethash e ind) (nth (funcall random-value (length slot-keys)) slot-keys)))
        (push ind population)))

    (labels
        ((eval-ind (ind)
           (incf total-evaluations)
           (multiple-value-bind (cost hard soft)
               (evaluate-solution ind exams slots conflicts
                                  :slot-days slot-days :rooms rooms)
             (list ind cost hard soft)))

         (tournament (scored-pop)
           (let* ((k 3)
                  (candidates (loop repeat k collect
                                    (nth (funcall random-value (length scored-pop)) scored-pop))))
             ;; Lowest cost wins tournament
             (car (reduce (lambda (c1 c2)
                            (if (< (second c1) (second c2)) c1 c2))
                          candidates))))

         (crossover (p1 p2)
           (if (< (funcall random-value 1.0) crossover-rate)
               (let ((child (make-hash-table :test 'equal))
                     (cut (1+ (funcall random-value (max 1 (1- num-exams))))))
                 (loop for i from 0
                       for e in exam-keys
                       do (setf (gethash e child)
                                (if (< i cut)
                                    (gethash e p1)
                                    (gethash e p2))))
                 child)
               (copy-hash p1)))

         (mutate (ind)
           (let ((mutated (copy-hash ind)))
             (dolist (e exam-keys)
               (when (< (funcall random-value 1.0) mutation-rate)
                 (setf (gethash e mutated)
                       (nth (funcall random-value (length slot-keys)) slot-keys))))
             mutated)))

      (dotimes (gen generations)
        (setf gen-reached (1+ gen))
        (let ((scored (mapcar #'eval-ind population)))
          ;; Sort population by cost ascending
          (setf scored (sort scored #'< :key #'second))

          (let ((best (first scored)))
            ;; If zero hard violations and zero soft violations, terminate early
            (when (and (= (third best) 0) (= (fourth best) 0))
              (return-from run-genetic
                (values (first best) total-evaluations gen-reached (second best) (third best) (fourth best))))

            ;; Elitism + Reproduction
            (let ((new-pop (list (first best))))
              (loop while (< (length new-pop) pop-size) do
                (let* ((p1 (tournament scored))
                       (p2 (tournament scored))
                       (child (mutate (crossover p1 p2))))
                  (push child new-pop)))
              (setf population new-pop)))))

      ;; Return best individual from final generation
      (let* ((final-scored (sort (mapcar #'eval-ind population) #'< :key #'second))
             (best (first final-scored)))
        (values (first best) total-evaluations gen-reached (second best) (third best) (fourth best))))))
