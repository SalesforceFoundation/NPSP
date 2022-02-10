/**
 * File Name: fflib_AppBindingMetaDataModule
 * @description An application module responsible for loading the application bindings
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
public with sharing class fflib_AppBindingMetaDataModule
		extends fflib_AppBindingModule
{
	public override void init()
	{
		this.bindings = new List<fflib_IAppBinding>();
		for (fflib_AppBinding__mdt binding : fflib_AppBindingsSelector.newInstance().selectAll())
		{
			addBinding(
					new fflib_AppBinding()
							.setBindingObject(getBindingObject(binding))
							.setBindingType(getBindingType(binding))
							.setImplementationType(getSystemType(binding, fflib_AppBinding__mdt.ImplementationType__c))
							.setInterfaceType(getSystemType(binding, fflib_AppBinding__mdt.InterfaceType__c))
							.setNamespacePrefix(binding.NamespacePrefix)
							.setSequence(binding.BindingSequence__c)
							.setSharingMode(getSharingModeFromString(binding.SharingMode__c))
			);
		}
	}

	private Object getBindingObject(fflib_AppBinding__mdt binding)
	{
		if (String.isBlank(binding.BindingObject__c) && String.isBlank(binding.BindingObjectAlternate__c)) return null;

		String bindingObjectApiName = String.isNotBlank(binding.BindingObject__c)
				? binding.BindingObject__r.QualifiedApiName.toLowerCase().trim()
				: binding.BindingObjectAlternate__c.toLowerCase().trim();

		// Assume its an SObjectType
		List<Schema.DescribeSObjectResult> schemaDescribes = Schema.describeSObjects(new List<String> {bindingObjectApiName});
		if (schemaDescribes.size() == 1)
		{
			return schemaDescribes.get(0).getSObjectType();
		}
		else
		{
			// check if its an Object (class)
			Type objectType = System.Type.forName(bindingObjectApiName);
			if (objectType == null)
				throw new DeveloperException('Failed to find (S)Object ' + bindingObjectApiName + ' referenced by binding ' + binding.DeveloperName);

			return objectType;
		}
	}

	private fflib_AppBindingType getBindingType(fflib_AppBinding__mdt binding)
	{
		Map<String, fflib_AppBindingType> bindingTypeByStrings = new Map<String, fflib_AppBindingType>();
		for (fflib_AppBindingType enumValue : fflib_AppBindingType.values())
		{
			bindingTypeByStrings.put(String.valueOf(enumValue).toUpperCase(), enumValue);
		}

		if (bindingTypeByStrings.containsKey(binding.Type__c.toUpperCase()) == false)
			throw new DeveloperException(
					String.format(
							'Unable to identify binding type {0} referenced by binding {1}',
							new List<String>{ binding.Type__c, binding.DeveloperName}
					)
			);

		return bindingTypeByStrings.get(binding.Type__c.toUpperCase());
	}

	private fflib_SharingMode getSharingModeFromString(String sharingMode)
	{
		switch on sharingMode.toUpperCase()
		{
			when 'WITH SHARING'
			{
				return fflib_SharingMode.WithSharing;
			}
			when 'WITHOUT SHARING'
			{
				return fflib_SharingMode.WithoutSharing;
			}
			when 'INHERITED SHARING'
			{
				return fflib_SharingMode.WithoutSharing;
			}
			when 'NONE'
			{
				return null;
			}
		}
		return null;
	}

	private Type getSystemType(fflib_AppBinding__mdt binding, Schema.SObjectField sObjectField)
	{
		String systemTypeName = String.valueOf(binding.get(sObjectField));
		if (null == systemTypeName) return null;

		Type systemType = System.Type.forName(systemTypeName);
		if (null == systemType)
			throw new DeveloperException(
					String.format(
							'Unable to find {0} referenced by binding {1} for {2}',
							new List<String>{ systemTypeName, binding.DeveloperName, sObjectField.getDescribe().getName()}
					)
			);
		return systemType;
	}

	public class DeveloperException extends Exception
	{
	}
}