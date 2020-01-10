BEGIN TRANSACTION;
CREATE TABLE "Account" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	"BillingStreet" VARCHAR(255), 
	"BillingCity" VARCHAR(255), 
	"BillingState" VARCHAR(255), 
	"BillingCountry" VARCHAR(255), 
	"BillingPostalCode" VARCHAR(255), 
	"npe01__SYSTEMIsIndividual__c" VARCHAR(255), 
	"npe01__SYSTEM_AccountType__c" VARCHAR(255), 
	"npo02__AverageAmount__c" VARCHAR(255), 
	"npo02__Best_Gift_Year_Total__c" VARCHAR(255), 
	"npo02__Best_Gift_Year__c" VARCHAR(255), 
	"npo02__FirstCloseDate__c" VARCHAR(255), 
	"npo02__Formal_Greeting__c" VARCHAR(255), 
	"npo02__HouseholdPhone__c" VARCHAR(255), 
	"npo02__Informal_Greeting__c" VARCHAR(255), 
	"npo02__LargestAmount__c" VARCHAR(255), 
	"npo02__LastCloseDate__c" VARCHAR(255), 
	"npo02__LastMembershipAmount__c" VARCHAR(255), 
	"npo02__LastMembershipDate__c" VARCHAR(255), 
	"npo02__LastMembershipLevel__c" VARCHAR(255), 
	"npo02__LastMembershipOrigin__c" VARCHAR(255), 
	"npo02__LastOppAmount__c" VARCHAR(255), 
	"npo02__MembershipEndDate__c" VARCHAR(255), 
	"npo02__MembershipJoinDate__c" VARCHAR(255), 
	"npo02__NumberOfClosedOpps__c" VARCHAR(255), 
	"npo02__NumberOfMembershipOpps__c" VARCHAR(255), 
	"npo02__OppAmount2YearsAgo__c" VARCHAR(255), 
	"npo02__OppAmountLastNDays__c" VARCHAR(255), 
	"npo02__OppAmountLastYear__c" VARCHAR(255), 
	"npo02__OppAmountThisYear__c" VARCHAR(255), 
	"npo02__OppsClosed2YearsAgo__c" VARCHAR(255), 
	"npo02__OppsClosedLastNDays__c" VARCHAR(255), 
	"npo02__OppsClosedLastYear__c" VARCHAR(255), 
	"npo02__OppsClosedThisYear__c" VARCHAR(255), 
	"npo02__SYSTEM_CUSTOM_NAMING__c" VARCHAR(255), 
	"npo02__SmallestAmount__c" VARCHAR(255), 
	"npo02__TotalMembershipOppAmount__c" VARCHAR(255), 
	"npo02__TotalOppAmount__c" VARCHAR(255), 
	"npsp__Funding_Focus__c" VARCHAR(255), 
	"npsp__Grantmaker__c" VARCHAR(255), 
	"npsp__Matching_Gift_Administrator_Name__c" VARCHAR(255), 
	"npsp__Matching_Gift_Amount_Max__c" VARCHAR(255), 
	"npsp__Matching_Gift_Amount_Min__c" VARCHAR(255), 
	"npsp__Matching_Gift_Annual_Employee_Max__c" VARCHAR(255), 
	"npsp__Matching_Gift_Comments__c" VARCHAR(255), 
	"npsp__Matching_Gift_Company__c" VARCHAR(255), 
	"npsp__Matching_Gift_Email__c" VARCHAR(255), 
	"npsp__Matching_Gift_Info_Updated__c" VARCHAR(255), 
	"npsp__Matching_Gift_Percent__c" VARCHAR(255), 
	"npsp__Matching_Gift_Phone__c" VARCHAR(255), 
	"npsp__Matching_Gift_Request_Deadline__c" VARCHAR(255), 
	"npsp__Number_of_Household_Members__c" VARCHAR(255), 
	level__c VARCHAR(255), 
	parent_id VARCHAR(255), 
	previous_level__c VARCHAR(255), 
	npe01__one2_one_contact__c VARCHAR(255), 
	npsp__batch__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "Account" VALUES('0013F00000U8YX0QAN','Dominico Household','0123F000001HAQxQAO','36624 Jefferson Way Way','Greenville','OR','','63102','true','Household Account','12500.0','12500.0','2019','2019-05-07','Em and Pavlina Dominico','','Em and Pavlina','12500.0','2019-05-07','12500.0','2019-05-07','','','12500.0','','','1.0','1.0','0.0','12500.0','0.0','12500.0','0.0','1.0','0.0','1.0','','12500.0','12500.0','12500.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpNQAW','','','0033F00000Luj27QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YX1QAN','Dominika and Luther Household','0123F000001HAQxQAO','36624 Jefferson Way Way','Greenville','OR','','63102','true','Household Account','10000.0','10000.0','2019','2019-08-27','Sarah Dominika and Sheridan Luther','','Sarah and Sheridan','10000.0','2019-08-27','10000.0','2019-08-27','','','10000.0','','','1.0','1.0','0.0','10000.0','0.0','10000.0','0.0','1.0','0.0','1.0','','10000.0','10000.0','10000.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpNQAW','','','0033F00000Luj29QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YX2QAN','Trelawni and Zappa Household','0123F000001HAQxQAO','18312 Duchess Rd','Kingston','WA','','63981','true','Household Account','9375.0','9375.0','2019','2019-05-08','Nicolai Trelawni and Buddy Zappa','','Nicolai and Buddy','9375.0','2019-05-08','9375.0','2019-05-08','','','9375.0','','','1.0','1.0','0.0','9375.0','0.0','9375.0','0.0','1.0','0.0','1.0','','9375.0','9375.0','9375.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpPQAW','','','0033F00000Luj4hQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YX3QAN','Evans and Wong Household','0123F000001HAQxQAO','','','','','','true','Household Account','461.67','3533.32','2019','2018-11-04','Candace Evans and Bobby Wong','','Candace and Bobby','833.33','2019-11-30','833.33','2019-11-30','','','833.33','','','10.0','10.0','0.0','3533.32','1083.33','3533.32','0.0','6.0','4.0','6.0','','50.0','4616.65','4616.65','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpPQAW','','','0033F00000Luj4jQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YX4QAN','Thulani and Abbascia Household','0123F000001HAQxQAO','18312 Duchess Rd','Kingston','WA','','63981','true','Household Account','7500.0','7500.0','2019','2019-08-28','Eugenius Thulani and Nudd Abbascia','','Eugenius and Nudd','7500.0','2019-08-28','7500.0','2019-08-28','','','7500.0','','','1.0','1.0','0.0','7500.0','0.0','7500.0','0.0','1.0','0.0','1.0','','7500.0','7500.0','7500.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpPQAW','','','0033F00000Luj4lQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YX5QAN','Music Foundation','0123F000001HAQyQAO','123 Main St.','San Francisco','CA','US','94105','false','','1125.0','1250.0','2019','2018-01-01','','','','1250.0','2019-01-01','1250.0','2019-01-01','','','1250.0','','','2.0','2.0','0.0','1250.0','1000.0','1250.0','0.0','1.0','1.0','1.0','','1000.0','2250.0','2250.0','','false','','','','','','false','','','','','','','a0d3F000001WSpPQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YX6QAN','Blotts, Hargrove and Spludge','0123F000001HAQyQAO','1223 Freshman Way','Cooperfield','CA','','94108','false','','1125.0','2250.0','2019','2019-05-10','','','','1250.0','2019-08-30','1000.0','2019-08-30','','','1000.0','','','2.0','2.0','0.0','2250.0','0.0','2250.0','0.0','2.0','0.0','2.0','','1000.0','2250.0','2250.0','','false','','','','','','false','','','','','','','a0d3F000001WSpPQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YX7QAN','Chong Household','0123F000001HAQxQAO','2137 Larry Street','San Francisco','CA','','94118','true','Household Account','68.33','205.0','2019','2019-01-01','Mattias, Jason, Sampson, Carly, Grayson and Julie Chong','','Mattias, Jason, Sampson, Carly, Grayson and Julie','100.0','2019-01-01','75.0','2019-01-01','','','75.0','','','3.0','3.0','0.0','205.0','0.0','205.0','0.0','3.0','0.0','3.0','','30.0','205.0','205.0','','false','','','','','','false','','','','','','6.0','a0d3F000001WSpOQAW','','','0033F00000Luj4KQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YX8QAN','Loki and Shouta Household','0123F000001HAQxQAO','306 Monterey Drive Ave S','Franklin','AK','','56949','true','Household Account','160.0','160.0','2019','2019-09-23','Llewlyn Loki and Brianna Shouta','','Llewlyn and Brianna','160.0','2019-09-23','160.0','2019-09-23','','','160.0','','','1.0','1.0','0.0','160.0','0.0','160.0','0.0','1.0','0.0','1.0','','160.0','160.0','160.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpOQAW','','','0033F00000Luj4NQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YX9QAN','Loui Household','0123F000001HAQxQAO','102 Drummand Grove Dr','Burnt Corn','AL','','56070','true','Household Account','125.0','125.0','2019','2019-05-01','Leo and Denorah Loui','','Leo and Denorah','125.0','2019-05-01','125.0','2019-05-01','','','125.0','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpOQAW','','','0033F00000Luj4PQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXAQA3','George and Waterman Household','0123F000001HAQxQAO','2754 Glamis Place Way','Chester','MA','','58707','true','Household Account','300.0','300.0','2019','2019-05-03','America George and Nina Waterman','','America and Nina','300.0','2019-05-03','300.0','2019-05-03','','','300.0','','','1.0','1.0','0.0','300.0','0.0','300.0','0.0','1.0','0.0','1.0','','300.0','300.0','300.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpOQAW','','','0033F00000Luj4RQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXBQA3','de la O and Subrahmanya Household','0123F000001HAQxQAO','74358 S Wycliff Ave','Salem','MA','','61344','true','Household Account','125.0','125.0','2019','2019-05-05','Geoff de la O and Ansa Subrahmanya','','Geoff and Ansa','125.0','2019-05-05','125.0','2019-05-05','','','125.0','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpOQAW','','','0033F00000Luj4TQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXCQA3','American Firefights for Freedom','0123F000001HAQyQAO','292 Sporting Green Pl','Charlotte','CA','','94108','false','','100.0','100.0','2019','2019-09-02','','','','100.0','2019-09-02','100.0','2019-09-02','','','100.0','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','','100.0','100.0','100.0','','false','','','','','','false','','','','','','','a0d3F000001WSpOQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YXDQA3','Kim Household','0123F000001HAQxQAO','2137 Larry Street','San Francisco','CA','','94118','true','Household Account','50.0','100.0','2019','2018-01-01','Carl, Julie, Kevin and Carly Kim','','Carl, Julie, Kevin and Carly','75.0','2019-01-01','75.0','2019-01-01','','','75.0','','','3.0','3.0','0.0','100.0','50.0','100.0','0.0','2.0','1.0','2.0','','25.0','150.0','150.0','','false','','','','','','false','','','','','','4.0','a0d3F000001WSpOQAW','','','0033F00000Luj4XQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXEQA3','Lewi Household','0123F000001HAQxQAO','102 Drummand Grove Dr','Burnt Corn','AL','','56070','true','Household Account','100.0','100.0','2019','2019-08-20','Tasgall and Leanne Lewi','','Tasgall and Leanne','100.0','2019-08-20','100.0','2019-08-20','','','100.0','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','','100.0','100.0','100.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpOQAW','','','0033F00000Luj4ZQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXFQA3','Oden Household','0123F000001HAQxQAO','306 Monterey Drive Ave S','Franklin','AK','','56949','true','Household Account','125.0','125.0','2019','2019-09-23','Freya and Brianna Oden','','Freya and Brianna','125.0','2019-09-23','125.0','2019-09-23','','','125.0','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpOQAW','','','0033F00000Luj4bQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXGQA3','Shouta Household','0123F000001HAQxQAO','2754 Glamis Place Way','Chester','MA','','58707','true','Household Account','225.0','225.0','2019','2019-08-22','Natalija and Nina Shouta','','Natalija and Nina','225.0','2019-08-22','225.0','2019-08-22','','','225.0','','','1.0','1.0','0.0','225.0','0.0','225.0','0.0','1.0','0.0','1.0','','225.0','225.0','225.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpOQAW','','','0033F00000Luj4dQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXHQA3','Primoz Household','0123F000001HAQxQAO','74358 S Wycliff Ave','Salem','MA','','61344','true','Household Account','100.0','100.0','2019','2019-08-25','Jeffry and Ansa Primoz','','Jeffry and Ansa','100.0','2019-08-25','100.0','2019-08-25','','','100.0','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','','100.0','100.0','100.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpOQAW','','','0033F00000Luj4fQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXIQA3','Johnson''s General Stores','0123F000001HAQyQAO','1121 David Vale Road','Reston','VA','','22091','false','','87.5','250.0','2019','2018-03-01','','','','125.0','2019-08-23','50.0','2019-08-23','','','50.0','','','4.0','4.0','0.0','250.0','100.0','250.0','0.0','3.0','1.0','3.0','','50.0','350.0','350.0','','false','','','','','','false','','','','','','','a0d3F000001WSpOQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YXJQA3','Orange Tree Imports','0123F000001HAQyQAO','1 Main Street','San Francisco','CA','','94108','false','','37.5','150.0','2019','2019-05-02','','','','75.0','2019-08-22','10.0','2019-08-22','','','10.0','','','4.0','4.0','0.0','150.0','0.0','150.0','0.0','4.0','0.0','4.0','','10.0','150.0','150.0','','false','','','','','','false','','','','','','','a0d3F000001WSpOQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YXKQA3','Gnarl''s Bicycles','0123F000001HAQyQAO','991 Bay Common Dr S','St. Louis','CA','','94108','false','','112.5','225.0','2019','2019-05-06','','','','125.0','2019-08-26','100.0','2019-08-26','','','100.0','','','2.0','2.0','0.0','225.0','0.0','225.0','0.0','2.0','0.0','2.0','','100.0','225.0','225.0','','false','','','','','','false','','','','','','','a0d3F000001WSpOQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YXLQA3','Hernandez and Nguyen Household','0123F000001HAQxQAO','55 Charleston','South San Francisco','CA','','94044','true','Household Account','125.0','125.0','2018','2018-04-20','Nilza Hernandez and Jon Nguyen','','Nilza and Jon','125.0','2018-04-20','125.0','2018-04-20','','','125.0','','','1.0','1.0','0.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2BQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXMQA3','Bace Household','0123F000001HAQxQAO','10 Ocean Parkway','Brooklyn','NY','','2317','true','Household Account','0.0','','','','Robert and Lonnie Bace','','Robert and Lonnie','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2DQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXNQA3','Ivans Household','0123F000001HAQxQAO','','','','','','true','Household Account','125.0','125.0','2018','2018-11-05','Geetika Ivans','','Geetika','125.0','2018-11-05','125.0','2018-11-05','','','125.0','','','1.0','1.0','0.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','1.0','a0d3F000001WSpQQAW','','','0033F00000Luj2EQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXOQA3','Nyugen and Offermans Household','0123F000001HAQxQAO','1172 Boylston St.','Boston','MA','','2199','true','Household Account','0.0','','','','Henry Nyugen and Felicity Offermans','','Henry and Felicity','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2FQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXPQA3','Smythe and Whitley Household','0123F000001HAQxQAO','1 Cherry Street','Pleasant','NJ','','7777','true','Household Account','0.0','','','','Caroline Smythe and Elias Whitley','','Caroline and Elias','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2IQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXQQA3','Beethavent and Unnur Household','0123F000001HAQxQAO','2357 Attlee Rd','Bristol','ME','','68376','true','Household Account','0.0','','','','Georgia Beethavent and Orion Unnur','','Georgia and Orion','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2KQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXRQA3','Mavis Household','0123F000001HAQxQAO','1391 Diane Street','City Of Commerce','CA','','90040','true','Household Account','0.0','','','','Nelda and Stapleton Mavis','','Nelda and Stapleton','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2MQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXSQA3','Bainter Household','0123F000001HAQxQAO','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','true','Household Account','75.0','75.0','2019','2019-01-02','Edith and Deborah Bainter','','Edith and Deborah','75.0','2019-01-02','75.0','2019-01-02','','','75.0','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2OQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXTQA3','Orange and Tan Household','0123F000001HAQxQAO','4270 4th Court','Arlington','MA','','2128','true','Household Account','75.0','75.0','2019','2019-01-22','Patrick Orange and Olivia Tan','','Patrick and Olivia','75.0','2019-01-22','75.0','2019-01-22','','','75.0','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2QQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXUQA3','Vakil and Wong Household','0123F000001HAQxQAO','918 Duffield Crescent St','Arlington','WA','','57828','true','Household Account','0.0','','','','Sufjan Vakil and Neve Wong','','Sufjan and Neve','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2SQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXVQA3','Rudddles Household','0123F000001HAQxQAO','8262 Phinney Ridge Rd','Georgetown','ME','','59586','true','Household Account','0.0','','','','Lara and Charlotte Rudddles','','Lara and Charlotte','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2UQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXWQA3','Jackson and Wong Household','0123F000001HAQxQAO','37179 Bedford Shores St','Fairfield','KS','','62223','true','Household Account','0.0','','','','Eliza Jackson and Nitika Wong','','Eliza and Nitika','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2WQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXXQA3','Aethelstan Household','0123F000001HAQxQAO','9156 Springfield Green Dr','Marion','VA','','64860','true','Household Account','75.0','75.0','2019','2019-05-09','Mattia and Kallistrate Aethelstan','','Mattia and Kallistrate','75.0','2019-05-09','75.0','2019-05-09','','','75.0','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2YQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXYQA3','O''Shea and Primoz Household','0123F000001HAQxQAO','4578 Linda Ave','Riverside','WV','','65739','true','Household Account','0.0','','','','Irma O''Shea and Nancy Primoz','','Irma and Nancy','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2aQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXZQA3','Geiser-Bann Household','0123F000001HAQxQAO','2289 David Budd St','Lebanon','MD','','66618','true','Household Account','30.0','30.0','2019','2019-05-11','Bennett and Maya Geiser-Bann','','Bennett and Maya','30.0','2019-05-11','30.0','2019-05-11','','','30.0','','','1.0','1.0','0.0','30.0','0.0','30.0','0.0','1.0','0.0','1.0','','30.0','30.0','30.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2cQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXaQAN','Clerr and Nazarian Household','0123F000001HAQxQAO','840 Mount Street','Bay City','MI','','48706','true','Household Account','0.0','','','','Danny Clerr and Bryce Nazarian','','Danny and Bryce','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2eQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXbQAN','Ivans Household','0123F000001HAQxQAO','','','','','','true','Household Account','75.0','75.0','2018','2018-11-04','Sehar Ivans','','Sehar','75.0','2018-11-04','75.0','2018-11-04','','','75.0','','','1.0','1.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','1.0','a0d3F000001WSpQQAW','','','0033F00000Luj2fQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXcQAN','Ivans Household','0123F000001HAQxQAO','','','','','','true','Household Account','0.0','','','','Lakshmi and Calvin Ivans','','Lakshmi and Calvin','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2hQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXdQAN','Figueroo Household','0123F000001HAQxQAO','25 10th Ave.','San Francisco','CA','','94121','true','Household Account','0.0','','','','Roger and Linda Figueroo','','Roger and Linda','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2jQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXeQAN','Campagna Household','0123F000001HAQxQAO','34 Shipham Close Rd','Truth or Consequences','NM','','55191','true','Household Account','0.0','','','','Tessa and Harold Campagna','','Tessa and Harold','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2lQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXfQAN','Clerk Household','0123F000001HAQxQAO','2527 Monroe Rd','Dover','CO','','98982','true','Household Account','0.0','','','','Deandre and Helena Clerk','','Deandre and Helena','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2nQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXgQAN','Kanban Household','0123F000001HAQxQAO','2459 44th St E','Reston','VA','','71013','true','Household Account','0.0','','','','Heidi and Xiao-yu Kanban','','Heidi and Xiao-yu','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2pQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXhQAN','Primordial Household','0123F000001HAQxQAO','','','','','','true','Household Account','0.0','','','','Lois and Louis Primordial','','Lois and Louis','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2rQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXiQAN','Djyradj Household','0123F000001HAQxQAO','2425 9th Ave','Madison','CA','','70134','true','Household Account','0.0','','','','Kamilla and Suhani Djyradj','','Kamilla and Suhani','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2tQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXjQAN','Kasprawicz Household','0123F000001HAQxQAO','2323 Dent Way','Witchita','KS','','67497','true','Household Account','0.0','','','','Luiza and Roger Kasprawicz','','Luiza and Roger','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2vQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXkQAN','Bateson and Navarro Household','0123F000001HAQxQAO','2391 Roborough Dr','Salem','LA','','69255','true','Household Account','0.0','','','','Jozef Bateson and Nageen Navarro','','Jozef and Nageen','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2xQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXlQAN','Frasier and Ng Household','0123F000001HAQxQAO','2629 Nebraska St','Dover','FL','','99948','true','Household Account','0.0','','','','Natali Frasier and Mpho Ng','','Natali and Mpho','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj2zQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXmQAN','Prasad and Oden Household','0123F000001HAQxQAO','2595 Montauk Ave W','Dover','FL','','99948','true','Household Account','0.0','','','','Gabriel Prasad and Bartolomej Oden','','Gabriel and Bartolomej','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj31QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXnQAN','Bates and Sokolov Household','0123F000001HAQxQAO','2493 89th Way','Seattle','WA','','98103','true','Household Account','0.0','','','','Eleonora Bates and Krithika Sokolov','','Eleonora and Krithika','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj33QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXoQAN','Bokolov and Wong Household','0123F000001HAQxQAO','2561 Madison Dr','Ashland','KY','','99861','true','Household Account','0.0','','','','Mirce Bokolov and Aldegund Wong','','Mirce and Aldegund','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj35QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXpQAN','Mandela and Yudes Household','0123F000001HAQxQAO','726 Twin House Lane','Springfield','MO','','65802','true','Household Account','0.0','','','','Diana Mandela and Crystal Yudes','','Diana and Crystal','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj36QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXqQAN','Watson Household','0123F000001HAQxQAO','24786 Handlebar Dr N','Madison','WI','','60465','true','Household Account','0.0','','','','Nashville and Evrim Watson','','Nashville and Evrim','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj39QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YXrQAN','Cole City Council Office','0123F000001HAQyQAO','143 South Main Street','Cole City','KS','United States','98104','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YXsQAN','Nostdal and Rymph Household','0123F000001HAQxQAO','762 Smiley','Port Townsend','WA','','98368','true','Household Account','0.0','','','','Jessie Nostdal and Zach Rymph','','Jessie and Zach','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3BQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXtQAN','Douglass Household','0123F000001HAQxQAO','','','','','','true','Household Account','0.0','','','','Erica Douglass','','Erica','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0d3F000001WSpQQAW','','','0033F00000Luj3CQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXuQAN','Community Center','0123F000001HAQyQAO','','','','','','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','0033F00000Luj3QQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXvQAN','Contact Household','0123F000001HAQxQAO','One Market Street','San Francisco','CA','USA','94105','true','Household Account','0.0','0.0','','','Sample Contact','','Sample','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0d3F000001WSpQQAW','','','0033F00000Luj3DQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXwQAN','Sample Organization','0123F000001HAQyQAO','One California Street','San Francisco','CA','USA','94105','false','','0.0','0.0','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','0033F00000Luj3DQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXxQAN','Figueroa and Nguyen Household','0123F000001HAQxQAO','25 10th Ave.','San Francisco','CA','','94121','true','Household Account','0.0','','','','Jose Figueroa and Linda Nguyen','','Jose and Linda','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3FQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXyQAN','Red and Brown Household','0123F000001HAQxQAO','4270 4th Court','Arlington','MA','','02128','true','Household Account','50.0','50.0','2018','2018-01-22','Gurleen Red and Christian Brown','','Gurleen and Christian','50.0','2018-01-22','50.0','2018-01-22','','','50.0','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','','50.0','50.0','50.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3HQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YXzQAN','Boston Household','0123F000001HAQxQAO','25 Boyston','Boston','MA','','2130','true','Household Account','62.5','75.0','2019','2018-01-22','Celia, Louis and Celia-Rae Boston','','Celia, Louis and Celia-Rae','75.0','2019-01-22','75.0','2019-01-22','','','75.0','','','2.0','2.0','0.0','75.0','50.0','75.0','0.0','1.0','1.0','1.0','','50.0','125.0','125.0','','false','','','','','','false','','','','','','3.0','a0d3F000001WSpQQAW','','','0033F00000Luj3JQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY0QAN','Ng Household','0123F000001HAQxQAO','1172 Boylston St.','Boston','MA','','02199','true','Household Account','0.0','','','','Walter and Felicia Ng','','Walter and Felicia','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3LQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY1QAN','Bruce Household','0123F000001HAQxQAO','10 Ocean Parkway','Brooklyn','NY','','02317','true','Household Account','0.0','','','','Robert and Lonnie Bruce','','Robert and Lonnie','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3OQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY2QAN','Bainter and Navarro Household','0123F000001HAQxQAO','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','true','Household Account','50.0','50.0','2018','2018-01-02','Daphne Bainter and Deborah Navarro','','Daphne and Deborah','50.0','2018-01-02','50.0','2018-01-02','','','50.0','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','','50.0','50.0','50.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3QQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY3QAN','Mayo and Whitley Household','0123F000001HAQxQAO','840 Mount Street','Bay City','MI','','48706','true','Household Account','0.0','','','','Chaz Mayo and Bryce Whitley','','Chaz and Bryce','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3SQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY4QAN','Davis Household','0123F000001HAQxQAO','1391 Diane Street','City Of Commerce','CA','','90040','true','Household Account','0.0','','','','Nelda Davis','','Nelda','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0d3F000001WSpQQAW','','','0033F00000Luj3TQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY5QAN','Mendoza Household','0123F000001HAQxQAO','55 Charleston','South San Francisco','CA','','94044','true','Household Account','100.0','100.0','2018','2018-04-20','Nilza and Jon Mendoza','','Nilza and Jon','100.0','2018-04-20','100.0','2018-04-20','','','100.0','','','1.0','1.0','0.0','0.0','100.0','0.0','0.0','0.0','1.0','0.0','','100.0','100.0','100.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3VQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY6QAN','Blum Household','0123F000001HAQxQAO','1 Cherry Street','Pleasant','NJ','','07777','true','Household Account','0.0','','','','Zoe Blum','','Zoe','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0d3F000001WSpQQAW','','','0033F00000Luj3WQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY7QAN','Subrahmanya Household','0123F000001HAQxQAO','918 Duffield Crescent St','Arlington','WA','','57828','true','Household Account','0.0','','','','Sieffre and Baptiste Subrahmanya','','Sieffre and Baptiste','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3YQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YY8QAN','Yudes Household','0123F000001HAQxQAO','8262 Phinney Ridge Rd','Georgetown','ME','','59586','true','Household Account','0.0','','','','Lara and Charlotte Yudes','','Lara and Charlotte','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3aQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YY9QAN','Lauterborn and Waterman Household','0123F000001HAQxQAO','37179 Bedford Shores St','Cole City','KS','','62223','true','Household Account','0.0','','','','Eric Lauterborn and Concepcion de Jesus Waterman','','Eric and Concepcion de Jesus','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3cQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYAQA3','Aethelstan and Giannino Household','0123F000001HAQxQAO','9156 Springfield Green Dr','Marion','VA','','64860','true','Household Account','50.0','50.0','2019','2019-08-29','Mattia Aethelstan and Kallistrate Giannino','','Mattia and Kallistrate','50.0','2019-08-29','50.0','2019-08-29','','','50.0','','','1.0','1.0','0.0','50.0','0.0','50.0','0.0','1.0','0.0','1.0','','50.0','50.0','50.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3eQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYBQA3','O''Sullivan and Guerra Household','0123F000001HAQxQAO','4578 Linda Ave','Riverside','WV','','65739','true','Household Account','0.0','','','','Irma O''Sullivan and Cassius Guerra','','Irma and Cassius','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3gQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYCQA3','Geier Household','0123F000001HAQxQAO','2289 David Budd St','Lebanon','MD','','66618','true','Household Account','25.0','25.0','2019','2019-08-31','Marat and Natasha Geier','','Marat and Natasha','25.0','2019-08-31','25.0','2019-08-31','','','25.0','','','1.0','1.0','0.0','25.0','0.0','25.0','0.0','1.0','0.0','1.0','','25.0','25.0','25.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3iQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYDQA3','Schubert and Maddox Household','0123F000001HAQxQAO','2357 Attlee Rd','Bristol','ME','','68376','true','Household Account','0.0','','','','Hildie Schubert and Ursula Maddox','','Hildie and Ursula','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3kQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYEQA3','Campaign Household','0123F000001HAQxQAO','34 Shipham Close Rd','Truth or Consequences','NM','','55191','true','Household Account','0.0','','','','Grace and Georgie Campaign','','Grace and Georgie','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3mQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYFQA3','Unnur Household','0123F000001HAQxQAO','24786 Handlebar Dr N','Madison','WI','','60465','true','Household Account','0.0','','','','Fionnghuala and Maia Unnur','','Fionnghuala and Maia','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3oQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYGQA3','Thomas and Gibbons Household','0123F000001HAQxQAO','726 Twin House Lane','Springfield','MO','','65802','true','Household Account','0.0','','','','Diana Thomas and Charlie Gibbons','','Diana and Charlie','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3pQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYHQA3','Kovacevic Household','0123F000001HAQxQAO','2323 Dent Way','Witchita','KS','','67497','true','Household Account','0.0','','','','Gretel and Baron Kovacevic','','Gretel and Baron','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3sQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYIQA3','Lukeson and Zappa Household','0123F000001HAQxQAO','2391 Roborough Dr','Salem','LA','','69255','true','Household Account','0.0','','','','Jozef Lukeson and Nageen Zappa','','Jozef and Nageen','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3uQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYJQA3','Djuradj and Tan Household','0123F000001HAQxQAO','2425 9th Ave','Madison','CA','','70134','true','Household Account','0.0','','','','Kamil Djuradj and Suhani Tan','','Kamil and Suhani','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3wQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYKQA3','Conbon and Bi Household','0123F000001HAQxQAO','2459 44th St E','Reston','VA','','71013','true','Household Account','0.0','','','','Azarel Conbon and Carol Bi','','Azarel and Carol','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj3yQAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYLQA3','Offermans Household','0123F000001HAQxQAO','2493 89th Way','Seattle','WA','','98103','true','Household Account','0.0','','','','Eleonora and Deepshika Offermans','','Eleonora and Deepshika','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj40QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYMQA3','Sandeghin and Castle Household','0123F000001HAQxQAO','2527 Monroe Rd','Dover','CO','','98982','true','Household Account','0.0','','','','Lucy Sandeghin and Helen Castle','','Lucy and Helen','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj41QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYNQA3','Sokolov Household','0123F000001HAQxQAO','2561 Madison Dr','Ashland','KY','','99861','true','Household Account','0.0','','','','Solitude and Aldegund Sokolov','','Solitude and Aldegund','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj44QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYOQA3','Nazarian Household','0123F000001HAQxQAO','2595 Montauk Ave W','Dover','FL','','99948','true','Household Account','0.0','','','','Gabrielle and Alexi Nazarian','','Gabrielle and Alexi','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj46QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYPQA3','McNeill Household','0123F000001HAQxQAO','2629 Nebraska St','Dover','FL','','99948','true','Household Account','0.0','','','','Vukasin and Mpho McNeill','','Vukasin and Mpho','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj48QAB','');
INSERT INTO "Account" VALUES('0013F00000U8YYQQA3','Devine Household','0123F000001HAQxQAO','','','','','','true','Household Account','0.0','','','','Lois and Louis Devine','','Lois and Louis','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj4AQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YYRQA3','Bullard Household','0123F000001HAQxQAO','129 W 81st','Buffalo','NY','','08982','true','Household Account','350.0','350.0','2019','2019-12-10','Robert, Sarah and Lisa Bullard','','Robert, Sarah and Lisa','350.0','2019-12-10','350.0','2019-12-10','','','350.0','','','1.0','1.0','0.0','350.0','0.0','350.0','0.0','1.0','0.0','1.0','','350.0','350.0','350.0','','false','','','','','','false','','','','','','3.0','a0d3F000001WSpQQAW','','','0033F00000Luj4DQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YYSQA3','Cloud Kicks','0123F000001HAQyQAO','1220 Burwell Heights Rd','Houston','TX','','77006','false','','1125.0','2250.0','2018','2018-11-04','','','','1250.0','2018-11-04','1250.0','2018-11-04','','','1250.0','','','2.0','2.0','0.0','0.0','2250.0','0.0','0.0','0.0','2.0','0.0','','1000.0','2250.0','2250.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYTQA3','Newchange','0123F000001HAQyQAO','8990 Chatham Drive','Flower Mound','Tx','','39932','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYUQA3','Tesco','0123F000001HAQyQAO','111 Second Street','Boston','MA','','02130','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYVQA3','Orange Company','0123F000001HAQyQAO','122 Rother View','','','','01478','false','','112.5','225.0','2018','2018-05-21','','','','125.0','2018-05-21','125.0','2018-05-21','','','125.0','','','2.0','2.0','0.0','0.0','225.0','0.0','0.0','0.0','2.0','0.0','','100.0','225.0','225.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYWQA3','Acme Corporation','0123F000001HAQyQAO','500 Main St.','Cambridge','MA','','02130','false','','11250.0','22500.0','2018','2018-06-30','','','','12500.0','2018-06-30','12500.0','2018-06-30','','','12500.0','','','2.0','2.0','0.0','0.0','22500.0','0.0','0.0','0.0','2.0','0.0','','10000.0','22500.0','22500.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYXQA3','Target Campaigns','0123F000001HAQyQAO','232F Coppice Loan Pkwy','San Francisco','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYYQA3','Save the Mutts','0123F000001HAQyQAO','2988 Raven Grange','Rochester','DE','','2222','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYZQA3','Spotsham University','0123F000001HAQyQAO','8923A Elm St','Dorchester','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYaQAN','University of Bringhampton','0123F000001HAQyQAO','982 Granary Point Ave N','Bingley','VA','','22091','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYbQAN','Whimsey Wearhouse','0123F000001HAQyQAO','882 Pine Tree Hall','Nayes Dam','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYcQAN','American Firefighters for Historic Book Preservation','0123F000001HAQyQAO','292 Sporting Green Pl','Charlotte','CA','','94108','false','','75.0','75.0','2019','2019-09-02','','','','75.0','2019-09-02','75.0','2019-09-02','','','75.0','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYdQAN','Foreign Fathers','0123F000001HAQyQAO','13 Angrew Trees Pl','Hill Station','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYeQAN','Turtledove Cinemas','0123F000001HAQyQAO','789 E Watersham Rte','Charlotte','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYfQAN','Yuri-Creek Playhouse','0123F000001HAQyQAO','3832 Laburnam Bank Rd','Vienna','VA','','22091','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYgQAN','Saltanas Bagels','0123F000001HAQyQAO','1222 Hunters Green Dr','Anita','WV','','20199','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYhQAN','Architecture for Adults','0123F000001HAQyQAO','8990 Iona Gardens Plaza','Meryls Town','Tx','','39932','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYiQAN','National Basketball Conglomeration','0123F000001HAQyQAO','373 Clare Heathcliff Pkway','Spottsville','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYjQAN','Junior Magazines','0123F000001HAQyQAO','44 Thomas Garth Dr','Hodgenville','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYkQAN','Hedgepeth Industries','0123F000001HAQyQAO','29887 Bailey Hill La','Bourbonvilla','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYlQAN','Glicks Furniture','0123F000001HAQyQAO','11235 Banana Seat Rd','Charleston','WV','','20777','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYmQAN','Peets Coffee','0123F000001HAQyQAO','25 Market St','San Francisco','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYnQAN','Benificent Insurance','0123F000001HAQyQAO','','','','','','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
INSERT INTO "Account" VALUES('0013F00000U8YYoQAN','Ventresca Household','0123F000001HAQxQAO','','','','','','true','Household Account','0.0','','','','Alex Ventresca','','Alex','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0d3F000001WSpQQAW','','','0033F00000Luj4FQAR','');
INSERT INTO "Account" VALUES('0013F00000U8YYpQAN','Nostdal Works','0123F000001HAQyQAO','','','','','','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0d3F000001WSpQQAW','','','','');
CREATE TABLE "Account_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "Account_rt_mapping" VALUES('0123F000001HAQxQAO','HH_Account');
INSERT INTO "Account_rt_mapping" VALUES('0123F000001HAQyQAO','Organization');
CREATE TABLE "Campaign" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"IsActive" VARCHAR(255), 
	"StartDate" VARCHAR(255), 
	"EndDate" VARCHAR(255), 
	"Status" VARCHAR(255), 
	"Type" VARCHAR(255), 
	location__c VARCHAR(255), 
	on_site_contact__c VARCHAR(255), 
	parent_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "Campaign" VALUES('7013F0000004b3lQAA','Give a Life','false','2018-10-01','2018-11-05','Planned','Telemarketing','','','7013F0000004b3gQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3aQAA','No More Hostile Architecture','true','2019-01-01','2019-11-30','In Progress','Advocacy','','','7013F0000004b3fQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3bQAA','Petition Drives','true','2019-01-01','2019-12-31','In Progress','Advocacy','','','7013F0000004b3aQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3cQAA','Direct Mail: January 2019 - Hostile Architecture','true','2019-01-14','2019-03-15','Completed','Fundraising','','','7013F0000004b3kQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3dQAA','Direct Mail: May 2019 - Hostile Architecture','true','2019-05-01','2019-05-31','Completed','Fundraising','','','7013F0000004b3kQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3eQAA','NMH Petition','true','2019-01-01','2019-05-31','In Progress','Advocacy','','','7013F0000004b3bQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3fQAA','2019 Advocacy Campaigns','true','2019-01-01','2019-12-31','In Progress','Advocacy','','','');
INSERT INTO "Campaign" VALUES('7013F0000004b3gQAA','Annual Appeal 2018','true','2018-01-01','2018-12-31','Completed','Fundraising','','','7013F0000004b3jQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3hQAA','NMH Transitional Housing Capital Campaign','true','2018-10-01','2019-12-31','In Progress','Fundraisng','','','');
INSERT INTO "Campaign" VALUES('7013F0000004b3iQAA','Annual Appeal 2019','true','2019-01-01','2019-12-31','In Progress','Fundraising','','','7013F0000004b3jQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3jQAA','Annual Fund','true','','','In Progress','Fundraising','','','');
INSERT INTO "Campaign" VALUES('7013F0000004b3kQAA','Email Outreach','true','2019-01-01','2019-01-01','In Progress','Advocacy','','','7013F0000004b3aQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3mQAA','Advocacy Training Days','true','2019-01-01','2019-12-31','In Progress','Advocacy','0013F00000U8YXuQAN','0033F00000Luj3QQAR','7013F0000004b3aQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3nQAA','Event: August 2019 - Advocacy Training Day','true','2019-08-07','2019-08-07','Completed','Advocacy','0013F00000U8YXuQAN','0033F00000Luj3QQAR','7013F0000004b3mQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3oQAA','Event: January 2019 - Advocacy Training Day','true','2019-01-15','2019-01-15','Completed','Advocacy','0013F00000U8YXuQAN','0033F00000Luj3QQAR','7013F0000004b3mQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3pQAA','Event: June 2019 - Advocacy Training Day','true','2019-06-20','2019-06-20','Completed','Advocacy','0013F00000U8YXuQAN','0033F00000Luj3QQAR','7013F0000004b3mQAA');
INSERT INTO "Campaign" VALUES('7013F0000004b3qQAA','Event: October 2019 - Advocacy Training Day','true','2019-10-24','2019-10-24','Completed','Advocacy','0013F00000U8YXuQAN','0033F00000Luj3QQAR','7013F0000004b3mQAA');
CREATE TABLE "CampaignMember" (
	sf_id VARCHAR(255) NOT NULL, 
	"Status" VARCHAR(255), 
	campaign_id VARCHAR(255), 
	contact_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "CampaignMember" VALUES('00v3F0000039DezQAE','Responded','7013F0000004b3gQAA','0033F00000Luj4jQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Df0QAE','Responded','7013F0000004b3hQAA','0033F00000Luj4jQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Df1QAE','Responded','7013F0000004b3lQAA','0033F00000Luj4jQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Df2QAE','Responded','7013F0000004b3iQAA','0033F00000Luj4lQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbNQAU','Attended','7013F0000004b3nQAA','0033F00000Luj4jQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbOQAU','Sent','7013F0000004b3nQAA','0033F00000Luj3IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc7QAE','Sent','7013F0000004b3oQAA','0033F00000Luj4jQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbPQAU','Attended','7013F0000004b3nQAA','0033F00000Luj3JQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbQQAU','Sent','7013F0000004b3nQAA','0033F00000Luj3PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbRQAU','Sent','7013F0000004b3nQAA','0033F00000Luj3QQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbSQAU','Sent','7013F0000004b3nQAA','0033F00000Luj3UQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbTQAU','Sent','7013F0000004b3nQAA','0033F00000Luj4UQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbUQAU','Attended','7013F0000004b3nQAA','0033F00000Luj4VQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbVQAU','Attended','7013F0000004b3nQAA','0033F00000Luj4XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbWQAU','Sent','7013F0000004b3nQAA','0033F00000Luj4ZQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbXQAU','Sent','7013F0000004b3nQAA','0033F00000Luj4eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbYQAU','Sent','7013F0000004b3nQAA','0033F00000Luj4kQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbZQAU','Sent','7013F0000004b3nQAA','0033F00000Luj3eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbaQAE','Attended','7013F0000004b3nQAA','0033F00000Luj3fQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbbQAE','Sent','7013F0000004b3nQAA','0033F00000Luj3hQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbcQAE','Sent','7013F0000004b3nQAA','0033F00000Luj3pQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbdQAE','Attended','7013F0000004b3nQAA','0033F00000Luj3xQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbeQAE','Sent','7013F0000004b3nQAA','0033F00000Luj3yQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbfQAE','Sent','7013F0000004b3nQAA','0033F00000Luj40QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbgQAE','Sent','7013F0000004b3nQAA','0033F00000Luj43QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbhQAE','Sent','7013F0000004b3nQAA','0033F00000Luj45QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbiQAE','Sent','7013F0000004b3nQAA','0033F00000Luj4EQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbjQAE','Sent','7013F0000004b3nQAA','0033F00000Luj4FQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbkQAE','Sent','7013F0000004b3nQAA','0033F00000Luj3BQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DblQAE','Sent','7013F0000004b3nQAA','0033F00000Luj2CQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbmQAE','Sent','7013F0000004b3nQAA','0033F00000Luj2DQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbnQAE','Attended','7013F0000004b3nQAA','0033F00000Luj4IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DboQAE','Attended','7013F0000004b3nQAA','0033F00000Luj2IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbpQAE','Sent','7013F0000004b3nQAA','0033F00000Luj4NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbqQAE','Sent','7013F0000004b3nQAA','0033F00000Luj2NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbrQAE','Sent','7013F0000004b3nQAA','0033F00000Luj2OQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbsQAE','Sent','7013F0000004b3nQAA','0033F00000Luj4PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbtQAE','Sent','7013F0000004b3nQAA','0033F00000Luj2SQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbuQAE','Sent','7013F0000004b3nQAA','0033F00000Luj4RQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbvQAE','Sent','7013F0000004b3nQAA','0033F00000Luj4SQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbwQAE','Attended','7013F0000004b3nQAA','0033F00000Luj4gQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbxQAE','Sent','7013F0000004b3nQAA','0033F00000Luj2XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbyQAE','Sent','7013F0000004b3nQAA','0033F00000Luj2YQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DbzQAE','Sent','7013F0000004b3nQAA','0033F00000Luj2bQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc0QAE','Attended','7013F0000004b3nQAA','0033F00000Luj2dQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc1QAE','Attended','7013F0000004b3nQAA','0033F00000Luj2gQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc2QAE','Sent','7013F0000004b3nQAA','0033F00000Luj2pQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc3QAE','Sent','7013F0000004b3nQAA','0033F00000Luj2qQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc4QAE','Sent','7013F0000004b3nQAA','0033F00000Luj2uQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc5QAE','Sent','7013F0000004b3nQAA','0033F00000Luj34QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc6QAE','Sent','7013F0000004b3nQAA','0033F00000Luj36QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc8QAE','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj3IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dc9QAE','Sent','7013F0000004b3oQAA','0033F00000Luj3JQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcAQAU','Attended','7013F0000004b3oQAA','0033F00000Luj3MQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcBQAU','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj3PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcCQAU','Sent','7013F0000004b3oQAA','0033F00000Luj3QQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcDQAU','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj3UQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcEQAU','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj4UQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcFQAU','Sent','7013F0000004b3oQAA','0033F00000Luj4VQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcGQAU','Sent','7013F0000004b3oQAA','0033F00000Luj4XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcHQAU','Sent','7013F0000004b3oQAA','0033F00000Luj4ZQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcIQAU','Sent','7013F0000004b3oQAA','0033F00000Luj4eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcJQAU','Attended','7013F0000004b3oQAA','0033F00000Luj29QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcKQAU','Sent','7013F0000004b3oQAA','0033F00000Luj4kQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcLQAU','Attended','7013F0000004b3oQAA','0033F00000Luj4lQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcMQAU','Sent','7013F0000004b3oQAA','0033F00000Luj3eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcNQAU','Sent','7013F0000004b3oQAA','0033F00000Luj3fQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcOQAU','Sent','7013F0000004b3oQAA','0033F00000Luj3hQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcPQAU','Sent','7013F0000004b3oQAA','0033F00000Luj3pQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcQQAU','Sent','7013F0000004b3oQAA','0033F00000Luj3xQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcRQAU','Sent','7013F0000004b3oQAA','0033F00000Luj3yQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcSQAU','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj40QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcTQAU','Sent','7013F0000004b3oQAA','0033F00000Luj43QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcUQAU','Sent','7013F0000004b3oQAA','0033F00000Luj45QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcVQAU','Sent','7013F0000004b3oQAA','0033F00000Luj4EQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcWQAU','Sent','7013F0000004b3oQAA','0033F00000Luj4FQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcXQAU','Sent','7013F0000004b3oQAA','0033F00000Luj3BQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcYQAU','Sent','7013F0000004b3oQAA','0033F00000Luj2CQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcZQAU','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj2DQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcaQAE','Attended','7013F0000004b3oQAA','0033F00000Luj2GQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcbQAE','Sent','7013F0000004b3oQAA','0033F00000Luj4IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DccQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcdQAE','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj4NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DceQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcfQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2OQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcgQAE','Sent','7013F0000004b3oQAA','0033F00000Luj4PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DchQAE','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj2SQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DciQAE','Sent','7013F0000004b3oQAA','0033F00000Luj4RQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcjQAE','Sent','7013F0000004b3oQAA','0033F00000Luj4SQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DckQAE','Sent','7013F0000004b3oQAA','0033F00000Luj4gQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DclQAE','Attended','7013F0000004b3oQAA','0033F00000Luj4hQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcmQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcnQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2YQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcoQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2bQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcpQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2dQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcqQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2gQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcrQAE','Attended','7013F0000004b3oQAA','0033F00000Luj27QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcsQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2pQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DctQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2qQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcuQAE','Sent','7013F0000004b3oQAA','0033F00000Luj2uQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcvQAE','Attended','7013F0000004b3oQAA','0033F00000Luj33QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcwQAE','Sent','7013F0000004b3oQAA','0033F00000Luj34QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcxQAE','RSVP Yes','7013F0000004b3oQAA','0033F00000Luj36QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DcyQAE','Sent','7013F0000004b3pQAA','0033F00000Luj4jQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DczQAE','Sent','7013F0000004b3pQAA','0033F00000Luj3IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd0QAE','Sent','7013F0000004b3pQAA','0033F00000Luj3JQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd1QAE','Sent','7013F0000004b3pQAA','0033F00000Luj3PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd2QAE','Sent','7013F0000004b3pQAA','0033F00000Luj3QQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd3QAE','Sent','7013F0000004b3pQAA','0033F00000Luj3UQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd4QAE','Sent','7013F0000004b3pQAA','0033F00000Luj4UQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd5QAE','Sent','7013F0000004b3pQAA','0033F00000Luj4VQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd6QAE','Sent','7013F0000004b3pQAA','0033F00000Luj4XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd7QAE','Attended','7013F0000004b3pQAA','0033F00000Luj4ZQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd8QAE','Sent','7013F0000004b3pQAA','0033F00000Luj4eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039Dd9QAE','Sent','7013F0000004b3pQAA','0033F00000Luj4kQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdAQAU','Sent','7013F0000004b3pQAA','0033F00000Luj3eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdBQAU','Sent','7013F0000004b3pQAA','0033F00000Luj3fQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdCQAU','Attended','7013F0000004b3pQAA','0033F00000Luj3hQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdDQAU','Sent','7013F0000004b3pQAA','0033F00000Luj3pQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdEQAU','Sent','7013F0000004b3pQAA','0033F00000Luj3xQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdFQAU','Attended','7013F0000004b3pQAA','0033F00000Luj3yQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdGQAU','Sent','7013F0000004b3pQAA','0033F00000Luj40QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdHQAU','Sent','7013F0000004b3pQAA','0033F00000Luj43QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdIQAU','Sent','7013F0000004b3pQAA','0033F00000Luj45QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdJQAU','Sent','7013F0000004b3pQAA','0033F00000Luj4EQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdKQAU','Sent','7013F0000004b3pQAA','0033F00000Luj4FQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdLQAU','Sent','7013F0000004b3pQAA','0033F00000Luj3BQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdMQAU','Sent','7013F0000004b3pQAA','0033F00000Luj2CQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdNQAU','Sent','7013F0000004b3pQAA','0033F00000Luj2DQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdOQAU','Sent','7013F0000004b3pQAA','0033F00000Luj4IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdPQAU','Sent','7013F0000004b3pQAA','0033F00000Luj2IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdQQAU','Sent','7013F0000004b3pQAA','0033F00000Luj4NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdRQAU','Sent','7013F0000004b3pQAA','0033F00000Luj2NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdSQAU','Sent','7013F0000004b3pQAA','0033F00000Luj2OQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdTQAU','Attended','7013F0000004b3pQAA','0033F00000Luj4PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdUQAU','Sent','7013F0000004b3pQAA','0033F00000Luj2SQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdVQAU','Sent','7013F0000004b3pQAA','0033F00000Luj4RQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdWQAU','Sent','7013F0000004b3pQAA','0033F00000Luj4SQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdXQAU','Sent','7013F0000004b3pQAA','0033F00000Luj4gQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdYQAU','Sent','7013F0000004b3pQAA','0033F00000Luj2XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdZQAU','Sent','7013F0000004b3pQAA','0033F00000Luj2YQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdaQAE','Sent','7013F0000004b3pQAA','0033F00000Luj2bQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdbQAE','Sent','7013F0000004b3pQAA','0033F00000Luj2dQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdcQAE','Sent','7013F0000004b3pQAA','0033F00000Luj2gQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DddQAE','Attended','7013F0000004b3pQAA','0033F00000Luj2pQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdeQAE','Sent','7013F0000004b3pQAA','0033F00000Luj2qQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdfQAE','Sent','7013F0000004b3pQAA','0033F00000Luj2uQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdgQAE','Sent','7013F0000004b3pQAA','0033F00000Luj34QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdhQAE','Sent','7013F0000004b3pQAA','0033F00000Luj36QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdiQAE','Attended','7013F0000004b3qQAA','0033F00000Luj4jQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdjQAE','RSVP Yes','7013F0000004b3qQAA','0033F00000Luj3IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdkQAE','RSVP Yes','7013F0000004b3qQAA','0033F00000Luj3JQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdlQAE','Sent','7013F0000004b3qQAA','0033F00000Luj3PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdmQAE','Sent','7013F0000004b3qQAA','0033F00000Luj3QQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdnQAE','Sent','7013F0000004b3qQAA','0033F00000Luj3UQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdoQAE','Sent','7013F0000004b3qQAA','0033F00000Luj4UQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdpQAE','Sent','7013F0000004b3qQAA','0033F00000Luj4VQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdqQAE','Sent','7013F0000004b3qQAA','0033F00000Luj4XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdrQAE','Attended','7013F0000004b3qQAA','0033F00000Luj4ZQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdsQAE','Attended','7013F0000004b3qQAA','0033F00000Luj4eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdtQAE','RSVP Yes','7013F0000004b3qQAA','0033F00000Luj4kQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DduQAE','RSVP Yes','7013F0000004b3qQAA','0033F00000Luj3eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdvQAE','RSVP Yes','7013F0000004b3qQAA','0033F00000Luj3fQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdwQAE','RSVP Yes','7013F0000004b3qQAA','0033F00000Luj3hQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdxQAE','Sent','7013F0000004b3qQAA','0033F00000Luj3pQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdyQAE','Sent','7013F0000004b3qQAA','0033F00000Luj3xQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DdzQAE','Sent','7013F0000004b3qQAA','0033F00000Luj3yQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De0QAE','Sent','7013F0000004b3qQAA','0033F00000Luj40QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De1QAE','Sent','7013F0000004b3qQAA','0033F00000Luj43QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De2QAE','Sent','7013F0000004b3qQAA','0033F00000Luj45QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De3QAE','Sent','7013F0000004b3qQAA','0033F00000Luj4EQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De4QAE','Sent','7013F0000004b3qQAA','0033F00000Luj4FQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De5QAE','Sent','7013F0000004b3qQAA','0033F00000Luj3BQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De6QAE','Sent','7013F0000004b3qQAA','0033F00000Luj2CQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De7QAE','Sent','7013F0000004b3qQAA','0033F00000Luj2DQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De8QAE','Sent','7013F0000004b3qQAA','0033F00000Luj4IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039De9QAE','Sent','7013F0000004b3qQAA','0033F00000Luj2IQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeAQAU','Sent','7013F0000004b3qQAA','0033F00000Luj4NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeBQAU','Sent','7013F0000004b3qQAA','0033F00000Luj2NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeCQAU','Sent','7013F0000004b3qQAA','0033F00000Luj2OQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeDQAU','Sent','7013F0000004b3qQAA','0033F00000Luj4PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeEQAU','Sent','7013F0000004b3qQAA','0033F00000Luj2SQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeFQAU','Sent','7013F0000004b3qQAA','0033F00000Luj4RQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeGQAU','Sent','7013F0000004b3qQAA','0033F00000Luj4SQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeHQAU','Sent','7013F0000004b3qQAA','0033F00000Luj4gQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeIQAU','Attended','7013F0000004b3qQAA','0033F00000Luj2XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeJQAU','Attended','7013F0000004b3qQAA','0033F00000Luj2YQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeKQAU','Attended','7013F0000004b3qQAA','0033F00000Luj2bQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeLQAU','Attended','7013F0000004b3qQAA','0033F00000Luj2dQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeMQAU','RSVP Yes','7013F0000004b3qQAA','0033F00000Luj2gQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeNQAU','RSVP Yes','7013F0000004b3qQAA','0033F00000Luj2pQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeOQAU','Attended','7013F0000004b3qQAA','0033F00000Luj2qQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DePQAU','Attended','7013F0000004b3qQAA','0033F00000Luj2uQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeQQAU','Sent','7013F0000004b3qQAA','0033F00000Luj34QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeRQAU','Attended','7013F0000004b3qQAA','0033F00000Luj36QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeSQAU','Responded','7013F0000004b3hQAA','0033F00000Luj27QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeTQAU','Responded','7013F0000004b3iQAA','0033F00000Luj29QAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeUQAU','Responded','7013F0000004b3gQAA','0033F00000Luj2BQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeVQAU','Responded','7013F0000004b3gQAA','0033F00000Luj2EQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeWQAU','Responded','7013F0000004b3cQAA','0033F00000Luj2OQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeXQAU','Responded','7013F0000004b3cQAA','0033F00000Luj2QQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeYQAU','Responded','7013F0000004b3dQAA','0033F00000Luj2YQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeZQAU','Responded','7013F0000004b3dQAA','0033F00000Luj2cQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeaQAE','Responded','7013F0000004b3hQAA','0033F00000Luj2fQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DebQAE','Responded','7013F0000004b3hQAA','0033F00000Luj2jQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DecQAE','Responded','7013F0000004b3hQAA','0033F00000Luj3FQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DedQAE','Responded','7013F0000004b3gQAA','0033F00000Luj3HQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeeQAE','Responded','7013F0000004b3cQAA','0033F00000Luj3KQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DefQAE','Responded','7013F0000004b3gQAA','0033F00000Luj3JQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DegQAE','Responded','7013F0000004b3gQAA','0033F00000Luj3QQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DehQAE','Responded','7013F0000004b3gQAA','0033F00000Luj3VQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeiQAE','Responded','7013F0000004b3iQAA','0033F00000Luj3eQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DejQAE','Responded','7013F0000004b3iQAA','0033F00000Luj3iQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DekQAE','Responded','7013F0000004b3gQAA','0033F00000Luj4DQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DelQAE','Responded','7013F0000004b3cQAA','0033F00000Luj4GQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DemQAE','Responded','7013F0000004b3cQAA','0033F00000Luj4LQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DenQAE','Responded','7013F0000004b3iQAA','0033F00000Luj4KQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeoQAE','Responded','7013F0000004b3iQAA','0033F00000Luj4NQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DepQAE','Responded','7013F0000004b3dQAA','0033F00000Luj4PQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeqQAE','Responded','7013F0000004b3dQAA','0033F00000Luj4RQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DerQAE','Responded','7013F0000004b3dQAA','0033F00000Luj4TQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DesQAE','Responded','7013F0000004b3gQAA','0033F00000Luj4XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DetQAE','Responded','7013F0000004b3iQAA','0033F00000Luj4XQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeuQAE','Responded','7013F0000004b3iQAA','0033F00000Luj4ZQAR');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DevQAE','Responded','7013F0000004b3iQAA','0033F00000Luj4bQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DewQAE','Responded','7013F0000004b3iQAA','0033F00000Luj4dQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DexQAE','Responded','7013F0000004b3iQAA','0033F00000Luj4fQAB');
INSERT INTO "CampaignMember" VALUES('00v3F0000039DeyQAE','Responded','7013F0000004b3dQAA','0033F00000Luj4hQAB');
CREATE TABLE "CampaignMemberStatus" (
	sf_id VARCHAR(255) NOT NULL, 
	"HasResponded" VARCHAR(255), 
	"IsDefault" VARCHAR(255), 
	"Label" VARCHAR(255), 
	campaign_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);

INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvivUAA','true','false','RSVP Yes','7013F0000004b3nQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xviwUAA','false','false','Cancelled','7013F0000004b3nQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvixUAA','false','false','No Show','7013F0000004b3nQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xviyUAA','true','false','Attended','7013F0000004b3nQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvizUAA','false','false','RSVP No','7013F0000004b3nQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj0UAA','false','false','RSVP No','7013F0000004b3oQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj1UAA','true','false','RSVP Yes','7013F0000004b3oQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj2UAA','false','false','No Show','7013F0000004b3oQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj3UAA','true','false','Attended','7013F0000004b3oQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj4UAA','false','false','Cancelled','7013F0000004b3oQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj5UAA','false','false','RSVP No','7013F0000004b3pQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj6UAA','true','false','Attended','7013F0000004b3pQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj7UAA','false','false','Cancelled','7013F0000004b3pQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj8UAA','false','false','No Show','7013F0000004b3pQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvj9UAA','true','false','RSVP Yes','7013F0000004b3pQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvjAUAQ','false','false','Cancelled','7013F0000004b3qQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvjBUAQ','false','false','RSVP No','7013F0000004b3qQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvjCUAQ','false','false','No Show','7013F0000004b3qQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvjDUAQ','false','false','RSVP Yes','7013F0000004b3qQAA');
INSERT INTO "CampaignMemberStatus" VALUES('01Y3F000000xvjEUAQ','true','false','Attended','7013F0000004b3qQAA');
CREATE TABLE "Case" (
	sf_id VARCHAR(255) NOT NULL, 
	"IsEscalated" VARCHAR(255), 
	"Subject" VARCHAR(255), 
	"Status" VARCHAR(255), 
	"Origin" VARCHAR(255), 
	"Type" VARCHAR(255), 
	"Priority" VARCHAR(255), 
	"Description" VARCHAR(255), 
	account_id VARCHAR(255), 
	contact_id VARCHAR(255), 
	parent_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "Case" VALUES('5003F000006LWfiQAG','false','Household goods needed','New','Phone','Problem','Medium','Alex needs household goods for herself and Daniel as they prepare to move to their new home.','0013F00000U8YYoQAN','0033F00000Luj4FQAR','');
CREATE TABLE "Contact" (
	sf_id VARCHAR(255) NOT NULL, 
	"FirstName" VARCHAR(255), 
	"LastName" VARCHAR(255), 
	"DoNotCall" VARCHAR(255), 
	"Gender__c" VARCHAR(255), 
	"MailingStreet" VARCHAR(255), 
	"MailingCity" VARCHAR(255), 
	"MailingState" VARCHAR(255), 
	"MailingCountry" VARCHAR(255), 
	"MailingPostalCode" VARCHAR(255), 
	"HasOptedOutOfEmail" VARCHAR(255), 
	"HasOptedOutOfFax" VARCHAR(255), 
	"npe01__AlternateEmail__c" VARCHAR(255), 
	"npe01__HomeEmail__c" VARCHAR(255), 
	"npe01__PreferredPhone__c" VARCHAR(255), 
	"npe01__Preferred_Email__c" VARCHAR(255), 
	"npe01__Primary_Address_Type__c" VARCHAR(255), 
	"npe01__Private__c" VARCHAR(255), 
	"npe01__Secondary_Address_Type__c" VARCHAR(255), 
	"npe01__SystemAccountProcessor__c" VARCHAR(255), 
	"npe01__WorkEmail__c" VARCHAR(255), 
	"npe01__WorkPhone__c" VARCHAR(255), 
	"npo02__AverageAmount__c" VARCHAR(255), 
	"npo02__Best_Gift_Year_Total__c" VARCHAR(255), 
	"npo02__Best_Gift_Year__c" VARCHAR(255), 
	"npo02__FirstCloseDate__c" VARCHAR(255), 
	"npo02__Household_Naming_Order__c" VARCHAR(255), 
	"npo02__LargestAmount__c" VARCHAR(255), 
	"npo02__LastCloseDate__c" VARCHAR(255), 
	"npo02__LastMembershipAmount__c" VARCHAR(255), 
	"npo02__LastMembershipDate__c" VARCHAR(255), 
	"npo02__LastMembershipLevel__c" VARCHAR(255), 
	"npo02__LastMembershipOrigin__c" VARCHAR(255), 
	"npo02__LastOppAmount__c" VARCHAR(255), 
	"npo02__MembershipEndDate__c" VARCHAR(255), 
	"npo02__MembershipJoinDate__c" VARCHAR(255), 
	"npo02__Naming_Exclusions__c" VARCHAR(255), 
	"npo02__NumberOfClosedOpps__c" VARCHAR(255), 
	"npo02__NumberOfMembershipOpps__c" VARCHAR(255), 
	"npo02__OppAmount2YearsAgo__c" VARCHAR(255), 
	"npo02__OppAmountLastNDays__c" VARCHAR(255), 
	"npo02__OppAmountLastYear__c" VARCHAR(255), 
	"npo02__OppAmountThisYear__c" VARCHAR(255), 
	"npo02__OppsClosed2YearsAgo__c" VARCHAR(255), 
	"npo02__OppsClosedLastNDays__c" VARCHAR(255), 
	"npo02__OppsClosedLastYear__c" VARCHAR(255), 
	"npo02__OppsClosedThisYear__c" VARCHAR(255), 
	"npo02__SmallestAmount__c" VARCHAR(255), 
	"npo02__Soft_Credit_Last_Year__c" VARCHAR(255), 
	"npo02__Soft_Credit_This_Year__c" VARCHAR(255), 
	"npo02__Soft_Credit_Total__c" VARCHAR(255), 
	"npo02__Soft_Credit_Two_Years_Ago__c" VARCHAR(255), 
	"npo02__SystemHouseholdProcessor__c" VARCHAR(255), 
	"npo02__TotalMembershipOppAmount__c" VARCHAR(255), 
	"npo02__TotalOppAmount__c" VARCHAR(255), 
	"npsp__Deceased__c" VARCHAR(255), 
	"npsp__Do_Not_Contact__c" VARCHAR(255), 
	"npsp__Exclude_from_Household_Formal_Greeting__c" VARCHAR(255), 
	"npsp__Exclude_from_Household_Informal_Greeting__c" VARCHAR(255), 
	"npsp__Exclude_from_Household_Name__c" VARCHAR(255), 
	"npsp__First_Soft_Credit_Amount__c" VARCHAR(255), 
	"npsp__First_Soft_Credit_Date__c" VARCHAR(255), 
	"npsp__Largest_Soft_Credit_Amount__c" VARCHAR(255), 
	"npsp__Largest_Soft_Credit_Date__c" VARCHAR(255), 
	"npsp__Last_Soft_Credit_Amount__c" VARCHAR(255), 
	"npsp__Last_Soft_Credit_Date__c" VARCHAR(255), 
	"npsp__Number_of_Soft_Credits_Last_N_Days__c" VARCHAR(255), 
	"npsp__Number_of_Soft_Credits_Last_Year__c" VARCHAR(255), 
	"npsp__Number_of_Soft_Credits_This_Year__c" VARCHAR(255), 
	"npsp__Number_of_Soft_Credits_Two_Years_Ago__c" VARCHAR(255), 
	"npsp__Number_of_Soft_Credits__c" VARCHAR(255), 
	"npsp__Soft_Credit_Last_N_Days__c" VARCHAR(255), 
	"npsp__is_Address_Override__c" VARCHAR(255), 
	account_id VARCHAR(255), 
	giving_level__c VARCHAR(255), 
	previous_giving_level__c VARCHAR(255), 
	reports_to_id VARCHAR(255), 
	npo02__household__c VARCHAR(255), 
	npsp__batch__c VARCHAR(255), 
	npsp__current_address__c VARCHAR(255), 
	npsp__primary_affiliation__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "Contact" VALUES('0033F00000Luj26QAB','Pavlina','Dominico','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','pavlut@lutes.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','12500.0','12500.0','0.0','','0.0','0.0','false','false','false','false','false','12500.0','2019-05-07','12500.0','2019-05-07','12500.0','2019-05-07','1.0','0.0','1.0','0.0','1.0','12500.0','false','0013F00000U8YX0QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQusUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj27QAB','Em','Dominico','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','emdom23@snailmail.com','Home','Personal','Home','false','','','','','12500.0','12500.0','2019','2019-05-07','','12500.0','2019-05-07','12500.0','2019-05-07','','','12500.0','','','','1.0','1.0','0.0','12500.0','0.0','12500.0','0.0','1.0','0.0','1.0','12500.0','','','','','','12500.0','12500.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YX0QAN','a0d3F000001WSpNQAW','','','','','a0L3F000002fQusUAE','0013F00000U8YYYQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj28QAB','Sheridan','Luther','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','pavlut@lutes.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','10000.0','10000.0','0.0','','0.0','0.0','false','false','false','false','false','10000.0','2019-08-27','10000.0','2019-08-27','10000.0','2019-08-27','1.0','0.0','1.0','0.0','1.0','10000.0','false','0013F00000U8YX1QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQutUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj29QAB','Sarah','Dominika','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','emdom@snailmail.com','Home','Personal','Home','false','','','','','10000.0','10000.0','2019','2019-08-27','','10000.0','2019-08-27','10000.0','2019-08-27','','','10000.0','','','','1.0','1.0','0.0','10000.0','0.0','10000.0','0.0','1.0','0.0','1.0','10000.0','','','','','','10000.0','10000.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YX1QAN','a0d3F000001WSpNQAW','','','','','a0L3F000002fQutUAE','0013F00000U8YYYQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2AQAR','Jon','Nguyen','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','jon@mendoza.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','0.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2018-04-20','125.0','2018-04-20','125.0','2018-04-20','0.0','1.0','0.0','0.0','1.0','0.0','false','0013F00000U8YXLQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuuUAE','0013F00000U8YYmQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2BQAR','Nilza','Hernandez','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','nilza51@mendoza.com','Home','Personal','Home','false','','','','','125.0','125.0','2018','2018-04-20','','125.0','2018-04-20','125.0','2018-04-20','','','125.0','','','','1.0','1.0','0.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXLQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQuuUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2CQAR','Lonnie','Bace','false','','10 Ocean Parkway','Brooklyn','NY','','2317','false','false','','lonnie@bruce.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXMQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuvUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2DQAR','Robert','Bace','false','','10 Ocean Parkway','Brooklyn','NY','','2317','false','false','','robert7@bruce.com','Home','Work','Home','false','','','robertbruce@oranges.com','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXMQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuvUAE','0013F00000U8YYVQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2EQAR','Geetika','Ivans','false','','','','','','','false','false','','candy25@evansfam.com','Home','Personal','','false','','','','','125.0','125.0','2018','2018-11-05','','125.0','2018-11-05','125.0','2018-11-05','','','125.0','','','','1.0','1.0','0.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXNQA3','a0d3F000001WSpOQAW','','','','','','0013F00000U8YYSQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2FQAR','Henry','Nyugen','false','','1172 Boylston St.','Boston','MA','','2199','false','false','','henry55@ng.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXOQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuwUAE','0013F00000U8YXIQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2GQAR','Felicity','Offermans','false','','1172 Boylston St.','Boston','MA','','2199','false','false','','felicia@ng.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXOQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuwUAE','0013F00000U8YX5QAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2HQAR','Elias','Whitley','false','','1 Cherry Street','Pleasant','NJ','','7777','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXPQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuxUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2IQAR','Caroline','Smythe','false','','1 Cherry Street','Pleasant','NJ','','7777','false','false','','smith71@smith.com','Home','Work','Home','false','','','carolines@orangetree.org','(922) 298-8282','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXPQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuxUAE','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2JQAR','Orion','Unnur','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXQQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuyUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2KQAR','Georgia','Beethavent','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','hildielovesfrank67@schuberts.com','Work','Work','Home','false','','','hildiebakes@bakery.net','(202) 756-9723','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXQQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuyUAE','0013F00000U8YXCQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2LQAR','Stapleton','Mavis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXRQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuzUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2MQAR','Nelda','Mavis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','neldaddavis17@cuvox.de','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXRQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQuzUAE','0013F00000U8YX5QAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2NQAR','Deborah','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','deborahmnavarro@cuvox.de','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-01-02','75.0','2019-01-02','75.0','2019-01-02','1.0','0.0','1.0','0.0','1.0','75.0','false','0013F00000U8YXSQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv0UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2OQAR','Edith','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','daphnecbainter3@teleworm.us','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-02','','75.0','2019-01-02','75.0','2019-01-02','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXSQA3','a0d3F000001WSpQQAW','','','','','a0L3F000002fQv0UAE','0013F00000U8YXIQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2PQAR','Olivia','Tan','false','','4270 4th Court','Arlington','MA','','2128','false','false','','chipboat@chippy.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-01-22','75.0','2019-01-22','75.0','2019-01-22','1.0','0.0','1.0','0.0','1.0','75.0','false','0013F00000U8YXTQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv1UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2QQAR','Patrick','Orange','false','','4270 4th Court','Arlington','MA','','2128','false','false','','cardinal65@chippy.com','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-22','','75.0','2019-01-22','75.0','2019-01-22','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXTQA3','a0d3F000001WSpQQAW','','','','','a0L3F000002fQv1UAE','0013F00000U8YYTQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2RQAR','Neve','Wong','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXUQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv2UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2SQAR','Sufjan','Vakil','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','sieffre75@hitchens.com','Mobile','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXUQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv2UAE','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2TQAR','Charlotte','Rudddles','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXVQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv3UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2UQAR','Lara','Rudddles','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','lara.yudes85@hitchens.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXVQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv3UAE','0013F00000U8YXIQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2VQAR','Nitika','Wong','false','','37179 Bedford Shores St','Fairfield','KS','','62223','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXWQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv4UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2WQAR','Eliza','Jackson','false','','37179 Bedford Shores St','Fairfield','KS','','62223','false','false','','taneshaep77@taconet.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXWQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv4UAE','0013F00000U8YXKQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2XQAR','Kallistrate','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-05-09','75.0','2019-05-09','75.0','2019-05-09','1.0','0.0','1.0','0.0','1.0','75.0','false','0013F00000U8YXXQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv5UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2YQAR','Mattia','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','rosebud1@meetsaround.com','Work','Work','Home','false','','','','(202) 909-9999','75.0','75.0','2019','2019-05-09','','75.0','2019-05-09','75.0','2019-05-09','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXXQA3','a0d3F000001WSpQQAW','','','','','a0L3F000002fQv5UAE','0013F00000U8YYaQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2ZQAR','Nancy','Primoz','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXYQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv6UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2aQAB','Irma','O''Shea','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','irmaosull57@sullyhouse.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXYQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv6UAE','0013F00000U8YX6QAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2bQAB','Maya','Geiser-Bann','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','babsgeiger@happydogs.net','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','30.0','30.0','0.0','','0.0','0.0','false','false','false','false','false','30.0','2019-05-11','30.0','2019-05-11','30.0','2019-05-11','1.0','0.0','1.0','0.0','1.0','30.0','false','0013F00000U8YXZQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv7UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2cQAB','Bennett','Geiser-Bann','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','maratgeier33@goregens.edu','Home','Personal','Home','false','','','','','30.0','30.0','2019','2019-05-11','','30.0','2019-05-11','30.0','2019-05-11','','','30.0','','','','1.0','1.0','0.0','30.0','0.0','30.0','0.0','1.0','0.0','1.0','30.0','','','','','','30.0','30.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXZQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv7UAE','0013F00000U8YYbQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2dQAB','Bryce','Nazarian','false','','840 Mount Street','Bay City','MI','','48706','false','false','','brycemwhitley@cuvox.de','Mobile','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXaQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv8UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2eQAB','Danny','Clerr','false','','840 Mount Street','Bay City','MI','','48706','false','false','','dannyvmayo47@rhyta.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXaQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv8UAE','0013F00000U8YYWQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2fQAB','Sehar','Ivans','false','','','','','','','false','false','','candy27@evansfam.com','Home','Personal','','false','','','','','75.0','75.0','2018','2018-11-04','','75.0','2018-11-04','75.0','2018-11-04','','','75.0','','','','1.0','1.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXbQAN','a0d3F000001WSpQQAW','','','','','','0013F00000U8YYSQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2gQAB','Calvin','Ivans','false','','','','','','','false','false','','rich@evansfam.com','Home','Personal','','false','','','rich@ballooga.com','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXcQAN','','a0d3F000001WSpQQAW','','','','','');
INSERT INTO "Contact" VALUES('0033F00000Luj2hQAB','Lakshmi','Ivans','false','','','','','','','false','false','','candy29@evansfam.com','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXcQAN','','a0d3F000001WSpQQAW','','','','','0013F00000U8YYSQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2iQAB','Linda','Figueroo','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','linda@nguyen.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXdQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv9UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj2jQAB','Roger','Figueroo','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','josefigleaf31@gmail.com','Home','Work','Home','false','','','jfigueroa@glicks.com','(222) 898-2002','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXdQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQv9UAE','0013F00000U8YYSQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2kQAB','Harold','Campagna','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','georgie@campaigns.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXeQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvAUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj2lQAB','Tessa','Campagna','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','tessa11@campaign.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXeQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvAUAU','0013F00000U8YYXQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2mQAB','Helena','Clerk','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXfQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvBUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj2nQAB','Deandre','Clerk','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','deandre13@blast.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXfQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvBUAU','0013F00000U8YYiQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2oQAB','Xiao-yu','Kanban','false','','2459 44th St E','Reston','VA','','71013','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXgQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvCUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj2pQAB','Heidi','Kanban','false','','2459 44th St E','Reston','VA','','71013','false','false','','azarel15@kanban.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXgQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvCUAU','0013F00000U8YYgQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2qQAB','Louis','Primordial','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXhQAN','','a0d3F000001WSpQQAW','','','','','0013F00000U8YYnQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2rQAB','Lois','Primordial','false','','','','','','','false','false','','lois19@devine.com','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXhQAN','','a0d3F000001WSpQQAW','','','','','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj2sQAB','Suhani','Djyradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','suhanitan@snailmail.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXiQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvDUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj2tQAB','Kamilla','Djyradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','kamild21@snailmail.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXiQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvDUAU','0013F00000U8YYfQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2uQAB','Roger','Kasprawicz','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXjQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvEUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj2vQAB','Luiza','Kasprawicz','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','copacetic41@cowabunga.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXjQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvEUAU','0013F00000U8YYdQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2wQAB','Nageen','Navarro','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXkQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvFUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj2xQAB','Jozef','Bateson','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','jozef45@hitchens.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXkQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvFUAU','0013F00000U8YYeQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj2yQAB','Mpho','Ng','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXlQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvGUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj2zQAB','Natali','Frasier','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','vukasinmcneill49@narnia.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXlQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvGUAU','0013F00000U8YYjQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj30QAB','Bartolomej','Oden','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXmQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvHUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj31QAB','Gabriel','Prasad','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','gabrielsphd53@atoms.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXmQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvHUAU','0013F00000U8YYkQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj32QAB','Krithika','Sokolov','false','','2493 89th Way','Seattle','WA','','98103','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXnQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvIUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj33QAB','Eleonora','Bates','false','','2493 89th Way','Seattle','WA','','98103','false','false','','eleonora61@scrumteam.net','Work','Work','Home','false','','','eleonora@scrumteam.net','(989) 777-4543','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXnQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvIUAU','0013F00000U8YYhQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj34QAB','Aldegund','Wong','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXoQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvJUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj35QAB','Mirce','Bokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','soko73@protons.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXoQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvJUAU','0013F00000U8YYjQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj36QAB','Diana','Mandela','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','dianarthomas79@superrito.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXpQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvKUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj37QAB','Crystal','Yudes','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','crystalhmudd@fleckens.hu','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXpQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvKUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj38QAB','Evrim','Watson','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','yudes@herbert.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXqQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvLUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj39QAB','Nashville','Watson','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','fionnur83@greensburg.ky.gov','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXqQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvLUAU','0013F00000U8YX5QAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3AQAR','Zach','Rymph','false','','762 Smiley','Port Townsend','WA','','98368','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','1.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXsQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvMUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3BQAR','Jessie','Nostdal','false','','762 Smiley','Port Townsend','WA','','98368','false','false','','drjessie@nostdalworks.com','Home','Personal','Home','false','','','','','0.0','','','','0.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXsQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvMUAU','0013F00000U8YYpQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3CQAR','Erica','Douglass','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXtQAN','','a0d3F000001WSpQQAW','','','','','0013F00000U8YYSQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3DQAR','Sample','Contact','false','','One Market Street','San Francisco','CA','USA','94105','false','false','sample.contact@otheremail.com','sample.contact@email.com','Work','Personal','Home','false','','','sample.contact@workemail.com','(202) 555-9654','0.0','0.0','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0013F00000U8YXvQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvNUAU','0013F00000U8YXwQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3EQAR','Linda','Nguyen','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','linda@nguyen.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXxQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvOUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3FQAR','Jose','Figueroa','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','josefigleaf@gmail.com','Home','Work','Home','false','','','jfigueroa@glicks.com','(222) 898-2002','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','350.0','350.0','0.0','','0.0','0.0','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','0.0','1.0','0.0','1.0','350.0','false','0013F00000U8YXxQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvOUAU','0013F00000U8YYSQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3GQAR','Christian','Brown','false','','4270 4th Court','Arlington','MA','','02128','false','false','','chipboat@chippy.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','0.0','50.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-22','50.0','2018-01-22','50.0','2018-01-22','0.0','1.0','0.0','0.0','1.0','0.0','false','0013F00000U8YXyQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvPUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3HQAR','Gurleen','Red','false','','4270 4th Court','Arlington','MA','','02128','false','false','','cardinal@chippy.com','Home','Personal','Home','false','','','','','50.0','50.0','2018','2018-01-22','','50.0','2018-01-22','50.0','2018-01-22','','','50.0','','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','50.0','','','','','','50.0','50.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXyQAN','a0d3F000001WSpQQAW','','','','','a0L3F000002fQvPUAU','0013F00000U8YYTQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3IQAR','Louis','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','louis@boston.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','75.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-22','75.0','2019-01-22','75.0','2019-01-22','1.0','1.0','1.0','0.0','2.0','75.0','false','0013F00000U8YXzQAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvQUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3JQAR','Celia','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','celia@boston.com','Home','Personal','Home','false','','','','(555) 555-5555','50.0','50.0','2018','2018-01-22','','50.0','2018-01-22','50.0','2018-01-22','','','50.0','','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','50.0','0.0','75.0','75.0','0.0','','50.0','50.0','false','false','false','false','false','75.0','2019-01-22','75.0','2019-01-22','75.0','2019-01-22','1.0','0.0','1.0','0.0','1.0','75.0','false','0013F00000U8YXzQAN','a0d3F000001WSpQQAW','','','','','a0L3F000002fQvQUAU','0013F00000U8YYUQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3KQAR','Celia-Rae','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','celia5@boston.com','Home','Personal','Home','false','','','','(555) 555-5555','75.0','75.0','2019','2019-01-22','','75.0','2019-01-22','75.0','2019-01-22','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXzQAN','a0d3F000001WSpQQAW','','','','','a0L3F000002fQvQUAU','0013F00000U8YYUQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3LQAR','Walter','Ng','false','','1172 Boylston St.','Boston','MA','','02199','false','false','','henry@ng.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY0QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvSUAU','0013F00000U8YXIQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3MQAR','Felicia','Ng','false','','1172 Boylston St.','Boston','MA','','02199','false','false','','felicia@ng.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY0QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvSUAU','0013F00000U8YX5QAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3NQAR','Lonnie','Bruce','false','','10 Ocean Parkway','Brooklyn','NY','','02317','false','false','','lonnie@bruce.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY1QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvTUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3OQAR','Robert','Bruce','false','','10 Ocean Parkway','Brooklyn','NY','','02317','false','false','','robert@bruce.com','Home','Work','Home','false','','','robertbruce@oranges.com','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY1QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvTUAU','0013F00000U8YYVQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3PQAR','Deborah','Navarro','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','deborahmnavarro@cuvox.de','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','0.0','50.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-02','50.0','2018-01-02','50.0','2018-01-02','0.0','1.0','0.0','0.0','1.0','0.0','false','0013F00000U8YY2QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvUUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3QQAR','Daphne','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','daphnecbainter@teleworm.us','Home','Personal','Home','false','','','','','50.0','50.0','2018','2018-01-02','','50.0','2018-01-02','50.0','2018-01-02','','','50.0','','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','50.0','','','','','','50.0','50.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY2QAN','a0d3F000001WSpQQAW','','','','','a0L3F000002fQvUUAU','0013F00000U8YXuQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3RQAR','Bryce','Whitley','false','','840 Mount Street','Bay City','MI','','48706','false','false','','brycemwhitley@cuvox.de','Mobile','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY3QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvVUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3SQAR','Chaz','Mayo','false','','840 Mount Street','Bay City','MI','','48706','false','false','','dannyvmayo@rhyta.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY3QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvVUAU','0013F00000U8YYWQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3TQAR','Nelda','Davis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','neldaddavis@cuvox.de','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY4QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvWUAU','0013F00000U8YX5QAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3UQAR','Jon','Mendoza','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','jon@mendoza.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','0.0','100.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2018-04-20','100.0','2018-04-20','100.0','2018-04-20','0.0','1.0','0.0','0.0','1.0','0.0','false','0013F00000U8YY5QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvXUAU','0013F00000U8YYmQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3VQAR','Nilza','Mendoza','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','nilza@mendoza.com','Home','Personal','Home','false','','','','','100.0','100.0','2018','2018-04-20','','100.0','2018-04-20','100.0','2018-04-20','','','100.0','','','','1.0','1.0','0.0','0.0','100.0','0.0','0.0','0.0','1.0','0.0','100.0','','','','','','100.0','100.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY5QAN','a0d3F000001WSpOQAW','','','','','a0L3F000002fQvXUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3WQAR','Zoe','Blum','false','','1 Cherry Street','Pleasant','NJ','','07777','false','false','','blum@smith.com','Home','Work','Home','false','','','carolines@orangetree.org','(922) 298-8282','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY6QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvYUAU','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3XQAR','Baptiste','Subrahmanya','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY7QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvZUAU','');
INSERT INTO "Contact" VALUES('0033F00000Luj3YQAR','Sieffre','Subrahmanya','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','sieffre@hitchens.com','Mobile','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY7QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvZUAU','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3ZQAR','Charlotte','Yudes','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY8QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvaUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3aQAB','Lara','Yudes','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','lara.yudes@hitchens.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY8QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvaUAE','0013F00000U8YXIQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3bQAB','Concepcion de Jesus','Waterman','false','','37179 Bedford Shores St','Cole City','KS','','62223','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY9QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvbUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3cQAB','Eric','Lauterborn','false','','37179 Bedford Shores St','Cole City','KS','','62223','false','false','','taneshaep@taconet.com','Home','Work','Home','false','','','lauterborn.e@colecity.gov','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YY9QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvbUAE','0013F00000U8YXrQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3dQAB','Kallistrate','Giannino','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','50.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2019-08-29','50.0','2019-08-29','50.0','2019-08-29','1.0','0.0','1.0','0.0','1.0','50.0','false','0013F00000U8YYAQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvdUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3eQAB','Mattia','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','rosebud@meetsaround.com','Work','Work','Home','false','','','','(202) 909-9999','50.0','50.0','2019','2019-08-29','','50.0','2019-08-29','50.0','2019-08-29','','','50.0','','','','1.0','1.0','0.0','50.0','0.0','50.0','0.0','1.0','0.0','1.0','50.0','','','','','','50.0','50.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYAQA3','a0d3F000001WSpQQAW','','','','','a0L3F000002fQvdUAE','0013F00000U8YYaQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3fQAB','Cassius','Guerra','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYBQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQveUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3gQAB','Irma','O''Sullivan','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','irmaosull@sullyhouse.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYBQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQveUAE','0013F00000U8YX6QAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3hQAB','Natasha','Geier','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','babsgeiger@happydogs.net','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','25.0','25.0','0.0','','0.0','0.0','false','false','false','false','false','25.0','2019-08-31','25.0','2019-08-31','25.0','2019-08-31','1.0','0.0','1.0','0.0','1.0','25.0','false','0013F00000U8YYCQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvfUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3iQAB','Marat','Geier','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','maratgeier@goregens.edu','Home','Personal','Home','false','','','','','25.0','25.0','2019','2019-08-31','','25.0','2019-08-31','25.0','2019-08-31','','','25.0','','','','1.0','1.0','0.0','25.0','0.0','25.0','0.0','1.0','0.0','1.0','25.0','','','','','','25.0','25.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYCQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvfUAE','0013F00000U8YYbQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3jQAB','Ursula','Maddox','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYDQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvgUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3kQAB','Hildie','Schubert','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','hildielovesfrank@schuberts.com','Work','Work','Home','false','','','hildiebakes@bakery.net','(202) 756-9723','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYDQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvgUAE','0013F00000U8YYcQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3lQAB','Georgie','Campaign','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','georgie@campaigns.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYEQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvhUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3mQAB','Grace','Campaign','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','tessa@campaign.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYEQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvhUAE','0013F00000U8YYXQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj3nQAB','Maia','Unnur','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','yudes@herbert.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYFQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQviUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3oQAB','Fionnghuala','Unnur','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','fionnur@greensburg.ky.gov','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYFQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQviUAE','0013F00000U8YX5QAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3pQAB','Diana','Thomas','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','dianarthomas@superrito.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYGQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvjUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3qQAB','Charlie','Gibbons','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','crystalhmudd@fleckens.hu','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYGQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvjUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3rQAB','Baron','Kovacevic','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYHQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvkUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3sQAB','Gretel','Kovacevic','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','copacetic@cowabunga.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYHQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvkUAE','0013F00000U8YYdQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3tQAB','Nageen','Zappa','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYIQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvlUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3uQAB','Jozef','Lukeson','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','jozef@hitchens.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYIQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvlUAE','0013F00000U8YYeQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3vQAB','Suhani','Tan','false','','2425 9th Ave','Madison','CA','','70134','false','false','','suhanitan@snailmail.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYJQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvmUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3wQAB','Kamil','Djuradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','kamild@snailmail.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYJQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvmUAE','0013F00000U8YYfQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3xQAB','Carol','Bi','false','','2459 44th St E','Reston','VA','','71013','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYKQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvnUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj3yQAB','Azarel','Conbon','false','','2459 44th St E','Reston','VA','','71013','false','false','','azarel@kanban.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYKQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvnUAE','0013F00000U8YYgQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj3zQAB','Deepshika','Offermans','false','','2493 89th Way','Seattle','WA','','98103','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYLQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvoUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj40QAB','Eleonora','Offermans','false','','2493 89th Way','Seattle','WA','','98103','false','false','','eleonora@scrumteam.net','Work','Work','Home','false','','','eleonora@scrumteam.net','(989) 777-4543','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYLQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvoUAE','0013F00000U8YYhQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj41QAB','Lucy','Sandeghin','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','deandre@blast.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYMQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvpUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj42QAB','Helen','Castle','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYMQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvpUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj43QAB','Aldegund','Sokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYNQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvqUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj44QAB','Solitude','Sokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','soko@protons.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYNQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvqUAE','0013F00000U8YYjQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj45QAB','Alexi','Nazarian','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYOQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvrUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj46QAB','Gabrielle','Nazarian','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','gabrielsphd@atoms.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYOQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvrUAE','0013F00000U8YYkQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj47QAB','Mpho','McNeill','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYPQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvsUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj48QAB','Vukasin','McNeill','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','vukasinmcneill@narnia.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYPQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvsUAE','0013F00000U8YYjQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj49QAB','Louis','Devine','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYQQA3','','a0d3F000001WSpQQAW','','','','','0013F00000U8YYnQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj4AQAR','Lois','Devine','false','','','','','','','false','false','','lois@devine.com','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYQQA3','','a0d3F000001WSpQQAW','','','','','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4BQAR','Sarah','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','350.0','350.0','0.0','','0.0','0.0','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','0.0','1.0','0.0','1.0','350.0','false','0013F00000U8YYRQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvtUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4CQAR','Lisa','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','350.0','350.0','0.0','','0.0','0.0','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','0.0','1.0','0.0','1.0','350.0','false','0013F00000U8YYRQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvtUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4DQAR','Robert','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','robert@myemail.com','Home','Personal','Home','false','','','ceo@myemail.com','(222) 222-2222','350.0','350.0','2019','2019-12-10','','350.0','2019-12-10','350.0','2019-12-10','','','350.0','','','','1.0','1.0','0.0','350.0','0.0','350.0','0.0','1.0','0.0','1.0','350.0','','','','','','350.0','350.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYRQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQvtUAE','0013F00000U8YYlQAN');
INSERT INTO "Contact" VALUES('0033F00000Luj4EQAR','Daniel','Baker','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','1.0','0.0','','0.0','','','','0.0','','','Household__c.Name;Household__c.Formal_Greeting__c;Household__c.Informal_Greeting__c','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','true','true','true','','','','','','','','','','','','0.0','false','0013F00000U8YYoQAN','','a0d3F000001WSpQQAW','','','','','');
INSERT INTO "Contact" VALUES('0033F00000Luj4FQAR','Alex','Ventresca','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','0.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YYoQAN','','a0d3F000001WSpQQAW','','','','','');
INSERT INTO "Contact" VALUES('0033F00000Luj4GQAR','Sampson','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim37@fleckens.hu','Home','Personal','Home','false','','','','','30.0','30.0','2019','2019-01-01','2.0','30.0','2019-01-01','30.0','2019-01-01','','','30.0','','','','1.0','1.0','0.0','30.0','0.0','30.0','0.0','1.0','0.0','1.0','30.0','0.0','175.0','175.0','0.0','','30.0','30.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','75.0','2019-01-01','2.0','0.0','2.0','0.0','2.0','175.0','false','0013F00000U8YX7QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvuUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4HQAR','Jason','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','1.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','3.0','0.0','3.0','0.0','3.0','205.0','false','0013F00000U8YX7QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvuUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4IQAR','Carly','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carly@kim.com','Home','Personal','Home','false','','','','','0.0','','','','3.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','3.0','0.0','3.0','0.0','3.0','205.0','false','0013F00000U8YX7QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvuUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4JQAR','Julie','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','kim@kim.com','Home','Personal','Home','false','','','','','0.0','','','','5.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','3.0','0.0','3.0','0.0','3.0','205.0','false','0013F00000U8YX7QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvuUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4KQAR','Mattias','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim39@fleckens.hu','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-01-01','0.0','100.0','2019-01-01','100.0','2019-01-01','','','100.0','','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','100.0','0.0','105.0','105.0','0.0','','100.0','100.0','false','false','false','false','false','30.0','2019-01-01','75.0','2019-01-01','75.0','2019-01-01','2.0','0.0','2.0','0.0','2.0','105.0','false','0013F00000U8YX7QAN','a0d3F000001WSpOQAW','','','','','a0L3F000002fQvuUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4LQAR','Grayson','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim35@fleckens.hu','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-01','4.0','75.0','2019-01-01','75.0','2019-01-01','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','0.0','130.0','130.0','0.0','','75.0','75.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','2.0','0.0','2.0','0.0','2.0','130.0','false','0013F00000U8YX7QAN','a0d3F000001WSpQQAW','','','','','a0L3F000002fQvuUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4MQAR','Brianna','Shouta','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','160.0','160.0','0.0','','0.0','0.0','false','false','false','false','false','160.0','2019-09-23','160.0','2019-09-23','160.0','2019-09-23','1.0','0.0','1.0','0.0','1.0','160.0','false','0013F00000U8YX8QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvvUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4NQAR','Llewlyn','Loki','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','ghosse59@isolationideas.info','Work','Personal','Home','false','','','','(356) 385-7489','160.0','160.0','2019','2019-09-23','','160.0','2019-09-23','160.0','2019-09-23','','','160.0','','','','1.0','1.0','0.0','160.0','0.0','160.0','0.0','1.0','0.0','1.0','160.0','','','','','','160.0','160.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YX8QAN','a0d3F000001WSpOQAW','','','','','a0L3F000002fQvvUAE','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4OQAR','Denorah','Loui','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-05-01','125.0','2019-05-01','125.0','2019-05-01','1.0','0.0','1.0','0.0','1.0','125.0','false','0013F00000U8YX9QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvwUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4PQAR','Leo','Loui','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','9alsfa7.666a43@pendokngana.gq','Home','Personal','Home','false','','','','','125.0','125.0','2019','2019-05-01','','125.0','2019-05-01','125.0','2019-05-01','','','125.0','','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YX9QAN','a0d3F000001WSpOQAW','','','','','a0L3F000002fQvwUAE','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4QQAR','Nina','Waterman','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','300.0','300.0','0.0','','0.0','0.0','false','false','false','false','false','300.0','2019-05-03','300.0','2019-05-03','300.0','2019-05-03','1.0','0.0','1.0','0.0','1.0','300.0','false','0013F00000U8YXAQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvxUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4RQAR','America','George','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','natalijas69@shouta.com','Home','Personal','Home','false','','','','','300.0','300.0','2019','2019-05-03','','300.0','2019-05-03','300.0','2019-05-03','','','300.0','','','','1.0','1.0','0.0','300.0','0.0','300.0','0.0','1.0','0.0','1.0','300.0','','','','','','300.0','300.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXAQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQvxUAE','0013F00000U8YYXQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4SQAR','Ansa','Subrahmanya','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-05-05','125.0','2019-05-05','125.0','2019-05-05','1.0','0.0','1.0','0.0','1.0','125.0','false','0013F00000U8YXBQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvyUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4TQAR','Geoff','de la O','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','jeffryp63@primoz.com','Home','Personal','Home','false','','','','','125.0','125.0','2019','2019-05-05','','125.0','2019-05-05','125.0','2019-05-05','','','125.0','','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXBQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQvyUAE','0013F00000U8YYTQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4UQAR','Julie','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','kim@kim.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','100.0','150.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','2.0','1.0','2.0','0.0','3.0','100.0','false','0013F00000U8YXDQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvzUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4VQAR','Carly','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carly@kim.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','100.0','150.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','2.0','1.0','2.0','0.0','3.0','100.0','false','0013F00000U8YXDQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvzUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4WQAR','Kevin','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','100.0','150.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','2.0','1.0','2.0','0.0','3.0','100.0','false','0013F00000U8YXDQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQvzUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4XQAR','Carl','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim@fleckens.hu','Home','Personal','Home','false','','','','','50.0','100.0','2019','2018-01-01','','75.0','2019-01-01','25.0','2019-01-01','','','25.0','','','','3.0','3.0','0.0','100.0','50.0','100.0','0.0','2.0','1.0','2.0','25.0','','','','','','150.0','150.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXDQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQvzUAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4YQAR','Leanne','Lewi','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','100.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-08-20','100.0','2019-08-20','100.0','2019-08-20','1.0','0.0','1.0','0.0','1.0','100.0','false','0013F00000U8YXEQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQw0UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4ZQAR','Tasgall','Lewi','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','9alsfa7.666a@pendokngana.gq','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-08-20','','100.0','2019-08-20','100.0','2019-08-20','','','100.0','','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','100.0','','','','','','100.0','100.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXEQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQw0UAE','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4aQAB','Brianna','Oden','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-09-23','125.0','2019-09-23','125.0','2019-09-23','1.0','0.0','1.0','0.0','1.0','125.0','false','0013F00000U8YXFQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQw1UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4bQAB','Freya','Oden','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','ghosse@isolationideas.info','Work','Personal','Home','false','','','','(356) 385-7489','125.0','125.0','2019','2019-09-23','','125.0','2019-09-23','125.0','2019-09-23','','','125.0','','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXFQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQw1UAE','0013F00000U8YXJQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4cQAB','Nina','Shouta','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','225.0','225.0','0.0','','0.0','0.0','false','false','false','false','false','225.0','2019-08-22','225.0','2019-08-22','225.0','2019-08-22','1.0','0.0','1.0','0.0','1.0','225.0','false','0013F00000U8YXGQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQw2UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4dQAB','Natalija','Shouta','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','natalijas@shouta.com','Home','Personal','Home','false','','','','','225.0','225.0','2019','2019-08-22','','225.0','2019-08-22','225.0','2019-08-22','','','225.0','','','','1.0','1.0','0.0','225.0','0.0','225.0','0.0','1.0','0.0','1.0','225.0','','','','','','225.0','225.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXGQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQw2UAE','0013F00000U8YYXQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4eQAB','Ansa','Primoz','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','100.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-08-25','100.0','2019-08-25','100.0','2019-08-25','1.0','0.0','1.0','0.0','1.0','100.0','false','0013F00000U8YXHQA3','','a0d3F000001WSpQQAW','','','','a0L3F000002fQw3UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4fQAB','Jeffry','Primoz','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','jeffryp@primoz.com','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-08-25','','100.0','2019-08-25','100.0','2019-08-25','','','100.0','','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','100.0','','','','','','100.0','100.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YXHQA3','a0d3F000001WSpOQAW','','','','','a0L3F000002fQw3UAE','0013F00000U8YYTQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4gQAB','Buddy','Zappa','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','9375.0','9375.0','0.0','','0.0','0.0','false','false','false','false','false','9375.0','2019-05-08','9375.0','2019-05-08','9375.0','2019-05-08','1.0','0.0','1.0','0.0','1.0','9375.0','false','0013F00000U8YX2QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQw4UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4hQAB','Nicolai','Trelawni','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','eugeniusthulani81@kalemail.com','Home','Personal','Home','false','','','','','9375.0','9375.0','2019','2019-05-08','','9375.0','2019-05-08','9375.0','2019-05-08','','','9375.0','','','','1.0','1.0','0.0','9375.0','0.0','9375.0','0.0','1.0','0.0','1.0','9375.0','','','','','','9375.0','9375.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YX2QAN','a0d3F000001WSpPQAW','','','','','a0L3F000002fQw4UAE','0013F00000U8YYZQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4iQAB','Bobby','Wong','false','','','','','','','false','false','','rich@evansfam.com','Home','Personal','','false','','','rich@ballooga.com','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','1083.33','3533.32','4616.65','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-11-04','833.33','2019-02-28','833.33','2019-11-30','6.0','4.0','6.0','0.0','10.0','3533.32','false','0013F00000U8YX3QAN','','a0d3F000001WSpQQAW','','','','','');
INSERT INTO "Contact" VALUES('0033F00000Luj4jQAB','Candace','Evans','false','','','','','','','false','false','','candy@evansfam.com','Home','Personal','','false','','','','','461.67','3533.32','2019','2018-11-04','','833.33','2019-11-30','833.33','2019-11-30','','','833.33','','','','10.0','10.0','0.0','3533.32','1083.33','3533.32','0.0','6.0','4.0','6.0','50.0','0.0','350.0','350.0','0.0','','4616.65','4616.65','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','0.0','1.0','0.0','1.0','350.0','false','0013F00000U8YX3QAN','a0d3F000001WSpPQAW','','','','','','0013F00000U8YYSQA3');
INSERT INTO "Contact" VALUES('0033F00000Luj4kQAB','Nudd','Abbascia','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','7500.0','7500.0','0.0','','0.0','0.0','false','false','false','false','false','7500.0','2019-08-28','7500.0','2019-08-28','7500.0','2019-08-28','1.0','0.0','1.0','0.0','1.0','7500.0','false','0013F00000U8YX4QAN','','a0d3F000001WSpQQAW','','','','a0L3F000002fQw5UAE','');
INSERT INTO "Contact" VALUES('0033F00000Luj4lQAB','Eugenius','Thulani','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','eugeniusthulani@kalemail.com','Home','Personal','Home','false','','','','','7500.0','7500.0','2019','2019-08-28','','7500.0','2019-08-28','7500.0','2019-08-28','','','7500.0','','','','1.0','1.0','0.0','7500.0','0.0','7500.0','0.0','1.0','0.0','1.0','7500.0','','','','','','7500.0','7500.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0013F00000U8YX4QAN','a0d3F000001WSpPQAW','','','','','a0L3F000002fQw5UAE','0013F00000U8YYZQA3');
CREATE TABLE "Event" (
	sf_id VARCHAR(255) NOT NULL, 
	"ActivityDate" VARCHAR(255), 
	"Description" VARCHAR(255), 
	"StartDateTime" VARCHAR(255), 
	"EndDateTime" VARCHAR(255), 
	"Subject" VARCHAR(255), 
	"Location" VARCHAR(255), 
	"WhoId" VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "Event" VALUES('00U3F000001tIErUAM','2019-11-11','Conversation to explore creating an advisory committee of major donors.','2019-11-11T17:30:00.000Z','2019-11-11T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0033F00000Luj4jQAB');
INSERT INTO "Event" VALUES('00U3F000001tIEsUAM','2019-12-13','Conversation to explore creating an advisory committee of major donors.','2019-12-13T17:30:00.000Z','2019-12-13T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0033F00000Luj29QAB');
INSERT INTO "Event" VALUES('00U3F000001tIEtUAM','2019-12-03','Conversation to explore creating an advisory committee of major donors.','2019-12-03T21:00:00.000Z','2019-12-03T22:00:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0033F00000Luj4lQAB');
INSERT INTO "Event" VALUES('00U3F000001tIEuUAM','2019-12-16','Conversation to explore creating an advisory committee of major donors.','2019-12-16T22:00:00.000Z','2019-12-16T23:00:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0033F00000Luj4hQAB');
INSERT INTO "Event" VALUES('00U3F000001tIEvUAM','2019-12-10','Conversation to explore creating an advisory committee of major donors.','2019-12-10T17:30:00.000Z','2019-12-10T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0033F00000Luj4hQAB');
INSERT INTO "Event" VALUES('00U3F000001tIEwUAM','2019-12-11','Conversation to explore creating an advisory committee of major donors.','2019-12-11T17:30:00.000Z','2019-12-11T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0033F00000Luj27QAB');
CREATE TABLE "Lead" (
	sf_id VARCHAR(255) NOT NULL, 
	"FirstName" VARCHAR(255), 
	"LastName" VARCHAR(255), 
	"Company" VARCHAR(255), 
	"DoNotCall" VARCHAR(255), 
	"HasOptedOutOfEmail" VARCHAR(255), 
	"HasOptedOutOfFax" VARCHAR(255), 
	"IsConverted" VARCHAR(255), 
	"IsUnreadByOwner" VARCHAR(255), 
	"Status" VARCHAR(255), 
	"LeadSource" VARCHAR(255), 
	"npe01__Preferred_Email__c" VARCHAR(255), 
	"npe01__Preferred_Phone__c" VARCHAR(255), 
	"npsp__CompanyCity__c" VARCHAR(255), 
	"npsp__CompanyCountry__c" VARCHAR(255), 
	"npsp__CompanyPostalCode__c" VARCHAR(255), 
	"npsp__CompanyState__c" VARCHAR(255), 
	"npsp__CompanyStreet__c" VARCHAR(255), 
	npsp__batch__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "Lead" VALUES('00Q3F000003EQoSUAW','Joshua','Kim','Self','false','false','false','false','true','Open - Not Contacted','Web','','','','','','','','');
INSERT INTO "Lead" VALUES('00Q3F000003EQoTUAW','Katie','Beaker','Self','false','false','false','false','true','Open - Not Contacted','','','','','','','','','');
INSERT INTO "Lead" VALUES('00Q3F000003EQoUUAW','Chloe','Jackson','Self','false','false','false','false','true','Open - Not Contacted','Web','','','','','','','','');
CREATE TABLE "Opportunity" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"CloseDate" VARCHAR(255), 
	"IsPrivate" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	"StageName" VARCHAR(255), 
	"Type" VARCHAR(255), 
	"Amount" VARCHAR(255), 
	"npe01__Contact_Id_for_Role__c" VARCHAR(255), 
	"npe01__Do_Not_Automatically_Create_Payment__c" VARCHAR(255), 
	"npe01__Member_Level__c" VARCHAR(255), 
	"npe01__Membership_End_Date__c" VARCHAR(255), 
	"npe01__Membership_Origin__c" VARCHAR(255), 
	"npe01__Membership_Start_Date__c" VARCHAR(255), 
	"npo02__systemHouseholdContactRoleProcessor__c" VARCHAR(255), 
	"npsp__Acknowledgment_Date__c" VARCHAR(255), 
	"npsp__Acknowledgment_Status__c" VARCHAR(255), 
	"npsp__Ask_Date__c" VARCHAR(255), 
	"npsp__Closed_Lost_Reason__c" VARCHAR(255), 
	"npsp__DisableContactRoleAutomation__c" VARCHAR(255), 
	"npsp__Fair_Market_Value__c" VARCHAR(255), 
	"npsp__Gift_Strategy__c" VARCHAR(255), 
	"npsp__Grant_Contract_Date__c" VARCHAR(255), 
	"npsp__Grant_Contract_Number__c" VARCHAR(255), 
	"npsp__Grant_Period_End_Date__c" VARCHAR(255), 
	"npsp__Grant_Period_Start_Date__c" VARCHAR(255), 
	"npsp__Grant_Program_Area_s__c" VARCHAR(255), 
	"npsp__Grant_Requirements_Website__c" VARCHAR(255), 
	"npsp__Honoree_Name__c" VARCHAR(255), 
	"npsp__In_Kind_Description__c" VARCHAR(255), 
	"npsp__In_Kind_Donor_Declared_Value__c" VARCHAR(255), 
	"npsp__In_Kind_Type__c" VARCHAR(255), 
	"npsp__Is_Grant_Renewal__c" VARCHAR(255), 
	"npsp__Matching_Gift_Employer__c" VARCHAR(255), 
	"npsp__Matching_Gift_Status__c" VARCHAR(255), 
	"npsp__Notification_Message__c" VARCHAR(255), 
	"npsp__Notification_Preference__c" VARCHAR(255), 
	"npsp__Notification_Recipient_Information__c" VARCHAR(255), 
	"npsp__Notification_Recipient_Name__c" VARCHAR(255), 
	"npsp__Primary_Contact_Campaign_Member_Status__c" VARCHAR(255), 
	"npsp__Recurring_Donation_Installment_Number__c" VARCHAR(255), 
	"npsp__Requested_Amount__c" VARCHAR(255), 
	"npsp__Tribute_Type__c" VARCHAR(255), 
	account_id VARCHAR(255), 
	campaign_id VARCHAR(255), 
	npe03__recurring_donation__c VARCHAR(255), 
	npsp__batch__c VARCHAR(255), 
	npsp__honoree_contact__c VARCHAR(255), 
	npsp__matching_gift_account__c VARCHAR(255), 
	npsp__matching_gift__c VARCHAR(255), 
	npsp__notification_recipient_contact__c VARCHAR(255), 
	npsp__previous_grant_opportunity__c VARCHAR(255), 
	npsp__primary_contact__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "Opportunity" VALUES('0063F00000ITwaIQAT','Em Dominico Major Gift 5/7/2019','2019-05-07','false','0123F000001HAaJQAW','Posted','Donation','12500.0','0032F00000Ub9FzQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YX0QAN','7013F0000004b3hQAA','','','','','','','','0033F00000Luj27QAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaJQAT','Em Dominika Donation 8/27/2019','2019-08-27','false','0123F000001HAaGQAW','Posted','Donation','10000.0','0032F00000UawOYQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YX1QAN','7013F0000004b3iQAA','','','','','','','','0033F00000Luj29QAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaKQAT','Nilza Hernandez Donation 4/20/2018','2018-04-20','false','0123F000001HAaGQAW','Posted','Donation','125.0','0032F00000Ub9FYQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXLQA3','7013F0000004b3gQAA','','','','','','','','0033F00000Luj2BQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaLQAT','Beatrice Ivans Donation 11/5/2018','2018-11-05','false','0123F000001HAaGQAW','Posted','','125.0','0032F00000Ub9FaQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXNQA3','7013F0000004b3gQAA','','','','','','','','0033F00000Luj2EQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaMQAT','Daphne Bainter Donation 1/2/2019','2019-01-02','false','0123F000001HAaGQAW','Posted','Donation','75.0','0032F00000Ub9FjQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXSQA3','7013F0000004b3cQAA','','','','','','','','0033F00000Luj2OQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaNQAT','Big Orange Donation 1/22/2019','2019-01-22','false','0123F000001HAaGQAW','Posted','Donation','75.0','0032F00000Ub9FlQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXTQA3','7013F0000004b3cQAA','','','','','','','','0033F00000Luj2QQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaOQAT','Mattia Aethelstan Donation 5/9/2019','2019-05-09','false','0123F000001HAaGQAW','Posted','Donation','75.0','0032F00000Ub9FtQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXXQA3','7013F0000004b3dQAA','','','','','','','','0033F00000Luj2YQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaPQAT','Bennett Geiser-Bann Donation 5/11/2019','2019-05-11','false','0123F000001HAaGQAW','Posted','Donation','30.0','0032F00000Ub9FvQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXZQA3','7013F0000004b3dQAA','','','','','','','','0033F00000Luj2cQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaQQAT','Beatrice Ivans Donation 11/4/2018','2018-11-04','false','0123F000001HAaGQAW','Posted','','75.0','0032F00000Ub9FxQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXbQAN','7013F0000004b3hQAA','','','','','','','','0033F00000Luj2fQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaRQAT','Roger Figueroo Major Gift 11/4/2020','2020-11-04','false','0123F000001HAaJQAW','Verbal Commitment','New Funding','375000.0','0032F00000Ub9G0QAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXdQAN','7013F0000004b3hQAA','','','','','','','','0033F00000Luj2jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaSQAT','Jose Figueroa Major Gift 11/4/2020','2020-11-04','false','0123F000001HAaJQAW','Verbal Commitment','New Funding','300000.0','0032F00000UawOGQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXxQAN','7013F0000004b3hQAA','','','','','','','','0033F00000Luj3FQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaTQAT','Big Red Donation 1/22/2018','2018-01-22','false','0123F000001HAaGQAW','Posted','Donation','50.0','0032F00000UawOHQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXyQAN','7013F0000004b3gQAA','','','','','','','','0033F00000Luj3HQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaUQAT','Celia-Rae Boston Donation 1/22/2019','2019-01-22','false','0123F000001HAaGQAW','Posted','Donation','75.0','0032F00000Ub9FkQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXzQAN','7013F0000004b3cQAA','','','','','','','','0033F00000Luj3KQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaVQAT','Celia Boston Donation 1/22/2018','2018-01-22','false','0123F000001HAaGQAW','Posted','Donation','50.0','0032F00000UawOIQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXzQAN','7013F0000004b3gQAA','','','','','','','','0033F00000Luj3JQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaWQAT','Daphne Bainter Donation 1/2/2018','2018-01-02','false','0123F000001HAaGQAW','Posted','Donation','50.0','0032F00000UawOLQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YY2QAN','7013F0000004b3gQAA','','','','','','','','0033F00000Luj3QQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaXQAT','Nilza Mendoza Donation 4/20/2018','2018-04-20','false','0123F000001HAaGQAW','Posted','Donation','100.0','0032F00000UawOOQAZ','false','','','','','All Opportunities','2018-04-20','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YY5QAN','7013F0000004b3gQAA','','','','','','','','0033F00000Luj3VQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaYQAT','Mattia Aethelstan Donation 8/29/2019','2019-08-29','false','0123F000001HAaGQAW','Posted','Donation','50.0','0032F00000UawOaQAJ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYAQA3','7013F0000004b3iQAA','','','','','','','','0033F00000Luj3eQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaZQAT','Marat Geier Donation 8/31/2019','2019-08-31','false','0123F000001HAaGQAW','Posted','Donation','25.0','0032F00000UawOcQAJ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYCQA3','7013F0000004b3iQAA','','','','','','','','0033F00000Luj3iQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaaQAD','Robert Bullard Donation 12/10/2019','2019-12-10','false','0123F000001HAaGQAW','Posted','','350.0','0032F00000UawOrQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYRQA3','7013F0000004b3gQAA','','','','','','','','0033F00000Luj4DQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwabQAD','Cloud Kicks Major Gift 11/4/2018','2018-11-04','false','0123F000001HAaJQAW','Posted','New Funding','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYSQA3','7013F0000004b3hQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwacQAD','Cloud Kicks Donation 11/4/2018','2018-11-04','false','0123F000001HAaGQAW','Posted','New Funding','1000.0','','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYSQA3','7013F0000004b3hQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwadQAD','Orange Company Donation 5/21/2018','2018-05-21','false','0123F000001HAaGQAW','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYVQA3','7013F0000004b3gQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaeQAD','Orange Company Donation 5/21/2018','2018-05-21','false','0123F000001HAaGQAW','Posted','Donation','100.0','','false','','','','','All Opportunities','2018-05-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYVQA3','7013F0000004b3gQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwafQAD','Acme Corporation Grant 6/30/2018','2018-06-30','false','0123F000001HAaHQAW','Posted','Grant','10000.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYWQA3','7013F0000004b3gQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwagQAD','Acme Corporation Grant 6/30/2018','2018-06-30','false','0123F000001HAaHQAW','Posted','Grant','12500.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYWQA3','7013F0000004b3hQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwahQAD','American Firefighters for Historic Books','2019-09-02','false','0123F000001HAaGQAW','Posted','Donation','75.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YYcQAN','7013F0000004b3iQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaiQAD','Mattias Chong Donation 1/1/2019','2019-01-01','false','0123F000001HAaGQAW','Posted','Donation','30.0','0032F00000Ub9FgQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YX7QAN','7013F0000004b3cQAA','','','','','','','','0033F00000Luj4GQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwajQAD','Mattias Chong Donation 1/1/2019','2019-01-01','false','0123F000001HAaGQAW','Posted','Donation','75.0','0032F00000Ub9FhQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YX7QAN','7013F0000004b3cQAA','','','','','','','','0033F00000Luj4LQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwakQAD','Mattias Chong Donation 1/1/2019','2019-01-01','false','0123F000001HAaGQAW','Posted','Donation','100.0','0032F00000Ub9FcQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YX7QAN','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4KQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwalQAD','Llew Loki Donation 9/23/2019','2019-09-23','false','0123F000001HAaGQAW','Posted','Donation','160.0','0032F00000Ub9FfQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YX8QAN','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4NQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwamQAD','Tasgall Loui Donation 5/1/2019','2019-05-01','false','0123F000001HAaGQAW','Posted','Donation','125.0','0032F00000Ub9FmQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YX9QAN','7013F0000004b3dQAA','','','','','','','','0033F00000Luj4PQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwanQAD','Natalija George Donation 5/3/2019','2019-05-03','false','0123F000001HAaGQAW','Posted','Donation','300.0','0032F00000Ub9FoQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXAQA3','7013F0000004b3dQAA','','','','','','','','0033F00000Luj4RQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaoQAD','Jeffry de la O Donation 5/5/2019','2019-05-05','false','0123F000001HAaGQAW','Posted','Donation','125.0','0032F00000Ub9FqQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YXBQA3','7013F0000004b3dQAA','','','','','','','','0033F00000Luj4TQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwapQAD','American Firefights for Freedom Donation 9/2/2019','2019-09-02','false','0123F000001HAaGQAW','Posted','Donation','100.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXCQA3','7013F0000004b3iQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaqQAD','Carl Kim Donation 1/1/2018','2018-01-01','false','0123F000001HAaGQAW','Posted','Donation','50.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXDQA3','7013F0000004b3gQAA','','','','','','','','0033F00000Luj4XQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwarQAD','Carl Kim Donation 1/1/2019','2019-01-01','false','0123F000001HAaGQAW','Posted','Donation','25.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXDQA3','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4XQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwasQAD','Carl Kim Donation 1/1/2019','2019-01-01','false','0123F000001HAaGQAW','Posted','Donation','75.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXDQA3','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4XQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwatQAD','Tasgall Lewi Donation 8/20/2019','2019-08-20','false','0123F000001HAaGQAW','Posted','Donation','100.0','0032F00000UawORQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXEQA3','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4ZQAR');
INSERT INTO "Opportunity" VALUES('0063F00000ITwauQAD','Llew Oden Donation 9/23/2019','2019-09-23','false','0123F000001HAaGQAW','Posted','Donation','125.0','0032F00000UawOSQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXFQA3','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4bQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwavQAD','Natalija Shouta Donation 8/22/2019','2019-08-22','false','0123F000001HAaGQAW','Posted','Donation','225.0','0032F00000UawOUQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXGQA3','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4dQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwawQAD','Jeffry Primoz Donation 8/25/2019','2019-08-25','false','0123F000001HAaGQAW','Posted','Donation','100.0','0032F00000UawOWQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXHQA3','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4fQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwaxQAD','Johnson''s General Stores Donation 5/4/2019','2019-05-04','false','0123F000001HAaGQAW','Posted','Donation','75.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXIQA3','7013F0000004b3dQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwayQAD','Johnson''s General Stores Donation 3/1/2019','2019-03-01','false','0123F000001HAaGQAW','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXIQA3','7013F0000004b3gQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwazQAD','Johnson''s General Stores Donation 3/1/2018','2018-03-01','false','0123F000001HAaGQAW','Posted','Donation','100.0','','false','','','','','All Opportunities','2018-03-10','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXIQA3','7013F0000004b3gQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb0QAD','Johnson''s General Stores Donation 8/23/2019','2019-08-23','false','0123F000001HAaGQAW','Posted','Donation','50.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXIQA3','7013F0000004b3iQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb1QAD','Orange Tree Imports Donation 5/2/2019','2019-05-02','false','0123F000001HAaGQAW','Posted','Donation','15.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXJQA3','7013F0000004b3dQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb2QAD','Orange Tree Imports Donation 8/2/2019','2019-08-02','false','0123F000001HAaGQAW','Posted','Donation','75.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXJQA3','7013F0000004b3iQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb3QAD','Orange Tree Imports Donation 8/2/2019','2019-08-02','false','0123F000001HAaGQAW','Posted','Donation','50.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXJQA3','7013F0000004b3iQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb4QAD','Orange Tree Imports Donation 8/22/2019','2019-08-22','false','0123F000001HAaGQAW','Posted','Donation','10.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXJQA3','7013F0000004b3iQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb5QAD','Gnarl''s Bicycles Donation 5/6/2019','2019-05-06','false','0123F000001HAaGQAW','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXKQA3','7013F0000004b3dQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb6QAD','Gnarl''s Bicycles Donation 8/26/2019','2019-08-26','false','0123F000001HAaGQAW','Posted','Donation','100.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YXKQA3','7013F0000004b3iQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb7QAD','Eugenius Trelawni Major Gift 5/8/2019','2019-05-08','false','0123F000001HAaJQAW','Posted','Donation','9375.0','0032F00000Ub9FsQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0013F00000U8YX2QAN','7013F0000004b3dQAA','','','','','','','','0033F00000Luj4hQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb8QAD','Candace Evans Donation 11/5/2018','2018-11-05','false','0123F000001HAaGQAW','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YX3QAN','7013F0000004b3gQAA','','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwb9QAD','Candace Evans Donation 11/4/2018','2018-11-04','false','0123F000001HAaGQAW','Posted','','50.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbAQAT','Candace Evans Donation (1 of 12) 11/30/2018','2018-11-30','false','0123F000001HAaGQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','1.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbBQAT','Candace Evans Donation (2 of 12) 2/28/2019','2019-02-28','false','0123F000001HAaGQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','2.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbCQAT','Candace Evans Donation (3 of 12) 5/31/2019','2019-05-31','false','0123F000001HAaGQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-06-02','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','3.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbDQAT','Candace Evans Donation (4 of 12) 8/31/2019','2019-08-31','false','0123F000001HAaGQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','4.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbEQAT','Candace Evans Donation (5 of 12) 11/30/2019','2019-11-30','false','0123F000001HAaGQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-11-01','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','5.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbFQAT','Candace Evans Donation (6 of 12) 2/29/2020','2020-02-29','false','0123F000001HAaGQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','6.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbGQAT','Candace Evans Donation (7 of 12) 5/31/2020','2020-05-31','false','0123F000001HAaGQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','7.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbHQAT','Candace Evans Donation (8 of 12) 8/31/2020','2020-08-31','false','0123F000001HAaGQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','8.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbIQAT','Candace Evans Donation (9 of 12) 11/30/2020','2020-11-30','false','0123F000001HAaGQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','9.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbJQAT','Candace Evans Donation (10 of 12) 2/28/2021','2021-02-28','false','0123F000001HAaGQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','10.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbKQAT','Candace Evans Donation (11 of 12) 5/31/2021','2021-05-31','false','0123F000001HAaGQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','11.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbLQAT','Candace Evans Donation (12 of 12) 8/31/2021','2021-08-31','false','0123F000001HAaGQAW','Pledged','','833.37','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','12.0','','','0013F00000U8YX3QAN','7013F0000004b3hQAA','a093F0000052NYNQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbMQAT','Candace Evans Donation (15) 2/1/2020','2020-02-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','15.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbNQAT','Candace Evans Donation (16) 3/1/2020','2020-03-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','16.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbOQAT','Candace Evans Donation (17) 4/1/2020','2020-04-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','17.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbPQAT','Candace Evans Donation (18) 5/1/2020','2020-05-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','18.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbQQAT','Candace Evans Donation (19) 6/1/2020','2020-06-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','19.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbRQAT','Candace Evans Donation (20) 7/1/2020','2020-07-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','20.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbSQAT','Candace Evans Donation (21) 8/1/2020','2020-08-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','21.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbTQAT','Candace Evans Donation (22) 9/1/2020','2020-09-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','22.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbUQAT','Candace Evans Donation (23) 10/1/2020','2020-10-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','23.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbVQAT','Candace Evans Donation (24) 11/1/2020','2020-11-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','24.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbWQAT','Candace Evans Donation (13) 12/1/2019','2019-12-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','13.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbXQAT','Candace Evans Donation (14) 1/1/2020','2020-01-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','14.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbYQAT','Candace Evans Donation (1) 12/1/2018','2018-12-01','false','0123F000001HAaGQAW','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','1.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbZQAT','Candace Evans Donation (2) 1/1/2019','2019-01-01','false','0123F000001HAaGQAW','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','2.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbaQAD','Candace Evans Donation (3) 2/1/2019','2019-02-01','false','0123F000001HAaGQAW','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','3.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbbQAD','Candace Evans Donation (4) 3/1/2019','2019-03-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','4.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbcQAD','Candace Evans Donation (5) 4/1/2019','2019-04-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','5.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbdQAD','Candace Evans Donation (6) 5/1/2019','2019-05-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','6.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbeQAD','Candace Evans Donation (7) 6/1/2019','2019-06-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','7.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbfQAD','Candace Evans Donation (8) 7/1/2019','2019-07-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','8.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbgQAD','Candace Evans Donation (9) 8/1/2019','2019-08-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','9.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbhQAD','Candace Evans Donation (10) 9/1/2019','2019-09-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','10.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbiQAD','Candace Evans Donation (11) 10/1/2019','2019-10-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','11.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbjQAD','Candace Evans Donation (12) 11/1/2019','2019-11-01','false','0123F000001HAaGQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','12.0','','','0013F00000U8YX3QAN','7013F0000004b3lQAA','a093F0000052NYOQA2','','','','','','','0033F00000Luj4jQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbkQAD','Eugenius Thulani Donation 8/28/2019','2019-08-28','false','0123F000001HAaGQAW','Posted','Donation','7500.0','0032F00000UawOZQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YX4QAN','7013F0000004b3iQAA','','','','','','','','0033F00000Luj4lQAB');
INSERT INTO "Opportunity" VALUES('0063F00000ITwblQAD','Music Foundation Major Gift 1/1/2019','2019-01-01','false','0123F000001HAaJQAW','Posted','Donation','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YX5QAN','7013F0000004b3cQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbmQAD','Music Foundation Donation 1/1/2018','2018-01-01','false','0123F000001HAaGQAW','Posted','Donation','1000.0','','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YX5QAN','7013F0000004b3gQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwbnQAD','Blotts, Hargrove and Spludge Major Gift 5/10/2019','2019-05-10','false','0123F000001HAaJQAW','Posted','Donation','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YX6QAN','7013F0000004b3dQAA','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0063F00000ITwboQAD','Blotts, Hargrove and Spludge Donation 8/30/2019','2019-08-30','false','0123F000001HAaGQAW','Posted','Donation','1000.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0013F00000U8YX6QAN','7013F0000004b3iQAA','','','','','','','','');
CREATE TABLE "Opportunity_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "Opportunity_rt_mapping" VALUES('0123F000001HAaGQAW','Donation');
INSERT INTO "Opportunity_rt_mapping" VALUES('0123F000001HAaHQAW','Grant');
INSERT INTO "Opportunity_rt_mapping" VALUES('0123F000001HAaIQAW','InKindGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0123F000001HAaJQAW','MajorGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0123F000001HAaKQAW','MatchingGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0123F000001HAaLQAW','Membership');
INSERT INTO "Opportunity_rt_mapping" VALUES('0123F000001HAR2QAO','NPSP_Default');
CREATE TABLE "OpportunityContactRole" (
	sf_id VARCHAR(255) NOT NULL,
	"opportunity_id" VARCHAR(255),
	"contact_id" VARCHAR(255),
	"Role" VARCHAR(255),
	PRIMARY KEY (sf_id)
);
INSERT INTO "OpportunityContactRole" VALUES('00K6g000000vATzEAM','0063F00000ITwacQAD','0033F00000Luj4DQAR','Soft Credit');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000000vAU0EAM','0063F00000ITwacQAD','0033F00000Luj3FQAR','Donor');
CREATE TABLE "npe01__OppPayment__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npe01__Check_Reference_Number__c" VARCHAR(255), 
	"npe01__Custom_Payment_Field__c" VARCHAR(255), 
	"npe01__Paid__c" VARCHAR(255), 
	"npe01__Payment_Amount__c" VARCHAR(255), 
	"npe01__Payment_Date__c" VARCHAR(255), 
	"npe01__Payment_Method__c" VARCHAR(255), 
	"npe01__Scheduled_Date__c" VARCHAR(255), 
	"npe01__Written_Off__c" VARCHAR(255), 
	"npsp__Payment_Acknowledged_Date__c" VARCHAR(255), 
	"npsp__Payment_Acknowledgment_Status__c" VARCHAR(255), 
	npe01__opportunity__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVeQAM','','','true','100.0','2018-11-05','Credit','','false','','','0063F00000ITwb8QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVfQAM','','','true','50.0','2018-11-04','Credit','','false','','','0063F00000ITwb9QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVgQAM','','','true','833.33','2018-11-30','','2018-11-30','false','','','0063F00000ITwbAQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVhQAM','','','true','833.33','2019-02-28','','2019-02-28','false','','','0063F00000ITwbBQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBViQAM','','','true','833.33','2019-05-31','','2019-05-31','false','','','0063F00000ITwbCQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVjQAM','','','true','833.33','2019-08-31','','2019-08-31','false','','','0063F00000ITwbDQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVkQAM','','','true','833.33','2019-11-30','','2019-11-30','false','','','0063F00000ITwbEQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVlQAM','','','false','833.33','','','2020-02-29','false','','','0063F00000ITwbFQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVmQAM','','','false','833.33','','','2020-05-31','false','','','0063F00000ITwbGQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVnQAM','','','false','833.33','','','2020-08-31','false','','','0063F00000ITwbHQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVoQAM','','','false','833.33','','','2020-11-30','false','','','0063F00000ITwbIQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVpQAM','','','false','833.33','','','2021-02-28','false','','','0063F00000ITwbJQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVqQAM','','','false','833.33','','','2021-05-31','false','','','0063F00000ITwbKQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVrQAM','','','false','833.37','','','2021-08-31','false','','','0063F00000ITwbLQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVsQAM','','','true','100.0','2018-12-01','','2018-12-01','false','','','0063F00000ITwbYQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVtQAM','','','true','100.0','2019-01-01','','2019-01-01','false','','','0063F00000ITwbZQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVuQAM','','','true','100.0','2019-02-01','','2019-02-01','false','','','0063F00000ITwbaQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVvQAM','','','false','100.0','','','2019-03-01','false','','','0063F00000ITwbbQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVwQAM','','','false','100.0','','','2019-04-01','false','','','0063F00000ITwbcQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVxQAM','','','false','100.0','','','2019-05-01','false','','','0063F00000ITwbdQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVyQAM','','','false','100.0','','','2019-06-01','false','','','0063F00000ITwbeQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBVzQAM','','','false','100.0','','','2019-07-01','false','','','0063F00000ITwbfQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW0QAM','','','false','100.0','','','2019-08-01','false','','','0063F00000ITwbgQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW1QAM','','','false','100.0','','','2019-09-01','false','','','0063F00000ITwbhQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW2QAM','','','false','100.0','','','2019-10-01','false','','','0063F00000ITwbiQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW3QAM','','','false','100.0','','','2019-11-01','false','','','0063F00000ITwbjQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW4QAM','','','false','100.0','','','2019-12-01','false','','','0063F00000ITwbWQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW5QAM','','','false','100.0','','','2020-01-01','false','','','0063F00000ITwbXQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW6QAM','','','false','100.0','','','2020-02-01','false','','','0063F00000ITwbMQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW7QAM','','','false','100.0','','','2020-03-01','false','','','0063F00000ITwbNQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW8QAM','','','false','100.0','','','2020-04-01','false','','','0063F00000ITwbOQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBW9QAM','','','false','100.0','','','2020-05-01','false','','','0063F00000ITwbPQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWAQA2','','','false','100.0','','','2020-06-01','false','','','0063F00000ITwbQQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWBQA2','','','false','100.0','','','2020-07-01','false','','','0063F00000ITwbRQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWCQA2','','','false','100.0','','','2020-08-01','false','','','0063F00000ITwbSQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWDQA2','','','false','100.0','','','2020-09-01','false','','','0063F00000ITwbTQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWEQA2','','','false','100.0','','','2020-10-01','false','','','0063F00000ITwbUQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWFQA2','','','false','100.0','','','2020-11-01','false','','','0063F00000ITwbVQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWGQA2','','','true','50000.0','2018-11-04','Credit Card','2018-11-04','false','','','0063F00000ITwaSQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWHQA2','','','false','50000.0','','Credit Card','2019-05-04','true','','','0063F00000ITwaSQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWIQA2','','','true','50000.0','2019-11-05','Credit Card','2019-11-04','false','','','0063F00000ITwaSQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWJQA2','','','false','150000.0','2019-12-04','','','true','','','0063F00000ITwaSQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWKQA2','888','','true','50.0','2018-01-22','Check','','false','','','0063F00000ITwaTQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWLQA2','888','','true','50.0','2018-01-22','Check','','false','','','0063F00000ITwaVQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWMQA2','888','','true','75.0','2019-01-22','Check','','false','','','0063F00000ITwaUQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWNQA2','342','','true','50.0','2018-01-02','Check','','false','','','0063F00000ITwaWQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWOQA2','','','true','100.0','2018-04-20','Credit','','false','','','0063F00000ITwaXQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWPQA2','39566','','true','50.0','2018-01-01','Check','','false','','','0063F00000ITwaqQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWQQA2','2294','','true','25.0','2019-01-01','Check','','false','','','0063F00000ITwarQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWRQA2','123','','true','75.0','2019-01-01','Check','','false','','','0063F00000ITwasQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWSQA2','','','true','100.0','2019-08-20','Cash','','false','','','0063F00000ITwatQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWTQA2','888','','true','125.0','2019-09-23','Check','','false','','','0063F00000ITwauQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWUQA2','','','true','225.0','2019-08-22','Credit','','false','','','0063F00000ITwavQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWVQA2','','','true','100.0','2019-08-25','Crecit','','false','','','0063F00000ITwawQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWWQA2','6226','','true','10000.0','2019-08-27','Check','','false','','','0063F00000ITwaJQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWXQA2','2294','','true','7500.0','2019-08-28','Check','','false','','','0063F00000ITwbkQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWYQA2','39566','','true','50.0','2019-08-29','Check','','false','','','0063F00000ITwaYQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWZQA2','','','true','25.0','2019-08-31','Credit','','false','','','0063F00000ITwaZQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWaQAM','','','true','350.0','2019-12-10','','','false','','','0063F00000ITwaaQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWbQAM','1001','','true','1250.0','2018-11-04','Check','','false','','','0063F00000ITwabQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWcQAM','1001','','true','1000.0','2018-11-04','Check','','false','','','0063F00000ITwacQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWdQAM','225','','true','125.0','2019-03-01','Check','','false','','','0063F00000ITwayQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWeQAM','225','','true','100.0','2018-03-01','Check','','false','','','0063F00000ITwazQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWfQAM','','','true','50.0','2019-08-23','Credit','','false','','','0063F00000ITwb0QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWgQAM','','','true','75.0','2019-05-04','Credit','','false','','','0063F00000ITwaxQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWhQAM','','','true','125.0','2018-05-21','Credit','','false','','','0063F00000ITwadQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWiQAM','','','true','100.0','2018-05-21','Credit','','false','','','0063F00000ITwaeQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWjQAM','966','','true','10000.0','2018-06-30','Check','','false','','','0063F00000ITwafQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWkQAM','966','','true','12500.0','2018-06-30','Check','','false','','','0063F00000ITwagQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWlQAM','6226','','true','1000.0','2018-01-01','Check','','false','','','0063F00000ITwbmQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWmQAM','6226','','true','1250.0','2019-01-01','Check','','false','','','0063F00000ITwblQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWnQAM','','','true','75.0','2019-08-02','Cash','','false','','','0063F00000ITwb2QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWoQAM','','','true','50.0','2019-08-02','Cash','','false','','','0063F00000ITwb3QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWpQAM','888','','true','10.0','2019-08-22','Check','','false','','','0063F00000ITwb4QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWqQAM','888','','true','15.0','2019-05-02','Check','','false','','','0063F00000ITwb1QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWrQAM','342','','true','100.0','2019-08-26','Check','','false','','','0063F00000ITwb6QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWsQAM','342','','true','125.0','2019-05-06','Check','','false','','','0063F00000ITwb5QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWtQAM','123','','true','1000.0','2019-08-30','Check','','false','','','0063F00000ITwboQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWuQAM','123','','true','1250.0','2019-05-10','Check','','false','','','0063F00000ITwbnQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWvQAM','','','true','75.0','2019-09-02','Cash','','false','','','0063F00000ITwahQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWwQAM','','','true','125.0','2018-04-20','Credit','','false','','','0063F00000ITwaKQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWxQAM','','','true','125.0','2018-11-05','Credit','','false','','','0063F00000ITwaLQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWyQAM','123','','true','100.0','2019-01-01','Check','','false','','','0063F00000ITwakQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBWzQAM','2294','','true','30.0','2019-01-01','Check','','false','','','0063F00000ITwaiQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX0QAM','39566','','true','75.0','2019-01-01','Check','','false','','','0063F00000ITwajQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX1QAM','888','','true','160.0','2019-09-23','Check','','false','','','0063F00000ITwalQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX2QAM','342','','true','75.0','2019-01-02','Check','','false','','','0063F00000ITwaMQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX3QAM','888','','true','75.0','2019-01-22','Check','','false','','','0063F00000ITwaNQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX4QAM','','','true','125.0','2019-05-01','Cash','','false','','','0063F00000ITwamQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX5QAM','','','true','300.0','2019-05-03','Credit','','false','','','0063F00000ITwanQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX6QAM','','','true','125.0','2019-05-05','Crecit','','false','','','0063F00000ITwaoQAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX7QAM','2294','','true','9375.0','2019-05-08','Check','','false','','','0063F00000ITwb7QAD');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX8QAM','39566','','true','75.0','2019-05-09','Check','','false','','','0063F00000ITwaOQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBX9QAM','','','true','30.0','2019-05-11','Credit','','false','','','0063F00000ITwaPQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBXAQA2','','','true','75.0','2018-11-04','Credit','','false','','','0063F00000ITwaQQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBXBQA2','6226','','true','12500.0','2019-05-07','Check','','false','','','0063F00000ITwaIQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBXCQA2','','','false','375000.0','','Credit','2020-11-04','false','','','0063F00000ITwaRQAT');
INSERT INTO "npe01__OppPayment__c" VALUES('a013F000004jBXDQA2','','','true','100.0','2019-09-02','Cash','','false','','','0063F00000ITwapQAD');
CREATE TABLE "npe03__Recurring_Donation__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npe03__Amount__c" VARCHAR(255), 
	"npe03__Date_Established__c" VARCHAR(255), 
	"npe03__Installment_Period__c" VARCHAR(255), 
	"npe03__Installments__c" VARCHAR(255), 
	"npe03__Last_Payment_Date__c" VARCHAR(255), 
	"npe03__Next_Payment_Date__c" VARCHAR(255), 
	"npe03__Open_Ended_Status__c" VARCHAR(255), 
	"npe03__Paid_Amount__c" VARCHAR(255), 
	"npe03__Schedule_Type__c" VARCHAR(255), 
	"npe03__Total_Paid_Installments__c" VARCHAR(255), 
	"npsp__Always_Use_Last_Day_Of_Month__c" VARCHAR(255), 
	"npsp__Day_of_Month__c" VARCHAR(255), 
	npe03__contact__c VARCHAR(255), 
	npe03__organization__c VARCHAR(255), 
	npe03__recurring_donation_campaign__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npe03__Recurring_Donation__c" VALUES('a093F0000052NYNQA2','NMH Transitional Housing Capital Campaign - Evans and Wong Household','10000.0','2018-11-05','Quarterly','12.0','2019-11-30','2020-02-29','None','4166.65','Divide By','5.0','true','30','0033F00000Luj4jQAB','','7013F0000004b3hQAA');
INSERT INTO "npe03__Recurring_Donation__c" VALUES('a093F0000052NYOQA2','Give a Life - Evans and Wong Household','100.0','2018-11-01','Monthly','1.0','2019-02-01','2019-03-01','Open','300.0','Multiply By','3.0','false','1','0033F00000Luj4jQAB','','7013F0000004b3lQAA');
CREATE TABLE "npe4__Relationship__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npe4__Description__c" VARCHAR(255), 
	"npe4__SYSTEM_SystemCreated__c" VARCHAR(255), 
	"npe4__Status__c" VARCHAR(255), 
	"npe4__Type__c" VARCHAR(255), 
	"npsp__Related_Opportunity_Contact_Role__c" VARCHAR(255), 
	npe4__contact__c VARCHAR(255), 
	npe4__reciprocal_relationship__c VARCHAR(255), 
	npe4__related_contact__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3B2UAK','Candace and Robert went to the same University.','true','Current','Friend','Solicitor','0033F00000Luj4jQAB','a0F3F000003L3BDUA0','0033F00000Luj4DQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3B3UAK','','true','Current','Friend','','0033F00000Luj3FQAR','a0F3F000003L3BEUA0','0033F00000Luj4DQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3B4UAK','','true','Current','Friend','','0033F00000Luj3HQAR','a0F3F000003L3B9UAK','0033F00000Luj4CQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3B5UAK','','true','Current','Leader','','0033F00000Luj3WQAR','a0F3F000003L3B6UAK','0033F00000Luj3qQAB');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3B6UAK','','false','Current','Member','','0033F00000Luj3qQAB','a0F3F000003L3B5UAK','0033F00000Luj3WQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3B7UAK','','true','Current','Friend','','0033F00000Luj3tQAB','a0F3F000003L3BAUA0','0033F00000Luj4CQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3B8UAK','','true','Current','Father','','0033F00000Luj4BQAR','a0F3F000003L3BFUA0','0033F00000Luj4DQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3B9UAK','','false','Current','Friend','','0033F00000Luj4CQAR','a0F3F000003L3B4UAK','0033F00000Luj3HQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BAUA0','','false','Current','Friend','','0033F00000Luj4CQAR','a0F3F000003L3B7UAK','0033F00000Luj3tQAB');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BBUA0','','true','Current','Husband','','0033F00000Luj4CQAR','a0F3F000003L3BGUA0','0033F00000Luj4DQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BCUA0','','false','Current','Mentee','','0033F00000Luj4CQAR','a0F3F000003L3BIUA0','0033F00000Luj4FQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BDUA0','Candace and Robert went to the same University.','false','Current','Friend','','0033F00000Luj4DQAR','a0F3F000003L3B2UAK','0033F00000Luj4jQAB');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BEUA0','','false','Current','Friend','Solicitor','0033F00000Luj4DQAR','a0F3F000003L3B3UAK','0033F00000Luj3FQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BFUA0','','false','Current','Daughter','Soft Credit','0033F00000Luj4DQAR','a0F3F000003L3B8UAK','0033F00000Luj4BQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BGUA0','','false','Current','Wife','Soft Credit','0033F00000Luj4DQAR','a0F3F000003L3BBUA0','0033F00000Luj4CQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BHUA0','','true','Current','Parent','','0033F00000Luj4EQAR','a0F3F000003L3BJUA0','0033F00000Luj4FQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BIUA0','','true','Current','Mentor','','0033F00000Luj4FQAR','a0F3F000003L3BCUA0','0033F00000Luj4CQAR');
INSERT INTO "npe4__Relationship__c" VALUES('a0F3F000003L3BJUA0','','false','Current','Son','','0033F00000Luj4FQAR','a0F3F000003L3BHUA0','0033F00000Luj4EQAR');
CREATE TABLE "npe5__Affiliation__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npe5__Description__c" VARCHAR(255), 
	"npe5__EndDate__c" VARCHAR(255), 
	"npe5__Primary__c" VARCHAR(255), 
	"npe5__Role__c" VARCHAR(255), 
	"npe5__StartDate__c" VARCHAR(255), 
	"npe5__Status__c" VARCHAR(255), 
	"npsp__Related_Opportunity_Contact_Role__c" VARCHAR(255), 
	npe5__contact__c VARCHAR(255), 
	npe5__organization__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLlUAK','','','true','CEO','2020-01-15','Current','','0033F00000Luj3DQAR','0013F00000U8YXwQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLmUAK','','','true','','2019-12-04','Current','','0033F00000Luj4jQAB','0013F00000U8YYSQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLnUAK','Graduate','','false','Alumni','1990-09-01','Former','','0033F00000Luj4jQAB','0013F00000U8YYaQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLoUAK','','','true','','2019-12-04','Current','','0033F00000Luj3FQAR','0013F00000U8YYSQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLpUAK','','','true','','2019-12-04','Current','','0033F00000Luj3HQAR','0013F00000U8YYTQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLqUAK','','','true','','2019-12-04','Current','','0033F00000Luj3JQAR','0013F00000U8YYUQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLrUAK','','','true','','2019-12-05','Current','','0033F00000Luj3KQAR','0013F00000U8YYUQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLsUAK','','','true','','2019-12-04','Current','','0033F00000Luj3LQAR','0013F00000U8YXIQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLtUAK','','','true','','2019-12-04','Current','','0033F00000Luj3MQAR','0013F00000U8YX5QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLuUAK','','','true','','2019-12-04','Current','','0033F00000Luj3OQAR','0013F00000U8YYVQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLvUAK','','','true','','2019-12-05','Current','','0033F00000Luj3QQAR','0013F00000U8YXuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLwUAK','','2019-12-05','false','','2019-12-04','Former','','0033F00000Luj3QQAR','0013F00000U8YXIQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLxUAK','','','true','','2019-12-04','Current','','0033F00000Luj3SQAR','0013F00000U8YYWQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLyUAK','','','true','','2019-12-04','Current','','0033F00000Luj3TQAR','0013F00000U8YX5QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfLzUAK','','','true','','2019-12-04','Current','','0033F00000Luj3UQAR','0013F00000U8YYmQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM0UAK','','','true','','2019-12-04','Current','','0033F00000Luj3WQAR','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM1UAK','','','true','','2019-12-04','Current','','0033F00000Luj4ZQAR','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM2UAK','','','true','','2019-12-04','Current','','0033F00000Luj4bQAB','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM3UAK','','','true','','2019-12-04','Current','','0033F00000Luj3YQAR','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM4UAK','','','true','','2019-12-04','Current','','0033F00000Luj4dQAB','0013F00000U8YYXQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM5UAK','','','true','','2019-12-04','Current','','0033F00000Luj3aQAB','0013F00000U8YXIQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM6UAK','','','true','','2019-12-04','Current','','0033F00000Luj4fQAB','0013F00000U8YYTQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM7UAK','','','true','Legislative Aide','2019-12-05','Current','','0033F00000Luj3cQAB','0013F00000U8YXrQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM8UAK','','2019-12-05','false','','2019-12-04','Former','','0033F00000Luj3cQAB','0013F00000U8YXKQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfM9UAK','','','true','','2019-12-04','Current','','0033F00000Luj29QAB','0013F00000U8YYYQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMAUA0','','','true','','2019-12-04','Current','','0033F00000Luj4lQAB','0013F00000U8YYZQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMBUA0','','','true','','2019-12-04','Current','','0033F00000Luj3eQAB','0013F00000U8YYaQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMCUA0','','','true','','2019-12-04','Current','','0033F00000Luj3gQAB','0013F00000U8YX6QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMDUA0','','','true','','2019-12-04','Current','','0033F00000Luj3iQAB','0013F00000U8YYbQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMEUA0','','','true','','2019-12-04','Current','','0033F00000Luj3kQAB','0013F00000U8YYcQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMFUA0','','','true','','2019-12-04','Current','','0033F00000Luj3mQAB','0013F00000U8YYXQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMGUA0','','','true','','2019-12-04','Current','','0033F00000Luj3oQAB','0013F00000U8YX5QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMHUA0','','','true','','2019-12-04','Current','','0033F00000Luj3sQAB','0013F00000U8YYdQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMIUA0','','','true','','2019-12-04','Current','','0033F00000Luj3uQAB','0013F00000U8YYeQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMJUA0','','','true','','2019-12-04','Current','','0033F00000Luj3wQAB','0013F00000U8YYfQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMKUA0','','','true','','2019-12-04','Current','','0033F00000Luj3yQAB','0013F00000U8YYgQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMLUA0','','','true','','2019-12-04','Current','','0033F00000Luj40QAB','0013F00000U8YYhQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMMUA0','','2019-12-05','false','','2019-12-04','Former','','0033F00000Luj41QAB','0013F00000U8YYiQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMNUA0','','','true','','2019-12-04','Current','','0033F00000Luj44QAB','0013F00000U8YYjQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMOUA0','','','true','','2019-12-04','Current','','0033F00000Luj46QAB','0013F00000U8YYkQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMPUA0','','','true','','2019-12-04','Current','','0033F00000Luj48QAB','0013F00000U8YYjQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMQUA0','','','true','','2019-12-04','Current','','0033F00000Luj4AQAR','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMRUA0','','','true','','2019-12-04','Current','','0033F00000Luj49QAB','0013F00000U8YYnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMSUA0','','','true','','2019-12-04','Current','','0033F00000Luj4DQAR','0013F00000U8YYlQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMTUA0','','','true','Employee','2016-04-07','Current','','0033F00000Luj3CQAR','0013F00000U8YYSQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMUUA0','','','true','','2019-12-05','Current','','0033F00000Luj3BQAR','0013F00000U8YYpQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMVUA0','','','true','','2019-12-05','Current','','0033F00000Luj2AQAR','0013F00000U8YYmQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMWUA0','','','true','','2019-12-05','Current','','0033F00000Luj2DQAR','0013F00000U8YYVQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMXUA0','','','true','','2019-12-05','Current','','0033F00000Luj2EQAR','0013F00000U8YYSQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMYUA0','','','true','','2019-12-05','Current','','0033F00000Luj2FQAR','0013F00000U8YXIQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMZUA0','','','true','','2019-12-05','Current','','0033F00000Luj2GQAR','0013F00000U8YX5QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMaUAK','','','true','','2019-12-05','Current','','0033F00000Luj2IQAR','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMbUAK','','','true','','2019-12-05','Current','','0033F00000Luj2KQAR','0013F00000U8YXCQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMcUAK','','','true','','2019-12-05','Current','','0033F00000Luj4NQAR','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMdUAK','','','true','','2019-12-05','Current','','0033F00000Luj2MQAR','0013F00000U8YX5QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMeUAK','','','true','','2019-12-05','Current','','0033F00000Luj2OQAR','0013F00000U8YXIQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMfUAK','','','true','','2019-12-05','Current','','0033F00000Luj2QQAR','0013F00000U8YYTQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMgUAK','','','true','','2019-12-05','Current','','0033F00000Luj4PQAR','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMhUAK','','','true','','2019-12-05','Current','','0033F00000Luj2SQAR','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMiUAK','','','true','','2019-12-05','Current','','0033F00000Luj4RQAR','0013F00000U8YYXQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMjUAK','','','true','','2019-12-05','Current','','0033F00000Luj2UQAR','0013F00000U8YXIQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMkUAK','','','true','','2019-12-05','Current','','0033F00000Luj4TQAR','0013F00000U8YYTQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMlUAK','','','true','','2019-12-05','Current','','0033F00000Luj2WQAR','0013F00000U8YXKQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMmUAK','','','true','','2019-12-05','Current','','0033F00000Luj4hQAB','0013F00000U8YYZQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMnUAK','','','true','','2019-12-05','Current','','0033F00000Luj2YQAR','0013F00000U8YYaQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMoUAK','','','true','','2019-12-05','Current','','0033F00000Luj2aQAB','0013F00000U8YX6QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMpUAK','','','true','','2019-12-05','Current','','0033F00000Luj2cQAB','0013F00000U8YYbQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMqUAK','','','true','','2019-12-05','Current','','0033F00000Luj2eQAB','0013F00000U8YYWQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMrUAK','','','true','','2019-12-05','Current','','0033F00000Luj2fQAB','0013F00000U8YYSQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMsUAK','','','true','','2019-12-05','Current','','0033F00000Luj2hQAB','0013F00000U8YYSQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMtUAK','','','true','','2019-12-05','Current','','0033F00000Luj27QAB','0013F00000U8YYYQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMuUAK','','','true','','2019-12-05','Current','','0033F00000Luj2jQAB','0013F00000U8YYSQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMvUAK','','','true','','2019-12-05','Current','','0033F00000Luj2lQAB','0013F00000U8YYXQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMwUAK','','','true','','2019-12-05','Current','','0033F00000Luj2nQAB','0013F00000U8YYiQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMxUAK','','','true','','2019-12-05','Current','','0033F00000Luj2pQAB','0013F00000U8YYgQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMyUAK','','','true','','2019-12-05','Current','','0033F00000Luj2rQAB','0013F00000U8YXJQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfMzUAK','','','true','','2019-12-05','Current','','0033F00000Luj2qQAB','0013F00000U8YYnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfN0UAK','','','true','','2019-12-05','Current','','0033F00000Luj2tQAB','0013F00000U8YYfQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfN1UAK','','','true','','2019-12-05','Current','','0033F00000Luj2vQAB','0013F00000U8YYdQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfN2UAK','','','true','','2019-12-05','Current','','0033F00000Luj2xQAB','0013F00000U8YYeQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfN3UAK','','','true','','2019-12-05','Current','','0033F00000Luj2zQAB','0013F00000U8YYjQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfN4UAK','','','true','','2019-12-05','Current','','0033F00000Luj31QAB','0013F00000U8YYkQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfN5UAK','','','true','','2019-12-05','Current','','0033F00000Luj33QAB','0013F00000U8YYhQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfN6UAK','','','true','','2019-12-05','Current','','0033F00000Luj35QAB','0013F00000U8YYjQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0G3F000003NfN7UAK','','','true','','2019-12-05','Current','','0033F00000Luj39QAB','0013F00000U8YX5QAN');
CREATE TABLE "npo02__Household__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npo02__Addressee__c" VARCHAR(255), 
	"npo02__Always_Anonymous__c" VARCHAR(255), 
	"npo02__AverageAmount__c" VARCHAR(255), 
	"npo02__Best_Gift_Year_Total__c" VARCHAR(255), 
	"npo02__Best_Gift_Year__c" VARCHAR(255), 
	"npo02__FirstCloseDate__c" VARCHAR(255), 
	"npo02__Formal_Greeting__c" VARCHAR(255), 
	"npo02__HouseholdEmail__c" VARCHAR(255), 
	"npo02__HouseholdPhone__c" VARCHAR(255), 
	"npo02__Household_ID__c" VARCHAR(255), 
	"npo02__Informal_Greeting__c" VARCHAR(255), 
	"npo02__LargestAmount__c" VARCHAR(255), 
	"npo02__LastCloseDate__c" VARCHAR(255), 
	"npo02__LastMembershipAmount__c" VARCHAR(255), 
	"npo02__LastMembershipDate__c" VARCHAR(255), 
	"npo02__LastMembershipLevel__c" VARCHAR(255), 
	"npo02__LastMembershipOrigin__c" VARCHAR(255), 
	"npo02__LastOppAmount__c" VARCHAR(255), 
	"npo02__MailingCity__c" VARCHAR(255), 
	"npo02__MailingCountry__c" VARCHAR(255), 
	"npo02__MailingPostalCode__c" VARCHAR(255), 
	"npo02__MailingState__c" VARCHAR(255), 
	"npo02__MailingStreet__c" VARCHAR(255), 
	"npo02__MembershipEndDate__c" VARCHAR(255), 
	"npo02__MembershipJoinDate__c" VARCHAR(255), 
	"npo02__NumberOfClosedOpps__c" VARCHAR(255), 
	"npo02__NumberOfMembershipOpps__c" VARCHAR(255), 
	"npo02__OppAmount2YearsAgo__c" VARCHAR(255), 
	"npo02__OppAmountLastNDays__c" VARCHAR(255), 
	"npo02__OppAmountLastYear__c" VARCHAR(255), 
	"npo02__OppAmountThisYear__c" VARCHAR(255), 
	"npo02__OppsClosed2YearsAgo__c" VARCHAR(255), 
	"npo02__OppsClosedLastNDays__c" VARCHAR(255), 
	"npo02__OppsClosedLastYear__c" VARCHAR(255), 
	"npo02__OppsClosedThisYear__c" VARCHAR(255), 
	"npo02__SYSTEM_CUSTOM_NAMING__c" VARCHAR(255), 
	"npo02__SmallestAmount__c" VARCHAR(255), 
	"npo02__TotalMembershipOppAmount__c" VARCHAR(255), 
	"npo02__TotalOppAmount__c" VARCHAR(255), 
	"npsp__Number_of_Household_Members__c" VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
CREATE TABLE "npsp__Account_Soft_Credit__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npsp__Amount__c" VARCHAR(255), 
	"npsp__Role__c" VARCHAR(255), 
	npsp__account__c VARCHAR(255), 
	npsp__opportunity__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
CREATE TABLE "npsp__Address__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npsp__API_Response__c" VARCHAR(255), 
	"npsp__Address_Type__c" VARCHAR(255), 
	"npsp__Administrative_Area__c" VARCHAR(255), 
	"npsp__Ambiguous__c" VARCHAR(255), 
	"npsp__Congressional_District__c" VARCHAR(255), 
	"npsp__County_Name__c" VARCHAR(255), 
	"npsp__Default_Address__c" VARCHAR(255), 
	"npsp__Latest_End_Date__c" VARCHAR(255), 
	"npsp__Latest_Start_Date__c" VARCHAR(255), 
	"npsp__MailingCity__c" VARCHAR(255), 
	"npsp__MailingCountry__c" VARCHAR(255), 
	"npsp__MailingPostalCode__c" VARCHAR(255), 
	"npsp__MailingState__c" VARCHAR(255), 
	"npsp__MailingStreet2__c" VARCHAR(255), 
	"npsp__MailingStreet__c" VARCHAR(255), 
	"npsp__Pre_Verification_Address__c" VARCHAR(255), 
	"npsp__Seasonal_End_Day__c" VARCHAR(255), 
	"npsp__Seasonal_End_Month__c" VARCHAR(255), 
	"npsp__Seasonal_Start_Day__c" VARCHAR(255), 
	"npsp__Seasonal_Start_Month__c" VARCHAR(255), 
	"npsp__State_Lower_District__c" VARCHAR(255), 
	"npsp__State_Upper_District__c" VARCHAR(255), 
	"npsp__Verification_Status__c" VARCHAR(255), 
	"npsp__Verified__c" VARCHAR(255), 
	npsp__household_account__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQusUAE','','Home','','false','','','true','','2020-01-08','Greenville','','63102','OR','','36624 Jefferson Way Way','','','','','','','','','false','0013F00000U8YX0QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQutUAE','','Home','','false','','','true','','2020-01-08','Greenville','','63102','OR','','36624 Jefferson Way Way','','','','','','','','','false','0013F00000U8YX1QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQuuUAE','','Home','','false','','','true','','2020-01-08','South San Francisco','','94044','CA','','55 Charleston','','','','','','','','','false','0013F00000U8YXLQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQuvUAE','','Home','','false','','','true','','2020-01-08','Brooklyn','','2317','NY','','10 Ocean Parkway','','','','','','','','','false','0013F00000U8YXMQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQuwUAE','','Home','','false','','','true','','2020-01-08','Boston','','2199','MA','','1172 Boylston St.','','','','','','','','','false','0013F00000U8YXOQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQuxUAE','','Home','','false','','','true','','2020-01-08','Pleasant','','7777','NJ','','1 Cherry Street','','','','','','','','','false','0013F00000U8YXPQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQuyUAE','','Home','','false','','','true','','2020-01-08','Bristol','','68376','ME','','2357 Attlee Rd','','','','','','','','','false','0013F00000U8YXQQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQuzUAE','','Home','','false','','','true','','2020-01-08','City Of Commerce','','90040','CA','','1391 Diane Street','','','','','','','','','false','0013F00000U8YXRQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv0UAE','','Home','','false','','','true','','2020-01-08','Bloomfield Township','','48302','MI','','3024 Summit Park Avenue','','','','','','','','','false','0013F00000U8YXSQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv1UAE','','Home','','false','','','true','','2020-01-08','Arlington','','2128','MA','','4270 4th Court','','','','','','','','','false','0013F00000U8YXTQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv2UAE','','Home','','false','','','true','','2020-01-08','Arlington','','57828','WA','','918 Duffield Crescent St','','','','','','','','','false','0013F00000U8YXUQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv3UAE','','Home','','false','','','true','','2020-01-08','Georgetown','','59586','ME','','8262 Phinney Ridge Rd','','','','','','','','','false','0013F00000U8YXVQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv4UAE','','Home','','false','','','true','','2020-01-08','Fairfield','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0013F00000U8YXWQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv5UAE','','Home','','false','','','true','','2020-01-08','Marion','','64860','VA','','9156 Springfield Green Dr','','','','','','','','','false','0013F00000U8YXXQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv6UAE','','Home','','false','','','true','','2020-01-08','Riverside','','65739','WV','','4578 Linda Ave','','','','','','','','','false','0013F00000U8YXYQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv7UAE','','Home','','false','','','true','','2020-01-08','Lebanon','','66618','MD','','2289 David Budd St','','','','','','','','','false','0013F00000U8YXZQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv8UAE','','Home','','false','','','true','','2020-01-08','Bay City','','48706','MI','','840 Mount Street','','','','','','','','','false','0013F00000U8YXaQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQv9UAE','','Home','','false','','','true','','2020-01-08','San Francisco','','94121','CA','','25 10th Ave.','','','','','','','','','false','0013F00000U8YXdQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvAUAU','','Home','','false','','','true','','2020-01-08','Truth or Consequences','','55191','NM','','34 Shipham Close Rd','','','','','','','','','false','0013F00000U8YXeQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvBUAU','','Home','','false','','','true','','2020-01-08','Dover','','98982','CO','','2527 Monroe Rd','','','','','','','','','false','0013F00000U8YXfQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvCUAU','','Home','','false','','','true','','2020-01-08','Reston','','71013','VA','','2459 44th St E','','','','','','','','','false','0013F00000U8YXgQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvDUAU','','Home','','false','','','true','','2020-01-08','Madison','','70134','CA','','2425 9th Ave','','','','','','','','','false','0013F00000U8YXiQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvEUAU','','Home','','false','','','true','','2020-01-08','Witchita','','67497','KS','','2323 Dent Way','','','','','','','','','false','0013F00000U8YXjQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvFUAU','','Home','','false','','','true','','2020-01-08','Salem','','69255','LA','','2391 Roborough Dr','','','','','','','','','false','0013F00000U8YXkQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvGUAU','','Home','','false','','','true','','2020-01-08','Dover','','99948','FL','','2629 Nebraska St','','','','','','','','','false','0013F00000U8YXlQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvHUAU','','Home','','false','','','true','','2020-01-08','Dover','','99948','FL','','2595 Montauk Ave W','','','','','','','','','false','0013F00000U8YXmQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvIUAU','','Home','','false','','','true','','2020-01-08','Seattle','','98103','WA','','2493 89th Way','','','','','','','','','false','0013F00000U8YXnQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvJUAU','','Home','','false','','','true','','2020-01-08','Ashland','','99861','KY','','2561 Madison Dr','','','','','','','','','false','0013F00000U8YXoQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvKUAU','','Home','','false','','','true','','2020-01-08','Springfield','','65802','MO','','726 Twin House Lane','','','','','','','','','false','0013F00000U8YXpQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvLUAU','','Home','','false','','','true','','2020-01-08','Madison','','60465','WI','','24786 Handlebar Dr N','','','','','','','','','false','0013F00000U8YXqQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvMUAU','','Home','','false','','','true','','2020-01-08','Port Townsend','','98368','WA','','762 Smiley','','','','','','','','','false','0013F00000U8YXsQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvNUAU','','Home','','false','','','true','','2020-01-08','San Francisco','USA','94105','CA','','One Market Street','','','','','','','','','false','0013F00000U8YXvQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvOUAU','','Home','','false','','','true','','2020-01-08','San Francisco','','94121','CA','','25 10th Ave.','','','','','','','','','false','0013F00000U8YXxQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvPUAU','','Home','','false','','','true','','2020-01-08','Arlington','','02128','MA','','4270 4th Court','','','','','','','','','false','0013F00000U8YXyQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvQUAU','','Home','','false','','','true','','2020-01-08','Boston','','2130','MA','','25 Boyston','','','','','','','','','false','0013F00000U8YXzQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvRUAU','','Home','','false','','','false','2019-12-05','2019-12-04','Boston','','02130','MA','','25 Boyston','','','','','','','','','false','0013F00000U8YXzQAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvSUAU','','Home','','false','','','true','','2020-01-08','Boston','','02199','MA','','1172 Boylston St.','','','','','','','','','false','0013F00000U8YY0QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvTUAU','','Home','','false','','','true','','2020-01-08','Brooklyn','','02317','NY','','10 Ocean Parkway','','','','','','','','','false','0013F00000U8YY1QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvUUAU','','Home','','false','','','true','','2020-01-08','Bloomfield Township','','48302','MI','','3024 Summit Park Avenue','','','','','','','','','false','0013F00000U8YY2QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvVUAU','','Home','','false','','','true','','2020-01-08','Bay City','','48706','MI','','840 Mount Street','','','','','','','','','false','0013F00000U8YY3QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvWUAU','','Home','','false','','','true','','2020-01-08','City Of Commerce','','90040','CA','','1391 Diane Street','','','','','','','','','false','0013F00000U8YY4QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvXUAU','','Home','','false','','','true','','2020-01-08','South San Francisco','','94044','CA','','55 Charleston','','','','','','','','','false','0013F00000U8YY5QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvYUAU','','Home','','false','','','true','','2020-01-08','Pleasant','','07777','NJ','','1 Cherry Street','','','','','','','','','false','0013F00000U8YY6QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvZUAU','','Home','','false','','','true','','2020-01-08','Arlington','','57828','WA','','918 Duffield Crescent St','','','','','','','','','false','0013F00000U8YY7QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvaUAE','','Home','','false','','','true','','2020-01-08','Georgetown','','59586','ME','','8262 Phinney Ridge Rd','','','','','','','','','false','0013F00000U8YY8QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvbUAE','','Home','','false','','','true','','2020-01-08','Cole City','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0013F00000U8YY9QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvcUAE','','Home','','false','','','false','2019-12-05','2019-12-04','Fairfield','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0013F00000U8YY9QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvdUAE','','Home','','false','','','true','','2020-01-08','Marion','','64860','VA','','9156 Springfield Green Dr','','','','','','','','','false','0013F00000U8YYAQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQveUAE','','Home','','false','','','true','','2020-01-08','Riverside','','65739','WV','','4578 Linda Ave','','','','','','','','','false','0013F00000U8YYBQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvfUAE','','Home','','false','','','true','','2020-01-08','Lebanon','','66618','MD','','2289 David Budd St','','','','','','','','','false','0013F00000U8YYCQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvgUAE','','Home','','false','','','true','','2020-01-08','Bristol','','68376','ME','','2357 Attlee Rd','','','','','','','','','false','0013F00000U8YYDQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvhUAE','','Home','','false','','','true','','2020-01-08','Truth or Consequences','','55191','NM','','34 Shipham Close Rd','','','','','','','','','false','0013F00000U8YYEQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQviUAE','','Home','','false','','','true','','2020-01-08','Madison','','60465','WI','','24786 Handlebar Dr N','','','','','','','','','false','0013F00000U8YYFQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvjUAE','','Home','','false','','','true','','2020-01-08','Springfield','','65802','MO','','726 Twin House Lane','','','','','','','','','false','0013F00000U8YYGQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvkUAE','','Home','','false','','','true','','2020-01-08','Witchita','','67497','KS','','2323 Dent Way','','','','','','','','','false','0013F00000U8YYHQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvlUAE','','Home','','false','','','true','','2020-01-08','Salem','','69255','LA','','2391 Roborough Dr','','','','','','','','','false','0013F00000U8YYIQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvmUAE','','Home','','false','','','true','','2020-01-08','Madison','','70134','CA','','2425 9th Ave','','','','','','','','','false','0013F00000U8YYJQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvnUAE','','Home','','false','','','true','','2020-01-08','Reston','','71013','VA','','2459 44th St E','','','','','','','','','false','0013F00000U8YYKQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvoUAE','','Home','','false','','','true','','2020-01-08','Seattle','','98103','WA','','2493 89th Way','','','','','','','','','false','0013F00000U8YYLQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvpUAE','','Home','','false','','','true','','2020-01-08','Dover','','98982','CO','','2527 Monroe Rd','','','','','','','','','false','0013F00000U8YYMQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvqUAE','','Home','','false','','','true','','2020-01-08','Ashland','','99861','KY','','2561 Madison Dr','','','','','','','','','false','0013F00000U8YYNQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvrUAE','','Home','','false','','','true','','2020-01-08','Dover','','99948','FL','','2595 Montauk Ave W','','','','','','','','','false','0013F00000U8YYOQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvsUAE','','Home','','false','','','true','','2020-01-08','Dover','','99948','FL','','2629 Nebraska St','','','','','','','','','false','0013F00000U8YYPQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvtUAE','','Home','','false','','','true','','2020-01-08','Buffalo','','08982','NY','','129 W 81st','','','','','','','','','false','0013F00000U8YYRQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvuUAE','','Home','','false','','','true','','2020-01-08','San Francisco','','94118','CA','','2137 Larry Street','','','','','','','','','false','0013F00000U8YX7QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvvUAE','','Home','','false','','','true','','2020-01-08','Franklin','','56949','AK','','306 Monterey Drive Ave S','','','','','','','','','false','0013F00000U8YX8QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvwUAE','','Home','','false','','','true','','2020-01-08','Burnt Corn','','56070','AL','','102 Drummand Grove Dr','','','','','','','','','false','0013F00000U8YX9QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvxUAE','','Home','','false','','','true','','2020-01-08','Chester','','58707','MA','','2754 Glamis Place Way','','','','','','','','','false','0013F00000U8YXAQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvyUAE','','Home','','false','','','true','','2020-01-08','Salem','','61344','MA','','74358 S Wycliff Ave','','','','','','','','','false','0013F00000U8YXBQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQvzUAE','','Home','','false','','','true','','2020-01-08','San Francisco','','94118','CA','','2137 Larry Street','','','','','','','','','false','0013F00000U8YXDQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQw0UAE','','Home','','false','','','true','','2020-01-08','Burnt Corn','','56070','AL','','102 Drummand Grove Dr','','','','','','','','','false','0013F00000U8YXEQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQw1UAE','','Home','','false','','','true','','2020-01-08','Franklin','','56949','AK','','306 Monterey Drive Ave S','','','','','','','','','false','0013F00000U8YXFQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQw2UAE','','Home','','false','','','true','','2020-01-08','Chester','','58707','MA','','2754 Glamis Place Way','','','','','','','','','false','0013F00000U8YXGQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQw3UAE','','Home','','false','','','true','','2020-01-08','Salem','','61344','MA','','74358 S Wycliff Ave','','','','','','','','','false','0013F00000U8YXHQA3');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQw4UAE','','Home','','false','','','true','','2020-01-08','Kingston','','63981','WA','','18312 Duchess Rd','','','','','','','','','false','0013F00000U8YX2QAN');
INSERT INTO "npsp__Address__c" VALUES('a0L3F000002fQw5UAE','','Home','','false','','','true','','2020-01-08','Kingston','','63981','WA','','18312 Duchess Rd','','','','','','','','','false','0013F00000U8YX4QAN');
CREATE TABLE "npsp__Allocation__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npsp__Amount__c" VARCHAR(255), 
	"npsp__Percent__c" VARCHAR(255), 
	npsp__campaign__c VARCHAR(255), 
	npsp__general_accounting_unit__c VARCHAR(255), 
	npsp__opportunity__c VARCHAR(255), 
	npsp__recurring_donation__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXrUAM','300000.0','100.0','','a0a3F000002p9HaQAI','0063F00000ITwaSQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXsUAM','1250.0','100.0','','a0a3F000002p9HaQAI','0063F00000ITwabQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXtUAM','1000.0','100.0','','a0a3F000002p9HaQAI','0063F00000ITwacQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXuUAM','12500.0','100.0','','a0a3F000002p9HaQAI','0063F00000ITwagQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXvUAM','75.0','100.0','','a0a3F000002p9HaQAI','0063F00000ITwaQQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXwUAM','12500.0','100.0','','a0a3F000002p9HaQAI','0063F00000ITwaIQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXxUAM','375000.0','100.0','','a0a3F000002p9HaQAI','0063F00000ITwaRQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXyUAM','','50.0','','a0a3F000002p9HbQAI','','a093F0000052NYOQA2');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQXzUAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbbQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY0UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbcQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY1UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbdQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY2UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbeQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY3UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbfQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY4UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbgQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY5UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbhQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY6UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbiQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY7UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbjQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY8UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbWQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQY9UAM','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbXQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYAUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbMQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYBUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbNQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYCUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbOQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYDUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbPQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYEUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbQQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYFUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbRQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYGUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbSQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYHUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbTQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYIUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbUQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYJUA2','50.0','50.0','','a0a3F000002p9HbQAI','0063F00000ITwbVQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYKUA2','50.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaTQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYLUA2','50.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaVQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYMUA2','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaUQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYNUA2','50.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaWQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYOUA2','100.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaXQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYPUA2','50.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaqQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYQUA2','25.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwarQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYRUA2','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwasQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYSUA2','100.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwatQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYTUA2','125.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwauQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYUUA2','225.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwavQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYVUA2','100.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwawQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYWUA2','10000.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaJQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYXUA2','7500.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwbkQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYYUA2','50.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaYQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYZUA2','25.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaZQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYaUAM','125.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwayQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYbUAM','100.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwazQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYcUAM','50.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwb0QAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYdUAM','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaxQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYeUAM','125.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwadQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYfUAM','100.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaeQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYgUAM','10000.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwafQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYhUAM','1000.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwbmQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYiUAM','1250.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwblQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYjUAM','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwb2QAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYkUAM','50.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwb3QAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYlUAM','10.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwb4QAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYmUAM','15.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwb1QAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYnUAM','100.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwb6QAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYoUAM','125.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwb5QAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYpUAM','1000.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwboQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYqUAM','1250.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwbnQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYrUAM','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwahQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYsUAM','125.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaKQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYtUAM','125.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaLQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYuUAM','100.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwakQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYvUAM','30.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaiQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYwUAM','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwajQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYxUAM','160.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwalQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYyUAM','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaMQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQYzUAM','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaNQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ0UAM','125.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwamQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ1UAM','300.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwanQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ2UAM','125.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaoQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ3UAM','9375.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwb7QAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ4UAM','75.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaOQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ5UAM','30.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwaPQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ6UAM','100.0','100.0','','a0a3F000002p9HdQAI','0063F00000ITwapQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ7UAM','','50.0','','a0a3F000002p9HfQAI','','a093F0000052NYOQA2');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ8UAM','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbbQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZ9UAM','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbcQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZAUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbdQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZBUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbeQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZCUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbfQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZDUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbgQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZEUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbhQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZFUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbiQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZGUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbjQAD','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZHUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbWQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZIUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbXQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZJUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbMQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZKUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbNQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZLUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbOQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZMUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbPQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZNUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbQQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZOUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbRQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZPUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbSQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZQUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbTQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZRUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbUQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZSUA2','50.0','50.0','','a0a3F000002p9HfQAI','0063F00000ITwbVQAT','');
INSERT INTO "npsp__Allocation__c" VALUES('a0M3F000002pQZTUA2','','100.0','7013F0000004b3hQAA','a0a3F000002p9HaQAI','','');
CREATE TABLE "npsp__Batch__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npsp__Batch_Status__c" VARCHAR(255), 
	"npsp__Description__c" VARCHAR(255), 
	"npsp__Number_of_Items__c" VARCHAR(255), 
	"npsp__Object_Name__c" VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
CREATE TABLE "npsp__Engagement_Plan_Task__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npsp__Comments__c" VARCHAR(255), 
	"npsp__Days_After__c" VARCHAR(255), 
	"npsp__Priority__c" VARCHAR(255), 
	"npsp__Reminder_Time__c" VARCHAR(255), 
	"npsp__Reminder__c" VARCHAR(255), 
	"npsp__Send_Email__c" VARCHAR(255), 
	"npsp__Status__c" VARCHAR(255), 
	"npsp__Type__c" VARCHAR(255), 
	npsp__engagement_plan_template__c VARCHAR(255), 
	npsp__parent_task__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVZUA0','Thank You Phone Call','','1.0','High','0','false','false','Not Started','Call','a0V3F0000014kIqUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVaUAK','Send Gold level packet in mail','','7.0','Normal','0','false','false','Not Started','Other','a0V3F0000014kIqUAI','a0U3F000001YhVZUA0');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVbUAK','Confirm packet received email','','5.0','Normal','0','false','false','Not Started','Email','a0V3F0000014kIqUAI','a0U3F000001YhVaUAK');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVcUAK','Follow Up Email','','30.0','High','0','false','false','Not Started','Email','a0V3F0000014kIqUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVdUAK','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0V3F0000014kIqUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVeUAK','Application Review','','1.0','High','0','false','false','Not Started','Other','a0V3F0000014kIrUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVfUAK','Approval Email','','1.0','High','0','false','false','Not Started','Email','a0V3F0000014kIrUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVgUAK','Background Check','','2.0','High','0','false','false','Not Started','Other','a0V3F0000014kIrUAI','a0U3F000001YhVfUAK');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVhUAK','Volunteer Orientation','','14.0','High','0','false','false','Not Started','Meeting','a0V3F0000014kIrUAI','a0U3F000001YhVgUAK');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhViUAK','Thank You Phone Call','','1.0','High','0','false','false','Not Started','Call','a0V3F0000014kIsUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVjUAK','Schedule Facility Tour & Lunch','','7.0','Normal','0','false','false','Not Started','Meeting','a0V3F0000014kIsUAI','a0U3F000001YhViUAK');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVkUAK','Follow Up Email','','3.0','High','0','false','false','Not Started','Email','a0V3F0000014kIsUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVlUAK','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0V3F0000014kIsUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVmUAK','Thank You Phone Call by Volunteer','Volunteer will call and thank donor within the month.','30.0','High','0','false','false','Not Started','Call','a0V3F0000014kItUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVnUAK','Send membership levels email','Send email with information about benefits of all of the membership levels.','7.0','Normal','0','false','false','Not Started','Other','a0V3F0000014kItUAI','a0U3F000001YhVmUAK');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVoUAK','Follow Up Email','','30.0','High','0','false','false','Not Started','Email','a0V3F0000014kItUAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0U3F000001YhVpUAK','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0V3F0000014kItUAI','');
CREATE TABLE "npsp__Engagement_Plan_Template__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npsp__Automatically_Update_Child_Task_Due_Date__c" VARCHAR(255), 
	"npsp__Default_Assignee__c" VARCHAR(255), 
	"npsp__Description__c" VARCHAR(255), 
	"npsp__Reschedule_To__c" VARCHAR(255), 
	"npsp__Skip_Weekends__c" VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0V3F0000014kIqUAI','Gold Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Silver to Gold level.','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0V3F0000014kIrUAI','Volunteer Onboarding','true','Owner of Object for Engagement Plan','Sample Engagement Plan Template','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0V3F0000014kIsUAI','Platinum Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Gold to Platinum level.','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0V3F0000014kItUAI','Silver Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Bronze to Silver level.','Monday','true');
CREATE TABLE "npsp__Engagement_Plan__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npsp__Completed_Tasks__c" VARCHAR(255), 
	"npsp__Total_Tasks__c" VARCHAR(255), 
	npsp__account__c VARCHAR(255), 
	npsp__campaign__c VARCHAR(255), 
	npsp__case__c VARCHAR(255), 
	npsp__contact__c VARCHAR(255), 
	npsp__engagement_plan_template__c VARCHAR(255), 
	npsp__opportunity__c VARCHAR(255), 
	npsp__recurring_donation__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDNUA0','0.0','4.0','','','','0033F00000Luj4jQAB','a0V3F0000014kIsUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDOUA0','0.0','4.0','','','','0033F00000Luj3HQAR','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDPUA0','0.0','4.0','','','','0033F00000Luj3JQAR','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDQUA0','0.0','4.0','','','','0033F00000Luj3KQAR','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDRUA0','0.0','4.0','','','','0033F00000Luj3QQAR','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDSUA0','0.0','5.0','','','','0033F00000Luj3VQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDTUA0','0.0','5.0','','','','0033F00000Luj4XQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDUUA0','0.0','5.0','','','','0033F00000Luj4ZQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDVUA0','0.0','5.0','','','','0033F00000Luj4bQAB','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDWUA0','0.0','5.0','','','','0033F00000Luj4dQAB','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDXUA0','0.0','5.0','','','','0033F00000Luj4fQAB','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDYUA0','0.0','4.0','','','','0033F00000Luj4lQAB','a0V3F0000014kIsUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDZUA0','0.0','4.0','','','','0033F00000Luj3eQAB','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDaUAK','0.0','5.0','','','','0033F00000Luj2BQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDbUAK','0.0','5.0','','','','0033F00000Luj2EQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDcUAK','0.0','4.0','','','','0033F00000Luj4LQAR','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDdUAK','0.0','5.0','','','','0033F00000Luj4KQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDeUAK','0.0','5.0','','','','0033F00000Luj4NQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDfUAK','0.0','4.0','','','','0033F00000Luj2OQAR','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDgUAK','0.0','4.0','','','','0033F00000Luj2QQAR','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDhUAK','0.0','5.0','','','','0033F00000Luj4PQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDiUAK','0.0','5.0','','','','0033F00000Luj4RQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDjUAK','0.0','5.0','','','','0033F00000Luj4TQAR','a0V3F0000014kIqUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDkUAK','0.0','4.0','','','','0033F00000Luj4hQAB','a0V3F0000014kIsUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDlUAK','0.0','4.0','','','','0033F00000Luj2YQAR','a0V3F0000014kItUAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0W3F000002MbDmUAK','0.0','4.0','','','','0033F00000Luj2fQAB','a0V3F0000014kItUAI','','');
CREATE TABLE "npsp__Fund__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
CREATE TABLE "npsp__General_Accounting_Unit__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npsp__Active__c" VARCHAR(255), 
	"npsp__Average_Allocation__c" VARCHAR(255), 
	"npsp__Description__c" VARCHAR(255), 
	"npsp__First_Allocation_Date__c" VARCHAR(255), 
	"npsp__Largest_Allocation__c" VARCHAR(255), 
	"npsp__Last_Allocation_Date__c" VARCHAR(255), 
	"npsp__Number_of_Allocations_Last_N_Days__c" VARCHAR(255), 
	"npsp__Number_of_Allocations_Last_Year__c" VARCHAR(255), 
	"npsp__Number_of_Allocations_This_Year__c" VARCHAR(255), 
	"npsp__Number_of_Allocations_Two_Years_Ago__c" VARCHAR(255), 
	"npsp__Smallest_Allocation__c" VARCHAR(255), 
	"npsp__Total_Allocations_Last_N_Days__c" VARCHAR(255), 
	"npsp__Total_Allocations_Last_Year__c" VARCHAR(255), 
	"npsp__Total_Allocations_This_Year__c" VARCHAR(255), 
	"npsp__Total_Allocations_Two_Years_Ago__c" VARCHAR(255), 
	"npsp__Total_Allocations__c" VARCHAR(255), 
	"npsp__Total_Number_of_Allocations__c" VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0a3F000002p9HaQAI','Transitional Housing Capital Campaign','true','5465.0','Transitional Housing program specific','2018-06-30','12500.0','2019-05-07','1.0','4.0','1.0','0.0','75.0','12500.0','14825.0','12500.0','0.0','27325.0','5.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0a3F000002p9HbQAI','Food Pantry Programs','true','0.0','','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0a3F000002p9HcQAI','HUD Transitional Housing Grant','true','0.0','','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0a3F000002p9HdQAI','General Fund','true','918.78','','2018-01-01','10000.0','2019-09-23','37.0','12.0','37.0','0.0','10.0','33145.0','11875.0','33145.0','0.0','45020.0','49.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0a3F000002p9HeQAI','Restricted Fund','true','0.0','','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0a3F000002p9HfQAI','Women''s Services','true','0.0','Fund for NMH annual women''s services.','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
CREATE TABLE "npsp__Grant_Deadline__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npsp__Grant_Deadline_Due_Date__c" VARCHAR(255), 
	"npsp__Grant_Deliverable_Close_Date__c" VARCHAR(255), 
	"npsp__Grant_Deliverable_Requirements__c" VARCHAR(255), 
	"npsp__Type__c" VARCHAR(255), 
	npsp__opportunity__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
CREATE TABLE "npsp__Level__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npsp__Active__c" VARCHAR(255), 
	"npsp__Description__c" VARCHAR(255), 
	"npsp__Level_Field__c" VARCHAR(255), 
	"npsp__Maximum_Amount__c" VARCHAR(255), 
	"npsp__Minimum_Amount__c" VARCHAR(255), 
	"npsp__Previous_Level_Field__c" VARCHAR(255), 
	"npsp__Source_Field__c" VARCHAR(255), 
	"npsp__Target__c" VARCHAR(255), 
	npsp__engagement_plan_template__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npsp__Level__c" VALUES('a0d3F000001WSpNQAW','Platinum','true','Our highest level.','Giving_Level__c','','10000.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','');
INSERT INTO "npsp__Level__c" VALUES('a0d3F000001WSpOQAW','Silver','true','The second level.','Giving_Level__c','1000.0','100.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0V3F0000014kIqUAI');
INSERT INTO "npsp__Level__c" VALUES('a0d3F000001WSpPQAW','Gold','true','The third level.','Giving_Level__c','10000.0','1000.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0V3F0000014kIsUAI');
INSERT INTO "npsp__Level__c" VALUES('a0d3F000001WSpQQAW','Bronze','true','The lowest entry level.','Giving_Level__c','100.0','35.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0V3F0000014kItUAI');
CREATE TABLE "npsp__Partial_Soft_Credit__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npsp__Amount__c" VARCHAR(255), 
	"npsp__Role_Name__c" VARCHAR(255), 
	npsp__contact__c VARCHAR(255), 
	npsp__opportunity__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
CREATE TABLE "npsp__Schedulable__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"npsp__Active__c" VARCHAR(255), 
	"npsp__Class_Name__c" VARCHAR(255), 
	"npsp__Frequency__c" VARCHAR(255), 
	"npsp__Last_Time_Run__c" VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
COMMIT;
