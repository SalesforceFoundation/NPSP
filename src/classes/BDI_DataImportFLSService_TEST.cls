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
                BDI_FieldMappingCustomMetadata.getInstance(),
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

        User readOnlyUser = UTIL_UnitTestData_TEST.createUserWithoutInsert('Read Only');
        System.runAs(readOnlyUser) {
            BDI_DataImportFLSService service = new BDI_DataImportFLSService(
                    new List<DataImport__c>{
                            dataImport
                    },
                    BDI_FieldMappingCustomMetadata.getInstance(),
                    accessLevels
            );

            List<DataImport__c> invalidatedDataImports = service.getInvalidRecords();
            System.assertEquals(1, invalidatedDataImports.size());
        }
    }
}