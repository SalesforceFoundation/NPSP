/**
 * File Name: fflib_DynamicDomainFactoryTest 
 * @description
 *
 * @author architect ir. Wilhelmus G.J. Velzeboer
 *
 * Copyright (c), W.G.J. Velzeboer,
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above author notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the author nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
@IsTest(IsParallel=true)
public class fflib_DynamicDomainFactoryTest
{
    private static final fflib_IAppBindingResolver bindingResolver =
            new fflib_AppBindingResolver();


    private static final fflib_IDomainFactory Domain =
            new fflib_DynamicDomainFactory(
                    bindingResolver,
                    fflib_DynamicSelectorFactoryTest.Selector);
    private static final SObjectType ACCOUNT_OBJECT_TYPE = Schema.Account.SObjectType;

    @IsTest
	static void itShouldReturnDomain()
	{
        // Mock the App Bindings selector
        fflib_AppBindingsSelector.SELECTOR_IMPL_TYPE = AppBindingsSelectorMock.class;
        final List<Account> records = generateAccountRecords();

        System.Test.startTest();
        Object instance = Domain.newInstance(records);
        System.Test.stopTest();

        System.assert(instance instanceof fflib_SObjects);
    }

    @IsTest
	static void itShouldReturnDomainById()
	{
        // Mock the App Bindings selector
        fflib_AppBindingsSelector.SELECTOR_IMPL_TYPE = AppBindingsSelectorMock.class;

        final List<Account> records = generateAccountRecords();
        final Set<Id> ids = new fflib_SObjects(records).getRecordIds();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectSelector selectorMock = (fflib_ISObjectSelector) mocks.mock(fflib_ISObjectSelector.class);
        mocks.startStubbing();
        mocks.when(selectorMock.selectSObjectsById(ids)).thenReturn(records);
        mocks.stopStubbing();

        fflib_DynamicSelectorFactoryTest.Selector.setMock(ACCOUNT_OBJECT_TYPE, selectorMock);

        System.Test.startTest();
        Object instance = Domain.newInstance(ids);
        System.Test.stopTest();

        System.assert(instance instanceof fflib_SObjects);
        System.assertEquals(records, ((fflib_SObjects) instance).getRecords());
    }

    @IsTest
    static void itShouldReturnTheMockDomain()
    {
        // Mock the App Bindings selector
        fflib_AppBindingsSelector.SELECTOR_IMPL_TYPE = AppBindingsSelectorMock.class;

        final List<Account> records = generateAccountRecords();
        final Set<Id> ids = new fflib_SObjects(records).getRecordIds();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_SObjects domainMock = (fflib_SObjects) mocks.mock(fflib_SObjects.class);

        mocks.startStubbing();
        mocks.when(domainMock.getType()).thenReturn(ACCOUNT_OBJECT_TYPE);
        mocks.when(domainMock.getRecords()).thenReturn(new List<Account>());
        mocks.stopStubbing();

        System.Test.startTest();
        fflib_SObjects instanceA = (fflib_SObjects) Domain.newInstance(records);
        Domain.setMock(domainMock);
        fflib_SObjects instanceB = (fflib_SObjects) Domain.newInstance(records, ACCOUNT_OBJECT_TYPE);
        System.Test.stopTest();

        System.assertEquals(records, instanceA.getRecords());
        System.assert(instanceB.getRecords().isEmpty());
    }


    private static List<Account> generateAccountRecords()
    {
        List<Account> records = new List<Account>
        {
                new Account(Id = fflib_IDGenerator.generate(ACCOUNT_OBJECT_TYPE)),
                new Account(Id = fflib_IDGenerator.generate(ACCOUNT_OBJECT_TYPE)),
                new Account(Id = fflib_IDGenerator.generate(ACCOUNT_OBJECT_TYPE))
        };
        return records;
    }


    public class MyDomainConstructor implements fflib_IDomainConstructor
    {
        public fflib_IDomain construct(List<Object> objects)
        {
            return new fflib_SObjects((List<SObject>) objects);
        }
    }

    private class AppBindingsSelectorMock extends fflib_AppBindingsSelector
    {
        public override List<fflib_AppBinding__mdt> selectAll()
        {
            return new List<fflib_AppBinding__mdt>
            {
                    new fflib_AppBinding__mdt(
                            Type__c = 'Domain',
                            BindingObject__c = '',
                            BindingObjectAlternate__c = ACCOUNT_OBJECT_TYPE.getDescribe().getName(),
                            ImplementationType__c = MyDomainConstructor.class.getName(),
                            SharingMode__c = 'None'
                    )
            };
        }
    }
}