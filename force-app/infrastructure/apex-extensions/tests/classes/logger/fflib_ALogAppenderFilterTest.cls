/**
 * File Name: fflib_LogAppenderFilterTest
 * Description: Unit test class for fflib_LogAppenderFilter.cls
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
private class fflib_ALogAppenderFilterTest
{
	private static final String TEST_USER_PROFILE = 'Standard User';

	@IsTest
	static void itShouldValidateErrorLevelWithDefaultSetToError()
	{
		// GIVEN - We create an AppenderFilter instance and set the filter to ERRROR
		FilteredAppender appender = new FilteredAppender();

		// WHEN - we check if ERROR is valid
		Boolean isValid = appender.checkValidLogLevel(System.LoggingLevel.ERROR);

		// THEN - It should be valid
		System.assert(isValid);
	}

	@IsTest
	static void itShouldNotValidateErrorLevelWithDefaultSetToNone()
	{
		// GIVEN - We create an AppenderFilter instance and set the filter to NONE
		FilteredAppender appender = new FilteredAppender();
		appender.setLoggingLevel(System.LoggingLevel.NONE);

		// WHEN - we check if ERROR is valid
		Boolean isValid = appender.checkValidLogLevel(System.LoggingLevel.ERROR);

		// THEN - It should not be valid
		System.assert(!isValid);
	}

	@IsTest
	static void itShouldNotValidateWarningLevelWithDefaultSetToError()
	{
		// GIVEN - We create an AppenderFilter instance and set the filter to NONE
		FilteredAppender appender = new FilteredAppender();

		// WHEN - we check if ERROR is valid
		Boolean isValid = appender.checkValidLogLevel(System.LoggingLevel.WARN);

		// THEN - It should not be valid
		System.assert(!isValid);
	}

	/**
	 * THIS UNIT TEST IS DISABLED BY DEFAULT SINCE THERE IS NO KNOWN STANDARD USER FACTORY METHOD FOR THE TARGET ORG
	 */
/*	@IsTest
	static void itShouldValidateWarningLevelWithDefaultSetToErrorForSpecifiedUser()
	{
		// Given - A default AppenderFilter instance and a specific user config set to Warning
		FilteredAppender appender = new FilteredAppender();
		User testUser = generateUser();
		insert testUser;

		insert new fflib_LogLevelFilter__c(

				SetupOwnerId = testUser.Id,
				LogLevel__c = System.LoggingLevel.WARN.name()
		);

		// When - we check if WARNING is valid
		Boolean isValid = false;
		System.runAs(testUser)
		{
			isValid = appender.checkValidLogLevel(System.LoggingLevel.WARN);
		}

		// Then - It should be valid
		System.assert(isValid);
	}*/

	/**
	 * THIS UNIT TEST IS DISABLED BY DEFAULT SINCE THERE IS NO KNOWN STANDARD USER FACTORY METHOD FOR THE TARGET ORG
	 */
/*	@IsTest
	static void itShouldValidateWarningLevelWithDefaultSetToErrorForSpecifiedProfile()
	{
		// Given - A default AppenderFilter instance and a specific user config set to Warning
		FilteredAppender appender = new FilteredAppender();
		User testUser = generateUser();
		insert testUser;

		insert new fflib_LogLevelFilter__c(

				SetupOwnerId = testUser.ProfileId,
				LogLevel__c = System.LoggingLevel.WARN.name()
		);

		// When - we check if WARNING is valid
		Boolean isValid = false;
		System.runAs(testUser)
		{
			isValid = appender.checkValidLogLevel(System.LoggingLevel.WARN);
		}

		// Then - It should be valid
		System.assert(isValid);
	}*/

	@IsTest
	static void itShouldValidateWarningLevelWithDefaultOrganisationLogLevelValueSetToWarning()
	{
		// GIVEN - A default AppenderFilter instance with log level set to ERROR
		//          and a custom setting at Organisation Level to WARNING
		FilteredAppender appender = new FilteredAppender();

		fflib_LogLevelFilter__c settings = fflib_LogLevelFilter__c.getOrgDefaults();
		settings.LogLevel__c = 'WARN';
		upsert settings fflib_LogLevelFilter__c.Id;

		// WHEN - We check if WARNING is valid
		Boolean isValid = appender.checkValidLogLevel(System.LoggingLevel.WARN);

		// Then - It should be valid
		System.assert(isValid);
	}

	@IsTest
	static void itShouldValidateWarningLevelWithDefaultOrganisationLogLevelValueSetToLowerCaseWarning()
	{
		// GIVEN - A default AppenderFilter instance with log level set to ERROR
		//          and a custom setting at Organisation Level to WARNING
		FilteredAppender appender = new FilteredAppender();

		fflib_LogLevelFilter__c settings = fflib_LogLevelFilter__c.getOrgDefaults();
		settings.LogLevel__c = 'warn';
		upsert settings fflib_LogLevelFilter__c.Id;

		// WHEN - We check if WARNING is valid
		Boolean isValid = appender.checkValidLogLevel(System.LoggingLevel.WARN);

		// Then - It should be valid
		System.assert(isValid);
	}


	@IsTest
	static void itShouldNotFailWithIncorrectValueSetForDefaultOrganisationLogLevel()
	{
		// GIVEN - A default AppenderFilter instance with log level set to ERROR
		//          and a custom setting at Organisation Level to FAIL
		FilteredAppender appender = new FilteredAppender();

		fflib_LogLevelFilter__c settings = fflib_LogLevelFilter__c.getOrgDefaults();
		settings.LogLevel__c = 'Fail';
		upsert settings fflib_LogLevelFilter__c.Id;

		// WHEN - We check if WARNING is valid
		Boolean isValid = appender.checkValidLogLevel(System.LoggingLevel.WARN);

		// Then - It should be valid
		System.assert(!isValid);
	}

	@IsTest
	static void itShouldNotLogWhenSetToNone()
	{
		// GIVEN - A default AppenderFilter instance with log level set to NONE
		FilteredAppender appender = new FilteredAppender();
		appender.setLoggingLevel(System.LoggingLevel.NONE);

		// WHEN - We check if WARNING is valid
		Boolean isValid = appender.checkValidLogLevel(System.LoggingLevel.WARN);

		// Then - It should not be valid
		System.assert(!isValid);
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

	private class FilteredAppender extends fflib_ALogAppenderFilter
	{
		public Boolean checkValidLogLevel(System.LoggingLevel logLevel)
		{
			return isValidLogLevel(logLevel);
		}

		public void append(fflib_LogEntry logEntry) {}
	}
}