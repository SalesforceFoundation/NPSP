/*
    Copyright (c) 2011, Salesforce.com Foundation
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
* @date 2011 (2.0)
* @description The controller for the VF page invoked by using the bulk opp rollups tab 
*/
public class RLLP_OppRollup_CTRL {
 
    // properties for page
    public boolean batching { get; set; }
    public boolean batchRunning { get; set; }

    // object id passed in via parameter
    string objectId;
    id oid;

    // constructor
    public RLLP_OppRollup_CTRL() {
        batchRunning = false;

        // get parameter if any
        try {
            objectId = ApexPages.currentPage().getParameters().get('id');
            oid = objectId;
        } catch (exception e) {
        	ERR_Handler.processError(e, null);
        }  
        
        if (oid != null) {
            batching = false;           
        } else {
            batching = true;
        }
    }
    
    public PageReference startAction() {
        PageReference ref;
        if (oid != null){            
            // run the rollup for the specified object
            RLLP_OppRollup rg = new RLLP_OppRollup();
            if (objectId.startsWith('001')){
                RLLP_OppRollup.RollupAccountsFuture(new set<id>{oid});
            }                
            else if (objectId.startsWith('003')){                
                RLLP_OppRollup.RollupContactsFuture(new set<id>{oid});                
            }                
            else{
                RLLP_OppRollup.RollupHouseholdsFuture(new set<id>{oid});                
            }    
            ref = new PageReference('/' + oid);
            ref.setRedirect(true);
        }
        return ref;
    }

    public PageReference rollup() {
        
        // run batch rollup
        RLLP_OppRollup rg = new RLLP_OppRollup();
        rg.rollupAll();
        
        batchRunning = true;
        return null;                
    }

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }

}