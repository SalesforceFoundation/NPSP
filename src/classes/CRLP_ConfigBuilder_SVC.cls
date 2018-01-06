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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Service methods to
*
*/
public class CRLP_ConfigBuilder_SVC {

    public static void queueRollupConfigForDeploy(List<CRLP_RollupCMT.FilterGroup> groupsAndRules) {
        List<List<Metadata.CustomMetadata>> nestedMetadata = new List<List<Metadata.CustomMetadata>>();

        List<Metadata.CustomMetadata> groups = new List<Metadata.CustomMetadata>();
        List<Metadata.CustomMetadata> rules = new List<Metadata.CustomMetadata>();
        for (CRLP_RollupCMT.FilterGroup fg : groupsAndRules) {
            groups.add(fg.getMetadataRecord());
            for (CRLP_RollupCMT.FilterRule fr : fg.rules) {
                rules.add(fr.getMetadataRecord());
            }
        }

        nestedMetadata.add(groups);
        nestedMetadata.add(rules);

        CMT_MetadataAPI.deployMetadata(UserInfo.getUserId(), nestedMetadata);
    }

    /** ***************************************************************************************************
    * ==================  SAMPLE CODE THAT ILLUSTRATES HOW TO IMPLEMENT THIS CLASS  =======================
    *******************************************************************************************************
    * Notes:
    * - Can call upsertCustomMetadata() multiple times to add insert/updates to the queue so that a single
    *   call to commitPendingOperations() will insert/update multiple records at once.
    * - When handling FilterGroups and FilterRules, the FilterGroups would have to be inserted first
    *   and then after the async job completes, the data can be queried using CMT_FilterRule_SEL
    *   to get the Id's to use to insert the FilterRule records.
    * - When inserting/updating CMT's from a UI, Javascript can be used to poll the status of the operations
    *   showing status to the User while also waiting for the first operation to complete before calling
    *   secondary actions (i.e., Filter_Rules__mdt).
    * - If this is being done as a headless operation (i.e., from a PostInstall script or something like that)
    *   then the process probably has to be split into chained queuable jobs where the first job inserts the
    *   Filter_Groups. The callback method for that job could launch the second queueable job to insert the
    *   Filter_Rules and Rollup records (both of which are dependent upon FilterGroup.Id).
    ******************************************************************************************************* */
    public static void testMetadataTypes() {

        /*CMT_MetadataAPI.upsertCustomMetadata(CRLP_RollupCMT.MetadataObject.Filter_Group, 'TEST_GROUP', 'Test Filter Group for Chained Deploy',
                new Map<String,Object>{
                        'Description__c' => 'Test Description',
                        'Is_Deleted__c' => false
                });

        List<List<Metadata.CustomMetadata>> nestedData = new List<List<Metadata.CustomMetadata>>();
        nestedData.add(cmtUpsertQueue.clone());
        cmtUpsertQueue.clear();

        CMT_MetadataAPI.upsertCustomMetadata(CRLP_RollupCMT.MetadataObject.Filter_Rule, 'TEST_GROUP_Rule_1', 'Test Group 1: Filter Opportunity Type',
                new Map<String,Object>{
                        'Filter_Group__c' => 'TEST_GROUP',
                        'Operator__c' => CMT_FilterRule.FilterOperation.NOT_EQUALS.name(),
                        'Constant__c' => 'Solicitor',
                        'Object__c' => SObjectType.Opportunity.getName(),
                        'Field__c' => SObjectType.Opportunity.Fields.Type.getName(),
                        'Is_Deleted__c' => false
                });
        nestedData.add(cmtUpsertQueue.clone());
        cmtUpsertQueue.clear();

        CMT_MetadataAPI.deployMetadata('1232', nestedData);*/
        // Can query AsyncApexJob to determine when the job has completed.
    }
    /* ==================================================================================================== */

}