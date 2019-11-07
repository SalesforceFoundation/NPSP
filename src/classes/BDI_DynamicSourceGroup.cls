public with sharing class BDI_DynamicSourceGroup {
    @AuraEnabled public Map<String,BDI_DynamicSource> dynamicSourceByObjMappingDevName;
    @AuraEnabled public String name;
    
    public BDI_DynamicSourceGroup() {

    }
}