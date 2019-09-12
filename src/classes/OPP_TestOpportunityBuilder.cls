/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Opportunity
* @description Opportunity Builder for unit tests
*
*/
@isTest
public with sharing class OPP_TestOpportunityBuilder {
    private Map<String, Object> valuesByFieldName;
    private String closedWonStage {
        get {
            if (closedWonStage == null) {                
                closedWonStage = getStage(true);
            }
            return closedWonStage;
        }
        set;
    }

    private String openStage {
        get {
            if (openStage == null) {                
                openStage = getStage(false);
            }
            return openStage;
        }
        set;
    }

    /*******************************************************************************************************************
    * @description Constructor sets default values
    */
    public OPP_TestOpportunityBuilder() {
        valuesByFieldName = new Map<String, Object>();
        
        //defaults
        valuesByFieldName.put('Name', 'TestOpportunity');
        valuesByFieldName.put('CloseDate', Date.today());
    }

    /*******************************************************************************************************************
    * @description Gets Open (isWon = false) or Close (isWon = true) stage name
    */
    public String getStage(Boolean isWon) {
        List<OpportunityStage> stages = [SELECT MasterLabel FROM OpportunityStage WHERE isActive = true AND isWon = :isWon];
        
        return stages.isEmpty() ? '' : stages[0].MasterLabel;
    }

    /*******************************************************************************************************************
    * @description Sets Opportunity Id
    */
    public OPP_TestOpportunityBuilder withId(Id anId) {
        valuesByFieldName.put('Id', anId);
        return this;
    }

    /*******************************************************************************************************************
    * @description Sets Name
    */
    public OPP_TestOpportunityBuilder withName(String name) {
        valuesByFieldName.put('Name', name);
        return this;
    }

    /*******************************************************************************************************************
    * @description Sets Account
    */
    public OPP_TestOpportunityBuilder withAccount(String name) {
        return withAccount(new Account(Name = name));
    }

    /*******************************************************************************************************************
    * @description Sets Account
    */
    public OPP_TestOpportunityBuilder withAccount(Account acc) {
        valuesByFieldName.put(String.valueOf(Account.SObjectType), acc);
        return withAccount(acc.Id);
    }

    /*******************************************************************************************************************
    * @description Sets Account
    */
    public OPP_TestOpportunityBuilder withAccount(Id accId) {
        valuesByFieldName.put('AccountId', accId);
        return this;
    }

    /*******************************************************************************************************************
    * @description Sets Campaign
    */
    public OPP_TestOpportunityBuilder withCampaign(Id campaignId) {
        valuesByFieldName.put('CampaignId', campaignId);
        return this;
    }

    /*******************************************************************************************************************
    * @description Sets Close Data
    */
    public OPP_TestOpportunityBuilder withCloseDate(Date dt) {
        valuesByFieldName.put('CloseDate', dt);
        return this;
    }

    /*******************************************************************************************************************
    * @description Sets Amount
    */
    public OPP_TestOpportunityBuilder withAmount(Decimal amount) {
        valuesByFieldName.put('Amount', amount);
        return this;
    }

    /*******************************************************************************************************************
    * @description Determines the Closed Won stage value and sets StageName to it
    */
    public OPP_TestOpportunityBuilder withClosedWonStage() {        
        valuesByFieldName.put('StageName', closedWonStage);
        return this;
    }

    /*******************************************************************************************************************
    * @description Determines the open stage value and sets StageName to it
    */
    public OPP_TestOpportunityBuilder withOpenStage() {        
        valuesByFieldName.put('StageName', openStage);
        return this;
    }

    /*******************************************************************************************************************
    * @description Sets Recurring Donation Id on the Opportunity
    */
    public OPP_TestOpportunityBuilder withRecurringDonation(Id rdId) {        
        valuesByFieldName.put('npe03__Recurring_Donation__c', rdId);
        return this;
    }

    /*******************************************************************************************************************
    * @description Adds Opportunity Line Items to the Opportunity
    */
    public OPP_TestOpportunityBuilder withOpportunityLineItems(List<SObject> items) {
        valuesByFieldName.put('OpportunityLineItems', makeArray(items));
        return this;
    }

    /*******************************************************************************************************************
    * @description Attaches child records to the Opportunity
    */
    Map<String, Object> makeArray(List<sObject> childRecords) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('records', childRecords);
        result.put('totalSize', childRecords.size());
        result.put('done', true);
        
        return result;
    }

    /*******************************************************************************************************************
    * @description Builds Opportunity sObject based on the provided values
    */
    public Opportunity build() {
        String jsonString = JSON.serialize(valuesByFieldName);
            
        return (Opportunity) JSON.deserialize(jsonString, Opportunity.class);
    }

}