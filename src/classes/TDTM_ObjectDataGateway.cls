/*
    Copyright (c) 2013, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
 * @author Salesforce.org
 * @date 2014
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Class that queries custom object to retrieve classes to call for creation or modification
 * of a record of a specific object type.
 */
public without sharing class TDTM_ObjectDataGateway implements TDTM_iTableDataGateway {
    
    //private static List<ToRunOnObjectAction> classesQueried = new List<ToRunOnObjectAction>();
    private static Integer rowCount;
    
    /*******************************************************************************************************
     * @description Checks is any TDTM records exist.
     * @return Boolean True is there are no TDTM records. False otherwise.
     */
    public Boolean isEmpty() {
        if(rowCount == null) {
            List<Trigger_Handler__c> result = [select Id from Trigger_Handler__c limit 1];
            rowCount = result.size();
        }
        if(rowCount == 0) {
            return true;
        }
        return false;
    }

    /*******************************************************************************************************
     * @description Returns the classes that will be called for the specified ojbect and action. Returned list 
     *              is sorted by load order. Filters out in-active handlers and any where the list of 
     *              excluded usernames includes the current context user.
     * @param objectName The name of the object.
     * @param action The action (before insert, after insert,...). 
     * @return List<SObject> List of classes to call, sorted by load order.
     **/
    public static List<SObject> getClassesToCallForObject(String objectName, TDTM_Runnable.Action action) {   
        string strAction = action.Name();
        string currUserName = UserInfo.getUserName();
        List<SObject> listClasses = new List<Sobject>();
        for (Trigger_Handler__c th : listTH) {
            Set<String> excludedUserNames = (th.Usernames_to_Exclude__c != null ?
                    new Set<String>(th.Usernames_to_Exclude__c.split(';')) : new Set<String>());
            if (th.Object__c == objectName && th.Trigger_Action__c.contains(strAction) && th.Active__c == true
                    && !excludedUserNames.contains(currUserName)) {
                listClasses.add(th);
            }
        }
        return listClasses;
    }

    /*******************************************************************************************************
     * @description to allow test code to modify the saved trigger handlers and have them reread into the cache.
     */
    public static void ClearCachedTriggerHandlersForTest() {
        listTH = null;
    }

    /*******************************************************************************************************
     * @description holds the trigger handlers cached in a list, to avoid repetitive soql calls.
     */
    public static list<Trigger_Handler__c> listTH {
        get {
            if (ADV_PackageInfo_SVC.useAdv() && ADV_PackageInfo_SVC.getApiNPSP() != null) {
                listTH = ADV_PackageInfo_SVC.getApiNPSP().getDefaultTdtmConfigNpspRecords(listTH);
            } else {
                if (listTH == null) {
                    listTH =  [SELECT Asynchronous__c, Class__c, Load_Order__c, Object__c, Active__c, Usernames_to_Exclude__c,
                        Trigger_Action__c, User_Managed__c FROM Trigger_Handler__c ORDER BY Load_Order__c];
                }
            }
            return listTH;
        }
        set;
    }
}