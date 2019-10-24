/*
    Copyright (c) 2019, Salesforce.org
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
* @group-content ../../ApexDocContent/Opportunity.htm
* @description API Class to allow caller to determine Opportunity's State (Uncommitted, Committed. or Finalized) using the Opportunities Stage
*/
public with sharing class OPP_StageMappingUtil {

    /******************************************************************************************************
    * @description Represents the overall state of the Opportunity.
    * UNCOMMITTED -- Donor has not yet agreed to make the donation.  Donation is unpaid.  This is useful
    * for soliciting or staging gifts.
    * COMMITTED --  Donor has agreed to make a donation.  Donation can be unpaid or partially paid.
    * More money is still expected from the donor.
    * FINALIZED -- Donation is completely received.  Donation can be fully or partially paid.  No more
    * money is expected for the donation.
    */
    @testVisible private static final String UNCOMMITTED_STATE_VAL = 'UNCOMMITTED';
    @testVisible private static final String COMMITTED_STATE_VAL = 'COMMITTED';
    @testVisible private static final String FINALIZED_STATE_VAL = 'FINALIZED';
    @testVisible private static final String TEST_FINALIZED_STAGE = 'Closed Won';
    @testVisible private static final String TEST_COMMITTED_STAGE = 'Pledged';
    


    /******************************************************************************************************
    * @description Used to Cache Set of Opportunity Stages that mean Opportunity is in a Committed State.
    */
    private static Set<String> COMMITTED_STATE_SET = null;

    /******************************************************************************************************
    * @description Used to Cache Set of Opportunity Stages that mean Opportunity is in a Finalized State.
    */
    private static Set<String> FINALIZED_STATE_SET = null;

    /*******************************************************************************************************
    * @description Determines the Opportunity State (UNCOMMITTED, COMMITTED, or FINALIZED) from the
    * Opportunity Stage.  If the Opportunity Stage does not map to a FINALIZED or COMMITTED state,
    * based on the Household Settings, it will return UNCOMMITTED.  It will always return UNCOMMITTED
    * if the settings are not configured.  It first checks the Opportunity Stage is a FINALIZED stage.  If
    * it is, it returns FINALIZED.  If it is not, it checks to see if the Opportunity Stage is a COMMITTED
    * stage.  If it is, it returns COMMITTED.  Otherwise, it returns UNCOMMITTED.
    *
    * NOTE: Opportunity Stage is treated as Case Insensitive, so Closed Won CLOSED WON and closed won are
    * all the same for this purpose.
    * @param String opportunityStage The opportunity stage to check the state of
    * @return String value representing the current opportunity state
    ********************************************************************************************************/
    public static String determineOppStateFromOppStage(String opportunityStage) {

        initializeStates();

        String oppStageToCheck = String.isNotBlank(opportunityStage) ? opportunityStage.trim().toLowerCase() : null;

        if (FINALIZED_STATE_SET != null && FINALIZED_STATE_SET.contains(oppStageToCheck)) {
            return FINALIZED_STATE_VAL;
        }

        if (COMMITTED_STATE_SET != null && COMMITTED_STATE_SET.contains(oppStageToCheck)) {
            return COMMITTED_STATE_VAL;
        }

        return UNCOMMITTED_STATE_VAL;
    }

    /*******************************************************************************************************
    * @description initializes the Opportunity State Sets, used by other parts of this class, if
    * necessary.
    ********************************************************************************************************/
    @testVisible private static void initializeStates() {

        // If either the committed state set or the finalized state set is null, query for everything and 
        // reinitialize everything. 
        if (COMMITTED_STATE_SET == null || FINALIZED_STATE_SET == null) {
            Map<String, Set<String>> oppStateStages = new Map<String, Set<String>>();
            List<Opportunity_Stage_To_State_Mapping__mdt> stageToStateRecords = getOpportunityStageToStateMappings();
            
            for (Opportunity_Stage_To_State_Mapping__mdt mappingRecord : stageToStateRecords) {
                if (mappingRecord.Opportunity_State__c != null) {

                    String oppState = mappingRecord.Opportunity_State__c.trim().toUpperCase();
                    String oppStage = mappingRecord.Opportunity_Stage__c.trim().toLowerCase();
                    Set<String> stages = oppStateStages.containsKey(oppState) ? oppStateStages.get(oppState) : new Set<String>();
                    stages.add(oppStage);
                    oppStateStages.put(oppState, stages);
                }
            }
            
            COMMITTED_STATE_SET = oppStateStages.containsKey(COMMITTED_STATE_VAL) ? oppStateStages.get(COMMITTED_STATE_VAL) : new Set<String>();
            FINALIZED_STATE_SET = oppStateStages.containsKey(FINALIZED_STATE_VAL) ? oppStateStages.get(FINALIZED_STATE_VAL) : new Set<String>();
        }
    }

    /*******************************************************************************************************
    * @description Returns a list of Opportunity stage to state mappings. If it is a test running,
    * return an artificially created list. Otherwise, get it from the database
    ********************************************************************************************************/
    private static List<Opportunity_Stage_To_State_Mapping__mdt> getOpportunityStageToStateMappings() {
        List<Opportunity_Stage_To_State_Mapping__mdt> metadataRecordList = new List<Opportunity_Stage_To_State_Mapping__mdt>();

        if (Test.isRunningTest()) {
            
            // If it's a test running, return artificial records. This ensures consistency in the testing. 
            Opportunity_Stage_To_State_Mapping__mdt finalizedRecord = new Opportunity_Stage_To_State_Mapping__mdt();
            finalizedRecord.Opportunity_Stage__c = TEST_FINALIZED_STAGE;
            finalizedRecord.Opportunity_State__c = FINALIZED_STATE_VAL;

            Opportunity_Stage_To_State_Mapping__mdt pledgedRecord = new Opportunity_Stage_To_State_Mapping__mdt();
            pledgedRecord.Opportunity_Stage__c = TEST_COMMITTED_STAGE;
            pledgedRecord.Opportunity_State__c = COMMITTED_STATE_VAL;

            metadataRecordList.add(finalizedRecord);
            metadataRecordList.add(pledgedRecord);
        } else {
            metadataRecordList = [SELECT Id, Opportunity_Stage__c, Opportunity_State__c FROM Opportunity_Stage_To_State_Mapping__mdt];
        }

        return metadataRecordList;
    }
}