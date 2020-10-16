public with sharing class GS_AdminSetup {

    @AuraEnabled(cacheable=true)
    public static List<ChecklistSection> getChecklist() {
        List<GS_Admin_Checklist_Section__mdt> checklistSections = [ 
          SELECT Id, Title_Label__c, Description_Label__c, Position__c, 
            (
             SELECT Id, Title_Label__c, Description_Label__c, Image__c, Position__c,
                Has_Link__c, Link_Label__c, Link_href__c,
                Principal_Button_Type__c, Principal_Button_Label__c, Principal_Button_Value__c,
                Secondary_Button_Type__c, Secondary_Button_Label__c, Secondary_Button_Value__c
             FROM GS_Admin_Checklist_Items__r ORDER BY Position__c ASC
            ) 
          FROM GS_Admin_Checklist_Section__mdt ORDER BY Position__c ASC 
        ];
        List<ChecklistSection> checklistWarpers = new List<ChecklistSection>();
        for(GS_Admin_Checklist_Section__mdt checklistSection:checklistSections) {
            checklistWarpers.add(wrapChecklistSection(checklistSection));
        }
        return checklistWarpers;
    }

    private static ChecklistSection wrapChecklistSection(GS_Admin_Checklist_Section__mdt section) {
        ChecklistSection cs = new ChecklistSection();
        cs.id = section.Id;
        cs.title = section.Title_Label__c;
        cs.description = section.Description_Label__c;
        cs.pos = section.Position__c.intValue();
        for(GS_Admin_Checklist_Item__mdt item:section.GS_Admin_Checklist_Items__r) {
            cs.items.add(wrapChecklistItem(item));
        }
        return cs;
    }

    private static ChecklistItem wrapChecklistItem(GS_Admin_Checklist_Item__mdt item) {
        ChecklistItem ci = new ChecklistItem();
        ci.Id = item.Id;
        ci.title = item.Title_Label__c;
        ci.description = item.Description_Label__c;
        ci.image = item.Image__c;
        ci.pos = item.Position__c.intValue();
        if(item.Has_Link__c) {
            ci.link = new ChecklistItemLink(item.Link_Label__c, item.Link_href__c);
        }
        if(item.Principal_Button_Type__c != 'Disabled') {
            ci.principalBtn = new ChecklistItemButton(item.Principal_Button_Type__c, item.Principal_Button_Label__c, item.Principal_Button_Value__c);
        }
        if(item.Secondary_Button_Type__c != 'Disabled') {
            ci.secondaryBtn = new ChecklistItemButton(item.Secondary_Button_Type__c, item.Secondary_Button_Label__c, item.Secondary_Button_Value__c);
        }
        return ci;
    }


    public class ChecklistSection {
        @AuraEnabled
        public List<ChecklistItem> items = new List<ChecklistItem>();
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public Integer pos;
        @AuraEnabled
        public Id id;
    }

    public class ChecklistItem {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public Integer pos;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String image;
        @AuraEnabled
        public ChecklistItemLink link;
        @AuraEnabled
        public ChecklistItemButton principalBtn;
        @AuraEnabled
        public ChecklistItemButton secondaryBtn;

    }

    public class ChecklistItemLink {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String href;

        public ChecklistItemLink(String label, String href) {
            this.label = label;
            this.href = href;
        }
    }

    public class ChecklistItemButton {
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        public ChecklistItemButton(String type, String label, String value) {
            this.type = type;
            this.label = label;
            this.value = value;
        }
    }

}
