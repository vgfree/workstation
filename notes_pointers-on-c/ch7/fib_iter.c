<<<<<<< HEAD
/*
** Compute the value of the n'th Fibonacci number, iteratively.
*/

long
fibonacci( int n )
{
	long	result;
	long	previous_result;
	long	next_older_result;

	result = previous_result = 1;

	while( n > 2 ){
		n -= 1;
		next_older_result = previous_result;
		previous_result = result;
		result = previous_result + next_older_result;
	}
	return result;
}
=======
/*
** Compute the value of the n'th Fibonacci number, iteratively.
*/

long
fibonacci( int n )
{
	long	result;
	long	previous_result;
	long	next_older_result;

	result = previous_result = 1;

	while( n > 2 ){
		n -= 1;
		next_older_result = previous_result;
		previous_result = result;
		result = previous_result + next_older_result;
	}
	return result;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
