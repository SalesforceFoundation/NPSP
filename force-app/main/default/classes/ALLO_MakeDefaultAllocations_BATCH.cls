/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Batch class creates default allocations for all opportunities that aren't excluded 
* in allocation settings by type or record type.
 */
public class ALLO_MakeDefaultAllocations_BATCH implements Database.Batchable<sObject> {

    /** @description Allocations settings object.*/
    private Allocations_Settings__c alloSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();
    
    /** @description Which opportunity types to exclude. We need to split this into a set 
    * to avoid a partial match, e.g. Donor could be matched to the string Matching Donor*/
    private Set<String> oppTypesToExclude = String.isBlank(alloSettings.Excluded_Opp_Types__c) ? new Set<String>() : new Set<String>(alloSettings.Excluded_Opp_Types__c.split(';'));

    /** @description The query for the batch process to run on.*/
    private String query;
    
    /** @description The batch process constructor; queries all opportunities, then excludes by recordtype/type in the execute method.
    * This approach avoids query timeouts on large data volumes. */
    public ALLO_MakeDefaultAllocations_BATCH() {
        if (ALLO_Multicurrency_TDTM.isMultiCurrency()) {
            query = 'SELECT Id, Amount, RecordTypeId, Type, CurrencyIsoCode FROM Opportunity';
        } else {
            query = 'SELECT Id, Amount, RecordTypeId, Type FROM Opportunity';
        }
    }
    
    /** @description Batch process start method.*/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    private Boolean needsDefaultAllocation(Opportunity opp) {
        if (!String.isBlank(alloSettings.Excluded_Opp_RecTypes__c) && !String.isBlank(opp.RecordTypeId)) {
            if (alloSettings.Excluded_Opp_RecTypes__c.contains(opp.RecordTypeId)) {
                return false;
            }
        }
        if (!String.isBlank(opp.Type) && oppTypesToExclude.contains(opp.Type)) {
            return false;
        }
        return true;
    }

    /*********************************************************************************************************
    * @description Batch process execute method. Queries for allocations for the current opportunity. Creates
    * a default allocation for the full amount if none are present, or for the unallocated remainder if the
    *  opportunity isn't completely allocated.
    */
    public void execute(Database.BatchableContext BC, List<sObject> scope) {

        list<Opportunity> listOpps = (list<Opportunity>) scope;

        map<id,Opportunity> mapIdOpp = new map<id,Opportunity>();
        map<id,list<Allocation__c>> mapOppIdAllo = new map<id,list<Allocation__c>>();
        list<Allocation__c> listAlloForInsert = new list<Allocation__c>();
        list<Allocation__c> listAlloForUpdate = new list<Allocation__c>();

        for (Opportunity opp : listOpps) {
            //only add opps not excluded in settings for processing
            if (needsDefaultAllocation(opp)) {
                mapIdOpp.put(opp.id, opp);
            }
        }

        for (Allocation__c allo : [SELECT Id, General_Accounting_Unit__c, Opportunity__c, Amount__c FROM Allocation__c WHERE Opportunity__c IN :mapIdOpp.keySet()]) {
            if (!mapOppIdAllo.containsKey(allo.Opportunity__c)) 
                mapOppIdAllo.put(allo.Opportunity__c, new list<Allocation__c>());

            mapOppIdAllo.get(allo.Opportunity__c).add(allo);
        }

        for (Opportunity opp : mapIdOpp.values()) {
            //if we have allocations for this opp, create or update the default
            if (mapOppIdAllo.containsKey(opp.id)) {
                decimal remainder = opp.Amount;
                Allocation__c defaultAllo = new Allocation__c();

                for (Allocation__c allo : mapOppIdAllo.get(opp.id)) {
                    if (alloSettings.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c == alloSettings.Default__c)
                        defaultAllo = allo;
                    else
                        remainder -= allo.Amount__c;
                }

                if (remainder > 0) {
                    if (defaultAllo.id!=null && defaultAllo.Amount__c!=remainder) {
                        defaultAllo.Amount__c = remainder;
                        listAlloForUpdate.add(defaultAllo);
                    } else if (defaultAllo.id==null) {
                        Allocation__c allo = ALLO_Allocations_TDTM.makeDefaultAllocation(opp);
                        allo.Amount__c = remainder;
                        listAlloForInsert.add(allo);
                    }
                }
            //if we have no allocations for this opp, create one
            } else {
                listAlloForInsert.add(ALLO_Allocations_TDTM.makeDefaultAllocation(opp));
            }
        }

        //No error handling necessary, because the only place this is called from is the widget that displays the batch
        //process status in the UI.
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, true);
        if (!listAlloForInsert.isEmpty()) {
            insert listAlloForInsert;
        }
        if (!listAlloForUpdate.isEmpty()) {
            update listAlloForUpdate;
        }
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);
    }
    
    /** @description Batch process finish method, does nothing.*/
    public void finish(Database.BatchableContext BC) {}
    
}