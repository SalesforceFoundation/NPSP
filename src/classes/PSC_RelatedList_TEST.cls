/*
    Copyright (c) 2016, Salesforce.org
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
 * @date 2016
 * @group Opportunity
 * @description test class for the Partial Soft Credit / OCR Related List VF page 
 */
 
@isTest 
public with sharing class PSC_RelatedList_TEST {

    /*******************************************************************************************************
    * @description test data for all tests
    */ 
    public static Account acc;
    public static integer cContact = 4;
    public static integer cPSCExisting = 2;
    public static list<Contact> listCon;
    public static Opportunity opp;
        
    /*******************************************************************************************************
    * @description initialize test data for all tests.  creates an Opp with an OCR to each contact,
    * the first contact being marked primary.
    * @param createPSCs whether to create PSC's for nonPrimary Contacts as well.
    */ 
    public static void initTestData(boolean createPSCs) {
        
        // create a matching gift company
        acc = new Account(name='some company');
        insert acc;
        
        // create some Contacts in Household Accounts
        listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(cContact);
        insert listCon;
        listCon = [select Id, Firstname,Lastname, AccountId from Contact];
        system.assertEquals(cContact, listCon.size());
        
        // create an Opportunity
        opp = new Opportunity(
            Name='test opp', 
            Amount=1000, 
            AccountId=acc.Id, 
            CloseDate=System.Today(),
            StageName=UTIL_UnitTestData_TEST.getClosedWonStage(),
            Primary_Contact__c = listCon[0].Id
            ); 
        insert opp;
        
        // create our nonprimary OCRs
        list<OpportunityContactRole> listOCR = new list<OpportunityContactRole>();
        for (integer i = 1; i < cContact; i++) {
            listOCR.add(new OpportunityContactRole(
                ContactId = listCon[i].Id,
                OpportunityId = opp.Id,
                Role = 'Soft Credit',
                IsPrimary = false
            ));
        }
        insert listOCR;
        
        if (createPSCs) {
            // create Partial Soft Credits
            list<Partial_Soft_Credit__c> listPSC = new list<Partial_Soft_Credit__c>();
            for (integer i = 1; i <= cPSCExisting; i++) {
                listPSC.add(new Partial_Soft_Credit__c(
                    Contact__c = listCon[i].Id,
                    Opportunity__c = opp.Id,
                    Role_Name__c = 'Soft Credit',
                    Amount__c = 100                
                    ));
            }
            insert listPSC;
            
        }        
    }

    /*******************************************************************************************************
    * @description verify list displays OCRs for an Opp with only OCRs.
    */ 
    static testmethod void displayOCRsOnly() {
        initTestData(false); // no existing PSCs
        Test.setCurrentPage(Page.PSC_RelatedList);
        PSC_RelatedList_CTRL ctrl = new PSC_RelatedList_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cContact, ctrl.softCredits.size());
    }

    /*******************************************************************************************************
    * @description verify list displays OCRs & PSCs for an Opp with both.
    */ 
    static testmethod void displayOCRsAndPSCs() {
        initTestData(true);
        Test.setCurrentPage(Page.PSC_RelatedList);
        PSC_RelatedList_CTRL ctrl = new PSC_RelatedList_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cContact, ctrl.softCredits.size());
    }

    /*******************************************************************************************************
    * @description delete an OCR and verify it is removed from the list
    */ 
    public static testMethod void deleteOCR() {
        initTestData(false); // no existing PSCs
        Test.setCurrentPage(Page.PSC_RelatedList);
        PSC_RelatedList_CTRL ctrl = new PSC_RelatedList_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cContact, ctrl.softCredits.size());
        
        system.currentPageReference().getParameters().put('recordId', [SELECT Id FROM OpportunityContactRole WHERE IsPrimary=false LIMIT 1].Id);
        ctrl.deleteSoftCredit();
        system.assertEquals(cContact-1, ctrl.softCredits.size());        
    }
    
}