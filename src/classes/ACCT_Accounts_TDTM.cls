/*
    Copyright (c) 2014 Salesforce.org
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
*
* @group Accounts
* @group-content ../../ApexDocContent/Accounts.htm
*
* @description Trigger Handler on Accounts that handles ensuring the correct system flags are set on
* our special accounts (Household, One-to-One), and also detects changes on Household Account that requires
* name updating.
*/
public class ACCT_Accounts_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on Accounts that handles ensuring the correct system flags are set on
    * our special accounts (Household, One-to-One), and also detects changes on Household Account that requires
    * name updating.
    * @param listNew the list of Accounts from trigger new. 
    * @param listOld the list of Accounts from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Accounts 
    * @return dmlWrapper.  always null.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        switch on triggerAction {
            when BeforeInsert {
                Accounts accounts = new Accounts(listNew);
                accounts.onBeforeInsert();
            }
            when BeforeUpdate {
                if (!isContactBeforeInsertContext()) {
                    Accounts accounts = new Accounts(listNew, listOld);
                    accounts.onBeforeUpdate();
                }
            }
            when AfterUpdate {
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);
                Accounts accounts = new Accounts(listNew, listOld);
                accounts.onAfterUpdate();
            }
        }

        return null;
    }

    private Boolean isContactBeforeInsertContext() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.HH_isRunningBeforeInsert);
    }
}