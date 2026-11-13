;;;; =========================================================================
;;;; FILE: scenarios.lisp
;;;; PURPOSE: Public scenario entry points. Dataset inputs live in CSV files.
;;;;          Supports running individual named datasets, custom paths, and
;;;;          listing/running all bundled datasets.
;;;;
;;;; PROVIDES:   run-dataset, list-datasets, run-all-datasets, run-all
;;;; DEPENDS ON: csv-data.lisp, experiment.lisp
;;;; =========================================================================

(in-package #:exam-timetabling)

(defun available-datasets ()
  "Return an alist of (name . directory-path) for all bundled datasets."
  (let ((datasets-dir (merge-pathnames #P"data/datasets/" *project-root*))
        (result '()))
    (when (probe-file datasets-dir)
      (dolist (entry (directory (merge-pathnames #P"*/" datasets-dir)))
        (let* ((dir-path (namestring entry))
               (exams-path (merge-pathnames "exams.csv" entry)))
          (when (probe-file exams-path)
            (let* ((clean (string-right-trim "/" (string-right-trim "\\" dir-path)))
                   (name (subseq clean
                                 (1+ (max (or (position #\/ clean :from-end t) -1)
                                          (or (position #\\ clean :from-end t) -1))))))
              (push (cons name entry) result))))))
    (sort result #'string< :key #'car)))

(defun list-datasets ()
  "Print all available bundled datasets."
  (let ((datasets (available-datasets)))
    (format t "~%Available datasets:~%")
    (format t "-------------------~%")
    (if (null datasets)
        (format t "  (none found in data/datasets/)~%")
        (dolist (ds datasets)
          (let* ((dir (cdr ds))
                 (readme (merge-pathnames "README.md" dir))
                 (description ""))
            (when (probe-file readme)
              (with-open-file (s readme :direction :input)
                (let ((line (read-line s nil nil)))
                  (when line
                    ;; Strip leading # markers from markdown
                    (setf description (string-trim '(#\# #\Space) line))))))
            (format t "  ~12a  ~a~%" (car ds) description))))
    (format t "~%Use: sbcl --script src/main.lisp <name>~%")
    (format t "      sbcl --script src/main.lisp all~%~%")))

(defun resolve-scenario (scenario)
  "Given a scenario name or path, return the exams.csv pathname.
A name like 'medium' resolves to data/datasets/medium/exams.csv.
A file path is used directly."
  (cond
    ;; Direct file path
    ((probe-file (pathname scenario))
     (pathname scenario))
    ;; Named dataset
    (t
     (let ((ds (assoc scenario (available-datasets) :test #'string-equal)))
       (if ds
           (merge-pathnames "exams.csv" (cdr ds))
           (progn
             (format *error-output* "~%ERROR: Unknown dataset '~a'.~%" scenario)
             (list-datasets)
             nil))))))

(defun run-dataset (&key scenario exams-file (seed (get-internal-real-time)))
  "Run the CSP and genetic algorithm on a CSV dataset.
SCENARIO is a dataset name (e.g. 'demo', 'medium') or path to exams.csv.
EXAMS-FILE overrides scenario with a direct pathname.
SEED controls the genetic algorithm and can be supplied to reproduce a run."
  (let ((path (cond
                (exams-file (pathname exams-file))
                (scenario   (resolve-scenario scenario))
                (t          nil))))
    ;; nil path = use default dataset
    (multiple-value-bind (exams slots rooms students slot-days dataset-directory)
        (if path
            (load-dataset path)
            (load-dataset))
      (declare (ignore dataset-directory))
      (let ((title (format nil "CSV DATASET: ~a"
                           (if scenario
                               (string-upcase scenario)
                               "DEMONSTRATION INSTANCE"))))
        (run-experiment-suite title exams slots rooms students
                              :slot-days slot-days
                              :seed seed)))))

(defun run-all-datasets (&key (seed (get-internal-real-time)))
  "Discover and run every bundled CSV dataset."
  (let ((datasets (available-datasets)))
    (format t "~%======================================================================~%")
    (format t "  EXAM TIMETABLING: RUNNING ALL ~a DATASETS~%" (length datasets))
    (format t "======================================================================~%")
    (if (null datasets)
        (format t "~%No datasets found in data/datasets/.~%")
        (dolist (ds datasets)
          (format t "~%>>> Loading dataset: ~a~%" (car ds))
          (run-dataset :scenario (car ds) :seed seed)))
    (format t "~%[All dataset runs completed]~%~%")))

(defun run-all (&key (seed (get-internal-real-time)))
  "Run the bundled CSV dataset through both scheduling approaches."
  (format t "~%======================================================================~%")
  (format t "  EXAM TIMETABLING: CSP BACKTRACKING + GENETIC SEARCH~%")
  (format t "======================================================================~%")
  (run-dataset :seed seed)
  (format t "~%[Dataset run completed]~%~%"))
