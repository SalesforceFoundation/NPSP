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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Wrapper class of Rollup Processing Options used by the CRLP_RollupProcessor_SVC methods
*
*/
public class CRLP_RollupProcessingOptions {

    /**
     * @description Defines the type of rollups being executed by the specific batch job. This is used with the
     * RollupFilterSetting enum to select the correct Rollup__mdt records to use for the entire rollup operation.
     */
    public Enum RollupType {
        AccountHardCredit,
        AccountSoftCredit,
        ContactHardCredit,
        AccountContactSoftCredit,
        ContactSoftCredit,
        GAU,
        RecurringDonations
    }

    /** @description Map the string name for each of the different rollup types enum vales */
    public static Map<String, RollupType> rollupTypeByName {
        get {
            if (rollupTypeByName == null) {
                rollupTypeByName = new Map<String, RollupType>{
                    RollupType.ContactHardCredit.name().toLowerCase() => RollupType.ContactHardCredit,
                    RollupType.ContactSoftCredit.name().toLowerCase() => RollupType.ContactSoftCredit,
                    RollupType.AccountHardCredit.name().toLowerCase() => RollupType.AccountHardCredit,
                    RollupType.AccountSoftCredit.name().toLowerCase() => RollupType.AccountSoftCredit,
                    RollupType.AccountContactSoftCredit.name().toLowerCase() => RollupType.AccountContactSoftCredit,
                    RollupType.RecurringDonations.name().toLowerCase() => RollupType.RecurringDonations,
                    RollupType.GAU.name().toLowerCase() => RollupType.GAU
                };
            }
            return rollupTypeByName;
        } set;
    }

    /**
     * @description The processing mode for the calling batch operation - normal or Skew mode. In Skew mode,
     * the List<CRLP_Rollup> collection is saved back into the ProcessingOptions class so that it can be
     * kept in a stateful var in the calling batch job; allowing rollups for a single parent record to extend
     * beyond a single batch iteration
     */
    public Enum BatchJobMode {
        NonSkewMode, SkewMode
    }

    /**
     * @description To aid in performance, the rollup operations can be limited to the following:
     * - All : All rollups for the parent are processed.
     * - DaysAgoOnly : Only Rollups using "Days Ago" (i.e., "Last N Days") are processed
     * - NonDaysAgoOnly : Only Rollups NOT using "Days Ago" are processed
     * - MembershipOnly : Only Rollups that target a Membership field
     */
    public Enum RollupTypeFilter {
        All,            // All the defined rollups for the target Summary object
        DaysAgoOnly,    // Only rollups with a TimeBoundOperationType of "Days Ago"
        NonDaysAgo,     // Only rollups without a TimeBoundOperationType of "Days Ago"
        MembershipsOnly // Only rolups with "Membership" in the Summary Field Name
    }

    /**
     * @description Processing Options to use for the CRLP_RollupProcessor.startRollupProcessing() method. These
     * define special conditions that the processing logic uses.
     */
    public class ProcessingOptions {

        /**
        * @description This is set to true if the Summary Object should be built and compared to the current object
        * in the database. If set to false, the rollup happens and the RollupDefinition instances are updated
        * accordingly, but the target Summary SObject is not built.
        */
        public Boolean doSummaryObjectComparison = true;

        /**
        * @description This is set to true when the Map of RollupDefinitions by ParentId is used to both retrieve
        * Rollup Definitions and to store the Rollup Definitions when done. Note that this should always be set to
        * true when running in Skew Batch Mode.
        */
        public Boolean useRollupDefsByParentIdMap = false;
    }
}