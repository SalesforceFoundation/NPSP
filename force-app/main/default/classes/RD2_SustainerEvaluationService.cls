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

    public static Boolean isSustainerUpdateEnabled = false;
    public static void setSustainerUpdateEnabled(Boolean enabled) {
        isSustainerUpdateEnabled = enabled;
    }

    public List<SObject> evaulateSustainersFor(String sObjectType, Set<Id> recordIds) {
        List<SObject> toUpdate = new List<SObject>();
        if (recordIds.isEmpty()) {
            return toUpdate;
        }
        List<SObject> evaulatedRecords = queryService.getSObjectWithActiveRecurringDonations(sObjectType,  recordIds);
        
        List<SObject> noneActiveSustainers = calculateSustainerFor(SustainerType.Active, evaulatedRecords, toUpdate);

        if (noneActiveSustainers.size() == 0) {
            return toUpdate;
        }

        List<SObject> lapsedSustainerCandidates = queryService.getSObjectWithLapsedRecurringDonations(sObjectType, UTIL_SObject.extractIds(noneActiveSustainers));
        List<SObject> formerSustainers = calculateSustainerFor(SustainerType.Lapsed, lapsedSustainerCandidates, toUpdate);

        for (SObject formerSustainer : formerSustainers) {
            if (formerSustainer.get(SUSTAINER_FIELD) != SustainerType.Former.name()) {
                formerSustainer.put(SUSTAINER_FIELD,SustainerType.Former.name());
                toUpdate.add(formerSustainer); 
            }
        }

        return toUpdate;
    }

    private List<SObject> calculateSustainerFor(SustainerType state, List<SObject> sustainerCandidates, List<SObject> toUpdate) {
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
                    toUpdate.add(candidate);
                }

            } else {
                needFurtherEvaluation.add(candidate);
            }
        }

        return needFurtherEvaluation;
    }
}
