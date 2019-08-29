/*
    Copyright (c) 2019 Salesforce.org
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
* @group Recurring Donations
* @description Recurring Donations API
*
*/
public with sharing class RD2_InterfaceApi {

    public interface Settings {
        Boolean isAutomaticNamingEnabled();
    }

    public interface NamingService {
        void autogenerateNames(List<npe03__Recurring_Donation__c> rds);
        void autogenerateNamesOnChange(Map<Id, npe03__Recurring_Donation__c> rdById, Map<Id, npe03__Recurring_Donation__c> oldRdById);
    }

    public interface DonorGateway {
        Map<Id, Donor> getDonors(List<npe03__Recurring_Donation__c> rds);
    }

    /***
    * @description 
    */
    public class Donor {
        public Id recordId;
        public String name;

        public Donor(Id recordId, String name) {
            this.recordId = recordId;
            this.name = name;
        }

        public Donor(Id recordId, String firstName, String lastName) {
            this.recordId = recordId;
            this.name = (String.isBlank(firstName) ? '' : firstName + ' ') + lastName;
            this.name.trim();
        }
    }

}