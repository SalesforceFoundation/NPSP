/*
    Copyright (c) 2013, Salesforce.com Foundation
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
public with sharing class TDTM_TriggerActionHelper {

    public enum Action {   
        BeforeInsert, 
        BeforeUpdate, 
        BeforeDelete, 
        AfterInsert, 
        AfterUpdate, 
        AfterDelete,
        AfterUndelete
    }
    
    public static Action determineTriggerAction(Boolean isBefore, Boolean isAfter, Boolean isInsert,
    Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {
        if (isBefore) {
            if (isInsert) return Action.BeforeInsert;
            else if (isUpdate) return Action.BeforeUpdate;
            else return Action.BeforeDelete;
        } else {
            if (isInsert) return Action.AfterInsert;
            else if (isUpdate) return Action.AfterUpdate;
            else if (isDelete) return Action.AfterDelete;
            else return Action.AfterUndelete;
        }
    }
    
    public static Action getTriggerActionFromName(String name) {
        Action ta;
    
        if (name == Action.BeforeInsert.name())
           ta = Action.BeforeInsert;
        else if(name == Action.BeforeUpdate.name())
           ta = Action.BeforeUpdate;
        else if(name == Action.BeforeDelete.name())
           ta = Action.BeforeDelete;
        else if(name == Action.AfterInsert.name())
           ta = Action.AfterInsert;
        else if(name == Action.AfterUpdate.name())
           ta = Action.AfterUpdate;
        else if(name == Action.AfterDelete.name())
           ta = Action.AfterDelete;
        else if(name == Action.AfterUndelete.name())
           ta = Action.AfterUndelete;
        return ta;
    }
    
    //@TODO: this method should be moved into a general utilities class
    public static Schema.DescribeSObjectResult getDescribeObjectByName(String objectName) {
    	Schema.DescribeSObjectResult objResult;
        for(Schema.SObjectType t : Schema.getGlobalDescribe().values()){
            if (t.getDescribe().getName() == objectName){
                objResult = t.getDescribe();
                break;
            }
        }
        return objResult;
    }
}