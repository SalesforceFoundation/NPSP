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
* @group Customizable Rollups Operations Services
* @description Unit Test for the Rollups Metadata
*/

@isTest(IsParallel=true)
public with sharing class CRLP_RollupCMT_TEST {

    /********************************************************************************************************
     * @description Verifies that similar rollups are not marked as different
     */
    @isTest
    private static void similarRollupsAreMarkedAsEqual() {

        CRLP_RollupCMT.Rollup newRollup = generateRollup('1');
        CRLP_RollupCMT.Rollup existingRollup = generateRollup('2');

        System.assertEquals(false, newRollup.isDifferent(existingRollup), 'Similiar Rollups are marked as as equal');
    }

    /********************************************************************************************************
     * @description Verifies that different rollups are marked as different
     */
    @isTest
    private static void differentRollupsAreMarkedAsDifferent() {

        CRLP_RollupCMT.Rollup newRollup1 = generateRollup('1');
        CRLP_RollupCMT.Rollup newRollup2 = generateRollup('2');
        CRLP_RollupCMT.Rollup newRollup3 = generateRollup('3');
        CRLP_RollupCMT.Rollup newRollup4 = generateRollup('4');
        CRLP_RollupCMT.Rollup newRollup5 = generateRollup('5');
        CRLP_RollupCMT.Rollup newRollup6 = generateRollup('6');
        CRLP_RollupCMT.Rollup newRollup7 = generateRollup('7');
        CRLP_RollupCMT.Rollup newRollup8 = generateRollup('8');
        CRLP_RollupCMT.Rollup newRollup9 = generateRollup('9');
        CRLP_RollupCMT.Rollup newRollup10 = generateRollup('10');
        CRLP_RollupCMT.Rollup newRollup11 = generateRollup('11');
        CRLP_RollupCMT.Rollup newRollup12 = generateRollup('12');
        CRLP_RollupCMT.Rollup newRollup13 = generateRollup('13');
        CRLP_RollupCMT.Rollup newRollup14 = generateRollup('14');
        CRLP_RollupCMT.Rollup existingRollup = generateRollup('20');

        newRollup1.filterGroupRecordName = 'Different';
        newRollup2.operation = 'Different';
        newRollup3.timeBoundOperationType = 'Different';
        newRollup4.summaryObject = 'Count';
        newRollup5.summaryField = 'Count';
        newRollup6.detailObject = 'Count';
        newRollup7.detailField = 'Count';
        newRollup8.amountObject = 'Count';
        newRollup9.amountField = 'Count';
        newRollup10.dateObject = 'Count';
        newRollup11.dateField = 'Count';
        newRollup12.isActive = false;
        newRollup13.isDeleted = true;
        newRollup14.intValue = 0;

        System.assertEquals(true, newRollup1.isDifferent(existingRollup), 'Different Rollups are marked as different for filterGroupRecordName');
        System.assertEquals(true, newRollup2.isDifferent(existingRollup), 'Different Rollups are marked as different for operation');
        System.assertEquals(true, newRollup3.isDifferent(existingRollup), 'Different Rollups are marked as different for timeBoundOperationType');
        System.assertEquals(true, newRollup4.isDifferent(existingRollup), 'Different Rollups are marked as different for summaryObject');
        System.assertEquals(true, newRollup5.isDifferent(existingRollup), 'Different Rollups are marked as different for summaryField');
        System.assertEquals(true, newRollup6.isDifferent(existingRollup), 'Different Rollups are marked as different for detailObject');
        System.assertEquals(true, newRollup7.isDifferent(existingRollup), 'Different Rollups are marked as different for detailField');
        System.assertEquals(true, newRollup8.isDifferent(existingRollup), 'Different Rollups are marked as different for amountObject');
        System.assertEquals(true, newRollup9.isDifferent(existingRollup), 'Different Rollups are marked as different for amountField');
        System.assertEquals(true, newRollup10.isDifferent(existingRollup), 'Different Rollups are marked as different for dateObject');
        System.assertEquals(true, newRollup11.isDifferent(existingRollup), 'Different Rollups are marked as different for dateField');
        System.assertEquals(true, newRollup12.isDifferent(existingRollup), 'Different Rollups are marked as different for isActive');
        System.assertEquals(true, newRollup13.isDifferent(existingRollup), 'Different Rollups are marked as different for isDeleted');
        System.assertEquals(true, newRollup14.isDifferent(existingRollup), 'Different Rollups are marked as different for intValue');
    }

    /********************************************************************************************************
     * @description Verifies that similar filter groups are not marked as different
     */
    @isTest
    private static void similarFilterGroupsAreMarkedAsEqual() {

        CRLP_RollupCMT.FilterGroup newFilterGroup = generateFilterGroup('1');
        CRLP_RollupCMT.FilterGroup existingFilterGroup = generateFilterGroup('2');
        newFilterGroup.description = 'new description';

        System.assertEquals(false, newFilterGroup.isDifferent(existingFilterGroup), 'Similiar Filter Groups are marked as equal');
    }

    /********************************************************************************************************
     * @description Verifies that different filter groups are marked as different
     */
    @isTest
    private static void differentFilterGroupsAreMarkedAsDifferent() {

        CRLP_RollupCMT.FilterGroup newFilterGroup = generateFilterGroup('1');
        CRLP_RollupCMT.FilterGroup existingFilterGroup = generateFilterGroup('2');
        newFilterGroup.rules[0].value = 'false';

        System.assertEquals(true, newFilterGroup.isDifferent(existingFilterGroup), 'Different Filter Groups are marked as different');
    }

    /********************************************************************************************************
     * @description Verifies that account hard credit rollups are returned as account hard credit
     */
    @isTest
    private static void accountHardCreditRollupIdentifiedAsHardCreditType() {

        CRLP_RollupCMT.Rollup newRollup = generateRollup('1');
        CRLP_RollupProcessingOptions.RollupType returnType = newRollup.getRollupType();

        System.assertEquals(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, returnType,
          'Account Hard Credit should be identified.');
    }

    /********************************************************************************************************
     * @description Verifies that account soft credit rollups are returned as account soft credit
     */
    @isTest
    private static void accountSoftCreditRollupIdentifiedAsSoftCreditType() {

        String accountSoftCredit = UTIL_Namespace.StrAllNSPrefix('Account_Soft_Credit__c');
        CRLP_RollupCMT.Rollup newRollup = generateRollup('1');
        newRollup.amountObject = accountSoftCredit;
        newRollup.detailObject = 'Opportunity';
        CRLP_RollupProcessingOptions.RollupType returnType = newRollup.getRollupType();

        System.assertEquals(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit, returnType,
          'Account Soft Credit should be identified.');
    }

    /********************************************************************************************************
     * @description Verifies that contact soft credit rollups are returned as contact soft credit
     */
    @isTest
    private static void contactSoftCreditRollupIdentifiedAsSoftCreditType() {

        String partialSoftCredit = UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c');
        CRLP_RollupCMT.Rollup newRollup = generateRollup('1');
        newRollup.summaryObject = 'Contact';
        newRollup.amountObject = partialSoftCredit;
        CRLP_RollupProcessingOptions.RollupType returnType = newRollup.getRollupType();

        System.assertEquals(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit, returnType,
          'Contact Soft Credit should be identified.');
    }

    /********************************************************************************************************
     * @description Verifies that GAU rollups are returned as GAU
     */
    @isTest
    private static void gauRollupIdentifiedAsGAUType() {

        String gaus = UTIL_Namespace.StrAllNSPrefix('General_Accounting_Unit__c');
        CRLP_RollupCMT.Rollup newRollup = generateRollup('1');
        newRollup.summaryObject = gaus;

        CRLP_RollupProcessingOptions.RollupType returnType = newRollup.getRollupType();

        System.assertEquals(CRLP_RollupProcessingOptions.RollupType.GAU, returnType,
          'GAU should be identified.');
    }

    /********************************************************************************************************
     * @description Verifies that RD rollups are returned as RD
     */
    @isTest
    private static void rdRollupIdentifiedAsRDType() {

        String recurringDonations = 'npe03__Recurring_Donation__c';
        CRLP_RollupCMT.Rollup newRollup = generateRollup('1');
        newRollup.summaryObject = recurringDonations;

        CRLP_RollupProcessingOptions.RollupType returnType = newRollup.getRollupType();

        System.assertEquals(CRLP_RollupProcessingOptions.RollupType.RecurringDonations, returnType,
          'RecurringDonations should be identified.');
    }

    /**
     * @description Validate that the setValueLabel() method in the FilterRule class properly handles converting
     * a picklist api name to its expected label - in either English or Spanish.
     */
    @IsTest
    private static void shouldConvertPicklistApiNamesIntoLabels() {
        CRLP_RollupCMT.FilterRule rule = new CRLP_RollupCMT.FilterRule('Test', 'Test');
        rule.objectName = RecurringDonationSchedule__c.SObjectType.getDescribe().getName();
        rule.fieldName = RecurringDonationSchedule__c.DayOfMonth__c.getDescribe().getName();
        rule.value = '1;Last_Day';
        rule.setValueLabel();

        String expected = '1;\nLast Day Of Month';
        if (UserInfo.getLanguage() == 'es') {
            expected = '1;\nÚltimo día del mes';
        }
        System.assertEquals(expected, rule.valueLabel, 'The value label should have been set from the Api Name');
    }

    /********************************************************************************************************
     * HELPER FUNCTIONS
     */


    /********************************************************************************************************
     * @description provides a sample Rollup object for Test
     */
    public static CRLP_RollupCMT.Rollup generateRollup(String name) {

        CRLP_RollupCMT.Rollup rollup = new CRLP_RollupCMT.Rollup(name);
        rollup.recordName = 'rollup' + name;
        rollup.label = name;
        rollup.filterGroupRecordName = 'filterGroupDevName';
        rollup.summaryObject = 'Account';
        rollup.summaryField = 'CustomerPriority__c';
        rollup.summaryObjectLabel = 'Account';
        rollup.detailObject = 'Opportunity';
        rollup.detailField = 'npe01__Member_Level__c';
        rollup.amountField = 'Amount';
        rollup.dateField = 'CloseDate';
        rollup.operation = 'Smallest';
        rollup.timeBoundOperationType = 'All_Time';
        rollup.detailObjectLabel = 'Opportunity';
        rollup.dateObjectLabel = 'Opportunity';
        rollup.dateObject = 'Opportunity';
        rollup.summaryFieldlabel = 'Customer Priority';
        rollup.detailFieldLabel = 'Member Level';

        return rollup;
    }

    /********************************************************************************************************
     * @description provides a sample Filter Group for Testing
     */
    public static CRLP_RollupCMT.FilterGroup generateFilterGroup(String name) {
        CRLP_RollupCMT.FilterGroup newFilterGroup = new CRLP_RollupCMT.FilterGroup(name);
        newFilterGroup.recordName = 'filterGroup' + name;
        newFilterGroup.label = name;

        CRLP_RollupCMT.FilterRule rule1 = new CRLP_RollupCMT.FilterRule(newFilterGroup.recordName, 'rule1');
        rule1.objectName = 'Opportunity';
        rule1.fieldName = 'Won';
        rule1.operationName = 'Equals';
        rule1.value = 'true';
        newFilterGroup.rules.add(rule1);

        CRLP_RollupCMT.FilterRule rule2 = new CRLP_RollupCMT.FilterRule(newFilterGroup.recordName, 'rule2');
        rule2.objectName = 'Opportunity';
        rule2.fieldName = 'Amount';
        rule2.operationName = 'Not Equals';
        newFilterGroup.rules.add(rule2);

        return newFilterGroup;
    }

}
