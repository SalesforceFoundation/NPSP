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
* @description Unit Test for the Default Customizable Rollups Configuration Builder classes
*/
@isTest(IsParallel=true)
private class CRLP_DefaultConfigBuilder_TEST {

    /** @description Default gift record type for tests. */
    private static final String giftRecordTypeIdForTests = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.sObjectType);

    /** @description Default membership record type for tests. */
    private static final String membershipRecordTypeIdForTests = UTIL_RecordTypes.getRecordTypeIdForMembershipTests(Opportunity.sObjectType);

    static void setupLegacySettings() {

        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = false,
                Rollups_Limit_on_Attached_Opps_for_Skew__c = 200,
                Rollups_Account_SkewMode_Batch_Size__c = 200,
                Rollups_Contact_SkewMode_Batch_Size__c = 200,
                Rollups_Contact_Soft_Credit_Batch_Size__c = 200,
                Rollups_Account_Batch_Size__c = 20,
                Rollups_Contact_Batch_Size__c = 20
        ));

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Payments_Enabled__c = true,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));

        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Always_Rollup_to_Primary_Contact__c = false,
                npo02__Enable_Opp_Rollup_Triggers__c = false,
                npo02__Excluded_Account_Opp_Rectypes__c = membershipRecordTypeIdForTests,
                npo02__Excluded_Account_Opp_Types__c = null,
                npo02__Excluded_Contact_Opp_Rectypes__c = membershipRecordTypeIdForTests,
                npo02__Excluded_Contact_Opp_Types__c = null,
                npo02__Membership_Record_Types__c = membershipRecordTypeIdForTests
        ));

        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c(
                Use_Fiscal_Year_for_Rollups__c=true,
                Excluded_Opp_Types__c='foo;bar',
                Excluded_Opp_RecTypes__c=membershipRecordTypeIdForTests
        ));
    }

    /**
     * @description Test creating the default rollup configuration where there the legacy rollup settings are the same
     * for the Account and Contact rollups
     */
    static testMethod void test_createDefaults_simple() {
        setupLegacySettings();
        test.startTest();
        CRLP_DefaultConfigBuilder_SVC.convertLegacyRollupsIntoCustomizableRollups();
        test.stopTest();

        Integer fgCount = 0;
        Integer rlpCount = 0;
        for (Metadata.CustomMetadata md : CRLP_ConfigBuilder_SVC.queuedMetadataTypes) {
            if (md.fullName.contains('Filter_Group__mdt')) {
                if (!isDeleteFlagTrue(md)) {
                    fgCount++;
                }
            } else if (md.fullName.contains('Rollup__mdt')) {
                if (!isDeleteFlagTrue(md)) {
                    rlpCount++;
                }
            }
        }

        System.assertEquals(8, fgCount, 'There should be 8 filter groups');
        System.assertEquals(CRLP_DefaultConfigBuilder.rollupDetailsBySummaryField.size(), rlpCount, 'There should be 87 rollups');
    }

    /**
     * @description Test creating the default rollup configuration where there the legacy rollup settings are different
     * for the Account and Contact rollups; and the 'Enable Soft Credit Rollups' field is unchecked.
     */
    static testMethod void test_createDefaults_diffContact() {
        setupLegacySettings();
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Always_Rollup_to_Primary_Contact__c = false,
                npo02__Enable_Opp_Rollup_Triggers__c = false,
                npo02__Excluded_Account_Opp_Rectypes__c = membershipRecordTypeIdForTests,
                npo02__Excluded_Account_Opp_Types__c = 'Nothing',
                npo02__Excluded_Contact_Opp_Rectypes__c = membershipRecordTypeIdForTests,
                npo02__Excluded_Contact_Opp_Types__c = 'Whatever',
                npo02__Membership_Record_Types__c = membershipRecordTypeIdForTests,
                npo02__Enable_Soft_Credit_Rollups__c = false
        ));
        test.startTest();
        CRLP_DefaultConfigBuilder_SVC.convertLegacyRollupsIntoCustomizableRollups();
        test.stopTest();

        Integer fgCount = 0;
        Integer rlpCount = 0;
        for (Metadata.CustomMetadata md : CRLP_ConfigBuilder_SVC.queuedMetadataTypes) {
            if (md.fullName.contains('Filter_Group__mdt')) {
                if (!isDeleteFlagTrue(md)) {
                    fgCount++;
                }
            } else if (md.fullName.contains('Rollup__mdt')) {
                if (!isDeleteFlagTrue(md)) {
                    rlpCount++;
                    String lbl = md.label;
                    for (Metadata.CustomMetadataValue val : md.values) {
                        if ((String)val.field == 'Active__c') {
                            if (lbl.containsIgnoreCase('soft') && (Boolean) val.value == true) {
                                System.assert(false, 'Soft Credit Rollups should not be active: ' + md.fullName);
                            } else if (!lbl.containsIgnoreCase('soft') && (Boolean) val.value == false) {
                                System.assert(false, 'All Other Rollups should be active: ' + md.fullName);
                            }
                        }
                    }
                }
            }
        }


        System.assertEquals(12, fgCount, 'There should be 12 filter groups');
        System.assertEquals(CRLP_DefaultConfigBuilder.rollupDetailsBySummaryField.size(), rlpCount, 'There should be 87 rollups');
    }

    /**
     * @description Helper method to check if a metadata record has been flagged as soft-deleted
     */
    private static Boolean isDeleteFlagTrue(Metadata.CustomMetadata md) {
        for (Metadata.CustomMetadataValue val : md.values) {
            if ((String) val.field == UTIL_Namespace.StrAllNSPrefix('Is_Deleted__c') && (Boolean) val.value == true) {
                return true;
            }
        }
        return false;
    }
}