/**
 * File Name: fflib_DynamicServiceFactory
 * @description Service Factory to return service class instances in a dynamic way
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
public virtual class fflib_DynamicServiceFactory
		extends fflib_DynamicAppFactory
		implements fflib_IServiceFactory
{
	public static final fflib_AppBindingType SERVICE_BINDING_TYPE = fflib_AppBindingType.Service;

	protected Map<System.Type, Object> mockServiceImplByObjectType = new Map<System.Type, Object>();

	public fflib_DynamicServiceFactory(fflib_IAppBindingResolver resolver)
	{
		this.resolver = resolver;
	}

	public Object newInstance(Type serviceInterfaceType)
	{
		if (hasMock(serviceInterfaceType)) return getMock(serviceInterfaceType);

		List<fflib_IAppBinding> bindings = resolver
				.byType(SERVICE_BINDING_TYPE)
				.byInterfaceType(serviceInterfaceType)
				.bySharingMode(sharingMode)
				.resolve();

		if (bindings.isEmpty())
			throw new DeveloperException(
					String.format(
							'Unable to find service binding for {0} with sharing more {1}',
							new List<String>
							{
									serviceInterfaceType.getName(),
									sharingMode.name()
							}
					)
			);

		return bindings.get(0).newImplInstance();
	}

	public void replaceWith(Type serviceInterfaceType, Type replacementImplType)
	{
		resolver.byType(SERVICE_BINDING_TYPE)
				.byInterfaceType(serviceInterfaceType)
				.bySharingMode(sharingMode)
				.resolve()
				.get(0) // TODO - validate that there are any resolved bindings
				.setImplementationType(replacementImplType);
	}

	public void setMock(Type serviceInterfaceType, Object serviceImpl)
	{
		super.setMock(serviceInterfaceType, serviceImpl);
	}

	public fflib_DynamicServiceFactory setSharingMode(fflib_SharingMode sharingMode)
	{
		this.sharingMode = sharingMode;
		return this;
	}

	public class DeveloperException extends Exception {}
}