IF DB_ID('hospital_db') IS NULL
CREATE DATABASE hospital_db
GO

USE hospital_db
GO
Select * from sys.tables;

CREATE TABLE departments (
    dept_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

CREATE TABLE doctors (
    doctor_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100),
    dept_id INT,
    phone VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);


CREATE TABLE patients (
    patient_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    dob DATE,
    gender VARCHAR(10) CHECK (gender IN ('Male','Female','Other')),
    phone VARCHAR(15),
    blood_group VARCHAR(5),
    registered_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE appointments (
    appt_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appt_date DATETIME NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled'
        CHECK (status IN ('scheduled','completed','cancelled')),
    notes TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE diagnoses (
    diagnosis_id INT IDENTITY(1,1) PRIMARY KEY,
    appt_id INT NOT NULL,
    icd_code VARCHAR(10),
    description TEXT NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('mild','moderate','severe')),
    FOREIGN KEY (appt_id) REFERENCES appointments(appt_id)
);

CREATE TABLE medicines (
    medicine_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit_cost DECIMAL(8,2) NOT NULL,
    stock_qty INT DEFAULT 0
);

CREATE TABLE prescriptions (
    pres_id INT IDENTITY(1,1) PRIMARY KEY,
    appt_id INT NOT NULL,
    medicine_id INT NOT NULL,
    dosage VARCHAR(50),
    days INT,
    qty INT,
    FOREIGN KEY (appt_id) REFERENCES appointments(appt_id),
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
);

CREATE TABLE lab_tests (
    test_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT NOT NULL,
    test_name VARCHAR(100),
    test_date DATE,
    result TEXT,
    cost DECIMAL(8,2),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);


CREATE TABLE bills (
    bill_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT NOT NULL,
    appt_id INT,
    consultation_fee DECIMAL(8,2) DEFAULT 500.00,
    medicine_cost DECIMAL(8,2) DEFAULT 0.00,
    lab_cost DECIMAL(8,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2),
    payment_status VARCHAR(20) DEFAULT 'unpaid'
        CHECK (payment_status IN ('unpaid','paid','partial')),
    billed_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (appt_id) REFERENCES appointments(appt_id)
);


CREATE TABLE patient_audit_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT,
    action VARCHAR(50),
    changed_at DATETIME DEFAULT GETDATE()
);


-- ??? SAMPLE DATA ???????????????????????????????????????????
SET IDENTITY_INSERT departments OFF;
select * from departments;
INSERT INTO departments VALUES
('Cardiology','Block A'),('Neurology','Block B'),
('Orthopedics','Block C'),('General Medicine','Block D');

INSERT INTO doctors(full_name, specialization, dept_id, phone, email) VALUES
('Dr. Ramesh Kumar','Cardiologist',      1,'9000001111','ramesh@hospital.com'),
('Dr. Sunita Rao',  'Neurologist',       2,'9000002222','sunita@hospital.com'),
('Dr. Arvind Shah', 'Orthopedic Surgeon',3,'9000003333','arvind@hospital.com'),
('Dr. Meena Joshi', 'General Physician', 4,'9000004444','meena@hospital.com');

INSERT INTO patients(full_name, dob, gender, phone, blood_group) VALUES
('Suresh Nair',  '1980-05-12','Male',  '9111111111','O+'),
('Kavita Mehta', '1990-08-25','Female','9222222222','A+'),
('Deepak Sharma','1975-03-30','Male',  '9333333333','B+'),
('Anjali Reddy', '2000-11-05','Female','9444444444','AB+'),
('Vikram Singh', '1965-07-19','Male',  '9555555555','O-');

INSERT INTO appointments(patient_id, doctor_id, appt_date, status, notes) VALUES
(1,1,'2024-01-10 10:00:00','completed','Chest pain follow-up'),
(2,2,'2024-01-11 11:00:00','completed','Recurring headaches'),
(3,3,'2024-01-12 09:00:00','completed','Knee pain'),
(4,4,'2024-01-13 14:00:00','completed','Fever and cold'),
(5,1,'2024-01-15 10:30:00','scheduled','Annual cardiac checkup');

INSERT INTO diagnoses(appt_id, icd_code, description, severity) VALUES
(1,'I20.9','Angina Pectoris',        'moderate'),
(2,'G43.9','Migraine without aura',  'mild'),
(3,'M17.9','Osteoarthritis of knee', 'moderate'),
(4,'J06.9','Acute upper respiratory','mild');

INSERT INTO medicines(name, unit_cost, stock_qty) VALUES
('Aspirin 75mg',5.00,500),('Atorvastatin',12.00,300),
('Sumatriptan',45.00,150),('Paracetamol', 3.50,800),
('Amoxicillin',18.00,400);

INSERT INTO prescriptions(appt_id, medicine_id, dosage, days, qty) VALUES
(1,1,'Once daily',30,30),(1,2,'Once daily',30,30),
(2,3,'As needed', 10, 5),
(3,4,'Thrice daily',7,21),
(4,4,'Twice daily',5,10),(4,5,'Twice daily',7,14);

INSERT INTO lab_tests(patient_id, test_name, test_date, result, cost) VALUES
(1,'ECG',          '2024-01-10','ST depression noted', 500.00),
(1,'Lipid Profile','2024-01-10','LDL: 145mg/dL',       800.00),
(2,'MRI Brain',    '2024-01-11','No acute findings',   3500.00),
(4,'CBC',          '2024-01-13','WBC elevated',         350.00);

INSERT INTO bills(patient_id,appt_id,consultation_fee,medicine_cost,lab_cost,total_amount,payment_status) VALUES
(1,1,500.00, 510.00,1300.00,2310.00,'paid'),
(2,2,500.00, 225.00,3500.00,4225.00,'paid'),
(3,3,500.00,  73.50,   0.00, 573.50,'unpaid'),
(4,4,500.00, 287.00, 350.00,1137.00,'partial');



UPDATE appointments 
SET status = 'completed' 
WHERE appt_id = 5;

UPDATE bills 
SET payment_status = 'paid' 
WHERE patient_id = 3;

UPDATE medicines 
SET stock_qty = stock_qty + 200 
WHERE medicine_id = 3;

CREATE PROCEDURE GenerateBill
@p_appt_id INT
AS
BEGIN

DECLARE @v_patient_id INT
DECLARE @v_med_cost DECIMAL(10,2)
DECLARE @v_lab_cost DECIMAL(10,2)
DECLARE @v_consultation DECIMAL(8,2) = 500.00
DECLARE @v_total DECIMAL(10,2)

SELECT @v_patient_id = patient_id
FROM appointments
WHERE appt_id = @p_appt_id

SELECT @v_med_cost = ISNULL(SUM(pr.qty * m.unit_cost),0)
FROM prescriptions pr
JOIN medicines m
ON pr.medicine_id = m.medicine_id
WHERE pr.appt_id = @p_appt_id

SELECT @v_lab_cost = ISNULL(SUM(cost),0)
FROM lab_tests
WHERE patient_id = @v_patient_id

SET @v_total = @v_consultation + @v_med_cost + @v_lab_cost

INSERT INTO bills
(patient_id,appt_id,consultation_fee,medicine_cost,lab_cost,total_amount)
VALUES
(@v_patient_id,@p_appt_id,@v_consultation,@v_med_cost,@v_lab_cost,@v_total)

SELECT 'Bill generated: Rs.' + CAST(@v_total AS VARCHAR)

END

EXEC GenerateBill 1

CREATE TRIGGER trg_patient_audit
ON patients
AFTER INSERT
AS
BEGIN

INSERT INTO patient_audit_log(patient_id, action)
SELECT patient_id,'NEW_PATIENT_REGISTERED'
FROM inserted

END


CREATE OR ALTER VIEW vw_patient_summary AS
SELECT
    p.patient_id,
    p.full_name,
    p.blood_group,
    COUNT(DISTINCT a.appt_id) AS total_visits,
    COUNT(DISTINCT lt.test_id) AS total_lab_tests,
    ISNULL(SUM(b.total_amount),0) AS total_billed
FROM patients p
LEFT JOIN appointments a ON p.patient_id = a.patient_id
LEFT JOIN lab_tests lt ON p.patient_id = lt.patient_id
LEFT JOIN bills b ON p.patient_id = b.patient_id
GROUP BY p.patient_id, p.full_name, p.blood_group;


CREATE INDEX idx_appt_patient ON appointments(patient_id)
CREATE INDEX idx_appt_doctor ON appointments(doctor_id)
CREATE INDEX idx_pres_appt ON prescriptions(appt_id)
CREATE INDEX idx_bill_patient ON bills(patient_id)


WITH severe_cases AS
(
SELECT a.patient_id, COUNT(*) AS severe_count
FROM diagnoses diag
JOIN appointments a
ON diag.appt_id = a.appt_id
WHERE diag.severity = 'severe'
GROUP BY a.patient_id
),

high_bill AS
(
SELECT patient_id, SUM(total_amount) AS total_bill
FROM bills
GROUP BY patient_id
HAVING SUM(total_amount) > 3000
)

SELECT
p.full_name,
p.phone,
p.blood_group,
ISNULL(sc.severe_count,0) AS severe_diagnoses,
hb.total_bill
FROM patients p
LEFT JOIN severe_cases sc ON p.patient_id = sc.patient_id
LEFT JOIN high_bill hb ON p.patient_id = hb.patient_id
WHERE sc.patient_id IS NOT NULL
OR hb.patient_id IS NOT NULL;