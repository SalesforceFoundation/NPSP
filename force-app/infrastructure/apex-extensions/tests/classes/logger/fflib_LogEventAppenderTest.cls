/**
 * File Name: fflib_LogEventAppenderTest
 * Description: Unit test class for fflib_LogEventAppender.cls
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
private class fflib_LogEventAppenderTest
{
	private static final String TEST_ERROR_MESSAGE = 'My Error Message';

	@IsTest
	static void itShouldThrowEventOnAppendedLogEntry()
	{
		// GIVEN - An instance of the LogEventAppender
		fflib_LogEventAppender eventAppender = new fflib_LogEventAppender();


		// WHEN - We append an entry
		Boolean caughtException = false;
		try
		{
			eventAppender.append(new fflib_LogEntry(System.LoggingLevel.ERROR, TEST_ERROR_MESSAGE));
		}
		catch (Exception e)
		{
			caughtException = true;
		}

		// THEN - An Log Event should be thrown
		System.assert(!caughtException);
	}

	@IsTest
	static void itShouldNotAppendInfoMessageWhileDefaultLevelIsSetToError()
	{
		// GIVEN - And appender with a default level set to Error
		fflib_LogEventAppender eventAppender = new fflib_LogEventAppender();

		// WHEN - We append an Info Entry
		eventAppender.append(new fflib_LogEntry(System.LoggingLevel.INFO, TEST_ERROR_MESSAGE));

		// THEN - It should be ignored
		System.assertEquals(0, Limits.getDmlStatements(), 'Oops, the log entry should have been ignored');
	}
}