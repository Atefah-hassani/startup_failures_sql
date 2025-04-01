USE startup_failures; 

select * FROM startup_failures.finance_insurance;

ALTER TABLE startup_failures.finance_insurance
ADD finance_id INT AUTO_INCREMENT PRIMARY KEY;

SELECT * FROM startup_failures.finance_insurance;

ALTER TABLE startup_failures.food_service
ADD food_id INT AUTO_INCREMENT PRIMARY KEY;

SELECT * FROM startup_failures.food_service;

ALTER TABLE startup_failures.healthcare
ADD health_id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE startup_failures.healthcare 
ADD CONSTRAINT fk_sector FOREIGN KEY (sector) 
REFERENCES startup_failures.startup_failures(sector);

SHOW COLUMNS FROM startup_failures.startup_failures;
SHOW COLUMNS FROM startup_failures.healthcare;


CREATE TABLE sectors (
    sector_id INT AUTO_INCREMENT PRIMARY KEY,
    sector_name VARCHAR(255) UNIQUE NOT NULL
);

SELECT * FROM sectors; 

INSERT INTO sectors (sector_name)
SELECT DISTINCT sector FROM startup_failures.startup_failures;

ALTER TABLE startup_failures ADD COLUMN sector_id INT;
ALTER TABLE healthcare ADD COLUMN sector_id INT;

SELECT * FROM startup_failures;

SHOW TABLES;

SET SQL_SAFE_UPDATES = 0;

UPDATE startup_failures sf
JOIN sectors s ON sf.sector = s.sector_name
SET sf.sector_id = s.sector_id;

UPDATE healthcare h
JOIN sectors s ON h.sector = s.sector_name
SET h.sector_id = s.sector_id;

ALTER TABLE startup_failures 
ADD CONSTRAINT fk_startup_sector FOREIGN KEY (sector_id) REFERENCES sectors(sector_id);

ALTER TABLE healthcare 
ADD CONSTRAINT fk_healthcare_sector FOREIGN KEY (sector_id) REFERENCES sectors(sector_id);

SELECT * FROM sectors
ORDER BY sector_id ASC; 


ALTER TABLE finance_insurance ADD COLUMN sector_id INT;
ALTER TABLE food_service ADD COLUMN sector_id INT;
ALTER TABLE information ADD COLUMN sector_id INT;
ALTER TABLE manufacturing ADD COLUMN sector_id INT;
ALTER TABLE retail ADD COLUMN sector_id INT;


UPDATE finance_insurance fi
JOIN sectors s ON fi.sector = s.sector_name
SET fi.sector_id = s.sector_id;

UPDATE food_service fs
JOIN sectors s ON fs.sector = s.sector_name
SET fs.sector_id = s.sector_id;

UPDATE information inf
JOIN sectors s ON inf.sector = s.sector_name
SET inf.sector_id = s.sector_id;

UPDATE manufacturing mf
JOIN sectors s ON mf.sector = s.sector_name
SET mf.sector_id = s.sector_id;

UPDATE retail rt
JOIN sectors s ON rt.sector = s.sector_name
SET rt.sector_id = s.sector_id;



ALTER TABLE finance_insurance 
ADD CONSTRAINT fi_startup_sector FOREIGN KEY (sector_id) REFERENCES sectors(sector_id);

ALTER TABLE food_service 
ADD CONSTRAINT fs_startup_sector FOREIGN KEY (sector_id) REFERENCES sectors(sector_id);

ALTER TABLE information
ADD CONSTRAINT inf_startup_sector FOREIGN KEY (sector_id) REFERENCES sectors(sector_id);

ALTER TABLE manufacturing
ADD CONSTRAINT mf_startup_sector FOREIGN KEY (sector_id) REFERENCES sectors(sector_id);

ALTER TABLE retail 
ADD CONSTRAINT rt_startup_sector FOREIGN KEY (sector_id) REFERENCES sectors(sector_id);


ALTER TABLE information
ADD info_id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE manufacturing
ADD mnf_id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE retail
ADD rt_id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE startup_failures
ADD sf_id INT AUTO_INCREMENT PRIMARY KEY;


-- Step 1: Calculate years of operation before failure
ALTER TABLE startup_failures ADD COLUMN years_operated INT;

UPDATE startup_failures 
SET years_operated = end_year - start_year;

-- Step 2: Categorize startups into funding levels
ALTER TABLE startup_failures ADD COLUMN funding_level VARCHAR(20);

ALTER TABLE finance_insurance
CHANGE COLUMN amount_raised_cleaned amount_raised VARCHAR(255);

Select * FROM startup_failures;


-- Step 2: Categorize startups into funding levels
ALTER TABLE startup_failures ADD COLUMN funding_level VARCHAR(20);
UPDATE startup_failures
SET funding_level =
    CASE 
        WHEN amount_raised < 1 THEN '<$1M'
        WHEN amount_raised BETWEEN 1 AND 10 THEN '$1M-$10M'
        WHEN amount_raised BETWEEN 10 AND 50 THEN '$10M-$50M'
        WHEN amount_raised BETWEEN 50 AND 100 THEN '$50M-$100M'
        WHEN amount_raised BETWEEN 100 AND 500 THEN '$100M-$500M'
        WHEN amount_raised BETWEEN 500 AND 1000 THEN '$500M-$1B'
        ELSE '>$1B'
    END;
    
DESC startup_failures;
    
UPDATE startup_failures 
SET sector = 'Unknown' 
WHERE sector IS NULL;

ALTER TABLE startup_failures ADD COLUMN amount_raised DECIMAL(15,2);


UPDATE startup_failures sf
JOIN finance_insurance fi ON sf.name = fi.name
SET sf.amount_raised = fi.amount_raised;

UPDATE startup_failures sf
JOIN food_service fs ON fs.name = fs.name
SET fs.amount_raised = fs.amount_raised;

UPDATE startup_failures sf
JOIN information inf ON inf.name = inf.name
SET inf.amount_raised = inf.amount_raised;

UPDATE startup_failures sf
JOIN manufacturing mnf ON mnf.name = mnf.name
SET mnf.amount_raised = mnf.amount_raised;


UPDATE startup_failures sf
JOIN retail rt ON sf.name = rt.name
SET sf.amount_raised = rt.amount_raised
WHERE rt.amount_raised IS NOT NULL;

UPDATE startup_failures sf
JOIN retail rt ON sf.rt_id = rt.rt_id
SET sf.amount_raised = rt.amount_raised
WHERE rt.amount_raised IS NOT NULL;

SELECT * FROM startup_failures;

SELECT sector FROM retail;

UPDATE startup_failures
SET funding_level =
    CASE 
        WHEN amount_raised < 1 THEN '<$1M'
        WHEN amount_raised BETWEEN 1 AND 10 THEN '$1M-$10M'
        WHEN amount_raised BETWEEN 10 AND 50 THEN '$10M-$50M'
        WHEN amount_raised BETWEEN 50 AND 100 THEN '$50M-$100M'
        WHEN amount_raised BETWEEN 100 AND 500 THEN '$100M-$500M'
        WHEN amount_raised BETWEEN 500 AND 1000 THEN '$500M-$1B'
		ELSE '>$1B'
    END;
    
    SELECT 
    funding_level, 
    COUNT(CASE WHEN end_year IS NOT NULL AND end_year < YEAR(CURDATE()) THEN 1 END) AS failed_startups,
    COUNT(*) AS total_startups,
    ROUND(
        COUNT(CASE WHEN end_year IS NOT NULL AND end_year < YEAR(CURDATE()) THEN 1 END) / COUNT(*) * 100, 
        2
    ) AS failure_rate
FROM startup_failures
GROUP BY funding_level
ORDER BY funding_level ASC;

SELECT 
    funding_level, 
    COUNT(*) AS total_failed_startups,
    ROUND(AVG(end_year - start_year), 2) AS avg_survival_years,
    MIN(end_year - start_year) AS min_survival_years,
    MAX(end_year - start_year) AS max_survival_years
FROM startup_failures
WHERE start_year IS NOT NULL AND end_year IS NOT NULL
GROUP BY funding_level
ORDER BY avg_survival_years DESC;


ALTER TABLE finance_insurance ADD COLUMN survival_years INT;
UPDATE finance_insurance 
SET survival_years = end_year - start_year;

-- only the existing failure factors

SELECT 'competition' AS factor, COUNT(*) AS count FROM finance_insurance WHERE competition = 1 AND survival_years < 5
UNION ALL
SELECT 'no_budget', COUNT(*) FROM finance_insurance WHERE no_budget = 1 AND survival_years < 5
UNION ALL
SELECT 'monetization_failure', COUNT(*) FROM finance_insurance WHERE monetization_failure = 1 AND survival_years < 5
UNION ALL
SELECT 'poor_market_fit', COUNT(*) FROM finance_insurance WHERE poor_market_fit = 1 AND survival_years < 5
ORDER BY count DESC;



SELECT 'competition' AS factor, COUNT(*) AS count 
FROM food_service 
WHERE competition = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'no_budget', COUNT(*) 
FROM food_service 
WHERE no_budget = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'monetization_failure', COUNT(*) 
FROM food_service 
WHERE monetization_failure = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'poor_market_fit', COUNT(*) 
FROM food_service 
WHERE poor_market_fit = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'acquisition_stagnation', COUNT(*) 
FROM food_service 
WHERE acquisition_stagnation = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'high_operational_costs', COUNT(*) 
FROM food_service 
WHERE high_operational_costs = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'niche_limits', COUNT(*) 
FROM food_service 
WHERE niche_limits = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'execution_flaws', COUNT(*) 
FROM food_service 
WHERE execution_flaws = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'trend_shifts', COUNT(*) 
FROM food_service 
WHERE trend_shifts = 1 AND (end_year - start_year) < 5

ORDER BY count DESC;


SELECT 'giants' AS factor, COUNT(*) AS count 
FROM healthcare 
WHERE giants = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'no_budget', COUNT(*) FROM healthcare WHERE no_budget = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'competition', COUNT(*) FROM healthcare WHERE competition = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'poor_market_fit', COUNT(*) FROM healthcare WHERE poor_market_fit = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'acquisition_stagnation', COUNT(*) FROM healthcare WHERE acquisition_stagnation = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'platform_dependency', COUNT(*) FROM healthcare WHERE platform_dependency = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'monetization_failure', COUNT(*) FROM healthcare WHERE monetization_failure = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'niche_limits', COUNT(*) FROM healthcare WHERE niche_limits = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'execution_flaws', COUNT(*) FROM healthcare WHERE execution_flaws = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'trend_shifts', COUNT(*) FROM healthcare WHERE trend_shifts = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'trust_issue', COUNT(*) FROM healthcare WHERE trust_issue = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'regulatory_pressure', COUNT(*) FROM healthcare WHERE regulatory_pressure = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'overhype', COUNT(*) FROM healthcare WHERE overhype = 1 AND (end_year - start_year) < 5 

ORDER BY count DESC;


SELECT 'giants' AS factor, COUNT(*) AS count FROM information WHERE giants = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'no_budget', COUNT(*) FROM information WHERE no_budget = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'competition', COUNT(*) FROM information WHERE competition = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'poor_market_fit', COUNT(*) FROM information WHERE poor_market_fit = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'acquisition_stagnation', COUNT(*) FROM information WHERE acquisition_stagnation = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'platform_dependency', COUNT(*) FROM information WHERE platform_dependency = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'monetization_failure', COUNT(*) FROM information WHERE monetization_failure = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'niche_limits', COUNT(*) FROM information WHERE niche_limits = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'execution_flaws', COUNT(*) FROM information WHERE execution_flaws = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'trend_shifts', COUNT(*) FROM information WHERE trend_shifts = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'trust_issue', COUNT(*) FROM information WHERE trust_issue = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'regulatory_pressure', COUNT(*) FROM information WHERE regulatory_pressure = 1 AND (end_year - start_year) < 5
UNION ALL
SELECT 'overhype', COUNT(*) FROM information WHERE overhype = 1 AND (end_year - start_year) < 5
ORDER BY count DESC;



SELECT 'competition' AS factor, COUNT(*) AS count FROM manufacturing WHERE competition = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'no_budget', COUNT(*) FROM manufacturing WHERE no_budget = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'regulatory_pressure', COUNT(*) FROM manufacturing WHERE regulatory_pressure = 1 AND (end_year - start_year) < 5

UNION ALL

SELECT 'monetization_failure', COUNT(*) FROM manufacturing WHERE monetization_failure = 1 AND (end_year - start_year) < 5

ORDER BY count DESC;



SELECT 'competition' AS factor, COUNT(*) AS count FROM retail WHERE competition = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'no_budget', COUNT(*) FROM retail WHERE no_budget = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'poor_market_fit', COUNT(*) FROM retail WHERE poor_market_fit = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'acquisition_stagnation', COUNT(*) FROM retail WHERE acquisition_stagnation = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'platform_dependency', COUNT(*) FROM retail WHERE platform_dependency = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'monetization_failure', COUNT(*) FROM retail WHERE monetization_failure = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'niche_limits', COUNT(*) FROM retail WHERE niche_limits = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'execution_flaws', COUNT(*) FROM retail WHERE execution_flaws = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'trend_shifts', COUNT(*) FROM retail WHERE trend_shifts = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'trust_issue', COUNT(*) FROM retail WHERE trust_issue = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'regulatory_pressure', COUNT(*) FROM retail WHERE regulatory_pressure = 1 AND (end_year - start_year) < 5 

UNION ALL

SELECT 'overhype', COUNT(*) FROM retail WHERE overhype = 1 AND (end_year - start_year) < 5 

ORDER BY count DESC;









