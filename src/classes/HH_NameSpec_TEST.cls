/*
    Copyright (c) 2014 Salesforce.com Foundation
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
* @date 2013
* @description tests specific to the HH_NameSpec custom household naming class 
*/

@isTest
private with sharing class HH_NameSpec_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
        
    /*********************************************************************************************************
    operation:
        1 contact in household 
    verify:
        HH Name, Formal Greeting, and Informal Greeting are correct
    **********************************************************************************************************/            
    static testMethod void OneContact() {
        if (strTestOnly != '*' && strTestOnly != 'OneContact') return;
        
        list<Contact> listCon = new list<Contact>();
        Contact c1 = new Contact (
            Salutation = 'Skipper',
            FirstName = 'John',
            LastName = 'Doe'
        );
        listCon.add(c1);
               
        HH_NameSpec ns = new HH_NameSpec();
        Household_Naming_Settings__c hns = UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
        
        hns.Household_Name_Format__c = '{!LastName} Family';
        system.assertEquals('Doe Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Household_Name_Format__c = 'HH - {!LastName}, {!{!FirstName}}';
        system.assertEquals('HH - Doe, John', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
        system.assertEquals('Skipper John Doe', ns.getExampleName(hns, 'Formal_Greeting_Format__c', listCon));

        hns.Informal_Greeting_Format__c = '{!{!FirstName} Dude}';
        system.assertEquals('John Dude', ns.getExampleName(hns, 'Informal_Greeting_Format__c', listCon));

    }

    /*********************************************************************************************************
    operation:
        2 contact, same lastname in household 
    verify:
        HH Name, Formal Greeting, and Informal Greeting are correct
    **********************************************************************************************************/            
    static testMethod void TwoContactSameLastname() {
        if (strTestOnly != '*' && strTestOnly != 'TwoContactSameLastname') return;
                
        list<Contact> listCon = new list<Contact>();
        Contact c1 = new Contact (
            Salutation = 'Skipper',
            FirstName = 'John',
            LastName = 'Doe'
        );
        listCon.add(c1);
        Contact c2 = new Contact (
            FirstName = 'Jane',
            LastName = 'Doe'
        );
        listCon.add(c2);
               
        HH_NameSpec ns = new HH_NameSpec();
        Household_Naming_Settings__c hns = UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
        hns.Name_Connector__c = '&';
        
        hns.Household_Name_Format__c = '{!LastName} Family';
        system.assertEquals('Doe Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));
        
        hns.Household_Name_Format__c = 'HH - {!LastName}, {!{!FirstName}}';
        system.assertEquals('HH - Doe, John & Jane', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
        system.assertEquals('Skipper John & Jane Doe', ns.getExampleName(hns, 'Formal_Greeting_Format__c', listCon));

        hns.Informal_Greeting_Format__c = '{!{!FirstName} Dude}';
        system.assertEquals('John Dude & Jane Dude', ns.getExampleName(hns, 'Informal_Greeting_Format__c', listCon));   
    }

    /*********************************************************************************************************
    operation:
        2 contacts, different lastnames in household 
    verify:
        HH Name, Formal Greeting, and Informal Greeting are correct
    **********************************************************************************************************/            
    static testMethod void TwoContactDifferentLastname() {
        if (strTestOnly != '*' && strTestOnly != 'TwoContactDifferentLastname') return;
                
        list<Contact> listCon = new list<Contact>();
        Contact c1 = new Contact (
            Salutation = 'Skipper',
            FirstName = 'John',
            LastName = 'Doe'
        );
        listCon.add(c1);
        Contact c2 = new Contact (
            FirstName = 'Jane',
            LastName = 'Smith'
        );
        listCon.add(c2);
               
        HH_NameSpec ns = new HH_NameSpec();
        Household_Naming_Settings__c hns = UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
        hns.Name_Connector__c = '&';
        
        hns.Household_Name_Format__c = '{!LastName} Family';
        system.assertEquals('Doe & Smith Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));
        
        hns.Household_Name_Format__c = 'HH - {!LastName}, {!{!FirstName}} Family';
        system.assertEquals('HH - Doe, John & Smith, Jane Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Household_Name_Format__c = 'The {!LastName} ({!{!FirstName}}) Family';
        system.assertEquals('The Doe (John) & Smith (Jane) Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
        system.assertEquals('Skipper John Doe & Jane Smith', ns.getExampleName(hns, 'Formal_Greeting_Format__c', listCon));

        hns.Informal_Greeting_Format__c = '{!{!FirstName} Dude}';
        system.assertEquals('John Dude & Jane Dude', ns.getExampleName(hns, 'Informal_Greeting_Format__c', listCon));   
    }

    /*********************************************************************************************************
    operation:
        3 contacts, 2 different lastnames in household 
    verify:
        HH Name, Formal Greeting, and Informal Greeting are correct
    **********************************************************************************************************/            
    static testMethod void ThreeContactsTwoLastnames() {
        if (strTestOnly != '*' && strTestOnly != 'ThreeContactsTwoLastnames') return;
                
        list<Contact> listCon = new list<Contact>();
        Contact c1 = new Contact (
            Salutation = 'Skipper',
            FirstName = 'John',
            LastName = 'Doe'
        );
        listCon.add(c1);
        Contact c2 = new Contact (
            FirstName = 'Jane',
            LastName = 'Doe'
        );
        listCon.add(c2);
        Contact c3 = new Contact (
            FirstName = 'Sally',
            LastName = 'Smith'
        );
        listCon.add(c3);
               
        HH_NameSpec ns = new HH_NameSpec();
        Household_Naming_Settings__c hns = UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
        hns.Name_Connector__c = '&';
        
        hns.Household_Name_Format__c = '{!LastName} Family';
        system.assertEquals('Doe & Smith Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));
        
        hns.Household_Name_Format__c = 'HH - {!LastName}, {!{!FirstName}} Family';
        system.assertEquals('HH - Doe, John & Jane & Smith, Sally Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Household_Name_Format__c = 'The {!LastName} ({!{!FirstName}}) Family';
        system.assertEquals('The Doe (John & Jane) & Smith (Sally) Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
        system.assertEquals('Skipper John & Jane Doe & Sally Smith', ns.getExampleName(hns, 'Formal_Greeting_Format__c', listCon));

        hns.Informal_Greeting_Format__c = '{!{!FirstName} Dude}';
        system.assertEquals('John Dude, Jane Dude & Sally Dude', ns.getExampleName(hns, 'Informal_Greeting_Format__c', listCon));   
    }
    
    /*********************************************************************************************************
    operation:
        3 contacts, 2 different lastnames in household, custom fields in format specs 
    verify:
        HH Name, Formal Greeting, and Informal Greeting are correct
    **********************************************************************************************************/            
    static testMethod void ThreeContactsTwoLastnamesCustomFields() {
        if (strTestOnly != '*' && strTestOnly != 'ThreeContactsTwoLastnamesCustomFields') return;
                
        list<Contact> listCon = new list<Contact>();
        Contact c1 = new Contact (
            Salutation = 'Skipper',
            FirstName = 'John',
            LastName = 'Doe',
            npe01__WorkEmail__c = 'john@doe.com'
            
        );
        listCon.add(c1);
        Contact c2 = new Contact (
            Salutation = 'Mrs.',
            FirstName = 'Jane',
            LastName = 'Doe',
            npe01__WorkEmail__c = 'jane@doe.com'
        );
        listCon.add(c2);
        Contact c3 = new Contact (
            FirstName = 'Sally',
            LastName = 'Smith'
        );
        listCon.add(c3);
               
        HH_NameSpec ns = new HH_NameSpec();
        Household_Naming_Settings__c hns = UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
        hns.Name_Connector__c = '&';
        
        hns.Household_Name_Format__c = '{!LastName} Family';
        system.assertEquals('Doe & Smith Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));
        
        hns.Household_Name_Format__c = 'HH - {!LastName}, {!{!FirstName} {!npe01__WorkEmail__c}} Family';
        system.assertEquals('HH - Doe, John john@doe.com & Jane jane@doe.com & Smith, Sally Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Household_Name_Format__c = 'The {!LastName} ({!{!FirstName} {!npe01__WorkEmail__c}}) Family';
        system.assertEquals('The Doe (John john@doe.com & Jane jane@doe.com) & Smith (Sally) Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName} {!npe01__WorkEmail__c}} {!LastName}';
        system.assertEquals('Skipper John john@doe.com & Mrs. Jane jane@doe.com Doe & Sally Smith', ns.getExampleName(hns, 'Formal_Greeting_Format__c', listCon));

        hns.Informal_Greeting_Format__c = '{!{!FirstName} {!npe01__WorkEmail__c} Dude}';
        system.assertEquals('John john@doe.com Dude, Jane jane@doe.com Dude & Sally Dude', ns.getExampleName(hns, 'Informal_Greeting_Format__c', listCon));   
    }

    /*********************************************************************************************************
    operation:
        6 contacts, 1 lastnames in household 
        Contact overrun set to 5
    verify:
        HH Name, Formal Greeting, and Informal Greeting are correct
    **********************************************************************************************************/            
    static testMethod void SixContactsOneLastnamesContactOverrun() {
        if (strTestOnly != '*' && strTestOnly != 'SixContactsOneLastnamesContactOverrun') return;
                
        list<Contact> listCon = new list<Contact>();
        Contact c1 = new Contact (
            Salutation = 'Skipper',
            FirstName = 'John',
            LastName = 'Doe'
        );
        listCon.add(c1);
        Contact c2 = new Contact (
            FirstName = 'Jane',
            LastName = 'Doe'
        );
        listCon.add(c2);
        Contact c3 = new Contact (
            FirstName = 'Sally',
            LastName = 'Doe'
        );
        listCon.add(c3);
        Contact c4 = new Contact (
            FirstName = 'Clay',
            LastName = 'Doe'
        );
        listCon.add(c4);
        Contact c5 = new Contact (
            FirstName = 'Cloe',
            LastName = 'Doe'
        );
        listCon.add(c5);
        Contact c6 = new Contact (
            FirstName = 'Charlie',
            LastName = 'Doe'
        );
        listCon.add(c6);
               
        HH_NameSpec ns = new HH_NameSpec();
        Household_Naming_Settings__c hns = UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
        hns.Name_Connector__c = '&';
        hns.Contact_Overrun_Count__c = 5;
        hns.Name_Overrun__c = 'Friends';
        
        hns.Household_Name_Format__c = '{!LastName} Family';
        system.assertEquals('Doe Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));
        
        hns.Household_Name_Format__c = 'HH - {!LastName}, {!{!FirstName}} Family';
        system.assertEquals('HH - Doe, John, Jane, Sally, Clay, Cloe & Friends Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Household_Name_Format__c = 'The {!LastName} ({!{!FirstName}}) Family';
        system.assertEquals('The Doe (John, Jane, Sally, Clay, Cloe) & Friends Family', ns.getExampleName(hns, 'Household_Name_Format__c', listCon));

        hns.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
        system.assertEquals('Skipper John, Jane, Sally, Clay, Cloe Doe & Friends', ns.getExampleName(hns, 'Formal_Greeting_Format__c', listCon));

        hns.Informal_Greeting_Format__c = '{!{!FirstName} Dude}';
        system.assertEquals('John Dude, Jane Dude, Sally Dude, Clay Dude, Cloe Dude & Friends', ns.getExampleName(hns, 'Informal_Greeting_Format__c', listCon));   
    }
}