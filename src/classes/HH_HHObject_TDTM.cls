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
public with sharing class HH_HHObject_TDTM extends TDTM_Runnable {
    
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) { 
        	
        list<npo02__Household__c> listHHNew = newlist;
        list<npo02__Household__c> listHHOld = oldlist;  
        map<ID, npo02__Household__c> mapIdHHOld = new map<ID, npo02__Household__c>(listHHOld);       
    
	    npo02__Households_Settings__c hs = HH_Households.getHouseholdsSettings();
	    
        //updates household records to indicate where/if user changes to the household record are happening
        //and marks them as such so they won't be updated
        //need to use a process control class to avoid recursion when async updates occur
        //in non async updates, this won't fire again, so we don't need to worry
        if (!HH_ProcessControl.inFutureContext && 
            (triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate || triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate)) {
            
            if (hs != null && hs.npo02__Advanced_Household_Naming__c == true) {

                // AfterUpdate data
                list<id> hhlist = new list<id>();
                                       
                for (npo02__Household__c h : listHHNew) {
                    string customname = '';
            
                    if (h.npo02__SYSTEM_CUSTOM_NAMING__c == null)
                        customname = ';';                    
                    else  
                        customname = h.npo02__SYSTEM_CUSTOM_NAMING__c + ';';
                
                    // BeforeUpdate data
                    list<string> customnamelist = new list<string>();
                    set<string> customnameset = new set<string>();
                    customnamelist = customname.split(';');
                    customnameset.addall(customnamelist);
                    
                    if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate) {                
	                    if (h.Name != null && h.Name != mapIdHHOld.get(h.id).Name && !customnameset.contains('Name')) {
	                        customname += 'Name' + ';';
	                    } else if ((h.Name == null || h.Name == '' || h.Name == system.Label.npo02.NameReplacementText) && customnameset.contains('Name')) {
	                        customname = customname.replace('Name;', ';');
	                        h.Name = system.Label.npo02.NameReplacementText;
	                    }
	            
	                    if (h.npo02__Informal_Greeting__c != null && 
	                        h.npo02__Informal_Greeting__c != mapIdHHOld.get(h.id).npo02__Informal_Greeting__c && 
	                        !customnameset.contains('Informal_Greeting__c')) {
	                        customname += 'Informal_Greeting__c' + ';';
	                    } else if ((h.npo02__Informal_Greeting__c == null || h.npo02__Informal_Greeting__c == '' || h.npo02__Informal_Greeting__c == system.Label.npo02.NameReplacementText) && 
	                        customnameset.contains('Informal_Greeting__c')) {                
	                        customname = customname.replace('Informal_Greeting__c;', ';');
	                        h.npo02__Informal_Greeting__c = system.Label.npo02.NameReplacementText;
	                    }
	            
	                    if (h.npo02__Formal_Greeting__c != null && 
	                        h.npo02__Formal_Greeting__c != mapIdHHOld.get(h.id).npo02__Formal_Greeting__c && 
	                        !customnameset.contains('Formal_Greeting__c')) {
	                        customname += 'Formal_Greeting__c' + ';';
	                    } else if ((h.npo02__Formal_Greeting__c == null || h.npo02__Formal_Greeting__c == '' || h.npo02__Formal_Greeting__c == system.Label.npo02.NameReplacementText) && 
	                        customnameset.contains('Formal_Greeting__c')) {
	                        customname = customname.replace('Formal_Greeting__c;', ';');
	                        h.npo02__Formal_Greeting__c = system.Label.npo02.NameReplacementText;
	                    }
	                    h.npo02__SYSTEM_CUSTOM_NAMING__c = customname;
                    } else if (triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
	                    if (h.Name == system.Label.npo02.NameReplacementText)
	                       hhlist.add(h.id);
	                    else if (h.npo02__Informal_Greeting__c == system.Label.npo02.NameReplacementText)
	                       hhlist.add(h.id);
	                    else if (h.npo02__Formal_Greeting__c == system.Label.npo02.NameReplacementText)
	                        hhlist.add(h.id);       
	                    else if (h.npo02__SYSTEM_CUSTOM_NAMING__c != mapIdHHOld.get(h.id).npo02__SYSTEM_CUSTOM_NAMING__c)
	                        hhlist.add(h.id);                        
                    }
                }
                if (!hhlist.isEmpty()){
                    HH_HouseholdNaming hn = new HH_HouseholdNaming();
                    hn.UpdateNames(hhlist);
                }
            }
        } 
    
    return null;  
    }
}