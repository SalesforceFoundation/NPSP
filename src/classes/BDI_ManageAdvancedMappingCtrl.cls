/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Visualforce page Controller for the Manage Advanced Mappings VF page
*/
public class BDI_ManageAdvancedMappingCtrl {

    private static BDI_FieldMappingCustomMetadata bdiCMT = BDI_FieldMappingCustomMetadata.getInstance();

    /** @description what is the namespace (an empty string if unmanaged, or 'npsp' if managed) */
    public string getNamespacePrefix() {
        return UTIL_Namespace.getNamespace();
    }

    @AuraEnabled(cacheable=true)
    public static Data_Import_Object_Mapping__mdt[] getObjectMappings(){
        Data_Import_Object_Mapping__mdt[] objMappings = bdiCMT.objMappingsByDevName.values();
        return objMappings;
    }

    @AuraEnabled(cacheable=true)
    public static DataImportFieldMappingWrapper[] getFieldMappingsByObjectMappingName(String name) {
        DataImportFieldMappingWrapper[] fieldMappingWrappers =
            new List<DataImportFieldMappingWrapper>();
        Data_Import_Field_Mapping__mdt[] fieldMappings =
            bdiCMT.fieldMappingsByObjMappingDevName.get(name);

        for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappings) {
            fieldMappingWrappers.add(new DataImportFieldMappingWrapper(fieldMapping));
        }

        return fieldMappingWrappers;
    }

    public class DataImportFieldMappingWrapper {
        @AuraEnabled public String MasterLabel;
        @AuraEnabled public String Source_Field_API_Name;
        @AuraEnabled public String Target_Field_API_Name;
        @AuraEnabled public String Maps_To_Icon;
        @AuraEnabled public String Source_Field_Label;
        @AuraEnabled public String Source_Field_Data_Type;
        // TODO: Still needs to be assigned
        @AuraEnabled public String Target_Field_Data_Type;

        public DataImportFieldMappingWrapper(Data_Import_Field_Mapping__mdt fieldMapping) {
            Schema.DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(
                UTIL_Namespace.StrTokenNSPrefix('DataImport__c'),
                UTIL_Namespace.removeNSPrefixNpspOnly(fieldMapping.Source_Field_API_Name__c));

            this.MasterLabel = fieldMapping.MasterLabel;
            this.Source_Field_API_Name = fieldMapping.Source_Field_API_Name__c;
            this.Target_Field_API_Name = fieldMapping.Target_Field_API_Name__c;

            this.Maps_To_Icon = 'utility:forward';
            this.Source_Field_Label = dfr.label;
            this.Source_Field_Data_Type = String.valueOf(dfr.type);
        }
    }

}// BDI_ManageAdvancedMappingCtrl
