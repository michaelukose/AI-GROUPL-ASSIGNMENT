;;;; =========================================================================
;;;; FILE: reporting.lisp
;;;; PURPOSE: Printing only - no scheduling logic lives here.
;;;;
;;;;   print-conflict-graph-summary - vertices, edges, degree per exam
;;;;   print-timetable-grid         - ASCII table of slot / room / exam
;;;;   print-comparison-table       - Method A vs Method B side by side
;;;;
;;;; DEPENDS ON: data-structures.lisp, utils.lisp, conflict-graph.lisp,
;;;;             backtracking.lisp (*bt-backtracks*)
;;;; =========================================================================

(in-package #:exam-timetabling)

(defun print-conflict-graph-summary (exams conflicts)
  "Display summary of the conflict graph nodes, edges, and vertex degrees."
  (format t "~%--- CONFLICT GRAPH SUMMARY ---~%")
  (format t "Vertices (Exams): ~a~%" (hash-table-count exams))
  (format t "Edges (Student Clashes): ~a~%" (length conflicts))
  (format t "Conflict pairs:~%")
  (dolist (c conflicts)
    (let ((e1 (gethash (car c) exams))
          (e2 (gethash (cdr c) exams)))
      (format t "  * ~a (~a) <---> ~a (~a)~%"
              (car c) (exam-name e1) (cdr c) (exam-name e2))))
  (format t "Degree per exam:~%")
  (let ((exam-keys (sort (get-hash-keys exams) #'string<)))
    (dolist (k exam-keys)
      (let ((deg (length (get-exam-neighbors k conflicts))))
        (format t "  * ~a [~a]: ~a conflicting exams~%"
                k (exam-name (gethash k exams)) deg)))))

(defun print-timetable-grid (slot-assign room-assign exams slots rooms)
  "Display a formatted ASCII grid showing exams and assigned rooms per slot."
  (format t "~%  +--------+----------------------+------------------------------------+---------+~%")
  (format t "  | Slot   | Room                 | Exam [Enrolled Students]           | Size/Cap|~%")
  (format t "  +--------+----------------------+------------------------------------+---------+~%")
  (let ((slot-keys (sort (get-hash-keys slots) #'<)))
    (dolist (s slot-keys)
      (let ((placed nil))
        (maphash
         (lambda (e-id slot)
           (when (eql slot s)
             (setf placed t)
             (let* ((ex (gethash e-id exams))
                    (r-id (gethash e-id room-assign "UNASSIGNED"))
                    (rm (gethash r-id rooms))
                    (cap (if rm (exam-room-capacity rm) 0))
                    (exam-desc (format nil "~a: ~a [~{~a~^,~}]"
                                       e-id (exam-name ex) (exam-students ex)))
                    (room-desc (if rm (format nil "~a (~a)" r-id (exam-room-name rm)) r-id))
                    (size-cap (format nil "~a/~a" (exam-size ex) cap)))
               (format t "  | Slot ~a | ~20a | ~34a | ~7a |~%"
                       s room-desc exam-desc size-cap))))
         slot-assign)
        (unless placed
          (format t "  | Slot ~a | (empty)              | (no exams scheduled)               |   -     |~%"
                  s)))))
  (format t "  +--------+----------------------+------------------------------------+---------+~%"))

(defun print-comparison-table (sol-a sol-b)
  "Display side-by-side comparative analysis table matching Section 5.4."
  (format t "~%========================================================================~%")
  (format t "            COMPARATIVE ANALYSIS: METHOD A vs. METHOD B                 ~%")
  (format t "========================================================================~%")
  (format t "~32a | ~18a | ~18a~%" "Evaluation Metric" "Backtracking (CSP)" "Genetic Algorithm")
  (format t "---------------------------------+--------------------+-------------------~%")
  (format t "~32a | ~18a | ~18a~%"
          "Valid Timetable Found"
          (if (timetable-solution-success-p sol-a) "YES" "NO")
          (if (timetable-solution-success-p sol-b) "YES" "NO"))
  (format t "~32a | ~18a | ~18a~%"
          "Hard Violations (Clashes/Rooms)"
          (timetable-solution-hard-violations sol-a)
          (timetable-solution-hard-violations sol-b))
  (format t "~32a | ~18a | ~18a~%"
          "Soft Violations"
          (timetable-solution-soft-violations sol-a)
          (timetable-solution-soft-violations sol-b))
  (format t "~32a | ~18a | ~18a~%"
          "Total Penalty Cost"
          (timetable-solution-total-cost sol-a)
          (timetable-solution-total-cost sol-b))
  (format t "~32a | ~18a | ~18a~%"
          "Search Effort"
          (format nil "~a assigns (~a bt)"
                  (timetable-solution-search-effort sol-a)
                  *bt-backtracks*)
          (format nil "~a evaluations"
                  (timetable-solution-search-effort sol-b)))
  (format t "~32a | ~18a | ~18a~%"
          "Execution Time"
          (format nil "~,2f ms" (timetable-solution-elapsed-ms sol-a))
          (format nil "~,2f ms" (timetable-solution-elapsed-ms sol-b)))
  (format t "~32a | ~18a | ~18a~%"
          "Theoretical Guarantee"
          "Complete (Exact)"
          "Heuristic (Stochastic)")
  (format t "~32a | ~18a | ~18a~%"
          "Can Prove Unsatisfiable?"
          "YES"
          "NO")
  (format t "========================================================================~%"))
