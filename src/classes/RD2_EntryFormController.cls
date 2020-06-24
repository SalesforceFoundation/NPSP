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
    * @description Set of fields that will be excluded from the RD2_EntryForm Custom Field Section
    */
    private static Set<String> excludedCustomFields = new Set<String> {
        'Name',
        'Id',
        'CurrencyIsoCode'
    };

    /**
    * @description  Gather the org setting for Recurring Donation Entry Form
    * @param parentId The parentId of the new RD
    * @return Map<String, Object>
    */
    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getSetting(Id parentId) {
        String parentSObjectType = (parentId == null)
            ? null
            : parentId.getSobjectType().getDescribe().getName();

        return new Map<String, Object> {
            'isAutoNamingEnabled' => RD2_NamingService.isAutomaticNamingEnabled,
            'isMultiCurrencyEnabled' => UserInfo.isMultiCurrencyOrganization(),
            'parentSObjectType' => parentSObjectType,
            'dayOfMonthLastDay' => RD2_Constants.DAY_OF_MONTH_LAST_DAY,
            'customFieldSets' => getCustomFields()
        };
    }

    /**
    * @description Retrieve the donor type for an existing RD record
    * @param recordId RecurringDonation.RecordId
    * @return Account (if Org is not a Household) or Contact
    */
    @AuraEnabled(Cacheable=true)
    public static String getDonorType(String recordId) {
        if (recordId == null) {
            return null;
        }

        try {
            npe03__Recurring_Donation__c rd = getRecurringDonation(recordId);
            if (rd.npe03__Organization__r.RecordTypeId == hhRecordTypeId
                || (rd.npe03__Organization__c == null && rd.npe03__Contact__r.Account.RecordTypeId == hhRecordTypeId)
            ) {
                return 'Contact';
            }
            return 'Account';
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
    * @param recordId RecurringDonation.RecordId
    * @return Recurring Donation object
    */
    private static npe03__Recurring_Donation__c getRecurringDonation(Id recordId) {
        Set<String> queryFields = new Set<String>{
            'Id',
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

    /***
    * @description Retrieve RD2_Entry_Form_Custom_Fields Fieldset and eliminate any packaged and already displayed fields
    * @return List<CustomField>
    */
    private static List<CustomField> getCustomFields () {
        List<CustomField> fields = new List<CustomField>();
        List<Schema.FieldSetMember> fieldSetFields = Schema.SObjectType.npe03__Recurring_Donation__c.fieldSets.getMap().get('RD2_Entry_Form_Custom_Fields').getFields();

        for (Schema.FieldSetMember field : fieldSetFields) {
            if (field.getFieldPath().startsWith('npsp__')
                || field.getFieldPath().startsWith('npe03__')
                || excludedCustomFields.contains(field.getFieldPath())) {
                continue;
            }

            fields.add(new CustomField(field.getFieldPath(), field.getDbRequired() || field.getRequired()));
        }

        return fields;
    }

    /***
    * @description Wrapper class for custom field info
    */
    public class CustomField {
        @AuraEnabled public String apiName;
        @AuraEnabled public Boolean required;

        /***
        * @description Constructor for the CustomField class
        * @param apiName Api name of the field
        * @param required Indicate if the field is required 
        */
        public CustomField(String apiName, Boolean required) {
            this.apiName = apiName;
            this.required = required;
        }
    }
}