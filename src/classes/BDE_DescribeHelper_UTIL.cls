/*
Copyright (c) 2011, salesforce.com foundation, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com foundation. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
/**
* @author Team Kick Ass; Veronica Waters, Evan Callahan, Derek Dsouza, Mike Fullmore
* @date 04/27/2011
* @description helper class for apex describe calls used in batch entry
*/
public class  BDE_DescribeHelper_UTIL {  
    // throw custom exceptions when a bogus object or field is provided. 
    public class SchemaDescribeException extends Exception {}
    
    //maps to hold the describe info
    private static Map<String, Schema.SObjectType> gd;
    private static Map<String, Schema.DescribeSObjectResult> objectDescribes = new Map<String, Schema.DescribeSObjectResult>();
    private static Map<String, Map<String, Schema.SObjectField>> fieldTokens = new Map<String,Map<String, Schema.SObjectField>>();
    private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldDescribes = new Map<String,Map<String, Schema.DescribeFieldResult>>();
        
    /*******************************************
    * Gets describe maps for a new object
    ********************************************/
    static void fillMapsForObject(string objectName) {
        // get the object map the first time
        if (gd==null) gd = Schema.getGlobalDescribe();
        
        // get the object description
        if (gd.containsKey(objectName)) {
            
            if (!objectDescribes.containsKey(objectName))
                objectDescribes.put(objectName, gd.get(objectName).getDescribe());
        } else {
            throw new SchemaDescribeException('Invalid object name \'' + objectName + '\'');
        }
    }

    /*******************************************
    * Gets field maps for a new object
    ********************************************/
    static void fillFieldMapsForObject(string objectName, string fieldName) {
        // get the object map the first time
        fillMapsForObject(objectName);
        
        // get the field description
        if (!fieldTokens.containsKey(objectName)) {
            fieldTokens.put(objectName, objectDescribes.get(objectName).fields.getMap());
            fieldDescribes.put(objectName, new Map<String, Schema.DescribeFieldResult>());
        }
        if (!fieldDescribes.get(objectName).containsKey(fieldName)) {
            if (fieldTokens.get(objectName).containsKey(fieldName)) {
                Schema.DescribeFieldResult dfr = fieldTokens.get(objectName).get(fieldName).getDescribe(); 
                fieldDescribes.get(objectName).put(fieldName, dfr);
            } else {
                throw new SchemaDescribeException('Invalid field name \'' + fieldName + '\'');          
            }
        }
    }
    
    static void fillFieldMapsForObject(string objectName) {
        // get the object map the first time
        fillMapsForObject(objectName);
        
        // get the field description
        if (!fieldTokens.containsKey(objectName)) {
            fieldTokens.put(objectName, objectDescribes.get(objectName).fields.getMap());
            fieldDescribes.put(objectName, new Map<String, Schema.DescribeFieldResult>());
        }
        
        //Map<String, Schema.SObjectField> fieldsMap = objectDescribes.get(objectName).fields.getMap();
        if (fieldTokens.get(objectName).size() != fieldDescribes.get(objectName).size()) {
            for ( string fieldName : fieldTokens.get(objectName).keyset()) {
                if (!fieldDescribes.get(objectName).containsKey(fieldName)) {
                    Schema.DescribeFieldResult dfr = fieldTokens.get(objectName).get(fieldName).getDescribe(); 
                    fieldDescribes.get(objectName).put(fieldName, dfr);
                }
            }
        }
    }

    /*******************************************
    * Returns new object of given type
    ********************************************/
    public static SObject getPrototypeObject(String objectName) {
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        return gd.get(objectName).newSObject();
    }   

    /*******************************************
    * Returns object friendly name
    ********************************************/
    public static string getObjectLabel(String objectName) {
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        return objectDescribes.get(objectName).getLabel();
    }   

    /*******************************************
    * Returns object describe data
    ********************************************/
    public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        return objectDescribes.get(objectName);
    }   

    /*******************************************
    * Compares Id to verify object type
    ********************************************/
    public static boolean isObjectIdThisType(Id salesforceId, String objectName) {
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        // now grab the requested id prefix
        boolean ret = false;
        if (salesforceId != null) {
            string prefix = objectDescribes.get(objectName).getKeyPrefix();
            if (prefix != null) 
                ret = ((string)(salesforceId)).startsWith(prefix);
        }
        return ret;
    }   
    
    /*******************************************
    * Returns all fields describe data
    ********************************************/
    public static Map<String, Schema.DescribeFieldResult> getAllFieldsDescribe(String objectName) {

        // make sure we have this field's schema mapped
        fillFieldMapsForObject(objectName);
        
        Map<String, Schema.DescribeFieldResult> fieldMap = fieldDescribes.get(objectName);
        return fieldMap;
    }
        
    /*******************************************
    * Gives field type name - ID, STRING, TEXTAREA, DATE, DATETIME, BOOLEAN, REFERENCE, 
        PICKLIST, MULTIPICKLIST, CURRENCY, DOUBLE, INTEGER, PERCENT, PHONE, EMAIL
    ********************************************/
    public static string getFieldType(String objectName, String fieldName) {
        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
            fillFieldMapsForObject(objectName, fieldName);
        
        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr.getType().name();
    }   
        
    /*******************************************
    * Returns field describe data
    ********************************************/
    public static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        // make sure we have this field's schema mapped
        fieldName = fieldName.toLowerCase();
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
            fillFieldMapsForObject(objectName, fieldName);
        
        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr;
    }

    /*******************************************
    * Gives field friendly name
    ********************************************/
    public static string getFieldLabel(String objectName, String fieldName) {
        // make sure we have this field's schema mapped
        fieldName = fieldName.toLowerCase();
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
            fillFieldMapsForObject(objectName, fieldName);
        
        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr.getLabel();
    }  
    
    // exception class used by listStrFromFieldSet
    private class MyException extends Exception {}

    // utility to return a list of strings from a field set.
    public static list<string> listStrFromFieldSet(string strObject, string strFS) {
        list<string> listStrFields = new list<string>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(strObject);
        Schema.DescribeSObjectResult d = targetType.getDescribe(); 
        Schema.FieldSet fs = d.fieldSets.getMap().get(strFS); 
        if (fs == null) {
        	throw (new MyException('Field set \'' + strFS + '\' does not exist.'));
        }      

        for(Schema.FieldSetMember f : fs.getFields()) {
            if (f.getFieldPath().contains('.')) {
                throw (new MyException('Related field \'' + f.getFieldPath() + '\' not supported ' +
                    'in field set \'' + strFS + '\'.  You can only include fields directly on object \'' + strObject + '\'.'));
            }
            listStrFields.add(f.getFieldPath());
        }
        return listStrFields;
    }
    
    // utility to return a comma separated string of field names from a field set
    public static string strFieldNamesFromFieldSet(string strObject, string strFS) {
        string strFields = '';
        for (string str : listStrFromFieldSet(strObject, strFS)) {
            strFields += str + ',';
        }       
        return strFields.substring(0, strFields.length()-1);        
    }
               
}