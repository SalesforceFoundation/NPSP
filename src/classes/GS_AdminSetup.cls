/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group GS
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Class to hold functionality to dispaly Checklist in GS UI.
*/
public with sharing class GS_AdminSetup {

    private static final String DISABLED = 'Disabled';
    /**
     * @description This method return a list of checklist 
     * section to display this information in UI
     * @return List<ChecklistSection>
     */
    @AuraEnabled(cacheable=true)
    public static List<ChecklistSection> getChecklist() {
        List<GS_Admin_Checklist_Section__mdt> checklistSections = getSectionsAndSubsections();
        List<ChecklistSection> checklistWrapers = new List<ChecklistSection>();
        for (GS_Admin_Checklist_Section__mdt checklistSection : checklistSections) {
            checklistWrapers.add(wrapChecklistSection(checklistSection));
        }
        return checklistWrapers;
    }

    /**
     * @description This method return a list of GS_Admin_Checklist_Section__mdt and his Items 
     * @return List<GS_Admin_Checklist_Section__mdt>
     */
    private static List<GS_Admin_Checklist_Section__mdt> getSectionsAndSubsections() {
        return [ 
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
    }

    /*
    * @description This method wrap a checklist section in a apex object to send to UI
    * @arg GS_Admin_Checklist_Section__mdt the metdata to wrap
    * @return ChecklistSection
    */
    private static ChecklistSection wrapChecklistSection(GS_Admin_Checklist_Section__mdt section) {
        ChecklistSection cs = new ChecklistSection();
        cs.id = section.Id;
        cs.title = section.Title_Label__c;
        cs.description = section.Description_Label__c;
        cs.pos = section.Position__c.intValue();
        for (GS_Admin_Checklist_Item__mdt item:section.GS_Admin_Checklist_Items__r) {
            cs.items.add(wrapChecklistItem(item));
        }
        return cs;
    }

    /*
    * @description This method wrap a checklist Item in a apex object to send to UI
    * @arg GS_Admin_Checklist_Item__mdt the metdata to wrap
    * @return ChecklistItem
    */
    private static ChecklistItem wrapChecklistItem(GS_Admin_Checklist_Item__mdt item) {
        ChecklistItem ci = new ChecklistItem();
        ci.Id = item.Id;
        ci.title = item.Title_Label__c;
        ci.description = item.Description_Label__c;
        ci.image = item.Image__c;
        ci.pos = item.Position__c.intValue();
        if (item.Has_Link__c) {
            ci.link = new ChecklistItemLink(item.Link_Label__c, item.Link_href__c);
        }
        if (item.Principal_Button_Type__c != DISABLED) {
            ci.principalBtn = new ChecklistItemButton(item.Principal_Button_Type__c, item.Principal_Button_Label__c, item.Principal_Button_Value__c);
        }
        if (item.Secondary_Button_Type__c != DISABLED) {
            ci.secondaryBtn = new ChecklistItemButton(item.Secondary_Button_Type__c, item.Secondary_Button_Label__c, item.Secondary_Button_Value__c);
        }
        return ci;
    }

    /*
    * @description This Class is to wrap GS_Admin_Checklist_Section__mdt information
    */
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

    /*
    * @description This Class is to wrap GS_Admin_Checklist_Item__mdt information
    */
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


    /*
    * @description This Class is to wrap GS_Admin_Checklist_Item__mdt Link information
    */
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


    /*
    * @description This Class is to wrap GS_Admin_Checklist_Item__mdt Buttons information
    */
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
