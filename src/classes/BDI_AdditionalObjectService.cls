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
* @description Implements the ability to import additional objects during batch data import.
*/

public with sharing class BDI_AdditionalObjectService {

    /*******************************************************************************************************
    * @description the data import service we are invoked from
    */
    private BDI_DataImportService dataImportService;
    private BDI_FieldMappingCustomMetadata fieldMapping;

    private Map<Integer,Map<String,Data_Import_Object_Mapping__mdt>> tierToObjMappings = new Map<Integer,Map<String,Data_Import_Object_Mapping__mdt>>();
    private Map<String,Map<String,Data_Import_Object_Mapping__mdt>> predecessorDevNameToSuccessors = new Map<String,Map<String,Data_Import_Object_Mapping__mdt>>();
    private Set<String> importedRecordFieldNames = new Set<String>();

    public Set<String> objMappingDevNames = new Set<String>();

    /*******************************************************************************************************
    * @description Constructor
    * @param dataImportService The data import service instance that invokes us
    */
    public BDI_AdditionalObjectService(BDI_DataImportService dataImportService) {
        this.dataImportService = dataImportService;
        this.fieldMapping = BDI_FieldMappingCustomMetadata.getInstance();
    }


    /*******************************************************************************************************
    * @description Main method to call to begin the additional object import process.
    */
    public void importAdditionalObjects(){

        generateTiersOfObjectMappings();
        createSetOfImportedRecordFieldNames(fieldMapping.objMappingDevNameToObjMapping.values());

        //Iterate through the map of tiers, starting with the first tier that actually has a predecessor (ie 2nd tier), and
        //validate and create each object as appropriate.
        for (Integer i = 1; i < tierToObjMappings.size(); i++) {

            Map<String,Data_Import_Object_Mapping__mdt> currentTier = tierToObjMappings.get(i);

            DataImport__c[] disWithoutFailure = new DataImport__c[]{};

            // Removing DIs that have already failed from the list since it is likely that it will fail due to predecessors not existing anyway.
            for (DataImport__c di : dataImportService.listDI) {
                if(di.Status__c != BDI_DataImport_API.bdiFailed){
                    disWithoutFailure.add(di);
                }
            }

            //for the current tier of object mappings, validate and populate object wrappers for later processing.
            Map<String,BDI_ObjectWrapper[]> objAPINameToObjWraps = prepareObjectWrappers(currentTier,disWithoutFailure);

            // if this is not a dry run then perform the insert/update of the object wrappers.
            if (!dataImportService.isDryRun) {
                importObjectWrappers(objAPINameToObjWraps);
            }
        }
    }

    /*******************************************************************************************************
    * @description Prepares object wrappers for a given tier of object mappings and data import records.
    * @param currentTierOfObjMappings a list of object mappings that are all on the same level of the object hierarchy
    * @param dataImportRecords the data import records that the preparation should be performed on.
    */

    private Map<String,BDI_ObjectWrapper[]> prepareObjectWrappers (Map<String,Data_Import_Object_Mapping__mdt> currentTierOfObjMappings, DataImport__c[] dataImportRecords) {

        Map<String,BDI_ObjectWrapper[]> objAPINameToObjWraps = new Map<String,BDI_ObjectWrapper[]>();

        if (currentTierOfObjMappings != null) {
            for (Data_Import_Object_Mapping__mdt objMapping : currentTierOfObjMappings.values()) {

                BDI_ObjectMappingLogic objMappingLogic = getObjectMappingLogicClass(objMapping);

                Data_Import_Object_Mapping__mdt predecessor = fieldMapping.objMappingDevNameToObjMapping.get(objMapping.Predecessor__c);
                Data_Import_Field_Mapping__mdt[] fieldMappings = fieldMapping.objMappingDevNameToFieldMappings.get(objMapping.DeveloperName);

                //Only proceed if at least one field mapping exists
                if (fieldMappings != null && fieldMappings.size() > 0) {

                    BDI_ObjectWrapper[] objWrapsForProcessing = new BDI_ObjectWrapper[]{};
                    for (DataImport__c di : dataImportRecords) {

                        BDI_ObjectWrapper objWrap = new BDI_ObjectWrapper(di,objMapping,fieldMappings,predecessor);

                        //null out any existing value in the status field for this object mapping
                        di.put(UTIL_Namespace.adjustNPSPNamespace(objMapping.Imported_Record_Status_Field_Name__c),'');

                        //If the imported record field for the object is not populated then create a new Sobject, otherwise update existing.
                        if (di.get(UTIL_Namespace.adjustNPSPNamespace(objMapping.Imported_Record_Field_Name__c)) == null) {

                            //If there are no fields populated or required fields are not populated for this object mapping then ignore this DI and continue.
                            if (!validateFields(objWrap)) {
                                continue;
                            }

                            //If the predecessor doesn't exist, then update the Data import object with an error and continue with the next di.
                            if (!predecessorExists(objWrap,predecessor)) {
                                di.put(UTIL_Namespace.adjustNPSPNamespace(objMapping.Imported_Record_Status_Field_Name__c),System.label.bdiAdditionalObjPredNotFound);
                                continue;
                            }

                        } else { 

                            //If there is an existing record then we don't need to perform the normal validation and can proceed to populating
                            //the record with any non-null values.
                            objWrap.existingSobjectId = (Id)di.get(UTIL_Namespace.adjustNPSPNamespace(objMapping.Imported_Record_Field_Name__c));

                        }

                        objWrapsForProcessing.add(objWrap);
                    }

                    if (!dataImportService.isDryRun && objWrapsForProcessing.size() > 0) {
                        objWrapsForProcessing = objMappingLogic.populateObjects(objWrapsForProcessing);

                        for (BDI_ObjectWrapper objWrap : objWrapsForProcessing) {

                            // If the sObject in the objWrap is not null then add it to the map of object wraps by sobject type to upsert.
                            // They are grouped by object api name so that we only need to do one upsert per object per tier.
                            if (objWrap.sObj != null) {
                                if (objAPINameToObjWraps.get(objMapping.Object_API_Name__c) != null) {
                                    objAPINameToObjWraps.get(objMapping.Object_API_Name__c).add(objWrap);
                                } else {
                                    objAPINameToObjWraps.put(objMapping.Object_API_Name__c,new BDI_ObjectWrapper[]{objWrap});
                                }
                            }
                        }
                    }
                }
            }
        }

        return objAPINameToObjWraps;
    }

    /*******************************************************************************************************
    * @description Takes a map of Sobject api name to the object wrappers for that sobject and either updates or inserts the data.
    * @param objAPINameToObjWraps map of Sobject api name to object wrappers.
    */

    private void importObjectWrappers (Map<String,BDI_ObjectWrapper[]> objAPINameToObjWraps) {
        //If there are any records to create, then combine them into lists for update
        if (objAPINameToObjWraps.size() > 0) {
            for (String objApiName : objAPINameToObjWraps.keySet()) {

                BDI_ObjectWrapper[] objWraps = objAPINameToObjWraps.get(objApiName);
                
                Sobject[] sObjsForUpdate = new Sobject[]{};
                Sobject[] sObjsForInsert = new Sobject[]{};

                BDI_ObjectWrapper[] objWrapsForUpdate = new BDI_ObjectWrapper[]{};
                BDI_ObjectWrapper[] objWrapsForInsert = new BDI_ObjectWrapper[]{};

                for (BDI_ObjectWrapper objWrap : objWraps) {
                    if (objWrap.sObj.Id != null) {
                        sObjsForUpdate.add(objWrap.sObj);
                        objWrapsForUpdate.add(objWrap);
                    } else {
                        sObjsForInsert.add(objWrap.sObj);
                        objWrapsForInsert.add(objWrap);
                    }
                }

                if (sObjsForUpdate.size() > 0) {

                    Database.SaveResult[] updateSaveResults = UTIL_DMLService.updateRecords(sObjsForUpdate,false);
                    //Cycle through all the upsert results and update the data import records with status appropriately.
                    for (Integer t = 0; t < updateSaveResults.size(); t++) {
                        Database.SaveResult result = updateSaveResults[t];

                        BDI_ObjectWrapper objWrap = objWrapsForUpdate[t];

                        if (result.isSuccess()) {
                            objWrap.di.put(UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Imported_Record_Status_Field_Name__c),System.label.bdiUpdated);
                        } else { 
                            dataImportService.LogBDIError(objWrap.di, result.getErrors()[0].getMessage(),UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Imported_Record_Status_Field_Name__c));
                        }
                    }
                }

                if (sObjsForInsert.size() > 0) {

                    Database.SaveResult[] insertSaveResults = UTIL_DMLService.insertRecords(sObjsForInsert,false);
                    //Cycle through all the upsert results and update the data import records with status appropriately.
                    for (Integer t = 0; t < insertSaveResults.size(); t++) {
                        Database.SaveResult result = insertSaveResults[t];

                        BDI_ObjectWrapper objWrap = objWrapsForInsert[t];

                        if (result.isSuccess()) {
                            objWrap.di.put(UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Imported_Record_Status_Field_Name__c),System.Label.bdiCreated);
                            objWrap.di.put(UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Imported_Record_Field_Name__c),objWrap.sObj.Id);
                        } else { 
                            dataImportService.LogBDIError(objWrap.di, result.getErrors()[0].getMessage(),UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Imported_Record_Status_Field_Name__c));
                        }
                    }
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Determines if there is a custom mapping logic class and constructs it if there is, otherwise returns the default
    * mapping class.
    * @param objMapping The Data Import Object Mapping to look for a custom mapping logic class on.
    */
    private BDI_ObjectMappingLogic getObjectMappingLogicClass (Data_Import_Object_Mapping__mdt objMapping) {
        BDI_ObjectMappingLogic objMappingLogicClass;

        if (objMapping.Custom_Mapping_Logic_Class__c != null) {
            Type custLogicClassType = Type.forName(UTIL_Namespace.adjustNPSPNamespace(objMapping.Custom_Mapping_Logic_Class__c));
            objMappingLogicClass = (BDI_ObjectMappingLogic)custLogicClassType.newInstance();
        } else {
            objMappingLogicClass = new BDI_ObjectMappingLogic();
        }
        return objMappingLogicClass;
    }


    /*******************************************************************************************************
    * @description Determines if the predecessor to this Data Import Object Mapping exists
    * @param predecessor The Data Import Object Mapping for which the imported field can be checked to see if it exists.
    */
    private Boolean predecessorExists(BDI_ObjectWrapper objWrap, Data_Import_Object_Mapping__mdt predecessor){
        return objWrap.di.get(UTIL_Namespace.adjustNPSPNamespace(predecessor.Imported_Record_Field_Name__c)) != null;
    }


    /*******************************************************************************************************
    * @description Validates the field mappings to make sure that the required ones are not null and that at least one non imported record
    * field is populated.
    * @param objWrap The BDI_ObjectWrapper that should have its field mappings validated.
    */
    private Boolean validateFields(BDI_ObjectWrapper objWrap){

        Boolean result = false;
        Boolean anyNonImportedRecordFieldsPopulated = false;
        Boolean allRequiredFieldsPopulated = true;

        String requiredFieldErrorMsg = System.label.bdiAdditionalObjRequiredFieldsNull;

        // First determine if there is at least one field populated that was not automatically populated by the import of another object.
        // This is done to ensure that the user actually intended to attempt the creation of this object.
        for (Data_Import_Field_Mapping__mdt fieldMapping : objWrap.fieldMappings) {

            if (!importedRecordFieldNames.contains(fieldMapping.Source_Field_API_Name__c.toLowerCase())
                && objWrap.di.get(UTIL_Namespace.adjustNPSPNamespace(fieldMapping.Source_Field_API_Name__c)) != null) {        
                anyNonImportedRecordFieldsPopulated = true;
            }
        }

        // If at least one field aside from imported record fields was populated then we should assume the user is trying to create the object and 
        // continue with record validation.
        if (anyNonImportedRecordFieldsPopulated) {

            for (Data_Import_Field_Mapping__mdt fieldMapping : objWrap.fieldMappings) {

                if (objWrap.di.get(UTIL_Namespace.adjustNPSPNamespace(fieldMapping.Source_Field_API_Name__c)) == null) {

                    if (fieldMapping.Required__c == 'Yes') {

                        allRequiredFieldsPopulated = false;
                        requiredFieldErrorMsg += UTIL_Namespace.adjustNPSPNamespace(fieldMapping.Source_Field_API_Name__c) + '; ';
                    }
                }
            }

            //if at least one of the fields is populated and all required fields are populated then set result to true
            if (anyNonImportedRecordFieldsPopulated && allRequiredFieldsPopulated) {

                result = true;

            } else if (anyNonImportedRecordFieldsPopulated && !allRequiredFieldsPopulated) {
                requiredFieldErrorMsg = requiredFieldErrorMsg.removeEnd('; ').abbreviate(255);
                dataImportService.LogBDIError(objWrap.di, requiredFieldErrorMsg ,UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Imported_Record_Status_Field_Name__c));
            }
        }

        return result;
    }


    /*******************************************************************************************************
    * @description Generates a map of tier number to list of Data Import Object Mappings so that they mappings can be processed and imported in the correct
    * order.
    */
    public void generateTiersOfObjectMappings() {

        if (fieldMapping.objMappingDevNameToObjMapping != null && fieldMapping.objMappingDevNameToObjMapping.size() > 0) {

            //Creates a map of predecessor dev name to successor and also identifies the base level objects with no predecessor defined.
            for (Data_Import_Object_Mapping__mdt objMapping : fieldMapping.objMappingDevNameToObjMapping.values()) {

                if (objMapping.Predecessor__c != null && objMapping.Relationship_Field__c != null && objMapping.Relationship_To_Predecessor__c != null) {

                    objMappingDevNames.add(objMapping.DeveloperName);

                    if (predecessorDevNameToSuccessors.get(objMapping.Predecessor__c) != null) {
                        predecessorDevNameToSuccessors.get(objMapping.Predecessor__c).put(objMapping.DeveloperName,objMapping);
                    } else {
                        predecessorDevNameToSuccessors.put(objMapping.Predecessor__c,new Map<String,Data_Import_Object_Mapping__mdt>{objMapping.DeveloperName => objMapping});
                    }
                } else {

                    if (tierToObjMappings.get(0) != null) {
                        tierToObjMappings.get(0).put(objMapping.DeveloperName,objMapping);
                    } else {
                        tierToObjMappings.put(0,new Map<String,Data_Import_Object_Mapping__mdt>{objMapping.DeveloperName => objMapping});
                    }
                }
            }

            //Iterates through the tier list and builds out each tier starting with the objects with no predecessor.
            for (Integer i = 0; i < tierToObjMappings.size(); i++) {

                Map<String,Data_Import_Object_Mapping__mdt> currentTier = new Map<String,Data_Import_Object_Mapping__mdt>();
                Map<String,Data_Import_Object_Mapping__mdt> nextTier = new Map<String,Data_Import_Object_Mapping__mdt>();

                if (tierToObjMappings.get(i) != null) {
                    currentTier = tierToObjMappings.get(i);

                    for (String objMappingDevName:currentTier.keyset()) {

                        if (predecessorDevNameToSuccessors.get(objMappingDevName) != null) {
                            nextTier.putAll(predecessorDevNameToSuccessors.get(objMappingDevName));
                        }
                    }

                    if (nextTier != null && nextTier.size() > 0) {
                        tierToObjMappings.put(i + 1,nextTier);
                    }
                }
            }
        }
    }


    /*******************************************************************************************************
    * @description creates a set of the imported record field names for all the object mappings it is passed for use in field validation.
    * @param objMappings the Data Import Object Mappings that the set should be built from.
    */
    private Set<String> createSetOfImportedRecordFieldNames(Data_Import_Object_Mapping__mdt[] objMappings){
        importedRecordFieldNames = new Set<String>();

        for (Data_Import_Object_Mapping__mdt objMapping : objMappings) {

            if (objMapping.Imported_Record_Field_Name__c != null) {
                importedRecordFieldNames.add(objMapping.Imported_Record_Field_Name__c.toLowerCase());
            }
            
        }
        return importedRecordFieldNames;
    }

}