;;;; =========================================================================
;;;; FILE: evaluation.lisp
;;;; PURPOSE: The COST FUNCTION - scores a timetable (lower is better).
;;;;
;;;;   cost = 1000 * (hard violations) + 1 * (soft violations)
;;;;   hard: student clashes in the same slot, plus room capacity/reuse violations
;;;;   soft: exams that share a student are back-to-back or on the same day
;;;;
;;;; PROVIDES:   evaluate-solution
;;;; DEPENDS ON: utils.lisp (get-hash-keys), conflict-graph.lisp (conflict-p)
;;;; =========================================================================

(in-package #:exam-timetabling)

(defun evaluate-solution (slot-assign exams slots conflicts
                          &key (whard 1000) (wsoft 1) (slot-days nil) (rooms nil))
  "Compute penalty cost according to Section 2.6:
   cost(timetable) = Whard * (hard violations) + Wsoft * (soft violations)
   
   Hard Constraints:
     1. Student clashes: If e1 and e2 share a student, slot(e1) != slot(e2).
     2. Room feasibility: every exam in a slot gets a distinct room with enough seats.
   
   Soft Constraints:
     1. Consecutive exams (back-to-back): |slot(e1) - slot(e2)| = 1.
     2. Same-day exams: Exams on the same day for the same student."
  (declare (ignore slots))
  (let ((hard-violations 0)
        (soft-violations 0))

    ;; 1. Check Hard Constraint: Student clashes in the same slot
    ;; Two conflicting exams sharing a student cannot be scheduled in the same slot.
    (dolist (c conflicts)
      (let* ((e1 (car c))
             (e2 (cdr c))
             (s1 (gethash e1 slot-assign))
             (s2 (gethash e2 slot-assign)))
        (when (and s1 s2 (eql s1 s2))
          (incf hard-violations))))

    ;; 2. Room capacity and room reuse are hard constraints when room data is given.
    (when rooms
      (multiple-value-bind (room-assignment room-violations)
          (assign-rooms slot-assign exams rooms)
        (declare (ignore room-assignment))
        (incf hard-violations room-violations)))

    ;; 3. Check Soft Constraints across conflicting pairs (shared students)
    (dolist (c conflicts)
      (let* ((e1 (car c))
             (e2 (cdr c))
             (s1 (gethash e1 slot-assign))
             (s2 (gethash e2 slot-assign)))
        (when (and s1 s2)
          ;; Soft rule A: Avoid back-to-back slots (|s1 - s2| = 1)
          (when (= (abs (- s1 s2)) 1)
            (incf soft-violations))
          ;; Soft rule B: Spread across days (same day penalty)
          (when (and slot-days
                     (not (eql s1 s2))
                     (eql (gethash s1 slot-days) (gethash s2 slot-days)))
            (incf soft-violations)))))

    (let ((total-cost (+ (* whard hard-violations) (* wsoft soft-violations))))
      (values total-cost hard-violations soft-violations))))
