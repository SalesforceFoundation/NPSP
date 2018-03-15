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

        // Set this to false so that all the RecordName values are generated with a friendly (and reproducible) value.
        CRLP_RollupCMT.useRandomGeneratedDeveloperName = false;

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
        String acctDonation = 'Donations';  // Use this to differentiate Account from Contact filters if that is needed
        String contDonation = 'Donations';  // Use this to differentiate Account from Contact filters if that is needed
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            acctDonation = acctDonation + '-Acct';
            contDonation = contDonation + '-Cont';
        }

        // ==============================================================================================================
        // Default "Donations: Close/Won Stage" filter group -- All Hard Credit, Soft Credit, and GAU Rollups
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupClosedWonDonations = new CRLP_RollupCMT.FilterGroup(acctDonation+': Closed Won excluding RTs');
        groupClosedWonDonations.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Donations_Accounts;
        groupClosedWonDonations.description = 'Closed/Won {0} Opportunities for all Hard and Soft Credit Rollups. ' +
                'The additional filter rule for SoftCredit Donor Role is only applied when rolling up Soft Credits to the Account or Contact objects';

        CRLP_RollupCMT.FilterRule ruleCloseWonStage = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, acctDonation+': CloseWon Only');
        ruleCloseWonStage.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage.recordName;
        ruleCloseWonStage.objectName = 'Opportunity';
        ruleCloseWonStage.fieldName = 'IsWon';
        ruleCloseWonStage.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage.value = 'true';
        groupClosedWonDonations.rules.add(ruleCloseWonStage);

        if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c != null) {
            CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, acctDonation + ': Excluded RT');
            ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
            ruleRecordType.objectName = 'Opportunity';
            ruleRecordType.fieldName = 'RecordTypeId';
            ruleRecordType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordType.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Rectypes__c, 'Membership');
            groupClosedWonDonations.rules.add(ruleRecordType);
            groupClosedWonDonations.description = String.format(groupClosedWonDonations.description,
                    New List<String>{ 'Non-'+ruleRecordType.value });
        } else {
            groupClosedWonDonations.description = String.format(groupClosedWonDonations.description,
                    New List<String>{ '' });
        }

        if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, acctDonation+': Excluded Opp.Type');
            ruleOppType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppType.recordName;
            ruleOppType.objectName = 'Opportunity';
            ruleOppType.fieldName = 'Type';
            ruleOppType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppType.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Account_Opp_Types__c;
            groupClosedWonDonations.rules.add(ruleOppType);
        }

        if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c != null) {
            CRLP_RollupCMT.FilterRule ruleSoftCreditRoles = new CRLP_RollupCMT.FilterRule(groupClosedWonDonations.recordName, acctDonation+': Soft Credit Roles ');
            ruleSoftCreditRoles.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleSoftCreditRoles.recordName;
            ruleSoftCreditRoles.objectName = SObjectType.Partial_Soft_Credit__c.getName();
            ruleSoftCreditRoles.fieldName = SObjectType.Partial_Soft_Credit__c.Fields.Role_Name__c.getName();
            ruleSoftCreditRoles.operation = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleSoftCreditRoles.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c;
            groupClosedWonDonations.rules.add(ruleSoftCreditRoles);
        }

        // If there is a need to create another Filter Group for Contacts that is different than Accounts ...
        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsContacts;
        if (CRLP_DefaultConfigBuilder.isDifferentContactFilterGroupNeeded) {
            // ==============================================================================================================
            // Default "Donations: Close/Won Stage" filter group -- All Hard Credit, Soft Credit, and GAU Rollups CONTACTS ONLY
            // ==============================================================================================================
            groupClosedWonDonationsContacts = new CRLP_RollupCMT.FilterGroup('Donations-Cont: ClosedWon excl RTs');
            groupClosedWonDonationsContacts.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Donations_Contacts;
            groupClosedWonDonationsContacts.description = 'Closed/Won {0} Opportunities for Contact Hard and Soft Credit Rollups. ' +
                    'The additional filter rule for SoftCredit Donor Role is only applied when rolling up Soft Credits to the Contact object';

            CRLP_RollupCMT.FilterRule ruleCloseWonStage1 = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContacts.recordName, 'Donations-Contact: CloseWon Only');
            ruleCloseWonStage1.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage1.recordName;
            ruleCloseWonStage1.objectName = 'Opportunity';
            ruleCloseWonStage1.fieldName = 'IsWon';
            ruleCloseWonStage1.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
            ruleCloseWonStage1.value = 'true';
            groupClosedWonDonationsContacts.rules.add(ruleCloseWonStage1);

            if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c != null) {
                CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContacts.recordName, 'Donations-Contact: Excluded RT');
                ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
                ruleRecordType.objectName = 'Opportunity';
                ruleRecordType.fieldName = 'RecordTypeId';
                ruleRecordType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleRecordType.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Rectypes__c, 'Membership');
                groupClosedWonDonationsContacts.rules.add(ruleRecordType);
                groupClosedWonDonationsContacts.description = String.format(groupClosedWonDonationsContacts.description,
                    New List<String>{ 'Non-'+ruleRecordType.value });
            } else {
                groupClosedWonDonationsContacts.description = String.format(groupClosedWonDonationsContacts.description,
                        New List<String>{ '' });
            }

            if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c != null) {
                CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContacts.recordName, 'Donations-Contact: Excluded Opp.Type');
                ruleOppType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppType.recordName;
                ruleOppType.objectName = 'Opportunity';
                ruleOppType.fieldName = 'Type';
                ruleOppType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
                ruleOppType.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Excluded_Contact_Opp_Types__c;
                groupClosedWonDonationsContacts.rules.add(ruleOppType);
            }

            if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c != null) {
                CRLP_RollupCMT.FilterRule ruleSoftCreditRoles = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsContacts.recordName, 'Donations-Contact: Soft Credit Roles ');
                ruleSoftCreditRoles.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleSoftCreditRoles.recordName;
                ruleSoftCreditRoles.objectName = SObjectType.Partial_Soft_Credit__c.getName();
                ruleSoftCreditRoles.fieldName = SObjectType.Partial_Soft_Credit__c.Fields.Role_Name__c.getName();
                ruleSoftCreditRoles.operation = CMT_FilterRule.FilterOperation.IN_LIST.name();
                ruleSoftCreditRoles.value = CRLP_DefaultConfigBuilder.legacySettings.npo02__Soft_Credit_Roles__c;
                groupClosedWonDonationsContacts.rules.add(ruleSoftCreditRoles);
            }
        }

        // ==============================================================================================================
        // Default "Memberships: Close/Won Stage" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupMemberships = new CRLP_RollupCMT.FilterGroup('Membership: Closed Won for specific RTs');
        groupMemberships.description = 'Closed/Won Membership Opportunities for all Membership Rollups';
        groupMemberships.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Membership;

        CRLP_RollupCMT.FilterRule ruleCloseWonStage2 = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: CloseWon Only');
        ruleCloseWonStage2.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage2.recordName;
        ruleCloseWonStage2.objectName = 'Opportunity';
        ruleCloseWonStage2.fieldName = 'IsWon';
        ruleCloseWonStage2.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage2.value = 'true';
        groupMemberships.rules.add(ruleCloseWonStage2);

        if (CRLP_DefaultConfigBuilder.legacySettings.npo02__Membership_Record_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupMemberships.recordName, 'Membership: for Record Types');
            ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
            ruleRecordType.objectName = 'Opportunity';
            ruleRecordType.fieldName = 'RecordTypeId';
            ruleRecordType.operation = CMT_FilterRule.FilterOperation.IN_LIST.name();
            ruleRecordType.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacySettings.npo02__Membership_Record_Types__c, 'Membership');
            groupMemberships.rules.add(ruleRecordType);
        }

        // ==============================================================================================================
        // Default "Allocations" filter group
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupAllocations = new CRLP_RollupCMT.FilterGroup('Allocations: Closed Won excluding RTs');
        groupAllocations.description = 'Closed/Won {0} Opportunities for the Allocation to GAU Rollup';
        groupAllocations.recordName = CRLP_DefaultConfigBuilder.FilterGroup_Allocations;

        CRLP_RollupCMT.FilterRule ruleCloseWonStage3 = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Allocations: CloseWon Only');
        ruleCloseWonStage3.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage3.recordName;
        ruleCloseWonStage3.objectName = 'Opportunity';
        ruleCloseWonStage3.fieldName = 'IsWon';
        ruleCloseWonStage3.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage3.value = 'true';
        groupAllocations.rules.add(ruleCloseWonStage3);

        if (CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_RecTypes__c != null) {
            CRLP_RollupCMT.FilterRule ruleRecordType = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Allocations: Excluded Record Types');
            ruleRecordType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleRecordType.recordName;
            ruleRecordType.objectName = 'Opportunity';
            ruleRecordType.fieldName = 'RecordTypeId';
            ruleRecordType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleRecordType.value = convertExcludedRecordTypeIdsToDevNames(CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_RecTypes__c, null);
            groupAllocations.rules.add(ruleRecordType);
            groupAllocations.description = String.format(groupAllocations.description,
                    New List<String>{ 'Non-'+ruleRecordType.value });
        } else {
            groupAllocations.description = String.format(groupAllocations.description,
                    New List<String>{ '' });
        }

        if (CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_Types__c != null) {
            CRLP_RollupCMT.FilterRule ruleOppType = new CRLP_RollupCMT.FilterRule(groupAllocations.recordName, 'Memberships: Excluded Opp.Types');
            ruleOppType.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOppType.recordName;
            ruleOppType.objectName = 'Opportunity';
            ruleOppType.fieldName = 'Type';
            ruleOppType.operation = CMT_FilterRule.FilterOperation.NOT_IN_LIST.name();
            ruleOppType.value = CRLP_DefaultConfigBuilder.legacyAllocSettings.Excluded_Opp_Types__c;
            groupAllocations.rules.add(ruleOppType);
        }

        // ==============================================================================================================
        // Default "Donations: Pledged Stage" filter group -- Recurring Donations Rollups
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupPledgedDonations = new CRLP_RollupCMT.FilterGroup(acctDonation+': Pledged Only');
        groupPledgedDonations.recordName = CRLP_DefaultConfigBuilder.FilterGroup_PledgedDonations;
        groupPledgedDonations.description = 'Pledged {0} Opportunities for all Hard and Soft Credit Rollups.';

        // isClosed == false && isWon == null
        // constructed this way to exactly match the logic from RDs
        CRLP_RollupCMT.FilterRule ruleOpenStage = new CRLP_RollupCMT.FilterRule(groupPledgedDonations.recordName, acctDonation+': Not Closed Only');
        ruleOpenStage.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleOpenStage.recordName;
        ruleOpenStage.objectName = 'Opportunity';
        ruleOpenStage.fieldName = 'isClosed';
        ruleOpenStage.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleOpenStage.value = 'false';
        groupPledgedDonations.rules.add(ruleOpenStage);

        CRLP_RollupCMT.FilterRule ruleNotWon = new CRLP_RollupCMT.FilterRule(groupPledgedDonations.recordName, acctDonation+': Not Won Only');
        ruleNotWon.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleNotWon.recordName;
        ruleNotWon.objectName = 'Opportunity';
        ruleNotWon.fieldName = 'isWon';
        ruleNotWon.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleNotWon.value = 'false';
        groupPledgedDonations.rules.add(ruleNotWon);
    
        // ==============================================================================================================
        // Default "Donations: Close/Won Stage WITHOUT RT Exclusions" filter group -- Recurring Donations Rollups
        // ==============================================================================================================
        CRLP_RollupCMT.FilterGroup groupClosedWonDonationsNoRTExclusions = new CRLP_RollupCMT.FilterGroup(acctDonation+': Closed Won not excluding RTs');
        groupClosedWonDonationsNoRTExclusions.recordName = CRLP_DefaultConfigBuilder.FilterGroup_ClosedWonOpps_NoRTExclusions;
        groupClosedWonDonationsNoRTExclusions.description = 'Closed/Won {0} Opportunities for Recurring Donations Rollups. ';

        CRLP_RollupCMT.FilterRule ruleCloseWonStage4 = new CRLP_RollupCMT.FilterRule(groupClosedWonDonationsNoRTExclusions.recordName, acctDonation+': Won Only');
        ruleCloseWonStage4.recordName = CRLP_DefaultConfigBuilder.RecordNamePrefix + ruleCloseWonStage4.recordName;
        ruleCloseWonStage4.objectName = 'Opportunity';
        ruleCloseWonStage4.fieldName = 'IsWon';
        ruleCloseWonStage4.operation = CMT_FilterRule.FilterOperation.EQUALS.name();
        ruleCloseWonStage4.value = 'true';
        groupClosedWonDonationsNoRTExclusions.rules.add(ruleCloseWonStage4);

        // ==============================================================================================================
        // Create a list of the default Groups+Rules to use for deployment
        // ==============================================================================================================

        List<CRLP_RollupCMT.FilterGroup> groups = new List<CRLP_RollupCMT.FilterGroup>{
                groupClosedWonDonations, groupMemberships, groupAllocations, groupPledgedDonations, groupClosedWonDonationsNoRTExclusions
        };
        if (groupClosedWonDonationsContacts != null) {
            groups.add(groupClosedWonDonationsContacts);
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
            rollup.recordName = (CRLP_DefaultConfigBuilder.RecordNamePrefix + rollup.recordName).replace('_365_', '_N_');
            rollup.description = rollupText[1];
            rollup.filterGroupRecordName = rollupDetails[1];
            rollup.summaryObject = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(summaryObjectField)[0]);
            rollup.summaryField = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(summaryObjectField)[1]);
            rollup.detailObject  = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[0])[0]);
            rollup.detailField  = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[0])[1]);
            rollup.amountObject  = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[2])[0]);
            rollup.amountField  = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[2])[1]);
            rollup.dateObject = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[3])[0]);
            rollup.dateField = applyNameSpaceToObjectField(CRLP_RollupCMT.parseObjectField(rollupDetails[3])[1]);
            rollup.operation = rollupDetails[4];
            rollup.timeBoundOperationType = rollupDetails[5];
            rollup.useFiscalYear = CRLP_DefaultConfigBuilder.legacySettings.npo02__Use_Fiscal_Year_for_Rollups__c;
            if (!String.isEmpty(rollupDetails[6])) {
                rollup.intValue = Integer.valueOf(rollupDetails[6]);
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

        for (npo02__User_Rollup_Field_Settings__c udr : CRLP_DefaultConfigBuilder.legacyUDRSettings) {
            String udrName = 'UDR: ' + udr.npo02__Source_Field__c.replace('__c', '').replace('_','') + ' to ' +
                    udr.npo02__Object_Name__c + '.' + udr.npo02__Target_Field__c.replace('__c', '').replace('_','');
            CRLP_RollupCMT.Rollup rollup = new CRLP_RollupCMT.Rollup(udrName.left(40));
            // rollup.recordName = 'UDR_' + rollup.recordName;
            rollup.description = 'User Defined Roll-up';
            rollup.filterGroupRecordName = (udr.npo02__Object_Name__c == 'Account'
                    ? CRLP_DefaultConfigBuilder.FilterGroup_Donations_Accounts
                    : CRLP_DefaultConfigBuilder.FilterGroup_Donations_Contacts);
            rollup.summaryObject = applyNameSpaceToObjectField(udr.npo02__Object_Name__c);
            rollup.summaryField = applyNameSpaceToObjectField(udr.npo02__Target_Field__c);
            rollup.detailObject = 'Opportunity';
            rollup.detailField = udr.npo02__Source_Field__c;
            rollup.amountObject = 'Opportunity';
            rollup.amountField = 'Amount';
            rollup.dateObject = 'Opportunity';
            rollup.dateField = 'CloseDate';
            rollup.operation = CRLP_Operation.getRollupTypeFromString(udr.npo02__Field_Action__c).name();
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