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
* @group Recurring Donations
* @description Recurring Donations Naming Trigger Handler
*
*/
public without sharing class RD2_RecurringDonationNaming_TDTM extends TDTM_Runnable {
    private static final SObjectType ACCOUNT_SOBJECT_TYPE = Account.SObjectType;
    private static final SObjectType CONTACT_SOBJECT_TYPE = Contact.SObjectType;

    /***
    * @description Represents Recurring Donation Naming Service instance
    */
    @TestVisible
    private RD2_NamingService namingService {
        get {
            if (namingService == null) {
                namingService = new RD2_NamingService();
            }
            return namingService;
        }
        set;
    }

    /***
    * @description 
    * Trigger handler on Account/Contact SObject 
    * to update related Recurring Donations' name asynchronously
    * if the Account/Contact name has been changed. 
    *
    * @param sObjects Trigger.new records
    * @param oldSObjects Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    * @param objResult SObject describe
    * @return dmlWrapper
    */
    public override DmlWrapper run(
        List<SObject> sObjects, List<SObject> oldSObjects, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult
    ) {
        if (triggerAction != TDTM_Runnable.Action.AfterUpdate || !RD2_NamingService.isAutomaticNamingEnabled) {
            return null;
        }

        Set<Id> recordIds = new Set<Id>();
        Map<Id, SObject> oldSObjectById = new Map<Id, SObject>(oldSObjects);
        SObjectType sObjType = objResult.getSObjectType();

        for (SObject record : SObjects) {
            if (hasChanged(record, oldSObjectById.get(record.Id), sObjType)) {
                recordIds.add(record.Id);
            }
        }

        if (!recordIds.isEmpty()) {
            System.enqueueJob(new RD2_NamingService.NamingQueueable(recordIds, sObjType));
        }

        return null;
    }

    /***
    * @description Specifies if the Account/Contact record Name has been changed
    * @param record Updated Account/Contact record
    * @param oldRecord Old Account/Contact records
    * @param sObjType SObjectType of the provided record
    * @return Boolean Indication if the Account/Contact Name is changed
    */
    private Boolean hasChanged(SObject record, SObject oldRecord, SObjectType sObjType) {
        if (sObjType == ACCOUNT_SOBJECT_TYPE) {
            return (String) record.get('Name') != (String) oldRecord.get('Name');

        } else if (sObjType == CONTACT_SOBJECT_TYPE) {
            return (String) record.get('FirstName') != (String) oldRecord.get('FirstName') 
                || (String) record.get('LastName') != (String) oldRecord.get('LastName');
        }

        return false;
    }
}