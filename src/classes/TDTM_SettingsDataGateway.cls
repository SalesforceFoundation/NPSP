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
 * Class that queries Custom Settings to retrieve classes to call on a specific trigger. 
 */
public with sharing class TDTM_SettingsDataGateway implements TDTM_iTableDataGateway {

    private static Map<String, Trigger_Handler_Setting__c> allClassesToCall;
    
    public static Boolean isEmpty() {
    	Map<String, Trigger_Handler_Setting__c> allRows = Trigger_Handler_Setting__c.getAll();
    	if(allRows.size() == 0)
    	   return true;
    	return false;
    }
    
    public static List<SObject> getClassesToCallOnTriggers(String objectName, TDTM_TriggerActionHelper.Action action) {
        Map<String, SObject> classesToCallMap = new Map<String, SObject>();
        if (allClassesToCall == null) {
           allClassesToCall = Trigger_Handler_Setting__c.getAll();
        }
        
        //Filter by params
        for(Trigger_Handler_Setting__c setting : allClassesToCall.values()) {
        	if(setting.Object__c == objectName && setting.Trigger_Action__c == action.name()) {
        	   classesToCallMap.put(setting.Name, setting);
        	}
        }
        
        //Sort
        List<ClassToCallWrapper> classesToCallSorted = new List<ClassToCallWrapper>();
        for(SObject classToCall : classesToCallMap.values()) {
        	classesToCallSorted.add(new ClassToCallWrapper(classToCall));
        }
        classesToCallSorted.sort();
        
        //Put them back in a list of SObjects
        List<SObject> classesToCallFinal = new List<SObject>();
        for(ClassToCallWrapper wrapper : classesToCallSorted) {
        	classesToCallFinal.add(wrapper.triggerHandler);
        }
        return classesToCallFinal;
    }
    
    public class ClassToCallWrapper implements Comparable {

        public final SObject triggerHandler;
        
        public ClassToCallWrapper(SObject triggerHandler) { 
            System.debug('****Class to call in wrapper constructor: ' + triggerHandler);
            this.triggerHandler = triggerHandler; 
        }
            
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            ClassToCallWrapper compareToSSM = (ClassToCallWrapper)compareTo;
            
            Integer LoadOrderThis = Integer.valueOf(triggerHandler.get('Load_Order__c'));
            Integer LoadOrderThat = Integer.valueOf(compareToSSM.triggerHandler.get('Load_Order__c'));
                        
            // The return value of 0 indicates that both elements are equal
            if (LoadOrderThis > LoadOrderThat) return -1;
            else if (LoadOrderThis < LoadOrderThat) return 1;
            return 0;
        }
    }
}