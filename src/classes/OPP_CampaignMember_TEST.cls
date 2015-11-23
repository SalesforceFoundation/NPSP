/*
    Copyright (c) 2015 Salesforce.org
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
* @date 2015
* @group Contact
* @description Tests for opporunity campaign member creation.
*/
@isTest
private class OPP_CampaignMember_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    /*********************************************************************************************************
    * @description Inserts a new opportunity for a contact with a primary campaign source, and a new member
    * status. Verifies that a campaign member and a new campaign member status are created.
    */
    @isTest static void newMemberCreateStatus() {
        if (strTestOnly != '*' && strTestOnly != 'newMemberCreateStatus') return;

        Contact con = new Contact(LastName='foo');
        insert con;

        Campaign cam = new Campaign(Name='foo');
        insert cam;

        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = con.id,
            CloseDate = system.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Amount = 8,
            CampaignId=cam.id,
            Primary_Contact_Campaign_Member_Status__c = 'foo'
        );

        test.startTest();
        insert opp;
        test.stopTest();

        list<campaignmember> querycm = [SELECT Id, Status FROM CampaignMember WHERE contactId=:con.id AND campaignId=:cam.id];
        system.assertEquals(1, querycm.size(), 'A campaign member should be created.');
        system.assertEquals('foo', querycm[0].Status, 'Campaign member should have our status.');

        list<campaignmemberstatus> querycms = [SELECT Id, IsDefault, HasResponded, Label, SortOrder FROM CampaignMemberStatus WHERE campaignid = :cam.id AND Label=:opp.Primary_Contact_Campaign_Member_Status__c];
        system.assertEquals(1, querycms.size(), 'A campaign member status should be created.');
        system.assertEquals(false, querycms[0].HasResponded, 'Status should be non-responded.');
    }

    /*********************************************************************************************************
    * @description Inserts a new opportunity with a primary campaign source, for a contact that has an existing 
    * campaign member for that campaign. Verifies a campaign member status is created and the existing campaign
    * member is updated with that status.
    */
    @isTest static void updateMemberCreateStatus() {
        if (strTestOnly != '*' && strTestOnly != 'updateMemberCreateStatus') return;

        Contact con = new Contact(LastName='foo');
        insert con;

        Campaign cam = new Campaign(Name='foo');
        insert cam;

        CampaignMember campmem = new CampaignMember(ContactId = con.id, CampaignId = cam.id);
        insert campmem;

        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = con.id,
            CloseDate = system.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Amount = 8,
            CampaignId=cam.id,
            Primary_Contact_Campaign_Member_Status__c = 'foo'
        );

        test.startTest();
        insert opp;
        test.stopTest();

        list<campaignmember> querycm = [SELECT Id, Status FROM CampaignMember WHERE contactId=:con.id AND campaignId=:cam.id];
        system.assertEquals(1, querycm.size(), 'A campaign member should be created.');
        system.assertEquals('foo', querycm[0].Status, 'Campaign member be updated to our status.');

        list<campaignmemberstatus> querycms = [SELECT Id, IsDefault, HasResponded, Label, SortOrder FROM CampaignMemberStatus WHERE campaignid = :cam.id AND Label=:opp.Primary_Contact_Campaign_Member_Status__c];
        system.assertEquals(1, querycms.size(), 'A campaign member status should be created.');
        system.assertEquals(false, querycms[0].HasResponded, 'Status should be non-responded.');
    }

    /*********************************************************************************************************
    * @description Inserts a new closed/won opportunity with a primary campaign source for a contact with an
    * existing campaign member for that campaign. Verifies campaign member's status was updated.
    */
    @isTest static void updateStatus() {
        if (strTestOnly != '*' && strTestOnly != 'createMemberResponded') return;

        Contact con = new Contact(LastName='foo');
        insert con;

        Campaign cam = new Campaign(Name='foo');
        insert cam;

        CampaignMember campmem = new CampaignMember(ContactId = con.id, CampaignId = cam.id);
        insert campmem;

        list<campaignmember> querycm = [SELECT Id, HasResponded FROM CampaignMember WHERE contactId=:con.id AND campaignId=:cam.id];
        system.assertEquals(1, querycm.size(), 'A campaign member should be created.');
        system.assertEquals(false, querycm[0].HasResponded, 'Member should have a default non responded status.');

        insert new CampaignMemberStatus(campaignId = cam.id, Label = 'Responded', HasResponded = true, SortOrder = 6);

        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = con.id,
            CloseDate = system.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Amount = 8,
            CampaignId=cam.id
        );

        test.startTest();
        insert opp;
        test.stopTest();

        querycm = [SELECT Id, HasResponded FROM CampaignMember WHERE contactId=:con.id AND campaignId=:cam.id];
        system.assertEquals(1, querycm.size(), 'A campaign member should still exist.');
        system.assertEquals(true, querycm[0].HasResponded, 'Campaign member should be updated to a responded status.');
    }

    /*********************************************************************************************************
    * @description Inserts a new open opportunity with a primary campaign source. Verifies a campaign member 
    * is created and that the first non responded status was given.
    */
    @isTest static void createMemberNonResponded() {
        if (strTestOnly != '*' && strTestOnly != 'createMemberNonResponded') return;
        
        Contact con = new Contact(LastName='foo');
        insert con;

        Campaign cam = new Campaign(Name='foo');
        insert cam;

        list<CampaignMemberStatus> listStatusForInsert = new list<CampaignMemberStatus>();
        listStatusForInsert.add(new CampaignMemberStatus(campaignId = cam.id, Label = 'NonResponded', HasResponded = false, SortOrder = 5));
        listStatusForInsert.add(new CampaignMemberStatus(campaignId = cam.id, Label = 'Responded', HasResponded = true, SortOrder = 6));
        insert listStatusForInsert;

        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = con.id,
            CloseDate = system.today(),
            StageName = UTIL_UnitTestData_TEST.getOpenStage(),
            Amount = 8,
            CampaignId=cam.id
    	);
    	
    	test.startTest();
        insert opp;
        test.stopTest();
        
        list<campaignmember> querycm = [SELECT Id, Status, HasResponded FROM CampaignMember WHERE contactId=:con.id AND campaignId=:cam.id];
        system.assertEquals(1, querycm.size(), 'A campaign member should be created.');
        system.assertEquals(false, querycm[0].hasResponded, 'Campaign Member should show not responded.');
    }

    /*********************************************************************************************************
    * @description Inserts a new closed/won opportunity with a primary campaign source. Verifies a campaign member 
    * is created and that the first responded status was given.
    */
    @isTest static void createMemberResponded() {
        if (strTestOnly != '*' && strTestOnly != 'createMemberResponded') return;
        
        Contact con = new Contact(LastName='foo');
        insert con;

        Campaign cam = new Campaign(Name='foo');
        insert cam;

        list<CampaignMemberStatus> listStatusForInsert = new list<CampaignMemberStatus>();
        listStatusForInsert.add(new CampaignMemberStatus(campaignId = cam.id, Label = 'NonResponded', HasResponded = false, SortOrder = 5));
        listStatusForInsert.add(new CampaignMemberStatus(campaignId = cam.id, Label = 'Responded', HasResponded = true, SortOrder = 6));
        insert listStatusForInsert;

        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = con.id,
            CloseDate = system.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Amount = 8,
            CampaignId=cam.id
    	);
    	
    	test.startTest();
        insert opp;
        test.stopTest();
        
        list<campaignmember> querycm = [SELECT Id, Status, HasResponded FROM CampaignMember WHERE contactId=:con.id AND campaignId=:cam.id];
        system.assertEquals(1, querycm.size(), 'A campaign member should be created.');
        system.assertEquals(true, querycm[0].hasResponded, 'Campaign Member should show responded.');
    }

    /*********************************************************************************************************
    * @description Inserts a new opportunity for a contact with a primary campaign source, but using omit as a
    * member status. Verifies that a campaign member isn't created.
    */
    @isTest static void omitCampaignMember() {
        if (strTestOnly != '*' && strTestOnly != 'omitCampaignMember') return;

        Contact con = new Contact(LastName='foo');
        insert con;

        Campaign cam = new Campaign(Name='foo');
        insert cam;

        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = con.id,
            CloseDate = system.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Amount = 8,
            CampaignId=cam.id,
            Primary_Contact_Campaign_Member_Status__c = Label.CampaignMemberStatusOmit
        );

        test.startTest();
        insert opp;
        test.stopTest();

        list<campaignmember> querycm = [SELECT Id, Status FROM CampaignMember WHERE contactId=:con.id AND campaignId=:cam.id];
        system.assertEquals(0, querycm.size(), 'A campaign member shouldn\'t be created.');
    }

    /*********************************************************************************************************
    * @description Inserts 200 opportunities with a primary campaign source of two different campaigns, 
    * including open and closed/won opportunities, and two new statuses. Verifies statuses created, and 
    * campaign members created.
    */
    @isTest static void batchCreateMixedMembers() {
        if (strTestOnly != '*' && strTestOnly != 'batchCreateMixedMembers') return;

        integer batchSize = 200;

        Account acc = new Account(Name='foo');
        insert acc;

        list<Contact> listCon = new list<Contact>();
        for (integer i=0; i<batchSize; i++)
            listCon.add(new Contact(LastName='foo' + i, AccountId=acc.id));
        insert listCon;

        list<Campaign> listCam = new list<Campaign>();
        listCam.add(new Campaign(Name='foo1'));
        listCam.add(new Campaign(Name='foo2'));
        insert listCam;

        list<Opportunity> listOpp = new list<Opportunity>();
        for (integer i=0; i<batchSize; i++) {
            Opportunity opp = new Opportunity(
                Name = 'foo' + i,
                Primary_Contact__c = listcon[i].id,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                Amount = 8,
                //switch between the two campaigns
                CampaignId = listCam[math.mod(i,2)].id
            );

            //mark every tenth opportunity as closed/lost
            if (math.mod(i,10) == 0)
                opp.StageName = UTIL_UnitTestData_TEST.getClosedLostStage();

            //switch between a blank status and two different statuses
            if (math.mod(i,3) == 0)
                opp.Primary_Contact_Campaign_Member_Status__c = 'foo';
            else if (math.mod(i,3) == 1)
                opp.Primary_Contact_Campaign_Member_Status__c = 'bar';

            listOpp.add(opp);
        }

        test.startTest();
        insert listOpp;
        test.stopTest();

        list<campaignmember> querycm = [SELECT Id, Status FROM CampaignMember WHERE campaignId IN :listCam];
        system.assertEquals(batchSize, querycm.size(), batchSize + ' campaign members should be created.');

        list<campaignmemberstatus> querycms = [SELECT Id, IsDefault, HasResponded, Label, SortOrder FROM CampaignMemberStatus WHERE campaignid IN :listCam AND Label IN ('foo','bar')];
        system.assertEquals(4, querycms.size(), 'A campaign member status should be created for both campaigns.');
        system.assertEquals(false, querycms[0].HasResponded, 'Status should be non-responded.');
    }
}