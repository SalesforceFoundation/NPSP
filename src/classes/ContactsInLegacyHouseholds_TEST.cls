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
* @description ContactsInLegacyHouseholds tests in NPSP.
*/
@IsTest
private with sharing class ContactsInLegacyHouseholds_TEST {

    @IsTest
    static void whenOnAfterInsert_thenCreateHouseholdsCalled() {
        //Given
        ContactsInLegacyHouseholds contactsInLegacyHouseholds =
                new ContactsInLegacyHouseholds(TEST_ContactBuilder.dummyContactList());

        HouseholdServiceMock householdServiceMock = new HouseholdServiceMock();
        contactsInLegacyHouseholds.householdService = stubFor(householdServiceMock);

        //When
        contactsInLegacyHouseholds.onAfterInsert();

        //Then
        System.assert(householdServiceMock.createHouseholdsCalled);
        Contact contactInQueue =
                (Contact) householdServiceMock.contactsQueuedForHouseholdCreation.getRecords()[0];
        System.assert(isDummyContact(contactInQueue), 'The dummy Contact should be queued for ' +
                'Household creation after insert.');
    }

    @IsTest
    static void whenOnAfterUpdate_thenUpdateHouseholdNameCalled() {
        //Given
        Contact dummyContactWithTitleChanged = TEST_ContactBuilder.dummyContactWithId();
        String newTitle = 'Handy Man';
        dummyContactWithTitleChanged.Title = newTitle;
        ContactsInLegacyHouseholds contactsInLegacyHouseholds =
                new ContactsInLegacyHouseholds(
                        new List<Contact>{
                                dummyContactWithTitleChanged
                        },
                        new Map<Id, Contact>(TEST_ContactBuilder.dummyContactListWithIds())
                );
        HouseholdServiceMock householdServiceMock = new HouseholdServiceMock();
        contactsInLegacyHouseholds.householdService = stubFor(householdServiceMock);

        //When
        contactsInLegacyHouseholds.onAfterUpdate();

        //Then
        System.assert(householdServiceMock.updateHouseholdNamesCalled);
        Contact contactInQueue =
                (Contact) householdServiceMock.contactsQueuedForHouseholdNameUpdate.getRecords()[0];
        System.assert(isDummyContact(contactInQueue), 'The dummy Contact should be queued for ' +
                'Household renaming since its Title changed.');
    }

    private static HouseholdService stubFor(HouseholdServiceMock householdServiceMock) {
        return (HouseholdService) Test.createStub(
                HouseholdService.class,
                householdServiceMock
        );
    }

    private static Boolean isDummyContact(Contact con) {
        return con.FirstName == TEST_ContactBuilder.dummyContact().FirstName &&
                con.LastName == TEST_ContactBuilder.dummyContact().LastName &&
                con.npe01__WorkEmail__c == TEST_ContactBuilder.dummyContact().npe01__WorkEmail__c;
    }

    public class HouseholdServiceMock implements StubProvider {
        public Boolean createHouseholdsCalled = false;
        public ContactsInLegacyHouseholds contactsQueuedForHouseholdCreation;
        public Boolean updateHouseholdNamesCalled = false;
        public ContactsInLegacyHouseholds contactsQueuedForHouseholdNameUpdate;

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'createHouseholdsFor' {
                    createHouseholdsCalled = true;
                    contactsQueuedForHouseholdCreation =
                            (ContactsInLegacyHouseholds) listOfArgs[0];
                }
                when 'updateHouseholdNamesFor' {
                    updateHouseholdNamesCalled = true;
                    contactsQueuedForHouseholdNameUpdate =
                            (ContactsInLegacyHouseholds) listOfArgs[0];
                }
            }
            return null;
        }
    }

}