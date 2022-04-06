/**
 * File Name: fflib_AppBindingsSelector 
 * @description Selector for fflib_AppBinding__mdt records
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
public virtual without sharing class fflib_AppBindingsSelector extends fflib_SObjectSelector
{
	// Used for mocking
	@TestVisible
	private static System.Type SELECTOR_IMPL_TYPE = fflib_AppBindingsSelector.class;

	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField>
		{
				fflib_AppBinding__mdt.Id,
				fflib_AppBinding__mdt.BindingObject__c,
				fflib_AppBinding__mdt.BindingObjectAlternate__c,
				fflib_AppBinding__mdt.BindingSequence__c,
				fflib_AppBinding__mdt.DeveloperName,
				fflib_AppBinding__mdt.NamespacePrefix,
				fflib_AppBinding__mdt.ImplementationType__c,
				fflib_AppBinding__mdt.InterfaceType__c,
				fflib_AppBinding__mdt.SharingMode__c,
				fflib_AppBinding__mdt.Type__c
		};
	}

	public static fflib_AppBindingsSelector newInstance()
	{
		return (fflib_AppBindingsSelector) SELECTOR_IMPL_TYPE.newInstance();
	}

	public Schema.SObjectType getSObjectType()
	{
		return fflib_AppBinding__mdt.SObjectType;
	}

	public virtual List<fflib_AppBinding__mdt> selectAll()
	{
		/**
		Todo - Waiting to uncomment the following section
		        until fflib-apex-common fixes the getFieldPath issue
		        Currently failing on the BindingObject__r field,
		        thinking its not a relationship field

				Error on line 119, column 1: fflib_QueryFactory.NonReferenceFieldException:
				fflib_AppBinding__mdt.BindingObject__r is not a lookup or master-detail
				 field but is used in a cross-object query field.

		return (List<fflib_AppBinding__mdt>) Database.query(
				newQueryFactory()
						.selectField('BindingObject__r.QualifiedApiName')
						.toSOQL());
						*/

		return (List<fflib_AppBinding__mdt>) Database.query(
				String.format(
						'SELECT {0} FROM {1}',
						new List<String>
						{
								getFieldListString() + ', BindingObject__r.QualifiedApiName',
								getSObjectType().getDescribe().getName()
						}
				)
		);
	}
}
