<<<<<<< HEAD
/*
** This program reads input lines from the standard input and prints
** each input line, followed by just some portions of the lines, to
** the standard output.
**
** The first input is a list of column numbers, which ends with a
** negative number.  The column numbers are paired and specify
** ranges of columns from the input line that are to be printed.
** For example, 0 3 10 12 -1 indicates that only columns 0 through 3
** and columns 10 through 12 will be printed.
*/
// 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define	MAX_COLS	20	/* max # of columns to process */
#define	MAX_INPUT	1000	/* max len of input & output lines */

int	read_column_numbers( int columns[], int max );
void	rearrange( char *output, char const *input,
	    int n_columns, int const columns[] );

int
main( void )
{
	int	n_columns;		/* # of columns to process */
	int	columns[MAX_COLS];	/* 需要最大处理行数 */
	char	input[MAX_INPUT];	/* 容纳输入行的数组 */
	char	output[MAX_INPUT];	/* 容纳输出行的数组 */

	/*
	** Read the list of column numbers
	*/
	n_columns = read_column_numbers( columns, MAX_COLS );

	/*
	** Read, process and print the remaining lines of input.
	*/
        // gets(input); 从终端读取字符，并存入数组input中,gets可接受空格，以回车结束
	while( gets( input ) != NULL ){
		printf( "Original input : %s\n", input );
		rearrange( output, input, n_columns, columns );
		printf( "Rearranged line: %s\n", output );
	}

	return EXIT_SUCCESS;
}

/*
** Read the list of column numbers, ignoring any beyond the specified
** maximum.
*/
// 从终端读取成对数字，并填充入数组columns[],返回实际读取到的个数
int
read_column_numbers( int columns[], int max )
{
	int	num = 0;
	int	ch;

	/*
	** Get the numbers, stopping at eof or when a number is < 0.
	*/
        // scanf("%d", &columns[num]); 从终端格式化输入带符号的十进制整数，并将值存放到数组columns中,以空格、回车、tab键为结束
        // 最多允许输入20个数字，且数字均大于0，当输入小于0时，循环结束
	while( num < max && scanf( "%d", &columns[num] ) == 1
	    && columns[num] >= 0 )
		num += 1;

	/*
	** Make sure we have an even number of inputs, as they are
	** supposed to be paired.
	*/
        // 确保数字是成对的
	if( num % 2 != 0 ){
		puts( "Last column number is not paired." );
		exit( EXIT_FAILURE );
	}

	/*
	** Discard the rest of the line that contained the final
	** number.
	*/
        // getchar();从输入缓冲区读取一个字符,因为scanf();在读取输入时会在缓冲区留下一个字符'\n'(回车导致的)
	while( (ch = getchar()) != EOF && ch != '\n' )
		;

	return num;
}

/*
** Process a line of input by concatenating the characters from
** the indicated columns.  The output line is then NUL terminated.
*/
void
rearrange( char *output, char const *input,
    int n_columns, int const columns[] )
{
	int	col;		/* subscript for columns array */
	int	output_col;	/* output column counter */
	int	len;		/* length of input line */

	len = strlen( input );  // 获取输入数组的实际长度
	output_col = 0;

	/*
	** Process each pair of column numbers.
	*/
        // 从下标0开始，每次跳2处理
	for( col = 0; col < n_columns; col += 2 ){
		int	nchars = columns[col + 1] - columns[col] + 1;   // 计算要处理的字节

		/*
		** If the input line isn't this long or the output
		** array is full, we're done.
		*/
                // 要处理的长度 > 实际长度 或 输出数组长度已满 就跳出循环
		if( columns[col] >= len ||
		    output_col == MAX_INPUT - 1 )
			break;

		/*
		** If there isn't room in the output array, only copy
		** what will fit.
		*/
                // output数组没有足够的空间，就只取即将填满output的长度数字
		if( output_col + nchars > MAX_INPUT - 1 )
			nchars = MAX_INPUT - output_col - 1;

		/*
		** Copy the relevant data.
		*/
                // 从input数组中复制数据到output数组中，每次复制nchars个，复制的内容从input+columns[col]开始，output中每次写入从output+output_col处开始
		strncpy( output + output_col, input + columns[col],
		    nchars );
		output_col += nchars;
	}

	output[output_col] = '\0';
}
=======
/*
** This program reads input lines from the standard input and prints
** each input line, followed by just some portions of the lines, to
** the standard output.
**
** The first input is a list of column numbers, which ends with a
** negative number.  The column numbers are paired and specify
** ranges of columns from the input line that are to be printed.
** For example, 0 3 10 12 -1 indicates that only columns 0 through 3
** and columns 10 through 12 will be printed.
*/
// 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define	MAX_COLS	20	/* max # of columns to process */
#define	MAX_INPUT	1000	/* max len of input & output lines */

int	read_column_numbers( int columns[], int max );
void	rearrange( char *output, char const *input,
	    int n_columns, int const columns[] );

int
main( void )
{
	int	n_columns;		/* # of columns to process */
	int	columns[MAX_COLS];	/* 需要最大处理行数 */
	char	input[MAX_INPUT];	/* 容纳输入行的数组 */
	char	output[MAX_INPUT];	/* 容纳输出行的数组 */

	/*
	** Read the list of column numbers
	*/
	n_columns = read_column_numbers( columns, MAX_COLS );

	/*
	** Read, process and print the remaining lines of input.
	*/
        // gets(input); 从终端读取字符，并存入数组input中,gets可接受空格，以回车结束
	while( gets( input ) != NULL ){
		printf( "Original input : %s\n", input );
		rearrange( output, input, n_columns, columns );
		printf( "Rearranged line: %s\n", output );
	}

	return EXIT_SUCCESS;
}

/*
** Read the list of column numbers, ignoring any beyond the specified
** maximum.
*/
// 从终端读取成对数字，并填充入数组columns[],返回实际读取到的个数
int
read_column_numbers( int columns[], int max )
{
	int	num = 0;
	int	ch;

	/*
	** Get the numbers, stopping at eof or when a number is < 0.
	*/
        // scanf("%d", &columns[num]); 从终端格式化输入带符号的十进制整数，并将值存放到数组columns中,以空格、回车、tab键为结束
        // 最多允许输入20个数字，且数字均大于0，当输入小于0时，循环结束
	while( num < max && scanf( "%d", &columns[num] ) == 1
	    && columns[num] >= 0 )
		num += 1;

	/*
	** Make sure we have an even number of inputs, as they are
	** supposed to be paired.
	*/
        // 确保数字是成对的
	if( num % 2 != 0 ){
		puts( "Last column number is not paired." );
		exit( EXIT_FAILURE );
	}

	/*
	** Discard the rest of the line that contained the final
	** number.
	*/
        // getchar();从输入缓冲区读取一个字符,因为scanf();在读取输入时会在缓冲区留下一个字符'\n'(回车导致的)
	while( (ch = getchar()) != EOF && ch != '\n' )
		;

	return num;
}

/*
** Process a line of input by concatenating the characters from
** the indicated columns.  The output line is then NUL terminated.
*/
void
rearrange( char *output, char const *input,
    int n_columns, int const columns[] )
{
	int	col;		/* subscript for columns array */
	int	output_col;	/* output column counter */
	int	len;		/* length of input line */

	len = strlen( input );  // 获取输入数组的实际长度
	output_col = 0;

	/*
	** Process each pair of column numbers.
	*/
        // 从下标0开始，每次跳2处理
	for( col = 0; col < n_columns; col += 2 ){
		int	nchars = columns[col + 1] - columns[col] + 1;   // 计算要处理的字节

		/*
		** If the input line isn't this long or the output
		** array is full, we're done.
		*/
                // 要处理的长度 > 实际长度 或 输出数组长度已满 就跳出循环
		if( columns[col] >= len ||
		    output_col == MAX_INPUT - 1 )
			break;

		/*
		** If there isn't room in the output array, only copy
		** what will fit.
		*/
                // output数组没有足够的空间，就只取即将填满output的长度数字
		if( output_col + nchars > MAX_INPUT - 1 )
			nchars = MAX_INPUT - output_col - 1;

		/*
		** Copy the relevant data.
		*/
                // 从input数组中复制数据到output数组中，每次复制nchars个，复制的内容从input+columns[col]开始，output中每次写入从output+output_col处开始
		strncpy( output + output_col, input + columns[col],
		    nchars );
		output_col += nchars;
	}

	output[output_col] = '\0';
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
