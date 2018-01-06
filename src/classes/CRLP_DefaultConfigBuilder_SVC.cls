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

    private static final npo02__Households_Settings__c legacySettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();
    private static final Map<Id, RecordType> recordTypesById = new Map<Id, RecordType>([SELECT Id, RecordType.DeveloperName
            FROM RecordType WHERE SobjectType = 'Opportunity']);

    public static void buildDefaultFilterGroups() {

        // ==============================================================================================================
        // Create the default "Donations: Close/Won Stage" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupClosedWonDonations = new CRLP_RollupCMT.FilterGroup('Donations: Closed Won Stage');
        groupClosedWonDonations.description = 'All Opps in a Closed/Won state where the Record Type is not Membership';

        CRLP_RollupCMT.FilterRule ruleCloseWonStage = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, 'Donations: CloseWon');
        ruleCloseWonStage.objectData = 'Opportunity.IsWon';
        ruleCloseWonStage.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage.value = 'true';
        groupClosedWonDonations.rules.add(ruleCloseWonStage);

        CRLP_RollupCMT.FilterRule ruleDonationsRecordType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, 'Donations: Record Type');
        ruleDonationsRecordType.objectData = 'Opportunity.RecordTypeId';
        ruleDonationsRecordType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
        ruleDonationsRecordType.value = convertExcludedRecordTypeIdsToDevNames(legacySettings.npo02__Excluded_Account_Opp_Rectypes__c, 'Membership');
        groupClosedWonDonations.rules.add(ruleDonationsRecordType);

        if (legacySettings.npo02__Excluded_Account_Opp_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, 'Donations: Type');
            ruleOppType.objectData = 'Opportunity.Type';
            ruleOppType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppType.value = legacySettings.npo02__Excluded_Account_Opp_Types__c;
            groupClosedWonDonations.rules.add(ruleOppType);
        }

        if (legacySettings.npo02__Soft_Credit_Roles__c != null) {
            CRLP_RollupCMT.FilterRule ruleSoftCreditRoles = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, 'Donations: Soft Credit Roles');
            ruleSoftCreditRoles.objectData = SObjectType.Partial_Soft_Credit__c.getName() + '.' +  SObjectType.Partial_Soft_Credit__c.Fields.Role_Name__c.getName();
            ruleSoftCreditRoles.operation = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleSoftCreditRoles.value = legacySettings.npo02__Soft_Credit_Roles__c;
            groupClosedWonDonations.rules.add(ruleSoftCreditRoles);
        }

        // ==============================================================================================================
        // Create the default "Memberships: Close/Won Stage" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupMemberships = new CRLP_RollupCMT.FilterGroup('Membership: Closed Won Stage');
        groupClosedWonDonations.description = 'Membership Opportunities in a Closed/Won state';

        CRLP_RollupCMT.FilterRule ruleCloseWonStage2 = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: CloseWon');
        ruleCloseWonStage2.objectData = 'Opportunity.IsWon';
        ruleCloseWonStage2.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage2.value = 'true';
        groupMemberships.rules.add(ruleCloseWonStage2);

        CRLP_RollupCMT.FilterRule ruleMembershipRecordType = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: Record Type');
        ruleMembershipRecordType.objectData = 'Opportunity.RecordTypeId';
        ruleMembershipRecordType.operation = CMT_FilterRule.FilterOperation.IN_LIST.name();
        ruleMembershipRecordType.value = convertExcludedRecordTypeIdsToDevNames(legacySettings.npo02__Membership_Record_Types__c, 'Membership');
        groupMemberships.rules.add(ruleMembershipRecordType);

        List<CRLP_RollupCMT.FilterGroup> groups = new List<CRLP_RollupCMT.FilterGroup>{
                groupClosedWonDonations, groupMemberships
        };

        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(groups);
    }

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