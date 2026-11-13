;;;; =========================================================================
;;;; FILE: experiment.lisp
;;;; PURPOSE: Runs BOTH methods on one problem instance and prints the results.
;;;;
;;;;   1. build conflict graph        4. run Method B (genetic algorithm)
;;;;   2. run Method A (backtracking) 5. assign rooms to Method B's timetable
;;;;   3. assign rooms to its result  6. print the comparison table
;;;;
;;;; PROVIDES:   run-experiment-suite
;;;; DEPENDS ON: every file above this one in load.lisp
;;;; =========================================================================

(in-package #:exam-timetabling)

(defun run-experiment-suite (title exams slots rooms students
                             &key (slot-days nil) (seed (get-internal-real-time)))
  "Execute both methods on a given problem instance and report side-by-side results."
  (format t "~%########################################################################~%")
  (format t "  ~a~%" title)
  (format t "########################################################################~%")

  (let* ((conflicts (build-conflicts-from-students students)))
    (print-conflict-graph-summary exams conflicts)

    ;; Run Method A (Backtracking)
    (format t "~%>>> Running Method A: Backtracking with CSP Heuristics (MRV + LCV + FC)...~%")
    (let ((t0 (get-internal-real-time))
          bt-assign bt-effort bt-backtracks)
      (multiple-value-setq (bt-assign bt-effort bt-backtracks)
        (solve-backtracking exams slots conflicts :rooms rooms))
      (let* ((t1 (get-internal-real-time))
             (ms (* 1000.0 (/ (- t1 t0) internal-time-units-per-second)))
             (sol-a (make-timetable-solution
                     :method-name "Backtracking"
                     :success-p (not (null bt-assign))
                     :slot-assignment (or bt-assign (make-hash-table :test 'equal))
                     :search-effort bt-effort
                     :elapsed-ms ms)))

        (if bt-assign
            (progn
              (multiple-value-bind (cost hard soft)
                  (evaluate-solution bt-assign exams slots conflicts
                                     :slot-days slot-days :rooms rooms)
                (setf (timetable-solution-total-cost sol-a) cost
                      (timetable-solution-hard-violations sol-a) hard
                      (timetable-solution-soft-violations sol-a) soft))
              ;; Stage 2: Room assignment
              (multiple-value-bind (room-assign room-viols)
                  (assign-rooms bt-assign exams rooms)
                (setf (timetable-solution-room-assignment sol-a) room-assign)
                (format t "[Method A Result] Feasible Timetable Found in ~,2f ms (~a assignments, ~a backtracks)!~%"
                        ms bt-effort bt-backtracks)
                (when (> room-viols 0)
                  (format t "  Warning: ~a room capacity violations in Stage 2!~%" room-viols))
                (print-timetable-grid bt-assign room-assign exams slots rooms)))
            (format t "[Method A Result] NO SOLUTION EXISTS. Backtracking proved unsatisfiability in ~,2f ms (~a assignments, ~a backtracks).~%"
                    ms bt-effort bt-backtracks))

        ;; Run Method B (Genetic Algorithm)
        (format t "~%>>> Running Method B: Genetic Algorithm (Tournament + 1-Point Crossover + Elitism)...~%")
        (let ((t0-ga (get-internal-real-time))
              ga-assign ga-evals ga-gens ga-cost ga-hard ga-soft)
          (multiple-value-setq (ga-assign ga-evals ga-gens ga-cost ga-hard ga-soft)
            (run-genetic exams slots conflicts :slot-days slot-days :rooms rooms :seed seed))
          (let* ((t1-ga (get-internal-real-time))
                 (ms-ga (* 1000.0 (/ (- t1-ga t0-ga) internal-time-units-per-second)))
                 (sol-b (make-timetable-solution
                         :method-name "Genetic Algorithm"
                         :success-p (= ga-hard 0)
                         :slot-assignment ga-assign
                         :hard-violations ga-hard
                         :soft-violations ga-soft
                         :total-cost ga-cost
                         :search-effort ga-evals
                         :elapsed-ms ms-ga)))

            ;; Stage 2: Room assignment
            (multiple-value-bind (room-assign room-viols)
                (assign-rooms ga-assign exams rooms)
              (setf (timetable-solution-room-assignment sol-b) room-assign)
              (format t "[Method B Result] Completed ~a generations (~a evaluations) in ~,2f ms. Cost: ~a (Hard: ~a, Soft: ~a).~%"
                      ga-gens ga-evals ms-ga ga-cost ga-hard ga-soft)
              (when (> room-viols 0)
                (format t "  Warning: ~a room capacity violations in Stage 2!~%" room-viols))
              (print-timetable-grid ga-assign room-assign exams slots rooms))

            ;; Comparative Analysis
            (print-comparison-table sol-a sol-b)))))))
