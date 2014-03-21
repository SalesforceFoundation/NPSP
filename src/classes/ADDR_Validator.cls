/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Class that asynchronously starts the address verification calls
* and processes the results.
*/
public with sharing class ADDR_Validator {

    private static Address_Verification_Settings__c settings = Address_Verification_Settings__c.getInstance();

    /* FUTURE METHOD FOR TRIGGERS */
    @future(callout=true)
    public static void verifyRecords(set<id> recordIds) {
        System.debug('****Retrieving data records');
        //query for all the indicated verification records
        list<Address__c> avList = [ select Id, Name, CreatedDate, LastModifiedDate, 
            MailingStreet__c, MailingCity__c, MailingCountry__c, MailingState__c, MailingPostalCode__c, 
            Verified__c, API_Response__c, Geolocation__Latitude__s, Geolocation__Longitude__s, 
            Congressional_District__c, County_Name__c from Address__c where id in : recordIds];

        if (!avList.isEmpty()) {
            System.debug('****Verifying records');
            ADDR_SmartyStreets_Validator validator = new ADDR_SmartyStreets_Validator();
            upsert validator.verifyRecords(avList, settings.Reject_Ambiguous_Addresses__c);
        }
    }
}