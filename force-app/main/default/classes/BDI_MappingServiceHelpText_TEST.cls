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
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Unit tests to cover help text mapping for BDI.
*/
@IsTest
private class BDI_MappingServiceHelpText_TEST {

    {
        UTIL_CustomSettingsFacade.enableHelpTextMapping();
    }

    @IsTest
    static void givenDonationRecordTypeHasNoMappingThenFieldShouldGetDefaultMapping() {
        UTIL_Describe.setInstance(getUtilDescribeStub(
                InlineHelpTextMapping.NO_MAPPING
        ));

        System.assert(BGE_BatchGiftEntry_UTIL.targetFieldsBySourceField.containsKey(
                DataImport__c.Donation_Record_Type_Name__c
        ), DataImport__c.Donation_Record_Type_Name__c +
                ' should always have a default mapping so that it is always presented to' +
                ' the User as an available field in the Batch Configuration Wizard.');

        System.assertNotEquals(null, BGE_ConfigurationWizard_CTRL.getRelevantFields().get(
                DataImport__c.Donation_Record_Type_Name__c
        ), 'The BGE_ConfigurationWizard component should always have a mapping for ' +
                DataImport__c.Donation_Record_Type_Name__c + '.'
        );

        System.assert(BGE_BatchGiftEntry_UTIL.targetFieldsBySourceField.get(
                DataImport__c.Donation_Record_Type_Name__c
        ).getTargetFieldsByTargetObject().get(Opportunity.SObjectType).contains(
                Opportunity.RecordTypeId),
                DataImport__c.Donation_Record_Type_Name__c + ' should be mapped ' +
                        'by default to ' + Opportunity.RecordTypeId);
    }

    @IsTest
    static void givenDonationRecordTypeHasBadMappingThenFieldShouldNotGetDefaultMapping() {
        UTIL_Describe.setInstance(getUtilDescribeStub(
                InlineHelpTextMapping.INVALID_USER_DEFINED_MAPPING
        ));

        System.assert(!BGE_BatchGiftEntry_UTIL.targetFieldsBySourceField.containsKey(
                DataImport__c.Donation_Record_Type_Name__c
        ), 'The default mapping should not be applied if the ' +
                DataImport__c.Donation_Record_Type_Name__c +
                ' field has invalid inline help text.');

        System.assertEquals(null, BGE_ConfigurationWizard_CTRL.getRelevantFields().get(
                DataImport__c.Donation_Record_Type_Name__c
        ), 'The BGE_ConfigurationWizard component should not have a mapping for ' +
                DataImport__c.Donation_Record_Type_Name__c +
                ' when it has invalid inline help text.'
        );
    }

    /**
    * @description Helper method used to create a stub for the UTIL_Describe class.
    * @param inlineHelpTextMapping InlineHelpTextMapping value to assign to the stub.
    * @return Stubbed instance of UTIL_Describe.
    */
    private static UTIL_Describe getUtilDescribeStub(InlineHelpTextMapping
            inlineHelpTextMapping) {
        UTIL_DescribeMock describeMockInstance = new UTIL_DescribeMock();
        describeMockInstance.inlineHelpTextMapping = inlineHelpTextMapping;
        UTIL_Describe stub = (UTIL_Describe) Test.createStub(
                UTIL_Describe.class,
                describeMockInstance
        );
        return stub;
    }

    /**
    * @description Used to test different types of text found in the inline help text of
    * a field.
    */
    private enum InlineHelpTextMapping {
        NO_MAPPING, INVALID_USER_DEFINED_MAPPING
    }

    /**
    * @description StubProvider implementation used to mock different text strings in the
    * help text of the Donation_Record_Type_Name__c field on DataImport__c.
    */
    public class UTIL_DescribeMock implements System.StubProvider {

        public InlineHelpTextMapping inlineHelpTextMapping;

        public Object handleMethodCall(
                Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            SObjectField field = (SObjectField) listOfArgs[0];
            switch on stubbedMethodName {
                when 'getHelpText' {
                    if (field == DataImport__c.Donation_Record_Type_Name__c) {
                        switch on inlineHelpTextMapping {
                            when NO_MAPPING {
                                return '';
                            }
                            when INVALID_USER_DEFINED_MAPPING {
                                return 'xyz';
                            }
                        }
                    }
                }
            }
            return null;
        }
    }
}
