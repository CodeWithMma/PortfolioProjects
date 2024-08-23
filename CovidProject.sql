SELECT * FROM coviddeaths order by 3, 4;

-- SELECT * FROM covidvaccinations order by 3, 4;
#select the data we'll be using
SELECT Location, date, total_cases, new_cases, total_deaths, population FROM coviddeaths
order by 1,2;

#Looking at Total Cases vs Total Deaths. 
#This shows the likelihood of dying if you contract COVID in afghanistan
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100
AS DeathPercentage FROM coviddeaths where location like '%afghanistan%'
order by 1,2;
#(I'm using afghanistan cos the dataset that was able to import didnt get to USA)
#looking @total_cases vs population
SELECT Location, date, population, total_cases,  (total_cases/population) * 100
AS PercentPopulationInfected FROM coviddeaths #where location like '%afghanistan%'
order by 1,2; #This shows the percentage of people that has contracted COVID

#Looking at countries with highest infection rate compared to population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, 
MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM coviddeaths #where location like '%afghanistan%' 
GROUP BY Location, population order by PercentPopulationInfected desc;

--  Stating countries with highest death count per population
SELECT Location, MAX(total_deaths) as TotalDeathCount
-- MAX((total_deaths/population)) * 100 AS PercentPopulationInfected
FROM coviddeaths #where location like '%afghanistan%' 
GROUP BY Location order by TotalDeathCount desc;

#LET'S BREAK THINGS DOWN BY CONTINENT
SELECT continent, MAX(total_deaths) as TotalDeathCount
-- MAX((total_deaths/population)) * 100 AS PercentPopulationInfected
FROM coviddeaths #where location like '%afghanistan%' 
GROUP BY continent order by TotalDeathCount desc;

-- Showing continenets with the highest death count per population
SELECT continent, MAX(total_deaths) as TotalDeathCount
-- MAX((total_deaths/population)) * 100 AS PercentPopulationInfected
FROM coviddeaths #where location like '%afghanistan%' 
GROUP BY continent order by TotalDeathCount desc;

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as  TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases) * 100
AS DeathPercentage FROM coviddeaths -- where location like '%afghanistan%'
where continent is not null
group by date 
order by 1,2;

SELECT SUM(new_cases) as  TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases) * 100
AS DeathPercentage FROM coviddeaths -- where location like '%afghanistan%'
where continent is not null
-- group by date 
order by 1,2; #This will give us the total cases of the entire data

-- Looking at Total Population vs Vaccination
SELECT * FROM coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 1,2;

# When the dtype of a column is a text type and it isn't givinh you properly arranged figures, 
# you use the CONVERT (int, column_name) or Cast(column_name as Int).
#Also, If you want to create a column with the cumulative figures of new_vaccinations, below is the code to write.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location )
FROM coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 1,2,3;#(This just did the sum of all the new_vaccinations by their location)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) AS
Rollingpeoplevaccinated
FROM coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 1,2,3;

#To know how many people in the country are vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) AS
Rollingpeoplevaccinated
-- (Rollingpeoplevaccinated/population)* 100
FROM coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 1,2,3; 

-- we have to use a CTE or a temptable to determine the number of people that are vaccinated
--  we can't use a column just created to divide by population.
-- USE CTE (the number of columns in your CTE has to be equal to the number of columns in your select statement.
-- you can't have orderby within a CTE.  after ruunig the CTE, the new column query will be in there and you can now use it to perform further calculations.
with popvsvac (continent, Location, Date, Population, new_vaccination,RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) AS
Rollingpeoplevaccinated
-- (Rollingpeoplevaccinated/population)* 100
FROM coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
SELECT *, (RollingPeopleVaccinated/population)* 100 FROM popvsvac;

-- Creating views to store data for later visualizations
Create view popvsvac as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) AS
Rollingpeoplevaccinated
-- (Rollingpeoplevaccinated/population)* 100
FROM coviddeaths dea join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
-- order by 2,3