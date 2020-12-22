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
* @description Class to test GS_ChecklistSetup class.
*/
@isTest
private with sharing class GS_ChecklistSetup_TEST {

    /**
    *  @description This test data if wraped in GS_ChecklistSetup.getChecklist are the same in the metadata
    */
    @isTest
    static void getChecklistsTest() {

        Id firstItemId = [ SELECT Id FROM GetStartedChecklistItem__mdt LIMIT 1 ].Id;

        GetStartedCompletionChecklistState__c checkedItem = new GetStartedCompletionChecklistState__c(Item_Id__c = firstItemId,
                                                                                                User__c = UserInfo.getUserId());
        insert checkedItem;

        List<GS_ChecklistSetup.ChecklistSection> checklists = GS_ChecklistSetup.getChecklists('Admin');
        List<GetStartedChecklistSection__mdt> metadataSections = [
            SELECT Id, Label, Position__c
            FROM GetStartedChecklistSection__mdt
            WHERE Page_Type__c = 'Admin'
            ORDER BY Position__c ASC
        ];

        System.assertNotEquals(null, checklists, 'The checklist section is null');
        System.assertEquals(
            metadataSections.size(),
            checklists.size(),
            'The checklist section does not have the same size than metadata in org'
        );

        for (Integer i = 0; i < metadataSections.size(); i++) {

            //Order in sub query doesn't work well
            GetStartedChecklistSection__mdt metadataSection = metadataSections[i];
            GS_ChecklistSetup.ChecklistSection checklist = checklists[i];
            System.assertEquals(
                metadataSection.Id,
                checklist.Id,
                'The metadataSection and Checklist are not in the same orden'
            );
            List<GetStartedChecklistItem__mdt> metadataSectionItems = [
                SELECT Id, Position__c
                FROM GetStartedChecklistItem__mdt
                WHERE GS_Checklist_Section__c = :metadataSection.Id
                ORDER BY Position__c ASC
            ];
            System.assertEquals(
                metadataSectionItems.size(),
                checklist.items.size(),
                'The checklist ' + metadataSection.Label + ' don\'t have same children size'
            );
            for (Integer j = 0; j < checklist.items.size(); j++) {
                GetStartedChecklistItem__mdt metadataItem = metadataSectionItems[j];
                GS_ChecklistSetup.ChecklistItem item = checklist.items[j];

                System.assertEquals(
                    metadataItem.Id,
                    item.Id,
                    'The metadataSection and Checklist childrens are not in the same orden'
                );

                System.assertEquals(item.Id == checkedItem.Item_Id__c, item.checked, 'Element is not checked as expected');
            }
        }
    }

    @isTest
    private static void persistTest() {
        List<GetStartedChecklistItem__mdt> metadataSectionItems = [SELECT Id, Position__c
                                                                   FROM   GetStartedChecklistItem__mdt
                                                                   ORDER BY Position__c ASC LIMIT 1];
        System.assertEquals(false, metadataSectionItems.isEmpty(), 'Items should not be empty');
        GS_ChecklistSetup.updateCheckItem('invalid', true);
        List<GetStartedCompletionChecklistState__c> adminStatus = [SELECT Id,
                                                                           Item_Id__c,
                                                                           User__c
                                                                    FROM   GetStartedCompletionChecklistState__c];
        System.assertEquals(true, adminStatus.isEmpty(), 'No Invalid Id should be persisted');
        GS_ChecklistSetup.updateCheckItem(metadataSectionItems[0].id, true);
        adminStatus = [SELECT Id,
                              Item_Id__c,
                              User__c
                       FROM   GetStartedCompletionChecklistState__c];
        System.assertEquals(1, adminStatus.size(), 'One element should have been created');
        System.assertEquals(metadataSectionItems[0].id, adminStatus[0].Item_Id__c,'Id should have been the same');
        System.assertEquals(UserInfo.getUserId(), adminStatus[0].User__c,'UserId should have been the current one');
        GS_ChecklistSetup.updateCheckItem(metadataSectionItems[0].id, true);
        adminStatus = [SELECT Id,
                              Item_Id__c,
                              User__c
                       FROM   GetStartedCompletionChecklistState__c];
        System.assertEquals(1, adminStatus.size(), 'No duplicated elements are allowed');
        GS_ChecklistSetup.updateCheckItem(metadataSectionItems[0].id, false);
        adminStatus = [SELECT Id,
                              Item_Id__c,
                              User__c
                       FROM   GetStartedCompletionChecklistState__c];
        System.assertEquals(true, adminStatus.isEmpty(), 'Item is not unchecked');
    }
}
