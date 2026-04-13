
class Transaction;
{   // Holds information about a single transaction.

    public:
	Transaction();
		// Default parameterless constructor.

	Transaction(long number,
	    time_t time,
	    date_t date,
	    char* description,
	    double amount);
		// Parameter constructor;

	Transaction(const Transaction& original);
		// Copy constructor.

    private:
	long m_number;
	time_t m_time;
	date_t m_date;
	char m_description[31];
	double m_amount;
};  // class Transaction


class Account;
{   // Keeps track of transactions for one account.

    public:
	Account();
		// Default parameterless constructor.

	Account(char* name,
		char* address,
		char* csz,
		char* phone);
		// Parameter constructor;

	Account(const Account& original);
		// Copy constructor.

	double getBalance(t_date asOf = );
		// Calculates the balance as of the date indicated.
		// DEFAULT PARAMETER = today's date.

	int addTrans(const Transaction& newTrans) const;
		// Enters a transaction for the account;

	int voidTrans(long number);
		// Voids the indicated transaction.

	Transaction& getTrans(long number);
		// Retrieves the indicated transaction.

	Transaction& getFirst();
		// Retrieves the first transaction on date.
		// DEFAULT PARAMETER = first transaction.

	Transaction& getLast();
		// Retrieves the last transaction on date.
		// DEFAULT PARAMETER = last transaction.

	Transaction& getNext();
		// Retrieves the next transaction.

	Transaction& getPrev();
		// Retrieves the previous transaction.

    private:
	char m_name[31];
	char m_address[31];
	char m_csz[31];
	char m_phone[21];
};  // class Transaction
