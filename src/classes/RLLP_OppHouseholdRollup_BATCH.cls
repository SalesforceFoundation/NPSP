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
* @description Batch class for opportunity household rollups. 
*/
public with sharing class RLLP_OppHouseholdRollup_BATCH implements Database.Batchable<SObject>, UTIL_MasterSchedulableHelper.UTIL_IRecurring {
    
    public Boolean executeReturnStatus() {
        if(UTIL_JobScheduler.canRunBatch()) {
            Database.executeBatch(this);
            return true;  
        }
        return false;
    }
    
    public database.Querylocator start(Database.BatchableContext bc) {
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();     
        return Database.getQueryLocator(oppRollupUtil.buildHouseholdQuery()); 
    }
    
    public void execute(Database.BatchableContext bc, List<npo02__Household__c> result) { 
        // NOTE: we don't capture exception and log errors here, because if we don't let the 
        // exception percolate up the call stack, then the batch will think it all succeeded.
        // but if we were to log it, and then propagate the exception, the transaction will 
        // get rolled back, and the logging will be erased!
        RLLP_OppRollup oppRoller = new RLLP_OppRollup();        
        oppRoller.RollupHouseholds(new Map<id, npo02__Household__c>((List<npo02__Household__c>)result));    
    }

    public void finish(Database.BatchableContext bc) {}
}