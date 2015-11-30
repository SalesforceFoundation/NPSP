/**
* @author Evan Callahan
* @date 2010 
* @group Utilities
* @description Provides recordtype wrapper for easy access in other codeblocks 
*/

public class UTIL_RecordTypes {
/*-----------------------------------------------------------------------------------------------
* Written by Evan Callahan, copyright (c) 2010 Groundwire
* This program is released under the GNU General Public License. http://www.gnu.org/licenses/
* 
* This class is meant to allow for access to Record Type information from within other classes.
*
* It is called statically, and therefore will supply the same information to all calls made from
* within one transaction, or Set of trigger calls. This is beneficial because this info should
* be the same for all calls in a transaction, and by calling it statically we reduce the calls
* that are made, making the total transaction more efficient
-----------------------------------------------------------------------------------------------*/
    
    //Maps to hold the record type info
    private static Map<String, Schema.SObjectType> gd;
    private static Map<String, Map<Id, Schema.RecordTypeInfo>> recordTypesById = new Map<String, Map<Id, Schema.RecordTypeInfo>>();
    private static Map<String, Map<String, Schema.RecordTypeInfo>> recordTypesByName = new Map<String, Map<String, Schema.RecordTypeInfo>>();
    private static List<Schema.Recordtypeinfo> recordTypesList = New List<Schema.Recordtypeinfo>();
    
    public static String giftrecordTypeNameForTests;
    public static String membershiprecordTypeNameForTests;
    
    /*******************************************************************************************************
    * @description Populates the static properties of the class, that store information about and Object and 
    *              its Record Types.
    * @param objectName The name of the Object.
    * @return void
    */
    private static void fillMapsForObject(String objectName) {
        // get the object map the first time
        if (gd==null) gd = Schema.getGlobalDescribe();
        
        // get the object description
        if (gd.containsKey(objectName)) {
            Schema.DescribeSObjectResult d = gd.get(objectName).getDescribe();
            recordTypesByName.put(objectName, d.getRecordTypeInfosByName());
            recordTypesById.put(objectName, d.getRecordTypeInfosById());
            recordTypesList = d.getRecordTypeInfos();
            for(integer i=recordTypesList.size()-1;i>=0;i--){
                if(recordTypesList[i].getName()=='Master' || !recordTypesList[i].isAvailable()){
                    recordTypesList.remove(i);
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Provides the Id of the Record Type with an specific name in an specific Object.
    * @param objectName The name of the Object.
    * @param  recordTypeName The name of the Record Type.
    * @return Id The Id of the Record Type.
    */
    public static Id GetRecordTypeId(String objectName, String recordTypeName) {
        // make sure we have this object's record types Mapped
        if (!recordTypesByName.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        // now grab and return the requested id 
        Map<String, Schema.RecordTypeInfo> rtMap = recordTypesByName.get(objectName);
        if (rtMap != null && rtMap.containsKey(recordTypeName)) {
            return rtMap.get(recordTypeName).getRecordTypeId();
        } else {
            return null;
        }
    }

    /*******************************************************************************************************
    * @description Determines whether a record type is active for the current profile.
    * @param objectName The name of the Object.
    * @param  recordTypeName The name of the Record Type.
    * @return Boolean Whether this record type is active for the current profile.
    */
    public static boolean isRecordTypeActive(string objectName, String recordTypeName) {
        if (!recordTypesByName.containsKey(objectName)) 
            fillMapsForObject(objectName);

        Map<String, Schema.RecordTypeInfo> rtMap = recordTypesByName.get(objectName);
        if (rtMap != null && rtMap.containsKey(recordTypeName)) {
            return rtMap.get(recordTypeName).isAvailable();
        } else {
            return false;
        }
        
    }

    /*******************************************************************************************************
    * @description Provides the Id of the first Record Type found in an specific Object, or a blank string if the
    *              Object does not have any Record Types.
    * @param objectName The name of the Object.
    * @return String The name of a Record Type that belongs to the specified Object, if at least one exists. Blank 
    *                string otherwise.
    */
    public static String getrecordTypeNameForGiftsTests(String objectName) {  

        if (giftrecordTypeNameForTests == null){
             // make sure we have this object's record types Mapped
            if (!recordTypesByName.containsKey(objectName)) 
                fillMapsForObject(objectName);
                
            if(recordTypesList.size()==0){
                giftrecordTypeNameForTests = '';
            } else{
                giftrecordTypeNameForTests = recordTypesList[0].getName();          
            }
        }      
       
        return giftrecordTypeNameForTests;
    }
    
    /*******************************************************************************************************
    * @description Provides the Id of the first Record Type found in an specific Object, if it has only one, or 
    *              the second one if it has more than one.
    * @param objectName The name of the Object.
    * @return String The name of the first Record Type found in the specified Object, if it has only one, or 
    *              the second one if it has more than one. Blank string if none exists.
    */
    public static String getrecordTypeNameForMembershipTests(String objectName){      
        if (membershiprecordTypeNameForTests == null){        
            // make sure we have this object's record types Mapped
            if (!recordTypesByName.containsKey(objectName)) 
                fillMapsForObject(objectName);
                
            if(recordTypesList.size()==0){
                membershiprecordTypeNameForTests = '';
            } else if(recordTypesList.size()==1){
                membershiprecordTypeNameForTests = recordTypesList[0].getName();
            } else {
                membershiprecordTypeNameForTests = recordTypesList[1].getName();            
            }
        }
        return membershiprecordTypeNameForTests;
    }
        
    /*******************************************************************************************************
    * @description Provides the name of the Record Type with an specific Id in an specific Object.
    * @param objectName The name of the Object.
    * @param  recordTypId The Id of the Record Type.
    * @return String The name of the Record Type.
    */
    public static String GetrecordTypeName(String objectName, String RecordTypeId) {
    	try {
	        // make sure we have this object's record types Mapped
	        if (!recordTypesById.containsKey(objectName)) 
	            fillMapsForObject(objectName);
	        
	        // now grab and return the requested id
	        Map<Id, Schema.RecordTypeInfo> rtMap = recordTypesById.get(objectName);
	        if (rtMap != null && rtMap.containsKey(RecordTypeId)) {
	            return rtMap.get(RecordTypeId).getName();
	        } else {
	            return null;
	        }
    	} catch(exception ex) {
	    	return null;
	    }
    }
    
    /*******************************************************************************************************
    * @description Provides the Ids of the Record Types with specific names in an specific Object.
    * @param objectName The name of the Object.
    * @param  recordTypeNameSet The names of the Record Types.
    * @return Set<Id> The Ids of the Record Types.
    */
    public static Set<Id> GetRecordTypeIdSet(String objectName, Set<String> recordTypeNameSet) {
        Set<Id> recordTypeIds = new Set<Id>();

        // make sure we have this object's record types Mapped
        if (!recordTypesByName.containsKey(objectName)) 
            fillMapsForObject(objectName);

        // fill the id Set from the name Set
        if (recordTypesByName.containsKey(objectName)) { 
            Map<String, Schema.RecordTypeInfo> rtMap = recordTypesByName.get(objectName);
            for (String recTypeName : recordTypeNameSet) {
                if (rtMap.containsKey(recTypeName)) {
                    recordTypeIds.add(rtMap.get(recTypeName).getRecordTypeId());
                }
            }
        }
        return recordTypeIds;
    }
    
    /*******************************************************************************************************
    * @description Provides the names and Ids of all the Record Types with the specified name.
    * @param objectName The name of the Object.
    * @return Map<String, Id> The name and Id of each Record Type.
    */
    public static Map<String, Id> GetRecordTypeIdMap(String objectName) {
        Map<String, Id> recordTypeMap = new Map<String, Id>();  
        // make sure we have this object's record types Mapped
        if (!recordTypesByName.containsKey(objectName)) 
            fillMapsForObject(objectName);

        // fill the name to id Map
        if (recordTypesByName.containsKey(objectName)) { 
            Map<String, Schema.RecordTypeInfo> rtMap = recordTypesByName.get(objectName);
            for (recordTypeInfo rti : rtMap.values()) {
                if (rti.getName() != 'Master')
                    recordTypeMap.put(rti.getName(), rti.getRecordTypeId());
            }
        }
        
        return recordTypeMap;
    }
    
    /*******************************************************************************************************
    * @description Provides the Record Types of an specific Object as a list of Select Options, to be displayed in
    *              a Visualforce page as a drop-down.
    * @param objectName The name of the Object.
    * @return List<SelectOption> The list of Record Types wrapped in a Select Option each.
    */
    public static List<SelectOption> getRecordTypesForSelectList(String objectName) {
        
        List<SelectOption> recordTypesOptions = new List<SelectOption>();     
        Map<String, Id> availRecordTypes = getRecordTypeIdMap(objectName);
        if (!availRecordTypes.isEmpty()) {
            for (String thisRecordType : availRecordTypes.keySet()) {
                recordTypesOptions.add(new SelectOption(availRecordTypes.get(thisRecordType), thisRecordType)); 
            }
        }
        return recordTypesOptions;
    }
    
    /*******************************************************************************************************
    * @description Provides the names of the Record Types of an specific Object as a list of Select Options, to be displayed 
    *              in a Visualforce page as a drop-down.
    * @param objectName The name of the Object.
    * @return List<SelectOption> The list of Record Type names wrapped in a Select Option each.
    */
    public static List<SelectOption> getStringRecordTypesForSelectList(String objectName) {
        
        List<SelectOption> recordTypesOptions = new List<SelectOption>();
        Map<String, Id> availRecordTypes = getRecordTypeIdMap(objectName);
        if (!availRecordTypes.isEmpty()) {
            for (String thisRecordType : availRecordTypes.keySet()) {
                recordTypesOptions.add(new SelectOption(thisRecordType, thisRecordType));   
            }
        }
        return recordTypesOptions;
    }


}