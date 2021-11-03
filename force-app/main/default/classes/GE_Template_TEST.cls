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
* @description Unit tests to cover default template creation.
*/
@isTest
public with sharing class GE_Template_TEST {
    /*******************************************************************************************************
     * @description Confirm that a default template is able to be deserialized to the
     * current GE_Template.Layout structure.
     * This is the best we can do since there will not be a migrated field set available for testing.  
     */
    @isTest
    private static void testDeserializeBaseJSONToCurrentFORMLayout() {
        try {
            GE_Template.buildDefaultTemplate();
        } catch (Exception e) {
            System.Assert(false, 'There was an error deserializing the Base ' + 
                                  'JSON to the current GE_Template.Layout structure');
        }
    }

    @isTest
    static void shouldRetrieveTemplateWithPermissionCRUD() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(true,
                GE_Template.OBJECT_CRUD_ERROR);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class,
                utilPermissionsMockInstance);
        UTIL_Permissions.setInstance(utilPermissionsMock);

        GE_Template.Template template = (GE_Template.Template) UTIL_UnitTestData_TEST.createSampleTemplate();

        UTIL_UnitTestData_TEST.createSampleFieldMappings();

        GE_Template.PermissionValidator validator =
                new GE_Template.PermissionValidator(template,
                        new Set<GE_Template.AccessLevel>{
                                GE_Template.AccessLevel.VALIDATE_READ,
                                GE_Template.AccessLevel.VALIDATE_CREATE,
                                GE_Template.AccessLevel.VALIDATE_UPDATE
                        });

        GE_Template.Template updatedTemplate = validator.validateTemplate();

        System.assert(String.isBlank(updatedTemplate.permissionErrors), 'There should be '
                + 'no permission errors when the user has all required CRUD and FLS permissions.');

        System.assertEquals(updatedTemplate.permissionErrorType, null, 'The template '
                + 'should not have a permission error type if the user has all required CRUD '
                + 'and FLS permissions.');
    }

    @isTest
    static void shouldRetrieveTemplateWithPermissionFLS() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(true,
                GE_Template.FLS_ERROR);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
                UTIL_Permissions.class, utilPermissionsMockInstance);

        UTIL_Permissions.setInstance(utilPermissionsMock);

        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();

        UTIL_UnitTestData_TEST.createSampleFieldMappings();

        GE_Template.PermissionValidator validator = new GE_Template.PermissionValidator
                (template,
                        new Set<GE_Template.AccessLevel>{
                                GE_Template.AccessLevel.VALIDATE_READ,
                                GE_Template.AccessLevel.VALIDATE_CREATE,
                                GE_Template.AccessLevel.VALIDATE_UPDATE
                        });

        GE_Template.Template updatedTemplate = validator.validateTemplate();

        System.assert(String.isBlank(updatedTemplate.permissionErrors), 'There should be '
                + 'no permission errors when the user has all required CRUD and FLS permissions.');

        System.assertEquals(updatedTemplate.permissionErrorType, null, 'The template '
                + 'should not have a permission error type if the user has all required CRUD '
                + 'and FLS permissions.');
    }

    @isTest
    static void shouldRetrieveTemplateWithCRUDErrors() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(false,
                GE_Template.OBJECT_CRUD_ERROR);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
                UTIL_Permissions.class, utilPermissionsMockInstance);

        UTIL_Permissions.setInstance(utilPermissionsMock);

        UTIL_UnitTestData_TEST.createSampleFieldMappings();

        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();


        GE_Template.PermissionValidator validator = new GE_Template.PermissionValidator
                (template,
                        new Set<GE_Template.AccessLevel>{
                                GE_Template.AccessLevel.VALIDATE_READ,
                                GE_Template.AccessLevel.VALIDATE_CREATE,
                                GE_Template.AccessLevel.VALIDATE_UPDATE
                        });

        GE_Template.Template updatedTemplate = validator.validateTemplate();

        System.assert(String.isNotBlank(updatedTemplate.permissionErrors), 'There should '
                + 'be permission errors when the user has no CRUD access to an object.');

        System.assertEquals(updatedTemplate.permissionErrorType, 'CRUD', 'The '
                + 'permission error type should be \'CRUD\' when the user does not '
                + 'have CRUD permissions.');

        System.assert(updatedTemplate.permissionErrors.contains(Account.SObjectType.getDescribe().getName()), 'The '
                + 'permissions error should contain the Account object, which the user does not '
                + 'have access to.');
/*      // Should we be checking the widget permissions right now??
        System.assert(updatedTemplate.permissionErrors.contains('Contact'), 'The '
            + 'permissions error should contain the Contact object, which the user does not have '
            + 'access to.');
*/
    }

    @isTest
    static void shouldRetrieveTemplateWithFLSErrors() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(false,
                GE_Template.FLS_ERROR);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
                UTIL_Permissions.class, utilPermissionsMockInstance);

        UTIL_Permissions.setInstance(utilPermissionsMock);

        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();

        UTIL_UnitTestData_TEST.createSampleFieldMappings();

        GE_Template.PermissionValidator validator = new GE_Template.PermissionValidator(template,
                new Set<GE_Template.AccessLevel>{
                        GE_Template.AccessLevel.VALIDATE_READ,
                        GE_Template.AccessLevel.VALIDATE_CREATE,
                        GE_Template.AccessLevel.VALIDATE_UPDATE
                });

        GE_Template.Template updatedTemplate = validator.validateTemplate();

        System.assert(String.isNotBlank(updatedTemplate.permissionErrors), 'There should '
                + 'be permission errors when the user has no FLS access to an object.');
        System.assertEquals(updatedTemplate.permissionErrorType, 'FLS', 'The '
                + 'permission error type should be \'FLS\' when the user does not have FLS '
                + 'permissions.');
        System.assert(updatedTemplate.permissionErrors.contains(Account.BillingCountry.getDescribe().getName()),
                'The permissions error should contain any field the user does not have access '
                        + 'to.');
        System.assert(updatedTemplate.permissionErrors.contains(Account.Name.getDescribe().getName()), 'The '
                + 'permissions error should contain any field the user does not have access '
                + 'to.');

        /* Should we be testing widget permissions right now??
        System.assert(updatedTemplate.permissionErrors.contains('FirstName'), 'The '
            + 'permissions error should contain any field the user does not have access '
            + 'to.');
        System.assert(updatedTemplate.permissionErrors.contains('LastName'), 'The '
            + 'permissions error should contain any field the user does not have access '
            + 'to.');

        */
    }

    @isTest
    static void shouldReturnListOfFieldApiNamesOnTheTemplate() {
        UTIL_UnitTestData_TEST.createSampleFieldMappings();
        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        GE_Template.Element lookupField =
            new GE_Template.Element('field', 'True', null, 'CustomLabel',
                new List<String>{String.valueOf(DataImport__c.Account1Imported__c)});
        template.layout.sections[0].elements.add(lookupField);

        System.assertEquals(template.giftFieldApiNames().size(), 2);
        System.assertEquals(template.giftFieldApiNames()[0], String.valueOf(DataImport__c.Account1_Name__c));
        System.assertEquals(template.giftFieldApiNames()[1], String.valueOf(DataImport__c.Account1Imported__c));
    }

    private class UTIL_PermissionsMock implements StubProvider {

        Boolean hasPermission;
        String permissionType;
        Boolean isFLS;

        public UTIL_PermissionsMock(Boolean hasPermission,  String permissionType) {
            this.hasPermission = hasPermission;
            this.permissionType = permissionType;
            this.isFLS = isFLS;
        }

        public Boolean getPermissions(List<Type> listOfParamTypes) {
            Set<Type> paramTypes = new Set<Type>(listOfParamTypes);

            Type objectFields = Type.forName('Set<SObjectField>');

            if(permissionType == GE_Template.FLS_ERROR &&
                    !paramTypes.contains(objectFields)) {
                return true;
            } else {
                return hasPermission;
            }
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on stubbedMethodName {
                when 'canRead' {
                    return getPermissions(listOfParamTypes);
                }
                when 'canCreate' {
                    return getPermissions(listOfParamTypes);
                }
                when 'canUpdate' {
                    return getPermissions(listOfParamTypes);
                }
            }
            return null;
        }
    }
    
    @IsTest
    static void defaultTemplateShouldNotIncludeDeletedFieldMappings() {
        // GIVEN that a field mapping that was on the default template has been deleted
        // WHEN the default template is generated
        GE_Template.Template sampleTemplate = createSampleTemplate();
        sampleTemplate.layout.stripElementsWithDeletedFieldMappings(
                fieldMappingsWithPmtMethodDeleted()
        );

        // THEN the Template should not include deleted field mappings
        System.assertEquals(true,
                sampleTemplate.layout.containsField(npe01__OppPayment__c.npe01__Check_Reference_Number__c),
                'The layout should include fields whose field mappings have not been ' +
                        'deleted: ' + npe01__OppPayment__c.npe01__Check_Reference_Number__c);
        System.assertEquals(false,
                sampleTemplate.layout.containsField(npe01__OppPayment__c.npe01__Payment_Method__c),
                'The layout should not include fields whose field mappings have been ' +
                        'deleted: ' + npe01__OppPayment__c.npe01__Payment_Method__c);
    }

    private static FieldMappings fieldMappingsWithPmtMethodDeleted() {
        Data_Import_Field_Mapping__mdt checkNumber = new Data_Import_Field_Mapping__mdt(
                MasterLabel = 'Payment Check/Reference Number',
                DeveloperName = 'Payment_Check_Reference_Number',
                Source_Field_API_Name__c =
                        String.valueOf(DataImport__c.Payment_Check_Reference_Number__c),
                Target_Field_API_Name__c =
                        String.valueOf(npe01__OppPayment__c.npe01__Check_Reference_Number__c),
                Is_Deleted__c = false
        );

        Data_Import_Field_Mapping__mdt paymentMethod = new Data_Import_Field_Mapping__mdt(
                MasterLabel = 'Payment Method',
                DeveloperName = 'Payment_Method',
                Source_Field_API_Name__c =
                        String.valueOf(DataImport__c.Payment_Method__c),
                Target_Field_API_Name__c =
                        String.valueOf(npe01__OppPayment__c.npe01__Payment_Method__c),
                Is_Deleted__c = true
        );
        List<Data_Import_Field_Mapping__mdt> d = new List<Data_Import_Field_Mapping__mdt>{
                checkNumber,
                paymentMethod
        };
        return new FieldMappings(d);
    }

    private static GE_Template.Template createSampleTemplate() {
        GE_Template.Element field = new GE_Template.Element('field',
                'True',
                null,
                'CustomLabel',
                new List<String>{'Payment_Check_Reference_Number'});
        field.fieldApiName = 'npe01__Check_Reference_Number__c';

        GE_Template.Element field2 = new GE_Template.Element('field',
                'True',
                null,
                'CustomLabel',
                new List<String>{'Payment_Method'});
        field2.fieldApiName = 'npe01__Payment_Method__c';

        GE_Template.Element[] elements = new GE_Template.Element[]{field,field2};

        GE_Template.Section section = new GE_Template.Section('SectionLabel',
                'Accordion',
                'Expanded',
                'True',
                elements);

        GE_Template.Layout layout = new GE_Template.Layout('DefaultMappingSet',
                new GE_Template.Section[]{section});

        GE_Template.Template template = new GE_Template.Template('Sample Template',
                'This is the description.',
                '1.0',
                layout);
        return template;
    }
}
