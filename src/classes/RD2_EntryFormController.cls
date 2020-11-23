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
    * @param parentId The parentId of the new RD
    * @return Map<String, Object>
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRecurringSettings(Id parentId) {
        String parentSObjectType = (parentId == null)
            ? null
            : parentId.getSobjectType().getDescribe().getName();

        // Checks whether the Elevate credit card can be displayed
        // on the form to enter a new Recurring Donation in NPSP and the related commitment in Elevate.
        // The RD2 controller should be using isIntegrationEnabled() only when GA.
        Boolean isElevateCustomer = RD2_ElevateIntegrationService.isIntegrationEnabled()
            && UTIL_FeatureEnablement.isPilotEnabled();

        return new Map<String, Object> {
            'isAutoNamingEnabled' => RD2_NamingService.isAutomaticNamingEnabled,
            'isMultiCurrencyEnabled' => UserInfo.isMultiCurrencyOrganization(),
            'parentSObjectType' => parentSObjectType,
            'InstallmentPeriodPermissions' => getFieldPermissionsMap('npe03__Installment_Period__c'),
            'InstallmentFrequencyPermissions' => getFieldPermissionsMap(UTIL_Namespace.StrTokenNSPrefix('InstallmentFrequency__c')),
            'customFieldSets' => getCustomFieldSectionFields(),
            'isElevateCustomer' => isElevateCustomer
        };
    }

    /**
    * @description Get a GUID to store as a temp Commitment Id
    * @return String
    */
    @AuraEnabled(cacheable=false)
    public static String getTempCommitmentId() {
        return RD2_ElevateIntegrationService.TEMP_COMMITMENT_ID_PREFIX + UTIL_String.getGUID();
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
            'npe03__Installments__c'
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
    * @description Builds an Elevate Commitment request body
    * @param recordId Recurring Donation Id
    * @param paymentMethodToken Payment Method Token
    * @return String: JSON containing the Commitment Request Body
    */
    @AuraEnabled
    public static String getCommitmentRequestBody(Id recordId, String paymentMethodToken) {
        try {
            return JSON.serialize(commitmentService.getRequestBody(recordId, paymentMethodToken));

        } catch (Exception ex) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(ex.getMessage());
        }

        return null;
    }

    /***
    * @description Creates Elevate Commitment and
    * updates the Recurring Donation with returned Commitment data
    * @param recordId Recurring Donation Id
    * @param jsonRequestBody JSON containing parameters for the commitment call request body
    * @return String: JSON containing the response with commitment data on success or error message on error
    */
    @AuraEnabled
    public static String createCommitment(Id recordId, String jsonRequestBody) {
        if (recordId == null) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(System.Label.RD2_ErrorRDIdIsMissingForCommitment);
        }

        UTIL_Http.Response response;

        try {
            response = commitmentService.sendRequest(recordId, jsonRequestBody);

            if (response.statusCode == UTIL_Http.STATUS_CODE_CREATED) {
                commitmentService.updateRecurringDonation(recordId, response);

            } else {
                processError(recordId, response.getErrorMessages());
            }

        } catch (Exception e) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(e.getMessage());

         }

        return JSON.serialize(response);
    }

    /**
    * @description Creates an error record for the specified record Id and error message
    * @param recordId Recurring Donation Id
    * @param errorMessage Error message
    * @return void
    */
    private static void processError(Id recordId, String errorMessage) {
        RD2_ElevateIntegrationService.Logger errorLogger = new RD2_ElevateIntegrationService.Logger();
        errorLogger.addError(
            recordId,
            errorMessage,
            RD2_ElevateIntegrationService.LOG_TYPE_COMMITMENT_CREATE
        );

        errorLogger.processErrors();
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

        /***
        * @description Builds an Elevate Commitment request body
        * @param recordId Recurring Donation Id
        * @param paymentMethodToken Payment Method Token
        * @return PS_CommitmentRequest.RequestBody
        */
        public PS_CommitmentRequest.RequestBody getRequestBody(Id recordId, String paymentMethodToken) {
            PS_CommitmentRequest request = new PS_CommitmentRequest();

            return request.getRequestBody(recordId, paymentMethodToken);
        }

        /***
        * @description Sends an HttpRequest so that matching Recurring Commitment is created in Elevate
        * @param jsonRequestBody JSON containing parameters for the commitment call request body
        * @return UTIL_Http.Response
        */
        public UTIL_Http.Response sendRequest(Id recordId, String jsonRequestBody) {
            UTIL_Http.Response response;

            try {
                HttpRequest request = new PS_CommitmentRequest()
                    .buildCreateRequest(jsonRequestBody);

                response = requestService.sendRequest(request);

            } catch (Exception ex) {
                response = requestService.buildErrorResponse(ex);
            }

            return response;
        }


        /***
        * @description Saves commitment Id and the credit card data onto the Recurring Donation record.
        * @param recordId Recurring Donation Id
        * @param response Response from Elevate on the commitment create request
        * @return void
        */
        public void updateRecurringDonation(Id recordId, UTIL_Http.Response response) {
            if (response == null
                || response.statusCode != UTIL_Http.STATUS_CODE_CREATED
            ) {
                return;
            }

            try {
                PS_CommitmentRequest.ResponseBody commitment = new PS_CommitmentRequest().getCommitment(response);

                if (commitment.hasId()) {
                    npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
                        Id = recordId,
                        CommitmentId__c = commitment.id,
                        CardLast4__c = commitment.getCardLast4(),
                        CardExpirationMonth__c = commitment.getCardExpirationMonth(),
                        CardExpirationYear__c = commitment.getCardExpirationYear()
                    );

                    UTIL_DMLService.updateRecordBatchAndLogErrors(
                        new List<npe03__Recurring_Donation__c>{ rd }, ERR_Handler_API.Context.Elevate.name()
                    );
                }
            } catch (Exception e) {
                throw e;
            }

           
        }
    }

}