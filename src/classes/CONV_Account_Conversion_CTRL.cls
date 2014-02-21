/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014 (2.0)
* @description The controller for the VF page invoked by using the bulk Account model conversion utility
*/
public with sharing class CONV_Account_Conversion_CTRL {

    // properties for page
    public boolean batching { get; set; }
    public boolean batchRunning { get; set; }

    // constructor
    public CONV_Account_Conversion_CTRL() {
        batching = true;
        batchRunning = false;
    }

    public PageReference convert() {
        Savepoint sp = Database.setSavepoint();
        try {
            batchRunning = true;
            String query = CONV_Account_Conversion_CTRL.getBatchQuery();

            CONV_Account_Conversion_BATCH cacv = new CONV_Account_Conversion_BATCH(query);

            ID batchprocessid = Database.executeBatch(cacv);

        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.CONV);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }

    public static String getBatchQuery(){
        String query ='SELECT id, Name,  ' +
        ' n.npo02__TotalOppAmount__c, n.npo02__TotalMembershipOppAmount__c, n.npo02__SmallestAmount__c, ' + 
        ' n.npo02__SYSTEM_CUSTOM_NAMING__c, n.npo02__OppsClosedThisYear__c, n.npo02__OppsClosedLastYear__c, ' +
        ' n.npo02__OppsClosedLastNDays__c, n.npo02__OppsClosed2YearsAgo__c, n.npo02__OppAmountThisYear__c, n.npo02__OppAmountLastYear__c, ' +
        ' n.npo02__OppAmountLastNDays__c, n.npo02__OppAmount2YearsAgo__c, n.npo02__NumberOfMembershipOpps__c, n.npo02__NumberOfClosedOpps__c, ' +
        ' n.npo02__Membership_Status__c, n.npo02__Membership_Span__c, n.npo02__MembershipJoinDate__c, n.npo02__MembershipEndDate__c, ' +
        ' n.npo02__MailingStreet__c, n.npo02__MailingState__c, n.npo02__MailingPostalCode__c, n.npo02__MailingCountry__c, ' +
        ' n.npo02__MailingCity__c, n.npo02__LastOppAmount__c, n.npo02__LastMembershipOrigin__c, n.npo02__LastMembershipLevel__c, ' +
        ' n.npo02__LastMembershipDate__c, n.npo02__LastMembershipAmount__c, n.npo02__LastCloseDate__c, n.npo02__LargestAmount__c, ' +
        ' n.npo02__Informal_Greeting__c, n.npo02__Household_ID__c, n.npo02__HouseholdPhone__c, n.npo02__HouseholdEmail__c, ' +
        ' n.npo02__Formula_MailingAddress__c, n.npo02__Formal_Greeting__c, n.npo02__FirstCloseDate__c, n.npo02__Best_Gift_Year__c, ' +
        ' n.npo02__Best_Gift_Year_Total__c, n.npo02__AverageAmount__c, n.npo02__Always_Anonymous__c, n.npo02__Addressee__c, ' +
        ' n.OwnerId ' +
        ' FROM npo02__Household__c n' +
        ' LIMIT 200';
        return query;
    }
}