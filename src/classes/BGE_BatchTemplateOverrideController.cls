public with sharing class BGE_BatchTemplateOverrideController {

    /*******************************************************************************************************
    * @description holds the Batch currently being edited by the page
    */
    public Batch_Template__c diBatchTemplate { get; set; }

    /*******************************************************************************************************
    * @description after successful save set to true to redirect page
    */ 
    public Boolean redirect {get; set;}

    /*******************************************************************************************************
    * @description constructor for the page
    * @param controller the StandardController for the page
    * @return nothing
    */
    public BGE_BatchTemplateOverrideController(ApexPages.StandardController controller) {
        redirect = false;
        // since our page doesn't directly refer to the Batch fields, we must explicitly list them
        if (!Test.isRunningTest()) {
            List<String> listFields = new List<String>{
                'Id',
                'Name',
                UTIL_Namespace.StrTokenNSPrefix('Account_Custom_Unique_ID__c'),
                UTIL_Namespace.StrTokenNSPrefix('Description__c'),
                UTIL_Namespace.StrTokenNSPrefix('Batch_Process_Size__c'),
                UTIL_Namespace.StrTokenNSPrefix('Contact_Custom_Unique_ID__c'),
                UTIL_Namespace.StrTokenNSPrefix('Contact_Matching_Rule__c'),
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date_Range__c'),
                UTIL_Namespace.StrTokenNSPrefix('Donation_Matching_Behavior__c'),
                UTIL_Namespace.StrTokenNSPrefix('Donation_Matching_Implementing_Class__c'),
                UTIL_Namespace.StrTokenNSPrefix('Donation_Matching_Rule__c'),
                UTIL_Namespace.StrTokenNSPrefix('Process_Using_Scheduled_Job__c')
            };
            controller.addFields(listFields);
        }

        diBatchTemplate = (Batch_Template__c) controller.getRecord();

        // for some reason, New override doesn't get default values set
        if (diBatchTemplate.Donation_Matching_Rule__c == null) {
            diBatchTemplate.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        }

        // our multiselect list of donation related fields holds keys in lowercase
        diBatchTemplate.Donation_Matching_Rule__c = diBatchTemplate.Donation_Matching_Rule__c.toLowerCase();

        //if clone param is set, this is the clone button override
        // Map<String, String> params = ApexPages.currentPage().getParameters();
        // if (params.containsKey('clone') && params.get('clone') == '1') {
        //     diBatchTemplate.Id = null;
        //     diBatchTemplate.Name += ' - ' + Label.lblCloned;
        // }

    }

    /*********************************************************************************************************
    * @description actionMethod to Save the current Batch.
    */
    public PageReference save() {

        try {
            validateSettings(diBatchTemplate);
            UTIL_DMLService.upsertRecord(diBatchTemplate);
            redirect = true;

        } catch (Exception ex) {

            ApexPages.addMessages(ex);
        }
        return null;
    }


    /*******************************************************************************************************
    * @description validates the Batch Template's data import settings.  Used by UI as well as at runtime by the batch template.
    * throws an exception if there are any invalid settings.
    * @param diBatchTemplate the batch template to validate
    * @return void
    */
    private void validateSettings(Batch_Template__c template) {

        // make sure name set
        if (String.isBlank(template.Name)) {

            throw(new BDIException(Label.bgeErrorBatchTemplateNameRequired));
        }

        String strBatchTemplateObj = UTIL_Namespace.StrTokenNSPrefix('Batch_Template__c');

        // validate matching rules
        if (template.Donation_Matching_Behavior__c != null &&
            template.Donation_Matching_Behavior__c != BDI_DataImport_API.DoNotMatch &&
            String.isBlank(template.Donation_Matching_Rule__c)) {
            throw(new BDIException(Label.bdiDonationMatchingRuleEmpty));
        }

        // validate Batch Process Size
        if (template.Batch_Process_Size__c == null || template.Batch_Process_Size__c < 0) {
            throw(new BDIException(String.format(Label.bdiPositiveNumber,
                new List<String>{UTIL_Describe.getFieldLabelSafe(strBatchTemplateObj, UTIL_Namespace.StrTokenNSPrefix('Batch_Process_Size__c'))})));
        }

        // validate Donation Date Range
        if (template.Donation_Date_Range__c < 0) {
            throw(new BDIException(String.format(Label.bdiPositiveNumber,
                new List<String>{UTIL_Describe.getFieldLabelSafe(strBatchTemplateObj, UTIL_Namespace.StrTokenNSPrefix('Donation_Date_Range__c'))})));
        }

        // validate donation implementing class by instantiating it
        instantiateClassForInterface('BDI_IMatchDonations', template.Donation_Matching_Implementing_Class__c);

        // validate post process implementing class by instantiating it
        // instantiateClassForInterface('BDI_IPostProcess', template.Post_Process_Implementing_Class__c);

        // ensure we are in the household account model!
        if (!CAO_Constants.isHHAccountModel())
            throw(new BDIException(Label.bdiHouseholdModelRequired));

        // validate settings
        if (template.Contact_Custom_Unique_ID__c != null) {
            // make sure c1 and c2 have the appropriately named field
            String strContact1 = strDIContactCustomIDField('Contact1', template);
            String strContact2 = strDIContactCustomIDField('Contact2', template);

            // if (!UTIL_Describe.isValidField(strDataImportObj, strContact1) ||
            //     !UTIL_Describe.isValidField(strDataImportObj, strContact2)) {
            if (!UTIL_Describe.isValidField(strBatchTemplateObj, strContact1) ||
                !UTIL_Describe.isValidField(strBatchTemplateObj, strContact2)) {
                throw(new BDIException(String.format(Label.bdiContactCustomIdError,
                    new String[]{template.Contact_Custom_Unique_ID__c, strContact1, strContact2})));
            }
        }
    }

    /*******************************************************************************************************
    * @description instantiate a class for the provided interface
    */
    public static Object instantiateClassForInterface(String strInterface, String strClass) {

        if (strClass == null || strClass == '') {
            return null;
        }

        Type classType = Type.forName(strClass);
        if (classType != null) {
            Object classInstance = classType.newInstance();

            if (strInterface == 'BDI_IPostProcess' && classInstance instanceOf BDI_IPostProcess) {
                return classInstance;
            }

            if (strInterface == 'BDI_IMatchDonations' && classInstance instanceOf BDI_IMatchDonations) {
                return classInstance;
            }
        }
        throw new BDIException(String.format(Label.bdiErrorInvalidIMatchDonations, new List<String>{strClass, strInterface}));
    }

    /*******************************************************************************************************
    * @description returns the field name of the Contact CustomID field for contact1 or contact2 in the
    * Data Import object.
    * @param strCx  which contact to reference (Contact1 or Contact2)
    * @param diSettings the settings object to read the setting from
    * @return String
    */
    public static String strDIContactCustomIDField(String strCx, Batch_Template__c template) {
        return strDICustomIDField(strCx, template.Contact_Custom_Unique_ID__c);
    }

    /*******************************************************************************************************
    * @description returns the field name of the Account CustomID field for Account1 or Account2 in the
    * Data Import object.
    * @param strAx  which account to reference (account1 or account2)
    * @param diSettings the settings object to read the setting from
    * @return String
    */
    private static String strDIAccountCustomIDField(String strAx, Batch_Template__c template) {
        return strDICustomIDField(strAx, template.Account_Custom_Unique_ID__c);
    }

    /*******************************************************************************************************
    * @description returns the field name of the Object's CustomID field in the
    * Data Import object.  The format of the setting is the full path name to the field on Object.  But
    * the Data Import field we want to return will need to be different depending on the source.  There
    * are three cases:
    *
    *   - Standard field
    *       Website => Contact1_Website__c
    *
    *   - custom field
    *       myUniqueId => Contact1_myUniqueId__c
    *
    *   - custom field that is namespaced
    *       ns__UniqueId__c => Contact1_UniqueId__c
    *       Yes, we assume that even if the object field is packaged, the DI field is not packaged,
    *       unless the namespace happens to be ours, in which case we'll return ns__Contact1_UniqueId__c
    *
    * Note that when running managed under the NPSP namespace, we don't need to add npsp__ in front of
    * the resultant field.  di.get(fieldname) works without the namespace.
    *
    * @param strObjx  which object to reference (Contact1, Contact2, Account1, Account2)
    * @param strCustomId the custom field from the object
    * @return String
    */
    @TestVisible private static String strDICustomIDField(String strObjx, String strCustomId) {
        if (strCustomId == null) {
            return null;
        }

        // handle standard fields
        if (!strCustomId.endsWith('__c')) {
            if (Test.isRunningTest()) {
                return UTIL_Namespace.StrTokenNSPrefix(strObjx + '_' + strCustomId + '__c');
            } else {
                return strObjx + '_' + strCustomId + '__c';
            }
        }

        // look for namespace
        Integer i = strCustomId.indexOf('__');
        if (i != -1 && i <> strCustomId.indexOf('__c')) {
            // is it our namespace, in which case this is probably unmanaged npsp code,
            // so any manual testing will need the namespace in the DI custom field.
            if (strCustomId.left(i).equalsIgnoreCase(UTIL_Namespace.getNamespace())) {
                return UTIL_Namespace.StrTokenNSPrefix(strObjx + '_' + strCustomId.subString(i + 2));
            } else {
                // skip namespace
                return strObjx + '_' + strCustomId.subString(i + 2);
            }
        }

        // custom fields without namespace
        return strObjx + '_' + strCustomId;
    }

    /*******************************************************************************************************
    * @description our exception object for Data Import errors.
    */
    private class BDIException extends Exception {}

}