/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group User
* @description Trigger handler on User object to handle User status changes.
*/

public with sharing class USER_InActiveUser_TDTM extends TDTM_Runnable {
    public USER_InActiveUser_TDTM() {}

    /*******************************************************************************************************
    * @description Trigger Handler on User that handles deactivation of System Administrator Users.
    * @param newlist List of Users from Trigger.new context.
    * @param oldlist List of Users from Trigger.old context.
    * @param triggerAction The trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult DescribeSObjectResult for User.
    * @return DmlWrapper The objects to insert/update/delete.
    ********************************************************************************************************/
    public override DmlWrapper run(List<sObject> newlist, List<sObject> oldlist,
		                              TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();

        if (TDTM_Runnable.Action.AfterUpdate == triggerAction) {
            onAfterUpdate(newlist);
        }

        return dmlWrapper;
    }


    /*********************************************************************************************************
    * @description Handles the TDTM_Runnable.Action for AfterUpdate
    * @param newlist List of Users from Trigger.new context.
    * @return void
    **********************************************************************************************************/
    public void onAfterUpdate(List<sObject> newlist) {
        handleIsActiveStatusChange(newlist);
    }


    /*********************************************************************************************************
    * @description Handles the deactivation of a System Administrator by performing the following tasks:
    *               1) Sets the Error Notification Recipients to 'All Sys Admins' when set to the deactivated
    *                  System Administrator.
    *               2) Logs an Error record to the Error Log.
    *               3) Sends an email to the org's System Administrators when the deactived
    *                  System Administrator is the owner of Scheduled Jobs.
    * @param newlist List of Users from Trigger.new context.
    * @return void
    **********************************************************************************************************/
    private void handleIsActiveStatusChange(List<SObject> newlist) {
        Set<Id> inactiveSysAdminUserIds = new Set<Id>();

        Map<Id, Boolean> userIdToIsSysAdmin = USER_UserService.isSysAdmin(newlist);
        Map<Id, Boolean> userIdToIsActive = USER_UserService.isActiveUser(newlist);

        for (Id currentUserId : userIdToIsSysAdmin.keySet()) {
            if (userIdToIsSysAdmin.get(currentUserId) && !userIdToIsActive.get(currentUserId)) {
                inactiveSysAdminUserIds.add(currentUserId);
            }
        }

        if (!inactiveSysAdminUserIds.isEmpty()) {
            USER_UserService.handleDeactivatedSysAdminFuture(inactiveSysAdminUserIds);
        }
    }


}