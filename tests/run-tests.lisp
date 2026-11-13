;;;; Test runner. This is separate from the main project loader on purpose.

(let ((test-dir (make-pathname :name nil :type nil :version nil
                               :defaults *load-truename*)))
  (load (merge-pathnames #P"../src/load.lisp" test-dir))
  (load (merge-pathnames "test-suite.lisp" test-dir)))

(exam-timetabling::run-tests)
