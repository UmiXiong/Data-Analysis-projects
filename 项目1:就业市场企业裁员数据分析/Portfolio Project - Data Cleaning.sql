-- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022


-- mysql workbench无法直接完整录入信息
-- 解决方案，使用 https://www.convertcsv.com/csv-to-sql.htm 去对csv数据进行转换，一条一条插入


SELECT * 
FROM world_layoffs.layoffs;
-- 测试，检测数据行数是否正确 
select count(*) from layoffs;

-- 1.移除重复项目
-- 2.标准化数据
-- 3.空值/空白值：试图填充
-- 4.移除不必要的行列 

-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens
-- 为了避免破坏原始数据，我们新建一个表，同时，为了使得数据一致，直接使用关键词like,复制所有列
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

-- 确认内容一致
select * 
from layoffs_staging;

select count(*) from layoffs_staging;

-- 插入表格内的相关内容
INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;


-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways



-- 1. Remove Duplicates

# First let's check for duplicates



SELECT *
FROM world_layoffs.layoffs_staging
;



-- 根据公司，行业，裁员数量，日期分类，查看每次裁员裁了多少人
-- 查询发现，有的数据被统计了多次，因此出现了row_number大于1的情况（需要移除）
SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

-- 查询重复数据
with duplicate_cte as(
	select *,
    ROW_NUMBER() OVER(partition by company, industry, total_laid_off,`date`) as row_num
    from layoffs_staging
)

select * from duplicate_cte where row_num > 1;


-- 检查后发现，3条Oda其实fund raised不一样，我们之所以认为它们是一样的是因为我们选择的数据列是一样的
select * from layoffs_staging
where company="Oda";



select * from duplicate_cte where row_num > 1;

SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
-- let's just look at oda to confirm
-- 发现Oda出现了3次，检查
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda'
;
-- it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate

-- these are our real duplicates 
-- 基于更详细的信息发现，所谓的重复项并非真的重复，而只是指定的项目重复了
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;

-- these are the ones we want to delete where the row number is > 1 or 2or greater essentially

-- 此时发现casper是一个满足条件的重复项目
select * from layoffs_staging where company='Casper';

-- now you may want to write it like this:
-- 我们试图删除那些row_num>=2的项目，但是发现行不通,因为没有row_num列
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;


WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- one solution, which I think is a good one. Is to create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column
-- so let's do it!!

ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;


SELECT *
FROM world_layoffs.layoffs_staging
;

-- 解决方案是，我们新建一个表，利用这个表来进行删除
CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

-- 表格建立成功，为空表
select * from layoffs_staging2;

INSERT INTO `world_layoffs`.`layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,

-- 在原来的表的基础上，新建一个row_num列，用于删除重复信息
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

-- now that we have this we can delete rows were row_num is greater than 2

-- 再次检查，发现数据成功加入，原始的layoffs_staging并没有row_num这一列可以用于检测那些重复的数据
select * from layoffs_staging2;

-- 验证
select * from layoffs_staging2 where company='Casper';

-- sql开了安全保护，需要用safe_updates参数设置为0，从而进行删除
SET SQL_SAFE_UPDATES = 0;
DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num >= 2;

-- 删除结束后，重置安全模式为1
SET SQL_SAFE_UPDATES = 1;

select * from layoffs_staging2;







-- 2. Standardize Data（标准化数据）

-- 查询所有公司
select company, trim(company)
from layoffs_staging2;


-- 更新内容，要求公司名称不包含首尾空位
set SQL_SAFE_UPDATES=0;
update layoffs_staging2 
set company= trim(company);

set SQL_SAFE_UPDATES=1;

SELECT * 
FROM world_layoffs.layoffs_staging2;

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these
-- 随后是行业，查看所有行业
-- 发现有名字相似，但是标记不同的项目，空项目等
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- 处理第一个：cryptoxxx
select *
from layoffs_staging2
where industry like 'Crypto%';

-- 更新
set SQL_SAFE_updates=0;
update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';
set SQL_SAFE_updates=1;

-- 检查crypto
select distinct industry
from layoffs_staging2;

-- 检查位置和国家
select distinct location
from layoffs_staging2
order by 1;

-- 检查国家后发现，有人在国家后面加.这种操作 
select distinct country
from layoffs_staging2
order by 1;

-- 有人在美国后面加.
select *
from layoffs_staging2
where country like "United States%"
order by 1;

-- 解决方案，使用trim，去掉末尾的.alter
-- trailing ”.“ from country表示去掉country字段末尾的”.“
select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

-- 更新那些错误的国家名称标记
set sql_safe_updates=0;
update layoffs_staging2
set country=trim(trailing '.' from country)
where country like "United States%";
set sql_safe_updates=1;

-- 再次检测
select distinct country
from layoffs_staging2;

-- 查看整体数据
select * 
from layoffs_staging2;

-- 日期检测，字符串格式改为date格式
-- STR_TO_DATE(字符串,日期格式)强转为日期格式
	-- %m表示月份,%d表示日期,%Y表示年份
select `date`, STR_TO_DATE(`date`,"%m/%d/%Y")
from layoffs_staging2;

-- 更新date列
set sql_safe_updates=0;
update layoffs_staging2
set `date`= STR_TO_DATE(`date`,"%m/%d/%Y");
set sql_safe_updates=1;

-- 确认生效（基本生效，除了一个null）
-- 我们会发现格式依然是text格式
select `date` from layoffs_staging2;

-- 解决方案是改变列格式（一定要使用备份表进行操作），此时我们可以发现date列变成了date格式
set sql_safe_updates=0;
alter table layoffs_staging2
modify column `date` DATE;
set sql_safe_updates=1;

-- 查看裁员
select * from layoffs_staging2 where total_laid_off is null
and percentage_laid_off is null;

-- 查看行业为空或者为空格的公司
select *
from layoffs_staging2
where industry is null or industry = '';

-- 发现第一个行业为空的公司为Airbnb
-- 检测后发现，有两条相关信息，其中行业应该是Travel
select * from layoffs_staging2
where company= 'Airbnb';

-- 更新industry列,使用相同表格找到对应的industry是什么
-- 因为前面的airbnb存在说有的查询记录有industry名称，而有的则没有
select *
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company=t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry='')
and t2.industry is not null;

-- 根据前面的得到的信息，更新industry栏
-- 如这里的industry更新,将那些应该有industry的公司但是并没有标记industry的更新为对应的industry
set sql_safe_updates=0;
update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry=t2.industry
where (t1.industry is null or t2.industry = '')
and t2.industry is not null;
set sql_safe_updates=1;

-- 再次检查:airbnb
select * from layoffs_staging2
where company= 'Airbnb';

-- 检查bally，发现bally只有一条，因此找不到相关的公司名称
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';


-- 对于裁员率，我们可以通过裁员人数/总人数得到一个比值，但是由于我们缺少这个信息，因此这一项无法进行填充

-- 查看裁员数和裁员率
select * from layoffs_staging2 where total_laid_off is null
and percentage_laid_off is null;

-- 对于我们来说，如果不摘掉裁员数和裁员率，那么这些数据就是没有任何意义的，因此可以直接删除
set sql_safe_updates=0;
delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;
set sql_safe_updates=1;

select * from layoffs_staging2;

-- 现在row_num列没有用了,可以删掉
alter table layoffs_staging2
drop column row_num;





















-- 参考信息

-- let's take a look at these
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';
-- nothing wrong here
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

-- we should set the blanks to nulls since those are typically easier to work with
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- now if we check those are all null

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- now we need to populate those nulls if possible

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- and if we check it looks like Bally's was the only one without a populated row to populate this null values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- ---------------------------------------------------

-- I also noticed the Crypto has multiple different variations. We need to standardize that - let's say all to Crypto
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- now that's taken care of:
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- --------------------------------------------------
-- we also need to look at 

SELECT *
FROM world_layoffs.layoffs_staging2;

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's standardize this.
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- now if we run this again it is fixed
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;


-- Let's also fix the date columns:
SELECT *
FROM world_layoffs.layoffs_staging2;

-- we can use str to date to update this field
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now we can convert the data type properly
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


SELECT *
FROM world_layoffs.layoffs_staging2;





-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase

-- so there isn't anything I want to change with the null values




-- 4. remove any columns and rows we need to

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL;


SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


SELECT * 
FROM world_layoffs.layoffs_staging2;


































