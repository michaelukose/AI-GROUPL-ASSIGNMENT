;;;; Scenario-based regression checks. Run with: sbcl --script tests/run-tests.lisp

(in-package #:exam-timetabling)

(defvar *test-pass-count* 0)
(defvar *test-fail-count* 0)

(defun check-scenario (condition description)
  (if condition
      (progn
        (incf *test-pass-count*)
        (format t "[PASS] ~a~%" description))
      (progn
        (incf *test-fail-count*)
        (format t "[FAIL] ~a~%" description))))

(defun make-test-exams (specs)
  (let ((table (make-hash-table :test 'equal)))
    (dolist (spec specs table)
      (setf (gethash (first spec) table)
            (make-exam :id (first spec) :name (first spec) :size (second spec))))))

(defun make-test-slots (count &optional (day 1))
  (let ((table (make-hash-table :test 'eql)))
    (dotimes (i count table)
      (let ((id (1+ i)))
        (setf (gethash id table)
              (make-timeslot :id id :day day :period (1+ i)
                             :name (format nil "Test slot ~a" id)))))))

(defun hash-tables-equal-p (left right)
  (and (= (hash-table-count left) (hash-table-count right))
       (loop for key being the hash-keys of left
             always (eql (gethash key left) (gethash key right)))))

(defun run-tests ()
  "Run the small deterministic regression scenarios shipped with this project."
  (setf *test-pass-count* 0 *test-fail-count* 0)
  (format t "~%=== EXAM TIMETABLING TEST SUITE ===~%~%")

  ;; --- CSV PARSER ---
  (let ((csv-fields (parse-csv-line "CS1,\"AI, Foundations\",55")))
    (check-scenario (equal csv-fields '("CS1" "AI, Foundations" "55"))
                    "CSV parser preserves quoted commas"))

  ;; --- DATASET LOADING ---
  (multiple-value-bind (demo-exams demo-slots demo-rooms demo-students demo-days)
      (load-dataset)
    (declare (ignore demo-days))
    (check-scenario (and (= (hash-table-count demo-exams) 15)
                         (= (hash-table-count demo-slots) 8)
                         (= (hash-table-count demo-rooms) 5)
                         (= (hash-table-count demo-students) 20))
                    "Bundled CSV dataset loads with expected dimensions")
    (let ((conflicts (build-conflicts-from-students demo-students)))
      (check-scenario (and (conflict-p "CS101" "CS201" conflicts)
                           (not (conflict-p "PHY101" "SEC404" conflicts)))
                      "Registrations produce expected graph edges")))

  ;; --- BACKTRACKING: TRIANGLE GRAPH ---
  (let* ((exams (make-test-exams '(("A" 20) ("B" 20) ("C" 20))))
         (triangle '(("A" . "B") ("A" . "C") ("B" . "C")))
         (three-slots (make-test-slots 3))
         (two-slots (make-test-slots 2)))
    (multiple-value-bind (assignment attempts backtracks)
        (solve-backtracking exams three-slots triangle)
      (declare (ignore attempts backtracks))
      (check-scenario (and assignment
                           (zerop (nth-value 1
                                             (evaluate-solution assignment exams three-slots triangle))))
                      "Triangle conflict graph is colored with three slots"))
    (multiple-value-bind (assignment attempts backtracks)
        (solve-backtracking exams two-slots triangle)
      (declare (ignore attempts backtracks))
      (check-scenario (null assignment)
                      "Triangle conflict graph is proven infeasible with two slots")))

  ;; --- ROOM ASSIGNMENT: CAPACITY VIOLATIONS ---
  (let* ((exams (make-test-exams '(("A" 45) ("B" 50))))
         (slots (make-test-slots 1))
         (rooms (make-hash-table :test 'equal))
         (assignment (make-hash-table :test 'equal)))
    (setf (gethash "H1" rooms) (make-exam-room :id "H1" :name "Hall" :capacity 50)
          (gethash "A" assignment) 1
          (gethash "B" assignment) 1)
    (multiple-value-bind (room-assignment room-violations)
        (assign-rooms assignment exams rooms)
      (declare (ignore room-assignment))
      (check-scenario (= room-violations 1)
                      "Room assignment detects same-slot room shortages"))
    (multiple-value-bind (schedule attempts backtracks)
        (solve-backtracking exams slots nil :rooms rooms)
      (declare (ignore attempts backtracks))
      (check-scenario (null schedule)
                      "CSP rejects a timetable that cannot fit the available rooms")))

  ;; --- SOFT CONSTRAINTS ---
  (let* ((exams (make-test-exams '(("A" 20) ("B" 20))))
         (slots (make-test-slots 2))
         (days (make-hash-table :test 'eql))
         (assignment (make-hash-table :test 'equal)))
    (setf (gethash 1 days) 1
          (gethash 2 days) 1
          (gethash "A" assignment) 1
          (gethash "B" assignment) 2)
    (multiple-value-bind (cost hard soft)
        (evaluate-solution assignment exams slots '(("A" . "B")) :slot-days days)
      (declare (ignore cost hard))
      (check-scenario (= soft 2)
                      "Same-day back-to-back exams incur both soft penalties")))

  ;; --- GENETIC REPRODUCIBILITY ---
  (multiple-value-bind (exams slots rooms students days)
      (load-dataset)
    (declare (ignore days))
    (let ((conflicts (build-conflicts-from-students students)))
      (multiple-value-bind (first-assignment first-evals first-gens first-cost)
          (run-genetic exams slots conflicts :rooms rooms :seed 31415
                       :pop-size 12 :generations 8)
        (multiple-value-bind (second-assignment second-evals second-gens second-cost)
            (run-genetic exams slots conflicts :rooms rooms :seed 31415
                         :pop-size 12 :generations 8)
          (check-scenario (and (hash-tables-equal-p first-assignment second-assignment)
                               (= first-evals second-evals)
                               (= first-gens second-gens)
                               (= first-cost second-cost))
                          "Genetic search is repeatable when given the same seed")))))

  ;; --- DATASET DISCOVERY ---
  (check-scenario (> (length (available-datasets)) 0)
                  "Dataset discovery finds at least one bundled dataset")

  ;; --- FULL PIPELINE ON DEMO ---
  (multiple-value-bind (exams slots rooms students days)
      (load-dataset)
    (let* ((conflicts (build-conflicts-from-students students))
           (bt-result (solve-backtracking exams slots conflicts :rooms rooms)))
      (check-scenario (not (null bt-result))
                      "Demo dataset is solvable by backtracking")))

  ;; --- SUMMARY ---
  (format t "~%=== RESULTS: ~a passed, ~a failed ===~%"
          *test-pass-count* *test-fail-count*)
  (if (zerop *test-fail-count*)
      (format t "All test scenarios passed.~%")
      (format t "SOME TESTS FAILED!~%"))
  (zerop *test-fail-count*))
