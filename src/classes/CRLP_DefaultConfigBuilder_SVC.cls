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
* @description Service methods to handle building the default Customizable Rollups Metadata Type records using
* the legacy rollup settings in the NPSP Custom Settings objects. This is effectively executed only one time
* in any given customer org.
*/
public class CRLP_DefaultConfigBuilder_SVC {

    /** @description Prefix all CMT DeveloperName values with this */
    private static final String RecordNamePrefix = 'NPSP_';

    /** @description Legacy Account/Contact rollup settings are stored in this custom settings object */
    private static final npo02__Households_Settings__c legacySettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

    /** @description Legacy Allocation rollup settings are stored in this custom settings object */
    private static final Allocations_Settings__c legacyAllocSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    /** @description Use this Map of RecordTypes by Id to convert the legacy settings into a DeveloperName for the Filter Rule */
    private static final Map<Id, RecordType> recordTypesById = new Map<Id, RecordType>([SELECT Id, RecordType.DeveloperName
            FROM RecordType WHERE SobjectType = 'Opportunity' AND IsActive = True]);

    /** @description The RecordName for the default filter group of Closed Won Donations */
    private static final String FilterGroup_Donations = RecordNamePrefix + 'ClosedWon_Donations';

    /** @description The RecordName for the default filter group of Closed Won Membership */
    private static final String FilterGroup_Membership = RecordNamePrefix + 'ClosedWon_Memberships';

    /** @description The RecordName for the default filter group to use for Allocations Rollups */
    private static final String FilterGroup_Allocations = RecordNamePrefix + 'Allocations_Filter';

    /** @description Map of Rollup Details, where the MapKey is the SummaryObject.Field and List<String> is the
     * following set of rollup properties
     * List<String>{ DetailObject.Field, FilterGroupRecordName, AmountObject.Field, DateObject.Field, OperationString, YearlyOperationString, IntValue }
     */
    private static final Map<String, List<String>> rollupDetailsBySummaryField = new Map<String, List<String>>();

    /** @description Map of Rollup Name & Descriptions; Keeping these separate from the Rollup details map just
     * to make the maps easier to read.
     * List<String>{ Rollup Label, Rollup Description }
     */
    private static final Map<String, List<String>> rollupNameAndDescriptionsBySummaryField = new Map<String, List<String>>();


    /*************************************************************************************************************
     * @description Create the 3 default Filter Groups used for Customizable Rollups using the legacy settings
     */
    public static void buildDefaultFilterGroups() {

        // ==============================================================================================================
        // Default "Donations: Close/Won Stage" filter group -- All Hard Credit, Soft Credit, and GAU Rollups
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupClosedWonDonations = new CRLP_RollupCMT.FilterGroup('Donations: Closed Won excluding RTs');
        groupClosedWonDonations.recordName = FilterGroup_Donations;
        groupClosedWonDonations.description = 'Closed/Won Non-Membership Opportunities for all Hard and Soft Credit Rollups. ' +
                'The additional filter rule for SoftCredit Donor Role is only applied when rolling up Soft Credits to the Account or Contact objects';

        CRLP_RollupCMT.FilterRule ruleCloseWonStage = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, 'Donations: CloseWon Only');
        ruleCloseWonStage.recordName = RecordNamePrefix + ruleCloseWonStage.recordName;
        ruleCloseWonStage.objectData = 'Opportunity.IsWon';
        ruleCloseWonStage.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage.value = 'true';
        groupClosedWonDonations.rules.add(ruleCloseWonStage);

        CRLP_RollupCMT.FilterRule ruleDonationsRecordType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, 'Donations: Excluded Record Types');
        ruleDonationsRecordType.recordName = RecordNamePrefix + ruleDonationsRecordType.recordName;
        ruleDonationsRecordType.objectData = 'Opportunity.RecordTypeId';
        ruleDonationsRecordType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
        ruleDonationsRecordType.value = convertExcludedRecordTypeIdsToDevNames(legacySettings.npo02__Excluded_Account_Opp_Rectypes__c, 'Membership');
        groupClosedWonDonations.rules.add(ruleDonationsRecordType);

        if (legacySettings.npo02__Excluded_Account_Opp_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, 'Donations: Excluded Opp.Type');
            ruleOppType.recordName = RecordNamePrefix + ruleOppType.recordName;
            ruleOppType.objectData = 'Opportunity.Type';
            ruleOppType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppType.value = legacySettings.npo02__Excluded_Account_Opp_Types__c;
            groupClosedWonDonations.rules.add(ruleOppType);
        }

        if (legacySettings.npo02__Soft_Credit_Roles__c != null) {
            CRLP_RollupCMT.FilterRule ruleSoftCreditRoles = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, 'Donations: Soft Credit Roles ');
            ruleSoftCreditRoles.recordName = RecordNamePrefix + ruleSoftCreditRoles.recordName;
            ruleSoftCreditRoles.objectData = SObjectType.Partial_Soft_Credit__c.getName() + '.' +  SObjectType.Partial_Soft_Credit__c.Fields.Role_Name__c.getName();
            ruleSoftCreditRoles.operation = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleSoftCreditRoles.value = legacySettings.npo02__Soft_Credit_Roles__c;
            groupClosedWonDonations.rules.add(ruleSoftCreditRoles);
        }

        // ==============================================================================================================
        // Default "Memberships: Close/Won Stage" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupMemberships = new CRLP_RollupCMT.FilterGroup('Membership: Closed Won excluding RTs');
        groupMemberships.description = 'Closed/Won Membership Opportunities for all Membership Rollups';
        groupMemberships.recordName = FilterGroup_Membership;

        CRLP_RollupCMT.FilterRule ruleCloseWonStage2 = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: CloseWon Only');
        ruleCloseWonStage2.recordName = RecordNamePrefix + ruleCloseWonStage2.recordName;
        ruleCloseWonStage2.objectData = 'Opportunity.IsWon';
        ruleCloseWonStage2.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage2.value = 'true';
        groupMemberships.rules.add(ruleCloseWonStage2);

        CRLP_RollupCMT.FilterRule ruleMembershipRecordType = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: for Record Type(s)');
        ruleMembershipRecordType.recordName = RecordNamePrefix + ruleMembershipRecordType.recordName;
        ruleMembershipRecordType.objectData = 'Opportunity.RecordTypeId';
        ruleMembershipRecordType.operation = CMT_FilterRule.FilterOperation.IN_LIST.name();
        ruleMembershipRecordType.value = convertExcludedRecordTypeIdsToDevNames(legacySettings.npo02__Membership_Record_Types__c, 'Membership');
        groupMemberships.rules.add(ruleMembershipRecordType);

        // ==============================================================================================================
        // Default "Allocations" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupAllocations = new CRLP_RollupCMT.FilterGroup('Allocations: Closed Won excluding RTs');
        groupAllocations.description = 'Closed/Won Opportunities for the Allocation to GAU Rollup';
        groupAllocations.recordName = FilterGroup_Allocations;

        CRLP_RollupCMT.FilterRule ruleCloseWonStage3 = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Allocations: CloseWon Only');
        ruleCloseWonStage3.recordName = RecordNamePrefix + ruleCloseWonStage3.recordName;
        ruleCloseWonStage3.objectData = 'Opportunity.IsWon';
        ruleCloseWonStage3.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage3.value = 'true';
        groupAllocations.rules.add(ruleCloseWonStage3);

        if (legacyAllocSettings.Excluded_Opp_RecTypes__c != null) {
            CRLP_RollupCMT.FilterRule ruleAllocationsRT = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Allocations: Excluded Record Types');
            ruleAllocationsRT.recordName = RecordNamePrefix + ruleAllocationsRT.recordName;
            ruleAllocationsRT.objectData = 'Opportunity.RecordTypeId';
            ruleAllocationsRT.operation = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleAllocationsRT.value = convertExcludedRecordTypeIdsToDevNames(legacyAllocSettings.Excluded_Opp_RecTypes__c, null);
            groupAllocations.rules.add(ruleAllocationsRT);
        }

        if (legacyAllocSettings.Excluded_Opp_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Memberships: Excluded Opp.Types');
            ruleOppType.recordName = RecordNamePrefix + ruleOppType.recordName;
            ruleOppType.objectData = 'Opportunity.Type';
            ruleOppType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppType.value = legacyAllocSettings.Excluded_Opp_Types__c;
            groupAllocations.rules.add(ruleOppType);
        }

        // ==============================================================================================================
        // Create a list of the default Groups+Rules to use for deployment
        // ==============================================================================================================

        List<CRLP_RollupCMT.FilterGroup> groups = new List<CRLP_RollupCMT.FilterGroup>{
                groupClosedWonDonations, groupMemberships, groupAllocations
        };

        // TODO -- Will these be deployed separately, or will this be combined with Rollups?
        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(groups);
    }

    /*************************************************************************************************************
     * @description Convert a legacy semi-colon separated list of Record Type Id's into a semi-colon list of
     * Record Type Developer Names. These are easier to 'read' (i.e., self-documenting) and more importantly it allows
     * for deploying a custom Filter Rule from a Sandbox to Production (where the Record Type Id might be different
     * if the RT was created in the Sandbox).
     * @param excludedRtIds semi-colon separatedlist of Record Type Id's
     * @param defRT If excludedRtIds is null, this record type developer name is always excluded (optional)
     * @return Semi-colon separated list of Record Type Developer Names
     */
    private static String convertExcludedRecordTypeIdsToDevNames(String excludedRtIds, String defRT) {
        Set<String> rtDevNames = new Set<String>();
        if (excludedRtIds != null) {
            for (String rtId : excludedRtIds.split(';')) {
                if (recordTypesById.containsKey(rtId)) {
                    rtDevNames.add(recordTypesById.get(rtId).DeveloperName);
                } else {
                    rtDevNames.add(rtId);
                }
            }
        } else if (defRT != null) {
            rtDevNames.add(defRT);   // default to this if there are no current exclusions
        }
        return String.join(new List<String>(rtDevNames), ';');
    }
}