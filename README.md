
# Zomato Data Analysis – Market Expansion & Performance Insights

## Overview
In this project, I worked on Zomato restaurant data to understand how restaurants perform across different cities and localities in India.

The main idea was not just to explore the data, but to figure out:
- where demand is high but supply is low
- which types of restaurants perform better
- what factors (like delivery or pricing) affect ratings and engagement

---

## Problem Statement
If Zomato wants to expand or onboard more restaurants, where should they focus?

To answer this, I tried to:
- identify underserved cities and localities
- compare different price ranges and cuisines
- check the impact of online delivery and table booking
- find patterns in ratings and votes

---

## Approach

I used SQL to break the problem into smaller parts:

### 1. City-level analysis
- counted number of restaurants per city
- calculated votes per restaurant as a proxy for demand
- compared cities to identify high-demand areas

### 2. Locality-level analysis
- ranked localities within each city
- looked at which areas perform better in terms of ratings and votes

### 3. Pricing & segment analysis
- grouped restaurants by price range
- checked how ratings and votes change across segments

### 4. Delivery & booking impact
- compared restaurants with and without online delivery
- compared restaurants with and without table booking

### 5. Cuisine analysis
- split cuisine column and analyzed demand per cuisine
- identified cuisines with higher engagement

### 6. Expansion score
- created a simple score using:
  - votes per restaurant
  - average rating
  - number of restaurants (competition)
- used this to rank cities for expansion

---

## Key Observations

- Some cities have high votes per restaurant but fewer listings → possible unmet demand  
- Mid-range restaurants tend to have better balance of rating and engagement  
- Online delivery is generally associated with higher votes  
- Highly saturated areas often show lower engagement per restaurant  

---

## Recommendations

Based on the analysis:

- Focus expansion on cities with high demand but lower restaurant density  
- Prioritize mid-range pricing segments for better performance  
- Encourage more restaurants to enable online delivery  
- Target high-performing cuisines in underserved areas  

---

## Tech Used
- SQL (CTEs, window functions, aggregations, views)

---

## Conclusion
This project helped me understand how SQL can be used not just for querying data, but for thinking about real business problems like expansion and performance.

---

## Author
Shaan Raza
