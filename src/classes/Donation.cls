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

    private Boolean alwaysRollupToPrimaryContactRole = false;
    
    private Set<String> softCreditRoles = new Set<String> {
        'Matched Donor',
        'Soft Credit',
        'Household Member'
    };

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
        if (recordId != null && selector != null) {
            List<Opportunity> opps = selector.selectOpportunitiesById(new Set<Id> { recordId });
            if (opps.size() > 0) {
                donationOpp = opps[0];
            }
        }
        this.donationOpp = donationOpp;

        // populate info from settings
        npo02__Households_Settings__c householdsSettings = npo02__Households_Settings__c.getInstance();
        alwaysRollupToPrimaryContactRole = householdsSettings.npo02__Always_Rollup_to_Primary_Contact__c;

        String scRolesSetting = householdsSettings.npo02__Soft_Credit_Roles__c;
        softCreditRoles = new Set<String>(scRolesSetting.split(';'));

    }

    public List<Donor> getHardCreditDonors() {
        List<Donor> hcDonors = new List<Donor>();
        if (donationOpp == null) {
            return hcDonors;
        }

        Boolean hasOrgAccount = false;
        if (donationOpp?.Account != null) {
            Donor acctDonor = new Donor();
            acctDonor.isHardCredit = true;
            acctDonor.recordId = donationOpp?.AccountId;
            acctDonor.amount = donationOpp.Amount;
            acctDonor.fullName = donationOpp.Account?.Name;
            if(donationOpp.Account.npe01__SYSTEM_AccountType__c != null &&
                donationOpp.Account.npe01__SYSTEM_AccountType__c.indexOf('Household') > -1) {
                acctDonor.donorType = Donor.DonorType.HOUSEHOLD.name();
            } else {
                acctDonor.donorType = Donor.DonorType.ORGANIZATION.name();
                hasOrgAccount = true;
            }
            hcDonors.add( acctDonor );
        }

        if ((!hasOrgAccount || alwaysRollupToPrimaryContactRole)
            && donationOpp.OpportunityContactRoles != null) {

            for (OpportunityContactRole contactRole: donationOpp.OpportunityContactRoles) {
                if (contactRole.IsPrimary) {
                    Donor contactDonor = new Donor();
                    contactDonor.isHardCredit = true;
                    contactDonor.amount = donationOpp.Amount;
                    contactDonor.fullName = contactRole.Contact.FirstName +' '+
                        contactRole.Contact.LastName;
                    contactDonor.role = contactRole.Role;
                    contactDonor.donorType = Donor.DonorType.CONTACT.name();
                    contactDonor.recordId = contactRole.ContactId;
                    
                    hcDonors.add(contactDonor);
                    break;
                }
            }
        }

        return hcDonors;
    }

    public List<Donor> getSoftCreditDonors() {
        List<Donor> scDonors = new List<Donor>();

        if(donationOpp == null) {
            return scDonors;
        }

        List<Donor> hcDonors = getHardCreditDonors();
        Set<Id> hcRecordIds = new Set<Id>();
        for (Donor hardCreditDonor: hcDonors) {
            if (hardCreditDonor.recordId != null) {
                hcRecordIds.add(hardCreditDonor.recordId);
            }
        }

        if (donationOpp.OpportunityContactRoles != null) {
            for (OpportunityContactRole contactRole: donationOpp.OpportunityContactRoles) {
                if (!hcRecordIds.contains(contactRole.ContactId) && 
                    softCreditRoles.contains(contactRole.Role)) {

                    Donor ocrDonor = new Donor();
                    ocrDonor.isHardCredit = false;
                    ocrDonor.amount = donationOpp.Amount;
                    ocrDonor.fullName = contactRole.Contact.FirstName +' '+
                        contactRole.Contact.LastName;
                    ocrDonor.role = contactRole.Role;
                    ocrDonor.donorType = Donor.DonorType.CONTACT.name();
                    ocrDonor.recordId = contactRole.ContactId;
                    
                    scDonors.add(ocrDonor);
                }
            }
        }

        if (donationOpp.Partial_Soft_Credits__r != null) {
            for (Partial_Soft_Credit__c partialSoftCredit: donationOpp.Partial_Soft_Credits__r) {
                
                Donor pscDonor = new Donor();
                pscDonor.isHardCredit = false;
                pscDonor.amount = partialSoftCredit.Amount__c;
                pscDonor.fullName = partialSoftCredit.Contact_Name__c;
                pscDonor.role = partialSoftCredit.Role_Name__c;
                pscDonor.donorType = Donor.DonorType.CONTACT.name();
                pscDonor.recordId = partialSoftCredit.Contact__c;
                
                scDonors.add(pscDonor);
            }
        }        

        if (donationOpp.Account_Soft_Credits__r != null) {
            for (Account_Soft_Credit__c accountSoftCredit: donationOpp.Account_Soft_Credits__r) {
                Donor ascDonor = new Donor();
                ascDonor.isHardCredit = false;
                ascDonor.amount = accountSoftCredit.Amount__c;
                ascDonor.fullName = accountSoftCredit.Account__r.Name;
                ascDonor.role = accountSoftCredit.Role__c;
                if (accountSoftCredit.Account__r.npe01__SYSTEM_AccountType__c != null &&
                    accountSoftCredit.Account__r.npe01__SYSTEM_AccountType__c.indexOf('Household') > -1) {
                    ascDonor.donorType = Donor.DonorType.HOUSEHOLD.name();    
                } else {
                    ascDonor.donorType = Donor.DonorType.ORGANIZATION.name();
                }
                ascDonor.recordId = accountSoftCredit.Account__c;
                
                scDonors.add(ascDonor);
            }
        }
        return scDonors;
    }

}