public with sharing class BGE_SettingsUITemplateController {

    /*********************************************************************************************************
    * @description The Data Import batch/settings object to work upon
    */
    public Batch_Template__c diBatchTemplate { get; set; }

    /*********************************************************************************************************
    * @description getter's to provide the page our API behaviors (which the page can't refer to directly)
    */
    public String getDoNotMatch() { return BDI_DataImport_API.DoNotMatch; }
    public String getRequireNoMatch() { return BDI_DataImport_API.RequireNoMatch; }
    public String getRequireExactMatch() { return BDI_DataImport_API.RequireExactMatch; }
    public String getExactMatchOrCreate() { return BDI_DataImport_API.ExactMatchOrCreate; }
    public String getRequireBestMatch() { return BDI_DataImport_API.RequireBestMatch; }
    public String getBestMatchOrCreate() { return BDI_DataImport_API.BestMatchOrCreate; }

    /*******************************************************************************************************
    * @description is the panel in Edit Mode
    */ 
    public boolean isEditMode { 
        get {
            if (isEditMode == null) {
                isEditMode = false;
            }
            return isEditMode;
        }
        set; 
    }
    
    /*******************************************************************************************************
    * @description is the panel in Read Only Mode
    */
    public Boolean isReadOnlyMode {
        get {
            return !isEditMode;
        }
    }

    /*******************************************************************************************************
    * @description should we display fields that are only in DataImportBatch, but not in DataImportSettings
    */
    public Boolean isShowBatchOnlyFields { get; set; }

    /*********************************************************************************************************
    * @description The list of SelectOptions of Donation fields from the BDI object. note that the option
    * keys are stored in lowercase.
    */
    public List<SelectOption> listSODonationFields {
        get {
        
            if (listSODonationFields == null) {
                listSODonationFields = new List<SelectOption>();
                
                set<String> setFields = new set<String>();
                setFields.addAll(BDI_Donations.mapDIFieldToOppField.keySet());
                setFields.addAll(BDI_Donations.mapDIFieldToPmtField.keySet());

                for (String diField : setFields) {
                    String strLabel = UTIL_Describe.getFieldLabel(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), diField); 
                    listSODonationFields.add(new SelectOption(diField, strLabel));
                }

                listSODonationFields.sort();
            }         
            return listSODonationFields;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions of Contact Unique ID fields 
    */
    public List<SelectOption> listSOContactUniqueID {
        get {
            if (listSOContactUniqueID == null) {
                listSOContactUniqueID = listSOForObject('Contact');
            }
            return listSOContactUniqueID;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions of Account Unique ID fields
    */
    public List<SelectOption> listSOAccountUniqueID {
        get {
            if (listSOAccountUniqueID == null) {
                listSOAccountUniqueID = listSOForObject('Account');
            }
            return listSOAccountUniqueID;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description creates a list of SelectOptions of potential Unique ID fields from the specified object
    * @param strObject the object to query fields on
    * @return List<SelectOption>
    */
    private List<SelectOption> listSOForObject(String strObject) {
        List<SelectOption> listSO = new List<SelectOption>();
        // add a default option
        listSO.add(new SelectOption('', Label.stgLabelNone));

        Map<String, Schema.DescribeFieldResult> mapNameToDfr = UTIL_Describe.getAllFieldsDescribe(strObject);
        for (Schema.DescribeFieldResult dfr : mapNameToDfr.values()) {
            // only allow unique fields and externalId fields
            if (dfr.isUnique() || dfr.isExternalId()) {
                listSO.add(new SelectOption(dfr.getName(), dfr.getLabel()));
            }
        }
        return listSO;
    }
}