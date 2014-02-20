/**
* @author Evan Callahan
* @date 2010 
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
* within one transaction, or set of trigger calls. This is beneficial because this info should
* be the same for all calls in a transaction, and by calling it statically we reduce the calls
* that are made, making the total transaction more efficient
-----------------------------------------------------------------------------------------------*/
    
    //maps to hold the record type info
    private static Map<String, Schema.SObjectType> gd;
    private static Map<String,Map<Id,Schema.RecordTypeInfo>> recordTypesById = new Map<String,Map<Id,Schema.RecordTypeInfo>>();
    private static Map<String,Map<String,Schema.RecordTypeInfo>> recordTypesByName = new Map<String,Map<String,Schema.RecordTypeInfo>>();
    private static List<Schema.Recordtypeinfo> recordTypesList = New List<Schema.Recordtypeinfo>();
    public static String giftRecordTypeNameForTests;
    public static String membershipRecordTypeNameForTests;    
        
    /*******************************************
    * Gets record type maps for a new object
    ********************************************/
    static void fillMapsForObject(string objectName) {
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

    /*******************************************
    * Gives record type Id from a given record type name
    ********************************************/
    public static Id GetRecordTypeId(String objectName, String RecordTypeName) {
        // make sure we have this object's record types mapped
        if (!recordTypesByName.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        // now grab and return the requested id 
        Map<String,Schema.RecordTypeInfo> rtMap = recordTypesByName.get(objectName);
        if (rtMap != null && rtMap.containsKey(RecordTypeName)) {
            return rtMap.get(RecordTypeName).getRecordTypeId();
        } else {
            return null;
        }
    }
    
    public static string getRecordTypeNameForGiftsTests(String objectName){  

        if (giftRecordTypeNameForTests == null){
             // make sure we have this object's record types mapped
            if (!recordTypesByName.containsKey(objectName)) 
                fillMapsForObject(objectName);
                
            if(recordTypesList.size()==0){
                giftRecordTypeNameForTests = '';
            } else{
                giftRecordTypeNameForTests = recordTypesList[0].getName();          
            }
        }      
       
        return giftRecordTypeNameForTests;
    }
    
    public static string getRecordTypeNameForMembershipTests(String objectName){      
        if (membershipRecordTypeNameForTests == null){        
            // make sure we have this object's record types mapped
            if (!recordTypesByName.containsKey(objectName)) 
                fillMapsForObject(objectName);
                
            if(recordTypesList.size()==0){
                membershipRecordTypeNameForTests = '';
            } else if(recordTypesList.size()==1){
                membershipRecordTypeNameForTests = recordTypesList[0].getName();
            } else {
                membershipRecordTypeNameForTests = recordTypesList[1].getName();            
            }
        }
        return membershipRecordTypeNameForTests;
    }
        
    /*******************************************
    * Gives record type Name from a given record type Id
    ********************************************/
    public static String GetRecordTypeName(String objectName, Id RecordTypeId) {
        // make sure we have this object's record types mapped
        if (!recordTypesById.containsKey(objectName)) 
            fillMapsForObject(objectName);
        
        // now grab and return the requested id
        Map<Id,Schema.RecordTypeInfo> rtMap = recordTypesById.get(objectName);
        if (rtMap != null && rtMap.containsKey(RecordTypeId)) {
            return rtMap.get(RecordTypeId).getName();
        } else {
            return null;
        }
    }
    
    /*******************************************
    * Gives a set of record type Ids from a given set of names
    ********************************************/
    public static set<Id> GetRecordTypeIdSet(String objectName, set<string> RecordTypeNameSet) {
        set<Id> recordTypeIds = new set<Id>();

        // make sure we have this object's record types mapped
        if (!recordTypesByName.containsKey(objectName)) 
            fillMapsForObject(objectName);

        // fill the id set from the name set
        if (recordTypesByName.containsKey(objectName)) { 
            Map<String,Schema.RecordTypeInfo> rtMap = recordTypesByName.get(objectName);
            for (String recTypeName : RecordTypeNameSet) {
                if (rtMap.containsKey(recTypeName)) {
                    recordTypeIds.add(rtMap.get(recTypeName).getRecordTypeId());
                }
            }
        }
        return recordTypeIds;
    }
    
    /*******************************************
    * Gives a set of record type Ids from a given set of names
    ********************************************/
    public static Map<String, Id> GetRecordTypeIdMap(String objectName) {
        Map<String, Id> recordTypeMap = new Map<String, Id>();  
        // make sure we have this object's record types mapped
        if (!recordTypesByName.containsKey(objectName)) 
            fillMapsForObject(objectName);

        // fill the name to id map
        if (recordTypesByName.containsKey(objectName)) { 
            Map<String,Schema.RecordTypeInfo> rtMap = recordTypesByName.get(objectName);
            for (recordTypeInfo rti : rtMap.values()) {
                if (rti.getName() != 'Master')
                    recordTypeMap.put(rti.getName(), rti.getRecordTypeId());
            }
        }
        
        return recordTypeMap;
    }

    /*******************************************
    * Gets record type naming suffix from record type name
    ********************************************/
    public static String GetOppNamingSuffix(String RecordTypeName){
        Map<String,String> OpportunitySufix =  new Map<String,String>();

        //add overrides for naming suffixes
        //OpportunitySufix.put('Gift','Gift Suffix');

        String Suffix;
        Suffix = OpportunitySufix.get(RecordTypeName);
        return (Suffix==null) ? RecordTypeName : Suffix;    
    }
    
    /****************************************************************
    * function to get a list of select options for a Visualforce picklist of record types. 
    *****************************************************************/
    public static List<SelectOption> getRecordTypesForSelectList(String objectName) {
        
        List<SelectOption> recordTypesOptions = new List<SelectOption>();
        
        Map<String,Id> availRecordTypes = getRecordTypeIdMap(objectName);
        if (!availRecordTypes.isEmpty()) {
            for (string thisRecordType : availRecordTypes.keyset()) {
                recordTypesOptions.add(new SelectOption(availRecordTypes.get(thisRecordType), thisRecordType)); 
            }
        }
        return recordTypesOptions;
    }
    
    public static List<SelectOption> getStringRecordTypesForSelectList(String objectName) {
        
        List<SelectOption> recordTypesOptions = new List<SelectOption>();
        Map<String,Id> availRecordTypes = getRecordTypeIdMap(objectName);
        if (!availRecordTypes.isEmpty()) {
            for (string thisRecordType : availRecordTypes.keyset()) {
                recordTypesOptions.add(new SelectOption(thisRecordType, thisRecordType));   
            }
        }
        return recordTypesOptions;
    }


}