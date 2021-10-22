/**
 * File Name: fflib_ClassicDomainFactoryTest
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
@IsTest
private class fflib_ClassicDomainFactoryTest
{
	@IsTest
	static void testBehavior()
	{
		// todo - fix assertions
		fflib_ClassicSelectorFactory selectorFactory =
				new fflib_ClassicSelectorFactory(
						new Map<SObjectType, Type>
						{
							Account.SObjectType => MySelector.class
						});

		fflib_ClassicDomainFactory domainFactory = new fflib_ClassicDomainFactory(
				selectorFactory,
				new Map<SObjectType, Type>
				{
						Account.SObjectType => MyDomainConstructor.class
				});
		List<Account> records = new List<Account>();

		domainFactory.newInstance(records);
		domainFactory.newInstance(
				new Set<Id>{fflib_IDGenerator.generate(Account.SObjectType)},
				Account.SObjectType);
		domainFactory.newInstance(new Set<Id>{fflib_IDGenerator.generate(Account.SObjectType)});
		domainFactory.replaceWith(Account.SObjectType, MyDomain.class);
		domainFactory.setMock(Account.SObjectType, new MyDomain(records));
		domainFactory.setMock(new MyDomain(records));
	}

	public class MySelector extends fflib_SObjectSelector
	{
		public List<Schema.SObjectField> getSObjectFieldList()
		{
			return new List<Schema.SObjectField>
			{
					Account.Id
			};
		}

		public override List<SObject> selectSObjectsById(Set<Id> idSet)
		{
			return new List<Account>{ new Account(Id = new List<Id>(idSet).get(0))};
		}

		public SObjectType getSObjectType()
		{
			return Account.SObjectType;
		}
	}

	public class MyDomain extends fflib_SObjects2
	{
		public MyDomain(List<Account> records)
		{
			super(records, Account.SObjectType);
		}
	}

	public class MyDomainConstructor implements fflib_IDomainConstructor
	{
		public fflib_IDomain construct(List<Object> objects)
		{
			return new fflib_SObjects((List<SObject>) objects);
		}
	}
}