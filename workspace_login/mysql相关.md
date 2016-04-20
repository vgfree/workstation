CREATE TABLE loginConfig( id INT NOT NULL AUTO_INCREMENT, appKey VARCHAR(20) NOT NULL, base VARCHAR(1000), roadRank VARCHAR(1000), sicong VARCHAR(1000), PRIMARY KEY (id));


INSERT INTO loginConfig(appKey, base, roadRank, sicong ) VALUES ("1858017065", '{"msgServer":"scsever.daoke.me", "msgPort":8282, "heart":30, "fileUrl":"http://oss-cn-hangzhou.aliyuncs.com"}', '{"rrIoUrl":"http://rtr.daoke.io/roadRankapi", "normalRoad":1000, "highRoad":5000, "askTime":180}', '{"serverType":1}');


UPDATE userInfo SET nickname='%s' , headName='%s', birthday='%s', gender=%d, activeCity='%s', introduction='%s', carBrand=%d, carModels=%d, plateNumber='%s' WHERE accountID='%s';


ALTER TABLE userInfo ADD cityCode VARCHAR(1000)
