;;;; =========================================================================
;;;; FILE: room-assignment.lisp
;;;; PURPOSE: STAGE 2 - once every exam has a time slot, give each exam a room.
;;;;          Inside each slot: biggest exams first, each into the smallest
;;;;          free room that is large enough (best-fit decreasing).
;;;;
;;;; PROVIDES:   assign-rooms
;;;; DEPENDS ON: data-structures.lisp (exam-size, exam-room-capacity),
;;;;             utils.lisp (get-hash-keys)
;;;; =========================================================================

(in-package #:exam-timetabling)

(defun assign-rooms (slot-assign exams rooms)
  "Stage 2 (Section 4.2 of write-up):
   Within each time slot, place the largest exams first, each in the smallest
   free room that can hold it (Best-Fit Decreasing / First-Fit Decreasing).
   If an exam cannot be placed (no room has sufficient capacity or all are taken),
   it is flagged as 'UNASSIGNED' and increments capacity violations."
  (let ((room-assign (make-hash-table :test 'equal))
        (room-violations 0)
        (slot-map (make-hash-table :test 'eql)))

    ;; Group exams by assigned time slot
    (maphash (lambda (e-id slot)
               (when slot
                 (push e-id (gethash slot slot-map '()))))
             slot-assign)

    ;; Sort rooms by capacity ascending (to pick the smallest sufficient room)
    (let ((sorted-room-ids
            (sort (get-hash-keys rooms)
                  #'<
                  :key (lambda (r-id) (exam-room-capacity (gethash r-id rooms))))))

      ;; Assign rooms independently for each slot
      (maphash
       (lambda (slot exam-ids)
         (declare (ignore slot))
         ;; Sort exams in this slot by size descending (largest first)
         (let ((sorted-exam-ids
                 (sort (copy-list exam-ids)
                       #'>
                       :key (lambda (e-id) (exam-size (gethash e-id exams)))))
               (available-rooms (copy-list sorted-room-ids)))

           (dolist (e-id sorted-exam-ids)
             (let* ((e-size (exam-size (gethash e-id exams)))
                    (chosen-room
                      (find-if (lambda (r-id)
                                 (>= (exam-room-capacity (gethash r-id rooms)) e-size))
                               available-rooms)))
               (if chosen-room
                   (progn
                     (setf (gethash e-id room-assign) chosen-room)
                     (setf available-rooms (delete chosen-room available-rooms :test #'equal :count 1)))
                   ;; No room with capacity >= e-size remains free
                   (progn
                     (setf (gethash e-id room-assign) "UNASSIGNED")
                     (incf room-violations)))))))
       slot-map))

    (values room-assign room-violations)))
