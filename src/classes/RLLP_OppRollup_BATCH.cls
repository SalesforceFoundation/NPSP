/*
    Copyright (c) 2009, Salesforce.com Foundation
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
* @date 2011
* @description Class provides a batchable wrapper for Opportunity Rollup functionality
*/
public class RLLP_OppRollup_BATCH implements Database.Batchable<SObject> {
// batch apex class to rollup opportunities
    
    public String query { get; set; }
    public enum BATCH_TYPE{ContactType, AccountType, HouseholdType, SoftCreditType} 
    public BATCH_TYPE btype;
    
    // constructors
    public RLLP_OppRollup_BATCH(string q, BATCH_TYPE bt){  
        btype = bt;
        query = q; 
    }
    public RLLP_OppRollup_BATCH(string q){  
        this(q, BATCH_TYPE.ContactType);        
    }
    
    public database.Querylocator start(Database.BatchableContext bc){       
        return Database.getQueryLocator(query);      
    }
    
    public void execute(Database.BatchableContext bc, Sobject[] result) {
    	
    	// NOTE: we don't capture exception and log errors here,
        // because if we don't let the exception percolate up the call
        // stack, then the batch will think it all succeeded.
        // but if we were to log it, and then proprogate the exception,
        // the transaction will get rolled back, and the logging will be erased!
        // Not sure of a way to have our cake (log it), and eat it to (have batch display failure)!
        
        // run rollups for this batch       
        RLLP_OppRollup rg = new RLLP_OppRollup();
        
        if (btype == BATCH_TYPE.ContactType){
            rg.rollupContacts(new map<id, Contact>((list<Contact>)result));             
        }
        else if (btype == BATCH_TYPE.AccountType){
            rg.RollupAccounts(new map<id, Account>((list<Account>)result));         
        }
        else if (btype == BATCH_TYPE.HouseholdType){
            rg.RollupHouseholds(new map<id, npo02__Household__c>((list<npo02__Household__c>)result));           
        }
        else if (btype == BATCH_TYPE.SoftCreditType && RLLP_OppRollup_UTIL.useSoftCredits()){
            rg.RollupSoftCredits(new map<id, Contact>((list<Contact>)result));          
        }
        else{           
            //throw error
            throw new NPSPBatchException('Invalid BATCH_TYPE: ' + btype);
        }       
    }

    public void finish(Database.BatchableContext bc) {
    }   
    
    public class NPSPBatchException extends Exception{} 

}