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
* @description Service methods to
*
*/
public class CRLP_ConfigBuilder_SVC {

    /** @description Metadata queued up for deployment */
    private static List<List<Metadata.CustomMetadata>> queuedNestedMetadata = new List<List<Metadata.CustomMetadata>>();

    public static void queueRollupConfigForDeploy(List<CRLP_RollupCMT.FilterGroup> groupsAndRules) {

        List<Metadata.CustomMetadata> groups = new List<Metadata.CustomMetadata>();
        List<Metadata.CustomMetadata> rules = new List<Metadata.CustomMetadata>();
        for (CRLP_RollupCMT.FilterGroup fg : groupsAndRules) {
            groups.add(fg.getMetadataRecord());
            for (CRLP_RollupCMT.FilterRule fr : fg.rules) {
                rules.add(fr.getMetadataRecord());
            }
        }

        queuedNestedMetadata.add(groups);
        queuedNestedMetadata.add(rules);
    }

    public static void queueRollupConfigForDeploy(List<CRLP_RollupCMT.Rollup> rollups) {
        List<Metadata.CustomMetadata> rollupMD = new List<Metadata.CustomMetadata>();
        for (CRLP_RollupCMT.Rollup rlp : rollups) {
            rollupMD.add(rlp.getMetadataRecord());
        }

        queuedNestedMetadata.add(rollupMD);
    }

    public static String deployedQueuedMetadataTypes() {
        String jobId = getUniqueJobId();
        CMT_MetadataAPI.deployMetadata(jobId, queuedNestedMetadata);
        return jobId;
    }

    /**
     * @return A 10 character unique 'jobId' to use for
     */
    public static String getUniqueJobId() {
        return UserInfo.getUserId().left(15).right(4).toUpperCase() +
                String.valueOf(Integer.valueOf(math.rint(math.random()*5000000))).right(6);
    }

}