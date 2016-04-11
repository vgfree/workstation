<<<<<<< HEAD
/*
** Structure for long distance telephone billing record.
*/
enum	PN_TYPE	{ CALLED, CALLING, BILLED };

struct LONG_DISTANCE_BILL {
	short	month;
	short	day;
	short	year;
	int	time;
	struct	PHONE_NUMBER	numbers[3];
};
=======
/*
** Structure for long distance telephone billing record.
*/
enum	PN_TYPE	{ CALLED, CALLING, BILLED };

struct LONG_DISTANCE_BILL {
	short	month;
	short	day;
	short	year;
	int	time;
	struct	PHONE_NUMBER	numbers[3];
};
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
