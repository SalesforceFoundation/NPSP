/**
 * File Name: fflib_DynamicSelectorFactoryTest 
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
public class fflib_DynamicSelectorFactoryTest
{

	private static fflib_IAppBindingResolver bindingResolver =
			new fflib_AppBindingResolver();

	@TestVisible
	private static final fflib_ISelectorFactory Selector =
			new fflib_DynamicSelectorFactory(bindingResolver)
					.setSharingMode(fflib_SharingMode.WithSharing);

	private static final Type MY_SELECTOR_TYPE = fflib_DynamicSelectorFactoryTest.MySelector.class;

	@IsTest
	static void itShouldReturnTheSelectorByBindingObject()
	{
		// Mock the App Bindings selector
		fflib_AppBindingsSelector.SELECTOR_IMPL_TYPE = AppBindingsSelectorMock.class;

		System.Test.startTest();
		Object instance = Selector.newInstance(Schema.Account.SObjectType);
		System.Test.stopTest();

		System.assert(instance instanceof fflib_DynamicSelectorFactoryTest.MySelector);
	}

	@IsTest
	static void itShouldReturnTheAlternativeSelector()
	{
		// Mock the App Bindings selector
		fflib_AppBindingsSelector.SELECTOR_IMPL_TYPE = AppBindingsSelectorMock.class;

		System.Test.startTest();
		Object instanceA = Selector.newInstance(Schema.Account.SObjectType);
		Selector.replaceWith(Schema.Account.SObjectType, MyMockSelector.class);
		Object instanceB = Selector.newInstance(Schema.Account.SObjectType);
		System.Test.stopTest();

		System.assert(instanceA instanceof fflib_DynamicSelectorFactoryTest.MySelector);
		System.assert(instanceB instanceof fflib_DynamicSelectorFactoryTest.MyMockSelector);
	}

	@IsTest
	static void itShouldReturnTheRecordsById()
	{
		Id id = fflib_IDGenerator.generate(Schema.Account.SObjectType);
		Set<Id> ids = new Set<Id>{ id };
		final List<Account> records = new List<Account>{ new Account(Name='Test') };

		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_ISObjectSelector selectorMock = (fflib_ISObjectSelector) mocks.mock(fflib_ISObjectSelector.class);
		mocks.startStubbing();
		mocks.when(selectorMock.selectSObjectsById(ids)).thenReturn(records);
		mocks.stopStubbing();

		Selector.setMock(Schema.Account.SObjectType, selectorMock);

		System.Test.startTest();
		List<SObject> result = Selector.selectById(ids);
		System.Test.stopTest();

		System.assert(result == records);
		((fflib_ISObjectSelector) mocks.verify(selectorMock)).selectSObjectsById(ids);
	}

	@IsTest
	static void itShouldReturnTheRecordsByRelatedId()
	{
		Id id = fflib_IDGenerator.generate(Schema.Account.SObjectType);
		Set<Id> ids = new Set<Id>{ id };
		final List<Account> accounts = new List<Account>{ new Account(Id = id, Name='Test') };
		final List<Contact> contacts = new List<Contact> { new Contact(AccountId = id)};

		fflib_ApexMocks mocks = new fflib_ApexMocks();
		fflib_ISObjectSelector selectorMock = (fflib_ISObjectSelector) mocks.mock(fflib_ISObjectSelector.class);
		mocks.startStubbing();
		mocks.when(selectorMock.sObjectType()).thenReturn(Schema.Account.SObjectType);
		mocks.when(selectorMock.selectSObjectsById(ids)).thenReturn(accounts);
		mocks.stopStubbing();

		Selector.setMock(selectorMock);

		System.Test.startTest();
		List<SObject> result = Selector.selectByRelationship(contacts, Schema.Contact.AccountId);
		System.Test.stopTest();

		System.assert(result == accounts);
		((fflib_ISObjectSelector) mocks.verify(selectorMock)).selectSObjectsById(ids);
	}

	public interface IMySelector extends fflib_ISObjectSelector	{}

	private abstract class MySelectorAbstract extends fflib_SObjectSelector implements IMySelector
	{
		public List<Schema.SObjectField> getSObjectFieldList()
		{
			return new List<Schema.SObjectField>{ Account.Id, Account.Name };
		}

		public SObjectType getSObjectType()
		{
			return Schema.Account.SObjectType;
		}
	}

	public class MySelector extends MySelectorAbstract {}
	public class MyMockSelector extends MySelectorAbstract {}

	private class AppBindingsSelectorMock extends fflib_AppBindingsSelector
	{
		public override List<fflib_AppBinding__mdt> selectAll()
		{
			return new List<fflib_AppBinding__mdt>
			{
					new fflib_AppBinding__mdt(
							Type__c = 'Selector',
							BindingObject__c = '',
							BindingObjectAlternate__c = Schema.Account.SObjectType.getDescribe().getName(),
							ImplementationType__c = MY_SELECTOR_TYPE.getName(),
							SharingMode__c = 'With Sharing'
					)
			};
		}
	}
}