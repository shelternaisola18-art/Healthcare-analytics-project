
--Patients demographics

SELECT 
COUNT(DISTINCT Name) as Unique_patients,
COUNT(*) as Total_admissions,
ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT Name), 2) as Avg_visits_per_patient
FROM Healthcare_dataset

--Patient readmission analysis
SELECT
Name,
COUNT(*) as Admission_count,
MIN(Date_of_admission) as First_admission,
MAX(Date_of_admission) as Last_admission,
SUM(Billing_amount) as Total_cost,
AVG(Length_of_stay) as Avg_Los
FROM Healthcare_dataset
GROUP BY Name
HAVING COUNT(*)>1
ORDER BY Admission_count DESC

--Age analysis 
SELECT
AVG(Age) as Avg_age,
MIN(Age) as Youngest_age,
MAX(Age) as Oldest_age
FROM Healthcare_dataset

--Age-gender-condition analysis
 SELECT
 CASE 
	 WHEN Age < 18 THEN 'Pediatric'
	 WHEN Age < 35 THEN 'Young Adult'
	 WHEN Age < 50 THEN 'Middle Age'
	 WHEN Age < 65 THEN 'Senior'
	 ELSE 'Elderly'
	 END as Age_group,
	 Gender,
	 Medical_condition,
	 COUNT(*) as Patient_count,
	 AVG(Billing_amount) as Avg_cost,
	 AVG(Length_of_stay) as Avg_los 
	 FROM Healthcare_dataset
	 GROUP BY Age, Gender, Medical_condition
	 ORDER BY Age_group, Patient_count  DESC


--Financial metrics
SELECT
SUM(Billing_amount) as Total_revenue,
AVG(Billing_amount) as Avg_bill,
MIN(Billing_amount) as Min_bill,
MAX(Billing_amount) as Max_bill
FROM Healthcare_dataset

--High-value patients 
SELECT Medical_condition,
COUNT(*) as Patient_count,
ROUND(AVG(Billing_amount), 2) AS Avg_revenue,
ROUND(SUM(Billing_amount), 2) AS Total_revenue
FROM Healthcare_dataset
GROUP BY  Medical_condition
ORDER BY Total_revenue DESC



--Insurance provider profitability
SELECT Insurance_provider,
COUNT(*) as Patient_count,
ROUND(AVG(Length_of_stay), 2) as Avg_los,
ROUND(SUM(Billing_amount), 2) as Total_revenue,
ROUND((SUM(Billing_amount) )/ COUNT(*), 2) as Revenue_per_patient
FROM Healthcare_dataset
GROUP BY Insurance_provider
ORDER BY Total_revenue DESC


-- Revenue over time
SELECT 
Datetrunc(Month, Date_of_admission) as Year_Month,
Count(*) as Admissions,
Sum(Billing_amount) as Total_revenue,
AVG(Billing_amount) as Average_bill
FROM Healthcare_dataset
GROUP BY Date_of_admission 
ORDER BY Year_Month asc
;

--Monthly revenue trends with growth rate
WITH Monthly_revenue AS (
SELECT
DATEPART(YEAR, Date_of_admission) as Year,
DATENAME(Month, Date_of_admission) as Month,
SUM(Billing_amount) as Revenue,
COUNT(*) as Admissions
FROM Healthcare_dataset
GROUP BY DATEPART(YEAR, Date_of_admission), DATENAME(Month, Date_of_admission)
)
SELECT 
Year, 
Month, 
Revenue, 
Admissions,
LAG(Revenue) OVER(ORDER BY Year, Month) as Prev_month_revenue,
ROUND(((Revenue- LAG (Revenue) OVER (ORDER BY Year, Month)) / 
LAG(Revenue) OVER (ORDER BY Year, Month)) * 100, 2) as Growth_rate
FROM Monthly_revenue
ORDER BY Year, Month




--Operational metrics

SELECT
AVG(Length_of_stay) as Avg_los,
SUM(Length_of_stay) as Total_bed_days
FROM Healthcare_dataset

--Admission types
SELECT
SUM(CASE WHEN Admission_type = 'Emergency' THEN 1 ELSE 0 END) as Emergency_admissions,
SUM(CASE WHEN Admission_type = 'Elective' THEN 1 ELSE 0 END) as Elective_admissions,
SUM(CASE WHEN Admission_type = 'Urgent' THEN 1 ELSE 0 END) as Urgent_admissions
FROM Healthcare_dataset

--Percentages 
SELECT
ROUND(SUM(CASE WHEN Admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) as Pct_emergency
FROM Healthcare_dataset


--Admission type cost benefit analysis
SELECT
Admission_type, 
Medical_condition,
COUNT(*) as Case_count,
AVG(Length_of_stay) as Avg_los,
AVG(Billing_amount) as Avg_bill,
SUM(Billing_amount) as Total_revenue,
ROUND(SUM(Billing_amount), 2 * 100 / (SELECT SUM(Billing_amount) FROM Healthcare_dataset),2) as Revenue_share
FROM Healthcare_dataset
GROUP BY Admission_type, Medical_condition
ORDER BY Total_revenue DESC
;


--Long stay patients
WITH Avg_los_by_condition as (
SELECT 
Medical_condition,
Avg(Length_of_stay) as Avg_los
FROM Healthcare_dataset
GROUP BY Medical_condition
)
SELECT 
H.Name,
H.Medical_condition,
H.Length_of_stay,
A.Avg_los as Typical_los,
H.Length_of_stay - A.Avg_los as Days_over_average,
H.Billing_amount
FROM Healthcare_dataset H
JOIN Avg_los_by_condition A on H.Medical_condition = A.Medical_condition
WHERE H.Length_of_stay > A.Avg_los * 1.5
order by Days_over_average DESC 
;


--Bed utilizations
WITH Daily_occupancy AS (
SELECT 
Hospital,
Date_of_admission,
COUNT(*) as Admissions,
SUM(Length_of_stay) as Total_bed_days
FROM Healthcare_dataset
GROUP BY Hospital, Date_of_admission
)
SELECT
Hospital,
AVG(Admissions) as Avg_daily_admissions,
MAX(Admissions) as Peak_admissions,
AVG(Total_bed_days) as Avg_bed_days_used
FROM Daily_occupancy
GROUP BY Hospital

--Seaonal admissions patterns
SELECT
CASE 
    WHEN MONTH(Date_of_admission) IN (12,1,2) THEN 'Winter'
    WHEN MONTH(Date_of_admission) IN (3,4,5) THEN 'Spring'
    WHEN MONTH(Date_of_admission) IN (6,7,8) THEN 'Summer'
    WHEN MONTH(Date_of_admission) IN (9,10,11) THEN 'Autumn'
END AS Season,
 DATENAME(MONTH, Date_of_admission) as Month,
DATEPART(YEAR, Date_of_admission) as Year,
Admission_type, 
COUNT(*) as Admissions,
AVG(Length_of_stay) as Avg_los
FROM Healthcare_dataset
GROUP BY DATEPART(YEAR,  Date_of_admission), DATENAME(MONTH, Date_of_admission), Admission_type, 
CASE 
    WHEN MONTH(Date_of_admission) IN (12,1,2) THEN 'Winter'
    WHEN MONTH(Date_of_admission) IN (3,4,5) THEN 'Spring'
    WHEN MONTH(Date_of_admission) IN (6,7,8) THEN 'Summer'
    WHEN MONTH(Date_of_admission) IN (9,10,11) THEN 'Autumn'
END

ORDER BY  year,Month, admissions DESC, Season


--Doctor perfomance metrics
SELECT Doctor,
COUNT(DISTINCT Name) as Unique_patients,
COUNT(*) as Total_cases,
SUM(Billing_amount) as Total_revenue,
AVG(Billing_amount) as Avg_revenue
FROM Healthcare_dataset
GROUP BY Doctor
HAVING COUNT(*) >= 10
ORDER BY Total_revenue DESC


