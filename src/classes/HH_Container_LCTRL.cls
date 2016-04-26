/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Households
* @group-content ../../ApexDocContent/Households.htm
* @description Lightning Component Server Controller for the Manage Household UI page
*/
public class HH_Container_LCTRL {
    
    /*******************************************************************************************************
    * @description returns the Household object (Account or Custom Object) given the Id
    * @param hhId The Household's Id
    * @return SObject The Household Account or Custom Object
    */
    @AuraEnabled
    public static SObject getHH(ID hhId) {
        if (hhId == null)
            return null;
        if (UTIL_Describe.isObjectIdThisType(hhId, 'Account'))
	        return [select Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c
                    from Account where Id = :hhId];
        else
	        return [select Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c 
                    from npo02__Household__c where Id = :hhId];
    }	
    
    /*******************************************************************************************************
    * @description returns the Contacts for the given Household
    * @param hhId The Household's Id
    * @return list<Contact> The Contacts in the Household
    */
    @AuraEnabled
    public static list<Contact> getContacts(ID hhId) {
        if (hhId == null)
            return null;
        
        string strSoql = conSelect;
        
        // don't use contact.HHId in one soql since it can't use an index
        // and won't work in LDV orgs.
        if (UTIL_Describe.isObjectIdThisType(hhId, 'Account'))
            strSoql += ' where AccountId = :hhId ';
        else
            strSoql += ' where npo02__Household__c = :hhId ';
        
        strSoql += ' order by npo02__Household_Naming_Order__c, CreatedDate';
        
        return database.query(strSoql);
    }
    
    /*******************************************************************************************************
    * @description returns the soql string to use to query contacts and their appropriate fields
    * @return String The soql select string to use for Contacts
    */
    private static string conSelect {
        get {
            if (conSelect == null) {
                //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
                string strSoql = 'SELECT Id, npo02__Household_Naming_Order__c, FirstName, LastName, Salutation, Name, ' +
                    'npo02__Naming_Exclusions__c, npo02__Household__c, AccountId, HHId__c, ' + 
                    'Exclude_from_Household_Name__c, Exclude_from_Household_Formal_Greeting__c, Exclude_from_Household_Informal_Greeting__c, ' +
                    'is_Address_Override__c, Current_Address__c, ' + 
                    'MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, CreatedDate ';
                
                set<string> setStrField = HH_HouseholdNaming.iNaming.setHouseholdNameFieldsOnContact();
                for (string strF : setStrField) {
                	if (!strSoql.contains(' ' + strF))
                        strSoql += ', ' + strF;
                }  
                                
                strSoql += ' FROM Contact ';
                conSelect = strSoql;
            }
            return conSelect;
        }
        set;        
    }    
    
    
    /*******************************************************************************************************
    * @description saves any changes to the Contacts in the database
    * @param listCon The list of Contacts to save
    * @return void
    */
    @AuraEnabled
    public static void updateContacts(list<Contact> listCon) {
        try {
	        update listCon;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /*******************************************************************************************************
    * @description deletes the Contacts in the database
    * @param listCon The list of Contacts to delete
    * @return void
    */
    @AuraEnabled
    public static void deleteContacts(list<Contact> listCon) {
        try {
	        delete listCon;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /*******************************************************************************************************
    * @description saves any changes to the Household in the database
    * @param hh The Household
    * @return void
    */
    @AuraEnabled
    public static void updateHousehold(SObject hh) {
        try {

            // we've already saved the data for the contacts in the household.
            // now we only need to save the account fields an update, and we don't want
            // any of the normal account trigger work to run again.  specifically,
            // we may have updated the names and greetings, because the contacts have changed,
            // but the user still may want auto-naming turned on.  our normal trigger flow
            // would think the user updated the name from what it was, and thus it should be
            // excluded from auto-naming!
            HH_ProcessControl.inFutureContext = true;
            
            update hh;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /*******************************************************************************************************
    * @description sets the Household Name and Greetings on the Household object, given the list of Contacts
	* @param hh The Household Object (Account or Custom Object) to set the names on
	* @param listCon The list of Contacts to use
	* @return SObject the Household object
	*/
	@AuraEnabled
    public static SObject getHHNamesGreetings(SObject hh, list<Contact> listCon) {
        
        // update naming exclusions field based on exclusion checkboxes
        for (Contact con : listCon)
            HH_Households_TDTM.copyNamingExclusionsFromCheckboxes(con);
        
        HH_HouseholdNaming hn = new HH_HouseholdNaming();
        String strExclusions = (String)hh.get('npo02__SYSTEM_CUSTOM_NAMING__c');
        if (strExclusions == null)
            strExclusions = '';
        if (!strExclusions.contains('Name'))
	        hh.put('Name', hn.getHHName(listCon));
        if (!strExclusions.contains('Formal_Greeting__c'))
	        hh.put('npo02__Formal_Greeting__c', hn.getFormalName(listCon));
        if (!strExclusions.contains('Informal_Greeting__c'))
    	    hh.put('npo02__Informal_Greeting__c', hn.getInformalName(listCon));
        return hh;
    }
    
}