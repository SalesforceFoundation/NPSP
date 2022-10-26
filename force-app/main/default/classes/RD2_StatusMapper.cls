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
* @description Retrieves Recurring Donation status to status type mapping
*/
public with sharing class RD2_StatusMapper {
    /**
    * @description Pre-defined Status to State mapping
    */
    public static final Map<String, String> READ_ONLY_STATUS_TO_STATE = new Map<String, String> {
        RD2_Constants.STATUS_ACTIVE => RD2_Constants.STATUS_ACTIVE,
        RD2_Constants.STATUS_LAPSED => RD2_Constants.STATUS_LAPSED,
        RD2_Constants.STATUS_CLOSED => RD2_Constants.STATUS_CLOSED,
        RD2_Constants.STATUS_PAUSED => RD2_Constants.STATUS_ACTIVE,
        RD2_Constants.STATUS_FAILING => RD2_Constants.STATUS_ACTIVE
    };

    /**
     * @description Interface for retrieving mapping records from database
     */
    public interface Gateway {
        List<RecurringDonationStatusMapping__mdt> getRecords();
    }

    /**
     * @description Status To State Mapping instance
     */
    @TestVisible
    private static RD2_StatusMapper statusMapper;

    /**
    * @description Returns Status To State Mapping instance
    * @return RD2_StatusMapper Status To State Mapping
    */
    public static RD2_StatusMapper getInstance() {
        if (statusMapper == null) {
            statusMapper = new RD2_StatusMapper();
        }
        return statusMapper;
    }

    /**
     * @description Retrieves status to state mapping configuration.
     * The interface is used in order to create a test class implementing the same interface
     * and to mock database record retrieval in tests.
     */
    @TestVisible
    private Gateway gateway {
        get {
            if (gateway == null) {
                gateway = new MappingGateway();
            }
            return gateway;
        }
        set;
    }

    /**
     * @description Contains Recurring Donation Status picklist field values and labels
     */
    @TestVisible
    private Map<String, String> statusLabelByValue {
        get {
            if (statusLabelByValue == null) {
                statusLabelByValue = getActiveStatusPicklistValues();
            }
            return statusLabelByValue;
        }
        set;
    }

    /**
     * @description Contains status to state mapping
     */
    private Map<String, Mapping> mappingByStatus {
        get {
            if (mappingByStatus == null) {
                mappingByStatus = getMapping();
            }
            return mappingByStatus;
        }
        set;
    }

    /**
     * @description Returns status to state mapping
     * @return Map<String, Mapping> Mapping by the status
     */
    private Map<String, Mapping> getMapping() {
        Map<String, Mapping> mappingByStatus = new Map<String, Mapping>();

        for (String status : statusLabelByValue.keySet()) {
            mappingByStatus.put(
                status,
                new Mapping(status, statusLabelByValue.get(status))
            );
        }

        for (RecurringDonationStatusMapping__mdt record : gateway.getRecords()) {
            Mapping mapping = mappingByStatus.get(record.Status__c);
            if (mapping != null) {
                mapping.withMappingRecord(record);
            }
        }

        return mappingByStatus;
    }

    /**
     * @description Returns Recurring Donation Status picklist field value and labels
     * @return Map<String, String> State value mapped by the status key
     */
    @TestVisible
    private Map<String, String> getActiveStatusPicklistValues() {
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
     * @description Returns all status to state mapping records
     * @return Map<String, Mapping> Mapping by the status
     */
    public Map<String, Mapping> getAll() {
        return mappingByStatus;
    }

    /**
     * @description Returns configured state for the specified status on the Recurring Donation
     * @param status Status on the Recurring Donation
     * @return String Mapped state
     */
    public String getState(String status) {
        Mapping mapping = mappingByStatus.get(status);

        return mapping == null ? null : mapping.state;
    }

    /**
     * @description Returns all Recurring Donation Status that are mapped to Active State
     * @return Set<String> Set of status
     */
    public Set<String> getActiveStatusValues() {
        List<Mapping> allmappings = mappingByStatus.values();
        Set<String> activeStates = new Set<String>();

        for (Mapping mapping : allmappings) {
            if (mapping.state == RD2_Constants.STATUS_ACTIVE) {
                activeStates.add(mapping.status);
            }
        }

        return activeStates;
    }

    /**
     * @description Returns all Recurring Donation Status that are mapped to Closed State
     * @return Set<String> Set of status
     */
    public Set<String> getClosedStatusValues() {
        List<Mapping> allmappings = mappingByStatus.values();
        Set<String> closedStates = new Set<String>();

        for (Mapping mapping : allmappings) {
            if (mapping.state == RD2_Constants.STATUS_CLOSED) {
                closedStates.add(mapping.status);
            }
        }

        return closedStates;
    }

    /**
     * @description Returns all Recurring Donation Status that are mapped to Lapsed State
     * @return Set<String> Set of status
     */
    public Set<String> getLapsedStatusValues() {
        List<Mapping> allmappings = mappingByStatus.values();
        Set<String> lapsedStates = new Set<String>();

        for (Mapping mapping : allmappings) {
            if (mapping.state == RD2_Constants.STATUS_LAPSED) {
                lapsedStates.add(mapping.status);
            }
        }

        return lapsedStates;
    }

    /**
     * @description Contains mapping configuration detail
     */
    public inherited sharing class Mapping {
        public String status;
        public String label;
        public String masterLabel;
        public String developerName;
        public String state;
        public Boolean isReadOnly = false;

        /**
         * @description Constructor
         * @param status Status picklist value
         * @param label Status value label
         */
        public Mapping(String status, String label) {
            this.status = status;
            this.label = label;

            if (READ_ONLY_STATUS_TO_STATE.containsKey(status)) {
                this.state = READ_ONLY_STATUS_TO_STATE.get(status);
                this.isReadOnly = true;
            }
        }

        /**
         * @description Sets state in the mapping
         * @param state State mapping value
         * @return Mapping This mapping record instance
         */
        public Mapping withState(String state) {
            this.state = state;
            return this;
        }

        /**
         * @description Populates configuration setting on the mapping record
         * @param record Custom metadata type record containing mapping detail
         * @return Mapping This mapping record instance
         */
        public Mapping withMappingRecord(RecurringDonationStatusMapping__mdt record) {
            this.masterLabel = record.MasterLabel;
            this.developerName = record.DeveloperName;
            this.state = record.State__c;

            return this;
        }
    }

    /**
     * @description Retrieves records from database
     */
    public inherited sharing class MappingGateway implements Gateway {

        /**
         * @description Retrieves status to state mapping configuration records from database
         * @return List<RecurringDonationStatusMapping__mdt>
         */
        public List<RecurringDonationStatusMapping__mdt> getRecords() {
            return [
                SELECT
                    MasterLabel,
                    DeveloperName,
                    Status__c,
                    State__c
                FROM RecurringDonationStatusMapping__mdt
            ];
        }
    }

}
