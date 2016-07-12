#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/un.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>

#define SERVERPATH "/tmp/server"

int processConnect(int newsd,int sd)
{
	pid_t pid=fork();
	if(pid==-1)
	{
		perror("fork");
		exit(-1);

	}
	if(pid==0)
	{
		close(sd);
		char buf[100];
		int fd,ret;

		fd=open("/etc/passwd",O_RDONLY);
		if(fd==-1)
		{
			perror("open");
			exit(-1);

		}
		while(1)
		{
			ret=read(fd,buf,100);
			if(ret==-1)
			{
				perror("read");
				return -1;

			}
			if(ret==0)
			{
				break;

			}
			write(newsd,buf,ret);

		}
		close(newsd);
		close(fd);
		exit(0);

	}
	return 0;

}

int main(void)
{
	int sd,newsd,ret;
	struct sockaddr_un addr;
	socklen_t length;

	addr.sun_family=AF_UNIX;
	strncpy(addr.sun_path,SERVERPATH,108);
	length=sizeof(addr);

	sd=socket(AF_UNIX,SOCK_STREAM,0);
	if(sd==-1)
	{
		perror("socket");
		exit(-1);

	}

	unlink(SERVERPATH);

	ret = bind(sd,(struct sockaddr *)&addr,length);
	if(ret==-1)
	{
		perror("bind");
		exit(-1);

	}
	ret=listen(sd,10);
	if(ret==-1)
	{
		perror("listen");
		exit(-1);

	}
	while(1)
	{
		newsd=accept(sd,NULL,NULL);
		if(newsd==-1)
		{
			perror("accept");
			exit(-1);

		}
		ret=processConnect(newsd,sd);
		if(ret==-1)
		{
			close(sd);
			close(newsd);
			exit(-1);

		}
		close(newsd);

	}
	close(sd);
	exit(0);

}
