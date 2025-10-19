 USE PortLogistics;

--1. Overall Port Performance
--Which UK ports handled the highest total tonnage in the latest year?
SELECT TOP 1
	Port,
	SUM(Tonnage_thousands) As Tonnage_Last_Year,
	Year
FROM dbo.Port0302
GROUP BY Port, Year
HAVING Year = 2024
ORDER BY SUM(Tonnage_thousands) DESC;


--Which ports handled the largest number of containers (TEUs)?
SELECT TOP 1
	Port,
	SUM(TEU_thousands) As TEU_thousands
FROM dbo.Port0302
GROUP BY Port
ORDER BY SUM(TEU_thousands) DESC;


--What are the top 10 ports by total traffic (inwards + outwards)?
SELECT TOP 10
	Port,
	SUM(Units_thousands) As Traffic_BothDirections
FROM dbo.Port0302
GROUP BY Port
ORDER BY SUM(Units_thousands) DESC;

--How has total port activity changed compared to previous years (growth or decline)?
WITH previous_year AS (
	SELECT 
		SUM(Units_thousands) AS Units_previous_year
	FROM dbo.Port0302
	WHERE Year = 2023
), 
current_year AS(
	SELECT 
		SUM(Units_thousands) AS Units_current_year
	FROM dbo.Port0302
	WHERE Year = 2024
)
SELECT 
	'AllPorts' As Ports, 
	Units_previous_year, 
	Units_current_year, 
	Units_previous_year - Units_current_year AS Change_in_units
FROM previous_year, current_year;

--2. Domestic Vs International 
--What percentage of total cargo is domestic vs international?
WITH tr AS(
	SELECT 
		Region_1,
		SUM(Tonnage_thousands) AS total_tonnage_region
	FROM dbo.Port0302
	GROUP BY Region_1
)
SELECT 
	Region_1 AS Region, 
	ROUND(100*(total_tonnage_region/SUM(total_tonnage_region) OVER ()), 2) AS Tonnage_Percentage
FROM tr;

--Which ports handle mostly international trade, and which are domestic hubs?
WITH i AS(
	SELECT 
		Port, 
		SUM(Tonnage_thousands) AS International_Units
	FROM dbo.Port0302
	WHERE Region_1 = 'International'
	GROUP BY Port
),

d AS (
	SELECT
		Port, 
		SUM(Tonnage_thousands) AS Domestic_Units
	FROM dbo.Port0302
	WHERE Region_1 = 'Domestic'
	GROUP BY Port
)

SELECT 
	i.Port,
	International_Units,
	Domestic_Units,
	CASE WHEN International_Units > Domestic_Units THEN 'International'
		 WHEN Domestic_Units > International_Units THEN 'Domestic'
		 WHEN Domestic_Units = International_Units THEN 'Tie'
		 ELSE 'N/A' 
	END AS Trade
FROM i
FULL OUTER JOIN d 
ON i.Port = d.Port;

--Are there specific regions that rely heavily on domestic shipping routes?
WITH i AS(
	SELECT 
		Port, 
		SUM(Units_thousands) AS International_Units
	FROM dbo.Port0302
	WHERE Region_1 = 'International'
	GROUP BY Port
),

d AS (
	SELECT
		Port, 
		SUM(Units_thousands) AS Domestic_Units
	FROM dbo.Port0302
	WHERE Region_1 = 'Domestic'
	GROUP BY Port
)

SELECT 
	i.Port,
	100*(Domestic_Units/(International_Units + Domestic_Units)) As Domestic_Units_Pct
FROM i
INNER JOIN d
ON d.Port = i.Port
WHERE Domestic_Units > International_Units
ORDER BY 100*(Domestic_Units/(International_Units + Domestic_Units));
	 
--3. Cargo Type Analysis
--What are the major cargo categories handled?
SELECT DISTINCT(Cargo_Group_Name)
FROM dbo.Port0302;

--How has each cargo type changed year-over-year?
WITH l AS (
	SELECT Cargo_Group_Name, 
		SUM(Tonnage_thousands) AS l_Units
	FROM dbo.Port0302
	WHERE Year = 2023 
	GROUP BY Cargo_Group_Name
), 

c AS (
	SELECT Cargo_Group_Name, 
		SUM(Tonnage_thousands) AS c_Units
	FROM dbo.Port0302
	WHERE Year = 2024
	GROUP BY Cargo_Group_Name
)

SELECT
	c.Cargo_Group_Name,
	l_Units, 
	c_Units, 
	c_Units - l_Units AS Change
	FROM l
	INNER JOIN c
	ON l.Cargo_Group_Name = c.Cargo_Group_Name
	ORDER BY c_Units - l_Units;

--Which ports specialize in particular cargo types ?
WITH C AS (
	SELECT 
		Year,
		Port,
		Cargo_Group_Name,
		SUM(Tonnage_thousands) AS Year_Tonnage
	FROM dbo.Port0302
	GROUP BY Year, Cargo_Group_Name, Port
	
),

m AS (
	SELECT 
		C.Cargo_Group_Name AS Cargo_Group,
		MAX(C.Year_Tonnage) AS Max_Tonnage
	FROM C
	GROUP BY C.Cargo_Group_Name
)

SELECT 
	m.Cargo_Group,
	C.Port,
	m.Max_Tonnage
	
FROM m
INNER JOIN C
ON C.Cargo_Group_Name = m.Cargo_Group
AND m.Max_Tonnage = C.Year_Tonnage;


--What proportion of total tonnage is containerized (Lo-Lo) vs non-containerized
SELECT
	CASE
		WHEN Cargo_Group_Name = 'Lo-Lo' THEN 'Lo-Lo'
		ELSE 'Non-Containerized'
	END AS Cargo_Group,
	SUM(Tonnage_thousands) AS Tonnage_thousands
FROM dbo.Port0302
GROUP BY 
	CASE
		WHEN Cargo_Group_Name = 'Lo-Lo' THEN 'Lo-Lo'
		ELSE 'Non-Containerized'
	END;

--4. Trade Direction and Flow
--How much freight is imported (Inwards) vs exported (Outwards)?
SELECT 
	Direction,
	SUM(Tonnage_thousands) AS Tonnage_thousands
FROM dbo.Port0302
GROUP BY Direction
HAVING Direction <> 'Both Directions';


--Are certain ports export-dominant or import-dominant?
WITH e AS (
	SELECT 
		Port, 
		SUM(Tonnage_thousands) AS exported_Units
	FROM dbo.Port0302
	WHERE Direction = 'Outwards'
	GROUP BY Port
),
i AS (
	SELECT 
		Port, 
		SUM(Tonnage_thousands) AS imported_Units
	FROM dbo.Port0302
	WHERE Direction = 'Inwards'
	GROUP BY Port
)
SELECT 
	i.Port,
	exported_Units,
	imported_Units,
	CASE
		WHEN exported_Units > imported_Units THEN 'Export Dominant'
		WHEN exported_Units < imported_Units THEN 'Import Dominant'
		ELSE 'Balanced'
	END AS Export_Import_Status
FROM i
FULL OUTER JOIN e
	ON i.Port = e.Port
WHERE exported_Units <> 0 AND imported_Units <> 0
ORDER BY Port;


--Main - Regional and Country-Level Analysis

--1. How is total freight distributed across England, Scotland, Wales, and Northern Ireland?
WITH U AS (
	SELECT 
		Port_UK_Country, 
		SUM(Units_thousands) AS Units
	FROM dbo.Port0302
	GROUP BY Port_UK_Country
),

S AS (
	SELECT
		SUM(Units_thousands) AS Total
	FROM dbo.Port0302
)

SELECT 
	Port_UK_Country,
	Units,
	100*(Units/Total) As Units_Pct
FROM U, S
ORDER BY Units;


--2. Which regions (e.g. South East England, Scottish Highlands) show strong growth?
WITH l AS (
	SELECT 
		Port_UK_Country, 
		SUM(Units_thousands) AS last_year_Units
	FROM dbo.Port0302
	WHERE Year = 2023
	GROUP BY Port_UK_Country
),

c AS (
	SELECT 
		Port_UK_Country, 
		SUM(Units_thousands) AS current_year_Units
	FROM dbo.Port0302
	WHERE Year = 2024
	GROUP BY Port_UK_Country
)

SELECT 
	l.Port_UK_Country,
	l.last_year_Units,
	c.current_year_Units,
	(c.current_year_Units - l.last_year_Units) AS Change
FROM l
INNER JOIN c
ON l.Port_UK_Country = c.Port_UK_Country
ORDER BY (c.current_year_Units - l.last_year_Units);

--3. Are there regional imbalances in port activity?
With d AS(
	SELECT
		Port,
		SUM(Tonnage_thousands) As Domestic_Tonnage
	FROM dbo.Port0302
	WHERE Region_1 = 'Domestic'
	GROUP BY Port
), 

i AS (
	SELECT
		Port,
		SUM(Tonnage_thousands) As International_Tonnage
	FROM dbo.Port0302
	WHERE Region_1 = 'International'
	GROUP BY Port
)
SELECT 
	d.Port,
	Domestic_Tonnage,
	International_Tonnage,
	ABS(International_Tonnage - Domestic_Tonnage) AS Difference,
	CASE
		WHEN 100.0*(ABS(International_Tonnage - Domestic_Tonnage))/ABS(International_Tonnage + Domestic_Tonnage) > 15 THEN 'Imbalance'
		ELSE 'Balanced'
	END AS Port_Activity
FROM d
INNER JOIN i
ON i.Port = d.Port
WHERE ABS(International_Tonnage - Domestic_Tonnage) <> 0
ORDER BY i.Port;

-- Infrastructure and Capacity Considerations

--1. Are top-performing ports nearing their capacity limits (TEUs handled per year)?

WITH m AS (
SELECT 
	Port,
	MAX(SUM(TEU_thousands)) OVER (PARTITION BY Port) AS Max_Teu
FROM dbo.Port0302
GROUP BY Port, Year
),

s AS(
SELECT 
	Port,
	Year,
	SUM(TEU_thousands) AS TEU_SUM
FROM dbo.Port0302
GROUP BY Port, Year
)
SELECT 
	TOP 20 s.Port,
	s.Year,
	AVG(s.TEU_SUM) AS TEU_SUM,
	AVG(m.Max_Teu) AS Max_TEU,
	100.0*(AVG(s.TEU_SUM) /AVG(m.Max_Teu) ) AS Capacity_Used
FROM s
INNER JOIN m
ON s.Port = m.Port
WHERE s.Year IN (2023, 2024)
GROUP BY s.Port, s.Year
ORDER BY AVG(s.TEU_SUM) DESC, s.Port, s.Year;


--2. Which smaller ports could be developed to handle more traffic and reduce congestion at major ports?
WITH c AS (
	SELECT
		SUM(Tonnage_thousands) As Total_Tonnage
	FROM dbo.Port0302
)
SELECT 
	d.Port,
	SUM(d.Tonnage_thousands) AS Tonnage_thousands,
	ROUND(100.0*SUM(d.Tonnage_thousands)/c.Total_Tonnage, 2) AS Tonnage_Pct
FROM dbo.Port0302 d
CROSS JOIN c
GROUP BY d.Port, c.Total_Tonnage
HAVING ROUND(100.0*SUM(d.Tonnage_thousands)/c.Total_Tonnage, 2) < 2
ORDER BY Tonnage_Pct;


--3. Are there underperforming ports that require modernization or policy attention?
WITH l AS (
	SELECT 
		Port, 
		SUM(Tonnage_thousands) AS last_year_Units
	FROM dbo.Port0302
	WHERE Year = 2023
	GROUP BY Port
),

c AS (
	SELECT 
		Port, 
		SUM(Tonnage_thousands) AS current_year_Units
	FROM dbo.Port0302
	WHERE Year = 2024
	GROUP BY Port
)

SELECT 
	l.Port,
	l.last_year_Units,
	c.current_year_Units,
	(c.current_year_Units - l.last_year_Units) AS Change
FROM l
INNER JOIN c
ON l.Port = c.Port
WHERE (c.current_year_Units - l.last_year_Units) < 1
ORDER BY Change;

SELECT * FROM dbo.Port0302;