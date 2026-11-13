;;;; =========================================================================
;;;; KCA UNIVERSITY
;;;; FACULTY OF COMPUTING & INFORMATION MANAGEMENT
;;;; DEPARTMENT OF SOFTWARE DEVELOPMENT & INFORMATION SYSTEMS
;;;; CPP 4103: ARTIFICIAL INTELLIGENCE PROGRAMMING
;;;; Assignment 2: Class Project
;;;; Topic: Exam Timetable Generation Using Constraint Satisfaction & Genetic Algorithms
;;;;
;;;; Implementation: ANSI Common Lisp (Optimized for SBCL)
;;;; =========================================================================
;;;;
;;;; FILE: package.lisp
;;;; PURPOSE: Declares the package (namespace) shared by every project file,
;;;;          and lists which names are exported (visible from outside).
;;;; DEPENDS ON: nothing - this is the first file loaded.
;;;; =========================================================================

(defpackage #:exam-timetabling
  (:use #:cl)
  (:export #:run-all
           #:run-all-datasets
           #:run-dataset
           #:list-datasets
           #:solve-backtracking
           #:run-genetic
           #:assign-rooms
           #:make-exam
           #:make-timeslot
           #:make-exam-room
           #:load-dataset
           #:run-experiment-suite))

(in-package #:exam-timetabling)

(defvar *project-root* nil
  "Absolute directory pathname of the project root, set by src/load.lisp.")
