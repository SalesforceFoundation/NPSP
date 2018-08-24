/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Utilities
* @description A more controllable method to handle the asynchronous submission of Telemetry data to the LMO
* without having to worry about governor limits when it comes to querying large datasets in LDV orgs. By iterating
* through a custom List<> of Enum Types with a batch size of ONE, the execute() method can call a service method
* to handle querying and submitting the specific telemetry data only for that Enum type. If for some reason that
* one query were to fail, which is theoretically possible in a huge organization where there may be other jobs
* executing or other factors at play, the rest of this job will continue. That ensures that our LMO collects as much
* data as possible. In addition, it can help us identify which specific telemetry data processes are failing.
*/
public class UTIL_OrgTelemetry_BATCH implements Database.Batchable<UTIL_OrgTelemetry_SVC.TelemetryTypeEnum> {

    /**
     * @description List of High Level Telemetry Data Types to be processed asynchronously by this batch job.
     */
    private static final List<UTIL_OrgTelemetry_SVC.TelemetryTypeEnum> telemetryTypesList =
        new List<UTIL_OrgTelemetry_SVC.TelemetryTypeEnum>{
            UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.NPSP_Settings,
            UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Org_Environment,
            UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Data_MaxNumRelatedOpps,
            UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Data_Count_of_RD_Opps_All,
            UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Data_Count_of_RD_Opps_OpenEnded,
            UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.Data_CountOfErrorLog
        };

    /**
     * @description Return the list of Telemetry Type Enum values to be processed by this batch job
     * @param BC BatchableContext (not used)
     * @return telemetryTypesList list from above
     */
    public Iterable<UTIL_OrgTelemetry_SVC.TelemetryTypeEnum> start(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            return UTIL_OrgTelemetry_BATCH.telemetryTypesList;
        } else {
            return new List<UTIL_OrgTelemetry_SVC.TelemetryTypeEnum>{UTIL_OrgTelemetry_SVC.TelemetryTypeEnum.NPSP_Settings};
        }
    }

    /**
     * @description Process the specific set of FeatureParameter submissions to the LMO based on the Telemetry
     * Type Enum value.
     * @param info BatchableContext (not used)
     * @param types List<UTIL_OrgTelemetry_SVC.TelemetryTypeEnum> -- Batch Size of ONE is required
     */
    public void execute(Database.BatchableContext info, List<UTIL_OrgTelemetry_SVC.TelemetryTypeEnum> types) {
        UTIL_OrgTelemetry_SVC.processTelemetryType(types[0]);
    }

    public void finish(Database.BatchableContext info) {}
}