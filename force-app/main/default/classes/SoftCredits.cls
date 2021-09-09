/*
    Copyright (c) 2021 Salesforce.org
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
* @description Aggregate class for soft credits.
*/
public inherited sharing class SoftCredits {

    private List<OpportunityContactRole> opportunityContactRoles =
        new List<OpportunityContactRole>();

    public SoftCredits(List<OpportunityContactRole> opportunityContactRoles) {
        this.opportunityContactRoles = deduplicate(opportunityContactRoles);
    }

    public List<OpportunityContactRole> all() {
        return opportunityContactRoles;
    }

    public Integer size() {
        return opportunityContactRoles.size();
    }

    public void add(OpportunityContactRole opportunityContactRole) {
        addAll(new List<OpportunityContactRole> { opportunityContactRole });
    }

    public void addAll(List<OpportunityContactRole> moreOpportunityContacRoles) {
        this.opportunityContactRoles = deduplicate(moreOpportunityContacRoles);
    }

    public List<OpportunityContactRole> unprocessed() {
        List<OpportunityContactRole> unprocessed = new List<OpportunityContactRole>();
        for (OpportunityContactRole ocr : this.opportunityContactRoles) {
            if (ocr.id == null) {
                unprocessed.add(ocr);
            }
        }
        return unprocessed;
    }

    private List<OpportunityContactRole> deduplicate(List<OpportunityContactRole> moreOpportunityContactRoles) {
        List<OpportunityContactRole> allOpportunityContactRoles = new List<OpportunityContactRole>();
        allOpportunityContactRoles.addAll(opportunityContactRoles);
        allOpportunityContactRoles.addAll(moreOpportunityContactRoles);

        Map<Integer, OpportunityContactRole> softCreditByContactRoleHashCode =
            new Map<Integer, OpportunityContactRole>();

        for (OpportunityContactRole ocr : allOpportunityContactRoles) {
            SoftCredit softCredit = new SoftCredit(ocr);

            Integer contactRoleHashCode = softCredit.contactRoleHashCode();
            OpportunityContactRole ocrInMap = softCreditByContactRoleHashCode.get(contactRoleHashCode);
            Boolean shouldAddToMap = ocrInMap == null;
            Boolean shouldReplaceInMap = ocrInMap != null && ocrInMap.Id == null;

            if (shouldAddToMap || shouldReplaceInMap) {
                softCreditByContactRoleHashCode.put(contactRoleHashCode, ocr);
            }
        }

        return softCreditByContactRoleHashCode.values();
    }
}
