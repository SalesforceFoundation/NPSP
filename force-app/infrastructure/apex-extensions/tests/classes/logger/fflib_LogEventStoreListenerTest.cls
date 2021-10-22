/**
 * File Name: fflib_LogEventStoreListenerTest
 * Description: Unit tests for fflib_LogEventStoreListener.cls
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
private class fflib_LogEventStoreListenerTest
{

	private static final String ERROR_MESSAGE = 'My Error Message';

	private static final String TEST_USER_PROFILE = 'Standard User';

	@IsTest
	static void itShouldStoreRecordOnLogEvent()
	{
		// GIVEN - A Log Event
		fflib_LogEvent__e logEvent = generateLoggingLevelEvent(System.LoggingLevel.ERROR, ERROR_MESSAGE);

		// WHEN - The log event is published
		System.Test.startTest();
		EventBus.publish(logEvent);
		System.Test.stopTest();

		// THEN - a record should be created in the Log Event Store
		System.assertEquals(1, [SELECT COUNT() FROM fflib_LogEntry__c]);
	}

	/**
	 * THIS UNIT TEST IS DISABLED BY DEFAULT SINCE THERE IS NO KNOWN STANDARD USER FACTORY METHOD FOR THE TARGET ORG
	 */
	@IsTest
	static void itShouldStoreRecordOnLogEventWithUserDetails()
	{
		// GIVEN - A Log Event thrown by a specific user
		fflib_LogEvent__e logEvent = generateLoggingLevelEvent(System.LoggingLevel.ERROR, ERROR_MESSAGE);
		User testUser = generateUser();
		insert testUser;

		// WHEN - The log event is published
		System.Test.startTest();
		System.runAs(testUser)
		{
			EventBus.publish(logEvent);
		}
		System.Test.stopTest();

		// THEN - a record should be created in the Log Event Store
		List<fflib_LogEntry__c> logEntries = [SELECT Id, LogLevel__c, Message__c, User__c FROM fflib_LogEntry__c];
		System.assert(logEntries.size() == 1);
		System.assertEquals(testUser.Id, logEntries.get(0).User__c, 'Log Entry stored with wrong CreatedById');
	}

	private static fflib_LogEvent__e generateLoggingLevelEvent(LoggingLevel loggingLevel, String message)
	{
		return new fflib_LogEvent__e(
				LogLevel__c = loggingLevel.name(),
				message__c = message
		);
	}

	private static User generateUser()
	{
		Profile profile = [SELECT Id FROM Profile WHERE Name = :TEST_USER_PROFILE];
		return new User(
				Alias = 'jnjfflib',
				Email = 'TestUser@example.com',
				EmailEncodingKey = 'UTF-8',
				FirstName = 'Test',
				LanguageLocaleKey = 'en_US',
				LastName = 'User',
				LocaleSidKey = 'en_US',
				ProfileId = profile.Id,
				TimeZoneSidKey = 'America/Los_Angeles',
				Username = 'TestUser@example.com.jnjfflib'
		);
	}
}