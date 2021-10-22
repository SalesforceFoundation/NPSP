/**
 * File Name: fflib_ClassicDomainFactory 
 * @description Domain Factory for creating instances of Domain classes
 *              using a static map for linking the SObjectType to its Domain Constructor implementation class
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
public virtual class fflib_ClassicDomainFactory
		extends fflib_Application.DomainFactory
		implements fflib_IDomainFactory
{
	protected fflib_ISelectorFactory selectorFactory;

	/**
	 * Constructs a Domain factory
	 **/
	public fflib_ClassicDomainFactory()	{}

	/**
	 * Constructs a Domain factory, based on a map linking the ObjectType to the
	 * implementation class type.
	 * Note: this will not check if the Apex classes actually implements the
	 *       interfaces since this is not possible in the Apex runtime at present
	 *
	 * @param selectorFactory, A reference to the Selector Factory instance, an instance of fflib_ISelectorFactory
	 * @param constructorTypeByObject Map of Domain classes by Object Type
	 **/
	public fflib_ClassicDomainFactory(
			fflib_ISelectorFactory selectorFactory,
			Map<Object, Type> constructorTypeByObject)
	{
		selectorFactory = selectorFactory;
		this.constructorTypeByObject = constructorTypeByObject;
		this.mockDomainByObject = new Map<Object, fflib_IDomain>();
	}

	/**
	 * Constructs a Domain factory, using an instance of the Selector Factory
	 *   and a map of Apex classes implementing fflib_ISObjectDomain by SObjectType
	 *   Note this will not check the Apex classes provided actually implement the interfaces
	 *     since this is not possible in the Apex runtime at present
	 * Use only for backwards compatibility.
	 *
	 * @param selectorFactory , e.g. Application.Selector
	 * @param sObjectByDomainConstructorType Map of Apex classes by SObjectType
	 **/
	public fflib_ClassicDomainFactory(fflib_ISelectorFactory selectorFactory,
			Map<SObjectType, Type> sObjectByDomainConstructorType)
	{
		this.selectorFactory = selectorFactory;
		this.constructorTypeByObject = getConstructorTypeByObject(sObjectByDomainConstructorType);
		this.mockDomainByObject = new Map<Object, fflib_IDomain>();
	}

	/**
	 * Dynamically constructs an instance of a Domain class for the given record Ids
	 *   Internally uses the Selector Factory to query the records before passing to a
	 *   dynamically constructed instance of the application Apex Domain class
	 *
	 * @param recordIds A list of Id's of the same type
	 *
	 * @return Instance of a Domain containing the queried records
	 * @exception Throws an exception via the Selector Factory if the Ids are not all of the same SObjectType
	 **/
	public virtual override fflib_IDomain newInstance(Set<Id> recordIds)
	{
		return newInstance(selectorFactory.selectById(recordIds));
	}

	/**
	 * Dynamically constructs an instance of a Domain class for the given record Ids
	 *   Internally uses the Selector Factory to query the records before passing to a
	 *   dynamically constructed instance of the application Apex Domain class
	 *
	 * @param recordIds A list of Id's of the same type
	 * @param sObjectType The SObjectType of the given record Ids
	 *
	 * @return Instance of a Domain containing the queried records
	 * @exception Throws an exception via the Selector Factory if the Ids are not all of the same SObjectType
	 **/
	public virtual fflib_IDomain newInstance(Set<Id> recordIds, Schema.SObjectType sObjectType)
	{
		return newInstance(selectorFactory.selectById(recordIds, sObjectType), sObjectType);
	}

	/**
	 * Creates or replaces an existing binding for another
	 *
	 * @param sObjectType The SObjectType of the selector to replace
	 * @param replacementImplType The implementation type of the replacement
	 */
	public virtual void replaceWith(Schema.SObjectType sObjectType, Type replacementImplType)
	{
		this.constructorTypeByObject.put(
				(Object) sObjectType,
				replacementImplType
		);
	}

	/**
	 * @param mockDomain The instance of the Domain mock
	 */
	public virtual override void setMock(fflib_ISObjectDomain mockDomain)
	{
		super.setMock(mockDomain);
	}

	/**
	 * @param sObjectType The SObjectType of the Domain mock,
	 *                    avoids the need to stub the mock to return its SObjectType
	 * @param mockDomain The instance of the Domain mock
	 */
	public virtual void setMock(Schema.SObjectType sObjectType, fflib_ISObjectDomain mockDomain)
	{
		mockDomainByObject.put((Object) sObjectType, mockDomain);
	}

	/**
	 * @param mockDomain The instance of the Domain mock
	 */
	public virtual override void setMock(fflib_IDomain mockDomain)
	{
		super.setMock(mockDomain);
	}

	/**
	 * @param domainType The ObjectType of the Domain mock,
	 *                    avoids the need to stub the mock to return its ObjectType
	 * @param mockDomain The instance of the Domain mock
	 */
	public virtual void setMock(Object domainType, fflib_IDomain mockDomain)
	{
		mockDomainByObject.put(domainType, mockDomain);
	}
}