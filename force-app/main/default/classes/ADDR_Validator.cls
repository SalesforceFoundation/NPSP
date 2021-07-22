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
* @description Class that asynchronously starts the address verification calls
* and processes the results.
*/
public with sharing class ADDR_Validator {

    /** @description Gets verification settings.*/
    private static Addr_Verification_Settings__c settings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();

    /**
    * @description Implementation of the appropriate database actions inner class depending on the user type/context.
    * This is needed because this particular class is a VF page controller as well as an entry point for an exposed
    * global api - both of which just use "with sharing". However, when a "Guest Site User" creates a new Contact
    * through an exposed (and unauthenticated) Sites Page, we still want address verification work through the triggers
    * even if the current user context (Guest User) doesn't technically have perms to query/update the Address records.
    */
    @TestVisible
    private static PermissionController dbActions {
        get {
            if (dbActions == null) {
                if (UserInfo.getUserType() == USER_UserService.USER_TYPE_GUEST_SITE_USER) {
                    dbActions = new EscalatedPermissions();
                } else {
                    dbActions = new StandardPermissions();
                }
            }
            return dbActions;
        } set;
    }

    /** @description Controller for verify address button, does nothing.*/
    public ADDR_Validator(ApexPages.StandardController standardController) {}

    /*******************************************************************************************************
    * @description Action method for verify address button, verifies address.
    * @return PageReference
    */
    public PageReference verifyAddressButton() {
        Id addrId = ApexPages.currentPage().getParameters().get('id');
        if (addrId != null) {
            Set<Id> setAddrId = new Set<Id>{addrId};
            verifyRecords(setAddrId, true);
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Verifies a set of address records in a future.
    * @param recordIds A set containing the IDs of the address records to verify.
    */
    @Future(Callout=true)
    public static void verifyRecordsFuture(Set<Id> recordIds) {
        verifyRecords(recordIds, false);
    }

    /*******************************************************************************************************
    * @description Verifies a set of address records.
    * @param recordIds A set containing the IDs of the address records to verify.
    * @param attemptAlreadyVerifiedRecords Whether addresses already marked Verified should be verified again.
    */
    public static void verifyRecords(Set<Id> recordIds, Boolean attemptAlreadyVerifiedRecords) {
        UTIL_Debug.debug(LoggingLevel.WARN, '****Retrieving data records');

        Set<String> selectFields = new Set<String>{
            'Id', 'Name', 'CreatedDate', 'LastModifiedDate',
            'MailingStreet__c', 'MailingStreet2__c', 'Formula_MailingStreetAddress__c',
            'MailingCity__c', 'MailingCountry__c', 'MailingState__c', 'MailingPostalCode__c',
            'Verified__c', 'API_Response__c', 'Geolocation__Latitude__s', 'Geolocation__Longitude__s',
            'Formula_MailingAddress__c', 'Congressional_District__c', 'County_Name__c'
        };

        UTIL_Query queryBuilder = new UTIL_Query()
            .withFrom(Address__c.SObjectType)
            .withSelectFields(selectFields)
            .withWhere('Id IN :recordIds');

        if (!attemptAlreadyVerifiedRecords) {
            queryBuilder.withWhere('Verified__c = false');
        }

        String soql = queryBuilder.build();
        verifyAddressRecords(dbActions.queryRows(soql, recordIds));
    }

    private class ValidationException extends Exception {}

    /*******************************************************************************************************
    * @description Verifies a list of address records.
    * We separate this in its own method from the query so that we can call it also from the batch process.
    * @param avList The list of address records to verify.
    */
    public static void verifyAddressRecords(List<Address__c> avList) {
        if (avList.isEmpty()) {
            return;
        }

        if (settings == null) {
            ERR_Handler.processError(new ValidationException(System.Label.Addr_Verification_Undefined_Class), ERR_Handler_API.Context.ADDR);
            return;
        }

        String classToRunName = String.valueOf(settings.get('Class__c'));
        if (classToRunName == null) {
            return;
        }
        Type classType = Type.forName(classToRunName);
        if (classType == null) {
            ERR_Handler.processError(new ValidationException(System.Label.Addr_Verification_Wrong_Class), ERR_Handler_API.Context.ADDR);
            return;
        }

        Object classInstance = classType.newInstance();
        Boolean isInstanceOfAddress = (classInstance instanceof ADDR_IValidator);
        if (!isInstanceOfAddress) {
            // The objects we create dynamically need to implement the ADDR_IValidator interface
            ERR_Handler.processError(new ValidationException(System.Label.Addr_Verification_Wrong_Interface), ERR_Handler_API.Context.ADDR);
            return;
        }

        // Setting the flag to avoid running ADDR_Validator_TDTM again after the verification
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunValidation, true);

        // Updating the addresses with the verified version
        UTIL_Debug.debug(LoggingLevel.WARN, '****Verifying records');
        ADDR_IValidator validator = (ADDR_IValidator)classInstance;

        dbActions.updateRows(validator.verifyRecords(avList, settings));

        // Reset the recursion flag when done
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunValidation, false);
    }

    /**
     * @description Interface to define the database actions class that will be dynamically instantiated
     * based on the type of User.
     */
    @TestVisible
    private interface PermissionController {
        List<Address__c> queryRows(String soql, Set<Id> recordIds);
        List<Database.SaveResult> updateRows(List<Address__c> rows);
    }

    /**
     * @description Support Query and Update operations for the Guest Site User - using "without sharing"
     */
    @TestVisible
    private without sharing class EscalatedPermissions implements ADDR_Validator.PermissionController {

        public List<Address__c> queryRows(String soql, Set<Id> recordIds) {
            return Database.query(soql);
        }

        public List<Database.SaveResult> updateRows(List<Address__c> rows) {
            return Database.update(rows);
        }
    }

    /**
     * @description For other User Type, use the default context sharing permissions Query and Update operations
     */
    @TestVisible
    private inherited sharing class StandardPermissions implements ADDR_Validator.PermissionController {

        public List<Address__c> queryRows(String soql, Set<Id> recordIds) {
            return Database.query(soql);
        }

        public List<Database.SaveResult> updateRows(List<Address__c> rows) {
            return Database.update(rows);
        }
    }

}