/* Calculate monthly averages by borough */

WITH so_by_borough 
AS
(
#combining rapes and other sexual offences, by borough and month
SELECT SUM(incidents) AS total_incidents, major, borough, 
CONCAT(dateyear, "/", datemonth) AS yearmonth
FROM london_crime_borough
WHERE major = "Sexual Offences"
GROUP BY major, borough, yearmonth
ORDER BY total_incidents DESC
)
#join with borough populations, calculate monthly averages for each borough
SELECT round(AVG(total_incidents),0) AS avg_monthly_incidents,
ROUND((AVG(total_incidents)/population)*100000, 0) AS avg_per_100k, 
s.borough, p.population, s.major
FROM so_by_borough AS s
LEFT JOIN borough_population AS p ON s.borough = p.borough 
GROUP BY s.borough
ORDER BY avg_per_100k DESC

/* Calculate the highest number of total incidents by borough and month */

SELECT SUM(incidents) AS total_incidents, major, borough, 
CONCAT(dateyear, "/", datemonth) AS yearmonth, datemonth
FROM london_crime_borough
WHERE major = "Sexual Offences"
GROUP BY yearmonth, borough
ORDER BY total_incidents DESC

/* Combine rape and other sexual assaults into total for Barnet */

#combine year and month into one column
SELECT SUM(incidents) AS total_incidents, major, borough,
dateyear, datemonth,
CONCAT(dateyear, "/", datemonth) AS yearmonth      
FROM london_crime_borough             
WHERE borough LIKE "%Barnet%" AND major LIKE "%sexual%" 
GROUP BY major, yearmonth                     
ORDER BY dateyear ASC, datemonth ASC

/* Create column rating each month compared to average for Barnet */
with barnet_so_averages AS

(
with total_barnet_so AS 

(
SELECT SUM(incidents) AS total_incidents, major, borough,
dateyear, datemonth,
CONCAT(dateyear, "/", datemonth) AS yearmonth       
FROM london_crime_borough             
WHERE borough LIKE "%Barnet%" AND major LIKE "%sexual%" 
GROUP BY major, yearmonth                        
ORDER BY dateyear asc, datemonth ASC
)

SELECT major, borough, dateyear, datemonth,total_incidents,
(
select AVG(total_incidents) FROM total_barnet_so 
)AS incident_average
FROM total_barnet_so
ORDER BY dateyear, datemonth

)

SELECT major, borough, dateyear, datemonth, total_incidents,
round(incident_average,0) AS average_incidents,
CASE
	when total_incidents > incident_average then "ABOVE AVERAGE"
	when total_incidents = incident_average then "AVERAGE"
	when total_incidents < incident_average then "BELOW AVERAGE"
END AS month_rating
FROM barnet_so_averages

/* Examine incident quartiles for Barnet sexual assaults */
with barnet_so_quartiles AS 
(
with total_barnet_so AS 

(
SELECT SUM(incidents) AS total_incidents, major, borough,
dateyear, datemonth,
CONCAT(dateyear, "/", datemonth) AS yearmonth       
FROM london_crime_borough             
WHERE borough LIKE "%Barnet%" AND major LIKE "%sexual%" 
GROUP BY major, yearmonth                        
ORDER BY dateyear asc, datemonth ASC
)

#divide Barnet months into quartiles
SELECT major, borough, dateyear, datemonth,total_incidents,
NTILE(4) over (ORDER BY total_incidents)
AS quartile
FROM total_barnet_so
)

#show min, max, and avg number of incidents in each quartile
SELECT MIN(total_incidents),
MAX(total_incidents), round(AVG(total_incidents),0) AS avg_incidents,
major, borough, quartile 
FROM barnet_so_quartiles
GROUP BY quartile

/* Calculate monthly change in sexual assaul incidents for Barnet */
with total_barnet_so AS 

(
SELECT SUM(incidents) AS total_incidents, major, borough,
dateyear, datemonth,
CONCAT(dateyear, "/", datemonth) AS yearmonth       
FROM london_crime_borough             
WHERE borough LIKE "%Barnet%" AND major LIKE "%sexual%" 
GROUP BY major, yearmonth                        
ORDER BY dateyear asc, datemonth ASC
)

SELECT major, borough, dateyear, datemonth,total_incidents,
total_incidents - LAG(total_incidents, 1) over (ORDER BY dateyear ASC, datemonth ASC)
AS incident_change
FROM total_barnet_so

/* Calculate total sexual assault running average for 2021 for Barnet */
with total_barnet_so AS 

(
SELECT SUM(incidents) AS total_incidents, major, borough,
dateyear, datemonth,
CONCAT(dateyear, "/", datemonth) AS yearmonth       
FROM london_crime_borough             
WHERE borough LIKE "%Barnet%" AND major LIKE "%sexual%" 
GROUP BY major, yearmonth                        
ORDER BY dateyear asc, datemonth ASC
)

#use 2021 as its the only complete year in last 24 months of data
SELECT major, borough, dateyear, datemonth,total_incidents,
ROUND(AVG(total_incidents) over 
(partition by dateyear ORDER BY dateyear ASC, datemonth ASC)
, 0) AS running_average
FROM total_barnet_so
WHERE dateyear = 2021
