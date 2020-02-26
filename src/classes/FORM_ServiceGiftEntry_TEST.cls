/*
    Copyright (c) 2019 Salesforce.org
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
* @group Gift Entry
* @group-content ../../ApexDocContent/GiftEntry.htm
* @description Unit tests to cover methods in FORM_ServiceGiftEntry_TEST.
*/
@isTest
public with sharing class FORM_ServiceGiftEntry_TEST {

    /*******************************************************************************************************
    * @description Confirming that method returns the correct number of records
    */
    @IsTest
    static void shouldReturnCorrectNumberOfRecords() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template0 = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON0 = JSON.serialize(template0);
        fs.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);

        FORM_Template template1 = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON1 = JSON.serialize(template1);
        fs.storeFormTemplate(null,template1.name, template1.description, template1.version, templateJSON1);

        System.assertEquals(2, fs.getAllFormTemplates().size());
    }

    /*******************************************************************************************************
    * @description Confirming that method deletes Form Template records with given ids.
    */
    @IsTest
    static void shouldDeleteFormTemplatesWithGivenIds() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template0 = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON0 = JSON.serialize(template0);
        fs.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);

        FORM_Template template1 = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON1 = JSON.serialize(template1);
        fs.storeFormTemplate(null,template1.name, template1.description, template1.version, templateJSON1);

        Form_Template__c[] formTemplates = [SELECT Id, Name FROM Form_Template__c];

        System.assertEquals(2, formTemplates.size());
        fs.deleteFormTemplates(new String[]{ formTemplates[0].id, formTemplates[1].id });

        formTemplates = [SELECT Id, Name FROM Form_Template__c];
        System.assertEquals(0, formTemplates.size());
    }

    /*******************************************************************************************************
    * @description Confirming that the lifecycle of storing and retrieving the template does not corrupt
    * the data.
    */
    @IsTest
    static void shouldCommitAndRetrieveTemplate() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();

        String templateJSON = JSON.serialize(template);
        String storedFormTemplateId = FORM_ServiceGiftEntry.storeFormTemplate(null, 
            template.name, 
            template.description, 
            template.version, 
            templateJSON);

        giftEntryCustomSetting.Default_Gift_Entry_Template__c = storedFormTemplateId;
        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        FORM_Template templateResult = fs.retrieveDefaultSGEFormTemplate();
        String templateResultJSON = JSON.serialize(templateResult);

        System.assertEquals(templateJSON, templateResultJSON);
    }

    /*******************************************************************************************************
    * @description Confirm that we're able to retrieve column headers based on a list name.
    */
    @IsTest
    static void shouldRetrieveColumnHeaderBasedOnListName() {

        Test.startTest();
        Custom_Column_Header__c[] allHeaders = UTIL_UnitTestData_TEST.createSampleColumnHeaders();
        insert allHeaders;
        Test.stopTest();

        Custom_Column_Header__c[] selectedHeaders =
            FORM_ServiceGiftEntry.retrieveCustomColumnHeaders('Sample List');

        System.assertEquals(3, allHeaders.size());
        System.assertEquals(1, selectedHeaders.size());
    }

    /*******************************************************************************************************
    * @description Confirm that we're able to retrieve column headers based on a list name.
    */
    @IsTest
    static void shouldPersistOnlyTheSelectedColumnHeadersForTheGivenList() {

        Test.startTest();
        Custom_Column_Header__c[] allHeaders = UTIL_UnitTestData_TEST.createSampleColumnHeaders();
        insert allHeaders;
        Test.stopTest();

        Custom_Column_Header__c[] selectedHeaders =
            FORM_ServiceGiftEntry.retrieveCustomColumnHeaders('Sample List 2');

        Custom_Column_Header__c columnHeaderToKeep = new Custom_Column_Header__c();
        columnHeaderToKeep.Name = 'sampleColumnHeader2';
        columnHeaderToKeep.List_Name__c = 'Sample List 2';
        columnHeaderToKeep.Index__c = 0;
        columnHeaderToKeep.Field_Api_Name__c = 'Sample_Field_2__c';

        String columnHeaderStringToKeep = JSON.serialize(new Custom_Column_Header__c[]{columnHeaderToKeep});

        FORM_ServiceGiftEntry.upsertCustomColumnHeaders(columnHeaderStringToKeep, 'Sample List 2');

        Custom_Column_Header__c[] updatedColumnHeadersList =
            FORM_ServiceGiftEntry.retrieveCustomColumnHeaders('Sample List 2');
        
        Custom_Column_Header__c columnHeaderToCheck = updatedColumnHeadersList[0];

        System.assertEquals(2, selectedHeaders.size());
        System.assertEquals(1, updatedColumnHeadersList.size());
        System.assertEquals('Sample_Field_2__c', columnHeaderToCheck.Field_Api_Name__c);
    }

    /*******************************************************************************************************
    * @description Confirm that we're able to build a query string and retrieve a list of records.
    */
    @IsTest
    static void shouldRetrieveRecordsBasedOnAQueryString() {

        Test.startTest();
        Custom_Column_Header__c[] allHeaders = UTIL_UnitTestData_TEST.createSampleColumnHeaders();
        insert allHeaders;
        Test.stopTest();

        String[] selectFields = new String[] {'Id', 'Name'};
        String sObjectApiName = SObjectType.Custom_Column_Header__c.Name;
        String[] whereClause = new String[] {};
        String orderByClause = 'LastModifiedDate desc';
        Integer limitClause = 10;

        sObject[] objects = FORM_ServiceGiftEntry.retrieveRecords(
            selectFields, sObjectApiName, whereClause, orderByClause, limitClause);
        
        System.assertEquals(3, objects.size());
    }
    
    /*******************************************************************************************************
    * @description Confirm that form template name uniqueness is enforced.
    */
    @IsTest
    static void shouldReturnFalseForExistingFormTemplateName() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        fs.storeFormTemplate(null,template.name, template.description, template.version, templateJSON);

        Form_Template__c[] formTemplates = [SELECT Id, Name, Template_JSON__c FROM Form_Template__c];

        Boolean isExistingName = FORM_ServiceGiftEntry.checkNameUniqueness(
            formTemplates[0].Name,
            null);

        Boolean isUniqueName = FORM_ServiceGiftEntry.checkNameUniqueness(
            'New Form Template Sample Name',
            null);

        System.assertEquals(false,
            isExistingName,
            'Existing template names should return false from `FORM_ServiceGiftEntry.checkNameUniqueness`');
        System.assertEquals(true,
            isUniqueName,
            'New template names should return true from `FORM_ServiceGiftEntry.checkNameUniqueness`');
    }

    @isTest
    static void shouldRetrieveSGETemplateWithPermission() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(true);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
            UTIL_Permissions.class,
            utilPermissionsMockInstance);
        UTIL_Permissions.setInstance(utilPermissionsMock);

        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        Gift_Entry_Settings__c giftEntrySettings = UTIL_CustomSettingsFacade.getGiftEntrySettings();
        String templateJSON = JSON.serialize(template);
        String storedFormTemplateId = FORM_ServiceGiftEntry.storeFormTemplate(null, 
            template.name, 
            template.description, 
            template.version, 
            templateJSON);
        
        giftEntrySettings.Default_Gift_Entry_Template__c = storedFormTemplateId;
        
        insert giftEntrySettings;
        
        UTIL_UnitTestData_TEST.createSampleFieldMappings();
        
        FORM_Template updatedTemplate = FORM_ServiceGiftEntry.retrieveDefaultSGEFormTemplate();

        System.assert(String.isBlank(updatedTemplate.permissionErrors), 
            'There should be no permission errors when the user has all required CRUD and FLS permissions.');
        System.assertEquals(updatedTemplate.permissionErrorType, null, 
            'The template should not have a permission error type if the user has all required CRUD and FLS permissions.');
    }

    /**************************************************************************************************
    * @description Confirms that a form template used by any Data Import Batch cannot be deleted.
    */
    @IsTest
    static void shouldPreventDeletionOfTemplateInUse() {
        FORM_Service fs = new FORM_Service();

        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        fs.storeFormTemplate(null,
                template.name,
                template.description,
                template.version,
                templateJSON);

        Form_Template__c[] formTemplates = [
                SELECT Id, Name, Template_JSON__c
                FROM Form_Template__c
        ];

        DataImportBatch__c batch = createBatch('Test Batch', false);
        batch.Form_Template__c = formTemplates[0].Id;

        insert batch;

        AuraHandledException failure;

        try {
            fs.deleteFormTemplates(new String[]{ formTemplates[0].Id });
        } catch (AuraHandledException ex) {
            failure = ex;
        }

        formTemplates = [
                SELECT Id, Name
                FROM Form_Template__c
        ];

        System.assert(String.isNotBlank(failure.getMessage()));
        System.assertEquals(1, formTemplates.size(), 'A Form Template in use should not be deleted');

    }

    /**************************************************************************************************
    * @description Confirms that a form template used as default on Gift Entry settings cannot be deleted.
    */
    @IsTest
    static void shouldPreventDeletionOfTemplateReferencedByGiftEntry() {

        // aux vars
        String templateName = 'fooName';
        AuraHandledException failure;

        // test data
        FORM_Template template = createSampleTemplate();
        template.name = templateName;
        String templateJSON = JSON.serialize(template);
        // form service init
        FORM_Service fs = new FORM_Service();
        // insert form template using service
        String templateId = FORM_ServiceGiftEntry.storeFormTemplate(null,
            template.name,
            template.description,
            template.version,
            templateJSON);

        // gift entry custom settings set up
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        giftEntryCustomSetting.Default_Gift_Entry_Template__c = templateId;
        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        // retrieve templates with id
        Form_Template__c[] formTemplates = [SELECT Id, 
                    Name, 
                    Template_JSON__c 
            FROM Form_Template__c];

        System.assertEquals( formTemplates.size(), 1, 
            'We should have only 1 form temp record at this time' );

        Test.startTest();
            try {
                // delete template using service
                fs.deleteFormTemplates(new String[]{ formTemplates[0].Id });
            } catch (AuraHandledException ex) {
                failure = ex;
            }
        Test.stopTest();

        formTemplates = [SELECT Id, Name FROM Form_Template__c];
        System.assert( String.isNotBlank(failure.getMessage()), 'Aura Exception found' );
        System.assertEquals( 1, formTemplates.size(), 'Template was not deleted' );

    }

    //Utility method for creating a sample template.
    public static FORM_Template createSampleTemplate () {
        
        FORM_Element field = new FORM_Element('FormField',
            'True',
            null,
            'CustomLabel',
            new String[]{});
        
        FORM_Element widget = new FORM_Element('FormWidget',
            'DisplayRule',
            'ComponentName',
            new String[]{});
        
        FORM_Element[] elements = new FORM_Element[]{field,widget};

        FORM_Section section = new FORM_Section('SectionLabel',
            'Accordion',
            'Expanded',
            'True',
            elements);
        
        FORM_Layout layout = new FORM_Layout('DefaultMappingSet',
            new FORM_Section[]{section});

        FORM_Template template = new FORM_Template('Sample Template',
            'This is the description.',
            '1.0',
            layout);

        return template;
    }

    //Utility method for creating sample column headers.
    public static Custom_Column_Header__c[] createSampleColumnHeaders () {
        
        Custom_Column_Header__c columnHeader = new Custom_Column_Header__c();
        columnHeader.Name = 'sampleColumnHeader';
        columnHeader.List_Name__c = 'Sample List';
        columnHeader.Index__c = 0;
        columnHeader.Field_Api_Name__c = 'Sample_Field__c';

        Custom_Column_Header__c columnHeader2 = new Custom_Column_Header__c();
        columnHeader2.Name = 'sampleColumnHeader2';
        columnHeader2.List_Name__c = 'Sample List 2';
        columnHeader2.Index__c = 0;
        columnHeader2.Field_Api_Name__c = 'Sample_Field_2__c';

        Custom_Column_Header__c columnHeader3 = new Custom_Column_Header__c();
        columnHeader3.Name = 'sampleColumnHeader3';
        columnHeader3.List_Name__c = 'Sample List 2';
        columnHeader3.Index__c = 1;
        columnHeader3.Field_Api_Name__c = 'Sample_Field_3__c';

        return new Custom_Column_Header__c[] { columnHeader, columnHeader2, columnHeader3 };
    }

    /**********************************************************************************************
     * @description Utility method that creates an NPSP Data Import Batch
     *
     * @param name
     * @param autoProcess
     *
     * @return DataImportBatch__c
     */
    private static DataImportBatch__c createBatch (String name, Boolean autoProcess) {
        DataImportBatch__c batch = new DataImportBatch__c();
        batch.Name = name;
        batch.Batch_Process_Size__c = 200;
        batch.Contact_Matching_Rule__c = 'Firstname,Lastname,Email';
        batch.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + 
                ';' + UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        batch.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;
        batch.Process_Using_Scheduled_Job__c = autoProcess;
        return batch;
    }

    private class UTIL_PermissionsMock implements StubProvider {

        Boolean hasPermission;
        String permission;
        
        public UTIL_PermissionsMock(Boolean hasPermission) {
            this.hasPermission = hasPermission;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            Set<String> paramNames = new Set<String>(listOfParamNames);
            
            switch on stubbedMethodName {
                when 'canRead' {
                    return hasPermission;
                }
                when 'canCreate' {
                    return hasPermission;
                }
                when 'canUpdate' {
                    return hasPermission;
                }
            }
            return null;
        }
    }
}
