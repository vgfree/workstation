```c++
/* cJSON Types: */
#define cJSON_False 0
#define cJSON_True 1
#define cJSON_NULL 2
#define cJSON_Number 3
#define cJSON_String 4
#define cJSON_Array 5
#define cJSON_Object 6
#define cJSON_IsReference 256


/* The cJSON structure: */
typedef struct cJSON {
    struct cJSON *next,*prev;	/同一级的元素使用双向列表储存/
    struct cJSON *child;		/* 如果是个 object 或 array 的话，第一个儿子的指针 */
    int type;					/* value 的类型 */

    char *valuestring;			/* 如果这个 value 是 字符串 的话，字符串值 */
    int valueint;				/* 如果是数字的话，整数值 */
    double valuedouble;			/* 如果是数字的话，浮点数值 */
    char *string;				/* 如果是对象的 key-value 元素的话， key 值 */
} cJSON;
```
