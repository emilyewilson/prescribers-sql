--1. 
--    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(prescription.total_claim_count) AS claim_count
FROM prescriber
INNER JOIN prescription USING (npi)
GROUP BY npi
ORDER BY claim_count DESC;

--	 b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(prescription.total_claim_count) AS claim_count
FROM prescriber
INNER JOIN prescription USING (npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY claim_count DESC;

--2. 
--    a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(prescription.total_claim_count) AS claim_count
FROM prescriber
INNER JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY claim_count DESC;
--family practice has the highest

--    b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(prescription.total_claim_count) AS claim_count, drug.opioid_drug_flag
FROM prescriber INNER JOIN prescription USING (npi)
				INNER JOIN drug USING (drug_name)
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty_description, drug.opioid_drug_flag
ORDER BY claim_count DESC;
--nurse practitioner has the highest claims for opioids

--    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT DISTINCT(specialty_description), prescription.total_claim_count
FROM prescriber LEFT JOIN prescription USING(npi)
WHERE prescription.total_claim_count IS NULL;

SELECT DISTINCT specialty_description
FROM prescriber
WHERE NOT EXISTS
    (SELECT *
     FROM prescription
     WHERE prescriber.npi =prescription.npi)

--    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?


--3. 
--    a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost) AS total_drug_cost
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;
--INSULIN GLARGINE,HUM.REC.ANLOG has the highest total drug cost

--    b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply),2) AS cost_per_day
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;
--C1 ESTERASE INHIBITOR
---- ROUND(SUM(total_drug_cost) / SUM(total_day_supply),2)
---  ROUND(SUM(total_drug_cost/total_day_supply),2)

--4. 
--    a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT DISTINCT drug_name,
	CASE WHEN opioid_drug_flag = 'y' THEN 'opioid' 	
		 WHEN antibiotic_drug_flag = 'Y' THEN  'antibiotic'
		 ELSE 'neither'
		 END AS drug_type
FROM drug
GROUP BY drug_name, drug_type;
	
--	  b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT DISTINCT SUM(total_drug_cost::money) AS total_drug_cost,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 	
		 WHEN antibiotic_drug_flag = 'Y' THEN  'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY drug_type, opioid_drug_flag, antibiotic_drug_flag
ORDER BY total_drug_cost DESC;
--more money spent on opioids

-- 5. 
--    a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(*)
FROM cbsa
WHERE cbsaname ILIKE '%, TN';
--56 CSBAs in TN and additional states, 33 TN specific

--    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT SUM(p.population), c.cbsaname
FROM cbsa AS c
INNER JOIN population AS p
USING( fipscounty)
GROUP BY  c.cbsaname 
ORDER BY SUM(p.population) DESC;
--Nashville-Davidson--Murfreesboro--Franklin, TN has the highest. Morristown, TN has the lowest

--    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT population, county
FROM population
FULL JOIN cbsa USING(fipscounty)
FULL JOIN fips_county USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC NULLS LAST;


-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >=3000;

--    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'not opioid' END AS opioid_flag
FROM prescription INNER JOIN drug USING(drug_name)
WHERE total_claim_count >=3000;

--    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name, total_claim_count, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name,
	CASE WHEN opioid_drug_flag = 'Y'THEN 'opioid'
	ELSE 'not opioid' END AS opioid_flag
FROM prescription INNER JOIN drug USING(drug_name)
				  INNER JOIN prescriber USING(npi)
WHERE total_claim_count >=3000;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
--    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, drug_name, specialty_description 
FROM prescriber CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	  AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'
GROUP BY npi, drug_name, specialty_description
ORDER BY npi;


--    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi, drug.drug_name, SUM(total_claim_count)
FROM prescriber CROSS JOIN drug
	LEFT JOIN prescription USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	  AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name
ORDER BY SUM(total_claim_count) DESC;
	
--    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE 
SELECT npi, drug.drug_name, COALESCE(SUM(total_claim_count),0) AS total_claim
FROM prescriber CROSS JOIN drug
	LEFT JOIN prescription USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	  AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name
ORDER BY SUM(total_claim_count) DESC;






























