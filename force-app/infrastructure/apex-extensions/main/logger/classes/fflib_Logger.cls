/**
 * File Name: fflib_Logger
 * Description: Logging utility with standard system.debug log appender and log message formatter
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
public with sharing class fflib_Logger implements fflib_ILogger
{
	public static final String LF = '\n';
	public static final String CR = '\r';

	private static final String ORG_NAMESPACE = [SELECT NamespacePrefix FROM Organization].NamespacePrefix;
	private static final String CLASSNAME = fflib_Logger.class.getName();
	private static final Pattern STACK_LINE =
			Pattern.compile('^(?:Class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$');


	protected List<fflib_ILogAppender> logAppenders = new List<fflib_ILogAppender>
	{
			new SystemAppender()
	};

	protected fflib_ILogMessageFormatter messageFormatter = new LogMessageFormatter();


	public void add(String message)
	{
		add(System.LoggingLevel.INFO, message);
	}

	public void add(LoggingLevel loggingLevel, Exception e)
	{
		add(new fflib_LogEntry(loggingLevel, messageFormatter.format(e)));
	}

	public void add(LoggingLevel loggingLevel, String message)
	{
		add(new fflib_LogEntry(loggingLevel, messageFormatter.format(message)));
	}

	public void add(LoggingLevel loggingLevel, String message, List<String> args)
	{
		add(new fflib_LogEntry(loggingLevel, messageFormatter.format(message, args)));
	}

	private void add(fflib_LogEntry logEntry)
	{
		populateStackTrace(logEntry);
		addLogEntryToAppenders(logEntry);
	}

	public fflib_ILogger addAppender(fflib_ILogAppender appender)
	{
		this.logAppenders.add(appender);
		return this;
	}


	public void debug(Exception e)
	{
		add(System.LoggingLevel.DEBUG, e);
	}

	public void debug(String message)
	{
		add(System.LoggingLevel.DEBUG, message);
	}

	public void debug(String message, List<String> args)
	{
		add(System.LoggingLevel.DEBUG, message, args);
	}

	public void error(Exception e)
	{
		add(System.LoggingLevel.ERROR, e);
	}

	public void error(String message)
	{
		add(System.LoggingLevel.ERROR, message);
	}

	public void error(String message, List<String> args)
	{
		add(System.LoggingLevel.ERROR, message, args);
	}

	public void info(Exception e)
	{
		add(System.LoggingLevel.INFO, e);
	}

	public void info(String message)
	{
		add(System.LoggingLevel.INFO, message);
	}

	public void info(String message, List<String> args)
	{
		add(System.LoggingLevel.INFO, message, args);
	}

	public fflib_ILogger setAppender(fflib_ILogAppender appender)
	{
		this.logAppenders.clear();
		this.logAppenders.add(appender);
		return this;
	}

	public fflib_ILogger setMessageFormatter(fflib_ILogMessageFormatter formatter)
	{
		this.messageFormatter = formatter;
		return this;
	}

	public void warning(String message)
	{
		add(System.LoggingLevel.WARN, message);
	}

	public void warning(String message, List<String> args)
	{
		add(System.LoggingLevel.WARN, message, args);
	}


	private void populateStackTrace(fflib_LogEntry logEntry)
	{
		List<String> stacktrace = new DmlException().getStackTraceString().split('\n');

		for (String line : stacktrace)
		{
			Matcher matcher = STACK_LINE.matcher(line);

			if (matcher.find() && !line.startsWith('Class.' + CLASSNAME + '.'))
			{
				Boolean hasNamespace = String.isNotBlank(matcher.group(3));

				if (hasNamespace)
				{
					logEntry.className =
							(matcher.group(1).equals(ORG_NAMESPACE)) ?
									matcher.group(2)
									:
									matcher.group(1) + '.' + matcher.group(2);

					logEntry.methodName = formatMethodName(matcher.group(3));
				}
				else
				{
					logEntry.className = matcher.group(1);
					logEntry.methodName = formatMethodName(matcher.group(2));
				}

				logEntry.lineNumber = Integer.valueOf(matcher.group(4));
				return;
			}
		}
	}

	private String formatMethodName(String method)
	{
		String result = (method == null) ? 'anonymous' : method;
		return (result.contains('init')) ? 'ctor' : result;
	}

	private void addLogEntryToAppenders(fflib_LogEntry logEntry)
	{
		for (fflib_ILogAppender logAppender : logAppenders)
		{
			logAppender.append(logEntry);
		}
	}

	public virtual class SystemAppender implements fflib_ILogAppender
	{
		public void append(fflib_LogEntry logEntry)
		{
			System.debug(logEntry.className + ' #' + logEntry.lineNumber + ' @'+ logEntry.methodName + ' ' + logEntry.message);
		}
	}

	public virtual class LogMessageFormatter implements fflib_ILogMessageFormatter
	{
		public virtual String format(String message)
		{
			return message;
		}

		public virtual String format(String message, List<String> args)
		{
			return String.format(message, args);
		}

		public virtual String format(Exception e)
		{
			String result = 'Exception: ' + e;
			if (null != e.getCause())
			{
				result += LF + ' Cause: ' + e.getCause();
			}
			result += LF + ' Stack trace: ' + e.getStackTraceString();

			return result;
		}
	}
}