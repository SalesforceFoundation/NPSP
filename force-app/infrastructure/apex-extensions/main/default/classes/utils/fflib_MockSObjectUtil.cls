/**
 * File Name: fflib_MockSObjectUtil
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
public with sharing class fflib_MockSObjectUtil
{
	public static SObject addRelatedParentObject(SObject childObject, SObject parentObject, String relationshipField)
	{
		String original = JSON.serialize(childObject);
		return (SObject) JSON.deserialize(
				original.left(original.length() - 1) +
						',"' + relationshipField + '":' +
						JSON.serialize(parentObject) + '}',
				SObject.class);
	}

	// Keeping this method for backwards compatibility
	@TestVisible
	private static SObject addFieldValue(SObject record, Schema.SObjectField sObjectField, Object value)
	{
		System.debug(LoggingLevel.WARN, 'addFieldValue is deprecated and will be removed at some point, please use setFieldValue instead');
		return setFieldValue(record, sObjectField, value);
	}

	@TestVisible
	private static SObject setFieldValue(
			SObject record, SObjectField sObjectField, Object value)
	{
		String fieldName = sObjectField.getDescribe().getName();

		String serializedRecord = JSON.serialize(record);
		Map<String, Object> valuesByFieldName =
				(Map<String, Object>) JSON.deserializeUntyped(serializedRecord);

		valuesByFieldName.put(fieldName, value);
		serializedRecord = JSON.serialize(valuesByFieldName);

		return (SObject) JSON.deserialize(serializedRecord, SObject.class);
	}

	@IsTest
	static void itShouldTestAddingReadOnlyField()
	{
		final Decimal amount = 10.0;
		Opportunity opp = new Opportunity(Id = fflib_IDGenerator.generate(Schema.Opportunity.SObjectType));
		SObject result = addFieldValue(opp, Opportunity.ExpectedRevenue, amount);
		System.assertEquals(amount, result.get(Opportunity.ExpectedRevenue));
	}

	@IsTest
	static void itShouldTestSettingDateField()
	{
		final Date today = Date.today();
		Lead record = new Lead(Id = fflib_IDGenerator.generate(Schema.Lead.SObjectType));
		SObject result = addFieldValue(record, Lead.ConvertedDate, today);
		System.assertEquals(today, result.get(Lead.ConvertedDate));
		System.debug('result: '+result);
	}
}