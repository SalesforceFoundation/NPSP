/**
 * File Name: fflib_DynamicServiceFactoryTest 
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
@IsTest(IsParallel=true)
public class fflib_DynamicServiceFactoryTest
{
    private static final Type MY_SERVICE_INTERFACE_TYPE = fflib_DynamicServiceFactoryTest.IMyService.class;
    private static final Type MY_SERVICE_TYPE = fflib_DynamicServiceFactoryTest.MyService.class;
    private static final Type MY_ALT_SERVICE_TYPE = fflib_DynamicServiceFactoryTest.MyALtService.class;

    @IsTest
	static void itShouldReturnTheCorrectInstance()
	{
        fflib_AppBindingModule module = new fflib_AppBindingModule();
        module.addBinding(createBindingForMyService());
        bindingResolver.addModule(module);

        System.Test.startTest();
        Object instance = Service.newInstance(MY_SERVICE_TYPE);
        System.Test.stopTest();

        System.assert(instance instanceof fflib_DynamicServiceFactoryTest.MyService);
    }

    @IsTest
	static void itShouldReturnTheAlternativeInstance()
	{
        fflib_AppBindingModule module = new fflib_AppBindingModule();
        module.addBinding(createBindingForMyService());
        bindingResolver.addModule(module);
        Service.replaceWith(MyService.class, MyAltService.class);

        System.Test.startTest();
        Object instance = Service.newInstance(MY_SERVICE_TYPE);
        System.Test.stopTest();

        System.assert(instance instanceof fflib_DynamicServiceFactoryTest.MyAltService);
    }

    @IsTest
	static void itShouldReturnTheMockInstance()
	{
        fflib_AppBindingModule module = new fflib_AppBindingModule();
        module.addBinding(createBindingForMyService());
        bindingResolver.addModule(module);
        IMyService mock = new MyAltService();
        Service.setMock(MyService.class, mock);

        System.Test.startTest();
        Object instance = Service.newInstance(MY_SERVICE_TYPE);
        System.Test.stopTest();

        System.assert(instance instanceof fflib_DynamicServiceFactoryTest.MyAltService);
    }

    @IsTest
	static void itShouldReturnTheFirstBindingInstance()
	{
        fflib_AppBindingsSelector.SELECTOR_IMPL_TYPE = AppBindingsSelectorMock.class;

        System.Test.startTest();
        Object instance = Service.newInstance(MY_SERVICE_INTERFACE_TYPE);
        System.Test.stopTest();

        System.assert(instance instanceof fflib_DynamicServiceFactoryTest.MyService);
    }

    @IsTest
	static void itShouldReturnTheSecondBindingInstance()
	{
        fflib_AppBindingsSelector.SELECTOR_IMPL_TYPE = reverseAppBindingsSelectorMock.class;

        System.Test.startTest();
        Object instance = Service.newInstance(MY_SERVICE_INTERFACE_TYPE);
        System.Test.stopTest();

        System.assert(instance instanceof fflib_DynamicServiceFactoryTest.MyAltService);
    }


    private static fflib_AppBinding createBindingForMyService()
    {
        fflib_AppBinding result = new fflib_AppBinding();

        result.setBindingType(fflib_AppBindingType.Service);
        result.setInterfaceType(MY_SERVICE_TYPE);
        result.setImplementationType(MY_SERVICE_TYPE);
        result.setSharingMode(fflib_SharingMode.WithSharing);
        result.setSequence(2);
        return result;
    }

    private static fflib_AppBinding createBindingForMyAltService()
    {
        fflib_AppBinding result = createBindingForMyService();
        result.setImplementationType(MyAltService.class);
        result.setSequence(1);
        return result;
    }

    private static fflib_IAppBindingResolver bindingResolver =
            new fflib_AppBindingResolver();

    private static final fflib_IServiceFactory Service =
            new fflib_DynamicServiceFactory(bindingResolver)
                    .setSharingMode(fflib_SharingMode.WithSharing);

    public interface IMyService {}

    public class MyService implements IMyService {  }

    public class MyAltService implements IMyService { }

    private class AppBindingsSelectorMock extends fflib_AppBindingsSelector
    {
        public override List<fflib_AppBinding__mdt> selectAll()
        {
            return new List<fflib_AppBinding__mdt>
            {
                    new fflib_AppBinding__mdt(
                            Type__c = 'Service',
                            InterfaceType__c = MY_SERVICE_INTERFACE_TYPE.getName(),
                            ImplementationType__c = MY_SERVICE_TYPE.getName(),
                            SharingMode__c = 'With Sharing',
                            BindingSequence__c = 1
                    ),
                    new fflib_AppBinding__mdt(
                            Type__c = 'Service',
                            InterfaceType__c = MY_SERVICE_INTERFACE_TYPE.getName(),
                            ImplementationType__c = MY_ALT_SERVICE_TYPE.getName(),
                            SharingMode__c = 'With Sharing',
                            BindingSequence__c = 2
                    )
            };
        }
    }

    private class reverseAppBindingsSelectorMock extends fflib_AppBindingsSelector
    {
        public override List<fflib_AppBinding__mdt> selectAll()
        {
            return new List<fflib_AppBinding__mdt>
            {
                    new fflib_AppBinding__mdt(
                            Type__c = 'Service',
                            InterfaceType__c = MY_SERVICE_INTERFACE_TYPE.getName(),
                            ImplementationType__c = MY_SERVICE_TYPE.getName(),
                            SharingMode__c = 'With Sharing',
                            BindingSequence__c = 2
                    ),
                    new fflib_AppBinding__mdt(
                            Type__c = 'Service',
                            InterfaceType__c = MY_SERVICE_INTERFACE_TYPE.getName(),
                            ImplementationType__c = MY_ALT_SERVICE_TYPE.getName(),
                            SharingMode__c = 'With Sharing',
                            BindingSequence__c = 1
                    )
            };
        }
    }
}