<<<<<<< HEAD
	/*
	** Add the new node to the list.
	*/
	if( next != NULL ){
		/*
		** Case 1 or 2: not at end of the list 
		*/
		newnode->fwd = next;
		if( this != rootp ){	   /* Case 1: not at front */
			this->fwd = newnode;
			newnode->bwd = this;
		}
		else {			   /* Case 2: at front */
			rootp->fwd = newnode;
			newnode->bwd = NULL;
		}
		next->bwd = newnode;
	}
	else {
		/*
		** Case 3 or 4: at end of the list
		*/
		newnode->fwd = NULL;
		if( this != rootp ){	   /* Case 3: not at front */
			this->fwd = newnode;
			newnode->bwd = this;
		}
		else {			   /* Case 4: at front */
			rootp->fwd = newnode;
			newnode->bwd = NULL;
		}
		rootp->bwd = newnode;
	}
=======
	/*
	** Add the new node to the list.
	*/
	if( next != NULL ){
		/*
		** Case 1 or 2: not at end of the list 
		*/
		newnode->fwd = next;
		if( this != rootp ){	   /* Case 1: not at front */
			this->fwd = newnode;
			newnode->bwd = this;
		}
		else {			   /* Case 2: at front */
			rootp->fwd = newnode;
			newnode->bwd = NULL;
		}
		next->bwd = newnode;
	}
	else {
		/*
		** Case 3 or 4: at end of the list
		*/
		newnode->fwd = NULL;
		if( this != rootp ){	   /* Case 3: not at front */
			this->fwd = newnode;
			newnode->bwd = this;
		}
		else {			   /* Case 4: at front */
			rootp->fwd = newnode;
			newnode->bwd = NULL;
		}
		rootp->bwd = newnode;
	}
>>>>>>> 5e38fbb866ef7610a3092d1af5d0c32556a87ed1
