@isTest
private with sharing class GS_AdminSetup_TEST {
  
    @isTest
    static void getChecklistTest() {
        List<GS_AdminSetup.ChecklistSection> checklists= GS_AdminSetup.getChecklist();
        List<GS_Admin_Checklist_Section__mdt> metadataSections = [ 
            SELECT Id, Label, Position__c, (SELECT Id, Position__c FROM GS_Admin_Checklist_Items__r ORDER BY Position__c ASC) 
            FROM GS_Admin_Checklist_Section__mdt ORDER BY Position__c ASC
        ];
        System.assertEquals(metadataSections.size(), checklists.size(), 'The checklist section don\'t have same size to the metadata are in the org');
        
        for(Integer i = 0; i < metadataSections.size(); i++) {
   
            GS_Admin_Checklist_Section__mdt metadataSection = metadataSections[i];
            GS_AdminSetup.ChecklistSection checklist = checklists[i];
            System.assertEquals(metadataSection.Id, checklist.Id,
            'The metadataSection and Checklist not are in the same orden');
            System.assertEquals(
                metadataSection.GS_Admin_Checklist_Items__r.size(), 
                checklist.items.size(),
                 'The checklist '+metadataSection.Label +' don\'t have same children size' 
            );
            for(Integer j = 0; j < checklist.items.size(); j++) {
                GS_Admin_Checklist_Item__mdt metadataItem = metadataSection.GS_Admin_Checklist_Items__r[j];
                GS_AdminSetup.ChecklistItem item = checklist.items[j];

                System.assertEquals(metadataItem.Id, item.Id,
                    'The metadataSection and Checklist childrens are not in the same orden');
            }
        }
    }
}
