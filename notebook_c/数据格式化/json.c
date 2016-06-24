// gcc -o json json.c -I./ ./libjson-c.a

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>

#include "/home/shana/reycle/supex/lib/json-c/json.h"
//#include "json.h"
//#include "parse_flags.h"

char json_str[256];

char *get_json()
{
	json_object *my_object;
	my_object = json_object_new_object();
	json_object_object_add(my_object, "abc", json_object_new_int(12));
	json_object_object_add(my_object, "foo", json_object_new_string("bar"));
	json_object_object_add(my_object, "bool0", json_object_new_boolean(0));
	json_object_object_add(my_object, "bool1", json_object_new_boolean(1));
	json_object_object_add(my_object, "baz", json_object_new_string("bang"));

	printf("my_object=\n");
	json_object_object_foreach(my_object, key, val)
	{
		printf("\t%s: %s\n", key, json_object_to_json_string(val));
	}
	printf("my_object.to_string()=%s\n", json_object_to_json_string(my_object));

	strcpy(json_str, json_object_to_json_string(my_object));

	printf("json_str = %s", json_str);

	return json_str;
}

int main()
{
	/*
	json_object *my_object;
	my_object = json_object_new_object();
	json_object_object_add(my_object, "abc", json_object_new_int(12));
	json_object_object_add(my_object, "foo", json_object_new_string("bar"));
	json_object_object_add(my_object, "bool0", json_object_new_boolean(0));
	json_object_object_add(my_object, "bool1", json_object_new_boolean(1));
	json_object_object_add(my_object, "baz", json_object_new_string("bang"));

	printf("my_object=\n");
	json_object_object_foreach(my_object, key, val)
	{
		printf("\t%s: %s\n", key, json_object_to_json_string(val));
	}
	printf("my_object.to_string()=%s\n", json_object_to_json_string(my_object));

	char json_str[256];
	strcpy(json_str, json_object_to_json_string(my_object));

	printf("json_str = %s", json_str);

	json_object_put(my_object);
	*/

	printf("%s\n", get_json());

	return 0;
}
