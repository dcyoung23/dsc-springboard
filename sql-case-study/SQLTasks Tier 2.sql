/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT 
  name
FROM 
  Facilities
WHERE 
  membercost > 0

/* Q2: How many facilities do not charge a fee to members? */
-- This query makes it eaier to add in other facility conditional aggregates as well
-- Answer = 4
SELECT 
  SUM(CASE WHEN membercost = 0 THEN 1 ELSE 0 END) AS no_member_cost
FROM 
  Facilities

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT
  facid
  ,name
  ,membercost
  ,monthlymaintenance
FROM 
  Facilities
WHERE 
  membercost > 0
  AND membercost < (monthlymaintenance * .2)

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT
  *
FROM 
  Facilities
WHERE
  facid in (1,5)

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT 
  name
  ,monthlymaintenance
  ,CASE WHEN monthlymaintenance > 100 THEN 'expensive' else 'cheap' END AS monthlymaintenance_category
FROM
  Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
-- Normally would have used a Window Function here but the MySQL version is < 8
SELECT
  firstname
  ,surname
FROM
  Members
WHERE
  joindate in (SELECT MAX(joindate) FROM Members)

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT
  F.name
  ,CONCAT(M.firstname,' ',M.surname) as member_name
  ,SUM(F.membercost) AS membercost_total
FROM 
  Members M
  INNER JOIN Bookings B ON M.memid = B.memid
  INNER JOIN Facilities F ON B.facid = F.facid
WHERE 
  F.name like '%Tennis Court%'
GROUP BY
  F.name
  ,member_name
ORDER BY
  member_name

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
SELECT 
  F.name
  ,CASE WHEN M.memid = 0 THEN 'Guest' ELSE CONCAT( M.firstname, ' ', M.surname ) END AS member_name
  ,SUM(CASE WHEN M.memid = 0 THEN F.guestcost ELSE F.membercost END * B.slots ) AS cost
FROM 
  Bookings B
  INNER JOIN Facilities F ON B.facid = F.facid
  LEFT JOIN Members M ON B.memid = M.memid
WHERE 
  DATE(starttime) = '2012-09-14'
GROUP BY 
  F.name
  ,member_name
HAVING 
  cost > 30
ORDER BY 
  cost DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT
name
  ,member_name
  ,SUM(cost) AS cost
FROM 
(
SELECT 
  F.name
  ,CASE WHEN M.memid = 0 THEN 'Guest' ELSE CONCAT( M.firstname, ' ', M.surname ) END AS member_name
  ,CASE WHEN M.memid = 0 THEN F.guestcost ELSE F.membercost END * B.slots AS cost
FROM 
  Bookings B
  INNER JOIN Facilities F ON B.facid = F.facid
  LEFT JOIN Members M ON B.memid = M.memid
WHERE 
  DATE(starttime) = '2012-09-14'
) X
GROUP BY
  name
  ,member_name
HAVING 
  cost > 30
ORDER BY
  cost DESC

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
def run_query(engine, q):
    with engine.connect() as con:
        rs = con.execute(q)
        df = pd.DataFrame(rs.fetchmany(size=5))
        df.columns = rs.keys()
    return df

q = """ 
    SELECT 
     F.name
    ,SUM(CASE WHEN M.memid = 0 THEN F.guestcost ELSE F.membercost END * B.slots ) AS revenue
    FROM Bookings B
    INNER JOIN Facilities F ON B.facid = F.facid
    LEFT JOIN Members M ON B.memid = M.memid
    GROUP BY 
    F.name
    HAVING(revenue) < 1000
    ORDER BY 
    revenue
    """ 
run_query(engine, q)

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
q = """ 
    SELECT 
    M.memid
    ,M.firstname
    ,M.surname
    ,M.address
    ,M.zipcode
    ,M.telephone
    ,R.firstname || ' ' || R.surname as recommendedby_name
    FROM Members M
    INNER JOIN Members R ON M.recommendedby = R.memid
    WHERE M.recommendedby > 0
    ORDER BY
    M.surname
    ,M.firstname
    """ 
run_query(engine, q)

/* Q12: Find the facilities with their usage by member, but not guests */
q = """ 
    SELECT 
    F.name
    ,M.memid
    ,M.firstname || ' ' || M.surname as member_name
    ,SUM(B.slots) AS usage
    FROM Bookings B
    INNER JOIN Facilities F ON B.facid = F.facid
    INNER JOIN Members M ON B.memid = M.memid
    WHERE M.memid > 0
    GROUP BY
    F.name
    ,M.memid
    ,member_name
    ORDER BY
    usage DESC
    """ 
run_query(engine, q)

/* Q13: Find the facilities usage by month, but not guests */
q = """ 
    SELECT 
    F.name
    ,strftime('%Y-%m', B.starttime) as month
    ,SUM(B.slots) AS usage
    FROM Bookings B
    INNER JOIN Facilities F ON B.facid = F.facid
    INNER JOIN Members M ON B.memid = M.memid
    WHERE M.memid > 0
    GROUP BY
    F.name
    ,month
    ORDER BY
    usage DESC
    """ 
run_query(engine, q)
