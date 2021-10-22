/**
 * File Name: fflib_ArrayUtils
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
public class fflib_ArrayUtils
{
	/* private constructor to prevent instantiation */
	private fflib_ArrayUtils() {}

	/**
	 * Creates a clone from the provided list and returns the sorted list
	 *
	 * @param unsortedIntegers List of unsorted Integers
	 *
	 * @return Sorted list or Integers
	 */
	public static List<Integer> cloneAndSort(List<Integer> unsortedIntegers)
	{
		return (List<Integer>) cloneAndSort((List<Object>) unsortedIntegers);
	}

	/**
	 * Creates a clone from the provided list and returns the sorted list
	 *
	 * @param unsorted List of unsorted Objects
	 *
	 * @return Sorted list
	 */
	public static List<Object> cloneAndSort(List<Object> unsorted)
	{
		List<Object> result = unsorted.clone();
		result.sort();
		return result;
	}

	/**
	 * Gets the first value of the list
	 *
	 * @param objects List of objects
	 *
	 * @return The first value of the list. Returns null, is the provided list is null or empty
	 */
	public static Object firstValue(List<Object> objects)
	{
		if (isEmpty(objects)) return null;

		return objects.get(0);
	}

	/**
	 * Validates if a list is empty
	 *
	 * @param objects The list to validate
	 *
	 * @return Returns true of the list is either null or empty
	 */
	public static Boolean isEmpty(List<Object> objects)
	{
		return (null == objects || objects.isEmpty());
	}

	/**
	 * Validates if a list is empty
	 *
	 * @param sObjects The list to validate
	 *
	 * @return Returns true of the list is either null or empty
	 */
	public static Boolean isEmpty(List<SObject> sObjects)
	{
		return (null == sObjects || sObjects.isEmpty());
	}

	/**
	 * Validates if a list is not empty
	 *
	 * @param objects The list to validate
	 *
	 * @return Returns true of the list is not null or not empty
	 */
	public static Boolean isNotEmpty(List<Object> objects)
	{
		return !isEmpty(objects);
	}

	/**
	 * Validates if a list is not empty
	 *
	 * @param sObjects The list to validate
	 *
	 * @return Returns true of the list is not null or not empty
	 */
	public static Boolean isNotEmpty(List<SObject> sObjects)
	{
		return !isEmpty(sObjects);
	}

	/**
	 * Get the last value in the list
	 *
	 * @param objects List of objects
	 *
	 * @return The last value of the list. Returns null, is the provided list is null or empty
	 */
	public static Object lastValue(List<Object> objects)
	{
		if (isEmpty(objects)) return null;

		return objects.get(objects.size() - 1);
	}

	/**
	 * Converts all Strings in the list to lowercase,
	 *   null values are ignored and removed from the list
	 *
	 * @param strings The List of String to convert
	 *
	 * @return Returns the List with only lowercase values
	 */
	public static List<String> lowerCase(List<String> strings)
	{
		List<String> result = new List<String>();
		if (isEmpty(strings)) return result;

		for (String str : strings)
		{
			if (null == str) continue;

			result.add(str.toLowerCase());
		}
		return result;
	}

	/**
	 * Sorts the list with Datetime values and return the highest value in the list
	 *
	 * @param input List of Datetime values
	 *
	 * @return Highest Datetime value of the given input. Returns null when the input is empty or null.
	 */
	public static Datetime maxDatetime(List<Datetime> input)
	{
		if (isEmpty(input)) return null;

		return (Datetime) max((List<Object>) input);
	}

	/**
	 * Sorts the list and return the highest value in the list
	 *
	 * @param input List of values
	 *
	 * @return Highest value of the given input. Returns null when the input is empty or null.
	 */
	public static Object max(List<Object> input)
	{
		if (isEmpty(input)) return null;

		return lastValue(cloneAndSort(input));
	}

	/**
	 * Sorts the list with Datetime values and return the oldest value in the list
	 *
	 * @param input List of Datetime values
	 *
	 * @return Oldest Datetime value of the given input. Returns null when the input is empty or null.
	 */
	public static Datetime minDatetime(List<Datetime> input)
	{
		if (isEmpty(input)) return null;

		return (Datetime) min((List<Object>) input);
	}

	/**
	 * Sorts the list and return the lowest value in the list
	 *
	 * @param input List of  values
	 *
	 * @return Lowest value of the given input. Returns null when the input is empty or null.
	 */
	public static Object min(List<Object> input)
	{
		if (isEmpty(input))	return null;

		List<Object> result = cloneAndSort(input);
		return firstValue(result);
	}

	/**
	 * Casts a list of objects to a list of their literal string version
	 *
	 * @param objects List of objects to convert
	 *
	 * @return Returns a list of Strings with the literal conversion of the object
	 */
	public static List<String> objectToString(List<Object> objects)
	{
		List<String> result = new List<String>();
		if (isEmpty(objects)) return result;

		for (Object obj : objects)
		{
			result.add(String.valueOf(obj));
		}
		return result;
	}

	/**
	 * Casts a Set of objects to a list of their literal string version
	 *
	 * @param objects Set of objects to convert
	 *
	 * @return Returns a list of Strings with the literal conversion of the object
	 */
	public static List<String> objectToString(Set<Object> objects)
	{
		return objectToString(new List<Object>(objects));
	}

	/**
	 * Casts a Set of Objects to a list of Ids
	 *    Non Id objects are ignored
	 *
	 * @param objects Set of objects to convert
	 *
	 * @return Returns a list of Strings with the literal conversion of the object
	 */
	public static Set<Id> objectToIds(Set<Object> objects)
	{
		Set<Id> results = new Set<Id>();
		for (Object obj : objects)
		{
			if (!(obj instanceof Id)) continue;

			results.add((Id) obj);
		}
		return results;
	}

	/**
	 * Reverse the order of a list of objects
	 *
	 * @param objects List of Objects
	 *
	 * @return Returns a list of objects in reserve order
	 */
	public static List<Object> reverse(List<Object> objects)
	{
		if (isEmpty(objects)) return objects;

		Integer i = 0;
		Integer j = objects.size() - 1;
		Object tmp;
		while (j > i)
		{
			tmp = objects[j];
			objects[j] = objects[i];
			objects[i] = tmp;
			j--;
			i++;
		}
		return objects;
	}

	/**
	 * Reverse the order of a list of SObjects
	 *
	 * @param sObjects List of SObjects
	 *
	 * @return Returns a list of SObjects in reserve order
	 */
	public static List<SObject> reverse(List<SObject> sObjects)
	{
		if (isEmpty(sObjects)) return sObjects;

		Integer i = 0;
		Integer j = sObjects.size() - 1;
		SObject tmp;
		while (j > i)
		{
			tmp = sObjects[j];
			sObjects[j] = sObjects[i];
			sObjects[i] = tmp;
			j--;
			i++;
		}
		return sObjects;
	}

	/**
	 * Converts all String of the list into uppercase
	 *   null values are ignored
	 *
	 * @param strings The list of Strings to convert
	 *
	 * @return Returns the List with uppercase Strings
	 */
	public static List<String> upperCase(List<String> strings)
	{
		List<String> result = new List<String>();
		if (isEmpty(strings)) return result;

		for (String str : strings)
		{
			if (null == str) continue;

			result.add(str.toUpperCase());
		}
		return result;
	}
}