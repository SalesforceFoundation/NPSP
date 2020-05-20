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
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Unit tests to cover changes made to support custom metadata mapping for BDI.
*/
@isTest
private class BDI_MappingServiceAdvanced_TEST {
    /*******************************************************************************************************
    * @description Tests that the BDI_MappingServiceAdvanced class can be instantiated correctly 
    *  based on the custom setting value and that it will return a string map for a core object 
    *  when called (using the default set of field mappings).
    */
    @isTest static void shouldReturnMapOfFieldsForCoreObject() {

        //Set the custom setting for Data import to use Data Import Field Mappings (eg Custom Metadata Type Mapping)
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c = 
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        //Retrieve a mapping service instance using the getDefaultMappingService method 
        //and confirm it is the custom metadata implementation
        BDI_MappingService bdiMS = BDI_DataImportService.getDefaultMappingService();
        String className = String.valueOf(bdiMS).split(':')[0];
        System.assertEquals('BDI_MappingServiceAdvanced',className);

        //Instantiate and call the data import service with the field mapping specified
        BDI_DataImportService bdiDis = new BDI_DataImportService(false, bdiMS);
        Map<String,String> accountFieldMapping = 
            bdiDis.mapDataImportFields('Account1','Account',BDI_DataImportService.listStrDataImportFields);
        System.assertNotEquals(null,accountFieldMapping);
        //Confirm that there are at least 8 records
        System.assert(accountFieldMapping.size() >= 8);

        String namespace = UTIL_Namespace.getNamespace();
        String sampleField = 'npsp__account1_city__c';
        
        if (UTIL_Namespace.shouldAlignNamespace) {
            sampleField = UTIL_Namespace.alignSchemaNSWithEnvironment(sampleField);
        }
        //Sample one of the fields to convfirm it is mapped correctly.
        System.assertEquals('BillingCity',accountFieldMapping.get(sampleField));

    }

    /*******************************************************************************************************
    * @description Tests that the UTIL_CustomSettingsFacade correctly sets the defaults for the Data Import Settings.
    */
    @isTest static void shouldReturnCorrectDefaultsForDISCustSetting() {
        //Confirm that the defaults for the fields are null.
        Data_Import_Settings__c dis1 = Data_Import_Settings__c.getInstance();
        System.assertEquals(null,dis1.Field_Mapping_Method__c);
        System.assertEquals(null,dis1.Default_Data_Import_Field_Mapping_Set__c);

        //Retreive the Data Import Settings and confirm that the defaults have been 
        //set correctly for the two CMT mapping related fields
        Data_Import_Settings__c dis2 = UTIL_CustomSettingsFacade.getDataImportSettings();

        System.assertEquals(BDI_DataImportService.FM_HELP_TEXT,dis2.Field_Mapping_Method__c);
        System.assertEquals(BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME,dis2.Default_Data_Import_Field_Mapping_Set__c);

    }

    /*******************************************************************************************************
    * @description Tests that the BDI_FieldMappingSet is properly constructed when getting an instance 
    * of the mapping service.
    */
    @isTest static void shouldReturnPopulatedBDIFieldMappingSet() {
        //Set the custom setting for Data import to use Data Import Field Mappings (eg Custom Metadata Type Mapping)
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c = BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        //Retrieve a mapping service instance
        BDI_MappingServiceAdvanced bdiMSAdv = BDI_MappingServiceAdvanced.getInstance();

        System.assert(bdiMSAdv.fieldMappingSet != null);
        System.assert(bdiMSAdv.fieldMappingSet.objectMappingByDevName.size() > 0);
        System.assert(bdiMSAdv.fieldMappingSet.fieldMappingByDevName.size() > 0);
    }

    /*******************************************************************************************************
    * @description Tests that the BDI_FieldMappingSet is properly constructed when getting an instance 
    * of BDI_FieldMappingSet through the AuraEnabled method getFieldMappingSet().
    */
    @isTest static void shouldReturnPopulatedBDIFieldMappingSetIncludingFieldMappingsByObjMappingDevName() {
        //Set the custom setting for Data import to use Data Import Field Mappings (eg Custom Metadata Type Mapping)
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c =
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        //Retrieve a mapping service instance
        BDI_MappingServiceAdvanced bdiMSAdv = BDI_MappingServiceAdvanced.getInstance(
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME,
            true);
        BDI_FieldMappingSet fms = BDI_MappingServiceAdvanced.getFieldMappingSet(
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME,
            true);

        System.assert(fms != null);
        System.assert(fms.objectMappingByDevName.size() > 0);
        System.assert(fms.fieldMappingByDevName.size() > 0);
        System.assert(fms.fieldMappingsByObjMappingDevName.size() > 0);
    }

    /*******************************************************************************************************
    * @description Tests that the Donation_Donor__c field from DataImport__c object has been added as a
    * simulated Field Mapping.
    */
    @isTest static void shouldAddDonationDonorFieldToMapsAsSimulatedFieldMapping() {
        //Set the custom setting for Data import to use Data Import Field Mappings
        // (eg Custom Metadata Type Mapping)
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c =
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        //Retrieve a mapping service instance
        BDI_MappingServiceAdvanced bdiMSAdv = BDI_MappingServiceAdvanced.getInstance(
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME,
            true);
        BDI_FieldMappingSet fms = BDI_MappingServiceAdvanced.getFieldMappingSet(
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME,
            true);

        // Confirm that we have the Donation_Donor__c field from DataImport__c as a Field Mapping
        Boolean hasDonationDonorFieldMapping = false;
        Schema.DescribeFieldResult dfr = SObjectType.DataImport__c.fields.Donation_Donor__c;
        BDI_FieldMapping donationDonorFieldMapping = fms.fieldMappingByDevName.get(dfr.getName());

        System.debug(donationDonorFieldMapping);
        System.assertNotEquals(
            null,
            donationDonorFieldMapping,
            'DataImport__c.Donation_Donor__c not found as a simulated Field Mapping.');
    }

    /*******************************************************************************************************
    * @description Tests that the various 'Imported' lookup fields from Object Mappings have been added as a
    * simulated Field Mappings.
    */
    @isTest static void shouldAddObjetMappingImportedFieldsToMapsAsSimulatedFieldMappings() {
        //Set the custom setting for Data import to use Data Import Field Mappings
        // (eg Custom Metadata Type Mapping)
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c =
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        //Retrieve a mapping service instance
        BDI_MappingServiceAdvanced bdiMSAdv = BDI_MappingServiceAdvanced.getInstance(
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME, true);
        BDI_FieldMappingSet fms = BDI_MappingServiceAdvanced.getFieldMappingSet(
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME, true);

        // Confirm that we have at least one DataImport__c.*Imported__c field as a Field Mapping
        Boolean hasImportedFieldMapping = false;
        for (String fieldMappingDevName : fms.fieldMappingByDevName.keySet()) {
            String targetFieldApiName =
                fms.fieldMappingByDevName.get(fieldMappingDevName).Target_Field_API_Name.toLowerCase();
            String sourceFieldApiName =
                fms.fieldMappingByDevName.get(fieldMappingDevName).Source_Field_API_Name.toLowerCase();

            if (targetFieldApiName == sourceFieldApiName && targetFieldApiName.contains('imported')) {
                hasImportedFieldMapping = true;
                break;
            }
        }

        System.assertEquals(
            true,
            hasImportedFieldMapping,
            'Could not find at least one Imported_Record_Field_Name__c field as a simulated Field Mapping.');
    }
}