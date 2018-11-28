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
* @group Tribute
* @group-content ../../ApexDocContent/Tribute.htm
* @description Tests for the MultipleTributesSettingsFacade class
*/
@isTest
private class TBU_MultipleTributesSettingsFacade_TEST {
    /*******************************************************************************************************
    * @description Role values to use in settings.
    */
    private static final String OPPORTUNITY_CONTACT_ROLE_DONOR = 'Donor';
    private static final String OPPORTUNITY_CONTACT_ROLE_HONOREE = 'Honoree';
    private static final String OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT = 'Notification Recipient';

    /*******************************************************************************************************
    * @description Test setting defaults when initially not set
    */
    static testMethod void testMultipleTributesSettingDefaults() {
        
        System.assertEquals (TBU_MultipleTributesSettingsFacade.TRIBUTE_SINGLE_VAL, TBU_MultipleTributesSettingsFacade.getMultipleTributesSetting(), 'Multiple Tributes - Single if not set');
        System.assertEquals (true, TBU_MultipleTributesSettingsFacade.isMultipleTributesSingle(), 'isMultipleTributesSingle()');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible(), 'isMultipleTributesFlexible()');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited(), 'isMultipleTributesLimited()');
        System.assertEquals (Label.stgMultipleTributesSingleOpp, TBU_MultipleTributesSettingsFacade.getMultipleTributesSettingLocalized(), 'getMultipleTributesSettingLocalized()');

    }

    /*******************************************************************************************************
    * @description Test setting defaults when NPSP Settings are present but Multiple Settings field is set
    */
   static testMethod void testMultipleTributesSettingNoMultipleSettingDefaults() {
        
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT
                )
        );

        System.assertEquals (TBU_MultipleTributesSettingsFacade.TRIBUTE_SINGLE_VAL, TBU_MultipleTributesSettingsFacade.getMultipleTributesSetting(), 'Multiple Tributes - Single if not set');
        System.assertEquals (true, TBU_MultipleTributesSettingsFacade.isMultipleTributesSingle(), 'isMultipleTributesSingle()');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible(), 'isMultipleTributesFlexible()');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited(), 'isMultipleTributesLimited()');
        System.assertEquals (Label.stgMultipleTributesSingleOpp, TBU_MultipleTributesSettingsFacade.getMultipleTributesSettingLocalized(), 'getMultipleTributesSettingLocalized()');
    }

    /*******************************************************************************************************
    * @description Test settings when Multiple Tributes set to Multiple Tributes Only
    */
    static testMethod void testMultipleTributesSettingMultiple() {

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT,
                        Multiple_Tributes__c = TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL
                )
        );

        System.assertEquals (TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL, TBU_MultipleTributesSettingsFacade.getMultipleTributesSetting(), 'Multiple Tributes Setting');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesSingle(), 'isMultipleTributesSingle()');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible(), 'isMultipleTributesFlexible()');
        System.assertEquals (true, TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited(), 'isMultipleTributesLimited()');
        System.assertEquals (Label.stgMultipleTributesLimited, TBU_MultipleTributesSettingsFacade.getMultipleTributesSettingLocalized(), 'getMultipleTributesSettingLocalized()');

    }

    /*******************************************************************************************************
    * @description Test settings when Multiple Tributes set to Mixed Mode (Multiple Tributes and Single Tributes [on Opportunity])
    */
    static testMethod void testMultipleTributesSettingMixed() {

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT,
                        Multiple_Tributes__c = TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL
                )
        );

        System.assertEquals (TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL, TBU_MultipleTributesSettingsFacade.getMultipleTributesSetting(), 'Multiple Tributes Setting');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesSingle(), 'isMultipleTributesSingle()');
        System.assertEquals (true, TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible(), 'isMultipleTributesFlexible()');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited(), 'isMultipleTributesLimited()');
        System.assertEquals (Label.stgMultipleTributesFlexible, TBU_MultipleTributesSettingsFacade.getMultipleTributesSettingLocalized(), 'getMultipleTributesSettingLocalized()');
    }

    /*******************************************************************************************************
    * @description Test settings when Multiple Tributes set to Single [Same as Default]
    */
    static testMethod void testMultipleTributesSettingSingle() {

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT,
                        Multiple_Tributes__c = TBU_MultipleTributesSettingsFacade.TRIBUTE_SINGLE_VAL
                )
        );

        System.assertEquals (TBU_MultipleTributesSettingsFacade.TRIBUTE_SINGLE_VAL, TBU_MultipleTributesSettingsFacade.getMultipleTributesSetting(), 'Multiple Tributes Setting');
        System.assertEquals (true, TBU_MultipleTributesSettingsFacade.isMultipleTributesSingle(), 'isMultipleTributesSingle()');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesFlexible(), 'isMultipleTributesFlexible()');
        System.assertEquals (false, TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited(), 'isMultipleTributesLimited()');
        System.assertEquals (Label.stgMultipleTributesSingleOpp, TBU_MultipleTributesSettingsFacade.getMultipleTributesSettingLocalized(), 'getMultipleTributesSettingLocalized()');
    }

}