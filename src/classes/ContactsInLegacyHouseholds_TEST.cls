/**
 * Created by kenneth.lewis on 5/1/21.
 */

@IsTest
private class ContactsInLegacyHouseholds_TEST {

    @IsTest
    static void whenOnAfterInsert_thenCreateHouseholdsCalled() {
        //Given
        ContactsInLegacyHouseholds contactsInLegacyHouseholds =
                new ContactsInLegacyHouseholds(ContactBuilder.dummyContactList());
        HouseholdServiceMock householdServiceMock = new HouseholdServiceMock();
        HouseholdService s = (HouseholdService) Test.createStub(
                HouseholdService.class,
                householdServiceMock
        );
        System.assert(!householdServiceMock.createHouseholdsCalled);
        contactsInLegacyHouseholds.householdService = s;

        //When
        contactsInLegacyHouseholds.onAfterInsert();

        //Then
        System.assert(householdServiceMock.createHouseholdsCalled);
    }

    public class HouseholdServiceMock implements StubProvider {
        public Boolean createHouseholdsCalled = false;

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'createHouseholdsFor' {
                    createHouseholdsCalled = true;
                }
            }
            return null;
        }
    }
}