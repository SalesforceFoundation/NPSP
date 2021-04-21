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
* @group Donations
* @description Holds behavior for Donations.
*/
public inherited sharing class Donation {

    public Id recordId;
    private DonationSelector selector;
    private Opportunity donationOpp;

    public Donation(Id recordId) {
        this.recordId = recordId; 
    }

    public Donation(DonationSelector selector) {
        this.selector = selector; 
    }

    public Donation(Id recordId, DonationSelector selector) {
        this.recordId = recordId; 
        this.selector = selector; 
    }

    public void query() {
        Opportunity donationOpp;
        if(recordId != null && selector != null) {
            List<Opportunity> opps = selector.selectOpportunitiesById(new Set<Id> { recordId });
            if(opps.size() > 0) {
                donationOpp = opps[0];
            }
        }
        this.donationOpp = donationOpp;
    }

    public List<Donor> getHardCreditDonors() {
        List<Donor> hcDonors = new List<Donor>();
        if(donationOpp == null) {
            return hcDonors;
        }

        Boolean hasOrgAccount = false;
        if(donationOpp?.Account != null) {
            Donor acctDonor = new Donor();
            acctDonor.isHardCredit = true;
            acctDonor.amount = donationOpp.Amount;
            acctDonor.fullName = donationOpp.Account?.Name;
            if(donationOpp.Account.RecordType.Name.indexOf('Household') > -1) {
                acctDonor.donorType = Donor.DonorType.HOUSEHOLD.name();
            } else {
                acctDonor.donorType = Donor.DonorType.ORGANIZATION.name();
                hasOrgAccount = true;
            }
            hcDonors.add( acctDonor );
        }
        if(!hasOrgAccount && donationOpp?.Primary_Contact__c != null) {
            Donor contactDonor = new Donor();
            contactDonor.isHardCredit = true;
            contactDonor.amount = donationOpp.Amount;
            contactDonor.fullName = donationOpp.Account?.Name;
            contactDonor.fullName = donationOpp.Primary_Contact__r?.FirstName + ' ' +
                donationOpp.Primary_Contact__r?.LastName;
                contactDonor.donorType = Donor.DonorType.CONTACT.name();
            hcDonors.add( contactDonor );
        }

        return hcDonors;
    }

}