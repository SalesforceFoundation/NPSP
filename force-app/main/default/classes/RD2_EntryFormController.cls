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
    * @description Handles commitment request creation, response parsing and RD Commitment Id update
    */
    private static RD2_CommitmentService commitmentService {
        get {
            if (commitmentService == null) {
                commitmentService = new RD2_CommitmentService();
            }
            return commitmentService;
        }
        set;
    }

    @TestVisible
    private static RD2_QueryService selector {
        get {
            if (selector == null) {
                selector = new RD2_QueryService();
            }
            return selector;
        }
        set;
    }

    private static RD2_Settings settings {
        get {
            if (settings == null) {
                settings = RD2_Settings.getInstance();
            }
            return settings;
        }
        set;
    }

    @TestVisible
    private static UTIL_Permissions permissions {
        get {
            if (permissions == null) {
                permissions = UTIL_Permissions.getInstance();
            }
            return permissions;
        }
        set;
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

    @AuraEnabled
    public static RD2_AppView getInitialView(Id parentId, Id recordId) {
        RD2_AppView view = new RD2_AppView();

        view.hasRequiredPermissions = hasRequiredFieldPermissions();
        if (!view.hasRequiredPermissions) {
            return view;
        }

        view.isAutoNamingEnabled = RD2_NamingService.isAutomaticNamingEnabled;
        view.isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        view.parentSObjectType = (parentId == null) ? null : UTIL_Describe.objectNameFromId(parentId);
        view.InstallmentPeriodPermissions = getFieldPermissionsMap('npe03__Installment_Period__c');
        view.InstallmentFrequencyPermissions = getFieldPermissionsMap(String.valueOf(npe03__Recurring_Donation__c.InstallmentFrequency__c));
        view.customFieldSets = getCustomFieldSectionFields();
        view.isElevateCustomer = RD2_ElevateIntegrationService.isIntegrationEnabled();
        view.isChangeLogEnabled = RD2_ChangeLogService.isChangeLogEnabled;
        view.periodToYearlyFrequencyMap = RD2_Constants.PERIOD_TO_YEARLY_FREQUENCY;
        view.closedStatusValues = new List<String>(RD2_StatusMapper.getInstance().getClosedStatusValues());
        view.defaultRecurringType = UTIL_Describe.getDefaultSelectOption(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.RecurringType__c)
        );
        view.defaultInstallmentPeriod = UTIL_Describe.getDefaultSelectOption(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.npe03__Installment_Period__c)
        );
        view.defaultDayOfMonth = UTIL_Describe.getDefaultSelectOption(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.Day_of_Month__c)
        );

        if (recordId != null) {
            npe03__Recurring_Donation__c rd = selector.getRecurringDonationForUI(recordId);
            view.withRecord(rd);
            view.record.donorType = getDonorType(rd);
            if (view.isMultiCurrencyEnabled) {
                view.record.currencyIsoCode = (String)rd.get('CurrencyIsoCode');
            }
        } else if (parentId != null) {
            view.withParentId(parentId);
        }

        view.setRecordCreateDefaults();

        return view;
    }

    public String getDefaultInstallmentPeriod() {
        return UTIL_Describe.getDefaultSelectOption('npe03__Recurring_Donation__c', 'npe03__Installment_Period__c');
    }

    public List<Map<String, String>> getInstallmentPeriodPicklistValues() {
        return UTIL_Describe.getLightningSelectOptions('npe03__Recurring_Donation__c','npe03__Installment_Period__c');
    }

    private static String getDonorType(npe03__Recurring_Donation__c rd) {
        String donorType = isContactDonor(rd) ? RD2_Constants.DONOR_TYPE_CONTACT : RD2_Constants.DONOR_TYPE_ACCOUNT;
        return donorType;
    }

    private static Boolean isContactDonor(npe03__Recurring_Donation__c rd) {
        Boolean isContactDonor = rd.npe03__Organization__r.RecordTypeId == hhRecordTypeId
                || (rd.npe03__Organization__c == null && rd.npe03__Contact__r.Account.RecordTypeId == hhRecordTypeId);
        return isContactDonor;
    }

    @TestVisible
    private static Boolean hasRequiredSavePermissions(RD2_SaveRequest request) {
        Set<String> requiredFields = new Set<String>{
                String.valueOf(npe03__Recurring_Donation__c.Status__c),
                String.valueOf(npe03__Recurring_Donation__c.ClosedReason__c),
                String.valueOf(npe03__Recurring_Donation__c.npe03__Contact__c),
                String.valueOf(npe03__Recurring_Donation__c.npe03__Organization__c),
                String.valueOf(npe03__Recurring_Donation__c.npe03__Date_Established__c),
                String.valueOf(npe03__Recurring_Donation__c.npe03__Amount__c),
                String.valueOf(npe03__Recurring_Donation__c.npe03__Installment_Period__c),
                String.valueOf(npe03__Recurring_Donation__c.InstallmentFrequency__c),
                String.valueOf(npe03__Recurring_Donation__c.StartDate__c),
                String.valueOf(npe03__Recurring_Donation__c.Day_of_Month__c),
                String.valueOf(npe03__Recurring_Donation__c.npe03__Installments__c),
                String.valueOf(npe03__Recurring_Donation__c.RecurringType__c),
                String.valueOf(npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c),
                String.valueOf(npe03__Recurring_Donation__c.PaymentMethod__c)
        };
        requiredFields.addAll(request.getCustomFieldNamesForPermissionCheck());
        return permissions.canUpdate(npe03__Recurring_Donation__c.SObjectType, requiredFields);
    }

    /**
     * @description Validate that the current user has Read access to a specific set of required fields. If this returns
     * false, the custom UI will display a warning message at the top of the page.
     * @return True if the User has Read access to all required fields in the UI
     */
    @TestVisible
    private static Boolean hasRequiredFieldPermissions() {
        Set<String> requiredFields = new Set<String>{
            String.valueOf(npe03__Recurring_Donation__c.npe03__Amount__c),
            String.valueOf(npe03__Recurring_Donation__c.npe03__Contact__c),
            String.valueOf(npe03__Recurring_Donation__c.npe03__Installment_Period__c),
            String.valueOf(npe03__Recurring_Donation__c.npe03__Date_Established__c),
            String.valueOf(npe03__Recurring_Donation__c.InstallmentFrequency__c),
            String.valueOf(npe03__Recurring_Donation__c.Day_of_Month__c),
            String.valueOf(npe03__Recurring_Donation__c.StartDate__c)
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
     * @description Build a map of field permissions for use by LWC so it can validate access permission
     * for custom picklist fields without a return trip to server. Fields using lightning-input-field do not
     * require this additional check.
     * @param fieldApiName Field ApiName
     * @return Map<String, Boolean> of field permissions
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
    * @return List<InputFieldView> of custom fields.
    */
    @TestVisible
    private static List<InputFieldView> getCustomFieldSectionFields() {
        List<InputFieldView> fields = new List<InputFieldView>();

        for (Schema.FieldSetMember field : settings.getCustomFieldSetMembers()) {
            fields.add(new InputFieldView(field));
        }

        return fields;
    }

    @AuraEnabled
    public static SaveResultView saveRecurringDonation(RD2_SaveRequest saveRequest) {
        npe03__Recurring_Donation__c rd = saveRequest.removeNonCreateableCustomFields().toRecord();
        Database.SaveResult sr;

        if (!hasRequiredSavePermissions(saveRequest)) {
            return new SaveResultView(Label.commonAccessErrorMessage);
        }

        if (rd.Id != null) {
            sr = Database.update(rd, false);
        } else {
            sr = Database.insert(rd, false);
        }

        if (sr.success) {
            npe03__Recurring_Donation__c record = selector.getRecurringDonationForUI(rd.Id);
            return new SaveResultView(sr, record);
        } else {
            return new SaveResultView(sr);
        }
    }

    /***
    * @description Constructs a Recurring Donation record based on the entry form fields, and
    * submits the create or edit commitment request to the Elevate Payments API.
    * @param jsonRecord Recurring Donation fields as entered by the user before the record is saved
    * @param paymentMethodToken Payment Method Token
    * @return String Commitment API response
    */
    @AuraEnabled
    public static String handleCommitment(String jsonRecord, String paymentMethodToken) {
        try {
            npe03__Recurring_Donation__c rd = (npe03__Recurring_Donation__c) JSON.deserialize(
                jsonRecord, npe03__Recurring_Donation__c.class
            );

            npe03__Recurring_Donation__c oldRd;
            if (rd.Id != null) {
                 oldRd = selector.getRecurringDonationForUI(rd.Id);
            }

            commitmentService.adjustAndValidateRD(rd, oldRd);
            UTIL_Http.Response response = commitmentService.handleCommitment(rd, oldRd, paymentMethodToken);

            return JSON.serialize(response);

        } catch (Exception ex) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(ex.getMessage());
        }

        return null;
    }

    /***
    * @description Constructs a Recurring Donation record based on the json record, and
    * submits the update payment commitment request to the Elevate Payments API.
    * @param jsonRecord Recurring Donation fields as entered by the user before the record is saved
    * @param paymentMethodToken Payment Method Token
    * @return String Commitment API response
    */
    @AuraEnabled
    public static String handleUpdatePaymentCommitment(String jsonRecord, String paymentMethodToken) {
        try {
            npe03__Recurring_Donation__c rd =  (npe03__Recurring_Donation__c) JSON.deserialize(
                jsonRecord, npe03__Recurring_Donation__c.class
            );

            UTIL_Http.Response response = commitmentService.handleCommitment(rd, null, paymentMethodToken);

            return JSON.serialize(response);

        } catch (Exception ex) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(ex.getMessage());
        }

        return null;
    }

    /***
    * @description Logs an error when a Recurring Donation cannot be created/updated
    * @param recordId A Recurring Donation, or a donor (Contact/Account) Id
    * @param errorMessage An error message
    */
    @AuraEnabled
    public static void logError(Id recordId, String errorMessage) {
        commitmentService.logError(recordId, errorMessage);
    }



}
