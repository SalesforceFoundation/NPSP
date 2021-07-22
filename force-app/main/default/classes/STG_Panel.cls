/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Settings
* @group-content ../../ApexDocContent/Settings.htm
* @description Controller for the base settings panel class.
*/
public with sharing virtual class STG_Panel {

    /*******************************************************************************************************
    * @description Class constructor
    */
	public STG_Panel() {
		//UTIL_Debug.debug('***** STG_Panel constructor');
		isEditMode = false;
	}

    /*******************************************************************************************************
    * @description the id of the panel, which we assume all derived classes will override.
    */
	public virtual string idPanel() { return null; }

    /*******************************************************************************************************
    * @description Opportunity object label
    */
    static public string oppLabel {
        get {
            if(oppLabel == null){
                oppLabel = Schema.sObjectType.Opportunity.getLabel();
            }
            return oppLabel;
        } private set;
    }

    /*******************************************************************************************************
    * @description Payment object label
    */
	static public string paymentLabel {
        get {
            if(paymentLabel == null){
                paymentLabel = Schema.sObjectType.npe01__OppPayment__c.getLabel();
            }
            return paymentLabel;
        } private set;
    }

    /*******************************************************************************************************
    * @description is the panel in Edit Mode
    */
	public boolean isEditMode { get; set; }

    /*******************************************************************************************************
    * @description is the panel in Read Only Mode
    */
	public boolean isReadOnlyMode {
		get {
			return !isEditMode;
		} private set;
	}

    /***
    * @description Verifies the user has Admin permissions for Opportunity naming settings.
    * @return true when the user has the appropriate access
    */
    public Boolean isRunningUserIsAdmin {
        get {
            if (isRunningUserIsAdmin == null) {
                isRunningUserIsAdmin = runningUserIsAdmin();
            }
            return isRunningUserIsAdmin;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description Checks if Enhanced Recurring Donations are enabled
    */
    public Boolean isRD2Enabled {
        get {
            return RD2_EnablementService.isRecurringDonations2Enabled;
        } private set;
    }

    /*******************************************************************************************************
    * @description the shared Settings Service object panels should use.
    */
    static public STG_SettingsService stgService {
        get {
            if (stgService == null) {
            	stgService = STG_SettingsService.stgService;
            }
            return stgService;
        } set;
    }

    /*******************************************************************************************************
    * @description Action Method to save all settings changes in the Settings Service.  Derived classes can override, if
    * they need to do any custom saving first.
    * @return void
    */
    public virtual PageReference saveSettings() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
	        stgService.saveAll();
	        isEditMode = false;
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;

    }

    /*******************************************************************************************************
    * @description Action Method to put the current page into Edit mode.
    * @return null
    */
    public virtual PageReference editSettings() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        isEditMode = true;
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to cancel the current page's Edit mode.
    * @return null
    */
    public virtual PageReference cancelEdit() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        isEditMode = false;
        return null;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for the Account Model.
    */
    static public list<SelectOption> listSOAccountModels {
        get {
            if (listSOAccountModels == null) {
                listSOAccountModels = new list<SelectOption>();
                listSOAccountModels.add(new SelectOption(CAO_Constants.HH_ACCOUNT_PROCESSOR, CAO_Constants.HH_ACCOUNT_PROCESSOR));
                listSOAccountModels.add(new SelectOption(CAO_Constants.ONE_TO_ONE_PROCESSOR, CAO_Constants.ONE_TO_ONE_PROCESSOR));
                listSOAccountModels.add(new SelectOption(CAO_Constants.BUCKET_PROCESSOR, CAO_Constants.BUCKET_PROCESSOR));
            }
            return listSOAccountModels;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Household Object Creation Rules
    */
    static public list<SelectOption> listSOHHRules {
        get {
            if (listSOHHRules == null) {
                listSOHHRules = new list<SelectOption>();
                listSOHHRules.add(new SelectOption(HH_Households.ALL_PROCESSOR, HH_Households.ALL_PROCESSOR));
                listSOHHRules.add(new SelectOption(HH_Households.ALL_INDIVIDUALS_PROCESSOR, HH_Households.ALL_INDIVIDUALS_PROCESSOR));
                listSOHHRules.add(new SelectOption(HH_Households.NO_HOUSEHOLDS_PROCESSOR, HH_Households.NO_HOUSEHOLDS_PROCESSOR));
            }
            return listSOHHRules;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Contact Record Types
    */
    static public list<SelectOption> listSOContactRecTypes {
        get {
            if (listSOContactRecTypes == null) {
                listSOContactRecTypes = new list<SelectOption>();
                listSOContactRecTypes.add(new SelectOption('', Label.stgLabelNone));
                listSOContactRecTypes.addAll(UTIL_RecordTypes.getStringRecordTypesForSelectList(Contact.sObjectType));
            }
            return listSOContactRecTypes;
        }
        private set;
    }

    /*
    * @description list of SelectOptions for Contact Record Type Ids
    */
    static public List<SelectOption> listSOContactRecTypeIds {
        get {
            if (listSOContactRecTypeIds == null) {
                listSOContactRecTypeIds = new list<SelectOption>();
                listSOContactRecTypeIds.add(new SelectOption('', Label.stgLabelNone));
                listSOContactRecTypeIds.addAll(UTIL_RecordTypes.getRecordTypesForSelectList(Contact.sObjectType));
            }
            return listSOContactRecTypeIds;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Acount Record Type Ids
    */
    static public list<SelectOption> listSOAccountRecTypeIds {
        get {
            if (listSOAccountRecTypeIds == null) {
                listSOAccountRecTypeIds = new list<SelectOption>();
                listSOAccountRecTypeIds.add(new SelectOption('', Label.stgLabelNone));
                listSOAccountRecTypeIds.addAll(UTIL_RecordTypes.getRecordTypesForSelectList(Account.sObjectType));
            }
            return listSOAccountRecTypeIds;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Opportunity Record Types
    */
    static public list<SelectOption> listSOOppRecTypes {
        get {
            if (listSOOppRecTypes == null) {
                listSOOppRecTypes = new list<SelectOption>();
                listSOOppRecTypes.add(new SelectOption('', Label.stgLabelNone));
                listSOOppRecTypes.addAll(UTIL_RecordTypes.getStringRecordTypesForSelectList(Opportunity.sObjectType));
            }
            return listSOOppRecTypes;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Opportunity Record Type Ids
    */
    static public list<SelectOption> listSOOppRecTypesIds {
        get {
            if (listSOOppRecTypesIds == null) {
                listSOOppRecTypesIds = new list<SelectOption>();
                listSOOppRecTypesIds.add(new SelectOption('', Label.stgLabelNone));
                listSOOppRecTypesIds.addAll(UTIL_RecordTypes.getRecordTypesForSelectList(Opportunity.sObjectType));
            }
            return listSOOppRecTypesIds;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Allocation Level setting
    */
    static public list<SelectOption> listSOAllocationLevels {
        get {
            if (listSOAllocationLevels == null) {
                listSOAllocationLevels = new list<SelectOption>();
                listSOAllocationLevels.add(new SelectOption(oppLabel, oppLabel));
                listSOAllocationLevels.add(new SelectOption(paymentLabel, paymentLabel));
            }
            return listSOAllocationLevels;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Opportunity Contact Roles
    */
    static public list<SelectOption> listSOOppContactRoles {
        get {
            if (listSOOppContactRoles == null) {
                listSOOppContactRoles = new list<SelectOption>();
                listSOOppContactRoles.add(new SelectOption('', Label.stgLabelNone));
                Schema.DescribeFieldResult F = Schema.sObjectType.OpportunityContactRole.fields.Role;
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for(Schema.PicklistEntry pe : P) {
                    listSOOppContactRoles.add(new SelectOption(pe.getValue(), pe.getLabel()));
                }
            }
            return listSOOppContactRoles;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Opportunity Contact Roles
    */
    static public list<SelectOption> listSOContactRoles {
        get {
            if (listSOContactRoles == null) {
                listSOContactRoles = new list<SelectOption>();
                listSOContactRoles.add(new SelectOption('', Label.stgLabelNone));
                Schema.DescribeFieldResult F = Schema.sObjectType.OpportunityContactRole.fields.Role;
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for(Schema.PicklistEntry pe : P) {
                    listSOContactRoles.add(new SelectOption(pe.getValue(), pe.getLabel()));
                }
            }
            return listSOContactRoles;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Opportunity Types
    */
    static public list<SelectOption> listSOOppTypes {
    	get {
	        if (listSOOppTypes == null) {
	            listSOOppTypes = new list<SelectOption>();
	            listSOOppTypes.add(new SelectOption('', Label.stgLabelNone));
	            Schema.DescribeFieldResult F = Schema.sObjectType.Opportunity.fields.Type;
	            list<Schema.PicklistEntry> P = F.getPicklistValues();

	            for (Schema.PicklistEntry plistentry: P) {
	                listSOOppTypes.add(new SelectOption(plistentry.getValue(),plistentry.getLabel()));
	            }
	        }
	        return listSOOppTypes;
    	}
    	private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Relationships Types
    */
     static public list<SelectOption> listSORelTypes {
        get {
            if (listSORelTypes == null) {
                listSORelTypes = new list<SelectOption>();
                listSORelTypes.add(new SelectOption('', Label.stgLabelNone));
                Schema.DescribeFieldResult F = Schema.sObjectType.npe4__Relationship__c.fields.npe4__Type__c;
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for (Schema.PicklistEntry pe : P) {
                    listSORelTypes.add(new SelectOption(pe.getValue(), pe.getLabel()));
                }
            }
            return listSORelTypes;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Campaign Types
    */
     static public list<SelectOption> listSOCampaignTypes {
        get {
            if (listSOCampaignTypes == null) {
                listSOCampaignTypes = new list<SelectOption>();
                listSOCampaignTypes.add(new SelectOption('', Label.stgLabelNone));
                Schema.DescribeFieldResult F = Schema.sObjectType.Campaign.fields.Type;
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for (Schema.PicklistEntry pe : P) {
                    listSOCampaignTypes.add(new SelectOption(pe.getValue(), pe.getLabel()));
                }
            }
            return listSOCampaignTypes;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description list of SelectOptions for Mailing Report Ids (mail is in the report name)
    */
    static public list<SelectOption> listSOMailingReportIds {
        get {
            if (listSOMailingReportIds == null) {
                listSOMailingReportIds = new list<SelectOption>();
                listSOMailingReportIds.add(new SelectOption('', Label.stgLabelNone));
                for (Report rpt : [SELECT Id, Name, DeveloperName, NamespacePrefix FROM Report WHERE Name LIKE '%mail%']) {
                    if (rpt.NamespacePrefix == 'npo02' && rpt.DeveloperName == 'NPSP_Campaign_Household_Mailing_List') {
                        // The original report included in the Households package is no longer compatible with
                        // the Household Mailing List button so exclude it from this picklist.
                        continue;
                    }
                    listSOMailingReportIds.add(new SelectOption(rpt.Id, rpt.Name));
                }
            }
            return listSOMailingReportIds;
        }
        private set;
    }

    /**
     * @description Given an sObjectType and a list of semicolon ';' separated
     * ids corresponding to record types, return a comma ',' separated string
     * that contain the names of those record types.  If the given idValues
     * string is blank, the given blankValue will be returned.
     *
     * @param Schema.sObjectType The object type to which the record types apply
     * @param idValues A semicolon separated string of ids
     * @param blankValue The string returned when the given idValues string is blank
     * @return String
     */
    public static String getRecordTypeNamesFromPicklistString(Schema.sObjectType objectType, String idValues, String blankValue) {
        if (idValues == null) {
            return blankValue;
        }

        Map<Id, Schema.RecordTypeInfo> recordTypes = objectType.getDescribe().getRecordTypeInfosById();
        List<String> recordTypeIdStrings = idValues.split(';', 0);
        List<String> recordTypeNames = new List<String>();

        for (String recordTypeIdString : recordTypeIdStrings) {
            Id recordTypeId;

            if (recordTypeIdString instanceof Id) {
                recordTypeId = (Id) recordTypeIdString;
            } else {
                continue;
            }

            if (recordTypes.containsKey(recordTypeId)) {
                recordTypeNames.add(recordTypes.get(recordTypeId).getName());
            }
        }

        if (recordTypeNames.isEmpty()) {
            return blankValue;
        } else {
            return String.join(recordTypeNames, ', ');
        }
    }

    /**
     * @description Given an sObjectType and a list of semicolon ';' separated
     * ids corresponding to record types, return a comma ',' separated string
     * that contain the names of those record types.
     *
     * @param Schema.sObjectType The object type to which the record types apply
     * @param idValues A semicolon separated string of ids
     * @return String
     */
    public static String getRecordTypeNamesFromPicklistString(Schema.sObjectType objectType, String idValues) {
        return getRecordTypeNamesFromPicklistString(objectType, idValues, Label.stgLabelNone);
    }

    /*******************************************************************************************************
    * @description Returns whether the running user is a System Administrator.
    * @return boolean
    */
    public static Boolean runningUserIsAdmin() {

        Id runningUserId = UserInfo.getUserId();
        Id runningUserProfileId = UserInfo.getProfileId();
        return USER_UserService.isSysAdmin(new List<User>{(new User(Id = runningUserId, ProfileId = runningUserProfileId))}).get(runningUserId);

    }

    /*******************************************************************************************************
    * @description Get the label of the picklist value
    * @param objectName The Sobject name of the picklist field
    * @param fieldName The field name of the picklist field
    * @param apiValue The value of the picklist field
    * @return String The label value of the picklist field
    */
    public static String getPicklistLabelFromValue(String objectName, String fieldName, String apiValue) {
        Schema.DescribeFieldResult fieldResult = UTIL_Describe.getFieldDescribe(objectName, fieldName);
        
        if (fieldResult.getType() !== Schema.DisplayType.PICKLIST && fieldResult.getType() !== Schema.DisplayType.MULTIPICKLIST) {
            return apiValue;
        }
        if (String.isBlank(apiValue)) {
            return System.Label.stgLabelNone;
        }
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.getValue() == apiValue) {
                return entry.getLabel();
            }
        }

        return apiValue;
    }

    /**
    * @description NPSP namespace: an empty string if unmanaged, or 'npsp' if managed
    * @return String
    */
    public virtual String getNamespace() {
        String namespace = UTIL_Namespace.getNamespace();
        if (String.isBlank(namespace)) {
            return 'c';
        }
        return namespace;
    }
}