
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

-- Comparing Total Cases vs Total Deaths
-- Shows the chances of dying if you contract the virus in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE Location like '%states%'
ORDER BY 1,2


-- Comparing Total Cases vs Population
-- Shows the percentage of a country's population who contracted the virus
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS PopulationContractionPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE Location like '%states%'
ORDER BY 1,2

-- Looking at contries who have the highest infection rate compared to population
SELECT Location, population, MAX(total_cases) AS HighestCaseCount, MAX(total_cases/population)*100 AS PopulationContractionPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
GROUP BY Location, population
ORDER BY PopulationContractionPercentage DESC

-- Looking at countries with highest death rate per population
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Looking at continents with the highest death rate per population
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Global Numbers 
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Comparing Total Population vs Vaccinations
 
SELECT *
FROM PortfolioProject.dbo.CovidDeathsCurrent AS deaths
JOIN PortfolioProject.dbo.CovidVaccinationsCurrent AS vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date

---- Using CTE 
WITH PopuvsVax (Continent, location, date, population, new_vaccinations, RollingCountPeopleVaxxed)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations AS bigint)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date ROWS UNBOUNDED PRECEDING) AS RollingCountPeopleVaxxed
--(RollingCountPeopleVaxxed/deaths.population)*100
FROM PortfolioProject.dbo.CovidDeathsCurrent AS deaths
JOIN PortfolioProject.dbo.CovidVaccinationsCurrent AS vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL AND deaths.continent= 'Europe'
--ORDER BY 2, 3
)

SELECT *, (RollingCountPeopleVaxxed/population)*100 AS PercentageTotalPopuVaxxed
FROM PopuvsVax;

---- Using CTE 
WITH PopuvsMaxVaxxed (location, population, RollingCountPeopleVaxxed)
AS
(
SELECT deaths.location, deaths.population,
SUM(cast(vax.new_vaccinations AS float)) OVER (PARTITION BY deaths.location ORDER BY deaths.location) AS RollingCountPeopleVaxxed
--(RollingCountPeopleVaxxed/deaths.population)*100
FROM PortfolioProject.dbo.CovidDeathsCurrent AS deaths
JOIN PortfolioProject.dbo.CovidVaccinationsCurrent AS vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT location, population, RollingCountPeopleVaxxed, MAX((RollingCountPeopleVaxxed/population)*100) AS PercentageTotalPopuVaxxed
FROM PopuvsMaxVaxxed
GROUP BY location, population, RollingCountPeopleVaxxed

-- TEMP TABLE Version
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingCountPeopleVaxxed numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingCountPeopleVaxxed
--(RollingCountPeopleVaxxed/deaths.population)*100
FROM PortfolioProject.dbo.CovidDeathsCurrent AS deaths
JOIN PortfolioProject.dbo.CovidVaccinationsCurrent AS vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingCountPeopleVaxxed/population)*100 AS PercentageTotalPopuVaxxed
FROM PercentPopulationVaccinated



-- Creating views to use for visualizations
CREATE VIEW PercentPopulationVaxxed AS 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingCountPeopleVaxxed
--(RollingCountPeopleVaxxed/deaths.population)*100
FROM PortfolioProject.dbo.CovidDeathsCurrent AS deaths
JOIN PortfolioProject.dbo.CovidVaccinations AS vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL;

-- Get the Global total cases and deaths along with the death percentage
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE continent is not null 
ORDER BY 1,2

-- Create view for Global total cases and deaths
CREATE VIEW GlobalCasesAndDeaths AS 
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE continent is not null 


-- Compare total death counts for each continent
SELECT location, SUM(cast(new_deaths as int)) as TotalDeaths
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE continent is null 
AND location NOT IN ('World', 'European Union', 'International')
AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeaths desc

-- Create view for death count by continent
CREATE VIEW DeathsByContinent AS 
SELECT location, SUM(cast(new_deaths as int)) as TotalDeaths
FROM PortfolioProject.dbo.CovidDeathsCurrent
WHERE continent is null 
AND location NOT IN ('World', 'European Union', 'International')
AND location NOT LIKE '%income%'
GROUP BY location


-- Compare countries with the higest infection percentages
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PopulationInfectedPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
GROUP BY Location, Population
ORDER BY PopulationInfectedPercentage desc

-- Creat view to compare countries with the highest infection percentages
CREATE VIEW CountryInfectionPercentages AS
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PopulationInfectedPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
GROUP BY Location, Population

SELECT Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PopulationInfectedPercentage
FROM PortfolioProject.dbo.CovidDeathsCurrent
GROUP BY Location, Population, date
ORDER BY PopulationInfectedPercentage desc

