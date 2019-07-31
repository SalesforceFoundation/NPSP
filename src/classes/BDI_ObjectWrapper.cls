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
* @description Wrapper class used to contain information about a particular object mapping and data import record combination.
*/

public with sharing class BDI_ObjectWrapper {

    public Data_Import_Object_Mapping__mdt objMapping;
    public Data_Import_Object_Mapping__mdt predecessorObjMapping;
    public Data_Import_Field_Mapping__mdt[] fieldMappings;
    public DataImport__c dataImport;
    public SObject sobj;

    public Id existingSObjectId;

    /*******************************************************************************************************
    * @description Constructor
    *
    * @param dataImport Instance of DataImport__c 
    * @param objMapping  CMT record for object from config
    * @param fieldMappings CMT records for field mappings from config
    * @param predessessorObjMapping CMT record of predessessor
    */
    public BDI_ObjectWrapper(DataImport__c dataImport, Data_Import_Object_Mapping__mdt objMapping, Data_Import_Field_Mapping__mdt[] fieldMappings, Data_Import_Object_Mapping__mdt predecessorObjMapping) {
        this.objMapping = objMapping;
        this.predecessorObjMapping = predecessorObjMapping;
        this.fieldMappings = fieldMappings;
        this.dataImport = dataImport;
    }

    /*******************************************************************************************************
    * @description Set the status for the DataImport__c
    */
    public void setDataImportStatus(String status) {
        dataImport.Status__c = status;
    }

    /*******************************************************************************************************
    * @description Set error information on the DataImport__c
    */
    public void setImportedRecordStatusError(String errorMessage) {
        String statusField = objMapping.Imported_Record_Status_Field_Name__c;
        if (statusField != null && errorMessage != null) {
            dataImport.put(statusField, errorMessage.left(255));
        }
    }

    /*******************************************************************************************************
    * @description Set failure information on the DataImport__c
    */
    public void setFailureInformation(String failureInformation) {
        dataImport.FailureInformation__c = failureInformation;
    }
}
