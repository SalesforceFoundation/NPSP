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
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description API Class to allow caller to determine Opportunity's State (Uncommitted, Committed. or Finalized) using the Opportunities Stage and Household Settings
*/
public with sharing class OPP_StageMappingUtil {

    /******************************************************************************************************
    * @description Represents the overall state of the Opportunity.
    * UNCOMMITTED -- Donor has not yet agreed to make the donation.  Donation is unpaid.  This is useful
    * for soliciting or staging gifts.
    * COMMITTED --  Donor has agreed to make a donation.  Donation can be unpaid or partially paid.
    * More money is still expected from the donor.
    * FINALIZED -- Donation is completely received.  Donation can be fully or partially paid.  No more
    * money is expected for the donation.
    */
    @testVisible private static final String UNCOMMITTED_STATE_VAL = 'UNCOMMITTED';
    @testVisible private static final String COMMITTED_STATE_VAL = 'COMMITTED';
    @testVisible private static final String FINALIZED_STATE_VAL = 'FINALIZED';

    /******************************************************************************************************
    * @description Used to Cache Set of Opportunity Stages that mean Opportunity is in a Committed State.
    */
    private static Set<String> COMMITTED_STATE_SET = null;

    /******************************************************************************************************
    * @description Used to Cache Set of Opportunity Stages that mean Opportunity is in a Finalized State.
    */
    private static Set<String> FINALIZED_STATE_SET = null;

    /******************************************************************************************************
    * @description Separator String used to parse Strings into multiple values
    */
    private static final String DEFAULT_SEPARATOR_VAL = ';';

    /*******************************************************************************************************
    * @description Determines the Opportunity State (UNCOMMITTED, COMMITTED, or FINALIZED) from the
    * Opportunity Stage.  If the Opportunity Stage does not map to a FINALIZED or COMMITTED state,
    * based on the Household Settings, it will return UNCOMMITTED.  It will always return UNCOMMITTED
    * if the settings are not configured.  It first checks the Opportunity Stage is a FINALIZED stage.  If
    * it is, it returns FINALIZED.  If it is not, it checks to see if the Opportunity Stage is a COMMITTED
    * stage.  If it is, it returns COMMITTED.  Otherwise, it returns UNCOMMITTED.
    *
    * NOTE: Opportunity Stage is treated as Case Insensitive, so Closed Won CLOSED WON and closed won are
    * all the same for this purpose.
    * @param String opportunityStage The opportunity stage to check the state of
    * @return String value representing the current opportunity state
    ********************************************************************************************************/
    public static String determineOppStateFromOppStage(String opportunityStage) {

        initializeStates();

        String oppStageToCheck = String.isNotBlank(opportunityStage) ? opportunityStage.trim().toLowerCase() : null;

        if (FINALIZED_STATE_SET != null && FINALIZED_STATE_SET.contains(oppStageToCheck)) {
            return FINALIZED_STATE_VAL;
        }

        if (COMMITTED_STATE_SET != null && COMMITTED_STATE_SET.contains(oppStageToCheck)) {
            return COMMITTED_STATE_VAL;
        }

        return UNCOMMITTED_STATE_VAL;
    }

    /*******************************************************************************************************
    * @description initializes the Opportunity State Sets, used by other parts of this class, if
    * necessary.  It retrieves them from fields on the NPSP Household Settings Custom Settings object.
    * If the Opportunity Committed Stages, and/or the Opportunity Finalized Stages are not blank, it will
    * convert them to Sets that can be used to determine if the Opportunity Stage is a member of that set.
    ********************************************************************************************************/
    @testVisible private static void initializeStates() {
        if (COMMITTED_STATE_SET == null || FINALIZED_STATE_SET == null) {
            npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

            if (String.isNotBlank(householdSettings.Opportunity_Committed_Stages__c)) {
                COMMITTED_STATE_SET = convertToSet(householdSettings.Opportunity_Committed_Stages__c);
            }

            if (String.isNotBlank(householdSettings.Opportunity_Finalized_Stages__c)) {
                FINALIZED_STATE_SET = convertToSet(householdSettings.Opportunity_Finalized_Stages__c);
            }
        }
    }

    /*******************************************************************************************************
    * @description converts a String value to a set of values (all lowercase), splitting it by using a ; as the default
    * separator.  Leading and Trailing Spaces are trimmed.
    * @param String val
    * @return Set<String> A set of String values
    ********************************************************************************************************/
    @testVisible private static Set<String> convertToSet(String val) {
        return convertToSet(val, DEFAULT_SEPARATOR_VAL, true);
    }

    /*******************************************************************************************************
    * @description converts a String value to a set of values (all lowercase), splitting it by using a String separator
    * value.  If not provided, it uses a ; by default.  Leading and Trailing Spaces are trimmed.
    * @param String val
    * @param String separatorVal a String value used to split the provided String into multiple values
    * @param Boolean forceValuesToLowerCase if true, set values will be converted to lower case as part of process.
    * @return Set<String> A set of String values
    ********************************************************************************************************/
    @testVisible private static Set<String> convertToSet(String val, String separatorVal, Boolean forceValuesToLowerCase) {

        Set<String> vals = new Set<String>();

        String regexForSplit = (String.isNotBlank(separatorVal) ? '\\s*' + separatorVal + '\\s*' : '\\s*' + DEFAULT_SEPARATOR_VAL + '\\s*');

        if (String.isNotBlank(val)) {
            String cvtVal = (forceValuesToLowerCase) ? val.toLowerCase() : val;

            List<String> valStrs = cvtVal.trim().split(regexForSplit);
            vals.addAll(valStrs);
        }

        return vals;
    }

}