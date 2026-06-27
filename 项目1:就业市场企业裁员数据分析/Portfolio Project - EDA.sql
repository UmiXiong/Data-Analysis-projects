-- EDA

-- Here we are jsut going to explore the data and find trends or patterns or anything interesting like outliers

-- normally when you start the EDA process you have some idea of what you're looking for

-- with this info we are just going to look around and see what we find!

SELECT * 
FROM world_layoffs.layoffs_staging2;

-- 查看处理之后的数据
select count(*) from world_layoffs.layoffs_staging2;



-- EASIER QUERIES

-- 检查裁员数量和裁员比例
SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;


-- Looking at Percentage to see how big these layoffs were
--  查看裁员率：发现最大全裁了
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off IS NOT NULL;

-- Which companies had 1 which is basically 100 percent of they company laid off
-- 查看哪些接近于倒闭的公司（裁员率为1）
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1;
-- these are mostly startups it looks like who all went out of business during this time

-- 哪些公司裁掉的人最多
select *
from layoffs_staging2
where percentage_laid_off=1 order by total_laid_off desc;

-- if we order by funcs_raised_millions we can see how big some of these companies were
-- 当然，也可以从融资角度来看
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- BritishVolt looks like an EV company, Quibi! I recognize that company - wow raised like 2 billion dollars and went under - ouch

-- SOMEWHAT TOUGHER AND MOSTLY USING GROUP BY--------------------------------------------------------------------------------------------------

-- Companies with the biggest single Layoff

-- 查看裁员最多的5个公司
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging2
-- 按照裁员人数来排序
ORDER BY 2 DESC
LIMIT 5;
-- now that's just on a single day

-- 查看裁员持续时间:裁员起始于疫情
select min(`date`),MAX(`date`)
from layoffs_staging2;


-- Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- 根据行业
SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC
LIMIT 10;



-- by location
-- 根据地点
SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- this it total in the past 3 years or in the dataset
-- 按照国家来排序
SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- 按照具体日期排序，查看每天裁员裁了多少
SELECT `date`, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY `date`
ORDER BY 1 ASC;

SELECT YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;


-- 根据融资阶段排序
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- 计算每个公司的平均裁员率
select company, AVG(percentage_laid_off) from layoffs_staging2
group by company order by 2 desc;


-- 按照月份查看裁员数量
select substring(`date`,6,2) as `month`, sum(total_laid_off)
from layoffs_staging2 group by `month`;

-- 更好的方案是，具体到哪年哪月
select substring(`date`,1,7) as `year-month`, sum(total_laid_off)
from layoffs_staging2 
-- 要求日期不为空
-- where `year-month` is not null: where的执行顺序在substring之前，所以不能使用别名
where substring(`date`,1,7) is not null
group by `year-month`
order by `year-month`;

-- 求累计总和,按照具体年-月
with rolling_total as
(
	select substring(`date`,1,7) as `year-month`, sum(total_laid_off) as total_off
	from layoffs_staging2 
	-- 要求日期不为空
	-- where `year-month` is not null: where的执行顺序在substring之前，所以不能使用别名
	where substring(`date`,1,7) is not null
	group by `year-month`
	order by `year-month`
)
-- 展示日期，当前日期裁员总数，累计总数
select `year-month`, total_off, sum(total_off) over(order by `year-month`) as rolling from rolling_total;

-- 我们想看到更加详细的：什么公司，哪天，一共裁了多少人
select company, `date`,sum(total_laid_off)
from layoffs_staging2
group by company,`date`;

-- 升级一下，变成查看什么公司，哪年裁了多少人
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by company;

-- 再改变一下，按照裁员数量逆序排列
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by 3 desc;


-- TOUGHER QUERIES------------------------------------------------------------------------------------------------------------------------------------

-- Earlier we looked at Companies with the most Layoffs. Now let's look at that per year. It's a little more difficult.
-- I want to look at 


-- 找出每年裁员人数最多的3家公司
WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;




-- Rolling Total of Layoffs Per Month
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC;

-- now use it in a CTE so we can query off of it
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;



















































