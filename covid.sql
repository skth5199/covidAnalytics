
-- Getting column names
select name from sys.columns where object_id = OBJECT_ID('covidDeaths');

-- Displaying the highest number of cases and the maximum infected percentage by country
select location, population, MAX(total_cases) as HighestCases, MAX((total_cases/population)*100) as MaxInfectedPercentage 
from PortfolioProjects..covidDeaths 
where location like '%%'
group by population,location 
order by 4 desc;

-- Dispaying death stats. 
-- On looking through the results, I realized that all the highest deaths were starting with 9. Hence, it was clear that there was a data type mismatch.
-- Some entries were found in the location column that did not belong. There were all found to have continent as null and hence an apt constraint was applied.
select location, population, MAX(cast(total_deaths as int)) as HighestDeaths, MAX((cast(total_deaths as int)/population)*100) as MaxDeathPercentage 
from PortfolioProjects..covidDeaths 
where location like '%%' and continent is not null
group by location, population
order by 4 desc;

-- Global stats
-- cases stats
select sum(h.maxCases) as TotalCasesWorld 
from (
select location,max(total_cases) as maxCases
from PortfolioProjects..covidDeaths
where location like '%%' and continent is not null
group by location
) as h;

-- deaths stats
select sum(k.maxDeaths) as TotalDeathsWorld 
from (
select location,max(cast(total_deaths as int)) as maxDeaths
from PortfolioProjects..covidDeaths
where location like '%%' and continent is not null
group by location
) as k;

-- World's death ratio
select (sum(k.maxDeaths)/sum(h.maxCases))*100 as WorldDeathRatio
from (
select location,max(total_cases) as maxCases
from PortfolioProjects..covidDeaths
where location like '%%' and continent is not null
group by location
) as h, (
select location,max(cast(total_deaths as int)) as maxDeaths
from PortfolioProjects..covidDeaths
where location like '%%' and continent is not null
group by location
) as k;


-- Covid Vaccinations Analysis
-- Using a CTE

With cumNewVac (continent, location, date, population, newvac, cumvac)
as (
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (Partition by d.location order by d.location,d.date) as cummulativeVax
from PortfolioProjects..covidDeaths d join PortfolioProjects..covidVax v
	on d.location = v.location and d.date = v.date
where d.continent is not null
-- order by 2,3
)
select *,(cumvac/population)*100  from cumNewVac


-- Creating a view for tableau for the above query
create view cumVaxView as
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (Partition by d.location order by d.location,d.date) as cummulativeVax
from PortfolioProjects..covidDeaths d join PortfolioProjects..covidVax v
	on d.location = v.location and d.date = v.date
where d.continent is not null
--order by 2,3