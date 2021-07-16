/*
    Copyright (c) 2019, Salesforce.org
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
* @group API
* @description Unit Tests for the CallableApiParameters class
*/
@IsTest(IsParallel=true)
private class CallableApiParameters_TEST {

    /**
    * @description Validate that a deserialized set of rollup definitions is returned
    */
    @IsTest
    private static void shouldReturnListRollupDefinitions() {
        List<CRLP_Rollup> rollups = new List<CRLP_Rollup>{ new CRLP_Rollup( new Rollup__mdt() ) };

        String rollupJson = JSON.serialize(rollups);

        Map<String, Object> params = new Map<String, Object>{
            CallableApiParameters.PARAM_ROLLUP_DEFS => rollupJson
        };

        CallableApiParameters service = new CallableApiParameters(params);
        System.assertEquals(1, service.getRollupDefinitions(CallableApiParameters.PARAM_ROLLUP_DEFS).size());
    }

    /**
    * @description Validate that an invalid rollups defintions json throws an exception
    */
    @IsTest
    private static void shouldThrowExceptionOnBadRollupDefsJson() {
        String rollupJson = JSON.serialize( new List<String>{ 'StringList' });

        Map<String, Object> params = new Map<String, Object>{
            CallableApiParameters.PARAM_ROLLUP_DEFS => rollupJson
        };

        CallableApiParameters service = new CallableApiParameters(params);
        try {
            service.getRollupDefinitions(CallableApiParameters.PARAM_ROLLUP_DEFS);
            System.assert(false, 'An exception should have been thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(CallableApiParameters.PARAM_ROLLUP_DEFS),
            'An exception should have been thrown referencing the rollup defintions');
        }
    }

    /**
    * @description Validate that a proper map of SObjects is returned
    */
    @IsTest
    private static void shouldReturnMapOfSobjectData() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(
                npe01__Payments_Enabled__c = true,
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = UTIL_CustomSettingsFacade.DEFAULT_OPPORTUNITY_CONTACT_ROLE_DONOR,
                Contact_Role_for_Organizational_Opps__c = UTIL_CustomSettingsFacade.DEFAULT_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT
            )
        );

        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert contacts;

        List<Opportunity> testOpps = UTIL_UnitTestData_TEST.OppsForContactList (
            contacts, null, UTIL_UnitTestData_TEST.getclosedWonStage(), System.today(), 100, null, null
        );
        insert testOpps;

        testOpps = [
            SELECT Id, Name, Amount, CloseDate, StageName, RecordTypeId,
                CampaignId, Description, Type, Tribute_Type__c, Primary_Contact__c,
                npe03__Recurring_Donation__c, Honoree_Contact__c, Honoree_Name__c,
                Notification_Recipient_Contact__c, Notification_Recipient_Name__c,
               (SELECT Id, ContactId, Role FROM OpportunityContactRoles),
               (SELECT Id, npe01__Opportunity__c, npe01__Payment_Amount__c,
                   npe01__Payment_Date__c, npe01__Payment_Method__c,
                   npe01__Paid__c, npe01__Written_Off__c
                FROM npe01__OppPayment__r)
            FROM Opportunity
        ];

        Test.startTest();
        Map<Id, Map<SObjectType, List<SObject>>> data = new Map<Id, Map<SObjectType, List<SObject>>>();
        for (Opportunity opp : testOpps) {
            Map<SObjectType, List<SObject>> dataMap = new Map<SObjectType, List<SObject>>{
                Opportunity.SObjectType => new List<SObject>{ opp }
            };

            dataMap.put( OpportunityContactRole.SObjectType, opp.OpportunityContactRoles );
            dataMap.put( npe01__OppPayment__c.SObjectType, opp.npe01__OppPayment__r );

            data.put(opp.Id, dataMap );
        }

        Map<String, Object> params = new Map<String, Object>{
            CallableApiParameters.PARAM_ROLLUP_DATA => data
        };

        CallableApiParameters service = new CallableApiParameters(params);
        Map<Id, Map<SObjectType, List<SObject>>> returnedData = service.getRollupDataMap(CallableApiParameters.PARAM_ROLLUP_DATA);

        System.assertEquals(data.size(), returnedData.size(),
            'The returned size of the data map should match the original');

        System.assertEquals(data, returnedData,
            'The two maps should be equivalent');

        System.assertEquals(data.get(testOpps[0].Id).get(Opportunity.SObjectType)[0].get('Id'),
            returnedData.get(testOpps[0].Id).get(Opportunity.SObjectType)[0].get('Id'),
            'The first Opportunity Id should match');

        System.assertEquals(data.get(testOpps[1].Id).get(npe01__OppPayment__c.SObjectType).size(),
            returnedData.get(testOpps[1].Id).get(npe01__OppPayment__c.SObjectType).size(),
            'The size of the Payments Related List on the second Opportunity should match');
    }


    /**
    * @description Validate that each of the service methods returns the expected data type
    */
    @IsTest
    private static void shouldCastParametersAsSpecifiedDataTypes() {

        Map<String, Object> params = new Map<String, Object>{
            'String' => 'String',
            'BooleanTrue' => true,
            'BooleanFalse' => false,
            'ListString' => new List<String>{ 'Value1' },
            'SetString' => new Set<String>{ 'Value1' },
            'ListSObject' => new List<SObject>{ new Opportunity(Name = 'Opportunity') },
            'ListObject' => new List<Object>{'Value', true}
        };

        CallableApiParameters service = new CallableApiParameters(params);
        String rtnString = service.getString('String');
        System.assertEquals('String', rtnString);

        Boolean rtnBoolean = service.getBoolean('NonExistantParm', true);
        System.assertEquals(true, rtnBoolean);

        rtnBoolean = service.getBoolean('BooleanTrue');
        System.assertEquals(true, rtnBoolean);

        rtnBoolean = service.getBoolean('BooleanFalse');
        System.assertEquals(false, rtnBoolean);

        List<String> rtnListString = service.getListString('ListString');
        System.assertEquals(1, rtnListString.size());
        System.assertEquals('Value1', rtnListString[0]);

        Set<String> rtnSetString = service.getSetString('SetString');
        System.assertEquals(1, rtnSetString.size());
        System.assertEquals(true, rtnSetString.contains('Value1'));

        List<SObject> rtnListSObject = service.getSObjects('ListSObject');
        System.assertEquals(1, rtnListSObject.size());
        System.assertEquals(Opportunity.SObjectType, rtnListSObject[0].getSObjectType());
        System.assertEquals('Opportunity', rtnListSObject[0].get('Name'));

        List<Object> rtnListObject = service.getObjects('ListObject');
        System.assertEquals(2, rtnListObject.size());
        System.assertEquals('Value', (String)rtnListObject.get(0));
        System.assertEquals(true, (Boolean)rtnListObject.get(1));
    }

    /**
    * @description Validate that each of the service methods throws an exception if parameter is invalid
    */
    @IsTest
    private static void shouldThrowExceptionOnInvalidDataType() {

        Map<String, Object> badParams = new Map<String, Object>{
            'String' => True,
            'Boolean' => 'XYZ',
            'List<String>' => new Set<SObject>{ new Opportunity() },
            'Set<String>' => 23,
            'List<SObject>' => new Map<String, String>{ 'X' => 'Y' },
            'RollupData' => new Account(),
            'PauseData' => new Map<Id, Object> { UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID => 'Test' }
        };

        CallableApiParameters service = new CallableApiParameters(badParams);

        for (String dataType : badParams.keySet()) {
            try {
                switch on dataType {
                    when 'String' {
                        service.getString(dataType);
                    }
                    when 'Boolean' {
                        service.getBoolean(dataType);
                    }
                    when 'List<String>' {
                        service.getListString(dataType);
                    }
                    when 'Set<String>' {
                        service.getSetString(dataType);
                    }
                    when 'List<SObject>' {
                        service.getSObjects(dataType);
                    }
                    when 'RollupData' {
                        service.getRollupDataMap(dataType);
                    }
                    when 'PauseData' {
                        service.getPauseObjectsById(dataType);
                    }
                }
                System.assert(false, 'An exception should have been thrown for an invalid data type');
            } catch (Exception ex) {
                System.assert(ex.getMessage().containsIgnoreCase(dataType),
                    'Message should contain "' + dataType + '" term\n' + ex.getMessage());
            }
        }
    }

    /**
     * @description Test the throwExceptionIfMissingParameter option for each getter method
     */
    @IsTest
    private static void shouldThrowExceptionOnMissingParameters() {
        Map<String, Object> params = new Map<String, Object>{
            'String' => 'Test',
            'Boolean' => True,
            'Datetime' => System.now(),
            'Map<Id, String>' => new Map<Id,String>{ UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID => 'Test' },
            'List<String>' => new List<String>{ 'Test' },
            'Set<String>' => new Set<String>{ 'Test' },
            'Set<Id>' => new Set<Id>{ UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID },
            'Map<Id, RD2_ApiService.PauseObject>' =>
                new Map<Id, RD2_ApiService.PauseObject>{
                    UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID => new RD2_ApiService.PauseObject()
                }
        };

        CallableApiParameters service = new CallableApiParameters(params)
            .withRequiredParamCheck();

        for (String dataType : params.keySet()) {
            String dummyParamName = 'TESTING';
            try {
                switch on dataType {
                    when 'String' {
                        service.getString(dummyParamName);
                    }
                    when 'Boolean' {
                        service.getBoolean(dummyParamName);
                    }
                    when 'Datetime' {
                        service.getDatetime(dummyParamName);
                    }
                    when 'Map<Id, String>' {
                        service.getStringsById(dummyParamName);
                    }
                    when 'List<String>' {
                        service.getListString(dummyParamName);
                    }
                    when 'Set<String>' {
                        service.getSetString(dummyParamName);
                    }
                    when 'Set<Id>' {
                        service.getSetId(dummyParamName);
                    }
                    when 'Map<Id, RD2_ApiService.PauseObject>' {
                        service.getPauseObjectsById(dummyParamName);
                    }
                }
                System.assert(false, 'An exception should have been thrown for a missing data type');
            } catch (Exception ex) {
                System.assert(ex.getMessage().containsIgnoreCase(dataType),
                    'Message should contain "' + dataType + '" term\n' + ex.getMessage());
            }
        }
    }
}