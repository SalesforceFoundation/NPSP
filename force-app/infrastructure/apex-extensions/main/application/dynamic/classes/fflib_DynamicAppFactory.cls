/**
 * File Name: fflib_DynamicAppFactory 
 * @description Abstract class with common functionality for Dynamic Bindings
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
public abstract class fflib_DynamicAppFactory
{
	protected fflib_SharingMode sharingMode
	{
		get
		{
			if (sharingMode == null)
			{
				sharingMode = fflib_SharingMode.WithSharing;
			}
			return sharingMode;
		}
		set;
	}
	protected fflib_IAppBindingResolver resolver;
	protected Map<System.Type, System.Type> routes;

	protected Map<Object, Object> mockImplByObjectType = new Map<Object, Object>();

	protected void setMock(Object objectType, Object mock)
	{
		this.mockImplByObjectType.put(
				objectType,
				mock
		);
	}

	protected Object getMock(Object objectType)
	{
		return this.mockImplByObjectType.get(objectType);
	}

	protected Boolean hasMock(Object objectType)
	{
		return this.mockImplByObjectType.containsKey(objectType);
	}
}