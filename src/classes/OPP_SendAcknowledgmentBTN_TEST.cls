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
* @group Opportunity
* @description Test class for the Send Acknowledgment buttons (single and list view) on Opportunities.  
*/
@isTest
public with sharing class OPP_SendAcknowledgmentBTN_TEST {
    private static final String TO_BE_ACKNOWLEDGED_STATUS = 'To Be Acknowledged';

    /*********************************************************************************************************
    * @description Tests the controller for the Send Acknowledgment Button
    */
    static testmethod void testSendAcknowledgment() {        
        list<Opportunity> listOpp = setUpOpportunities(1);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(listOpp);
        sc.setSelected(listOpp);
        OPP_SendAcknowledgmentBTN_CTRL ctrl = new OPP_SendAcknowledgmentBTN_CTRL(sc);
        
        Test.startTest();
        ctrl.SendAcknowledgment();
        Test.stopTest();
        
        listOpp = [select Id, name, Acknowledgment_Status__c, Acknowledgment_Date__c from Opportunity];
        system.assertEquals(1, listOpp.size());

        // we don't know if the workflow is active or not.
        system.assert(listOpp[0].Acknowledgment_Status__c == label.sendAcknowledgmentFailedStatus ||
            listOpp[0].Acknowledgment_Status__c == label.sendAcknowledgmentSucceeded);            
        system.assertNotEquals(null, ctrl.listOppNotSent);
        system.assertNotEquals(ctrl.cSent, ctrl.cNotSent);   
    }

    /*********************************************************************************************************
    @description 
        Test SendAcknowledgment() rollback when an exception occurs 
    verify:
        The transaction is completely rolled back and there is no partial commit
    **********************************************************************************************************/ 
    private static testMethod void testSendAcknowledgmentRollsBackAllDmlsOnError() { 
        Test.setCurrentPage(Page.OPP_SendAcknowledgmentBTN);

        List<Opportunity> opps = setUpOpportunities(2);
        //fail an update
        opps[0].Id = Opportunity.sObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(opps);
        sc.setSelected(opps);
        OPP_SendAcknowledgmentBTN_CTRL ctrl = new OPP_SendAcknowledgmentBTN_CTRL(sc);
        
        Test.startTest();
        ctrl.SendAcknowledgment();
        Test.stopTest();

        UTIL_UnitTestData_TEST.assertPageHasError('invalid cross reference');

        for (Opportunity opp : [SELECT Acknowledgment_Status__c FROM Opportunity]) {
            System.assertEquals(TO_BE_ACKNOWLEDGED_STATUS, opp.Acknowledgment_Status__c, 'The Acknowledgment Status should be unchanged');
        }     
    }

    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Create Opportunities and Opportunity Contact Roles
    * @param oppCount Number of how many Opportunities should be created
    * @return List<Opportunity> List of Opportunities
    **********************************************************************************************************/
    private static List<Opportunity> setUpOpportunities(Integer oppCount) {
        Account account = new Account(Name = 'Test Company');
        insert account;
        
        Contact contact = new Contact(AccountID = account.Id, FirstName = 'Test', LastName = 'Company', Email = 'Test.Company@example.com');
        insert contact;
        
        List<Opportunity> opps = new List<Opportunity>();
        Date today = system.today();
        String closedWonStage = UTIL_UnitTestData_TEST.getClosedWonStage();

        for (Integer i = 0; i < oppCount; i++) {
            opps.add(new Opportunity(
                AccountId = account.Id, Primary_Contact__c = contact.Id,
                CloseDate = today, Amount = 100, Name = 'Test Company Donation', 
                StageName = closedWonStage, Acknowledgment_Status__c = TO_BE_ACKNOWLEDGED_STATUS
            ));
        }
        insert opps;  
        
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for (Opportunity opp : opps) {
            ocrs.add(new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contact.Id, IsPrimary = true));
        }      
        insert ocrs;
        
        return opps;
    }

}