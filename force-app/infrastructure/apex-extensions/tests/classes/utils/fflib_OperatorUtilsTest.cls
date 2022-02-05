/**
 * File Name: sflib_sflib_OperatorUtilsTest
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
private class fflib_OperatorUtilsTest
{
	@IsTest
	static void testBehavior()
	{
		System.assertEquals('=', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.EQUALS));
		System.assertEquals('!=', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.NOT_EQUALS));
		System.assertEquals('<', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.LESS_THAN));
		System.assertEquals('<=', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.LESS_THAN_OR_EQUAL_TO));
		System.assertEquals('>', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.GREATER_THAN));
		System.assertEquals('>=', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.GREATER_THAN_OR_EQUAL_TO));
		System.assertEquals('like', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.LIKEx));
		System.assertEquals('IN', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.INx));
		System.assertEquals('NOT IN', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.NOT_IN));
		System.assertEquals('INCLUDES', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.INCLUDES));
		System.assertEquals('EXCLUDES', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.EXCLUDES));
		System.assertEquals(null, fflib_OperatorUtils.operatorToString(null));
	}
}