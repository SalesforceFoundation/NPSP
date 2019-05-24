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
* @description Class that gets called when Address__c records change and
* begins the address verification/normalization.
* @async_support this trigger handler DOES NOT SUPPORT ASYNC!  the validation call is a future,
* and if we are already in a future to deal with the trigger handler, we can't call the future verification api!
*/
public class ADDR_Validator_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description To support DML operations with more than 200 records, use a static Set of Id's that
    * have been passed to the verifyAddressRecords() method. This allows for a recursion check that goes
    * by the Id's of the records as opposed to a simple boolean.
    */
    public static Set<Id> processedIdsForValidation = new Set<Id>();

    /*******************************************************************************************************
    * @description Exception raised during the address validation process.
    */
    public class ADDR_Validator_Exception extends Exception { }

    /*******************************************************************************************************
    * @description Verifies new or modified address records, if verification enabled in the settings.
    * @param listNew The list of Addresses from trigger new. 
    * @param listOld The list of Addresses from trigger old. 
    * @param triggerAction The trigger event (BeforeInsert, AfterInsert, etc.) that caused the class to run. 
    * @param objResult The describe for Addresses.
    * @return dmlWrapper The wrapper with the records to perform DML on. 
    */
    public override DmlWrapper run(List<SObject> newList, List<SObject> oldList,
    TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // Look in the static list of previoysly processed Id's to determine if the record has already
        // gone through this trigger. If so, then don't process it a second time.
        Boolean recordsPreviouslyProcessed = false;
        if (newList !=  null && newList[0].Id != null && processedIdsForValidation.contains(newList[0].Id)) {
            recordsPreviouslyProcessed = true;
        }

        if(!recordsPreviouslyProcessed && UTIL_CustomSettingsFacade.getAddressVerificationSettings().enable_automatic_verification__c) {
            if (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
                for(SObject so : newList) {
                    Address__c address = (Address__c)so;
                    //don't verify this address if it has already been verified
                    if (address.Verified__c != null && address.Verified__c) {
                        continue;
                    }
                    if(!system.isFuture() && !system.isBatch()) {
                        address.Verification_Status__c = Label.Addr_Pending_Verification;
                    } else {
                        address.Verification_Status__c = Label.Addr_Verification_Required;
                    }
                }
            }
            if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                if(!system.isFuture() && !system.isBatch()) {
                    ADDR_Validator.verifyRecordsFuture(new Map<Id, SObject>(newList).keyset());
                    // To support DML operations with more than 200 records, update a static list of Id's that
                    // have been submitted to this method.
                    for (SObject s : newList) {
                        processedIdsForValidation.add((Id)s.get('Id'));
                    }
                } else if(system.isFuture()) {
                    UTIL_Debug.debug('****ADDR_Validator_TDTM called from future, addresses not verified.');
                } else if(system.isBatch()) {
                    UTIL_Debug.debug('****ADDR_Validator_TDTM called from batch, addresses not verified.');
                }
            }
        }
        //we cannot return records to perform DML on because the address verification has to run
        //in a future for making external web service calls
        return null;
    }
}