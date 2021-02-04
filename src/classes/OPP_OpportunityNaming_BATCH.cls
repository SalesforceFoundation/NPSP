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
* @description Batch class creates names all Opportunities per the naming spec. Batch job chunks Opportunities
* in groups of 10,000,000 records ordered by Id and chains itself to process additional records to avoid query limits
 */
public class OPP_OpportunityNaming_BATCH extends UTIL_AbstractChunkingLDV_BATCH implements Schedulable {
    /**
     * @description # of records in each batch
     */
    private static final Integer BATCH_SIZE = 200;

    /**
     * @description Chunk size to use when running in LDV Mode
     */
    private static final Integer CHUNK_SIZE = 10000000;

    /** @description Default No argument constructor */
    public OPP_OpportunityNaming_BATCH() {
        // Overriding default batch size
        this.setBatchSize(BATCH_SIZE);
    }

    /** @description Schedulable execute method.*/
    public void execute(SchedulableContext context) {
        Database.executeBatch(new OPP_OpportunityNaming_BATCH(), BATCH_SIZE);
    }

    /*********************************************************************************************************
    * @description Batch process execute method. Names and updates all opportunities in the current batch.
    */
    public override void doExecute(Database.BatchableContext BC, List<SObject> records) {

        List<Opportunity> oppsToProcess = (List<Opportunity>) records;

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
            UTIL_DMLService.updateRecords(oppsForUpdate, false);
        }
    }

   /**
     * @description Returns Opportunity for the main object we are querying
     * @return String value of SOQLObjectName
     */
    public override SObjectType getSObjectType() {
        return Opportunity.getSObjectType();
    }

    /**
     * @description LDV Chunk Size to use
     * @return Integer chunk size to use when running in LDV Chunking mode
     */
    public override Integer getLDVChunkSize() {
        return CHUNK_SIZE;
    }

    /**
     * Returns ID, Name
     * @return String SOQL Query fragment consisting of fields and subqueries to retrieve, part between outer select and from
     */
    public override String getSOQLFullQueryFieldList() {
        return 'ID, Name';
    }
}