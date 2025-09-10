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
* @author Team Kick Ass; Veronica Waters, Evan Callahan, Derek Dsouza, Mike Fullmore
* @date 04/27/2011
* @group BatchDataEntry
* @description test class for the batch data entry, supports all the custom settings you might have.
*/
@isTest
private class BDE_BatchEntry_TEST {

    /*******************************************************************************************************
    * @description load the batch data entry page for a new opportunity batch, save and validate the 
    * batch and batch items were saved
    */
    static testMethod void testBatchDataEntryController() {

        Test.setCurrentPageReference(new PageReference('Page.BDE_BatchEntry'));
        system.currentPageReference().getParameters().put('obj', 'Opportunity');
        BDE_BatchEntry_CTRL ctrl = new BDE_BatchEntry_CTRL(new ApexPages.standardController(new Batch__c() ));

    }
    /*******************************************************************************************************
    * @description load the batch data entry page for a new contact batch, save and reload the page with
    * the saved item
    */
    static testMethod void testBatchWithSave() {

        ApexPages.StandardController sc = new ApexPages.standardController( new Batch__c() );
        Test.setCurrentPage(Page.BDE_BatchEntry);
        ApexPages.currentPage().getParameters().put('obj', 'contact');
        BDE_BatchEntry_CTRL ext = new BDE_BatchEntry_CTRL(sc);
        ext.displayBatchSection = true;

    }
    /*******************************************************************************************************
    * @description load the batch data entry page for a new object
    */
    static testMethod void testNewObjectLoad(){
        ApexPages.StandardController sc = new ApexPages.standardController( new Batch__c() );
        Test.setCurrentPage(Page.BDE_BatchEntry);
        BDE_BatchEntry_CTRL ext = new BDE_BatchEntry_CTRL(sc);

        //exercise entry display
        ext.displayBatchSection = true;
    }
    /*******************************************************************************************************
    * @description load the batch data entry page with existing batches
    */
    static testMethod void testExistingBatchObjects(){

        Batch__c b1 = new Batch__c(Name='New Batch', Object_Name__c = 'opportunity', Batch_Status__c = 'In Progress');
        Batch__c b2 = new Batch__c(Name='New Batch', Object_Name__c = 'opportunity', Batch_Status__c = 'Complete');
        insert b1;
        insert b2;

        ApexPages.StandardController sc = new ApexPages.standardController(b1);
        Test.setCurrentPage(Page.BDE_BatchEntry);
        BDE_BatchEntry_CTRL ext = new BDE_BatchEntry_CTRL(sc);
        ext.batch = new Batch__c();
        ext.displayBatchSection = true;

    }
    /*******************************************************************************************************
    * @description load the batch data entry page for an opportunity with an opportunity contact role
    */
    static testMethod void testOtherConfig(){
        Batch__c b = new Batch__c(Name = 'Opp Batch', Object_Name__c = 'opportunity');
        insert b;
        Opportunity oppinbatch = new Opportunity(Name='MyTestOpp', CloseDate=system.today(), StageName='Closed Won', Batch__c = b.id);
        insert oppinbatch;
        Contact c = new Contact(Lastname = 'OCRLastName');
        insert c;
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityID = oppinbatch.id, ContactID = c.id);
        insert ocr;


        ApexPages.StandardController sc = new ApexPages.standardController(b);
        Test.setCurrentPage(Page.BDE_BatchEntry);
        BDE_BatchEntry_CTRL ext = new BDE_BatchEntry_CTRL(sc);
        ext.objname = 'opportunity';
        ext.displayBatchSection = true;
        ext.ocrlookup = new Map<id, OpportunityContactRole>();
        ext.ocrlookup.put(ocr.id, ocr);

    }

    @IsTest
    private static void shouldGetBatchDataEntrySettings () {
        Batch_Data_Entry_Settings__c settings = BDE_BatchEntry_CTRL.getBatchDataEntrySettings();
        System.assertNotEquals(settings, null, 'Batch Data Entry Setting should not be null');
    }

    @IsTest
    private static void shouldUpsertRetirementAlert () {
        BDE_BatchEntry_CTRL.upsertRetirementAlert(true);
        Batch_Data_Entry_Settings__c settings = Batch_Data_Entry_Settings__c.getValues(UserInfo.getUserId());
        System.assertEquals(settings.Viewed_Retirement_Alert__c, true, 'The retirement alert should be checked');
    }

}