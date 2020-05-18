/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit tests for Enhanced Recurring Donation Status Mapping Setting
*
*/
@IsTest(IsParallel=true)
public with sharing class RD2_StatusMapper_TEST {
    /***
    * @description RD2_StatusMapper Stub
    */
    public class Stub implements System.StubProvider {

        /***
        * @description Mock RD Status Mapping Settings
        */
        private Map<String, String> stateByStatus = new Map<String, String>();

        /**
        * @description Load Status Mapping Settings mock with default values
        * @return Stub
        */
        public Stub withDefaultMapping() {
            stateByStatus.putAll(new Map<String, String> {
                RD2_Constants.STATUS_ACTIVE => RD2_Constants.STATUS_ACTIVE,
                RD2_Constants.STATUS_LAPSED => RD2_Constants.STATUS_LAPSED,
                RD2_Constants.STATUS_CLOSED => RD2_Constants.STATUS_CLOSED
            });

            return this;
        }

        /**
        * @description Put all Status value into Status Mapping Settings mock
        * @return Stub
        */
        public Stub withAllMapping() {
            List<SelectOption> picklistValues = 
                UTIL_Describe.getSelectOptions(
                    'npe03__Recurring_Donation__c',
                    String.valueOf(npe03__Recurring_Donation__c.Status__c)
                );
            for (SelectOption option : picklistValues) {
                withStatusMapping(option.getValue(), option.getValue());
            }

            return this;
        }

        /**
        * @description Add Status to State to the Statue Mapping Settings
        * @param status The status to mapped from
        * @param state The state to mapped to
        * @return Stub
        */
        public Stub withStatusMapping(String status, String state) {
            stateByStatus.put(status, state);

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
                when 'getState' {
                    return stateByStatus.get((String) args[0]);
                } when else {
                    return null;
                }
            }
        }
    }
}
