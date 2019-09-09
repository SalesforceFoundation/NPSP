/*
    Copyright (c) 2019 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2019
* @group Settings
* @description Recurring Donations Settings tests
*
*/
@isTest
public with sharing class RD2_Settings_TEST {

    /***
    * @description Verifies configuration when settings is not set up
    */
    @isTest
    private static void shouldReturnDefaultsWhenNotSetUp() {
        RD2_Settings settings = new RD2_Settings();
        
        System.assertEquals(false, settings.isAutomaticNamingEnabled(), 'Automatic Naming should be disabled by default');
    }

    /***
    * @description Verifies set configuration
    */
    @isTest
    private static void shouldReturnEnableAutomaticNamingValue() {
        npe03__Recurring_Donations_Settings__c orgDefaults = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
        orgDefaults.EnableAutomaticNaming__c = true;
        upsert orgDefaults;

        RD2_Settings settings = new RD2_Settings();
        
        System.assertEquals(true, settings.isAutomaticNamingEnabled(), 'Automatic Naming value should be returned');
    }



    /****
    * @description Stub for settings instance
    */
    public class Stub implements System.StubProvider {
        private Boolean isAutomaticNamingEnabled = false;
        private Boolean isEnhancedRDEnabled = false;

        public Stub withAutomaticNamingEnabled() {
            isAutomaticNamingEnabled = true;
            return this;
        }

        public Stub withEnhancedRDEnabled() {
            isEnhancedRDEnabled = true;
            return this;
        }

        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            switch on methodName {
                when 'isAutomaticNamingEnabled' {
                    return isAutomaticNamingEnabled;

                } when 'isEnhancedRDEnabled' {
                    return isEnhancedRDEnabled;

                } when else {
                    return null;
                }
            }
        }
    }

}