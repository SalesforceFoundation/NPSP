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
* @description Wrapper class to hold data related to the object mapping 
*/
public virtual with sharing class BDI_ObjectMapping {
    @AuraEnabled public Id Id;
    @AuraEnabled public String DeveloperName;
    @AuraEnabled public String MasterLabel;
    @AuraEnabled public String Custom_Mapping_Logic_Class;
    @AuraEnabled public String Data_Import_Object_Mapping_Set;
    @AuraEnabled public String Data_Import_Object_Mapping_Set_Dev_Name;
    @AuraEnabled public String Imported_Record_Field_Name;
    @AuraEnabled public String Imported_Record_Status_Field_Name;
    @AuraEnabled public Boolean Is_Deleted;
    @AuraEnabled public String Object_API_Name;
    @AuraEnabled public String Predecessor;
    @AuraEnabled public String Predecessor_Label_Name;
    @AuraEnabled public String Relationship_Field;
    @AuraEnabled public String Relationship_To_Predecessor;
    @AuraEnabled public String dynamicSourceField;
    @AuraEnabled public BDI_FieldMapping[] Field_Mappings;

    /*******************************************************************************************************
    * @description No parameter constructor to enable use as virtual class.
    */
    public BDI_ObjectMapping() {
        
    }

    /*******************************************************************************************************
    * @description Constructor that populates the wrapper with data from a Data_Import_Object_Mapping__mdt record.
    * @param objectMapping the Data_Import_Object_Mapping__mdt to populate from.
    */
    public BDI_ObjectMapping(Data_Import_Object_Mapping__mdt objectMapping) {
        this.Id = objectMapping.Id;
        this.MasterLabel = objectMapping.MasterLabel;
        this.DeveloperName = objectMapping.DeveloperName;

        //If the code is not in the npsp namespace, then the npsp field prefixes will need to be systematically removed.
        if (UTIL_Namespace.shouldAlignNamespace) {
            objectMapping.Imported_Record_Field_Name__c = 
                UTIL_Namespace.alignSchemaNSWithEnvironment(objectMapping.Imported_Record_Field_Name__c);
            objectMapping.Imported_Record_Status_Field_Name__c = 
                UTIL_Namespace.alignSchemaNSWithEnvironment(objectMapping.Imported_Record_Status_Field_Name__c);
            objectMapping.Object_API_Name__c = 
                UTIL_Namespace.alignSchemaNSWithEnvironment(objectMapping.Object_API_Name__c);
            objectMapping.Relationship_Field__c = 
                UTIL_Namespace.alignSchemaNSWithEnvironment(objectMapping.Relationship_Field__c);
        }

        this.Custom_Mapping_Logic_Class = objectMapping.Custom_Mapping_Logic_Class__c;
        this.Data_Import_Object_Mapping_Set = objectMapping.Data_Import_Object_Mapping_Set__c;
        this.Data_Import_Object_Mapping_Set_Dev_Name = objectMapping.Data_Import_Object_Mapping_Set__r.DeveloperName;
        this.Imported_Record_Field_Name = UTIL_Describe.getFieldName(SObjectType.DataImport__c.Name,
            objectMapping.Imported_Record_Field_Name__c);
        this.Imported_Record_Status_Field_Name = UTIL_Describe.getFieldName(SObjectType.DataImport__c.Name,
            objectMapping.Imported_Record_Status_Field_Name__c);
        this.Object_API_Name = UTIL_Describe.getObjectName(objectMapping.Object_API_Name__c);

        this.Relationship_Field = objectMapping.Relationship_Field__c;

        this.Is_Deleted = objectMapping.Is_Deleted__c;
        this.Predecessor = objectMapping.Predecessor__c;
        this.Relationship_To_Predecessor = objectMapping.Relationship_To_Predecessor__c;
        this.Field_Mappings = new BDI_FieldMapping[]{};
    }

    /*******************************************************************************************************
    * @description Constructor used when cloning an existing BDI_ObjectMapping
    * @param objectMapping the existing BDI_ObjectMapping to be cloned
    * @param newDevName the new Developer name to be used for the object mapping
    */
    public BDI_ObjectMapping(BDI_ObjectMapping objectMapping, String newDevName) {
        this.MasterLabel = objectMapping.MasterLabel;
        this.DeveloperName = newDevName;
        this.Custom_Mapping_Logic_Class = objectMapping.Custom_Mapping_Logic_Class;
        this.Data_Import_Object_Mapping_Set = objectMapping.Data_Import_Object_Mapping_Set;
        this.Data_Import_Object_Mapping_Set_Dev_Name = objectMapping.Data_Import_Object_Mapping_Set_Dev_Name;
        this.Imported_Record_Field_Name = objectMapping.Imported_Record_Field_Name;
        this.Imported_Record_Status_Field_Name = objectMapping.Imported_Record_Status_Field_Name;
        this.Object_API_Name = objectMapping.Object_API_Name;
        this.Relationship_Field = objectMapping.Relationship_Field;
        this.Is_Deleted = objectMapping.Is_Deleted;
        this.Predecessor = objectMapping.Predecessor;
        this.Relationship_To_Predecessor = objectMapping.Relationship_To_Predecessor;
    }
}
