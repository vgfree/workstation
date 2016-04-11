<<<<<<< HEAD
	/*
	** Add the new node to the list.
	*/
	newnode->fwd = next;
	this->fwd = newnode;
	newnode->bwd = this != rootp ? this : NULL;
	( next != NULL ? next : rootp )->bwd = newnode;
=======
	/*
	** Add the new node to the list.
	*/
	newnode->fwd = next;
	this->fwd = newnode;
	newnode->bwd = this != rootp ? this : NULL;
	( next != NULL ? next : rootp )->bwd = newnode;
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
