CREATE PROCEDURE CheckOutBook
@BookID int,
@BorrowerID int,
@CheckoutDate DATE,
@DueDate DATE output,
@TransactionID int output
as
begin

declare @AvailableCopies int

--Check for the available books

Select @AvailableCopies=AvailableCopies
From books Where bookid=@BookID

IF @AvailableCopies> 0
Begin
	
	--Start the transaction
	Begin Transaction

	--Insert into transaction table
	Insert Into Transactions (BookID,BorrowerID,CheckoutDate)
	Values(@BookID,@BorrowerID,@CheckoutDate)

	set @TransactionID=SCOPE_IDENTITY()

	--update books table
	Update Books
	set AvailableCopies=AvailableCopies-1,
	status=Case 
		   When AvailableCopies-1=0 then 'Not Avilable' else 'Available' end
	where BookID=@BookID

	--update borrower table
	update Borrowers
	set NumBooksBorrowed=NumBooksBorrowed+1
	Where BorrowerID=@BorrowerID

	Commit Transaction

	Set @DueDate=DATEADD(week,2,@CheckoutDate)

end
Else
Begin
--Book is not available
RAISERROR('Book is not avialable for checkout',16,1)
end
end

--Stored procedure for returning book

CREATE PROCEDURE ReturnBook
@TransactionID int,
@ReturnDate date,
@LateFee money output
as
begin

	declare @BookID int,@BorrowedID int,@CheckOutDate date,@DueDate date

	-- Retrieve transaction details
	select @BookID=bookID,@BorrowedID=borrowerID,@CheckOutDate=CheckOutDate
	from Transactions Where TransactionID=@TransactionID

	-- Calculate due date (2 weeks from checkout date)

	set @DueDate=DATEADD(week,2,@CheckoutDate)

	-- Calculate late fee if the book is returned after the due date

	If @ReturnDate > @DueDate
	begin
		set @LateFee=DATEDIFF(day,@DueDate,@ReturnDate)*1.0
	end

	else
	begin
		
		set @LateFee=0
	end

	Begin Try
	-- Start the transaction
		Begin Transaction
	-- Update transaction table

		Update Transactions 
			Set ReturnDate=@ReturnDate,Latefee=@LateFee
			where TransactionID=@TransactionID
	-- Update books table

		Update Books
			Set AvailableCopies=AvailableCopies+1,
			Status='Available'
			Where BookID=@BookID
	-- Update borrower table

		Update Borrowers
			Set NumBooksBorrowed=NumBooksBorrowed-1
			where BorrowerID=@BorrowedID

		Commit transaction
	End Try
	Begin Catch

		Rollback Transaction
		Raiserror('An error occurred during the return process.', 16, 1)

	End Catch
end


Declare @Duedate Date, @TransactionID INT
execute CheckOutBook 3,2,'2024-07-31',@Duedate out,@TransactionID OUT
Select @DueDate,@TransactionID

--Return book

Declare @LateFee MONEY;
Execute ReturnBook 1, '2024-08-15', @LateFee OUT;
Select @LateFee;