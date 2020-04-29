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
* @description Used to store and retrieve Recurring Donation status to status type mapping
*/
public with sharing class RD2_StatusMapper {
    private static final Set<String> REQUIRED_STATUSES = new Set<String>{
        RD2_Constants.STATUS_ACTIVE,
        RD2_Constants.STATUS_LAPSED,
        RD2_Constants.STATUS_CLOSED
    };

    private Map<String, Record> recordByStatus {
        get {
            if (recordByStatus == null) {
                recordByStatus = getMapping();
            }
            return recordByStatus;
        }
        set;
    }

    private Map<String, Record> getMapping() {
        Map<String, Record> recordByStatus = new Map<String, Record>();

        for (RecurringDonationStatusMapping__mdt mdt : [
            SELECT 
                MasterLabel,
                Status__c,
                State__c,
                IsDeleted__c
            FROM RecurringDonationStatusMapping__mdt
            WHERE IsDeleted__c = false
        ]) {
            recordByStatus.put(mdt.Status__c, new Record(mdt));
        }
        //keep only active RD SObject Status__c picklist field values//TODO
        //add required statuses if missing//TODO

        return recordByStatus;
    }

    public String getState(String status) {
        Record record = recordByStatus.get(status);

        return record == null ? null : record.state;
    }

    public List<Record> getRecords() {
        return recordByStatus.values();
    }

    public void saveRecords(List<Record> records) {
        //TODO
    }

    public class Record {
        public String label;
        public String status;
        public String state;
        public Boolean isDeleted = false;

        public Record(String status) {
            this.label = status;
            this.status = status;
        }

        public Record(RecurringDonationStatusMapping__mdt mapping) {
            this.label = mapping.MasterLabel;
            this.status = mapping.Status__c;
            this.state = mapping.State__c;
            this.isDeleted = mapping.IsDeleted__c;
        }

        public Metadata.CustomMetadata getCustomMetadata() {
            String sobjType = String.valueOf(RecurringDonationStatusMapping__mdt.getSObjectType());

            Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
            cmd.label = status;
            cmd.fullName = sobjType + '.' + status;
            cmd.protected_x = false;

            Map<String, Object> fieldValues = new Map<String, Object>{
                'IsDeleted__c' => isDeleted
            };
            if (isDeleted != true) {
                fieldValues.put('Status__c', this.status);
                fieldValues.put('State__c', this.state);
            }
            cmd = CMT_MetadataAPI.addFieldsToMetadataObject(cmd, fieldValues);

            return cmd;
        }
    }

}
