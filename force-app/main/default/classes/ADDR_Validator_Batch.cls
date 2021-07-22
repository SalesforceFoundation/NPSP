/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Address Management
* @description Batch class for SmartyStreets address verification. It looks for all populated addresses and updates them if the setting is turned on.
*/
public class ADDR_Validator_Batch extends UTIL_AbstractChunkingLDV_BATCH implements Database.AllowsCallouts {
    /**
    * @description # of records in each batch
    */
    private static final Integer BATCH_SIZE = 200;

    /**
    * @description Chunk size to use when running in LDV Mode
    */
    private static final Integer CHUNK_SIZE = 10000000;

    /**
    * @description Control whether or not to skip the already verified address 
    */
    private Boolean skipPreviouslyVerified = false;

    /**
    * @description Constructor that initializes the class.
    * @param skipPreviouslyVerified If true, the batch skips over objects that already have any verification records.
    */
    public ADDR_Validator_Batch(Boolean skipPreviouslyVerified) {
        this.skipPreviouslyVerified = skipPreviouslyVerified;
        this.setBatchSize(BATCH_SIZE);
    }

    /**
    * @description Processes the batch of records in the scope.
    * @param bc The context for the batch. Provided by the platform.
    * @param scope The batch records to be process.
    */
    public override void doExecute(Database.BatchableContext BC, List<SObject> records) {
        List<Address__c> addressesToProcess = (List<Address__c>) records;
        List<Address__c> addressesToVerify = new List<Address__c>();

        for (Address__c address : addressesToProcess) {
            if (this.skipPreviouslyVerified == true && address.Verified__c == true) {
                continue;
            }

            if (ADDR_Validator_UTIL.isUSAddress(address)) {
                addressesToVerify.add(address);
            }
        }

        //verify and update this batch of addresses
        if (!addressesToVerify.isEmpty()) {
            ADDR_Validator.verifyAddressRecords(addressesToVerify);
        }
    }

    /**
     * @description Define the fields to be queried
     * @return String
     */
    public override String getSOQLFullQueryFieldList() {
        return 'Id, Name,  Formula_MailingStreetAddress__c, Formula_MailingAddress__c, ' 
            + 'MailingStreet__c, MailingStreet2__c, MailingCity__c, MailingState__c, '
            + 'MailingPostalCode__c, MailingCountry__c, API_Response__c, Verified__c';
    }

    /**
    * @description Define Address__c for the main object that is being processed in the batch
    * @return String value of SOQLObjectName
    */
    public override SObjectType getSObjectType() {
        return Address__c.getSObjectType();
    }

    /**
    * @description Define the WHERE clause in the batch query
    * @return String
    */
    public override String getWhereClause() {
        return (skipPreviouslyVerified) 
            ? 'Verified__c != true'
            : '';
    }

    /**
    * @description LDV Chunk Size to use
    * @return Integer chunk size to use when running in LDV Chunking mode
    */
    public override Integer getLDVChunkSize() {
        return CHUNK_SIZE;
    }

}