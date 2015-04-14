/*
    Copyright (c) 2015, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2015
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Main logic class for opportunity naming
*/

//look at recurring donation naming
//what to do if we have no settings?
//set up default naming convention in install script
public with sharing class OPP_OpportunityNaming implements OPP_INaming {

    private static string chLToken = '{!';
    private static string chRToken = '}';
    private static list<Opportunity_Naming_Settings__c> listOppNamingSettings = Opportunity_Naming_Settings__c.getAll().clone().values();
    private static map<string,Opportunity_Naming_Settings__c> mapOppNameSettings;


    //returns a list of opportunities with new names for the case where the contact roles exists
    public static list<Opportunity> refreshOppNames(list<Opportunity> oppList) {
        
        set<string> allFields = new set<string>();

        if (mapOppNameSettings == null)
            fillOppNameSettings();

        for (Opportunity_Naming_Settings__c ons : listOppNamingSettings)
            allFields.addAll(getFieldNamesFromSpec(ons.Opportunity_Name_Format__c));

        //query for opportunities and associated contacts
        list<Opportunity> oppsForUpdate = database.query(getOppQuery(allFields) + ' WHERE Id IN :oppList');
        list<sObject> oppConRoleQuery = database.query(getConRoleQuery(allFields) + ' WHERE OpportunityId IN :oppList AND IsPrimary = TRUE');
        
        system.debug('lookhere! opps:' + oppsForUpdate + ' conroles: ' + oppConRoleQuery);

        //fill opportunity id to contact map
        map<id,Contact> mapOppIdToCon = new map<id,Contact>();
        for (sObject obj : oppConRoleQuery)
            mapOppIdToCon.put((id)obj.get('opportunityid'),(contact)obj.getsObject('contact'));
        
        //name the opportunities
        for (Opportunity opp : oppsForUpdate) {
            
            //use the naming setting for this opportunity if it exists, otherwise use the default
            Opportunity_Naming_Settings__c ons;
            if (mapOppNameSettings.containsKey(opp.RecordType.Name)) {
                ons = mapOppNameSettings.get(opp.RecordType.Name);
            } else if (mapOppNameSettings.containsKey('')) {
                ons = mapOppNameSettings.get('');
            }
                
            if (ons!=null && !string.isBlank(ons.Opportunity_Name_Format__c))
                opp.Name = replaceFieldNamesWithValues(opp, mapOppIdToCon.get(opp.id), ons);

            if (opp.Name.length() > 120)
                opp.Name = opp.Name.substring(0,120);
        }

        return oppsForUpdate;
    }
    
    //returns a list of opportunities with new names for the case where the contact roles do not exist. Uses Contact Id for Role field.
    public static list<Opportunity> getOppNamesAfterInsert(list<Opportunity> oppList) {
        
        set<string> allFields = new set<string>();
 
        if (mapOppNameSettings == null)
            fillOppNameSettings();

        for (Opportunity_Naming_Settings__c ons : listOppNamingSettings)
            allFields.addAll(getFieldNamesFromSpec(ons.Opportunity_Name_Format__c));

        list<Opportunity> oppsForUpdate = database.query(getOppQuery(allFields) + ' WHERE Id IN :oppList');
        
        set<id> setConId = new set<id>();
        for (Opportunity opp : oppsForUpdate) {
            if (opp.npe01__Contact_Id_for_Role__c != null) {
                setConId.add(opp.npe01__Contact_Id_for_Role__c);
            }
        }

        map<id,Contact> mapCons = new map<id,Contact>();
        if (!setConId.isEmpty()) {
            mapCons = new map<id,Contact>((list<Contact>)database.query(getConQuery(allFields) + ' WHERE Id IN :setConId'));
        }

        for (Opportunity opp : oppsForUpdate) {

            //use the naming setting for this opportunity if it exists, otherwise use the default
            Opportunity_Naming_Settings__c ons;
            if (mapOppNameSettings.containsKey(opp.RecordType.Name)) {
                ons = mapOppNameSettings.get(opp.RecordType.Name);
            } else if (mapOppNameSettings.containsKey('')) {
                ons = mapOppNameSettings.get('');
            }

            if (ons!=null && !string.isBlank(ons.Opportunity_Name_Format__c))
                opp.Name = replaceFieldNamesWithValues(opp, mapCons.get(opp.npe01__Contact_Id_for_Role__c), ons);
            
            if (opp.Name.length() > 120)
                opp.Name = opp.Name.substring(0,120);

        }

        return oppsForUpdate;
    }

    public static void fillOppNameSettings() {
        mapOppNameSettings = new map<string,Opportunity_Naming_Settings__c>();
        for (Opportunity_Naming_Settings__c ons : Opportunity_Naming_Settings__c.getAll().clone().values()) {
            if (string.isBlank(ons.Opportunity_Record_Types__c)) {
                mapOppNameSettings.put('',ons);
            } else for (string recTypeName : ons.Opportunity_Record_Types__c.split(';',0)) {
                mapOppNameSettings.put(recTypeName,ons);
            }
        }
    }

    public static set<string> getOppFields(set<string> fields) {
        set<string> result = new set<string>();
        for (string field : fields) {
            if (!field.startsWithIgnoreCase('contact'))
                result.add(field);
        }
        return result;
    }

    public static set<string> getConFields(set<string> fields) {
        set<string> result = new set<string>();
        for (string field : fields) {
            if (field.startsWithIgnoreCase('contact'))
                result.add(field);
        }
        return result;
    }

    public static string getOppQuery(set<string> fields) {
        fields.addAll(new set<string>{'id','name','recordtypeid', 'recordtype.name','npe01__contact_id_for_role__c'});
        string result = 'SELECT ';
        for (string field : getOppFields(fields)) {
            result += field + ', ';
        }
        result = result.substring(0, result.length()-2) + ' FROM Opportunity';
        return result;
    }

    public static string getConQuery(set<string> fields) {
        fields.add('contact.id');
        string result = 'SELECT ';
        for (string field : getConFields(fields)) {
            result += field.substring(field.indexOf('.')+1) + ', ';
        }

        result = result.substring(0, result.length()-2) + ' FROM Contact';
        return result;
    }

    public static string getConRoleQuery(set<string> fields) {
        fields.add('contact.id');
        string result = 'SELECT opportunityid, ';
        for (string field : getConFields(fields)) {
            result += field + ', ';
        }
        result = result.substring(0, result.length()-2) + ' FROM OpportunityContactRole';
        return result;
    }

    public static set<string> getFieldNamesFromSpec(string spec) {
        set<string> setStrField = new set<string>();
        
        // First, instantiate a new Pattern object looking for {!...}
        Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');       
        //Pattern MyPattern = Pattern.compile('\\{!*\\}');       
        // Then instantiate a new Matcher object 
        Matcher MyMatcher = MyPattern.matcher(spec);
        
        while (MyMatcher.find()) {
            // get the fieldname without the {}'s
            string strField = spec.substring(MyMatcher.start() + chLToken.length(), MyMatcher.end()-chRToken.length());
            setStrField.add(strField.trim().toLowerCase());
        }
        return setStrField;
    }

    public static string replaceFieldNamesWithValues(Opportunity opp, Contact con, Opportunity_Naming_Settings__c ons) {
        string result = ons.Opportunity_Name_Format__c;
        
        //First, instantiate a new Pattern object looking for {!...} without any nested {'s.
        Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');       
        //Pattern MyPattern = Pattern.compile('\\{!*\\}');       
        //Then instantiate a new Matcher object 
        Matcher MyMatcher = MyPattern.matcher(ons.Opportunity_Name_Format__c);
        
        while (MyMatcher.find()) {
            //get the fieldname without the {! }
            string strField = ons.Opportunity_Name_Format__c.substring(MyMatcher.start() + chLToken.length(), MyMatcher.end()-chRToken.length());
            
            //separate cross object references, i.e. account.name
            list<string> splitField = (strField.split('\\.',0));
            
            //remove the field name itself to only include parent object references
            string fieldName = splitField[splitField.size()-1];
            splitField.remove(splitField.size()-1);

            //use the correct sObject
            sObject thisObj;
            if (!splitField.isEmpty() && splitField[0].equalsIgnoreCase('contact')) {
                thisObj = con;
                splitField.remove(0);
            } else {
                thisObj = opp;
            }

            //traverse parent relationships until the last one
            if (thisObj!=null) {
                for (string parentObj : splitField) {
                    thisObj = thisObj.getsObject(parentObj);
                }
            }

            //if this field is a date or datetime field, follow the format supplied in the settings
            string val = getFieldValue(thisObj, fieldName, ons);

            // add back the {}'s for string substitution
            strField = chLToken + strField + chRToken;
            if (val == null) {   
                // eat potential trailing space
                result = result.replace(strField + ' ', '');
                // eat potential leading space
                result = result.replace(' ' + strField, '');
            }
            result = result.replace(strField, val == null ? '' : val);
        }
        return result;
    }

    //Returns the value of a field as a string, while respecting the date format specified in settings
    public static string getFieldValue(sObject obj, string fieldName, Opportunity_Naming_Settings__c ons) {
        if (obj==null) return null;
        Schema.DisplayType dt = UTIL_Describe.getFieldDisplaytype(obj.getSObjectType().getDescribe().getName(),fieldName);
        string result = '';

        //If this is a Date or DateTime field, use the specified formatting if there is one
        if (dt == Schema.DisplayType.Date || dt == Schema.DisplayType.DateTime) {
            DateTime d = (DateTime) obj.get(fieldName.trim());
            string dateFormat = String.isBlank(ons.Date_Format__c) ? 'yyyy.MM.dd' : ons.Date_Format__c;
            
            //if this was a date, use the GMT time zone so we don't end up on a different date
            if (dt == Schema.DisplayType.Date) {
                result = d.formatGmt(dateFormat);
            } else {
                result = d.format(dateFormat);
            }
        } else {
            result = (String) obj.get(fieldName.trim());
        }

        return result;
    }

}