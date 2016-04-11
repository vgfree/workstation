<<<<<<< HEAD
/*
** Count the number of nodes on a singly linked list.
*/

#include "singly_linked_list_node.h"
#include <stdio.h>

int
sll_count_nodes( struct NODE *first )
{
	int	count;

	for( count = 0; first != NULL; first = first->link ){
		count += 1;
	}

	return count;
}
=======
/*
** Count the number of nodes on a singly linked list.
*/

#include "singly_linked_list_node.h"
#include <stdio.h>

int
sll_count_nodes( struct NODE *first )
{
	int	count;

	for( count = 0; first != NULL; first = first->link ){
		count += 1;
	}

	return count;
}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
