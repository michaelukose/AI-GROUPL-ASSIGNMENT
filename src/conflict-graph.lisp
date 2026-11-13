;;;; =========================================================================
;;;; FILE: conflict-graph.lisp
;;;; PURPOSE: Builds and queries the CONFLICT GRAPH.
;;;;          Each exam is a vertex; two exams are joined by an edge when at
;;;;          least one student has to sit both of them.
;;;;
;;;;   build-conflicts-from-students - student registrations -> list of (e1 . e2) edges
;;;;   conflict-p                    - do two exams share a student?
;;;;   get-exam-neighbors            - every exam that clashes with a given exam
;;;;
;;;; DEPENDS ON: package.lisp
;;;; =========================================================================

(in-package #:exam-timetabling)

(defun conflict-p (e1 e2 conflicts)
  "Check whether exams e1 and e2 share a student (connected in conflict graph)."
  (or (member (cons e1 e2) conflicts :test #'equal)
      (member (cons e2 e1) conflicts :test #'equal)))

(defun get-exam-neighbors (exam-id conflicts)
  "Return a list of adjacent exam IDs conflicting with exam-id."
  (let ((neighbors '()))
    (dolist (c conflicts)
      (cond ((equal (car c) exam-id) (pushnew (cdr c) neighbors :test #'equal))
            ((equal (cdr c) exam-id) (pushnew (car c) neighbors :test #'equal))))
    neighbors))

(defun build-conflicts-from-students (students-table)
  "Construct the conflict graph edges from student course registrations.
   Whenever a student is registered for both e1 and e2, an undirected edge (e1, e2) is added."
  (let ((conflicts '()))
    (maphash
     (lambda (student-id exam-ids)
       (declare (ignore student-id))
       (loop for (e1 . rest) on exam-ids do
         (dolist (e2 rest)
           (unless (conflict-p e1 e2 conflicts)
             (push (cons e1 e2) conflicts)))))
     students-table)
    conflicts))
