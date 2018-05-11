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

    /** @description Use this Map of RecordTypes by Id to convert the legacy settings into a DeveloperName for the Filter Rule */
    private static final Map<Id, RecordType> recordTypesById = new Map<Id, RecordType>(
        [SELECT Id, RecordType.DeveloperName
            FROM RecordType
            WHERE SobjectType = 'Opportunity' AND IsActive = True]);

    /*************************************************************************************************************
     * @description Call each of the methods in this class to build the default Filter Groups and each of the four
     * Rollup Types (Account Hard Credit/Membership, Contact Hard Credit/Membership, Contact Soft Credit, and GAU)
     */
    public static String convertLegacyRollupsIntoCustomizableRollups() {

        List<CRLP_RollupCMT.FilterGroup> filterGroups = buildDefaultFilterGroups();

        List<CRLP_RollupCMT.Rollup> rollups = new List<CRLP_RollupCMT.Rollup>();
        rollups.addAll(buildDefaultRollups());
        rollups.addAll(buildUserDefinedRollups());

        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(filterGroups);
        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(rollups);

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
        String acctOpp = 'Opportunities';  // Use this to differentiate Account from Contact filters if that is needed
        String contOpp = 'Opportunities';  // Use this to differentiate Account from Contact filters if that is needed
        String acctPmt = 'Payments';  // Use this to differentiate Account from Contact filters if that is needed
        String contPmt = 'Payments';  // Use this to differentiate Account from Contact filters if that is needed
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
        // Default "Donations: Close/Won Stage" filter group -- All Hard Credit, Soft Credit, and GAU Rollups
        // ==============================================================================================================

        CRLP_RollupCMT.FilterGroup groupClosedWonDonations = new CRLP_RollupCMT.FilterGroup(acctOpp +': Won' + (acctRTExclusionsExist ? ' excluding Rec Types' : ''));
        groupClosedWonDonations.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Opps_Accounts;
        groupClosedWonDonations.description = 'Won Opportunities for both Hard and Soft Credit Rollups. ' +
                'The Soft Credit Role Name rule is only applied when rolling up Soft Credits to Accounts' +
                (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded ? '.' : ' or Contacts.') +
                (acctRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');

        CRLP_RollupCMT.FilterRule ruleCloseWonStage = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, acctOpp +': Won Only');
        ruleCloseWonStage.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage.recordName;
        ruleCloseWonStage.objectName = 'Opportunity';
        ruleCloseWonStage.fieldName = 'IsWon';
        ruleCloseWonStage.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage.value = 'true';
        groupClosedWonDonations.rules.add(ruleCloseWonStage);

        if (acctRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, acctOpp + ': Excluded RT');
            ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
            ruleRecordType.objectName = 'Opportunity';
            ruleRecordType.fieldName = 'RecordTypeId';
            ruleRecordType.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordType.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c, 'Membership');
            groupClosedWonDonations.rules.add(ruleRecordType);
        }

        if (acctOppTypeExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, acctOpp +': Excluded Opp.Type');
            ruleOppType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppType.recordName;
            ruleOppType.objectName = 'Opportunity';
            ruleOppType.fieldName = 'Type';
            ruleOppType.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppType.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c;
            groupClosedWonDonations.rules.add(ruleOppType);
        }

        if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c != null) {
            CRLP_RollupCMT.FilterRule ruleSoftCreditRoles = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, acctOpp +': Soft Credit Roles ');
            ruleSoftCreditRoles.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleSoftCreditRoles.recordName;
            ruleSoftCreditRoles.objectName = SObjectType.Partial_Soft_Credit__c.getName();
            ruleSoftCreditRoles.fieldName = SObjectType.Partial_Soft_Credit__c.Fields.Role_Name__c.getName();
            ruleSoftCreditRoles.operationName = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleSoftCreditRoles.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c;
            groupClosedWonDonations.rules.add(ruleSoftCreditRoles);
        }

        // If there is a need to create another Filter Group for Contacts that is different than Accounts ...
        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsContacts;
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            // ==============================================================================================================
            // Default "Donations: Close/Won Stage" filter group -- All Hard Credit, Soft Credit, and GAU Rollups CONTACTS ONLY
            // ==============================================================================================================
            groupClosedWonDonationsContacts = new CRLP_RollupCMT.FilterGroup(contOpp +': Won' + (conRTExclusionsExist ? ' excluding Rec Types' : ''));
            groupClosedWonDonationsContacts.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Opps_Contacts;
            groupClosedWonDonationsContacts.description = 'Won Opportunities for both Hard and Soft Credit Rollups. ' +
                    'The Soft Credit Role Name rule is only applied when rolling up Soft Credits to Contacts.' +
                    (conRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');

            CRLP_RollupCMT.FilterRule ruleCloseWonStage1 = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContacts.recordName, contOpp +': Won Only');
            ruleCloseWonStage1.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage1.recordName;
            ruleCloseWonStage1.objectName = 'Opportunity';
            ruleCloseWonStage1.fieldName = 'IsWon';
            ruleCloseWonStage1.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
            ruleCloseWonStage1.value = 'true';
            groupClosedWonDonationsContacts.rules.add(ruleCloseWonStage1);

            if (conRTExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContacts.recordName, contOpp +': Excluded RT');
                ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
                ruleRecordType.objectName = 'Opportunity';
                ruleRecordType.fieldName = 'RecordTypeId';
                ruleRecordType.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleRecordType.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c, 'Membership');
                groupClosedWonDonationsContacts.rules.add(ruleRecordType);
            }

            if (conOppTypeExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContacts.recordName, contOpp +': Excluded Opp.Type');
                ruleOppType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppType.recordName;
                ruleOppType.objectName = 'Opportunity';
                ruleOppType.fieldName = 'Type';
                ruleOppType.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleOppType.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c;
                groupClosedWonDonationsContacts.rules.add(ruleOppType);
            }

            if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c != null) {
                CRLP_RollupCMT.FilterRule ruleSoftCreditRoles = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContacts.recordName, contOpp +': Soft Credit Roles');
                ruleSoftCreditRoles.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleSoftCreditRoles.recordName;
                ruleSoftCreditRoles.objectName = SObjectType.Partial_Soft_Credit__c.getName();
                ruleSoftCreditRoles.fieldName = SObjectType.Partial_Soft_Credit__c.Fields.Role_Name__c.getName();
                ruleSoftCreditRoles.operationName = CMT_FilterRule.FilterOperation.IN_LIST.name();
                ruleSoftCreditRoles.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c;
                groupClosedWonDonationsContacts.rules.add(ruleSoftCreditRoles);
            }
        }

        // ==============================================================================================================
        // Default "Memberships: Close/Won Stage" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupMemberships = new CRLP_RollupCMT.FilterGroup('Memberships: Won');
        groupMemberships.description = 'Won Membership Opportunities used for all Membership Rollups. Record Types as defined in legacy NPSP Membership Settings.';
        groupMemberships.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Membership;

        CRLP_RollupCMT.FilterRule ruleCloseWonStage2 = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: Won Only');
        ruleCloseWonStage2.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage2.recordName;
        ruleCloseWonStage2.objectName = 'Opportunity';
        ruleCloseWonStage2.fieldName = 'IsWon';
        ruleCloseWonStage2.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage2.value = 'true';
        groupMemberships.rules.add(ruleCloseWonStage2);

        if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Membership_Record_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: for Record Types');
            ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
            ruleRecordType.objectName = 'Opportunity';
            ruleRecordType.fieldName = 'RecordTypeId';
            ruleRecordType.operationName = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleRecordType.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Membership_Record_Types__c, 'Membership');
            groupMemberships.rules.add(ruleRecordType);
        }

        // ==============================================================================================================
        // Default "Allocations" filter group
        // ==============================================================================================================

        Boolean alloRTExclusionsExist = (CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_RecTypes__c != null);

        CRLP_RollupCMT.FilterGroup groupAllocations = new CRLP_RollupCMT.FilterGroup('Allocations: Won' + (alloRTExclusionsExist ? ' excluding Rec Types' : ''));
        groupAllocations.description = 'Closed/Won Opportunities used for GAU Allocation to General Accounting Unit rollups.' + (alloRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');
        groupAllocations.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Allocations;

        CRLP_RollupCMT.FilterRule ruleCloseWonStage3 = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Allocations: Won Only');
        ruleCloseWonStage3.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage3.recordName;
        ruleCloseWonStage3.objectName = 'Opportunity';
        ruleCloseWonStage3.fieldName = 'IsWon';
        ruleCloseWonStage3.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage3.value = 'true';
        groupAllocations.rules.add(ruleCloseWonStage3);

        if (alloRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Allocations: Excluded Record Types');
            ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
            ruleRecordType.objectName = 'Opportunity';
            ruleRecordType.fieldName = 'RecordTypeId';
            ruleRecordType.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordType.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_RecTypes__c, null);
            groupAllocations.rules.add(ruleRecordType);
        }

        if (CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Memberships: Excluded Opp.Types');
            ruleOppType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppType.recordName;
            ruleOppType.objectName = 'Opportunity';
            ruleOppType.fieldName = 'Type';
            ruleOppType.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppType.value = CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_Types__c;
            groupAllocations.rules.add(ruleOppType);
        }

        // ==============================================================================================================
        // Default "Opportunities: Open" filter group -- Recurring Donations Rollups
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupOpenDonations = new CRLP_RollupCMT.FilterGroup('Opportunities: Open');
        groupOpenDonations.recordName = CRLP_DefaultConfigBuilder.FilterGroup_OpenOpps;
        groupOpenDonations.description = 'All open Opportunities';

        CRLP_RollupCMT.FilterRule ruleOpenStage = new CRLP_RollupCMT.FilterRule(groupOpenDonations.recordName, 'Opportunities: Not Closed Only');
        ruleOpenStage.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOpenStage.recordName;
        ruleOpenStage.objectName = 'Opportunity';
        ruleOpenStage.fieldName = 'isClosed';
        ruleOpenStage.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleOpenStage.value = 'false';
        groupOpenDonations.rules.add(ruleOpenStage);
    
        // ==============================================================================================================
        // Default "Donations: Close/Won Stage WITHOUT RT Exclusions" filter group -- Recurring Donations Rollups
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsNoRTExclusions = new CRLP_RollupCMT.FilterGroup('Opportunities: Won (Recurring Donations)');
        groupClosedWonDonationsNoRTExclusions.recordName = CRLP_DefaultConfigBuilder.FilterGroup_ClosedWonOpps_NoRTExclusions;
        groupClosedWonDonationsNoRTExclusions.description = 'Won Opportunities used for Recurring Donations Rollups.';

        CRLP_RollupCMT.FilterRule ruleCloseWonStage4 = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsNoRTExclusions.recordName, 'Opportunities: Won Only (RD)');
        ruleCloseWonStage4.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage4.recordName;
        ruleCloseWonStage4.objectName = 'Opportunity';
        ruleCloseWonStage4.fieldName = 'IsWon';
        ruleCloseWonStage4.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage4.value = 'true';
        groupClosedWonDonationsNoRTExclusions.rules.add(ruleCloseWonStage4);

        // ==============================================================================================================
        // Default "Payments: Paid" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupPaymentsPaid = new CRLP_RollupCMT.FilterGroup(acctPmt + ': Paid' + ( acctRTExclusionsExist ? ' excl Rec Types' : ''));
        groupPaymentsPaid.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsPaid;
        groupPaymentsPaid.description = 'All paid Payments.'+
                (acctRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');

        CRLP_RollupCMT.FilterRule rulePaid = new CRLP_RollupCMT.FilterRule(groupPaymentsPaid.recordName, acctPmt + ': Paid Only');
        rulePaid.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + rulePaid.recordName;
        rulePaid.objectName = 'npe01__OppPayment__c';
        rulePaid.fieldName = 'npe01__Paid__c';
        rulePaid.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        rulePaid.value = 'true';
        groupPaymentsPaid.rules.add(rulePaid);

        if (acctRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordTypePaid = new CRLP_RollupCMT.FilterRule(groupPaymentsPaid.recordName, acctPmt + ': Excl RT (Paid)');
            ruleRecordTypePaid.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypePaid.recordName;
            ruleRecordTypePaid.objectName = 'Opportunity';
            ruleRecordTypePaid.fieldName = 'RecordTypeId';
            ruleRecordTypePaid.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordTypePaid.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c, 'Membership');
            groupPaymentsPaid.rules.add(ruleRecordTypePaid);
        }

        if (acctOppTypeExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleOppTypePaid = new CRLP_RollupCMT.FilterRule(groupPaymentsPaid.recordName, acctPmt +': Excl Opp.Type (Paid)');
            ruleOppTypePaid.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypePaid.recordName;
            ruleOppTypePaid.objectName = 'Opportunity';
            ruleOppTypePaid.fieldName = 'Type';
            ruleOppTypePaid.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppTypePaid.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c;
            groupPaymentsPaid.rules.add(ruleOppTypePaid);
        }

        // If there is a need to create another Filter Group for Contacts that is different than Accounts ...
        CRLP_RollupCMT.FilterGroup groupPaymentsPaidContacts;
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            // ==============================================================================================================
            // Default "Payments: Paid" filter group CONTACTS ONLY
            // ==============================================================================================================
            groupPaymentsPaidContacts = new CRLP_RollupCMT.FilterGroup(contPmt + ': Paid' + ( conRTExclusionsExist ? ' excl Rec Types' : ''));
            groupPaymentsPaidContacts.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsPaid_Contacts;
            groupPaymentsPaidContacts.description = 'All paid Payments.'+
                    (conRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');

            CRLP_RollupCMT.FilterRule rulePaidCon = new CRLP_RollupCMT.FilterRule(groupPaymentsPaidContacts.recordName, contPmt + ': Paid Only');
            rulePaidCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + rulePaid.recordName;
            rulePaidCon.objectName = 'npe01__OppPayment__c';
            rulePaidCon.fieldName = 'npe01__Paid__c';
            rulePaidCon.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
            rulePaidCon.value = 'true';
            groupPaymentsPaidContacts.rules.add(rulePaidCon);

            if (conRTExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleRecordTypePaidCon = new CRLP_RollupCMT.FilterRule(groupPaymentsPaid.recordName, contPmt + ': Excl RT (Paid)');
                ruleRecordTypePaidCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypePaidCon.recordName;
                ruleRecordTypePaidCon.objectName = 'Opportunity';
                ruleRecordTypePaidCon.fieldName = 'RecordTypeId';
                ruleRecordTypePaidCon.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleRecordTypePaidCon.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c, 'Membership');
                groupPaymentsPaidContacts.rules.add(ruleRecordTypePaidCon);
            }

            if (conOppTypeExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleOppTypePaidCon = new CRLP_RollupCMT.FilterRule(groupPaymentsPaidContacts.recordName, contPmt +': Excl Opp.Type (Paid)');
                ruleOppTypePaidCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypePaidCon.recordName;
                ruleOppTypePaidCon.objectName = 'Opportunity';
                ruleOppTypePaidCon.fieldName = 'Type';
                ruleOppTypePaidCon.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleOppTypePaidCon.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c;
                groupPaymentsPaidContacts.rules.add(ruleOppTypePaidCon);
            }

        }

        // ==============================================================================================================
        // Default "Payments: Written Off" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupPaymentsWrittenOff = new CRLP_RollupCMT.FilterGroup(acctPmt + ': WrittenOff' + ( acctRTExclusionsExist ? ' excl Rec Types' : ''));
        groupPaymentsWrittenOff.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsWrittenOff;
        groupPaymentsWrittenOff.description = 'All written off Payments.';

        CRLP_RollupCMT.FilterRule ruleWrittenOff = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOff.recordName, acctPmt + ': Written Off Only');
        ruleWrittenOff.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleWrittenOff.recordName;
        ruleWrittenOff.objectName = 'npe01__OppPayment__c';
        ruleWrittenOff.fieldName = 'npe01__Written_Off__c';
        ruleWrittenOff.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleWrittenOff.value = 'true';
        groupPaymentsWrittenOff.rules.add(ruleWrittenOff);

        if (acctRTExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleRecordTypeWrittenOff = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOff.recordName, acctPmt + ': Excl RT (Written Off)');
            ruleRecordTypeWrittenOff.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypeWrittenOff.recordName;
            ruleRecordTypeWrittenOff.objectName = 'Opportunity';
            ruleRecordTypeWrittenOff.fieldName = 'RecordTypeId';
            ruleRecordTypeWrittenOff.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordTypeWrittenOff.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c, 'Membership');
            groupPaymentsWrittenOff.rules.add(ruleRecordTypeWrittenOff);
        }

        if (acctOppTypeExclusionsExist) {
            CRLP_RollupCMT.FilterRule ruleOppTypeWrittenOff = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOff.recordName, acctPmt +': Excl Opp.Type (Written Off)');
            ruleOppTypeWrittenOff.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypeWrittenOff.recordName;
            ruleOppTypeWrittenOff.objectName = 'Opportunity';
            ruleOppTypeWrittenOff.fieldName = 'Type';
            ruleOppTypeWrittenOff.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppTypeWrittenOff.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c;
            groupPaymentsWrittenOff.rules.add(ruleOppTypeWrittenOff);
        }

        // If there is a need to create another Filter Group for Contacts that is different than Accounts ...
        CRLP_RollupCMT.FilterGroup groupPaymentsWrittenOffContacts;
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            // ==============================================================================================================
            // Default "Payments: Written Off" filter group CONTACTS ONLY
            // ==============================================================================================================
            groupPaymentsWrittenOffContacts = new CRLP_RollupCMT.FilterGroup(contPmt + ': WrittenOff' + ( conRTExclusionsExist ? ' excl Rec Types' : ''));
            groupPaymentsWrittenOffContacts.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsWrittenOff_Contacts;
            groupPaymentsWrittenOffContacts.description = 'All written off Payments.'+
                    (conRTExclusionsExist ? ' Excludes Record Types as defined in legacy NPSP Rollup Settings.' : '');

            CRLP_RollupCMT.FilterRule ruleWrittenOffCon = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOffContacts.recordName, contPmt + ': Written Off Only');
            ruleWrittenOffCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleWrittenOffCon.recordName;
            ruleWrittenOffCon.objectName = 'npe01__OppPayment__c';
            ruleWrittenOffCon.fieldName = 'npe01__Written_Off__c';
            ruleWrittenOffCon.operationName = CMT_FilterRule.FilterOperation.EQUALS.name();
            ruleWrittenOffCon.value = 'true';
            groupPaymentsWrittenOffContacts.rules.add(ruleWrittenOffCon);

            if (conRTExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleRecordTypeWrittenOffCon = new CRLP_RollupCMT.FilterRule(groupPaymentsWrittenOffContacts.recordName, contPmt + ': Excl RT (Written Off)');
                ruleRecordTypeWrittenOffCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordTypeWrittenOffCon.recordName;
                ruleRecordTypeWrittenOffCon.objectName = 'Opportunity';
                ruleRecordTypeWrittenOffCon.fieldName = 'RecordTypeId';
                ruleRecordTypeWrittenOffCon.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleRecordTypeWrittenOffCon.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c, 'Membership');
                groupPaymentsWrittenOffContacts.rules.add(ruleRecordTypeWrittenOffCon);
            }

            if (conOppTypeExclusionsExist) {
                CRLP_RollupCMT.FilterRule ruleOppTypeWrittenOffCon = new CRLP_RollupCMT.FilterRule(groupPaymentsPaidContacts.recordName, contPmt +': Excl Opp.Type (Paid)');
                ruleOppTypeWrittenOffCon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppTypeWrittenOffCon.recordName;
                ruleOppTypeWrittenOffCon.objectName = 'Opportunity';
                ruleOppTypeWrittenOffCon.fieldName = 'Type';
                ruleOppTypeWrittenOffCon.operationName = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleOppTypeWrittenOffCon.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c;
                groupPaymentsWrittenOffContacts.rules.add(ruleOppTypeWrittenOffCon);
            }

        }

        // ==============================================================================================================
        // Create a list of the default Groups+Rules to use for deployment
        // ==============================================================================================================

        List<CRLP_RollupCMT.FilterGroup> groups = new List<CRLP_RollupCMT.FilterGroup>{
                groupClosedWonDonations,
                groupMemberships,
                groupAllocations,
                groupOpenDonations,
                groupClosedWonDonationsNoRTExclusions,
                groupPaymentsPaid,
                groupPaymentsWrittenOff
        };
        if (groupClosedWonDonationsContacts != null) {
            groups.add(groupClosedWonDonationsContacts);
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

            // If the legacy 'Enable Soft Credit Rollups' field is false, set all the soft credit rollup
            // definitions to inactive.
            if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Enable_Soft_Credit_Rollups__c == false &&
                    rollupDetails[2] == CRLP_DefaultConfigBuilder.pscAmountFld) {
                rollup.isActive = false;
            }

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

        for (npo02__User_Rollup_Field_Settings__c udr : CRLP_DefaultConfigBuilder.legacyUDRSettings) {
            String udrName = 'UDR: ' + udr.npo02__Source_Field__c.replace('__c', '').replace('_','') + ' to ' +
                    udr.npo02__Object_Name__c + '.' + udr.npo02__Target_Field__c.replace('__c', '').replace('_','');
            CRLP_RollupCMT.Rollup rollup = new CRLP_RollupCMT.Rollup(udrName.left(40));
            // rollup.recordName = 'UDR_' + rollup.recordName;
            rollup.description = 'User Defined Roll-up';
            rollup.filterGroupRecordName = (udr.npo02__Object_Name__c == 'Account'
                    ? CRLP_DefaultConfigBuilder.FilterGroup_Opps_Accounts
                    : CRLP_DefaultConfigBuilder.FilterGroup_Opps_Contacts);
            rollup.summaryObject = applyNameSpaceToObjectField(udr.npo02__Object_Name__c);
            rollup.summaryField = applyNameSpaceToObjectField(udr.npo02__Target_Field__c);
            rollup.detailObject = 'Opportunity';
            rollup.detailField = udr.npo02__Source_Field__c;
            rollup.amountObject = 'Opportunity';
            rollup.amountField = 'Amount';
            rollup.dateObject = 'Opportunity';
            rollup.dateField = 'CloseDate';
            rollup.operation = convertUDROperationMap.get(udr.npo02__Field_Action__c);
            rollup.useFiscalYear = CRLP_DefaultConfigBuilder.legacySettings.npo02__Use_Fiscal_Year_for_Rollups__c;
            rollups.add(rollup);
        }
        return rollups;
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