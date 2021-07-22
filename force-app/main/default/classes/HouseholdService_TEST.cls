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
* @description HouseholdService tests in NPSP.
*/
@IsTest
private class HouseholdService_TEST {

    @IsTest
    static void insertHouseholdsForContacts_insertsAHouseholdForDummyContact_whenHHSettingsAll
            () {
        //Given
        setHouseholdSettingsToAll();

        //Then
        validateCreateHouseholds_insertsHouseholdForDummyContact();
    }

    @IsTest
    static void
    insertHouseholdsForContacts_insertsAHouseholdForDummyContact_whenHHSettingsAllIndividuals
            () {
        //Given
        setHouseholdSettingsToAllIndividuals();

        //Then
        validateCreateHouseholds_insertsHouseholdForDummyContact();
    }

    private static void validateCreateHouseholds_insertsHouseholdForDummyContact() {
        HouseholdService service = new HouseholdService();
        UnitOfWorkMock mock = new UnitOfWorkMock();
        UnitOfWork stub = (UnitOfWork) Test.createStub(UnitOfWork.class, mock);
        service.unitOfWorkInst = stub;

        //When
        service.createHouseholdsFor(
                new ContactsInLegacyHouseholds(
                        TEST_ContactBuilder.dummyContactList()));

        //Then
        System.assert(mock.householdsToBeInserted.size() == 1);
        System.assert(mock.saveCalled);
    }

    private class UnitOfWorkMock implements StubProvider {
        public Boolean registerNewCalled = false;
        List<npo02__Household__c> householdsToBeInserted;
        public Boolean saveCalled = false;

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'registerNew' {
                    registerNewCalled = true;
                    householdsToBeInserted = (List<npo02__Household__c>) listOfArgs[0];
                }
                when 'save' {
                    saveCalled = true;
                    return new List<Database.SaveResult>();
                }
            }
            return null;
        }
    }

    private static void setHouseholdSettingsToAll() {
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                        npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR));
    }

    private static void setHouseholdSettingsToAllIndividuals() {
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                        npo02__Household_Rules__c = HH_Households.ALL_INDIVIDUALS_PROCESSOR));
    }

}