/**
 * File Name: fflib_IAppBinding 
 * @description Interface for Application Binding Data Object
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
public interface fflib_IAppBinding
{
	/**
	 * @return Returns the Object to which the binding is bound to.
	 */
	Object getBindingObject();

	/**
	 * @return Returns the enum value fflib_AppBindingType that defines the type of the binding
	 *
	 * @see fflib_AppBindingType
	 */
	fflib_AppBindingType getBindingType();

	/**
	 * @return Returns the System.Type of the implementation class for the binding
	 */
	System.Type getImplementationType();

	/**
	 * @return Returns the System.Type of the interface for the binding
	 */
	System.Type getInterfaceType();

	/**
	 * @return Returns the Namespace for the binding
	 */
	String getNamespacePrefix();

	/**
	 * @return Returns the number of the order sequence in which the binding should be returned
	 */
	Decimal getSequence();

	/**
	 * @return Returns an enum value fflib_SharingMode that defines the type of sharing used in the implementation class
	 *
	 * @see fflib_SharingMode
	 */
	fflib_SharingMode getSharingMode();

	/**
	 * Creates a new instance of the implementation for this binding.
	 *
	 * @return The enum value fflib_SharingMode that defines the type of sharing used in the implementation class
	 */
	Object newImplInstance();

	/**
	 * Sets the Object to which the binding is bound to
	 *
	 * @param bindingObject An object representing the binding type, e.g.;
	 *                      `MyCustomerInfo.class` or `Schema.Account.SObjectType`
	 *
	 * @return An instance of itself to enable method chaining
	 */
	fflib_IAppBinding setBindingObject(Object bindingObject);

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
	fflib_IAppBinding setBindingType(fflib_AppBindingType bindingType);

	/**
	 * Sets the System.Type of the implementation class for the binding
	 *
	 * @param implementationType The System.Type of the implementation class. e.g.; `AccountsServiceImpl.class`
	 *
	 * @return An instance of itself to enable method chaining
	 */
	fflib_IAppBinding setImplementationType(System.Type implementationType);

	/**
	 * Sets the System.Type of the interface for the binding
	 *
	 * @param interfaceType The System.Type of the interface class. e.g.; `IAccountsService.class`.
	 *                      This must match the type of the implementation.
	 *
	 * @return An instance of itself to enable method chaining
	 */
	fflib_IAppBinding setInterfaceType(System.Type interfaceType);

	/**
	 * Sets the Namespace for the binding. This is typically used when Apps use Namespaces
	 * or have multiple packages inside a single project
	 *
	 * @param namespacePrefix The name of the Namespace for the binding
	 *
	 * @return An instance of itself to enable method chaining
	 */
	fflib_IAppBinding setNamespacePrefix(String namespacePrefix);

	/**
	 * Set the order number so that the resolver can sort the bindings.
	 * The higher the number, the more priority.
	 * The binding with the highest number will be returned first by the resolver.
	 *
	 * @param sequence A decimal number representing the priority of the binding
	 *
	 * @return An instance of itself to enable method chaining
	 */
	fflib_IAppBinding setSequence(Decimal sequence);

	/**
	 * Sets an enum value fflib_SharingMode that defines the type of sharing used in the implementation class
	 *
	 * @param sharingMode A enum value of fflib_SharingMode representing the sharing mode
	 *
	 * @return An instance of itself to enable method chaining
	 *
	 * @see fflib_SharingMode
	 */
	fflib_IAppBinding setSharingMode(fflib_SharingMode sharingMode);
}