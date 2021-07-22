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
* @description Virtual class containing the standard logic for mapping fields between source and target objects.  Can be overriden by clients
* who need custom mapping logic.
*/

public with sharing virtual class BDI_ObjectMappingLogic {

    public virtual BDI_ObjectWrapper[] populateObjects(BDI_ObjectWrapper[] objWraps) {
        if (objWraps == null) {
            return objWraps;
        }
        
        String sourceObjName = SObjectType.DataImport__c.getName();
        
        for (BDI_ObjectWrapper objWrap : objWraps) {

            objWrap.sObj = UTIL_Describe.getPrototypeObject(objWrap.objMapping.Object_API_Name);

            // If the object already has an existing SObject Id, then set it in the sObj
            if (objWrap.existingSObjectId != null) {
                objWrap.sObj.put('Id', objWrap.existingSObjectId);
            }

            updateChildToPredecessorRelationship(objWrap);
            
            for (BDI_FieldMapping fieldMapping : objWrap.fieldMappings) {
                String sourceFieldName = fieldMapping.Source_Field_API_Name;
                String targetFieldName = fieldMapping.Target_Field_API_Name;
                
                Schema.DescribeFieldResult sourceFieldDescribe = UTIL_Describe.getFieldDescribe(sourceObjName, sourceFieldName);
                Schema.DescribeFieldResult targetFieldDescribe = UTIL_Describe.getFieldDescribe(objWrap.objMapping.Object_API_Name, targetFieldName);

                //Confirm that it is real field, and that it is accessible to the running user.
                if (targetFieldDescribe != null && targetFieldDescribe.isAccessible()) {

                    //Confirm that either the sObj Id is null (ie new record) or that the field is updatable if it is not new.
                    if (objWrap.sObj.Id == null || targetFieldDescribe.isUpdateable()) {

                        castAndCopyField(objWrap, sourceFieldName, sourceFieldDescribe, targetFieldName, targetFieldDescribe);
                    }
                }

            } 
        }
        return objWraps;
    }

    // When the relationship to the predecessor is "Child" then this will put the Id 
    // of the predecessor into the defined relationship field on a new SObject.
    public static void updateChildToPredecessorRelationship(BDI_ObjectWrapper objWrap) {
        // If the object we are working on is a child to its predecessor then set the relationship field 
        if (objWrap.sObj.Id == null && objWrap.objMapping.Relationship_To_Predecessor == 'Child') {

            objWrap.sObj.put(objWrap.objMapping.Relationship_Field,objWrap.dataImport.get(objWrap.predecessorObjMapping.Imported_Record_Field_Name));
        }
    }


    // Copies the value from the source field to the target field and handles casting type
    // when needed.
    public static void castAndCopyField(BDI_ObjectWrapper objWrap, 
                                        String sourceFieldName,
                                        Schema.DescribeFieldResult sourceFieldDescribe,
                                        String targetFieldName, 
                                        Schema.DescribeFieldResult targetFieldDescribe) {

        Object value = objWrap.getSourceFieldValue(sourceFieldName);

        //only copy values that are not null to avoid overwriting data when updating existing SObjects.
        if (value != null) {

            // If the destination field is a Boolean and the DI field intermediate requires interpretation to Boolean
            // This allows for mapping checkboxes to a tri-state picklist - null, True, False - or a text with either 
            // null, "True", or "False"
            if (targetFieldDescribe.getType() == Schema.DisplayType.BOOLEAN && !(value instanceof Boolean)) {
                value = Boolean.valueOf(value);
            }

            // If the destination field is an integer, and the source field is a double with a scale of 0 then
            // convert the value to be an integer.  This solves for the fact that some standard salesforce fields
            // are listed as numbers with scale of zero, but internally are of type Integer.
            if (targetFieldDescribe.getType() == Schema.DisplayType.INTEGER 
                    && !(value instanceof Integer) 
                    && sourceFieldDescribe.getType() == Schema.DisplayType.DOUBLE
                    && sourceFieldDescribe.getScale() == 0) {
                value = Integer.valueOf(value);
            }

            objWrap.sObj.put(targetFieldName,value);
        }
    }
}
