--Taking a look at our data
SELECT TOP(10) * 
FROM deaths

SELECT TOP(10) * 
FROM vaccinations

--Selecting data we'll be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM deaths
ORDER BY 1, 2

--Checking data types of table columns
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'deaths'

-- We can see that total_deaths and total_cases are nvarchar, let's transform to int
ALTER TABLE deaths
ALTER COLUMN total_deaths
int;

ALTER TABLE deaths
ALTER COLUMN total_cases
int;

-- Looking at total cases vs total deaths
-- Shows the likelihood of dying if you catch Covid
SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) / total_cases) * 100 AS death_rate
FROM deaths
WHERE location LIKE 'Egypt'
ORDER BY 2

-- Looking at total cases vs population
SELECT Location, date, total_cases, population, (CAST(total_cases AS FLOAT) / population) * 100 AS infection_rate
FROM deaths
WHERE location like 'Egypt'
ORDER BY 2

-- Looking at countries with hieghest infection_count and infection_rate compared to population
SELECT location, population, MAX(total_cases) AS hieghest_infection_count, MAX((total_cases/population)) *100 AS infection_rate
from deaths
GROUP BY location, population
ORDER BY 4 DESC

-- Shows countries with heighest death_count and death_rate compared to population
SELECT location, population, MAX(total_deaths) AS hieghest_death_count, MAX(total_deaths/population) * 100 AS heighest_death_rate
FROM deaths
GROUP BY location, population
ORDER BY 4 DESC

-- Shows countries with hieghest deaths per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS hieghest_total_deaths
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- LET'S BREAK THING UP BY CONTINENT
SELECT continent, MAX(CAST(total_deaths AS INT)) AS hieghest_total_deaths
FROM deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, 
SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS death_rate
FROM deaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2

-- Looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM deaths dea
JOIN  vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- Most important
WITH pop_vs_vac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM deaths dea
JOIN  vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM pop_vs_vac


-- Temp table creation
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(225),
Location nvarchar(225),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)

-- Populating the temp table
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM deaths dea
JOIN  vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2, 3
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Create a view for later use in visualizations
CREATE View PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM deaths dea
JOIN  vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT TOP(10)* 
FROM PercentPopulationVaccinated

