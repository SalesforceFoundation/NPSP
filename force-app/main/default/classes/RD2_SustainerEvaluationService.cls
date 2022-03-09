/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Recurring Donations
* @description Evaluate Sustainer
*/
public inherited sharing class RD2_SustainerEvaluationService {
    private static final String SUSTAINER_FIELD = UTIL_Namespace.StrTokenNSPrefix('Sustainer__c');

    @TestVisible
    private static RD2_QueryService queryService {
        get {
            if (queryService == null) {
                queryService = new RD2_QueryService();
            }
            return queryService;
        }
        set;
    }

    public enum SustainerType {
        Active,
        Lapsed,
        Former
    }

    private boolean isBatchMode = false;
    public RD2_SustainerEvaluationService withBatchContext(Boolean isBatchMode) {
        this.isBatchMode = isBatchMode;
        return this;
    }

    public static Boolean isSustainerUpdateEnabled = false;
    public static void setSustainerUpdateEnabled(Boolean enabled) {
        isSustainerUpdateEnabled = enabled;
    }

    private Set<Id> contactIds = new Set<Id>();
    private Set<Id> accountIds = new Set<Id>();
    private List<SObject> recordsToUpdate = new List<SObject>();

    public RD2_SustainerEvaluationService withRecurringDonations(List<npe03__Recurring_Donation__c> rds) {
        if (rds == null || rds.isEmpty()) {
            return this;
        }
    
        this.contactIds.addAll(UTIL_SObject.extractId(rds, npe03__Recurring_Donation__c.npe03__Contact__c));
        this.accountIds.addAll(UTIL_SObject.extractId(rds, npe03__Recurring_Donation__c.npe03__Organization__c));
        return this;
    }

    public RD2_SustainerEvaluationService withContacts(List<Contact> contacts) {
        contactIds.addAll(UTIL_SObject.extractIds(contacts));
        return this;
    }

    public RD2_SustainerEvaluationService withAccounts(List<Account> accounts) {
        accountIds.addAll(UTIL_SObject.extractIds(accounts));
        return this;
    }

    public List<Contact> getContactsWithSustainerChanged() {
        evaulateSustainersFor('Contact', contactIds);
        return (List<Contact>) recordsToUpdate;
    }

    public List<Account> getAccountsWithSustainerChanged() {
        evaulateSustainersFor('Account', accountIds);
        return (List<Account>) recordsToUpdate;
    }

    /**
    * @description Evaluate what type of Donor the Account/Contact reocrd is. The Account/Contact records can be
    * Active, Lapsed, or Former Sustainer.
    * @param sObjectType The passed in record Ids' SObject type. The type can be either Account or Contact
    * @param recordsIds A set of record Ids that will be evaluated
    */
    private void evaulateSustainersFor(String sObjectType, Set<Id> recordIds) {
        this.recordsToUpdate = new List<SObject>();
        if (recordIds.isEmpty()) {
            return;
        }
    
        List<SObject> evaulatedRecords = queryService.getSObjectWithActiveRecurringDonations(sObjectType,  recordIds);
        List<SObject> inactiveSustainers = evaluateCurrentSustainerTypeAndReturnNotMatchingRecords(SustainerType.Active, evaulatedRecords);

        if (inactiveSustainers.size() == 0) {
            return;
        }

        List<SObject> lapsedSustainerCandidates = queryService.getSObjectWithLapsedRecurringDonations(sObjectType, UTIL_SObject.extractIds(inactiveSustainers));
        List<SObject> formerSustainers = evaluateCurrentSustainerTypeAndReturnNotMatchingRecords(SustainerType.Lapsed, lapsedSustainerCandidates);

        if (formerSustainers.size() == 0) {
            return;
        }
  
        if (isBatchMode) {
            for (SObject formerSustainer : formerSustainers) {
                if (formerSustainer.get(SUSTAINER_FIELD) != SustainerType.Former.name()) {
                    formerSustainer.put(SUSTAINER_FIELD, SustainerType.Former.name());
                    this.recordsToUpdate.add(formerSustainer); 
                }
            }
            return;
        }

        List<SObject> formerSustainerCandidates = queryService.getSObjectWithClosedRecurringDonations(sObjectType, UTIL_SObject.extractIds(formerSustainers));
        List<SObject> nonSustainers = evaluateCurrentSustainerTypeAndReturnNotMatchingRecords(SustainerType.Former, formerSustainerCandidates);

        for (SObject nonSustainer : nonSustainers) {
            if (String.isNotBlank(String.valueOf(nonSustainer.get(SUSTAINER_FIELD)))) {
                nonSustainer.put(SUSTAINER_FIELD, null);
                this.recordsToUpdate.add(nonSustainer); 
            }
        }
    }

    private List<SObject> evaluateCurrentSustainerTypeAndReturnNotMatchingRecords(SustainerType state, List<SObject> sustainerCandidates) {
        List<SObject> needFurtherEvaluation = new List<SObject>();
        String lookupReference = sustainerCandidates[0].getSObjectType() == Schema.Account.getSObjectType()
            ? 'npe03__RecurringDonations__r'
            : 'npe03__R00N80000002bOmREAU__r';
        
        for (Integer i = 0; i < sustainerCandidates.size(); i++) {
            SObject candidate = sustainerCandidates[i];
            List<npe03__Recurring_Donation__c> rdsWithSpecificState = candidate.getSobjects(lookupReference);

            if (rdsWithSpecificState != null && rdsWithSpecificState.size() > 0) {
                if (candidate.get(SUSTAINER_FIELD) != state.name()) {
                    candidate.put(SUSTAINER_FIELD, state.name());
                    this.recordsToUpdate.add(candidate);
                }

            } else {
                needFurtherEvaluation.add(candidate);
            }
        }

        return needFurtherEvaluation;
    }
}
