

#1. i want to first before anything NOT alter the raw data so I will create 
#a staging table where i can safely delete and update changes.
#2. I will go through my staging table and remove duplicates
#3. I will standardize my data, remove extra space, trim up anything
#4. Finally I willr emove null and blank values where needed and determine if values
#are MAR or MCAR or MNAR

SELECT * FROM layoffs;

#after importing our raw data and creating our table, we need to create a staging
#table with all the same values so we can safely update and delete data without
#permanently altering our raw dataset, this is good practice even if we already have
#a backup dataset

CREATE TABLE layoffs_staging_
LIKE layoffs;

SELECT * FROM layoffs_staging_;

INSERT layoffs_staging_
SELECT *
FROM layoffs;

SELECT * FROM layoffs_staging_;

#Next we will go through and find duplicate rows, but because this dataset doesnt have an ID column, 
#this poses a unique challenge we'll have to solve through creating our own unique ID column. I'll do so by assigning 
#a row_number to each row and partition over each value in order to reveal if there are any duplicate rows.

#Here i'll create a simple select statement that does this and paste this into a CTE that allows
#me to quickly select values where our new row_num column has values greater than 1
#(signaling to us that these are duplicate values)

SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,`date`,stage,country,funds_raised_millions) as row_num
FROM layoffs_staging;

WITH CTE AS(
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company,industry,total_laid_off,percentage_laid_off,`date`) as row_num
	FROM layoffs_staging)
SELECT *
FROM CTE
WHERE row_num > 1;

#thankfully there is no duplicates in this dataset! We can safely proceed 
#and start standarizing our data

#Just at a glance, I notice there are some company names that 
#have extra spaces before the name, we can quickly resolve this
#with a TRIM feature and visualize this side by side with our original 
#company column, and if were happy with the changes, i'll go ahead and 
#update my staging table to set a new value for that column.

SET SQL_SAFE_UPDATES = 0;

SELECT company,TRIM(Company)
FROM layoffs_staging_;

UPDATE layoffs_staging_
SET company = TRIM(company);

#Let's check to see if there are any industry names that are repeated or 
#that are incorrectly spelled in the dataset.

SELECT DISTINCT Industry
FROM layoffs_staging_
ORDER BY 1;

#We see that there is one industry that is NULL, lets dive deeper to see what company 
#this is and we might be able to fill this missing data or determine that its best to leave it.

SELECT company
FROM layoffs_staging_
WHERE industry IS NULL;

#Upon further investigation we see the company with the null industry value is Bally's
#which we can easily determine as an entertainment company, but first we should see if we can match 
#any of our existing industry values to this company before creating an entire new value

SELECT DISTINCT Industry
FROM layoffs_staging_
ORDER BY 1;

#Because there are no options similar to entertainment, we do have an option "other" 
#that may be more appropriate to identfiy Bally's as, given that it falls under that category.

UPDATE layoffs_staging_
SET industry = 'Other'
WHERE industry IS NULL;

#Continuing, let's now move to our country value to see if we have any errors

SELECT DISTINCT(country)
FROM layoffs_staging_
ORDER BY 1;

#Looking at our distinct country values, I notice that United States is listed twice, once normally
#spelled and the second time spelled with a period at the end. Although trivial, this is important 
#that we discovered this error as it can lead to incorrect aggregations, incorrect visualizations, and
#ultimately lead to possible inaccurate information overall. This example highlights the importance
#of performing proper cleaning practices prior to performing EDA.

#Because the error is only a period, We can perform a trim and utilize a trailing method
#that removes and then updates this to the correct value

SELECT DISTINCT(country), TRIM(TRAILING '.' FROM country)
FROM layoffs_staging_;

#We can see here that this Select statement indeed removes the period correctly
#so we will apply this and update it to the staging table

UPDATE layoffs_staging_
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


#Another vital part of standardizing is making sure all of our data types are correctly formatted
#to the data type they belong to. If we inspect our columns data type in our staging table,
#most of our types look correct except for our date column which is TEXT. If, for example, we were
#to create a time series with our data, if our date column type was TEXT, this would be impossible.

#Let's correctly change our data type for date to the correct "date" type.

SELECT `date` , STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging_;

UPDATE layoffs_staging_
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

#Now that we have a proper date formt, lets change the type

ALTER TABLE layoffs_staging_
MODIFY COLUMN `date` DATE;

#Finally, as our last step, lets decide what null and blank values in the rest 
#of our dataset we can either populate, leave alone, or get rid of.


















