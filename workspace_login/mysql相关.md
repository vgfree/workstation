create table login_config( id INT NOT NULL AUTO_INCREMENT, appKey VARCHAR(1000) NOT NULL, base VARCHAR(1000), roadRank VARCHAR(1000), sicong VARCHAR(1000), userInfo VARCHAR(1000), PRIMARY KEY (id));


INSERT INTO login_config(appKey, base, roadRank, sicong ) VALUES ("bcYtC65Gc89", '{"msgServer":"scsever.daoke.me", "msgPort":8282, "heart":30, "fileUrl":"http://oss-cn-hangzhou.aliyuncs.com"}', '{"rrIoUrl":"http://rtr.daoke.io/roadRankapi", "normalRoad":1000, "highRoad":5000, "askTime":180}', '{"serverType":1}');


UPDATE userInfo SET nickname='%s' , headName='%s', birthday='%s', gender=%d, activeCity='%s', introduction='%s', carBrand=%d, carModels=%d, plateNumber='%s' WHERE accountID='%s';
