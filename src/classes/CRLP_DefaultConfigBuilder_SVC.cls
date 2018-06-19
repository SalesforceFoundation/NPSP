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

    /** @description Use this Map of Opp RecordTypes by Id to convert the legacy settings into a DeveloperName for the Filter Rule */
    private static final Map<Id, RecordType> oppRecordTypesById = new Map<Id, RecordType>(
        [SELECT Id, RecordType.DeveloperName
            FROM RecordType
            WHERE SobjectType = 'Opportunity']);

    /*************************************************************************************************************
     * @description Call each of the methods in this class to build the default Filter Groups and each of the four
     * Rollup Types (Account Hard Credit/Membership, Contact Hard Credit/Membership, Contact Soft Credit, and GAU)
     */
    public static String convertLegacyRollupsIntoCustomizableRollups() {

        List<CRLP_RollupCMT.FilterGroup> filterGroups = buildDefaultFilterGroups();

        List<CRLP_RollupCMT.FilterRule> filterRulesToSoftDelete = softDeleteExtraFilterRulesInNPSPFilterGroups(filterGroups);
        List<CRLP_RollupCMT.FilterGroup> filterGroupsToSoftDelete = softDeleteExtraFilterGroupsAndRules(filterGroups);

        List<CRLP_RollupCMT.Rollup> rollups = new List<CRLP_RollupCMT.Rollup>();
        rollups.addAll(buildDefaultRollups());
        rollups.addAll(buildUserDefinedRollups());

        List<CRLP_RollupCMT.Rollup> rollupsToSoftDelete = softDeleteExtraRollups(rollups);

        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(filterGroups);
        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(rollups);

        if(!filterRulesToSoftDelete.isEmpty()){
            CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(filterRulesToSoftDelete);
        }
        if(!filterGroupsToSoftDelete.isEmpty()){
            CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(filterGroupsToSoftDelete);
        }
        if(!rollupsToSoftDelete.isEmpty()){
            CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(rollupsToSoftDelete);
        }

        String jobId = CRLP_ConfigBuilder_SVC.deployedQueuedMetadataTypes();
        return jobId;
    }

    /*************************************************************************************************************
     * @description Create the default Filter Groups used for Customizable Rollups using the legacy settings.
     * There are 3 at a minimum (ClosedWon Donations, ClosedWon Memberships, and CloseWon only), but if there are
     * different exclusion settings for Account vs. Contact in the legacy settings, then the "ClosedWon Donations"
     * filter group will be split into 2 different groups - one for Account and one for Contact.
     * @return List<FilterGroup> defined Filter Group wrapper classes; each containing a List<FilterRule>
     */
    private static List<CRLP_RollupCMT.FilterGroup> buildDefaultFilterGroups() {
        // Use these to differentiate Account from Contact filters if that is needed
        String acctOpp = 'Opps';
        String contOpp = 'Opps';
        String acctPmt = 'Pmts';
        String contPmt = 'Pmts';
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            acctOpp = acctOpp + '-Acct';
            contOpp = contOpp + '-Cont';
            acctPmt = acctPmt + '-Acct';
            contPmt = contPmt + '-Cont';
        }

        Boolean acctRTExclusionsExist = (CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c != null);
        Boolean conRTExclusionsExist = (CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c != null);
        Boolean acctOppTypeExclusionsExist = (CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c != null);
        Boolean conOppTypeExclusionsExist = (CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c != null);

        // ==============================================================================================================
        // Default "Donations: Close/Won Stage" filter group -- Hard Credit Rollups
        // ==============================================================================================================

        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsHC = new CRLP_RollupCMT.FilterGroup(acctOpp +': Won (HC)' + (acctRTExclusionsExist ? ' Excl RecTypes' : ''));
        groupClosedWonDonationsHC.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Opps_Accounts_HC;
        groupClosedWonDonationsHC.description = 'Won Opportunities for '+ (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded ? 'Account ' : '')+ 'Hard Credit Rollups.' +
                (acctRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
        groupClosedWonDonationsHC.isDeleted = false;

        CRLP_RollupCMT.FilterRule ruleCloseWonStageHC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsHC.recordName, acctOpp +': Won Only (HC)');
        ruleCloseWonStageHC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStageHC.recordName;
        ruleCloseWonStageHC.objectName = 'Opportunity';
        ruleCloseWonStageHC.fieldName = 'IsWon';
        ruleCloseWonStageHC.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStageHC.value = 'true';
        ruleCloseWonStageHC.isDeleted = false;
        groupClosedWonDonationsHC.rules.add(ruleCloseWonStageHC);

        CRLP_RollupCMT.FilterRule ruleAmountNotNullHC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsHC.recordName, acctOpp +': Amount Not Null (HC)');
        ruleAmountNotNullHC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleAmountNotNullHC.recordName;
        ruleAmountNotNullHC.objectName = 'Opportunity';
        ruleAmountNotNullHC.fieldName = 'Amount';
        ruleAmountNotNullHC.operationName = CMT_FilterRule.FilterOperation.NOT_EQUALS.name();
        ruleAmountNotNullHC.value = null;
        ruleAmountNotNullHC.isDeleted = false;
        groupClosedWonDonationsHC.rules.add(ruleAmountNotNullHC);

        if (acctRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordTypeHC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsHC.recordName, acctOpp + ': Excl RT (HC)');
            ruleRecordTypeHC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypeHC.recordName;
            ruleRecordTypeHC.objectName = 'Opportunity';
            ruleRecordTypeHC.fieldName = 'RecordTypeId';
            ruleRecordTypeHC.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordTypeHC.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c);
            ruleRecordTypeHC.isDeleted = false;
            groupClosedWonDonationsHC.rules.add(ruleRecordTypeHC);
        }

        if (acctOppTypeExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleOppTypeHC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsHC.recordName, acctOpp +': Excl Opp.Type (HC)');
            ruleOppTypeHC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypeHC.recordName;
            ruleOppTypeHC.objectName = 'Opportunity';
            ruleOppTypeHC.fieldName = 'Type';
            ruleOppTypeHC.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppTypeHC.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c;
            ruleOppTypeHC.isDeleted = false;
            groupClosedWonDonationsHC.rules.add(ruleOppTypeHC);
        }

        // If there is a need to create another Filter Group for Contacts that is different than Accounts ...
        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsContactsHC;
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            // ==============================================================================================================
            // Default "Donations: Close/Won Stage" filter group -- Hard Credit Rollups CONTACTS ONLY
            // ==============================================================================================================
            groupClosedWonDonationsContactsHC = new CRLP_RollupCMT.FilterGroup(contOpp +': Won (HC)' + (conRTExclusionsExist ? ' Excl RecTypes' : ''));
            groupClosedWonDonationsContactsHC.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Opps_Contacts_HC;
            groupClosedWonDonationsContactsHC.description = 'Won Opportunities for Contact Hard Credit Rollups.' +
                    (conRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
            groupClosedWonDonationsContactsHC.isDeleted = false;

            CRLP_RollupCMT.FilterRule ruleCloseWonStage1HC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsHC.recordName, contOpp +': Won Only (HC)');
            ruleCloseWonStage1HC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage1HC.recordName;
            ruleCloseWonStage1HC.objectName = 'Opportunity';
            ruleCloseWonStage1HC.fieldName = 'IsWon';
            ruleCloseWonStage1HC.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
            ruleCloseWonStage1HC.value = 'true';
            ruleCloseWonStage1HC.isDeleted = false;
            groupClosedWonDonationsContactsHC.rules.add(ruleCloseWonStage1HC);

            CRLP_RollupCMT.FilterRule ruleAmountNotNullConHC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsHC.recordName, contOpp +': Amount Not Null (HC)');
            ruleAmountNotNullConHC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleAmountNotNullConHC.recordName;
            ruleAmountNotNullConHC.objectName = 'Opportunity';
            ruleAmountNotNullConHC.fieldName = 'Amount';
            ruleAmountNotNullConHC.operationName = CMT_FilterRule.FilterOperation.NOT_EQUALS.name();
            ruleAmountNotNullConHC.value = null;
            ruleAmountNotNullConHC.isDeleted = false;
            groupClosedWonDonationsContactsHC.rules.add(ruleAmountNotNullConHC);

            if (conRTExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleRecordTypeConHC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsHC.recordName, contOpp +': Excl RT (HC)');
                ruleRecordTypeConHC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypeConHC.recordName;
                ruleRecordTypeConHC.objectName = 'Opportunity';
                ruleRecordTypeConHC.fieldName = 'RecordTypeId';
                ruleRecordTypeConHC.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleRecordTypeConHC.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c);
                ruleRecordTypeConHC.isDeleted = false;
                groupClosedWonDonationsContactsHC.rules.add(ruleRecordTypeConHC);
            }

            if (conOppTypeExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleOppTypeConHC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsHC.recordName, contOpp +': Excl Opp.Type (HC)');
                ruleOppTypeConHC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypeConHC.recordName;
                ruleOppTypeConHC.objectName = 'Opportunity';
                ruleOppTypeConHC.fieldName = 'Type';
                ruleOppTypeConHC.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleOppTypeConHC.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c;
                ruleOppTypeConHC.isDeleted = false;
                groupClosedWonDonationsContactsHC.rules.add(ruleOppTypeConHC);
            }

        }

        // ==============================================================================================================
        // Default "Donations: Close/Won Stage" filter group -- Soft Credit Rollups
        // ==============================================================================================================

        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsSC = new CRLP_RollupCMT.FilterGroup(acctOpp +': Won (SC)' + (acctRTExclusionsExist ? ' Excl RecTypes' : ''));
        groupClosedWonDonationsSC.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Opps_Accounts_SC;
        groupClosedWonDonationsSC.description = 'Won Opportunities for '+ (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded ? 'Account ' : '')+ 'Soft Credit Rollups.' +
                (acctRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
        groupClosedWonDonationsSC.isDeleted = false;

        CRLP_RollupCMT.FilterRule ruleCloseWonStageSC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsSC.recordName, acctOpp +': Won Only (SC)');
        ruleCloseWonStageSC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStageSC.recordName;
        ruleCloseWonStageSC.objectName = 'Opportunity';
        ruleCloseWonStageSC.fieldName = 'IsWon';
        ruleCloseWonStageSC.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStageSC.value = 'true';
        ruleCloseWonStageSC.isDeleted = false;
        groupClosedWonDonationsSC.rules.add(ruleCloseWonStageSC);

        CRLP_RollupCMT.FilterRule ruleAmountNotNullSC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsSC.recordName, acctOpp +': Amount Not Null (SC)');
        ruleAmountNotNullSC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleAmountNotNullSC.recordName;
        ruleAmountNotNullSC.objectName = 'Opportunity';
        ruleAmountNotNullSC.fieldName = 'Amount';
        ruleAmountNotNullSC.operationName = CMT_FilterRule.FilterOperation.NOT_EQUALS.name();
        ruleAmountNotNullSC.value = null;
        ruleAmountNotNullSC.isDeleted = false;
        groupClosedWonDonationsSC.rules.add(ruleAmountNotNullSC);

        if (acctRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordTypeSC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsSC.recordName, acctOpp + ': Excl RT (SC)');
            ruleRecordTypeSC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypeSC.recordName;
            ruleRecordTypeSC.objectName = 'Opportunity';
            ruleRecordTypeSC.fieldName = 'RecordTypeId';
            ruleRecordTypeSC.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordTypeSC.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c);
            ruleRecordTypeSC.isDeleted = false;
            groupClosedWonDonationsSC.rules.add(ruleRecordTypeSC);
        }

        if (acctOppTypeExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleOppTypeSC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsSC.recordName, acctOpp +': Excl Opp.Type (SC)');
            ruleOppTypeSC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypeSC.recordName;
            ruleOppTypeSC.objectName = 'Opportunity';
            ruleOppTypeSC.fieldName = 'Type';
            ruleOppTypeSC.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppTypeSC.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c;
            ruleOppTypeSC.isDeleted = false;
            groupClosedWonDonationsSC.rules.add(ruleOppTypeSC);
        }

        if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c != null) {
            CRLP_RollupCMT.FilterRule ruleSoftCreditRoles = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsSC.recordName, acctOpp +': Soft Credit Roles ');
            ruleSoftCreditRoles.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleSoftCreditRoles.recordName;
            ruleSoftCreditRoles.objectName = SObjectType.Partial_Soft_Credit__c.getName();
            ruleSoftCreditRoles.fieldName = SObjectType.Partial_Soft_Credit__c.Fields.Role_Name__c.getName();
            ruleSoftCreditRoles.operationName = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleSoftCreditRoles.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c;
            ruleSoftCreditRoles.isDeleted = false;
            groupClosedWonDonationsSC.rules.add(ruleSoftCreditRoles);
        }

        // If there is a need to create another Filter Group for Contacts that is different than Accounts ...
        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsContactsSC;
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            // ==============================================================================================================
            // Default "Donations: Close/Won Stage" filter group -- Soft Credit Rollups CONTACTS ONLY
            // ==============================================================================================================
            groupClosedWonDonationsContactsSC = new CRLP_RollupCMT.FilterGroup(contOpp +': Won (SC)' + (conRTExclusionsExist ? ' Excl RecTypes' : ''));
            groupClosedWonDonationsContactsSC.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Opps_Contacts_SC;
            groupClosedWonDonationsContactsSC.description = 'Won Opportunities for Contact Soft Credit Rollups.' +
                    (conRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
            groupClosedWonDonationsContactsSC.isDeleted = false;

            CRLP_RollupCMT.FilterRule ruleCloseWonStageConSC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsSC.recordName, contOpp +': Won Only (SC)');
            ruleCloseWonStageConSC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStageConSC.recordName;
            ruleCloseWonStageConSC.objectName = 'Opportunity';
            ruleCloseWonStageConSC.fieldName = 'IsWon';
            ruleCloseWonStageConSC.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
            ruleCloseWonStageConSC.value = 'true';
            ruleCloseWonStageConSC.isDeleted = false;
            groupClosedWonDonationsContactsSC.rules.add(ruleCloseWonStageConSC);

            CRLP_RollupCMT.FilterRule ruleAmountNotNullConSC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsSC.recordName, contOpp +': Amount Not Null (SC)');
            ruleAmountNotNullConSC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleAmountNotNullConSC.recordName;
            ruleAmountNotNullConSC.objectName = 'Opportunity';
            ruleAmountNotNullConSC.fieldName = 'Amount';
            ruleAmountNotNullConSC.operationName = CMT_FilterRule.FilterOperation.NOT_EQUALS.name();
            ruleAmountNotNullConSC.value = null;
            ruleAmountNotNullConSC.isDeleted = false;
            groupClosedWonDonationsContactsSC.rules.add(ruleAmountNotNullConSC);

            if (conRTExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleRecordTypeConSC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsSC.recordName, contOpp +': Excluded RT (SC)');
                ruleRecordTypeConSC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypeConSC.recordName;
                ruleRecordTypeConSC.objectName = 'Opportunity';
                ruleRecordTypeConSC.fieldName = 'RecordTypeId';
                ruleRecordTypeConSC.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleRecordTypeConSC.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c);
                ruleRecordTypeConSC.isDeleted = false;
                groupClosedWonDonationsContactsSC.rules.add(ruleRecordTypeConSC);
            }

            if (conOppTypeExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleOppTypeConSC = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsSC.recordName, contOpp +': Excluded Opp.Type (SC)');
                ruleOppTypeConSC.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypeConSC.recordName;
                ruleOppTypeConSC.objectName = 'Opportunity';
                ruleOppTypeConSC.fieldName = 'Type';
                ruleOppTypeConSC.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleOppTypeConSC.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c;
                ruleOppTypeConSC.isDeleted = false;
                groupClosedWonDonationsContactsSC.rules.add(ruleOppTypeConSC);
            }

            if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c != null) {
                CRLP_RollupCMT.FilterRule ruleSoftCreditRolesCon = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContactsSC.recordName, contOpp +': Soft Credit Roles');
                ruleSoftCreditRolesCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleSoftCreditRolesCon.recordName;
                ruleSoftCreditRolesCon.objectName = SObjectType.Partial_Soft_Credit__c.getName();
                ruleSoftCreditRolesCon.fieldName = SObjectType.Partial_Soft_Credit__c.Fields.Role_Name__c.getName();
                ruleSoftCreditRolesCon.operationName = CMT_FilterRule.FilterOperation.IN_LIST.name();
                ruleSoftCreditRolesCon.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c;
                ruleSoftCreditRolesCon.isDeleted = false;
                groupClosedWonDonationsContactsSC.rules.add(ruleSoftCreditRolesCon);
            }
        }

        // ==============================================================================================================
        // Default "Memberships: Close/Won Stage" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupMemberships = new CRLP_RollupCMT.FilterGroup('Memberships: Won');
        groupMemberships.description = 'Won Membership Opportunities used for all Membership Rollups. Record Types as defined in legacy NPSP Membership Settings.';
        groupMemberships.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Membership;
        groupMemberships.isDeleted = false;

        CRLP_RollupCMT.FilterRule ruleCloseWonStage2 = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: Won Only');
        ruleCloseWonStage2.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage2.recordName;
        ruleCloseWonStage2.objectName = 'Opportunity';
        ruleCloseWonStage2.fieldName = 'IsWon';
        ruleCloseWonStage2.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage2.value = 'true';
        ruleCloseWonStage2.isDeleted = false;
        groupMemberships.rules.add(ruleCloseWonStage2);

        CRLP_RollupCMT.FilterRule ruleAmountNotNullMembership = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: Amount Not Null');
        ruleAmountNotNullMembership.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleAmountNotNullMembership.recordName;
        ruleAmountNotNullMembership.objectName = 'Opportunity';
        ruleAmountNotNullMembership.fieldName = 'Amount';
        ruleAmountNotNullMembership.operationName = CMT_FilterRule.FilterOperation.NOT_EQUALS.name();
        ruleAmountNotNullMembership.value = null;
        ruleAmountNotNullMembership.isDeleted = false;
        groupMemberships.rules.add(ruleAmountNotNullMembership);

        if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Membership_Record_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: for Record Types');
            ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
            ruleRecordType.objectName = 'Opportunity';
            ruleRecordType.fieldName = 'RecordTypeId';
            ruleRecordType.operationName = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleRecordType.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Membership_Record_Types__c);
            ruleRecordType.isDeleted = false;
            groupMemberships.rules.add(ruleRecordType);
        }

        // ==============================================================================================================
        // Default "Allocations" filter group
        // ==============================================================================================================

        Boolean alloRTExclusionsExist = (CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_RecTypes__c != null);

        CRLP_RollupCMT.FilterGroup groupAllocations = new CRLP_RollupCMT.FilterGroup('Allocations: Won' + (alloRTExclusionsExist ? ' excluding Rec Types' : ''));
        groupAllocations.description = 'Closed/Won Opportunities used for GAU Allocation to General Accounting Unit rollups.' + (alloRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
        groupAllocations.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Allocations;
        groupAllocations.isDeleted = false;

        CRLP_RollupCMT.FilterRule ruleCloseWonStageAllo = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Allocations: Won Only');
        ruleCloseWonStageAllo.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStageAllo.recordName;
        ruleCloseWonStageAllo.objectName = 'Opportunity';
        ruleCloseWonStageAllo.fieldName = 'IsWon';
        ruleCloseWonStageAllo.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStageAllo.value = 'true';
        ruleCloseWonStageAllo.isDeleted = false;
        groupAllocations.rules.add(ruleCloseWonStageAllo);

        if (alloRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Allocations: Excluded Record Types');
            ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
            ruleRecordType.objectName = 'Opportunity';
            ruleRecordType.fieldName = 'RecordTypeId';
            ruleRecordType.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordType.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_RecTypes__c);
            ruleRecordType.isDeleted = false;
            groupAllocations.rules.add(ruleRecordType);
        }

        if (CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Memberships: Excluded Opp.Types');
            ruleOppType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppType.recordName;
            ruleOppType.objectName = 'Opportunity';
            ruleOppType.fieldName = 'Type';
            ruleOppType.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppType.value = CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_Types__c;
            ruleOppType.isDeleted = false;
            groupAllocations.rules.add(ruleOppType);
        }

        // ==============================================================================================================
        // Default "Opportunities: Open" filter group -- Recurring Donations Rollups
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupOpenDonations = new CRLP_RollupCMT.FilterGroup('Opps: Open');
        groupOpenDonations.recordName = CRLP_DefaultConfigBuilder.FilterGroup_OpenOpps;
        groupOpenDonations.description = 'All open Opportunities';
        groupOpenDonations.isDeleted = false;

        CRLP_RollupCMT.FilterRule ruleOpenStage = new CRLP_RollupCMT.FilterRule(groupOpenDonations.recordName, 'Opps: Not Closed Only');
        ruleOpenStage.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOpenStage.recordName;
        ruleOpenStage.objectName = 'Opportunity';
        ruleOpenStage.fieldName = 'isClosed';
        ruleOpenStage.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleOpenStage.value = 'false';
        ruleOpenStage.isDeleted = false;
        groupOpenDonations.rules.add(ruleOpenStage);
    
        // ==============================================================================================================
        // Default "Donations: Close/Won Stage WITHOUT RT Exclusions" filter group -- Recurring Donations Rollups
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsNoRTExclusions = new CRLP_RollupCMT.FilterGroup('Opps: Won (Recurring Donations)');
        groupClosedWonDonationsNoRTExclusions.recordName = CRLP_DefaultConfigBuilder.FilterGroup_ClosedWonOpps_NoRTExclusions;
        groupClosedWonDonationsNoRTExclusions.description = 'Won Opportunities used for Recurring Donations Rollups.';
        groupClosedWonDonationsNoRTExclusions.isDeleted = false;

        CRLP_RollupCMT.FilterRule ruleCloseWonStageRD = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsNoRTExclusions.recordName, 'Opps: Won Only (RD)');
        ruleCloseWonStageRD.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStageRD.recordName;
        ruleCloseWonStageRD.objectName = 'Opportunity';
        ruleCloseWonStageRD.fieldName = 'IsWon';
        ruleCloseWonStageRD.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStageRD.value = 'true';
        ruleCloseWonStageRD.isDeleted = false;
        groupClosedWonDonationsNoRTExclusions.rules.add(ruleCloseWonStageRD);

        // ==============================================================================================================
        // Default "Payments: Paid" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupPaymentsPaid = new CRLP_RollupCMT.FilterGroup(acctPmt + ': Paid' + ( acctRTExclusionsExist ? ' Excl Rec Types' : ''));
        groupPaymentsPaid.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsPaid;
        groupPaymentsPaid.description = 'All paid Payments.'+
                (acctRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
        groupPaymentsPaid.isDeleted = false;

        CRLP_RollupCMT.FilterRule rulePaid = new CRLP_RollupCMT.FilterRule(groupPaymentsPaid.recordName, acctPmt + ': Paid Only');
        rulePaid.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + rulePaid.recordName;
        rulePaid.objectName = 'npe01__OppPayment__c';
        rulePaid.fieldName = 'npe01__Paid__c';
        rulePaid.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        rulePaid.value = 'true';
        rulePaid.isDeleted = false;
        groupPaymentsPaid.rules.add(rulePaid);

        if (acctRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordTypePaid = new CRLP_RollupCMT.FilterRule(groupPaymentsPaid.recordName, acctPmt + ': Excl RT (Paid)');
            ruleRecordTypePaid.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypePaid.recordName;
            ruleRecordTypePaid.objectName = 'Opportunity';
            ruleRecordTypePaid.fieldName = 'RecordTypeId';
            ruleRecordTypePaid.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordTypePaid.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c);
            ruleRecordTypePaid.isDeleted = false;
            groupPaymentsPaid.rules.add(ruleRecordTypePaid);
        }

        if (acctOppTypeExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleOppTypePaid = new CRLP_RollupCMT.FilterRule(groupPaymentsPaid.recordName, acctPmt +': Excl Opp.Type (Paid)');
            ruleOppTypePaid.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypePaid.recordName;
            ruleOppTypePaid.objectName = 'Opportunity';
            ruleOppTypePaid.fieldName = 'Type';
            ruleOppTypePaid.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppTypePaid.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c;
            ruleOppTypePaid.isDeleted = false;
            groupPaymentsPaid.rules.add(ruleOppTypePaid);
        }

        // If there is a need to create another Filter Group for Contacts that is different than Accounts ...
        CRLP_RollupCMT.FilterGroup groupPaymentsPaidContacts;
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            // ==============================================================================================================
            // Default "Payments: Paid" filter group CONTACTS ONLY
            // ==============================================================================================================
            groupPaymentsPaidContacts = new CRLP_RollupCMT.FilterGroup(contPmt + ': Paid' + ( conRTExclusionsExist ? ' Excl Rec Types' : ''));
            groupPaymentsPaidContacts.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsPaid_Contacts;
            groupPaymentsPaidContacts.description = 'All paid Payments.'+
                    (conRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
            groupPaymentsPaidContacts.isDeleted = false;

            CRLP_RollupCMT.FilterRule rulePaidCon = new CRLP_RollupCMT.FilterRule(groupPaymentsPaidContacts.recordName, contPmt + ': Paid Only');
            rulePaidCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + rulePaid.recordName;
            rulePaidCon.objectName = 'npe01__OppPayment__c';
            rulePaidCon.fieldName = 'npe01__Paid__c';
            rulePaidCon.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
            rulePaidCon.value = 'true';
            rulePaidCon.isDeleted = false;
            groupPaymentsPaidContacts.rules.add(rulePaidCon);

            if (conRTExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleRecordTypePaidCon = new CRLP_RollupCMT.FilterRule(groupPaymentsPaid.recordName, contPmt + ': Excl RT (Paid)');
                ruleRecordTypePaidCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypePaidCon.recordName;
                ruleRecordTypePaidCon.objectName = 'Opportunity';
                ruleRecordTypePaidCon.fieldName = 'RecordTypeId';
                ruleRecordTypePaidCon.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleRecordTypePaidCon.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c);
                ruleRecordTypePaidCon.isDeleted = false;
                groupPaymentsPaidContacts.rules.add(ruleRecordTypePaidCon);
            }

            if (conOppTypeExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleOppTypePaidCon = new CRLP_RollupCMT.FilterRule(groupPaymentsPaidContacts.recordName, contPmt +': Excl Opp.Type (Paid)');
                ruleOppTypePaidCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypePaidCon.recordName;
                ruleOppTypePaidCon.objectName = 'Opportunity';
                ruleOppTypePaidCon.fieldName = 'Type';
                ruleOppTypePaidCon.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleOppTypePaidCon.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c;
                ruleOppTypePaidCon.isDeleted = false;
                groupPaymentsPaidContacts.rules.add(ruleOppTypePaidCon);
            }

        }

        // ==============================================================================================================
        // Default "Payments: Written Off" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupPaymentsWrittenOff = new CRLP_RollupCMT.FilterGroup(acctPmt + ': WrittenOff' + ( acctRTExclusionsExist ? ' Excl Rec Types' : ''));
        groupPaymentsWrittenOff.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsWrittenOff;
        groupPaymentsWrittenOff.description = 'All written off Payments.';
        groupPaymentsWrittenOff.isDeleted = false;

        CRLP_RollupCMT.FilterRule ruleWrittenOff = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOff.recordName, acctPmt + ': Written Off Only');
        ruleWrittenOff.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleWrittenOff.recordName;
        ruleWrittenOff.objectName = 'npe01__OppPayment__c';
        ruleWrittenOff.fieldName = 'npe01__Written_Off__c';
        ruleWrittenOff.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleWrittenOff.value = 'true';
        ruleWrittenOff.isDeleted = false;
        groupPaymentsWrittenOff.rules.add(ruleWrittenOff);

        if (acctRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordTypeWrittenOff = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOff.recordName, acctPmt + ': Excl RT (Written Off)');
            ruleRecordTypeWrittenOff.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypeWrittenOff.recordName;
            ruleRecordTypeWrittenOff.objectName = 'Opportunity';
            ruleRecordTypeWrittenOff.fieldName = 'RecordTypeId';
            ruleRecordTypeWrittenOff.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordTypeWrittenOff.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c);
            ruleRecordTypeWrittenOff.isDeleted = false;
            groupPaymentsWrittenOff.rules.add(ruleRecordTypeWrittenOff);
        }

        if (acctOppTypeExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleOppTypeWrittenOff = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOff.recordName, acctPmt +': Excl Opp.Type (Written Off)');
            ruleOppTypeWrittenOff.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypeWrittenOff.recordName;
            ruleOppTypeWrittenOff.objectName = 'Opportunity';
            ruleOppTypeWrittenOff.fieldName = 'Type';
            ruleOppTypeWrittenOff.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppTypeWrittenOff.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c;
            ruleOppTypeWrittenOff.isDeleted = false;
            groupPaymentsWrittenOff.rules.add(ruleOppTypeWrittenOff);
        }

        // If there is a need to create another Filter Group for Contacts that is different than Accounts ...
        CRLP_RollupCMT.FilterGroup groupPaymentsWrittenOffContacts;
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            // ==============================================================================================================
            // Default "Payments: Written Off" filter group CONTACTS ONLY
            // ==============================================================================================================
            groupPaymentsWrittenOffContacts = new CRLP_RollupCMT.FilterGroup(contPmt + ': WrittenOff' + ( conRTExclusionsExist ? ' Excl Rec Types' : ''));
            groupPaymentsWrittenOffContacts.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsWrittenOff_Contacts;
            groupPaymentsWrittenOffContacts.description = 'All written off Payments.'+
                    (conRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
            groupPaymentsWrittenOffContacts.isDeleted = false;

            CRLP_RollupCMT.FilterRule ruleWrittenOffCon = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOffContacts.recordName, contPmt + ': Written Off Only');
            ruleWrittenOffCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleWrittenOffCon.recordName;
            ruleWrittenOffCon.objectName = 'npe01__OppPayment__c';
            ruleWrittenOffCon.fieldName = 'npe01__Written_Off__c';
            ruleWrittenOffCon.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
            ruleWrittenOffCon.value = 'true';
            ruleWrittenOffCon.isDeleted = false;
            groupPaymentsWrittenOffContacts.rules.add(ruleWrittenOffCon);

            if (conRTExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleRecordTypeWrittenOffCon = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOffContacts.recordName, contPmt + ': Excl RT (Written Off)');
                ruleRecordTypeWrittenOffCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypeWrittenOffCon.recordName;
                ruleRecordTypeWrittenOffCon.objectName = 'Opportunity';
                ruleRecordTypeWrittenOffCon.fieldName = 'RecordTypeId';
                ruleRecordTypeWrittenOffCon.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleRecordTypeWrittenOffCon.value = convertRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c);
                ruleRecordTypeWrittenOffCon.isDeleted = false;
                groupPaymentsWrittenOffContacts.rules.add(ruleRecordTypeWrittenOffCon);
            }

            if (conOppTypeExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleOppTypeWrittenOffCon = new CRLP_RollupCMT.FilterRule(groupPaymentsPaidContacts.recordName, contPmt +': Excl Opp.Type (Written Off)');
                ruleOppTypeWrittenOffCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypeWrittenOffCon.recordName;
                ruleOppTypeWrittenOffCon.objectName = 'Opportunity';
                ruleOppTypeWrittenOffCon.fieldName = 'Type';
                ruleOppTypeWrittenOffCon.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleOppTypeWrittenOffCon.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c;
                ruleOppTypeWrittenOffCon.isDeleted = false;
                groupPaymentsWrittenOffContacts.rules.add(ruleOppTypeWrittenOffCon);
            }

        }

        // ==============================================================================================================
        // Create a list of the default Groups+Rules to use for deployment
        // ==============================================================================================================

        List<CRLP_RollupCMT.FilterGroup> groups = new List<CRLP_RollupCMT.FilterGroup>{
                groupClosedWonDonationsHC,
                groupClosedWonDonationsSC,
                groupMemberships,
                groupAllocations,
                groupOpenDonations,
                groupClosedWonDonationsNoRTExclusions,
                groupPaymentsPaid,
                groupPaymentsWrittenOff
        };
        if (groupClosedWonDonationsContactsHC != null) {
            groups.add(groupClosedWonDonationsContactsHC);
        }
        if (groupClosedWonDonationsContactsSC != null) {
            groups.add(groupClosedWonDonationsContactsSC);
        }
        if (groupPaymentsPaidContacts != null) {
            groups.add(groupPaymentsPaidContacts);
        }
        if (groupPaymentsWrittenOffContacts != null) {
            groups.add(groupPaymentsWrittenOffContacts);
        }

        return groups;
    }

    /*************************************************************************************************************
     * @description Soft deletes all extra Filter Rules in the NPSP Filter Groups upon CRLP Reset
     * @param List<FilterGroup> the default Filter Groups (wrapper classes) with their lists of default Filter Rules
     * @return List<FilterRule> defined Filter Rule wrapper classes
     */
    private static List<CRLP_RollupCMT.FilterRule> softDeleteExtraFilterRulesInNPSPFilterGroups(List<CRLP_RollupCMT.FilterGroup> groups) {

        List<CRLP_RollupCMT.FilterRule> rulesToSoftDelete = new List<CRLP_RollupCMT.FilterRule>();
        List<Filter_Rule__mdt> allExistingRules = CMT_FilterRule_SEL.getFilterRules();

        // only proceed if there are existing rules to compare to
        if (!allExistingRules.isEmpty()) {

            Set<String> defaultRuleNames = new Set<String>();
            Set<String> defaultGroupNames = new Set<String>();
            for (CRLP_RollupCMT.FilterGroup grp : groups) {
                defaultGroupNames.add(grp.recordName);
                for (CRLP_RollupCMT.FilterRule rule : grp.rules) {
                    defaultRuleNames.add(rule.recordName);
                }
            }

            for (Filter_Rule__mdt rule : allExistingRules) {
                if (!defaultRuleNames.contains(rule.DeveloperName) && defaultGroupNames.contains(rule.Filter_Group__r.DeveloperName)) {
                    CRLP_RollupCMT.FilterRule ruleToDelete = new CRLP_RollupCMT.FilterRule(rule);
                    ruleToDelete.isDeleted = true;
                    rulesToSoftDelete.add(ruleToDelete);
                }
            }
        }

        return rulesToSoftDelete;
    }

    /*************************************************************************************************************
    * @description Soft deletes all extra Filter Groups and their Filter Rules upon CRLP Reset
    * @param List<FilterGroup> the default Filter Groups (wrapper classes)
    * @return List<FilterGroup> defined Filter Group wrapper classes with their Filter Rules
    */
    private static List<CRLP_RollupCMT.FilterGroup> softDeleteExtraFilterGroupsAndRules(List<CRLP_RollupCMT.FilterGroup> groups) {

        List<CRLP_RollupCMT.FilterGroup> groupsToSoftDelete = new List<CRLP_RollupCMT.FilterGroup>();
        List<Filter_Group__mdt> allExistingGroups = CMT_FilterRule_SEL.getFilterGroups();

        // only proceed if there are existing groups to compare to
        if (!allExistingGroups.isEmpty()) {

            Set<String> defaultGroupNames = new Set<String>();
            for (CRLP_RollupCMT.FilterGroup grp : groups) {
                defaultGroupNames.add(grp.recordName);
            }

            for (Filter_Group__mdt grp : allExistingGroups) {
                if (!defaultGroupNames.contains(grp.DeveloperName)) {
                    CRLP_RollupCMT.FilterGroup groupToDelete = new CRLP_RollupCMT.FilterGroup(grp);
                    groupToDelete.isDeleted = true;
                    for (CRLP_RollupCMT.FilterRule rule : groupToDelete.rules) {
                        rule.isDeleted = true;
                    }
                    groupsToSoftDelete.add(groupToDelete);
                }
            }
        }

        return groupsToSoftDelete;
    }

    /*************************************************************************************************************
     * @description Soft deletes all extra Rollups upon CRLP Reset
     * @param List<Rollup> the default Rollups (wrapper classes)
     * @return List<Rollup> defined Rollup wrapper classes
     */
    private static List<CRLP_RollupCMT.Rollup> softDeleteExtraRollups(List<CRLP_RollupCMT.Rollup> rollups) {

        List<CRLP_RollupCMT.Rollup> rollupsToSoftDelete = new List<CRLP_RollupCMT.Rollup>();

        List<Rollup__mdt> allExistingRollups = CRLP_Rollup_SEL.getRollupDefinitions();

        // only proceed if there are existing rollups to compare to
        if (!allExistingRollups.isEmpty()) {

            Set<String> defaultRollupNames = new Set<String>();
            for (CRLP_RollupCMT.Rollup rlp : rollups) {
                defaultRollupNames.add(rlp.recordName);
            }


            for (Rollup__mdt rollup : allExistingRollups) {
                if (!defaultRollupNames.contains(rollup.DeveloperName)) {
                    CRLP_RollupCMT.Rollup rollupToDelete = new CRLP_RollupCMT.Rollup(rollup);
                    rollupToDelete.isDeleted = true;
                    rollupsToSoftDelete.add(rollupToDelete);
                }
            }
        }

        return rollupsToSoftDelete;
    }

    /*************************************************************************************************************
     * @description Create the default Customizable Rollups for all standard NPSP rollup fields using the
     * maps defined in the CRLP_DefaultConfigBuilder class.
     * @return List<Rollup> defined Rollup wrapper classes
     */
    private static List<CRLP_RollupCMT.Rollup> buildDefaultRollups() {
        List<CRLP_RollupCMT.Rollup> rollups = new List<CRLP_RollupCMT.Rollup>();

        String gauObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('General_Accounting_Unit__c')).getName();
        String rdObjectName = UTIL_Describe.getObjectDescribe('npe03__Recurring_Donation__c').getName();

        // rollupDetailsBySummaryField list data:
        // 0 = DetailObject.Field
        // 1 = FilterGroupRecordName,
        // 2 = AmountObject.Field,
        // 3 = DateObject.Field,
        // 4 = OperationString,
        // 5 = TimeBoundOperationString,
        // 6 = IntValue

        for (String summaryObjectField : CRLP_DefaultConfigBuilder.rollupDetailsBySummaryField.keySet()) {
            List<String> rollupDetails = CRLP_DefaultConfigBuilder.rollupDetailsBySummaryField.get(summaryObjectField);
            List<String> rollupText = CRLP_DefaultConfigBuilder.rollupNameAndDescriptionsBySummaryField.get(summaryObjectField);
            CRLP_RollupCMT.Rollup rollup = new CRLP_RollupCMT.Rollup(rollupText[0]);

            rollup.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + rollup.recordName;
            rollup.description = rollupText[1];
            rollup.filterGroupRecordName = rollupDetails[1];
            rollup.summaryObject = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(summaryObjectField)[0]);
            rollup.summaryField = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(summaryObjectField)[1]);
            rollup.detailObject = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[0])[0]);
            rollup.detailField = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[0])[1]);
            rollup.amountObject = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[2])[0]);
            rollup.amountField = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[2])[1]);
            rollup.dateObject = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[3])[0]);
            rollup.dateField = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[3])[1]);
            rollup.operation = rollupDetails[4];
            rollup.timeBoundOperationType = rollupDetails[5];

            // Set the UseFiscalYear based on the type of rollup being done
            if (rollup.summaryObject == gauObjectName) {
                rollup.useFiscalYear = CRLP_DefaultConfigBuilder.legacyAllocSettings.Use_Fiscal_Year_for_Rollups__c;
            } else if (rollup.summaryObject == rdObjectName) {
                // Out of the box Recurring Donation rollups do not use FiscalYear (primariliy not needed anyway)
                rollup.useFiscalYear = false;
            } else {
                rollup.useFiscalYear = CRLP_DefaultConfigBuilder.legacySettings.npo02__Use_Fiscal_Year_for_Rollups__c;
            }

            // If UseFiscalYear is checked, change any occurances of "Calendar Year" in the rollup description
            // to "Fiscal Year"
            if (rollup.useFiscalYear == true) {
                rollup.description = rollup.description.replace('Calendar', 'Fiscal').replace('calendar', 'fiscal');
            }

            if (!String.isEmpty(rollupDetails[6])) {
                rollup.intValue = Integer.valueOf(rollupDetails[6]);
            }

            if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Enable_Soft_Credit_Rollups__c == false &&
                    rollupDetails[2] == CRLP_DefaultConfigBuilder.pscAmountFld) {
                // If the legacy 'Enable Soft Credit Rollups' field is false,
                // set all the soft credit rollup definitions to inactive.
                rollup.isActive = false;
            } else if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Membership_Record_Types__c == null &&
                    rollupDetails[1] == CRLP_DefaultConfigBuilder.FilterGroup_Membership) {
                // If the legacy Membership Record Type setting is null,
                // set all the membership rollup definitions to inactive.
                rollup.isActive = false;
            } else {
                rollup.isActive = true;
            }

            // set isDeleted explicitly so upon reset everything is undeleted
            rollup.isDeleted = false;

            rollups.add(rollup);
        }

        return rollups;
    }

    /*************************************************************************************************************
     * @description Convert any existing NPSP User Defined Rollups to the new CMT format
     * @return List<Rollup> defined Rollup wrapper classes
     */
    private static List<CRLP_RollupCMT.Rollup> buildUserDefinedRollups() {
        List<CRLP_RollupCMT.Rollup> rollups = new List<CRLP_RollupCMT.Rollup>();

        Map<String, String> convertUDROperationMap = new Map<String, String>{
                'MIN' => CRLP_Operation.RollupType.Smallest.name(),
                'MAX' => CRLP_Operation.RollupType.Largest.name(),
                'AVG' => CRLP_Operation.RollupType.Average.name(),
                'SUM' => CRLP_Operation.RollupType.Sum.name()
        };

        Map<String, String> convertDateUDROperationMap = new Map<String, String>{
                'MIN' => CRLP_Operation.RollupType.First.name(),
                'MAX' => CRLP_Operation.RollupType.Last.name()
        };

        for (npo02__User_Rollup_Field_Settings__c udr : CRLP_DefaultConfigBuilder.legacyUDRSettings) {
            try {
                if(udr.npo02__Object_Name__c != 'npo02__Household__c') {
                    String udrSourceFieldType = UTIL_Describe.getFieldType('Opportunity', udr.npo02__Source_Field__c.toLowerCase());
                    String udrTargetFieldType = UTIL_Describe.getFieldType(udr.npo02__Object_Name__c, udr.npo02__Target_Field__c.toLowerCase());

                    Boolean sourceFieldIsAmount = (udrSourceFieldType == 'CURRENCY'
                            || udrSourceFieldType == 'INTEGER'
                            || udrSourceFieldType == 'PERCENT'
                            || udrSourceFieldType == 'DOUBLE');
                    Boolean sourceFieldIsDate = (udrSourceFieldType == 'DATE'
                            || udrSourceFieldType == 'DATETIME');
                    String operation = (sourceFieldIsDate ? convertDateUDROperationMap.get(udr.npo02__Field_Action__c) : convertUDROperationMap.get(udr.npo02__Field_Action__c));
                    List<String> sourceListWithoutNamespace = udr.npo02__Source_Field__c.split('__');
                    String sourceWithoutNamespace = (sourceListWithoutNamespace.size() == 3 ? sourceListWithoutNamespace[1]: sourceListWithoutNamespace[0]);

                    String udrName = 'UDR: ' + operation + ' ' + sourceWithoutNamespace.replace('_', '') + ' to ' +
                            udr.npo02__Object_Name__c + '.' + udr.npo02__Target_Field__c.replace('__c', '').replace('_', '');
                    CRLP_RollupCMT.Rollup rollup = new CRLP_RollupCMT.Rollup(udrName.left(40));

                    rollup.description = 'User Defined Roll-up';
                    rollup.filterGroupRecordName = (udr.npo02__Object_Name__c == 'Account'
                            ? CRLP_DefaultConfigBuilder.FilterGroup_Opps_Accounts_HC
                            : CRLP_DefaultConfigBuilder.FilterGroup_Opps_Contacts_HC);
                    rollup.summaryObject = udr.npo02__Object_Name__c;
                    rollup.summaryField = udr.npo02__Target_Field__c;
                    rollup.detailObject = 'Opportunity';
                    rollup.detailField = udr.npo02__Source_Field__c;
                    rollup.amountObject = 'Opportunity';
                    rollup.amountField = (sourceFieldIsAmount ? udr.npo02__Source_Field__c : 'Amount');
                    rollup.dateObject = 'Opportunity';
                    rollup.dateField = (sourceFieldIsDate ? udr.npo02__Source_Field__c : 'CloseDate');
                    rollup.operation = operation;
                    rollup.useFiscalYear = CRLP_DefaultConfigBuilder.legacySettings.npo02__Use_Fiscal_Year_for_Rollups__c;
                    rollup.isActive = true;
                    rollup.isDeleted = false;
                    rollups.add(rollup);
                }
            }
            catch(Exception ex) {
                continue;
            }  
        }
        return rollups;
    }

    /*************************************************************************************************************
     * @description Convert a legacy semi-colon separated list of Record Type Id's into a semi-colon list of
     * Record Type Developer Names. These are easier to 'read' (i.e., self-documenting) and more importantly it allows
     * for deploying a custom Filter Rule from a Sandbox to Production (where the Record Type Id might be different
     * if the RT was created in the Sandbox).
     * @param rtIds semi-colon separatedlist of Record Type Id's
     * @return Semi-colon separated list of Record Type Developer Names
     */
    private static String convertRecordTypeIdsToDevNames(String rtIds) {
        Set<String> rtDevNames = new Set<String>();
        if (rtIds != null) {
            for (String rtId : rtIds.split(';')) {
                if (oppRecordTypesById.containsKey(rtId)) {
                    rtDevNames.add(oppRecordTypesById.get(rtId).DeveloperName);
                }
            }
        }
        return String.join(new List<String>(rtDevNames), ';');
    }

    /**
     * @description The Object.Field strings defined in this class do not apply the npsp__ namespace for fields that
     * are in the npsp package. This method parses that string value and applies the appropriate namespace to the
     * object and/or field names as necessary.
     * @param objFieldData Object.Field (or just Object).
     * @return Object.Field with applied npsp namespace where necessary
     */
    private static String applyNameSpaceToObjectField(String objFieldData) {
        if (objFieldData == null) {
            return null;
        } else if (objFieldData.contains('.')) {
            String obj = objFieldData.split('\\.')[0];
            String fld = objFieldData.split('\\.')[1];
            return UTIL_Namespace.StrAllNSPrefix(obj) + '.' + UTIL_Namespace.StrAllNSPrefix(fld);
        } else {
            return UTIL_Namespace.StrAllNSPrefix(objFieldData);
        }
    }
}
