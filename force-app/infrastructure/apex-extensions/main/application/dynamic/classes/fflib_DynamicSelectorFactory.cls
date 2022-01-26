/**
 * File Name: fflib_DynamicSelectorFactory
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
public virtual class fflib_DynamicSelectorFactory
		extends fflib_DynamicAppFactory
		implements fflib_ISelectorFactory
{
	public static final fflib_AppBindingType SELECTOR_BINDING_TYPE = fflib_AppBindingType.Selector;

	protected Map<Object, Object> mockSelectorImplByObjectType = new Map<Object, Object>();

	public fflib_DynamicSelectorFactory(fflib_IAppBindingResolver resolver)
	{
		this.resolver = resolver;
	}

	public fflib_ISObjectSelector newInstance(SObjectType sObjectType)
	{
		if (hasMock(sObjectType)) return (fflib_ISObjectSelector) getMock(sObjectType);

		List<fflib_IAppBinding> bindings = resolver
				.byType(SELECTOR_BINDING_TYPE)
				.byObject(sObjectType)
				.bySharingMode(sharingMode)
				.resolve();

		if (bindings.isEmpty())
			throw new DeveloperException(
					String.format(
							'Unable to find selector binding for {0} with sharing mode {1}',
							new List<String>
							{
									sObjectType.getDescribe().getName(),
									sharingMode.name()
							}
					)
			);

		return (fflib_ISObjectSelector) bindings.get(0).newImplInstance();
	}

	public List<SObject> selectById(Set<Id> recordIds)
	{
		if (null == recordIds || recordIds.size() == 0)
			throw new fflib_Application.DeveloperException('Invalid record Id\'s set');

		return selectById(recordIds, new List<Id>(recordIds)[0].getSObjectType());
	}

	public List<SObject> selectById(Set<Id> recordIds, SObjectType sObjectType)
	{
		if (null == recordIds || recordIds.size() == 0)
			throw new fflib_Application.DeveloperException('Invalid record Id\'s set');

		return newInstance(sObjectType)
				.selectSObjectsById(recordIds);
	}

	public List<SObject> selectByRelationship(List<SObject> relatedRecords, SObjectField relationshipField)
	{
		Set<Id> relatedIds =
				new RelatedRecordsDomain(relatedRecords)
						.getRelatedIds(relationshipField);

		if (relatedIds.isEmpty()) return new List<SObject>();

		return selectById(relatedIds);
	}

	public void replaceWith(SObjectType sObjectType, Type replacementImplType)
	{
		resolver.byType(fflib_AppBindingType.Selector)
				.byObject(sObjectType)
				.bySharingMode(this.sharingMode)
				.resolve()
				.get(0)
				.setImplementationType(replacementImplType);
	}

	public void setMock(fflib_ISObjectSelector selectorInstance)
	{
		setMock(selectorInstance.sObjectType(), selectorInstance);
	}

	public void setMock(SObjectType sObjectType, fflib_ISObjectSelector selectorInstance)
	{
		super.setMock(sObjectType, selectorInstance);
	}

	public fflib_DynamicSelectorFactory setSharingMode(fflib_SharingMode sharingMode)
	{
		this.sharingMode = sharingMode;
		return this;
	}

	private class RelatedRecordsDomain extends fflib_SObjects2
	{
		public 	RelatedRecordsDomain(List<SObject> records)
		{
			super(records);
		}

		public Set<Id> getRelatedIds(Schema.SObjectField relationshipField)
		{
			return getIdFieldValues(relationshipField).getIds();
		}
	}

	public class DeveloperException extends Exception {}
}