/*
    Copyright (c) 2015 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.  
*/
/**
* @author Salesforce.org
* @date 2015
* @description test Soft Credit Rollups, both full and partial
*/

@isTest
private class RLLP_OppPartialSoftCreditRollup_TEST {

    /*******************************************************************************************************
    * @description test data for Soft Credit and Partial Soft Credit tests
    */ 
    static integer cContactTest = 40;
    static integer cOppTest = 30;
    static integer amountTest = 100;
    static list<Contact> listCon;
    
    private static void createPSCData(integer cContact, integer cOpp, integer Amount) {
        
        // create some Contacts in Household Accounts
        listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(cContact);
        insert listCon;
        listCon = [select Id, Firstname,Lastname, AccountId from Contact];
        system.assertEquals(cContact, listCon.size());
        
        // create cOpp Opportunities for each Contact
        list<Opportunity> listOpp = new list<Opportunity>();
        for (integer i = 0; i < cOpp; i++) {
            listOpp.addAll(UTIL_UnitTestData_TEST.OppsForContactWithAccountList (listCon, null,             
                UTIL_UnitTestData_TEST.getClosedWonStage(), system.Today(), Amount, null, null));
        } 
        insert listOpp;
        system.assertEquals(cContact * cOpp, listOpp.size());
        
        // primary OCR's automatically created
        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role, IsPrimary from OpportunityContactRole];
        system.assertEquals(listOpp.size(), listOCR.size());

        // change them to Soft Credit OCR's
        for (OpportunityContactRole ocr : listOCR) {
            ocr.Role = 'Soft Credit';        
            ocr.IsPrimary = false;
        }
        update listOCR;
        
        // create our Partial Soft Credits
        list<Partial_Soft_Credit__c> listPSC = new list<Partial_Soft_Credit__c>();
        for (OpportunityContactRole ocr : listOCR) {
            listPSC.add(new Partial_Soft_Credit__c(
                Contact__c = ocr.ContactId,
                Opportunity__c = ocr.OpportunityId,
                Role_Name__c = ocr.Role,
                Contact_Role_ID__c = ocr.Id,
                Amount__c = Amount/2                
                ));
        }
        insert listPSC;
    }

    static testmethod void testCurrentSoftCreditRollups() {
        createPSCData(cContactTest, cOppTest, amountTest);
        
        RLLP_OppRollup rllp = new RLLP_OppRollup();
        RLLP_OppRollup_UTIL util = new RLLP_OppRollup_UTIL();
        map<id, Contact> cmap = new map<id, Contact>((list<Contact>)Database.query(util.buildContactQuery() +
                                                      ' where id IN :listCon'));
        Test.startTest();
        UTIL_Debug.debugWithInfo('DJH: testCurrentSoftCreditRollups pre '); 
        rllp.rollupSoftCreditsOLDNoPartialSupport(cmap);
        UTIL_Debug.debugWithInfo('DJH: testCurrentSoftCreditRollups post '); 
        Test.stopTest();
        UTIL_Debug.debugWithInfo('DJH: testCurrentSoftCreditRollups after stopTest'); 
        
        // verify results
        listCon = [select Id, Lastname, npo02__Soft_Credit_This_Year__c, npo02__Soft_Credit_Total__c,
            Number_of_Soft_Credits_This_Year__c, Number_of_Soft_Credits__c from Contact];
        system.assertEquals(cContactTest, listCon.size());
        for (Contact con : listCon) {
            system.assertEquals(cOppTest * amountTest, con.npo02__Soft_Credit_This_Year__c);
            system.assertEquals(cOppTest * amountTest, con.npo02__Soft_Credit_Total__c);
            //system.assertEquals(10, con.Number_of_Soft_Credits_This_Year__c);
            //system.assertEquals(10, con.Number_of_Soft_Credits__c);
        }       
    }

    static testmethod void testPartialSoftCreditRollups() {
        createPSCData(cContactTest, cOppTest, amountTest);

        RLLP_OppRollup rllp = new RLLP_OppRollup();
        RLLP_OppRollup_UTIL util = new RLLP_OppRollup_UTIL();        
        listCon = (list<Contact>)Database.query(util.buildContactQuery() + ' where id IN :listCon');

        Test.startTest();
        UTIL_Debug.debugWithInfo('DJH: testPartialSoftCreditRollups pre ');
        rllp.rollupSoftCreditsWithPartialSupport(listCon);
        UTIL_Debug.debugWithInfo('DJH: testPartialSoftCreditRollups post ');
        Test.stopTest();
        UTIL_Debug.debugWithInfo('DJH: testPartialSoftCreditRollups after stopTest');
        
        // verify results
        listCon = [select Id, Lastname, npo02__Soft_Credit_This_Year__c, npo02__Soft_Credit_Total__c,
            Number_of_Soft_Credits_This_Year__c, Number_of_Soft_Credits__c from Contact];
        system.assertEquals(cContactTest, listCon.size());
        for (Contact con : listCon) {
            system.assertEquals(cOppTest * amountTest/2, con.npo02__Soft_Credit_This_Year__c);
            system.assertEquals(cOppTest * amountTest/2, con.npo02__Soft_Credit_Total__c);
            system.assertEquals(cOppTest, con.Number_of_Soft_Credits_This_Year__c);
            system.assertEquals(cOppTest, con.Number_of_Soft_Credits__c);
        }
        
    }
}