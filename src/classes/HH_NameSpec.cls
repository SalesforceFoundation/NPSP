/*
    Copyright (c) 2014, Salesforce.com Foundation
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
* @date 2014
* @description HH_NameSpec class that implements template based naming for Households.
*/
public with sharing class HH_NameSpec implements HH_INaming {

    // get the Household Name for the passed in list of Contacts from a single Household.
    public string getHouseholdName(list<Contact> listCon) { 
        NameSpec ns = new NameSpec(hns, 'Household_Name_Format__c');
        return strNameFromNameSpec(ns, listCon);            	
    }

    // get the Household Formal Greeting for the passed in list of Contacts from a single Household.
    public string getHouseholdFormalGreeting(list<Contact> listCon) { 
        NameSpec ns = new NameSpec(hns, 'Formal_Greeting_Format__c');
        return strNameFromNameSpec(ns, listCon);                
    }

    // get the Household Informal Greeting for the passed in list of Contacts from a single Household.
    public string getHouseholdInformalGreeting(list<Contact> listCon) { 
        NameSpec ns = new NameSpec(hns, 'Informal_Greeting_Format__c');
        return strNameFromNameSpec(ns, listCon);                
    }
    
    // for the Settings page, get the formatted name for the list of Contacts.
    // hns holds an in-memory Household Naming Settings object, and strField is one of:
    // Household_Name_Format__c, Formal_Greeting_Format__c, or Informal_Greeting_Format__c.
    public string getExampleName(Household_Naming_Settings__c hnsMem, string strField, list<Contact> listCon) {
        NameSpec ns = new NameSpec(hnsMem, strField);
        return strNameFromNameSpec(ns, listCon);        
    }
    
    // our cached copy of the Household Naming Settings
    private Household_Naming_Settings__c hns {
    	get {
    		if (hns == null) hns = UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
    		return hns;
    	}
    	set;
    }

    private static string chLToken = '{!';
    private static string chRToken = '}';
        
    // class that supports the parsing of a format string
    // from the Household Naming Settings object.
    //
    // the NameSpec looks like:
    //      prefix {lastname} {{firstnamespec}} suffix
    // where firstname spec is a combo of fields and literals like:
    //      {salutation} {firstname} ({mailingcity})
    //
    private class NameSpec {
        private string strPrefix { get; set; }
        private string strSuffix { get; set; }
        private string strFirstNameSpec { get; set; }
        private string strFullNameSpec { get; set; }
        private string strAnd { get; set; }
        private string strOverrun { get; set; }
        private integer cMaxUseOverrun { get; set; }
        private string strHNSField { get; set; }
        
        private NameSpec(Household_Naming_Settings__c hns, string strField) {
        	strHNSField = strField; 
        	string strNameSpec = string.valueOf(hns.get(strField));
        	strAnd = hns.Name_Connector__c;
        	strOverrun = hns.Name_Overrun__c;
        	cMaxUseOverrun = integer.valueOf(hns.Contact_Overrun_Count__c);
        	parseNameSpec(strNameSpec);
        }
        
        private void parseNameSpec(string strNameSpec) {
            strPrefix = '';
            strSuffix = '';
            strFirstNameSpec = '';
            strFullNameSpec = '';
            
            if (strNameSpec == null)
                return;
            
            // get optional Prefix
            integer ich = strNameSpec.indexOf(chLToken);   
            if (ich > 0) {
                // don't include any tokens immediately next to the '{' in the prefix
                //while (ich > 0 && strNameSpec.substring(ich, ich+1) != ' ') ich--;
                strPrefix = strNameSpec.left(ich);
                strNameSpec = strNameSpec.substring(ich);
            }
               
            // get optional Suffix
            ich = strNameSpec.lastIndexOf(chRToken);
            if (ich > 0) {
                // don't include any tokens immediately after the '}' in the suffix
                while (ich < strNameSpec.length()-1 && strNameSpec.substring(ich+1, ich+2) != ' ') ich++;
                strSuffix = strNameSpec.substring(ich+1);
                strNameSpec = strNameSpec.left(ich+1);
            }
            
            // look for the FirstNameSpec by removing any {LastName} field references
            string str = strNameSpec.replace(chLToken + 'LastName' + chRToken, '');
            ich = str.indexOf(chLToken);
            integer ichR = str.lastIndexOf(chRToken);
            if (ich >= 0 && ichR > 0) {
                strFirstNameSpec = str.substring(ich + chLToken.length(), ichR);
                strFullNameSpec = strNameSpec.replace(strFirstNameSpec, 'FirstNameSpec');
            } else {
                strFullNameSpec = strNameSpec;
            }
        }
    }
    
    
    // given a namespec and a list of Contacts (assumed from a single household),
    // return the formated string for that household.  
    // this can be used for any of the household strings (name, formal greeting, informal greeting)
    private static string strNameFromNameSpec(NameSpec ns, list<Contact> listCon) {
        string strName = '';
        integer cCon = listCon.size();          
        integer i = 0;
        boolean isNoLastnames = (ns.strFullNameSpec.indexOf(chLToken + 'LastName' + chRToken) == -1);
        
        if (cCon == 0) {
        	if (ns.strHNSField == 'Household_Name_Format__c')
        	   strName = label.npo02.HouseholdAnonymousName;
            else 
        	   strName = label.npo02.HouseholdAnonymousGreeting;
        }
        
        while (i < cCon && i < ns.cMaxUseOverrun) {
            
            string strLname = listCon[i].LastName;
            string strFname = strConFspec(listCon[i], ns.strFirstNameSpec);
            
            // get the set of all fname's for this lname
            integer j = i + 1;
            while (j < cCon && j < ns.cMaxUseOverrun && (isNoLastnames || listCon[j].LastName == strLname)) {
                integer k = j + 1;
                if (k == cCon || (!isNoLastnames && listCon[k].LastName != strLname)) {
                    strFname += ' ' + ns.strAnd + ' ' + strConFspec(listCon[j], ns.strFirstNameSpec);
                    j++;
                    break;
                } else {
                    strFName += ', ' + strConFspec(listCon[j], ns.strFirstNameSpec);
                    j++;
                }
            }
            
            // now all contacts from lname should have their fname in strFname.
            string strCon = ns.strFullNameSpec;
            strCon = strCon.replace(chLToken + 'LastName' + chRToken, strLname);
            strCon = strCon.replace(chLToken + 'FirstNameSpec' + chRToken, strFname);
            
            // add it to the whole name
            if (i > 0 && j < cCon && j < ns.cMaxUseOverrun) {
                strName += ', ';
            } else if (i > 0 && (j == cCon || j == ns.cMaxUseOverrun)) {
                strName += ' ' + ns.strAnd + ' ';
            }
            strName += strCon;

            if (j == ns.cMaxUseOverrun && cCon > ns.cMaxUseOverrun && ns.strFirstNameSpec != '') {
                strName += ' ' + ns.strAnd + ' ' + ns.strOverrun;
            }

            // continue with the next person we haven't included
            i = j;
        }
        
        return ns.strPrefix + strName + ns.strSuffix;
    }
    
    // given a single contact and a namespec, returns the formatted string filling
    // in fields in the namespec from the contact.
    private static string strConFspec(Contact con, string strFspec) {
        string str = strFspec;
        
        // First, instantiate a new Pattern object looking for {...} without any nested {'s.
        Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');       
        // Then instantiate a new Matcher object 
        Matcher MyMatcher = MyPattern.matcher(strFspec);
        
        while (MyMatcher.find()) {
            // get the fieldname without the {}'s
            string strField = strFspec.substring(MyMatcher.start() + chLToken.length(), MyMatcher.end()-1);
            string val = string.valueOf(con.get(strField.trim()));
            // add back the {}'s for string substitution
            strField = chLToken + strField + chRToken;
            if (val == null) {   
                // eat potential trailing space
                str = str.replace(strField + ' ', '');
                // eat potential leading space
                str = str.replace(' ' + strField, '');
            }
            str = str.replace(strField, val == null ? '' : val);
        }
        return str;     
    }

}