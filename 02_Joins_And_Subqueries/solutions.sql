-- https://pgexercises.com/questions/joins/
-- Above is the link for the PostGreSQl Exercises Website
-- Category : Joins and Subqueries

-- Q.1 How can you produce a list of the start times for bookings by members named 'David Farrell'?

SELECT book.starttime
FROM cd.bookings book JOIN cd.members mem
ON book.memid = mem.memid
WHERE mem.firstname = 'David' AND surname = 'Farrell'

-- Q.2 How can you produce a list of the start times for bookings for tennis courts, for the date '2012-09-21'? Return a list of start time and facility name pairings, ordered by the time.

SELECT book.starttime, facs.name
FROM cd.bookings book JOIN cd.facilities facs
ON book.facid = facs.facid
WHERE facs.name LIKE 'Tennis%'AND date(book.starttime) = '2012-09-21'
ORDER BY book.starttime

-- Q.3 How can you output a list of all members who have recommended another member? Ensure that there are no duplicates in the list, and that results are ordered by (surname, firstname).

SELECT DISTINCT recs.firstname, recs.surname
FROM cd.members mems JOIN cd.members recs
ON mems.recommendedby = recs.memid
ORDER BY surname, firstname

-- Q.4 How can you output a list of all members, including the individual who recommended them (if any)? Ensure that results are ordered by (surname, firstname).

SELECT mems.firstname, mems.surname, recs.firstname, recs.surname
FROM cd.members mems LEFT JOIN cd.members recs
ON mems.recommendedby = recs.memid
ORDER BY mems.surname, mems.firstname

-- Q.5 How can you produce a list of all members who have used a tennis court? Include in your output the name of the court, and the name of the member formatted as a single column. Ensure no duplicate data, and order by the member name followed by the facility name.

SELECT DISTINCT mems.firstname || ' ' || mems.surname AS member, facs.name AS facility
FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
JOIN cd.members mems 
ON mems.memid = book.memid
WHERE facs.name LIKE '%Tennis Court%'
ORDER BY member, facility

-- Q.6 How can you produce a list of bookings on the day of 2012-09-14 which will cost the member (or guest) more than $30? Remember that guests have different costs to members (the listed costs are per half-hour 'slot'), and the guest user is always ID 0. Include in your output the name of the facility, the name of the member formatted as a single column, and the cost. Order by descending cost, and do not use any subqueries.

WITH t1 AS

(SELECT mems.firstname || ' ' || mems.surname AS member, facs.name AS facility,
	book.slots * 
	CASE
		WHEN book.memid = 0 THEN facs.guestcost
		ELSE facs.membercost
	END AS cost

FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
JOIN cd.members mems
ON book.memid = mems.memid

WHERE DATE(book.starttime) = '2012-09-14'
ORDER BY cost DESC) 

SELECT *
FROM t1
WHERE cost > 30

-- Q.7 How can you output a list of all members, including the individual who recommended them (if any), without using any joins? Ensure that there are no duplicates in the list, and that each firstname + surname pairing is formatted as a column and ordered.

SELECT DISTINCT firstname || ' ' || surname AS member, 
(SELECT firstname || ' ' || surname	
  FROM cd.members recs
WHERE recs.memid = mems.recommendedby) AS recommender
FROM cd.members mems
ORDER BY member, recommender 

-- Q.8 The Produce a list of costly bookings exercise contained some messy logic: we had to calculate the booking cost in both the WHERE clause and the CASE statement. Try to simplify this calculation using subqueries. For reference, the question was:

-- How can you produce a list of bookings on the day of 2012-09-14 which will cost the member (or guest) more than $30? Remember that guests have different costs to members (the listed costs are per half-hour 'slot'), and the guest user is always ID 0. Include in your output the name of the facility, the name of the member formatted as a single column, and the cost. Order by descending cost.

WITH t1 AS

(SELECT mems.firstname || ' ' || mems.surname AS member, facs.name AS facility,
	book.slots * 
	CASE
		WHEN book.memid = 0 THEN facs.guestcost
		ELSE facs.membercost
	END AS cost

FROM cd.bookings book
JOIN cd.facilities facs
ON book.facid = facs.facid
JOIN cd.members mems
ON book.memid = mems.memid

WHERE DATE(book.starttime) = '2012-09-14'
ORDER BY cost DESC) 

SELECT *
FROM t1
WHERE cost > 30
