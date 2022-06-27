/**
 * File Name: fflib_RecordTypeId
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
public class fflib_RecordTypeId
{
	private static Map<String, Map<String, RecordTypeInfo>> cacheByName;
	private static Map<String, Map<String, RecordTypeInfo>> cacheByDeveloperName;

	public static Id getByDeveloperName(String sObjectName, String recordTypeName)
	{
		return getRecordTypeId(cacheByDeveloperName, sObjectName, recordTypeName);
	}

	public static Id getByDeveloperName(Schema.SObjectType sObjectType, String recordTypeName)
	{
		return getRecordTypeId(
				cacheByDeveloperName,
				fflib_SObjectDescribe.getDescribe(sObjectType).getDescribe().getName(),
				recordTypeName);
	}

	public static Id getByName(String sObjectName, String recordTypeName)
	{
		return getRecordTypeId(cacheByName, sObjectName, recordTypeName);
	}

	public static Id getByName(Schema.SObjectType sObjectType, String recordTypeName)
	{
		return getRecordTypeId(
				cacheByName,
				fflib_SObjectDescribe.getDescribe(sObjectType).getDescribe().getName(),
				recordTypeName);
	}

	private static Id getRecordTypeId(
			Map<String, Map<String, RecordTypeInfo>> cache,
			String sObjectName,
			String recordTypeName)
	{
		if (cache.containsKey(sObjectName)) return getRecordTypeIdFromCache(cache, sObjectName, recordTypeName);

		Map<String, RecordTypeInfo> recordTypeInfosByName = fflib_SObjectDescribe.getDescribe(sObjectName)
				.getDescribe()
				.getRecordTypeInfosByDeveloperName();

		cache.put(sObjectName, recordTypeInfosByName);

		if (recordTypeInfosByName.containsKey(recordTypeName) == false)
			throwUnableToFindException(sObjectName, recordTypeName);

		return recordTypeInfosByName.get(recordTypeName).getRecordTypeId();
	}

	private static Id getRecordTypeIdFromCache(
			Map<String, Map<String,RecordTypeInfo>> cache,
			String sObjectName,
			String recordTypeName)
	{
		if (cache.get(sObjectName).containsKey(recordTypeName) == false)
			throwUnableToFindException(recordTypeName, sObjectName);

		return cache.get(sObjectName).get(recordTypeName).getRecordTypeId();
	}

	private static void throwUnableToFindException(String recordTypeName, String sObjectName)
	{
		throw new RecordTypeException(
				String.format(
						'Unable to find recordType {0} on SObject {1}',
						new List<String> {recordTypeName, sObjectName}));
	}

	public class RecordTypeException extends Exception {}
}