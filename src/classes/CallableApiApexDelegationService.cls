/*
    Copyright (c) 2021, Salesforce.org
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
* @date 2021
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description API class that handles apex jobs
*/

public inherited sharing class CallableApiApexDelegationService {

    /*******************************************************************************************************
    * @description Handles scheduling apex jobs specified in params
    * @param params name value map of arguments
    * @return Object returned is String with CronTrigger.Id
    ********************************************************************************************************/
    public static Object handleApexScheduleJob(Map<String, Object> params) {
        CallableApiParameters paramService = new CallableApiParameters(params)
            .withRequiredParamCheck()
            .withEmptyStringParamCheck();

        String jobName = paramService.getString(CallableApiParameters.PARAM_SCHEDULED_JOB_NAME);
        String cronExpression = paramService.getString(CallableApiParameters.PARAM_SCHEDULED_JOB_CRON_EXPRESSION);
        String apexClass = paramService.getString(CallableApiParameters.PARAM_SCHEDULED_JOB_CLASS);

        Type apexClassType = Type.forName(apexClass);
        if (apexClassType == null) {
            throw new Callable_API.MalformedMethodInvocationException(
                    String.format(System.Label.CallableApiJobScheduleInvalidClass, new List<String> { apexClass })
            );
        }

        Schedulable schedulableClass = (Schedulable) apexClassType.newInstance();
        return System.schedule(jobName, cronExpression, schedulableClass);
    }
}
