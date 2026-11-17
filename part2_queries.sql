CREATE DATABASE subbu_capstone_db;
USE subbu_capstone_db;

CREATE TABLE clinics (
  clinic_id VARCHAR(5) PRIMARY KEY, clinic_name VARCHAR(40) NOT NULL, city VARCHAR(20) NOT NULL,
  tier VARCHAR(10), latitude DECIMAL(8,4), longitude DECIMAL(8,4), temp_c DECIMAL(5,1));

CREATE TABLE appointments (
  appointment_id VARCHAR(8) PRIMARY KEY, patient_id VARCHAR(8) NOT NULL, clinic_id VARCHAR(5) NOT NULL,
  booked_on DATE, appt_date DATE, age INT, gender VARCHAR(1), distance_km DECIMAL(5,1), fee_inr INT,
  booking_channel VARCHAR(10), visit_type VARCHAR(12), reminder_sent VARCHAR(3), prior_no_shows INT,
  status VARCHAR(10), lead_days INT, no_show INT,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id));
USE subbu_capstone_db;
SELECT COUNT(*) FROM clinics;
SELECT COUNT(*), SUM(no_show) FROM appointments;
USE subbu_capstone_db;



INSERT INTO appointments VALUES ('A0001','P999','C01','2025-01-24','2025-01-25',30,'F',5.0,500,'App','Consultation','Yes',0,'Attended',1,0);
-- -----------------------------------------------
-- Note :CODE 1062. Duplicate entry 'A0001' for key 'appointments.PRIMARY'
-- -----------------------------------------------


USE subbu_capstone_db;

-- ------------------------------------------------------------
-- Clinics with at least 95 appointments, highest no-show rate first
-- ------------------------------------------------------------
SELECT c.clinic_name,
       c.city,
       COUNT(*) AS appointments,
       SUM(a.no_show) AS no_shows,
       ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
HAVING COUNT(*) >= 95
ORDER BY no_show_pct DESC;
-- -------------------------S-----------------------------------
-- All 8 clinics, highest no-show rate first
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Task 2.3: no-shows by lead-time band
-- ------------------------------------------------------------
SELECT CASE
           WHEN lead_days BETWEEN 1 AND 7 THEN '1-7'
           WHEN lead_days BETWEEN 8 AND 14 THEN '8-14'
           WHEN lead_days BETWEEN 15 AND 30 THEN '15-30'
           WHEN lead_days >= 31 THEN '31+'
       END AS lead_band,
       COUNT(*) AS appointments,
       SUM(no_show) AS no_shows,
       ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY lead_band
ORDER BY MIN(lead_days);

-- ------------------------------------------------------------
-- Task 2.4: month-by-month no-show trend
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT SUBSTR(appt_date, 1, 7) AS month,
           COUNT(*) AS appointments,
           ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT month,
       appointments,
       no_show_pct,
       no_show_pct - LAG(no_show_pct) OVER (ORDER BY month) AS change_pp
FROM monthly
ORDER BY month;


-- ------------------------------------------------------------
-- Task 2.5: rank clinics inside each city
-- ------------------------------------------------------------
WITH clinic_rates AS (
    SELECT c.clinic_name AS clinic,
           c.city AS city,
           ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments a
    JOIN clinics c ON a.clinic_id = c.clinic_id
    GROUP BY c.clinic_id, c.clinic_name, c.city
)
SELECT clinic,
       city,
       no_show_pct,
       RANK() OVER (PARTITION BY city ORDER BY no_show_pct DESC) AS rank_in_city,
       CASE
           WHEN no_show_pct > (SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 1) FROM appointments) THEN 'above'
           WHEN no_show_pct < (SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 1) FROM appointments) THEN 'below'
           ELSE 'equal'
       END AS vs_overall
FROM clinic_rates
ORDER BY city, rank_in_city;



