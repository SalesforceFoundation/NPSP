/**
 * File Name: fflib_ALogAppenderFilter
 * Description: Log Appender that includes a filter for logginglevel 
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
public abstract with sharing class fflib_ALogAppenderFilter implements fflib_ILogAppender
{
	// The default logging level that must be met before log messages are processed
	public static final System.LoggingLevel DEFAULT_LEVEL = System.LoggingLevel.ERROR;

	// The current used logging level which can be modified during runtime
	protected System.LoggingLevel minLogLevel = DEFAULT_LEVEL;

	/**
	 * setLoggingLevel
	 *
	 * @description Change the current minimum logging level
	 * @param logLevel
	 */
	public void setLoggingLevel(System.LoggingLevel logLevel)
	{
		this.minLogLevel = logLevel;
	}

	/**
	 * isValidLogLevel
	 *
	 * @description Compares the Organisation, User and Apex logging level settings
	 * @param logLevel
	 *
	 * @return Returns true if one of the settings is equal or higher than the given loglevel
	 */
	protected Boolean isValidLogLevel(System.LoggingLevel logLevel)
	{
		return (
				isValidOrganisationLogLevel(logLevel) ||
				isValidUserLogLevel(logLevel) ||
				isValidApexClassLogLevel(logLevel)
		);
	}

	/**
	 * isValidLogLevel
	 *
	 * @description Compares the given log level valueToCompare against the compareTo
	 * @param compareTo The log level to compare against
	 * @param valueToCompare The log level to compare
	 *
	 * @return Returns true if the valueToCompare is equal of higher then the compareTo
	 */
	private Boolean isValidLogLevel(System.LoggingLevel compareTo, System.LoggingLevel valueToCompare)
	{
		return compareTo != System.LoggingLevel.NONE
					&&
				valueToCompare != System.LoggingLevel.NONE
					&&
				valueToCompare.ordinal() >= compareTo.ordinal();
	}

	/**
	 * isValidApexClassLogLevel
	 *
	 * @description Compare the given loglevel against the current Apex setting stored in this.minLogLevel
	 * @param logLevel The log level to compare
	 *
	 * @return Returns true if the given log level is equal of higher then the Apex setting
	 */
	private Boolean isValidApexClassLogLevel(System.LoggingLevel logLevel)
	{
		return isValidLogLevel(this.minLogLevel, logLevel);
	}

	/**
	 * isValidOrganisationLogLevel
	 *
	 * @description Compare the given loglevel against the Organisation setting stored in a Custom Setting
	 * @param logLevel The log level to compare
	 *
	 * @return Returns true if the given log level is equal of higher then the Organisation setting
	 */
	private Boolean isValidOrganisationLogLevel(System.LoggingLevel logLevel)
	{
		return isValidLogLevel(
				getDefaultOrganisationLogLevel(),
				logLevel
		);
	}

	/**
	 * isValidUserLogLevel
	 *
	 * @description Compare the given loglevel against the User setting stored in a Custom Setting
	 * @param logLevel The log level to compare
	 *
	 * @return Returns true if the given log level is equal of higher then the User setting
	 */
	private Boolean isValidUserLogLevel(System.LoggingLevel logLevel)
	{
		return isValidLogLevel(
				getUserLogLevel(),
				logLevel
		);
	}

	/**
	 * getDefaultOrganisationLogLevel
	 *
	 * @return Returns the default Organisation log level setting stored in fflib_LogLevelFilter__c
	 */
	private System.LoggingLevel getDefaultOrganisationLogLevel()
	{
		fflib_LogLevelFilter__c orgSettings = fflib_LogLevelFilter__c.getOrgDefaults();
		if (String.isBlank(orgSettings.LogLevel__c))
		{
			return System.LoggingLevel.NONE;
		}
		return stringToLoggingLevel(orgSettings.LogLevel__c);
	}

	/**
	 * getUserLogLevel
	 *
	 * @return Returns the default User log level setting stored in user or profile setting in fflib_LogLevelFilter__c
	 */
	private System.LoggingLevel getUserLogLevel()
	{
		fflib_LogLevelFilter__c logLevelFilter = fflib_LogLevelFilter__c.getInstance(UserInfo.getUserId());
		if (!hasSettingsValue(logLevelFilter, fflib_LogLevelFilter__c.LogLevel__c))
		{
			return System.LoggingLevel.NONE;
		}
		return stringToLoggingLevel(logLevelFilter.LogLevel__c);
	}

	/**
	 * hasSettingsValue
	 *
	 * @description Validates if the Custom Setting has a value stored in the given field
	 * @param setting The Custom Setting to validate
	 * @param sObjectField The field to check
	 *
	 * @return Returns true is the given field is set in the Custom Setting
	 */
	private Boolean hasSettingsValue(fflib_LogLevelFilter__c setting, SObjectField sObjectField)
	{
		return (
				null != setting
						&&
				setting.getPopulatedFieldsAsMap().containsKey(sObjectField.getDescribe().getName())
		);
	}

	/**
	 * stringToLoggingLevel
	 *
	 * @param logLevelToConvert
	 *
	 * @return Returns the Log level for a given string, and System.LoggingLevel.None is an invalid string is given
	 */
	private System.LoggingLevel stringToLoggingLevel(String logLevelToConvert)
	{
		String logLevelString = logLevelToConvert.toUpperCase();
		for (System.LoggingLevel logLevel : System.LoggingLevel.values())
		{
			if (logLevelString == logLevel.name())
			{
				return logLevel;
			}
		}
		return System.LoggingLevel.NONE;
	}
}