/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @group Product Instrumentation
* @description Mock Service to Unit Testing against the Instrumentation Services
*
*/
@IsTest
public without sharing class SfdoInstrumentationMock_TEST {


    /*******************************************************************************************************************
    * @description Configure the instrumentation Mock and return an instance to the MockService class to allow the 
    * calling test method to assert the resulting values in the classes properties.
    */
    public static MockService injectMockedInstrumentationService() {
        MockService mock = new MockService();
        SfdoInstrumentationService mockService = (SfdoInstrumentationService) Test.createStub(
                SfdoInstrumentationService.class,
                mock);
        SfdoInstrumentationService.instance = mockService;
        return mock;
    }
    
    /**
    * @description StubProvider implementation used to modify the Instrumentation Service
    */
    @TestVisible
    private class MockService implements StubProvider {

        public List<LastCallData> lastCallStack = new List<LastCallData>();

        public SfdoInstrumentationEnum.Feature feature;
        public SfdoInstrumentationEnum.Component component;
        public SfdoInstrumentationEnum.Action actionName;
        public Integer value;
        public Map<String,Object> context;

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> paramTypes, List<String> paramNames,
                List<Object> params) {

            if (stubbedMethodName == 'log') {
                this.feature = (SfdoInstrumentationEnum.Feature) params[0];
                this.component = (SfdoInstrumentationEnum.Component)params[1];
                this.actionName = (SfdoInstrumentationEnum.Action)params[2];
                this.value = null;
                this.context = null;

                for (Integer n=3; n<params.size(); n++) {
                    if (paramNames[n] == 'value') {
                        this.value =  (Integer)params[n];
                    } else if (paramNames[n] == 'context') {
                        this.context =  (Map<String,Object>)params[n];
                    } 
                }
                this.lastCallStack.add(new LastCallData(this.feature, this.component, this.actionName, this.context, this.value));
            }
            return null;
        }
    }

    /**
    * @description Class to store the last call data for all instrumentation calls, allow for deeper validation
    */
    @TestVisible
    private class LastCallData {

        public LastCallData(SfdoInstrumentationEnum.Feature feature, SfdoInstrumentationEnum.Component component, 
                SfdoInstrumentationEnum.Action actionName, Map<String,Object> context, Integer value) {
            this.feature = feature;
            this.component = component;
            this.actionName = actionName;
            this.value = value;
            this.context = context;
        }
    
        public SfdoInstrumentationEnum.Feature feature;
        public SfdoInstrumentationEnum.Component component;
        public SfdoInstrumentationEnum.Action actionName;
        public Integer value;
        public Map<String,Object> context;
    }
}
