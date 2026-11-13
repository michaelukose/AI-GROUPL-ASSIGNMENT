# Medium Exam Timetabling Dataset

## Overview
A university-style exam scheduling scenario designed to provide a moderately complex
optimization challenge with realistic departmental structures and student conflicts.

## Dataset Statistics
- **Exams:** 20 (across 6 departments: CS, MTH, ENG, BUS, PHY, CHEM)
- **Timeslots:** 8 (4 days × 2 periods: morning/afternoon)
- **Rooms:** 6 (capacities ranging from 30 to 150)
- **Students:** 50 (with 2–5 exam registrations each)
- **Total registrations:** 190

## Files
| File | Description |
|------|-------------|
| `exams.csv` | Exam definitions with enrollment counts (15–120) |
| `timeslots.csv` | Available scheduling slots across 4 exam days |
| `rooms.csv` | Room inventory with seating capacities |
| `registrations.csv` | Student-to-exam mappings that define conflict constraints |

## Conflict Structure
Students are grouped by major, creating dense intra-department conflicts:
- **CS** students share CS and MTH exams
- **MTH/PHY** students share MTH, PHY, and some CHEM exams
- **ENG/BUS** students share ENG and BUS exams
- **CHEM/PHY** students share CHEM, PHY, and some MTH exams
- **Cross-department** students create inter-department conflicts

This structure ensures scheduling is non-trivial — many exam pairs share students
and cannot be placed in the same timeslot.
