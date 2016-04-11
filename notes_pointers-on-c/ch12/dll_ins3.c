<<<<<<< HEAD
	/*
	** Add the new node to the list.
	*/
	newnode->fwd = next;

	if( this != rootp ){
		this->fwd = newnode;
		newnode->bwd = this;
	}
	else {
		rootp->fwd = newnode;
		newnode->bwd = NULL;
	}
	if( next != NULL )
		next->bwd = newnode;
	else
		rootp->bwd = newnode;
=======
	/*
	** Add the new node to the list.
	*/
	newnode->fwd = next;

	if( this != rootp ){
		this->fwd = newnode;
		newnode->bwd = this;
	}
	else {
		rootp->fwd = newnode;
		newnode->bwd = NULL;
	}
	if( next != NULL )
		next->bwd = newnode;
	else
		rootp->bwd = newnode;
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
