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
* @group Utilities
* @group-content
* @description Test for UTIL_FeatureManagement class. Mainly for code coverage since you can't assert on
* System.FeatureManagement method execution
*
*/
@isTest
public with sharing class UTIL_FeatureManagement_TEST {

    /**
     * @description  Validates feature management package Boolean value is set
     */
    @isTest
    private static void shouldCallSetPackageBooleanValue() {
        UTIL_FeatureManagement featureMgt = new UTIL_FeatureManagement();

        featureMgt.setPackageBooleanValue(
            UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_HouseholdAcctModel.name(),
            false
        );

        System.assertEquals(false, featureMgt.checkPackageBooleanValue(
            UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_HouseholdAcctModel.name())
        );
    }

    /**
     * @description  Validates feature management package Integer value is set
     */
    @isTest
    private static void shouldCallSetPackageIntegerValue() {
        UTIL_FeatureManagement featureMgt = new UTIL_FeatureManagement();

        featureMgt.setPackageIntegerValue(
            UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll.name(),
            1
        );

        System.assertEquals(1, featureMgt.checkPackageIntegerValue(
            UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll.name())
        );
    }

    /**
     * @description Validates feature management Boolean value can be retrieved as it was set
     */
    @isTest
    private static void shouldCallCheckPackageBooleanValue() {
        UTIL_FeatureManagement featureMgt = new UTIL_FeatureManagement();

        featureMgt.setPackageBooleanValue( UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_AddressVerification.name(),
            true
        );

        System.assertEquals(true,
            new UTIL_FeatureEnablement().isEnabled(UTIL_OrgTelemetry_SVC.TelemetryParameterName.IsEnabled_AddressVerification.name()));
    }

    @isTest
    private static void shouldCallCheckPackageDateValue() {
        // Skipping the test if it's running in with a namespace
        // This causes an error en 2gp tests returning the error CANNOT_MODIFY_MANAGED_OBJECT
        if (!String.isBlank(UTIL_Namespace.getNamespace())) {
            return;
        }
        UTIL_FeatureManagement featureMgt = new UTIL_FeatureManagement();

        featureMgt.setPackageDateValue('P10_Application_Date', Date.newInstance(2020, 01, 01));
        
        System.assertEquals(Date.newInstance(2020,01,01), featureMgt.checkPackageDateValue('P10_Application_Date'), 'P10_Application_Date stored different than expected');
    }

    /*******************************************************************************************************************
    * @description Mock for UTIL_FeatureManagement instance
    */
    public class Mock implements System.StubProvider {
        public Map<String, Boolean> packageBooleanValuesByName = new Map<String, Boolean>();
        public Map<String, Integer> packageIntegerValuesByName = new Map<String, Integer>();

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            switch on stubbedMethodName {
                when 'setPackageBooleanValue' {
                    packageBooleanValuesByName.put((String) listOfArgs[0], (Boolean) listOfArgs[1]);
                }

                when 'setPackageIntegerValue' {
                    packageIntegerValuesByName.put((String) listOfArgs[0], (Integer) listOfArgs[1]);
                }

                when 'checkPackageBooleanValue' {
                    return packageBooleanValuesByName.get((String) listOfArgs[0]);
                }

                when 'checkPackageIntegerValue' {
                    return packageIntegerValuesByName.get((String) listOfArgs[0]);
                }
            }
            return null;
        }
    }
}
