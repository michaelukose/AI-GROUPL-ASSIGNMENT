;;;; =========================================================================
;;;; FILE: backtracking.lisp
;;;; PURPOSE: METHOD A - exact search. Backtracking with CSP heuristics:
;;;;            MRV   - pick the exam with the fewest legal slots left
;;;;            Degree- break ties by most clashes with unassigned exams
;;;;            LCV   - try the slot that rules out the fewest options for neighbours
;;;;            FC    - forward checking: prune neighbours' slots, fail early
;;;;          Finds a clash- and room-feasible timetable, or proves none exists.
;;;;
;;;; PROVIDES:   solve-backtracking, *bt-assignments*, *bt-backtracks*
;;;; DEPENDS ON: utils.lisp (get-hash-keys, copy-hash),
;;;;             conflict-graph.lisp (get-exam-neighbors)
;;;; =========================================================================

(in-package #:exam-timetabling)

(defvar *bt-assignments* 0 "Global counter for attempted variable assignments")
(defvar *bt-backtracks* 0 "Global counter for backtrack events")

(defun solve-backtracking (exams slots conflicts &key (rooms nil))
  "Method A (Section 4.3):
   Backtracking search with CSP heuristics:
   1. Minimum Remaining Values (MRV): Pick unassigned exam with fewest legal slots.
   2. Degree Heuristic Tie-Breaker: Break ties by picking exam with most conflicts to unassigned exams.
   3. Least Constraining Value (LCV): Try slots that eliminate the fewest choices for neighbors.
   4. Forward Checking (FC): Prune conflicting slots and room-infeasible domains."
  (setf *bt-assignments* 0)
  (setf *bt-backtracks* 0)
  (let* ((assignment (make-hash-table :test 'equal))
         (domains (make-hash-table :test 'equal))
         (slot-keys (sort (get-hash-keys slots) #'<))
         (exam-keys (sort (get-hash-keys exams) #'string<)))

    ;; Initialize domains for all exams with all available time slots
    (dolist (e exam-keys)
      (setf (gethash e domains) (copy-list slot-keys)))

    (labels
        ((unassigned-exams (assign)
           (remove-if (lambda (k) (gethash k assign)) exam-keys))

         (unassigned-degree (e assign)
           (count-if (lambda (neigh) (null (gethash neigh assign)))
                     (get-exam-neighbors e conflicts)))

         (select-mrv-variable (assign doms)
           "Select next exam using MRV and Degree heuristic tie-breaker."
           (let ((unassigned (unassigned-exams assign)))
             (reduce
              (lambda (e1 e2)
                (let ((d1 (length (gethash e1 doms)))
                      (d2 (length (gethash e2 doms))))
                  (cond ((< d1 d2) e1)
                        ((> d1 d2) e2)
                        ;; Tie-breaker: most conflicts with unassigned neighbors
                        (t (if (>= (unassigned-degree e1 assign)
                                   (unassigned-degree e2 assign))
                               e1 e2)))))
              unassigned)))

         (order-domain-values-lcv (e doms assign)
           "Least Constraining Value: sort domain slots by fewest conflicts caused to neighbors."
           (let ((legal-slots (gethash e doms))
                 (neighbors (remove-if (lambda (n) (gethash n assign))
                                       (get-exam-neighbors e conflicts))))
             (if (null neighbors)
                 legal-slots
                 (let ((scored
                         (mapcar
                          (lambda (s)
                            (let ((eliminated
                                    (count-if (lambda (n)
                                                (member s (gethash n doms) :test #'eql))
                                              neighbors)))
                              (cons s eliminated)))
                          legal-slots)))
                   (mapcar #'car (sort scored #'< :key #'cdr))))))

         (room-feasible-p (assign)
           (if (null rooms)
               t
               (multiple-value-bind (room-assignment room-violations)
                   (assign-rooms assign exams rooms)
                 (declare (ignore room-assignment))
                 (zerop room-violations))))

         (backtrack (assign doms)
           (if (= (hash-table-count assign) (length exam-keys))
               assign
               (let ((e (select-mrv-variable assign doms)))
                 (dolist (slot (order-domain-values-lcv e doms assign))
                   (incf *bt-assignments*)
                   (setf (gethash e assign) slot)

                   ;; Forward checking step
                   (let ((new-doms (copy-hash doms))
                         (feasible t))
                     (unless (room-feasible-p assign)
                       (setf feasible nil))
                     (dolist (neigh (get-exam-neighbors e conflicts))
                       (unless (gethash neigh assign)
                         (let ((pruned (remove slot (gethash neigh new-doms) :test #'eql)))
                           (setf (gethash neigh new-doms) pruned)
                           (when (null pruned)
                             (setf feasible nil)))))

                     ;; Room constraints affect every exam, not only graph neighbors.
                     ;; Remove any slot that would make the partial room assignment
                     ;; impossible, and fail early when an exam has no such slot.
                     (when (and feasible rooms)
                       (dolist (other (unassigned-exams assign))
                         (setf (gethash other new-doms)
                               (remove-if-not
                                (lambda (candidate-slot)
                                  (let ((trial (copy-hash assign)))
                                    (setf (gethash other trial) candidate-slot)
                                    (room-feasible-p trial)))
                                (gethash other new-doms)))
                         (when (null (gethash other new-doms))
                           (setf feasible nil))))

                     (if feasible
                         (let ((res (backtrack assign new-doms)))
                           (when res (return-from backtrack res)))
                         (incf *bt-backtracks*))

                     ;; Undo assignment
                     (remhash e assign)))
                 (incf *bt-backtracks*)
                 nil))))

      (let ((result (backtrack assignment domains)))
        (values result *bt-assignments* *bt-backtracks*)))))
