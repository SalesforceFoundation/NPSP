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
* @description Wrapper class to hold data related to the field mapping set.
*/
public with sharing class BDI_FieldMappingSet {
    @AuraEnabled public String DeveloperName;
    @AuraEnabled public String MasterLabel;
    @AuraEnabled public Id Id;
    @AuraEnabled public String Data_Import_Object_Mapping_Group_Dev_Name;

    @AuraEnabled public Map<String,BDI_ObjectMapping> objectMappingByDevName = new Map<String,BDI_ObjectMapping>();
    @AuraEnabled public Map<String,BDI_FieldMapping> fieldMappingByDevName = new Map<String,BDI_FieldMapping>();
    @AuraEnabled public Map<String,BDI_FieldMapping> fieldMappingByTargetFieldName = new Map<String,BDI_FieldMapping>();
    @AuraEnabled public Map<String,BDI_FieldMapping[]> fieldMappingsByObjMappingDevName = new Map<String,BDI_FieldMapping[]>();


    /*******************************************************************************************************
    * @description Constructor that wraps together the field mapping set info using already constructed
    * BDI_ObjectMapping and BDI_FieldMapping objects and a Data_Import_Field_Mapping_Set__mdt record.
    * @param fieldMappingSet
    * @param objectMappingByDevName
    * @param fieldMappingByDevName
    */
    public BDI_FieldMappingSet(Data_Import_Field_Mapping_Set__mdt fieldMappingSet, 
                                Map<String,BDI_ObjectMapping> objectMappingByDevName,
                                Map<String,BDI_FieldMapping>  fieldMappingByDevName,
                                Map<String,BDI_FieldMapping>  fieldMappingByTargetFieldName,
                                Map<String,BDI_FieldMapping[]> fieldMappingsByObjMappingDevName) {

        this.DeveloperName = fieldMappingSet.DeveloperName;
        this.MasterLabel = fieldMappingSet.MasterLabel;
        this.Id = fieldMappingSet.Id;
        this.Data_Import_Object_Mapping_Group_Dev_Name = fieldMappingSet.Data_Import_Object_Mapping_Set__r.DeveloperName;

        this.objectMappingByDevName = objectMappingByDevName;
        this.fieldMappingByDevName = fieldMappingByDevName;
        this.fieldMappingByTargetFieldName = fieldMappingByTargetFieldName;
        this.fieldMappingsByObjMappingDevName = fieldMappingsByObjMappingDevName;
    }
}
