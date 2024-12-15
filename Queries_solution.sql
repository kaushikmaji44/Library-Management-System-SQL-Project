-- Library Management System Project using SQL --

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;


 -- Project Tasks --

-- Task 1. Create a New Book Record.
-- "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')".

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher) 
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;


-- Task 2: Update an Existing Member's Address.

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
SELECT * FROM members;


-- Task 3: Delete a Record from the Issued Status Table.
-- (Objective: Delete the record with issued_id = 'IS121' from the issued_status table).

DELETE FROM issued_status
WHERE issued_id = 'IS140';
SELECT * FROM issued_status;


-- Task 4: Retrieve All Books Issued by a Specific Employee.
-- (Objective: Select all books issued by the employee with emp_id = 'E101').

SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101';


-- Task 5: List Members Who Have Issued More Than One Book.
-- (Objective: Use GROUP BY to find members who have issued more than one book).

SELECT 
	issued_member_id,
	COUNT(*) AS total_books_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1
ORDER BY total_books_issued DESC;

-- OR --

SELECT m.member_id, m.member_name
FROM members as m
join issued_status as i
on m.member_id = i.issued_member_id
GROUP BY member_id
HAVING COUNT(*) > 1
ORDER BY m.member_id;


-- CTAS (Create Table As Select)

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - 
--         each book and total book_issued_cnt.

CREATE TABLE books_table AS
SELECT b.isbn, b.book_title, COUNT(i.issued_id)
FROM books AS b
JOIN issued_status AS i
ON b.isbn = i.issued_book_isbn
GROUP BY b.book_title, b.isbn;

SELECT *
FROM books_table;


-- Data Analysis & Findings

-- The following SQL queries were used to address specific questions:

-- Task 7. Retrieve All Books in a Specific Category:

SELECT DISTINCT category
FROM books

SELECT *
FROM books
WHERE category = 'Classic';

SELECT *
FROM books
WHERE category = 'History';

SELECT *
FROM books
WHERE category = 'Fantasy';

SELECT *
FROM books
WHERE category = 'Dystopian';

SELECT *
FROM books
WHERE category = 'Horror';

SELECT *
FROM books
WHERE category = 'Literary Fiction';

SELECT *
FROM books
WHERE category = 'Mystery';

SELECT *
FROM books
WHERE category = 'Children';

SELECT *
FROM books
WHERE category = 'Science Fiction';

SELECT *
FROM books
WHERE category = 'Fiction';


-- Task 8: Find Total Rental Income by Category.

SELECT 
	b.category,
	SUM(b.rental_price) AS total_rental_income
FROM books AS b
JOIN issued_status AS i
ON b.isbn = i.issued_book_isbn
GROUP BY 1
ORDER BY 2 DESC;


-- Task 9: List Members Who Registered in the Last 180 Days.

SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 DAYS';


-- Task 10: List Employees with Their Branch Manager's Name and their branch details.

SELECT 
	e1.emp_id,
	e1.emp_name,
	e2.emp_id AS manager_id,
	e2.emp_name AS manager_name,
	b.*
FROM employees AS e1
JOIN branch AS b ON e1.branch_id = b.branch_id
JOIN employees AS e2 ON e2.emp_id = b.manager_id;


-- Task 11: Create a Table of Books with Rental Price Above a Certain Threshold.

CREATE TABLE premium_books AS
SELECT *
FROM books
WHERE rental_price >= 7;

SELECT *
FROM premium_books;


-- Task 12: Retrieve the List of Books Not Yet Returned.

SELECT 
	i.issued_id,
	i.issued_book_name,
	i.issued_date,
	r.return_date
FROM issued_status AS i
LEFT JOIN return_status AS r
ON i.issued_id = r.issued_id
WHERE r.return_date IS NUll;


-- Advanced SQL Operations

-- Task 13: Identify Members with Overdue Books.  
-- Write a query to identify members who have overdue books (assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT 
	i.issued_member_id, 
	m.member_name, 
	i.issued_book_name, 
	i.issued_date, 
	(CURRENT_DATE - i.issued_date) AS days_overdue
FROM issued_status AS i
LEFT JOIN return_status AS r ON r.issued_id = i.issued_id
JOIN members AS m ON m.member_id = i.issued_member_id
JOIN books AS b ON b.isbn = i.issued_book_isbn
WHERE
	return_date IS NULL AND (CURRENT_DATE - i.issued_date) > 30
ORDER BY 1;
	


-- Task 14: Update Book Status on Return.
-- Write a query to update the status of books in the books table to "Yes" when they are returned 
-- (based on entries in the return_status table).

SELECT *
FROM issued_status
WHERE issued_book_isbn = '978-0-679-77644-3';

SELECT *
FROM books
WHERE isbn = '978-0-679-77644-3';

UPDATE books
SET status = 'No'
WHERE isbn = '978-0-679-77644-3';

SELECT *
FROM return_status
WHERE issued_id = 'IS127';


-- (MANUALLY CREATING)
INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
VALUES ('RS120', 'IS127', CURRENT_DATE, 'Good');

SELECT *
FROM return_status
WHERE issued_id = 'IS127';

SELECT *
FROM issued_status
WHERE issued_id = 'IS127';

SELECT *
FROM books
WHERE isbn = '978-0-679-77644-3';

UPDATE books
SET status = 'Yes'
WHERE isbn = '978-0-679-77644-3';


-- Using SQL store procedures (Stores everything Automatically)

CREATE OR REPLACE PROCEDURE update_records (p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(100))
LANGUAGE plpgsql
AS $$

DECLARE
	v_isbn VARCHAR(20);
	v_book_name VARCHAR(100);

BEGIN

	-- Insertion of data into return_status table from user's input
	
	INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
	VALUES (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

	-- updating books table after insertion of data into return_status table

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO
		v_isbn,
		v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;

	UPDATE books
	SET status = 'Yes'
	WHERE isbn = v_isbn;

	RAISE NOTICE 'Thank You for returning the Book : %', v_book_name;

END;

$$



-- Testing the Procedure(update_records())

SELECT *
FROM books
WHERE isbn = '978-0-7432-7357-1';

SELECT *
FROM issued_status
WHERE issued_book_isbn = '978-0-7432-7357-1';

SELECT *
FROM return_status
WHERE issued_id = 'IS136';

-- issued_id = 'IS136'
-- isbn = '978-0-7432-7357-1'

CALL update_records('RS123', 'IS136', 'Good');


-- Task 15: Branch Performance Report.
-- Create a query that generates a performance report for each branch, showing the number of books issued, 
-- the number of books returned, and the total revenue generated from book rentals.

SELECT 
	br.branch_id,
	COUNT(i.issued_id) AS total_books_issued,
	COUNT(r.return_id) AS total_books_returned,
	SUM(b.rental_price) AS total_revenue
FROM branch AS br
JOIN employees AS e ON br.branch_id = e.branch_id
JOIN issued_status AS i ON e.emp_id = i.issued_emp_id
JOIN return_status AS r ON i.issued_id = r.issued_id
JOIN books AS b ON b.isbn = i.issued_book_isbn
GROUP BY br.branch_id
ORDER BY 4 DESC;


-- Task 16: CTAS: Create a Table of Active Members.
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members
-- who have issued at least one book in the last 2 months.

CREATE TABLE active_members1 AS
SELECT m.*, ist.issued_date
FROM members AS m 
JOIN issued_status AS ist ON m.member_id = ist.issued_member_id
WHERE ist.issued_date >= CURRENT_DATE - INTERVAL '2 month';

SELECT *
FROM active_members1;

-- OR --

CREATE TABLE active_members2 AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL '2 month'
                    );

SELECT *
FROM active_members2;


-- Task 17: Find Employees with the Most Book Issues Processed. 
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

SELECT 
	e.emp_id,
	e.emp_name,
	COUNT(ist.issued_id) AS total_books_processed,
	b.branch_id
FROM employees AS e
JOIN branch AS b ON e.branch_id = b.branch_id
JOIN issued_status AS ist ON e.emp_id = ist.issued_emp_id
GROUP BY 1, 2, 4
ORDER BY 3 DESC
LIMIT 3;


-- Task 18: Identify Members Issuing High-Risk Books.
-- Write a query to identify members who have issued books more than twice with the status "damaged" 
-- in the books table. Display the member name, book title, and the number of times they've 
-- issued damaged books.

SELECT 
	m.member_id, 
	m.member_name, 
	ist.issued_book_name,
	COUNT(*)
FROM return_status AS rs
JOIN issued_status AS ist ON rs.issued_id = ist.issued_id
JOIN members AS m ON m.member_id = ist.issued_member_id
WHERE rs.book_quality = 'Damaged'
GROUP BY 1, 3
HAVING COUNT(*) > 2;


-- Project Ends --
