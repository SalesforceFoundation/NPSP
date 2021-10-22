/**
 * File Name: fflib_LogEventAppender
 * Description: Log Appender for publishing Platform Events
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
public virtual without sharing class fflib_LogEventAppender extends fflib_ALogAppenderFilter
{

	/**
	 * Publish a platform event fflib_LogEvent__e with the given message and logging level if it meets the minimum logging level
	 *
	 * @param logEntry The new log entry to append
	 */
	public virtual void append(fflib_LogEntry logEntry)
	{
		if (!isValidLogLevel(logEntry.logLevel)) return;

		publishEvents(
				new List<fflib_LogEvent__e>
				{
						logEntry.toPlatformEvent()
				});
	}

	/**
	 * publishEvents
	 *
	 * @description Publish the given fflib_LogEvent__e events and report if there are any errors
	 * @param events The Platform events to publish
	 */
	protected virtual void publishEvents(List<fflib_LogEvent__e> events)
	{
		List<Database.SaveResult> results = EventBus.publish(events);
		checkAndReportErrors(results);
	}


	/**
	 * checkAndReportErrors
	 *
	 * @description Iterate over the given Database.SaveResults and report any errors
	 * @param saveResults
	 */
	protected void checkAndReportErrors(List<Database.SaveResult> saveResults)
	{
		// Inspect publishing result for each event
		for (Database.SaveResult saveResult : saveResults)
		{
			if (!saveResult.isSuccess())
			{
				reportError(saveResult);
			}
		}
	}

	/**
	 * reportError
	 *
	 * @description Construct the error message for the failing Database.SaveResult and throws an exception
	 * @param saveResult
	 *
	 * @throws fflib_LogEventAppender.fflib_LogEventAppenderException
	 */
	protected virtual void reportError(Database.SaveResult saveResult)
	{
		String errorMessage = 'Error while publishing Log event:';
		for (Database.Error databaseError : saveResult.getErrors())
		{
			errorMessage += String.format(
					' {0} - {1}, ',
					new List<String>
					{
							String.valueOf(databaseError.getStatusCode()),
							databaseError.getMessage()
					}
			);
		}
		throw new fflib_LogEventAppenderException(errorMessage);
	}

	public class fflib_LogEventAppenderException extends Exception {}
}