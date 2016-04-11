<<<<<<< HEAD
/*
** Process each of the files whose names appear on the command line.
*/
#include <stdlib.h>
#include <stdio.h>

int
main( int ac, char **av )
{
	int	exit_status = EXIT_SUCCESS;
	FILE	*input;

	/*
	** While there are more names ...
	*/
	while( *++av != NULL ){
		/*
		** Try opening the file.
		*/
		input = fopen( *av, "r" );
		if( input == NULL ){
			perror( *av );
			exit_status = EXIT_FAILURE;
			continue;
		}

		/*
		** Process the file here ...
		*/

		/*
		** Close the file (don't expect any errors here).
		*/
		if( fclose( input ) != 0 ){
			perror( "fclose" );
			exit( EXIT_FAILURE );
		}
	}

	return exit_status;
}
=======
/*
** Process each of the files whose names appear on the command line.
*/
#include <stdlib.h>
#include <stdio.h>

int
main( int ac, char **av )
{
	int	exit_status = EXIT_SUCCESS;
	FILE	*input;

	/*
	** While there are more names ...
	*/
	while( *++av != NULL ){
		/*
		** Try opening the file.
		*/
		input = fopen( *av, "r" );
		if( input == NULL ){
			perror( *av );
			exit_status = EXIT_FAILURE;
			continue;
		}

		/*
		** Process the file here ...
		*/

		/*
		** Close the file (don't expect any errors here).
		*/
		if( fclose( input ) != 0 ){
			perror( "fclose" );
			exit( EXIT_FAILURE );
		}
	}

	return exit_status;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
