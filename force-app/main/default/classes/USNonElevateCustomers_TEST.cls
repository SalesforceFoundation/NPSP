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
* @description Unit test class for the USNonElevateCustomers Audience implementation.
*/

@IsTest
private class USNonElevateCustomers_TEST {
   @IsTest
   static void shouldReturnAudienceForUSOrganizationAsANonElevateCustomer() {
       UserSelectorMock userSelectorMock = new UserSelectorMock();
       OrganizationSelectorMock organizationSelectorMock = new OrganizationSelectorMock().withUSOrganization(true);
       PS_IntegrationServiceConfigMock integrationServiceConfigMock =
           new PS_IntegrationServiceConfigMock().asElevateCustomer(false);

       USNonElevateCustomers customers = new USNonElevateCustomers();
       customers.userSelector = stubFor(userSelectorMock);
       customers.organizationSelector = stubFor(organizationSelectorMock);
       customers.serviceConfig = stubFor(integrationServiceConfigMock);
       UserIds userIds = customers.audience();
       System.assert(!userIds.values().isEmpty());
   }

    @IsTest
    static void shouldNotReturnAudienceForNonUSOrganizationAsANonElevateCustomer() {
        UserSelectorMock userSelectorMock = new UserSelectorMock();
        OrganizationSelectorMock organizationSelectorMock = new OrganizationSelectorMock().withUSOrganization(false);
        PS_IntegrationServiceConfigMock integrationServiceConfigMock =
            new PS_IntegrationServiceConfigMock().asElevateCustomer(false);

        USNonElevateCustomers customers = new USNonElevateCustomers();
        customers.userSelector = stubFor(userSelectorMock);
        customers.organizationSelector = stubFor(organizationSelectorMock);
        customers.serviceConfig = stubFor(integrationServiceConfigMock);
        UserIds userIds = customers.audience();
        System.assert(userIds == null);
    }

    @IsTest
    static void shouldNotReturnAudienceForUSOrganizationAsAnElevateCustomer() {
        UserSelectorMock userSelectorMock = new UserSelectorMock();
        OrganizationSelectorMock organizationSelectorMock = new OrganizationSelectorMock().withUSOrganization(true);
        PS_IntegrationServiceConfigMock integrationServiceConfigMock =
            new PS_IntegrationServiceConfigMock().asElevateCustomer(true);

        USNonElevateCustomers customers = new USNonElevateCustomers();
        customers.userSelector = stubFor(userSelectorMock);
        customers.organizationSelector = stubFor(organizationSelectorMock);
        customers.serviceConfig = stubFor(integrationServiceConfigMock);
        UserIds userIds = customers.audience();
        System.assert(userIds == null);
    }

    /**
     * @description Tests that this Custom Notification's Audience
     * will not include inactive UserIds, which cause a platform
     * exception and prevent delivery.  This test should remain an
     * integration test that uses the database, in order to validate
     * that when this Audience is generated using customer orgs it will
     * always exclude inactive Users.
     */
    @IsTest
    static void shouldNotIncludeInactiveUserIds(){
        // GIVEN that an Org contains at least one inactive User
        User inactiveUser = UTIL_UnitTestData_TEST.createNewInactiveUserForTests
                (UTIL_UnitTestData_TEST.getRandomUsername());

        // WHEN the USNonElevateCustomers Audience is generated
        IAudience usNonElevateCustomers = new USNonElevateCustomers();

        // THEN it will not include Ids of the inactive Users
        System.assertEquals(false,
                usNonElevateCustomers.audience().values().contains(inactiveUser.Id),
                'The US Non-Elevate Customers Audience should not include inactive User Ids');
    }

    private class PS_IntegrationServiceConfigMock implements StubProvider {

        private Boolean isElevateCustomer = false;

        public PS_IntegrationServiceConfigMock asElevateCustomer(Boolean isElevateCustomer) {
            this.isElevateCustomer = isElevateCustomer;
            return this;
        }

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'isIntegrationEnabled' {
                    return isElevateCustomer;
                }
            }
            return null;
        }
    }

    private class UserSelectorMock implements StubProvider {

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'getActiveStandardUsers' {
                    return new List<User>{
                        new User(Id = UTIL_UnitTestData_TEST.mockId(User.SObjectType))
                    };
                }
            }
            return null;
        }
    }

    private class OrganizationSelectorMock implements StubProvider {

        private Boolean withUSOrganization = true;

        public OrganizationSelectorMock withUSOrganization (Boolean withUSOrganization) {
            this.withUSOrganization = withUSOrganization;
            return this;
        }

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'isUSOrganization' {
                    return withUSOrganization;
                }
            }
            return null;
        }
    }

    private static PS_IntegrationServiceConfig stubFor(
        PS_IntegrationServiceConfigMock integrationServiceConfigMock) {
        return (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class, integrationServiceConfigMock);
    }

    private static OrganizationSelector stubFor(
        OrganizationSelectorMock organizationSelectorMock) {
        return (OrganizationSelector) Test.createStub(
            OrganizationSelector.class, organizationSelectorMock);
    }

    private static UserSelector stubFor(
        UserSelectorMock userSelectorMock) {
        return (UserSelector) Test.createStub(
            UserSelector.class, userSelectorMock);
    }
}