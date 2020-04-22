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
INSERT INTO "Account" VALUES('0016g000007WEfsAAG','Clerr and Nazarian Household','0126g000000MyJkAAK','840 Mount Street','Bay City','MI','','48706','true','Household Account','0.0','0.0','','','Danny Clerr and Bryce Nazarian','','Danny and Bryce','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfhAAC','');
INSERT INTO "Account" VALUES('0016g000007WEftAAG','Ivans Household','0126g000000MyJkAAK','','','','','','true','Household Account','75.0','75.0','2018','2018-11-04','Sehar Ivans','','Sehar','75.0','2018-11-04','0.0','','','','75.0','','','1.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','','75.0','0.0','75.0','','false','','','','','','false','','','','','','1.0','a0e6g000000OuHTAA0','','','0036g000006JcfiAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfuAAG','Ivans Household','0126g000000MyJkAAK','','','','','','true','Household Account','0.0','0.0','','','Lakshmi and Calvin Ivans','','Lakshmi and Calvin','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfkAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfvAAG','Figueroo Household','0126g000000MyJkAAK','25 10th Ave.','San Francisco','CA','','94121','true','Household Account','0.0','0.0','','','Roger and Linda Figueroo','','Roger and Linda','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfmAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfwAAG','Campagna Household','0126g000000MyJkAAK','34 Shipham Close Rd','Truth or Consequences','NM','','55191','true','Household Account','0.0','0.0','','','Tessa and Harold Campagna','','Tessa and Harold','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfoAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfxAAG','Clerk Household','0126g000000MyJkAAK','2527 Monroe Rd','Dover','CO','','98982','true','Household Account','0.0','0.0','','','Deandre and Helena Clerk','','Deandre and Helena','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfqAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfyAAG','Kanban Household','0126g000000MyJkAAK','2459 44th St E','Reston','VA','','71013','true','Household Account','0.0','0.0','','','Heidi and Xiao-yu Kanban','','Heidi and Xiao-yu','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfsAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfzAAG','Primordial Household','0126g000000MyJkAAK','','','','','','true','Household Account','0.0','0.0','','','Lois and Louis Primordial','','Lois and Louis','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcftAAC','');
INSERT INTO "Account" VALUES('0016g000007WEg0AAG','Djyradj Household','0126g000000MyJkAAK','2425 9th Ave','Madison','CA','','70134','true','Household Account','0.0','0.0','','','Kamilla and Suhani Djyradj','','Kamilla and Suhani','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfwAAC','');
INSERT INTO "Account" VALUES('0016g000007WEg1AAG','Kasprawicz Household','0126g000000MyJkAAK','2323 Dent Way','Witchita','KS','','67497','true','Household Account','0.0','0.0','','','Luiza and Roger Kasprawicz','','Luiza and Roger','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfyAAC','');
INSERT INTO "Account" VALUES('0016g000007WEg2AAG','Bateson and Navarro Household','0126g000000MyJkAAK','2391 Roborough Dr','Salem','LA','','69255','true','Household Account','0.0','0.0','','','Jozef Bateson and Nageen Navarro','','Jozef and Nageen','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jcg0AAC','');
INSERT INTO "Account" VALUES('0016g000007WEg3AAG','Frasier and Ng Household','0126g000000MyJkAAK','2629 Nebraska St','Dover','FL','','99948','true','Household Account','0.0','0.0','','','Natali Frasier and Mpho Ng','','Natali and Mpho','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jcg2AAC','');
INSERT INTO "Account" VALUES('0016g000007WEg4AAG','Prasad and Oden Household','0126g000000MyJkAAK','2595 Montauk Ave W','Dover','FL','','99948','true','Household Account','0.0','0.0','','','Gabriel Prasad and Bartolomej Oden','','Gabriel and Bartolomej','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jcg4AAC','');
INSERT INTO "Account" VALUES('0016g000007WEg5AAG','Bates and Sokolov Household','0126g000000MyJkAAK','2493 89th Way','Seattle','WA','','98103','true','Household Account','0.0','0.0','','','Eleonora Bates and Krithika Sokolov','','Eleonora and Krithika','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jcg6AAC','');
INSERT INTO "Account" VALUES('0016g000007WEg6AAG','Bokolov and Wong Household','0126g000000MyJkAAK','2561 Madison Dr','Ashland','KY','','99861','true','Household Account','0.0','0.0','','','Mirce Bokolov and Aldegund Wong','','Mirce and Aldegund','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jcg8AAC','');
INSERT INTO "Account" VALUES('0016g000007WEg7AAG','Mandela and Yudes Household','0126g000000MyJkAAK','726 Twin House Lane','Springfield','MO','','65802','true','Household Account','0.0','0.0','','','Diana Mandela and Crystal Yudes','','Diana and Crystal','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jcg9AAC','');
INSERT INTO "Account" VALUES('0016g000007WEg8AAG','Watson Household','0126g000000MyJkAAK','24786 Handlebar Dr N','Madison','WI','','60465','true','Household Account','0.0','0.0','','','Nashville and Evrim Watson','','Nashville and Evrim','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgCAAS','');
INSERT INTO "Account" VALUES('0016g000007WEg9AAG','Cole City Council Office','0126g000000MyJlAAK','143 South Main Street','Cole City','KS','United States','98104','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgAAAW','Nostdal and Rymph Household','0126g000000MyJkAAK','762 Smiley','Port Townsend','WA','','98368','true','Household Account','0.0','0.0','','','Jessie Nostdal and Zach Rymph','','Jessie and Zach','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgEAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgBAAW','Douglass Household','0126g000000MyJkAAK','','','','','','true','Household Account','50.0','50.0','2019','2019-01-01','Erica Douglass','','Erica','50.0','2019-01-01','0.0','','','','50.0','','','1.0','0.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','','50.0','0.0','50.0','','false','','','','','','false','','','','','','1.0','a0e6g000000OuHTAA0','','','0036g000006JcgFAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgCAAW','Community Center','0126g000000MyJlAAK','','','','','','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','0036g000006JcgTAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgDAAW','Contact Household','0126g000000MyJkAAK','One Market Street','San Francisco','CA','USA','94105','true','Household Account','0.0','0.0','','','Sample Contact','','Sample','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0e6g000000OuHTAA0','','','0036g000006JcgGAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgEAAW','Sample Organization','0126g000000MyJlAAK','One California Street','San Francisco','CA','USA','94105','false','','0.0','0.0','','','','','','0.0','','0.0','','','','0.0','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','0036g000006JcgGAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgFAAW','Figueroa and Nguyen Household','0126g000000MyJkAAK','25 10th Ave.','San Francisco','CA','','94121','true','Household Account','0.0','0.0','','','Jose Figueroa and Linda Nguyen','','Jose and Linda','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgIAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgGAAW','Red and Brown Household','0126g000000MyJkAAK','4270 4th Court','Arlington','MA','','02128','true','Household Account','50.0','50.0','2018','2018-01-22','Gurleen Red and Christian Brown','','Gurleen and Christian','50.0','2018-01-22','0.0','','','','50.0','','','1.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','','50.0','0.0','50.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgKAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgHAAW','Boston Household','0126g000000MyJkAAK','25 Boyston','Boston','MA','','2130','true','Household Account','62.5','75.0','2019','2018-01-22','Celia, Louis and Celia-Rae Boston','','Celia, Louis and Celia-Rae','75.0','2019-01-22','0.0','','','','75.0','','','2.0','0.0','50.0','0.0','75.0','0.0','1.0','0.0','1.0','0.0','','50.0','0.0','125.0','','false','','','','','','false','','','','','','3.0','a0e6g000000OuHTAA0','','','0036g000006JcgMAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgIAAW','Ng Household','0126g000000MyJkAAK','1172 Boylston St.','Boston','MA','','02199','true','Household Account','0.0','0.0','','','Walter and Felicia Ng','','Walter and Felicia','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgPAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgJAAW','Bruce Household','0126g000000MyJkAAK','10 Ocean Parkway','Brooklyn','NY','','02317','true','Household Account','0.0','0.0','','','Robert and Lonnie Bruce','','Robert and Lonnie','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgRAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgKAAW','Bainter and Navarro Household','0126g000000MyJkAAK','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','true','Household Account','50.0','50.0','2018','2018-01-02','Daphne Bainter and Deborah Navarro','','Daphne and Deborah','50.0','2018-01-02','0.0','','','','50.0','','','1.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','','50.0','0.0','50.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgTAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgLAAW','Mayo and Whitley Household','0126g000000MyJkAAK','840 Mount Street','Bay City','MI','','48706','true','Household Account','0.0','0.0','','','Chaz Mayo and Bryce Whitley','','Chaz and Bryce','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgVAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgMAAW','Davis Household','0126g000000MyJkAAK','1391 Diane Street','City Of Commerce','CA','','90040','true','Household Account','0.0','0.0','','','Nelda Davis','','Nelda','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0e6g000000OuHTAA0','','','0036g000006JcgWAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgNAAW','Mendoza Household','0126g000000MyJkAAK','55 Charleston','South San Francisco','CA','','94044','true','Household Account','100.0','100.0','2018','2018-04-20','Nilza and Jon Mendoza','','Nilza and Jon','100.0','2018-04-20','0.0','','','','100.0','','','1.0','0.0','100.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','','100.0','0.0','100.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgYAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgOAAW','Blum Household','0126g000000MyJkAAK','1 Cherry Street','Pleasant','NJ','','07777','true','Household Account','0.0','0.0','','','Zoe Blum','','Zoe','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','1.0','a0e6g000000OuHTAA0','','','0036g000006JcgZAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgPAAW','Subrahmanya Household','0126g000000MyJkAAK','918 Duffield Crescent St','Arlington','WA','','57828','true','Household Account','0.0','0.0','','','Sieffre and Baptiste Subrahmanya','','Sieffre and Baptiste','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgbAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgQAAW','Yudes Household','0126g000000MyJkAAK','8262 Phinney Ridge Rd','Georgetown','ME','','59586','true','Household Account','0.0','0.0','','','Lara and Charlotte Yudes','','Lara and Charlotte','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgdAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgRAAW','Lauterborn and Waterman Household','0126g000000MyJkAAK','37179 Bedford Shores St','Cole City','KS','','62223','true','Household Account','0.0','0.0','','','Eric Lauterborn and Concepcion de Jesus Waterman','','Eric and Concepcion de Jesus','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgfAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgSAAW','Aethelstan and Giannino Household','0126g000000MyJkAAK','9156 Springfield Green Dr','Marion','VA','','64860','true','Household Account','50.0','50.0','2019','2019-08-29','Mattia Aethelstan and Kallistrate Giannino','','Mattia and Kallistrate','50.0','2019-08-29','0.0','','','','50.0','','','1.0','0.0','0.0','50.0','50.0','0.0','0.0','1.0','1.0','0.0','','50.0','0.0','50.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcghAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgTAAW','O''Sullivan and Guerra Household','0126g000000MyJkAAK','4578 Linda Ave','Riverside','WV','','65739','true','Household Account','0.0','0.0','','','Irma O''Sullivan and Cassius Guerra','','Irma and Cassius','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgjAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgUAAW','Geier Household','0126g000000MyJkAAK','2289 David Budd St','Lebanon','MD','','66618','true','Household Account','25.0','25.0','2019','2019-08-31','Marat and Natasha Geier','','Marat and Natasha','25.0','2019-08-31','0.0','','','','25.0','','','1.0','0.0','0.0','25.0','25.0','0.0','0.0','1.0','1.0','0.0','','25.0','0.0','25.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcglAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgVAAW','Schubert and Maddox Household','0126g000000MyJkAAK','2357 Attlee Rd','Bristol','ME','','68376','true','Household Account','0.0','0.0','','','Hildie Schubert and Ursula Maddox','','Hildie and Ursula','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgnAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgWAAW','Campaign Household','0126g000000MyJkAAK','34 Shipham Close Rd','Truth or Consequences','NM','','55191','true','Household Account','0.0','0.0','','','Grace and Georgie Campaign','','Grace and Georgie','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgpAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgXAAW','Unnur Household','0126g000000MyJkAAK','24786 Handlebar Dr N','Madison','WI','','60465','true','Household Account','0.0','0.0','','','Fionnghuala and Maia Unnur','','Fionnghuala and Maia','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgrAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgYAAW','Thomas and Gibbons Household','0126g000000MyJkAAK','726 Twin House Lane','Springfield','MO','','65802','true','Household Account','0.0','0.0','','','Diana Thomas and Charlie Gibbons','','Diana and Charlie','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgsAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgZAAW','Kovacevic Household','0126g000000MyJkAAK','2323 Dent Way','Witchita','KS','','67497','true','Household Account','0.0','0.0','','','Gretel and Baron Kovacevic','','Gretel and Baron','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgvAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgaAAG','Lukeson and Zappa Household','0126g000000MyJkAAK','2391 Roborough Dr','Salem','LA','','69255','true','Household Account','0.0','0.0','','','Jozef Lukeson and Nageen Zappa','','Jozef and Nageen','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgxAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgbAAG','Djuradj and Tan Household','0126g000000MyJkAAK','2425 9th Ave','Madison','CA','','70134','true','Household Account','0.0','0.0','','','Kamil Djuradj and Suhani Tan','','Kamil and Suhani','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcgzAAC','');
INSERT INTO "Account" VALUES('0016g000007WEgcAAG','Conbon and Bi Household','0126g000000MyJkAAK','2459 44th St E','Reston','VA','','71013','true','Household Account','0.0','0.0','','','Azarel Conbon and Carol Bi','','Azarel and Carol','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jch1AAC','');
INSERT INTO "Account" VALUES('0016g000007WEgdAAG','Offermans Household','0126g000000MyJkAAK','2493 89th Way','Seattle','WA','','98103','true','Household Account','0.0','0.0','','','Eleonora and Deepshika Offermans','','Eleonora and Deepshika','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jch3AAC','');
INSERT INTO "Account" VALUES('0016g000007WEgeAAG','Sandeghin and Castle Household','0126g000000MyJkAAK','2527 Monroe Rd','Dover','CO','','98982','true','Household Account','0.0','0.0','','','Lucy Sandeghin and Helen Castle','','Lucy and Helen','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jch4AAC','');
INSERT INTO "Account" VALUES('0016g000007WEgfAAG','Sokolov Household','0126g000000MyJkAAK','2561 Madison Dr','Ashland','KY','','99861','true','Household Account','0.0','0.0','','','Solitude and Aldegund Sokolov','','Solitude and Aldegund','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jch7AAC','');
INSERT INTO "Account" VALUES('0016g000007WEggAAG','Nazarian Household','0126g000000MyJkAAK','2595 Montauk Ave W','Dover','FL','','99948','true','Household Account','0.0','0.0','','','Gabrielle and Alexi Nazarian','','Gabrielle and Alexi','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006Jch9AAC','');
INSERT INTO "Account" VALUES('0016g000007WEghAAG','McNeill Household','0126g000000MyJkAAK','2629 Nebraska St','Dover','FL','','99948','true','Household Account','0.0','0.0','','','Vukasin and Mpho McNeill','','Vukasin and Mpho','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JchBAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgiAAG','Devine Household','0126g000000MyJkAAK','','','','','','true','Household Account','0.0','0.0','','','Lois and Louis Devine','','Lois and Louis','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JchCAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgjAAG','Bullard Household','0126g000000MyJkAAK','129 W 81st','Buffalo','NY','','08982','true','Household Account','350.0','350.0','2019','2019-12-10','Robert, Sarah and Lisa Bullard','','Robert, Sarah and Lisa','350.0','2019-12-10','0.0','','','','350.0','','','1.0','0.0','0.0','350.0','350.0','0.0','0.0','1.0','1.0','0.0','','350.0','0.0','350.0','','false','','','','','','false','','','','','','3.0','a0e6g000000OuHTAA0','','','0036g000006JchGAAS','');
INSERT INTO "Account" VALUES('0016g000007WEgkAAG','Cloud Kicks','0126g000000MyJlAAK','1220 Burwell Heights Rd','Houston','TX','','77006','false','','600.0','2350.0','2018','2018-11-04','','','','1250.0','2019-01-07','0.0','','','','50.0','','','4.0','0.0','2350.0','0.0','50.0','0.0','3.0','0.0','1.0','0.0','','50.0','0.0','2400.0','','false','','','','','','true','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEglAAG','Newchange','0126g000000MyJlAAK','8990 Chatham Drive','Flower Mound','Tx','','39932','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgmAAG','Tesco','0126g000000MyJlAAK','111 Second Street','Boston','MA','','02130','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgnAAG','Orange Company','0126g000000MyJlAAK','122 Rother View','','','','01478','false','','112.5','225.0','2018','2018-05-21','','','','125.0','2018-05-21','0.0','','','','125.0','','','2.0','0.0','225.0','0.0','0.0','0.0','2.0','0.0','0.0','0.0','','100.0','0.0','225.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgoAAG','Acme Corporation','0126g000000MyJlAAK','500 Main St.','Cambridge','MA','','02130','false','','11250.0','22500.0','2018','2018-06-30','','','','12500.0','2018-06-30','0.0','','','','12500.0','','','2.0','0.0','22500.0','0.0','0.0','0.0','2.0','0.0','0.0','0.0','','10000.0','0.0','22500.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgpAAG','Target Campaigns','0126g000000MyJlAAK','232F Coppice Loan Pkwy','San Francisco','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEguAAG','American Firefighters for Historic Book Preservation','0126g000000MyJlAAK','292 Sporting Green Pl','Charlotte','CA','','94108','false','','75.0','75.0','2019','2019-09-02','','','','75.0','2019-09-02','0.0','','','','75.0','','','1.0','0.0','0.0','75.0','75.0','0.0','0.0','1.0','1.0','0.0','','75.0','0.0','75.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgvAAG','Foreign Fathers','0126g000000MyJlAAK','13 Angrew Trees Pl','Hill Station','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgwAAG','Turtledove Cinemas','0126g000000MyJlAAK','789 E Watersham Rte','Charlotte','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgxAAG','Yuri-Creek Playhouse','0126g000000MyJlAAK','3832 Laburnam Bank Rd','Vienna','VA','','22091','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgyAAG','Saltanas Bagels','0126g000000MyJlAAK','1222 Hunters Green Dr','Anita','WV','','20199','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgzAAG','Architecture for Adults','0126g000000MyJlAAK','8990 Iona Gardens Plaza','Meryls Town','Tx','','39932','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEh0AAG','National Basketball Conglomeration','0126g000000MyJlAAK','373 Clare Heathcliff Pkway','Spottsville','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEh1AAG','Junior Magazines','0126g000000MyJlAAK','44 Thomas Garth Dr','Hodgenville','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEh2AAG','Hedgepeth Industries','0126g000000MyJlAAK','29887 Bailey Hill La','Bourbonvilla','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEh3AAG','Glicks Furniture','0126g000000MyJlAAK','11235 Banana Seat Rd','Charleston','WV','','20777','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEh4AAG','Peets Coffee','0126g000000MyJlAAK','25 Market St','San Francisco','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEh5AAG','Benificent Insurance','0126g000000MyJlAAK','','','','','','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEh6AAG','Ventresca Household','0126g000000MyJkAAK','','','','','','true','Household Account','0.0','0.0','','','Alex Ventresca','','Alex','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JchIAAS','');
INSERT INTO "Account" VALUES('0016g000007WEh7AAG','Nostdal Works','0126g000000MyJlAAK','','','','','','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgqAAG','Save the Mutts','0126g000000MyJlAAK','2988 Raven Grange','Rochester','DE','','2222','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgrAAG','Spotsham University','0126g000000MyJlAAK','8923A Elm St','Dorchester','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgsAAG','University of Bringhampton','0126g000000MyJlAAK','982 Granary Point Ave N','Bingley','VA','','22091','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEgtAAG','Whimsey Wearhouse','0126g000000MyJlAAK','882 Pine Tree Hall','Nayes Dam','CA','','94108','false','','0.0','0.0','','','','','','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','','a0e6g000000OuHTAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEfIAAW','Dominico Household','0126g000000MyJkAAK','36624 Jefferson Way Way','Greenville','OR','','63102','true','Household Account','12500.0','12500.0','2019','2019-05-07','Em and Pavlina Dominico','','Em and Pavlina','12500.0','2019-05-07','0.0','','','','12500.0','','','1.0','0.0','0.0','12500.0','12500.0','0.0','0.0','1.0','1.0','0.0','','12500.0','0.0','12500.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHQAA0','','','0036g000006JceeAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfJAAW','Dominika and Luther Household','0126g000000MyJkAAK','36624 Jefferson Way Way','Greenville','OR','','63102','true','Household Account','10000.0','10000.0','2019','2019-08-27','Sarah Dominika and Sheridan Luther','','Sarah and Sheridan','10000.0','2019-08-27','0.0','','','','10000.0','','','1.0','0.0','0.0','10000.0','10000.0','0.0','0.0','1.0','1.0','0.0','','10000.0','0.0','10000.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHQAA0','','','0036g000006JcegAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfKAAW','Chong Household','0126g000000MyJkAAK','2137 Larry Street','San Francisco','CA','','94118','true','Household Account','68.33333333333333','205.0','2019','2019-01-01','Mattias, Jason, Sampson, Carly, Grayson and Julie Chong','','Mattias, Jason, Sampson, Carly, Grayson and Julie','100.0','2019-01-01','0.0','','','','75.0','','','3.0','0.0','0.0','0.0','205.0','0.0','0.0','0.0','3.0','0.0','','30.0','0.0','205.0','','false','','','','','','false','','','','','','6.0','a0e6g000000OuHRAA0','','','0036g000006JcerAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfLAAW','Loki and Shouta Household','0126g000000MyJkAAK','306 Monterey Drive Ave S','Franklin','AK','','56949','true','Household Account','160.0','160.0','2019','2019-09-23','Llewlyn Loki and Brianna Shouta','','Llewlyn and Brianna','160.0','2019-09-23','0.0','','','','160.0','','','1.0','0.0','0.0','160.0','160.0','0.0','0.0','1.0','1.0','0.0','','160.0','0.0','160.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHRAA0','','','0036g000006JceuAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfMAAW','Loui Household','0126g000000MyJkAAK','102 Drummand Grove Dr','Burnt Corn','AL','','56070','true','Household Account','125.0','125.0','2019','2019-05-01','Leo and Denorah Loui','','Leo and Denorah','125.0','2019-05-01','0.0','','','','125.0','','','1.0','0.0','0.0','125.0','125.0','0.0','0.0','1.0','1.0','0.0','','125.0','0.0','125.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHRAA0','','','0036g000006JcewAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfNAAW','George and Waterman Household','0126g000000MyJkAAK','2754 Glamis Place Way','Chester','MA','','58707','true','Household Account','300.0','300.0','2019','2019-05-03','America George and Nina Waterman','','America and Nina','300.0','2019-05-03','0.0','','','','300.0','','','1.0','0.0','0.0','300.0','300.0','0.0','0.0','1.0','1.0','0.0','','300.0','0.0','300.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHRAA0','','','0036g000006JceyAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfOAAW','de la O and Subrahmanya Household','0126g000000MyJkAAK','74358 S Wycliff Ave','Salem','MA','','61344','true','Household Account','125.0','125.0','2019','2019-05-05','Geoff de la O and Ansa Subrahmanya','','Geoff and Ansa','125.0','2019-05-05','0.0','','','','125.0','','','1.0','0.0','0.0','125.0','125.0','0.0','0.0','1.0','1.0','0.0','','125.0','0.0','125.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHRAA0','','','0036g000006Jcf0AAC','');
INSERT INTO "Account" VALUES('0016g000007WEfPAAW','American Firefights for Freedom','0126g000000MyJlAAK','292 Sporting Green Pl','Charlotte','CA','','94108','false','','100.0','100.0','2019','2019-09-02','','','','100.0','2019-09-02','0.0','','','','100.0','','','1.0','0.0','0.0','100.0','100.0','0.0','0.0','1.0','1.0','0.0','','100.0','0.0','100.0','','false','','','','','','false','','','','','','','a0e6g000000OuHRAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEfQAAW','Kim Household','0126g000000MyJkAAK','2137 Larry Street','San Francisco','CA','','94118','true','Household Account','50.0','100.0','2019','2018-01-01','Carl, Julie, Kevin and Carly Kim','','Carl, Julie, Kevin and Carly','75.0','2019-01-01','0.0','','','','75.0','','','3.0','0.0','50.0','0.0','100.0','0.0','1.0','0.0','2.0','0.0','','25.0','0.0','150.0','','false','','','','','','false','','','','','','4.0','a0e6g000000OuHRAA0','','','0036g000006Jcf4AAC','');
INSERT INTO "Account" VALUES('0016g000007WEfRAAW','Lewi Household','0126g000000MyJkAAK','102 Drummand Grove Dr','Burnt Corn','AL','','56070','true','Household Account','100.0','100.0','2019','2019-08-20','Tasgall and Leanne Lewi','','Tasgall and Leanne','100.0','2019-08-20','0.0','','','','100.0','','','1.0','0.0','0.0','100.0','100.0','0.0','0.0','1.0','1.0','0.0','','100.0','0.0','100.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHRAA0','','','0036g000006Jcf6AAC','');
INSERT INTO "Account" VALUES('0016g000007WEfSAAW','Oden Household','0126g000000MyJkAAK','306 Monterey Drive Ave S','Franklin','AK','','56949','true','Household Account','125.0','125.0','2019','2019-09-23','Freya and Brianna Oden','','Freya and Brianna','125.0','2019-09-23','0.0','','','','125.0','','','1.0','0.0','0.0','125.0','125.0','0.0','0.0','1.0','1.0','0.0','','125.0','0.0','125.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHRAA0','','','0036g000006Jcf8AAC','');
INSERT INTO "Account" VALUES('0016g000007WEfTAAW','Shouta Household','0126g000000MyJkAAK','2754 Glamis Place Way','Chester','MA','','58707','true','Household Account','225.0','225.0','2019','2019-08-22','Natalija and Nina Shouta','','Natalija and Nina','225.0','2019-08-22','0.0','','','','225.0','','','1.0','0.0','0.0','225.0','225.0','0.0','0.0','1.0','1.0','0.0','','225.0','0.0','225.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHRAA0','','','0036g000006JcfAAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfUAAW','Primoz Household','0126g000000MyJkAAK','74358 S Wycliff Ave','Salem','MA','','61344','true','Household Account','100.0','100.0','2019','2019-08-25','Jeffry and Ansa Primoz','','Jeffry and Ansa','100.0','2019-08-25','0.0','','','','100.0','','','1.0','0.0','0.0','100.0','100.0','0.0','0.0','1.0','1.0','0.0','','100.0','0.0','100.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHRAA0','','','0036g000006JcfCAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfVAAW','Johnson''s General Stores','0126g000000MyJlAAK','1121 David Vale Road','Reston','VA','','22091','false','','87.5','250.0','2019','2018-03-01','','','','125.0','2019-08-23','0.0','','','','50.0','','','4.0','0.0','100.0','250.0','250.0','0.0','1.0','3.0','3.0','0.0','','50.0','0.0','350.0','','false','','','','','','false','','','','','','','a0e6g000000OuHRAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEfWAAW','Orange Tree Imports','0126g000000MyJlAAK','1 Main Street','San Francisco','CA','','94108','false','','37.5','150.0','2019','2019-05-02','','','','75.0','2019-08-22','0.0','','','','10.0','','','4.0','0.0','0.0','150.0','150.0','0.0','0.0','4.0','4.0','0.0','','10.0','0.0','150.0','','false','','','','','','false','','','','','','','a0e6g000000OuHRAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEfXAAW','Gnarl''s Bicycles','0126g000000MyJlAAK','991 Bay Common Dr S','St. Louis','CA','','94108','false','','112.5','225.0','2019','2019-05-06','','','','125.0','2019-08-26','0.0','','','','100.0','','','2.0','0.0','0.0','225.0','225.0','0.0','0.0','2.0','2.0','0.0','','100.0','0.0','225.0','','false','','','','','','false','','','','','','','a0e6g000000OuHRAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEfYAAW','Trelawni and Zappa Household','0126g000000MyJkAAK','18312 Duchess Rd','Kingston','WA','','63981','true','Household Account','9375.0','9375.0','2019','2019-05-08','Nicolai Trelawni and Buddy Zappa','','Nicolai and Buddy','9375.0','2019-05-08','0.0','','','','9375.0','','','1.0','0.0','0.0','9375.0','9375.0','0.0','0.0','1.0','1.0','0.0','','9375.0','0.0','9375.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHSAA0','','','0036g000006JceiAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfZAAW','Evans and Wong Household','0126g000000MyJkAAK','','','','','','true','Household Account','461.665','3533.32','2019','2018-11-04','Candace Evans and Calvin Wong','','Candace and Calvin','833.33','2019-11-30','0.0','','','','833.33','','','10.0','0.0','1083.33','3333.32','3533.32','0.0','4.0','4.0','6.0','0.0','','50.0','0.0','4616.65','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHSAA0','','','0036g000006JcekAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfaAAG','Thulani and Abbascia Household','0126g000000MyJkAAK','18312 Duchess Rd','Kingston','WA','','63981','true','Household Account','7500.0','7500.0','2019','2019-08-28','Eugenius Thulani and Nudd Abbascia','','Eugenius and Nudd','7500.0','2019-08-28','0.0','','','','7500.0','','','1.0','0.0','0.0','7500.0','7500.0','0.0','0.0','1.0','1.0','0.0','','7500.0','0.0','7500.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHSAA0','','','0036g000006JcemAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfbAAG','Music Foundation','0126g000000MyJlAAK','123 Main St.','San Francisco','CA','US','94105','false','','1125.0','1250.0','2019','2018-01-01','','','','1250.0','2019-01-01','0.0','','','','1250.0','','','2.0','0.0','1000.0','0.0','1250.0','0.0','1.0','0.0','1.0','0.0','','1000.0','0.0','2250.0','','false','','','','','','false','','','','','','','a0e6g000000OuHSAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEfcAAG','Blotts, Hargrove and Spludge','0126g000000MyJlAAK','1223 Freshman Way','Cooperfield','CA','','94108','false','','1125.0','2250.0','2019','2019-05-10','','','','1250.0','2019-08-30','0.0','','','','1000.0','','','2.0','0.0','0.0','2250.0','2250.0','0.0','0.0','2.0','2.0','0.0','','1000.0','0.0','2250.0','','false','','','','','','false','','','','','','','a0e6g000000OuHSAA0','','','','');
INSERT INTO "Account" VALUES('0016g000007WEfdAAG','Hernandez and Nguyen Household','0126g000000MyJkAAK','55 Charleston','South San Francisco','CA','','94044','true','Household Account','125.0','125.0','2018','2018-04-20','Nilza Hernandez and Jon Nguyen','','Nilza and Jon','125.0','2018-04-20','0.0','','','','125.0','','','1.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','','125.0','0.0','125.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfEAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfeAAG','Bace Household','0126g000000MyJkAAK','10 Ocean Parkway','Brooklyn','NY','','2317','true','Household Account','0.0','0.0','','','Robert and Lonnie Bace','','Robert and Lonnie','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfGAAS','');
INSERT INTO "Account" VALUES('0016g000007WEffAAG','Ivans Household','0126g000000MyJkAAK','','','','','','true','Household Account','125.0','125.0','2018','2018-11-05','Geetika Ivans','','Geetika','125.0','2018-11-05','0.0','','','','125.0','','','1.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','','125.0','0.0','125.0','','false','','','','','','false','','','','','','1.0','a0e6g000000OuHTAA0','','','0036g000006JcfHAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfgAAG','Nyugen and Offermans Household','0126g000000MyJkAAK','1172 Boylston St.','Boston','MA','','2199','true','Household Account','0.0','0.0','','','Henry Nyugen and Felicity Offermans','','Henry and Felicity','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfJAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfhAAG','Smythe and Whitley Household','0126g000000MyJkAAK','1 Cherry Street','Pleasant','NJ','','7777','true','Household Account','0.0','0.0','','','Caroline Smythe and Elias Whitley','','Caroline and Elias','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfLAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfiAAG','Beethavent and Unnur Household','0126g000000MyJkAAK','2357 Attlee Rd','Bristol','ME','','68376','true','Household Account','0.0','0.0','','','Georgia Beethavent and Orion Unnur','','Georgia and Orion','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfNAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfjAAG','Mavis Household','0126g000000MyJkAAK','1391 Diane Street','City Of Commerce','CA','','90040','true','Household Account','0.0','0.0','','','Nelda and Stapleton Mavis','','Nelda and Stapleton','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfPAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfkAAG','Bainter Household','0126g000000MyJkAAK','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','true','Household Account','75.0','75.0','2019','2019-01-02','Edith and Deborah Bainter','','Edith and Deborah','75.0','2019-01-02','0.0','','','','75.0','','','1.0','0.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','','75.0','0.0','75.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfRAAS','');
INSERT INTO "Account" VALUES('0016g000007WEflAAG','Orange and Tan Household','0126g000000MyJkAAK','4270 4th Court','Arlington','MA','','2128','true','Household Account','75.0','75.0','2019','2019-01-22','Patrick Orange and Olivia Tan','','Patrick and Olivia','75.0','2019-01-22','0.0','','','','75.0','','','1.0','0.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','','75.0','0.0','75.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfTAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfmAAG','Vakil and Wong Household','0126g000000MyJkAAK','918 Duffield Crescent St','Arlington','WA','','57828','true','Household Account','0.0','0.0','','','Sufjan Vakil and Neve Wong','','Sufjan and Neve','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfVAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfnAAG','Rudddles Household','0126g000000MyJkAAK','8262 Phinney Ridge Rd','Georgetown','ME','','59586','true','Household Account','0.0','0.0','','','Lara and Charlotte Rudddles','','Lara and Charlotte','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfXAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfoAAG','Jackson and Wong Household','0126g000000MyJkAAK','37179 Bedford Shores St','Fairfield','KS','','62223','true','Household Account','0.0','0.0','','','Eliza Jackson and Nitika Wong','','Eliza and Nitika','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfZAAS','');
INSERT INTO "Account" VALUES('0016g000007WEfpAAG','Aethelstan Household','0126g000000MyJkAAK','9156 Springfield Green Dr','Marion','VA','','64860','true','Household Account','75.0','75.0','2019','2019-05-09','Mattia and Kallistrate Aethelstan','','Mattia and Kallistrate','75.0','2019-05-09','0.0','','','','75.0','','','1.0','0.0','0.0','75.0','75.0','0.0','0.0','1.0','1.0','0.0','','75.0','0.0','75.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfbAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfqAAG','O''Shea and Primoz Household','0126g000000MyJkAAK','4578 Linda Ave','Riverside','WV','','65739','true','Household Account','0.0','0.0','','','Irma O''Shea and Nancy Primoz','','Irma and Nancy','0.0','','0.0','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','0.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcfdAAC','');
INSERT INTO "Account" VALUES('0016g000007WEfrAAG','Geiser-Bann Household','0126g000000MyJkAAK','2289 David Budd St','Lebanon','MD','','66618','true','Household Account','30.0','30.0','2019','2019-05-11','Bennett and Maya Geiser-Bann','','Bennett and Maya','30.0','2019-05-11','0.0','','','','30.0','','','1.0','0.0','0.0','30.0','30.0','0.0','0.0','1.0','1.0','0.0','','30.0','0.0','30.0','','false','','','','','','false','','','','','','2.0','a0e6g000000OuHTAA0','','','0036g000006JcffAAC','');
INSERT INTO "Account" VALUES('0016g00000Bs4xfAAB','Way for Good','0126g000000MyJlAAK','','','','','','false','','1000.0','1000.0','2018','2018-11-06','','','','1000.0','2018-11-06','0.0','','','','1000.0','','','1.0','0.0','1000.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','','1000.0','0.0','1000.0','','false','','','','','','false','','','','','','','','','','','');
CREATE TABLE "Account_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "Account_rt_mapping" VALUES('0126g000000MyJkAAK','HH_Account');
INSERT INTO "Account_rt_mapping" VALUES('0126g000000MyJlAAK','Organization');
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
INSERT INTO "Campaign" VALUES('7016g000000gmWNAAY','Give a Life','false','2018-10-01','2018-11-05','Planned','Telemarketing','','','7016g000000gmWUAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWOAAY','No More Hostile Architecture','true','2019-01-01','2019-11-30','In Progress','Advocacy','','','7016g000000gmWTAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWPAAY','Petition Drives','true','2019-01-01','2019-12-31','In Progress','Advocacy','','','7016g000000gmWOAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWQAAY','Direct Mail: January 2019 - Hostile Architecture','true','2019-01-14','2019-03-15','Completed','Fundraising','','','7016g000000gmWYAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWRAAY','Direct Mail: May 2019 - Hostile Architecture','true','2019-05-01','2019-05-31','Completed','Fundraising','','','7016g000000gmWYAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWSAAY','NMH Petition','true','2019-01-01','2019-05-31','In Progress','Advocacy','','','7016g000000gmWPAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWTAAY','2019 Advocacy Campaigns','true','2019-01-01','2019-12-31','In Progress','Advocacy','','','');
INSERT INTO "Campaign" VALUES('7016g000000gmWUAAY','Annual Appeal 2018','true','2018-01-01','2018-12-31','Completed','Fundraising','','','7016g000000gmWXAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWVAAY','NMH Transitional Housing Capital Campaign','true','2018-10-01','2019-12-31','In Progress','Fundraisng','','','');
INSERT INTO "Campaign" VALUES('7016g000000gmWWAAY','Annual Appeal 2019','true','2019-01-01','2019-12-31','In Progress','Fundraising','','','7016g000000gmWXAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWXAAY','Annual Fund','true','','','In Progress','Fundraising','','','');
INSERT INTO "Campaign" VALUES('7016g000000gmWYAAY','Email Outreach','true','2019-01-01','2019-01-01','In Progress','Advocacy','','','7016g000000gmWOAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWZAAY','Advocacy Training Days','true','2019-01-01','2019-12-31','In Progress','Advocacy','0016g000007WEgCAAW','0036g000006JcgTAAS','7016g000000gmWOAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWaAAI','Event: August 2019 - Advocacy Training Day','true','2019-08-07','2019-08-07','Completed','Advocacy','0016g000007WEgCAAW','0036g000006JcgTAAS','7016g000000gmWZAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWbAAI','Event: January 2019 - Advocacy Training Day','true','2019-01-15','2019-01-15','Completed','Advocacy','0016g000007WEgCAAW','0036g000006JcgTAAS','7016g000000gmWZAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWcAAI','Event: June 2019 - Advocacy Training Day','true','2019-06-20','2019-06-20','Completed','Advocacy','0016g000007WEgCAAW','0036g000006JcgTAAS','7016g000000gmWZAAY');
INSERT INTO "Campaign" VALUES('7016g000000gmWdAAI','Event: October 2019 - Advocacy Training Day','true','2019-10-24','2019-10-24','Completed','Advocacy','0016g000007WEgCAAW','0036g000006JcgTAAS','7016g000000gmWZAAY');
CREATE TABLE "CampaignMember" (
	sf_id VARCHAR(255) NOT NULL, 
	"Status" VARCHAR(255), 
	campaign_id VARCHAR(255), 
	contact_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "CampaignMember" VALUES('00v6g000000mN04AAE','Responded','7016g000000gmWQAAY','0036g000006JcfRAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN05AAE','Responded','7016g000000gmWQAAY','0036g000006JcfTAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN06AAE','Responded','7016g000000gmWQAAY','0036g000006JcgNAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN07AAE','Responded','7016g000000gmWQAAY','0036g000006JcenAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN08AAE','Responded','7016g000000gmWQAAY','0036g000006JcesAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN09AAE','Responded','7016g000000gmWRAAY','0036g000006JcfbAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0AAAU','Responded','7016g000000gmWRAAY','0036g000006JcffAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0BAAU','Responded','7016g000000gmWRAAY','0036g000006JcewAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0CAAU','Responded','7016g000000gmWRAAY','0036g000006JceyAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0DAAU','Responded','7016g000000gmWRAAY','0036g000006Jcf0AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0EAAU','Responded','7016g000000gmWRAAY','0036g000006JceiAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0FAAU','Responded','7016g000000gmWUAAY','0036g000006JcfEAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0GAAU','Responded','7016g000000gmWUAAY','0036g000006JcfHAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0HAAU','Responded','7016g000000gmWUAAY','0036g000006JcgKAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0IAAU','Responded','7016g000000gmWUAAY','0036g000006JcgMAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0JAAU','Responded','7016g000000gmWUAAY','0036g000006JcgTAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0KAAU','Responded','7016g000000gmWUAAY','0036g000006JcgYAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0LAAU','Responded','7016g000000gmWUAAY','0036g000006JchGAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0MAAU','Responded','7016g000000gmWUAAY','0036g000006Jcf4AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0NAAU','Responded','7016g000000gmWUAAY','0036g000006JcekAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0OAAU','Responded','7016g000000gmWVAAY','0036g000006JceeAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0PAAU','Responded','7016g000000gmWVAAY','0036g000006JcfiAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0QAAU','Responded','7016g000000gmWVAAY','0036g000006JcfmAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0RAAU','Responded','7016g000000gmWVAAY','0036g000006JcgIAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0SAAU','Responded','7016g000000gmWVAAY','0036g000006JcekAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2lAAE','Sent','7016g000000gmWcAAI','0036g000006JchHAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2mAAE','Sent','7016g000000gmWcAAI','0036g000006JchIAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2nAAE','Sent','7016g000000gmWcAAI','0036g000006JcepAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1EAAU','Sent','7016g000000gmWaAAI','0036g000006JcewAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1FAAU','Sent','7016g000000gmWaAAI','0036g000006JceyAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1GAAU','Sent','7016g000000gmWaAAI','0036g000006JcezAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1HAAU','Sent','7016g000000gmWaAAI','0036g000006Jcf1AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1IAAU','Attended','7016g000000gmWaAAI','0036g000006Jcf2AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1JAAU','Attended','7016g000000gmWaAAI','0036g000006Jcf4AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1KAAU','Sent','7016g000000gmWaAAI','0036g000006Jcf6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1LAAU','Sent','7016g000000gmWaAAI','0036g000006JcfBAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1MAAU','Attended','7016g000000gmWaAAI','0036g000006JcehAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1NAAU','Attended','7016g000000gmWaAAI','0036g000006JcekAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1OAAU','Sent','7016g000000gmWaAAI','0036g000006JcelAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1PAAU','Attended','7016g000000gmWbAAI','0036g000006JceeAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1QAAU','Attended','7016g000000gmWbAAI','0036g000006JcegAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1RAAU','Sent','7016g000000gmWbAAI','0036g000006JcfFAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1SAAU','RSVP Yes','7016g000000gmWbAAI','0036g000006JcfGAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1TAAU','Attended','7016g000000gmWbAAI','0036g000006JcfIAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1UAAU','Sent','7016g000000gmWbAAI','0036g000006JcfLAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1VAAU','Sent','7016g000000gmWbAAI','0036g000006JcfQAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1WAAU','Sent','7016g000000gmWbAAI','0036g000006JcfRAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1XAAU','RSVP Yes','7016g000000gmWbAAI','0036g000006JcfVAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1YAAU','Sent','7016g000000gmWbAAI','0036g000006JcfaAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1ZAAU','Sent','7016g000000gmWbAAI','0036g000006JcfbAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1aAAE','Sent','7016g000000gmWbAAI','0036g000006JcfeAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1bAAE','Sent','7016g000000gmWbAAI','0036g000006JcfgAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1cAAE','Sent','7016g000000gmWbAAI','0036g000006JcfjAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1dAAE','Sent','7016g000000gmWbAAI','0036g000006JcfsAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1eAAE','Sent','7016g000000gmWbAAI','0036g000006JcfuAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1fAAE','Sent','7016g000000gmWbAAI','0036g000006JcfxAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1gAAE','Attended','7016g000000gmWbAAI','0036g000006Jcg6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1hAAE','Sent','7016g000000gmWbAAI','0036g000006Jcg7AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1iAAE','RSVP Yes','7016g000000gmWbAAI','0036g000006Jcg9AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1jAAE','Sent','7016g000000gmWbAAI','0036g000006JcgEAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1kAAE','RSVP Yes','7016g000000gmWbAAI','0036g000006JcgLAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1lAAE','Sent','7016g000000gmWbAAI','0036g000006JcgMAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1mAAE','Attended','7016g000000gmWbAAI','0036g000006JcgOAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1nAAE','RSVP Yes','7016g000000gmWbAAI','0036g000006JcgSAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1oAAE','Sent','7016g000000gmWbAAI','0036g000006JcgTAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1pAAE','RSVP Yes','7016g000000gmWbAAI','0036g000006JcgXAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1qAAE','Sent','7016g000000gmWbAAI','0036g000006JcghAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1rAAE','Sent','7016g000000gmWbAAI','0036g000006JcgiAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1sAAE','Sent','7016g000000gmWbAAI','0036g000006JcgkAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1tAAE','Sent','7016g000000gmWbAAI','0036g000006JcgsAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1uAAE','Sent','7016g000000gmWbAAI','0036g000006Jch0AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1vAAE','Sent','7016g000000gmWbAAI','0036g000006Jch1AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1wAAE','RSVP Yes','7016g000000gmWbAAI','0036g000006Jch3AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1xAAE','Sent','7016g000000gmWbAAI','0036g000006Jch6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1yAAE','Sent','7016g000000gmWbAAI','0036g000006Jch8AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2oAAE','Sent','7016g000000gmWcAAI','0036g000006JceuAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2pAAE','Attended','7016g000000gmWcAAI','0036g000006JcewAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2qAAE','Sent','7016g000000gmWcAAI','0036g000006JceyAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2rAAE','Sent','7016g000000gmWcAAI','0036g000006JcezAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2sAAE','Sent','7016g000000gmWcAAI','0036g000006Jcf1AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2tAAE','Sent','7016g000000gmWcAAI','0036g000006Jcf2AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2uAAE','Sent','7016g000000gmWcAAI','0036g000006Jcf4AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2vAAE','Attended','7016g000000gmWcAAI','0036g000006Jcf6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2wAAE','Sent','7016g000000gmWcAAI','0036g000006JcfBAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2xAAE','Sent','7016g000000gmWcAAI','0036g000006JcehAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2yAAE','Sent','7016g000000gmWcAAI','0036g000006JcekAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2zAAE','Sent','7016g000000gmWcAAI','0036g000006JcelAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN30AAE','Sent','7016g000000gmWdAAI','0036g000006JcfFAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN31AAE','Sent','7016g000000gmWdAAI','0036g000006JcfGAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN32AAE','Sent','7016g000000gmWdAAI','0036g000006JcfLAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN33AAE','Sent','7016g000000gmWdAAI','0036g000006JcfQAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN34AAE','Sent','7016g000000gmWdAAI','0036g000006JcfRAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN35AAE','Sent','7016g000000gmWdAAI','0036g000006JcfVAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN36AAE','Attended','7016g000000gmWdAAI','0036g000006JcfaAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN37AAE','Attended','7016g000000gmWdAAI','0036g000006JcfbAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN38AAE','Attended','7016g000000gmWdAAI','0036g000006JcfeAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN39AAE','Attended','7016g000000gmWdAAI','0036g000006JcfgAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3AAAU','RSVP Yes','7016g000000gmWdAAI','0036g000006JcfjAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3BAAU','RSVP Yes','7016g000000gmWdAAI','0036g000006JcfsAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3CAAU','Attended','7016g000000gmWdAAI','0036g000006JcfuAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3DAAU','Attended','7016g000000gmWdAAI','0036g000006JcfxAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3EAAU','Sent','7016g000000gmWdAAI','0036g000006Jcg7AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3FAAU','Attended','7016g000000gmWdAAI','0036g000006Jcg9AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3GAAU','Sent','7016g000000gmWdAAI','0036g000006JcgEAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3HAAU','RSVP Yes','7016g000000gmWdAAI','0036g000006JcgLAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3IAAU','RSVP Yes','7016g000000gmWdAAI','0036g000006JcgMAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3JAAU','Sent','7016g000000gmWdAAI','0036g000006JcgSAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3KAAU','Sent','7016g000000gmWdAAI','0036g000006JcgTAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3LAAU','Sent','7016g000000gmWdAAI','0036g000006JcgXAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3MAAU','RSVP Yes','7016g000000gmWdAAI','0036g000006JcghAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3NAAU','RSVP Yes','7016g000000gmWdAAI','0036g000006JcgiAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3OAAU','RSVP Yes','7016g000000gmWdAAI','0036g000006JcgkAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3PAAU','Sent','7016g000000gmWdAAI','0036g000006JcgsAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3QAAU','Sent','7016g000000gmWdAAI','0036g000006Jch0AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3RAAU','Sent','7016g000000gmWdAAI','0036g000006Jch1AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3SAAU','Sent','7016g000000gmWdAAI','0036g000006Jch3AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3TAAU','Sent','7016g000000gmWdAAI','0036g000006Jch6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3UAAU','Sent','7016g000000gmWdAAI','0036g000006Jch8AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3VAAU','Sent','7016g000000gmWdAAI','0036g000006JchHAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3WAAU','Sent','7016g000000gmWdAAI','0036g000006JchIAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3XAAU','Sent','7016g000000gmWdAAI','0036g000006JcepAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3YAAU','Sent','7016g000000gmWdAAI','0036g000006JceuAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3ZAAU','Sent','7016g000000gmWdAAI','0036g000006JcewAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1zAAE','Sent','7016g000000gmWbAAI','0036g000006JchHAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN20AAE','Sent','7016g000000gmWbAAI','0036g000006JchIAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN21AAE','Sent','7016g000000gmWbAAI','0036g000006JcepAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN22AAE','RSVP Yes','7016g000000gmWbAAI','0036g000006JceuAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN23AAE','Sent','7016g000000gmWbAAI','0036g000006JcewAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN24AAE','Sent','7016g000000gmWbAAI','0036g000006JceyAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN25AAE','Sent','7016g000000gmWbAAI','0036g000006JcezAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN26AAE','RSVP Yes','7016g000000gmWbAAI','0036g000006Jcf1AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN27AAE','Sent','7016g000000gmWbAAI','0036g000006Jcf2AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN28AAE','Sent','7016g000000gmWbAAI','0036g000006Jcf4AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN29AAE','Sent','7016g000000gmWbAAI','0036g000006Jcf6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2AAAU','Sent','7016g000000gmWbAAI','0036g000006JcfBAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2BAAU','Sent','7016g000000gmWbAAI','0036g000006JcehAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2CAAU','Attended','7016g000000gmWbAAI','0036g000006JceiAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2DAAU','Sent','7016g000000gmWbAAI','0036g000006JcekAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2EAAU','Sent','7016g000000gmWbAAI','0036g000006JcelAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2FAAU','Attended','7016g000000gmWbAAI','0036g000006JcemAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2GAAU','Sent','7016g000000gmWcAAI','0036g000006JcfFAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2HAAU','Sent','7016g000000gmWcAAI','0036g000006JcfGAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2IAAU','Sent','7016g000000gmWcAAI','0036g000006JcfLAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2JAAU','Sent','7016g000000gmWcAAI','0036g000006JcfQAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2KAAU','Sent','7016g000000gmWcAAI','0036g000006JcfRAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2LAAU','Sent','7016g000000gmWcAAI','0036g000006JcfVAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2MAAU','Sent','7016g000000gmWcAAI','0036g000006JcfaAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2NAAU','Sent','7016g000000gmWcAAI','0036g000006JcfbAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2OAAU','Sent','7016g000000gmWcAAI','0036g000006JcfeAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2PAAU','Sent','7016g000000gmWcAAI','0036g000006JcfgAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2QAAU','Sent','7016g000000gmWcAAI','0036g000006JcfjAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2RAAU','Attended','7016g000000gmWcAAI','0036g000006JcfsAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2SAAU','Sent','7016g000000gmWcAAI','0036g000006JcfuAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2TAAU','Sent','7016g000000gmWcAAI','0036g000006JcfxAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2UAAU','Sent','7016g000000gmWcAAI','0036g000006Jcg7AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2VAAU','Sent','7016g000000gmWcAAI','0036g000006Jcg9AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2WAAU','Sent','7016g000000gmWcAAI','0036g000006JcgEAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2XAAU','Sent','7016g000000gmWcAAI','0036g000006JcgLAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2YAAU','Sent','7016g000000gmWcAAI','0036g000006JcgMAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2ZAAU','Sent','7016g000000gmWcAAI','0036g000006JcgSAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2aAAE','Sent','7016g000000gmWcAAI','0036g000006JcgTAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2bAAE','Sent','7016g000000gmWcAAI','0036g000006JcgXAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2cAAE','Sent','7016g000000gmWcAAI','0036g000006JcghAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2dAAE','Sent','7016g000000gmWcAAI','0036g000006JcgiAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2eAAE','Attended','7016g000000gmWcAAI','0036g000006JcgkAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2fAAE','Sent','7016g000000gmWcAAI','0036g000006JcgsAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2gAAE','Sent','7016g000000gmWcAAI','0036g000006Jch0AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2hAAE','Attended','7016g000000gmWcAAI','0036g000006Jch1AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2iAAE','Sent','7016g000000gmWcAAI','0036g000006Jch3AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2jAAE','Sent','7016g000000gmWcAAI','0036g000006Jch6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN2kAAE','Sent','7016g000000gmWcAAI','0036g000006Jch8AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3aAAE','Sent','7016g000000gmWdAAI','0036g000006JceyAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3bAAE','Sent','7016g000000gmWdAAI','0036g000006JcezAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3cAAE','Sent','7016g000000gmWdAAI','0036g000006Jcf1AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3dAAE','Sent','7016g000000gmWdAAI','0036g000006Jcf2AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3eAAE','Sent','7016g000000gmWdAAI','0036g000006Jcf4AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3fAAE','Attended','7016g000000gmWdAAI','0036g000006Jcf6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3gAAE','Attended','7016g000000gmWdAAI','0036g000006JcfBAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3hAAE','Sent','7016g000000gmWdAAI','0036g000006JcehAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3iAAE','Attended','7016g000000gmWdAAI','0036g000006JcekAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN3jAAE','RSVP Yes','7016g000000gmWdAAI','0036g000006JcelAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0TAAU','Responded','7016g000000gmWWAAY','0036g000006JcegAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0UAAU','Responded','7016g000000gmWWAAY','0036g000006JcghAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0VAAU','Responded','7016g000000gmWWAAY','0036g000006JcglAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0WAAU','Responded','7016g000000gmWWAAY','0036g000006JcerAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0XAAU','Responded','7016g000000gmWWAAY','0036g000006JceuAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0YAAU','Responded','7016g000000gmWWAAY','0036g000006Jcf4AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0ZAAU','Responded','7016g000000gmWWAAY','0036g000006Jcf6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0aAAE','Responded','7016g000000gmWWAAY','0036g000006Jcf8AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0bAAE','Responded','7016g000000gmWWAAY','0036g000006JcfAAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0cAAE','Responded','7016g000000gmWWAAY','0036g000006JcfCAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0dAAE','Responded','7016g000000gmWWAAY','0036g000006JcemAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0eAAE','Responded','7016g000000gmWNAAY','0036g000006JcekAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0fAAE','Sent','7016g000000gmWaAAI','0036g000006JcfFAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0gAAE','Sent','7016g000000gmWaAAI','0036g000006JcfGAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0hAAE','Attended','7016g000000gmWaAAI','0036g000006JcfLAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0iAAE','Sent','7016g000000gmWaAAI','0036g000006JcfQAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0jAAE','Sent','7016g000000gmWaAAI','0036g000006JcfRAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0kAAE','Sent','7016g000000gmWaAAI','0036g000006JcfVAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0lAAE','Sent','7016g000000gmWaAAI','0036g000006JcfaAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0mAAE','Sent','7016g000000gmWaAAI','0036g000006JcfbAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0nAAE','Sent','7016g000000gmWaAAI','0036g000006JcfeAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0oAAE','Attended','7016g000000gmWaAAI','0036g000006JcfgAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0pAAE','Attended','7016g000000gmWaAAI','0036g000006JcfjAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0qAAE','Sent','7016g000000gmWaAAI','0036g000006JcfsAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0rAAE','Sent','7016g000000gmWaAAI','0036g000006JcfuAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0sAAE','Sent','7016g000000gmWaAAI','0036g000006JcfxAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0tAAE','Sent','7016g000000gmWaAAI','0036g000006Jcg7AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0uAAE','Sent','7016g000000gmWaAAI','0036g000006Jcg9AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0vAAE','Sent','7016g000000gmWaAAI','0036g000006JcgEAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0wAAE','Sent','7016g000000gmWaAAI','0036g000006JcgLAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0xAAE','Attended','7016g000000gmWaAAI','0036g000006JcgMAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0yAAE','Sent','7016g000000gmWaAAI','0036g000006JcgSAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN0zAAE','Sent','7016g000000gmWaAAI','0036g000006JcgTAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN10AAE','Sent','7016g000000gmWaAAI','0036g000006JcgXAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN11AAE','Sent','7016g000000gmWaAAI','0036g000006JcghAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN12AAE','Attended','7016g000000gmWaAAI','0036g000006JcgiAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN13AAE','Sent','7016g000000gmWaAAI','0036g000006JcgkAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN14AAE','Sent','7016g000000gmWaAAI','0036g000006JcgsAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN15AAE','Attended','7016g000000gmWaAAI','0036g000006Jch0AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN16AAE','Sent','7016g000000gmWaAAI','0036g000006Jch1AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN17AAE','Sent','7016g000000gmWaAAI','0036g000006Jch3AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN18AAE','Sent','7016g000000gmWaAAI','0036g000006Jch6AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN19AAE','Sent','7016g000000gmWaAAI','0036g000006Jch8AAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1AAAU','Sent','7016g000000gmWaAAI','0036g000006JchHAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1BAAU','Sent','7016g000000gmWaAAI','0036g000006JchIAAS');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1CAAU','Attended','7016g000000gmWaAAI','0036g000006JcepAAC');
INSERT INTO "CampaignMember" VALUES('00v6g000000mN1DAAU','Sent','7016g000000gmWaAAI','0036g000006JceuAAC');
CREATE TABLE "CampaignMemberStatus" (
	sf_id VARCHAR(255) NOT NULL, 
	"HasResponded" VARCHAR(255), 
	"IsDefault" VARCHAR(255), 
	"Label" VARCHAR(255), 
	campaign_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthDEAQ','false','true','Sent','7016g000000gmWNAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthEEAQ','true','false','Responded','7016g000000gmWNAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthFEAQ','false','true','Sent','7016g000000gmWOAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthGEAQ','true','false','Responded','7016g000000gmWOAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthHEAQ','false','true','Sent','7016g000000gmWPAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthIEAQ','true','false','Responded','7016g000000gmWPAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthJEAQ','false','true','Sent','7016g000000gmWQAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthKEAQ','true','false','Responded','7016g000000gmWQAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthLEAQ','false','true','Sent','7016g000000gmWRAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthMEAQ','true','false','Responded','7016g000000gmWRAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthNEAQ','false','true','Sent','7016g000000gmWSAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthOEAQ','true','false','Responded','7016g000000gmWSAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthPEAQ','false','true','Sent','7016g000000gmWTAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthQEAQ','true','false','Responded','7016g000000gmWTAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthREAQ','false','true','Sent','7016g000000gmWUAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthSEAQ','true','false','Responded','7016g000000gmWUAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthTEAQ','false','true','Sent','7016g000000gmWVAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthUEAQ','true','false','Responded','7016g000000gmWVAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthVEAQ','false','true','Sent','7016g000000gmWWAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthWEAQ','true','false','Responded','7016g000000gmWWAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthXEAQ','false','true','Sent','7016g000000gmWXAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthYEAQ','true','false','Responded','7016g000000gmWXAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthZEAQ','false','true','Sent','7016g000000gmWYAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthaEAA','true','false','Responded','7016g000000gmWYAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthbEAA','false','true','Sent','7016g000000gmWZAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthcEAA','true','false','Responded','7016g000000gmWZAAY');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthdEAA','false','true','Sent','7016g000000gmWaAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gtheEAA','true','false','Responded','7016g000000gmWaAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthfEAA','false','true','Sent','7016g000000gmWbAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthgEAA','true','false','Responded','7016g000000gmWbAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthhEAA','false','true','Sent','7016g000000gmWcAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthiEAA','true','false','Responded','7016g000000gmWcAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthjEAA','false','true','Sent','7016g000000gmWdAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthkEAA','true','false','Responded','7016g000000gmWdAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthmEAA','true','false','RSVP Yes','7016g000000gmWaAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthnEAA','false','false','Cancelled','7016g000000gmWaAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthoEAA','false','false','No Show','7016g000000gmWaAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthpEAA','true','false','Attended','7016g000000gmWaAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthqEAA','false','false','RSVP No','7016g000000gmWaAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthrEAA','false','false','RSVP No','7016g000000gmWbAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthsEAA','true','false','RSVP Yes','7016g000000gmWbAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthtEAA','false','false','No Show','7016g000000gmWbAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthuEAA','true','false','Attended','7016g000000gmWbAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthvEAA','false','false','Cancelled','7016g000000gmWbAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthwEAA','false','false','RSVP No','7016g000000gmWcAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthxEAA','true','false','Attended','7016g000000gmWcAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthyEAA','false','false','Cancelled','7016g000000gmWcAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gthzEAA','false','false','No Show','7016g000000gmWcAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gti0EAA','true','false','RSVP Yes','7016g000000gmWcAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gti1EAA','false','false','Cancelled','7016g000000gmWdAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gti2EAA','false','false','RSVP No','7016g000000gmWdAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gti3EAA','false','false','No Show','7016g000000gmWdAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gti4EAA','false','false','RSVP Yes','7016g000000gmWdAAI');
INSERT INTO "CampaignMemberStatus" VALUES('01Y6g000000gti5EAA','true','false','Attended','7016g000000gmWdAAI');
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
INSERT INTO "Case" VALUES('5006g000006DYN7AAO','false','Household goods needed','New','Phone','Problem','Medium','Alex needs household goods for herself and Daniel as they prepare to move to their new home.','0016g000007WEh6AAG','0036g000006JchIAAS','');
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
INSERT INTO "Contact" VALUES('0036g000006JcedAAC','Pavlina','Dominico','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','pavlut@lutes.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','12500.0','0.0','12500.0','0.0','','0.0','0.0','false','false','false','false','false','12500.0','2019-05-07','12500.0','2019-05-07','12500.0','2019-05-07','1.0','1.0','0.0','0.0','1.0','12500.0','false','0016g000007WEfIAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAeEAO','');
INSERT INTO "Contact" VALUES('0036g000006JceeAAC','Em','Dominico','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','emdom23@snailmail.com','Home','Personal','Home','false','','','','','12500.0','12500.0','2019','2019-05-07','','12500.0','2019-05-07','0.0','','','','12500.0','','','','1.0','0.0','0.0','12500.0','12500.0','0.0','0.0','1.0','1.0','0.0','12500.0','0.0','0.0','0.0','0.0','','0.0','12500.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfIAAW','a0e6g000000OuHQAA0','','','','','a0M6g000000NTAeEAO','0016g000007WEgqAAG');
INSERT INTO "Contact" VALUES('0036g000006JcefAAC','Sheridan','Luther','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','pavlut@lutes.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','10000.0','0.0','10000.0','0.0','','0.0','0.0','false','false','false','false','false','10000.0','2019-08-27','10000.0','2019-08-27','10000.0','2019-08-27','1.0','1.0','0.0','0.0','1.0','10000.0','false','0016g000007WEfJAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAfEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcehAAC','Buddy','Zappa','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','9375.0','0.0','9375.0','0.0','','0.0','0.0','false','false','false','false','false','9375.0','2019-05-08','9375.0','2019-05-08','9375.0','2019-05-08','1.0','1.0','0.0','0.0','1.0','9375.0','false','0016g000007WEfYAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAgEAO','');
INSERT INTO "Contact" VALUES('0036g000006JceiAAC','Nicolai','Trelawni','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','eugeniusthulani81@kalemail.com','Home','Personal','Home','false','','','','','9375.0','9375.0','2019','2019-05-08','','9375.0','2019-05-08','0.0','','','','9375.0','','','','1.0','0.0','0.0','9375.0','9375.0','0.0','0.0','1.0','1.0','0.0','9375.0','0.0','0.0','0.0','0.0','','0.0','9375.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfYAAW','a0e6g000000OuHSAA0','','','','','a0M6g000000NTAgEAO','0016g000007WEgrAAG');
INSERT INTO "Contact" VALUES('0036g000006JcejAAC','Calvin','Wong','false','','','','','','','false','false','','rich@evansfam.com','Home','Personal','','false','','','rich@ballooga.com','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','3533.32','0.0','4616.65','1083.33','','0.0','0.0','false','false','false','false','false','50.0','2018-11-04','833.33','2018-11-30','0.0','2020-01-10','5.0','6.0','1.0','4.0','11.0','3333.32','false','0016g000007WEfZAAW','','a0e6g000000OuHTAA0','','','','','');
INSERT INTO "Contact" VALUES('0036g000006JcekAAC','Candace','Evans','false','','','','','','','false','false','','candy@evansfam.com','Home','Personal','','false','','','','','461.665','3533.32','2019','2018-11-04','','833.33','2019-11-30','0.0','','','','833.33','','','','10.0','0.0','1083.33','3333.32','3533.32','0.0','4.0','4.0','6.0','0.0','50.0','0.0','0.0','350.0','350.0','','0.0','4616.65','false','false','false','false','false','100.0','2018-11-05','250.0','2018-11-06','250.0','2018-11-06','0.0','0.0','0.0','2.0','2.0','0.0','false','0016g000007WEfZAAW','a0e6g000000OuHSAA0','','','','','','0016g000007WEgkAAG');
INSERT INTO "Contact" VALUES('0036g000006JcelAAC','Nudd','Abbascia','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','7500.0','0.0','7500.0','0.0','','0.0','0.0','false','false','false','false','false','7500.0','2019-08-28','7500.0','2019-08-28','7500.0','2019-08-28','1.0','1.0','0.0','0.0','1.0','7500.0','false','0016g000007WEfaAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAhEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcemAAC','Eugenius','Thulani','false','','18312 Duchess Rd','Kingston','WA','','63981','false','false','','eugeniusthulani@kalemail.com','Home','Personal','Home','false','','','','','7500.0','7500.0','2019','2019-08-28','','7500.0','2019-08-28','0.0','','','','7500.0','','','','1.0','0.0','0.0','7500.0','7500.0','0.0','0.0','1.0','1.0','0.0','7500.0','0.0','0.0','0.0','0.0','','0.0','7500.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfaAAG','a0e6g000000OuHSAA0','','','','','a0M6g000000NTAhEAO','0016g000007WEgrAAG');
INSERT INTO "Contact" VALUES('0036g000006JcenAAC','Sampson','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim37@fleckens.hu','Home','Personal','Home','false','','','','','30.0','30.0','2019','2019-01-01','2.0','30.0','2019-01-01','0.0','','','','30.0','','','','1.0','0.0','0.0','0.0','30.0','0.0','0.0','0.0','1.0','0.0','30.0','175.0','0.0','175.0','0.0','','0.0','30.0','false','false','false','false','false','75.0','2019-01-01','100.0','2019-01-01','75.0','2019-01-01','0.0','2.0','0.0','0.0','2.0','0.0','false','0016g000007WEfKAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAiEAO','');
INSERT INTO "Contact" VALUES('0036g000006JceoAAC','Jason','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','1.0','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','0.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','30.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','0.0','3.0','0.0','0.0','3.0','0.0','false','0016g000007WEfKAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAiEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcepAAC','Carly','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carly@kim.com','Home','Personal','Home','false','','','','','0.0','0.0','','','3.0','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','0.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','30.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','0.0','3.0','0.0','0.0','3.0','0.0','false','0016g000007WEfKAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAiEAO','');
INSERT INTO "Contact" VALUES('0036g000006JceqAAC','Julie','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','kim@kim.com','Home','Personal','Home','false','','','','','0.0','0.0','','','5.0','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','205.0','0.0','205.0','0.0','','0.0','0.0','false','false','false','false','false','30.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','0.0','3.0','0.0','0.0','3.0','0.0','false','0016g000007WEfKAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAiEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcerAAC','Mattias','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim39@fleckens.hu','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-01-01','0.0','100.0','2019-01-01','0.0','','','','100.0','','','','1.0','0.0','0.0','0.0','100.0','0.0','0.0','0.0','1.0','0.0','100.0','105.0','0.0','105.0','0.0','','0.0','100.0','false','false','false','false','false','30.0','2019-01-01','75.0','2019-01-01','30.0','2019-01-01','0.0','2.0','0.0','0.0','2.0','0.0','false','0016g000007WEfKAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAiEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcesAAC','Grayson','Chong','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim35@fleckens.hu','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-01','4.0','75.0','2019-01-01','0.0','','','','75.0','','','','1.0','0.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','75.0','130.0','0.0','130.0','0.0','','0.0','75.0','false','false','false','false','false','30.0','2019-01-01','100.0','2019-01-01','30.0','2019-01-01','0.0','2.0','0.0','0.0','2.0','0.0','false','0016g000007WEfKAAW','a0e6g000000OuHTAA0','','','','','a0M6g000000NTAiEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcetAAC','Brianna','Shouta','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','160.0','0.0','160.0','0.0','','0.0','0.0','false','false','false','false','false','160.0','2019-09-23','160.0','2019-09-23','160.0','2019-09-23','1.0','1.0','0.0','0.0','1.0','160.0','false','0016g000007WEfLAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAjEAO','');
INSERT INTO "Contact" VALUES('0036g000006JceuAAC','Llewlyn','Loki','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','ghosse59@isolationideas.info','Work','Personal','Home','false','','','','(356) 385-7489','160.0','160.0','2019','2019-09-23','','160.0','2019-09-23','0.0','','','','160.0','','','','1.0','0.0','0.0','160.0','160.0','0.0','0.0','1.0','1.0','0.0','160.0','0.0','0.0','0.0','0.0','','0.0','160.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfLAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAjEAO','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006JcevAAC','Denorah','Loui','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','0.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-05-01','125.0','2019-05-01','125.0','2019-05-01','1.0','1.0','0.0','0.0','1.0','125.0','false','0016g000007WEfMAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAkEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcewAAC','Leo','Loui','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','9alsfa7.666a43@pendokngana.gq','Home','Personal','Home','false','','','','','125.0','125.0','2019','2019-05-01','','125.0','2019-05-01','0.0','','','','125.0','','','','1.0','0.0','0.0','125.0','125.0','0.0','0.0','1.0','1.0','0.0','125.0','0.0','0.0','0.0','0.0','','0.0','125.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfMAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAkEAO','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006JcexAAC','Nina','Waterman','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','300.0','0.0','300.0','0.0','','0.0','0.0','false','false','false','false','false','300.0','2019-05-03','300.0','2019-05-03','300.0','2019-05-03','1.0','1.0','0.0','0.0','1.0','300.0','false','0016g000007WEfNAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAlEAO','');
INSERT INTO "Contact" VALUES('0036g000006JceyAAC','America','George','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','natalijas69@shouta.com','Home','Personal','Home','false','','','','','300.0','300.0','2019','2019-05-03','','300.0','2019-05-03','0.0','','','','300.0','','','','1.0','0.0','0.0','300.0','300.0','0.0','0.0','1.0','1.0','0.0','300.0','0.0','0.0','0.0','0.0','','0.0','300.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfNAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAlEAO','0016g000007WEgpAAG');
INSERT INTO "Contact" VALUES('0036g000006JcegAAC','Sarah','Dominika','false','','36624 Jefferson Way Way','Greenville','OR','','63102','false','false','','emdom@snailmail.com','Home','Personal','Home','false','','','','','10000.0','10000.0','2019','2019-08-27','','10000.0','2019-08-27','0.0','','','','10000.0','','','','1.0','0.0','0.0','10000.0','10000.0','0.0','0.0','1.0','1.0','0.0','10000.0','0.0','0.0','0.0','0.0','','0.0','10000.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfJAAW','a0e6g000000OuHQAA0','','','','','a0M6g000000NTAfEAO','0016g000007WEgqAAG');
INSERT INTO "Contact" VALUES('0036g000006JcezAAC','Ansa','Subrahmanya','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','0.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-05-05','125.0','2019-05-05','125.0','2019-05-05','1.0','1.0','0.0','0.0','1.0','125.0','false','0016g000007WEfOAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAmEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jcf1AAC','Julie','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','kim@kim.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','0.0','150.0','50.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','0.0','2.0','0.0','1.0','3.0','0.0','false','0016g000007WEfQAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAnEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jcf2AAC','Carly','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carly@kim.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','0.0','150.0','50.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','0.0','2.0','0.0','1.0','3.0','0.0','false','0016g000007WEfQAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAnEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jcf3AAC','Kevin','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','0.0','150.0','50.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-01','75.0','2019-01-01','25.0','2019-01-01','0.0','2.0','0.0','1.0','3.0','0.0','false','0016g000007WEfQAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAnEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jcf4AAC','Carl','Kim','false','','2137 Larry Street','San Francisco','CA','','94118','false','false','','carlykim@fleckens.hu','Home','Personal','Home','false','','','','','50.0','100.0','2019','2018-01-01','','75.0','2019-01-01','0.0','','','','75.0','','','','3.0','0.0','50.0','0.0','100.0','0.0','1.0','0.0','2.0','0.0','25.0','0.0','0.0','0.0','0.0','','0.0','150.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfQAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAnEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jcf5AAC','Leanne','Lewi','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','0.0','100.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-08-20','100.0','2019-08-20','100.0','2019-08-20','1.0','1.0','0.0','0.0','1.0','100.0','false','0016g000007WEfRAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAoEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jcf6AAC','Tasgall','Lewi','false','','102 Drummand Grove Dr','Burnt Corn','AL','','56070','false','false','','9alsfa7.666a@pendokngana.gq','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-08-20','','100.0','2019-08-20','0.0','','','','100.0','','','','1.0','0.0','0.0','100.0','100.0','0.0','0.0','1.0','1.0','0.0','100.0','0.0','0.0','0.0','0.0','','0.0','100.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfRAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAoEAO','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006Jcf7AAC','Brianna','Oden','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','0.0','125.0','0.0','','0.0','0.0','false','false','false','false','false','125.0','2019-09-23','125.0','2019-09-23','125.0','2019-09-23','1.0','1.0','0.0','0.0','1.0','125.0','false','0016g000007WEfSAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTApEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jcf8AAC','Freya','Oden','false','','306 Monterey Drive Ave S','Franklin','AK','','56949','false','false','','ghosse@isolationideas.info','Work','Personal','Home','false','','','','(356) 385-7489','125.0','125.0','2019','2019-09-23','','125.0','2019-09-23','0.0','','','','125.0','','','','1.0','0.0','0.0','125.0','125.0','0.0','0.0','1.0','1.0','0.0','125.0','0.0','0.0','0.0','0.0','','0.0','125.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfSAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTApEAO','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006Jcf9AAC','Nina','Shouta','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','225.0','0.0','225.0','0.0','','0.0','0.0','false','false','false','false','false','225.0','2019-08-22','225.0','2019-08-22','225.0','2019-08-22','1.0','1.0','0.0','0.0','1.0','225.0','false','0016g000007WEfTAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAqEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfAAAS','Natalija','Shouta','false','','2754 Glamis Place Way','Chester','MA','','58707','false','false','','natalijas@shouta.com','Home','Personal','Home','false','','','','','225.0','225.0','2019','2019-08-22','','225.0','2019-08-22','0.0','','','','225.0','','','','1.0','0.0','0.0','225.0','225.0','0.0','0.0','1.0','1.0','0.0','225.0','0.0','0.0','0.0','0.0','','0.0','225.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfTAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAqEAO','0016g000007WEgpAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfBAAS','Ansa','Primoz','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','0.0','100.0','0.0','','0.0','0.0','false','false','false','false','false','100.0','2019-08-25','100.0','2019-08-25','100.0','2019-08-25','1.0','1.0','0.0','0.0','1.0','100.0','false','0016g000007WEfUAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTArEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfCAAS','Jeffry','Primoz','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','jeffryp@primoz.com','Home','Personal','Home','false','','','','','100.0','100.0','2019','2019-08-25','','100.0','2019-08-25','0.0','','','','100.0','','','','1.0','0.0','0.0','100.0','100.0','0.0','0.0','1.0','1.0','0.0','100.0','0.0','0.0','0.0','0.0','','0.0','100.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfUAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTArEAO','0016g000007WEglAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfDAAS','Jon','Nguyen','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','jon@mendoza.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','125.0','125.0','','0.0','0.0','false','false','false','false','false','125.0','2018-04-20','125.0','2018-04-20','125.0','2018-04-20','0.0','0.0','0.0','1.0','1.0','0.0','false','0016g000007WEfdAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAsEAO','0016g000007WEh4AAG');
INSERT INTO "Contact" VALUES('0036g000006JcfEAAS','Nilza','Hernandez','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','nilza51@mendoza.com','Home','Personal','Home','false','','','','','125.0','125.0','2018','2018-04-20','','125.0','2018-04-20','0.0','','','','125.0','','','','1.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','125.0','0.0','0.0','0.0','0.0','','0.0','125.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfdAAG','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAsEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfFAAS','Lonnie','Bace','false','','10 Ocean Parkway','Brooklyn','NY','','2317','false','false','','lonnie@bruce.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfeAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAtEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfGAAS','Robert','Bace','false','','10 Ocean Parkway','Brooklyn','NY','','2317','false','false','','robert7@bruce.com','Home','Work','Home','false','','','robertbruce@oranges.com','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfeAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAtEAO','0016g000007WEgnAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfHAAS','Geetika','Ivans','false','','','','','','','false','false','','candy25@evansfam.com','Home','Personal','','false','','','','','125.0','125.0','2018','2018-11-05','','125.0','2018-11-05','0.0','','','','125.0','','','','1.0','0.0','125.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','125.0','0.0','0.0','250.0','250.0','','0.0','125.0','false','false','false','false','false','250.0','2018-11-06','250.0','2018-11-06','250.0','2018-11-06','0.0','0.0','0.0','1.0','1.0','0.0','false','0016g000007WEffAAG','a0e6g000000OuHRAA0','','','','','','0016g000007WEgkAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfIAAS','Felicity','Offermans','false','','1172 Boylston St.','Boston','MA','','2199','false','false','','felicia@ng.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfgAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAuEAO','0016g000007WEfbAAG');
INSERT INTO "Contact" VALUES('0036g000006Jcf0AAC','Geoff','de la O','false','','74358 S Wycliff Ave','Salem','MA','','61344','false','false','','jeffryp63@primoz.com','Home','Personal','Home','false','','','','','125.0','125.0','2019','2019-05-05','','125.0','2019-05-05','0.0','','','','125.0','','','','1.0','0.0','0.0','125.0','125.0','0.0','0.0','1.0','1.0','0.0','125.0','0.0','0.0','0.0','0.0','','0.0','125.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfOAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTAmEAO','0016g000007WEglAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfJAAS','Henry','Nyugen','false','','1172 Boylston St.','Boston','MA','','2199','false','false','','henry55@ng.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfgAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAuEAO','0016g000007WEfVAAW');
INSERT INTO "Contact" VALUES('0036g000006JcfKAAS','Elias','Whitley','false','','1 Cherry Street','Pleasant','NJ','','7777','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfhAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAvEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfLAAS','Caroline','Smythe','false','','1 Cherry Street','Pleasant','NJ','','7777','false','false','','smith71@smith.com','Home','Work','Home','false','','','carolines@orangetree.org','(922) 298-8282','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfhAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAvEAO','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006JcfMAAS','Orion','Unnur','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfiAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAwEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfOAAS','Stapleton','Mavis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfjAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAxEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfPAAS','Nelda','Mavis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','neldaddavis17@cuvox.de','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfjAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAxEAO','0016g000007WEfbAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfQAAS','Deborah','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','deborahmnavarro@cuvox.de','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','0.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-01-02','75.0','2019-01-02','75.0','2019-01-02','0.0','1.0','0.0','0.0','1.0','0.0','false','0016g000007WEfkAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAyEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfRAAS','Edith','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','daphnecbainter3@teleworm.us','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-02','','75.0','2019-01-02','0.0','','','','75.0','','','','1.0','0.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','75.0','0.0','0.0','0.0','0.0','','0.0','75.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfkAAG','a0e6g000000OuHTAA0','','','','','a0M6g000000NTAyEAO','0016g000007WEfVAAW');
INSERT INTO "Contact" VALUES('0036g000006JcfSAAS','Olivia','Tan','false','','4270 4th Court','Arlington','MA','','2128','false','false','','chipboat@chippy.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','0.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-01-22','75.0','2019-01-22','75.0','2019-01-22','0.0','1.0','0.0','0.0','1.0','0.0','false','0016g000007WEflAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAzEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfTAAS','Patrick','Orange','false','','4270 4th Court','Arlington','MA','','2128','false','false','','cardinal65@chippy.com','Home','Personal','Home','false','','','','','75.0','75.0','2019','2019-01-22','','75.0','2019-01-22','0.0','','','','75.0','','','','1.0','0.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','75.0','0.0','0.0','0.0','0.0','','0.0','75.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEflAAG','a0e6g000000OuHTAA0','','','','','a0M6g000000NTAzEAO','0016g000007WEglAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfUAAS','Neve','Wong','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfmAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB0EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfVAAS','Sufjan','Vakil','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','sieffre75@hitchens.com','Mobile','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfmAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB0EAO','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006JcfWAAS','Charlotte','Rudddles','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfnAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB1EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfXAAS','Lara','Rudddles','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','lara.yudes85@hitchens.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfnAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB1EAO','0016g000007WEfVAAW');
INSERT INTO "Contact" VALUES('0036g000006JcfYAAS','Nitika','Wong','false','','37179 Bedford Shores St','Fairfield','KS','','62223','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfoAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB2EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfZAAS','Eliza','Jackson','false','','37179 Bedford Shores St','Fairfield','KS','','62223','false','false','','taneshaep77@taconet.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfoAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB2EAO','0016g000007WEfXAAW');
INSERT INTO "Contact" VALUES('0036g000006JcfaAAC','Kallistrate','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','0.0','75.0','0.0','','0.0','0.0','false','false','false','false','false','75.0','2019-05-09','75.0','2019-05-09','75.0','2019-05-09','1.0','1.0','0.0','0.0','1.0','75.0','false','0016g000007WEfpAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB3EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfbAAC','Mattia','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','rosebud1@meetsaround.com','Work','Work','Home','false','','','','(202) 909-9999','75.0','75.0','2019','2019-05-09','','75.0','2019-05-09','0.0','','','','75.0','','','','1.0','0.0','0.0','75.0','75.0','0.0','0.0','1.0','1.0','0.0','75.0','0.0','0.0','0.0','0.0','','0.0','75.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfpAAG','a0e6g000000OuHTAA0','','','','','a0M6g000000NTB3EAO','0016g000007WEgsAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfcAAC','Nancy','Primoz','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfqAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB4EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfdAAC','Irma','O''Shea','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','irmaosull57@sullyhouse.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfqAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB4EAO','0016g000007WEfcAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfeAAC','Maya','Geiser-Bann','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','babsgeiger@happydogs.net','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','30.0','0.0','30.0','0.0','','0.0','0.0','false','false','false','false','false','30.0','2019-05-11','30.0','2019-05-11','30.0','2019-05-11','1.0','1.0','0.0','0.0','1.0','30.0','false','0016g000007WEfrAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB5EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcffAAC','Bennett','Geiser-Bann','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','maratgeier33@goregens.edu','Home','Personal','Home','false','','','','','30.0','30.0','2019','2019-05-11','','30.0','2019-05-11','0.0','','','','30.0','','','','1.0','0.0','0.0','30.0','30.0','0.0','0.0','1.0','1.0','0.0','30.0','0.0','0.0','0.0','0.0','','0.0','30.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfrAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB5EAO','0016g000007WEgtAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfgAAC','Bryce','Nazarian','false','','840 Mount Street','Bay City','MI','','48706','false','false','','brycemwhitley@cuvox.de','Mobile','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfsAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB6EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfhAAC','Danny','Clerr','false','','840 Mount Street','Bay City','MI','','48706','false','false','','dannyvmayo47@rhyta.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfsAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB6EAO','0016g000007WEgoAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfNAAS','Georgia','Beethavent','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','hildielovesfrank67@schuberts.com','Work','Work','Home','false','','','hildiebakes@bakery.net','(202) 756-9723','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfiAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTAwEAO','0016g000007WEfPAAW');
INSERT INTO "Contact" VALUES('0036g000006JcfiAAC','Sehar','Ivans','false','','','','','','','false','false','','candy27@evansfam.com','Home','Personal','','false','','','','','75.0','75.0','2018','2018-11-04','','75.0','2018-11-04','0.0','','','','75.0','','','','1.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','75.0','0.0','0.0','0.0','0.0','','0.0','75.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEftAAG','a0e6g000000OuHTAA0','','','','','','0016g000007WEgkAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfjAAC','Calvin','Ivans','false','','','','','','','false','false','','rich@evansfam.com','Home','Personal','','false','','','rich@ballooga.com','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfuAAG','','a0e6g000000OuHTAA0','','','','','');
INSERT INTO "Contact" VALUES('0036g000006JcfkAAC','Lakshmi','Ivans','false','','','','','','','false','false','','candy29@evansfam.com','Home','Personal','','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfuAAG','','a0e6g000000OuHTAA0','','','','','0016g000007WEgkAAG');
INSERT INTO "Contact" VALUES('0036g000006JcflAAC','Linda','Figueroo','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','linda@nguyen.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfvAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB7EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfmAAC','Roger','Figueroo','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','josefigleaf31@gmail.com','Home','Work','Home','false','','','jfigueroa@glicks.com','(222) 898-2002','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfvAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB7EAO','0016g000007WEgkAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfqAAC','Deandre','Clerk','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','deandre13@blast.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfxAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB9EAO','0016g000007WEh0AAG');
INSERT INTO "Contact" VALUES('0036g000006JcfrAAC','Xiao-yu','Kanban','false','','2459 44th St E','Reston','VA','','71013','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfyAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBAEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcfsAAC','Heidi','Kanban','false','','2459 44th St E','Reston','VA','','71013','false','false','','azarel15@kanban.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfyAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBAEA4','0016g000007WEgyAAG');
INSERT INTO "Contact" VALUES('0036g000006JcftAAC','Lois','Primordial','false','','','','','','','false','false','','lois19@devine.com','Home','Personal','','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfzAAG','','a0e6g000000OuHTAA0','','','','','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006JcfuAAC','Louis','Primordial','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfzAAG','','a0e6g000000OuHTAA0','','','','','0016g000007WEh5AAG');
INSERT INTO "Contact" VALUES('0036g000006JcfvAAC','Suhani','Djyradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','suhanitan@snailmail.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg0AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBBEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcfwAAC','Kamilla','Djyradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','kamild21@snailmail.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg0AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBBEA4','0016g000007WEgxAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfxAAC','Roger','Kasprawicz','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg1AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBCEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcfyAAC','Luiza','Kasprawicz','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','copacetic41@cowabunga.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg1AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBCEA4','0016g000007WEgvAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfzAAC','Nageen','Navarro','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg2AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBDEA4','');
INSERT INTO "Contact" VALUES('0036g000006Jcg0AAC','Jozef','Bateson','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','jozef45@hitchens.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg2AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBDEA4','0016g000007WEgwAAG');
INSERT INTO "Contact" VALUES('0036g000006Jcg1AAC','Mpho','Ng','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg3AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBEEA4','');
INSERT INTO "Contact" VALUES('0036g000006Jcg2AAC','Natali','Frasier','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','vukasinmcneill49@narnia.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg3AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBEEA4','0016g000007WEh1AAG');
INSERT INTO "Contact" VALUES('0036g000006Jcg3AAC','Bartolomej','Oden','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg4AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBFEA4','');
INSERT INTO "Contact" VALUES('0036g000006Jcg4AAC','Gabriel','Prasad','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','gabrielsphd53@atoms.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg4AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBFEA4','0016g000007WEh2AAG');
INSERT INTO "Contact" VALUES('0036g000006Jcg5AAC','Krithika','Sokolov','false','','2493 89th Way','Seattle','WA','','98103','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg5AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBGEA4','');
INSERT INTO "Contact" VALUES('0036g000006Jcg6AAC','Eleonora','Bates','false','','2493 89th Way','Seattle','WA','','98103','false','false','','eleonora61@scrumteam.net','Work','Work','Home','false','','','eleonora@scrumteam.net','(989) 777-4543','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg5AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBGEA4','0016g000007WEgzAAG');
INSERT INTO "Contact" VALUES('0036g000006Jcg7AAC','Aldegund','Wong','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg6AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBHEA4','');
INSERT INTO "Contact" VALUES('0036g000006Jcg8AAC','Mirce','Bokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','soko73@protons.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg6AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBHEA4','0016g000007WEh1AAG');
INSERT INTO "Contact" VALUES('0036g000006Jcg9AAC','Diana','Mandela','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','dianarthomas79@superrito.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg7AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBIEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcfnAAC','Harold','Campagna','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','georgie@campaigns.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfwAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB8EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcfoAAC','Tessa','Campagna','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','tessa11@campaign.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfwAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB8EAO','0016g000007WEgpAAG');
INSERT INTO "Contact" VALUES('0036g000006JcfpAAC','Helena','Clerk','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEfxAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTB9EAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgAAAS','Crystal','Yudes','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','crystalhmudd@fleckens.hu','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg7AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBIEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgBAAS','Evrim','Watson','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','yudes@herbert.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg8AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBJEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgCAAS','Nashville','Watson','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','fionnur83@greensburg.ky.gov','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEg8AAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBJEA4','0016g000007WEfbAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgDAAS','Zach','Rymph','false','','762 Smiley','Port Townsend','WA','','98368','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','1.0','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgAAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBKEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgEAAS','Jessie','Nostdal','false','','762 Smiley','Port Townsend','WA','','98368','false','false','','drjessie@nostdalworks.com','Home','Personal','Home','false','','','','','0.0','0.0','','','0.0','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgAAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBKEA4','0016g000007WEh7AAG');
INSERT INTO "Contact" VALUES('0036g000006JcgFAAS','Erica','Douglass','false','','','','','','','false','false','','','Home','Personal','','false','','','','','50.0','50.0','2019','2019-01-01','','50.0','2019-01-01','0.0','','','','50.0','','','','1.0','0.0','0.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','50.0','50.0','0.0','300.0','250.0','','0.0','50.0','false','false','false','false','false','250.0','2018-11-06','250.0','2018-11-06','50.0','2019-01-07','0.0','1.0','0.0','1.0','2.0','0.0','false','0016g000007WEgBAAW','a0e6g000000OuHTAA0','','','','','','0016g000007WEgkAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgGAAS','Sample','Contact','false','','One Market Street','San Francisco','CA','USA','94105','false','false','sample.contact@otheremail.com','sample.contact@email.com','Work','Personal','Home','false','','','sample.contact@workemail.com','(202) 555-9654','0.0','0.0','','','','0.0','','0.0','','','','0.0','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgDAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBLEA4','0016g000007WEgEAAW');
INSERT INTO "Contact" VALUES('0036g000006JcgHAAS','Linda','Nguyen','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','linda@nguyen.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgFAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBMEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgIAAS','Jose','Figueroa','false','','25 10th Ave.','San Francisco','CA','','94121','false','false','','josefigleaf@gmail.com','Home','Work','Home','false','','','jfigueroa@glicks.com','(222) 898-2002','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','250.0','250.0','','0.0','0.0','false','false','false','false','false','250.0','2018-11-06','250.0','2018-11-06','250.0','2018-11-06','0.0','0.0','0.0','1.0','1.0','0.0','false','0016g000007WEgFAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBMEA4','0016g000007WEgkAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgJAAS','Christian','Brown','false','','4270 4th Court','Arlington','MA','','02128','false','false','','chipboat@chippy.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','50.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-22','50.0','2018-01-22','50.0','2018-01-22','0.0','0.0','0.0','1.0','1.0','0.0','false','0016g000007WEgGAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBNEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgKAAS','Gurleen','Red','false','','4270 4th Court','Arlington','MA','','02128','false','false','','cardinal@chippy.com','Home','Personal','Home','false','','','','','50.0','50.0','2018','2018-01-22','','50.0','2018-01-22','0.0','','','','50.0','','','','1.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','50.0','0.0','0.0','0.0','0.0','','0.0','50.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgGAAW','a0e6g000000OuHTAA0','','','','','a0M6g000000NTBNEA4','0016g000007WEglAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgLAAS','Louis','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','louis@boston.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','75.0','0.0','125.0','50.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-22','75.0','2019-01-22','75.0','2019-01-22','0.0','1.0','0.0','1.0','2.0','0.0','false','0016g000007WEgHAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBOEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgMAAS','Celia','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','celia@boston.com','Home','Personal','Home','false','','','','(555) 555-5555','50.0','50.0','2018','2018-01-22','','50.0','2018-01-22','0.0','','','','50.0','','','','1.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','50.0','75.0','0.0','75.0','0.0','','0.0','50.0','false','false','false','false','false','75.0','2019-01-22','75.0','2019-01-22','75.0','2019-01-22','0.0','1.0','0.0','0.0','1.0','0.0','false','0016g000007WEgHAAW','a0e6g000000OuHTAA0','','','','','a0M6g000000NTBOEA4','0016g000007WEgmAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgNAAS','Celia-Rae','Boston','false','','25 Boyston','Boston','MA','','2130','false','false','','celia5@boston.com','Home','Personal','Home','false','','','','(555) 555-5555','75.0','75.0','2019','2019-01-22','','75.0','2019-01-22','0.0','','','','75.0','','','','1.0','0.0','0.0','0.0','75.0','0.0','0.0','0.0','1.0','0.0','75.0','0.0','0.0','50.0','50.0','','0.0','75.0','false','false','false','false','false','50.0','2018-01-22','50.0','2018-01-22','50.0','2018-01-22','0.0','0.0','0.0','1.0','1.0','0.0','false','0016g000007WEgHAAW','a0e6g000000OuHTAA0','','','','','a0M6g000000NTBOEA4','0016g000007WEgmAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgOAAS','Felicia','Ng','false','','1172 Boylston St.','Boston','MA','','02199','false','false','','felicia@ng.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgIAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBQEA4','0016g000007WEfbAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgPAAS','Walter','Ng','false','','1172 Boylston St.','Boston','MA','','02199','false','false','','henry@ng.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgIAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBQEA4','0016g000007WEfVAAW');
INSERT INTO "Contact" VALUES('0036g000006JcgQAAS','Lonnie','Bruce','false','','10 Ocean Parkway','Brooklyn','NY','','02317','false','false','','lonnie@bruce.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgJAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBREA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgRAAS','Robert','Bruce','false','','10 Ocean Parkway','Brooklyn','NY','','02317','false','false','','robert@bruce.com','Home','Work','Home','false','','','robertbruce@oranges.com','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgJAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBREA4','0016g000007WEgnAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgSAAS','Deborah','Navarro','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','deborahmnavarro@cuvox.de','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','50.0','','0.0','0.0','false','false','false','false','false','50.0','2018-01-02','50.0','2018-01-02','50.0','2018-01-02','0.0','0.0','0.0','1.0','1.0','0.0','false','0016g000007WEgKAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBSEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgTAAS','Daphne','Bainter','false','','3024 Summit Park Avenue','Bloomfield Township','MI','','48302','false','false','','daphnecbainter@teleworm.us','Home','Personal','Home','false','','','','','50.0','50.0','2018','2018-01-02','','50.0','2018-01-02','0.0','','','','50.0','','','','1.0','0.0','50.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','50.0','0.0','0.0','0.0','0.0','','0.0','50.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgKAAW','a0e6g000000OuHTAA0','','','','','a0M6g000000NTBSEA4','0016g000007WEgCAAW');
INSERT INTO "Contact" VALUES('0036g000006JcgUAAS','Bryce','Whitley','false','','840 Mount Street','Bay City','MI','','48706','false','false','','brycemwhitley@cuvox.de','Mobile','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgLAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBTEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgVAAS','Chaz','Mayo','false','','840 Mount Street','Bay City','MI','','48706','false','false','','dannyvmayo@rhyta.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgLAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBTEA4','0016g000007WEgoAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgWAAS','Nelda','Davis','false','','1391 Diane Street','City Of Commerce','CA','','90040','false','false','','neldaddavis@cuvox.de','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgMAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBUEA4','0016g000007WEfbAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgXAAS','Jon','Mendoza','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','jon@mendoza.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','100.0','100.0','','0.0','0.0','false','false','false','false','false','100.0','2018-04-20','100.0','2018-04-20','100.0','2018-04-20','0.0','0.0','0.0','1.0','1.0','0.0','false','0016g000007WEgNAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBVEA4','0016g000007WEh4AAG');
INSERT INTO "Contact" VALUES('0036g000006JcgYAAS','Nilza','Mendoza','false','','55 Charleston','South San Francisco','CA','','94044','false','false','','nilza@mendoza.com','Home','Personal','Home','false','','','','','100.0','100.0','2018','2018-04-20','','100.0','2018-04-20','0.0','','','','100.0','','','','1.0','0.0','100.0','0.0','0.0','0.0','1.0','0.0','0.0','0.0','100.0','0.0','0.0','0.0','0.0','','0.0','100.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgNAAW','a0e6g000000OuHRAA0','','','','','a0M6g000000NTBVEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgZAAS','Zoe','Blum','false','','1 Cherry Street','Pleasant','NJ','','07777','false','false','','blum@smith.com','Home','Work','Home','false','','','carolines@orangetree.org','(922) 298-8282','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgOAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBWEA4','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006JcgaAAC','Baptiste','Subrahmanya','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgPAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBXEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgbAAC','Sieffre','Subrahmanya','false','','918 Duffield Crescent St','Arlington','WA','','57828','false','false','','sieffre@hitchens.com','Mobile','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgPAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBXEA4','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006JcgcAAC','Charlotte','Yudes','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgQAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBYEA4','');
INSERT INTO "Contact" VALUES('0036g000006JcgdAAC','Lara','Yudes','false','','8262 Phinney Ridge Rd','Georgetown','ME','','59586','false','false','','lara.yudes@hitchens.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgQAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBYEA4','0016g000007WEfVAAW');
INSERT INTO "Contact" VALUES('0036g000006JcgfAAC','Eric','Lauterborn','false','','37179 Bedford Shores St','Cole City','KS','','62223','false','false','','taneshaep@taconet.com','Home','Work','Home','false','','','lauterborn.e@colecity.gov','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgRAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBZEA4','0016g000007WEg9AAG');
INSERT INTO "Contact" VALUES('0036g000006JcggAAC','Kallistrate','Giannino','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','50.0','0.0','50.0','0.0','','0.0','0.0','false','false','false','false','false','50.0','2019-08-29','50.0','2019-08-29','50.0','2019-08-29','1.0','1.0','0.0','0.0','1.0','50.0','false','0016g000007WEgSAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBbEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcghAAC','Mattia','Aethelstan','false','','9156 Springfield Green Dr','Marion','VA','','64860','false','false','','rosebud@meetsaround.com','Work','Work','Home','false','','','','(202) 909-9999','50.0','50.0','2019','2019-08-29','','50.0','2019-08-29','0.0','','','','50.0','','','','1.0','0.0','0.0','50.0','50.0','0.0','0.0','1.0','1.0','0.0','50.0','0.0','0.0','0.0','0.0','','0.0','50.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgSAAW','a0e6g000000OuHTAA0','','','','','a0M6g000000NTBbEAO','0016g000007WEgsAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgiAAC','Cassius','Guerra','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgTAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBcEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgjAAC','Irma','O''Sullivan','false','','4578 Linda Ave','Riverside','WV','','65739','false','false','','irmaosull@sullyhouse.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgTAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBcEAO','0016g000007WEfcAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgkAAC','Natasha','Geier','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','babsgeiger@happydogs.net','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','25.0','0.0','25.0','0.0','','0.0','0.0','false','false','false','false','false','25.0','2019-08-31','25.0','2019-08-31','25.0','2019-08-31','1.0','1.0','0.0','0.0','1.0','25.0','false','0016g000007WEgUAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBdEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcglAAC','Marat','Geier','false','','2289 David Budd St','Lebanon','MD','','66618','false','false','','maratgeier@goregens.edu','Home','Personal','Home','false','','','','','25.0','25.0','2019','2019-08-31','','25.0','2019-08-31','0.0','','','','25.0','','','','1.0','0.0','0.0','25.0','25.0','0.0','0.0','1.0','1.0','0.0','25.0','0.0','0.0','0.0','0.0','','0.0','25.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgUAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBdEAO','0016g000007WEgtAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgmAAC','Ursula','Maddox','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgVAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBeEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgnAAC','Hildie','Schubert','false','','2357 Attlee Rd','Bristol','ME','','68376','false','false','','hildielovesfrank@schuberts.com','Work','Work','Home','false','','','hildiebakes@bakery.net','(202) 756-9723','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgVAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBeEAO','0016g000007WEguAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgoAAC','Georgie','Campaign','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','georgie@campaigns.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgWAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBfEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgpAAC','Grace','Campaign','false','','34 Shipham Close Rd','Truth or Consequences','NM','','55191','false','false','','tessa@campaign.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgWAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBfEAO','0016g000007WEgpAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgqAAC','Maia','Unnur','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','yudes@herbert.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgXAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBgEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgrAAC','Fionnghuala','Unnur','false','','24786 Handlebar Dr N','Madison','WI','','60465','false','false','','fionnur@greensburg.ky.gov','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgXAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBgEAO','0016g000007WEfbAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgsAAC','Diana','Thomas','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','dianarthomas@superrito.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgYAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBhEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgtAAC','Charlie','Gibbons','false','','726 Twin House Lane','Springfield','MO','','65802','false','false','','crystalhmudd@fleckens.hu','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgYAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBhEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcguAAC','Baron','Kovacevic','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgZAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBiEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgvAAC','Gretel','Kovacevic','false','','2323 Dent Way','Witchita','KS','','67497','false','false','','copacetic@cowabunga.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgZAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBiEAO','0016g000007WEgvAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgwAAC','Nageen','Zappa','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgaAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBjEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgxAAC','Jozef','Lukeson','false','','2391 Roborough Dr','Salem','LA','','69255','false','false','','jozef@hitchens.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgaAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBjEAO','0016g000007WEgwAAG');
INSERT INTO "Contact" VALUES('0036g000006JcgyAAC','Suhani','Tan','false','','2425 9th Ave','Madison','CA','','70134','false','false','','suhanitan@snailmail.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgbAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBkEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgzAAC','Kamil','Djuradj','false','','2425 9th Ave','Madison','CA','','70134','false','false','','kamild@snailmail.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgbAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBkEAO','0016g000007WEgxAAG');
INSERT INTO "Contact" VALUES('0036g000006Jch0AAC','Carol','Bi','false','','2459 44th St E','Reston','VA','','71013','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgcAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBlEAO','');
INSERT INTO "Contact" VALUES('0036g000006JcgeAAC','Concepcion de Jesus','Waterman','false','','37179 Bedford Shores St','Cole City','KS','','62223','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgRAAW','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBZEA4','');
INSERT INTO "Contact" VALUES('0036g000006Jch1AAC','Azarel','Conbon','false','','2459 44th St E','Reston','VA','','71013','false','false','','azarel@kanban.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgcAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBlEAO','0016g000007WEgyAAG');
INSERT INTO "Contact" VALUES('0036g000006Jch2AAC','Deepshika','Offermans','false','','2493 89th Way','Seattle','WA','','98103','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgdAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBmEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jch3AAC','Eleonora','Offermans','false','','2493 89th Way','Seattle','WA','','98103','false','false','','eleonora@scrumteam.net','Work','Work','Home','false','','','eleonora@scrumteam.net','(989) 777-4543','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgdAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBmEAO','0016g000007WEgzAAG');
INSERT INTO "Contact" VALUES('0036g000006Jch4AAC','Lucy','Sandeghin','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','deandre@blast.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgeAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBnEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jch5AAC','Helen','Castle','false','','2527 Monroe Rd','Dover','CO','','98982','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgeAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBnEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jch6AAC','Aldegund','Sokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgfAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBoEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jch7AAC','Solitude','Sokolov','false','','2561 Madison Dr','Ashland','KY','','99861','false','false','','soko@protons.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgfAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBoEAO','0016g000007WEh1AAG');
INSERT INTO "Contact" VALUES('0036g000006Jch8AAC','Alexi','Nazarian','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEggAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBpEAO','');
INSERT INTO "Contact" VALUES('0036g000006Jch9AAC','Gabrielle','Nazarian','false','','2595 Montauk Ave W','Dover','FL','','99948','false','false','','gabrielsphd@atoms.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEggAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBpEAO','0016g000007WEh2AAG');
INSERT INTO "Contact" VALUES('0036g000006JchAAAS','Mpho','McNeill','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEghAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBqEAO','');
INSERT INTO "Contact" VALUES('0036g000006JchBAAS','Vukasin','McNeill','false','','2629 Nebraska St','Dover','FL','','99948','false','false','','vukasinmcneill@narnia.com','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEghAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBqEAO','0016g000007WEh1AAG');
INSERT INTO "Contact" VALUES('0036g000006JchCAAS','Lois','Devine','false','','','','','','','false','false','','lois@devine.com','Home','Personal','','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgiAAG','','a0e6g000000OuHTAA0','','','','','0016g000007WEfWAAW');
INSERT INTO "Contact" VALUES('0036g000006JchDAAS','Louis','Devine','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgiAAG','','a0e6g000000OuHTAA0','','','','','0016g000007WEh5AAG');
INSERT INTO "Contact" VALUES('0036g000006JchEAAS','Sarah','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','350.0','0.0','350.0','0.0','','0.0','0.0','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','1.0','0.0','0.0','1.0','350.0','false','0016g000007WEgjAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBrEAO','');
INSERT INTO "Contact" VALUES('0036g000006JchFAAS','Lisa','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','','Home','Personal','Home','false','','','','','0.0','0.0','','','','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','350.0','0.0','350.0','0.0','','0.0','0.0','false','false','false','false','false','350.0','2019-12-10','350.0','2019-12-10','350.0','2019-12-10','1.0','1.0','0.0','0.0','1.0','350.0','false','0016g000007WEgjAAG','','a0e6g000000OuHTAA0','','','','a0M6g000000NTBrEAO','');
INSERT INTO "Contact" VALUES('0036g000006JchGAAS','Robert','Bullard','false','','129 W 81st','Buffalo','NY','','08982','false','false','','robert@myemail.com','Home','Personal','Home','false','','','ceo@myemail.com','(222) 222-2222','350.0','350.0','2019','2019-12-10','','350.0','2019-12-10','0.0','','','','350.0','','','','1.0','0.0','0.0','350.0','350.0','0.0','0.0','1.0','1.0','0.0','350.0','0.0','0.0','0.0','0.0','','0.0','350.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEgjAAG','a0e6g000000OuHRAA0','','','','','a0M6g000000NTBrEAO','0016g000007WEh3AAG');
INSERT INTO "Contact" VALUES('0036g000006JchHAAS','Daniel','Baker','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','0.0','','','1.0','0.0','','0.0','','','','','','','Household__c.Name;Household__c.Formal_Greeting__c;Household__c.Informal_Greeting__c','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','true','true','true','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEh6AAG','','a0e6g000000OuHTAA0','','','','','');
INSERT INTO "Contact" VALUES('0036g000006JchIAAS','Alex','Ventresca','false','','','','','','','false','false','','','Home','Personal','','false','','','','','0.0','0.0','','','0.0','0.0','','0.0','','','','','','','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','','0.0','0.0','false','false','false','false','false','0.0','','0.0','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','false','0016g000007WEh6AAG','','a0e6g000000OuHTAA0','','','','','');
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
INSERT INTO "Event" VALUES('00U6g000001dWEaEAM','2019-12-11','Conversation to explore creating an advisory committee of major donors.','2019-12-11T17:30:00.000Z','2019-12-11T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0036g000006JceeAAC');
INSERT INTO "Event" VALUES('00U6g000001dWEbEAM','2019-12-13','Conversation to explore creating an advisory committee of major donors.','2019-12-13T17:30:00.000Z','2019-12-13T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0036g000006JcegAAC');
INSERT INTO "Event" VALUES('00U6g000001dWEcEAM','2019-12-16','Conversation to explore creating an advisory committee of major donors.','2019-12-16T22:00:00.000Z','2019-12-16T23:00:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0036g000006JceiAAC');
INSERT INTO "Event" VALUES('00U6g000001dWEdEAM','2019-12-10','Conversation to explore creating an advisory committee of major donors.','2019-12-10T17:30:00.000Z','2019-12-10T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0036g000006JceiAAC');
INSERT INTO "Event" VALUES('00U6g000001dWEeEAM','2019-11-11','Conversation to explore creating an advisory committee of major donors.','2019-11-11T17:30:00.000Z','2019-11-11T18:30:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0036g000006JcekAAC');
INSERT INTO "Event" VALUES('00U6g000001dWEfEAM','2019-12-03','Conversation to explore creating an advisory committee of major donors.','2019-12-03T21:00:00.000Z','2019-12-03T22:00:00.000Z','Advisory Board Exploration Conversation','Rachel''s Coffee Shop','0036g000006JcemAAC');
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
INSERT INTO "Lead" VALUES('00Q6g000001B1mFEAS','Joshua','Kim','Self','false','false','false','false','true','Open - Not Contacted','Web','','','','','','','','');
INSERT INTO "Lead" VALUES('00Q6g000001B1mGEAS','Katie','Beaker','Self','false','false','false','false','true','Open - Not Contacted','','','','','','','','','');
INSERT INTO "Lead" VALUES('00Q6g000001B1mHEAS','Chloe','Jackson','Self','false','false','false','false','true','Open - Not Contacted','Web','','','','','','','','');
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
INSERT INTO "Opportunity" VALUES('0066g00000mEB4yAAG','Candace Evans Donation 1/10/2020','2020-01-10','false','0126g000000MyKnAAK','Posted','','','0036g000006JcekAAC','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfZAAW','','','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEBiDAAW','Candace Evans Donation (25) 12/1/2020','2020-12-01','false','0126g000000MyKnAAK','Pledged','','100.0','0036g000006JcekAAC','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','25.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3mAAG','Celia Boston Donation 1/22/2018','2018-01-22','false','0126g000000MyKnAAK','Posted','Donation','50.0','0032F00000UawOIQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgHAAW','7016g000000gmWUAAY','','','','','','','','0036g000006JcgMAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3nAAG','Daphne Bainter Donation 1/2/2018','2018-01-02','false','0126g000000MyKnAAK','Posted','Donation','50.0','0032F00000UawOLQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgKAAW','7016g000000gmWUAAY','','','','','','','','0036g000006JcgTAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3oAAG','Nilza Mendoza Donation 4/20/2018','2018-04-20','false','0126g000000MyKnAAK','Posted','Donation','100.0','0032F00000UawOOQAZ','false','','','','','All Opportunities','2018-04-20','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgNAAW','7016g000000gmWUAAY','','','','','','','','0036g000006JcgYAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3pAAG','Mattia Aethelstan Donation 8/29/2019','2019-08-29','false','0126g000000MyKnAAK','Posted','Donation','50.0','0032F00000UawOaQAJ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgSAAW','7016g000000gmWWAAY','','','','','','','','0036g000006JcghAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3qAAG','Marat Geier Donation 8/31/2019','2019-08-31','false','0126g000000MyKnAAK','Posted','Donation','25.0','0032F00000UawOcQAJ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgUAAW','7016g000000gmWWAAY','','','','','','','','0036g000006JcglAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3rAAG','Robert Bullard Donation 12/10/2019','2019-12-10','false','0126g000000MyKnAAK','Posted','','350.0','0032F00000UawOrQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgjAAG','7016g000000gmWUAAY','','','','','','','','0036g000006JchGAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3sAAG','Cloud Kicks Major Gift 11/4/2018','2018-11-04','false','0126g000000MyKqAAK','Posted','New Funding','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgkAAG','7016g000000gmWVAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3tAAG','Cloud Kicks Donation 11/4/2018','2018-11-04','false','0126g000000MyKnAAK','Posted','New Funding','1000.0','','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgkAAG','7016g000000gmWVAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3uAAG','Orange Company Donation 5/21/2018','2018-05-21','false','0126g000000MyKnAAK','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgnAAG','7016g000000gmWUAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3vAAG','Orange Company Donation 5/21/2018','2018-05-21','false','0126g000000MyKnAAK','Posted','Donation','100.0','','false','','','','','All Opportunities','2018-05-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgnAAG','7016g000000gmWUAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3wAAG','Acme Corporation Grant 6/30/2018','2018-06-30','false','0126g000000MyKoAAK','Posted','Grant','10000.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgoAAG','7016g000000gmWUAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3xAAG','Acme Corporation Grant 6/30/2018','2018-06-30','false','0126g000000MyKoAAK','Posted','Grant','12500.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgoAAG','7016g000000gmWVAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3yAAG','American Firefighters for Historic Books','2019-09-02','false','0126g000000MyKnAAK','Posted','Donation','75.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEguAAG','7016g000000gmWWAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2SAAW','Em Dominico Major Gift 5/7/2019','2019-05-07','false','0126g000000MyKqAAK','Posted','Donation','12500.0','0032F00000Ub9FzQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfIAAW','7016g000000gmWVAAY','','','','','','','','0036g000006JceeAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2TAAW','Em Dominika Donation 8/27/2019','2019-08-27','false','0126g000000MyKnAAK','Posted','Donation','10000.0','0032F00000UawOYQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfJAAW','7016g000000gmWWAAY','','','','','','','','0036g000006JcegAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2UAAW','Eugenius Trelawni Major Gift 5/8/2019','2019-05-08','false','0126g000000MyKqAAK','Posted','Donation','9375.0','0032F00000Ub9FsQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfYAAW','7016g000000gmWRAAY','','','','','','','','0036g000006JceiAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2VAAW','Candace Evans Donation 11/5/2018','2018-11-05','false','0126g000000MyKnAAK','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','Cloud Kicks','Received','','','','','','','','','0016g000007WEfZAAW','7016g000000gmWUAAY','','','','0016g000007WEgkAAG','0066g00001COGRsAAP','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2WAAW','Candace Evans Donation 11/4/2018','2018-11-04','false','0126g000000MyKnAAK','Posted','','50.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfZAAW','7016g000000gmWVAAY','','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2XAAW','Candace Evans Donation (1 of 12) 11/30/2018','2018-11-30','false','0126g000000MyKnAAK','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','1.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2YAAW','Candace Evans Donation (2 of 12) 2/28/2019','2019-02-28','false','0126g000000MyKnAAK','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','2.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2ZAAW','Candace Evans Donation (3 of 12) 5/31/2019','2019-05-31','false','0126g000000MyKnAAK','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-06-02','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','3.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2aAAG','Candace Evans Donation (4 of 12) 8/31/2019','2019-08-31','false','0126g000000MyKnAAK','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','4.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2bAAG','Candace Evans Donation (5 of 12) 11/30/2019','2019-11-30','false','0126g000000MyKnAAK','Posted','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-11-01','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','5.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2cAAG','Candace Evans Donation (6 of 12) 2/29/2020','2020-02-29','false','0126g000000MyKnAAK','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','6.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2dAAG','Candace Evans Donation (7 of 12) 5/31/2020','2020-05-31','false','0126g000000MyKnAAK','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','7.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2eAAG','Candace Evans Donation (8 of 12) 8/31/2020','2020-08-31','false','0126g000000MyKnAAK','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','8.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2fAAG','Candace Evans Donation (9 of 12) 11/30/2020','2020-11-30','false','0126g000000MyKnAAK','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','9.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2gAAG','Candace Evans Donation (10 of 12) 2/28/2021','2021-02-28','false','0126g000000MyKnAAK','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','10.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2hAAG','Candace Evans Donation (11 of 12) 5/31/2021','2021-05-31','false','0126g000000MyKnAAK','Pledged','','833.33','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','11.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2iAAG','Candace Evans Donation (12 of 12) 8/31/2021','2021-08-31','false','0126g000000MyKnAAK','Pledged','','833.37','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','12.0','','','0016g000007WEfZAAW','7016g000000gmWVAAY','a0A6g0000041b4pEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2jAAG','Candace Evans Donation (15) 2/1/2020','2020-02-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','15.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2kAAG','Candace Evans Donation (16) 3/1/2020','2020-03-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','16.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2lAAG','Candace Evans Donation (17) 4/1/2020','2020-04-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','17.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2mAAG','Candace Evans Donation (18) 5/1/2020','2020-05-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','18.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2nAAG','Candace Evans Donation (19) 6/1/2020','2020-06-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','19.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2oAAG','Candace Evans Donation (20) 7/1/2020','2020-07-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','20.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2pAAG','Candace Evans Donation (21) 8/1/2020','2020-08-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','21.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2qAAG','Candace Evans Donation (22) 9/1/2020','2020-09-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','22.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2rAAG','Candace Evans Donation (23) 10/1/2020','2020-10-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','23.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2sAAG','Candace Evans Donation (24) 11/1/2020','2020-11-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','24.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2tAAG','Candace Evans Donation (13) 12/1/2019','2019-12-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','13.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2wAAG','Candace Evans Donation (2) 1/1/2019','2019-01-01','false','0126g000000MyKnAAK','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','2.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2xAAG','Candace Evans Donation (3) 2/1/2019','2019-02-01','false','0126g000000MyKnAAK','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','3.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2yAAG','Candace Evans Donation (4) 3/1/2019','2019-03-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','4.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2zAAG','Candace Evans Donation (5) 4/1/2019','2019-04-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','5.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB30AAG','Candace Evans Donation (6) 5/1/2019','2019-05-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','6.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB31AAG','Candace Evans Donation (7) 6/1/2019','2019-06-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','7.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB32AAG','Candace Evans Donation (8) 7/1/2019','2019-07-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','8.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB33AAG','Candace Evans Donation (9) 8/1/2019','2019-08-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','9.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB34AAG','Candace Evans Donation (10) 9/1/2019','2019-09-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','10.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB35AAG','Candace Evans Donation (11) 10/1/2019','2019-10-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','11.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB36AAG','Candace Evans Donation (12) 11/1/2019','2019-11-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','12.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB37AAG','Eugenius Thulani Donation 8/28/2019','2019-08-28','false','0126g000000MyKnAAK','Posted','Donation','7500.0','0032F00000UawOZQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfaAAG','7016g000000gmWWAAY','','','','','','','','0036g000006JcemAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB38AAG','Music Foundation Major Gift 1/1/2019','2019-01-01','false','0126g000000MyKqAAK','Posted','Donation','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfbAAG','7016g000000gmWQAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB39AAG','Music Foundation Donation 1/1/2018','2018-01-01','false','0126g000000MyKnAAK','Posted','Donation','1000.0','','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfbAAG','7016g000000gmWUAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3AAAW','Blotts, Hargrove and Spludge Major Gift 5/10/2019','2019-05-10','false','0126g000000MyKqAAK','Posted','Donation','1250.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfcAAG','7016g000000gmWRAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3BAAW','Blotts, Hargrove and Spludge Donation 8/30/2019','2019-08-30','false','0126g000000MyKnAAK','Posted','Donation','1000.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfcAAG','7016g000000gmWWAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3CAAW','Mattias Chong Donation 1/1/2019','2019-01-01','false','0126g000000MyKnAAK','Posted','Donation','30.0','0032F00000Ub9FgQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfKAAW','7016g000000gmWQAAY','','','','','','','','0036g000006JcenAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3DAAW','Mattias Chong Donation 1/1/2019','2019-01-01','false','0126g000000MyKnAAK','Posted','Donation','75.0','0032F00000Ub9FhQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfKAAW','7016g000000gmWQAAY','','','','','','','','0036g000006JcesAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3EAAW','Mattias Chong Donation 1/1/2019','2019-01-01','false','0126g000000MyKnAAK','Posted','Donation','100.0','0032F00000Ub9FcQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfKAAW','7016g000000gmWWAAY','','','','','','','','0036g000006JcerAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3FAAW','Llew Loki Donation 9/23/2019','2019-09-23','false','0126g000000MyKnAAK','Posted','Donation','160.0','0032F00000Ub9FfQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfLAAW','7016g000000gmWWAAY','','','','','','','','0036g000006JceuAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3GAAW','Tasgall Loui Donation 5/1/2019','2019-05-01','false','0126g000000MyKnAAK','Posted','Donation','125.0','0032F00000Ub9FmQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfMAAW','7016g000000gmWRAAY','','','','','','','','0036g000006JcewAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3HAAW','Natalija George Donation 5/3/2019','2019-05-03','false','0126g000000MyKnAAK','Posted','Donation','300.0','0032F00000Ub9FoQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfNAAW','7016g000000gmWRAAY','','','','','','','','0036g000006JceyAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2uAAG','Candace Evans Donation (14) 1/1/2020','2020-01-01','false','0126g000000MyKnAAK','Pledged','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','14.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB2vAAG','Candace Evans Donation (1) 12/1/2018','2018-12-01','false','0126g000000MyKnAAK','Posted','','100.0','0032F00000UawOFQAZ','false','','','','','All Opportunities','2018-12-15','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','1.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3IAAW','Jeffry de la O Donation 5/5/2019','2019-05-05','false','0126g000000MyKnAAK','Posted','Donation','125.0','0032F00000Ub9FqQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfOAAW','7016g000000gmWRAAY','','','','','','','','0036g000006Jcf0AAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3JAAW','American Firefights for Freedom Donation 9/2/2019','2019-09-02','false','0126g000000MyKnAAK','Posted','Donation','100.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfPAAW','7016g000000gmWWAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3KAAW','Carl Kim Donation 1/1/2018','2018-01-01','false','0126g000000MyKnAAK','Posted','Donation','50.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfQAAW','7016g000000gmWUAAY','','','','','','','','0036g000006Jcf4AAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3LAAW','Carl Kim Donation 1/1/2019','2019-01-01','false','0126g000000MyKnAAK','Posted','Donation','25.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfQAAW','7016g000000gmWWAAY','','','','','','','','0036g000006Jcf4AAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3MAAW','Carl Kim Donation 1/1/2019','2019-01-01','false','0126g000000MyKnAAK','Posted','Donation','75.0','0032F00000UawOPQAZ','false','','','','','All Opportunities','2019-02-28','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfQAAW','7016g000000gmWWAAY','','','','','','','','0036g000006Jcf4AAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3NAAW','Tasgall Lewi Donation 8/20/2019','2019-08-20','false','0126g000000MyKnAAK','Posted','Donation','100.0','0032F00000UawORQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfRAAW','7016g000000gmWWAAY','','','','','','','','0036g000006Jcf6AAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3OAAW','Llew Oden Donation 9/23/2019','2019-09-23','false','0126g000000MyKnAAK','Posted','Donation','125.0','0032F00000UawOSQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfSAAW','7016g000000gmWWAAY','','','','','','','','0036g000006Jcf8AAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3PAAW','Natalija Shouta Donation 8/22/2019','2019-08-22','false','0126g000000MyKnAAK','Posted','Donation','225.0','0032F00000UawOUQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfTAAW','7016g000000gmWWAAY','','','','','','','','0036g000006JcfAAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3QAAW','Jeffry Primoz Donation 8/25/2019','2019-08-25','false','0126g000000MyKnAAK','Posted','Donation','100.0','0032F00000UawOWQAZ','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfUAAW','7016g000000gmWWAAY','','','','','','','','0036g000006JcfCAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3RAAW','Johnson''s General Stores Donation 5/4/2019','2019-05-04','false','0126g000000MyKnAAK','Posted','Donation','75.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfVAAW','7016g000000gmWRAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3SAAW','Johnson''s General Stores Donation 3/1/2019','2019-03-01','false','0126g000000MyKnAAK','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfVAAW','7016g000000gmWUAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3TAAW','Johnson''s General Stores Donation 3/1/2018','2018-03-01','false','0126g000000MyKnAAK','Posted','Donation','100.0','','false','','','','','All Opportunities','2018-03-10','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfVAAW','7016g000000gmWUAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3UAAW','Johnson''s General Stores Donation 8/23/2019','2019-08-23','false','0126g000000MyKnAAK','Posted','Donation','50.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfVAAW','7016g000000gmWWAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3VAAW','Orange Tree Imports Donation 5/2/2019','2019-05-02','false','0126g000000MyKnAAK','Posted','Donation','15.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfWAAW','7016g000000gmWRAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3WAAW','Orange Tree Imports Donation 8/2/2019','2019-08-02','false','0126g000000MyKnAAK','Posted','Donation','75.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfWAAW','7016g000000gmWWAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3XAAW','Orange Tree Imports Donation 8/2/2019','2019-08-02','false','0126g000000MyKnAAK','Posted','Donation','50.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfWAAW','7016g000000gmWWAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3YAAW','Orange Tree Imports Donation 8/22/2019','2019-08-22','false','0126g000000MyKnAAK','Posted','Donation','10.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfWAAW','7016g000000gmWWAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3ZAAW','Gnarl''s Bicycles Donation 5/6/2019','2019-05-06','false','0126g000000MyKnAAK','Posted','Donation','125.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfXAAW','7016g000000gmWRAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3aAAG','Gnarl''s Bicycles Donation 8/26/2019','2019-08-26','false','0126g000000MyKnAAK','Posted','Donation','100.0','','false','','','','','All Opportunities','2019-09-30','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEfXAAW','7016g000000gmWWAAY','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3bAAG','Nilza Hernandez Donation 4/20/2018','2018-04-20','false','0126g000000MyKnAAK','Posted','Donation','125.0','0032F00000Ub9FYQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfdAAG','7016g000000gmWUAAY','','','','','','','','0036g000006JcfEAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3cAAG','Beatrice Ivans Donation 11/5/2018','2018-11-05','false','0126g000000MyKnAAK','Posted','','125.0','0032F00000Ub9FaQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEffAAG','7016g000000gmWUAAY','','','','','','','','0036g000006JcfHAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3dAAG','Daphne Bainter Donation 1/2/2019','2019-01-02','false','0126g000000MyKnAAK','Posted','Donation','75.0','0032F00000Ub9FjQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfkAAG','7016g000000gmWQAAY','','','','','','','','0036g000006JcfRAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3eAAG','Big Orange Donation 1/22/2019','2019-01-22','false','0126g000000MyKnAAK','Posted','Donation','75.0','0032F00000Ub9FlQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEflAAG','7016g000000gmWQAAY','','','','','','','','0036g000006JcfTAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3fAAG','Mattia Aethelstan Donation 5/9/2019','2019-05-09','false','0126g000000MyKnAAK','Posted','Donation','75.0','0032F00000Ub9FtQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfpAAG','7016g000000gmWRAAY','','','','','','','','0036g000006JcfbAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3gAAG','Bennett Geiser-Bann Donation 5/11/2019','2019-05-11','false','0126g000000MyKnAAK','Posted','Donation','30.0','0032F00000Ub9FvQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfrAAG','7016g000000gmWRAAY','','','','','','','','0036g000006JcffAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3hAAG','Beatrice Ivans Donation 11/4/2018','2018-11-04','false','0126g000000MyKnAAK','Posted','','75.0','0032F00000Ub9FxQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEftAAG','7016g000000gmWVAAY','','','','','','','','0036g000006JcfiAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3iAAG','Roger Figueroo Major Gift 11/4/2020','2020-11-04','false','0126g000000MyKqAAK','Verbal Commitment','New Funding','375000.0','0032F00000Ub9G0QAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEfvAAG','7016g000000gmWVAAY','','','','','','','','0036g000006JcfmAAC');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3jAAG','Jose Figueroa Major Gift 11/4/2020','2020-11-04','false','0126g000000MyKqAAK','Verbal Commitment','New Funding','300000.0','0032F00000UawOGQAZ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgFAAW','7016g000000gmWVAAY','','','','','','','','0036g000006JcgIAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3kAAG','Big Red Donation 1/22/2018','2018-01-22','false','0126g000000MyKnAAK','Posted','Donation','50.0','0032F00000UawOHQAZ','false','','','','','All Opportunities','2018-01-31','Acknowledged','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgGAAW','7016g000000gmWUAAY','','','','','','','','0036g000006JcgKAAS');
INSERT INTO "Opportunity" VALUES('0066g00000mEB3lAAG','Celia-Rae Boston Donation 1/22/2019','2019-01-22','false','0126g000000MyKnAAK','Posted','Donation','75.0','0032F00000Ub9FkQAJ','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','Sent','','','','0016g000007WEgHAAW','7016g000000gmWQAAY','','','','','','','','0036g000006JcgNAAS');
INSERT INTO "Opportunity" VALUES('0066g00001COGRsAAP','Cloud Kicks Matching Donation 11/05/2018','2018-11-05','false','0126g000000MyKrAAK','Posted','','100.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgkAAG','','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00001COGSHAA5','Erica Douglass Donation 1/1/2019','2019-01-01','false','0126g000000MyKnAAK','Posted','','50.0','0036g000006JcgFAAS','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','Received','','','','','','','','','0016g000007WEgBAAW','','','','','0016g000007WEgkAAG','0066g00001COGSMAA5','','','0036g000006JcgFAAS');
INSERT INTO "Opportunity" VALUES('0066g00001COGTGAA5','Way for Good $1000 Donation 11/06/2018','2018-11-06','false','0126g000000MyKnAAK','Posted','','1000.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g00000Bs4xfAAB','','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00001COGSMAA5','Cloud Kicks Matching Donation 01/07/2019','2019-01-07','false','0126g000000MyKrAAK','Posted','','50.0','','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','','','','0016g000007WEgkAAG','','','','','','','','','');
INSERT INTO "Opportunity" VALUES('0066g00000p2SN0AAM','Candace Evans Donation (26) 1/1/2021','2021-01-01','false','0126g000000MyJpAAK','Pledged','','100.0','0036g000006JcekAAC','false','','','','','All Opportunities','','','','','false','','','','','','','','','','','false','','false','','','','','','','','26.0','','','0016g000007WEfZAAW','7016g000000gmWNAAY','a0A6g0000041b4qEAA','','','','','','','0036g000006JcekAAC');
CREATE TABLE "OpportunityContactRole" (
	sf_id VARCHAR(255) NOT NULL, 
	"Role" VARCHAR(255), 
	"IsPrimary" VARCHAR(255), 
	contact_id VARCHAR(255), 
	opportunity_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "OpportunityContactRole" VALUES('00K6g00000200k0EAA','Donor','true','0036g000006JcekAAC','0066g00000mEBiDAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g00000200k1EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEBiDAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g00000200k2EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEBiDAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzmLEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB4yAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzmMEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB4yAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzmNEAQ','Household Member','false','0036g000006JcejAAC','0066g00000mEB4yAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbXEAQ','Donor','true','0036g000006Jcf6AAC','0066g00000mEB3NAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbYEAQ','Donor','true','0036g000006Jcf8AAC','0066g00000mEB3OAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbZEAQ','Donor','true','0036g000006JcfAAAS','0066g00000mEB3PAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbaEAA','Donor','true','0036g000006JcfCAAS','0066g00000mEB3QAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbbEAA','Donor','true','0036g000006JcfEAAS','0066g00000mEB3bAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbcEAA','Donor','true','0036g000006JcfHAAS','0066g00000mEB3cAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbdEAA','Donor','true','0036g000006JcfRAAS','0066g00000mEB3dAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbeEAA','Donor','true','0036g000006JcfTAAS','0066g00000mEB3eAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbfEAA','Donor','true','0036g000006JcfbAAC','0066g00000mEB3fAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbgEAA','Donor','true','0036g000006JcffAAC','0066g00000mEB3gAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbhEAA','Donor','true','0036g000006JcfiAAC','0066g00000mEB3hAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbiEAA','Donor','true','0036g000006JcfmAAC','0066g00000mEB3iAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbjEAA','Donor','true','0036g000006JcgIAAS','0066g00000mEB3jAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbkEAA','Donor','true','0036g000006JcgKAAS','0066g00000mEB3kAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzblEAA','Donor','true','0036g000006JcgNAAS','0066g00000mEB3lAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbmEAA','Donor','true','0036g000006JcgMAAS','0066g00000mEB3mAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbnEAA','Donor','true','0036g000006JcgTAAS','0066g00000mEB3nAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzboEAA','Donor','true','0036g000006JcgYAAS','0066g00000mEB3oAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbpEAA','Donor','true','0036g000006JcghAAC','0066g00000mEB3pAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbqEAA','Donor','true','0036g000006JcglAAC','0066g00000mEB3qAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbrEAA','Donor','true','0036g000006JchGAAS','0066g00000mEB3rAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbsEAA','Solicitor','false','0036g000006JcgIAAS','0066g00000mEB3rAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbtEAA','Soft Credit','false','0036g000006JchEAAS','0066g00000mEB3rAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbuEAA','Soft Credit','false','0036g000006JchFAAS','0066g00000mEB3rAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbvEAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2VAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbwEAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2WAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbxEAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2XAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbyEAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2YAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbzEAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2ZAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc0EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2aAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc1EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2bAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbWEAQ','Donor','true','0036g000006Jcf4AAC','0066g00000mEB3MAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc2EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2cAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc3EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2dAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc4EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2eAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc5EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2fAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc6EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2gAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc7EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2hAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc8EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2iAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzc9EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2jAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcAEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2kAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcBEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2lAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcCEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2mAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcDEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2nAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcEEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2oAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcFEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2pAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcGEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2qAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcHEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2rAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcIEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2sAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcJEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2tAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcKEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2uAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcLEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2vAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcMEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2wAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcNEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2xAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcOEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2yAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcPEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB2zAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcQEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB30AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcREAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB31AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcSEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB32AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcTEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB33AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcUEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB34AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcVEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB35AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcWEAQ','Solicitor','false','0036g000006JchGAAS','0066g00000mEB36AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcXEAQ','Household Member','false','0036g000006JcedAAC','0066g00000mEB2SAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcYEAQ','Household Member','false','0036g000006JcefAAC','0066g00000mEB2TAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcZEAQ','Household Member','false','0036g000006JcehAAC','0066g00000mEB2UAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcaEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2VAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcbEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2WAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzccEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2XAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcdEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2YAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzceEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2ZAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcfEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2aAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcgEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2bAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzchEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2cAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzciEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2dAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcjEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2eAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzckEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2fAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzclEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2gAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcmEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2hAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcnEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2iAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcoEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2jAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcpEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2kAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcqEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2lAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcrEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2mAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcsEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2nAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzctEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2oAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcuEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2pAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcvEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2qAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcwEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2rAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcxEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2sAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzcyEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2tAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzczEAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2uAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd0EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2vAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd1EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2wAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd2EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2xAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd3EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2yAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd4EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB2zAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd5EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB30AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd6EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB31AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd7EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB32AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd8EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB33AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzd9EAA','Household Member','false','0036g000006JcejAAC','0066g00000mEB34AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdAEAQ','Household Member','false','0036g000006JcejAAC','0066g00000mEB35AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdBEAQ','Household Member','false','0036g000006JcejAAC','0066g00000mEB36AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdCEAQ','Household Member','false','0036g000006JcelAAC','0066g00000mEB37AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdDEAQ','Household Member','false','0036g000006JceoAAC','0066g00000mEB3CAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdEEAQ','Household Member','false','0036g000006JcepAAC','0066g00000mEB3CAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdFEAQ','Household Member','false','0036g000006JceqAAC','0066g00000mEB3CAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdGEAQ','Household Member','false','0036g000006JcerAAC','0066g00000mEB3CAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdHEAQ','Household Member','false','0036g000006JcesAAC','0066g00000mEB3CAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdIEAQ','Household Member','false','0036g000006JcenAAC','0066g00000mEB3DAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdJEAQ','Household Member','false','0036g000006JceoAAC','0066g00000mEB3DAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdKEAQ','Household Member','false','0036g000006JcepAAC','0066g00000mEB3DAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdLEAQ','Household Member','false','0036g000006JceqAAC','0066g00000mEB3DAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdMEAQ','Household Member','false','0036g000006JcerAAC','0066g00000mEB3DAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdNEAQ','Household Member','false','0036g000006JcenAAC','0066g00000mEB3EAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdOEAQ','Household Member','false','0036g000006JceoAAC','0066g00000mEB3EAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdPEAQ','Household Member','false','0036g000006JcepAAC','0066g00000mEB3EAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdQEAQ','Household Member','false','0036g000006JceqAAC','0066g00000mEB3EAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdREAQ','Household Member','false','0036g000006JcesAAC','0066g00000mEB3EAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdSEAQ','Household Member','false','0036g000006JcetAAC','0066g00000mEB3FAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdTEAQ','Household Member','false','0036g000006JcevAAC','0066g00000mEB3GAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdUEAQ','Household Member','false','0036g000006JcexAAC','0066g00000mEB3HAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdVEAQ','Household Member','false','0036g000006JcezAAC','0066g00000mEB3IAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdWEAQ','Household Member','false','0036g000006Jcf1AAC','0066g00000mEB3KAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdXEAQ','Household Member','false','0036g000006Jcf2AAC','0066g00000mEB3KAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdYEAQ','Household Member','false','0036g000006Jcf3AAC','0066g00000mEB3KAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdZEAQ','Household Member','false','0036g000006Jcf1AAC','0066g00000mEB3LAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdaEAA','Household Member','false','0036g000006Jcf2AAC','0066g00000mEB3LAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdbEAA','Household Member','false','0036g000006Jcf3AAC','0066g00000mEB3LAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdcEAA','Household Member','false','0036g000006Jcf1AAC','0066g00000mEB3MAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzddEAA','Household Member','false','0036g000006Jcf2AAC','0066g00000mEB3MAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdeEAA','Household Member','false','0036g000006Jcf3AAC','0066g00000mEB3MAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdfEAA','Household Member','false','0036g000006Jcf5AAC','0066g00000mEB3NAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdgEAA','Household Member','false','0036g000006Jcf7AAC','0066g00000mEB3OAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdhEAA','Household Member','false','0036g000006Jcf9AAC','0066g00000mEB3PAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdiEAA','Household Member','false','0036g000006JcfBAAS','0066g00000mEB3QAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdjEAA','Household Member','false','0036g000006JcfDAAS','0066g00000mEB3bAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdkEAA','Household Member','false','0036g000006JcfQAAS','0066g00000mEB3dAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdlEAA','Household Member','false','0036g000006JcfSAAS','0066g00000mEB3eAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdmEAA','Household Member','false','0036g000006JcfaAAC','0066g00000mEB3fAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdnEAA','Household Member','false','0036g000006JcfeAAC','0066g00000mEB3gAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdoEAA','Household Member','false','0036g000006JcflAAC','0066g00000mEB3iAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdpEAA','Household Member','false','0036g000006JcgHAAS','0066g00000mEB3jAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdqEAA','Household Member','false','0036g000006JcgJAAS','0066g00000mEB3kAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdrEAA','Household Member','false','0036g000006JcgLAAS','0066g00000mEB3lAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdsEAA','Household Member','false','0036g000006JcgMAAS','0066g00000mEB3lAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdtEAA','Household Member','false','0036g000006JcgLAAS','0066g00000mEB3mAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzduEAA','Household Member','false','0036g000006JcgNAAS','0066g00000mEB3mAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdvEAA','Household Member','false','0036g000006JcgSAAS','0066g00000mEB3nAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdwEAA','Household Member','false','0036g000006JcgXAAS','0066g00000mEB3oAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdxEAA','Household Member','false','0036g000006JcggAAC','0066g00000mEB3pAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdyEAA','Household Member','false','0036g000006JcgkAAC','0066g00000mEB3qAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzdzEAA','Donor','false','0036g000006JcgIAAS','0066g00000mEB3tAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zze0EAA','Solicitor','false','0036g000006JchGAAS','0066g00000mEB3tAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzahEAA','Donor','true','0036g000006JceeAAC','0066g00000mEB2SAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzaiEAA','Donor','true','0036g000006JcegAAC','0066g00000mEB2TAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzajEAA','Donor','true','0036g000006JceiAAC','0066g00000mEB2UAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzakEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2VAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzalEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2WAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzamEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2XAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzanEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2YAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzaoEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2ZAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzapEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2aAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzaqEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2bAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzarEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2cAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzasEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2dAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzatEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2eAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzauEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2fAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzavEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2gAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzawEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2hAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzaxEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2iAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzayEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2jAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzazEAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2kAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb0EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2lAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb1EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2mAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb2EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2nAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb3EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2oAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb4EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2pAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb5EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2qAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb6EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2rAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb7EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2sAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb8EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2tAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzb9EAA','Donor','true','0036g000006JcekAAC','0066g00000mEB2uAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbAEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB2vAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbBEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB2wAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbCEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB2xAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbDEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB2yAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbEEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB2zAAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbFEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB30AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbGEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB31AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbHEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB32AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbIEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB33AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbJEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB34AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbKEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB35AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbLEAQ','Donor','true','0036g000006JcekAAC','0066g00000mEB36AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbMEAQ','Donor','true','0036g000006JcemAAC','0066g00000mEB37AAG');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbNEAQ','Donor','true','0036g000006JcenAAC','0066g00000mEB3CAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbOEAQ','Donor','true','0036g000006JcesAAC','0066g00000mEB3DAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbPEAQ','Donor','true','0036g000006JcerAAC','0066g00000mEB3EAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbQEAQ','Donor','true','0036g000006JceuAAC','0066g00000mEB3FAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbREAQ','Donor','true','0036g000006JcewAAC','0066g00000mEB3GAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbSEAQ','Donor','true','0036g000006JceyAAC','0066g00000mEB3HAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbTEAQ','Donor','true','0036g000006Jcf0AAC','0066g00000mEB3IAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbUEAQ','Donor','true','0036g000006Jcf4AAC','0066g00000mEB3KAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000001zzbVEAQ','Donor','true','0036g000006Jcf4AAC','0066g00000mEB3LAAW');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002YcqYEAS','Matched Donor','false','0036g000006JcgFAAS','0066g00001COGSMAA5');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002YcqJEAS','Matched Donor','false','0036g000006JcekAAC','0066g00001COGRsAAP');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002EXv3EAG','Donor','true','0036g000006JcekAAC','0066g00000p2SN0AAM');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002EXv4EAG','Solicitor','false','0036g000006JchGAAS','0066g00000p2SN0AAM');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002EXv5EAG','Household Member','false','0036g000006JcejAAC','0066g00000p2SN0AAM');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002YcqOEAS','Donor','true','0036g000006JcgFAAS','0066g00001COGSHAA5');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002YcqnEAC','Soft Credit','false','0036g000006JcgFAAS','0066g00001COGTGAA5');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002YcqoEAC','Soft Credit','false','0036g000006JcekAAC','0066g00001COGTGAA5');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002YcqpEAC','Soft Credit','false','0036g000006JcgIAAS','0066g00001COGTGAA5');
INSERT INTO "OpportunityContactRole" VALUES('00K6g000002YcqsEAC','Soft Credit','false','0036g000006JcfHAAS','0066g00001COGTGAA5');
CREATE TABLE "Opportunity_rt_mapping" (
	record_type_id VARCHAR(18) NOT NULL, 
	developer_name VARCHAR(255), 
	PRIMARY KEY (record_type_id)
);
INSERT INTO "Opportunity_rt_mapping" VALUES('0126g000000MyKnAAK','Donation');
INSERT INTO "Opportunity_rt_mapping" VALUES('0126g000000MyKoAAK','Grant');
INSERT INTO "Opportunity_rt_mapping" VALUES('0126g000000MyKpAAK','InKindGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0126g000000MyKqAAK','MajorGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0126g000000MyKrAAK','MatchingGift');
INSERT INTO "Opportunity_rt_mapping" VALUES('0126g000000MyKsAAK','Membership');
INSERT INTO "Opportunity_rt_mapping" VALUES('0126g000000MyJpAAK','NPSP_Default');
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
INSERT INTO "npe01__OppPayment__c" VALUES('a026g00000654JdAAI','','','true','50.0','2019-01-07','','','false','','','0066g00001COGSMAA5');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g00000654W6AAI','','','true','1000.0','2018-11-06','','','false','','','0066g00001COGTGAA5');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g00000654F1AAI','','','true','100.0','2020-02-07','','','false','','','0066g00001COGRsAAP');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g00000654JYAAY','','','true','50.0','2019-01-01','','','false','','','0066g00001COGSHAA5');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FkPpAAK','','','false','100.0','','','2020-12-01','false','','','0066g00000mEBiDAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhDuAAK','6226','','true','12500.0','2019-05-07','Check','','false','','','0066g00000mEB2SAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhDvAAK','6226','','true','10000.0','2019-08-27','Check','','false','','','0066g00000mEB2TAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhDwAAK','','','true','125.0','2018-04-20','Credit','','false','','','0066g00000mEB3bAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhDxAAK','','','true','125.0','2018-11-05','Credit','','false','','','0066g00000mEB3cAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhDyAAK','342','','true','75.0','2019-01-02','Check','','false','','','0066g00000mEB3dAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhDzAAK','888','','true','75.0','2019-01-22','Check','','false','','','0066g00000mEB3eAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE0AAK','39566','','true','75.0','2019-05-09','Check','','false','','','0066g00000mEB3fAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE1AAK','','','true','30.0','2019-05-11','Credit','','false','','','0066g00000mEB3gAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE2AAK','','','true','75.0','2018-11-04','Credit','','false','','','0066g00000mEB3hAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE3AAK','','','false','375000.0','','Credit','2020-11-04','false','','','0066g00000mEB3iAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE4AAK','','','true','50000.0','2018-11-04','Credit Card','2018-11-04','false','','','0066g00000mEB3jAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE5AAK','','','false','50000.0','','Credit Card','2019-05-04','true','','','0066g00000mEB3jAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE6AAK','','','true','50000.0','2019-11-05','Credit Card','2019-11-04','false','','','0066g00000mEB3jAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE7AAK','','','false','150000.0','2019-12-04','','','true','','','0066g00000mEB3jAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE8AAK','888','','true','50.0','2018-01-22','Check','','false','','','0066g00000mEB3kAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhE9AAK','888','','true','75.0','2019-01-22','Check','','false','','','0066g00000mEB3lAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEAAA0','888','','true','50.0','2018-01-22','Check','','false','','','0066g00000mEB3mAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEBAA0','342','','true','50.0','2018-01-02','Check','','false','','','0066g00000mEB3nAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhECAA0','','','true','100.0','2018-04-20','Credit','','false','','','0066g00000mEB3oAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEDAA0','39566','','true','50.0','2019-08-29','Check','','false','','','0066g00000mEB3pAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEEAA0','','','true','25.0','2019-08-31','Credit','','false','','','0066g00000mEB3qAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEFAA0','','','true','350.0','2019-12-10','','','false','','','0066g00000mEB3rAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEGAA0','1001','','true','1250.0','2018-11-04','Check','','false','','','0066g00000mEB3sAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEHAA0','1001','','true','1000.0','2018-11-04','Check','','false','','','0066g00000mEB3tAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEIAA0','','','true','125.0','2018-05-21','Credit','','false','','','0066g00000mEB3uAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEJAA0','','','true','100.0','2018-05-21','Credit','','false','','','0066g00000mEB3vAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEKAA0','966','','true','10000.0','2018-06-30','Check','','false','','','0066g00000mEB3wAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhELAA0','966','','true','12500.0','2018-06-30','Check','','false','','','0066g00000mEB3xAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEMAA0','','','true','75.0','2019-09-02','Cash','','false','','','0066g00000mEB3yAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhENAA0','2294','','true','30.0','2019-01-01','Check','','false','','','0066g00000mEB3CAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEOAA0','39566','','true','75.0','2019-01-01','Check','','false','','','0066g00000mEB3DAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEPAA0','123','','true','100.0','2019-01-01','Check','','false','','','0066g00000mEB3EAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEQAA0','888','','true','160.0','2019-09-23','Check','','false','','','0066g00000mEB3FAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhERAA0','','','true','125.0','2019-05-01','Cash','','false','','','0066g00000mEB3GAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhESAA0','','','true','300.0','2019-05-03','Credit','','false','','','0066g00000mEB3HAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhETAA0','','','true','125.0','2019-05-05','Crecit','','false','','','0066g00000mEB3IAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEUAA0','','','true','100.0','2019-09-02','Cash','','false','','','0066g00000mEB3JAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEVAA0','39566','','true','50.0','2018-01-01','Check','','false','','','0066g00000mEB3KAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEWAA0','2294','','true','25.0','2019-01-01','Check','','false','','','0066g00000mEB3LAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEXAA0','123','','true','75.0','2019-01-01','Check','','false','','','0066g00000mEB3MAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEYAA0','','','true','100.0','2019-08-20','Cash','','false','','','0066g00000mEB3NAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEZAA0','888','','true','125.0','2019-09-23','Check','','false','','','0066g00000mEB3OAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEaAAK','','','true','225.0','2019-08-22','Credit','','false','','','0066g00000mEB3PAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEbAAK','','','true','100.0','2019-08-25','Crecit','','false','','','0066g00000mEB3QAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEcAAK','','','true','75.0','2019-05-04','Credit','','false','','','0066g00000mEB3RAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEdAAK','225','','true','125.0','2019-03-01','Check','','false','','','0066g00000mEB3SAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEeAAK','225','','true','100.0','2018-03-01','Check','','false','','','0066g00000mEB3TAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEfAAK','','','true','50.0','2019-08-23','Credit','','false','','','0066g00000mEB3UAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEgAAK','888','','true','15.0','2019-05-02','Check','','false','','','0066g00000mEB3VAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEhAAK','','','true','75.0','2019-08-02','Cash','','false','','','0066g00000mEB3WAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEiAAK','','','true','50.0','2019-08-02','Cash','','false','','','0066g00000mEB3XAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEjAAK','888','','true','10.0','2019-08-22','Check','','false','','','0066g00000mEB3YAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEkAAK','342','','true','125.0','2019-05-06','Check','','false','','','0066g00000mEB3ZAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhElAAK','342','','true','100.0','2019-08-26','Check','','false','','','0066g00000mEB3aAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEmAAK','2294','','true','9375.0','2019-05-08','Check','','false','','','0066g00000mEB2UAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEnAAK','','','true','100.0','2018-11-05','Credit','','false','','','0066g00000mEB2VAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEoAAK','','','true','50.0','2018-11-04','Credit','','false','','','0066g00000mEB2WAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEpAAK','','','true','833.33','2018-11-30','','2018-11-30','false','','','0066g00000mEB2XAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEqAAK','','','true','833.33','2019-02-28','','2019-02-28','false','','','0066g00000mEB2YAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhErAAK','','','true','833.33','2019-05-31','','2019-05-31','false','','','0066g00000mEB2ZAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEsAAK','','','true','833.33','2019-08-31','','2019-08-31','false','','','0066g00000mEB2aAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEtAAK','','','true','833.33','2019-11-30','','2019-11-30','false','','','0066g00000mEB2bAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEuAAK','','','false','833.33','','','2020-02-29','false','','','0066g00000mEB2cAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEvAAK','','','false','833.33','','','2020-05-31','false','','','0066g00000mEB2dAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEwAAK','','','false','833.33','','','2020-08-31','false','','','0066g00000mEB2eAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhExAAK','','','false','833.33','','','2020-11-30','false','','','0066g00000mEB2fAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEyAAK','','','false','833.33','','','2021-02-28','false','','','0066g00000mEB2gAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhEzAAK','','','false','833.33','','','2021-05-31','false','','','0066g00000mEB2hAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF0AAK','','','false','833.37','','','2021-08-31','false','','','0066g00000mEB2iAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF1AAK','','','false','100.0','','','2020-02-01','false','','','0066g00000mEB2jAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF2AAK','','','false','100.0','','','2020-03-01','false','','','0066g00000mEB2kAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF3AAK','','','false','100.0','','','2020-04-01','false','','','0066g00000mEB2lAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF4AAK','','','false','100.0','','','2020-05-01','false','','','0066g00000mEB2mAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF5AAK','','','false','100.0','','','2020-06-01','false','','','0066g00000mEB2nAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF6AAK','','','false','100.0','','','2020-07-01','false','','','0066g00000mEB2oAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF7AAK','','','false','100.0','','','2020-08-01','false','','','0066g00000mEB2pAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF8AAK','','','false','100.0','','','2020-09-01','false','','','0066g00000mEB2qAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhF9AAK','','','false','100.0','','','2020-10-01','false','','','0066g00000mEB2rAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFAAA0','','','false','100.0','','','2020-11-01','false','','','0066g00000mEB2sAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFBAA0','','','false','100.0','','','2019-12-01','false','','','0066g00000mEB2tAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFCAA0','','','false','100.0','','','2020-01-01','false','','','0066g00000mEB2uAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFDAA0','','','true','100.0','2018-12-01','','2018-12-01','false','','','0066g00000mEB2vAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFEAA0','','','true','100.0','2019-01-01','','2019-01-01','false','','','0066g00000mEB2wAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFFAA0','','','true','100.0','2019-02-01','','2019-02-01','false','','','0066g00000mEB2xAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFGAA0','','','false','100.0','','','2019-03-01','false','','','0066g00000mEB2yAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFHAA0','','','false','100.0','','','2019-04-01','false','','','0066g00000mEB2zAAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFIAA0','','','false','100.0','','','2019-05-01','false','','','0066g00000mEB30AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFJAA0','','','false','100.0','','','2019-06-01','false','','','0066g00000mEB31AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFKAA0','','','false','100.0','','','2019-07-01','false','','','0066g00000mEB32AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFLAA0','','','false','100.0','','','2019-08-01','false','','','0066g00000mEB33AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFMAA0','','','false','100.0','','','2019-09-01','false','','','0066g00000mEB34AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFNAA0','','','false','100.0','','','2019-10-01','false','','','0066g00000mEB35AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFOAA0','','','false','100.0','','','2019-11-01','false','','','0066g00000mEB36AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFPAA0','2294','','true','7500.0','2019-08-28','Check','','false','','','0066g00000mEB37AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFQAA0','6226','','true','1250.0','2019-01-01','Check','','false','','','0066g00000mEB38AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFRAA0','6226','','true','1000.0','2018-01-01','Check','','false','','','0066g00000mEB39AAG');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFSAA0','123','','true','1250.0','2019-05-10','Check','','false','','','0066g00000mEB3AAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g000004FhFTAA0','123','','true','1000.0','2019-08-30','Check','','false','','','0066g00000mEB3BAAW');
INSERT INTO "npe01__OppPayment__c" VALUES('a026g00000640JQAAY','','','false','100.0','','','2021-01-01','false','','','0066g00000p2SN0AAM');
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
INSERT INTO "npe03__Recurring_Donation__c" VALUES('a0A6g0000041b4pEAA','NMH Transitional Housing Capital Campaign - Evans and Wong Household','10000.0','2018-11-05','Quarterly','12.0','2019-11-30','2020-02-29','None','4166.65','Divide By','5.0','true','30','0036g000006JcekAAC','','7016g000000gmWVAAY');
INSERT INTO "npe03__Recurring_Donation__c" VALUES('a0A6g0000041b4qEAA','Give a Life - Evans and Wong Household','100.0','2018-11-01','Monthly','26.0','2019-02-01','2019-03-01','Open','300.0','Multiply By','3.0','false','1','0036g000006JcekAAC','','7016g000000gmWNAAY');
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
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXGEA4','','true','Current','Friend','','0036g000006JcgIAAS','a0G6g000000JNXQEA4','0036g000006JchGAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXHEA4','','true','Current','Friend','','0036g000006JcgKAAS','a0G6g000000JNXMEA4','0036g000006JchFAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXIEA4','','true','Current','Leader','','0036g000006JcgZAAS','a0G6g000000JNXJEA4','0036g000006JcgtAAC');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXJEA4','','false','Current','Member','','0036g000006JcgtAAC','a0G6g000000JNXIEA4','0036g000006JcgZAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXKEA4','','true','Current','Friend','','0036g000006JcgwAAC','a0G6g000000JNXNEA4','0036g000006JchFAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXLEA4','','true','Current','Father','','0036g000006JchEAAS','a0G6g000000JNXREA4','0036g000006JchGAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXMEA4','','false','Current','Friend','','0036g000006JchFAAS','a0G6g000000JNXHEA4','0036g000006JcgKAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXNEA4','','false','Current','Friend','','0036g000006JchFAAS','a0G6g000000JNXKEA4','0036g000006JcgwAAC');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXOEA4','','true','Current','Husband','','0036g000006JchFAAS','a0G6g000000JNXSEA4','0036g000006JchGAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXPEA4','','false','Current','Mentee','','0036g000006JchFAAS','a0G6g000000JNXVEA4','0036g000006JchIAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXQEA4','','false','Current','Friend','Solicitor','0036g000006JchGAAS','a0G6g000000JNXGEA4','0036g000006JcgIAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXREA4','','false','Current','Daughter','Soft Credit','0036g000006JchGAAS','a0G6g000000JNXLEA4','0036g000006JchEAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXSEA4','','false','Current','Wife','Soft Credit','0036g000006JchGAAS','a0G6g000000JNXOEA4','0036g000006JchFAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXTEA4','Candace and Robert went to the same University.','false','Current','Friend','','0036g000006JchGAAS','a0G6g000000JNXXEA4','0036g000006JcekAAC');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXUEA4','','true','Current','Parent','','0036g000006JchHAAS','a0G6g000000JNXWEA4','0036g000006JchIAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXVEA4','','true','Current','Mentor','','0036g000006JchIAAS','a0G6g000000JNXPEA4','0036g000006JchFAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXWEA4','','false','Current','Son','','0036g000006JchIAAS','a0G6g000000JNXUEA4','0036g000006JchHAAS');
INSERT INTO "npe4__Relationship__c" VALUES('a0G6g000000JNXXEA4','Candace and Robert went to the same University.','true','Current','Friend','Solicitor','0036g000006JcekAAC','a0G6g000000JNXTEA4','0036g000006JchGAAS');
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
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvngEAA','','','true','','2019-12-05','Current','','0036g000006JceeAAC','0016g000007WEgqAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnhEAA','','','true','','2019-12-04','Current','','0036g000006JcegAAC','0016g000007WEgqAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvniEAA','','','true','','2019-12-05','Current','','0036g000006JcfDAAS','0016g000007WEh4AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnjEAA','','','true','','2019-12-05','Current','','0036g000006JcfGAAS','0016g000007WEgnAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnkEAA','','','true','','2019-12-05','Current','','0036g000006JcfHAAS','0016g000007WEgkAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnlEAA','','','true','','2019-12-05','Current','','0036g000006JcfJAAS','0016g000007WEfVAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnmEAA','','','true','','2019-12-05','Current','','0036g000006JcfIAAS','0016g000007WEfbAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnnEAA','','','true','','2019-12-05','Current','','0036g000006JcfLAAS','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnoEAA','','','true','','2019-12-05','Current','','0036g000006JcfNAAS','0016g000007WEfPAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnpEAA','','','true','','2019-12-05','Current','','0036g000006JcfPAAS','0016g000007WEfbAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnqEAA','','','true','','2019-12-05','Current','','0036g000006JcfRAAS','0016g000007WEfVAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnrEAA','','','true','','2019-12-05','Current','','0036g000006JcfTAAS','0016g000007WEglAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnsEAA','','','true','','2019-12-05','Current','','0036g000006JcfVAAS','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvntEAA','','','true','','2019-12-05','Current','','0036g000006JcfXAAS','0016g000007WEfVAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnuEAA','','','true','','2019-12-05','Current','','0036g000006JcfZAAS','0016g000007WEfXAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnvEAA','','','true','','2019-12-05','Current','','0036g000006JcfbAAC','0016g000007WEgsAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnwEAA','','','true','','2019-12-05','Current','','0036g000006JcfdAAC','0016g000007WEfcAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnxEAA','','','true','','2019-12-05','Current','','0036g000006JcffAAC','0016g000007WEgtAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnyEAA','','','true','','2019-12-05','Current','','0036g000006JcfhAAC','0016g000007WEgoAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvnzEAA','','','true','','2019-12-05','Current','','0036g000006JcfiAAC','0016g000007WEgkAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo0EAA','','','true','','2019-12-05','Current','','0036g000006JcfkAAC','0016g000007WEgkAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo1EAA','','','true','','2019-12-05','Current','','0036g000006JcfmAAC','0016g000007WEgkAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo2EAA','','','true','','2019-12-05','Current','','0036g000006JcfoAAC','0016g000007WEgpAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo3EAA','','','true','','2019-12-05','Current','','0036g000006JcfqAAC','0016g000007WEh0AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo4EAA','','','true','','2019-12-05','Current','','0036g000006JcfsAAC','0016g000007WEgyAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo5EAA','','','true','','2019-12-05','Current','','0036g000006JcfuAAC','0016g000007WEh5AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo6EAA','','','true','','2019-12-05','Current','','0036g000006JcftAAC','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo7EAA','','','true','','2019-12-05','Current','','0036g000006JcfwAAC','0016g000007WEgxAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo8EAA','','','true','','2019-12-05','Current','','0036g000006JcfyAAC','0016g000007WEgvAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvo9EAA','','','true','','2019-12-05','Current','','0036g000006Jcg0AAC','0016g000007WEgwAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoAEAQ','','','true','','2019-12-05','Current','','0036g000006Jcg2AAC','0016g000007WEh1AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoBEAQ','','','true','','2019-12-05','Current','','0036g000006Jcg4AAC','0016g000007WEh2AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoCEAQ','','','true','','2019-12-05','Current','','0036g000006Jcg6AAC','0016g000007WEgzAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoDEAQ','','','true','','2019-12-05','Current','','0036g000006Jcg8AAC','0016g000007WEh1AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoEEAQ','','','true','','2019-12-05','Current','','0036g000006JcgCAAS','0016g000007WEfbAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoFEAQ','','','true','','2019-12-05','Current','','0036g000006JcgEAAS','0016g000007WEh7AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoGEAQ','','','true','Employee','2016-04-07','Current','','0036g000006JcgFAAS','0016g000007WEgkAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoHEAQ','','','true','CEO','2020-01-15','Current','','0036g000006JcgGAAS','0016g000007WEgEAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoIEAQ','','','true','','2019-12-04','Current','','0036g000006JcgIAAS','0016g000007WEgkAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoJEAQ','','','true','','2019-12-04','Current','','0036g000006JcgKAAS','0016g000007WEglAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoKEAQ','','','true','','2019-12-04','Current','','0036g000006JcgMAAS','0016g000007WEgmAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoLEAQ','','','true','','2019-12-05','Current','','0036g000006JcgNAAS','0016g000007WEgmAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoMEAQ','','','true','','2019-12-04','Current','','0036g000006JcgPAAS','0016g000007WEfVAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoNEAQ','','','true','','2019-12-04','Current','','0036g000006JcgOAAS','0016g000007WEfbAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoOEAQ','','','true','','2019-12-04','Current','','0036g000006JcgRAAS','0016g000007WEgnAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoPEAQ','','2019-12-05','false','','2019-12-04','Former','','0036g000006JcgTAAS','0016g000007WEfVAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoQEAQ','','','true','','2019-12-05','Current','','0036g000006JcgTAAS','0016g000007WEgCAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoREAQ','','','true','','2019-12-04','Current','','0036g000006JcgVAAS','0016g000007WEgoAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoSEAQ','','','true','','2019-12-04','Current','','0036g000006JcgWAAS','0016g000007WEfbAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoTEAQ','','','true','','2019-12-04','Current','','0036g000006JcgXAAS','0016g000007WEh4AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoUEAQ','','','true','','2019-12-04','Current','','0036g000006JcgZAAS','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoVEAQ','','','true','','2019-12-04','Current','','0036g000006JcgbAAC','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoWEAQ','','','true','','2019-12-04','Current','','0036g000006JcgdAAC','0016g000007WEfVAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoXEAQ','','2019-12-05','false','','2019-12-04','Former','','0036g000006JcgfAAC','0016g000007WEfXAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoYEAQ','','','true','Legislative Aide','2019-12-05','Current','','0036g000006JcgfAAC','0016g000007WEg9AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoZEAQ','','','true','','2019-12-04','Current','','0036g000006JcghAAC','0016g000007WEgsAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoaEAA','','','true','','2019-12-04','Current','','0036g000006JcgjAAC','0016g000007WEfcAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvobEAA','','','true','','2019-12-04','Current','','0036g000006JcglAAC','0016g000007WEgtAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvocEAA','','','true','','2019-12-04','Current','','0036g000006JcgnAAC','0016g000007WEguAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvodEAA','','','true','','2019-12-04','Current','','0036g000006JcgpAAC','0016g000007WEgpAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoeEAA','','','true','','2019-12-04','Current','','0036g000006JcgrAAC','0016g000007WEfbAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvofEAA','','','true','','2019-12-04','Current','','0036g000006JcgvAAC','0016g000007WEgvAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvogEAA','','','true','','2019-12-04','Current','','0036g000006JcgxAAC','0016g000007WEgwAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvohEAA','','','true','','2019-12-04','Current','','0036g000006JcgzAAC','0016g000007WEgxAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoiEAA','','','true','','2019-12-04','Current','','0036g000006Jch1AAC','0016g000007WEgyAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvojEAA','','','true','','2019-12-04','Current','','0036g000006Jch3AAC','0016g000007WEgzAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvokEAA','','2019-12-05','false','','2019-12-04','Former','','0036g000006Jch4AAC','0016g000007WEh0AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvolEAA','','','true','','2019-12-04','Current','','0036g000006Jch7AAC','0016g000007WEh1AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvomEAA','','','true','','2019-12-04','Current','','0036g000006Jch9AAC','0016g000007WEh2AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvonEAA','','','true','','2019-12-04','Current','','0036g000006JchBAAS','0016g000007WEh1AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvooEAA','','','true','','2019-12-04','Current','','0036g000006JchDAAS','0016g000007WEh5AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvopEAA','','','true','','2019-12-04','Current','','0036g000006JchCAAS','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoqEAA','','','true','','2019-12-04','Current','','0036g000006JchGAAS','0016g000007WEh3AAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvotEAA','','','true','','2019-12-05','Current','','0036g000006JceyAAC','0016g000007WEgpAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvouEAA','','','true','','2019-12-05','Current','','0036g000006Jcf0AAC','0016g000007WEglAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvovEAA','','','true','','2019-12-04','Current','','0036g000006Jcf6AAC','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvowEAA','','','true','','2019-12-04','Current','','0036g000006Jcf8AAC','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoxEAA','','','true','','2019-12-04','Current','','0036g000006JcfAAAS','0016g000007WEgpAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvoyEAA','','','true','','2019-12-04','Current','','0036g000006JcfCAAS','0016g000007WEglAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvozEAA','','','true','','2019-12-05','Current','','0036g000006JceiAAC','0016g000007WEgrAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvp0EAA','','','true','','2019-12-04','Current','','0036g000006JcekAAC','0016g000007WEgkAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvp1EAA','Graduate','','false','Alumni','1990-09-01','Former','','0036g000006JcekAAC','0016g000007WEgsAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvp2EAA','','','true','','2019-12-04','Current','','0036g000006JcemAAC','0016g000007WEgrAAG');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvorEAA','','','true','','2019-12-05','Current','','0036g000006JceuAAC','0016g000007WEfWAAW');
INSERT INTO "npe5__Affiliation__c" VALUES('a0H6g000001kvosEAA','','','true','','2019-12-05','Current','','0036g000006JcewAAC','0016g000007WEfWAAW');
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
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBHEA4','','Home','','false','','','true','','2020-01-10','Ashland','','99861','KY','','2561 Madison Dr','','','','','','','','','false','0016g000007WEg6AAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBIEA4','','Home','','false','','','true','','2020-01-10','Springfield','','65802','MO','','726 Twin House Lane','','','','','','','','','false','0016g000007WEg7AAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBJEA4','','Home','','false','','','true','','2020-01-10','Madison','','60465','WI','','24786 Handlebar Dr N','','','','','','','','','false','0016g000007WEg8AAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBKEA4','','Home','','false','','','true','','2020-01-10','Port Townsend','','98368','WA','','762 Smiley','','','','','','','','','false','0016g000007WEgAAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBLEA4','','Home','','false','','','true','','2020-01-10','San Francisco','USA','94105','CA','','One Market Street','','','','','','','','','false','0016g000007WEgDAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBMEA4','','Home','','false','','','true','','2020-01-10','San Francisco','','94121','CA','','25 10th Ave.','','','','','','','','','false','0016g000007WEgFAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBNEA4','','Home','','false','','','true','','2020-01-10','Arlington','','02128','MA','','4270 4th Court','','','','','','','','','false','0016g000007WEgGAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBOEA4','','Home','','false','','','true','','2020-01-10','Boston','','2130','MA','','25 Boyston','','','','','','','','','false','0016g000007WEgHAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBPEA4','','Home','','false','','','false','2019-12-05','2019-12-04','Boston','','02130','MA','','25 Boyston','','','','','','','','','false','0016g000007WEgHAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBQEA4','','Home','','false','','','true','','2020-01-10','Boston','','02199','MA','','1172 Boylston St.','','','','','','','','','false','0016g000007WEgIAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBREA4','','Home','','false','','','true','','2020-01-10','Brooklyn','','02317','NY','','10 Ocean Parkway','','','','','','','','','false','0016g000007WEgJAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBSEA4','','Home','','false','','','true','','2020-01-10','Bloomfield Township','','48302','MI','','3024 Summit Park Avenue','','','','','','','','','false','0016g000007WEgKAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBTEA4','','Home','','false','','','true','','2020-01-10','Bay City','','48706','MI','','840 Mount Street','','','','','','','','','false','0016g000007WEgLAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBUEA4','','Home','','false','','','true','','2020-01-10','City Of Commerce','','90040','CA','','1391 Diane Street','','','','','','','','','false','0016g000007WEgMAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBVEA4','','Home','','false','','','true','','2020-01-10','South San Francisco','','94044','CA','','55 Charleston','','','','','','','','','false','0016g000007WEgNAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBWEA4','','Home','','false','','','true','','2020-01-10','Pleasant','','07777','NJ','','1 Cherry Street','','','','','','','','','false','0016g000007WEgOAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBXEA4','','Home','','false','','','true','','2020-01-10','Arlington','','57828','WA','','918 Duffield Crescent St','','','','','','','','','false','0016g000007WEgPAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBYEA4','','Home','','false','','','true','','2020-01-10','Georgetown','','59586','ME','','8262 Phinney Ridge Rd','','','','','','','','','false','0016g000007WEgQAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBZEA4','','Home','','false','','','true','','2020-01-10','Cole City','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0016g000007WEgRAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBaEAO','','Home','','false','','','false','2019-12-05','2019-12-04','Fairfield','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0016g000007WEgRAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBbEAO','','Home','','false','','','true','','2020-01-10','Marion','','64860','VA','','9156 Springfield Green Dr','','','','','','','','','false','0016g000007WEgSAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBcEAO','','Home','','false','','','true','','2020-01-10','Riverside','','65739','WV','','4578 Linda Ave','','','','','','','','','false','0016g000007WEgTAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBdEAO','','Home','','false','','','true','','2020-01-10','Lebanon','','66618','MD','','2289 David Budd St','','','','','','','','','false','0016g000007WEgUAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBeEAO','','Home','','false','','','true','','2020-01-10','Bristol','','68376','ME','','2357 Attlee Rd','','','','','','','','','false','0016g000007WEgVAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBfEAO','','Home','','false','','','true','','2020-01-10','Truth or Consequences','','55191','NM','','34 Shipham Close Rd','','','','','','','','','false','0016g000007WEgWAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAeEAO','','Home','','false','','','true','','2020-01-10','Greenville','','63102','OR','','36624 Jefferson Way Way','','','','','','','','','false','0016g000007WEfIAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAfEAO','','Home','','false','','','true','','2020-01-10','Greenville','','63102','OR','','36624 Jefferson Way Way','','','','','','','','','false','0016g000007WEfJAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAgEAO','','Home','','false','','','true','','2020-01-10','Kingston','','63981','WA','','18312 Duchess Rd','','','','','','','','','false','0016g000007WEfYAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAhEAO','','Home','','false','','','true','','2020-01-10','Kingston','','63981','WA','','18312 Duchess Rd','','','','','','','','','false','0016g000007WEfaAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAiEAO','','Home','','false','','','true','','2020-01-10','San Francisco','','94118','CA','','2137 Larry Street','','','','','','','','','false','0016g000007WEfKAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAjEAO','','Home','','false','','','true','','2020-01-10','Franklin','','56949','AK','','306 Monterey Drive Ave S','','','','','','','','','false','0016g000007WEfLAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAkEAO','','Home','','false','','','true','','2020-01-10','Burnt Corn','','56070','AL','','102 Drummand Grove Dr','','','','','','','','','false','0016g000007WEfMAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAlEAO','','Home','','false','','','true','','2020-01-10','Chester','','58707','MA','','2754 Glamis Place Way','','','','','','','','','false','0016g000007WEfNAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBgEAO','','Home','','false','','','true','','2020-01-10','Madison','','60465','WI','','24786 Handlebar Dr N','','','','','','','','','false','0016g000007WEgXAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBhEAO','','Home','','false','','','true','','2020-01-10','Springfield','','65802','MO','','726 Twin House Lane','','','','','','','','','false','0016g000007WEgYAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBiEAO','','Home','','false','','','true','','2020-01-10','Witchita','','67497','KS','','2323 Dent Way','','','','','','','','','false','0016g000007WEgZAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBjEAO','','Home','','false','','','true','','2020-01-10','Salem','','69255','LA','','2391 Roborough Dr','','','','','','','','','false','0016g000007WEgaAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBkEAO','','Home','','false','','','true','','2020-01-10','Madison','','70134','CA','','2425 9th Ave','','','','','','','','','false','0016g000007WEgbAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBlEAO','','Home','','false','','','true','','2020-01-10','Reston','','71013','VA','','2459 44th St E','','','','','','','','','false','0016g000007WEgcAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBmEAO','','Home','','false','','','true','','2020-01-10','Seattle','','98103','WA','','2493 89th Way','','','','','','','','','false','0016g000007WEgdAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBnEAO','','Home','','false','','','true','','2020-01-10','Dover','','98982','CO','','2527 Monroe Rd','','','','','','','','','false','0016g000007WEgeAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBoEAO','','Home','','false','','','true','','2020-01-10','Ashland','','99861','KY','','2561 Madison Dr','','','','','','','','','false','0016g000007WEgfAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBpEAO','','Home','','false','','','true','','2020-01-10','Dover','','99948','FL','','2595 Montauk Ave W','','','','','','','','','false','0016g000007WEggAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBqEAO','','Home','','false','','','true','','2020-01-10','Dover','','99948','FL','','2629 Nebraska St','','','','','','','','','false','0016g000007WEghAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBrEAO','','Home','','false','','','true','','2020-01-10','Buffalo','','08982','NY','','129 W 81st','','','','','','','','','false','0016g000007WEgjAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAmEAO','','Home','','false','','','true','','2020-01-10','Salem','','61344','MA','','74358 S Wycliff Ave','','','','','','','','','false','0016g000007WEfOAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAnEAO','','Home','','false','','','true','','2020-01-10','San Francisco','','94118','CA','','2137 Larry Street','','','','','','','','','false','0016g000007WEfQAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAoEAO','','Home','','false','','','true','','2020-01-10','Burnt Corn','','56070','AL','','102 Drummand Grove Dr','','','','','','','','','false','0016g000007WEfRAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTApEAO','','Home','','false','','','true','','2020-01-10','Franklin','','56949','AK','','306 Monterey Drive Ave S','','','','','','','','','false','0016g000007WEfSAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAqEAO','','Home','','false','','','true','','2020-01-10','Chester','','58707','MA','','2754 Glamis Place Way','','','','','','','','','false','0016g000007WEfTAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTArEAO','','Home','','false','','','true','','2020-01-10','Salem','','61344','MA','','74358 S Wycliff Ave','','','','','','','','','false','0016g000007WEfUAAW');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAsEAO','','Home','','false','','','true','','2020-01-10','South San Francisco','','94044','CA','','55 Charleston','','','','','','','','','false','0016g000007WEfdAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAtEAO','','Home','','false','','','true','','2020-01-10','Brooklyn','','2317','NY','','10 Ocean Parkway','','','','','','','','','false','0016g000007WEfeAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAuEAO','','Home','','false','','','true','','2020-01-10','Boston','','2199','MA','','1172 Boylston St.','','','','','','','','','false','0016g000007WEfgAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAvEAO','','Home','','false','','','true','','2020-01-10','Pleasant','','7777','NJ','','1 Cherry Street','','','','','','','','','false','0016g000007WEfhAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAwEAO','','Home','','false','','','true','','2020-01-10','Bristol','','68376','ME','','2357 Attlee Rd','','','','','','','','','false','0016g000007WEfiAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAxEAO','','Home','','false','','','true','','2020-01-10','City Of Commerce','','90040','CA','','1391 Diane Street','','','','','','','','','false','0016g000007WEfjAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAyEAO','','Home','','false','','','true','','2020-01-10','Bloomfield Township','','48302','MI','','3024 Summit Park Avenue','','','','','','','','','false','0016g000007WEfkAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTAzEAO','','Home','','false','','','true','','2020-01-10','Arlington','','2128','MA','','4270 4th Court','','','','','','','','','false','0016g000007WEflAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB0EAO','','Home','','false','','','true','','2020-01-10','Arlington','','57828','WA','','918 Duffield Crescent St','','','','','','','','','false','0016g000007WEfmAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB1EAO','','Home','','false','','','true','','2020-01-10','Georgetown','','59586','ME','','8262 Phinney Ridge Rd','','','','','','','','','false','0016g000007WEfnAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB2EAO','','Home','','false','','','true','','2020-01-10','Fairfield','','62223','KS','','37179 Bedford Shores St','','','','','','','','','false','0016g000007WEfoAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB3EAO','','Home','','false','','','true','','2020-01-10','Marion','','64860','VA','','9156 Springfield Green Dr','','','','','','','','','false','0016g000007WEfpAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB4EAO','','Home','','false','','','true','','2020-01-10','Riverside','','65739','WV','','4578 Linda Ave','','','','','','','','','false','0016g000007WEfqAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB5EAO','','Home','','false','','','true','','2020-01-10','Lebanon','','66618','MD','','2289 David Budd St','','','','','','','','','false','0016g000007WEfrAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB6EAO','','Home','','false','','','true','','2020-01-10','Bay City','','48706','MI','','840 Mount Street','','','','','','','','','false','0016g000007WEfsAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB7EAO','','Home','','false','','','true','','2020-01-10','San Francisco','','94121','CA','','25 10th Ave.','','','','','','','','','false','0016g000007WEfvAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB8EAO','','Home','','false','','','true','','2020-01-10','Truth or Consequences','','55191','NM','','34 Shipham Close Rd','','','','','','','','','false','0016g000007WEfwAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTB9EAO','','Home','','false','','','true','','2020-01-10','Dover','','98982','CO','','2527 Monroe Rd','','','','','','','','','false','0016g000007WEfxAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBAEA4','','Home','','false','','','true','','2020-01-10','Reston','','71013','VA','','2459 44th St E','','','','','','','','','false','0016g000007WEfyAAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBBEA4','','Home','','false','','','true','','2020-01-10','Madison','','70134','CA','','2425 9th Ave','','','','','','','','','false','0016g000007WEg0AAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBCEA4','','Home','','false','','','true','','2020-01-10','Witchita','','67497','KS','','2323 Dent Way','','','','','','','','','false','0016g000007WEg1AAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBDEA4','','Home','','false','','','true','','2020-01-10','Salem','','69255','LA','','2391 Roborough Dr','','','','','','','','','false','0016g000007WEg2AAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBEEA4','','Home','','false','','','true','','2020-01-10','Dover','','99948','FL','','2629 Nebraska St','','','','','','','','','false','0016g000007WEg3AAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBFEA4','','Home','','false','','','true','','2020-01-10','Dover','','99948','FL','','2595 Montauk Ave W','','','','','','','','','false','0016g000007WEg4AAG');
INSERT INTO "npsp__Address__c" VALUES('a0M6g000000NTBGEA4','','Home','','false','','','true','','2020-01-10','Seattle','','98103','WA','','2493 89th Way','','','','','','','','','false','0016g000007WEg5AAG');
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
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k3KHEAY','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEBiDAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k3KIEAY','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEBiDAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ePEAQ','12500.0','100.0','','a0b6g000000WlnXAAS','0066g00000mEB2SAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eQEAQ','75.0','100.0','','a0b6g000000WlnXAAS','0066g00000mEB3hAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eREAQ','375000.0','100.0','','a0b6g000000WlnXAAS','0066g00000mEB3iAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eSEAQ','300000.0','100.0','','a0b6g000000WlnXAAS','0066g00000mEB3jAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eTEAQ','1250.0','100.0','','a0b6g000000WlnXAAS','0066g00000mEB3sAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eUEAQ','1000.0','100.0','','a0b6g000000WlnXAAS','0066g00000mEB3tAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eVEAQ','12500.0','100.0','','a0b6g000000WlnXAAS','0066g00000mEB3xAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eWEAQ','','50.0','','a0b6g000000WlnYAAS','','a0A6g0000041b4qEAA');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eXEAQ','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2jAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eYEAQ','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2kAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eZEAQ','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2lAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eaEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2mAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ebEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2nAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ecEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2oAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2edEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2pAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eeEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2qAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2efEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2rAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2egEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2sAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ehEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2tAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eiEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2uAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ejEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2yAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ekEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB2zAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2elEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB30AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2emEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB31AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2enEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB32AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eoEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB33AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2epEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB34AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eqEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB35AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2erEAA','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000mEB36AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2esEAA','10000.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB2TAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2etEAA','125.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3bAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2euEAA','125.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3cAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2evEAA','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3dAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ewEAA','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3eAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2exEAA','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3fAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2eyEAA','30.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3gAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ezEAA','50.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3kAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f0EAA','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3lAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f1EAA','50.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3mAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f2EAA','50.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3nAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f3EAA','100.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3oAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f4EAA','50.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3pAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f5EAA','25.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3qAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f6EAA','125.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3uAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f7EAA','100.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3vAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f8EAA','10000.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3wAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2f9EAA','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3yAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fAEAQ','30.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3CAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fBEAQ','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3DAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fCEAQ','100.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3EAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fDEAQ','160.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3FAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fEEAQ','125.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3GAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fFEAQ','300.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3HAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fGEAQ','125.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3IAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fHEAQ','100.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3JAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fIEAQ','50.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3KAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fJEAQ','25.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3LAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fKEAQ','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3MAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fLEAQ','100.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3NAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fMEAQ','125.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3OAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fNEAQ','225.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3PAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fOEAQ','100.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3QAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fPEAQ','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3RAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fQEAQ','125.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3SAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fREAQ','100.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3TAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fSEAQ','50.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3UAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fTEAQ','15.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3VAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fUEAQ','75.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3WAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fVEAQ','50.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3XAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fWEAQ','10.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3YAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fXEAQ','125.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3ZAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fYEAQ','100.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3aAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fZEAQ','9375.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB2UAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2faEAA','7500.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB37AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fbEAA','1250.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB38AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fcEAA','1000.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB39AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fdEAA','1250.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3AAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2feEAA','1000.0','100.0','','a0b6g000000WlnaAAC','0066g00000mEB3BAAW','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ffEAA','','50.0','','a0b6g000000WlncAAC','','a0A6g0000041b4qEAA');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fgEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2jAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fhEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2kAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fiEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2lAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fjEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2mAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fkEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2nAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2flEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2oAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fmEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2pAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fnEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2qAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2foEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2rAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fpEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2sAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fqEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2tAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2frEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2uAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fsEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2yAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2ftEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB2zAAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fuEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB30AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fvEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB31AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fwEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB32AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fxEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB33AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fyEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB34AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2fzEAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB35AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2g0EAA','50.0','50.0','','a0b6g000000WlncAAC','0066g00000mEB36AAG','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000000k2g1EAA','','100.0','7016g000000gmWVAAY','a0b6g000000WlnXAAS','','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000001EkCEEA0','50.0','50.0','','a0b6g000000WlnYAAS','0066g00000p2SN0AAM','');
INSERT INTO "npsp__Allocation__c" VALUES('a0N6g000001EkCFEA0','50.0','50.0','','a0b6g000000WlncAAC','0066g00000p2SN0AAM','');
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
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIDvEAM','Thank You Phone Call','','1.0','High','0','false','false','Not Started','Call','a0W6g000000JJXMEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIDwEAM','Send Gold level packet in mail','','7.0','Normal','0','false','false','Not Started','Other','a0W6g000000JJXMEA4','a0V6g000000jIDvEAM');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIDxEAM','Confirm packet received email','','5.0','Normal','0','false','false','Not Started','Email','a0W6g000000JJXMEA4','a0V6g000000jIDwEAM');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIDyEAM','Follow Up Email','','30.0','High','0','false','false','Not Started','Email','a0W6g000000JJXMEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIDzEAM','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0W6g000000JJXMEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE0EAM','Application Review','','1.0','High','0','false','false','Not Started','Other','a0W6g000000JJXNEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE1EAM','Approval Email','','1.0','High','0','false','false','Not Started','Email','a0W6g000000JJXNEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE2EAM','Background Check','','2.0','High','0','false','false','Not Started','Other','a0W6g000000JJXNEA4','a0V6g000000jIE1EAM');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE3EAM','Volunteer Orientation','','14.0','High','0','false','false','Not Started','Meeting','a0W6g000000JJXNEA4','a0V6g000000jIE2EAM');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE4EAM','Thank You Phone Call','','1.0','High','0','false','false','Not Started','Call','a0W6g000000JJXOEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE5EAM','Schedule Facility Tour & Lunch','','7.0','Normal','0','false','false','Not Started','Meeting','a0W6g000000JJXOEA4','a0V6g000000jIE4EAM');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE6EAM','Follow Up Email','','3.0','High','0','false','false','Not Started','Email','a0W6g000000JJXOEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE7EAM','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0W6g000000JJXOEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE8EAM','Thank You Phone Call by Volunteer','Volunteer will call and thank donor within the month.','30.0','High','0','false','false','Not Started','Call','a0W6g000000JJXPEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIE9EAM','Send membership levels email','Send email with information about benefits of all of the membership levels.','7.0','Normal','0','false','false','Not Started','Other','a0W6g000000JJXPEA4','a0V6g000000jIE8EAM');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIEAEA2','Follow Up Email','','30.0','High','0','false','false','Not Started','Email','a0W6g000000JJXPEA4','');
INSERT INTO "npsp__Engagement_Plan_Task__c" VALUES('a0V6g000000jIEBEA2','Send Impact Report','','90.0','Normal','0','false','false','Not Started','Other','a0W6g000000JJXPEA4','');
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
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0W6g000000JJXMEA4','Gold Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Silver to Gold level.','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0W6g000000JJXNEA4','Volunteer Onboarding','true','Owner of Object for Engagement Plan','Sample Engagement Plan Template','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0W6g000000JJXOEA4','Platinum Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Gold to Platinum level.','Monday','true');
INSERT INTO "npsp__Engagement_Plan_Template__c" VALUES('a0W6g000000JJXPEA4','Silver Stewardship Plan','true','Owner of Object for Engagement Plan','Plan to move someone from Bronze to Silver level.','Monday','true');
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
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eom4EAA','0.0','5.0','','','','0036g000006JcfEAAS','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eom5EAA','0.0','5.0','','','','0036g000006JcfHAAS','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eom6EAA','0.0','4.0','','','','0036g000006JcfRAAS','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eom7EAA','0.0','4.0','','','','0036g000006JcfTAAS','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eom8EAA','0.0','4.0','','','','0036g000006JcfbAAC','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eom9EAA','0.0','4.0','','','','0036g000006JcfiAAC','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomAEAQ','0.0','4.0','','','','0036g000006JcgKAAS','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomBEAQ','0.0','4.0','','','','0036g000006JcgMAAS','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomCEAQ','0.0','4.0','','','','0036g000006JcgNAAS','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomDEAQ','0.0','4.0','','','','0036g000006JcgTAAS','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomEEAQ','0.0','5.0','','','','0036g000006JcgYAAS','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomFEAQ','0.0','4.0','','','','0036g000006JcghAAC','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomGEAQ','0.0','5.0','','','','0036g000006JcerAAC','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomHEAQ','0.0','4.0','','','','0036g000006JcesAAC','a0W6g000000JJXPEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomIEAQ','0.0','5.0','','','','0036g000006JceuAAC','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomJEAQ','0.0','5.0','','','','0036g000006JcewAAC','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomKEAQ','0.0','5.0','','','','0036g000006JceyAAC','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomLEAQ','0.0','5.0','','','','0036g000006Jcf0AAC','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomMEAQ','0.0','5.0','','','','0036g000006Jcf4AAC','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomNEAQ','0.0','5.0','','','','0036g000006Jcf6AAC','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomOEAQ','0.0','5.0','','','','0036g000006Jcf8AAC','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomPEAQ','0.0','5.0','','','','0036g000006JcfAAAS','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomQEAQ','0.0','5.0','','','','0036g000006JcfCAAS','a0W6g000000JJXMEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomREAQ','0.0','4.0','','','','0036g000006JceiAAC','a0W6g000000JJXOEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomSEAQ','0.0','4.0','','','','0036g000006JcekAAC','a0W6g000000JJXOEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000eomTEAQ','0.0','4.0','','','','0036g000006JcemAAC','a0W6g000000JJXOEA4','','');
INSERT INTO "npsp__Engagement_Plan__c" VALUES('a0X6g000000ffzTEAQ','0.0','4.0','','','','0036g000006JcgFAAS','a0W6g000000JJXPEA4','','');
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
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0b6g000000WlnXAAS','Transitional Housing Capital Campaign','true','5465.0','Transitional Housing program specific','2018-06-30','12500.0','2019-05-07','1.0','1.0','0.0','4.0','75.0','12500.0','12500.0','0.0','14825.0','27325.0','5.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0b6g000000WlnYAAS','Food Pantry Programs','true','0.0','','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0b6g000000WlnaAAC','General Fund','true','918.7755102040817','','2018-01-01','10000.0','2019-09-23','28.0','37.0','0.0','12.0','10.0','31365.0','33145.0','0.0','11875.0','45020.0','49.0');
INSERT INTO "npsp__General_Accounting_Unit__c" VALUES('a0b6g000000WlncAAC','Women''s Services','true','0.0','Fund for NMH annual women''s services.','','0.0','','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0','0.0');
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
INSERT INTO "npsp__Level__c" VALUES('a0e6g000000OuHQAA0','Platinum','true','Our highest level.','Giving_Level__c','','10000.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','');
INSERT INTO "npsp__Level__c" VALUES('a0e6g000000OuHRAA0','Silver','true','The second level.','Giving_Level__c','1000.0','100.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0W6g000000JJXMEA4');
INSERT INTO "npsp__Level__c" VALUES('a0e6g000000OuHSAA0','Gold','true','The third level.','Giving_Level__c','10000.0','1000.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0W6g000000JJXOEA4');
INSERT INTO "npsp__Level__c" VALUES('a0e6g000000OuHTAA0','Bronze','true','The lowest entry level.','Giving_Level__c','100.0','35.0','Previous_Giving_Level__c','npo02__TotalOppAmount__c','Contact','a0W6g000000JJXPEA4');
CREATE TABLE "npsp__Partial_Soft_Credit__c" (
	sf_id VARCHAR(255) NOT NULL, 
	"npsp__Amount__c" VARCHAR(255), 
	"npsp__Role_Name__c" VARCHAR(255), 
	npsp__contact__c VARCHAR(255), 
	npsp__opportunity__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "npsp__Partial_Soft_Credit__c" VALUES('a0i6g000001Yt3PAAS','250.0','Soft Credit','0036g000006JcekAAC','0066g00001COGTGAA5');
INSERT INTO "npsp__Partial_Soft_Credit__c" VALUES('a0i6g000001Yt3QAAS','250.0','Soft Credit','0036g000006JcfHAAS','0066g00001COGTGAA5');
INSERT INTO "npsp__Partial_Soft_Credit__c" VALUES('a0i6g000001Yt3RAAS','250.0','Soft Credit','0036g000006JcgFAAS','0066g00001COGTGAA5');
INSERT INTO "npsp__Partial_Soft_Credit__c" VALUES('a0i6g000001Yt3SAAS','250.0','Soft Credit','0036g000006JcgIAAS','0066g00001COGTGAA5');
INSERT INTO "npsp__Partial_Soft_Credit__c" VALUES('a0i6g000001YsycAAC','50.0','Matched Donor','0036g000006JcgFAAS','0066g00001COGSMAA5');
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
