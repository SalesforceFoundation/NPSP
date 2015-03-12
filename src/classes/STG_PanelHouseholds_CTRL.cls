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
* @group Settings
* @description Controller for the Households panel.
*/
public with sharing class STG_PanelHouseholds_CTRL extends STG_Panel {
	
    /*********************************************************************************************************
    * @description The panel's constructor 
    */
	public STG_PanelHouseholds_CTRL() {
		isRunningBatch = false;
	}
	    
    /*********************************************************************************************************
    * @description Returns the string Id of the Households panel. 
    */
    public override string idPanel() { return 'idPanelHH'; }

    /*********************************************************************************************************
    * @description Whether we are running the Update Household Names batch process 
    */
    public boolean isRunningBatch { get; set; }

    /*********************************************************************************************************
    * @description Action Method to save settings and invoke the Update Household Names batch process 
    * @return null
    */
    public PageReference activateHouseholdNaming() {
        boolean isActivation = (UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Advanced_Household_Naming__c == false);
                
        STG_Panel.stgService.stgHH.npo02__Advanced_Household_Naming__c = true;

        // make sure any custom name formats are valid.
		if (!isValidNameFormats()) {
			return null;        			
		}

        saveSettings();
        
        isRunningBatch = true; 
        HH_HouseholdNaming.refreshAllHouseholdNaming(isActivation);        
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to enter Edit mode
    * @return null 
    */
    public override PageReference editSettings() {
        isRunningBatch = false;
        return super.editSettings();
    }
    
    /*********************************************************************************************************
    * @description Returns wwhether the custom name formats are valid or not, and adds a Page Message for
    * any errors.
    * @return boolean 
    */
    private boolean isValidNameFormats() {
        // make sure any custom name formats are valid.
        if (STG_Panel.stgService.stgHH.npo02__Advanced_Household_Naming__c) {
	        string strSetting;        
			try {
				strSetting = UTIL_Describe.getFieldLabel(UTIL_Namespace.StrTokenNSPrefix('Household_Naming_Settings__c'), 'Household_Name_Format__c');     
	            strNameSpecExample(STG_Panel.stgService.stgHN, 'Household_Name_Format__c', 2); 
				strSetting = UTIL_Describe.getFieldLabel(UTIL_Namespace.StrTokenNSPrefix('Household_Naming_Settings__c'), 'Formal_Greeting_Format__c');     
	            strNameSpecExample(STG_Panel.stgService.stgHN, 'Formal_Greeting_Format__c', 2); 
				strSetting = UTIL_Describe.getFieldLabel(UTIL_Namespace.StrTokenNSPrefix('Household_Naming_Settings__c'), 'Informal_Greeting_Format__c');     
	            strNameSpecExample(STG_Panel.stgService.stgHN, 'Informal_Greeting_Format__c', 2);
	            return true; 
			} catch (Exception ex) {
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
	            	string.format(label.stgErrorInvalidNameFormat, new string[]{strSetting, ex.getMessage()})));
	            return false;			
			}        
        } 
        return true;   	
    }

    /*********************************************************************************************************
    * @description Action Method to save the current settings
    * @return null 
    */
    public override PageReference saveSettings() {
    	
    	// add some extra error detection
    	if (STG_Panel.stgService.stgHH.npo02__Household_Rules__c != HH_Households.NO_HOUSEHOLDS_PROCESSOR &&
    	   STG_Panel.stgService.stgCon.npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, system.Label.stgValidationHHAccountHHRules));
            return null;
        }

        // make sure any custom name formats are valid.
		if (!isValidNameFormats())
			return null;        
                
        return super.saveSettings();
    }

    /*********************************************************************************************************
    * @description The name of the Household Mailing List report 
    */
    static public string strMailingReport {
        get {
            if (strMailingReport == null) {
            	ID id = STG_Panel.stgService.stgHH.npo02__Household_Mailing_List_ID__c;
            	if (id != null) {
	                list<Report> listRpt = [select Id, Name from Report where id = :id];
	                if (listRpt.size() > 0)
	                   strMailingReport = listRpt[0].Name;
            	}
            }
            return strMailingReport;
        }
        private set;
    }
        
    /*********************************************************************************************************
    * @description The list of SelectOptions for the Household Name Formats 
    */
    static public list<SelectOption> listSOHouseholdNameFormats {
        get {    
            if (listSOHouseholdNameFormats == null) {
                listSOHouseholdNameFormats = new list<SelectOption>();
                listSOHouseholdNameFormats.add(new SelectOption('', Label.stgLabelNone));
                listSOHouseholdNameFormats.add(new SelectOption('{!LastName} ' + label.npo02.DefaultHouseholdName, '{!LastName} ' + label.npo02.DefaultHouseholdName));
                listSOHouseholdNameFormats.add(new SelectOption('{!{!FirstName}} {!LastName} ' + label.npo02.DefaultHouseholdName, '{!{!FirstName}} {!LastName} ' + label.npo02.DefaultHouseholdName));
                listSOHouseholdNameFormats.add(new SelectOption('{!LastName} ({!{!FirstName}}) ' + label.npo02.DefaultHouseholdName, '{!LastName} ({!{!FirstName}}) ' + label.npo02.DefaultHouseholdName));
                listSOHouseholdNameFormats.add(new SelectOption('{!LastName} Family', '{!LastName} Family'));
                listSOHouseholdNameFormats.add(new SelectOption('{!{!FirstName}} {!LastName} Family', '{!{!FirstName}} {!LastName} Family'));
                listSOHouseholdNameFormats.add(new SelectOption('{!LastName} ({!{!FirstName}}) Family', '{!LastName} ({!{!FirstName}}) Family'));
                listSOHouseholdNameFormats.add(new SelectOption(Label.stgLabelOther, Label.stgLabelOther));
            }
            return listSOHouseholdNameFormats;
        }
        private set;
    }
    
    /*********************************************************************************************************
    * @description The list of SelectOptions for the Household Greeting Formats 
    */
    static public list<SelectOption> listSOFormalGreetingFormats {
        get {    
            if (listSOFormalGreetingFormats == null) {
                listSOFormalGreetingFormats = new list<SelectOption>();
                listSOFormalGreetingFormats.add(new SelectOption('', Label.stgLabelNone));
                listSOFormalGreetingFormats.add(new SelectOption('{!{!FirstName}} {!LastName}', '{!{!FirstName}} {!LastName}'));
                listSOFormalGreetingFormats.add(new SelectOption('{!{!Salutation} {!FirstName}} {!LastName}', '{!{!Salutation} {!FirstName}} {!LastName}'));
                listSOFormalGreetingFormats.add(new SelectOption(Label.stgLabelOther, Label.stgLabelOther));
            }
            return listSOFormalGreetingFormats;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions for the Household Informal Greeting Formats 
    */
    static public list<SelectOption> listSOInformalGreetingFormats {
        get {    
            if (listSOInformalGreetingFormats == null) {
                listSOInformalGreetingFormats = new list<SelectOption>();
                listSOInformalGreetingFormats.add(new SelectOption('', Label.stgLabelNone));
                listSOInformalGreetingFormats.add(new SelectOption('{!{!FirstName}}', '{!{!FirstName}}'));
                listSOInformalGreetingFormats.add(new SelectOption('{!{!FirstName}} {!LastName}', '{!{!FirstName}} {!LastName}'));
                listSOInformalGreetingFormats.add(new SelectOption(Label.stgLabelOther, Label.stgLabelOther));
            }
            return listSOInformalGreetingFormats;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description The list of Contacts to use when construction sample name examples 
    */
    private static list<Contact> listConExamples {
    	get {
            if (listConExamples == null) {
                    listConExamples = new list<Contact>();
                    Contact con = new Contact();
                    con.FirstName = 'Sam';
                    con.LastName = 'Smith';
                    con.Salutation = 'Dr.';
                    con.MailingCity = 'Seattle';
                    listConExamples.add(con);
                    
                    con = new Contact();
                    con.FirstName = 'Sally';
                    con.LastName = 'Smith';
                    con.Salutation = 'Mrs.';
                    con.MailingCity = 'Seattle';
                    listConExamples.add(con);
                    
                    con = new Contact();
                    con.FirstName = 'Suzie';
                    con.LastName = 'Smith';
                    listConExamples.add(con);

                    con = new Contact();
                    con.FirstName = 'Daphne';
                    con.LastName = 'Doe';
                    con.Salutation = 'Ms.';
                    con.MailingCity = 'Portland';
                    listConExamples.add(con);

                    con = new Contact();
                    con.FirstName = 'Donald';
                    con.LastName = 'Doe';
                    con.Salutation = 'Mr.';
                    con.MailingCity = 'Portland';
                    listConExamples.add(con);
                }
            return listConExamples;
        }
    	private set;
    }
    
    /*********************************************************************************************************
    * @description Javascript remoting api to provide an Example formatted string given an instance of
    * Household Name Settings, which type of string (Name, Formal Greeting, Informal Greeting),
    * for the specified number of sample Contacts.
    * @param hns The current Household Name Settings
    * @param strField The custom name field to get examples for (Name, Formal Greeting, Informal Greeting)
    * @param cContact How many Contacts to include in the example name
    */
    @RemoteAction
    public static string strNameSpecExample(Household_Naming_Settings__c hns, string strField, integer cContact) {
    
        list<Contact> listCon = new list<Contact>();
        for (integer i = 0; i < cContact && i < listConExamples.size(); i++)
        	listCon.add(listConExamples[i]);
        	
        // call INaming interface dynamically  
        string strClass = hns.Implementing_Class__c;  
        if (strClass == null || strClass == '') strClass = 'HH_NameSpec';   
        Type classType = Type.forName(strClass);
        if (classType != null) {     
            Object classInstance = classType.newInstance();
            if (classInstance instanceof HH_INaming) {
                HH_INaming n = (HH_INaming)classInstance;
                return n.getExampleName(hns, strField, listCon);
            } else {
            	return label.stgErrorINaming;
            }
        } else {
        	return label.stgErrorInvalidClass;
        }
    }    
}