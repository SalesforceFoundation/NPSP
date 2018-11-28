/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2018
* @group Opportunity
* @description Tests for OpportunityContactRoles as pertains to Multiple Tributes functionality
*/
@isTest
private class OPP_OpportunityContactRolesTribute_TEST {
 
    /*******************************************************************************************************
    * @description Role values to use in settings.
    */    
    private static final String OPPORTUNITY_CONTACT_ROLE_DONOR = 'Donor';
    private static final String OPPORTUNITY_CONTACT_ROLE_HONOREE = 'Honoree';
    private static final String OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT = 'Notification Recipient';

    /******************************************************************************************************
    * @description Test Create Opporunity with SingleTribute Only mode
    */
    static testMethod void createOppWithTributeSingle() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT,
                        Multiple_Tributes__c = TBU_MultipleTributesSettingsFacade.TRIBUTE_SINGLE_VAL
                )
        );

        //Create and Insert Opportunity
        Account orgAcct = new Account(Name = 'MultipleTributeAccount1', npe01__SYSTEMIsIndividual__c = false);
        insert orgAcct;

        Opportunity oppToInsert = new Opportunity( AccountId = orgAcct.id, StageName = 'Close Won', Name='Donation1',
                Amount= 1000, CloseDate = date.today(), Honoree_Name__c = 'John Smith', Notification_Recipient_Name__c = 'Mark Smith');

        Test.startTest();
        insert oppToInsert;
        Test.stopTest();

        //verify that the there is no tribute in the org
        List<Tribute__c> tributes = [Select Id from Tribute__c];
        System.assertEquals(0, tributes.size());

        //verify that the Tribute field is still on opp
        List<Opportunity> opp = [Select Id from Opportunity where Honoree_Name__c = 'John Smith' and Notification_Recipient_Name__c = 'Mark Smith'
        and Id =: oppToInsert.Id];
        System.assertEquals(1, opp.size());
    }

    /******************************************************************************************************
    * @description Test Create/Update Opportunity/Tribute with Mix mode (Allow both Tribute object
    * and Tribute Field)
    ********************************************************************************************************/
    static testMethod void createOppWithTributeMultipleLoose() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT,
                        Multiple_Tributes__c = TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL
                )
        );

        //Create and Insert Opportunity
        Account orgAcct = new Account(Name = 'MultipleTributeAccount2', npe01__SYSTEMIsIndividual__c = false);
        insert orgAcct;

        List<Opportunity> oppsToInsert = new List<Opportunity>();

        Opportunity opp1 = new Opportunity( AccountId = orgAcct.id, StageName = 'Close Won', Name='Donation2',
                Amount= 1000, CloseDate = date.today(), Honoree_Name__c = 'John Smith', Notification_Recipient_Name__c = 'Mark Smith');

        oppsToInsert.add(opp1);

        Opportunity opp2 = new Opportunity( AccountId = orgAcct.id, StageName = 'Close Won', Name='Donation3',
                Amount= 1000, CloseDate = date.today());

        oppsToInsert.add(opp2);

        Test.startTest();

        insert oppsToInsert;

        //verify that the there is no tribute in the org
        List<Tribute__c> tributes = [Select Id from Tribute__c];
        System.assertEquals(0, tributes.size());

        //Now insert a Tribute for opp2, should not have any issue
        Tribute__c tri = new Tribute__c(Opportunity__c = opp2.Id, Honoree_Name__c = 'John Smith');
        insert tri;

        //System should allow update of Tribute info on Opp1
        opp1.Honoree_Name__c = 'Mike Brown';
        update opp1;

        opp1 = [Select Id, Honoree_Name__c from Opportunity where Id =: opp1.Id];
        System.assertEquals('Mike Brown', opp1.Honoree_Name__c);


        //system should prevent update Tribute on Opp2 since Opp2 has a separate Tribute record on it
        try{
            opp2.Honoree_Name__c = 'Mike Brown';
            update opp2; //System should throw an exception here
            System.assert(false);
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.errMultipleTributesEnforceMultiple) == true);
        }

        Test.stopTest();
    }

    /******************************************************************************************************
    * @description Test Create/Update Opportunity with Multiple Tribute only mode
    ********************************************************************************************************/
    static testMethod void createOppWithTributeMultipleStrict() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT,
                        Multiple_Tributes__c = TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL
                )
        );

        //Create and Insert Opportunity
        Account orgAcct = new Account(Name = 'MultipleTributeAccount3', npe01__SYSTEMIsIndividual__c = false);
        insert orgAcct;

        Opportunity opp = new Opportunity( AccountId = orgAcct.id, StageName = 'Close Won', Name='Donation2',
                Amount= 1000, CloseDate = date.today(), Honoree_Name__c = 'John Smith', Notification_Recipient_Name__c = 'Mark Smith');

        Test.startTest();
        insert opp;

        //verify that the there is one tribute in the org, and Tribute fields get cleared
        List<Tribute__c> tributes = [Select Id, Opportunity__c, Honoree_Name__c, Opportunity__r.Honoree_Name__c, Opportunity__r.Notification_Recipient_Name__c from Tribute__c];
        System.assertEquals(1, tributes.size());
        System.assertEquals(opp.Id, tributes[0].Opportunity__c);
        System.assertEquals('John Smith', tributes[0].Honoree_Name__c);
        System.assertEquals(null, tributes[0].Opportunity__r.Honoree_Name__c);

        //verify that system will not Allow update Tribute on Opp
        try{
            opp.Honoree_Name__c = 'Mike Brown';
            update opp; //System should throw an exception here
            System.assert(false);
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.errMultipleTributesEnforceMultiple) == true);
        }

        Test.stopTest();
    }

    /******************************************************************************************************
    * @description Test clear OCR and Sync OCR for Multiple Tributes
    ********************************************************************************************************/
    static testMethod void updatePrimaryContactOfOpportunity(){
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT,
                        Multiple_Tributes__c = TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL
                )
        );

        //Insert three Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert cons;

        Opportunity opp = new Opportunity(
                Name = 'Test',
                Primary_Contact__c = cons[0].id,
                Honoree_Contact__c = cons[1].id,
                Notification_Recipient_Contact__c = cons[2].Id,
                CloseDate = date.today(),
                StageName = 'Close Won'
        );

        insert opp;

        List<OpportunityContactRole> ocrs = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.id];
        delete ocrs;

        OpportunityContactRole garbageOCR = new OpportunityContactRole();
        garbageOCR.OpportunityId = opp.Id;
        garbageOCR.ContactId = cons[3].Id;
        garbageOCR.Role = OPPORTUNITY_CONTACT_ROLE_HONOREE;
        garbageOCR.isPrimary = false;

        insert garbageOCR;

        //When the Primary Contact changes on the Opp, system should run Clear OCR to delete unnecessary OCR and create
        //the missing OCR based on the Tribute
        opp = [Select Primary_Contact__c from Opportunity where Id =: opp.Id];
        opp.Primary_Contact__c = cons[4].id;
        Test.startTest();
        update opp;
        Test.stopTest();

        List<OpportunityContactRole> queryOCR = [SELECT Id, ContactId, Contact.Name, OpportunityId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:opp.id ORDER BY Contact.Name];
        System.assertEquals(3, queryOCR.size());
        
        System.assertEquals(cons[1].id, queryOCR[0].ContactId);
        System.assertEquals(false, queryOCR[0].isPrimary);
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_HONOREE, queryOCR[0].Role);

        System.assertEquals(cons[2].id, queryOCR[1].ContactId);
        System.assertEquals(false, queryOCR[1].isPrimary);
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT, queryOCR[1].Role);

        System.assertEquals(cons[4].id, queryOCR[2].ContactId);
        System.assertEquals(true, queryOCR[2].isPrimary);
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, queryOCR[2].Role);
    }
}