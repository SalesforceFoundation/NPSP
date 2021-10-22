/**
 * File Name: sflib_sflib_OperatorUtils 
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
public with sharing class fflib_OperatorUtils
{

	public static final fflib_Operator EQUALS = fflib_Operator.EQUALS;
	public static final fflib_Operator NOT_EQUALS = fflib_Operator.NOT_EQUALS;
	public static final fflib_Operator LESS_THAN = fflib_Operator.LESS_THAN;
	public static final fflib_Operator LESS_THAN_OR_EQUAL_TO = fflib_Operator.LESS_THAN_OR_EQUAL_TO;
	public static final fflib_Operator GREATER_THAN = fflib_Operator.GREATER_THAN;
	public static final fflib_Operator GREATER_THAN_OR_EQUAL_TO = fflib_Operator.GREATER_THAN_OR_EQUAL_TO;
	public static final fflib_Operator LIKEx = fflib_Operator.LIKEx;
	public static final fflib_Operator INx = fflib_Operator.INx;
	public static final fflib_Operator NOT_IN = fflib_Operator.NOT_IN;
	public static final fflib_Operator INCLUDES = fflib_Operator.INCLUDES;
	public static final fflib_Operator EXCLUDES = fflib_Operator.EXCLUDES;
	public static final fflib_Operator DEFAULT_sflib_Operator = EQUALS;


	public static String operatorToString(fflib_Operator op)
	{
		if (op == EQUALS)
			return '=';
		else if (op == NOT_EQUALS)
			return '!=';
		else if (op == LESS_THAN)
			return '<';
		else if (op == LESS_THAN_OR_EQUAL_TO)
			return '<=';
		else if (op == GREATER_THAN)
			return '>';
		else if (op == GREATER_THAN_OR_EQUAL_TO)
			return '>=';
		else if (op == LIKEx)
			return 'like';
		else if (op == INx)
			return 'IN';
		else if (op == NOT_IN)
			return 'NOT IN';
		else if (op == INCLUDES)
			return 'INCLUDES';
		else if (op == EXCLUDES)
			return 'EXCLUDES';
		else
				return null;
	}
}