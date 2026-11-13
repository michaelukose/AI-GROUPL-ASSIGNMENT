;;;; =========================================================================
;;;; FILE: main.lisp
;;;; PURPOSE: Entry point. Loads the project and runs a dataset scenario.
;;;;
;;;; Usage (from a terminal, inside the project folder):
;;;;   sbcl --script src/main.lisp                     ; run the demo dataset
;;;;   sbcl --script src/main.lisp demo                ; same as above
;;;;   sbcl --script src/main.lisp medium              ; run the medium dataset
;;;;   sbcl --script src/main.lisp large               ; run the large dataset
;;;;   sbcl --script src/main.lisp stress              ; run the stress dataset
;;;;   sbcl --script src/main.lisp all                 ; run all datasets
;;;;   sbcl --script src/main.lisp list                ; list available datasets
;;;;   sbcl --script src/main.lisp path/to/exams.csv   ; run a custom dataset
;;;;
;;;; Or via the helper:
;;;;   powershell -File run.ps1 run                    ; demo dataset
;;;;   powershell -File run.ps1 run medium             ; medium dataset
;;;;   powershell -File run.ps1 test                   ; run the test suite
;;;; =========================================================================

;;; --script does not reliably set *load-truename* on all SBCL versions.
;;; We try *load-truename* first, then fall back to *load-pathname* (SBCL),
;;; and finally to the process working directory + "src/main.lisp".

(defvar *main-source-path*
  (or *load-truename*
      *load-pathname*
      (merge-pathnames #P"src/main.lisp" (truename "."))))

(load (merge-pathnames "load.lisp"
                       (make-pathname :name nil :type nil :version nil
                                      :defaults *main-source-path*)))

(let ((args (rest sb-ext:*posix-argv*)))
  (if (null args)
      ;; No arguments: run the demo dataset
      (exam-timetabling:run-dataset)
      ;; Process each argument as a scenario name
      (dolist (arg args)
        (cond
          ((string-equal arg "list")
           (exam-timetabling:list-datasets))
          ((string-equal arg "all")
           (exam-timetabling:run-all-datasets))
          ((string-equal arg "help")
           (format t "~%Usage: sbcl --script src/main.lisp [SCENARIO|COMMAND]~%~%")
           (format t "Scenarios:~%")
           (format t "  demo       Run the demonstration dataset (default)~%")
           (format t "  medium     Run the medium-sized dataset~%")
           (format t "  large      Run the large dataset~%")
           (format t "  stress     Run the stress-test dataset~%")
           (format t "  <path>     Run a custom dataset by path to exams.csv~%~%")
           (format t "Commands:~%")
           (format t "  all        Run all bundled datasets~%")
           (format t "  list       List available datasets~%")
           (format t "  help       Show this message~%~%"))
          (t
           (exam-timetabling:run-dataset :scenario arg))))))
