#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
	int sockfd;
	int len;
	struct sockaddr_in address;
	int result;
	char ch = 'A';
	char buf[] = "GET / HTTP/1.1\n\n\n";
	char get[1024] = {0};
	// 创建sockfd
	sockfd = socket(AF_INET, SOCK_STREAM, 0);
	address.sin_family = AF_INET;
	address.sin_addr.s_addr = inet_addr("127.0.0.1");
	address.sin_port = htons(50329);
	len = sizeof(address);
	// 建立连接
	result = connect(sockfd, (struct sockaddr *)&address, len);

	if (result == -1)
	{
		perror("oops: client1");
		exit(1);
	}
	write(sockfd,buf, sizeof(buf));/*发送请求*/
	 read(sockfd,get, sizeof(get));/*接收返回数据*/
	// 向socket写数据
//	write(sockfd, &ch, 1);
	// 从socket读数据
//	read(sockfd, &ch, 1);
//	printf("char from server = %c\n", ch);
	printf("%s\n", get);
	close(sockfd);
	exit(0);
}
