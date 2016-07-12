/* J. David's webserver */
/* This is a simple webserver.
 * Created November 1999 by J. David Blackstone.
 * CSE 4344 (Network concepts), Prof. Zeigler
 * University of Texas at Arlington
 */
/* This program compiles for Sparc Solaris 2.6.
 * To compile for Linux:
 *  1) Comment out the #include <pthread.h> line.
 *  2) Comment out the line that defines the variable newthread.
 *  3) Comment out the two lines that run pthread_create().
 *  4) Uncomment the line that runs accept_request().
 *  5) Remove -lsocket from the Makefile.
 */
#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <ctype.h>
#include <strings.h>
#include <string.h>
#include <sys/stat.h>
#include <pthread.h>
#include <sys/wait.h>
#include <stdlib.h>

#define ISspace(x) isspace((int)(x))

#define SERVER_STRING "Server: jdbhttpd/0.1.0\r\n"

//void accept_request(int);
void *accept_request(void *);
void bad_request(int);
void cat(int, FILE *);
void cannot_execute(int);
void error_die(const char *);
void execute_cgi(int, const char *, const char *, const char *);
int get_line(int, char *, int);
void headers(int, const char *);
void not_found(int);
void serve_file(int, const char *);
int startup(u_short *);
void unimplemented(int);

/**********************************************************************/
/* A request has caused a call to accept() on the server port to
 * return.  Process the request appropriately.
 * Parameters: the socket connected to the client */
/**********************************************************************/
void *accept_request(void *tclient)
{
	// client 是socket
	int client = *(int *)tclient;
	char buf[1024];
	int numchars;
	char method[255];
	char url[255];
	char path[512];
	size_t i, j;
	struct stat st;
	int cgi = 0;      /* becomes true if server decides this is a CGI
			   * program */
	char *query_string = NULL;
	// 得到请求的第一行
	numchars = get_line(client, buf, sizeof(buf));
	i = 0;
	j = 0;
	// 第一行buf 以space来切割 
	// 示例: GET /search?hl=zh-CN&source=hp&q=domety&aq=f&oq= HTTP/1.1
	// 获取请求方法
	while (!ISspace(buf[j]) && (i < sizeof(method) - 1))
	{
		method[i] = buf[j];
		i++; j++;
	}
	method[i] = '\0';
	// 忽略大小写比较字符串
	if (strcasecmp(method, "GET") && strcasecmp(method, "POST"))
	{
		// 不是POST/GET 报错 501
		unimplemented(client);
		return NULL;
	}

	if (strcasecmp(method, "POST") == 0)
		cgi = 1;

	i = 0;
	// 继续排除space
	while (ISspace(buf[j]) && (j < sizeof(buf)))
		j++;
	// 获取url 地址, url长度限制为<255
	// /search?hl=zh-CN&source=hp&q=domety&aq=f&oq=
	while (!ISspace(buf[j]) && (i < sizeof(url) - 1) && (j < sizeof(buf)))
	{
		// 存储url
		url[i] = buf[j];
		i++; j++;
	}
	url[i] = '\0';

	// 处理GET请求
	if (strcasecmp(method, "GET") == 0)
	{
		query_string = url;
		while ((*query_string != '?') && (*query_string != '\0'))
			query_string++;
		// GET 请求方法特点是 ? 为URL的结束和请求参数的开始
		if (*query_string == '?')
		{
			// 开启CGI
			cgi = 1;
			// query_string 到此截至
			*query_string = '\0';
			query_string++;
		}
	}
	// 此时url = '/search', 在此组装出资源的相对路径
	sprintf(path, "htdocs%s", url);
	// 将"index.html" 拼接到path(默认情况下为index.html)
	if (path[strlen(path) - 1] == '/')
		strcat(path, "index.html");
	// 通过filename 获取文件信息, 并保存在st的结构体中
	if (stat(path, &st) == -1) {
		// 丢弃所有先前获取的headers数据
		while ((numchars > 0) && strcmp("\n", buf))  /* read & discard headers */
			numchars = get_line(client, buf, sizeof(buf));
		// 向客户端报错 404
		not_found(client);
	}
	else
	{
		// 通过掩码 S_IFMT 判断文件类型
		if ((st.st_mode & S_IFMT) == S_IFDIR)
			strcat(path, "/index.html");
		// 判断执行权限 USER GROUP OTHER
		if ((st.st_mode & S_IXUSR) ||
				(st.st_mode & S_IXGRP) ||
				(st.st_mode & S_IXOTH)    )
			cgi = 1;
		// 不是cgi, 直接把服务器文件返回, 否则执行cgi
		if (!cgi)
			serve_file(client, path);
		else
			execute_cgi(client, path, method, query_string);
	}

	close(client);
	return NULL;
}

/**********************************************************************/
/* Inform the client that a request it has made has a problem.
 * Parameters: client socket */
/**********************************************************************/
void bad_request(int client)
{
	char buf[1024];

	sprintf(buf, "HTTP/1.0 400 BAD REQUEST\r\n");
	send(client, buf, sizeof(buf), 0);
	sprintf(buf, "Content-type: text/html\r\n");
	send(client, buf, sizeof(buf), 0);
	sprintf(buf, "\r\n");
	send(client, buf, sizeof(buf), 0);
	sprintf(buf, "<P>Your browser sent a bad request, ");
	send(client, buf, sizeof(buf), 0);
	sprintf(buf, "such as a POST without a Content-Length.\r\n");
	send(client, buf, sizeof(buf), 0);
}

/**********************************************************************/
/* Put the entire contents of a file out on a socket.  This function
 * is named after the UNIX "cat" command, because it might have been
 * easier just to do something like pipe, fork, and exec("cat").
 * Parameters: the client socket descriptor
 *             FILE pointer for the file to cat */
/**********************************************************************/
void cat(int client, FILE *resource)
{
	char buf[1024];
	// 读取数据
	fgets(buf, sizeof(buf), resource);
	while (!feof(resource))
	{
		// 向客户端发送数据
		send(client, buf, strlen(buf), 0);
		fgets(buf, sizeof(buf), resource);
	}
}

/**********************************************************************/
/* Inform the client that a CGI script could not be executed.
 * Parameter: the client socket descriptor. */
/**********************************************************************/
void cannot_execute(int client)
{
	char buf[1024];

	sprintf(buf, "HTTP/1.0 500 Internal Server Error\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "Content-type: text/html\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "<P>Error prohibited CGI execution.\r\n");
	send(client, buf, strlen(buf), 0);
}

/**********************************************************************/
/* Print out an error message with perror() (for system errors; based
 * on value of errno, which indicates system call errors) and exit the
 * program indicating an error. */
/**********************************************************************/
void error_die(const char *sc)
{
	perror(sc);
	exit(1);
}

/**********************************************************************/
/* Execute a CGI script.  Will need to set environment variables as
 * appropriate.
 * Parameters: client socket descriptor
 *             path to the CGI script */
/**********************************************************************/
void execute_cgi(int client, const char *path,
		const char *method, const char *query_string)
{
	char buf[1024];
	// 在父子进程中需要使用不同的stdin 和 stdout 所以需要将它们分开
	int cgi_output[2];
	int cgi_input[2];
	pid_t pid;
	int status;
	int i;
	char c;
	int numchars = 1;
	int content_length = -1;

	buf[0] = 'A'; buf[1] = '\0';
	if (strcasecmp(method, "GET") == 0)
		// 读取 header 并丢弃
		while ((numchars > 0) && strcmp("\n", buf))  /* read & discard headers */
			numchars = get_line(client, buf, sizeof(buf));
	else    /* POST */
	{
		// 读取第二行, Content-Length
		numchars = get_line(client, buf, sizeof(buf));
		while ((numchars > 0) && strcmp("\n", buf))
		{
			buf[15] = '\0';
			if (strcasecmp(buf, "Content-Length:") == 0)
				content_length = atoi(&(buf[16]));
			numchars = get_line(client, buf, sizeof(buf));
		}
		// 没有content_length 时报错
		if (content_length == -1) {
			// 报错 400
			bad_request(client);
			return;
		}
	}

	// 发送返回 header
	sprintf(buf, "HTTP/1.0 200 OK\r\n");
	send(client, buf, strlen(buf), 0);
	// cgi_output[0] 读 cgi_output[1] 写
	if (pipe(cgi_output) < 0) {
		// 报错 500
		cannot_execute(client);
		return;
	}
	if (pipe(cgi_input) < 0) {
		cannot_execute(client);
		return;
	}

	if ( (pid = fork()) < 0 ) {
		cannot_execute(client);
		return;
	}
	if (pid == 0)  /* child: CGI script */
	{
		char meth_env[255];
		char query_env[255];
		char length_env[255];

		// stdout 现在由 cgi_output[1] 代替
		dup2(cgi_output[1], 1);
		// stdin 现在由 cgi_input[0] 代替
		dup2(cgi_input[0], 0);
		close(cgi_output[0]);
		close(cgi_input[1]);

		// 设置新的进程环境变量
		sprintf(meth_env, "REQUEST_METHOD=%s", method);
		putenv(meth_env);
		if (strcasecmp(method, "GET") == 0) {
			sprintf(query_env, "QUERY_STRING=%s", query_string);
			putenv(query_env);
		}
		else {   /* POST */
			sprintf(length_env, "CONTENT_LENGTH=%d", content_length);
			putenv(length_env);
		}
		// 运行cgi, 执行path文件路径, 传参path, 以NULL为结束
		execl(path, path, NULL);
		exit(0);

	} else {    /* parent */
		close(cgi_output[1]);
		close(cgi_input[0]);
		if (strcasecmp(method, "POST") == 0)
			// 读取post body
			for (i = 0; i < content_length; i++) {
				recv(client, &c, 1, 0);
				write(cgi_input[1], &c, 1);
			}
		// 读取数据发送
		while (read(cgi_output[0], &c, 1) > 0)
			send(client, &c, 1, 0);

		close(cgi_output[0]);
		close(cgi_input[1]);
		// 等待子进程
		waitpid(pid, &status, 0);
	}
}

/**********************************************************************/
/* Get a line from a socket, whether the line ends in a newline,
 * carriage return, or a CRLF combination.  Terminates the string read
 * with a null character.  If no newline indicator is found before the
 * end of the buffer, the string is terminated with a null.  If any of
 * the above three line terminators is read, the last character of the
 * string will be a linefeed and the string will be terminated with a
 * null character.
 * Parameters: the socket descriptor
 *             the buffer to save the data in
 *             the size of the buffer
 * Returns: the number of bytes stored (excluding null) */
/**********************************************************************/
int get_line(int sock, char *buf, int size)
{
	int i = 0;
	char c = '\0';
	int n;

	// 逐个字符的接收客户端数据, 同时统计接收到的字符个数,
	// 最后在buf最后加'\0'
	// 中止条件是 \n 换行符
	while ((i < size - 1) && (c != '\n'))
	{
		// recv(接收端套接字, 存放数据的缓冲区, buf长度, 0)
		n = recv(sock, &c, 1, 0);
		/* DEBUG printf("%02X\n", c); */
		if (n > 0)
		{
			// 受到 \r 则继续接收数据, 因为换行符肯呢个是\r\n
			if (c == '\r')
			{
				// 将套接字接收队列中可读数据copy到buf, 即预读
				n = recv(sock, &c, 1, MSG_PEEK);
				/* DEBUG printf("%02X\n", c); */
				// 如果预读出的数据是换行符, 则将其吸收掉
				if ((n > 0) && (c == '\n'))
					recv(sock, &c, 1, 0);
				else
					c = '\n';
			}
			// 数据存储到缓冲区
			buf[i] = c;
			i++;
		}
		else
			c = '\n';
	}
	buf[i] = '\0';
	// 返回buf数组大小
	return(i);
}

/**********************************************************************/
/* Return the informational HTTP headers about a file. */
/* Parameters: the socket to print the headers on
 *             the name of the file */
/**********************************************************************/
void headers(int client, const char *filename)
{
	char buf[1024];
	(void)filename;  /* could use filename to determine file type */

	strcpy(buf, "HTTP/1.0 200 OK\r\n");
	send(client, buf, strlen(buf), 0);
	strcpy(buf, SERVER_STRING);
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "Content-Type: text/html\r\n");
	send(client, buf, strlen(buf), 0);
	strcpy(buf, "\r\n");
	send(client, buf, strlen(buf), 0);
}

/**********************************************************************/
/* Give a client a 404 not found status message. */
/**********************************************************************/
void not_found(int client)
{
	char buf[1024];

	sprintf(buf, "HTTP/1.0 404 NOT FOUND\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, SERVER_STRING);
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "Content-Type: text/html\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "<HTML><TITLE>Not Found</TITLE>\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "<BODY><P>The server could not fulfill\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "your request because the resource specified\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "is unavailable or nonexistent.\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "</BODY></HTML>\r\n");
	send(client, buf, strlen(buf), 0);
}

/**********************************************************************/
/* Send a regular file to the client.  Use headers, and report
 * errors to client if they occur.
 * Parameters: a pointer to a file structure produced from the socket
 *              file descriptor
 *             the name of the file to serve */
/**********************************************************************/
void serve_file(int client, const char *filename)
{
	FILE *resource = NULL;
	int numchars = 1;
	char buf[1024];

	// 读取并丢弃header
	buf[0] = 'A';
	buf[1] = '\0';
	while ((numchars > 0) && strcmp("\n", buf))  /* read & discard headers */
		numchars = get_line(client, buf, sizeof(buf));

	// 打开server 文件
	resource = fopen(filename, "r");
	if (resource == NULL)
		not_found(client);
	else
	{
		// 组装返回 headers
		headers(client, filename);
		// 复制文件
		cat(client, resource);
	}
	fclose(resource);
}

/**********************************************************************/
/* This function starts the process of listening for web connections
 * on a specified port.  If the port is 0, then dynamically allocate a
 * port and modify the original port variable to reflect the actual
 * port.
 * Parameters: pointer to variable containing the port to connect on
 * Returns: the socket */
/**********************************************************************/
int startup(u_short *port)
{
	int httpd = 0;
	struct sockaddr_in name;

	// 创建socket, ipv4 流式套接字
	httpd = socket(PF_INET, SOCK_STREAM, 0);
	if (httpd == -1)
		error_die("socket");
	memset(&name, 0, sizeof(name));
	// ipv4 网络套接字
	name.sin_family = AF_INET;
	// 整形变量 主机字节s->网络字节序
	name.sin_port = htons(*port);
	// 将任意ip地址转换为网络字节序
	name.sin_addr.s_addr = htonl(INADDR_ANY);

	// socket绑定,
	// 为socket关联一个地址,发送到这个地址的数据可以通过该套接字读取与使用
	if (bind(httpd, (struct sockaddr *)&name, sizeof(name)) < 0)
		error_die("bind");
	// 如果port为0, 则随机分配一个端口
	if (*port == 0)  /* if dynamically allocating a port */
	{
		socklen_t namelen = sizeof(name);
		if (getsockname(httpd, (struct sockaddr *)&name, &namelen) == -1)
			error_die("getsockname");
		// 网络字节序转主机字节序
		*port = ntohs(name.sin_port);
	}
	// 套接字监听
	if (listen(httpd, 5) < 0)
		error_die("listen");
	return(httpd);
}

/**********************************************************************/
/* Inform the client that the requested web method has not been
 * implemented.
 * Parameter: the client socket */
/**********************************************************************/
void unimplemented(int client)
{
	char buf[1024];

	sprintf(buf, "HTTP/1.0 501 Method Not Implemented\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, SERVER_STRING);
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "Content-Type: text/html\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "<HTML><HEAD><TITLE>Method Not Implemented\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "</TITLE></HEAD>\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "<BODY><P>HTTP request method not supported.\r\n");
	send(client, buf, strlen(buf), 0);
	sprintf(buf, "</BODY></HTML>\r\n");
	send(client, buf, strlen(buf), 0);
}

/**********************************************************************/

int main(void)
{
	int server_sock = -1;
	u_short port = 0;
	int client_sock = -1;
	struct sockaddr_in client_name;
	socklen_t client_name_len = sizeof(client_name);
	pthread_t newthread;

	// 在对应端口建立httpd服务, 返回套接字
	server_sock = startup(&port);
	printf("httpd running on port %d\n", port);

	while (1)
	{
		// 通过接收客户端请求, 返回新的socket
		client_sock = accept(server_sock,
				(struct sockaddr *)&client_name,
				&client_name_len);
		if (client_sock == -1)
			error_die("accept");

		// 创建线程并调用回调函数accept_request 传参client_sock 进行处理
		if (pthread_create(&newthread, NULL, accept_request,
					(void *)&client_sock) != 0)
			perror("pthread_create");
	}

	close(server_sock);

	return(0);
}
