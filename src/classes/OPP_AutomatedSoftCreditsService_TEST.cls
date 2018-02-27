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
* @group Opportunity
* @description Test class for OPP_AutomatedSoftCreditsService class.
*/

@isTest
public with sharing class OPP_AutomatedSoftCreditsService_TEST {

	/*********************************************************************************************************
    * @description If you only want to run a single test in this class, fill in its name here.
    * If you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';


    /*********************************************************************************************************
    * @description Tests the Opportunity's Account has an Organization record type.
    * verify:
    *   Account's RecordType is Organization.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testOpportunityAccountRecordTypeIsOrganization() {
        if (strTestOnly != '*' && strTestOnly != 'testOpportunityAccountRecordTypeIsOrganization') return;
        
        Boolean isOrganizationalAccount = false;

        Account acct = new Account(Name = 'Organization Account');
        acct.RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.sobjectType, OPP_AutomatedSoftCreditsService.ACCOUNT_RECORD_TYPE_ORGANIZATION);
        insert acct;

        Test.startTest();
		isOrganizationalAccount = OPP_AutomatedSoftCreditsService.isOrganizationalAccount(acct.RecordTypeId);
        Test.stopTest();

        System.assertEquals(true, isOrganizationalAccount);
    }


    /*********************************************************************************************************
    * @description Tests the Opportunity's Account does not have an Organization record type.
    * verify:
    *   Account's RecordType is not Organization.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testOpportunityAccountRecordTypeNotOrganization() {
        if (strTestOnly != '*' && strTestOnly != 'testOpportunityAccountRecordTypeNotOrganization') return;
        
        Boolean isOrganizationalAccount = false;

        Account acct = new Account(Name = 'Household Account');
        acct.RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Account.sobjectType, CAO_Constants.HH_ACCOUNT_TYPE);
        insert acct;

        Test.startTest();
		isOrganizationalAccount = OPP_AutomatedSoftCreditsService.isOrganizationalAccount(acct.RecordTypeId);
        Test.stopTest();

        System.assertEquals(false, isOrganizationalAccount);
    }

    
}

