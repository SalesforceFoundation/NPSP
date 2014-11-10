/*
Copyright (c) 2014 salesforce.com foundation, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com foundation. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
/**
* @author Salesforce Foundation
* @date 01/13/2014
* @description Settings Service class
*/

public with sharing class STG_SettingsService {
    
    public static STG_SettingsService stgService = new STG_SettingsService();
    
    public STG_SettingsService() {
    	//UTIL_Debug.debug('***** STG_SettingsService constructor');
    }
    
    public npe01__Contacts_And_Orgs_Settings__c stgCon {
        get {
            if (stgCon == null) stgCon = UTIL_CustomSettingsFacade.getOrgContactsSettings();
            return stgCon;
        }
        private set;
    }
    
    public npo02__Households_Settings__c stgHH {
        get {
            if (stgHH == null) stgHH = UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();
            return stgHH;
        }
        private set;
    }
    
    public Household_Naming_Settings__c stgHN {
        get {
            if (stgHN == null) stgHN = UTIL_CustomSettingsFacade.getOrgHouseholdNamingSettings();
            return stgHN;
        }
        private set;
    }

    public npe03__Recurring_Donations_Settings__c stgRD {
        get {
            if (stgRD == null) stgRD = UTIL_CustomSettingsFacade.getOrgRecurringDonationsSettings();
            return stgRD;
        }
        private set;
    }
    
    public npe4__Relationship_Settings__c stgRel {
        get {
            if (stgRel == null) stgRel = UTIL_CustomSettingsFacade.getOrgRelationshipSettings();
            return stgRel;
        }
        private set;
    }
    
    public npe5__Affiliations_Settings__c stgAffl {
        get {
            if (stgAffl == null) stgAffl = UTIL_CustomSettingsFacade.getOrgAffiliationsSettings();
            return stgAffl;
        }
        private set;
    }
    
    public Error_Settings__c stgErr {
        get {
            if (stgErr == null) stgErr = UTIL_CustomSettingsFacade.getOrgErrorSettings();
            return stgErr;
        }
        private set;
    }
    
    public Batch_Data_Entry_Settings__c stgBDE {
        get {
            if (stgBDE == null) stgBDE = UTIL_CustomSettingsFacade.getOrgBDESettings();
            return stgBDE;
        }
        private set;
    }
    
    public Allocations_Settings__c stgAllo {
        get {
            if (stgAllo == null) stgAllo = UTIL_CustomSettingsFacade.getOrgAllocationsSettings();
            return stgAllo;
        }
        private set;
    }

    public map<string, npe03__Custom_Field_Mapping__c> mapRDCustomField {
    	get {
    		if (mapRDCustomField == null) {
			    mapRDCustomField = new map<string, npe03__Custom_Field_Mapping__c>();
			    mapRDCustomField = npe03__Custom_Field_Mapping__c.getAll();
    		} 
            return mapRDCustomField;    	   
    	}
    	public set;
    }
    
    public list<npe03__Custom_Installment_Settings__c> listRDCustomInstallment {
        get {
            if (listRDCustomInstallment == null) {
                listRDCustomInstallment = new list<npe03__Custom_Installment_Settings__c>();
                listRDCustomInstallment = npe03__Custom_Installment_Settings__c.getAll().values();
            } 
            return listRDCustomInstallment;           
        }
        public set;     
    }

    public list<npe03__Custom_Field_Mapping__c> listRDCustomFieldMapping {
        get {
            if (listRDCustomFieldMapping == null) {
                listRDCustomFieldMapping = new list<npe03__Custom_Field_Mapping__c>();
                listRDCustomFieldMapping = npe03__Custom_Field_Mapping__c.getAll().values();
            } 
            return listRDCustomFieldMapping;           
        }
        public set;     
    }

    public list<npe01__Payment_Field_Mapping_Settings__c> listPMTFieldMapping {
        get {
            if (listPMTFieldMapping == null) {
                listPMTFieldMapping = new list<npe01__Payment_Field_Mapping_Settings__c>();
                listPMTFieldMapping = npe01__Payment_Field_Mapping_Settings__c.getAll().values();
            } 
            return listPMTFieldMapping;           
        }
        public set;    	
    } 
    
    public void saveAll() {
        upsert stgCon;
        upsert stgHH;
        upsert stgHN;
        upsert stgRD;
        upsert stgRel;
        upsert stgAffl;
        upsert stgBDE;
        upsert stgErr;
        system.debug('lookhere: stgallo: ' + stgAllo);
        upsert stgAllo;
    }
}