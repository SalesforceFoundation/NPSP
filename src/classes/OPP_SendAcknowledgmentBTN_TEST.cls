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
@isTest(isParallel=true)
public with sharing class OPP_SendAcknowledgmentBTN_TEST {
    private static final String TO_BE_ACKNOWLEDGED_STATUS = 'To Be Acknowledged';

    /*********************************************************************************************************
    * @description Tests the controller for the Send Acknowledgment Button
    */
    @isTest
    private static void testSendAcknowledgment() {        
        List<Opportunity> listOpp = setUpOpportunities(1);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(listOpp);
        sc.setSelected(listOpp);
        OPP_SendAcknowledgmentBTN_CTRL ctrl = new OPP_SendAcknowledgmentBTN_CTRL(sc);
        
        Test.startTest();
        ctrl.SendAcknowledgment();
        Test.stopTest();
        
        listOpp = getOpps();

        System.assertEquals(1, listOpp.size());

        // we don't know if the workflow is active or not.
        System.assert(
            listOpp[0].Acknowledgment_Status__c == OPP_SendAcknowledgmentBTN_CTRL.ACKNOWLEDGEMENT_FAILED ||
            listOpp[0].Acknowledgment_Status__c == OPP_SendAcknowledgmentBTN_CTRL.ACKNOWLEDGED, 
            'Acknowledge Status Mismatch Expected: (' +  OPP_SendAcknowledgmentBTN_CTRL.ACKNOWLEDGEMENT_FAILED +
             ' OR ' + OPP_SendAcknowledgmentBTN_CTRL.ACKNOWLEDGED + ') ACTUAL: ' + listOpp[0].Acknowledgment_Status__c
        );  
        System.assertNotEquals(null, ctrl.listOppNotSent);
        System.assertNotEquals(ctrl.cSent, ctrl.cNotSent);   
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
        ctrl.oppsToAcknowledge = opps;
        
        Test.startTest();
        ctrl.SendAcknowledgment();
        Test.stopTest();

        UTIL_UnitTestData_TEST.assertPageHasError('invalid cross reference');

        for (Opportunity opp : getOpps()) {
            System.assertEquals(
                TO_BE_ACKNOWLEDGED_STATUS, opp.Acknowledgment_Status__c, 
                'The Acknowledgment Status should be unchanged'
            );
        }    

        System.assertEquals(0, ctrl.cSent, 'Sent Counter was not rolledback');
        System.assertEquals(1, ctrl.cNotSent, 'Not Sent Counter was not rolledback');

    }


    /*********************************************************************************************************
    @description 
        Test testResendOfAcknowledgement() will attempt to send the acknowledgement when the opportunity is 
        already acknowledged
    verify:
        The opportunity should not resend the acknowledgement multiple times
    **********************************************************************************************************/     
    @isTest
    private static void testResendAcknowledgements() { 
        Date INITIAL_DATE = Date.newInstance(2018, 1, 1);

        List<Opportunity> allOpps = setUpOpportunities(5);
        Set<Id> resendOppIds = new Set<Id>();
        Set<Id> sendOppIds = new Set<Id>();
        
        for (Integer oppIndex=0; oppIndex < allOpps.size(); oppIndex++) {
            Opportunity o = allOpps[oppIndex];
            o.Acknowledgment_Date__c = INITIAL_DATE;
            if (oppIndex < 3) {
                o.Acknowledgment_Status__c = OPP_SendAcknowledgmentBTN_CTRL.ACKNOWLEDGED;
                resendOppIds.add(o.Id);
            } else {
                sendOppIds.add(o.Id);
            }
        }     
        
        update allOpps;

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(allOpps);
        sc.setSelected(allOpps);
        OPP_SendAcknowledgmentBTN_CTRL ctrl = new OPP_SendAcknowledgmentBTN_CTRL(sc);                
        
        Test.startTest();
        ctrl.SendAcknowledgment();
        Test.stopTest();

        // check the resulting acknowledgement status 
        allOpps = getOpps();

        System.assertEquals(5, allOpps.size(), 'Opportunity Size mismatch');     
        System.assertEquals(3, ctrl.cAlreadySent, 'Incorrect # of acks already sent');

        Integer sentCount = 0;
        Integer notSentCount = 0;

        for (Opportunity o : allOpps) {
            if (resendOppIds.contains(o.Id)) {
                System.assertEquals(
                    OPP_SendAcknowledgmentBTN_CTRL.ACKNOWLEDGED, 
                    o.Acknowledgment_Status__c, 
                    'Acknowledgement status is wrong'
                );
                System.assertEquals(INITIAL_DATE, o.Acknowledgment_Date__c, 'Acknowledgement date is wrong'); 
                continue;
            } 

            if (o.Acknowledgment_Status__c == OPP_SendAcknowledgmentBTN_CTRL.ACKNOWLEDGED) {
                sentCount++;
            }

            if (o.Acknowledgment_Status__c == OPP_SendAcknowledgmentBTN_CTRL.ACKNOWLEDGEMENT_FAILED) {
                notSentCount++;
            }                  
        }  

        System.assertEquals(notSentCount, ctrl.cNotSent, 'Incorrect # of not sent acks');
        System.assertEquals(sentCount, ctrl.cSent, 'Incorrect # of sent acks');
                
    }


    /*********************************************************************************************************
    * @description  
        Test testEmptyOpportunityList() send an empty Opportunity List to the controller        
    * verify:
    *   The appropriate error message is displayed
    **********************************************************************************************************/   
    
    @isTest
    private static void testEmptyOpportunity() { 
        Test.setCurrentPage(Page.OPP_SendAcknowledgmentBTN);

        List<Opportunity> opps = new List<Opportunity>();

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(opps);
        sc.setSelected(opps);
        OPP_SendAcknowledgmentBTN_CTRL ctrl = new OPP_SendAcknowledgmentBTN_CTRL(sc);
        
        Test.startTest();
        ctrl.SendAcknowledgment();
        Test.stopTest();

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.sendAcknowledgmentNoneSelected);


    }



    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Create Opportunities and Opportunity Contact Roles
    * @param oppCount Number of how many Opportunities should be created
    * @return List<Opportunity> List of Opportunities
    **********************************************************************************************************/
    private static List<Opportunity> setUpOpportunities(Integer oppCount) {
        Account acc = new Account(Name = 'Test Company');
        insert acc;
        
        Contact con = new Contact(
            AccountID = acc.Id, 
            FirstName = 'Test', 
            LastName = 'Company', 
            Email = 'Test.Company@example.com'
        );
        insert con;
        
        List<Opportunity> opps = new List<Opportunity>();
        Date today = system.today();
        String closedWonStage = UTIL_UnitTestData_TEST.getClosedWonStage();

        for (Integer i = 0; i < oppCount; i++) {
            opps.add(
                new Opportunity(
                    AccountId = acc.Id, 
                    Primary_Contact__c = con.Id,
                    CloseDate = today, 
                    Amount = 100, Name = 'Test Company Donation', 
                    StageName = closedWonStage, 
                    Acknowledgment_Status__c = TO_BE_ACKNOWLEDGED_STATUS
                )
            );
        }
        insert opps;
        
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for (Opportunity opp : opps) {
            ocrs.add(
                new OpportunityContactRole(
                    OpportunityId = opp.Id, 
                    ContactId = con.Id, 
                    IsPrimary = true
                )
            );
        }      
        insert ocrs;
        
        return opps;
    }

    /*********************************************************************************************************
    * @description Return all opportunities
    * @return List<Opportunity> List of Opportunities
    **********************************************************************************************************/
  
    private static List<Opportunity> getOpps() {
        return [SELECT 
                    Id, 
                    name, 
                    Acknowledgment_Status__c, 
                    Acknowledgment_Date__c 
                FROM Opportunity];
    }    
}