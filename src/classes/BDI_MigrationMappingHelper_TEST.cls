/*
    Copyright (c) 2014 Salesforce.org
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
* @description Unit Test for the Migration Mapping Helper
*/

@IsTest
private class BDI_MigrationMappingHelper_TEST {

    /*******************************************************************************************************
    * @description Developer name of the default field mapping set (Data_Import_Field_Mapping_Set__mdt)
    */
    private static final String DEFAULT_FIELD_MAPPING_SET = 'Default_Field_Mapping_Set';

    /*******************************************************************************************************
    * @description Developer name of the default object mapping set (Data_Import_Object_Mapping_Set__mdt)
    */
    public static final String DEFAULT_OBJECT_MAPPING_SET= 'Default_Object_Mapping_Set';

    /*******************************************************************************************************
    * @description list of Strings as defaultFieldMapping input
    */
    public static List<String> newDefaultMappingStrings = new List<String>{'Account_1_City', 'Account_1_Country'};

    /*******************************************************************************************************
    * @description Test that we can retrieve the packaged default field mapping set
    */
    @isTest
    static void shouldGetFieldMappingSet() {
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();

        List<Data_Import_Field_Mapping_Set__mdt> fieldMappingSets =
            helper.getFieldMappingSet(DEFAULT_FIELD_MAPPING_SET);

        System.assert(fieldMappingSets.size() > 0,
            'We\'re able to retrieve the packaged default field mapping set');
    }

    /*******************************************************************************************************
    * @description Test that we can retrieve and convert the Data Import's help text field to Help Text
    * Field Mappings
    */
    @isTest
    static void shouldGetListOfHelpTextFieldMappingsFromDataImportHelpText() {
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();

        List<BDI_MigrationMappingUtility.HelpTextFieldMapping> helpTextFieldMappings =
            helper.getAllHelpTextFieldMappings();

        System.assert(helpTextFieldMappings.size() > 0,
            'We\'re able to create help text field mapppings from Data Import help text fields');
    }

    /*******************************************************************************************************
    * @description Test that we can retrieve a map of the packaged data import object mappings
    * (Data_Import_Object_Mapping__mdt)
    */
    @isTest
    static void shouldgetObjectMappingsBySetDeveloperName() {
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();

        Map<String, Data_Import_Object_Mapping__mdt> objectMappings =
            helper.getObjectMappingsBySetDeveloperName(DEFAULT_OBJECT_MAPPING_SET);

        System.assert(objectMappings.size() > 0,
            'We\'re able to retrieve a map of the packaged data import object mappings');
    }

    /*******************************************************************************************************
    * @description Test that we can retrieve the packaged data import field mappings
    * (Data_Import_Field_Mapping__mdt)
    */
    @isTest
    static void shouldgetFieldMappingsByFieldMappingSetDeveloperName() {
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();

        Map<String, Data_Import_Field_Mapping__mdt> fieldMappings =
            helper.getFieldMappingsByFieldMappingSetDeveloperName(DEFAULT_FIELD_MAPPING_SET);

        System.assert(fieldMappings.size() > 0,
            'We\'re able to retrieve a map of the packaged data import field mappings');
    }

    /*******************************************************************************************************
    * @description Test that we can retrieve the packaged data import field mappings
    * (Data_Import_Field_Mapping__mdt)
    */
    @isTest
    static void shouldGetFieldMappingStringsBySetDeveloperName() {
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();

        Map<String, Data_Import_Field_Mapping__mdt> fieldMappings =
                helper.getFieldMappingStringsBySetDeveloperName(DEFAULT_FIELD_MAPPING_SET);

        System.assert(fieldMappings.size() > 0,
                'We\'re able to retrieve a map of the packaged data import field mappings');
    }

    /*******************************************************************************************************
    * @description Test that we can retrieve field values from the packaged data import field mappings
    * (Data_Import_Field_Mapping__mdt)
    */
    @isTest
    static void shouldGetFieldMappingKeysByDeveloperName() {
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();

        List<String> fieldMappings =
                helper.getFieldMappingKeysByDeveloperName(newDefaultMappingStrings, DEFAULT_FIELD_MAPPING_SET);

        System.assert(fieldMappings.size() > 0,
                'We\'re able to retrieve a list of the packaged data import field mappings');
    }

    /*******************************************************************************************************
   * @description Test that we can retrieve values from Custom Metadata Type Object Mapping
   */
    @isTest
    static void shouldGetObjectDeveloperNameByLabel() {
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();

        Map<String, Data_Import_Object_Mapping__mdt> existingMigratedObjectMappings =
                helper.getObjectMappingsBySetDeveloperName(
                        BDI_MigrationMappingUtility.MIGRATED_CUSTOM_OBJECT_MAPPING_SET_RECORD_NAME);

        Map <String, String> objectFieldMappingStrings =
                helper.getDataImportObjectDeveloperNamesByLabel();

        if (existingMigratedObjectMappings.size() > 0) {
            System.assert(objectFieldMappingStrings.size() > 0,
                    'Migrated Custom Object Mapping exists and we\'re able to retrieve them');
        } else {
            System.assert(objectFieldMappingStrings.size() == 0,
                    'Migrated Custom Object Mapping does not exists so we\'re unable to retrieve them');
        }
    }
}
