;;;; CSV input and dataset validation.
;;;; The project intentionally uses a small CSV reader instead of a third-party
;;;; dependency. It supports quoted fields, commas, and escaped double quotes.

(in-package #:exam-timetabling)

(defun parse-csv-line (line)
  "Split one CSV record into fields, honoring RFC-style quote escaping.
Newlines inside quoted fields are intentionally unsupported by this small reader."
  (let ((fields '())
        (field-chars '())
        (quoted-p nil)
        (index 0))
    (labels ((finish-field ()
               (push (coerce (nreverse field-chars) 'string) fields)
               (setf field-chars '())))
      (loop while (< index (length line))
            for character = (char line index)
            do (cond
                 ((char= character #\")
                  (if quoted-p
                      (if (and (< (1+ index) (length line))
                               (char= (char line (1+ index)) #\"))
                          (progn (push #\" field-chars) (incf index))
                          (setf quoted-p nil))
                      (setf quoted-p t)))
                 ((and (char= character #\,) (not quoted-p))
                  (finish-field))
                 (t (push character field-chars)))
               (incf index))
      (when quoted-p
        (error "Unclosed quote in CSV record: ~s" line))
      (finish-field)
      (nreverse fields))))

(defun read-csv-records (file)
  "Read a CSV file as a list of string-keyed row hash tables."
  (with-open-file (stream file :direction :input :external-format :utf-8)
    (let ((headers nil)
          (records '())
          (line-number 0))
      (loop for line = (read-line stream nil nil)
            while line
            do (incf line-number)
               (unless (string= (string-trim '(#\Space #\Tab #\Return) line) "")
                 (let ((fields (parse-csv-line line)))
                   (if (null headers)
                       (progn
                         (setf headers
                               (mapcar (lambda (header)
                                         (string-downcase
                                          (string-trim '(#\Space #\Tab #\Return) header)))
                                       fields))
                         (when (or (member "" headers :test #'string=)
                                   (/= (length headers)
                                       (length (remove-duplicates headers :test #'string=))))
                           (error "CSV file ~a has an empty or duplicate header." file)))
                       (progn
                         (unless (= (length headers) (length fields))
                           (error "CSV file ~a line ~a has ~a fields; expected ~a."
                                  file line-number (length fields) (length headers)))
                         (let ((row (make-hash-table :test 'equal)))
                           (loop for header in headers
                                 for value in fields
                                 do (setf (gethash header row) value))
                           (push row records)))))))
      (unless headers
        (error "CSV file ~a is empty." file))
      (nreverse records))))

(defun csv-cell (row column file)
  (multiple-value-bind (value present-p) (gethash column row)
    (unless present-p
      (error "CSV file ~a is missing required column ~a." file column))
    (string-trim '(#\Space #\Tab #\Return) value)))

(defun csv-positive-integer (value label file)
  (let ((number (ignore-errors (parse-integer value :junk-allowed nil))))
    (unless (and number (> number 0))
      (error "Expected a positive integer for ~a in ~a; got ~s." label file value))
    number))

(defun csv-unique-row (table key value label file)
  (when (gethash key table)
    (error "Duplicate ~a ~s in ~a." label key file))
  (setf (gethash key table) value))

(defun load-dataset (&optional
                       (exams-file
                         (and *project-root*
                              (merge-pathnames #P"data/datasets/demo/exams.csv"
                                               *project-root*))))
  "Load exams.csv and its sibling registrations, timeslots, and rooms files.
Returns six values: exams, slots, rooms, student registrations, slot-to-day map,
and the directory pathname. Pass the path to exams.csv to select another dataset."
  (unless exams-file
    (error "Project root is unknown. Load src/load.lisp before loading a dataset."))
  (let* ((exam-path (pathname exams-file))
         (registrations-path (make-pathname :name "registrations" :type "csv"
                                            :defaults exam-path))
         (slots-path (make-pathname :name "timeslots" :type "csv"
                                    :defaults exam-path))
         (rooms-path (make-pathname :name "rooms" :type "csv"
                                    :defaults exam-path))
         (exam-rows (read-csv-records exam-path))
         (registration-rows (read-csv-records registrations-path))
         (slot-rows (read-csv-records slots-path))
         (room-rows (read-csv-records rooms-path))
         (exams (make-hash-table :test 'equal))
         (slots (make-hash-table :test 'eql))
         (rooms (make-hash-table :test 'equal))
         (students (make-hash-table :test 'equal))
         (slot-days (make-hash-table :test 'eql)))
    (dolist (row exam-rows)
      (let* ((id (csv-cell row "exam_id" exam-path))
             (name (csv-cell row "name" exam-path))
             (size (csv-positive-integer (csv-cell row "enrollment" exam-path)
                                         "enrollment" exam-path)))
        (when (string= id "") (error "An exam_id cannot be blank in ~a." exam-path))
        (csv-unique-row exams id (make-exam :id id :name name :size size)
                        "exam_id" exam-path)))
    (dolist (row registration-rows)
      (let ((student-id (csv-cell row "student_id" registrations-path))
            (exam-id (csv-cell row "exam_id" registrations-path)))
        (unless (gethash exam-id exams)
          (error "Registration references unknown exam ~s in ~a." exam-id registrations-path))
        (when (string= student-id "")
          (error "A student_id cannot be blank in ~a." registrations-path))
        (let ((student-exams (gethash student-id students)))
          (when (member exam-id student-exams :test #'string=)
            (error "Duplicate registration for student ~s and exam ~s in ~a."
                   student-id exam-id registrations-path))
          (push exam-id (gethash student-id students))
          (push student-id (exam-students (gethash exam-id exams))))))
    (dolist (row slot-rows)
      (let* ((id (csv-positive-integer (csv-cell row "slot_id" slots-path)
                                       "slot_id" slots-path))
             (day (csv-positive-integer (csv-cell row "day" slots-path)
                                         "day" slots-path))
             (period (csv-positive-integer (csv-cell row "period" slots-path)
                                            "period" slots-path))
             (name (csv-cell row "name" slots-path)))
        (csv-unique-row slots id (make-timeslot :id id :day day :period period :name name)
                        "slot_id" slots-path)
        (setf (gethash id slot-days) day)))
    (dolist (row room-rows)
      (let* ((id (csv-cell row "room_id" rooms-path))
             (name (csv-cell row "name" rooms-path))
             (capacity (csv-positive-integer (csv-cell row "capacity" rooms-path)
                                             "capacity" rooms-path)))
        (when (string= id "") (error "A room_id cannot be blank in ~a." rooms-path))
        (csv-unique-row rooms id (make-exam-room :id id :name name :capacity capacity)
                        "room_id" rooms-path)))
    (values exams slots rooms students slot-days
            (make-pathname :name nil :type nil :version nil :defaults exam-path))))
