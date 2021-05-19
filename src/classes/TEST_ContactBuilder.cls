/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Used to create test Contacts in NPSP.
*/
@IsTest
public inherited sharing class TEST_ContactBuilder {

    @TestVisible
    private static Contact dummyContact() {
        Contact con = new Contact(
                FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                Title = 'Doctor',
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        return con;
    }

    @TestVisible
    private static Contacts dummyContacts() {
        return new Contacts(dummyContactList());
    }

    @TestVisible
    private static List<Contact> dummyContactList() {
        return new List<Contact>{dummyContact()};
    }

    @TestVisible
    private static Contact dummyContactWithId() {
        Contact con = dummyContact();
        con.Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        return con;
    }

    @TestVisible
    private static List<Contact> dummyContactListWithIds() {
        return new List<Contact>{dummyContactWithId()};
    }

}