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
* @group Get Started
* @description Class to hold functionality to display Checklist in GS UI.
*/
public with sharing class GS_ChecklistSetup {

    private static final String DISABLED = 'Disabled';
    private static Set<Id> storedItemsId = null;
    /**
     * @description Returns a list of the checklist section with each subsection.
     * Each section is defined in GetStartedChecklistSection__mdt and each subsection is defined in GetStartedChecklistItem__mdt
     * @return List<ChecklistSection>
     */
    @AuraEnabled
    public static List<ChecklistSection> getChecklists(String pageType) {
        storedItemsId = getMarkedAsCompletedCheckListItemByUser();
        List<GetStartedChecklistSection__mdt> checklistSections = getSectionsAndSubsections(pageType);
        List<ChecklistSection> checklistWrapers = new List<ChecklistSection>();
        for (GetStartedChecklistSection__mdt checklistSection : checklistSections) {
            checklistWrapers.add(wrapChecklistSection(checklistSection));
        }
        return checklistWrapers;
    }

    /**
     * @description Persist in database if an element is checked or not.
     * For doing so we use the object GetStartedCompletionChecklistState__c;.
     * The object contains two fields: Item_Id and User.
     * Which means that a checkbox is selected if an element
     * it means the element is checked
     * @param  itemId  Id the checklist item id
     * @param  isChecked boolean element is checked of not
     */
    @AuraEnabled
    public static void updateCheckItem(String itemId, Boolean isChecked){

        if (doesChecklistItemExists(itemId)) {
            List<GetStartedCompletionChecklistState__c> alreadyStoredCompletedItems = [
                SELECT Id
                FROM   GetStartedCompletionChecklistState__c
                WHERE  Item_Id__c = :itemId
                AND    User__c = :UserInfo.getUserId()
                WITH SECURITY_ENFORCED
            ];
            if (isChecked) {
                markItemAsCompleted(alreadyStoredCompletedItems, itemId);
            } else {
                unmarkItemAsCompleted(alreadyStoredCompletedItems);
            }
        }
    }

    /**
     * @description Check if exists an GetStartedChecklistItem__mdt with the Id
     * @param  itemId String the id of the GetStartedChecklistItem__mdt to be validated
     * @return true if itemId is found, false otherwise
     */
    private static Boolean doesChecklistItemExists(String itemId) {
        List<GetStartedChecklistItem__mdt> items = [
            SELECT Id FROM  GetStartedChecklistItem__mdt
            WHERE  Id = :itemId
            WITH SECURITY_ENFORCED
        ];
        return !items.isEmpty();
    }

    /**
     * @description Set an Checklist element as checked to the current user.
     * It's only done if the element was previously marked as "incomplete"(record does not exists).
     * It will not create duplicated records.
     * @param  checklistStatus List<GetStartedCompletionChecklistState__c> list with the checklistStatus filtered by user and filter id
     * @param  itemId      String the item id to be completed
     */
    private static void markItemAsCompleted(List<GetStartedCompletionChecklistState__c> checklistStatus, String itemId) {
        if (Schema.SObjectType.GetStartedCompletionChecklistState__c.fields.Item_Id__c.isUpdateable() &&
            Schema.SObjectType.GetStartedCompletionChecklistState__c.fields.User__c.isUpdateable() &&
            checklistStatus.isEmpty()) {

            checklistStatus.add(new GetStartedCompletionChecklistState__c(Item_Id__c = itemId,
                                                                     User__c = UserInfo.getUserId()));
            insert checklistStatus;
        }
    }

    /**
     * @description unmark the previously completed checklist item marking it as "incomplete"
     * In this implementation, we only store the "completed" items so we deleted.
     * @param  checklistStatus List<GetStartedCompletionChecklistState__c> list with the items filtered by currentUser and itemId
     */
    private static void unmarkItemAsCompleted(List<GetStartedCompletionChecklistState__c> checklistStatus) {
        if (GetStartedCompletionChecklistState__c.SObjectType.getDescribe().isDeletable() && !checklistStatus.isEmpty()) {
            database.delete(checklistStatus);
        }
    }

    /**
     * @description Return the list of GetStartedChecklistSection__mdt and his Items
     * @return List<GetStartedChecklistSection__mdt>
     * @note [ORDER BY Position__c ASC] doesn't work well in the inner query, I need to sort outside SOQL
     */
    private static List<GetStartedChecklistSection__mdt> getSectionsAndSubsections(String pageType) {
        return [
            SELECT Id, Title_Label__c, Description_Label__c, Position__c,
                (
                    SELECT Id, Title_Label__c, Description_Label__c, Image__c, Position__c,
                        Has_Link__c, Link_Label__c, Link_URL__c, Extra_Info_Label__c,
                        Primary_Button_Type__c, Primary_Button_Label__c, Primary_Button_Value__c,
                        Secondary_Button_Type__c, Secondary_Button_Label__c, Secondary_Button_Value__c
                    FROM GetStartedChecklistItems__r
                )
            FROM GetStartedChecklistSection__mdt
            WHERE Page_Type__c = :pageType
            WITH SECURITY_ENFORCED
            ORDER BY Position__c ASC
        ];
    }

    /**
    * @description This method wrap a checklist section in a apex object to send to UI
    * @param GetStartedChecklistSection__mdt the metdata to wrap
    * @return ChecklistSection
    */
    private static ChecklistSection wrapChecklistSection(GetStartedChecklistSection__mdt section) {
        ChecklistSection cs = new ChecklistSection();
        cs.id = section.Id;
        cs.title = section.Title_Label__c;
        cs.description = section.Description_Label__c;
        cs.pos = section.Position__c.intValue();
        for (GetStartedChecklistItem__mdt item : section.GetStartedChecklistItems__r) {
            cs.items.add(wrapChecklistItem(item));
        }
        //I need sort manualy to not work well in SOQL [ORDER BY]
        cs.items.sort();
        return cs;
    }

    /**
    * @description This method wrap a checklist Item in a apex object to send to UI
    * @param GetStartedChecklistItem__mdt the metdata to wrap
    * @return ChecklistItem
    */
    private static ChecklistItem wrapChecklistItem(GetStartedChecklistItem__mdt item) {
        ChecklistItem ci = new ChecklistItem();
        ci.Id = item.Id;
        ci.title = item.Title_Label__c;
        ci.description = item.Description_Label__c;
        ci.extraInfo = item.Extra_Info_Label__c;
        ci.image = item.Image__c;
        ci.pos = item.Position__c.intValue();
        ci.checked = storedItemsId.contains(item.Id);
        if (item.Has_Link__c) {
            ci.link = new ChecklistItemLink(item.Link_Label__c, item.Link_URL__c);
        }
        if (item.Primary_Button_Type__c != DISABLED) {
            ci.primaryBtn = new ChecklistItemButton(item.Primary_Button_Type__c, item.Primary_Button_Label__c, item.Primary_Button_Value__c);
        }
        if (item.Secondary_Button_Type__c != DISABLED) {
            ci.secondaryBtn = new ChecklistItemButton(item.Secondary_Button_Type__c, item.Secondary_Button_Label__c, item.Secondary_Button_Value__c);
        }
        return ci;
    }

    private static Set<Id> getMarkedAsCompletedCheckListItemByUser() {
        List<GetStartedCompletionChecklistState__c> checkedItemList = [
            SELECT Item_Id__c
            FROM GetStartedCompletionChecklistState__c
            WHERE User__c = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
        ];
        Set<Id> ids = new Set<Id>();
        for (GetStartedCompletionChecklistState__c checkedItem : checkedItemList) {
            ids.add(checkedItem.Item_Id__c);
        }
        return ids;
    }

    /***
    * @description NPSP namespace: an empty string if unmanaged, or 'npsp' if managed
    * @return String
    */
    @AuraEnabled(Cacheable=true)
    public static String getNamespace() {
        return UTIL_Namespace.getNamespace();
    }

    /**
    * @description This Class is to wrap GetStartedChecklistSection__mdt information
    */
    public class ChecklistSection {
        /*
        * @description List of items in the secction
        * @type List<ChecklistItem>
        */
        @AuraEnabled
        public List<ChecklistItem> items = new List<ChecklistItem>();
        /*
        * @description Name of title label
        * @type String
        */
        @AuraEnabled
        public String title;
        /*
        * @description Name of description label
        * @type String
        */
        @AuraEnabled
        public String description;
        /*
        * @description Section position
        * @type
        */
        @AuraEnabled
        public Integer pos;
        /*
        * @description Metadata Id
        * @type Id
        */
        @AuraEnabled
        public Id id;
    }

    /**
    * @description This Class is to wrap GetStartedChecklistItem__mdt information
    */
    public class ChecklistItem implements Comparable {
        /**
        * @description Metadata id
        * @type Id
        */
        @AuraEnabled
        public Id id;
        /**
        * @description Item title label Name
        * @type String
        */
        @AuraEnabled
        public String title;
        /*
        * @description  Item position
        * @type Integer
        */
        @AuraEnabled
        public Integer pos;
        /**
        * @description Item describtion label Name
        * @type String
        */
        @AuraEnabled
        public String description;
        /**
        * @description Item image name
        * @type String
        */
        @AuraEnabled
        public String image;
        /**
        * @description Item extra info label name
        * @type String
        */
        @AuraEnabled
        public String extraInfo;
        /**
        * @description Item link info
        * @type ChecklistItemLink
        */
        @AuraEnabled
        public ChecklistItemLink link;
        /**
        * @description Item primary button info
        * @type ChecklistItemLink
        */
        @AuraEnabled
        public ChecklistItemButton primaryBtn;
        /**
        * @description Item secondary button info
        * @type ChecklistItemButton
        */
        @AuraEnabled
        public ChecklistItemButton secondaryBtn;

        @AuraEnabled
        public Boolean checked;

        /**
        * @description Compare ChecklistItem to short using position
        * @param ChecklistItem object to compare
        * @note I need make that to not work well inner order in SOQL
        */
        public Integer compareTo(Object compareTo) {
            ChecklistItem compare = (ChecklistItem) compareTo;
            if(this.pos > compare.pos) {
                return 1;
            } else if(this.pos < compare.pos) {
                return -1;
            }
            return 0;
        }

    }

    /**
    * @description This Class is to wrap GetStartedChecklistItem__mdt Link information
    */
    public class ChecklistItemLink {
        /**
        * @description Name of link label
        * @type String
        */
        @AuraEnabled
        public String label;
        /**
        * @description Link Url
        * @type String
        */
        @AuraEnabled
        public String href;

        /**
        * @description Class constructor to link info object
        * @param String label Link label name
        * @param String href Link url value
        */
        public ChecklistItemLink(String label, String href) {
            this.label = label;
            this.href = href;
        }
    }

    /**
    * @description This Class is to wrap GetStartedChecklistItem__mdt Buttons information
    */
    public class ChecklistItemButton {
        /**
        * @description Type of acction have the button
        * @type String
        */
        @AuraEnabled
        public String type;
        /**
        * @description Name of button label
        * @type String
        */
        @AuraEnabled
        public String label;
        /**
        * @description Value use to make the button action
        * @type String
        */
        @AuraEnabled
        public String value;

        /**
        * @description Class constructor to button info object
        * @param String type Button type
        * @param String label Button label name
        * @param String value Button value to action
        */
        public ChecklistItemButton(String type, String label, String value) {
            this.type = type;
            this.label = label;
            this.value = value;
        }
    }
}
