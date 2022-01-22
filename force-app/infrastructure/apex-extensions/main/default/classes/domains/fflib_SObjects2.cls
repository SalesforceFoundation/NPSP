/**
 * File Name: fflib_SObjects2
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
public virtual class fflib_SObjects2
		extends fflib_SObjects
		implements fflib_ISObjects
{
	protected Schema.DescribeSObjectResult SObjectDescribe { get; private set; }

	/**
	 * Class constructors
	 *
	 * @param objects The Objects of type SObjectType, to contain inside the domain
	 */
	public fflib_SObjects2(List<Object> objects)
	{
		// todo - assert of objects of type SObject
		this((List<SObject>) objects);
	}

	/**
	 * Class constructor
	 *
	 * @param records The records to contain inside the domain
	 */
	public fflib_SObjects2(List<SObject> records)
	{
		this(records, records.getSObjectType());
	}

	/**
	 * Class constructor
	 *
	 * @param records The records to contain inside the domain
	 * @param sObjectType The SObjectType of the records
	 */
	public fflib_SObjects2(List<SObject> records, Schema.SObjectType sObjectType)
	{
		super(records, sObjectType);
		SObjectDescribe = sObjectType.getDescribe();
	}

	/**
	 * @param id Domain containing primary key (Id field) values
	 *
	 * @return Returns only the SObjects from the domain matching the given Ids.
	 */
	public virtual SObject getRecord(Id id)
	{
		List<SObject> result = getRecords(new Set<Id> {id});

		return (result.size() == 0) ? null : result.get(0);
	}

	/**
	 * @return Returns the contents of the Domain by their primary Key ('Id' field)
	 */
	public virtual Map<Id, SObject> getSObjectById()
	{
		return new Map<Id, SObject>(getRecords());
	}

	/**
	 * @param ids Domain containing primary key (Id field) values
	 *
	 * @return Returns only the SObjects from the domain matching the given Ids.
	 */
	public virtual List<SObject> getRecords(fflib_Ids ids)
	{
		return getRecords(ids.getIds());
	}

	/**
	 * @param ids A Set containing primary key (Id field) values
	 *
	 * @return Returns only the SObjects from the domain matching the given Ids.
	 */
	public virtual List<SObject> getRecords(Set<Id> ids)
	{
		Map<Id, SObject> sObjectsByIds = getSObjectById();
		List<SObject> result = new List<SObject>();
		for (Id id : ids)
		{
			if (sObjectsByIds.containsKey(id) == false) continue;

			result.add(sObjectsByIds.get(id));
		}
		return result;
	}

	/**
	 * @param criteria The condition the returned record must meet
	 *
	 * @return Return the SObject records contained in the domain matching the criteria
	 */
	public virtual List<SObject> getRecords(fflib_Criteria criteria)
	{
		List<SObject> result = new List<SObject>();
		for (SObject record : getRecords())
		{
			if (!criteria.evaluate(record)) continue;

			result.add(record);
		}
		return result;
	}

	/**
	 * Adds an error message to the records in the domain
	 *
	 * @param message The error message to add to each record
	 */
	@TestVisible
	protected virtual void addError(String message)
	{
		for (SObject record : getRecords())
		{
			record.addError(error(message, record));
		}
	}

	/**
	 * Adds an error message to the a field records in the domain
	 *
	 * @param sObjectField The field where the error should be reported
	 * @param message The error message to add to the given field on each record
	 */
	@TestVisible
	protected virtual void addError(Schema.SObjectField sObjectField, String message)
	{
		for (SObject record : getRecords())
		{
			record.addError(sObjectField, error(message, record, sObjectField));
		}
	}

	/**
	 * Clear the field value on all the records of the domain
	 * @param sObjectField The field to nullify
	 */
	@TestVisible
	protected virtual void clearField(Schema.SObjectField sObjectField)
	{
		clearFields(new Set<Schema.SObjectField>{ sObjectField });
	}

	/**
	 * Clear the field values on all the records of the domain
	 * @param sObjectFields The fields to nullify
	 */
	@TestVisible
	protected virtual void clearFields(Set<Schema.SObjectField> sObjectFields)
	{
		for (SObject record : getRecords())
		{
			for (SObjectField sObjectField : sObjectFields)
			{
				record.put(sObjectField, null);
			}
		}
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 *
	 * @return The Date values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Dates getDateFieldValues(Schema.SObjectField sObjectField)
	{
		Set<Date> result = new Set<Date>();
		for (SObject record : getRecords())
		{
			Object fieldValue = record.get(sObjectField);
			if (fieldValue == null) continue;
			result.add((Date) fieldValue);
		}
		return new fflib_Dates(result);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 * @param criteria The criteria condition that must be met to include the value in the return
	 *
	 * @return The Date values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Dates getDateFieldValues(Schema.SObjectField sObjectField, fflib_Criteria criteria)
	{
		return new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.getDateFieldValues(sObjectField);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 *
	 * @return The DateTime values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_DateTimes getDateTimeFieldValues(Schema.SObjectField sObjectField)
	{
		Set<Datetime> result = new Set<Datetime>();
		for (SObject record : getRecords())
		{
			Object fieldValue = record.get(sObjectField);
			if (fieldValue == null) continue;
			result.add((Datetime) fieldValue);
		}
		return new fflib_DateTimes(result);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 * @param criteria The criteria condition that must be met to include the value in the return
	 *
	 * @return The DateTime values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_DateTimes getDateTimeFieldValues(Schema.SObjectField sObjectField, fflib_Criteria criteria)
	{
		return new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.getDateTimeFieldValues(sObjectField);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get the SUM of
	 *
	 * @return The total SUM of the given field
	 */
	@TestVisible
	protected virtual Decimal getDecimalFieldSum(Schema.SObjectField sObjectField)
	{
		Decimal result = 0;
		for (SObject record : getRecords())
		{
			result += record.get(sObjectField) == null ? 0 : (Decimal) record.get(sObjectField);
		}
		return result;
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 *
	 * @return The Decimal values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Decimals getDecimalFieldValues(Schema.SObjectField sObjectField)
	{
		Set<Decimal> result = new Set<Decimal>();
		for (SObject record : getRecords())
		{
			Object fieldValue = record.get(sObjectField);
			if (fieldValue == null) continue;
			result.add((Decimal) fieldValue);
		}
		return new fflib_Decimals(result);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 * @param criteria The criteria condition that must be met to include the value in the return
	 *
	 * @return The Decimal values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Decimals getDecimalFieldValues(Schema.SObjectField sObjectField, fflib_Criteria criteria)
	{
		return new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.getDecimalFieldValues(sObjectField);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 *
	 * @return The Double values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Doubles getDoubleFieldValues(Schema.SObjectField sObjectField)
	{
		Set<Double> result = new Set<Double>();
		for (SObject record : getRecords())
		{
			Object fieldValue = record.get(sObjectField);
			if (fieldValue == null) continue;
			result.add((Double) fieldValue);
		}
		return new fflib_Doubles(result);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 * @param criteria The criteria condition that must be met to include the value in the return
	 *
	 * @return The Double values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Doubles getDoubleFieldValues(Schema.SObjectField sObjectField, fflib_Criteria criteria)
	{
		return new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.getDoubleFieldValues(sObjectField);
	}

	/**
	 * Get a map with the values of two fields.
	 * Key fields containing null values are omitted
	 *
	 * @param valueField The field to use as the Value of the Map
	 * @param keyField The field to use as the Key of the map
	 *
	 * @return Returns a map with the values of two fields
	 *
	 * @example
	 * Accounts accounts = Accounts.newInstance(records);
	 * Map<Object, Object> accountNameById = accounts.getFieldByField(Account.Name, Account.Id);
	 */
	@TestVisible
	protected virtual Map<Object, Object> getFieldByField(Schema.SObjectField valueField, Schema.SObjectField keyField)
	{
		Map<Object, Object> result = new Map<Object, Object>();
		for (SObject record : getRecords())
		{
			if (record.get(keyField) == null) continue;

			result.put(
					record.get(keyField),
					record.get(valueField)
			);
		}
		return result;
	}

	/**
	 * Get a map with the values of two fields
	 * Key fields containing null values are omitted
	 *
	 * @param valueField The field to use as the Value of the Map
	 * @param keyField The field to use as the Key of the map
	 *
	 * @return Returns a map with the values of two fields
	 *
	 * @example
	 * Contacts contacts = Contacts.newInstance(records);
	 * Map<Object, Set<Object>> contactIdByAccountId = contacts.getFieldsByField(Contact.Id, Contact.AccountId);
	 */
	@TestVisible
	protected virtual Map<Object, Set<Object>> getFieldsByField(Schema.SObjectField valueField, Schema.SObjectField keyField)
	{
		Map<Object, Set<Object>> result = new Map<Object, Set<Object>>();
		for (SObject record : getRecords())
		{
			Object keyFieldValue = record.get(keyField);
			if (keyFieldValue == null) continue;

			if (!result.containsKey(keyFieldValue))
			{
				result.put(keyFieldValue, new Set<Object>());
			}
			result.get(keyFieldValue).add(record.get(valueField));
		}
		return result;
	}

	/**
	 * @return Returns only the first SObject contained in the domain.
	 */
	public SObject getFirstSObject()
	{
		if (isEmpty()) return null;

		return getRecords().get(0);
	}

	/**
	 * Get a map with the values of a String field as key and Id field
	 * Key fields containing null values are omitted
	 *
	 * @param valueField The Id field to use as the Value of the Map
	 * @param keyField The String field to use as the Key of the map
	 *
	 * @return Returns a map with the values of two fields
	 *
	 * @example
	 * Contacts contacts = Contacts.newInstance(records);
	 * Map<String, Id> accountIdByContactId = contacts.getIdFieldByStringField(Contact.Id, Contact.Name);
	 */
	@TestVisible
	protected virtual Map<String, Id> getIdFieldByStringField(Schema.SObjectField valueField, Schema.SObjectField keyField)
	{
		Map<String, Id> result = new Map<String, Id>();
		for (SObject record : getRecords())
		{
			if (record.get(keyField) == null) continue;

			result.put(
					(String) record.get(keyField),
					(Id) record.get(valueField)
			);
		}
		return result;
	}

	/**
	 * Get a map with the values of two Id fields
	 * Key fields containing null values are omitted
	 *
	 * @param valueField The Id field to use as the Value of the Map
	 * @param keyField The Id field to use as the Key of the map
	 *
	 * @return Returns a map with the values of two fields
	 *
	 * @example
	 * Contacts contacts = Contacts.newInstance(records);
	 * Map<Id, Id> accountIdByContactId = contacts.getIdFieldByIdField(Contact.AccountId, Contact.Id);
	 */
	@TestVisible
	protected virtual Map<Id, Id> getIdFieldByIdField(Schema.SObjectField valueField, Schema.SObjectField keyField)
	{
		Map<Id, Id> result = new Map<Id, Id>();
		for (SObject record : getRecords())
		{
			if (record.get(keyField) == null) continue;

			result.put(
					(Id) record.get(keyField),
					(Id) record.get(valueField)
			);
		}
		return result;
	}

	/**
	 * Get a map with the values of two Id fields with a one to many relation
	 * Key fields containing null values are omitted
	 *
	 * @param valueField The Id field to use as the Value of the Map
	 * @param keyField The Id field to use as the Key of the map
	 *
	 * @return Returns a map with the values of two fields
	 *
	 * @example
	 * Contacts contacts = Contacts.newInstance(records);
	 * Map<Id, Set<Id>> contactIdByAccountId = contacts.getIdFieldsByIdField(Contact.Id, Contact.AccountId);
	 */
	@TestVisible
	protected virtual Map<Id, Set<Id>> getIdFieldsByIdField(Schema.SObjectField valueField, Schema.SObjectField keyField)
	{
		Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
		for (SObject record : getRecords())
		{
			Id keyFieldId = (Id) record.get(keyField);
			if (keyFieldId == null) continue;

			if (!result.containsKey(keyFieldId))
			{
				result.put(keyFieldId, new Set<Id>());
			}
			result.get(keyFieldId).add((Id) record.get(valueField));
		}
		return result;
	}

	/**
	 * Gets the values from the given Id field
	 *
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 * Fields containing null values are omitted
	 *
	 * @return The Id values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Ids getIdFieldValues(Schema.SObjectField sObjectField)
	{
		Set<Id> result = new Set<Id>();
		for (SObject record : getRecords())
		{
			Object fieldValue = record.get(sObjectField);
			if (fieldValue == null) continue;

			result.add(Id.valueOf(String.valueOf(fieldValue)));
		}
		return new fflib_Ids(result);
		// todo - alternative return to avoid code duplications: return new Ids(getFieldValues(sObjectField));
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their Id values
	 * @param criteria The criteria condition that must be met to include the value in the return
	 *
	 * @return The Id values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Ids getIdFieldValues(Schema.SObjectField sObjectField, fflib_Criteria criteria)
	{
		return new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.getIdFieldValues(sObjectField);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their values
	 *
	 * @return The Integer values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Integers getIntegerFieldValues(Schema.SObjectField sObjectField)
	{
		Set<Integer> result = new Set<Integer>();
		for (SObject record : getRecords())
		{
			Object fieldValue = record.get(sObjectField);
			if (fieldValue == null) continue;

			result.add(Integer.valueOf(fieldValue));
		}
		return new fflib_Integers(result);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their values
	 * @param criteria The criteria condition that must be met to include the value in the return
	 *
	 * @return The Integer values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Integers getIntegerFieldValues(Schema.SObjectField sObjectField, fflib_Criteria criteria)
	{
		return new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.getIntegerFieldValues(sObjectField);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their values
	 *
	 * @return The Long values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Longs getLongFieldValues(Schema.SObjectField sObjectField)
	{
		Set<Long> result = new Set<Long>();
		for (SObject record : getRecords())
		{
			Object fieldValue = record.get(sObjectField);
			if (fieldValue == null) continue;
			result.add((Long) fieldValue);
		}
		return new fflib_Longs(result);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their values
	 * @param criteria The criteria condition that must be met to include the value in the return
	 *
	 * @return The Long values of the given sObjectField, null values are omitted
	 */
	@TestVisible
	protected virtual fflib_Longs getLongFieldValues(Schema.SObjectField sObjectField, fflib_Criteria criteria)
	{
		return new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.getLongFieldValues(sObjectField);
	}

	/**
	 * Get a map with the record mapped to the given Id field value
	 * Key fields containing null values are omitted
	 *
	 * @param sObjectField The field to use as key for the map
	 *
	 * @return Returns a map with the record mapped to the given Id field value
	 *
	 * @example
	 * Account account = Account.newInstance(records);
	 * Map<Id, SObject> accountById = account.getSObjectByIdField(Account.Id);
	 */
	@TestVisible
	protected virtual Map<Id, SObject> getSObjectByIdField(Schema.SObjectField sObjectField)
	{
		Map<Id, SObject> result = new Map<Id, SObject>();
		for (SObject record : getRecords())
		{
			if (record.get(sObjectField) == null) continue;

			result.put((Id) record.get(sObjectField), record);
		}
		return result;
	}

	/**
	 * Get a map with the records mapped to the given Id field value
	 * Key fields containing null values are omitted
	 *
	 * @param sObjectField The field to use as key for the map
	 *
	 * @return Returns a map with the records mapped to the given Id field value
	 *
	 * @example
	 * Contacts contacts = Contacts.newInstance(records);
	 * Map<Id, List<SObject>> contactsByAccountId = contacts.getSObjectsByIdField(Contact.AccountId);
	 */
	@TestVisible
	protected virtual Map<Id, List<SObject>> getSObjectsByIdField(Schema.SObjectField sObjectField)
	{
		Map<Id, List<SObject>> result = new Map<Id, List<SObject>>();
		for (SObject record : getRecords())
		{
			Id fieldId = (Id) record.get(sObjectField);
			if (fieldId == null) continue;

			if (!result.containsKey(fieldId))
			{
				result.put(fieldId, new List<SObject>());
			}
			result.get(fieldId).add(record);
		}
		return result;
	}

	/**
	 * Get a map with the record mapped to the given String field value
	 * Key fields containing null values are omitted
	 *
	 * @param sObjectField The field to use as key for the map
	 *
	 * @return Returns a map with the record mapped to the given String field value
	 *
	 * @example
	 * Account account = Account.newInstance(records);
	 * Map<String, SObject> accountByNumber = account.getSObjectByStringField(Account.AccountNumber);
	 */
	@TestVisible
	protected virtual Map<String, SObject> getSObjectByStringField(Schema.SObjectField sObjectField)
	{
		Map<String, SObject> result = new Map<String, SObject>();
		for (SObject record : getRecords())
		{
			if (record.get(sObjectField) == null) continue;

			String fieldValue = (String) record.get(sObjectField);
			result.put(fieldValue, record);
		}
		return result;
	}

	/**
	 * Get a map with the records mapped to the given String field value
	 * Key fields containing null values are omitted
	 *
	 * @param sObjectField The field to use as key for the map
	 *
	 * @return Returns a map with the records mapped to the given String field value
	 *
	 * @example
	 * Account account = Account.newInstance(records);
	 * Map<String, SObject> accountByName = account.getSObjectsByStringField(Account.AccountName);
	 */
	@TestVisible
	protected virtual Map<String, List<SObject>> getSObjectsByStringField(Schema.SObjectField sObjectField)
	{
		Map<String, List<SObject>> result = new Map<String, List<SObject>>();
		for (SObject record : getRecords())
		{
			String fieldValue = (String) record.get(sObjectField);
			if (fieldValue == null) continue;

			if (!result.containsKey(fieldValue))
			{
				result.put(fieldValue, new List<SObject>());
			}
			result.get(fieldValue).add(record);
		}
		return result;
	}

	/**
	 * Get a map with the given String field value mapped to the given Id field
	 * Key fields containing null values are omitted
	 *
	 * @param valueField The String field to use as value for the map
	 * @param keyField The Id field to use as key for the map
	 *
	 * @return a map with the given String field value mapped to the given Id field
	 *
	 * @example
	 * Account account = Account.newInstance(records);
	 * Map<Id, String> accountNameById = account.getStringFieldByIdField(Account.AccountName, Account.Id);
	 */
	@TestVisible
	protected virtual Map<Id, String> getStringFieldByIdField(Schema.SObjectField valueField, Schema.SObjectField keyField)
	{
		Map<Id, String> result = new Map<Id, String>();
		Map<Object, Object> fieldByField = getFieldByField(valueField, keyField);
		for (Object obj : fieldByField.keySet())
		{
			result.put((Id) obj, (String) fieldByField.get(obj));
		}
		return result;
	}

	/**
	 * Get a map with the records mapped to the given String field value
	 * Key fields containing null values are omitted
	 *
	 * @param valueField The field to use as value for the map
	 * @param keyField The field to use as key for the map
	 *
	 * @return Returns a map with the record mapped to the given Id field value
	 *
	 * @example
	 * Account account = Account.newInstance(records);
	 * Map<Id, String> accountNameById = account.getStringFieldByStringField(Account.AccountName, Account.Id);
	 */
	@TestVisible
	protected virtual Map<String, String> getStringFieldByStringField(Schema.SObjectField valueField, Schema.SObjectField keyField)
	{
		Map<String, String> result = new Map<String, String>();
		Map<Object, Object> fieldByField = getFieldByField(keyField, valueField);
		for (Object obj : fieldByField.keySet())
		{
			result.put((String) obj, (String) fieldByField.get(obj));
		}
		return result;
	}

	/**
	 * Gets the values for the provided String field
	 *
	 * @param sObjectField The Schema.SObjectField to get their values
	 *
	 * @return The String values of the given sObjectField
	 */
	@TestVisible
	protected virtual fflib_Strings getStringFieldValues(Schema.SObjectField sObjectField)
	{
		Set<String> result = new Set<String>();
		for (SObject record : getRecords())
		{
			result.add(String.valueOf(record.get(sObjectField)));
		}
		return new fflib_Strings(result);
	}

	/**
	 * @param sObjectField The Schema.SObjectField to get their values
	 * @param criteria The criteria condition that must be met to include the value in the return
	 *
	 * @return The String values of the given sObjectField
	 */
	@TestVisible
	protected virtual fflib_Strings getStringFieldValues(Schema.SObjectField sObjectField, fflib_Criteria criteria)
	{
		return new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.getStringFieldValues(sObjectField);
	}

	/**
	 * Sets the given value to the given field only when the criteria is met for the record
	 *
	 * @param sObjectField The Schema.SObjectField to change its value
	 * @param value The new value for the given sObjectField
	 * @param criteria The criteria condition that must be met to include the value in the return
	 */
	@TestVisible
	protected virtual void setFieldValue(Schema.SObjectField sObjectField, Object value, fflib_Criteria criteria)
	{
		new fflib_SObjects2(getRecords(criteria), getSObjectType())
				.setFieldValue(sObjectField, value);
	}

	/**
	 * Sets a value to the given field only when key field Id value is provided in the given map
	 *
	 * @param sObjectIdFieldToCheck The SObject Id Field to match the key against in the provided map
	 * @param sObjectFieldToUpdate The SObjectField to store the mapped value when the key matches the value in the sObjectFieldToUpdate field
	 * @param values Map of values to store by the sObjectIdFieldToCheck fields value
	 */
	@TestVisible
	protected virtual void setFieldValue(
			Schema.SObjectField sObjectIdFieldToCheck,
			Schema.SObjectField sObjectFieldToUpdate,
			Map<Id, Object> values)
	{
		for (SObject record : getRecords())
		{
			Id keyValue = (Id) record.get(sObjectIdFieldToCheck);
			if (values?.containsKey(keyValue))
			{
				record.put(sObjectFieldToUpdate, values.get(keyValue));
			}
		}
	}

	/**
	 * Sets a value to the given field only when key field String value is provided in the given map
	 *
	 * @param sObjectStringFieldToCheck The SObject String Field to match the key against in the provided map
	 * @param sObjectFieldToUpdate The SObjectField to store the mapped value when the key matches the value in the sObjectFieldToUpdate field
	 * @param values Map of values to store by the sObjectIdFieldToCheck fields value
	 */
	@TestVisible
	protected virtual void setFieldValue(
			Schema.SObjectField sObjectStringFieldToCheck,
			Schema.SObjectField sObjectFieldToUpdate,
			Map<String, Object> values)
	{
		for (SObject record : getRecords())
		{
			String keyValue = (String) record.get(sObjectStringFieldToCheck);
			if (values?.containsKey(keyValue))
			{
				record.put(sObjectFieldToUpdate, values.get(keyValue));
			}
		}

	}
}