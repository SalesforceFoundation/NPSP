/*
 *
 *     Copyright (c) 2022, Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 * /
 */
/**
* @author Salesforce.org
* @description This class uses getters to define and return the default interface/implementation bindings for the
 * "Service" binding type to be used by the 'Application.cls' in the fflib dynamic domain factory so that we can
 * define the implementation dynamically instead of callers referencing the domain implementation directly.
*/
public with sharing class ServiceAppBindings {

    public static List<fflib_IAppBinding> getBindings() {
        List<fflib_IAppBinding> serviceAppBindings = new List<fflib_IAppBinding>();
        serviceAppBindings.add(getAccountServiceBinding());

        return serviceAppBindings;
    }

    private static fflib_IAppBinding getAccountServiceBinding() {
        return new fflib_AppBinding()
            .setBindingObject(Account.SObjectType)
            .setBindingType(fflib_AppBindingType.Service)
            .setImplementationType(
                Type.forName(
                    UTIL_Namespace.getNamespace(), 'AccountsServiceImpl')
            )
            .setInterfaceType(
                Type.forName(
                    UTIL_Namespace.getNamespace(), 'IAccountsService')
            )
            .setSharingMode(fflib_SharingMode.WithSharing);
    }
}