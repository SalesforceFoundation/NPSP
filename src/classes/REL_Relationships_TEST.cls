/*
    Copyright (c) 2009, 2012, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2011,2012 
* @description Testing for the Relationships class
*/
@isTest
private class REL_Relationships_TEST {
	
	// if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    private static Contact c1;//male
    private static Contact c2;//female
    private static Contact c3;//unknown
    
    //helper for test methods
    private static void setupRelationshipTestData(npe4__Relationship_Settings__c rs){
        
        //set running user to avoid dml issue            
        System.runAs(new User(id = UserInfo.getUserId())){ 
        
            //remove any existing settings
            delete [select id from npe4__Relationship_Settings__c];
            if (rs != null)
                insert rs;
            else{
                rs = new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'List Setting', npe4__Gender_Field__c = 'Description');
                insert rs;           
            }
            
            //add autocreate settings for CMs 
            delete [select id from npe4__Relationship_Auto_Create__c];
            insert new npe4__Relationship_Auto_Create__c(Name='AutoCreate',npe4__Object__c='CampaignMember',
                                                    npe4__Field__c='ContactId',npe4__Relationship_Type__c = 'TestType',
                                                    npe4__Campaign_Types__c = 'Other;');    
            
            insert new npe4__Relationship_Auto_Create__c(Name='AutoCreate2',npe4__Object__c='Contact',
                                                    npe4__Field__c='ReportsToId',npe4__Relationship_Type__c = 'TestType');
            
            //add Reciprocal Relationship
            delete [select id from npe4__Relationship_Lookup__c];
            insert new npe4__Relationship_Lookup__c(Name='TestLookupType',npe4__Male__c='TestMaleType',
                                                npe4__Female__c='TestFemaleType',npe4__Neutral__c='TestNeutralType');
            insert new npe4__Relationship_Lookup__c(Name='TestLookupType2',npe4__Male__c='TestMaleType2',
                                                npe4__Female__c='TestFemaleType2',npe4__Neutral__c='TestNeutralType2',
                                                npe4__Active__c=false);                                
        
            c1 = new Contact(Salutation = 'Mr.', FirstName = 'Walter_Test', LastName = 'Roosevelt_Test');
            c2 = new Contact(Salutation = 'Mrs.', FirstName = 'Jane_Test', LastName = 'Nixon_Test');        
            c3 = new Contact(Salutation = 'Dr.', FirstName = 'Pat_Test', LastName = 'Cleveland_Test');
            insert new Contact[] {c1, c2, c3};
        }
    }
    
    /// <name> TestContactRel </name>
    /// <summary> test method for relationships and the mirroring </summary>
    static testMethod void testContactRel() {
    	if (strTestOnly != '*' && strTestOnly != 'testContactRel') return;
             
        setupRelationshipTestData(null);     
      
        npe4__Relationship__c rel = new npe4__Relationship__c(
              npe4__contact__c = c1.id, 
              npe4__relatedcontact__c = c2.id, 
              npe4__Type__c='Friend',
              npe4__Status__c='Active',
              npe4__Description__c='notes');
        insert rel;
        
        // check that rel gets created
        List<npe4__Relationship__c> relList = [select id,npe4__contact__c,npe4__Relatedcontact__c,npe4__Status__c,
                                          npe4__Type__c, npe4__ReciprocalRelationship__c
                                          from npe4__Relationship__c where Id= :rel.Id limit 1];
        // check for mirror rel
        List<npe4__Relationship__c> mirrorList = [select id,npe4__contact__c,npe4__Relatedcontact__c,npe4__Status__c,
                                              npe4__Type__c,npe4__ReciprocalRelationship__c  
                                              from npe4__Relationship__c where npe4__ReciprocalRelationship__c=:relList[0].Id limit 1];
        
        
        //reference eachother
        System.assertEquals(relList[0].npe4__ReciprocalRelationship__c, mirrorList[0].Id);
        System.assertEquals(mirrorList[0].npe4__ReciprocalRelationship__c, relList[0].Id);

        //same types
        System.assertEquals(mirrorList[0].npe4__Type__c, 'Friend');
        System.assertEquals(relList[0].npe4__Type__c, 'Friend');  
        
        // test changing the relationship
        relList[0].npe4__Type__c = 'Colleague';
        relList[0].npe4__Description__c = 'test desc';        
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        update relList[0];
        Test.stopTest();        
        
        // test change to the rel
        npe4__Relationship__c updated_original = [select id, npe4__Description__c, npe4__Type__c,npe4__ReciprocalRelationship__c 
                                              from npe4__Relationship__c where id = :relList[0].Id limit 1];
                                              
        //original should have updated relationship
        System.assertEquals('Colleague', updated_original.npe4__Type__c);
        //original should have updated notes
        System.assertEquals('test desc', updated_original.npe4__Description__c);
        
        npe4__Relationship__c updated_mirror = [select id, npe4__Type__c, npe4__Description__c, npe4__ReciprocalRelationship__c
                                              from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :relList[0].Id limit 1];
        //mirror should have relationship set right
        System.assertEquals('Colleague', updated_mirror.npe4__Type__c);   
        //mirror should have updated notes
        System.assertEquals('test desc', updated_mirror.npe4__Description__c);
    
        // test deleting the rel
        delete updated_original;
        npe4__Relationship__c[] mirror_after_original_deleted = [select id 
                                                           from npe4__Relationship__c 
                                                           where npe4__ReciprocalRelationship__c = :rel.Id];
        //mirror should be deleted as well
        System.assertEquals(0, mirror_after_original_deleted.size());
    }
    /// <name> TestOrphanedRelDelete </name>
    /// <summary> test method for relationships and deleting the mirror record </summary>
    static testMethod void testOrphanedRelDelete() {
    	if (strTestOnly != '*' && strTestOnly != 'testOrphanedRelDelete') return;
    	    
        setupRelationshipTestData(null);

        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='Buddies')
        };
        insert crel;
        
        // check that rel gets created
        npe4__Relationship__c crel_original = [select id, npe4__Description__c,npe4__Type__c,npe4__reciprocalrelationship__c from npe4__Relationship__c where id=:crel[0].Id];
        //relationship should be set right
        System.assertEquals(crel_original.npe4__Type__c, 'Buddies');

        // check for mirror rel
        npe4__Relationship__c crel_mirror = [select id, npe4__Description__c, npe4__reciprocalrelationship__c, npe4__Type__c from npe4__Relationship__c where npe4__reciprocalrelationship__c=:crel_original.Id];
        //mirror should reference the original
        System.assertEquals(crel_mirror.npe4__reciprocalrelationship__c, crel_original.Id);
        Contact secondContactForDelete = [select id from contact where id=:c2.id];
        Test.startTest();
        delete secondContactForDelete;
        Test.stopTest();
        // test change to the rel
        npe4__Relationship__c[] orphanedCrel = [select id from npe4__Relationship__c where id = :crel_original.Id];
        //original should have updated relationship
        System.assertEquals(0, orphanedCrel.size());
    }
    
    //deleting the original should delete the reciprocal
    static testMethod void testRelationshipDelete(){
    	if (strTestOnly != '*' && strTestOnly != 'testRelationshipDelete') return;
    	
        setupRelationshipTestData(null);
        npe4__Relationship__c crel_original = new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, 
                                                                npe4__Type__c='Buddies');
        insert crel_original;
        
        crel_original = [select id, npe4__Description__c, npe4__reciprocalrelationship__c, npe4__Type__c 
                                            from npe4__Relationship__c where Id=:crel_original.Id];
        System.debug('****Original relationship: ' + crel_original);

        // check mirror rel got created
        npe4__Relationship__c crel_mirror = [select id, npe4__Description__c, npe4__reciprocalrelationship__c, npe4__Type__c 
                                            from npe4__Relationship__c where npe4__reciprocalrelationship__c=:crel_original.Id];

        System.debug('****Mirror relationship: ' + crel_mirror);
                                        
        //mirror should reference the original
        System.assertEquals(crel_original.Id, crel_mirror.npe4__reciprocalrelationship__c);        
        
        //original should reference mirror
        System.assertEquals(crel_mirror.Id, crel_original.npe4__reciprocalrelationship__c);  
        System.debug('***Original successfully references mirror');
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        delete crel_original;
        Test.stopTest();        
        system.assertEquals(0, [select count() from npe4__Relationship__c where id = :crel_mirror.id]);
    }
    
    static testMethod void testAutoCreateCampaignMemberInsert(){
    	if (strTestOnly != '*' && strTestOnly != 'testAutoCreateCampaignMemberInsert') return;
    	
        setupRelationshipTestData(null);
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //Insert a campaign
        Campaign campaign = new Campaign(Name='TestCampaign', isActive=true, Type='Other');
        insert campaign;
        
        //Insert a campaign member
        CampaignMember cm = new CampaignMember(ContactId = c2.id, CampaignId = campaign.id);
        Test.startTest();        
        insert cm;
        Test.stopTest();
        
        //Verify a relationship was automatically created when the campaign member was created 
        List<npe4__Relationship__c> relationships = [select id, npe4__Type__c from npe4__Relationship__c 
                                        where npe4__Contact__c = :c2.id];
        System.debug('****Number of relationships after creating campaign member: ' + relationships.size());
        system.assertEquals(2, relationships.size());
        system.assertEquals('TestType', relationships[0].npe4__Type__c);
        
        //Verify a reciprocal relationship was also automatically created when the campaign member was created 
        List<npe4__Relationship__c> reciprocalRelationships = [select id, npe4__Type__c from npe4__Relationship__c 
                                        where npe4__ReciprocalRelationship__c = :relationships[0].id];
        System.debug('****Number of reciprocal relationships: ' + reciprocalRelationships);
        system.assertEquals(1, reciprocalRelationships.size());
        system.assertEquals('TestType', reciprocalRelationships[0].npe4__Type__c);
        
    }  
     
    //test the synchronous process as well
    static testMethod void testAutoCreateCampaignMemberInsertSynch(){
    	if (strTestOnly != '*' && strTestOnly != 'testAutoCreateCampaignMemberInsertSynch') return;
    	
        setupRelationshipTestData(new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'List Setting', npe4__Force_Synchronous_Auto_Create__c = true));
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a campaignmember
        Campaign c = new Campaign(Name='TestCampaign', isActive=true, Type='Other');
        insert c;
        CampaignMember cm = new CampaignMember(ContactId = c2.id, CampaignId = c.id);
        
        Test.startTest();        
        insert cm;
        Test.stopTest();
         
        npe4__Relationship__c rel = [select id, npe4__Type__c from npe4__Relationship__c where npe4__Contact__c = :c2.id limit 1];
        system.assertEquals('TestType', rel.npe4__Type__c);
        npe4__Relationship__c recRel = [select id, npe4__Type__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :rel.id];
        system.assertEquals('TestType', recRel.npe4__Type__c);
    }
    
    //can't do a true test as ContactId is not updatable, but we'll hit the update for coverage
    static testMethod void testAutoCreateCampaignMemberUpdate(){
    	if (strTestOnly != '*' && strTestOnly != 'testAutoCreateCampaignMemberUpdate') return;
    	
        setupRelationshipTestData(null);        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        //insert a campaignmember
        Campaign c = new Campaign(Name='TestCampaign', isActive=true);
        insert c;
        CampaignMember cm = new CampaignMember(ContactId = c2.id, CampaignId = c.id);
        insert cm;        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        //do an update and check that a second relationship set is created for the new Contact
        cm.Status = 'SomethingDifferentForUpdate';        
        Test.startTest();        
        update cm;
        Test.stopTest();        
    }
    static testMethod void testAutoCreateContactInsert(){
    	if (strTestOnly != '*' && strTestOnly != 'testAutoCreateContactInsert') return;
    	
        setupRelationshipTestData(null);
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a new Contact
        Contact c = new Contact(LastName='ReportingIn', ReportsToId = c1.id);        
        
        Test.startTest();        
        insert c;
        Test.stopTest();
         
        npe4__Relationship__c rel = [select id, npe4__Type__c, npe4__RelatedContact__c from npe4__Relationship__c where npe4__Contact__c = :c.id limit 1];
        system.assertEquals('TestType', rel.npe4__Type__c);
        system.assertEquals(c1.id, rel.npe4__RelatedContact__c);
        
        npe4__Relationship__c recRel = [select id, npe4__Type__c, npe4__RelatedContact__c, npe4__Contact__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :rel.id];
        system.assertEquals('TestType', recRel.npe4__Type__c);
        system.assertEquals(c.id, recRel.npe4__RelatedContact__c);
    }
    
    static testMethod void testAutoCreateContactInsertSynch(){
    	if (strTestOnly != '*' && strTestOnly != 'testAutoCreateContactInsertSynch') return;
    	
        setupRelationshipTestData(new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'List Setting', npe4__Force_Synchronous_Auto_Create__c = true));
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a new Contact
        Contact c = new Contact(LastName='ReportingIn', ReportsToId = c1.id);        
        
        Test.startTest();        
        insert c;
        Test.stopTest();
         
        npe4__Relationship__c rel = [select id, npe4__Type__c, npe4__RelatedContact__c from npe4__Relationship__c where npe4__Contact__c = :c.id limit 1];
        system.assertEquals('TestType', rel.npe4__Type__c);
        system.assertEquals(c1.id, rel.npe4__RelatedContact__c);
        
        npe4__Relationship__c recRel = [select id, npe4__Type__c, npe4__RelatedContact__c, npe4__Contact__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :rel.id];
        system.assertEquals('TestType', recRel.npe4__Type__c);
        system.assertEquals(c.id, recRel.npe4__RelatedContact__c);
    }
    
    static testMethod void testAutoCreateContactUpdate(){
    	if (strTestOnly != '*' && strTestOnly != 'testAutoCreateContactUpdate') return;
    	
        setupRelationshipTestData(null);
        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        //insert a new Contact
        Contact c = new Contact(LastName='ReportingIn', ReportsToId = c1.id);        
        insert c;
        //Relationships_ProcessControl.hasRun = false;
        c.ReportsToId = c2.id;
        
        Test.startTest();        
        update c;
        Test.stopTest();
         
        npe4__Relationship__c rel = [select id, npe4__Type__c, npe4__RelatedContact__c from npe4__Relationship__c where npe4__Contact__c = :c.id and npe4__RelatedContact__c = :c2.id limit 1];
        system.assertEquals('TestType', rel.npe4__Type__c);
        system.assertEquals(c2.id, rel.npe4__RelatedContact__c);
    }
    
    static testMethod void testInversionSettingsHaveType(){
    	if (strTestOnly != '*' && strTestOnly != 'testInversionSettingsHaveType') return;
    	
        setupRelationshipTestData(new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'Value Inversion'));
        
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='Buddies-Friends')
        };
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        insert crel;
        Test.stopTest();
        
        // check that rel gets created
        npe4__Relationship__c crel_original = [select id, npe4__Description__c,npe4__Type__c,npe4__reciprocalrelationship__c from npe4__Relationship__c where id=:crel[0].Id];
        //relationship should be set right
        system.assertEquals(crel_original.npe4__Type__c, 'Buddies-Friends');

        // check for mirror rel
        npe4__Relationship__c crel_mirror = [select id, npe4__Description__c, npe4__reciprocalrelationship__c, npe4__Type__c from npe4__Relationship__c where npe4__reciprocalrelationship__c=:crel_original.Id];
        //mirror should reference the original
        system.assertEquals(crel_mirror.npe4__reciprocalrelationship__c, crel_original.Id);
        system.assertEquals('Friends-Buddies', crel_mirror.npe4__Type__c);        
    }
    
    static testMethod void testInversionSettingsNoType(){
    	if (strTestOnly != '*' && strTestOnly != 'testInversionSettingsNoType') return;
    	
        setupRelationshipTestData(new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'Value Inversion'));
        
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='BuddiesFriends')
        };
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        insert crel;
        Test.stopTest();
        
        // check that rel gets created
        npe4__Relationship__c crel_original = [select id, npe4__Description__c,npe4__Type__c,npe4__reciprocalrelationship__c from npe4__Relationship__c where id=:crel[0].Id];
        //relationship should be set right
        system.assertEquals(crel_original.npe4__Type__c, 'BuddiesFriends');

        // check for mirror rel
        npe4__Relationship__c crel_mirror = [select id, npe4__Description__c, npe4__reciprocalrelationship__c, npe4__Type__c from npe4__Relationship__c where npe4__reciprocalrelationship__c=:crel_original.Id];
        //mirror should reference the original
        system.assertEquals(crel_mirror.npe4__reciprocalrelationship__c, crel_original.Id);
        system.assertEquals('BuddiesFriends', crel_mirror.npe4__Type__c);
    }
    
    static testMethod void testNoValidSettingsConfig(){
    	if (strTestOnly != '*' && strTestOnly != 'testNoValidSettingsConfig') return;
    	
        setupRelationshipTestData(new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'BAD_VALUE'));
        
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='BuddiesFriends')
        };
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;
        
        Test.startTest();
        insert crel;
        Test.stopTest();
        
        // check that rel gets created
        npe4__Relationship__c crel_original = [select id, npe4__Description__c,npe4__Type__c,npe4__reciprocalrelationship__c from npe4__Relationship__c where id=:crel[0].Id];
        //relationship should be set right
        system.assertEquals(crel_original.npe4__Type__c, 'BuddiesFriends');

        // check for mirror rel
        npe4__Relationship__c crel_mirror = [select id, npe4__Description__c, npe4__reciprocalrelationship__c, npe4__Type__c from npe4__Relationship__c where npe4__reciprocalrelationship__c=:crel_original.Id];
        //mirror should reference the original
        system.assertEquals(crel_mirror.npe4__reciprocalrelationship__c, crel_original.Id);
        system.assertEquals('BuddiesFriends', crel_mirror.npe4__Type__c);
    }
    
    static testMethod void testMaleSalutationReciprocal(){
    	if (strTestOnly != '*' && strTestOnly != 'testMaleSalutationReciprocal') return;
    	
        setupRelationshipTestData(null);
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='TestLookupType')
        };        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;      
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        npe4__Relationship__c recRel = [select id, npe4__Type__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestMaleType', recRel.npe4__Type__c);
    }
    
    static testMethod void testFemaleSalutationReciprocal(){
    	if (strTestOnly != '*' && strTestOnly != 'testFemaleSalutationReciprocal') return;
    	
        setupRelationshipTestData(null);
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c2.id, npe4__Relatedcontact__c = c1.id, npe4__Type__c='TestLookupType')
        };        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        npe4__Relationship__c recRel = [select id, npe4__Type__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestFemaleType', recRel.npe4__Type__c);
    }
    
    static testMethod void testNeutralSalutationReciprocal(){
    	if (strTestOnly != '*' && strTestOnly != 'testNeutralSalutationReciprocal') return;
    	
        setupRelationshipTestData(null);
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c3.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='TestLookupType')
        };        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        npe4__Relationship__c recRel = [select id, npe4__Type__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestNeutralType', recRel.npe4__Type__c);
    }
    
    static testMethod void testNeutralGenderFieldReciprocal(){
    	if (strTestOnly != '*' && strTestOnly != 'testNeutralGenderFieldReciprocal') return;
    	
        setupRelationshipTestData(new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'List Setting', npe4__Gender_Field__c = 'Description'));
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c3.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='TestLookupType')
        };                
        c3.Description = 'Neutral';
        update c3;
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        npe4__Relationship__c recRel = [select id, npe4__Type__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestNeutralType', recRel.npe4__Type__c);
    }
    
    static testMethod void testMaleGenderFieldReciprocal(){
    	if (strTestOnly != '*' && strTestOnly != 'testMaleGenderFieldReciprocal') return;
    	
        setupRelationshipTestData(new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'List Setting', npe4__Gender_Field__c = 'Description'));
        c1.Description = 'Male';
        update c1;
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='TestLookupType')
        };        
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        npe4__Relationship__c recRel = [select id, npe4__Type__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestMaleType', recRel.npe4__Type__c);
    }
    
    static testMethod void testFemaleGenderFieldReciprocal(){
    	if (strTestOnly != '*' && strTestOnly != 'testFemaleGenderFieldReciprocal') return;
    	
        setupRelationshipTestData(new npe4__Relationship_Settings__c(npe4__Reciprocal_Method__c = 'List Setting', npe4__Gender_Field__c = 'Description'));
        c2.Description = 'Female';
        update c2;
        
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c2.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='TestLookupType')
        };
        //reset the process controller to mimic a second user action
        //Relationships_ProcessControl.hasRun = false;        
        
        Test.startTest();
        insert crel;
        Test.stopTest();      
        
        npe4__Relationship__c recRel = [select id, npe4__Type__c from npe4__Relationship__c where npe4__ReciprocalRelationship__c = :crel[0].id];
        system.assertEquals('TestFemaleType', recRel.npe4__Type__c);
    }
    
    static testMethod void testErrorRecordCreation(){
    	if (strTestOnly != '*' && strTestOnly != 'testErrorRecordCreation') return;
    	
        setupRelationshipTestData(null);
        npe4__Relationship__c[] relationships = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c2.id, npe4__Type__c='TestLookupType')
        };
        Database.SaveResult[] insertResults = Database.insert(relationships, false);
        //assert an error - Required fields are missing: [npe4__Contact__c]
        system.assertEquals(1, [select count() from Error__c]);
        
        //update relationship - this will create the missing npe4__Contact__c field
        relationships[0].npe4__RelatedContact__c = c1.id;
        Database.SaveResult[] updateResults = Database.update(relationships, false);
        System.debug('****npe4__Contact__c field: ' + relationships[0].npe4__Contact__c);
        
        //process error
        ERR_Handler errorHandler = new ERR_Handler();
        errorHandler.processResults(null, updateResults, null, null, 
                                    null, (List<SObject>)relationships, null, null);
        System.debug(LoggingLevel.WARN, '****Relationships record: ' + relationships[0]);
        //no additional error was created on update
        system.assertEquals(1, [select count() from Error__c]);
    }
    
    static testMethod void testExceptionRecordCreation(){
    	if (strTestOnly != '*' && strTestOnly != 'testExceptionRecordCreation') return;
    	
        setupRelationshipTestData(null);
        
        try{
            throw new MyException('TestException');
        }
        catch(Exception e){
            Error__c er = ERR_Handler.createError(e);
            system.assertEquals('TestException', er.Full_Message__c);
        }       
    }
    
    static testMethod void testAutoCreateDupePrevention(){
    	if (strTestOnly != '*' && strTestOnly != 'testAutoCreateDupePrevention') return;
    	
        setupRelationshipTestData(null);
        
        npe4__Relationship__c[] crel = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='TestType')
        };
        crel.add(new npe4__Relationship__c(npe4__contact__c = c1.id, npe4__Relatedcontact__c = c2.id, npe4__Type__c='TestType2'));
        insert crel;
        
        //update the ReportsToId to trigger autocreation 
        c1.ReportsToId = c2.id;
        //Relationships_ProcessControl.hasRun = false;
                
        Test.startTest();        
        update c1;
        Test.stopTest();
        
        //assert we only have one relationship since we've deduped the auto-created one   
        npe4__Relationship__c[] rel = [select id, npe4__Type__c, npe4__RelatedContact__c from npe4__Relationship__c where npe4__Contact__c = :c1.id and npe4__Type__c = 'TestType'];
        system.assertEquals('TestType', rel[0].npe4__Type__c);
        system.assertEquals(rel.size(), 1);     
    }
    
    static testMethod void testRelationshipUTILS(){
    	if (strTestOnly != '*' && strTestOnly != 'testRelationshipUTILS') return;
    	
        //to test the Relationship_Utils class      
        System.runAs(new User(id = UserInfo.getUserId())){ 
           delete [select id from npe4__Relationship_Settings__c];
           npe4__Relationship_Settings__c rs = REL_Utils.getRelationshipSettings();
           Boolean cAuto = REL_Utils.hasContactAutoCreate;
           Boolean cmAuto = REL_Utils.hasCMAutoCreate;
        }
    }  
    
    static testmethod void test2Rels1Transaction_v2() {
    	if (strTestOnly != '*' && strTestOnly != 'test2Rels1Transaction_v2') return;
    	
         // Create three contacts
        Contact mainClient = new Contact(FirstName='Main',LastName='AAAClient');
        Contact friend = new Contact(FirstName='Test',LastName='AAAFriend');
        Contact coworker = new Contact(FirstName='Test',LastName='AAACoworker');
        insert new Contact[] {mainClient, friend, coworker};
        
        // Create two relationships
        npe4__Relationship__c r1 = new npe4__Relationship__c(npe4__Contact__c=mainClient.Id, npe4__RelatedContact__c=friend.Id, npe4__Type__c='Friend');
        npe4__Relationship__c r2 = new npe4__Relationship__c(npe4__Contact__c=mainClient.Id, npe4__RelatedContact__c=coworker.Id, npe4__Type__c='Coworker');
        
        Test.startTest();
        insert new npe4__Relationship__c[] {r1, r2};
        Test.stopTest();
        
        npe4__Relationship__c nr = [select id, npe4__ReciprocalRelationship__c from npe4__Relationship__c where Id = :r1.id];      
        system.assert(nr.npe4__ReciprocalRelationship__c != null);        
               
        npe4__Relationship__c nr2 = [select id, npe4__ReciprocalRelationship__c from npe4__Relationship__c where Id = :r2.id];
        system.assert(nr2.npe4__ReciprocalRelationship__c != null);       
        
        list<npe4__Relationship__c> rels = new list<npe4__Relationship__c>(); 
        rels.add(new npe4__Relationship__c(npe4__Contact__c=mainClient.Id,npe4__RelatedContact__c=friend.Id,npe4__Type__c='Friend2'));
        rels.add(new npe4__Relationship__c(npe4__Contact__c=mainClient.Id,npe4__RelatedContact__c=coworker.Id,npe4__Type__c='Coworker2'));
        insert rels;
        list<npe4__Relationship__c> rels2 = [select id, npe4__ReciprocalRelationship__c from npe4__Relationship__c where Id = :rels[0].Id or Id = :rels[1].Id];
        system.assertEquals(2, rels2.size());
        system.assert(rels2[0].npe4__ReciprocalRelationship__c != null);      
        system.assert(rels2[1].npe4__ReciprocalRelationship__c != null);     
        
    }  
  
    public class MyException extends Exception{}
  
    // from REL_RelationshipsViewer_CTRL
    public static testMethod void RelationshipsViewer_TEST(){
    	if (strTestOnly != '*' && strTestOnly != 'RelationshipsViewer_TEST') return;
    	
        //set running user to avoid dml issue            
        System.runAs(new User(id = UserInfo.getUserId())){ 
            //insert two contacts
            c1 = new Contact(LastName = 'Testy');
            insert c1;
            c2 = new Contact(LastName = 'McTester');
            insert c2;
            //create a relationship between them
            npe4__Relationship__c rel = new npe4__Relationship__c(
                  npe4__contact__c = c1.id, 
                  npe4__relatedcontact__c = c2.id, 
                  npe4__Type__c='Friend',
                  npe4__Status__c='Active',
                  npe4__Description__c='notes');
            insert rel;
            //list to hold nodes
            List<REL_RelationshipsViewer_CTRL.Node> nodeList = new List<REL_RelationshipsViewer_CTRL.Node>();
            
            ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c1);
            REL_RelationshipsViewer_CTRL rvc = new REL_RelationshipsViewer_CTRL(sc);
            
            //call the remote static method to get the node list
            nodeList = REL_RelationshipsViewer_CTRL.getRelationships(c1.id, true, null);
            
            //check that a base node (contact) and the related contact are in the node list
            system.assertEquals(2, nodeList.size());
            system.assertEquals('Testy', nodeList[0].LastName);
            system.assertEquals('McTester', nodeList[1].LastName);     
            List<String> sList = new List<String>();
            sList.add('01r80000000Gty5');     
            nodeList = REL_RelationshipsViewer_CTRL.getRelationships(c1.id, false, sList);
            REL_RelationshipsViewer_CTRL.RelationshipInfo ri = REL_RelationshipsViewer_CTRL.getRelationshipInfo();
            system.assertNotEquals(null, ri);                       
        }
    }

    /*** TEST METHODS from STTG_Relationships_CTRL ***/
    static testMethod void STTG_Relationships_CTRL_TEST(){
        if (strTestOnly != '*' && strTestOnly != 'STTG_Relationships_CTRL_TEST') return;
        
        //test auto relationship creation
        npe4__Relationship_Auto_Create__c newAC = new npe4__Relationship_Auto_Create__c(Name = 'TESTACAUTO', npe4__Object__c = 'Contact', npe4__Field__c = 'Description', npe4__Relationship_Type__c = 'NewType', npe4__Campaign_Types__c = 'Other;');
        insert newAC;
        
        //test relationship lookup creation
        npe4__Relationship_Lookup__c newRL = new npe4__Relationship_Lookup__c(Name='TESTRL', npe4__Male__c='Male', npe4__Female__c='Female', npe4__Neutral__c='Neutral');
        insert newRL;
        //insert an error so the controller posts a message
        npe4__Relationship_Error__c re = new npe4__Relationship_Error__c(
           npe4__Error_Type__c = 'MyType',
           npe4__Error_Date_Time__c = system.now(),
           npe4__Full_Error_Message__c = 'FullTextErrorMessage'
        );
        insert re;
        
        //create a new instance of the controller
        STTG_Relationships_CTRL rsCTRL = new STTG_Relationships_CTRL();
        rsCTRL.getSettingsFirstTime();
        system.assertNotEquals(null, rsCTRL.relSettings);
        system.assertNotEquals(null, rsCTRL.relACMap);
        system.assertNotEquals(null, rsCTRL.relLookupMap);
        system.assertEquals('general_settings', rsCTRL.active_tab);
        
        //test behavior of uncovered getters
        List<SelectOption> genderList;
        genderList = rsCTRL.genderFieldOptions;
        system.assertEquals('-None-', genderList[0].getLabel());        
        
        //test auto relationship behavior
        system.assert(rsCTRL.relACMap.keySet().size() > 0);
        system.assert(rsCTRL.relAutoCreateList.size() == rsCTRL.relACMap.keySet().size());
        rsCTRL.selectedACName = 'TESTACAUTO';
        rsCTRL.editAC();
        system.assertEquals('TESTACAUTO', rsCTRL.activeAC.Name);
        rsCTRL.activeAC.Name = 'TESTACAUTO2';           
        rsCTRL.saveAC();
        system.assert(rsCTRL.relACMap.keySet().size() > 0);
        system.assert(rsCTRL.relACMap.containsKey('TESTACAUTO2'));
        List<SelectOption> acList;
        acList = rsCTRL.ACFieldOptions;
        system.assertEquals('-None-', acList[0].getLabel());    
        
        rsCTRL.selectedACName = 'TESTACAUTO2';
        rsCTRL.deleteAC();
        system.assert(!rsCTRL.relACMap.containsKey('TESTACAUTO2'));
        rsCTRL.addAC();
        rsCTRL.cTypeOptions = new List<String>{'Other', 'Email'};
        rsCTRL.activeAC.npe4__Object__c = 'CampaignMember';
        rsCTRL.activeAC.npe4__Field__c = 'npe4__TestField__c';
        rsCTRL.activeAC.npe4__Relationship_Type__c = 'Whatever';
        rsCTRL.saveAC();
        system.assert(rsCTRL.relACMap.keySet().size() > 0);     
        acList = rsCTRL.ACFieldOptions;
        system.assertEquals('-None-', acList[0].getLabel());
        
        //test relationships lookup behavior
        system.assert(rsCTRL.relLookupMap.keySet().size() > 0);
        system.assert(rsCTRL.setCon.getResultSize() == rsCTRL.relLookupMap.keySet().size());
        rsCTRL.selectedRLName = 'TESTRL';
        rsCTRL.editLookup();
        system.assertEquals('TESTRL', rsCTRL.activeRL.Name);
        rsCTRL.activeRL.Name = 'TESTRL2';
        rsCTRL.saveLookup();
        system.assert(rsCTRL.relLookupMap.keySet().size() > 0);
        system.assert(rsCTRL.relLookupMap.containsKey('TESTRL2'));
        system.assert(rsCTRL.relLookupList.size() > 0);
        rsCTRL.addLookup();
        rsCTRL.activeRL.Name = 'TESTRLName3';
        rsCTRL.activeRL.npe4__Male__c = 'Male';
        rsCTRL.activeRL.npe4__Female__c = 'Female';
        rsCTRL.activeRL.npe4__Neutral__c = 'Neutral';
        rsCTRL.saveLookup();
        system.assert(rsCTRL.relLookupMap.containsKey('TESTRLName3'));           
        rsCTRL.selectedRLName = 'TESTRLName3';
        rsCTRL.deleteLookup();  
        system.assert(!rsCTRL.relLookupMap.containsKey('TESTRLName3'));
        rsCTRL.activeRL = rsCTRL.relLookupMap.get('TESTRL');
        rsCTRL.cancel();
        system.assertNotEquals('TESTRL', rsCTRL.activeRL.Name);
        
        //use the getter
        Integer i = rsCTRL.pageCountRL;
        List<SelectOption> campaignOptionList = rsCTRL.ACCampaignTypeOptions;
        
        //other methods for coverage
        rsCTRL.deleteErrors();
        rsCTRL.saveGeneralSettings();
        rsCTRL.editGeneralSettings();       
    }
    
    static testmethod void testSettingsObjectWithJustOrgDefaults() {
    	if (strTestOnly != '*' && strTestOnly != 'testSettingsObjectWithJustOrgDefaults') return;
    	
        npe4__Relationship_Settings__c newRS;
        newRS = npe4__Relationship_Settings__c.getOrgDefaults();
        system.assertNotEquals(null, newRS);
        system.assertEquals(null, newRS.Id);   
        system.assertEquals(null, newRS.npe4__Reciprocal_Method__c);  
        newRS.npe4__Reciprocal_Method__c = 'List Settings';
        insert newRS;
        system.assertNotEquals(null, newRS.Id);
        
        //create a new instance of the controller
        STTG_Relationships_CTRL rsCTRL = new STTG_Relationships_CTRL();
        rsCTRL.getSettingsFirstTime();
        system.assertNotEquals(null, rsCTRL.relSettings);
        system.assertNotEquals(null, rsCtrl.relSettings.Id);    
    }
}