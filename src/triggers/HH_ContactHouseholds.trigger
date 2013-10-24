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
trigger HH_ContactHouseholds on Contact (after insert, after update, after delete) {

    npo02__Households_Settings__c hs = HH_Households.getHouseholdsSettings();
    
    if (!hs.npo02__DISABLE_Households_trigger__c){
        if( Trigger.isAfter && Trigger.isInsert ){
            HH_Households process = new HH_Households(Trigger.new, Trigger.old, HH_Households.triggerAction.afterInsert);
        }
        if( Trigger.isAfter && Trigger.isUpdate ){ 
            //after update is going to call the version that takes a map as well
            HH_Households process = new HH_Households(Trigger.new, Trigger.old, HH_Households.triggerAction.afterUpdate, trigger.newMap, trigger.oldMap);
        }
        if( Trigger.isAfter && Trigger.isDelete ){
            HH_Households process = new HH_Households(Trigger.old, null, HH_Households.triggerAction.afterDelete);
        }
    }
}