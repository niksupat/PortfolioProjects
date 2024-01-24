-- Initial exploration of data

SELECT *
FROM coviddeaths
where [location] like 'world'
order by 3,4

SELECT *
FROM covidvaccinations
order by 3,4

-- Select data that we're going to be starting with

SELECT [location], [date], total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1,2

-- Looking at Total Cases vs. Total Deaths; shows the likelihood of dying if you contract Covid in Singapore

SELECT [location], [date], total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
FROM coviddeaths
WHERE [location] LIKE 'Singapore'
ORDER BY 1,2

-- Looking at Total Cases vs Population; shows what percentage of population infected with Covid in Singapore

SELECT [location], [date], total_cases, population, (total_cases/population)*100 AS percentpopulationinfected
FROM coviddeaths
WHERE [location] LIKE 'Singapore'
ORDER BY 1,2

-- Looking at countries with the highest infection rates compared to population

SELECT [location], MAX(total_cases) AS HighestInfectionCount, population, MAX(total_cases/population)*100 AS MaxPercentInfected
FROM coviddeaths
GROUP BY [location], population
ORDER BY MaxPercentInfected DESC

-- Showing countries with the highest death count per population

SELECT [location], MAX(total_deaths) AS totaldeathcount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY [location]
ORDER BY totaldeathcount DESC

-- Showing continents with the highest death count per population

SELECT [continent], MAX(total_deaths) AS totaldeathcount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY [continent]
ORDER BY totaldeathcount DESC

-- Global numbers; use of CASE to handle divide by zero error. Can also include commented lines to view rolling global death percentage over time

SELECT
    -- [date],
    SUM(new_cases) AS totalcases,
    SUM(new_deaths) AS totaldeaths,
    CASE
        WHEN SUM(CAST(new_cases AS int)) > 0
        THEN SUM(CAST(new_deaths AS int)) * 100.00 / SUM(CAST(new_cases AS int))
        ELSE NULL
    END AS deathpercentage
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
-- GROUP BY
--     [date]
ORDER BY
    1,2

-- Total Population vs Vaccinations; shows percentage of population that has recieved at least 1 Covid vaccine

SELECT
    dea.continent,
    dea.[location],
    dea.[date],
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.[date]) AS RollingPeopleVaccinated
FROM
    coviddeaths dea
    JOIN
    covidvaccinations vac ON dea.[location] = vac.[location] AND dea.[date] = vac.[date]
WHERE
    dea.continent IS NOT NULL
ORDER BY
    dea.[location], dea.[date]

-- Option 1: Using a CTE to perform calculation on partition by in the previous query

WITH
    PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
    AS
    (
        SELECT
            dea.continent,
            dea.[location],
            dea.[date],
            dea.population,
            vac.new_vaccinations,
            SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.[date]) AS RollingPeopleVaccinated
        FROM
            coviddeaths dea
            JOIN
            covidvaccinations vac ON dea.[location] = vac.[location] AND dea.[date] = vac.[date]
        WHERE
    dea.continent IS NOT NULL
    )
SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingVaccinationPercentage
FROM PopvsVac

-- Option 2: Using a temp table to perform calculation on partition by in the previous query

DROP TABLE IF EXISTS #PercentPopulationVaccination
CREATE TABLE #PercentPopulationVaccination
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccination NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO [#PercentPopulationVaccination]
SELECT
    dea.continent,
    dea.[location],
    dea.[date],
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.[date]) AS RollingPeopleVaccinated
FROM
    coviddeaths dea
    JOIN
    covidvaccinations vac ON dea.[location] = vac.[location] AND dea.[date] = vac.[date]
WHERE
    dea.continent IS NOT NULL
ORDER BY
    dea.[location], dea.[date]

SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingVaccinationPercentage
FROM #PercentPopulationVaccination

-- Creating a View to store data for later Tableau data vizualisations

-- Drop the view if it exists
IF OBJECT_ID('PercentPopulationVaccination', 'V') IS NOT NULL
    DROP VIEW PercentPopulationVaccination;
GO

CREATE VIEW PercentPopulationVaccination
AS
    SELECT
        dea.continent,
        dea.[location],
        dea.[date],
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.[date]) AS RollingPeopleVaccinated
    FROM
        coviddeaths dea
        JOIN
        covidvaccinations vac ON dea.[location] = vac.[location] AND dea.[date] = vac.[date]
    WHERE
        dea.continent IS NOT NULL
GO

SELECT * FROM PercentPopulationVaccination