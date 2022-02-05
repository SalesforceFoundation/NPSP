/**
 * File Name: fflib_AppBindingResolver
 * @description Resolver for returning the requested binding(s)
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
public virtual class fflib_AppBindingResolver
		implements fflib_IAppBindingResolver
{
	// allow for dependency injection inside the resolver
	protected InternalBindings internalBindings
	{
		get
		{
			if (null == internalBindings)
			{
				internalBindings = new InternalBindings();
			}
			return internalBindings;
		}
		private set;
	}

	protected fflib_IAppBinding bindingToResolve
	{
		get
		{
			if (bindingToResolve == null)
			{
				bindingToResolve = internalBindings.newAppBinding();
			}
			return bindingToResolve;
		}
		private set;
	}

	protected fflib_IAppBindings bindings;
	private List<fflib_IAppBindingModule> modules;

	public static fflib_IAppBindingResolver newInstance()
	{
		return new fflib_AppBindingResolver();
	}

	/**
	 * Constructors
	 */
	public fflib_AppBindingResolver()
	{
	}

	/**
	 * Providing routes to the AppBindingResolver constructor provides dependency injection inside the resolver
	 *
	 * @param routes The routes
	 */
	public fflib_AppBindingResolver(fflib_IAppBindingRouter routes)
	{
		this(routes.getRoutes());
	}

	public fflib_AppBindingResolver(Map<System.Type, System.Type> internalBindings)
	{
		this.internalBindings = new InternalBindings(internalBindings);
	}

	public fflib_IAppBindingResolver addModule(fflib_IAppBindingModule bindingModule)
	{
		if (null == this.modules) this.modules = new List<fflib_IAppBindingModule>();

		this.modules.add(bindingModule);
		return this;
	}

	public fflib_IAppBindingResolver byObject(Object bindingObject)
	{
		this.bindingToResolve.setBindingObject(bindingObject);
		return this;
	}

	public fflib_IAppBindingResolver bySequence(Integer sequence)
	{
		this.bindingToResolve.setSequence(sequence);
		return this;
	}

	public fflib_IAppBindingResolver byType(fflib_AppBindingType bindingType)
	{
		this.bindingToResolve.setBindingType(bindingType);
		return this;
	}

	public fflib_IAppBindingResolver byInterfaceType(Type interfaceType)
	{
		this.bindingToResolve.setInterfaceType(interfaceType);
		return this;
	}

	public fflib_IAppBindingResolver bySharingMode(fflib_SharingMode sharingMode)
	{
		this.bindingToResolve.setSharingMode(sharingMode);
		return this;
	}

	public fflib_IAppBindingResolver byNamespacePrefix(String namespacePrefix)
	{
		this.bindingToResolve.setNamespacePrefix(namespacePrefix);
		return this;
	}


	/**
	 * Handles lazy loading of modules, if no custom module is configured (via addModule) the default module is returned
	 *
	 * @return Returns the configured modules
	 */
	public List<fflib_IAppBindingModule> getModules()
	{
		if (null == this.modules)
		{
			// Lazy load the default Binding module is none other is set.
			modules = new List<fflib_IAppBindingModule>
			{
					internalBindings.newAppBindingModule()
			};
		}
		return modules;
	}

	public List<fflib_IAppBinding> resolve()
	{
		if (!hasBindingsLoaded()) loadBindings();

		fflib_IAppBindings resolvedBindings =
				this.bindings
						.selectByNamespacePrefix(bindingToResolve.getNamespacePrefix())
						.selectByType(bindingToResolve.getBindingType())
						.selectByInterfaceType(bindingToResolve.getInterfaceType())
						.selectByObject(bindingToResolve.getBindingObject())
						.selectBySharingMode(bindingToResolve.getSharingMode())
						.selectBySequence(bindingToResolve.getSequence());

		this.bindingToResolve = internalBindings.newAppBinding();
		return resolvedBindings.getBindings();
	}


	protected Boolean hasBindingsLoaded()
	{
		return (this.bindings != null);
	}

	/**
	 * Prepares a domain to store the bindings,
	 * retrieves the bindings from the modules
	 * and stores the bindings in this.bindings
	 */
	protected virtual void loadBindings()
	{
		this.bindings = internalBindings.newAppBindings();
		List<fflib_IAppBindingModule> modules = getModules();
		List<fflib_IAppBinding> appBindings = loadModules(modules);
		this.bindings.addBindings(
				appBindings
		);
	}

	/**
	 * Initialises all the modules and retrieves their binding.
	 * Any child modules in all nested will also be initialised and processed
	 *
	 * @param modules The modules to load their binding
	 *
	 * @return Returns the bindings configured in the given modules
	 */
	protected virtual List<fflib_IAppBinding> loadModules(List<fflib_IAppBindingModule> modules)
	{
		List<fflib_IAppBinding> result = new List<fflib_IAppBinding>();
		for (fflib_IAppBindingModule module : getModules())
		{
			module.init();
			List<fflib_IAppBinding> bindings = module.getBindings();
			List<fflib_IAppBindingModule> subModules = getModulesFromBindings(bindings);

			if (subModules.isEmpty() == false)
			{
				result.addAll(
						loadModules(subModules)
				);
			}
			result.addAll(bindings);
		}
		return result;
	}

	/**
	 * Retrieves the bindings of the type module from the given list and returns their instance
	 *
	 * @param bindings The bindings to filter
	 *
	 * @return Returns the instances of Module bindings
	 */
	private List<fflib_IAppBindingModule> getModulesFromBindings(List<fflib_IAppBinding> bindings)
	{
		List<fflib_IAppBindingModule> result = new List<fflib_IAppBindingModule>();
		for (fflib_IAppBinding binding : bindings)
		{
			if (binding.getBindingType() != fflib_AppBindingType.Module) continue;

			Object instance = binding.newImplInstance();
			if (!(instance instanceof fflib_IAppBindingModule))
				throw new DeveloperException(
						'Binding module should be an instance of fflib_IAppBindingModule, instead found: '
								+ binding.getImplementationType().getName()
				);

			result.add(
					(fflib_IAppBindingModule) instance
			);
		}
		return result;
	}

	public class InternalBindings
	{
		private Map<System.Type, System.Type> bindings;

		public InternalBindings()
		{
		}

		public InternalBindings(Map<System.Type, System.Type> internalBindings)
		{
			this.bindings = internalBindings;
		}

		public fflib_IAppBinding newAppBinding()
		{
			System.Type interfaceType = fflib_IAppBinding.class;
			if (hasInternalBinding(interfaceType))
			{
				Object instance = getInternalBinding(interfaceType);
				if (!(instance instanceof fflib_IAppBinding))
					throw new DeveloperException('Invalid internal binding for fflib_IAppBinding');

				return (fflib_IAppBinding) instance;
			}

			return new fflib_AppBinding();
		}

		public fflib_IAppBindings newAppBindings()
		{
			System.Type interfaceType = fflib_IAppBindings.class;
			if (hasInternalBinding(interfaceType))
			{
				Object instance = getInternalBinding(interfaceType);
				if (!(instance instanceof fflib_IAppBinding))
					throw new DeveloperException('Invalid internal binding for fflib_IAppBindings');

				return (fflib_IAppBindings) instance;
			}

			return new fflib_AppBindings();
		}

		private Boolean hasInternalBinding(System.Type interfaceType)
		{
			return this.bindings != null && this.bindings.containsKey(interfaceType);
		}

		private Object getInternalBinding(System.Type interfaceType)
		{
			return this.bindings.get(interfaceType).newInstance();
		}

		private fflib_IAppBindingModule newAppBindingModule()
		{
			System.Type interfaceType = fflib_IAppBindingModule.class;
			if (hasInternalBinding(interfaceType))
			{
				Object instance = getInternalBinding(interfaceType);
				if (!(instance instanceof fflib_IAppBindingModule))
					throw new DeveloperException('Invalid internal binding for fflib_IAppBindingModule');

				return (fflib_IAppBindingModule) instance;
			}

			return new fflib_AppBindingMetaDataModule();
		}
	}

	public class DeveloperException extends Exception {}
}