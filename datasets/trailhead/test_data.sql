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
INSERT INTO "Account" VALUES('0012F00000XttuJQAR','Hernandez and Nguyen Household','0122F000000SQwCQAW','55 Charleston','South San Francisco','CA','','94044','true','Household Account','125.0','125.0','2018','2018-04-20','Ms. Nilza Hernandez and Jon Nguyen','','Nilza and Jon','125.0','2018-04-20','125.0','2018-04-20','','','125.0','','','1.0','1.0','0.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FYQAZ','');
INSERT INTO "Account" VALUES('0012F00000XttuKQAR','Bace Household','0122F000000SQwCQAW','10 Ocean Parkway','Brooklyn','NY','','2317','true','Household Account','0.0','','','','Mr. Robert and Lonnie Bace','','Robert and Lonnie','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FZQAZ','');
INSERT INTO "Account" VALUES('0012F00000XttuLQAR','Ivans Household','0122F000000SQwCQAW','','','','','','true','Household Account','125.0','125.0','2018','2018-11-05','Ms. Geetika Ivans','','Geetika','125.0','2018-11-05','125.0','2018-11-05','','','125.0','','','1.0','1.0','0.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','1.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FaQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuMQAR','Nyugen and Offermans Household','0122F000000SQwCQAW','1172 Boylston St.','Boston','MA','','2199','true','Household Account','0.0','','','','Mr. Henry Nyugen and Felicity Offermans','','Henry and Felicity','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FbQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuNQAR','Chong Household','0122F000000SQwCQAW','2137 Larry Street','San Francisco','CA','','94118','true','Household Account','68.33','205.0','2019','2019-01-01','Mr. Mattias, Jason, Mr. Sampson, Carly, Mr. Grayson and Julie Chong','','Mattias, Jason, Sampson, Carly, Grayson and Julie','100.0','2019-01-01','75.0','2019-01-01','','','75.0','','','3.0','3.0','0.0','205.0','0.0','205.0','0.0','3.0','0.0','3.0','','30.0','205.0','205.0','','false','','','','','','false','','','','','','6.0','a0l2F000001XKCgQAO','','','0032F00000Ub9FcQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuOQAR','Smythe and Whitley Household','0122F000000SQwCQAW','1 Cherry Street','Pleasant','NJ','','7777','true','Household Account','0.0','','','','Ms. Caroline Smythe and Elias Whitley','','Caroline and Elias','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FdQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuPQAR','Beethavent and Unnur Household','0122F000000SQwCQAW','2357 Attlee Rd','Bristol','ME','','68376','true','Household Account','0.0','','','','Mrs. Georgia Beethavent and Orion Unnur','','Georgia and Orion','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FeQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuQQAR','Loki and Shouta Household','0122F000000SQwCQAW','306 Monterey Drive Ave S','Franklin','AK','','56949','true','Household Account','160.0','160.0','2019','2019-09-23','Mr. Llewlyn Loki and Brianna Shouta','','Llewlyn and Brianna','160.0','2019-09-23','160.0','2019-09-23','','','160.0','','','1.0','1.0','0.0','160.0','0.0','160.0','0.0','1.0','0.0','1.0','','160.0','160.0','160.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCgQAO','','','0032F00000Ub9FfQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuTQAR','Mavis Household','0122F000000SQwCQAW','1391 Diane Street','City Of Commerce','CA','','90040','true','Household Account','0.0','','','','Nelda and Stapleton Mavis','','Nelda and Stapleton','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FiQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuUQAR','Bainter Household','0122F000000SQwCQAW','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','true','Household Account','75.0','75.0','2019','2019-01-02','Ms Edith and Deborah Bainter','','Edith and Deborah','75.0','2019-01-02','75.0','2019-01-02','','','75.0','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FjQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuVQAR','Orange and Tan Household','0122F000000SQwCQAW','4270 4th Court','Arlington','MA','','2128','true','Household Account','75.0','75.0','2019','2019-01-22','Ms. Patrick Orange and Olivia Tan','','Patrick and Olivia','75.0','2019-01-22','75.0','2019-01-22','','','75.0','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FlQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuWQAR','Loui Household','0122F000000SQwCQAW','102 Drummand Grove Dr','Burnt Corn','AL','','56070','true','Household Account','125.0','125.0','2019','2019-05-01','Leo and Denorah Loui','','Leo and Denorah','125.0','2019-05-01','125.0','2019-05-01','','','125.0','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCgQAO','','','0032F00000Ub9FmQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuXQAR','Vakil and Wong Household','0122F000000SQwCQAW','918 Duffield Crescent St','Arlington','WA','','57828','true','Household Account','0.0','','','','Sufjan Vakil and Neve Wong','','Sufjan and Neve','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FnQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuYQAR','George and Waterman Household','0122F000000SQwCQAW','2754 Glamis Place Way','Chester','MA','','58707','true','Household Account','300.0','300.0','2019','2019-05-03','Ms. America George and Nina Waterman','','America and Nina','300.0','2019-05-03','300.0','2019-05-03','','','300.0','','','1.0','1.0','0.0','300.0','0.0','300.0','0.0','1.0','0.0','1.0','','300.0','300.0','300.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCgQAO','','','0032F00000Ub9FoQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuZQAR','Rudddles Household','0122F000000SQwCQAW','8262 Phinney Ridge Rd','Georgetown','ME','','59586','true','Household Account','0.0','','','','Ms. Lara and Charlotte Rudddles','','Lara and Charlotte','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FpQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuaQAB','de la O and Subrahmanya Household','0122F000000SQwCQAW','74358 S Wycliff Ave','Salem','MA','','61344','true','Household Account','125.0','125.0','2019','2019-05-05','Mr. Geoff de la O and Ansa Subrahmanya','','Geoff and Ansa','125.0','2019-05-05','125.0','2019-05-05','','','125.0','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCgQAO','','','0032F00000Ub9FqQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttubQAB','Jackson and Wong Household','0122F000000SQwCQAW','37179 Bedford Shores St','Fairfield','KS','','62223','true','Household Account','0.0','','','','Mrs. Eliza Jackson and Nitika Wong','','Eliza and Nitika','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FrQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttucQAB','Trelawni and Zappa Household','0122F000000SQwCQAW','18312 Duchess Rd','Kingston','WA','','63981','true','Household Account','9375.0','9375.0','2019','2019-05-08','Nicolai Trelawni and Buddy Zappa','','Nicolai and Buddy','9375.0','2019-05-08','9375.0','2019-05-08','','','9375.0','','','1.0','1.0','0.0','9375.0','0.0','9375.0','0.0','1.0','0.0','1.0','','9375.0','9375.0','9375.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKChQAO','','','0032F00000Ub9FsQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttudQAB','Aethelstan Household','0122F000000SQwCQAW','9156 Springfield Green Dr','Marion','VA','','64860','true','Household Account','75.0','75.0','2019','2019-05-09','Mattia and Kallistrate Aethelstan','','Mattia and Kallistrate','75.0','2019-05-09','75.0','2019-05-09','','','75.0','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FtQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttueQAB','O''Shea and Primoz Household','0122F000000SQwCQAW','4578 Linda Ave','Riverside','WV','','65739','true','Household Account','0.0','','','','Mrs. Irma O''Shea and Nancy Primoz','','Irma and Nancy','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FuQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttufQAB','Geiser-Bann Household','0122F000000SQwCQAW','2289 David Budd St','Lebanon','MD','','66618','true','Household Account','30.0','30.0','2019','2019-05-11','Bennett and Maya Geiser-Bann','','Bennett and Maya','30.0','2019-05-11','30.0','2019-05-11','','','30.0','','','1.0','1.0','0.0','30.0','0.0','30.0','0.0','1.0','0.0','1.0','','30.0','30.0','30.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FvQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttugQAB','Clerr and Nazarian Household','0122F000000SQwCQAW','840 Mount Street','Bay City','MI','','48706','true','Household Account','0.0','','','','Mr. Danny Clerr and Bryce Nazarian','','Danny and Bryce','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FwQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuhQAB','Ivans Household','0122F000000SQwCQAW','','','','','','true','Household Account','75.0','75.0','2018','2018-11-04','Ms. Sehar Ivans','','Sehar','75.0','2018-11-04','75.0','2018-11-04','','','75.0','','','1.0','1.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','1.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FxQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuiQAB','Ivans Household','0122F000000SQwCQAW','','','','','','true','Household Account','0.0','','','','Ms. Lakshmi and Calvin Ivans','','Lakshmi and Calvin','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9FyQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttujQAB','Dominico Household','0122F000000SQwCQAW','36624 Jefferson Way Way','Greenville','OR','','63102','true','Household Account','12500.0','12500.0','2019','2019-05-07','Ms. Em and Pavlina Dominico','','Em and Pavlina','12500.0','2019-05-07','12500.0','2019-05-07','','','12500.0','','','1.0','1.0','0.0','12500.0','0.0','12500.0','0.0','1.0','0.0','1.0','','12500.0','12500.0','12500.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCeQAO','','','0032F00000Ub9FzQAJ','');
INSERT INTO "Account" VALUES('0012F00000XttukQAB','Figueroo Household','0122F000000SQwCQAW','25 10th Ave.','San Francisco','CA','','94121','true','Household Account','0.0','','','','Mr. Roger and Linda Figueroo','','Roger and Linda','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G0QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttulQAB','Campagna Household','0122F000000SQwCQAW','34 Shipham Close Rd','Truth or Consequences','NM','','55191','true','Household Account','0.0','','','','Mrs Tessa and Harold Campagna','','Tessa and Harold','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G1QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttumQAB','Clerk Household','0122F000000SQwCQAW','2527 Monroe Rd','Dover','CO','','98982','true','Household Account','0.0','','','','Mr. Deandre and Helena Clerk','','Deandre and Helena','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G2QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttunQAB','Kanban Household','0122F000000SQwCQAW','2459 44th St E','Reston','VA','','71013','true','Household Account','0.0','','','','Heidi and Xiao-yu Kanban','','Heidi and Xiao-yu','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G3QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuoQAB','Primordial Household','0122F000000SQwCQAW','','','','','','true','Household Account','0.0','','','','Ms. Lois and Louis Primordial','','Lois and Louis','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G4QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttupQAB','Djyradj Household','0122F000000SQwCQAW','2425 9th Ave','Madison','CA','','70134','true','Household Account','0.0','','','','Kamilla and Suhani Djyradj','','Kamilla and Suhani','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G5QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuqQAB','Kasprawicz Household','0122F000000SQwCQAW','2323 Dent Way','Witchita','KS','','67497','true','Household Account','0.0','','','','Ms. Luiza and Roger Kasprawicz','','Luiza and Roger','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G6QAJ','');
INSERT INTO "Account" VALUES('0012F00000XtturQAB','Bateson and Navarro Household','0122F000000SQwCQAW','2391 Roborough Dr','Salem','LA','','69255','true','Household Account','0.0','','','','Mr. Jozef Bateson and Nageen Navarro','','Jozef and Nageen','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G7QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttusQAB','Frasier and Ng Household','0122F000000SQwCQAW','2629 Nebraska St','Dover','FL','','99948','true','Household Account','0.0','','','','Natali Frasier and Mpho Ng','','Natali and Mpho','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G8QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttutQAB','Prasad and Oden Household','0122F000000SQwCQAW','2595 Montauk Ave W','Dover','FL','','99948','true','Household Account','0.0','','','','Mr. Gabriel Prasad and Bartolomej Oden','','Gabriel and Bartolomej','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9G9QAJ','');
INSERT INTO "Account" VALUES('0012F00000XttuuQAB','Bates and Sokolov Household','0122F000000SQwCQAW','2493 89th Way','Seattle','WA','','98103','true','Household Account','0.0','','','','Ms. Eleonora Bates and Krithika Sokolov','','Eleonora and Krithika','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9GAQAZ','');
INSERT INTO "Account" VALUES('0012F00000XttuvQAB','Bokolov and Wong Household','0122F000000SQwCQAW','2561 Madison Dr','Ashland','KY','','99861','true','Household Account','0.0','','','','Mirce Bokolov and Aldegund Wong','','Mirce and Aldegund','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9GBQAZ','');
INSERT INTO "Account" VALUES('0012F00000XttuwQAB','Mandela and Yudes Household','0122F000000SQwCQAW','726 Twin House Lane','Springfield','MO','','65802','true','Household Account','0.0','','','','Miss Diana Mandela and Crystal Yudes','','Diana and Crystal','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9GCQAZ','');
INSERT INTO "Account" VALUES('0012F00000XttuxQAB','Watson Household','0122F000000SQwCQAW','24786 Handlebar Dr N','Madison','WI','','60465','true','Household Account','0.0','','','','Ms. Nashville and Evrim Watson','','Nashville and Evrim','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub9GDQAZ','');
INSERT INTO "Account" VALUES('0012F00000XttuyQAB','American Firefights for Freedom','0122F000000SQwDQAW','292 Sporting Green Pl','Charlotte','CA','','94108','false','','100.0','100.0','2019','2019-09-02','','','','100.0','2019-09-02','100.0','2019-09-02','','','100.0','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','','100.0','100.0','100.0','','false','','','','','','false','','','','','','','a0l2F000001XKCgQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtsOwQAJ','Cole City Council Office','0122F000000SQwDQAW','143 South Main Street','Cole City','KS','United States','98104','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtnohQAB','Nostdal and Rymph Household','0122F000000SQwCQAW','762 Smiley','Port Townsend','WA','','98368','true','Household Account','0.0','','','','Dr. Jessie Nostdal and Zach Rymph','','Jessie and Zach','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub7d0QAB','');
INSERT INTO "Account" VALUES('0012F00000XtgggQAB','Douglass Household','0122F000000SQwCQAW','','','','','','true','Household Account','0.0','','','','Erica Douglass','','Erica','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0l2F000001XKCfQAO','','','0032F00000Ub2ALQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtsibQAB','Community Center','0122F000000SQwDQAW','','','','','','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','0032F00000UawOLQAZ','');
INSERT INTO "Account" VALUES('0012F00000XlQpTQAV','Contact Household','0122F000000SQwCQAW','One Market Street','San Francisco','CA','USA','94105','true','Household Account','0.0','0.0','','','Sample Contact','','Sample','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0l2F000001XKCfQAO','','','0032F00000UnI9ZQAV','');
INSERT INTO "Account" VALUES('0012F00000XlQpUQAV','Sample Organization','0122F000000SQwDQAW','One California Street','San Francisco','CA','USA','94105','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','0032F00000UnI9ZQAV','');
INSERT INTO "Account" VALUES('0012F00000XtUCAQA3','Evans and Wong Household','0122F000000SQwCQAW','','','','','','true','Household Account','461.67','3533.32','2019','2018-11-04','Ms. Candace Evans and Bobby Wong','','Candace and Bobby','833.33','2019-11-30','833.33','2019-11-30','','','833.33','','','10.0','10.0','0.0','3533.32','1083.33','3533.32','0.0','6.0','4.0','6.0','','50.0','4616.65','4616.65','','false','','','','','','false','','','','','','2.0','a0l2F000001XKChQAO','','','0032F00000UawOFQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCBQA3','Figueroa and Nguyen Household','0122F000000SQwCQAW','25 10th Ave.','San Francisco','CA','','94121','true','Household Account','0.0','','','','Mr. Jose Figueroa and Linda Nguyen','','Jose and Linda','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOGQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCCQA3','Red and Brown Household','0122F000000SQwCQAW','4270 4th Court','Arlington','MA','','02128','true','Household Account','50.0','50.0','2018','2018-01-22','Ms. Gurleen Red and Christian Brown','','Gurleen and Christian','50.0','2018-01-22','50.0','2018-01-22','','','50.0','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','','50.0','50.0','50.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOHQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCDQA3','Boston Household','0122F000000SQwCQAW','25 Boyston','Boston','MA','','2130','true','Household Account','62.5','75.0','2019','2018-01-22','Ms. Celia, Louis and Ms. Celia-Rae Boston','','Celia, Louis and Celia-Rae','75.0','2019-01-22','75.0','2019-01-22','','','75.0','','','2.0','2.0','0.0','75.0','50.0','75.0','0.0','1.0','1.0','1.0','','50.0','125.0','125.0','','false','','','','','','false','','','','','','3.0','a0l2F000001XKCfQAO','','','0032F00000UawOIQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCEQA3','Ng Household','0122F000000SQwCQAW','1172 Boylston St.','Boston','MA','','02199','true','Household Account','0.0','','','','Mr. Walter and Felicia Ng','','Walter and Felicia','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOJQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCFQA3','Bruce Household','0122F000000SQwCQAW','10 Ocean Parkway','Brooklyn','NY','','02317','true','Household Account','0.0','','','','Mr. Robert and Lonnie Bruce','','Robert and Lonnie','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOKQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCGQA3','Bainter and Navarro Household','0122F000000SQwCQAW','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','true','Household Account','50.0','50.0','2018','2018-01-02','Ms Daphne Bainter and Deborah Navarro','','Daphne and Deborah','50.0','2018-01-02','50.0','2018-01-02','','','50.0','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','','50.0','50.0','50.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOLQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCHQA3','Mayo and Whitley Household','0122F000000SQwCQAW','840 Mount Street','Bay City','MI','','48706','true','Household Account','0.0','','','','Mr. Chaz Mayo and Bryce Whitley','','Chaz and Bryce','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOMQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCIQA3','Davis Household','0122F000000SQwCQAW','1391 Diane Street','City Of Commerce','CA','','90040','true','Household Account','0.0','','','','Nelda Davis','','Nelda','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0l2F000001XKCfQAO','','','0032F00000UawONQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCJQA3','Mendoza Household','0122F000000SQwCQAW','55 Charleston','South San Francisco','CA','','94044','true','Household Account','100.0','100.0','2018','2018-04-20','Ms. Nilza and Jon Mendoza','','Nilza and Jon','100.0','2018-04-20','100.0','2018-04-20','','','100.0','','','1.0','1.0','0.0','0.0','100.0','0.0','0.0','0.0','1.0','0.0','','100.0','100.0','100.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOOQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCKQA3','Kim Household','0122F000000SQwCQAW','2137 Larry Street','San Francisco','CA','','94118','true','Household Account','50.0','100.0','2019','2018-01-01','Mr. Carl, Julie, Kevin and Carly Kim','','Carl, Julie, Kevin and Carly','75.0','2019-01-01','75.0','2019-01-01','','','75.0','','','3.0','3.0','0.0','100.0','50.0','100.0','0.0','2.0','1.0','2.0','','25.0','150.0','150.0','','false','','','','','','false','','','','','','4.0','a0l2F000001XKCgQAO','','','0032F00000UawOPQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCLQA3','Blum Household','0122F000000SQwCQAW','1 Cherry Street','Pleasant','NJ','','07777','true','Household Account','0.0','','','','Ms. Zoe Blum','','Zoe','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0l2F000001XKCfQAO','','','0032F00000UawOQQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCMQA3','Lewi Household','0122F000000SQwCQAW','102 Drummand Grove Dr','Burnt Corn','AL','','56070','true','Household Account','100.0','100.0','2019','2019-08-20','Tasgall and Leanne Lewi','','Tasgall and Leanne','100.0','2019-08-20','100.0','2019-08-20','','','100.0','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','','100.0','100.0','100.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCgQAO','','','0032F00000UawORQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCNQA3','Oden Household','0122F000000SQwCQAW','306 Monterey Drive Ave S','Franklin','AK','','56949','true','Household Account','125.0','125.0','2019','2019-09-23','Mr. Freya and Brianna Oden','','Freya and Brianna','125.0','2019-09-23','125.0','2019-09-23','','','125.0','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','','125.0','125.0','125.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCgQAO','','','0032F00000UawOSQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCOQA3','Subrahmanya Household','0122F000000SQwCQAW','918 Duffield Crescent St','Arlington','WA','','57828','true','Household Account','0.0','','','','Sieffre and Baptiste Subrahmanya','','Sieffre and Baptiste','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOTQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCPQA3','Shouta Household','0122F000000SQwCQAW','2754 Glamis Place Way','Chester','MA','','58707','true','Household Account','225.0','225.0','2019','2019-08-22','Ms. Natalija and Nina Shouta','','Natalija and Nina','225.0','2019-08-22','225.0','2019-08-22','','','225.0','','','1.0','1.0','0.0','225.0','0.0','225.0','0.0','1.0','0.0','1.0','','225.0','225.0','225.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCgQAO','','','0032F00000UawOUQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCQQA3','Yudes Household','0122F000000SQwCQAW','8262 Phinney Ridge Rd','Georgetown','ME','','59586','true','Household Account','0.0','','','','Ms. Lara and Charlotte Yudes','','Lara and Charlotte','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOVQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCRQA3','Primoz Household','0122F000000SQwCQAW','74358 S Wycliff Ave','Salem','MA','','61344','true','Household Account','100.0','100.0','2019','2019-08-25','Mr. Jeffry and Ansa Primoz','','Jeffry and Ansa','100.0','2019-08-25','100.0','2019-08-25','','','100.0','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','','100.0','100.0','100.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCgQAO','','','0032F00000UawOWQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCSQA3','Lauterborn and Waterman Household','0122F000000SQwCQAW','37179 Bedford Shores St','Cole City','KS','','62223','true','Household Account','0.0','','','','Mr. Eric Lauterborn and Concepcion de Jesus Waterman','','Eric and Concepcion de Jesus','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOXQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCTQA3','Dominika and Luther Household','0122F000000SQwCQAW','36624 Jefferson Way Way','Greenville','OR','','63102','true','Household Account','10000.0','10000.0','2019','2019-08-27','Ms. Sarah Dominika and Sheridan Luther','','Sarah and Sheridan','10000.0','2019-08-27','10000.0','2019-08-27','','','10000.0','','','1.0','1.0','0.0','10000.0','0.0','10000.0','0.0','1.0','0.0','1.0','','10000.0','10000.0','10000.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCeQAO','','','0032F00000UawOYQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCUQA3','Thulani and Abbascia Household','0122F000000SQwCQAW','18312 Duchess Rd','Kingston','WA','','63981','true','Household Account','7500.0','7500.0','2019','2019-08-28','Eugenius Thulani and Nudd Abbascia','','Eugenius and Nudd','7500.0','2019-08-28','7500.0','2019-08-28','','','7500.0','','','1.0','1.0','0.0','7500.0','0.0','7500.0','0.0','1.0','0.0','1.0','','7500.0','7500.0','7500.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKChQAO','','','0032F00000UawOZQAZ','');
INSERT INTO "Account" VALUES('0012F00000XtUCVQA3','Aethelstan and Giannino Household','0122F000000SQwCQAW','9156 Springfield Green Dr','Marion','VA','','64860','true','Household Account','50.0','50.0','2019','2019-08-29','Mattia Aethelstan and Kallistrate Giannino','','Mattia and Kallistrate','50.0','2019-08-29','50.0','2019-08-29','','','50.0','','','1.0','1.0','0.0','50.0','0.0','50.0','0.0','1.0','0.0','1.0','','50.0','50.0','50.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOaQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCWQA3','O''Sullivan and Guerra Household','0122F000000SQwCQAW','4578 Linda Ave','Riverside','WV','','65739','true','Household Account','0.0','','','','Mrs. Irma O''Sullivan and Cassius Guerra','','Irma and Cassius','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawObQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCXQA3','Geier Household','0122F000000SQwCQAW','2289 David Budd St','Lebanon','MD','','66618','true','Household Account','25.0','25.0','2019','2019-08-31','Marat and Natasha Geier','','Marat and Natasha','25.0','2019-08-31','25.0','2019-08-31','','','25.0','','','1.0','1.0','0.0','25.0','0.0','25.0','0.0','1.0','0.0','1.0','','25.0','25.0','25.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOcQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCYQA3','Schubert and Maddox Household','0122F000000SQwCQAW','2357 Attlee Rd','Bristol','ME','','68376','true','Household Account','0.0','','','','Mrs. Hildie Schubert and Ursula Maddox','','Hildie and Ursula','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOdQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCZQA3','Campaign Household','0122F000000SQwCQAW','34 Shipham Close Rd','Truth or Consequences','NM','','55191','true','Household Account','0.0','','','','Mrs Grace and Georgie Campaign','','Grace and Georgie','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOeQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCaQAN','Unnur Household','0122F000000SQwCQAW','24786 Handlebar Dr N','Madison','WI','','60465','true','Household Account','0.0','','','','Ms. Fionnghuala and Maia Unnur','','Fionnghuala and Maia','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOfQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCbQAN','Thomas and Gibbons Household','0122F000000SQwCQAW','726 Twin House Lane','Springfield','MO','','65802','true','Household Account','0.0','','','','Miss Diana Thomas and Charlie Gibbons','','Diana and Charlie','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOgQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCcQAN','Kovacevic Household','0122F000000SQwCQAW','2323 Dent Way','Witchita','KS','','67497','true','Household Account','0.0','','','','Ms. Gretel and Baron Kovacevic','','Gretel and Baron','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOhQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCdQAN','Lukeson and Zappa Household','0122F000000SQwCQAW','2391 Roborough Dr','Salem','LA','','69255','true','Household Account','0.0','','','','Mr. Jozef Lukeson and Nageen Zappa','','Jozef and Nageen','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOiQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCeQAN','Djuradj and Tan Household','0122F000000SQwCQAW','2425 9th Ave','Madison','CA','','70134','true','Household Account','0.0','','','','Kamil Djuradj and Suhani Tan','','Kamil and Suhani','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOjQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCfQAN','Conbon and Bi Household','0122F000000SQwCQAW','2459 44th St E','Reston','VA','','71013','true','Household Account','0.0','','','','Azarel Conbon and Carol Bi','','Azarel and Carol','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOkQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCgQAN','Offermans Household','0122F000000SQwCQAW','2493 89th Way','Seattle','WA','','98103','true','Household Account','0.0','','','','Ms. Eleonora and Deepshika Offermans','','Eleonora and Deepshika','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOlQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUChQAN','Sandeghin and Castle Household','0122F000000SQwCQAW','2527 Monroe Rd','Dover','CO','','98982','true','Household Account','0.0','','','','Ms. Lucy Sandeghin and Helen Castle','','Lucy and Helen','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOmQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCiQAN','Sokolov Household','0122F000000SQwCQAW','2561 Madison Dr','Ashland','KY','','99861','true','Household Account','0.0','','','','Solitude and Aldegund Sokolov','','Solitude and Aldegund','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOnQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCjQAN','Nazarian Household','0122F000000SQwCQAW','2595 Montauk Ave W','Dover','FL','','99948','true','Household Account','0.0','','','','Mr. Gabrielle and Alexi Nazarian','','Gabrielle and Alexi','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOoQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCkQAN','McNeill Household','0122F000000SQwCQAW','2629 Nebraska St','Dover','FL','','99948','true','Household Account','0.0','','','','Vukasin and Mpho McNeill','','Vukasin and Mpho','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOpQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUClQAN','Devine Household','0122F000000SQwCQAW','','','','','','true','Household Account','0.0','','','','Ms. Lois and Louis Devine','','Lois and Louis','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000UawOqQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCmQAN','Bullard Household','0122F000000SQwCQAW','129 W 81st','Buffalo','NY','','08982','true','Household Account','350.0','350.0','2019','2019-12-10','Mr. Robert, Lisa and Sarah Bullard','','Robert, Lisa and Sarah','350.0','2019-12-10','350.0','2019-12-10','','','350.0','','','1.0','1.0','0.0','350.0','0.0','350.0','0.0','1.0','0.0','1.0','','350.0','350.0','350.0','','false','','','','','','false','','','','','','3.0','a0l2F000001XKCfQAO','','','0032F00000UawOrQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtUCnQAN','Cloud Kicks','0122F000000SQwDQAW','1220 Burwell Heights Rd','Houston','TX','','77006','false','','1125.0','2250.0','2018','2018-11-04','','','','1250.0','2018-11-04','1250.0','2018-11-04','','','1250.0','','','2.0','2.0','0.0','0.0','2250.0','0.0','0.0','0.0','2.0','0.0','','1000.0','2250.0','2250.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCoQAN','Newchange','0122F000000SQwDQAW','8990 Chatham Drive','Flower Mound','Tx','','39932','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCpQAN','Tesco','0122F000000SQwDQAW','111 Second Street','Boston','MA','','02130','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCqQAN','Johnson''s General Stores','0122F000000SQwDQAW','1121 David Vale Road','Reston','VA','','22091','false','','87.5','250.0','2019','2018-03-01','','','','125.0','2019-08-23','50.0','2019-08-23','','','50.0','','','4.0','4.0','0.0','250.0','100.0','250.0','0.0','3.0','1.0','3.0','','50.0','350.0','350.0','','false','','','','','','false','','','','','','','a0l2F000001XKCgQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCrQAN','Orange Company','0122F000000SQwDQAW','122 Rother View','','','','01478','false','','112.5','225.0','2018','2018-05-21','','','','125.0','2018-05-21','125.0','2018-05-21','','','125.0','','','2.0','2.0','0.0','0.0','225.0','0.0','0.0','0.0','2.0','0.0','','100.0','225.0','225.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCsQAN','Acme Corporation','0122F000000SQwDQAW','500 Main St.','Cambridge','MA','','02130','false','','11250.0','22500.0','2018','2018-06-30','','','','12500.0','2018-06-30','12500.0','2018-06-30','','','12500.0','','','2.0','2.0','0.0','0.0','22500.0','0.0','0.0','0.0','2.0','0.0','','10000.0','22500.0','22500.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCtQAN','Music Foundation','0122F000000SQwDQAW','123 Main St.','San Francisco','CA','US','94105','false','','1125.0','1250.0','2019','2018-01-01','','','','1250.0','2019-01-01','1250.0','2019-01-01','','','1250.0','','','2.0','2.0','0.0','1250.0','1000.0','1250.0','0.0','1.0','1.0','1.0','','1000.0','2250.0','2250.0','','false','','','','','','false','','','','','','','a0l2F000001XKChQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCuQAN','Orange Tree Imports','0122F000000SQwDQAW','1 Main Street','San Francisco','CA','','94108','false','','37.5','150.0','2019','2019-05-02','','','','75.0','2019-08-22','10.0','2019-08-22','','','10.0','','','4.0','4.0','0.0','150.0','0.0','150.0','0.0','4.0','0.0','4.0','','10.0','150.0','150.0','','false','','','','','','false','','','','','','','a0l2F000001XKCgQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCvQAN','Target Campaigns','0122F000000SQwDQAW','232F Coppice Loan Pkwy','San Francisco','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCwQAN','Gnarl''s Bicycles','0122F000000SQwDQAW','991 Bay Common Dr S','St. Louis','CA','','94108','false','','112.5','225.0','2019','2019-05-06','','','','125.0','2019-08-26','100.0','2019-08-26','','','100.0','','','2.0','2.0','0.0','225.0','0.0','225.0','0.0','2.0','0.0','2.0','','100.0','225.0','225.0','','false','','','','','','false','','','','','','','a0l2F000001XKCgQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCxQAN','Save the Mutts','0122F000000SQwDQAW','2988 Raven Grange','Rochester','DE','','2222','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCyQAN','Spotsham University','0122F000000SQwDQAW','8923A Elm St','Dorchester','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUCzQAN','University of Bringhampton','0122F000000SQwDQAW','982 Granary Point Ave N','Bingley','VA','','22091','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD0QAN','Blotts, Hargrove and Spludge','0122F000000SQwDQAW','1223 Freshman Way','Cooperfield','CA','','94108','false','','1125.0','2250.0','2019','2019-05-10','','','','1250.0','2019-08-30','1000.0','2019-08-30','','','1000.0','','','2.0','2.0','0.0','2250.0','0.0','2250.0','0.0','2.0','0.0','2.0','','1000.0','2250.0','2250.0','','false','','','','','','false','','','','','','','a0l2F000001XKChQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD1QAN','Whimsey Wearhouse','0122F000000SQwDQAW','882 Pine Tree Hall','Nayes Dam','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD2QAN','American Firefighters for Historic Book Preservation','0122F000000SQwDQAW','292 Sporting Green Pl','Charlotte','CA','','94108','false','','75.0','75.0','2019','2019-09-02','','','','75.0','2019-09-02','75.0','2019-09-02','','','75.0','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','','75.0','75.0','75.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD3QAN','Foreign Fathers','0122F000000SQwDQAW','13 Angrew Trees Pl','Hill Station','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD4QAN','Turtledove Cinemas','0122F000000SQwDQAW','789 E Watersham Rte','Charlotte','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD5QAN','Yuri-Creek Playhouse','0122F000000SQwDQAW','3832 Laburnam Bank Rd','Vienna','VA','','22091','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD6QAN','Saltanas Bagels','0122F000000SQwDQAW','1222 Hunters Green Dr','Anita','WV','','20199','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD7QAN','Architecture for Adults','0122F000000SQwDQAW','8990 Iona Gardens Plaza','Meryls Town','Tx','','39932','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD8QAN','National Basketball Conglomeration','0122F000000SQwDQAW','373 Clare Heathcliff Pkway','Spottsville','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUD9QAN','Junior Magazines','0122F000000SQwDQAW','44 Thomas Garth Dr','Hodgenville','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUDAQA3','Hedgepeth Industries','0122F000000SQwDQAW','29887 Bailey Hill La','Bourbonvilla','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUDBQA3','Glicks Furniture','0122F000000SQwDQAW','11235 Banana Seat Rd','Charleston','WV','','20777','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUDCQA3','Peets Coffee','0122F000000SQwDQAW','25 Market St','San Francisco','CA','','94108','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000XtUDDQA3','Benificent Insurance','0122F000000SQwDQAW','','','','','','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
INSERT INTO "Account" VALUES('0012F00000Xtg9dQAB','Ventresca Household','0122F000000SQwCQAW','','','','','','true','Household Account','0.0','','','','Alex Ventresca','','Alex','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0l2F000001XKCfQAO','','','0032F00000Ub0UmQAJ','');
INSERT INTO "Account" VALUES('0012F00000XtnlOQAR','Nostdal Works','0122F000000SQwDQAW','','','','','','false','','0.0','','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0l2F000001XKCfQAO','','','','');
CREATE TABLE "Account_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "Account_rt_mapping" VALUES('0122F000000SQwCQAW','HH_Account');
INSERT INTO "Account_rt_mapping" VALUES('0122F000000SQwDQAW','Organization');
CREATE TABLE "Campaign" (
	sf_id VARCHAR(255) NOT NULL, 
	"Name" VARCHAR(255), 
	"IsActive" VARCHAR(255), 
	"RecordTypeId" VARCHAR(255), 
	"StartDate" VARCHAR(255), 
	"EndDate" VARCHAR(255), 
	"Status" VARCHAR(255), 
	"Type" VARCHAR(255), 
	location__c VARCHAR(255), 
	on_site_contact__c VARCHAR(255), 
	parent_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "Campaign" VALUES('7012F000000LvfDQAS','No More Hostile Architecture','true','0122F000000TsdLQAS','2019-01-01','2019-11-30','In Progress','Advocacy','','','7012F000000LvfOQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvfEQAS','Advocacy Training Days','true','0122F000000Tsd6QAC','2019-01-01','2019-12-31','In Progress','Advocacy','0012F00000XtsibQAB','0032F00000UawOLQAZ','7012F000000LvfDQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvfGQAS','Petition Drives','true','0122F000000TsdLQAS','2019-01-01','2019-12-31','In Progress','Advocacy','','','7012F000000LvfDQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvfHQAS','Direct Mail: January 2019 - Hostile Architecture','true','0122F000000TsdBQAS','2019-01-14','2019-03-15','Completed','Fundraising','','','7012F000000Lvf8QAC');
INSERT INTO "Campaign" VALUES('7012F000000LvfIQAS','Direct Mail: May 2019 - Hostile Architecture','true','0122F000000TsdBQAS','2019-05-01','2019-05-31','Completed','Fundraising','','','7012F000000Lvf8QAC');
INSERT INTO "Campaign" VALUES('7012F000000LvfJQAS','NMH Petition','true','0122F000000TsdLQAS','2019-01-01','2019-05-31','In Progress','Advocacy','','','7012F000000LvfGQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvfKQAS','Event: August 2019 - Advocacy Training Day','true','0122F000000Tsd6QAC','2019-08-07','2019-08-07','Completed','Advocacy','0012F00000XtsibQAB','0032F00000UawOLQAZ','7012F000000LvfEQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvfLQAS','Event: January 2019 - Advocacy Training Day','true','0122F000000Tsd6QAC','2019-01-15','2019-01-15','Completed','Advocacy','0012F00000XtsibQAB','0032F00000UawOLQAZ','7012F000000LvfEQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvfMQAS','Event: June 2019 - Advocacy Training Day','true','0122F000000Tsd6QAC','2019-06-20','2019-06-20','Completed','Advocacy','0012F00000XtsibQAB','0032F00000UawOLQAZ','7012F000000LvfEQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvfNQAS','Event: October 2019 - Advocacy Training Day','true','0122F000000Tsd6QAC','2019-10-24','2019-10-24','Completed','Advocacy','0012F00000XtsibQAB','0032F00000UawOLQAZ','7012F000000LvfEQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvfOQAS','2019 Advocacy Campaigns','true','0122F000000TsdLQAS','2019-01-01','2019-12-31','In Progress','Advocacy','','','');
INSERT INTO "Campaign" VALUES('7012F000000LvPqQAK','Annual Appeal 2018','true','0122F000000SQwFQAW','2018-01-01','2018-12-31','Completed','Fundraising','','','7012F000000LvfaQAC');
INSERT INTO "Campaign" VALUES('7012F000000LvPrQAK','NMH Transitional Housing Capital Campaign','true','0122F000000TsdLQAS','2018-10-01','2019-12-31','In Progress','Fundraisng','','','');
INSERT INTO "Campaign" VALUES('7012F000000LvPsQAK','Annual Appeal 2019','true','0122F000000SQwFQAW','2019-01-01','2019-12-31','In Progress','Fundraising','','','7012F000000LvfaQAC');
INSERT INTO "Campaign" VALUES('7012F000000LvfaQAC','Annual Fund','true','0122F000000TsdBQAS','','','In Progress','Fundraising','','','');
INSERT INTO "Campaign" VALUES('7012F000000Lvf8QAC','Email Outreach','true','0122F000000TsdBQAS','2019-01-01','2019-01-01','In Progress','Advocacy','','','7012F000000LvfDQAS');
INSERT INTO "Campaign" VALUES('7012F000000LvPvQAK','Give a Life','false','0122F000000SQwFQAW','2018-10-01','2018-11-05','Planned','Telemarketing','','','7012F000000LvPqQAK');
CREATE TABLE "Campaign_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "Campaign_rt_mapping" VALUES('0122F000000SQwFQAW','Default');
INSERT INTO "Campaign_rt_mapping" VALUES('0122F000000Tsd6QAC','Event');
INSERT INTO "Campaign_rt_mapping" VALUES('0122F000000TsdBQAS','Fundraising');
INSERT INTO "Campaign_rt_mapping" VALUES('0122F000000TsdLQAS','General');
INSERT INTO "Campaign_rt_mapping" VALUES('0122F000000TsdGQAS','Marketing');
INSERT INTO "Campaign_rt_mapping" VALUES('0122F000000Tsd1QAC','Volunteer_Campaign');
CREATE TABLE "CampaignMemberStatus" (
	sf_id VARCHAR(255) NOT NULL, 
	"HasResponded" VARCHAR(255), 
	"IsDefault" VARCHAR(255), 
	"Label" VARCHAR(255), 
	"SortOrder" VARCHAR(255), 
	campaign_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOviUAE','true','false','RSVP Yes','2','7012F000000LvfKQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwWUAU','false','false','RSVP No','5','7012F000000LvfLQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwIUAU','true','false','RSVP Yes','4','7012F000000LvfLQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwJUAU','false','false','No Show','6','7012F000000LvfLQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwHUAU','false','false','RSVP No','6','7012F000000LvfMQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwlUAE','false','false','Cancelled','5','7012F000000LvfKQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwqUAE','false','false','No Show','6','7012F000000LvfKQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOw7UAE','true','false','Attended','3','7012F000000LvfMQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwgUAE','true','false','Attended','4','7012F000000LvfKQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwCUAU','false','false','Cancelled','4','7012F000000LvfMQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwDUAU','false','false','No Show','5','7012F000000LvfMQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwRUAU','true','false','Attended','3','7012F000000LvfLQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwSUAU','false','false','RSVP No','3','7012F000000LvfKQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwMUAU','true','false','RSVP Yes','7','7012F000000LvfMQAS');
INSERT INTO "CampaignMemberStatus" VALUES('01Y2F000000iOwbUAE','false','false','Cancelled','7','7012F000000LvfLQAS');
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
INSERT INTO "Case" VALUES('5002F000004zzo3QAA','false','Household goods needed','New','Phone','Problem','Medium','Alex needs household goods for herself and Daniel as they prepare to move to their new home.','0012F00000Xtg9dQAB','0032F00000Ub0UmQAJ','');
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
INSERT INTO "Contact" VALUES('0032F00000Ub2ALQAZ','Erica','Douglass','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtgggQAB','','a0l2F000001XKCfQAO','','','','','0012F00000XtUCnQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub0VHQAZ','Daniel','Baker','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','1.0','0.0','','0.0','','','','0.0','','','Household__c.Name;Household__c.Formal_Greeting__c;Household__c.Informal_Greeting__c','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','true','true','true','','','','','','','','','','','','0.0','false','0012F00000Xtg9dQAB','','a0l2F000001XKCfQAO','','','','','');
INSERT INTO "Contact" VALUES('0032F00000UawUGQAZ','Sarah','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','350.0','350.0','0.0','','0.0','0.0','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','0.0','1.0','0.0','1.0','350.0','false','0012F00000XtUCmQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doy0UAA','');
INSERT INTO "Contact" VALUES('0032F00000UnI9ZQAV','Sample','Contact','false','','One Market Street','San Francisco','CA','USA','94105','false','false','sample.contact@otheremail.com','sample.contact@email.com','Work','Personal','Home','false','','','sample.contact@workemail.com','(202) 555-9654','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0012F00000XlQpTQAV','','a0l2F000001XKCfQAO','','','','a0K2F000007dnxvUAA','0012F00000XlQpUQAV');
INSERT INTO "Contact" VALUES('0032F00000Ub0UmQAJ','Alex','Ventresca','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','0.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000Xtg9dQAB','','a0l2F000001XKCfQAO','','','','','');
INSERT INTO "Contact" VALUES('0032F00000UawOsQAJ','Bobby','Wong','false','','','','','','','false','false','','rich@evansfam.com','Home','Personal','','false','','','rich@ballooga.com','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','1083.33','3533.32','4616.65','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-11-04','833.33','2019-02-28','833.33','2019-11-30','6.0','4.0','6.0','0.0','10.0','3533.32','false','0012F00000XtUCAQA3','','a0l2F000001XKCfQAO','','','','','');
INSERT INTO "Contact" VALUES('0032F00000UawOFQAZ','Candace','Evans','false','','','','','','','false','false','','candy@evansfam.com','Home','Personal','','false','','','','','461.67','3533.32','2019','2018-11-04','','833.33','2019-11-30','833.33','2019-11-30','','','833.33','','','','10.0','10.0','0.0','3533.32','1083.33','3533.32','0.0','6.0','4.0','6.0','50.0','0.0','350.0','350.0','0.0','','4616.65','4616.65','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','0.0','1.0','0.0','1.0','350.0','false','0012F00000XtUCAQA3','a0l2F000001XKChQAO','','','','','','0012F00000XtUCnQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOGQAZ','Jose','Figueroa','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','josefigleaf@gmail.com','Home','Work','Home','false','','','jfigueroa@glicks.com','(222) 898-2002','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','350.0','350.0','0.0','','0.0','0.0','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','0.0','1.0','0.0','1.0','350.0','false','0012F00000XtUCBQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxQUAQ','0012F00000XtUCnQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOHQAZ','Gurleen','Red','false','','4270 4th Court','Arlington','MA','','02128','false','false','','cardinal@chippy.com','Home','Personal','Home','false','','','','','50.0','50.0','2018','2018-01-22','','50.0','2018-01-22','50.0','2018-01-22','','','50.0','','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','50.0','','','','','','50.0','50.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCCQA3','a0l2F000001XKCfQAO','','','','','a0K2F000007doxRUAQ','0012F00000XtUCoQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOIQAZ','Celia','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','celia@boston.com','Home','Personal','Home','false','','','','(555) 555-5555','50.0','50.0','2018','2018-01-22','','50.0','2018-01-22','50.0','2018-01-22','','','50.0','','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','50.0','0.0','75.0','75.0','0.0','','50.0','50.0','false','false','false','false','false','75.0','2019-01-22','75.0','2019-01-22','75.0','2019-01-22','1.0','0.0','1.0','0.0','1.0','75.0','false','0012F00000XtUCDQA3','a0l2F000001XKCfQAO','','','','','a0K2F000007dqSlUAI','0012F00000XtUCpQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOJQAZ','Walter','Ng','false','','1172 Boylston St.','Boston','MA','','02199','false','false','','henry@ng.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCEQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxTUAQ','0012F00000XtUCqQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOKQAZ','Robert','Bruce','false','','10 Ocean Parkway','Brooklyn','NY','','02317','false','false','','robert@bruce.com','Home','Work','Home','false','','','robertbruce@oranges.com','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCFQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxUUAQ','0012F00000XtUCrQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOLQAZ','Daphne','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','daphnecbainter@teleworm.us','Home','Personal','Home','false','','','','','50.0','50.0','2018','2018-01-02','','50.0','2018-01-02','50.0','2018-01-02','','','50.0','','','','1.0','1.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','50.0','','','','','','50.0','50.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCGQA3','a0l2F000001XKCfQAO','','','','','a0K2F000007doxVUAQ','0012F00000XtsibQAB');
INSERT INTO "Contact" VALUES('0032F00000UawOMQAZ','Chaz','Mayo','false','','840 Mount Street','Bay City','MI','','48706','false','false','','dannyvmayo@rhyta.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCHQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxWUAQ','0012F00000XtUCsQAN');
INSERT INTO "Contact" VALUES('0032F00000UawONQAZ','Nelda','Davis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','neldaddavis@cuvox.de','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCIQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxXUAQ','0012F00000XtUCtQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOOQAZ','Nilza','Mendoza','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','nilza@mendoza.com','Home','Personal','Home','false','','','','','100.0','100.0','2018','2018-04-20','','100.0','2018-04-20','100.0','2018-04-20','','','100.0','','','','1.0','1.0','0.0','0.0','100.0','0.0','0.0','0.0','1.0','0.0','100.0','','','','','','100.0','100.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCJQA3','a0l2F000001XKCgQAO','','','','','a0K2F000007doxYUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawOPQAZ','Carl','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim@fleckens.hu','Home','Personal','Home','false','','','','','50.0','100.0','2019','2018-01-01','','75.0','2019-01-01','25.0','2019-01-01','','','25.0','','','','3.0','3.0','0.0','100.0','50.0','100.0','0.0','2.0','1.0','2.0','25.0','','','','','','150.0','150.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCKQA3','a0l2F000001XKCgQAO','','','','','a0K2F000007doxZUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawOQQAZ','Zoe','Blum','false','','1 Cherry Street','Pleasant','NJ','','07777','false','false','','blum@smith.com','Home','Work','Home','false','','','carolines@orangetree.org','(922) 298-8282','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCLQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxaUAA','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000UawORQAZ','Tasgall','Lewi','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','9alsfa7.666a@pendokngana.gq','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-08-20','','100.0','2019-08-20','100.0','2019-08-20','','','100.0','','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','100.0','','','','','','100.0','100.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCMQA3','a0l2F000001XKCgQAO','','','','','a0K2F000007doxbUAA','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOSQAZ','Freya','Oden','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','ghosse@isolationideas.info','Work','Personal','Home','false','','','','(356) 385-7489','125.0','125.0','2019','2019-09-23','','125.0','2019-09-23','125.0','2019-09-23','','','125.0','','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCNQA3','a0l2F000001XKCgQAO','','','','','a0K2F000007doxcUAA','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOTQAZ','Sieffre','Subrahmanya','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','sieffre@hitchens.com','Mobile','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCOQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxdUAA','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOUQAZ','Natalija','Shouta','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','natalijas@shouta.com','Home','Personal','Home','false','','','','','225.0','225.0','2019','2019-08-22','','225.0','2019-08-22','225.0','2019-08-22','','','225.0','','','','1.0','1.0','0.0','225.0','0.0','225.0','0.0','1.0','0.0','1.0','225.0','','','','','','225.0','225.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCPQA3','a0l2F000001XKCgQAO','','','','','a0K2F000007doxeUAA','0012F00000XtUCvQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOVQAZ','Lara','Yudes','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','lara.yudes@hitchens.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCQQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxfUAA','0012F00000XtUCqQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOWQAZ','Jeffry','Primoz','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','jeffryp@primoz.com','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-08-25','','100.0','2019-08-25','100.0','2019-08-25','','','100.0','','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','100.0','','','','','','100.0','100.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCRQA3','a0l2F000001XKCgQAO','','','','','a0K2F000007doxgUAA','0012F00000XtUCoQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOXQAZ','Eric','Lauterborn','false','','37179 Bedford Shores St','Cole City','KS','','62223','false','false','','taneshaep@taconet.com','Home','Work','Home','false','','','lauterborn.e@colecity.gov','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCSQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007dq8EUAQ','0012F00000XtsOwQAJ');
INSERT INTO "Contact" VALUES('0032F00000UawOYQAZ','Sarah','Dominika','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','emdom@snailmail.com','Home','Personal','Home','false','','','','','10000.0','10000.0','2019','2019-08-27','','10000.0','2019-08-27','10000.0','2019-08-27','','','10000.0','','','','1.0','1.0','0.0','10000.0','0.0','10000.0','0.0','1.0','0.0','1.0','10000.0','','','','','','10000.0','10000.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCTQA3','a0l2F000001XKCeQAO','','','','','a0K2F000007doxiUAA','0012F00000XtUCxQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOZQAZ','Eugenius','Thulani','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','eugeniusthulani@kalemail.com','Home','Personal','Home','false','','','','','7500.0','7500.0','2019','2019-08-28','','7500.0','2019-08-28','7500.0','2019-08-28','','','7500.0','','','','1.0','1.0','0.0','7500.0','0.0','7500.0','0.0','1.0','0.0','1.0','7500.0','','','','','','7500.0','7500.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCUQA3','a0l2F000001XKChQAO','','','','','a0K2F000007doxjUAA','0012F00000XtUCyQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOaQAJ','Mattia','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','rosebud@meetsaround.com','Work','Work','Home','false','','','','(202) 909-9999','50.0','50.0','2019','2019-08-29','','50.0','2019-08-29','50.0','2019-08-29','','','50.0','','','','1.0','1.0','0.0','50.0','0.0','50.0','0.0','1.0','0.0','1.0','50.0','','','','','','50.0','50.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCVQA3','a0l2F000001XKCfQAO','','','','','a0K2F000007doxkUAA','0012F00000XtUCzQAN');
INSERT INTO "Contact" VALUES('0032F00000UawObQAJ','Irma','O''Sullivan','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','irmaosull@sullyhouse.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCWQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxlUAA','0012F00000XtUD0QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOcQAJ','Marat','Geier','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','maratgeier@goregens.edu','Home','Personal','Home','false','','','','','25.0','25.0','2019','2019-08-31','','25.0','2019-08-31','25.0','2019-08-31','','','25.0','','','','1.0','1.0','0.0','25.0','0.0','25.0','0.0','1.0','0.0','1.0','25.0','','','','','','25.0','25.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCXQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxmUAA','0012F00000XtUD1QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOdQAJ','Hildie','Schubert','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','hildielovesfrank@schuberts.com','Work','Work','Home','false','','','hildiebakes@bakery.net','(202) 756-9723','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCYQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxnUAA','0012F00000XtUD2QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOeQAJ','Grace','Campaign','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','tessa@campaign.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCZQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxoUAA','0012F00000XtUCvQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOfQAJ','Fionnghuala','Unnur','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','fionnur@greensburg.ky.gov','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCaQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxpUAA','0012F00000XtUCtQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOgQAJ','Diana','Thomas','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','dianarthomas@superrito.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCbQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxqUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawOhQAJ','Gretel','Kovacevic','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','copacetic@cowabunga.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCcQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxrUAA','0012F00000XtUD3QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOiQAJ','Jozef','Lukeson','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','jozef@hitchens.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCdQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxsUAA','0012F00000XtUD4QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOjQAJ','Kamil','Djuradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','kamild@snailmail.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCeQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxtUAA','0012F00000XtUD5QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOkQAJ','Azarel','Conbon','false','','2459 44th St E','Reston','VA','','71013','false','false','','azarel@kanban.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCfQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxuUAA','0012F00000XtUD6QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOlQAJ','Eleonora','Offermans','false','','2493 89th Way','Seattle','WA','','98103','false','false','','eleonora@scrumteam.net','Work','Work','Home','false','','','eleonora@scrumteam.net','(989) 777-4543','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCgQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxvUAA','0012F00000XtUD7QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOmQAJ','Lucy','Sandeghin','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','deandre@blast.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUChQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxwUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawOnQAJ','Solitude','Sokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','soko@protons.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCiQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxxUAA','0012F00000XtUD9QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOoQAJ','Gabrielle','Nazarian','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','gabrielsphd@atoms.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCjQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxyUAA','0012F00000XtUDAQA3');
INSERT INTO "Contact" VALUES('0032F00000UawOpQAJ','Vukasin','McNeill','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','vukasinmcneill@narnia.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCkQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxzUAA','0012F00000XtUD9QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOqQAJ','Lois','Devine','false','','','','','','','false','false','','lois@devine.com','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUClQAN','','a0l2F000001XKCfQAO','','','','','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOrQAJ','Robert','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','robert@myemail.com','Home','Personal','Home','false','','','ceo@myemail.com','(222) 222-2222','350.0','350.0','2019','2019-12-10','','350.0','2019-12-10','350.0','2019-12-10','','','350.0','','','','1.0','1.0','0.0','350.0','0.0','350.0','0.0','1.0','0.0','1.0','350.0','','','','','','350.0','350.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCmQAN','a0l2F000001XKCgQAO','','','','','a0K2F000007doy0UAA','0012F00000XtUDBQA3');
INSERT INTO "Contact" VALUES('0032F00000Ub9FYQAZ','Nilza','Hernandez','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','nilza51@mendoza.com','Home','Personal','Home','false','','','','','125.0','125.0','2018','2018-04-20','','125.0','2018-04-20','125.0','2018-04-20','','','125.0','','','','1.0','1.0','0.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuJQAR','a0l2F000001XKCgQAO','','','','','a0K2F000007dqSaUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9FZQAZ','Robert','Bace','false','','10 Ocean Parkway','Brooklyn','NY','','2317','false','false','','robert7@bruce.com','Home','Work','Home','false','','','robertbruce@oranges.com','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuKQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSbUAI','0012F00000XtUCrQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FaQAJ','Geetika','Ivans','false','','','','','','','false','false','','candy25@evansfam.com','Home','Personal','','false','','','','','125.0','125.0','2018','2018-11-05','','125.0','2018-11-05','125.0','2018-11-05','','','125.0','','','','1.0','1.0','0.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuLQAR','a0l2F000001XKCgQAO','','','','','','0012F00000XtUCnQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FbQAJ','Henry','Nyugen','false','','1172 Boylston St.','Boston','MA','','2199','false','false','','henry55@ng.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuMQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqScUAI','0012F00000XtUCqQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FcQAJ','Mattias','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim39@fleckens.hu','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-01-01','0.0','100.0','2019-01-01','100.0','2019-01-01','','','100.0','','','','1.0','1.0','0.0','100.0','0.0','100.0','0.0','1.0','0.0','1.0','100.0','0.0','105.0','105.0','0.0','','100.0','100.0','false','false','false','false','false','30.0','2019-01-01','75.0','2019-01-01','75.0','2019-01-01','2.0','0.0','2.0','0.0','2.0','105.0','false','0012F00000XttuNQAR','a0l2F000001XKCgQAO','','','','','a0K2F000007dqSdUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9FdQAJ','Caroline','Smythe','false','','1 Cherry Street','Pleasant','NJ','','7777','false','false','','smith71@smith.com','Home','Work','Home','false','','','carolines@orangetree.org','(922) 298-8282','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuOQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSeUAI','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FeQAJ','Georgia','Beethavent','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','hildielovesfrank67@schuberts.com','Work','Work','Home','false','','','hildiebakes@bakery.net','(202) 756-9723','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuPQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSfUAI','0012F00000XttuyQAB');
INSERT INTO "Contact" VALUES('0032F00000Ub9FfQAJ','Llewlyn','Loki','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','ghosse59@isolationideas.info','Work','Personal','Home','false','','','','(356) 385-7489','160.0','160.0','2019','2019-09-23','','160.0','2019-09-23','160.0','2019-09-23','','','160.0','','','','1.0','1.0','0.0','160.0','0.0','160.0','0.0','1.0','0.0','1.0','160.0','','','','','','160.0','160.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuQQAR','a0l2F000001XKCgQAO','','','','','a0K2F000007dqSgUAI','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FgQAJ','Sampson','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim37@fleckens.hu','Home','Personal','Home','false','','','','','30.0','30.0','2019','2019-01-01','2.0','30.0','2019-01-01','30.0','2019-01-01','','','30.0','','','','1.0','1.0','0.0','30.0','0.0','30.0','0.0','1.0','0.0','1.0','30.0','0.0','175.0','175.0','0.0','','30.0','30.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','75.0','2019-01-01','2.0','0.0','2.0','0.0','2.0','175.0','false','0012F00000XttuNQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSdUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9FhQAJ','Grayson','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim35@fleckens.hu','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-01','4.0','75.0','2019-01-01','75.0','2019-01-01','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','0.0','130.0','130.0','0.0','','75.0','75.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','2.0','0.0','2.0','0.0','2.0','130.0','false','0012F00000XttuNQAR','a0l2F000001XKCfQAO','','','','','a0K2F000007dqSdUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9FiQAJ','Nelda','Mavis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','neldaddavis17@cuvox.de','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuTQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSjUAI','0012F00000XtUCtQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FjQAJ','Edith','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','daphnecbainter3@teleworm.us','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-02','','75.0','2019-01-02','75.0','2019-01-02','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuUQAR','a0l2F000001XKCfQAO','','','','','a0K2F000007dqSkUAI','0012F00000XtUCqQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FkQAJ','Celia-Rae','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','celia5@boston.com','Home','Personal','Home','false','','','','(555) 555-5555','75.0','75.0','2019','2019-01-22','','75.0','2019-01-22','75.0','2019-01-22','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCDQA3','a0l2F000001XKCfQAO','','','','','a0K2F000007dqSlUAI','0012F00000XtUCpQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FlQAJ','Patrick','Orange','false','','4270 4th Court','Arlington','MA','','2128','false','false','','cardinal65@chippy.com','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-22','','75.0','2019-01-22','75.0','2019-01-22','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuVQAR','a0l2F000001XKCfQAO','','','','','a0K2F000007dqSmUAI','0012F00000XtUCoQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FmQAJ','Leo','Loui','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','9alsfa7.666a43@pendokngana.gq','Home','Personal','Home','false','','','','','125.0','125.0','2019','2019-05-01','','125.0','2019-05-01','125.0','2019-05-01','','','125.0','','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuWQAR','a0l2F000001XKCgQAO','','','','','a0K2F000007dqSnUAI','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FnQAJ','Sufjan','Vakil','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','sieffre75@hitchens.com','Mobile','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuXQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSoUAI','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FoQAJ','America','George','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','natalijas69@shouta.com','Home','Personal','Home','false','','','','','300.0','300.0','2019','2019-05-03','','300.0','2019-05-03','300.0','2019-05-03','','','300.0','','','','1.0','1.0','0.0','300.0','0.0','300.0','0.0','1.0','0.0','1.0','300.0','','','','','','300.0','300.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuYQAR','a0l2F000001XKCgQAO','','','','','a0K2F000007dqSpUAI','0012F00000XtUCvQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FpQAJ','Lara','Rudddles','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','lara.yudes85@hitchens.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuZQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSqUAI','0012F00000XtUCqQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FqQAJ','Geoff','de la O','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','jeffryp63@primoz.com','Home','Personal','Home','false','','','','','125.0','125.0','2019','2019-05-05','','125.0','2019-05-05','125.0','2019-05-05','','','125.0','','','','1.0','1.0','0.0','125.0','0.0','125.0','0.0','1.0','0.0','1.0','125.0','','','','','','125.0','125.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuaQAB','a0l2F000001XKCgQAO','','','','','a0K2F000007dqSrUAI','0012F00000XtUCoQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FrQAJ','Eliza','Jackson','false','','37179 Bedford Shores St','Fairfield','KS','','62223','false','false','','taneshaep77@taconet.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttubQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSsUAI','0012F00000XtUCwQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FsQAJ','Nicolai','Trelawni','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','eugeniusthulani81@kalemail.com','Home','Personal','Home','false','','','','','9375.0','9375.0','2019','2019-05-08','','9375.0','2019-05-08','9375.0','2019-05-08','','','9375.0','','','','1.0','1.0','0.0','9375.0','0.0','9375.0','0.0','1.0','0.0','1.0','9375.0','','','','','','9375.0','9375.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttucQAB','a0l2F000001XKChQAO','','','','','a0K2F000007dqStUAI','0012F00000XtUCyQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FtQAJ','Mattia','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','rosebud1@meetsaround.com','Work','Work','Home','false','','','','(202) 909-9999','75.0','75.0','2019','2019-05-09','','75.0','2019-05-09','75.0','2019-05-09','','','75.0','','','','1.0','1.0','0.0','75.0','0.0','75.0','0.0','1.0','0.0','1.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttudQAB','a0l2F000001XKCfQAO','','','','','a0K2F000007dqSuUAI','0012F00000XtUCzQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FuQAJ','Irma','O''Shea','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','irmaosull57@sullyhouse.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttueQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSvUAI','0012F00000XtUD0QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FvQAJ','Bennett','Geiser-Bann','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','maratgeier33@goregens.edu','Home','Personal','Home','false','','','','','30.0','30.0','2019','2019-05-11','','30.0','2019-05-11','30.0','2019-05-11','','','30.0','','','','1.0','1.0','0.0','30.0','0.0','30.0','0.0','1.0','0.0','1.0','30.0','','','','','','30.0','30.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttufQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSwUAI','0012F00000XtUD1QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FwQAJ','Danny','Clerr','false','','840 Mount Street','Bay City','MI','','48706','false','false','','dannyvmayo47@rhyta.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttugQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSxUAI','0012F00000XtUCsQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FxQAJ','Sehar','Ivans','false','','','','','','','false','false','','candy27@evansfam.com','Home','Personal','','false','','','','','75.0','75.0','2018','2018-11-04','','75.0','2018-11-04','75.0','2018-11-04','','','75.0','','','','1.0','1.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','75.0','','','','','','75.0','75.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuhQAB','a0l2F000001XKCfQAO','','','','','','0012F00000XtUCnQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FyQAJ','Lakshmi','Ivans','false','','','','','','','false','false','','candy29@evansfam.com','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuiQAB','','a0l2F000001XKCfQAO','','','','','0012F00000XtUCnQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9FzQAJ','Em','Dominico','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','emdom23@snailmail.com','Home','Personal','Home','false','','','','','12500.0','12500.0','2019','2019-05-07','','12500.0','2019-05-07','12500.0','2019-05-07','','','12500.0','','','','1.0','1.0','0.0','12500.0','0.0','12500.0','0.0','1.0','0.0','1.0','12500.0','','','','','','12500.0','12500.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttujQAB','a0l2F000001XKCeQAO','','','','','a0K2F000007dqSyUAI','0012F00000XtUCxQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G0QAJ','Roger','Figueroo','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','josefigleaf31@gmail.com','Home','Work','Home','false','','','jfigueroa@glicks.com','(222) 898-2002','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttukQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSzUAI','0012F00000XtUCnQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G1QAJ','Tessa','Campagna','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','tessa11@campaign.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttulQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT0UAI','0012F00000XtUCvQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G2QAJ','Deandre','Clerk','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','deandre13@blast.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttumQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT1UAI','0012F00000XtUD8QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G3QAJ','Heidi','Kanban','false','','2459 44th St E','Reston','VA','','71013','false','false','','azarel15@kanban.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttunQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT2UAI','0012F00000XtUD6QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G4QAJ','Lois','Primordial','false','','','','','','','false','false','','lois19@devine.com','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuoQAB','','a0l2F000001XKCfQAO','','','','','0012F00000XtUCuQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G5QAJ','Kamilla','Djyradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','kamild21@snailmail.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttupQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT3UAI','0012F00000XtUD5QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G6QAJ','Luiza','Kasprawicz','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','copacetic41@cowabunga.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuqQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT4UAI','0012F00000XtUD3QAN');
INSERT INTO "Contact" VALUES('0032F00000UawOtQAJ','Linda','Nguyen','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','linda@nguyen.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCBQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxQUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawOuQAJ','Christian','Brown','false','','4270 4th Court','Arlington','MA','','02128','false','false','','chipboat@chippy.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','0.0','50.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-22','50.0','2018-01-22','50.0','2018-01-22','0.0','1.0','0.0','0.0','1.0','0.0','false','0012F00000XtUCCQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxRUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawOvQAJ','Louis','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','louis@boston.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','75.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-22','75.0','2019-01-22','75.0','2019-01-22','1.0','1.0','1.0','0.0','2.0','75.0','false','0012F00000XtUCDQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSlUAI','');
INSERT INTO "Contact" VALUES('0032F00000UawOwQAJ','Felicia','Ng','false','','1172 Boylston St.','Boston','MA','','02199','false','false','','felicia@ng.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCEQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxTUAQ','0012F00000XtUCtQAN');
INSERT INTO "Contact" VALUES('0032F00000UawOxQAJ','Lonnie','Bruce','false','','10 Ocean Parkway','Brooklyn','NY','','02317','false','false','','lonnie@bruce.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCFQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxUUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawOyQAJ','Deborah','Navarro','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','deborahmnavarro@cuvox.de','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','0.0','50.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-02','50.0','2018-01-02','50.0','2018-01-02','0.0','1.0','0.0','0.0','1.0','0.0','false','0012F00000XtUCGQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxVUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawOzQAJ','Bryce','Whitley','false','','840 Mount Street','Bay City','MI','','48706','false','false','','brycemwhitley@cuvox.de','Mobile','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCHQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxWUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawP0QAJ','Jon','Mendoza','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','jon@mendoza.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','0.0','100.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2018-04-20','100.0','2018-04-20','100.0','2018-04-20','0.0','1.0','0.0','0.0','1.0','0.0','false','0012F00000XtUCJQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxYUAQ','0012F00000XtUDCQA3');
INSERT INTO "Contact" VALUES('0032F00000UawP1QAJ','Julie','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','kim@kim.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','100.0','150.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','2.0','1.0','2.0','0.0','3.0','100.0','false','0012F00000XtUCKQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxZUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawP2QAJ','Leanne','Lewi','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','100.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-08-20','100.0','2019-08-20','100.0','2019-08-20','1.0','0.0','1.0','0.0','1.0','100.0','false','0012F00000XtUCMQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxbUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawP3QAJ','Brianna','Oden','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-09-23','125.0','2019-09-23','125.0','2019-09-23','1.0','0.0','1.0','0.0','1.0','125.0','false','0012F00000XtUCNQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxcUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawP4QAJ','Baptiste','Subrahmanya','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCOQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxdUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawP5QAJ','Nina','Shouta','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','225.0','225.0','0.0','','0.0','0.0','false','false','false','false','false','225.0','2019-08-22','225.0','2019-08-22','225.0','2019-08-22','1.0','0.0','1.0','0.0','1.0','225.0','false','0012F00000XtUCPQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxeUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawP6QAJ','Charlotte','Yudes','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCQQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxfUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawP7QAJ','Ansa','Primoz','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','100.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-08-25','100.0','2019-08-25','100.0','2019-08-25','1.0','0.0','1.0','0.0','1.0','100.0','false','0012F00000XtUCRQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxgUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawP8QAJ','Concepcion de Jesus','Waterman','false','','37179 Bedford Shores St','Cole City','KS','','62223','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCSQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007dq8EUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawP9QAJ','Sheridan','Luther','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','pavlut@lutes.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','10000.0','10000.0','0.0','','0.0','0.0','false','false','false','false','false','10000.0','2019-08-27','10000.0','2019-08-27','10000.0','2019-08-27','1.0','0.0','1.0','0.0','1.0','10000.0','false','0012F00000XtUCTQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxiUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPAQAZ','Nudd','Abbascia','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','7500.0','7500.0','0.0','','0.0','0.0','false','false','false','false','false','7500.0','2019-08-28','7500.0','2019-08-28','7500.0','2019-08-28','1.0','0.0','1.0','0.0','1.0','7500.0','false','0012F00000XtUCUQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxjUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPBQAZ','Kallistrate','Giannino','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','50.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2019-08-29','50.0','2019-08-29','50.0','2019-08-29','1.0','0.0','1.0','0.0','1.0','50.0','false','0012F00000XtUCVQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxkUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPCQAZ','Cassius','Guerra','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCWQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxlUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPDQAZ','Natasha','Geier','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','babsgeiger@happydogs.net','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','25.0','25.0','0.0','','0.0','0.0','false','false','false','false','false','25.0','2019-08-31','25.0','2019-08-31','25.0','2019-08-31','1.0','0.0','1.0','0.0','1.0','25.0','false','0012F00000XtUCXQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxmUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPEQAZ','Ursula','Maddox','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCYQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxnUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPFQAZ','Carly','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carly@kim.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','100.0','150.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','2.0','1.0','2.0','0.0','3.0','100.0','false','0012F00000XtUCKQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxZUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawPGQAZ','Kevin','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','100.0','150.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','2.0','1.0','2.0','0.0','3.0','100.0','false','0012F00000XtUCKQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxZUAQ','');
INSERT INTO "Contact" VALUES('0032F00000UawPHQAZ','Georgie','Campaign','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','georgie@campaigns.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCZQA3','','a0l2F000001XKCfQAO','','','','a0K2F000007doxoUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPIQAZ','Maia','Unnur','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','yudes@herbert.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCaQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxpUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPJQAZ','Charlie','Gibbons','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','crystalhmudd@fleckens.hu','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCbQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxqUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPKQAZ','Baron','Kovacevic','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCcQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxrUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPLQAZ','Nageen','Zappa','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCdQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxsUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPMQAZ','Suhani','Tan','false','','2425 9th Ave','Madison','CA','','70134','false','false','','suhanitan@snailmail.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCeQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxtUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPNQAZ','Carol','Bi','false','','2459 44th St E','Reston','VA','','71013','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCfQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxuUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPOQAZ','Deepshika','Offermans','false','','2493 89th Way','Seattle','WA','','98103','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCgQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxvUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPPQAZ','Helen','Castle','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUChQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxwUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPQQAZ','Aldegund','Sokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCiQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxxUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPRQAZ','Alexi','Nazarian','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCjQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxyUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPSQAZ','Mpho','McNeill','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUCkQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doxzUAA','');
INSERT INTO "Contact" VALUES('0032F00000UawPTQAZ','Louis','Devine','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtUClQAN','','a0l2F000001XKCfQAO','','','','','0012F00000XtUDDQA3');
INSERT INTO "Contact" VALUES('0032F00000UawPUQAZ','Lisa','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','350.0','350.0','0.0','','0.0','0.0','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','0.0','1.0','0.0','1.0','350.0','false','0012F00000XtUCmQAN','','a0l2F000001XKCfQAO','','','','a0K2F000007doy0UAA','');
INSERT INTO "Contact" VALUES('0032F00000Ub9G7QAJ','Jozef','Bateson','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','jozef45@hitchens.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtturQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT5UAI','0012F00000XtUD4QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G8QAJ','Natali','Frasier','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','vukasinmcneill49@narnia.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttusQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT6UAI','0012F00000XtUD9QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9G9QAJ','Gabriel','Prasad','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','gabrielsphd53@atoms.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttutQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT7UAI','0012F00000XtUDAQA3');
INSERT INTO "Contact" VALUES('0032F00000Ub9GAQAZ','Eleonora','Bates','false','','2493 89th Way','Seattle','WA','','98103','false','false','','eleonora61@scrumteam.net','Work','Work','Home','false','','','eleonora@scrumteam.net','(989) 777-4543','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuuQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT8UAI','0012F00000XtUD7QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9GBQAZ','Mirce','Bokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','soko73@protons.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuvQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT9UAI','0012F00000XtUD9QAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9GCQAZ','Diana','Mandela','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','dianarthomas79@superrito.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuwQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqTAUAY','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GDQAZ','Nashville','Watson','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','fionnur83@greensburg.ky.gov','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuxQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqTBUAY','0012F00000XtUCtQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9GEQAZ','Jon','Nguyen','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','jon@mendoza.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','0.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2018-04-20','125.0','2018-04-20','125.0','2018-04-20','0.0','1.0','0.0','0.0','1.0','0.0','false','0012F00000XttuJQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSaUAI','0012F00000XtUDCQA3');
INSERT INTO "Contact" VALUES('0032F00000Ub9GFQAZ','Lonnie','Bace','false','','10 Ocean Parkway','Brooklyn','NY','','2317','false','false','','lonnie@bruce.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuKQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSbUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GGQAZ','Calvin','Ivans','false','','','','','','','false','false','','rich@evansfam.com','Home','Personal','','false','','','rich@ballooga.com','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuiQAB','','a0l2F000001XKCfQAO','','','','','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GHQAZ','Felicity','Offermans','false','','1172 Boylston St.','Boston','MA','','2199','false','false','','felicia@ng.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuMQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqScUAI','0012F00000XtUCtQAN');
INSERT INTO "Contact" VALUES('0032F00000Ub9GIQAZ','Jason','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','1.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','3.0','0.0','3.0','0.0','3.0','205.0','false','0012F00000XttuNQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSdUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GJQAZ','Elias','Whitley','false','','1 Cherry Street','Pleasant','NJ','','7777','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuOQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSeUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GKQAZ','Orion','Unnur','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuPQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSfUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GLQAZ','Brianna','Shouta','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','160.0','160.0','0.0','','0.0','0.0','false','false','false','false','false','160.0','2019-09-23','160.0','2019-09-23','160.0','2019-09-23','1.0','0.0','1.0','0.0','1.0','160.0','false','0012F00000XttuQQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSgUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GMQAZ','Carly','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carly@kim.com','Home','Personal','Home','false','','','','','0.0','','','','3.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','3.0','0.0','3.0','0.0','3.0','205.0','false','0012F00000XttuNQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSdUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GNQAZ','Julie','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','kim@kim.com','Home','Personal','Home','false','','','','','0.0','','','','5.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','3.0','0.0','3.0','0.0','3.0','205.0','false','0012F00000XttuNQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSdUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GOQAZ','Stapleton','Mavis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuTQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSjUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GPQAZ','Deborah','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','deborahmnavarro@cuvox.de','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-01-02','75.0','2019-01-02','75.0','2019-01-02','1.0','0.0','1.0','0.0','1.0','75.0','false','0012F00000XttuUQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSkUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GQQAZ','Olivia','Tan','false','','4270 4th Court','Arlington','MA','','2128','false','false','','chipboat@chippy.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-01-22','75.0','2019-01-22','75.0','2019-01-22','1.0','0.0','1.0','0.0','1.0','75.0','false','0012F00000XttuVQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSmUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GRQAZ','Denorah','Loui','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-05-01','125.0','2019-05-01','125.0','2019-05-01','1.0','0.0','1.0','0.0','1.0','125.0','false','0012F00000XttuWQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSnUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GSQAZ','Neve','Wong','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuXQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSoUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GTQAZ','Nina','Waterman','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','300.0','300.0','0.0','','0.0','0.0','false','false','false','false','false','300.0','2019-05-03','300.0','2019-05-03','300.0','2019-05-03','1.0','0.0','1.0','0.0','1.0','300.0','false','0012F00000XttuYQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSpUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GUQAZ','Charlotte','Rudddles','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuZQAR','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSqUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GVQAZ','Ansa','Subrahmanya','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-05-05','125.0','2019-05-05','125.0','2019-05-05','1.0','0.0','1.0','0.0','1.0','125.0','false','0012F00000XttuaQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSrUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GWQAZ','Nitika','Wong','false','','37179 Bedford Shores St','Fairfield','KS','','62223','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttubQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSsUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GXQAZ','Buddy','Zappa','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','9375.0','9375.0','0.0','','0.0','0.0','false','false','false','false','false','9375.0','2019-05-08','9375.0','2019-05-08','9375.0','2019-05-08','1.0','0.0','1.0','0.0','1.0','9375.0','false','0012F00000XttucQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqStUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GYQAZ','Kallistrate','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-05-09','75.0','2019-05-09','75.0','2019-05-09','1.0','0.0','1.0','0.0','1.0','75.0','false','0012F00000XttudQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSuUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GZQAZ','Nancy','Primoz','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttueQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSvUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GaQAJ','Maya','Geiser-Bann','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','babsgeiger@happydogs.net','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','30.0','30.0','0.0','','0.0','0.0','false','false','false','false','false','30.0','2019-05-11','30.0','2019-05-11','30.0','2019-05-11','1.0','0.0','1.0','0.0','1.0','30.0','false','0012F00000XttufQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSwUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GbQAJ','Bryce','Nazarian','false','','840 Mount Street','Bay City','MI','','48706','false','false','','brycemwhitley@cuvox.de','Mobile','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttugQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSxUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GcQAJ','Pavlina','Dominico','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','pavlut@lutes.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','12500.0','12500.0','0.0','','0.0','0.0','false','false','false','false','false','12500.0','2019-05-07','12500.0','2019-05-07','12500.0','2019-05-07','1.0','0.0','1.0','0.0','1.0','12500.0','false','0012F00000XttujQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSyUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GdQAJ','Linda','Figueroo','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','linda@nguyen.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttukQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqSzUAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GeQAJ','Harold','Campagna','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','georgie@campaigns.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttulQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT0UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GfQAJ','Helena','Clerk','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttumQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT1UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GgQAJ','Xiao-yu','Kanban','false','','2459 44th St E','Reston','VA','','71013','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttunQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT2UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GhQAJ','Louis','Primordial','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuoQAB','','a0l2F000001XKCfQAO','','','','','0012F00000XtUDDQA3');
INSERT INTO "Contact" VALUES('0032F00000Ub9GiQAJ','Suhani','Djyradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','suhanitan@snailmail.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttupQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT3UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GjQAJ','Roger','Kasprawicz','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuqQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT4UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GkQAJ','Nageen','Navarro','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtturQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT5UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GlQAJ','Mpho','Ng','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttusQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT6UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GmQAJ','Bartolomej','Oden','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttutQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT7UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GnQAJ','Krithika','Sokolov','false','','2493 89th Way','Seattle','WA','','98103','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuuQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT8UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GoQAJ','Aldegund','Wong','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuvQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqT9UAI','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GpQAJ','Crystal','Yudes','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','crystalhmudd@fleckens.hu','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuwQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqTAUAY','');
INSERT INTO "Contact" VALUES('0032F00000Ub9GqQAJ','Evrim','Watson','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','yudes@herbert.com','Home','Personal','Home','false','','','','','0.0','','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XttuxQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dqTBUAY','');
INSERT INTO "Contact" VALUES('0032F00000Ub7d0QAB','Jessie','Nostdal','false','','762 Smiley','Port Townsend','WA','','98368','false','false','','drjessie@nostdalworks.com','Home','Personal','Home','false','','','','','0.0','','','','0.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtnohQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dq0VUAQ','0012F00000XtnlOQAR');
INSERT INTO "Contact" VALUES('0032F00000Ub7erQAB','Zach','Rymph','false','','762 Smiley','Port Townsend','WA','','98368','false','false','','','Home','Personal','Home','false','','','','','0.0','','','','1.0','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','','','','','0.0','0.0','false','false','false','false','false','','','','','','','','','','','','0.0','false','0012F00000XtnohQAB','','a0l2F000001XKCfQAO','','','','a0K2F000007dq0VUAQ','');
CREATE TABLE "Event" (
	id INTEGER NOT NULL, 
	"ActivityDate" VARCHAR(255), 
	"Description" VARCHAR(255), 
	"Type" VARCHAR(255), 
	"WhoId" VARCHAR(255), 
	"StartDateTime" VARCHAR(255), 
	"EndDateTime" VARCHAR(255), 
	"Subject" VARCHAR(255), 
	"Location" VARCHAR(255), 
	"OwnerId" VARCHAR(255), 
	"WhatId" VARCHAR(255), 
	PRIMARY KEY (id)
);
INSERT INTO "Event" VALUES(1,'2019-12-16','Conversation to explore creating an advisory committee of major donors.','','0032F00000Ub9FsQAJ','2019-12-16T22:00:00.000Z','2019-12-16T23:00:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0052F000004hRJdQAM','');
INSERT INTO "Event" VALUES(2,'2019-11-11','Conversation to explore creating an advisory committee of major donors.','Meeting','0032F00000UawOFQAZ','2019-11-11T17:30:00.000Z','2019-11-11T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0052F000004hRJdQAM','');
INSERT INTO "Event" VALUES(3,'2019-12-03','Conversation to explore creating an advisory committee of major donors.','Meeting','0032F00000UawOZQAZ','2019-12-03T21:00:00.000Z','2019-12-03T22:00:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0052F000004hRJdQAM','');
INSERT INTO "Event" VALUES(4,'2019-12-10','Conversation to explore creating an advisory committee of major donors.','Meeting','0032F00000Ub9FsQAJ','2019-12-10T17:30:00.000Z','2019-12-10T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0052F000004hRJdQAM','');
INSERT INTO "Event" VALUES(5,'2019-12-13','Conversation to explore creating an advisory committee of major donors.','Meeting','0032F00000UawOYQAZ','2019-12-13T17:30:00.000Z','2019-12-13T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0052F000004hRJdQAM','');
INSERT INTO "Event" VALUES(6,'2019-12-11','Conversation to explore creating an advisory committee of major donors.','Meeting','0032F00000Ub9FzQAJ','2019-12-11T17:30:00.000Z','2019-12-11T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0052F000004hRJdQAM','');
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
INSERT INTO "Lead" VALUES('00Q2F0000070FbQUAU','Joshua','Kim','Self','false','false','false','false','false','Open - Not Contacted','Web','','','','','','','','');
INSERT INTO "Lead" VALUES('00Q2F000006zG0fUAE','Katie','Beaker','Self','false','false','false','false','false','Open - Not Contacted','','','','','','','','','');
INSERT INTO "Lead" VALUES('00Q2F000006zG0kUAE','Chloe','Jackson','Self','false','false','false','false','false','Open - Not Contacted','Web','','','','','','','','');
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
INSERT INTO "Opportunity" VALUES('0062F000008qEmLQAU','Nilza Hernandez Donation 4/20/2018','2018-04-20','false','0122F000000SQwEQAW','Posted','Donation','125.0','0032F00000Ub9FYQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuJQAR','7012F000000LvPqQAK','','','','','','','','0032F00000Ub9FYQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmMQAU','Orange Company Donation 5/21/2018','2018-05-21','false','0122F000000SQwEQAW','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCrQAN','7012F000000LvPqQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmNQAU','Beatrice Ivans Donation 11/5/2018','2018-11-05','false','0122F000000SQwEQAW','Posted','','125.0','0032F00000Ub9FaQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuLQAR','7012F000000LvPqQAK','','','','','','','','0032F00000Ub9FaQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmOQAU','Johnson''s General Stores Donation 3/1/2019','2019-03-01','false','0122F000000SQwEQAW','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCqQAN','7012F000000LvPqQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmPQAU','Mattias Chong Donation 1/1/2019','2019-01-01','false','0122F000000SQwEQAW','Posted','Donation','100.0','0032F00000Ub9FcQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuNQAR','7012F000000LvPsQAK','','','','','','','','0032F00000Ub9FcQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmQQAU','Orange Tree Imports Donation 8/2/2019','2019-08-02','false','0122F000000SQwEQAW','Posted','Donation','75.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCuQAN','7012F000000LvPsQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmRQAU','American Firefights for Freedom Donation 9/2/2019','2019-09-02','false','0122F000000SQwEQAW','Posted','Donation','100.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XttuyQAB','7012F000000LvPsQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmSQAU','Llew Loki Donation 9/23/2019','2019-09-23','false','0122F000000SQwEQAW','Posted','Donation','160.0','0032F00000Ub9FfQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuQQAR','7012F000000LvPsQAK','','','','','','','','0032F00000Ub9FfQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmTQAU','Mattias Chong Donation 1/1/2019','2019-01-01','false','0122F000000SQwEQAW','Posted','Donation','30.0','0032F00000Ub9FgQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuNQAR','7012F000000LvfHQAS','','','','','','','','0032F00000Ub9FgQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmUQAU','Mattias Chong Donation 1/1/2019','2019-01-01','false','0122F000000SQwEQAW','Posted','Donation','75.0','0032F00000Ub9FhQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuNQAR','7012F000000LvfHQAS','','','','','','','','0032F00000Ub9FhQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmVQAU','Music Foundation Major Gift 1/1/2019','2019-01-01','false','0122F000000SQwJQAW','Posted','Donation','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCtQAN','7012F000000LvfHQAS','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmWQAU','Daphne Bainter Donation 1/2/2019','2019-01-02','false','0122F000000SQwEQAW','Posted','Donation','75.0','0032F00000Ub9FjQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuUQAR','7012F000000LvfHQAS','','','','','','','','0032F00000Ub9FjQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmXQAU','Celia-Rae Boston Donation 1/22/2019','2019-01-22','false','0122F000000SQwEQAW','Posted','Donation','75.0','0032F00000Ub9FkQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XtUCDQA3','7012F000000LvfHQAS','','','','','','','','0032F00000Ub9FkQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmYQAU','Big Orange Donation 1/22/2019','2019-01-22','false','0122F000000SQwEQAW','Posted','Donation','75.0','0032F00000Ub9FlQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuVQAR','7012F000000LvfHQAS','','','','','','','','0032F00000Ub9FlQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmZQAU','Tasgall Loui Donation 5/1/2019','2019-05-01','false','0122F000000SQwEQAW','Posted','Donation','125.0','0032F00000Ub9FmQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuWQAR','7012F000000LvfIQAS','','','','','','','','0032F00000Ub9FmQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmaQAE','Orange Tree Imports Donation 5/2/2019','2019-05-02','false','0122F000000SQwEQAW','Posted','Donation','15.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCuQAN','7012F000000LvfIQAS','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmbQAE','Natalija George Donation 5/3/2019','2019-05-03','false','0122F000000SQwEQAW','Posted','Donation','300.0','0032F00000Ub9FoQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuYQAR','7012F000000LvfIQAS','','','','','','','','0032F00000Ub9FoQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmcQAE','Johnson''s General Stores Donation 5/4/2019','2019-05-04','false','0122F000000SQwEQAW','Posted','Donation','75.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCqQAN','7012F000000LvfIQAS','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmdQAE','Jeffry de la O Donation 5/5/2019','2019-05-05','false','0122F000000SQwEQAW','Posted','Donation','125.0','0032F00000Ub9FqQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuaQAB','7012F000000LvfIQAS','','','','','','','','0032F00000Ub9FqQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmeQAE','Gnarl''s Bicycles Donation 5/6/2019','2019-05-06','false','0122F000000SQwEQAW','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCwQAN','7012F000000LvfIQAS','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmfQAE','Eugenius Trelawni Major Gift 5/8/2019','2019-05-08','false','0122F000000SQwJQAW','Posted','Donation','9375.0','0032F00000Ub9FsQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttucQAB','7012F000000LvfIQAS','','','','','','','','0032F00000Ub9FsQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmgQAE','Mattia Aethelstan Donation 5/9/2019','2019-05-09','false','0122F000000SQwEQAW','Posted','Donation','75.0','0032F00000Ub9FtQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttudQAB','7012F000000LvfIQAS','','','','','','','','0032F00000Ub9FtQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmhQAE','Blotts, Hargrove and Spludge Major Gift 5/10/2019','2019-05-10','false','0122F000000SQwJQAW','Posted','Donation','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUD0QAN','7012F000000LvfIQAS','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmiQAE','Bennett Geiser-Bann Donation 5/11/2019','2019-05-11','false','0122F000000SQwEQAW','Posted','Donation','30.0','0032F00000Ub9FvQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttufQAB','7012F000000LvfIQAS','','','','','','','','0032F00000Ub9FvQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmjQAE','Acme Corporation Grant 6/30/2018','2018-06-30','false','0122F000000SQwBQAW','Posted','Grant','12500.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCsQAN','7012F000000LvPrQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmkQAE','Beatrice Ivans Donation 11/4/2018','2018-11-04','false','0122F000000SQwEQAW','Posted','','75.0','0032F00000Ub9FxQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttuhQAB','7012F000000LvPrQAK','','','','','','','','0032F00000Ub9FxQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmlQAE','Cloud Kicks Major Gift 11/4/2018','2018-11-04','false','0122F000000SQwJQAW','Posted','New Funding','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCnQAN','7012F000000LvPrQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qEmmQAE','Em Dominico Major Gift 5/7/2019','2019-05-07','false','0122F000000SQwJQAW','Posted','Donation','12500.0','0032F00000Ub9FzQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttujQAB','7012F000000LvPrQAK','','','','','','','','0032F00000Ub9FzQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qEmnQAE','Roger Figueroo Major Gift 11/4/2020','2020-11-04','false','0122F000000SQwJQAW','Verbal Commitment','New Funding','375000.0','0032F00000Ub9G0QAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0012F00000XttukQAB','7012F000000LvPrQAK','','','','','','','','0032F00000Ub9G0QAJ');
INSERT INTO "Opportunity" VALUES('0062F000008yq5AQAQ','Robert Bullard Donation 12/10/2019','2019-12-10','false','0122F000000SQwEQAW','Posted','','350.0','0032F00000UawOrQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCmQAN','7012F000000LvPqQAK','','','','','','','','0032F00000UawOrQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMJQA2','Candace Evans Donation (1) 12/1/2018','2018-12-01','false','0122F000000SQwEQAW','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','1.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMKQA2','Candace Evans Donation (2) 1/1/2019','2019-01-01','false','0122F000000SQwEQAW','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','2.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMLQA2','Candace Evans Donation (3) 2/1/2019','2019-02-01','false','0122F000000SQwEQAW','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','3.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMMQA2','Candace Evans Donation (4) 3/1/2019','2019-03-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','4.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMNQA2','Candace Evans Donation (5) 4/1/2019','2019-04-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','5.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMOQA2','Candace Evans Donation (6) 5/1/2019','2019-05-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','6.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMPQA2','Candace Evans Donation (7) 6/1/2019','2019-06-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','7.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMQQA2','Candace Evans Donation (8) 7/1/2019','2019-07-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','8.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMRQA2','Candace Evans Donation (9) 8/1/2019','2019-08-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','9.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMSQA2','Candace Evans Donation (10) 9/1/2019','2019-09-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','10.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMTQA2','Candace Evans Donation (11) 10/1/2019','2019-10-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','11.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMUQA2','Candace Evans Donation (12) 11/1/2019','2019-11-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','12.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMVQA2','Candace Evans Donation (13) 12/1/2019','2019-12-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','13.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMWQA2','Candace Evans Donation (14) 1/1/2020','2020-01-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','14.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMXQA2','Candace Evans Donation (15) 2/1/2020','2020-02-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','15.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMYQA2','Candace Evans Donation (16) 3/1/2020','2020-03-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','16.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMZQA2','Candace Evans Donation (17) 4/1/2020','2020-04-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','17.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMaQAM','Candace Evans Donation (18) 5/1/2020','2020-05-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','18.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMbQAM','Candace Evans Donation (19) 6/1/2020','2020-06-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','19.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMcQAM','Candace Evans Donation (20) 7/1/2020','2020-07-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','20.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMdQAM','Candace Evans Donation (21) 8/1/2020','2020-08-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','21.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMeQAM','Candace Evans Donation (22) 9/1/2020','2020-09-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','22.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMfQAM','Candace Evans Donation (23) 10/1/2020','2020-10-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','23.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMgQAM','Candace Evans Donation (24) 11/1/2020','2020-11-01','false','0122F000000SQwEQAW','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','24.0','','','0012F00000XtUCAQA3','7012F000000LvPvQAK','a092F000002bGIkQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKEQA2','Candace Evans Donation 11/5/2018','2018-11-05','false','0122F000000SQwEQAW','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCAQA3','7012F000000LvPqQAK','','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKFQA2','Jose Figueroa Major Gift 11/4/2020','2020-11-04','false','0122F000000SQwJQAW','Verbal Commitment','New Funding','300000.0','0032F00000UawOGQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCBQA3','7012F000000LvPrQAK','','','','','','','','0032F00000UawOGQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKGQA2','Candace Evans Donation 11/4/2018','2018-11-04','false','0122F000000SQwEQAW','Posted','','50.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKHQA2','Cloud Kicks Donation 11/4/2018','2018-11-04','false','0122F000000SQwEQAW','Posted','New Funding','1000.0','','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCnQAN','7012F000000LvPrQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKIQA2','Big Red Donation 1/22/2018','2018-01-22','false','0122F000000SQwEQAW','Posted','Donation','50.0','0032F00000UawOHQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCCQA3','7012F000000LvPqQAK','','','','','','','','0032F00000UawOHQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKJQA2','Celia Boston Donation 1/22/2018','2018-01-22','false','0122F000000SQwEQAW','Posted','Donation','50.0','0032F00000UawOIQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCDQA3','7012F000000LvPqQAK','','','','','','','','0032F00000UawOIQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKKQA2','Johnson''s General Stores Donation 3/1/2018','2018-03-01','false','0122F000000SQwEQAW','Posted','Donation','100.0','','false','','','','','All Opportunities','2018-03-10','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCqQAN','7012F000000LvPqQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKQQA2','Carl Kim Donation 1/1/2018','2018-01-01','false','0122F000000SQwEQAW','Posted','Donation','50.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCKQA3','7012F000000LvPqQAK','','','','','','','','0032F00000UawOPQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKRQA2','Orange Tree Imports Donation 8/2/2019','2019-08-02','false','0122F000000SQwEQAW','Posted','Donation','50.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCuQAN','7012F000000LvPsQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKSQA2','Tasgall Lewi Donation 8/20/2019','2019-08-20','false','0122F000000SQwEQAW','Posted','Donation','100.0','0032F00000UawORQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCMQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawORQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKTQA2','Llew Oden Donation 9/23/2019','2019-09-23','false','0122F000000SQwEQAW','Posted','Donation','125.0','0032F00000UawOSQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCNQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOSQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKLQA2','Orange Company Donation 5/21/2018','2018-05-21','false','0122F000000SQwEQAW','Posted','Donation','100.0','','false','','','','','All Opportunities','2018-05-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCrQAN','7012F000000LvPqQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKMQA2','Daphne Bainter Donation 1/2/2018','2018-01-02','false','0122F000000SQwEQAW','Posted','Donation','50.0','0032F00000UawOLQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCGQA3','7012F000000LvPqQAK','','','','','','','','0032F00000UawOLQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKNQA2','Acme Corporation Grant 6/30/2018','2018-06-30','false','0122F000000SQwBQAW','Posted','Grant','10000.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCsQAN','7012F000000LvPqQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKOQA2','Music Foundation Donation 1/1/2018','2018-01-01','false','0122F000000SQwEQAW','Posted','Donation','1000.0','','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCtQAN','7012F000000LvPqQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKPQA2','Nilza Mendoza Donation 4/20/2018','2018-04-20','false','0122F000000SQwEQAW','Posted','Donation','100.0','0032F00000UawOOQAZ','false','','','','','All Opportunities','2018-04-20','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCJQA3','7012F000000LvPqQAK','','','','','','','','0032F00000UawOOQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKUQA2','Orange Tree Imports Donation 8/22/2019','2019-08-22','false','0122F000000SQwEQAW','Posted','Donation','10.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCuQAN','7012F000000LvPsQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKVQA2','Natalija Shouta Donation 8/22/2019','2019-08-22','false','0122F000000SQwEQAW','Posted','Donation','225.0','0032F00000UawOUQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCPQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOUQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKWQA2','Johnson''s General Stores Donation 8/23/2019','2019-08-23','false','0122F000000SQwEQAW','Posted','Donation','50.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCqQAN','7012F000000LvPsQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKXQA2','Jeffry Primoz Donation 8/25/2019','2019-08-25','false','0122F000000SQwEQAW','Posted','Donation','100.0','0032F00000UawOWQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCRQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOWQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKYQA2','Gnarl''s Bicycles Donation 8/26/2019','2019-08-26','false','0122F000000SQwEQAW','Posted','Donation','100.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCwQAN','7012F000000LvPsQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKaQAM','Eugenius Thulani Donation 8/28/2019','2019-08-28','false','0122F000000SQwEQAW','Posted','Donation','7500.0','0032F00000UawOZQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCUQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOZQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKbQAM','Mattia Aethelstan Donation 8/29/2019','2019-08-29','false','0122F000000SQwEQAW','Posted','Donation','50.0','0032F00000UawOaQAJ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCVQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOaQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKcQAM','Blotts, Hargrove and Spludge Donation 8/30/2019','2019-08-30','false','0122F000000SQwEQAW','Posted','Donation','1000.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUD0QAN','7012F000000LvPsQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKdQAM','Marat Geier Donation 8/31/2019','2019-08-31','false','0122F000000SQwEQAW','Posted','Donation','25.0','0032F00000UawOcQAJ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCXQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOcQAJ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKeQAM','American Firefighters for Historic Books','2019-09-02','false','0122F000000SQwEQAW','Posted','Donation','75.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUD2QAN','7012F000000LvPsQAK','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0062F000008qDKfQAM','Carl Kim Donation 1/1/2019','2019-01-01','false','0122F000000SQwEQAW','Posted','Donation','25.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCKQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOPQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKgQAM','Carl Kim Donation 1/1/2019','2019-01-01','false','0122F000000SQwEQAW','Posted','Donation','75.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCKQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOPQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMhQAM','Candace Evans Donation (1 of 12) 11/30/2018','2018-11-30','false','0122F000000SQwEQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','1.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMiQAM','Candace Evans Donation (2 of 12) 2/28/2019','2019-02-28','false','0122F000000SQwEQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','2.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMjQAM','Candace Evans Donation (3 of 12) 5/31/2019','2019-05-31','false','0122F000000SQwEQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-06-02','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','3.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMkQAM','Candace Evans Donation (4 of 12) 8/31/2019','2019-08-31','false','0122F000000SQwEQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','4.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMlQAM','Candace Evans Donation (5 of 12) 11/30/2019','2019-11-30','false','0122F000000SQwEQAW','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-11-01','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','5.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMmQAM','Candace Evans Donation (6 of 12) 2/29/2020','2020-02-29','false','0122F000000SQwEQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','6.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMnQAM','Candace Evans Donation (7 of 12) 5/31/2020','2020-05-31','false','0122F000000SQwEQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','7.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMoQAM','Candace Evans Donation (8 of 12) 8/31/2020','2020-08-31','false','0122F000000SQwEQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','8.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMpQAM','Candace Evans Donation (9 of 12) 11/30/2020','2020-11-30','false','0122F000000SQwEQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','9.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMqQAM','Candace Evans Donation (10 of 12) 2/28/2021','2021-02-28','false','0122F000000SQwEQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','10.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMrQAM','Candace Evans Donation (11 of 12) 5/31/2021','2021-05-31','false','0122F000000SQwEQAW','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','11.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDMsQAM','Candace Evans Donation (12 of 12) 8/31/2021','2021-08-31','false','0122F000000SQwEQAW','Pledged','','833.37','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','12.0','','','0012F00000XtUCAQA3','7012F000000LvPrQAK','a092F000002bGIpQAM','','','','','','','0032F00000UawOFQAZ');
INSERT INTO "Opportunity" VALUES('0062F000008qDKZQA2','Em Dominika Donation 8/27/2019','2019-08-27','false','0122F000000SQwEQAW','Posted','Donation','10000.0','0032F00000UawOYQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0012F00000XtUCTQA3','7012F000000LvPsQAK','','','','','','','','0032F00000UawOYQAZ');
CREATE TABLE "Opportunity_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "Opportunity_rt_mapping" VALUES('0122F000000SQwEQAW','Donation');
INSERT INTO "Opportunity_rt_mapping" VALUES('0122F000000SQwBQAW','Grant');
INSERT INTO "Opportunity_rt_mapping" VALUES('0122F000000SQwMQAW','InKindGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0122F000000SQwJQAW','MajorGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0122F000000SQwKQAW','MatchingGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0122F000000SQwGQAW','Membership');
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
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PrZ2QAK','','','true','350.0','2019-12-10','','','false','','','0062F000008yq5AQAQ');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRgQAK','','','true','125.0','2018-04-20','Credit','','false','','','0062F000008qEmLQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRhQAK','','','true','125.0','2018-05-21','Credit','','false','','','0062F000008qEmMQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRiQAK','','','true','125.0','2018-11-05','Credit','','false','','','0062F000008qEmNQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRjQAK','225','','true','125.0','2019-03-01','Check','','false','','','0062F000008qEmOQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRkQAK','123','','true','100.0','2019-01-01','Check','','false','','','0062F000008qEmPQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRlQAK','','','true','75.0','2019-08-02','Cash','','false','','','0062F000008qEmQQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRmQAK','','','true','100.0','2019-09-02','Cash','','false','','','0062F000008qEmRQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRnQAK','888','','true','160.0','2019-09-23','Check','','false','','','0062F000008qEmSQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRoQAK','2294','','true','30.0','2019-01-01','Check','','false','','','0062F000008qEmTQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRpQAK','39566','','true','75.0','2019-01-01','Check','','false','','','0062F000008qEmUQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRqQAK','6226','','true','1250.0','2019-01-01','Check','','false','','','0062F000008qEmVQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRrQAK','342','','true','75.0','2019-01-02','Check','','false','','','0062F000008qEmWQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRsQAK','888','','true','75.0','2019-01-22','Check','','false','','','0062F000008qEmXQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRtQAK','888','','true','75.0','2019-01-22','Check','','false','','','0062F000008qEmYQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRuQAK','','','true','125.0','2019-05-01','Cash','','false','','','0062F000008qEmZQAU');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRvQAK','888','','true','15.0','2019-05-02','Check','','false','','','0062F000008qEmaQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRwQAK','','','true','300.0','2019-05-03','Credit','','false','','','0062F000008qEmbQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRxQAK','','','true','75.0','2019-05-04','Credit','','false','','','0062F000008qEmcQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRyQAK','','','true','125.0','2019-05-05','Crecit','','false','','','0062F000008qEmdQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgRzQAK','342','','true','125.0','2019-05-06','Check','','false','','','0062F000008qEmeQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS0QAK','2294','','true','9375.0','2019-05-08','Check','','false','','','0062F000008qEmfQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS1QAK','39566','','true','75.0','2019-05-09','Check','','false','','','0062F000008qEmgQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS2QAK','123','','true','1250.0','2019-05-10','Check','','false','','','0062F000008qEmhQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS3QAK','','','true','30.0','2019-05-11','Credit','','false','','','0062F000008qEmiQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS4QAK','966','','true','12500.0','2018-06-30','Check','','false','','','0062F000008qEmjQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS5QAK','','','true','75.0','2018-11-04','Credit','','false','','','0062F000008qEmkQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS6QAK','1001','','true','1250.0','2018-11-04','Check','','false','','','0062F000008qEmlQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS7QAK','6226','','true','12500.0','2019-05-07','Check','','false','','','0062F000008qEmmQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PgS8QAK','','','false','375000.0','','Credit','2020-11-04','false','','','0062F000008qEmnQAE');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfBzQAK','','','true','50000.0','2018-11-04','Credit Card','2018-11-04','false','','','0062F000008qDKFQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfC0QAK','','','false','50000.0','','Credit Card','2019-05-04','true','','','0062F000008qDKFQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfC1QAK','','','true','50000.0','2019-11-05','Credit Card','2019-11-04','false','','','0062F000008qDKFQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfC5QAK','','','false','150000.0','2019-12-04','','','true','','','0062F000008qDKFQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCAQA0','','','true','100.0','2018-12-01','','2018-12-01','false','','','0062F000008qDMJQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCBQA0','','','true','100.0','2019-01-01','','2019-01-01','false','','','0062F000008qDMKQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCCQA0','','','true','100.0','2019-02-01','','2019-02-01','false','','','0062F000008qDMLQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCDQA0','','','false','100.0','','','2019-03-01','false','','','0062F000008qDMMQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCEQA0','','','false','100.0','','','2019-04-01','false','','','0062F000008qDMNQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCFQA0','','','false','100.0','','','2019-05-01','false','','','0062F000008qDMOQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCGQA0','','','false','100.0','','','2019-06-01','false','','','0062F000008qDMPQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCHQA0','','','false','100.0','','','2019-07-01','false','','','0062F000008qDMQQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCIQA0','','','false','100.0','','','2019-08-01','false','','','0062F000008qDMRQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCJQA0','','','false','100.0','','','2019-09-01','false','','','0062F000008qDMSQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCKQA0','','','false','100.0','','','2019-10-01','false','','','0062F000008qDMTQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCLQA0','','','false','100.0','','','2019-11-01','false','','','0062F000008qDMUQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCMQA0','','','false','100.0','','','2019-12-01','false','','','0062F000008qDMVQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCNQA0','','','false','100.0','','','2020-01-01','false','','','0062F000008qDMWQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCOQA0','','','false','100.0','','','2020-02-01','false','','','0062F000008qDMXQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCPQA0','','','false','100.0','','','2020-03-01','false','','','0062F000008qDMYQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCQQA0','','','false','100.0','','','2020-04-01','false','','','0062F000008qDMZQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCRQA0','','','false','100.0','','','2020-05-01','false','','','0062F000008qDMaQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCSQA0','','','false','100.0','','','2020-06-01','false','','','0062F000008qDMbQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCTQA0','','','false','100.0','','','2020-07-01','false','','','0062F000008qDMcQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCUQA0','','','false','100.0','','','2020-08-01','false','','','0062F000008qDMdQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCVQA0','','','false','100.0','','','2020-09-01','false','','','0062F000008qDMeQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCWQA0','','','false','100.0','','','2020-10-01','false','','','0062F000008qDMfQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCXQA0','','','false','100.0','','','2020-11-01','false','','','0062F000008qDMgQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCYQA0','','','true','833.33','2018-11-30','','2018-11-30','false','','','0062F000008qDMhQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCZQA0','','','true','833.33','2019-02-28','','2019-02-28','false','','','0062F000008qDMiQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCaQAK','','','true','833.33','2019-05-31','','2019-05-31','false','','','0062F000008qDMjQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCbQAK','','','true','833.33','2019-08-31','','2019-08-31','false','','','0062F000008qDMkQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCcQAK','','','true','833.33','2019-11-30','','2019-11-30','false','','','0062F000008qDMlQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCdQAK','','','false','833.33','','','2020-02-29','false','','','0062F000008qDMmQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCeQAK','','','false','833.33','','','2020-05-31','false','','','0062F000008qDMnQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCfQAK','','','false','833.33','','','2020-08-31','false','','','0062F000008qDMoQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCgQAK','','','false','833.33','','','2020-11-30','false','','','0062F000008qDMpQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfChQAK','','','false','833.33','','','2021-02-28','false','','','0062F000008qDMqQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCiQAK','','','false','833.33','','','2021-05-31','false','','','0062F000008qDMrQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfCjQAK','','','false','833.37','','','2021-08-31','false','','','0062F000008qDMsQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAiQAK','','','true','100.0','2018-11-05','Credit','','false','','','0062F000008qDKEQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAkQAK','','','true','50.0','2018-11-04','Credit','','false','','','0062F000008qDKGQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAlQAK','1001','','true','1000.0','2018-11-04','Check','','false','','','0062F000008qDKHQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAmQAK','888','','true','50.0','2018-01-22','Check','','false','','','0062F000008qDKIQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAnQAK','888','','true','50.0','2018-01-22','Check','','false','','','0062F000008qDKJQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAoQAK','225','','true','100.0','2018-03-01','Check','','false','','','0062F000008qDKKQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfApQAK','','','true','100.0','2018-05-21','Credit','','false','','','0062F000008qDKLQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAqQAK','342','','true','50.0','2018-01-02','Check','','false','','','0062F000008qDKMQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfArQAK','966','','true','10000.0','2018-06-30','Check','','false','','','0062F000008qDKNQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAsQAK','6226','','true','1000.0','2018-01-01','Check','','false','','','0062F000008qDKOQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAtQAK','','','true','100.0','2018-04-20','Credit','','false','','','0062F000008qDKPQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAuQAK','39566','','true','50.0','2018-01-01','Check','','false','','','0062F000008qDKQQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAvQAK','','','true','50.0','2019-08-02','Cash','','false','','','0062F000008qDKRQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAwQAK','','','true','100.0','2019-08-20','Cash','','false','','','0062F000008qDKSQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAxQAK','888','','true','125.0','2019-09-23','Check','','false','','','0062F000008qDKTQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAyQAK','888','','true','10.0','2019-08-22','Check','','false','','','0062F000008qDKUQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfAzQAK','','','true','225.0','2019-08-22','Credit','','false','','','0062F000008qDKVQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB0QAK','','','true','50.0','2019-08-23','Credit','','false','','','0062F000008qDKWQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB1QAK','','','true','100.0','2019-08-25','Crecit','','false','','','0062F000008qDKXQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB2QAK','342','','true','100.0','2019-08-26','Check','','false','','','0062F000008qDKYQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB3QAK','6226','','true','10000.0','2019-08-27','Check','','false','','','0062F000008qDKZQA2');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB4QAK','2294','','true','7500.0','2019-08-28','Check','','false','','','0062F000008qDKaQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB5QAK','39566','','true','50.0','2019-08-29','Check','','false','','','0062F000008qDKbQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB6QAK','123','','true','1000.0','2019-08-30','Check','','false','','','0062F000008qDKcQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB7QAK','','','true','25.0','2019-08-31','Credit','','false','','','0062F000008qDKdQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB8QAK','','','true','75.0','2019-09-02','Cash','','false','','','0062F000008qDKeQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfB9QAK','2294','','true','25.0','2019-01-01','Check','','false','','','0062F000008qDKfQAM');
INSERT INTO "npe01__OppPayment__c" VALUES('a012F000008PfBAQA0','123','','true','75.0','2019-01-01','Check','','false','','','0062F000008qDKgQAM');
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
INSERT INTO "npe03__Recurring_Donation__c" VALUES('a092F000002bGIkQAM','Give a Life - Evans and Wong Household','100.0','2018-11-01','Monthly','1.0','2019-02-01','2019-03-01','Open','300.0','Multiply By','3.0','false','1','0032F00000UawOFQAZ','','7012F000000LvPvQAK');
INSERT INTO "npe03__Recurring_Donation__c" VALUES('a092F000002bGIpQAM','NMH Transitional Housing Capital Campaign - Evans and Wong Household','10000.0','2018-11-05','Quarterly','12.0','2019-11-30','2020-02-29','None','4166.65','Divide By','5.0','true','30','0032F00000UawOFQAZ','','7012F000000LvPrQAK');
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
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9bJUAQ','','false','Current','Son','','0032F00000Ub0UmQAJ','a0G2F000003t9bKUAQ','0032F00000Ub0VHQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9bKUAQ','','true','Current','Parent','','0032F00000Ub0VHQAZ','a0G2F000003t9bJUAQ','0032F00000Ub0UmQAJ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HfUAI','','false','Current','Daughter','Soft Credit','0032F00000UawOrQAJ','a0G2F000003t9HgUAI','0032F00000UawUGQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HgUAI','','true','Current','Father','','0032F00000UawUGQAZ','a0G2F000003t9HfUAI','0032F00000UawOrQAJ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HkUAI','','false','Current','Wife','Soft Credit','0032F00000UawOrQAJ','a0G2F000003t9HlUAI','0032F00000UawPUQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HlUAI','','true','Current','Husband','','0032F00000UawPUQAZ','a0G2F000003t9HkUAI','0032F00000UawOrQAJ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9fTUAQ','','false','Current','Mentee','','0032F00000UawPUQAZ','a0G2F000003t9fUUAQ','0032F00000Ub0UmQAJ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9fUUAQ','','true','Current','Mentor','','0032F00000Ub0UmQAJ','a0G2F000003t9fTUAQ','0032F00000UawPUQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HuUAI','','false','Current','Friend','Solicitor','0032F00000UawOrQAJ','a0G2F000003t9HvUAI','0032F00000UawOGQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HvUAI','','true','Current','Friend','','0032F00000UawOGQAZ','a0G2F000003t9HuUAI','0032F00000UawOrQAJ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HpUAI','Candace and Robert went to the same University.','false','Current','Friend','Soft Credit','0032F00000UawOrQAJ','a0G2F000003t9HqUAI','0032F00000UawOFQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HqUAI','Candace and Robert went to the same University.','true','Current','Friend','','0032F00000UawOFQAZ','a0G2F000003t9HpUAI','0032F00000UawOrQAJ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9HzUAI','','false','Current','Friend','','0032F00000UawPUQAZ','a0G2F000003t9I0UAI','0032F00000UawOHQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9I0UAI','','true','Current','Friend','','0032F00000UawOHQAZ','a0G2F000003t9HzUAI','0032F00000UawPUQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9fYUAQ','','false','Current','Member','','0032F00000UawPJQAZ','a0G2F000003t9fZUAQ','0032F00000UawOQQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9fZUAQ','','true','Current','Leader','','0032F00000UawOQQAZ','a0G2F000003t9fYUAQ','0032F00000UawPJQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9I4UAI','','false','Current','Friend','','0032F00000UawPUQAZ','a0G2F000003t9I5UAI','0032F00000UawPLQAZ');
INSERT INTO "npe4__Relationship__c" VALUES('a0G2F000003t9I5UAI','','true','Current','Friend','','0032F00000UawPLQAZ','a0G2F000003t9I4UAI','0032F00000UawPUQAZ');
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
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029UV2UAM','','','true','Employee','2016-04-07','Current','','0032F00000Ub2ALQAZ','0012F00000XtUCnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8qUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FZQAZ','0012F00000XtUCrQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8rUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FaQAJ','0012F00000XtUCnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8sUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FbQAJ','0012F00000XtUCqQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8tUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FdQAJ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8uUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FeQAJ','0012F00000XttuyQAB');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8vUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FfQAJ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8wUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FiQAJ','0012F00000XtUCtQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8xUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FjQAJ','0012F00000XtUCqQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8yUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FkQAJ','0012F00000XtUCpQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V8zUAE','','','true','','2019-12-05','Current','','0032F00000Ub9FlQAJ','0012F00000XtUCoQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V90UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FmQAJ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V91UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FnQAJ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V92UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FoQAJ','0012F00000XtUCvQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V93UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FpQAJ','0012F00000XtUCqQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V94UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FqQAJ','0012F00000XtUCoQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V95UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FrQAJ','0012F00000XtUCwQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V96UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FsQAJ','0012F00000XtUCyQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V97UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FtQAJ','0012F00000XtUCzQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V98UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FuQAJ','0012F00000XtUD0QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V99UAE','','','true','','2019-12-05','Current','','0032F00000Ub9FvQAJ','0012F00000XtUD1QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9AUAU','','','true','','2019-12-05','Current','','0032F00000Ub9FwQAJ','0012F00000XtUCsQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9BUAU','','','true','','2019-12-05','Current','','0032F00000Ub9FxQAJ','0012F00000XtUCnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9CUAU','','','true','','2019-12-05','Current','','0032F00000Ub9FyQAJ','0012F00000XtUCnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9DUAU','','','true','','2019-12-05','Current','','0032F00000Ub9FzQAJ','0012F00000XtUCxQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9EUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G0QAJ','0012F00000XtUCnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9FUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G1QAJ','0012F00000XtUCvQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9GUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G2QAJ','0012F00000XtUD8QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9HUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G3QAJ','0012F00000XtUD6QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9IUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G4QAJ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9JUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G5QAJ','0012F00000XtUD5QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9KUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G6QAJ','0012F00000XtUD3QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9LUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G7QAJ','0012F00000XtUD4QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9MUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G8QAJ','0012F00000XtUD9QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9NUAU','','','true','','2019-12-05','Current','','0032F00000Ub9G9QAJ','0012F00000XtUDAQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9OUAU','','','true','','2019-12-05','Current','','0032F00000Ub9GAQAZ','0012F00000XtUD7QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9PUAU','','','true','','2019-12-05','Current','','0032F00000Ub9GBQAZ','0012F00000XtUD9QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9QUAU','','','true','','2019-12-05','Current','','0032F00000Ub9GDQAZ','0012F00000XtUCtQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9RUAU','','','true','','2019-12-05','Current','','0032F00000Ub9GEQAZ','0012F00000XtUDCQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9SUAU','','','true','','2019-12-05','Current','','0032F00000Ub9GHQAZ','0012F00000XtUCtQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029V9TUAU','','','true','','2019-12-05','Current','','0032F00000Ub9GhQAJ','0012F00000XtUDDQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029Ur1UAE','','','true','Legislative Aide','2019-12-05','Current','','0032F00000UawOXQAZ','0012F00000XtsOwQAJ');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029Ur6UAE','','','true','','2019-12-05','Current','','0032F00000UawOLQAZ','0012F00000XtsibQAB');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029SXVUA2','','','true','CEO','2020-01-15','Current','','0032F00000UnI9ZQAV','0012F00000XlQpUQAV');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U0vUAE','','','true','','2019-12-04','Current','','0032F00000UawOFQAZ','0012F00000XtUCnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U0wUAE','','','true','','2019-12-04','Current','','0032F00000UawOGQAZ','0012F00000XtUCnQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U0xUAE','','','true','','2019-12-04','Current','','0032F00000UawOHQAZ','0012F00000XtUCoQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U0yUAE','','','true','','2019-12-04','Current','','0032F00000UawOIQAZ','0012F00000XtUCpQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U0zUAE','','','true','','2019-12-04','Current','','0032F00000UawOJQAZ','0012F00000XtUCqQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U10UAE','','','true','','2019-12-04','Current','','0032F00000UawOKQAZ','0012F00000XtUCrQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U11UAE','','2019-12-05','false','','2019-12-04','Former','','0032F00000UawOLQAZ','0012F00000XtUCqQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U12UAE','','','true','','2019-12-04','Current','','0032F00000UawOMQAZ','0012F00000XtUCsQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U13UAE','','','true','','2019-12-04','Current','','0032F00000UawONQAZ','0012F00000XtUCtQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U14UAE','','','true','','2019-12-04','Current','','0032F00000UawOQQAZ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1VUAU','','','true','','2019-12-04','Current','','0032F00000UawOwQAJ','0012F00000XtUCtQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U15UAE','','','true','','2019-12-04','Current','','0032F00000UawORQAZ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U16UAE','','','true','','2019-12-04','Current','','0032F00000UawOSQAZ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U17UAE','','','true','','2019-12-04','Current','','0032F00000UawOTQAZ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U18UAE','','','true','','2019-12-04','Current','','0032F00000UawOUQAZ','0012F00000XtUCvQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U19UAE','','','true','','2019-12-04','Current','','0032F00000UawOVQAZ','0012F00000XtUCqQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1AUAU','','','true','','2019-12-04','Current','','0032F00000UawOWQAZ','0012F00000XtUCoQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1BUAU','','2019-12-05','false','','2019-12-04','Former','','0032F00000UawOXQAZ','0012F00000XtUCwQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1CUAU','','','true','','2019-12-04','Current','','0032F00000UawOYQAZ','0012F00000XtUCxQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1DUAU','','','true','','2019-12-04','Current','','0032F00000UawOZQAZ','0012F00000XtUCyQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1EUAU','','','true','','2019-12-04','Current','','0032F00000UawOaQAJ','0012F00000XtUCzQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1FUAU','','','true','','2019-12-04','Current','','0032F00000UawObQAJ','0012F00000XtUD0QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1GUAU','','','true','','2019-12-04','Current','','0032F00000UawOcQAJ','0012F00000XtUD1QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1HUAU','','','true','','2019-12-04','Current','','0032F00000UawOdQAJ','0012F00000XtUD2QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1IUAU','','','true','','2019-12-04','Current','','0032F00000UawOeQAJ','0012F00000XtUCvQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1JUAU','','','true','','2019-12-04','Current','','0032F00000UawOfQAJ','0012F00000XtUCtQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1KUAU','','','true','','2019-12-04','Current','','0032F00000UawOhQAJ','0012F00000XtUD3QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1LUAU','','','true','','2019-12-04','Current','','0032F00000UawOiQAJ','0012F00000XtUD4QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1MUAU','','','true','','2019-12-04','Current','','0032F00000UawOjQAJ','0012F00000XtUD5QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1NUAU','','','true','','2019-12-04','Current','','0032F00000UawOkQAJ','0012F00000XtUD6QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1OUAU','','','true','','2019-12-04','Current','','0032F00000UawOlQAJ','0012F00000XtUD7QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1PUAU','','2019-12-05','false','','2019-12-04','Former','','0032F00000UawOmQAJ','0012F00000XtUD8QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1QUAU','','','true','','2019-12-04','Current','','0032F00000UawOnQAJ','0012F00000XtUD9QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1RUAU','','','true','','2019-12-04','Current','','0032F00000UawOoQAJ','0012F00000XtUDAQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1SUAU','','','true','','2019-12-04','Current','','0032F00000UawOpQAJ','0012F00000XtUD9QAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1TUAU','','','true','','2019-12-04','Current','','0032F00000UawOqQAJ','0012F00000XtUCuQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1UUAU','','','true','','2019-12-04','Current','','0032F00000UawOrQAJ','0012F00000XtUDBQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1WUAU','','','true','','2019-12-04','Current','','0032F00000UawP0QAJ','0012F00000XtUDCQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U1XUAU','','','true','','2019-12-04','Current','','0032F00000UawPTQAZ','0012F00000XtUDDQA3');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029U3UUAU','Graduate','','false','Alumni','1990-09-01','Former','','0032F00000UawOFQAZ','0012F00000XtUCzQAN');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H2F0000029UccUAE','','','true','','2019-12-05','Current','','0032F00000Ub7d0QAB','0012F00000XtnlOQAR');
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
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSaUAI','','Home','','false','','','true','','2019-12-05','South San Francisco','','94044','CA','','55 Charleston','','','','','','','','','false','0012F00000XttuJQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSbUAI','','Home','','false','','','true','','2019-12-05','Brooklyn','','2317','NY','','10 Ocean Parkway','','','','','','','','','false','0012F00000XttuKQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqScUAI','','Home','','false','','','true','','2019-12-05','Boston','','2199','MA','','1172 Boylston St.','','','','','','','','','false','0012F00000XttuMQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSdUAI','','Home','','false','','','true','','2019-12-05','San Francisco','','94118','CA','','2137 Larry Street','','','','','','','','','false','0012F00000XttuNQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSeUAI','','Home','','false','','','true','','2019-12-05','Pleasant','','7777','NJ','','1 Cherry Street','','','','','','','','','false','0012F00000XttuOQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSfUAI','','Home','','false','','','true','','2019-12-05','Bristol','','68376','ME','','2357 Attlee Rd','','','','','','','','','false','0012F00000XttuPQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSgUAI','','Home','','false','','','true','','2019-12-05','Franklin','','56949','AK','','306 Monterey Drive Ave S','','','','','','','','','false','0012F00000XttuQQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSjUAI','','Home','','false','','','true','','2019-12-05','City Of Commerce','','90040','CA','','1391 Diane Street','','','','','','','','','false','0012F00000XttuTQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSkUAI','','Home','','false','','','true','','2019-12-05','Bloomfield Township','','48302','MI','','3024 Summit Park Avenue','','','','','','','','','false','0012F00000XttuUQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSlUAI','','Home','','false','','','true','','2019-12-05','Boston','','2130','MA','','25 Boyston','','','','','','','','','false','0012F00000XtUCDQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSmUAI','','Home','','false','','','true','','2019-12-05','Arlington','','2128','MA','','4270 4th Court','','','','','','','','','false','0012F00000XttuVQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSnUAI','','Home','','false','','','true','','2019-12-05','Burnt Corn','','56070','AL','','102 Drummand Grove Dr','','','','','','','','','false','0012F00000XttuWQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSoUAI','','Home','','false','','','true','','2019-12-05','Arlington','','57828','WA','','918 Duffield Crescent St','','','','','','','','','false','0012F00000XttuXQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSpUAI','','Home','','false','','','true','','2019-12-05','Chester','','58707','MA','','2754 Glamis Place Way','','','','','','','','','false','0012F00000XttuYQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSqUAI','','Home','','false','','','true','','2019-12-05','Georgetown','','59586','ME','','8262 Phinney Ridge Rd','','','','','','','','','false','0012F00000XttuZQAR');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSrUAI','','Home','','false','','','true','','2019-12-05','Salem','','61344','MA','','74358 S Wycliff Ave','','','','','','','','','false','0012F00000XttuaQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSsUAI','','Home','','false','','','true','','2019-12-05','Fairfield','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0012F00000XttubQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqStUAI','','Home','','false','','','true','','2019-12-05','Kingston','','63981','WA','','18312 Duchess Rd','','','','','','','','','false','0012F00000XttucQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSuUAI','','Home','','false','','','true','','2019-12-05','Marion','','64860','VA','','9156 Springfield Green Dr','','','','','','','','','false','0012F00000XttudQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSvUAI','','Home','','false','','','true','','2019-12-05','Riverside','','65739','WV','','4578 Linda Ave','','','','','','','','','false','0012F00000XttueQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSwUAI','','Home','','false','','','true','','2019-12-05','Lebanon','','66618','MD','','2289 David Budd St','','','','','','','','','false','0012F00000XttufQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSxUAI','','Home','','false','','','true','','2019-12-05','Bay City','','48706','MI','','840 Mount Street','','','','','','','','','false','0012F00000XttugQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSyUAI','','Home','','false','','','true','','2019-12-05','Greenville','','63102','OR','','36624 Jefferson Way Way','','','','','','','','','false','0012F00000XttujQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqSzUAI','','Home','','false','','','true','','2019-12-05','San Francisco','','94121','CA','','25 10th Ave.','','','','','','','','','false','0012F00000XttukQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT0UAI','','Home','','false','','','true','','2019-12-05','Truth or Consequences','','55191','NM','','34 Shipham Close Rd','','','','','','','','','false','0012F00000XttulQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT1UAI','','Home','','false','','','true','','2019-12-05','Dover','','98982','CO','','2527 Monroe Rd','','','','','','','','','false','0012F00000XttumQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT2UAI','','Home','','false','','','true','','2019-12-05','Reston','','71013','VA','','2459 44th St E','','','','','','','','','false','0012F00000XttunQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT3UAI','','Home','','false','','','true','','2019-12-05','Madison','','70134','CA','','2425 9th Ave','','','','','','','','','false','0012F00000XttupQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT4UAI','','Home','','false','','','true','','2019-12-05','Witchita','','67497','KS','','2323 Dent Way','','','','','','','','','false','0012F00000XttuqQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT5UAI','','Home','','false','','','true','','2019-12-05','Salem','','69255','LA','','2391 Roborough Dr','','','','','','','','','false','0012F00000XtturQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT6UAI','','Home','','false','','','true','','2019-12-05','Dover','','99948','FL','','2629 Nebraska St','','','','','','','','','false','0012F00000XttusQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT7UAI','','Home','','false','','','true','','2019-12-05','Dover','','99948','FL','','2595 Montauk Ave W','','','','','','','','','false','0012F00000XttutQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT8UAI','','Home','','false','','','true','','2019-12-05','Seattle','','98103','WA','','2493 89th Way','','','','','','','','','false','0012F00000XttuuQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqT9UAI','','Home','','false','','','true','','2019-12-05','Ashland','','99861','KY','','2561 Madison Dr','','','','','','','','','false','0012F00000XttuvQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqTAUAY','','Home','','false','','','true','','2019-12-05','Springfield','','65802','MO','','726 Twin House Lane','','','','','','','','','false','0012F00000XttuwQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dqTBUAY','','Home','','false','','','true','','2019-12-05','Madison','','60465','WI','','24786 Handlebar Dr N','','','','','','','','','false','0012F00000XttuxQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dq8EUAQ','','Home','','false','','','true','','2019-12-05','Cole City','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0012F00000XtUCSQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dq0VUAQ','','Home','','false','','','true','','2019-12-05','Port Townsend','','98368','WA','','762 Smiley','','','','','','','','','false','0012F00000XtnohQAB');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007dnxvUAA','','Home','','false','','','true','','2020-01-05','San Francisco','USA','94105','CA','','One Market Street','','','','','','','','','false','0012F00000XlQpTQAV');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxQUAQ','','Home','','false','','','true','','2019-12-04','San Francisco','','94121','CA','','25 10th Ave.','','','','','','','','','false','0012F00000XtUCBQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxRUAQ','','Home','','false','','','true','','2019-12-04','Arlington','','02128','MA','','4270 4th Court','','','','','','','','','false','0012F00000XtUCCQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxSUAQ','','Home','','false','','','false','2019-12-05','2019-12-04','Boston','','02130','MA','','25 Boyston','','','','','','','','','false','0012F00000XtUCDQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxTUAQ','','Home','','false','','','true','','2019-12-04','Boston','','02199','MA','','1172 Boylston St.','','','','','','','','','false','0012F00000XtUCEQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxUUAQ','','Home','','false','','','true','','2019-12-04','Brooklyn','','02317','NY','','10 Ocean Parkway','','','','','','','','','false','0012F00000XtUCFQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxVUAQ','','Home','','false','','','true','','2019-12-04','Bloomfield Township','','48302','MI','','3024 Summit Park Avenue','','','','','','','','','false','0012F00000XtUCGQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxWUAQ','','Home','','false','','','true','','2019-12-04','Bay City','','48706','MI','','840 Mount Street','','','','','','','','','false','0012F00000XtUCHQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxXUAQ','','Home','','false','','','true','','2019-12-04','City Of Commerce','','90040','CA','','1391 Diane Street','','','','','','','','','false','0012F00000XtUCIQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxYUAQ','','Home','','false','','','true','','2019-12-04','South San Francisco','','94044','CA','','55 Charleston','','','','','','','','','false','0012F00000XtUCJQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxZUAQ','','Home','','false','','','true','','2019-12-04','San Francisco','','94118','CA','','2137 Larry Street','','','','','','','','','false','0012F00000XtUCKQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxaUAA','','Home','','false','','','true','','2019-12-04','Pleasant','','07777','NJ','','1 Cherry Street','','','','','','','','','false','0012F00000XtUCLQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxbUAA','','Home','','false','','','true','','2019-12-04','Burnt Corn','','56070','AL','','102 Drummand Grove Dr','','','','','','','','','false','0012F00000XtUCMQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxcUAA','','Home','','false','','','true','','2019-12-04','Franklin','','56949','AK','','306 Monterey Drive Ave S','','','','','','','','','false','0012F00000XtUCNQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxdUAA','','Home','','false','','','true','','2019-12-04','Arlington','','57828','WA','','918 Duffield Crescent St','','','','','','','','','false','0012F00000XtUCOQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxeUAA','','Home','','false','','','true','','2019-12-04','Chester','','58707','MA','','2754 Glamis Place Way','','','','','','','','','false','0012F00000XtUCPQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxfUAA','','Home','','false','','','true','','2019-12-04','Georgetown','','59586','ME','','8262 Phinney Ridge Rd','','','','','','','','','false','0012F00000XtUCQQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxgUAA','','Home','','false','','','true','','2019-12-04','Salem','','61344','MA','','74358 S Wycliff Ave','','','','','','','','','false','0012F00000XtUCRQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxhUAA','','Home','','false','','','false','2019-12-05','2019-12-04','Fairfield','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0012F00000XtUCSQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxiUAA','','Home','','false','','','true','','2019-12-04','Greenville','','63102','OR','','36624 Jefferson Way Way','','','','','','','','','false','0012F00000XtUCTQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxjUAA','','Home','','false','','','true','','2019-12-04','Kingston','','63981','WA','','18312 Duchess Rd','','','','','','','','','false','0012F00000XtUCUQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxkUAA','','Home','','false','','','true','','2019-12-04','Marion','','64860','VA','','9156 Springfield Green Dr','','','','','','','','','false','0012F00000XtUCVQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxlUAA','','Home','','false','','','true','','2019-12-04','Riverside','','65739','WV','','4578 Linda Ave','','','','','','','','','false','0012F00000XtUCWQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxmUAA','','Home','','false','','','true','','2019-12-04','Lebanon','','66618','MD','','2289 David Budd St','','','','','','','','','false','0012F00000XtUCXQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxnUAA','','Home','','false','','','true','','2019-12-04','Bristol','','68376','ME','','2357 Attlee Rd','','','','','','','','','false','0012F00000XtUCYQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxoUAA','','Home','','false','','','true','','2019-12-04','Truth or Consequences','','55191','NM','','34 Shipham Close Rd','','','','','','','','','false','0012F00000XtUCZQA3');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxpUAA','','Home','','false','','','true','','2019-12-04','Madison','','60465','WI','','24786 Handlebar Dr N','','','','','','','','','false','0012F00000XtUCaQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxqUAA','','Home','','false','','','true','','2019-12-04','Springfield','','65802','MO','','726 Twin House Lane','','','','','','','','','false','0012F00000XtUCbQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxrUAA','','Home','','false','','','true','','2019-12-04','Witchita','','67497','KS','','2323 Dent Way','','','','','','','','','false','0012F00000XtUCcQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxsUAA','','Home','','false','','','true','','2019-12-04','Salem','','69255','LA','','2391 Roborough Dr','','','','','','','','','false','0012F00000XtUCdQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxtUAA','','Home','','false','','','true','','2019-12-04','Madison','','70134','CA','','2425 9th Ave','','','','','','','','','false','0012F00000XtUCeQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxuUAA','','Home','','false','','','true','','2019-12-04','Reston','','71013','VA','','2459 44th St E','','','','','','','','','false','0012F00000XtUCfQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxvUAA','','Home','','false','','','true','','2019-12-04','Seattle','','98103','WA','','2493 89th Way','','','','','','','','','false','0012F00000XtUCgQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxwUAA','','Home','','false','','','true','','2019-12-04','Dover','','98982','CO','','2527 Monroe Rd','','','','','','','','','false','0012F00000XtUChQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxxUAA','','Home','','false','','','true','','2019-12-04','Ashland','','99861','KY','','2561 Madison Dr','','','','','','','','','false','0012F00000XtUCiQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxyUAA','','Home','','false','','','true','','2019-12-04','Dover','','99948','FL','','2595 Montauk Ave W','','','','','','','','','false','0012F00000XtUCjQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doxzUAA','','Home','','false','','','true','','2019-12-04','Dover','','99948','FL','','2629 Nebraska St','','','','','','','','','false','0012F00000XtUCkQAN');
INSERT INTO "npsp__Address__c" VALUES('a0K2F000007doy0UAA','','Home','','false','','','true','','2019-12-04','Buffalo','','08982','NY','','129 W 81st','','','','','','','','','false','0012F00000XtUCmQAN');
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
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPnQAM','100.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKPQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPoQAM','125.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmOQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPpQAM','50.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKJQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPqQAM','125.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmMQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPrQAM','100.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKLQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPsQAM','100.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKKQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPtQAM','125.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmLQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPuQAM','1000.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKOQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPvQAM','50.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKMQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPwQAM','50.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKIQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPxQAM','50.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKQQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPyQAM','125.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmNQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XPzQAM','10000.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKNQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ0QAM','100.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmPQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ1QAM','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKeQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ2QAM','7500.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKaQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ3QAM','100.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKYQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ4QAM','100.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKSQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ5QAM','125.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKTQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ6QAM','225.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKVQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XMAQA2','12500.0','100.0','','a0e2F000001lFK8QAM','0062F000008qEmjQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XMBQA2','75.0','100.0','','a0e2F000001lFK8QAM','0062F000008qEmkQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XMCQA2','1250.0','100.0','','a0e2F000001lFK8QAM','0062F000008qEmlQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XMDQA2','12500.0','100.0','','a0e2F000001lFK8QAM','0062F000008qEmmQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XMEQA2','375000.0','100.0','','a0e2F000001lFK8QAM','0062F000008qEmnQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ7QAM','160.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmSQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ8QAM','1000.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKcQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQ9QAM','10.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKUQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQAQA2','100.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmRQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQBQA2','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmQQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQCQA2','100.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKXQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQDQA2','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKgQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQEQA2','25.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKdQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQFQA2','10000.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKZQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQGQA2','50.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKRQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQHQA2','25.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKfQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQIQA2','50.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKbQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQJQA2','50.0','100.0','','a0e2F000001lEjsQAE','0062F000008qDKWQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQKQA2','1250.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmVQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQLQA2','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmXQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQMQA2','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmWQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQNQA2','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmYQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQOQA2','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmUQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQPQA2','30.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmTQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQQQA2','300.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmbQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQRQA2','9375.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmfQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQSQA2','125.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmZQAU','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQTQA2','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmcQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQUQA2','30.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmiQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQVQA2','15.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmaQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQWQA2','75.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmgQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQXQA2','1250.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmhQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQYQA2','125.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmdQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQZQA2','125.0','100.0','','a0e2F000001lEjsQAE','0062F000008qEmeQAE','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQaQAM','1000.0','100.0','','a0e2F000001lFK8QAM','0062F000008qDKHQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036XQbQAM','300000.0','100.0','','a0e2F000001lFK8QAM','0062F000008qDKFQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSHQA2','','50.0','','a0e2F000001lFK3QAM','','a092F000002bGIkQAM');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSIQA2','','50.0','','a0e2F000001lFK9QAM','','a092F000002bGIkQAM');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSJQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMMQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSKQA2','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMMQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSLQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMNQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSMQA2','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMNQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSNQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMOQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSOQA2','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMOQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSPQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMPQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSQQA2','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMPQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSRQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMQQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSSQA2','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMQQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSTQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMRQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSUQA2','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMRQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSVQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMSQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSWQA2','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMSQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSXQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMTQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSYQA2','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMTQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSZQA2','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMUQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSaQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMUQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSbQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMVQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TScQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMVQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSdQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMWQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSeQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMWQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSfQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMXQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSgQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMXQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TShQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMYQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSiQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMYQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSjQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMZQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSkQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMZQA2','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSlQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMaQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSmQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMaQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSnQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMbQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSoQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMbQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSpQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMcQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSqQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMcQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSrQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMdQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSsQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMdQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TStQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMeQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSuQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMeQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSvQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMfQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSwQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMfQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSxQAM','50.0','50.0','','a0e2F000001lFK3QAM','0062F000008qDMgQAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TSyQAM','50.0','50.0','','a0e2F000001lFK9QAM','0062F000008qDMgQAM','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036G9yQAE','200.0','','','a0e2F000001lEjsQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036G9zQAE','50.0','100.0','','a0e2F000001lEjsQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA0QAM','','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA1QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA2QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA3QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA4QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA5QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA6QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA7QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA8QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GA9QAM','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GAAQA2','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GABQA2','20.0','100.0','','a0e2F000001lEjtQAE','','');
--INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036GACQA2','20.0','100.0','','a0e2F000001lEjtQAE','','');
INSERT INTO "npsp__Allocation__c" VALUES('a0b2F0000036TT2QAM','','100.0','7012F000000LvPrQAK','a0e2F000001lFK8QAM','','');
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
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfMQAQ','Thank You Phone Call','','1.0','High','0','false','false','Not Started','Call','a0j2F000001tCSfQAM','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfNQAQ','Send Gold level packet in mail','','7.0','Normal','0','false','false','Not Started','Other','a0j2F000001tCSfQAM','a0i2F000000lmfMQAQ');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfOQAQ','Confirm packet received email','','5.0','Normal','0','false','false','Not Started','Email','a0j2F000001tCSfQAM','a0i2F000000lmfNQAQ');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfPQAQ','Follow Up Email','','30.0','High','0','false','false','Not Started','Email','a0j2F000001tCSfQAM','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfQQAQ','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0j2F000001tCSfQAM','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lkKxQAI','Application Review','','1.0','High','0','false','false','Not Started','Other','a0j2F000001t6MaQAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lkKyQAI','Approval Email','','1.0','High','0','false','false','Not Started','Email','a0j2F000001t6MaQAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lkKzQAI','Background Check','','2.0','High','0','false','false','Not Started','Other','a0j2F000001t6MaQAI','a0i2F000000lkKyQAI');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lkL0QAI','Volunteer Orientation','','14.0','High','0','false','false','Not Started','Meeting','a0j2F000001t6MaQAI','a0i2F000000lkKzQAI');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lkL1QAI','Thank You Phone Call','','1.0','High','0','false','false','Not Started','Call','a0j2F000001t6MbQAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lkL2QAI','Schedule Facility Tour & Lunch','','7.0','Normal','0','false','false','Not Started','Meeting','a0j2F000001t6MbQAI','a0i2F000000lkL1QAI');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lkL3QAI','Follow Up Email','','3.0','High','0','false','false','Not Started','Email','a0j2F000001t6MbQAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lkL4QAI','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0j2F000001t6MbQAI','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfRQAQ','Thank You Phone Call by Volunteer','Volunteer will call and thank donor within the month.','30.0','High','0','false','false','Not Started','Call','a0j2F000001tCSkQAM','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfSQAQ','Send membership levels email','Send email with information about benefits of all of the membership levels.','7.0','Normal','0','false','false','Not Started','Other','a0j2F000001tCSkQAM','a0i2F000000lmfRQAQ');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfTQAQ','Follow Up Email','','30.0','High','0','false','false','Not Started','Email','a0j2F000001tCSkQAM','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0i2F000000lmfUQAQ','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0j2F000001tCSkQAM','');
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
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0j2F000001tCSfQAM','Gold Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Silver to Gold level.','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0j2F000001t6MaQAI','Volunteer Onboarding','true','Owner of Object for Engagement Plan','Sample Engagement Plan Template','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0j2F000001t6MbQAI','Platinum Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Gold to Platinum level.','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0j2F000001tCSkQAM','Silver Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Bronze to Silver level.','Monday','true');
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
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fdQAC','0.0','4.0','','','','0032F00000UawOFQAZ','a0j2F000001t6MbQAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4feQAC','0.0','4.0','','','','0032F00000UawOHQAZ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4ffQAC','0.0','4.0','','','','0032F00000UawOIQAZ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fgQAC','0.0','4.0','','','','0032F00000UawOLQAZ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fhQAC','0.0','5.0','','','','0032F00000UawOOQAZ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fiQAC','0.0','5.0','','','','0032F00000UawOPQAZ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fjQAC','0.0','5.0','','','','0032F00000UawORQAZ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fkQAC','0.0','5.0','','','','0032F00000UawOSQAZ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4flQAC','0.0','5.0','','','','0032F00000UawOUQAZ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fmQAC','0.0','5.0','','','','0032F00000UawOWQAZ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fnQAC','0.0','4.0','','','','0032F00000UawOZQAZ','a0j2F000001t6MbQAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4foQAC','0.0','4.0','','','','0032F00000UawOaQAJ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fpQAC','0.0','5.0','','','','0032F00000Ub9FYQAZ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fqQAC','0.0','5.0','','','','0032F00000Ub9FaQAJ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4frQAC','0.0','5.0','','','','0032F00000Ub9FcQAJ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fsQAC','0.0','5.0','','','','0032F00000Ub9FfQAJ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4ftQAC','0.0','4.0','','','','0032F00000Ub9FhQAJ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fuQAC','0.0','4.0','','','','0032F00000Ub9FjQAJ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fvQAC','0.0','4.0','','','','0032F00000Ub9FkQAJ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fwQAC','0.0','4.0','','','','0032F00000Ub9FlQAJ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fxQAC','0.0','5.0','','','','0032F00000Ub9FmQAJ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fyQAC','0.0','5.0','','','','0032F00000Ub9FoQAJ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4fzQAC','0.0','5.0','','','','0032F00000Ub9FqQAJ','a0j2F000001tCSfQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4g0QAC','0.0','4.0','','','','0032F00000Ub9FsQAJ','a0j2F000001t6MbQAI','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4g1QAC','0.0','4.0','','','','0032F00000Ub9FtQAJ','a0j2F000001tCSkQAM','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0k2F000001Y4g2QAC','0.0','4.0','','','','0032F00000Ub9FxQAJ','a0j2F000001tCSkQAM','','');
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
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0e2F000001lFK8QAM','Transitional Housing Capital Campaign','true','5465.0','Transitional Housing program specific','2018-06-30','12500.0','2019-05-07','1.0','4.0','1.0','0.0','75.0','12500.0','14825.0','12500.0','0.0','27325.0','5.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0e2F000001lFK9QAM','Food Pantry Programs','true','0.0','','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0e2F000001lFKAQA2','HUD Transitional Housing Grant','true','0.0','','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0e2F000001lEjsQAE','General Fund','true','918.78','','2018-01-01','10000.0','2019-09-23','37.0','12.0','37.0','0.0','10.0','33145.0','11875.0','33145.0','0.0','45020.0','49.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0e2F000001lEjtQAE','Restricted Fund','true','0.0','','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0e2F000001lFK3QAM','Women''s Services','true','0.0','Fund for NMH annual women''s services.','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
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
INSERT INTO "npsp__Level__c" VALUES('a0l2F000001XKCeQAO','Platinum','true','Our highest level.','Giving_Level__c','','10000.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','');
INSERT INTO "npsp__Level__c" VALUES('a0l2F000001XKCfQAO','Bronze','true','The lowest entry level.','Giving_Level__c','100.0','35.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0j2F000001tCSkQAM');
INSERT INTO "npsp__Level__c" VALUES('a0l2F000001XKCgQAO','Silver','true','The second level.','Giving_Level__c','1000.0','100.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0j2F000001tCSfQAM');
INSERT INTO "npsp__Level__c" VALUES('a0l2F000001XKChQAO','Gold','true','The third level.','Giving_Level__c','10000.0','1000.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0j2F000001t6MbQAI');
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
