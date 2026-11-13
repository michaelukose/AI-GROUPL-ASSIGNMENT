;;;; =========================================================================
;;;; FILE: utils.lisp
;;;; PURPOSE: Small, general-purpose hash-table helpers used by several files.
;;;;
;;;;   get-hash-keys - list of all keys in a hash table
;;;;   copy-hash     - independent copy of a hash table (lets the search "undo")
;;;;
;;;; DEPENDS ON: package.lisp
;;;; =========================================================================

(in-package #:exam-timetabling)

(defun get-hash-keys (table)
  "Return a list of all keys in a hash table."
  (let ((keys '()))
    (maphash (lambda (k v) (declare (ignore v)) (push k keys)) table)
    keys))

(defun copy-hash (table)
  "Create an independent shallow copy of a hash table."
  (let ((new-table (make-hash-table :test (hash-table-test table))))
    (maphash (lambda (k v) (setf (gethash k new-table) v)) table)
    new-table))

(defun make-random-source (seed)
  "Return a deterministic small pseudo-random source for integer/float limits.
Passing the same integer seed produces the same genetic-algorithm run."
  (unless (integerp seed)
    (error "Random seed must be an integer, got ~s." seed))
  (let ((state (mod (abs seed) 2147483647)))
    (when (zerop state) (setf state 1))
    (lambda (limit)
      (unless (and (realp limit) (> limit 0))
        (error "Random limit must be positive, got ~s." limit))
      (setf state (mod (* 48271 state) 2147483647))
      (if (integerp limit)
          (mod state limit)
          (* limit (/ state 2147483647.0d0))))))
