/**
 * File Name: fflib_AppBinding 
 * @description Definition for an Application Binding
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
public virtual class fflib_AppBinding
		implements fflib_IAppBinding, Comparable
{
	protected Object bindingObject { get; set; }
	protected Decimal bindingSequence { get; set; }
	protected fflib_AppBindingType bindingType { get; set; }
	protected System.Type implementationType { get; set; }
	protected System.Type interfaceType { get; set; }
	protected String namespacePrefix { get; set; }
	protected fflib_SharingMode sharingMode { get; set; }

	public Integer compareTo(Object compareTo)
	{
		fflib_IAppBinding compareToEmp = (fflib_IAppBinding) compareTo;
		if (getSequence() == compareToEmp.getSequence()) return 0;
		if (getSequence() > compareToEmp.getSequence()) return 1;
		return -1;
	}

	/**
	 * @return Returns the Object to which the binding is bound to.
	 */
	public Object getBindingObject()
	{
		return this.bindingObject;
	}

	/**
	 * @return Returns the enum value fflib_AppBindingType that defines the type of the binding
	 *
	 * @see fflib_AppBindingType
	 */
	public virtual fflib_AppBindingType getBindingType()
	{
		return this.bindingType;
	}

	/**
	 * @return Returns the System.Type of the implementation class for the binding
	 */
	public virtual System.Type getImplementationType()
	{
		return this.implementationType;
	}

	/**
	 * @return Returns the System.Type of the interface for the binding
	 */
	public virtual System.Type getInterfaceType()
	{
		return this.interfaceType;
	}

	/**
	 * @return Returns the Namespace for the binding
	 */
	public virtual String getNamespacePrefix()
	{
		return this.namespacePrefix;
	}

	/**
	 * @return Returns the number of the order sequence in which the binding should be returned
	 */
	public virtual Decimal getSequence()
	{
		return this.bindingSequence;
	}

	/**
	 * @return Returns an enum value fflib_SharingMode that defines the type of sharing used in the implementation class
	 *
	 * @see fflib_SharingMode
	 */
	public virtual fflib_SharingMode getSharingMode()
	{
		return this.sharingMode;
	}

	/**
	 * Creates a new instance of the implementation for this binding.
	 *
	 * @return The enum value fflib_SharingMode that defines the type of sharing used in the implementation class
	 */
	public virtual Object newImplInstance()
	{
		return implementationType.newInstance();
	}

	/**
	 * Sets the Object to which the binding is bound to
	 *
	 * @param bindingObject An object representing the binding type, e.g.;
	 *                      `MyCustomerInfo.class` or `Schema.Account.SObjectType`
	 *
	 * @return An instance of itself to enable method chaining
	 */
	public virtual fflib_IAppBinding setBindingObject(Object bindingObject)
	{
		this.bindingObject = bindingObject;
		return this;
	}

	/**
	 * Sets the bindingType to an enum value of fflib_AppBindingType
	 *
	 * @param bindingType An enum value of fflib_AppBindingType to define the type of binding, e.g.;
	 *                   `Service` or `Domain`
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @see fflib_AppBindingType
	 */
	public virtual fflib_IAppBinding setBindingType(fflib_AppBindingType bindingType)
	{
		this.bindingType = bindingType;
		return this;
	}

	/**
	 * Sets the System.Type of the implementation class for the binding
	 *
	 * @param implementationType The System.Type of the implementation class. e.g.; `AccountsServiceImpl.class`
	 *
	 * @return An instance of itself to enable method chaining
	 */
	public virtual fflib_IAppBinding setImplementationType(System.Type implementationType)
	{
		this.implementationType = implementationType;
		return this;
	}

	/**
	 * Sets the System.Type of the interface for the binding
	 *
	 * @param interfaceType The System.Type of the interface class. e.g.; `IAccountsService.class`.
	 *                      This must match the type of the implementation.
	 *
	 * @return An instance of itself to enable method chaining
	 */
	public virtual fflib_IAppBinding setInterfaceType(System.Type interfaceType)
	{
		this.interfaceType = interfaceType;
		return this;
	}

	/**
	 * Sets the Namespace for the binding. This is typically used when Apps use Namespaces
	 * or have multiple packages inside a single project
	 *
	 * @param namespacePrefix The name of the Namespace for the binding
	 *
	 * @return An instance of itself to enable method chaining
	 */
	public virtual fflib_IAppBinding setNamespacePrefix(String namespacePrefix)
	{
		this.namespacePrefix = namespacePrefix;
		return this;
	}

	/**
	 * Set the order number so that the resolver can sort the bindings.
	 * The higher the number, the more priority.
	 * The binding with the highest number will be returned first by the resolver.
	 *
	 * @param sequence A decimal number representing the priority of the binding
	 *
	 * @return An instance of itself to enable method chaining
	 */
	public virtual fflib_IAppBinding setSequence(Decimal sequence)
	{
		this.bindingSequence = sequence;
		return this;
	}

	/**
	 * Sets an enum value fflib_SharingMode that defines the type of sharing used in the implementation class
	 *
	 * @param sharingMode A enum value of fflib_SharingMode representing the sharing mode
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @see fflib_SharingMode
	 */
	public virtual fflib_IAppBinding setSharingMode(fflib_SharingMode sharingMode)
	{
		this.sharingMode = sharingMode;
		return this;
	}
}