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
    @TestVisible
    private static Set<String> excludedCustomFields = new Set<String> {
        'CreatedById',
        'CreatedDate',
        'CurrencyIsoCode',
        'Id',
        'IsDeleted',
        'LastModifiedById',
        'LastModifiedDate',
        'LastReferencedDate',
        'LastViewedDate',
        'Name',
        'OwnerId',
        'SystemModStamp'
    };

    /**
    * @description Handles commitment request creation, response parsing and RD Commitment Id update
    */
    private static CommitmentService commitmentService {
        get {
            if (commitmentService == null) {
                commitmentService = new CommitmentService();
            }
            return commitmentService;
        }
        set;
    }


    /**
    * @description  Gather the org, object and environment setting for Recurring Donation Entry/Edit Form
    * @param parentId The Contact or Account Id for which Recurring Donation will be created
    * @param recordId Recurring Donation Id
    * @return Map<String, Object>
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRecurringSettings(Id parentId, Id recordId) {
        String parentSObjectType = (parentId == null)
            ? null
            : parentId.getSobjectType().getDescribe().getName();
            
        Map<String, Object> data = new Map<String, Object>{
            'isAutoNamingEnabled' => RD2_NamingService.isAutomaticNamingEnabled,
            'isMultiCurrencyEnabled' => UserInfo.isMultiCurrencyOrganization(),
            'parentSObjectType' => parentSObjectType,
            'InstallmentPeriodPermissions' => getFieldPermissionsMap('npe03__Installment_Period__c'),
            'InstallmentFrequencyPermissions' => getFieldPermissionsMap(UTIL_Namespace.StrTokenNSPrefix('InstallmentFrequency__c')),
            'customFieldSets' => getCustomFieldSectionFields()
        };

        Boolean isElevateCustomer = RD2_ElevateIntegrationService.isElevateCreateEnabled();
        data.put('isElevateCustomer', isElevateCustomer);

        if (isElevateCustomer && recordId != null) {
            data.put('commitmentId', getCommitmentId(recordId));
        }

        return data;
    }

    /**
    * @description Get the Elevate recurring commitment Id
    * @return String
    */
    public static String getCommitmentId(Id recordId) {
        String commitmentId;

        try {
            npe03__Recurring_Donation__c rd = getRecurringDonation(recordId);
            commitmentId = rd.CommitmentId__c;

        } catch (Exception ex) {            
            UTIL_AuraEnabledCommon.throwAuraHandledException(ex.getMessage());
        }

        return commitmentId;
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
        response.put('RecurringType', rd.RecurringType__c);
        response.put('NumInstallments', rd.npe03__Installments__c);

        return response;
    }

    /**
     * @description Validate that the current user has Read access to a specific set of required fields. If this returns
     * false, the custom UI will display a warning message at the top of the page.
     * @return True if the User has Read access to all required fields in the UI
     */
    @AuraEnabled(cacheable=true)
    public static Boolean hasRequiredFieldPermissions() {
        Set<String> requiredFields = new Set<String>{
            'npe03__Amount__c',
            'npe03__Contact__c',
            'npe03__Installment_Period__c',
            'npe03__Date_Established__c',
            UTIL_Namespace.StrTokenNSPrefix('InstallmentFrequency__c'),
            UTIL_Namespace.StrTokenNSPrefix('Day_of_Month__c'),
            UTIL_Namespace.StrTokenNSPrefix('StartDate__c')
        };

        Boolean hasPermissions = true;

        for (String fld : requiredFields) {
            DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe('npe03__Recurring_Donation__c', fld);
            if (!dfr.isAccessible()) {
                hasPermissions = false;
                break;
            }
        }

        return hasPermissions;
    }

    /**
    * @param recordId RecurringDonation.RecordId
    * @return Recurring Donation object
    */
    private static npe03__Recurring_Donation__c getRecurringDonation(Id recordId) {
        Set<String> queryFields = new Set<String>{
            'Id',
            'RecurringType__c',
            'npe03__Installment_Period__c',
            'InstallmentFrequency__c',
            'npe03__Organization__c',
            'npe03__Organization__r.RecordTypeId',
            'npe03__Contact__r.Account.RecordTypeId',
            'npe03__Installments__c',
            'CommitmentId__c'
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

    /**
     * @description Build a map of field permissions for use by LWC so it can validate access permission
     * for custom picklist fields without a return trip to server. Fields using lightning-input-field do not
     * require this additional check.
     * @param fieldApiName Field ApiName
     * @return Map<String, Object> of field permissions
     */
    private static Map<String, Boolean> getFieldPermissionsMap(String fieldApiName) {
        DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe('npe03__Recurring_Donation__c', fieldApiName);
        return new Map<String, Boolean>{
            'Createable' => dfr.isCreateable(),
            'Updateable' => dfr.isUpdateable(),
            'Visible' => dfr.isAccessible()
        };
    }

    /***
    * @description Retrieve RD2_Entry_Form_Custom_Fields Fieldset and eliminate any packaged and already displayed fields
    * @return List<CustomField>
    */
    @TestVisible
    private static List<CustomField> getCustomFieldSectionFields () {
        List<CustomField> fields = new List<CustomField>();
        List<Schema.FieldSetMember> fieldSetFields = Schema.SObjectType.npe03__Recurring_Donation__c.fieldSets.RD2_Entry_Form_Custom_Fields.getFields();

        for (Schema.FieldSetMember field : fieldSetFields) {
            if (excludedCustomFields.contains(field.getFieldPath())
                || field.getFieldPath().startsWith('npsp__')
                || field.getFieldPath().startsWith('npe03__')
                || !UTIL_Describe.getFieldDescribe('npe03__Recurring_Donation__c', field.getFieldPath()).isAccessible()
            ) {
                continue;
            }

            fields.add(new CustomField(field));
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
        public CustomField(Schema.FieldSetMember field) {
            this.apiName = field.getFieldPath();
            this.required = field.getDbRequired() || field.getRequired();
        }
    }


    /***
    * @description Constructs the Recurring Donation based on the entry form fields.
    * Validates the Recurring Donation and creates or updates the commitments depending
    * if it is a new or existing recurring commitment in Elevate.
    * @param recordId Recurring Donation Id
    * @param jsonRecord Recurring Donation fields as entered by the user before the record is saved
    * @param paymentMethodToken Payment Method Token
    * @return String Commitment create/update response
    */
    @AuraEnabled
    public static String handleCommitment(Id recordId, String jsonRecord, String paymentMethodToken) {
        npe03__Recurring_Donation__c rd = constructRecurringDonation(recordId, jsonRecord);
        
        validate(rd);

        PS_CommitmentRequest.RequestBody requestBody = getRequestBody(rd, paymentMethodToken);
        
        return processCommitment(recordId, rd.CommitmentId__c, JSON.serialize(requestBody));
    }


    private static npe03__Recurring_Donation__c constructRecurringDonation(Id recordId, String jsonRecord) {
        npe03__Recurring_Donation__c rd = (npe03__Recurring_Donation__c) JSON.deserialize(
            jsonRecord, npe03__Recurring_Donation__c.class
        );

        if (recordId != null) {
            rd.Id = recordId;
        }

        if (String.isBlank(rd.Status__c)) {
            rd.Status__c = 'Active';//TODO populate defaults that DML does by default, currency? etc.
        }

        return rd;
    }

    @TestVisible
    private static void validate(npe03__Recurring_Donation__c rd) {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{ rd };
        List<npe03__Recurring_Donation__c> oldRds = rd.Id == null
            ? new List<npe03__Recurring_Donation__c>()
            : new RD2_QueryService().getRecurringDonationsBase(new Set<Id>{ rd.Id });

        RD2_RecurringDonations_TDTM.DataAuditor auditor = new RD2_RecurringDonations_TDTM.DataAuditor();        
        auditor.adjust(rds, oldRds);

        List<RD2_ValidationService.Notification> notifications = auditor.validate(rds, oldRds);

        if (!notifications.isEmpty()) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(
                notifications[0].getErrors()[0]
            );
        }        
    }

    @TestVisible
    private static PS_CommitmentRequest.RequestBody getRequestBody(npe03__Recurring_Donation__c rd, String paymentMethodToken) {
        try {
            PS_CommitmentRequest request = new PS_CommitmentRequest();

            return request.getRequestBody(rd, paymentMethodToken);

        } catch (Exception ex) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(ex.getMessage());
        }

        return null;
    }
    
    @TestVisible
    private static String processCommitment(Id recordId, String commitmentId, String jsonRequestBody) {
        UTIL_Http.Response response;

        try {
            response = sendRequest(commitmentId, jsonRequestBody);

            if (response.statusCode != UTIL_Http.STATUS_CODE_CREATED) {
                processError(recordId, response.getErrorMessages());
            }

        } catch (Exception e) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(e.getMessage());
         }

        return JSON.serialize(response);
    }

    @TestVisible
    private static UTIL_Http.Response sendRequest(String commitmentId, String jsonRequestBody) {
        UTIL_Http.RequestService requestService = new UTIL_Http.RequestService();
        UTIL_Http.Response response;

        try {
            HttpRequest request = new PS_CommitmentRequest()
                .buildRequest(commitmentId, jsonRequestBody);

            response = requestService.sendRequest(request);

        } catch (Exception ex) {
            response = requestService.buildErrorResponse(ex);
        }

        return response;
    }


    /**
    * @description Creates an error record for the specified record Id and error message
    * @param recordId Recurring Donation Id
    * @param errorMessage Error message
    * @return void
    */
    private static void processError(Id recordId, String errorMessage) {
        ERR_LogService.Logger logger = new ERR_LogService.Logger(
            ERR_Handler_API.Context.Elevate,
            npe03__Recurring_Donation__c.SObjectType
        );

        logger.addError(
            recordId,
            errorMessage,
            RD2_ElevateIntegrationService.LOG_TYPE_COMMITMENT_CREATE
        );

        logger.processErrors();
    }
    

    /**
    * @description Handles sending commitment request and saving its values on the RD
    */
    public without sharing class CommitmentService {

        /**
        * @description Sends requests and constructs the response
        */
        private UTIL_Http.RequestService requestService {
            get {
                if (requestService == null) {
                    requestService = new UTIL_Http.RequestService();
                }
                return requestService;
            }
            set;
        }
    }

}