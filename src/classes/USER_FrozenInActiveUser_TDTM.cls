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

public class USER_FrozenInActiveUser_TDTM extends TDTM_Runnable {
	
	public USER_FrozenInActiveUser_TDTM() {}

    /*******************************************************************************************************
    * @description Trigger Handler on Opportunity that handles managing Opportunity Contact Roles
    * @param listNew List of Opportunities from trigger new. 
    * @param listOld List of Opportunities from trigger old. 
    * @param triggerAction Which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult DescribeSObjectResult for Opportunity 
    * @return dmlWrapper The objects to insert/update/delete
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist,
						              TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();

        //================================
        // Determine which handler method to call based on the triggerAction
        //================================
        if(TDTM_Runnable.Action.BeforeInsert == triggerAction) {
            onBeforeInsert();

        } else if(TDTM_Runnable.Action.BeforeUpdate == triggerAction) {
            onBeforeUpdate();

        } else if(TDTM_Runnable.Action.BeforeDelete == triggerAction) {
            onBeforeDelete();

        } else if(TDTM_Runnable.Action.AfterInsert == triggerAction) {
            onAfterInsert();

        } else if(TDTM_Runnable.Action.AfterUpdate == triggerAction) {
            onAfterUpdate(newlist);

        } else if(TDTM_Runnable.Action.AfterDelete == triggerAction) {
            onAfterDelete();

        } else if(TDTM_Runnable.Action.AfterUndelete == triggerAction) {
            onAfterUnDelete();

        }

        return dmlWrapper;
    }
 

    /*********************************************************************************************************
    * @description Handles the TDTM_Runnable.Action for BeforeInsert 
    * @return void
    **********************************************************************************************************/
    public void onBeforeInsert() {}


    /*********************************************************************************************************
    * @description Handles the TDTM_Runnable.Action for BeforeUpdate
    * @return void
    **********************************************************************************************************/
    public void onBeforeUpdate() {}


    /*********************************************************************************************************
    * @description Handles the TDTM_Runnable.Action for BeforeDelete 
    * @return void
    **********************************************************************************************************/
    public void onBeforeDelete() {}


    /*********************************************************************************************************
    * @description Handles the TDTM_Runnable.Action for AfterInsert 
    * @return void
    **********************************************************************************************************/
    public void onAfterInsert() {}


    /*********************************************************************************************************
    * @description Handles the TDTM_Runnable.Action for AfterUpdate 
    * @return void
    **********************************************************************************************************/
    public void onAfterUpdate(List<SObject> newlist) {
        handleIsActiveIsFrozenStatusChanges(newlist);
    }


    /*********************************************************************************************************
    * @description Handles the TDTM_Runnable.Action for AfterDelete 
    * @return void
    **********************************************************************************************************/
    public void onAfterDelete() {}


    /*********************************************************************************************************
    * @description Handles the TDTM_Runnable.Action for AfterUndelete 
    * @return void
    **********************************************************************************************************/
    public void onAfterUnDelete() {}


    /*********************************************************************************************************
    * @description Handles IsActive/IsFrozen changes for Users.
    * @param newList List of Users from trigger new.
    * @return void
    **********************************************************************************************************/
    private void handleIsActiveIsFrozenStatusChanges(List<SObject> newlist) {
        Set<Id> inactiveOrFrozenSysAdminUserIds = new Set<Id>();

        Map<Id, Boolean> userIdToIsSysAdmin = USER_UserService.isSysAdmin(newlist);
        Map<Id, Boolean> userIdToIsActive = USER_UserService.isActiveUser(newlist);
        Map<Id, Boolean> userIdToIsFrozen = USER_UserService.isFrozenUser(newlist);

        for(Id currentUserId : userIdToIsSysAdmin.keySet()) {
            if(userIdToIsSysAdmin.get(currentUserId)
                && (!userIdToIsActive.get(currentUserId)
                    || userIdToIsFrozen.get(currentUserId))) {
                inactiveOrFrozenSysAdminUserIds.add(currentUserId);
            }
        }

        USER_UserService.applySysAdminIsActiveIsFrozenStatusChangesFuture(inactiveOrFrozenSysAdminUserIds);
    }

    
} // end class USER_FrozenInActiveUser_TDTM