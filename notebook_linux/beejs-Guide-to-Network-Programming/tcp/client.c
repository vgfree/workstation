#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/un.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <string.h>

#define SERVERPATH "/tmp/server"

int main(void)
{
	int sd,newsd,ret;
	struct sockaddr_un addr;
	socklen_t length;
	char buf[100];

	addr.sun_family=AF_UNIX;
	strncpy(addr.sun_path,SERVERPATH,108);
	length=sizeof(addr);

	sd=socket(AF_UNIX,SOCK_STREAM,0);
	if(sd==-1)
	{
		perror("socket");
		exit(-1);

	}
	ret = connect(sd,(struct sockaddr *)&addr,length);
	if(ret==-1)
	{
		perror("connect");
		exit(-1);

	}

	while(1)
	{
		ret=read(sd,buf,100);
		if(ret==-1)
		{
			perror("read");
			exit(-1);

		}
		if(ret==0)
		{
			break;

		}
		write(1,buf,ret);

	}
	close(sd);
	exit(0);

}
