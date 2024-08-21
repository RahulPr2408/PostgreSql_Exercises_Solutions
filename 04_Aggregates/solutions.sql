-- https://pgexercises.com/questions/aggregates/
-- Above is the link for the PostGreSQl Exercises Website
-- Category : Aggregates

-- Q.1 For our first foray into aggregates, we're going to stick to something simple. We want to know how many facilities exist - simply produce a total count.

SELECT COUNT(*)
FROM cd.facilities

-- Q.2 Produce a count of the number of facilities that have a cost to guests of 10 or more.

SELECT COUNT(*)
FROM cd.facilities
WHERE guestcost >= 10

-- Q.3 Produce a count of the number of recommendations each member has made. Order by member ID.

SELECT recommendedby, COUNT(*) AS count
FROM cd.members
WHERE recommendedby IS NOT NULL
GROUP BY recommendedby
ORDER BY recommendedby

-- Q.4 Produce a list of the total number of slots booked per facility. For now, just produce an output table consisting of facility id and slots, sorted by facility id.

SELECT facid, SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
ORDER BY facid

-- Q.5 Produce a list of the total number of slots booked per facility in the month of September 2012. Produce an output table consisting of facility id and slots, sorted by the number of slots.

SELECT facid, SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE DATE_TRUNC('month', starttime) = '2012-09-01'
GROUP BY facid
ORDER BY "Total Slots"

-- Q.6 Produce a list of the total number of slots booked per facility per month in the year of 2012. Produce an output table consisting of facility id and slots, sorted by the id and month.

SELECT facid, EXTRACT('month' FROM starttime) AS month,
SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE EXTRACT('year' FROM starttime) = 2012
GROUP BY facid, EXTRACT('month' FROM starttime)
ORDER BY facid, month

-- Q.7 Find the total number of members (including guests) who have made at least one booking.

SELECT COUNT(DISTINCT memid)
FROM cd.bookings

-- Q.8 Produce a list of facilities with more than 1000 slots booked. Produce an output table consisting of facility id and slots, sorted by facility id.

SELECT facid, SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
HAVING SUM(slots) > 1000 
ORDER BY facid

-- Q.9 Produce a list of facilities along with their total revenue. The output table should consist of facility name and revenue, sorted by revenue. Remember that there's a different cost for guests and members!

SELECT facs.name,
SUM(CASE
	WHEN book.memid = 0 THEN facs.guestcost
	ELSE facs.membercost
END * slots) AS revenue
FROM cd.bookings book 
JOIN cd.facilities facs
ON book.facid = facs.facid
GROUP BY facs.name
ORDER BY revenue

-- Q.10 Produce a list of facilities with a total revenue less than 1000. Produce an output table consisting of facility name and revenue, sorted by revenue. Remember that there's a different cost for guests and members!

WITH t1 as
(SELECT facs.name,
SUM(
  CASE
  	WHEN book.memid = 0 THEN facs.guestcost
  	ELSE facs.membercost
  END * slots
  ) AS revenue
  
FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
GROUP BY facs.name) 

SELECT *
FROM t1
WHERE revenue < 1000
ORDER BY revenue


-- Q.11 Output the facility id that has the highest number of slots booked. For bonus points, try a version without a LIMIT clause. This version will probably look messy!

WITH t1 AS
(SELECT facid, SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid)

SELECT *
FROM t1
WHERE "Total Slots" = (SELECT MAX("Total Slots") FROM t1)

-- OR

WITH t1 AS
(SELECT facid, SUM(slots) AS "Total Slots",
 MAX(SUM(slots)) over() AS max_slots
FROM cd.bookings
GROUP BY facid)

SELECT facid, "Total Slots"
FROM t1
WHERE "Total Slots" = max_slots

-- Q.12 Produce a list of the total number of slots booked per facility per month in the year of 2012. In this version, include output rows containing totals for all months per facility, and a total for all months for all facilities. The output table should consist of facility id, month and slots, sorted by the id and month. When calculating the aggregated values for all months and all facids, return null values in the month and facid columns.

-- total by facility, month

SELECT facid, EXTRACT('month' FROM starttime) AS month,
SUM(slots) AS slots
FROM cd.bookings
WHERE EXTRACT('year' FROM starttime) = 2012
GROUP BY facid, EXTRACT('month' FROM starttime) 

UNION

-- total by facility

SELECT facid, NULL,
SUM(slots) AS slots
FROM cd.bookings
WHERE EXTRACT('year' FROM starttime) = 2012
GROUP BY facid 

UNION
-- final total

SELECT NULL, NULL,
SUM(slots) AS slots
FROM cd.bookings
WHERE EXTRACT('year' FROM starttime) = 2012 

ORDER BY facid, month

-- Q.13 Produce a list of the total number of hours booked per facility, remembering that a slot lasts half an hour. The output table should consist of the facility id, name, and hours booked, sorted by facility id. Try formatting the hours to two decimal places.

SELECT book.facid, facs.name, ROUND(SUM(book.slots) / 2.0, 2) AS "Total Hours"
FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
GROUP BY book.facid, facs.name
ORDER BY facid

-- Q.14 Produce a list of each member name, id, and their first booking after September 1st 2012. Order by member ID.

SELECT mems.surname, mems.firstname, mems.memid,
MIN(starttime) AS starttime
FROM cd.members mems
JOIN cd.bookings book
ON mems.memid = book.memid
WHERE starttime > '2012-09-01'
GROUP BY mems.surname, mems.firstname, mems.memid
ORDER BY memid

-- Q.15 Produce a list of member names, with each row containing the total member count. Order by join date, and include guest members.

SELECT COUNT(*) OVER(), firstname, surname
FROM cd.members

-- Q.16 Produce a monotonically increasing numbered list of members (including guests), ordered by their date of joining. Remember that member IDs are not guaranteed to be sequential.

SELECT ROW_NUMBER() OVER(ORDER BY joindate) as row_number,
firstname, surname
FROM cd.members

-- Q.17 Output the facility id that has the highest number of slots booked. Ensure that in the event of a tie, all tieing results get output.

WITH t1 AS (
	SELECT facid, SUM(slots) AS total,
  	RANK() OVER(ORDER BY SUM(slots) DESC) AS rk
	FROM cd.bookings
	GROUP BY facid
	ORDER BY SUM(slots) DESC  
)

SELECT facid, total
FROM t1
WHERE rk = 1

-- Q.18 Produce a list of members (including guests), along with the number of hours they've booked in facilities, rounded to the nearest ten hours. Rank them by this rounded figure, producing output of first name, surname, rounded hours, rank. Sort by rank, surname, and first name.

SELECT mems.firstname, mems.surname,
ROUND(SUM(slots) / 2.0, -1) as hours,
RANK() OVER(ORDER BY ROUND(SUM(slots) / 2.0, -1) DESC) as rank
FROM cd.members mems
JOIN cd.bookings book
ON mems.memid = book.memid
GROUP BY mems.firstname, mems.surname
ORDER BY rank, surname, firstname

-- How Rounding Works

SELECT 
28910.78201,
ROUND(28910.78201, 2),
ROUND(28910.78201, 1),
ROUND(28910.78201),
ROUND(28910.78201, -1),  -- it'll round it to nearest 10
ROUND(28910.78201, -2),  -- it'll round it to nearesr 100
ROUND(28910.78201, -3),  -- it'll round it to nearesr 1000
ROUND(28910.78201, -4),  -- it'll round it to nearesr 10000
ROUND(28910.78201, -5)   -- it'll round it to nearesr 100000

-- Q.19 Produce a list of the top three revenue generating facilities (including ties). Output facility name and rank, sorted by rank and facility name.

WITH t1 AS
(SELECT facs.name,
RANK () OVER(ORDER BY SUM(
	CASE
  		WHEN book.memid = 0 THEN facs.guestcost
  		ELSE facs.membercost
  	END * slots
) DESC) as rank

FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
GROUP BY facs.name) 

SELECT *
FROM t1
WHERE rank <= 3

-- Q.20 Classify facilities into equally sized groups of high, average, and low based on their revenue. Order by classification and facility name.

WITH t1 AS
(SELECT facs.name,
NTILE(3) OVER(ORDER BY SUM(
	CASE
  		WHEN book.memid = 0 THEN facs.guestcost
  		ELSE facs.membercost
  	END * slots
) DESC) as ntile

FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
GROUP BY facs.name)

SELECT name,
CASE
	WHEN ntile = 1 THEN 'high'
	WHEN ntile = 2 THEN 'average'
	ELSE 'low'
END AS revenue
FROM t1
ORDER BY ntile, name

-- Q.21 Based on the 3 complete months of data so far, calculate the amount of time each facility will take to repay its cost of ownership. Remember to take into account ongoing monthly maintenance. Output facility name and payback time in months, order by facility name. Don't worry about differences in month lengths, we're only looking for a rough value here!

SELECT facs.name,
facs.initialoutlay / (SUM(
	CASE
  		WHEN book.memid = 0 THEN facs.guestcost
  		ELSE facs.membercost
  	END * slots
) / 3.0 - facs.monthlymaintenance) as months

FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
GROUP BY facs.name, facs.monthlymaintenance, facs.initialoutlay
ORDER BY facs.name

-- Q.22 For each day in August 2012, calculate a rolling average of total revenue over the previous 15 days. Output should contain date and revenue columns, sorted by the date. Remember to account for the possibility of a day having zero revenue. This one's a bit tough, so don't be afraid to check out the hint!

WITH t1 AS
(SELECT DATE(book.starttime),

AVG(SUM(
	CASE
  		WHEN book.memid = 0 THEN facs.guestcost
  		ELSE facs.membercost
  	END * slots)) OVER(ORDER BY DATE(book.starttime) 
					   ROWS BETWEEN 14 PRECEDING AND CURRENT ROW) AS revenue


FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
GROUP BY DATE(book.starttime))

SELECT *
FROM t1
WHERE EXTRACT('month' FROM date) = 8
ORDER BY date