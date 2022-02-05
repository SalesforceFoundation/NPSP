/**
 * File Name: fflib_AppBindings 
 * @description Domain class for fflib_AppBinding objects
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
public virtual class fflib_AppBindings
		implements fflib_IAppBindings
{
	protected List<fflib_IAppBinding> bindings;

	public fflib_AppBindings() {	}

	public fflib_AppBindings(List<fflib_IAppBinding> bindings)
	{
		this.bindings = bindings;
	}

	public void addBinding(fflib_IAppBinding binding)
	{
		if (null == this.bindings)
		{
			this.bindings = new List<fflib_IAppBinding>{ binding };
		}
		{
			this.bindings.add(binding);
		}
	}

	public void addBindings(List<fflib_IAppBinding> bindings)
	{
		if (null == this.bindings)
		{
			this.bindings = bindings;
		}
		else
		{
			this.bindings.addAll(bindings);
		}
	}

	public fflib_IAppBindings selectByObject(Object bindingObject)
	{
		if (null == bindingObject) return this;

		List<fflib_IAppBinding> result = new List<fflib_IAppBinding>();
		for (fflib_IAppBinding binding : bindings)
		{
			if (binding.getBindingObject() != bindingObject) continue;

			result.add(binding);
		}
		return new fflib_AppBindings(result);
	}

	public fflib_IAppBindings selectBySequence(Decimal sequence)
	{
		bindings.sort();

		if (null == sequence) return this;

		List<fflib_IAppBinding> result = new List<fflib_IAppBinding>();
		for (fflib_IAppBinding binding : bindings)
		{
			if (binding.getSequence() != sequence) continue;

			result.add(binding);
		}
		return new fflib_AppBindings(result);
	}

	public fflib_IAppBindings selectByType(fflib_AppBindingType bindingType)
	{
		if (null == bindingType) return this;

		List<fflib_IAppBinding> result = new List<fflib_IAppBinding>();
		for (fflib_IAppBinding binding : bindings)
		{
			if (binding.getBindingType() != bindingType) continue;

			result.add(binding);
		}
		return new fflib_AppBindings(result);
	}

	public fflib_IAppBindings selectByInterfaceType(Type interfaceType)
	{
		if (null == interfaceType) return this;

		List<fflib_IAppBinding> result = new List<fflib_IAppBinding>();
		for (fflib_IAppBinding binding : bindings)
		{
			if (binding.getInterfaceType() != interfaceType) continue;

			result.add(binding);
		}
		return new fflib_AppBindings(result);
	}

	public fflib_IAppBindings selectBySharingMode(fflib_SharingMode sharingMode)
	{
		if (null == sharingMode) return this;

		List<fflib_IAppBinding> result = new List<fflib_IAppBinding>();
		for (fflib_IAppBinding binding : bindings)
		{
			if (binding.getSharingMode() != sharingMode) continue;

			result.add(binding);
		}
		return new fflib_AppBindings(result);
	}

	public fflib_IAppBindings selectByNamespacePrefix(String namespacePrefix)
	{
		if (null == namespacePrefix) return this;

		List<fflib_IAppBinding> result = new List<fflib_IAppBinding>();
		for (fflib_IAppBinding binding : bindings)
		{
			if (binding.getNamespacePrefix() != namespacePrefix) continue;

			result.add(binding);
		}
		return new fflib_AppBindings(result);
	}

	public List<fflib_IAppBinding> getBindings()
	{
		return this.bindings;
	}

	public List<System.Type> getImplementations()
	{
		List<System.Type> result = new List<System.Type>();
		for (fflib_IAppBinding binding : bindings)
		{
			result.add(
					binding.getImplementationType()
			);
		}
		return result;
	}

	public List<Object> getObjects()
	{
		return getBindings();
	}

	public Object getType()
	{
		return fflib_IAppBinding.class;
	}
}