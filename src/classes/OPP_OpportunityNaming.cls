/*
    Copyright (c) 2015, Salesforce.org
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
* @date 2015
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Main logic class for opportunity naming
*/
//TODO: finish implementation of interface so other implementing classes can be used. this will require making classes global and a heirarchical setting that we don't yet have. TBD if this is necessary.
public inherited sharing class OPP_OpportunityNaming implements OPP_INaming {

    private static final SObjectType recordTypeSObjectType = UTIL_Describe.getSObjectType('RecordType');

    /*********************************************************************************************************
    * @description Left token for field names in Opportunity Naming Settings spec.
    */
    private static String chLToken = '{!';
    /*********************************************************************************************************
    * @description Rigjt token for field names in Opportunity Naming Settings spec.
    */
    private static String chRToken = '}';
    /*********************************************************************************************************
    * @description A list of all Opportunity Naming Settings.
    */
    private static List<Opportunity_Naming_Settings__c> listOppNamingSettings;
    /*********************************************************************************************************
    * @description A map to match opportunity record type and attribution info to the appropriate setting.
    */
    private static Map<String,Opportunity_Naming_Settings__c> mapOppIdSettings;

    /*******************************************************************************************************
    * @description Calculates opportunity names based on Opportunity Naming Settings using the primary Contact
    * Role for contact fields.
    * @param oppList The list of Opportunities to rename.
    * @return List<Opportunity> The original Opportunity list with updated names.
    ********************************************************************************************************/
    public static void refreshOppNames(List<Opportunity> oppList) {

        Set<String> allFields = new Set<String>();

        fillOppNameSettings();

        if (listOppNamingSettings.isEmpty()) {
            return;
        }

        for (Opportunity_Naming_Settings__c ons : listOppNamingSettings) {
            allFields.addAll(getFieldNamesFromSpec(ons.Opportunity_Name_Format__c));
        }

        //query for opportunities and associated contacts
        Map<Id,Opportunity> mapOppsQuery = new Map<Id,Opportunity>(
            (List<Opportunity>)Database.query(getOppQuery(allFields)+' WHERE Id IN :oppList')
        );

        //fill opportunity id to contact map
        Map<Id,Contact> mapOppIdToCon = fillConMap(mapOppsQuery.values());

        //name the opportunities
        for (Opportunity opp : oppList) {

            //use the naming setting for this opportunity if it exists, otherwise use the default
            Opportunity queryOpp = mapOppsQuery.get(opp.id);
            Contact con = mapOppIdToCon.get(opp.id);
            Opportunity_Naming_Settings__c ons = getONS(queryOpp);
            if (ons!=null && !string.isBlank(ons.Opportunity_Name_Format__c)) {
                opp.Name = replaceFieldNamesWithValues(queryOpp, con, ons);

                if (opp.Name.length() > 120) {
                    opp.Name = opp.Name.substring(0,120);
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Calculates opportunity names based on Opportunity Naming Settings using the primary
    * Contact Id for Role field for contact fields.
    * @param oppList The list of Opportunities to rename.
    * @return List<Opportunity> A new list of renamed opportunities. The new list comes from an Opportunity
    * query and can be updated in an after opportunity insert trigger context.
    ********************************************************************************************************/
    public static List<Opportunity> getOppNamesAfterInsert(List<Opportunity> oppList) {

        Set<String> allFields = new Set<String>();
        List<Opportunity> oppsForUpdate = new List<Opportunity>();

        fillOppNameSettings();

        if (listOppNamingSettings.isEmpty()) {
            return new List<Opportunity>();
        }

        for (Opportunity_Naming_Settings__c ons : listOppNamingSettings) {
            allFields.addAll(getFieldNamesFromSpec(ons.Opportunity_Name_Format__c));
        }

        //query for opportunities and associated contacts
        Map<Id,Opportunity> mapOppsQuery = new Map<Id,Opportunity>(
            (List<Opportunity>) database.query(getOppQuery(allFields)+' WHERE Id IN :oppList')
        );

        //fill opportunity id to contact map
        Map<Id,Contact> mapOppIdToCon = fillConMap(mapOppsQuery.values());

        for (Opportunity opp : oppList) {
            //use the query object as we're in an after insert trigger and can't edit the current trigger set
            Opportunity queryOpp = mapOppsQuery.get(opp.id);
            Contact con = mapOppIdToCon.get(opp.id);
            Opportunity_Naming_Settings__c ons = getONS(queryOpp);

            if (ons!=null && !string.isBlank(ons.Opportunity_Name_Format__c)) {
                queryOpp.Name = replaceFieldNamesWithValues(queryOpp, con, ons);

                if (queryOpp.Name.length() > 120) {
                    queryOpp.Name = queryOpp.Name.substring(0,120);
                }
                oppsForUpdate.add(queryOpp);
            }
        }

        return oppsForUpdate;
    }

    /*******************************************************************************************************
    * @description Mathes the current opportunity to the appropriate opp naming setting.
    * @param opp The opportunity to find the setting for.
    * @return Opportunity_Naming_Settings__c The opp name setting for this Opportunity if it exists.
    ********************************************************************************************************/
    public static Opportunity_Naming_Settings__c getONS(Opportunity opp) {
        if (mapOppIdSettings.containsKey(getOppAttribution(opp) + opp.RecordTypeId)) {

            return mapOppIdSettings.get(getOppAttribution(opp) + opp.RecordTypeId);

        } else if (mapOppIdSettings.containsKey(getOppAttribution(opp))) {

            return mapOppIdSettings.get(getOppAttribution(opp));

        }
        return null;
    }

    /*******************************************************************************************************
    * @description Attempts to apply naming and date formats to a random opportunity in order to validate
    * user entered opportunity name settings.
    ********************************************************************************************************/
    public static void validateSetting(Opportunity_Naming_Settings__c ons) {

        Set<String> allFields = getFieldNamesFromSpec(ons.Opportunity_Name_Format__c);

        Opportunity testOpp = new Opportunity();
        Contact testCon = new Contact();

        String s = replaceFieldNamesWithValues(testOpp, testCon, ons);

        s = system.now().format(ons.Date_Format__c);
    }

    /*******************************************************************************************************
    * @description Fills the mapOppIdSettings map with record type and attribution info and all settings.
    ********************************************************************************************************/
    public static void fillOppNameSettings() {
        listOppNamingSettings = UTIL_ListCustomSettingsFacade.getMapOppNamingSettings().clone().values();
        mapOppIdSettings = new Map<String,Opportunity_Naming_Settings__c>();

        for (Opportunity_Naming_Settings__c ons : listOppNamingSettings) {

            List<String> oppRecTypeStrings = string.isBlank(ons.Opportunity_Record_Types__c) 
                ? new List<String>() 
                : ons.Opportunity_Record_Types__c.split(';', 0);

            List<Id> oppRecTypeIds = new List<Id>();
            for (String recTypeString : oppRecTypeStrings) {
                if (!String.isBlank(recTypeString)) {
                    try {
                        oppRecTypeIds.add((id)recTypeString);
                    } catch (Exception e) {}
                }
            }

            STG_PanelOppNaming_CTRL.AttributionSettings attributionSettings = new STG_PanelOppNaming_CTRL.AttributionSettings()
                .withSelected(ons.Attribution__c);

            if (oppRecTypeIds.isEmpty()) {
                mapOppIdSettings.put('', ons);
                if (attributionSettings.isBoth()) {
                    mapOppIdSettings.put(Label.oppNamingIndividual,ons);
                    mapOppIdSettings.put(Label.oppNamingOrganizational,ons);
                } else {
                    mapOppIdSettings.put(attributionSettings.selectedLabel, ons);
                }

            } else {

                for (Id recTypeId : oppRecTypeIds) {
                    mapOppIdSettings.put(recTypeId,ons);
                    if (attributionSettings.isBoth()) {
                        mapOppIdSettings.put(Label.oppNamingIndividual+recTypeId,ons);
                        mapOppIdSettings.put(Label.oppNamingOrganizational+recTypeId,ons);
                    } else {
                        mapOppIdSettings.put(attributionSettings.selectedLabel+recTypeId, ons);
                    }
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Finds an opportunity's attribution based on Account.npe01__SYSTEMIsIndividual__c
    * @param opp The opportunity.
    * @return String Individual or Organizational, based on the opportunity's attribution.
    ********************************************************************************************************/
    public static String getOppAttribution(Opportunity opp) {
        if (opp.Account == null || opp.Account.npe01__SYSTEMIsIndividual__c) {
            return Label.oppNamingIndividual;
        } else {
            return Label.oppNamingOrganizational;
        }
    }

    /*******************************************************************************************************
    * @description Returns all non-contact fields from a set of field names.
    * @param fields A set of strings of all fields from an opportunity naming spec.
    * @return Set<String> Only those fields not attributed to a contact.
    ********************************************************************************************************/
    public static Set<String> getOppFields(Set<String> fields) {
        Set<String> result = new Set<String>();
        for (String field : fields) {
            if (!field.startsWithIgnoreCase('contact')) {
                result.add(field);
            }
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Returns all contact fields from a set of field names.
    * @param fields A set of strings of all fields from an opportunity naming spec.
    * @return Set<String> Only those fields attributed to a contact.
    ********************************************************************************************************/
    public static Set<String> getConFields(Set<String> fields) {
        Set<String> result = new Set<String>();
        for (String field : fields) {
            if (field.startsWithIgnoreCase('contact')) {
                result.add(field);
            }
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Constructs a query for Opportunities with all fields from all naming specs. Also includes
    * various fields needed for later calculations.
    * @param fields A set of strings of all fields from an opportunity naming spec.
    * @return String An opportunity query string.
    ********************************************************************************************************/
    public static String getOppQuery(Set<String> fields) {
        fields.addAll(new Set<String>{
            'id',
            'name',
            'recordtypeid', 
            'tolabel(recordtype.name) RecordTypeLabel', 
            'account.npe01__systemisindividual__c'
        });

        String result = 'SELECT ';
        for (String field : getOppFields(fields)) {
            result += field + ', ';
        }
        if (UTIL_Currency.getInstance().isMultiCurrencyOrganization() && !result.containsIgnoreCase('currencyisocode')) {
            result += ' CurrencyIsoCode, ';
        }

        result += '(' + getConRoleQuery(fields) + ' WHERE IsPrimary=TRUE LIMIT 1) ';
        result += 'FROM Opportunity';

        return result;
    }

    /*******************************************************************************************************
    * @description Constructs a query for Contacts with all contact fields from all naming specs. Also
    * includes various fields needed for later calculations.
    * @param fields A set of strings of all fields from an opportunity naming spec.
    * @return String A contact query string.
    ********************************************************************************************************/
    public static String getConQuery(Set<String> fields) {
        fields.add('contact.id');

        String result = 'SELECT ';
        for (String field : getConFields(fields)) {
            result += field.substring(field.indexOf('.')+1) + ', ';
        }
        if (UTIL_Currency.getInstance().isMultiCurrencyOrganization() && !result.containsIgnoreCase('currencyisocode')) {
            result += ' CurrencyIsoCode, ';
        }

        result = result.substring(0, result.length()-2) + ' FROM Contact';

        return result;
    }

    /*******************************************************************************************************
    * @description Constructs a query for OpportunityContactRole with all contact fields from all naming specs. Also includes
    * various fields needed for later calculations.
    * @param fields A set of strings of all fields from an opportunity naming spec.
    * @return String An opportunity contact role query string.
    ********************************************************************************************************/
    public static String getConRoleQuery(Set<String> fields) {
        fields.add('contact.id');
        String result = 'SELECT opportunityId, ';
        for (String field : getConFields(fields)) {
            result += field + ', ';
        }
        result = result.substring(0, result.length()-2) + ' FROM OpportunityContactRoles';
        return result;
    }

    /*******************************************************************************************************
    * @description For an opportunity query with a primary  opportunitycontactrole subquery, splits out the
    * contact object and puts it in a map.
    * @param fields A set of strings of all fields from an opportunity naming spec.
    * @return String A map from Opportunity
    ********************************************************************************************************/
    public static Map<Id,Contact> fillConMap (List<Opportunity> opps) {
        Map<Id,Contact> mapOppIdToCon = new Map<Id,Contact>();
        for (sObject obj : opps) {
            if (obj.getSObjects('OpportunityContactRoles')!=null) {
                OpportunityContactRole primaryOCR = (OpportunityContactRole) obj.getSObjects('OpportunityContactRoles')[0];
                mapOppIdToCon.put((id)primaryOCR.get('opportunityid'),(contact)primaryOCR.getsObject('contact'));
            }
        }
        return mapOppIdToCon;
    }

    /*******************************************************************************************************
    * @description Parses out field names from an opportunity naming spec and returns them as a set of
    * strings.
    * @param fields An opportunity naming spec.
    * @return Set<String> The field names from the spec.
    ********************************************************************************************************/
    public static Set<String> getFieldNamesFromSpec(String spec) {
        Set<String> setStrField = new Set<String>();
        if (!string.isBlank(spec)) {
            // First, instantiate a new Pattern object looking for {!...}
            Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');
            //Pattern MyPattern = Pattern.compile('\\{!*\\}');
            // Then instantiate a new Matcher object
            Matcher MyMatcher = MyPattern.matcher(spec);

            while (MyMatcher.find()) {
                // get the fieldname without the {}'s
                String strField = spec.substring(MyMatcher.start() + chLToken.length(), MyMatcher.end()-chRToken.length());
                setStrField.add(strField.trim().toLowerCase());
            }
        }
        return setStrField;
    }

    /*******************************************************************************************************
    * @description Finds an opportunity's attribution based on Account.npe01__SYSTEMIsIndividual__c
    * @param opp The queried opportunity and all associated fields in the spec.
    * @param con The queried contact and all associated fields in the spec.
    * @param ons The opportunity naming setting that applies to this opportunity.
    * @return String The opportunity name for this opportunity.
    ********************************************************************************************************/
    public static String replaceFieldNamesWithValues(Opportunity opp, Contact con, Opportunity_Naming_Settings__c ons) {
        String result = ons.Opportunity_Name_Format__c;

        //First, instantiate a new Pattern object looking for {!...} without any nested {'s.
        Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');
        //Pattern MyPattern = Pattern.compile('\\{!*\\}');
        //Then instantiate a new Matcher object
        Matcher MyMatcher = MyPattern.matcher(ons.Opportunity_Name_Format__c);

        while (MyMatcher.find()) {
            //get the fieldname without the {! }
            String strField = ons.Opportunity_Name_Format__c.substring(MyMatcher.start() + chLToken.length(), MyMatcher.end()-chRToken.length());

            //separate cross object references, i.e. account.name
            List<String> splitField = (strField.split('\\.',0));

            //remove the field name itself to only include parent object references
            String fieldName = splitField[splitField.size()-1];
            splitField.remove(splitField.size()-1);

            //use the correct sObject
            SObject thisObj;
            if (!splitField.isEmpty() && splitField[0].equalsIgnoreCase('contact')) {
                thisObj = con;
                splitField.remove(0);
            } else {
                thisObj = opp;
            }

            //traverse parent relationships until the last one
            for (String parentObj : splitField) {
                if (thisObj != null) {
                    thisObj = thisObj.getSObject(parentObj);
                }
            }
            // For the RecordType object, use the result of toLabel(RecordType.Name) so the value is properly translated
            if (thisObj != null && thisObj.getSObjectType() == recordTypeSObjectType) {
                thisObj.put('Name', thisObj.get('RecordTypeLabel'));
            }

            //if this field is a date or datetime field, follow the format supplied in the settings
            String val = getFieldValue(thisObj, fieldName, ons);

            // add back the {}'s for String substitution
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

     /*******************************************************************************************************
    * @description Gets the field value from an object, and formats it properly if needed.
    * @param obj The sObject to get the field value from.
    * @param fieldName The name of the field to get.
    * @param ons The opportunity naming setting that applies to this field.
    * @return String The formatted value of the field.
    ********************************************************************************************************/
   public static String getFieldValue(SObject obj, String fieldName, Opportunity_Naming_Settings__c ons) {
        if (obj == null) {
            return null;
        }
        Schema.DisplayType dt = UTIL_Describe.getFieldDisplaytype(obj.getSObjectType().getDescribe().getName(),fieldName);
        String result = '';

        if (obj.get(fieldName.trim()) == null) {
            return null;
        }

        //If this is a Date or DateTime field, use the specified formatting if there is one
        if (dt == Schema.DisplayType.Date || dt == Schema.DisplayType.DateTime) {
            DateTime d = (DateTime) obj.get(fieldName.trim());
            String dateFormat = String.isBlank(ons.Date_Format__c) ? 'yyyy.MM.dd' : ons.Date_Format__c;

            //if this was a date, use the GMT time zone so we don't end up on a different date
            if (dt == Schema.DisplayType.Date) {
                result = d.formatGmt(dateFormat);
            } else {
                result = d.format(dateFormat);
            }

        } else if (dt == Schema.DisplayType.Currency) {

            if (obj.get(fieldName.trim())!=null) {
                String currCode = null;
                if (UTIL_Currency.getInstance().isMultiCurrencyOrganization()) {
                    currCode = (String) obj.get('CurrencyIsoCode');
                }
                String currencySymbol = UTIL_Currency.getInstance().getCurrencySymbol(currCode);
                if (!String.isBlank(currencySymbol) && currencySymbol.length() > 1) {
                    currencySymbol += ' ';
                }
                result = String.isBlank(currencySymbol) ? String.valueOf(obj.get(fieldName.trim())) : currencySymbol + String.valueOf(obj.get(fieldName.trim()));

                if (result.endsWith('.00')) {
                    result = result.subString(0,result.length()-3);
                }
            }
        } else {

            result = String.valueOf(obj.get(fieldName.trim()));
        }

        return result;
    }

}