/**
 * Created by kenneth.lewis on 2019-07-10.
 */

public class BDI_TargetFields {
    private Map<SObjectType, Set<SObjectField>> targetFieldsByTargetObject = new Map<SObjectType, Set<SObjectField>>();

    public Map<SObjectType, Set<SObjectField>> getTargetFieldsByTargetObject(){
        return targetFieldsByTargetObject;
    }

    public void addTargetField(String objName, String fieldName){
        SObjectType objectToken;
        SObjectField fieldToken;

        //TODO: move to method description
        //Convert to object and field tokens,
        //UTIL_Describe methods will throw exceptions if the input strings do not
        //resolve to valid SObjects and Fields
        objectToken = UTIL_Describe.getObjectDescribe(objName).getSObjectType();
        fieldToken = UTIL_Describe.getFieldDescribe(objName, fieldName).getSobjectField();

        if (targetFieldsByTargetObject.get(objectToken) == null) {
            targetFieldsByTargetObject.put(objectToken, new Set<SObjectField>{fieldToken});
        } else {
            targetFieldsByTargetObject.get(objectToken).add(fieldToken);
        }
    }
}