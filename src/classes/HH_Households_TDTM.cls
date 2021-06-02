/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2011 (2.0)
* @group Households
* @group-content ../../ApexDocContent/Households.htm
* @description Trigger Handler on Contact to deal with managing Households (Objects), and naming exclusions
* on contact.
*/
public without sharing class HH_Households_TDTM extends TDTM_Runnable {

    public static Boolean isNewContactInsert = false;

    @TestVisible
    private HouseholdSettings settings {
        get {
            if (settings == null) {
                settings = new HouseholdSettings();
            }
            return settings;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Trigger Handler on Contacts that handles managing Households (Objects) and naming exclusions
    * on contact.
    * @param newlist List of Contacts from trigger new.
    * @param oldlist List of Contacts from trigger old.
    * @param triggerAction Which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult DescribeSObjectResult for Contacts
    * @return dmlWrapper The objects to insert/update/delete
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();

        switch on triggerAction {
            when BeforeInsert {
                //prevent execution of BeforeUpdate in ACCT_Accounts_TDTM
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH_isRunningBeforeInsert, true);
                isNewContactInsert = true;
                Contacts contacts = new Contacts(newlist);
                contacts.onBeforeInsert();
                isNewContactInsert = false;
            }
            when BeforeUpdate {
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);
                Contacts contacts = new Contacts(newlist, oldlist);
                contacts.onBeforeUpdate();
            }
            when AfterInsert {
                isNewContactInsert = true;
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH_isRunningBeforeInsert, false);
                //AFTER INSERT - NOTE: naming has to be handled inside othe household inserts,
                //since we don't have the contact's household ids until after the insert
                //we'll check the trigger action again there to make sure it doesn't run twice
                if (orgUsesLegacyHouseholds()) {
                    ContactsInLegacyHouseholds legacyHouseholdContacts =
                            ContactsInLegacyHouseholds.newInstance(newlist);
                    legacyHouseholdContacts.onAfterInsert();
                }
                isNewContactInsert = false;
            }
            when AfterDelete {
                Contacts contacts = new Contacts(oldlist);
                contacts.onAfterDelete();
            }
            when AfterUpdate {
                ContactsInLegacyHouseholds legacyHouseholdContacts =
                        new ContactsInLegacyHouseholds(
                                newlist, new Map<Id, Contact>((List<Contact>) oldList));
                legacyHouseholdContacts.onAfterUpdate();
            }
        }
        return dmlWrapper;
    }

    private Boolean orgUsesLegacyHouseholds() {
        return settings.isAllProcessor() || settings.isAllIndividualsProcessor();
    }
}