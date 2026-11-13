;;;; =========================================================================
;;;; FILE: data-structures.lisp
;;;; PURPOSE: The "nouns" of the project - the record types everything else uses.
;;;;
;;;;   exam                - one course exam (id, name, size, list of students)
;;;;   timeslot            - one exam session (id, day, morning/afternoon)
;;;;   exam-room           - one room (id, name, seating capacity)
;;;;   timetable-solution  - the outcome of a solve (assignments, costs, timings)
;;;;
;;;; DEPENDS ON: package.lisp
;;;; =========================================================================

(in-package #:exam-timetabling)

(defstruct exam
  "Represents an academic course exam to be scheduled.
   - ID: Unique identifier string, e.g. 'E1'
   - NAME: Descriptive course title, e.g. 'Programming'
   - SIZE: Number of enrolled students sitting the exam
   - STUDENTS: List of student IDs registered for this exam"
  (id "" :type string)
  (name "" :type string)
  (size 0 :type integer)
  (students '() :type list))

(defstruct timeslot
  "Represents an exam session period.
   - ID: Integer index (1..k)
   - DAY: Academic day index (1..d)
   - PERIOD: Period in day (1 = Morning, 2 = Afternoon)
   - NAME: Human-readable description"
  (id 1 :type integer)
  (day 1 :type integer)
  (period 1 :type integer)
  (name "" :type string))

(defstruct exam-room
  "Represents a physical room or lecture hall.
   - ID: Room code, e.g. 'R1'
   - NAME: Room description, e.g. 'Main Hall'
   - CAPACITY: Maximum student seating capacity"
  (id "" :type string)
  (name "" :type string)
  (capacity 0 :type integer))

(defstruct timetable-solution
  "Container for timetable search outcomes."
  (method-name "" :type string)
  (success-p nil :type boolean)
  (slot-assignment (make-hash-table :test 'equal))
  (room-assignment (make-hash-table :test 'equal))
  (hard-violations 0 :type integer)
  (soft-violations 0 :type integer)
  (total-cost 0 :type integer)
  (search-effort 0 :type integer)
  (elapsed-ms 0.0 :type float)
  (notes "" :type string))
