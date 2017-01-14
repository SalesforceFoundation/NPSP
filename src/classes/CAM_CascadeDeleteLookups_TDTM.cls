public with sharing class CAM_CascadeDeleteLookups_TDTM extends UTIL_CascadeDeleteLookups_TDTM {
    
    private static List<Cascade> cascades = new List<Cascade>{
        new Cascade(UTIL_Namespace.StrTokenNSPrefix('Allocation__c'),'Campaign__c')
    };
    
    public override List<Cascade> getCascades() {
        return cascades;
    }
}