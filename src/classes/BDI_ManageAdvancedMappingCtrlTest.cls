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
* @description Unit Test for BDI_ManageAdvancedMappingCtrl
*/

@IsTest
private class BDI_ManageAdvancedMappingCtrlTest {

    /*******************************************************************************************************
    * @description Initialize test custom settings record
    */
    private static Data_Import_Settings__c settingsInstance;

    /*******************************************************************************************************
    * @description Name of test Data Import Field Mapping Set
    */
    private static final String DEFAULT_FIELD_MAPPING_SET_NAME = 'Default_Field_Mapping_Set';

    /*******************************************************************************************************
    * @description Name of test Data Import Field Mapping Set
    */
    private static final String DEFAULT_OBJECT_MAPPING_SET_NAME = 'Default_Object_Mapping_Set';

    /*******************************************************************************************************
    * @description Name of default Account1 Data Import Object Mapping
    */
    private static final String ACCOUNT1 = 'Account1';

    /*******************************************************************************************************
    * @description Account object name
    */
    private static final String ACCOUNT_OBJECT = 'Account';

    /*******************************************************************************************************
    * @description Contact object name
    */
    private static final String CONTACT_OBJECT = 'Contact';

    /*******************************************************************************************************
    * @description Test that we get the current namespace
    */
    @isTest
    static void shouldReturnCurrentPackageNamespace() {
        ApexClass controllerClass = [SELECT NamespacePrefix
            FROM ApexClass
            WHERE Name = :'BDI_ManageAdvancedMappingCtrl'];
        String actualNamespace = controllerClass.NamespacePrefix;

        String namespace = BDI_ManageAdvancedMappingCtrl.getNamespacePrefix();

        System.assertEquals(actualNamespace, namespace);
    }

    /*******************************************************************************************************
    * @description Test that we get the default field mapping set name
    */
    @isTest
    static void shouldReturnDefaultDataImportFieldMappingSetName() {
        String defaultDataImportFieldMappingSetName = BDI_ManageAdvancedMappingCtrl.getFieldMappingSetName();

        System.assertEquals(DEFAULT_FIELD_MAPPING_SET_NAME, defaultDataImportFieldMappingSetName);
    }

    /*******************************************************************************************************
    * @description Test that we create the correct number of Data Import Object Mapping wrappers
    */
    @isTest
    static void shouldGetCorrectNumberOfObjectMappingWrappers() {
        Data_Import_Object_Mapping__mdt[] defaultObjectMappings = [SELECT Id
            FROM Data_Import_Object_Mapping__mdt
            WHERE Data_Import_Object_Mapping_Set__r.DeveloperName = :DEFAULT_OBJECT_MAPPING_SET_NAME];

        BDI_ManageAdvancedMappingCtrl.DataImportObjectMappingWrapper[] objectMappingWrappers =
            BDI_ManageAdvancedMappingCtrl.getObjectMappings();

        System.assertEquals(defaultObjectMappings.size(), objectMappingWrappers.size());
    }

    /*******************************************************************************************************
    * @description Test that we create the correct number of Field Info wrappers for the given objects
    */
    @isTest
    static void shouldGetCorrectNumberOfObjectMappingFieldInfosForGivenObject() {
        Map<String, Schema.SObjectField> accountFieldMap = Account.sObjectType.getDescribe().Fields.getMap();
        Set<String> creatableAccountFields = getCreatableFields(accountFieldMap);

        Map<String, Schema.SObjectField> contactFieldMap = Contact.sObjectType.getDescribe().Fields.getMap();
        Set<String> creatableContactFields = getCreatableFields(contactFieldMap);

        BDI_ManageAdvancedMappingCtrl.FieldInfo[] accountFieldInfos =
            BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes(ACCOUNT_OBJECT);

        BDI_ManageAdvancedMappingCtrl.FieldInfo[] contactFieldInfos =
            BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes(CONTACT_OBJECT);

        System.assertEquals(creatableAccountFields.size(), accountFieldInfos.size());
        System.assertEquals(creatableContactFields.size(), contactFieldInfos.size());
    }

    /*******************************************************************************************************
    * @description Test that we create the correct number of Field Info wrappers for the given object
    */
    @isTest
    static void shouldGetCorrectNumberOfFieldMappingWrappersForGivenObjectMapping() {
        Data_Import_Field_Mapping__mdt[] account1FieldMappings = [SELECT Id
            FROM Data_Import_Field_Mapping__mdt
            WHERE Data_Import_Field_Mapping_Set__r.DeveloperName = :DEFAULT_FIELD_MAPPING_SET_NAME
                AND Target_Object_Mapping__r.DeveloperName = :ACCOUNT1];

        BDI_ManageAdvancedMappingCtrl.DataImportFieldMappingWrapper[] account1FieldMappingWrappers =
            BDI_ManageAdvancedMappingCtrl.getFieldMappingsByObjectAndFieldSetNames(
                ACCOUNT1,
                DEFAULT_FIELD_MAPPING_SET_NAME);

        System.assertEquals(account1FieldMappings.size(), account1FieldMappingWrappers.size());
    }

    static Set<String> getCreatableFields(Map<String, Schema.SObjectField> fieldMap) {
        Set<String> creatableFields = new Set<String>();
        if (fieldMap != null) {
            for (Schema.SObjectField ft : fieldMap.values()) {
                Schema.DescribeFieldResult fieldDescribe = ft.getDescribe();
                if (fieldDescribe.isCreateable()) {
                    creatableFields.add(fieldDescribe.getName());
                }
            }
        }
        return creatableFields;
    }
}
