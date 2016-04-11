<<<<<<< HEAD
/*
** Check the value for even parity.
*/

int
even_parity( int value, int n_bits )
{
	int	parity = 0;

	/*
	** Count the number of 1-bits in the value.
	*/
	while( n_bits > 0 ){
		parity += value & 1;
		value >>= 1;
		n_bits -= 1;
	}

	/*
	** Return TRUE if the low order bit of the count is zero
	** (which means that there were an even number of 1's).
	*/
	return ( parity % 2 ) == 0;
}
=======
/*
** Check the value for even parity.
*/

int
even_parity( int value, int n_bits )
{
	int	parity = 0;

	/*
	** Count the number of 1-bits in the value.
	*/
	while( n_bits > 0 ){
		parity += value & 1;
		value >>= 1;
		n_bits -= 1;
	}

	/*
	** Return TRUE if the low order bit of the count is zero
	** (which means that there were an even number of 1's).
	*/
	return ( parity % 2 ) == 0;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
