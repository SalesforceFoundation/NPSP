/*
    Copyright (c) 2019, Salesforce.org
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
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Tests specific to the BDI_DataImportFLSService class.
*/
@IsTest
private class BDI_DataImportFLSService_TEST {

    @IsTest
    static void givenRecordHasLookupFieldPopulatedInMemoryThenAssertFieldValidated() {
        Account testAcct = new Account(Name = 'testAcct');

        DataImport__c dataImport = new DataImport__c(
                Account1Imported__r = testAcct
        );

        Set<BDI_DataImportFLSService.AccessLevel> accessLevels = new
                Set<BDI_DataImportFLSService.AccessLevel>{
                BDI_DataImportFLSService.AccessLevel.VALIDATE_READ
        };

        BDI_DataImportFLSService service = new BDI_DataImportFLSService(
                new List<DataImport__c>{
                        dataImport
                },
                BDI_MappingServiceAdvanced.getInstance(),
                accessLevels
        );

        List<DataImport__c> validatedDataImports = service.getValidRecords();
        System.assertEquals(1, validatedDataImports.size());
    }

    @IsTest
    static void givenRecordHasLookupFieldPopulatedInMemoryThenAssertFieldInvalidated() {
        Account testAcct = new Account(Name = 'testAcct');

        DataImport__c dataImport = new DataImport__c(
                Account1Imported__r = testAcct,
                Account1_Name__c = 'testAcctUpdatedName'
        );

        Set<BDI_DataImportFLSService.AccessLevel> accessLevels = new
                Set<BDI_DataImportFLSService.AccessLevel>{
                BDI_DataImportFLSService.AccessLevel.VALIDATE_CREATE,
                BDI_DataImportFLSService.AccessLevel.VALIDATE_UPDATE
        };

        User readOnlyUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);
        System.runAs(readOnlyUser) {
            BDI_DataImportFLSService service = new BDI_DataImportFLSService(
                    new List<DataImport__c>{
                            dataImport
                    },
                    BDI_MappingServiceAdvanced.getInstance(),
                    accessLevels
            );

            List<DataImport__c> invalidatedDataImports = service.getInvalidRecords();
            System.assertEquals(1, invalidatedDataImports.size());
        }
    }

    /**
     * @description Integration test used to mimic the scenario where a master-detail field
     * returns false from a call to DescribeFieldResult.isUpdateable().  Since we cannot
     * currently add a Master-Detail field to the DataImport object within Apex,
     * implementations of the StubProvider interface are used to 1) make the platform think
     * that an existing field on DataImport is not updateable, and 2) confirm that the field
     * will be considered valid by the DescribeFieldResult.isUpdateable() if it is thought to
     * be a Master-Detail field, preventing the 'You do not have permissions to modify' error
     * when Master-Detail fields are mapped as targets for additional objects in BDI
     * Advanced Mapping.
     */
    @IsTest
    static void givenMasterDetailFieldPopulatedThenAssertFieldIsValidatedAsUpdateable
            () {
        //Insert a basic Data Import record with minimal Contact information
        DataImport__c dataImport = new DataImport__c(
                Contact1_Firstname__c = 'testFirst',
                Contact1_Lastname__c = 'testLast',
                Contact1_Work_Email__c = 'test@test99875409948.com',
                Opportunity_Contact_Role_1_Role__c = 'Test'
        );
        insert dataImport;

        //Create a stub that will mock the UTIL_Permissions.isUpdateable() method
        //so that the Contact.LastName field will return false
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock();
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
                UTIL_Permissions.class,
                utilPermissionsMockInstance);
        UTIL_Permissions.setInstance(utilPermissionsMock);
        //Process the Data Import record
        BDI_DataImportService dataImportService = new BDI_DataImportService(
                false,
                BDI_DataImportService.getDefaultMappingService());
        dataImportService.process(
                null,
                BDI_DataImportService.loadSettings(null),
                new List<DataImport__c>{
                        dataImport
                });

        //Assert that the Data Import record fails with
        //a permissions error on the LastName field
        List<DataImport__c> processedDataImports = [
                SELECT
                        Status__c,
                        FailureInformation__c
                FROM DataImport__c
                WHERE Id = :dataImport.Id
        ];
        System.assertEquals(dataImportService.statusDIFailed(),
                processedDataImports[0].Status__c);
        System.assert(processedDataImports[0].FailureInformation__c.contains(
                System.Label.flsError.replace('{0}', 'Contact.LastName')
        ), 'The utilPermissionsMockInstance should have reported ' +
                'the Contact.LastName field as not updateable.');

        //Now create a stub that will mock the UTIL_Describe.isMasterDetailField() method
        //so that the Contact.LastName field will return true
        UTIL_DescribeMock mockInstance = new UTIL_DescribeMock();
        UTIL_Describe describeServiceMock = (UTIL_Describe) Test.createStub(
                UTIL_Describe.class,
                mockInstance);
        UTIL_Describe.setInstance(describeServiceMock);

        //Re-process the Data Import record
        dataImportService.process(
                null,
                BDI_DataImportService.loadSettings(null),
                new List<DataImport__c>{
                        dataImport
                });

        processedDataImports = [
                SELECT
                        Status__c,
                        FailureInformation__c
                FROM DataImport__c
                WHERE Id = :dataImport.Id
        ];

        //Since the Contact.LastName field is now considered a Master-Detail
        //field, assert that it is skipped by the BDI_DataImportFLSService.isValid method
        //and the Data Import record processes successfully
        System.assertEquals(dataImportService.statusDISuccess(),
                processedDataImports[0].Status__c);
        System.assertEquals(null, processedDataImports[0].FailureInformation__c,
                'The Data Import record should have re-processed successfully, since the ' +
                        'non-updateable master-detail field should have been ' +
                        'considered valid by the mocked BDI_DataImportFLSService.');
    }

    /**
     * @description This test validates that the CampaignMember.CampaignId gets
     * exempted from Field Level Security checks to allow for campaign member imports
     */
    @IsTest
    static void testCampaignIdIsValidateUpdateException () {
        UTIL_CustomSettingsFacade.enableAdvancedMapping();
        Set<BDI_DataImportFLSService.AccessLevel> accessLevels = new
                Set<BDI_DataImportFLSService.AccessLevel>{
                BDI_DataImportFLSService.AccessLevel.VALIDATE_UPDATE,
                BDI_DataImportFLSService.AccessLevel.VALIDATE_READ,
                BDI_DataImportFLSService.AccessLevel.VALIDATE_CREATE
        };

        BDIFieldMappingMock mock = new BDIFieldMappingMock();
        mock.mapField(DataImport__c.Account1_Name__c, CampaignMember.SObjectType,
                CampaignMember.CampaignId);
        mock.mapField(DataImport__c.Campaign_Member_Status__c, CampaignMember.SObjectType,
                CampaignMember.Status);
        BDI_MappingServiceAdvanced stub = (BDI_MappingServiceAdvanced) Test.createStub(
                BDI_MappingServiceAdvanced.class, mock);
        BDI_MappingServiceAdvanced.setInstance(stub);

        Campaign campaign = new Campaign(Name = 'Test Campaign');
        insert campaign;

        DataImport__c dataImport = new DataImport__c(
                Account1_Name__c = campaign.Id,
                Campaign_Member_Status__c = 'Responded'
        );

        BDI_DataImportFLSService service = new BDI_DataImportFLSService(
                new List<DataImport__c> {
                        dataImport
                },
                BDI_DataImportService.getDefaultMappingService(),
                accessLevels
        );

        System.assertEquals(service.getInvalidRecords().size(), 0,
                'All records to be imported should be validated');
    }

    /**
     * @description This test validates the FLS checks on a master-detail field
     */
    @IsTest
    static void testMasterDetailFieldValid() {
        Set<BDI_DataImportFLSService.AccessLevel> accessLevels = new
                Set<BDI_DataImportFLSService.AccessLevel> {
                BDI_DataImportFLSService.AccessLevel.VALIDATE_UPDATE,
                BDI_DataImportFLSService.AccessLevel.VALIDATE_READ,
                BDI_DataImportFLSService.AccessLevel.VALIDATE_CREATE
        };

        BDI_DataImportFLSService service = new BDI_DataImportFLSService(accessLevels);
        Boolean valid = service.isValid(Account_Soft_Credit__c.SObjectType, Account_Soft_Credit__c.Opportunity__c);
        System.assertEquals(true, valid, 'This master detail field ' +
                'should be certified valid for data import processing');
    }


    /**
    * @description This test validates the FLS checks on a non-master-detail field
    */
    @IsTest
    static void testNormalFieldValid() {
        Set<BDI_DataImportFLSService.AccessLevel> accessLevels = new
                Set<BDI_DataImportFLSService.AccessLevel> {
                BDI_DataImportFLSService.AccessLevel.VALIDATE_UPDATE,
                BDI_DataImportFLSService.AccessLevel.VALIDATE_READ,
                BDI_DataImportFLSService.AccessLevel.VALIDATE_CREATE
        };

        BDI_DataImportFLSService service = new BDI_DataImportFLSService(accessLevels);
        Boolean valid = service.isValid(Contact.SObjectType, Contact.FirstName);
        System.assertEquals(true, valid, 'This field should be certified valid for data import processing');
    }

    /**
     * @description StubProvider implementation used to make a field be considered a
     * master-detail field in tests.
     */
    private class UTIL_DescribeMock implements StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            if (stubbedMethodName == 'isMasterDetailField') {
                SObjectField field = (SObjectField) listOfArgs[0];
                DescribeFieldResult dfr = field.getDescribe();
                if (dfr.getName() == 'LastName') {
                    return true;
                } else {
                    return false;
                }
            }
            return null;
        }
    }

    /**
     * @description StubProvider implementation used to make a field non-updateable in tests.
     */
    private class UTIL_PermissionsMock implements StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            if (stubbedMethodName == 'canUpdate') {
                Set<SObjectField> fieldSet = (Set<SObjectField>) listOfArgs[0];
                SObjectField field = new List<SObjectField>(fieldSet)[0];
                if (field.getDescribe().getName() == 'LastName') {
                    return false;
                } else {
                    return true;
                }
            } else {
                return true;
            }
        }
    }

    /**
     * @description StubProvider implementation used to create field mappings in tests
     */
    private class BDIFieldMappingMock implements StubProvider {
        private Map<SObjectField, BDI_TargetFields> targetFieldsBySourceField = new
                Map<SObjectField, BDI_TargetFields>();

        @TestVisible
        private void mapField(SObjectField sourceField, SObjectType targetObjectType,
                SObjectField targetField) {
            BDI_TargetFields targetFields = targetFieldsBySourceField.get(sourceField);
            if (targetFields == null) {
                targetFields = new BDI_TargetFields();
            }
            targetFields.addTargetField(targetObjectType, targetField);
            targetFieldsBySourceField.put(sourceField, targetFields);
        }

        public Object handleMethodCall(
                Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'getTargetFieldsBySourceField' {
                    return targetFieldsBySourceField;
                }
            }
            return null;
        }
    }
}