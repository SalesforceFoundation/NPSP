/*
    Copyright (c) 2019, Salesforce.org
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
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description Global API class that exposes a System.Callable interface for external
* applications and customers to leverage for future NPSP api's
*/
global with sharing class Callable_API implements System.Callable {

    /*******************************************************************************************************
    * @description Exception class for Malformed Method Invocations
    ********************************************************************************************************/
    public class MalformedMethodInvocationException extends Exception {}


    @TestVisible
    private AdvancedMappingEnablementService advancedMappingEnablementService {
        get {
            if (advancedMappingEnablementService == null) {
                advancedMappingEnablementService = new AdvancedMappingEnablementService();
            }
            return advancedMappingEnablementService;
        }
        set;
    }

    @TestVisible
    private GiftEntryEnablementService giftEntryEnablementService {
        get {
            if (giftEntryEnablementService == null) {
                giftEntryEnablementService = new GiftEntryEnablementService();
            }
            return giftEntryEnablementService;
        }
        set;
    }

    @TestVisible
    PMT_RefundService refundService {
        get {
            if (refundService == null) {
                refundService = new PMT_RefundService();
            }
            return refundService;
        }
        set;
    }

    /*******************************************************************************************************
    * @description call function implementation of the callable Interface will dispatch to the appropriate
    * action handler based on the action text
    * @param action string of the target action
    * @param params name value map of arguments
    * @return Object returned will depend on the results of the target function otherwise it returns true
    ********************************************************************************************************/
    global Object call(String action, Map<String, Object> params) {
        String cleanActionText = (String.isBlank(action) ? '' : action.toLowerCase());

        CallableApiParameters paramService = new CallableApiParameters(params);

        switch on (cleanActionText) {
            when 'tdtm.disablealltriggers' {
                TDTM_Config_API.disableAllTriggers();

            } when 'opp.mapstagetostate' {
                String oppStage = paramService.getString(CallableApiParameters.PARAM_OPPORTUNITY_STAGE);
                return OPP_StageMappingUtil.determineOppStateFromOppStage(oppStage);

            } when 'crlp.getdefinitionsforrolluptype' {
                String rollupType = paramService.getString(CallableApiParameters.PARAM_ROLLUP_TYPE);

                CRLP_ApiService crlpApiSvc = new CRLP_ApiService();
                List<CRLP_Rollup> response = crlpApiSvc.getRollupDefinitions(rollupType);

                return JSON.serialize(response, true);

            } when 'crlp.executerollups' {
                Id parentId = paramService.getString(CallableApiParameters.PARAM_ROLLUP_PARENTID);
                String rollupType = paramService.getString(CallableApiParameters.PARAM_ROLLUP_TYPE);
                List<CRLP_Rollup> rollupDefs = paramService.getRollupDefinitions(CallableApiParameters.PARAM_ROLLUP_DEFS);
                Boolean commitToDb = paramService.getBoolean(CallableApiParameters.PARAM_ROLLUP_COMMIT, false);
                Map<Id, Map<SObjectType, List<SObject>>> rollupData = paramService.getRollupDataMap(CallableApiParameters.PARAM_ROLLUP_DATA);

                CRLP_ApiService crlpApiSvc = new CRLP_ApiService();
                rollupDefs = crlpApiSvc.executeRollups(parentId, rollupType, rollupDefs, rollupData, commitToDb);

                return JSON.serialize(rollupDefs,false);

            } when 'crlp.iscrlpenabled' {
                CRLP_ApiService crlpApiSvc = new CRLP_ApiService();
                return crlpApiSvc.isCrlpEnabled();

            } when 'err.dispatchaction' {
                // This method is to be used only by Salesforce.org apps and is subject to change at any time. Do NOT call this method.
                // If you do so, your functionality can break without any warning or liability from Salesforce.
               
                // Since there are multiple actions that can be invoked, the ERR_Dispatch_API will get the remaining params out of the
                // parameter service depending on which action was invoked
                return CallableDispatchService_ERR.getInstanceOf(paramService).dispatch();

            } when 'rd2.executedatamigration' {
                return RD2_EnablementDelegate_CTRL.callableApiRunMigration();

            } when 'rd2.pause' {
                Map<Id, RD2_ApiService.PauseObject> pauseObjectsById = paramService
                    .withRequiredParamCheck()
                    .getPauseObjectsById(CallableApiParameters.PARAM_PAUSE_DATA);

                return new RD2_ApiService().pause(pauseObjectsById);

            } when 'rd2.queryschedules' {
                Set<Id> rdIds = paramService
                    .withRequiredParamCheck()
                    .getSetId(CallableApiParameters.PARAM_RECORD_IDS);

                return new RD2_ApiService().querySchedules(rdIds);

            } when 'rd2.queryinstallments' {
                Date startDate = paramService
                    .getDate(CallableApiParameters.PARAM_START_DATE);
                Date endDate = paramService
                    .getDate(CallableApiParameters.PARAM_END_DATE);
                Set<Id> rdIds = paramService
                    .withRequiredParamCheck()
                    .getSetId(CallableApiParameters.PARAM_RECORD_IDS);

                return new RD2_ApiService().queryInstallments(startDate, endDate, rdIds);

            } when 'settings.enableenhancedrecurringdonations' {
                Boolean scheduleJobsWhenComplete = paramService.getBoolean(CallableApiParameters.PARAM_SCHEDULE_JOBS, true);
                RD2_EnablementDelegate_CTRL.callableApiEnableEnhancement(scheduleJobsWhenComplete);
                return null;

            } when 'allo.processoppsandpmts' {
                // This method is to be used only by Salesforce.org apps and is subject to change at any time. Do NOT call this method.
                // If you do so, your functionality can break without any warning or liability from Salesforce.
                Set<Id> opportunityIds = paramService.getSetId(CallableApiParameters.PARAM_OPPORTUNITY_IDS);
                String contextType = paramService.getString(CallableApiParameters.PARAM_CONTEXT_TYPE);
                Datetime processingBoundary = paramService.getDatetime(CallableApiParameters.PARAM_PROCESSING_BOUNDARY);
                Boolean disableOppAndPmtAlloTriggers = paramService.getBoolean(CallableApiParameters.PARAM_DISABLE_ALLOCATION_TRIGGERS);

                return new ALLO_AllocationsService()
                                .withAllocationTriggersDisabled(disableOppAndPmtAlloTriggers)
                                .withAlternateContextType(contextType)
                                .withCommitAndClearRecordsEnabled(true)
                                .processRecords(opportunityIds);

            } when 'allo.validatepmtallocationconfig' {
                // This method is to be used only by Salesforce.org apps and is subject to change at any time. Do NOT call this method.
                // If you do so, your functionality can break without any warning or liability from Salesforce.               
                return ALLO_AllocationsSettings.getSettings().validatePaymentAllocationsConfiguration();

             } when 'pmt.procressrefunds' {
                List<npe01__OppPayment__c> refunds = paramService.getSObjects(CallableApiParameters.PARAM_REFUND_RECORDS);
                    refundService.withRefundRecords(refunds);
                    refundService.adjustAllocationsAndOpportunities();
                    refundService.updateAllocationsAndOpportunities();
                
                return null;
            } 
            when 'settings.enablecustomizablerollups' {
                Boolean scheduleJobsWhenComplete = paramService.getBoolean(CallableApiParameters.PARAM_SCHEDULE_JOBS, true);
                return new CRLP_EnablementService().enable(scheduleJobsWhenComplete);

            } when 'apex.schedulejob' {
                // This method schedules the specified Schedulable class using the specified job name & cron expression.
                // It should only be used for Schedulable classes that are in the NPSP Managed Package.
                // It returns the Job ID of the Scheduled Job.
                return CallableApiApexDelegationService.handleApexScheduleJob(params);

            } when 'settings.enableadvancedmapping' {
                if (advancedMappingEnablementService.isEnabled()) {
                    return null;
                }

                advancedMappingEnablementService.enable();

                return null;

            } when 'settings.enablegiftentry' {
                if (giftEntryEnablementService.isEnabled()) {
                    return null;
                }

                giftEntryEnablementService.enable();

                return null;
            }
            when else {
                throw new MalformedMethodInvocationException(
                    String.format(System.Label.CallableApiMethodNotImplemented, new List<String> { action })
                );
            }
        }

        // if the action does not return a value then return success
        return true;
    }
}
