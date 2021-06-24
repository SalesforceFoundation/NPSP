/*
    Copyright (c) 2014, Salesforce.org
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
* @group Address Management
* @group-content ../../ApexDocContent/Addresses.htm
* @description trigger handler on Address object to support propagating addresses 
* @async_support this trigger handler has been tested with async=true, and appears to not cause problems.
*/
public class ADDR_Addresses_TDTM extends TDTM_Runnable {

    private final TDTM_ProcessControl.flag recursionFlag =
            TDTM_ProcessControl.flag.ADDR_hasRunTrigger;

    /*******************************************************************************************************
    * @description Trigger Handler on Address that handles address management.  Updates the appropriate
    * Accounts and Contacts when an Address is changed.
    * @param listNew the list of Addresses from trigger new. 
    * @param listOld the list of Addresses from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Addresses 
    * @return dmlWrapper.  
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // STRATEGY
        // when an Address is created or modified, we need to consider three other objects we may need to update:
        // - the Address's HH Account, if it is marked Default_Address
        // - any other HH Addresses that should no longer be Default
        // - the HH Contacts, if the Address is Default, or a contact specifies it in Address_Override
        //
        // So a change to the Address to become Default, or a change in its Address fields
        // will require visiting all the HH Accounts, and deciding whether we are propagating the change
        // to all related objects, or just to Contacts who are using the Address as their override.
        //

        // prevent recursion
        if (isRecursive()) {
            UTIL_Debug.debug('**** RECURSION: Stop Addr Trigger recursion in ADDR_Addresses_TDTM');
            return null;
        }

        Addresses addresses;
        switch on triggerAction {
            when BeforeInsert {
                addresses = new Addresses(listNew);
                addresses.onBeforeInsert();
                return null;
            }
            when AfterInsert {
                activateRecursionFlag();
                addresses = new Addresses(listNew);
                addresses.onAfterInsert();
            }
            when BeforeUpdate {
                addresses = new Addresses(listNew, listOld);
                addresses.onBeforeUpdate();
                return null;
            }
            when AfterUpdate {
                activateRecursionFlag();
                addresses = new Addresses(listNew, listOld);
                addresses.onAfterUpdate();
            }
            when AfterDelete {
                activateRecursionFlag();
                addresses = new Addresses(listOld);
                addresses.onAfterDelete();
            }
        }

        deactivateRecursionFlag();
        return null;
    }

    private Boolean isRecursive() {
        return TDTM_ProcessControl.isRecursive(recursionFlag);
    }

    private void activateRecursionFlag() {
        TDTM_ProcessControl.setRecursionFlag(recursionFlag, true);
    }

    private void deactivateRecursionFlag() {
        TDTM_ProcessControl.setRecursionFlag(recursionFlag, false);
    }

}