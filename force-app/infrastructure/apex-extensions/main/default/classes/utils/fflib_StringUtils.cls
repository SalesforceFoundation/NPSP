/**
 * File Name: fflib_StringUtils
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer
 */
public with sharing class fflib_StringUtils
{
	public static String getBetweenBrackets(String open, String close, String expression, Integer index)
	{
		Integer openChar = open.charAt(0);
		Integer closeChar = close.charAt(0);

		// If index given is invalid and is
		// not an opening bracket.
		if (expression.charAt(index) != openChar)
			new StringException('Expected char \'' + open + '\' as position ' + index);

		// Stack to store opening brackets.
		List<Integer> stack = new List<Integer>();

		// Traverse through string starting from
		// given index.
		for (Integer i = index; i < expression.length(); i++)
		{

			// If current character is an opening bracket push it in stack.
			if (expression.charAt(i) == openChar)
			{
				stack.add(expression.charAt(i));
			}
			// If current character is a closing bracket, pop from stack.
			// If stack is empty, then this closing bracket is required bracket.
			else if (expression.charAt(i) == closeChar)
			{
				stack.remove(stack.size()-1);
				if (stack.isEmpty())
				{
					return expression.substring(index + 1, i);
				}
			}
		}

		return null;
	}

	public class StringException extends Exception {}
}