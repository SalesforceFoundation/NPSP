/*
    Copyright (c) 2015, Salesforce.org
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
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Batch class creates names all Opportunities per the naming spec.
 */
public class OPP_OpportunityNaming_BATCH implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    /** @description The query for the batch process to run on.*/
    private String query;

    @TestVisible
    private static Integer defaultQueryLimit = 10000000;

    @TestVisible
    private Id lastOppIdProcessed;

    /** @description The batch process constructor; creates opportunity query for all opportunities.*/
    public OPP_OpportunityNaming_BATCH() {
        query = 'SELECT Id, Name FROM Opportunity ORDER BY Id LIMIT ' + defaultQueryLimit;
    }

    /** @description Constructor that accepts Id offset*/
    public OPP_OpportunityNaming_BATCH(Id idToOffset) {
        query = buildOffsetQuery(idToOffset, defaultQueryLimit);
    }

    /** @description Builds query string with given Id to offset and query limit*/
    private String buildOffsetQuery(Id idToOffset, Integer queryLimit) {
        return String.format(
            'SELECT Id, Name FROM Opportunity WHERE Id > \'\'{0}\'\' ORDER BY Id LIMIT {1}',
            new List<String>{ idToOffset, String.valueOf(queryLimit) }
        );
    }

    /** @description Batch process start method.*/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    /** @description Schedulable execute method.*/
    public void execute(SchedulableContext context) {
        Database.executeBatch(new OPP_OpportunityNaming_BATCH(), 200);
    }

    /*********************************************************************************************************
    * @description Batch process execute method. Names and updates all opportunities in the current batch.
    */
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Opportunity> oppsToProcess = scope;
        lastOppIdProcessed = oppsToProcess[oppsToProcess.size() - 1].Id;

        //save old opp names to see if we need an update
        Map<Id, String> originalOppNamesById = new Map<Id, String>();
        for (Opportunity opp : oppsToProcess) {
            originalOppNamesById.put(opp.id, opp.Name);
        }

        //refresh names
        OPP_OpportunityNaming.refreshOppNames(oppsToProcess);

        //find which names have been updated, add to list
        List<Opportunity> oppsForUpdate = new List<Opportunity>();
        for (Opportunity opp : oppsToProcess) {
            if (opp.Name != originalOppNamesById.get(opp.id)) {
                oppsForUpdate.add(opp);
            }
        }

        if (!oppsForUpdate.isEmpty()) {
            Database.update(oppsForUpdate, false);
        }
    }
    
    /** @description Batch process finish method, chains another batch if there are more opportunities to process.*/
    public void finish(Database.BatchableContext BC) {
        if (shouldChainNextBatch()) {
            Database.executeBatch(new OPP_OpportunityNaming_BATCH(lastOppIdProcessed), 200);
        }
    }

    /** @description Returns whether or not another batch should be chained*/
    private Boolean shouldChainNextBatch() {
        if (lastOppIdProcessed == null) {
            return false;
        }

        String hasMoreQuery = buildOffsetQuery(lastOppIdProcessed, 1);
        return !Database.query(hasMoreQuery).isEmpty();
    }
}