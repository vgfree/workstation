### json
#### json 大致有3种结构: json对象, json数组, json对象和数组嵌套
1. json 对象	
 key-value , value 可以为 number, string , boolean	

 **number**	
 `{"max":100, "min":10};`	

 **string**	
 `{"name":"louis", "telephone":"sony"}`		

 **boolean**
 `{"success":false}` 输出为boolean fasle
 `{"success":"false"}` 输出为string false

2. json 数组
 `{"list":[1,2,3,4]}` 可通过jsonname.lists[i] 输出,长度为jsonname.lists.length

3. json嵌套
 嵌套:json对象中可以包括json数组,json数组中可包括json对象
 `{
	 "total":2,


 }`
 ```json
{
	"total":2,
	"row":[
		{
			"name":"shana",
			"age":13
		},
		{
			"name":"miku",
			"age":16
		}
	]
}
 ```

 tips: 最后一个参数后没有逗号

