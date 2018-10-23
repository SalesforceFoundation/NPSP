/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Tribute
* @group-content ../../ApexDocContent/Tribute.htm
* @description Test class of Create Tribute API class.
*/
@isTest
public class OPP_CreateTribute_TEST {
    /******************************************************************************************************
    * @description Test the batch process for Tribute creation
    ********************************************************************************************************/
    static testMethod void testCreateTributeBatch() {
        //Make sure there is no Tribute record in the org
        List<Tribute__c> tributes = [Select Id from Tribute__c];
        system.assertEquals(0, tributes.size());
        //Create and Insert Opportunity
        Account acc = new Account(Name='TheAccount');
        insert acc;
        List<Opportunity> oppsToInsert = new List<Opportunity>();

        for(Integer i = 0; i < 10; i++) {
            Opportunity opp = new Opportunity( AccountId = acc.id, StageName = 'Close Won', Name='Donation' + i,
                    Amount= i, CloseDate = Date.newInstance(2018, 1, 2), Honoree_Name__c = 'John Smith', Notification_Recipient_Name__c = 'Mark Smith');
            oppsToInsert.add(opp);
        }
        insert oppsToInsert;
        Test.startTest();
        Database.executeBatch(new OPP_CreateTribute_BATCH(), 2000);
        Test.stopTest();
        //System should create the Tribute record for the Opportunity
        tributes = [Select Id from Tribute__c];
        system.assertEquals(10, tributes.size());
        //System should clear the Tribute fields on the Opportunity
        List<Opportunity> opps = [Select Id from Opportunity where Honoree_Name__c != null OR Notification_Recipient_Name__c != null];
        system.assertEquals(0, opps.size());
    }
}