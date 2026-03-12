-- ==========================================================
-- PROJECT 3: STUDENT MANAGEMENT SYSTEM (SQL SERVER VERSION)
-- Business Logic:
-- • Supports BCA/BSc programs
-- • Tracks enrollments, attendance and exam marks
-- • Attendance <75% flagged as detention risk
-- • Calculates grades and CGPA using credit-weighted system
-- ==========================================================

-- ---------- DATABASE ----------
IF DB_ID('student_db') IS NULL
CREATE DATABASE student_db;
GO
USE student_db;
GO


-- ---------- PROGRAMS TABLE ----------
CREATE TABLE programs(
 program_id INT IDENTITY(1,1) PRIMARY KEY,
 name VARCHAR(100),
 duration_years TINYINT
);


-- ---------- STUDENTS ----------
CREATE TABLE students(
 student_id INT IDENTITY(1,1) PRIMARY KEY,
 roll_no VARCHAR(20) UNIQUE NOT NULL,
 full_name VARCHAR(100) NOT NULL,
 dob DATE,
 gender VARCHAR(10) CHECK(gender IN ('Male','Female','Other')),
 email VARCHAR(100) UNIQUE,
 phone VARCHAR(15),
 program_id INT,
 admission_year INT,
 FOREIGN KEY(program_id) REFERENCES programs(program_id)
);


-- ---------- FACULTY ----------
CREATE TABLE faculty(
 faculty_id INT IDENTITY(1,1) PRIMARY KEY,
 full_name VARCHAR(100),
 designation VARCHAR(100),
 email VARCHAR(100) UNIQUE,
 department VARCHAR(100)
);


-- ---------- COURSES ----------
CREATE TABLE courses(
 course_id INT IDENTITY(1,1) PRIMARY KEY,
 code VARCHAR(15) UNIQUE NOT NULL,
 name VARCHAR(150),
 credits TINYINT,
 semester TINYINT,
 faculty_id INT,
 FOREIGN KEY(faculty_id) REFERENCES faculty(faculty_id)
);


-- ---------- ENROLLMENTS ----------
CREATE TABLE enrollments(
 enrollment_id INT IDENTITY(1,1) PRIMARY KEY,
 student_id INT,
 course_id INT,
 semester TINYINT,
 academic_year VARCHAR(10),
 CONSTRAINT uk_enroll UNIQUE(student_id,course_id,academic_year),
 FOREIGN KEY(student_id) REFERENCES students(student_id),
 FOREIGN KEY(course_id) REFERENCES courses(course_id)
);


-- ---------- ATTENDANCE ----------
CREATE TABLE attendance(
 attendance_id INT IDENTITY(1,1) PRIMARY KEY,
 enrollment_id INT,
 class_date DATE,
 status VARCHAR(10) CHECK(status IN ('present','absent','late')),
 FOREIGN KEY(enrollment_id) REFERENCES enrollments(enrollment_id)
);


-- ---------- EXAMS ----------
CREATE TABLE exams(
 exam_id INT IDENTITY(1,1) PRIMARY KEY,
 course_id INT,
 exam_type VARCHAR(20) CHECK(exam_type IN ('internal','midterm','final')),
 exam_date DATE,
 max_marks DECIMAL(5,2),
 FOREIGN KEY(course_id) REFERENCES courses(course_id)
);


-- ---------- MARKS ----------
CREATE TABLE marks(
 mark_id INT IDENTITY(1,1) PRIMARY KEY,
 student_id INT,
 exam_id INT,
 marks_obtained DECIMAL(5,2),
 FOREIGN KEY(student_id) REFERENCES students(student_id),
 FOREIGN KEY(exam_id) REFERENCES exams(exam_id)
);


-- ==========================================================
-- SAMPLE DATA
-- ==========================================================

INSERT INTO programs(name,duration_years) VALUES
('Bachelor of Computer Applications',3),
('Bachelor of Science CS',3);

INSERT INTO faculty(full_name,designation,email,department) VALUES
('Prof. A.K. Mishra','Associate Professor','mishra@univ.edu','CS'),
('Prof. S. Lakshmi','Assistant Professor','lakshmi@univ.edu','Math'),
('Prof. R. Bhatia','Professor','bhatia@univ.edu','CS');

INSERT INTO students
(roll_no,full_name,dob,gender,email,phone,program_id,admission_year)
VALUES
('BCA2024001','Aarav Tiwari','2003-01-15','Male','aarav@mail.com','9100001111',1,2024),
('BCA2024002','Diya Kapoor','2003-06-22','Female','diya@mail.com','9100002222',1,2024),
('BCA2024003','Karthik Rajan','2002-11-08','Male','karthik@mail.com','9100003333',1,2024),
('BCA2024004','Sneha Pillai','2003-03-17','Female','sneha@mail.com','9100004444',1,2024),
('BCA2024005','Manish Dubey','2002-09-25','Male','manish@mail.com','9100005555',1,2024);

INSERT INTO courses(code,name,credits,semester,faculty_id) VALUES
('BCA101','Programming in C',4,1,1),
('BCA102','Mathematics for Computing',3,1,2),
('BCA103','Database Management',4,1,1);

INSERT INTO exams(course_id, exam_type, exam_date, max_marks) VALUES
(1,'internal','2024-09-15',30),(1,'final','2024-11-20',70),
(2,'internal','2024-09-16',30),(2,'final','2024-11-21',70),
(3,'internal','2024-09-17',30),(3,'final','2024-11-22',70);

INSERT INTO marks(student_id, exam_id, marks_obtained) VALUES
(1,1,26),(1,2,62),(1,3,25),(1,4,61),(1,5,27),(1,6,65),
(2,1,28),(2,2,67),(2,3,26),(2,4,58),(2,5,29),(2,6,68),
(3,1,20),(3,2,45),(3,3,18),(3,4,40),(3,5,22),(3,6,48),
(4,1,29),(4,2,63),(4,3,28),(4,4,65),(4,5,30),(4,6,69),
(5,1,15),(5,2,30),(5,3,14),(5,4,32),(5,5,16),(5,6,35);
-- ==========================================================
-- UPDATE EXAMPLES
-- ==========================================================

UPDATE marks
SET marks_obtained=55
WHERE student_id=3 AND exam_id=2;

UPDATE faculty
SET designation='Professor'
WHERE faculty_id=2;


-- ==========================================================
-- SELECT: MARKSHEET WITH GRADE CALCULATION
-- ==========================================================

SELECT
 s.roll_no,
 s.full_name,
 c.code,
 c.name AS course,
 SUM(m.marks_obtained) total_marks,
 e_max.total_max,
 ROUND(SUM(m.marks_obtained)/e_max.total_max*100,2) percentage,

 CASE
  WHEN SUM(m.marks_obtained)/e_max.total_max*100>=90 THEN 'O'
  WHEN SUM(m.marks_obtained)/e_max.total_max*100>=80 THEN 'A+'
  WHEN SUM(m.marks_obtained)/e_max.total_max*100>=70 THEN 'A'
  WHEN SUM(m.marks_obtained)/e_max.total_max*100>=60 THEN 'B+'
  WHEN SUM(m.marks_obtained)/e_max.total_max*100>=50 THEN 'B'
  WHEN SUM(m.marks_obtained)/e_max.total_max*100>=40 THEN 'C'
  ELSE 'F'
 END grade

FROM students s
JOIN marks m ON s.student_id=m.student_id
JOIN exams e ON m.exam_id=e.exam_id
JOIN courses c ON e.course_id=c.course_id

JOIN(
 SELECT course_id,SUM(max_marks) total_max
 FROM exams GROUP BY course_id
) e_max ON e.course_id=e_max.course_id

GROUP BY
s.student_id,s.roll_no,s.full_name,
c.course_id,c.code,c.name,e_max.total_max

ORDER BY s.roll_no,c.code;


-- ==========================================================
-- SELECT: ATTENDANCE PERCENTAGE
-- ==========================================================

SELECT
 s.full_name,
 c.name course,
 COUNT(a.attendance_id) total_classes,

 SUM(CASE WHEN a.status='present' THEN 1 ELSE 0 END) attended,

 ROUND(
  SUM(CASE WHEN a.status='present' THEN 1 ELSE 0 END)
  *100.0/COUNT(*),2
 ) attendance_pct,

 CASE
  WHEN SUM(CASE WHEN a.status='present' THEN 1 ELSE 0 END)
       *100.0/COUNT(*) <75
  THEN 'DETAINED RISK'
  ELSE 'OK'
 END remark

FROM students s
JOIN enrollments en ON s.student_id=en.student_id
JOIN courses c ON en.course_id=c.course_id
JOIN attendance a ON en.enrollment_id=a.enrollment_id

GROUP BY s.student_id,s.full_name,c.course_id,c.name
ORDER BY attendance_pct;


-- ==========================================================
-- VIEW: TOPPER LIST
-- ==========================================================

CREATE OR ALTER VIEW vw_topper_list AS
SELECT
 s.roll_no,
 s.full_name,
 p.name program,
 SUM(m.marks_obtained) total_marks,
 RANK() OVER(ORDER BY SUM(m.marks_obtained) DESC) rank_pos
FROM students s
JOIN marks m ON s.student_id=m.student_id
JOIN programs p ON s.program_id=p.program_id
GROUP BY s.student_id,s.roll_no,s.full_name,p.name;


-- ==========================================================
-- INDEXES FOR PERFORMANCE
-- ==========================================================

CREATE INDEX idx_marks_student ON marks(student_id);
CREATE INDEX idx_marks_exam ON marks(exam_id);
CREATE INDEX idx_attendance_enroll ON attendance(enrollment_id);
select * from marks;

-- ==========================================================
-- CTE: CGPA CALCULATION
-- ==========================================================

WITH course_marks AS(
 SELECT
  s.student_id,
  s.full_name,
  c.credits,
  SUM(m.marks_obtained) earned,
  SUM(e.max_marks) max_total

 FROM students s
 JOIN marks m ON s.student_id=m.student_id
 JOIN exams e ON m.exam_id=e.exam_id
 JOIN courses c ON e.course_id=c.course_id

 GROUP BY s.student_id,s.full_name,c.course_id,c.credits
),

graded AS(
 SELECT *,
 CASE
  WHEN earned*100.0/max_total>=90 THEN 10
  WHEN earned*100.0/max_total>=80 THEN 9
  WHEN earned*100.0/max_total>=70 THEN 8
  WHEN earned*100.0/max_total>=60 THEN 7
  WHEN earned*100.0/max_total>=50 THEN 6
  WHEN earned*100.0/max_total>=40 THEN 5
  ELSE 0
 END gp
 FROM course_marks
)

SELECT
 full_name,
 ROUND(SUM(gp*credits)/SUM(credits),2) cgpa
FROM graded
GROUP BY student_id,full_name
ORDER BY cgpa DESC;