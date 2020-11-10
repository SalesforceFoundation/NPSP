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
* @group Getting Started
* @description Class to test GS_AdminSetup class.
*/
@isTest
private with sharing class GS_AdminSetup_TEST {
  
    /**
    *  @description This test data if wraped in GS_AdminSetup.getChecklist are the same in the metadata
    */
    @isTest
    static void getChecklistsTest() {
        List<GS_AdminSetup.ChecklistSection> checklists = GS_AdminSetup.getChecklists();
        List<GS_Admin_Checklist_Section__mdt> metadataSections = [ 
            SELECT Id, Label, Position__c 
            FROM GS_Admin_Checklist_Section__mdt 
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
            GS_Admin_Checklist_Section__mdt metadataSection = metadataSections[i];
            GS_AdminSetup.ChecklistSection checklist = checklists[i];
            System.assertEquals(
                metadataSection.Id, 
                checklist.Id,
                'The metadataSection and Checklist are not in the same orden'
            );
            List<GS_Admin_Checklist_Item__mdt> metadataSectionItems = [
                SELECT Id, Position__c
                FROM GS_Admin_Checklist_Item__mdt
                WHERE GS_Admin_Checklist_Section__c = :metadataSection.Id
                ORDER BY Position__c ASC
            ];
            System.assertEquals(
                metadataSectionItems.size(), 
                checklist.items.size(),
                'The checklist ' + metadataSection.Label + ' don\'t have same children size' 
            );
            for (Integer j = 0; j < checklist.items.size(); j++) {
                GS_Admin_Checklist_Item__mdt metadataItem = metadataSectionItems[j];
                GS_AdminSetup.ChecklistItem item = checklist.items[j];

                System.assertEquals(
                    metadataItem.Id,
                    item.Id,
                    'The metadataSection and Checklist childrens are not in the same orden'
                );
            }
        }
    }
}
