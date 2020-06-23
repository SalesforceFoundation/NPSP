/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Enhanced Recurring Donations Entry Form LWC Controller Class
*
*/
public with sharing class RD2_EntryFormController {

    /**
    * @description  Gather the org setting for Recurring Donation Entry Form
    * @param parentId The parentId to use when creating the new RD record (if New from Acount or Contact)
    * @return Map<String, Object>
    */
    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getRecurringSettings(Id parentId) {
        String parentSObjectType = (parentId == null)
            ? null
            : parentId.getSobjectType().getDescribe().getName();

        DescribeFieldResult dfrPeriod = UTIL_Describe.getFieldDescribe(
            'npe03__Recurring_Donation__c', 'npe03__Installment_Period__c'
        );
        DescribeFieldResult dfrFrequency = UTIL_Describe.getFieldDescribe(
            'npe03__Recurring_Donation__c', UTIL_Namespace.StrTokenNSPrefix('InstallmentFrequency__c')
        );

        return new Map<String, Object> {
            'isAutoNamingEnabled' => RD2_NamingService.isAutomaticNamingEnabled,
            'isMultiCurrencyEnabled' => UserInfo.isMultiCurrencyOrganization(),
            'parentSObjectType' => parentSObjectType,
            'dayOfMonthLastDay' => RD2_Constants.DAY_OF_MONTH_LAST_DAY,
            'InstallmentPeriodPermissions' => new Map<String, Boolean> {
                    'Createable' => dfrPeriod.isCreateable(),
                    'Updateable' => dfrPeriod.isUpdateable(),
                    'Visible' => dfrPeriod.isAccessible()
                },
            'InstallmentFrequencyPermissions' => new Map<String, Boolean> {
                    'Createable' => dfrFrequency.isCreateable(),
                    'Updateable' => dfrFrequency.isUpdateable(),
                    'Visible' => dfrFrequency.isAccessible()
                }
        };
    }

    /**
    * @description Retrieve the donor type for an existing RD record
    * @param recordId RecurringDonation.RecordId
    * @return Map<String, Object> of specific type of RD data
    */
    @AuraEnabled
    public static Map<String, Object> getRecurringData(String recordId) {
        if (recordId == null) {
            return null;
        }

        npe03__Recurring_Donation__c rd;
        Map<String, Object> response = new Map<String, Object>();
        try {
            rd = getRecurringDonation(recordId);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }

        if (rd.npe03__Organization__r.RecordTypeId == hhRecordTypeId
            || (rd.npe03__Organization__c == null && rd.npe03__Contact__r.Account.RecordTypeId == hhRecordTypeId)
        ) {
            response.put('DonorType', 'Contact');
        } else {
            response.put('DonorType', 'Account');
        }

        response.put('Period', rd.npe03__Installment_Period__c);
        response.put('Frequency', rd.InstallmentFrequency__c);

        return response;
    }

    /**
    * @param recordId RecurringDonation.RecordId
    * @return Recurring Donation object
    */
    private static npe03__Recurring_Donation__c getRecurringDonation(Id recordId) {
        Set<String> queryFields = new Set<String>{
            'Id',
            'npe03__Installment_Period__c',
            'InstallmentFrequency__c',
            'npe03__Organization__c',
            'npe03__Organization__r.RecordTypeId',
            'npe03__Contact__r.Account.RecordTypeId'
        };

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id = :recordId')
            .withLimit(1)
            .build();

        return Database.query(soql);
    }

    /***
    * @description Retrieves the record type id for the household account record type
    */
    @TestVisible
    private static String hhRecordTypeId {
        get {
            if (hhRecordTypeId == null) {
                hhRecordTypeId = UTIL_CustomSettingsFacade.getContactsSettings().npe01__HH_Account_RecordTypeID__c;
            }
            return hhRecordTypeId;
        }
        private set;
    }
}