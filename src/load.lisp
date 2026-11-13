;;;; =========================================================================
;;;; FILE: src/load.lisp
;;;; PURPOSE: Loads the application modules in dependency order. Runs nothing.
;;;;
;;;; Usage from the project root in an SBCL REPL:
;;;;   (load "src/load.lisp")
;;;;   (exam-timetabling:run-dataset)
;;;;
;;;; ORDER MATTERS: a file may only use things defined in files above it.
;;;;
;;;;   package           the namespace
;;;;   data-structures   exam, timeslot, exam-room, timetable-solution
;;;;   utils             hash-table helpers
;;;;   csv-data          CSV parser and dataset loader
;;;;   conflict-graph    which exams clash?
;;;;   room-assignment   Stage 2: rooms
;;;;   evaluation        hard/soft objective function
;;;;   backtracking      Method A
;;;;   genetic           Method B
;;;;   reporting         printing
;;;;   experiment        runs A and B on one problem
;;;;   scenarios         dataset-backed entry points
;;;; =========================================================================

;;; Compute source-dir and project-dir before loading package.lisp,
;;; so we can set *project-root* immediately after the package exists.
(let* ((source-dir (make-pathname :name nil :type nil :version nil
                                  :defaults (or *load-truename*
                                                *load-pathname*)))
       (project-dir (merge-pathnames #P"../" source-dir)))

  ;; 1. Load the package first (defines EXAM-TIMETABLING)
  (load (merge-pathnames "package.lisp" source-dir))

  ;; 2. Now the package symbol is accessible - set the project root
  (setf (symbol-value (find-symbol "*PROJECT-ROOT*" "EXAM-TIMETABLING"))
        project-dir)

  ;; 3. Load the rest in dependency order
  (dolist (file '("data-structures"
                  "utils"
                  "csv-data"
                  "conflict-graph"
                  "room-assignment"
                  "evaluation"
                  "backtracking"
                  "genetic"
                  "reporting"
                  "experiment"
                  "scenarios"))
    (load (merge-pathnames (concatenate 'string file ".lisp") source-dir))))
