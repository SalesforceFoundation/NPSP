/*
    Copyright (c) 2009,2012, Salesforce.com Foundation
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
trigger REL_Relationships on npe4__Relationship__c (before insert, before update, before delete, 
after insert, after update, after delete, after undelete) {
    
    /*if (REL_ProcessControl.hasRun != true && !REL_Utils.getRelationshipSettings().npe4__DISABLE_Relationships_trigger__c){  
        if(Trigger.isBefore && Trigger.isInsert){          
            REL_Relationships process = new REL_Relationships(Trigger.new, Trigger.old, REL_Utils.triggerAction.beforeInsert);
        }        
        else if(Trigger.isBefore && Trigger.isUpdate){      
            REL_Relationships process = new REL_Relationships(Trigger.new, Trigger.old, REL_Utils.triggerAction.beforeUpdate);
        }
        else if(Trigger.isAfter && Trigger.isInsert ){         
            REL_Relationships process = new REL_Relationships(Trigger.new, Trigger.old, REL_Utils.triggerAction.afterInsert);
        }    
        else if(Trigger.isAfter && Trigger.isUpdate ){         
            REL_Relationships process = new REL_Relationships(Trigger.new, Trigger.old, REL_Utils.triggerAction.afterUpdate);
        }
        else if(Trigger.isAfter && Trigger.isDelete ){
            REL_Relationships process = new REL_Relationships(Trigger.old, null, REL_Utils.triggerAction.afterDelete);
        }   
    }*/
    
    TDTM_TriggerHandler handler = new TDTM_TriggerHandler();  
    handler.initialize(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, 
        Trigger.isUnDelete, Trigger.new, Trigger.old, Schema.Sobjecttype.npe4__Relationship__c);
    handler.runClasses(new TDTM_ObjectDataGateway());
}