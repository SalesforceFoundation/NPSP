/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Recurring Donations
* @description Trigger on Recurring Donations when enhanced Recurring Donations are enabled
*
*/
public class RD2_RecurringDonations_TDTM extends TDTM_Runnable {
    
    /***
    * @description Recurring Donation naming service instance
    */
    @TestVisible
    private RD2_NamingService namingService {
        get {
            if (namingService == null) {
                namingService = new RD2_NamingService();
            }
            return namingService;
        }
        set;
    }

    /***
    * @description Trigger handler on Recurring Donations when enhancement is enabled
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    * @param objResult Recurring Donation SObject describe
    * @return dmlWrapper
    */
    public override DmlWrapper run(
        List<SObject> rds, List<SObject> oldRds, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult
    ) {

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            return null;
        }

        autogenerateNames(rds, oldRds, triggerAction);

        dispatchToIntegrationGateway(rds, oldRds, triggerAction);

        return null;
    }

    /***
    * @description Autogenerates recurring donation names 
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    */
    public void autogenerateNames(List<SObject> rds, List<SObject> oldRds, TDTM_Runnable.Action triggerAction) {

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            namingService.autogenerateNames(rds);
            
        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            namingService.autogenerateNamesOnChange(rds, oldRds);
        }
    }

    /***
    * @description Dispatches trigger records to integration gateway
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    */
    private void dispatchToIntegrationGateway(List<SObject> rds, List<SObject> oldRds, TDTM_Runnable.Action triggerAction) {
        if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
            integrationGateway.handleBeforeDelete(oldRds);
        }
    }

}