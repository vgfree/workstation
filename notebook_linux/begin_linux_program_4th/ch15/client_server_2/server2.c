#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

int main()
{
	int server_sockfd, client_sockfd;
	int server_len, client_len;
	struct sockaddr_in server_address;
	struct sockaddr_in client_address;

	server_sockfd = socket(AF_INET, SOCK_STREAM, 0);

	server_address.sin_family = AF_INET;
	server_address.sin_addr.s_addr = inet_addr("127.0.0.1");
	server_address.sin_port = 8080;
	server_len = sizeof(server_address);

	bind(server_sockfd, (struct sockaddr *)&server_address, server_len);

	listen(server_sockfd, 5);

	//	char *msg = "HTTP/1.1 200 OK\r\nContent-Length:107\r\nContent-Type:text/html\r\n\r\n<html><head></head><body>hello</body></html>";

	char *msg = "HTTP/1.1 200 OK \r\n" \
		     "Content-Type: text/html\r\n" \
		     "Content-Length: 24\r\n" \
		     "\r\n" \
		     "<h1>Hello World!</h1>";

	while (1) {
		char *ch[2048];
		client_len = sizeof(client_address);
		client_sockfd = accept(server_sockfd, (struct sockaddr *)&client_address, &client_len);
		read(client_sockfd, &ch, 2048);
		printf("ch = %s\n", &ch);
		printf("%s, len = %d\n", msg, strlen(msg));
		write(client_sockfd, msg, strlen(msg));
		close(client_sockfd);
	}
}
