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
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Primary class for recursion process control logic shared across all TDTM classes
 *
***/
public class TDTM_ProcessControl {

    private static TDTM_ProcessControl mock;
    @TestVisible
    private static void setMock(TDTM_ProcessControl mockInstance) {
        mock = mockInstance;
    }

    public static TDTM_ProcessControl newInstance(){
        return mock != null ? mock : new TDTM_ProcessControl();
    }

    private Boolean isRecursionAllowedInTests = false;

    /*******************************************************************************************************
    * @description Enum to define the various recursion prevention types used by all the related TDTM classes
    * Address Triggers:
    * - ADDR: Prevent commom recursion through most of the ADDR triggers
    * - ADDR_hasRunValidation: Prevent recursion specifically in the Address Validation/Verification related triggers
    * - ADDR_hasRunContactOnBefore: Prevent the AfterUpdate trigger on the Contact from processing changes
    *       to the Contact's address that are being made by this BeforeUpdate trigger. Only used by ADDR_Contact_TDTM.
    * Affiliation Triggers
    * - AFFL_doNotRunForContacts: Prevent execution for all Affiliation trigger on the Contact object
    * - AFFL_hasRunForAffiliations: Prevent recursion for Affiliations on the Affiliation object
    * - AFFL_hasRunForAccounts: Prevent recursion for Affiliation on the Account object
    * Allocation Triggers:
    * - ALLOC
    * Household Triggers:
    * - HH
    * - HH_isRunningBeforeInsert: Prevent execution of BeforeInsert trigger in ACCT_Accounts_TDTM
    * OPP Triggers:
    * - OPP_CampaignMember: Control recursion specifically for the OPP_CampaignMember_TDTM class
    * Recurring Donations Triggers:
    * - RD
    * Relationships Triggers:
    * - REL
    */
    public enum flag {
        ADDR_hasRunTrigger,
        ADDR_hasRunContactOnBefore,
        ADDR_hasRunValidation,
        CascadeDeletes,
        AFFL_doNotRunForContacts,
        AFFL_hasRunForAffiliations,
        AFFL_hasRunForAccounts,
        ALLOC,
        HH,
        HH_isRunningBeforeInsert,
        OPP_CampaignMember,
        RD,
        REL
    }

    /*******************************************************************************************************
    * @description Map to track the specific recursion type status
    */
    private static Map<flag, Integer> recursionMap = new Map<flag, Integer>();

    /*******************************************************************************************************
    * @description Increment/Decrement the static flag counter that tracks whether the processing
    *    trigger has been called already
    * @param f A flag whose static flag counter is to be incremented or decremented.
    * @param b A boolean where true increments the counter and false decrements it.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    public static void setRecursionFlag(flag f, boolean b) {
        Integer recursionFlag = (recursionMap.containsKey(f) ? recursionMap.get(f) : 0);
        recursionFlag += (b ? 1 : -1);
        if (recursionFlag < 0) {
            recursionFlag = 0;
        }
        recursionMap.put(f, recursionFlag);
    }

    /********************************************************************************************************
    * @description Returns true if the recursionFlag value is greater than 0
    * @return Boolean
    */
    public static Boolean isRecursive(flag f) {
        return (recursionMap.containsKey(f) ? recursionMap.get(f) : 0) > 0;
    }

    /*******************************************************************************************************
    * @description Modifies the global static collection of Trigger_Handler records to disable or enable
    * a specific TriggerHander by SObjectName and ApexClass name.
    * @param objName SObject Name
    * @param className Apex Class Name
    * @param state True (enable) | False (disable)
    */
    public static void toggleTriggerState(String objName, String className, Boolean state) {
        List<Trigger_Handler__c> triggerHandlers = TDTM_Config_API.getCachedRecords();
        for (Trigger_Handler__c th : triggerHandlers) {
            if (th.Object__c == objName && th.Class__c == className) {
                th.Active__c = state;
            }
        }
    }

    public Boolean isRecursionAllowedInTests() {
       return isRecursionAllowedInTests;
    }

    /**
     * @description Stub definition for the TDTM Process Controller that can be used for
     * NPSP tests that need to allow recursion in order to complete their test data setup.
     */
    private class TDTM_ProcessControlMockWithAllowRecursionInTests implements StubProvider {
        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {
            switch on (stubbedMethodName) {
                when 'isRecursionAllowedInTests' {
                    return true;
                }
            }
            return null;
        }
    }

    /**
     * @description Factory for test stubs. This method is used by multiple test methods
     * that need to allow recursion when they are setting up their test data.
     */
    private static TDTM_ProcessControl processControllerWithAllowRecursion() {
        TDTM_ProcessControl.TDTM_ProcessControlMockWithAllowRecursionInTests mock =
                new TDTM_ProcessControl.TDTM_ProcessControlMockWithAllowRecursionInTests();
        return (TDTM_ProcessControl) Test.createStub(TDTM_ProcessControl.class, mock);
    }

    @TestVisible
    private static void allowRecursionForComplexTestDataSetup() {
        setMock(processControllerWithAllowRecursion());
    }

}