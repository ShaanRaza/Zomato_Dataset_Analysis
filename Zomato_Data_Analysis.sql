USE project;

-- =========================================================
-- ZOMATO DATA ANALYSIS – MARKET EXPANSION & PERFORMANCE
-- SQL DIALECT: MySQL 8.0+
-- =========================================================


-- QUESTION 1: Display the full Zomato dataset
SELECT *
FROM ZomatoData1;


-- =========================================================
-- BASIC EXPLORATORY / ORIGINAL BUSINESS QUESTIONS
-- =========================================================

-- QUESTION 2: What is the rolling / moving count of restaurants across localities within Indian cities?
SELECT
    `COUNTRY_NAME`,
    `City`,
    `Locality`,
    COUNT(`Locality`) AS TOTAL_REST,
    SUM(COUNT(`Locality`)) OVER (
        PARTITION BY `City`
        ORDER BY `Locality` DESC
    ) AS ROLLING_TOTAL_REST
FROM ZomatoData1
WHERE `COUNTRY_NAME` = 'INDIA'
GROUP BY `COUNTRY_NAME`, `City`, `Locality`;


-- QUESTION 3: What percentage of total restaurants belongs to each country?
WITH country_counts AS (
    SELECT
        `COUNTRY_NAME`,
        COUNT(`RestaurantID`) AS REST_COUNT
    FROM ZomatoData1
    GROUP BY `COUNTRY_NAME`
),
total_count AS (
    SELECT COUNT(`RestaurantID`) AS TOTAL_REST
    FROM ZomatoData1
)
SELECT
    c.`COUNTRY_NAME`,
    c.REST_COUNT,
    ROUND(c.REST_COUNT / t.TOTAL_REST * 100, 2) AS REST_PERCENTAGE
FROM country_counts c
CROSS JOIN total_count t
ORDER BY REST_PERCENTAGE DESC;


-- QUESTION 4: Which countries have restaurants offering online delivery, and what percentage of each country’s restaurants provide it?
WITH country_rest AS (
    SELECT
        `COUNTRY_NAME`,
        COUNT(`RestaurantID`) AS REST_COUNT
    FROM ZomatoData1
    GROUP BY `COUNTRY_NAME`
)
SELECT
    a.`COUNTRY_NAME`,
    COUNT(a.`RestaurantID`) AS TOTAL_REST_WITH_DELIVERY,
    ROUND(COUNT(a.`RestaurantID`) / b.REST_COUNT * 100, 2) AS ONLINE_DELIVERY_PERCENTAGE
FROM ZomatoData1 a
JOIN country_rest b
    ON a.`COUNTRY_NAME` = b.`COUNTRY_NAME`
WHERE a.`Has_Online_delivery` = 'YES'
GROUP BY a.`COUNTRY_NAME`, b.REST_COUNT
ORDER BY TOTAL_REST_WITH_DELIVERY DESC;


-- QUESTION 5: Which city and locality in India has the maximum number of restaurants listed on Zomato?
WITH locality_counts AS (
    SELECT
        `City`,
        `Locality`,
        COUNT(`RestaurantID`) AS REST_COUNT
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`, `Locality`
)
SELECT
    `City`,
    `Locality`,
    REST_COUNT
FROM locality_counts
WHERE REST_COUNT = (
    SELECT MAX(REST_COUNT) FROM locality_counts
);


-- QUESTION 6: What types of cuisines are available in the Indian locality with the maximum number of restaurants?
WITH locality_counts AS (
    SELECT
        `City`,
        `Locality`,
        COUNT(`RestaurantID`) AS REST_COUNT
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`, `Locality`
),
top_locality AS (
    SELECT
        `Locality`,
        REST_COUNT
    FROM locality_counts
    WHERE REST_COUNT = (
        SELECT MAX(REST_COUNT) FROM locality_counts
    )
)
SELECT
    t.`Locality`,
    z.`Cuisines`
FROM top_locality t
JOIN ZomatoData1 z
    ON t.`Locality` = z.`Locality`;


-- QUESTION 7: What is the most common cuisine in the Indian locality with the maximum number of restaurants?
WITH locality_counts AS (
    SELECT
        `City`,
        `Locality`,
        COUNT(`RestaurantID`) AS REST_COUNT
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`, `Locality`
),
top_locality AS (
    SELECT
        `Locality`
    FROM locality_counts
    WHERE REST_COUNT = (
        SELECT MAX(REST_COUNT) FROM locality_counts
    )
),
cuisine_split AS (
    SELECT
        z.`Locality`,
        TRIM(jt.cuisine) AS cuisine
    FROM ZomatoData1 z
    JOIN top_locality t
        ON z.`Locality` = t.`Locality`
    JOIN JSON_TABLE(
        CONCAT(
            '["',
            REPLACE(REPLACE(z.`Cuisines`, '"', '\\"'), ',', '","'),
            '"]'
        ),
        '$[*]' COLUMNS (
            cuisine VARCHAR(255) PATH '$'
        )
    ) jt
)
SELECT
    cuisine,
    COUNT(*) AS CUISINE_COUNT
FROM cuisine_split
GROUP BY cuisine
ORDER BY CUISINE_COUNT DESC;


-- QUESTION 8: Which localities in India have the lowest number of restaurants listed on Zomato?
WITH locality_counts AS (
    SELECT
        `City`,
        `Locality`,
        COUNT(`RestaurantID`) AS REST_COUNT
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`, `Locality`
)
SELECT *
FROM locality_counts
WHERE REST_COUNT = (
    SELECT MIN(REST_COUNT) FROM locality_counts
)
ORDER BY `City`;


-- QUESTION 9: How many restaurants offer table booking in the Indian locality with the maximum number of restaurants?
WITH locality_counts AS (
    SELECT
        `City`,
        `Locality`,
        COUNT(`RestaurantID`) AS REST_COUNT
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`, `Locality`
),
top_locality AS (
    SELECT
        `Locality`
    FROM locality_counts
    WHERE REST_COUNT = (
        SELECT MAX(REST_COUNT) FROM locality_counts
    )
)
SELECT
    z.`Locality`,
    COUNT(*) AS TABLE_BOOKING_OPTION
FROM ZomatoData1 z
JOIN top_locality t
    ON z.`Locality` = t.`Locality`
WHERE z.`Has_Table_booking` = 'YES'
GROUP BY z.`Locality`;


-- QUESTION 10: How does rating differ for restaurants with and without table booking in Connaught Place?
SELECT
    'WITH_TABLE' AS TABLE_BOOKING_OPT,
    COUNT(*) AS TOTAL_REST,
    ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS AVG_RATING
FROM ZomatoData1
WHERE `Has_Table_booking` = 'YES'
  AND `Locality` = 'Connaught Place'

UNION ALL

SELECT
    'WITHOUT_TABLE' AS TABLE_BOOKING_OPT,
    COUNT(*) AS TOTAL_REST,
    ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS AVG_RATING
FROM ZomatoData1
WHERE `Has_Table_booking` = 'NO'
  AND `Locality` = 'Connaught Place';


-- QUESTION 11: What is the average rating and restaurant count locality-wise across all countries and cities?
SELECT
    `COUNTRY_NAME`,
    `City`,
    `Locality`,
    COUNT(`RestaurantID`) AS TOTAL_REST,
    ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS AVG_RATING
FROM ZomatoData1
GROUP BY `COUNTRY_NAME`, `City`, `Locality`
ORDER BY TOTAL_REST DESC;


-- QUESTION 12: Which restaurants in India offer table booking and online delivery, have moderate cost for two, high votes, high ratings, and Indian cuisine?
SELECT *
FROM ZomatoData1
WHERE `COUNTRY_NAME` = 'INDIA'
  AND `Has_Table_booking` = 'YES'
  AND `Has_Online_delivery` = 'YES'
  AND `Price_range` <= 3
  AND `Votes` > 1000
  AND `Average_Cost_for_two` < 1000
  AND `Rating` > 4
  AND `Cuisines` LIKE '%Indian%';


-- QUESTION 13: Among highly rated restaurants, how many offer table booking across each price range?
SELECT
    `Price_range`,
    COUNT(*) AS NO_OF_REST
FROM ZomatoData1
WHERE `Rating` >= 4.5
  AND `Has_Table_booking` = 'YES'
GROUP BY `Price_range`
ORDER BY `Price_range`;


-- =========================================================
-- UPGRADED BUSINESS-ORIENTED ANALYSIS
-- =========================================================

-- QUESTION 14: Which Indian cities are oversaturated, balanced, or underserved based on demand per restaurant?
WITH city_metrics AS (
    SELECT
        `City`,
        COUNT(`RestaurantID`) AS total_restaurants,
        SUM(CAST(`Votes` AS SIGNED)) AS total_votes,
        ROUND(
            CAST(SUM(CAST(`Votes` AS SIGNED)) AS DECIMAL(18,2))
            / NULLIF(COUNT(`RestaurantID`), 0), 2
        ) AS votes_per_restaurant,
        ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`
)
SELECT *,
       CASE
           WHEN votes_per_restaurant >= 150 AND total_restaurants < 50 THEN 'UNDERSERVED_OPPORTUNITY'
           WHEN votes_per_restaurant < 80 AND total_restaurants > 100 THEN 'OVERSATURATED'
           ELSE 'BALANCED'
       END AS market_status
FROM city_metrics
ORDER BY votes_per_restaurant DESC, avg_rating DESC;


-- QUESTION 15: Which localities within each city have the highest opportunity based on demand and ratings?
WITH locality_metrics AS (
    SELECT
        `City`,
        `Locality`,
        COUNT(`RestaurantID`) AS total_restaurants,
        SUM(CAST(`Votes` AS SIGNED)) AS total_votes,
        ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating,
        ROUND(
            CAST(SUM(CAST(`Votes` AS SIGNED)) AS DECIMAL(18,2))
            / NULLIF(COUNT(`RestaurantID`), 0), 2
        ) AS votes_per_restaurant
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`, `Locality`
)
SELECT *,
       DENSE_RANK() OVER (
           PARTITION BY `City`
           ORDER BY votes_per_restaurant DESC, avg_rating DESC
       ) AS locality_rank_within_city
FROM locality_metrics
ORDER BY `City`, locality_rank_within_city;


-- QUESTION 16: Does online delivery correlate with better ratings, engagement, and cost across restaurants in India?
SELECT
    `Has_Online_delivery`,
    COUNT(`RestaurantID`) AS total_restaurants,
    ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating,
    ROUND(AVG(CAST(`Votes` AS DECIMAL(18,2))), 2) AS avg_votes,
    ROUND(AVG(CAST(`Average_Cost_for_two` AS DECIMAL(18,2))), 2) AS avg_cost_for_two
FROM ZomatoData1
WHERE `COUNTRY_NAME` = 'INDIA'
GROUP BY `Has_Online_delivery`;


-- QUESTION 17: How does online delivery impact restaurant performance across different price segments?
SELECT
    `Price_range`,
    `Has_Online_delivery`,
    COUNT(`RestaurantID`) AS total_restaurants,
    ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating,
    ROUND(AVG(CAST(`Votes` AS DECIMAL(18,2))), 2) AS avg_votes
FROM ZomatoData1
WHERE `COUNTRY_NAME` = 'INDIA'
GROUP BY `Price_range`, `Has_Online_delivery`
ORDER BY `Price_range`, `Has_Online_delivery`;


-- QUESTION 18: How does table booking impact restaurant ratings and engagement across different price ranges?
SELECT
    `Price_range`,
    `Has_Table_booking`,
    COUNT(`RestaurantID`) AS total_restaurants,
    ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating,
    ROUND(AVG(CAST(`Votes` AS DECIMAL(18,2))), 2) AS avg_votes
FROM ZomatoData1
WHERE `COUNTRY_NAME` = 'INDIA'
GROUP BY `Price_range`, `Has_Table_booking`
ORDER BY `Price_range`, `Has_Table_booking`;


-- QUESTION 19: Which restaurant configuration performs best in each city by pricing, delivery, and booking attributes?
WITH segment_perf AS (
    SELECT
        `City`,
        `Price_range`,
        `Has_Online_delivery`,
        `Has_Table_booking`,
        COUNT(`RestaurantID`) AS total_restaurants,
        ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating,
        ROUND(AVG(CAST(`Votes` AS DECIMAL(18,2))), 2) AS avg_votes,
        ROUND(AVG(CAST(`Average_Cost_for_two` AS DECIMAL(18,2))), 2) AS avg_cost
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY
        `City`,
        `Price_range`,
        `Has_Online_delivery`,
        `Has_Table_booking`
)
SELECT *,
       DENSE_RANK() OVER (
           PARTITION BY `City`
           ORDER BY avg_rating DESC, avg_votes DESC
       ) AS segment_rank_in_city
FROM segment_perf
WHERE total_restaurants >= 5
ORDER BY `City`, segment_rank_in_city;


-- QUESTION 20: Which cuisines show the highest demand per restaurant in each city?
WITH cuisine_split AS (
    SELECT
        z.`City`,
        z.`Locality`,
        z.`RestaurantID`,
        CAST(z.`Votes` AS SIGNED) AS Votes,
        CAST(z.`Rating` AS DECIMAL(10,2)) AS Rating,
        TRIM(jt.cuisine) AS cuisine
    FROM ZomatoData1 z
    JOIN JSON_TABLE(
        CONCAT(
            '["',
            REPLACE(REPLACE(z.`Cuisines`, '"', '\\"'), ',', '","'),
            '"]'
        ),
        '$[*]' COLUMNS (
            cuisine VARCHAR(255) PATH '$'
        )
    ) jt
),
cuisine_metrics AS (
    SELECT
        `City`,
        cuisine,
        COUNT(`RestaurantID`) AS restaurant_count,
        SUM(Votes) AS total_votes,
        ROUND(AVG(Rating), 2) AS avg_rating,
        ROUND(
            CAST(SUM(Votes) AS DECIMAL(18,2))
            / NULLIF(COUNT(`RestaurantID`), 0), 2
        ) AS votes_per_restaurant
    FROM cuisine_split
    GROUP BY `City`, cuisine
)
SELECT *,
       DENSE_RANK() OVER (
           PARTITION BY `City`
           ORDER BY votes_per_restaurant DESC, avg_rating DESC
       ) AS cuisine_opportunity_rank
FROM cuisine_metrics
WHERE restaurant_count >= 3
ORDER BY `City`, cuisine_opportunity_rank;


-- QUESTION 21: Which pricing segment performs best in terms of ratings, votes, and average cost?
SELECT
    CASE
        WHEN `Price_range` IN (1,2) THEN 'BUDGET'
        WHEN `Price_range` = 3 THEN 'MID_RANGE'
        WHEN `Price_range` IN (4,5) THEN 'PREMIUM'
        ELSE 'OTHER'
    END AS restaurant_segment,
    COUNT(`RestaurantID`) AS total_restaurants,
    ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating,
    ROUND(AVG(CAST(`Votes` AS DECIMAL(18,2))), 2) AS avg_votes,
    ROUND(AVG(CAST(`Average_Cost_for_two` AS DECIMAL(18,2))), 2) AS avg_cost
FROM ZomatoData1
WHERE `COUNTRY_NAME` = 'INDIA'
GROUP BY
    CASE
        WHEN `Price_range` IN (1,2) THEN 'BUDGET'
        WHEN `Price_range` = 3 THEN 'MID_RANGE'
        WHEN `Price_range` IN (4,5) THEN 'PREMIUM'
        ELSE 'OTHER'
    END
ORDER BY avg_votes DESC;


-- QUESTION 22: Which restaurants can be considered hidden gems based on high ratings, strong votes, and affordable pricing?
SELECT
    `Restaurant Name`,
    `City`,
    `Locality`,
    `Cuisines`,
    `Average_Cost_for_two`,
    `Rating`,
    `Votes`
FROM ZomatoData1
WHERE `COUNTRY_NAME` = 'INDIA'
  AND CAST(`Rating` AS DECIMAL(10,2)) >= 4.3
  AND CAST(`Votes` AS SIGNED) >= 500
  AND CAST(`Average_Cost_for_two` AS SIGNED) <= 800
ORDER BY CAST(`Rating` AS DECIMAL(10,2)) DESC,
         CAST(`Votes` AS SIGNED) DESC;


-- QUESTION 23: What are the top 5 restaurants in each city based on rating and votes?
WITH city_rest_rank AS (
    SELECT
        `City`,
        `Restaurant Name`,
        `Locality`,
        `Rating`,
        `Votes`,
        ROW_NUMBER() OVER (
            PARTITION BY `City`
            ORDER BY CAST(`Rating` AS DECIMAL(10,2)) DESC,
                     CAST(`Votes` AS SIGNED) DESC
        ) AS rn
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
)
SELECT *
FROM city_rest_rank
WHERE rn <= 5
ORDER BY `City`, rn;


-- QUESTION 24: Which Indian cities should be prioritized for restaurant expansion using a composite expansion score?
WITH city_metrics AS (
    SELECT
        `City`,
        COUNT(`RestaurantID`) AS total_restaurants,
        SUM(CAST(`Votes` AS SIGNED)) AS total_votes,
        ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating,
        ROUND(AVG(CAST(`Average_Cost_for_two` AS DECIMAL(18,2))), 2) AS avg_cost_for_two,
        ROUND(
            CAST(SUM(CAST(`Votes` AS SIGNED)) AS DECIMAL(18,2)) /
            NULLIF(COUNT(`RestaurantID`), 0),
            2
        ) AS votes_per_restaurant,
        SUM(CASE WHEN `Has_Online_delivery` = 'YES' THEN 1 ELSE 0 END) AS online_delivery_restaurants
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`
),
city_scores AS (
    SELECT
        `City`,
        total_restaurants,
        total_votes,
        avg_rating,
        avg_cost_for_two,
        votes_per_restaurant,
        online_delivery_restaurants,
        ROUND(
            CAST(online_delivery_restaurants AS DECIMAL(18,2)) /
            NULLIF(total_restaurants, 0) * 100,
            2
        ) AS online_delivery_pct,
        ROUND(
            (votes_per_restaurant * 0.50) +
            (avg_rating * 20 * 0.30) -
            (total_restaurants * 0.20),
            2
        ) AS expansion_score
    FROM city_metrics
)
SELECT *,
       DENSE_RANK() OVER (ORDER BY expansion_score DESC) AS city_expansion_rank
FROM city_scores
ORDER BY city_expansion_rank;


-- QUESTION 25: How can cities be classified into expansion opportunity buckets?
WITH city_metrics AS (
    SELECT
        `City`,
        COUNT(`RestaurantID`) AS total_restaurants,
        SUM(CAST(`Votes` AS SIGNED)) AS total_votes,
        ROUND(AVG(CAST(`Rating` AS DECIMAL(10,2))), 2) AS avg_rating,
        ROUND(
            CAST(SUM(CAST(`Votes` AS SIGNED)) AS DECIMAL(18,2))
            / NULLIF(COUNT(`RestaurantID`), 0),
            2
        ) AS votes_per_restaurant
    FROM ZomatoData1
    WHERE `COUNTRY_NAME` = 'INDIA'
    GROUP BY `City`
)
SELECT *,
       CASE
           WHEN votes_per_restaurant >= 200 AND total_restaurants < 80 THEN 'HIGH_OPPORTUNITY'
           WHEN votes_per_restaurant BETWEEN 120 AND 199 THEN 'MODERATE_OPPORTUNITY'
           ELSE 'LOW_OPPORTUNITY_OR_SATURATED'
       END AS opportunity_bucket
FROM city_metrics
ORDER BY votes_per_restaurant DESC, avg_rating DESC;
