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

/**
 * Class that queries Custom Object to retrieve classes to call on a specific trigger. 
 */
public with sharing class TDTM_ObjectDataGateway implements TDTM_iTableDataGateway {
    
    public static Boolean isEmpty() {
    	//@TODO: is this the best way to check if a table (object) is empty?
    	List<AggregateResult> result = [select count(Id) rowCount from Trigger_Handler__c];
    	Integer rowCount = (Integer)result[0].get('rowCount');
    	if(rowCount == 0)
    	   return true;	
    	return false;
    }
    
    public static List<SObject> getClassesToCallOnTriggers(String objectName, TDTM_TriggerActionHelper.Action action) {   
        
        return [select Asynchronous__c, Class__c, Load_Order__c, Object__c, Active__c, Trigger_Action__c 
                from Trigger_Handler__c where Active__c = true and Object__c = :objectName and 
                Trigger_Action__c = :action.name() order by Load_Order__c];
    }
}