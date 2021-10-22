/**
 * File Name: fflib_ClassicSelectorFactory 
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
public virtual class fflib_ClassicSelectorFactory
		extends fflib_Application.SelectorFactory
		implements fflib_ISelectorFactory
{
	/**
	 * Constructs a simple Selector Factory
	 **/
	public fflib_ClassicSelectorFactory() {}

	/**
	 * Constructs a Selector Factory linking SObjectType's with Apex Classes implement the fflib_ISObjectSelector interface
	 *   Note that the factory does not check the given Apex Classes implement the interface
	 *     currently this is not possible in Apex.
	 *
	 * @param sObjectBySelectorType Map of SObjectType's to Selector Apex Classes
	 **/
	public fflib_ClassicSelectorFactory(Map<SObjectType, Type> sObjectBySelectorType)
	{
		super(sObjectBySelectorType);
	}

	/**
	 * Helper method to query the given SObject records
	 *   Internally creates an instance of the registered Selector and calls its
	 *   selectSObjectById method.
	 *   It assumes that all Ids are of the given SObjectType, no additional validation is done.
	 *
	 * @param recordIds The recordIds to query
	 * @param sObjectType The SObjectType of the Ids
	 *
	 * @return The queried records
	 * @exception fflib_Application.DeveloperException is thrown if the Ids set is empty
	 */
	public virtual List<SObject> selectById(Set<Id> recordIds, SObjectType sObjectType)
	{
		if (recordIds == null || recordIds.size() == 0)
			throw new fflib_Application.DeveloperException('Invalid record Id\'s set');

		return newInstance(sObjectType)
				.selectSObjectsById(recordIds);
	}

	/**
	 * Creates or replaces an existing binding for another
	 *
	 * @param sObjectType The SObjectType of the selector to replace
	 * @param replacementImplType The implementation type of the replacement
	 */
	public virtual void replaceWith(SObjectType sObjectType, Type replacementImplType)
	{
		this.m_sObjectBySelectorType.put(sObjectType, replacementImplType);
	}

	/**
	 * @param selectorInstance The instance of the mocked selector
	 */
	public virtual override void setMock(fflib_ISObjectSelector selectorInstance)
	{
		super.setMock(selectorInstance);
	}

	/**
	 * @param sObjectType The SObjectType of the selector mock,
	 *                    avoids the need to stub the mock to return its SObjectType
	 * @param selectorInstance The instance of the mocked selector
	 */
	public virtual void setMock(SObjectType sObjectType, fflib_ISObjectSelector selectorInstance)
	{
		this.m_sObjectByMockSelector.put(sObjectType, selectorInstance);
	}
}