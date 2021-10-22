/**
 * File Name: SObjects
 * @description Primitive domain for the object type SObject
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
private class fflib_SObjects2Test
{
	@IsTest
	static void itShouldAddErrorMessage()
	{
		SObjectType accountSObjectType = Schema.Account.SObjectType;
		final Id idA = fflib_IDGenerator.generate(accountSObjectType);
		final Id idB = fflib_IDGenerator.generate(accountSObjectType);

		DomainAccounts domain = new DomainAccounts(
				new List<SObject>
				{
						new Account(Id = idA),
						new Account(Id = idB)
				}
		);

		domain.addError('Oops');
		domain.addError(Schema.Account.Name,'Oops');

		System.assertEquals(
				4,
				fflib_SObjects.Errors.getAll().size()
		);
	}

	@IsTest
	static void itShouldClearTheField()
	{
		Account record = new Account(ShippingCountry = 'Holland');
		DomainAccounts domain = new DomainAccounts(new List<Account> {record});
		System.assert(!domain.selectByShippingCountry('Holland').isEmpty(), 'Incorrect test data');

		domain.clearShippingCountry();

		System.assert(domain.selectByShippingCountry('Holland').isEmpty(), 'Field should have been nullified');
	}

	@IsTest
	static void itShouldReturnTheCreatedData()
	{
		System.assertEquals(
				(Object) Schema.Account.SObjectType,
				new DomainAccounts(new List<Account>())
						.getType(),
				'Unexpected Domain Type'
		);
		System.assertEquals(
				Schema.Account.SObjectType,
				new DomainAccounts(new List<Account>())
						.getSObjectType(),
				'Unexpected Domain SObjectType'
		);
	}

	@IsTest
	static void itShouldReturnTheDomainsType()
	{
		fflib_Criteria criteria = new fflib_Criteria().equalTo(Account.Name, 'A');

		DomainAccounts domain = generateDomain();
		domain.getDateTimeFieldValues(Account.LastActivityDate);
		domain.getDateTimeFieldValues(Account.CreatedDate);
		domain.getFieldByField(Account.Name, Account.AccountNumber);
		domain.getFieldsByField(Account.Id, Account.AccountNumber);
		domain.getFieldByField(Account.Id, Account.Id);
		domain.getIdFieldByIdField(Account.Id, Account.Id);
		domain.getIdFieldsByIdField(Account.Id, Account.Id);
		domain.getIdFieldValues(Account.Id);
		domain.getIdFieldValues(Account.Id, criteria);
		domain.getIntegerFieldValues(Account.NumberOfEmployees);
		domain.getIntegerFieldValues(Account.NumberOfEmployees, criteria);
		domain.getDoubleFieldValues(Account.BillingLatitude);
		domain.getDoubleFieldValues(Account.BillingLatitude, criteria);
		domain.getSObjectByIdField(Account.Id);
		domain.getSObjectsByIdField(Account.Id);
		domain.getSObjectByStringField(Account.Name);
		domain.getSObjectsByStringField(Account.Name);
		domain.getStringFieldByIdField(Account.Id, Account.Name);
		domain.getStringFieldByStringField(Account.Name, Account.AccountNumber);
		domain.getStringFieldValues(Account.Name, criteria);

		// todo - add assertions
	}

	@IsTest
	static void itShouldReturnRecordByIds()
	{
		SObjectType accountSObjectType = Schema.Account.SObjectType;
		final Id idA = fflib_IDGenerator.generate(accountSObjectType);
		final Id idB = fflib_IDGenerator.generate(accountSObjectType);
		final Id idC = fflib_IDGenerator.generate(accountSObjectType);

		DomainAccounts domain = new DomainAccounts(
				new List<SObject>
				{
						new Account(Id = idA),
						new Account(Id = idB),
						new Account(Id = idC)
				}
		);

		Set<Id> recordIds = new Set<Id> {idA, idB, idC};
		System.assert(
				domain.getSObjectById().keySet().containsAll(recordIds),
				'The domain should return all the record Ids'
		);
	}


	@IsTest
	static void itShouldReturnRecordsIds()
	{
		SObjectType accountSObjectType = Schema.Account.SObjectType;
		Id idA = fflib_IDGenerator.generate(accountSObjectType);
		Id idB = fflib_IDGenerator.generate(accountSObjectType);
		Id idC = fflib_IDGenerator.generate(accountSObjectType);

		DomainAccounts domain = new DomainAccounts(
				new List<SObject>
				{
						new Account(Id = idA),
						new Account(Id = idB),
						new Account(Id = idC)
				}
		);

		Set<Id> recordIds = new Set<Id> {idA, idB, idC};
		System.assert(
				domain.getRecordIds().containsAll(recordIds),
				'The domain should return all the record Ids'
		);
	}

	@IsTest
	static void itShouldReturnRecords()
	{
		DomainAccounts domain = generateDomain();

		System.assert(domain.getRecords().size() == 6);
	}

	@IsTest
	static void itShouldReturnRecordByCriteria()
	{
		final Id idA = fflib_IDGenerator.generate(Schema.Account.SObjectType);
		DomainAccounts domain = new DomainAccounts(
				new List<Account>
				{
						new Account(Name = 'A', Id = idA),
						new Account(Name = 'B', Id = fflib_IDGenerator.generate(Schema.Account.SObjectType))
				});

		System.assertEquals(
				'A',
				domain.getRecords(
						new fflib_Criteria()
						.equalTo(Schema.Account.Id, idA)
				)
						.get(0)
						.get('Name')
		);
	}

	@IsTest
	static void itShouldReturnRecordById()
	{
		final Id idA = fflib_IDGenerator.generate(Schema.Account.SObjectType);
		DomainAccounts domain = new DomainAccounts(
				new List<Account>
				{
						new Account(Name = 'A', Id = idA),
						new Account(Name = 'B', Id = fflib_IDGenerator.generate(Schema.Account.SObjectType))
				});

		System.assertEquals('A', domain.getRecord(idA).get('Name'));
	}

	@IsTest
	static void itShouldReturnRecordsById()
	{
		final Id idA = fflib_IDGenerator.generate(Schema.Account.SObjectType);
		final fflib_Ids ids = new fflib_Ids(new Set<Id> {idA});
		DomainAccounts domain = new DomainAccounts(
				new List<Account>
				{
						new Account(Name = 'A', Id = idA),
						new Account(Name = 'B', Id = fflib_IDGenerator.generate(Schema.Account.SObjectType))
				});

		System.assertEquals('A', domain.getRecords(ids).get(0).get('Name'));
	}

	@IsTest
	static void itShouldReturnRecordsByIds()
	{
		final Id idA = fflib_IDGenerator.generate(Schema.Account.SObjectType);
		DomainAccounts domain = new DomainAccounts(
				new List<Account>
				{
						new Account(Name = 'A', Id = idA),
						new Account(Name = 'B', Id = fflib_IDGenerator.generate(Schema.Account.SObjectType))
				});

		System.assertEquals('A', domain.getRecords(new Set<Id> {idA}).get(0).get('Name'));
	}

	@IsTest
	static void itShouldReturnRecordsWithFieldValues()
	{
		DomainAccounts domain = generateDomain();

		System.assert(domain.selectByShippingCountry('USA').size() == 1);
	}

	@IsTest
	static void itShouldReturnRecordsWithoutFieldValues()
	{
		DomainAccounts domain = generateDomain();

		System.assert(domain.selectWithoutShippingCountry().size() == 3);
	}

	@IsTest
	static void itShouldReturnRecordsWithoutAllFieldValues()
	{
		DomainAccounts domain = generateDomain();

		System.assert(domain.selectWithEmptyRecord().size() == 1);
	}

	@IsTest
	static void itShouldReturnRecordsWithShippingCountry()
	{
		DomainAccounts domain = generateDomain();

		System.assert(domain.selectWithShippingCountry().size() == 3);
	}

	@IsTest
	static void itShouldReturnRecordsWithAllFieldValues()
	{
		DomainAccounts domain = generateDomain();

		System.assert(domain.selectPopulatedRecords().size() == 3);
	}

	@IsTest
	static void itShouldReturnFieldValues()
	{
		DomainAccounts domain = generateDomain();

		System.assert(
				domain.getStringFieldValues(Schema.Account.ShippingCountry)
						.containsAll(
						new Set<Object>
						{
								'USA',
								'Ireland',
								'UK',
								''
						}
				)
		);
	}

	@IsTest
	static void itShouldSetFieldValue()
	{
		DomainAccounts domain = generateDomain();
		String country = 'Holland';
		domain.setShippingCountry(country);

		System.assert(domain.selectByShippingCountry(country).size() == 6);
	}

	@IsTest
	static void itShouldSetFieldValueByCondition()
	{
		DomainAccounts domain = generateDomain();
		domain.setRatingByShippingCountry(
				new Map<Object, Object>
				{
						'USA' => 'Hot'
				}
		);

		System.assert(domain.selectByRating('Hot').size() == 1);
	}

	private static DomainAccounts generateDomain()
	{
		DomainAccounts domain = new DomainAccounts(
				new List<Account>
				{
						new Account(Name = 'A', ShippingCountry = 'USA'),
						new Account(Name = 'B', ShippingCountry = 'Ireland'),
						new Account(Name = 'C', ShippingCountry = 'UK'),
						new Account(Name = 'D', ShippingCountry = ''),
						new Account(Name = 'E'),
						new Account()
				}
		);
		return domain;
	}


	private class DomainAccounts extends fflib_SObjects2
	{
		public DomainAccounts(List<SObject> records)
		{
			super(records, Schema.Account.SObjectType);
		}

		public List<Account> selectByShippingCountry(String country)
		{
			return (List<Account>) getRecordsByFieldValues(
					Schema.Account.ShippingCountry,
					new Set<Object> {country}
			);
		}

		public List<Account> selectByRating(String rating)
		{
			return (List<Account>) getRecordsByFieldValue(
					Schema.Account.Rating,
					rating
			);
		}

		public List<Account> selectWithoutShippingCountry()
		{
			return (List<Account>) getRecordsWithBlankFieldValues(
					Schema.Account.ShippingCountry
			);
		}

		public List<Account> selectWithShippingCountry()
		{
			return (List<Account>) getRecordsWithNotBlankFieldValues(
					Schema.Account.ShippingCountry
			);
		}

		public List<Account> selectWithEmptyRecord()
		{
			return (List<Account>) getRecordsWithAllBlankFieldValues(
					new Set<Schema.SObjectField>
					{
							Schema.Account.Name,
							Schema.Account.ShippingCountry
					}
			);
		}

		public List<Account> selectPopulatedRecords()
		{
			return (List<Account>) getRecordsWithAllNotBlankFieldValues(
					new Set<Schema.SObjectField>
					{
							Schema.Account.Name,
							Schema.Account.ShippingCountry
					}
			);
		}

		public void setShippingCountry(String country)
		{
			setFieldValue(Schema.Account.ShippingCountry, country);
		}

		public void setRatingByShippingCountry(Map<Object, Object> ratingByCountry)
		{
			setFieldValueByMap(
					Schema.Account.ShippingCountry,
					Schema.Account.Rating,
					ratingByCountry);
		}

		public void addNameError(String message)
		{
			addError(Schema.Account.Name, message);
		}

		public void clearShippingCountry()
		{
			clearField(Schema.Account.ShippingCountry);
		}
	}
}