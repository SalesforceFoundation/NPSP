/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
/**
* @author Salesforce.com Foundation
* @date 2009
*
* @group Affiliations
*
* @description  
*/

@isTest	
public with sharing class AFFL_BulkTests_TEST {

    static testMethod void newContactOnOrgAccount() {
    	UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
            new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
    	    	
        Account acc = new Account(Name='test77');
        insert acc;
        
        String newContactfirstName = 'test';
        String newContactLastName = 'Contact_forTests';
        String newContactTitle = 'CEO';
        List<Contact> cons = new List<contact>();
        Integer conCount = 200;
        for(Integer i=0;i<conCount;i++){
            Contact con = new Contact(
                FirstName=newContactfirstName,
                LastName=newContactLastName,
                Title=newContactTitle,
                AccountId = acc.Id
            );
            cons.add(con);
        }
        
        insert cons;
        
        Id firstAffiliationId;
        
        npe5__Affiliation__c[] createdAffiliations = [select id, npe5__Status__c, npe5__StartDate__c, npe5__Role__c, npe5__Organization__c, npe5__EndDate__c, npe5__Contact__c from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc.id];
        
        firstAffiliationId = createdAffiliations[0].Id;
        
        system.assertEquals(conCount,createdAffiliations.size());
        
        system.assertEquals(system.label.npe5.DefaultCurrentStatus, createdAffiliations[0].npe5__Status__c);
        system.assertEquals(newContactTitle, createdAffiliations[0].npe5__Role__c);
        system.assertEquals(System.Today(), createdAffiliations[0].npe5__StartDate__c);
        
        Account acc2 = new Account(Name='test88');
        insert acc2;
        
        Test.startTest();
        AFFL_Affiliations_TDTM.hasRunForContacts = false;
        for(Contact thisContact : cons){    
            thisContact.AccountId = acc2.id;
        }
        update cons;
        Test.stopTest();
        
        npe5__Affiliation__c[] createdAffiliations2 = [select id, npe5__Status__c, npe5__StartDate__c, npe5__Role__c, npe5__Organization__c, npe5__EndDate__c, npe5__Contact__c from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc2.id];
        
        system.assertEquals(conCount,createdAffiliations2.size());
        
        system.assertEquals(system.label.npe5.DefaultCurrentStatus, createdAffiliations2[0].npe5__Status__c);
        system.assertEquals(newContactTitle, createdAffiliations2[0].npe5__Role__c);
        system.assertEquals(System.Today(), createdAffiliations2[0].npe5__StartDate__c);
        
    }
    
    static testMethod void newContactOnIndividualAccount() {
    	UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
            new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
    	
        Account acc = new Account(Name='Individual', npe01__SYSTEMIsIndividual__c=true);
        insert acc;
        
        String newContactfirstName = 'test';
        String newContactLastName = 'Contact_forTests';
        String newContactTitle = 'CEO';
        List<Contact> cons = new List<contact>();
        Integer conCount = 200;
        for(Integer i=0;i<conCount;i++){
            Contact con = new Contact(
                FirstName=newContactfirstName,
                LastName=newContactLastName,
                Title=newContactTitle,
                AccountId = acc.Id
            );
            cons.add(con);
        }
        Test.startTest();
        insert cons;
        Test.stopTest();
        
        npe5__Affiliation__c[] createdAffiliations = [select id, npe5__Status__c, npe5__StartDate__c, npe5__Role__c, npe5__Organization__c, npe5__EndDate__c, npe5__Contact__c from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc.id];
        
        system.assertEquals(0, createdAffiliations.size());
    
    }
    /****  A NEW VERSION CREATED WITH ONLY TWO EXECUTION CONTEXTS (ONE BEFORE STARTTEST AND ONE AFTER) - See below
    static testMethod void contactWithMultipleAffiliations() {
     	//AFFL_Affiliations_TEST.setupTDTM();
     	
        Account acc = new Account(Name='test77');
        insert acc;
        
        Account acc2 = new Account(Name='test88');
        insert acc2;
        
        Account acc3 = new Account(Name='test99');
        insert acc3;
        
        String newContactfirstName = 'test';
        String newContactLastName = 'Contact_forTests';
        String newContactTitle = 'CEO';
        List<Contact> cons = new List<contact>();
        Integer conCount = 200;
        for(Integer i=0;i<conCount;i++){
            Contact con = new Contact(
                FirstName=newContactfirstName,
                LastName=newContactLastName,
                Title=newContactTitle,
                AccountId = acc.Id
            );
            cons.add(con);
        }
        
        insert cons;
        
        Id firstAffiliationId;
        
        npe5__Affiliation__c[] createdAffiliations = [select id from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc.id];     
        system.assertEquals(conCount,createdAffiliations.size());
        firstAffiliationId = createdAffiliations[0].Id;
        
        for(Contact thisContact : cons){    
            thisContact.AccountId = acc2.id;
        }
        
        Test.startTest();
        update cons;
        Test.stopTest();
        
        Id secondAffiliationId;
        
        npe5__Affiliation__c[] createdAffiliations2 = [select id from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc2.id];
        
        system.assertEquals(conCount,createdAffiliations2.size());
        
        secondAffiliationId = createdAffiliations2[0].id;
        
        for(Contact thisContact : cons){    
            thisContact.AccountId = acc3.id;
        }
        update cons;
        
        npe5__Affiliation__c[] createdAffiliations3 = [select id, npe5__Status__c, npe5__StartDate__c, npe5__Role__c, npe5__Organization__c, npe5__EndDate__c, npe5__Contact__c from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc3.id];
        createdAffiliations = [select id, npe5__Status__c, npe5__StartDate__c, npe5__Role__c, npe5__Organization__c, npe5__EndDate__c, npe5__Contact__c from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc.id limit 1];
        createdAffiliations2 = [select id, npe5__Status__c, npe5__StartDate__c, npe5__Role__c, npe5__Organization__c, npe5__EndDate__c, npe5__Contact__c from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc2.id limit 1];
        
        system.assertEquals(conCount,createdAffiliations3.size());
        
        system.assertEquals(system.label.npe5.DefaultCurrentStatus, createdAffiliations3[0].npe5__Status__c);
        system.assertEquals(system.label.npe5.DefaultFormerStatus, createdAffiliations[0].npe5__Status__c);
        system.assertEquals(system.label.npe5.DefaultFormerStatus, createdAffiliations2[0].npe5__Status__c);
        
    }*/
    
    //Modifying the test above to have only two DMLs, one before StartTest and one after
    static testMethod void contactWithMultipleAffiliations_v2() {
        UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
            new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
        
        Account acc = new Account(Name='test77');
        insert acc;

        String newContactfirstName = 'test';
        String newContactLastName = 'Contact_forTests';
        String newContactTitle = 'CEO';
        List<Contact> cons = new List<contact>();
        Integer conCount = 200;
        for(Integer i=0;i<conCount;i++){
            Contact con = new Contact(
                FirstName=newContactfirstName,
                LastName=newContactLastName,
                Title=newContactTitle,
                AccountId = acc.Id
            );
            cons.add(con);
        }
        
        insert cons;
                
        npe5__Affiliation__c[] createdAffiliations = [select id from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc.id];     
        system.assertEquals(conCount,createdAffiliations.size());
        
        Account acc2 = new Account(Name='test88');
        insert acc2;
        for(Contact thisContact : cons){    
            thisContact.AccountId = acc2.id;
        }
        
        Test.startTest();
        AFFL_Affiliations_TDTM.hasRunForContacts = false;
        update cons;
        Test.stopTest();
                
        npe5__Affiliation__c[] createdAffiliations2 = [select id from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc2.id];
        system.assertEquals(conCount,createdAffiliations2.size());
                
        createdAffiliations = [select id, npe5__Status__c, npe5__StartDate__c, npe5__Role__c, npe5__Organization__c, npe5__EndDate__c, npe5__Contact__c from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc.id limit 1];
        createdAffiliations2 = [select id, npe5__Status__c, npe5__StartDate__c, npe5__Role__c, npe5__Organization__c, npe5__EndDate__c, npe5__Contact__c from npe5__Affiliation__c where npe5__Contact__c IN :cons AND npe5__Organization__c = :acc2.id limit 1];
        
        system.assertEquals(system.label.npe5.DefaultFormerStatus, createdAffiliations[0].npe5__Status__c);
        system.assertEquals(system.label.npe5.DefaultCurrentStatus, createdAffiliations2[0].npe5__Status__c);
        
    }
}