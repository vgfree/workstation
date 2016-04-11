### tokencode 获取
 curl http://192.168.71.55/config?kernelver=3_3_0&verno=drivereyes_V151227_1.0_P3_1.0.2&imsi=311637930955458&mod=SG900&imei=311637930955458&androidver=4_4_2&modelver=CV5021CBDL7FG_0022&basebandver=M6290A2_408_WM930_2___Nov_22_2013_07_44_17__EC78_&buildver=CV5021CBDL7FG_0022_20151209

### mysql 操作
[root@c5-nginxlua nginx]# mysql -h 192.168.1.6 -u app_identify -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 83681
Server version: 5.5.27-log Source distribution

Copyright (c) 2000, 2013, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| coreIdentification |
+--------------------+
2 rows in set (0.01 sec)

mysql> use coreIdentification;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+------------------------------+
| Tables_in_coreIdentification |
+------------------------------+
| carMachineInfo               |
| devicePermissionInfo         |
| devicePermissionInfoHistory  |
| getImeiInfo                  |
| getImeiInfo_bak_20150331     |
| getImeiInfo_tmp              |
| imeiOrder                    |
| imei_table                   |
| mirrtalkHistory              |
| mirrtalkHistory_20151013     |
| mirrtalkHistory_bak_20150331 |
| mirrtalkHistory_tmp          |
| mirrtalkInfo                 |
| mirrtalkInfo_20151013        |
| mirrtalkInfo_del             |
| mirrtalkInfo_tmp             |
| modelInfo                    |
| simHistory                   |
| simHistory_tmp               |
| simInfo                      |
| simInfo_tmp                  |
| systemStatusType             |
+------------------------------+
22 rows in set (0.00 sec)

mysql> select * from mirrtalkInfo limit 10;
+----+----------------+------+-------+---------+--------+--------+------------+----------+------------+------------+---------+----------+
| id | imei           | mbid | model | factory | status | nCheck | endTime    | validity | createTime | updateTime | remarks | isOccupy |
+----+----------------+------+-------+---------+--------+--------+------------+----------+------------+------------+---------+----------+
| 33 | 21834361160983 |      | MG900 |         | 10r    |      5 | 1713779825 |        0 | 1397902052 | 1444909107 | S9??    |        0 |
| 34 | 98611514358115 |      | SG900 |         | 10r    |      9 | 1713779825 |        1 | 1397902052 | 1402761600 | S9??    |        0 |
| 37 | 32403823306389 |      | SG900 |         | 21p    |      9 | 1713779825 |        0 | 1397902052 | 1408155404 | S9??    |        0 |
| 38 | 48678569203206 |      | SG900 |         | 11b    |      2 | 1713779825 |        1 | 1397902052 | 1398700800 | S9??    |        0 |
| 39 | 15562144263342 |      | SG900 |         | 21p    |      2 | 1713779825 |        0 | 1397902052 | 1408511977 | S9??    |        0 |
| 40 | 48181113635776 |      | SG900 |         | 21p    |      9 | 1713779825 |        0 | 1397902052 | 1408512054 | S9??    |        0 |
| 41 | 31075182485459 |      | SG900 |         | 21p    |      3 | 1713779825 |        0 | 1397902052 | 1413422548 | S9??    |        0 |
| 42 | 31163793095545 |      | SG900 |         | 13g    |      8 | 1713779825 |        1 | 1397902052 | 1402761600 | S9??    |        0 |
| 43 | 80399562832478 |      | SG900 |         | 21p    |      2 | 1713779825 |        0 | 1397902052 | 1401866080 | S9??    |        0 |
| 44 | 64216038160233 |      | SG900 |         | 13g    |      9 | 1713779825 |        1 | 1397902052 | 1402761600 | S9??    |        0 |
+----+----------------+------+-------+---------+--------+--------+------------+----------+------------+------------+---------+----------+
10 rows in set (0.00 sec)

mysql> select concat(imei,nCheck) from mirrtalkInfo where status='13g' limit 10;      
+---------------------+
| concat(imei,nCheck) |
+---------------------+
| 311637930955458     |
| 642160381602339     |
| 954584074351551     |
| 141131133440589     |
| 554766547629275     |
| 573313693012209     |
| 514723010502447     |
| 227834420544362     |
| 842064985969433     |
| 151776036357780     |
+---------------------+
10 rows in set (0.00 sec)

mysql> select concat(imei,nCheck) from mirrtalkInfo where status='13g' limit 20;
+---------------------+
| concat(imei,nCheck) |
+---------------------+
| 311637930955458     |
| 642160381602339     |
| 954584074351551     |
| 141131133440589     |
| 554766547629275     |
| 573313693012209     |
| 514723010502447     |
| 227834420544362     |
| 842064985969433     |
| 151776036357780     |
| 253689773916618     |
| 899275278743150     |
| 734706548937353     |
| 846013717901012     |
| 437804607486121     |
| 324329186664530     |
| 109074566127051     |
| 461421255590549     |
| 399662534830795     |
| 112294826594347     |
+---------------------+
20 rows in set (0.00 sec)
mysql>

### 修改BMR中的tokencode
