/*
Copyright (c) 2014 salesforce.com foundation, Inc.
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
* @author Salesforce Foundation
* @date 01/13/2014
* @description This class allows easy access to object and field description information from within other classes.
*
* It is called statically, and therefore will supply the same information to all calls made from
* within one transaction, or set of trigger calls. This is beneficial because this info should
* be the same for all calls in a transaction, and by calling it statically we reduce the calls
* that are made, making the total transaction more efficient.
*/
	
public with sharing class UTIL_Describe {
    
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
    * Gets a field map for a new object/field pair
    ********************************************/
    private static void fillFieldMapsForObject(string objectName, string fieldName) {
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
    
    /*******************************************
    * Gets all field maps for a new object
    ********************************************/
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

    /*******************************************************************************************************
    * @description Returns new object of given type.
    * @param objectName the name of the object to create
    * @return the new SObject
    */  
    public static SObject getPrototypeObject(String objectName) {
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        return gd.get(objectName).newSObject();
    }   

    /*******************************************************************************************************
    * @description Returns object friendly name.
    * @param objectName the name of the object to lookup 
    * @return the Label of the object
    */  
    public static string getObjectLabel(String objectName) {
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        return objectDescribes.get(objectName).getLabel();
    }   

    /*******************************************************************************************************
    * @description Returns object describe data.
    * @param objectName the name of the object to lookup 
    * @return Schema.DescribeSObjectResult of the object
    */  
    public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        return objectDescribes.get(objectName);
    }   

    /*******************************************************************************************************
    * @description Compares Id to verify object type
    * @param salesforceId of the object
    * @param objectName 
    * @return true if the Id is for the given object type, false otherwise.
    */  
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
    
    /*******************************************************************************************************
    * @description Returns all field describe data
    * @param objectName the name of the object to look up
    * @return Map<String, Schema.DescribeFieldResult> a map of object names to describe file results.
    */  
    public static Map<String, Schema.DescribeFieldResult> getAllFieldsDescribe(String objectName) {

        // make sure we have this field's schema mapped
        fillFieldMapsForObject(objectName);
        
        Map<String, Schema.DescribeFieldResult> fieldMap = fieldDescribes.get(objectName);
        return fieldMap;
    }

    /*******************************************************************************************************
    * @description Gives field type name - ID, STRING, TEXTAREA, DATE, DATETIME, BOOLEAN, REFERENCE, 
    * PICKLIST, MULTIPICKLIST, CURRENCY, DOUBLE, INTEGER, PERCENT, PHONE, EMAIL
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return string the name of the of the field's type
    */  
    public static string getFieldType(String objectName, String fieldName) {
        // fields in our own package must not have their prefix for the Describe Field Map
        fieldName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldName);
        
        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
            fillFieldMapsForObject(objectName, fieldName);
        
        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr.getType().name();
    }   

    /*******************************************************************************************************
    * @description Gives field type name - ID, STRING, TEXTAREA, DATE, DATETIME, BOOLEAN, REFERENCE, 
    * PICKLIST, MULTIPICKLIST, CURRENCY, DOUBLE, INTEGER, PERCENT, PHONE, EMAIL
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return Displaytype the Displaytype of the field
    */  
    public static Schema.Displaytype getFieldDisplaytype(String objectName, String fieldName) {
        // fields in our own package must not have their prefix for the Describe Field Map
        fieldName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldName);

        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
            fillFieldMapsForObject(objectName, fieldName);
        
        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr.getType();
    }   

    /*******************************************************************************************************
    * @description Returns field describe data 
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return Schema.DescribeFieldResult the describe field result for the given field
    */ 
    public static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        // fields in our own package must not have their prefix for the Describe Field Map
        fieldName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldName);
        
        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
            fillFieldMapsForObject(objectName, fieldName);
        
        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr;
    }

    /*******************************************************************************************************
    * @description Gives field friendly name 
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return string the label of the field
    */ 
    public static string getFieldLabel(String objectName, String fieldName) {
        // fields in our own package must not have their prefix for the Describe Field Map
        fieldName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldName);
        
        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
            fillFieldMapsForObject(objectName, fieldName);
        
        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr.getLabel();
    }       

    /*******************************************************************************************************
    * @description Gives field friendly name without throwing exception if not valid. 
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return string the label of the field
    */ 
    public static string getFieldLabelSafe(string strObj, string strField) {
        try {
            return getFieldLabel(strObj, strField);                   
        } catch (Exception e) {
            return strField;
        }       
    }
        
    /*******************************************************************************************************
    * @description checks whether the field exists
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return boolean whether the field exists
    */ 
    public static boolean isValidField(String objectName, String fieldName) {
        // fields in our own package must not have their prefix for the Describe Field Map
        fieldName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldName);
        
        // make sure we have this field's schema mapped        
        try {
	        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
	            fillFieldMapsForObject(objectName, fieldName);
	        
	        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
	        return dfr != null;
        } catch (exception ex) {
        	return false;
        }
    }  
    
    /*******************************************************************************************************
    * @description utility to check for compatible datatypes for data copying
    * @return true if the types can be copied between
    */ 
    public static boolean canDisplaytypesCopy(Schema.Displaytype dtSrc, Schema.Displaytype dtTgt) {
        
        if (dtSrc == dtTgt)
           return true;
        
        // date can go to datetime
        if (dtSrc == Schema.Displaytype.Date && dtTgt == Schema.Displaytype.DateTime)
           return true;
           
        // numbers can implictly cast to other numbers
        if ((dtSrc == Schema.Displaytype.Currency ||
            dtSrc == Schema.Displaytype.Double ||
            dtSrc == Schema.Displaytype.Integer ||
            dtSrc == Schema.Displaytype.Percent) &&
           (dtTgt == Schema.Displaytype.Currency ||
            dtTgt == Schema.Displaytype.Double ||
            dtTgt == Schema.Displaytype.Integer ||
            dtTgt == Schema.Displaytype.Percent)) {
            return true;
        }
        
        // text can go to longer text
        if (dtSrc == Schema.Displaytype.String && dtTgt == Schema.Displaytype.TextArea)
            return true;
        
        return false;
    }
    
    
    /*******************************************************************************************************
    * @description Dependent Picklist Describe Support 
    *
    * Unfortunately, Salesforce doesn't provide a direct way to get the dependency information
    * between dependent picklists.  but I was able to find some code from
    * http://titancronus.com/blog/2014/05/01/salesforce-acquiring-dependent-picklists-in-apex/
    * that solves the problem.  the code i grabbed follows this function.  i changed the
    * code from returning a map of <controlling label> to a list of <dependent label> to be
    * a map of <controlling value>|<dependent value> to a single <dependent label>
    */

    /*******************************************************************************************************
    * @description: Entity to represent a json version of a picklist entry
    * so that the validFor property becomes exposed
    */
    public class TPicklistEntry{
        public string active {get;set;}
        public string defaultValue {get;set;}
        public string label {get;set;}
        public string value {get;set;}
        public string validFor {get;set;}
        public TPicklistEntry(){
            
        }
    }    

    /*******************************************************************************************************
    * @description: helper class to handle bit operations
    */
    public class Bitset{
        public Map<String,Integer> AlphaNumCharCodes {get;set;}
        public Map<String, Integer> Base64CharCodes { get; set; }
        public Bitset(){
            LoadCharCodes();
        }
        //Method loads the char codes
        private void LoadCharCodes(){
            AlphaNumCharCodes = new Map<String,Integer>{
                'A'=>65,'B'=>66,'C'=>67,'D'=>68,'E'=>69,'F'=>70,'G'=>71,'H'=>72,'I'=>73,'J'=>74,
                'K'=>75,'L'=>76,'M'=>77,'N'=>78,'O'=>79,'P'=>80,'Q'=>81,'R'=>82,'S'=>83,'T'=>84,
                'U'=>85,'V'=> 86,'W'=>87,'X'=>88,'Y'=>89,'Z'=>90    
            };
            Base64CharCodes = new Map<String, Integer>();
            //lower case
            Set<String> pUpperCase = AlphaNumCharCodes.keySet();
            for(String pKey : pUpperCase){
                //the difference between upper case and lower case is 32
                AlphaNumCharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey)+32);
                //Base 64 alpha starts from 0 (The ascii charcodes started from 65)
                Base64CharCodes.put(pKey,AlphaNumCharCodes.get(pKey) - 65);
                Base64CharCodes.put(pKey.toLowerCase(),AlphaNumCharCodes.get(pKey) - (65) + 26);
            }
            //numerics
            for (Integer i=0; i<=9; i++){
                AlphaNumCharCodes.put(string.valueOf(i),i+48);
                //base 64 numeric starts from 52
                Base64CharCodes.put(string.valueOf(i), i + 52);
            }
        }

	    /*
	        Effect: Method takes a validFor string and tests it against a set of controlling indexes
	        Postcondition: Returns a list of all controlling indexes for which the validFor string test True
	    */
	    public List<Integer> testBits(String pValidFor,List<Integer> nList){
	        List<Integer> results = new List<Integer>();
	        //the list of bytes (not derived from n)
	        List<Integer> pBytes = new List<Integer>();
	        //multiply by 6 since base 64 uses 6 bits (not derived form n)
	        Integer bytesBeingUsed = (pValidFor.length() * 6)/8;
	        //will be used to hold the full decimal value (not derived from n)
	        Integer pFullValue = 0;
	        //must be more than 1 byte
	        if (bytesBeingUsed <= 1)
	            return results;
	        //get the base64bytes
	        for(Integer i=0;i<pValidFor.length();i++){
	            //get currenct character value
	            pBytes.Add((Base64CharCodes.get((pValidFor.Substring(i, i+1)))));
	        }   
	        //calculate the full decimal value
	        for (Integer i = 0; i < pBytes.size(); i++)
	        {
	            Integer pShiftAmount = (pBytes.size()-(i+1))*6;//used to shift by a factor 6 bits to get the value
	            pFullValue = pFullValue + (pBytes[i] << (pShiftAmount));
	        }
	        //now we don't want to always be declaring memory, so let's set the initial 
	        //variables
	        Integer bit;
	        Integer targetOctet;
	        Integer shiftBits;
	        Integer tBitVal;
	        Integer n;
	        Integer nListSize = nList.size();
	        for(Integer i=0; i<nListSize; i++){
	            n = nList[i];
	            //calculate the target bit for comparison
	            bit = 7 - (Math.mod(n,8)); 
	            //calculate the octet that has in the target bit
	            targetOctet = (bytesBeingUsed - 1) - (n >> bytesBeingUsed); 
	            //the number of bits to shift by until we find the bit to compare for true or false
	            shiftBits = (targetOctet * 8) + bit;
	            //& is to set the same set of bits for testing
	            //shift to the bit which will dictate true or false
	            //Math.Pow(2, shiftBits) == 2 << (shiftBits+1)
	            tBitVal = ((Integer)(2 << (shiftBits-1)) & pFullValue) >> shiftBits;
	            if (tBitVal==1)
	                results.add(n);
	        }
	        return results;
	    }
    }
    

    /*******************************************************************************************************
    * @description: For the given Object with a controlling picklist and dependent picklist, get information.
    * @return map<string, string> a map of <controlling value | dependent value> to <dependent label>
    */
    public static Map<String,string> GetDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName){
        Map<String,string> objResults = new Map<String,string>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        if (!Schema.getGlobalDescribe().containsKey(pObjName))
            return objResults;
        //get the type being dealt with
        Schema.SObjectType pType = Schema.getGlobalDescribe().get(pObjName);
        return GetDependentOptionsImpl(pType,pControllingFieldName,pDependentFieldName);        
    }
    
    /*******************************************************************************************************
    * @description: For the given Object Type with a controlling picklist and dependent picklist, get information.
    * @return map<string, string> a map of <controlling value | dependent value> to <dependent label>
    */
    public static Map<String,string> GetDependentOptionsImpl(Schema.SObjectType pType, String pControllingFieldName, String pDependentFieldName){
        Map<String,string> objResults = new Map<String,string>();
        if (pType==null)
            return objResults;
        Bitset BitSetInstance = new Bitset();
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        //verify field names
        if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName))
            return objResults;     
        //get the control values   
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
        objFieldMap = null;
        List<Integer> lstControllingIndexes = new List<Integer>();
        //iterate through the values and get the ones valid for the controlling field name
        //set up the results
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){           
            //get the pointer to the entry
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            //String pControllingLabel = ctrl_entry.getLabel();
            //create the entry with the label
            //objResults.put(pControllingLabel,new List<String>());
            //keep track of the controlling indexes
            lstControllingIndexes.add(pControllingIndex);
        }
        //cater for null and empty
        //objResults.put('',new List<String>());
        //objResults.put(null,new List<String>());
        
        //load all dep entries
        List<Schema.PicklistEntry> objEntries = new List<Schema.PicklistEntry>();
        List<TPicklistEntry> objDS_Entries = new List<TPicklistEntry>();
        //add all entries
        for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++){          
            //get the pointer to the dependent index
            Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
            objEntries.add(dep_entry);            
        } 
        //serialize once  
        UTIL_Debug.debugWithInfo('****DJH calling JSON.deserialize');
        objDS_Entries = (List<TPicklistEntry>)JSON.deserialize(JSON.serialize(objEntries), List<TPicklistEntry>.class);
        UTIL_Debug.debugWithInfo('****DJH returned JSON.deserialize');
        List<Integer> validIndexes;
        for (TPicklistEntry objDepPLE : objDS_Entries){
            //if valid for is empty, skip    
            if (objDepPLE.validFor==null || objDepPLE.validFor==''){
                continue;
            }
            //get the test for the controlling indexes
        UTIL_Debug.debugWithInfo('****DJH calling testBits');
            validIndexes = BitSetInstance.testBits(objDepPLE.validFor,lstControllingIndexes);
        UTIL_Debug.debugWithInfo('****DJH returned testBits');
            for (Integer validIndex : validIndexes){                
                //get the label
                String pControllingValue = ctrl_ple[validIndex].getValue();
                String pDepValue = objDepPLE.value;
                //objResults.get(pControllingLabel).add(objDepPLE.label);
                objResults.put(pControllingValue + '|' + pDepValue, objDepPLE.label);
            }
        }
        objEntries = null;
        objDS_Entries = null;
        return objResults;
    }
        
}