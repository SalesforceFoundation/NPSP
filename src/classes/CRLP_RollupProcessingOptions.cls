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
     * @description Processing Options to use for the startRollupsProcess
     * These are set by the calling Batch or Queueable job to define how the rollups will be processed by the
     * CRLP_RollupProcessor_SVC methods.
     */
    public class ProcessingOptions {

        /** @description Define the type of batch job mode - LDV or NonLDV mode */
        public BatchJobMode mode = BatchJobMode.NonSkewMode;

        /** @description Type of rollup being performed */
        public RollupType rollupJobType;

        /** @description Support filtering the specific types of Rollup definitions that will be processed */
        public RollupTypeFilter rollupTypesToProcess = RollupTypeFilter.All;

        public SObjectType parentObjType;   // Summary object (Account, Contact, GAU)
        public SObjectType detailObjType;   // Used when working with Soft Credits to have a way to know what the detail object is
        public String parentKeyField;       // Used to know how to get the Id of the Parent record from the supplied detail record

        /**
         * @description used to recieve and return the last Parent record id processed by startRollupsForLDV().
         * The value is saved as a stateful var in the calling batch process
         */
        public Id lastParentIdProcessed;

        /**
         * @description Used to return a true to the calling LDV class when the last parent Id was removed from
         * the list of updated SObjects
         */
        public Boolean lastParentIdRemovedFromUpdatesList = false;

        /**
         * @description Stateful rollups collection for LDV Mode. Needs to stay in ProcessingOptions to allow for passing
         * between various service methods with the rest of the processing options
         */
        public Map<Id, List<CRLP_Rollup>> mapOfRollupsByParentId = new Map<Id, List<CRLP_Rollup>>();

        /**
         * @description When working with Account Soft Credit Rollups, this var is used to hold a list
         * of Opportunity Id's that have been rolled up to a given Account. The data is retained in a stateful var
         * in the batch job to support scenarios where a given Account's rollups straddle multiple batch operations
         */
        public Map<Id,Set<Id>> mapOfProcessedOppIdsByParentId = new Map<Id,Set<Id>>();

        /**
         * @description Set the property
         */
        public void setMapOfProcessedOppIdsByParentId(Map<Id,Set<Id>> theMap, List<Id> parentIds) {
            this.mapOfProcessedOppIdsByParentId = new Map<Id, Set<Id>>();
            for (Id mapKey : parentIds) {
                if (theMap.containsKey(mapKey)) {
                    this.mapOfProcessedOppIdsByParentId.put(mapKey, theMap.get(mapKey));
                }
            }
        }

        /**
         * @description Set the property by fully cloning the passed Map so that the Map and the list of elements
         * in each map value are a complete copy of the passed version. This is necesssary because the processing
         * job will add every parent id to this map, but the stateful var only needs to retain the first and last
         * parent id's processed.
         */
        public void setMapOfRollupsByParentId(Map<Id, List<CRLP_Rollup>> theMap, List<Id> parentIds) {
            this.mapOfRollupsByParentId = new Map<Id, List<CRLP_Rollup>>();
            for (Id mapKey : parentIds) {
                if (theMap.get(mapKey) != null) {
                    List<CRLP_Rollup> newList = new List<CRLP_Rollup>();
                    for (CRLP_Rollup r : theMap.get(mapKey)) {
                        newList.add(r.clone());
                    }
                    this.mapOfRollupsByParentId.put(mapKey, newList);
                }
            }
        }

        /**
         * @description Returns the updated Map of processed Opportunity Id's by the parent Account Id.
         * Used to expose this value to the LDV Batch Job to retrieve the current setting.
         */
        public Map<Id,Set<Id>> getUpdatedMapOfProcessedOppsByParentId() {
            return this.mapOfProcessedOppIdsByParentId;
        }

        /**
         * @description Returns the updated Map of List<CRLP_Rollup> values by the parent record Id.
         * Used to expose this value to the LDV Batch Job to retrieve the current setting.
         */
        public Map<Id, List<CRLP_Rollup>> getUpdatedMapOfRollupsByParentId() {
            return this.mapOfRollupsByParentId;
        }

        /**
         * @description Returns the last parent id processed by the RollupsProcessor logic for the given execution scope
         */
        public Id getLastParentIdProcessed() {
            return this.lastParentIdProcessed;
        }

    }

}