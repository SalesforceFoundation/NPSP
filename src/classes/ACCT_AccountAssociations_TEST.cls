/*
    Copyright (c) 2015, Salesforce.com Foundation
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
* @date 2015
* @description Testing for the ACCT_AccountAssociations class
*/
@isTest
private class ACCT_AccountAssociations_TEST {
    
    private static Account a1;
    private static Account a2;
    private static Account a3;
    
    /*********************************************************************************************************
    * @description Helper for test methods, creates 2 accounts
    */
    private static void setupAccountTestData(){
        a1 = new Account(Name = 'Org 1');
        a2 = new Account(Name = 'Org 2');
        a3 = new Account(Name = 'Org 3');
        insert new Account[] {a1, a2, a3};
    }
    
    /*********************************************************************************************************
    * @description Tests create/update/delete of reciprocal Account Association
    */
    static testMethod void testAccountAssociation() {
        setupAccountTestData();
      
        Account_Association__c aa = new Account_Association__c(
        	Account__c = a1.Id,
        	Associated_Account__c = a2.Id,
        	Description__c = 'notes',
        	Type__c = 'Partner',
        	Status__c = 'Current');
        insert aa;
        
        // get forward association that we inserted
        Account_Association__c forward = [select Id, Associated_Account__c, Status__c,
        	Type__c, Reciprocal_Association__c
        	from Account_Association__c where Id=:aa.Id];
        // get mirror association
        Account_Association__c backward = [select Id, Associated_Account__c, Status__c,
            Type__c, Reciprocal_Association__c
            from Account_Association__c where Reciprocal_Association__c=:forward.Id];
        
        // should reference eachother
        System.assertEquals(forward.Reciprocal_Association__c, backward.Id);
        System.assertEquals(backward.Reciprocal_Association__c, forward.Id);

        // same types
        System.assertEquals(forward.Type__c, 'Partner');
        System.assertEquals(backward.Type__c, 'Partner');
        
        // test updating the association
        forward.Status__c = 'Former';
        update forward;

        // make sure change was propagated to the mirror
		forward = [select Id, Associated_Account__c, Status__c,
		    Type__c, Reciprocal_Association__c
		    from Account_Association__c where Id=:aa.Id];                                              
		backward = [select Id, Associated_Account__c, Status__c,
            Type__c, Reciprocal_Association__c
            from Account_Association__c where Reciprocal_Association__c=:forward.Id];
        System.assertEquals('Former', forward.Status__c);        
        System.assertEquals('Former', backward.Status__c);
    
        // test deleting the rel
        delete forward;
        list<Account_Association__c> mirror = [select Id from Account_Association__c where Reciprocal_Association__c = :aa.Id];
        System.assertEquals(0, mirror.size());
    }

    /*********************************************************************************************************
    * @description Tests that reparenting an Account Association updates the mirror
    */
    static testMethod void testAccountAssociationReparenting() {
        setupAccountTestData();

        // add association between account 1 and 2
        Account_Association__c aa = new Account_Association__c(
        	Account__c = a1.Id,
        	Associated_Account__c = a2.Id);
        insert aa;

        // change originating account to account 3
        aa.Account__c = a3.Id;
        update aa;

        // make sure mirror was updated
        Account_Association__c forward = [select Id, Account__c from Account_Association__c where Id=:aa.Id];
        Account_Association__c backward = [select Id, Associated_Account__c from Account_Association__c where Reciprocal_Association__c=:aa.Id];
        System.assertEquals(a3.Id, forward.Account__c);
        System.assertEquals(a3.Id, backward.Associated_Account__c);

        // change associated account to account 1
        aa.Associated_Account__c = a1.Id;
        update aa;

        // make sure mirror was updated
        forward = [select Id, Associated_Account__c from Account_Association__c where Id=:aa.Id];
        backward = [select Id, Account__c from Account_Association__c where Reciprocal_Association__c=:aa.Id];
        System.assertEquals(a1.Id, forward.Associated_Account__c);
        System.assertEquals(a1.Id, backward.Account__c);
    }

    /*********************************************************************************************************
    * @description Tests that deleting an Account deletes related Account Associations
    */
    static testMethod void testAccountDeletion() {
    	setupAccountTestData();

    	Account_Association__c aa1 = new Account_Association__c(
    		Account__c = a1.Id,
    		Associated_Account__c = a2.Id);
    	Account_Association__c aa2 = new Account_Association__c(
    		Account__c = a2.Id,
    		Associated_Account__c = a3.Id);
    	insert new Account_Association__c[] {aa1, aa2};

    	// at this point we should have 4 Account Associations, forward and back for each association
    	list<Account_Association__c> associations = [select Id from Account_Association__c];
    	System.assertEquals(4, associations.size());

    	// after deleting account 1 the 2 associations referencing it should be gone
    	delete a1;
    	associations = [select Id from Account_Association__c];
    	System.assertEquals(2, associations.size());

    	// after deleting account 3 the 2 remaining associations should be gone
    	delete a3;
    	associations = [select Id from Account_Association__c];
    	System.assertEquals(0, associations.size());
    }
            
    /*********************************************************************************************************
    * @description Test inversion of association type on the mirror association
    */
    static testMethod void testReciprocalAssociationType(){
        // set up a reciprocal type mapping
        Reciprocal_Account_Association_Types__c reciprocalSetting1 = new Reciprocal_Account_Association_Types__c(
            Name='Vendor',
            Reciprocal_Type__c='Customer'
        );
        insert reciprocalSetting1;
        Reciprocal_Account_Association_Types__c reciprocalSetting2 = new Reciprocal_Account_Association_Types__c(
            Name='Branch',
            Reciprocal_Type__c='Central Office'
        );
        insert reciprocalSetting2;

        // set up accounts
        setupAccountTestData();

        // add forward association
        Account_Association__c aa = new Account_Association__c(
            Account__c = a1.Id,
            Associated_Account__c = a2.Id,
            Type__c = 'Vendor');
        insert aa;

        // check that a mirror was created with the reciprocal type
        Account_Association__c forward = [select Id, Type__c from Account_Association__c where Id=:aa.Id];
        Account_Association__c backward = [select Id, Type__c from Account_Association__c where Reciprocal_Association__c=:aa.Id];
        System.assertEquals('Vendor', forward.Type__c);
        System.assertEquals('Customer', backward.Type__c);

        // update forward association
        aa.Type__c = 'Branch';
        update aa;

        // check that the mirror was updated with the reciprocal type
        backward = [select Id, Type__c from Account_Association__c where Reciprocal_Association__c=:aa.Id];
        System.assertEquals('Central Office', backward.Type__c);
    }

    /*********************************************************************************************************
    * @description Merging two associated accounts should delete the associations.
    */
    static testMethod void testMergingAssociatedAccountsDeletesAssociations() {
        // add associated accounts
        setupAccountTestData();
        Account_Association__c aa = new Account_Association__c(
            Account__c = a1.Id,
            Associated_Account__c = a2.Id);
        insert aa;

        // merge accounts (and wait for future calls)
        Test.startTest();
        merge a1 a2;
        Test.stopTest();

        // make sure the associations were deleted
        list<Account_Association__c> associations = [select Id from Account_Association__c];
        System.assertEquals(0, associations.size());
    }

}