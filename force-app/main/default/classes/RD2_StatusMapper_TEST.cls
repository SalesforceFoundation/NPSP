/*
    Copyright (c) 2020, Salesforce.org
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
* @description Tests to store and retrieve Recurring Donation status to status type mapping
*/
@IsTest(IsParallel=true)
public with sharing class RD2_StatusMapper_TEST {
    private static final Set<String> READ_ONLY_STATUS_VALUES = RD2_StatusMapper.READ_ONLY_STATUS_TO_STATE.keySet();

    /**
     * @description Verifies default Status picklist field mapping is returned
     * when mapping is not configured
     */
    @IsTest
    private static void shouldReturnDefaultStatusMappingWhenNoMappingIsConfigured() {
        RD2_StatusMapper mapper = new RD2_StatusMapper();
        mapper.gateway = new TestMappingGateway();
        mapper.statusLabelByValue = getDefaultStatusLabelByValue();

        Map<String, RD2_StatusMapper.Mapping> mappingByStatus = mapper.getAll();

        for (RD2_StatusMapper.Mapping mapping : mappingByStatus.values()) {
            assertReadOnlyStatusMapping(mapping);

            if (!READ_ONLY_STATUS_VALUES.contains(mapping.status)) {
                System.assertEquals(null, mapping.state,
                    'State should be unmapped when mapping is not configured: ' + mapping
                );
            }
        }

        assertDefaultStatusValues(mappingByStatus.keySet());
    }

    /**
     * @description Verifies empty State is returned for a new Status
     * when mapping is not configured
     */
    @IsTest
    private static void shouldReturnEmptyStateWhenNewStatusMappingIsNotConfigured() {
        final String newStatus = 'Pending';

        RD2_StatusMapper mapper = new RD2_StatusMapper();
        mapper.statusLabelByValue = getDefaultStatusLabelByValue();
        mapper.statusLabelByValue.put(newStatus, newStatus);
        Map<String, RD2_StatusMapper.Mapping> mappingByStatus = mapper.getAll();

        System.assertEquals(true, mappingByStatus.keySet().contains(newStatus),
            'New Status should be returned: ' + mappingByStatus.values()
        );
        System.assertEquals(null, mappingByStatus.get(newStatus).state,
            'State for the unmapped Status should be empty: ' + mappingByStatus.get(newStatus)
        );

        for (RD2_StatusMapper.Mapping mapping : mappingByStatus.values()) {
            assertReadOnlyStatusMapping(mapping);
        }
        assertDefaultStatusValues(mappingByStatus.keySet());
    }

    /**
     * @description Verifies mapped State is returned for a new Status
     * when mapping is configured
     */
    @IsTest
    private static void shouldReturnStatusMappingWhenNewStatusMappingIsConfigured() {
        final String newStatus = 'Pending';
        final String newStatusState = RD2_Constants.STATUS_ACTIVE;

        RD2_StatusMapper.Gateway mappingGateway = new TestMappingGateway()
            .withRecord(
                buildMockCustomMetadataRecord(newStatus, newStatusState)
            );

        RD2_StatusMapper mapper = new RD2_StatusMapper();
        mapper.gateway = mappingGateway;
        mapper.statusLabelByValue = getDefaultStatusLabelByValue();
        mapper.statusLabelByValue.put(newStatus, newStatus);
        Map<String, RD2_StatusMapper.Mapping> mappingByStatus = mapper.getAll();

        System.assertEquals(true, mappingByStatus.keySet().contains(newStatus),
            'New Status should be returned: ' + mappingByStatus.values()
        );
        System.assertEquals(newStatusState, mappingByStatus.get(newStatus).state,
            'State for the mapped Status should be returned: ' + mappingByStatus.get(newStatus)
        );

        for (RD2_StatusMapper.Mapping mapping : mappingByStatus.values()) {
            assertReadOnlyStatusMapping(mapping);
        }
        assertDefaultStatusValues(mappingByStatus.keySet());
    }

    /**
     * @description Verifies status to state mapping is not returned by the mapper
     * when mapping is configured
     * but the status is not defined in the Status picklist field
     */
    @IsTest
    private static void shouldNotReturnStatusMappingWhenStatusPicklistValueDoesNotExist() {
        final String invalidStatus = 'foo';

        RD2_StatusMapper.Gateway mappingGateway = new TestMappingGateway()
            .withRecord(
                buildMockCustomMetadataRecord(invalidStatus)
            );

        RD2_StatusMapper mapper = new RD2_StatusMapper();
        mapper.gateway = mappingGateway;
        Map<String, RD2_StatusMapper.Mapping> mappingByStatus = mapper.getAll();

        System.assertEquals(false, mappingByStatus.keySet().contains(invalidStatus),
            'Status not existing on Status picklist field should not be returned: ' + mappingByStatus.values()
        );

        for (RD2_StatusMapper.Mapping mapping : mappingByStatus.values()) {
            assertReadOnlyStatusMapping(mapping);
        }

        assertDefaultStatusValues(mappingByStatus.keySet());
        assertAllActivePicklistStatusValues(mappingByStatus.keySet());
    }

    /**
     * @description Verifies State is returned for required read-only Status
     */
    @IsTest
    private static void shouldReturnStateWhenStatusIsRequiredReadOnlyMapping() {
        RD2_StatusMapper mapper = new RD2_StatusMapper();

        Map<String,String> activeValuesMap = mapper.getActiveStatusPicklistValues();

        for (String status : READ_ONLY_STATUS_VALUES) {
            if (activeValuesMap.get(status) != null) {
                System.assertEquals(RD2_StatusMapper.READ_ONLY_STATUS_TO_STATE.get(status), mapper.getState(status),
                    'State should mapped to pre-defined state for required read-only value'
                );
            }
        }
    }

    /**
     * @description Verifies no State is returned when Status is invalid picklist entry
     */
    @IsTest
    private static void shouldNotReturnStateWhenStatusIsInvalidPicklistEntry() {
        final String invalidStatus = 'bar';
        RD2_StatusMapper mapper = new RD2_StatusMapper();

        System.assertEquals(null, mapper.getState(invalidStatus),
            'State should be empty for an invalid Status value'
        );
    }

    /**
     * @description Verifies mapped State is returned when Status is valid picklist entry
     */
    @IsTest
    private static void shouldReturnStateWhenStatusIsValidPicklistEntry() {
        final String newStatus = 'Canceled';
        final String newStatusState = RD2_Constants.STATUS_CLOSED;

        RD2_StatusMapper.Gateway mappingGateway = new TestMappingGateway()
            .withRecord(
                buildMockCustomMetadataRecord(newStatus, newStatusState)
            );

        RD2_StatusMapper mapper = new RD2_StatusMapper();
        mapper.gateway = mappingGateway;
        mapper.statusLabelByValue = getDefaultStatusLabelByValue();
        mapper.statusLabelByValue.put(newStatus, newStatus);

        System.assertEquals(newStatusState, mapper.getState(newStatus),
            'State should be returned for a mapped Status value'
        );
    }

    @IsTest
    private static void shouldReturnAllClosedStatus() {
        RD2_StatusMapper mapper = new RD2_StatusMapper();
        mapper.gateway = new TestMappingGateway();
        mapper.statusLabelByValue = getDefaultStatusLabelByValue();

        List<String> closedStatus = new List<String>(mapper.getClosedStatusValues());

        System.assertEquals(1, closedStatus.size(), 'Only 1 closed Status should be return');
        System.assertEquals(RD2_Constants.STATUS_CLOSED, closedStatus[0], 'Closed Status should be return');
    }

    @IsTest
    private static void shouldReturnAllLapsedStatus() {
        RD2_StatusMapper mapper = new RD2_StatusMapper();
        mapper.gateway = new TestMappingGateway();
        mapper.statusLabelByValue = getDefaultStatusLabelByValue();

        List<String> lapsedStatus = new List<String>(mapper.getLapsedStatusValues());

        System.assertEquals(1, lapsedStatus.size(), 'Only 1 closed Status should be return');
        System.assertEquals(RD2_Constants.STATUS_LAPSED, lapsedStatus[0], 'Closed Status should be return');
    }

    // Helpers
    //////////////////

    /***
    * @description Verifies required read-only status to state mapping is as expected
    * @param mapping Mapping record
    * @return void
    */
    private static void assertReadOnlyStatusMapping(RD2_StatusMapper.Mapping mapping) {
        if (!READ_ONLY_STATUS_VALUES.contains(mapping.status)) {
            return;
        }

        System.assertEquals(RD2_StatusMapper.READ_ONLY_STATUS_TO_STATE.get(mapping.state), mapping.state,
            'State should equal to the Status for required read-only value: ' + mapping
        );
    }

    /***
    * @description Verifies required default Status picklist field values are returned by the mapper
    * @param statusValues Actual Status values returned by the mapper
    * @return void
    */
    public static void assertDefaultStatusValues(Set<String> statusValues) {
        Boolean hasRequired =
            statusValues.contains(RD2_Constants.STATUS_ACTIVE)
            && statusValues.contains(RD2_Constants.STATUS_LAPSED)
            && statusValues.contains(RD2_Constants.STATUS_CLOSED);

        System.assertEquals(true, hasRequired,
            'Required Status values should be returned by the mapper: ' + statusValues
        );
    }

    /***
    * @description Verifies all active Status picklist field values are returned by the mapper
    * @param statusValues Actual Status values returned by the mapper
    * @return void
    */
    public static void assertAllActivePicklistStatusValues(Set<String> statusValues) {
        Map<String, String> labelByValue = getActiveStatusLabelByValue();

        System.assertEquals(labelByValue.keySet(), statusValues,
            'All active Status values should be returned by the mapper: ' + statusValues
        );
    }

    /**
     * @description Returns Recurring Donation Status picklist field value and labels
     * @return Map<String, String> State value mapped by the status key
     */
    private static Map<String, String> getActiveStatusLabelByValue() {
        Map<String, String> labelByValue = new Map<String, String>();
        List<Schema.PicklistEntry> statusEntries = npe03__Recurring_Donation__c.Status__c.getDescribe().getPicklistValues();

        for (Schema.PicklistEntry entry : statusEntries) {
            if (entry.isActive()) {
                labelByValue.put(entry.getValue(), entry.getLabel());
            }
        }

        return labelByValue;
    }

    /**
     * @description Returns default Recurring Donation Status picklist field value and labels
     * @return Map<String, String> State value mapped by the status key
     */
    private static Map<String, String> getDefaultStatusLabelByValue() {
        return new Map<String, String>{
            RD2_Constants.STATUS_ACTIVE => RD2_Constants.STATUS_ACTIVE,
            RD2_Constants.STATUS_LAPSED => RD2_Constants.STATUS_LAPSED,
            RD2_Constants.STATUS_CLOSED => RD2_Constants.STATUS_CLOSED,
            RD2_Constants.STATUS_PAUSED => RD2_Constants.STATUS_ACTIVE,
            RD2_Constants.STATUS_FAILING => RD2_Constants.STATUS_ACTIVE
        };
    }

    /**
     * @description Builds custom metadatype record
     * @param status Status value
     * @return RecurringDonationStatusMapping__mdt
     */
    private static RecurringDonationStatusMapping__mdt buildMockCustomMetadataRecord(String status) {
        return buildMockCustomMetadataRecord(status, status);
    }

    /**
     * @description Builds custom metadatype record
     * @param status Status value
     * @param state State mapping value
     * @return RecurringDonationStatusMapping__mdt
     */
    private static RecurringDonationStatusMapping__mdt buildMockCustomMetadataRecord(String status, String state) {
        return new RecurringDonationStatusMapping__mdt(
            Status__c = status,
            State__c = state
        );
    }

    /***
    * @description Stub for the status to status type mapper
    */
    public class Stub implements System.StubProvider {
        private Map<String, RD2_StatusMapper.Mapping> mappingByStatus = new Map<String, RD2_StatusMapper.Mapping>();

        /**
        * @description Accepts the status to state mapping as specified by the input arguments
        * @param status Status value
        * @param mapping Status to state mapping record
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
                withMapping(option.getValue(), option.getValue());
            }

            return this;
        }

        /**
        * @description Populates mapping with default status to state mapping
        * @return Stub
        */
        public Stub withDefaultMapping() {
            return withMapping(RD2_Constants.STATUS_ACTIVE, RD2_Constants.STATUS_ACTIVE)
                .withMapping(RD2_Constants.STATUS_LAPSED, RD2_Constants.STATUS_LAPSED)
                .withMapping(RD2_Constants.STATUS_CLOSED, RD2_Constants.STATUS_CLOSED);
        }

        /**
        * @description Accepts the status to state mapping as specified by the input arguments
        * @param status Status value
        * @param state State mapping value
        * @return Stub
        */
        public Stub withMapping(String status, String state) {
            RD2_StatusMapper.Mapping mapping = new RD2_StatusMapper.Mapping(status, status)
                .withState(state);

            return withMapping(status, mapping);
        }

        /**
        * @description Add Status to State to the Statue Mapping Settings
        * @param status The status to mapped from
        * @param state The state to mapped to
        * @return Stub
        */
        public Stub withMapping(String status, RD2_StatusMapper.Mapping mapping) {
            mappingByStatus.put(status, mapping);
            return this;
        }

        /**
        * @description Process method calls
        * @return Object Method return value
        */
        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            switch on methodName {
                when 'getAll' {
                    return mappingByStatus;

                } when 'getState' {
                    String status = (String) args[0];
                    RD2_StatusMapper.Mapping mapping = mappingByStatus.get(status);

                    return mapping == null ? null : mapping.state;

                } when 'getClosedStatusValues' {
                    return new Set<String>{RD2_Constants.STATUS_CLOSED};

                } when 'getLapsedStatusValues' {
                    return new Set<String>{RD2_Constants.STATUS_LAPSED};

                } when else {
                    return null;
                }
            }
        }
    }

    /***
    * @description Implements status to state mapping record retrieval gateway
    */
    public class TestMappingGateway implements RD2_StatusMapper.Gateway {
        private List<RecurringDonationStatusMapping__mdt> records = new List<RecurringDonationStatusMapping__mdt>();

        /**
        * @description Adds record to the list of records to be returned
        * @param record Custom metadata record
        * @return TestMappingGateway
        */
        public TestMappingGateway withRecord(RecurringDonationStatusMapping__mdt record) {
            this.records.add(record);
            return this;
        }

        /**
        * @description Adds record to the list of records to be returned
        * @param jsonRecord JSON representation of the custom metadata record
        * @return TestMappingGateway
        */
        public TestMappingGateway withRecord(String jsonRecord) {
            this.records.add(
                (RecurringDonationStatusMapping__mdt) JSON.deserialize(
                    jsonRecord,
                    RecurringDonationStatusMapping__mdt.class
                )
            );
            return this;
        }

        /**
        * @description Sets mock records to return as database retrieval call
        * @param records Custom metadata records
        * @return TestMappingGateway
        */
        public TestMappingGateway withRecords(List<RecurringDonationStatusMapping__mdt> records) {
            this.records = records;
            return this;
        }

        /**
        * @description Simulates database records' return call
        * @return List<RecurringDonationStatusMapping__mdt>
        */
        public List<RecurringDonationStatusMapping__mdt> getRecords() {
            return records;
        }
    }
}
