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
* @group CMT Filter Rules
* @description Service class to handle evaluating CMT Filter Rules (i.e., all Rules within a specified Filter Group)
*/
public class CMT_FilterRuleEval_SVC {

    /**
     * @description Static map of instantiated Filter_Rule__mdt by FilterGroupId
     */
    private static Map<Id, List<CMT_FilterRule>> mapOfFilterRulesByGroupId = new Map<Id, List<CMT_FilterRule>>();

    /**
     * @description For a given SObject detail record and possibly a related related record, evaluate the
     * record(s) against the FilterRules in the specified FilterGroupId.
     * @param detailRows A collection of SObject records to be processed.
     * @param filterGroupId The Id of specific FilterGroup to retrieve the Filter_Rules for to evaluate against
     * @return True if the record passed the rule or False if it failed the rule.
     */
    public static Boolean evaluateFilterGroup(List<SObject> detailRows, Id filterGroupId) {

        // If the Rules within the Filter Group have not already been instantiated, retrieve them
        // and save the list of instantiated rules into the static map
        if (!mapOfFilterRulesByGroupId.containsKey(filterGroupId)) {
            List<CMT_FilterRule> rules = new List<CMT_FilterRule>();
            for (Filter_Rule__mdt rule : CMT_FilterRule_SEL.getFilterRulesByGroup().get(filterGroupId)) {
                rules.add(new CMT_FilterRule(rule));
            }
            mapOfFilterRulesByGroupId.put(filterGroupId, rules);
        }

        List<CMT_FilterRule> rulesToEvaluate = mapOfFilterRulesByGroupId.get(filterGroupId);

        for (SObject record : detailRows) {
            SObjectType objType = record.getSObjectType();
            for (CMT_FilterRule rule : rulesToEvaluate) {
                if (objType == rule.getObjectType()) {
                    if (!rule.isIncluded(record)) {
                        // No reason to continue if any one rule for any one record fails the evaluation
                        return false;
                    }
                }
            }
        }

        // if make it all the way through the rules for all records without any exclusions, then it passes
        return true;
    }

}