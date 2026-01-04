-- =====================================================
-- DATA CLEANING & VALIDATION
-- =====================================================


-- =====================================================
-- 1. BASIC DATA VALIDATION
-- =====================================================

-- Total records in table
SELECT COUNT(*) AS total_rows FROM netflix;

-- Check for duplicate show_id values
SELECT show_id, COUNT(*) AS duplicate_count
FROM netflix
GROUP BY show_id
HAVING COUNT(*) > 1;


-- =====================================================
-- 2. NULL VALUE AUDIT
-- =====================================================

SELECT
    COUNT(*) FILTER (WHERE title IS NULL) AS null_title,
    COUNT(*) FILTER (WHERE type IS NULL) AS null_type,
    COUNT(*) FILTER (WHERE director IS NULL) AS null_director,
    COUNT(*) FILTER (WHERE casts IS NULL) AS null_casts,
    COUNT(*) FILTER (WHERE country IS NULL) AS null_country,
    COUNT(*) FILTER (WHERE date_added IS NULL) AS null_date_added,
    COUNT(*) FILTER (WHERE rating IS NULL) AS null_rating,
    COUNT(*) FILTER (WHERE duration IS NULL) AS null_duration
FROM netflix;


-- =====================================================
-- 3. DATA CLEANING
-- =====================================================

-- Replace missing country values
UPDATE netflix
SET country = 'Unknown'
WHERE country IS NULL;

-- Replace missing rating values
UPDATE netflix
SET rating = 'Not Rated'
WHERE rating IS NULL;

-- Trim leading and trailing spaces
UPDATE netflix
SET
    title = TRIM(title),
    director = TRIM(director),
    country = TRIM(country),
    listed_in = TRIM(listed_in);


-- =====================================================
-- 4. DOMAIN & RANGE VALIDATION
-- =====================================================

-- Validate content types
SELECT DISTINCT type FROM netflix;

-- Validate ratings
SELECT DISTINCT rating FROM netflix ORDER BY rating;

-- Detect invalid release years
SELECT *
FROM netflix
WHERE release_year < 1900
   OR release_year > EXTRACT(YEAR FROM CURRENT_DATE);

-- Detect future dates in date_added
SELECT *
FROM netflix
WHERE date_added::DATE > CURRENT_DATE;


-- =====================================================
-- 5. DATA TYPE CORRECTION
-- =====================================================

-- Convert date_added from VARCHAR to DATE
ALTER TABLE netflix
ALTER COLUMN date_added TYPE DATE
USING date_added::DATE;


-- =====================================================
-- 6. FEATURE ENGINEERING
-- =====================================================

-- Extract numeric duration (minutes or seasons)
ALTER TABLE netflix
ADD COLUMN duration_value INT;

UPDATE netflix
SET duration_value = CAST(SPLIT_PART(duration, ' ', 1) AS INT);

-- Extract year and month from date_added
ALTER TABLE netflix
ADD COLUMN year_added INT,
ADD COLUMN month_added INT;

UPDATE netflix
SET
    year_added = EXTRACT(YEAR FROM date_added),
    month_added = EXTRACT(MONTH FROM date_added);


-- =====================================================
-- 7. FINAL DATA QUALITY CHECK
-- =====================================================

SELECT
    COUNT(*) FILTER (WHERE country = 'Unknown') AS unknown_country_count,
    COUNT(*) FILTER (WHERE rating = 'Not Rated') AS not_rated_count,
    COUNT(*) FILTER (WHERE duration_value IS NULL) AS missing_duration_value
FROM netflix;


-- =====================================================
-- 8. EXPLORATORY DATA ANALYSIS (EDA)
-- =====================================================

-- Movies vs TV Shows
SELECT type, COUNT(*) AS total_titles
FROM netflix
GROUP BY type;

-- Year-wise content addition
SELECT year_added, COUNT(*) AS total_content
FROM netflix
GROUP BY year_added
ORDER BY year_added;

-- Top 10 countries by content
SELECT country, COUNT(*) AS total_titles
FROM netflix
GROUP BY country
ORDER BY total_titles DESC
LIMIT 10;

-- Rating distribution
SELECT rating, COUNT(*) AS total_titles
FROM netflix
GROUP BY rating
ORDER BY total_titles DESC;

-- Average movie duration
SELECT AVG(duration_value) AS avg_movie_duration
FROM netflix
WHERE type = 'Movie';

-- TV show season distribution
SELECT duration_value AS seasons, COUNT(*) AS total_shows
FROM netflix
WHERE type = 'TV Show'
GROUP BY duration_value
ORDER BY seasons;


-- =====================================================
-- 9. ADVANCED / BUSINESS ANALYSIS
-- =====================================================

-- Year-wise Movies vs TV Shows
SELECT year_added, type, COUNT(*) AS total_titles
FROM netflix
GROUP BY year_added, type
ORDER BY year_added;

-- Monthly content addition trend
SELECT month_added, COUNT(*) AS total_titles
FROM netflix
GROUP BY month_added
ORDER BY month_added;

-- Year-over-Year content growth
WITH yearly_content AS (
    SELECT year_added, COUNT(*) AS total_titles
    FROM netflix
    GROUP BY year_added
)
SELECT
    year_added,
    total_titles,
    total_titles - LAG(total_titles) OVER (ORDER BY year_added) AS yoy_growth
FROM yearly_content;
