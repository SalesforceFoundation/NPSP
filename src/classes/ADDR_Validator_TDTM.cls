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
* @description Class that gets called when Address__c records change and
* begins the address verification/normalization.
*/
public with sharing class ADDR_Validator_TDTM extends TDTM_Runnable {
	
	public class ADDR_Validator_Exception extends Exception { }
	
	public static Boolean alreadyRun = false;
	
	public override DmlWrapper run(List<SObject> newList, List<SObject> oldList, 
    TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) { 
        
        if(!alreadyRun) {
	        Addr_Verification_Settings__c settings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();
	        if(trigger.isBefore && settings.enable_automatic_verification__c) {        	
	        	for(SObject so : newList) {
	        		Address__c address = (Address__c)so;
	        		if(!system.isFuture() && !system.isBatch()) {
	        		    address.Verification_Status__c = Label.Addr_Pending_Verification;
	        		} else {
	        			address.Verification_Status__c = Label.Addr_Verification_Required;
	        		}	
        	    }
	        }
	        if (trigger.isAfter && settings.enable_automatic_verification__c) {
                if(!system.isFuture() && !system.isBatch()) {
                    ADDR_Validator.verifyRecordsFuture(new Map<Id, SObject>(newList).keyset());
                    alreadyRun = true;
                } else if(system.isFuture()) {
                	ERR_Handler.processError(new ADDR_Validator_Exception('ADDR_Validator_TDTM called from future'), 
                	                           ERR_Handler.Context.ADDR);
                } else if(system.isBatch()) {
                	UTIL_Debug.debug('****ADDR_Validator_TDTM called from batch, addresses not verified.');
                    /*We don't want to log an error here. Instead, we'll just do a debug statement.

                    ERR_Handler.processError(new ADDR_Validator_Exception('ADDR_Validator_TDTM called from batch'), 
                                               ERR_Handler.Context.ADDR);*/
                }
	        }
        }
        //we cannot return records to perform DML on because the address verification has to run
        //in a future for making external web service calls
        return new DmlWrapper();
    }
}