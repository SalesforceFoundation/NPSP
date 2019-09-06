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
* @description Virtual class containing the standard logic for matching source and target records.  
* Can be overriden by clients who need custom matching logic.
*/

public with sharing virtual class BDI_ObjectMatchingLogic {

    public virtual BDI_ObjectWrapper[] matchObjects(BDI_ObjectWrapper[] objWraps, BDI_DataImportService dataImportService) {
        if (objWraps != null && objWraps.size() > 0 && objWraps[0].fieldMappings != null) {

            Boolean shouldMatch = false;

            //Note it is assumed that all object wraps passed into this class will be using the same
            //field mappings.
            Data_Import_Field_Mapping__mdt[] fieldMappings = objWraps[0].fieldMappings;

            String targetObject = objWraps[0].objMapping.Object_API_Name__c;
            String importedRecordStatusField = objWraps[0].objMapping.Imported_Record_Status_Field_Name__c;
            String importedRecordField = objWraps[0].objMapping.Imported_Record_Field_Name__c;

            String matchSourceField;
            String matchTargetField;
            Integer matchSourceCount = 0;

            //Determine what the source field is for matching
            for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappings) {
                if (fieldMapping.Match_On_This_Mapping__c == 'Yes') {
                    matchSourceField = fieldMapping.Source_Field_API_Name__c;
                    matchTargetField = fieldMapping.Target_Field_API_Name__c;

                    matchSourceCount++;
                }
            }

            Map<String,BDI_ObjectWrapper[]> objWrapsByMatchingSourceValue = new Map<String,BDI_ObjectWrapper[]>();

            //For basic matching only one match field is allowed, if there is more than one then
            //add an error to all data import records;
            if (matchSourceCount > 1) {
                for (BDI_ObjectWrapper objWrap : objWraps) {             
                    objWrap.logError(dataImportService.statusDIFailed(),System.label.bdiObjMatchErrorTooManyMatchingFields);
                }
            } else if (matchSourceCount == 1) {

                // If the source field for the match on the DI has a value then we will attempt to match.
                // also add the source strings for matching to a list.
                for (BDI_ObjectWrapper objWrap : objWraps) {

                    String sourceValue = (String)objWrap.dataImport.get(matchSourceField);

                    //If the source value for matching to target records is not null then add to map
                    //for later use in querying and matching the results.
                    if (sourceValue != null && sourceValue.length() > 0) {

                        if (objWrapsByMatchingSourceValue.get(sourceValue) != null) {
                            objWrapsByMatchingSourceValue.get(sourceValue).add(objWrap);
                        } else {
                            objWrapsByMatchingSourceValue.put(sourceValue, new BDI_ObjectWrapper[]{objWrap});
                        }
                    }
                }

                if (objWrapsByMatchingSourceValue.size() > 0) {
                    Set<String> stringsToMatch = objWrapsByMatchingSourceValue.keySet();

                    String query = 'SELECT Id, ' + matchTargetField 
                        + ' FROM '  + targetObject + 
                        ' WHERE ' + matchTargetField + ' IN: stringsToMatch';

                    SObject[] queryResults = Database.query(query);

                    Map<String,SObject[]> matchingSObjectsByMatchString = new Map<String,SObject[]>();

                    if (queryResults != null && queryResults.size() > 0) {
                        //Place the result SObjects in a map by the matching value to facilitate linking back
                        //to the DI records.
                        for (SObject result : queryResults) {
                            String targetFieldValue = (String)result.get(matchTargetField);
                            if (matchingSObjectsByMatchString.get(targetFieldValue) != null) {
                                matchingSObjectsByMatchString.get(targetFieldValue).add(result);
                            } else {
                                matchingSObjectsByMatchString.put(targetFieldValue, new SObject[]{result});
                            }
                        }
                    }

                    //Loop back through the obj wraps and match to the result set, then update the import status.
                    for (BDI_ObjectWrapper objWrap : objWraps) {

                        //Clear out any existing Imported Record Status
                        objWrap.dataImport.put(importedRecordStatusField, null);

                        String sourceValue = (String)objWrap.dataImport.get(matchSourceField);

                        if (sourceValue != null) {
                            SObject[] matchingSObjs = matchingSObjectsByMatchString.get(sourceValue); 

                            if (matchingSObjs != null) {

                                if (matchingSObjs.size() == 1){
                                    objWrap.dataImport.put(importedRecordStatusField,
                                        dataImportService.statusMatchedExisting());
                                    objWrap.dataImport.put(importedRecordField,matchingSObjs[0].Id);
                                    objWrap.existingSObjectId = matchingSObjs[0].Id;
                                } else if (matchingSObjs.size() > 1) {
                                    objWrap.logError(dataImportService.statusDIFailed(),
                                        System.label.bdiObjMatchErrorMultipleMatch + ' ' + matchSourceField);
                                }
                            }
                        } 

                        //If it didn't match any records and there wasn't an error, then put in the no match status
                        if (objWrap.dataImport.get(importedRecordStatusField) == null) {
                            objWrap.dataImport.put(importedRecordStatusField,
                                dataImportService.statusMatchedNone());
                        }
                    }
                }
            }
        }
        return objWraps;
    }
}