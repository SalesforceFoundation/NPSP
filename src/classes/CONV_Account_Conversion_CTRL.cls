/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distributio
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permissio
 
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
    public Boolean batching { get; set; }
    public Boolean batchRunning { get; set; }
    public String AccountHouseholdIdField {get;set;}
    public Map<String, String> copyFieldSet {get;set;}
    public list<SelectOption> targetAccountfields = new list<SelectOption>();

    public list<SelectOption> getTargetAccountFields(){
        targetAccountfields.clear();
        Map<string, Schema.Sobjectfield> targetTokenMap = new Map<string, Schema.Sobjectfield>();
        targetTokenMap = Schema.SObjectType.Account.fields.getMap().clone();

        //pop out the known fields
        for (String s : AccountFields){
            s = s.toLowerCase();
            targetTokenMap.remove(s);
        }
        targetAccountfields.add(new SelectOption('', '-None-'));

        for (String s : targetTokenMap.keyset()){
            if (s.endsWith('__c')){
                List<String> nameSegs = s.split('__');
                if (nameSegs.size() < 3 && Limits.getFieldsDescribes() < Limits.getLimitFieldsDescribes()){
                    Schema.DescribeFieldResult f = targetTokenMap.get(s).getDescribe();
                    Schema.DisplayType payType = f.getType();
                    if(payType == Schema.DisplayType.Id || payType == Schema.DisplayType.TextArea || payType == Schema.DisplayType.String){
                        targetAccountfields.add(new SelectOption(f.getName(), s));
                    }
                }
            }
        }
        return targetAccountfields;
    }

    @RemoteAction
    public static Boolean verifyFieldTypeForIds(String HHField){
        Map<string, Schema.Sobjectfield> targetTokenMap = new Map<string, Schema.Sobjectfield>();
        targetTokenMap = Schema.SObjectType.Account.fields.getMap().clone();

        if (targetTokenMap.containsKey(HHField)){
            Schema.DescribeFieldResult f = targetTokenMap.get(HHField).getDescribe();
            Schema.DisplayType payType = f.getType();
            if(payType == Schema.DisplayType.Id || payType == Schema.DisplayType.TextArea || payType == Schema.DisplayType.String)
                return true;
            else
                return false;
        }
        else{
            return false;
        }
    }

    private static Set<String> HouseholdFields = new Set<String>{'Name', +
        'npo02__TotalOppAmount__c', 'npo02__TotalMembershipOppAmount__c', 'npo02__SmallestAmount__c', + 
        'npo02__SYSTEM_CUSTOM_NAMING__c', 'npo02__OppsClosedThisYear__c', 'npo02__OppsClosedLastYear__c', +
        'npo02__OppsClosedLastNDays__c', 'npo02__OppsClosed2YearsAgo__c', 'npo02__OppAmountThisYear__c', 'npo02__OppAmountLastYear__c', +
        'npo02__OppAmountLastNDays__c', 'npo02__OppAmount2YearsAgo__c', 'npo02__NumberOfMembershipOpps__c', 'npo02__NumberOfClosedOpps__c', +
        'npo02__Membership_Status__c', 'npo02__Membership_Span__c', 'npo02__MembershipJoinDate__c', 'npo02__MembershipEndDate__c',  +
        'npo02__MailingStreet__c', 'npo02__MailingState__c', 'npo02__MailingPostalCode__c', 'npo02__MailingCountry__c', +
        'npo02__MailingCity__c', 'npo02__LastOppAmount__c', 'npo02__LastMembershipOrigin__c', 'npo02__LastMembershipLevel__c', +
        'npo02__LastMembershipDate__c', 'npo02__LastMembershipAmount__c', 'npo02__LastCloseDate__c', 'npo02__LargestAmount__c', +
        'npo02__Informal_Greeting__c', 'npo02__Household_ID__c', 'npo02__HouseholdPhone__c', 'npo02__HouseholdEmail__c', +
        'npo02__Formula_MailingAddress__c', 'npo02__Formal_Greeting__c', 'npo02__FirstCloseDate__c', 'npo02__Best_Gift_Year__c', +
        'npo02__Best_Gift_Year_Total__c', 'npo02__AverageAmount__c', 'npo02__Always_Anonymous__c', 'npo02__Addressee__c', +
        'OwnerId '
    };
    private static Set<String> AccountFields = new Set<String>{
        'npo02__TotalOppAmount__c', 'npo02__TotalMembershipOppAmount__c', 'npo02__SmallestAmount__c', 'npo02__SYSTEM_CUSTOM_NAMING__c', 'npo02__OppsClosedThisYear__c', + 
        'npo02__OppsClosedLastYear__c', 'npo02__OppsClosedLastNDays__c', 'npo02__OppsClosed2YearsAgo__c', 'npo02__OppAmountThisYear__c', 'npo02__OppAmountLastYear__c', +
        'npo02__OppAmountLastNDays__c', 'npo02__OppAmount2YearsAgo__c', 'npo02__NumberOfMembershipOpps__c', 'npo02__NumberOfClosedOpps__c', 'npo02__MembershipJoinDate__c', +
        'npo02__MembershipEndDate__c', 'npo02__LastOppAmount__c', 'npo02__LastMembershipOrigin__c', 'npo02__LastMembershipLevel__c', 'npo02__LastMembershipDate__c', +
        'npo02__LastMembershipAmount__c', 'npo02__LastCloseDate__c', 'npo02__LargestAmount__c', 'npo02__Informal_Greeting__c', 'npo02__HouseholdPhone__c', 'npo02__Formal_Greeting__c', +
        'npo02__FirstCloseDate__c', 'npo02__Best_Gift_Year__c', 'npo02__Best_Gift_Year_Total__c', 'npo02__AverageAmount__c', 'npe01__SYSTEM_AccountType__c', 'npe01__SYSTEMIsIndividual__c', +
        'npe01__One2OneContact__c', 'npe01__LifetimeDonationHistory_Number__c', 'npe01__LifetimeDonationHistory_Amount__c', 'npe01__LastDonationDate__c', 'npe01__FirstDonationDate__c'
    };

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

            CONV_Account_Conversion_BATCH cacv = new CONV_Account_Conversion_BATCH(query, AccountHouseholdIdField, null);

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
        String query ='SELECT id';
        for (String s : CONV_Account_Conversion_CTRL.HouseholdFields)
            query += ', ' + s;
        query += ' FROM npo02__Household__c n';
        if (Test.isRunningTest())
            query += ' LIMIT 200';
        return query;
    }
    
    public class FieldValidationException extends Exception {}
}