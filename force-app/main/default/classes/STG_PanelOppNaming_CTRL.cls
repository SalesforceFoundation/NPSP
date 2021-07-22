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
* @group Settings
* @description Controller for the Opportunity Naming settings panel.
*/
public with sharing class STG_PanelOppNaming_CTRL extends STG_Panel {

    /*********************************************************************************************************
    * @description The active Opportunity Name Settings instance in new or edit mode.
    */
    public Opportunity_Naming_Settings__c currentONS {get;set;}

    /*********************************************************************************************************
    * @description The name of the Opportunity Naming Settings instance, passed from the page to know which
    * instance we're dealing with.
    */
    public string currentONSName {get;set;}

   /***
    * @description Contains Recurring Donation Installment Name field API name
    */
    private static String rdInstallmentFieldName {
        get {
            if (String.isBlank(rdInstallmentFieldName)) {
                rdInstallmentFieldName = UTIL_Namespace.StrTokenNSPrefix('Recurring_Donation_Installment_Name__c');
            }
            return rdInstallmentFieldName;
        }
        set;
    }

    /***
    * @description Specifies whether you want to apply these settings to Contact Donations,
    * Organization Donations, or both Contact and Organization Donations.
    */
    public enum AttributionOptions {
        Both,
        Contact_Donations,
        Organization_Donations
    }

    /*********************************************************************************************************
    * @description A map of all Opportunity Naming Settings by Name.
    */
    public map<string,Opportunity_Naming_Settings__c> mapOppNameSettings {
        get {
            if (mapOppNameSettings==null)
                mapOppNameSettings = UTIL_ListCustomSettingsFacade.getMapOppNamingSettings();
            return mapOppNameSettings;
        }
        set;
    }

    /*********************************************************************************************************
    * @description A list of all Opportunity Naming Settings for display on the page. Replaces blank Name
    * Formats with  "- do not rename-" and blank Record Types with '- all record types -'
    */
    public List<OpportunityNamingSetting> listOppNameSettings {
        get {
            listOppNameSettings = new List<OpportunityNamingSetting>();
            List<Opportunity_Naming_Settings__c> oppNameSettings = mapOppNameSettings.values().deepClone();
            for (Opportunity_Naming_Settings__c ons : oppNameSettings) {
                listOppNameSettings.add(new OpportunityNamingSetting(ons));
            }
            return listOppNameSettings;
        }
        set;
    }

    /*********************************************************************************************************
    * @description The panel's constructor
    */
    public STG_PanelOppNaming_CTRL() {}

    /*********************************************************************************************************
    * @description Returns the string Id of the Households panel.
    */
    public override string idPanel() { return 'idPanelOppNaming'; }

    /*********************************************************************************************************
    * @description Action Method to delete a specific settings instance.
    * @return null
    */
    public PageReference delONS() {
        if (!isRunningUserIsAdmin) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.stgDeletePermissionError));
            return null;
        }

        delete mapOppNameSettings.get(currentONSName);
        UTIL_ListCustomSettingsFacade.mapOppNamingSettings = null;//reset the Opp naming settings
        mapOppNameSettings = UTIL_ListCustomSettingsFacade.getMapOppNamingSettings();
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to enter Edit mode for a specific setting instance.
    * @return null
    */
    public PageReference editONS() {
        if (!isRunningUserIsAdmin) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.stgEditPermissionError));
            return null;
        }

        currentONS = mapOppNameSettings.get(currentONSName);
        super.editSettings();
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to create a new settings object in memory, then enter Edit mode.
    * @return null
    */
    public PageReference newONS() {
        currentONS = new Opportunity_Naming_Settings__c(
            Name = System.now().format()
        );
        super.editSettings();
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to validate the current setting, save it, refresh the list of settings, and
    * return to the main page.
    * @return null
    */
    public PageReference saveONS() {
        if (isValidNameFormats()) {
            upsert currentONS;
            mapOppNameSettings = UTIL_ListCustomSettingsFacade.getMapOppNamingSettings();
            super.cancelEdit();
        }
        return null;
    }

    /*********************************************************************************************************
    * @description TODO: Returns whether the custom name formats are valid or not, and adds a Page Message for
    * any errors.
    * @return boolean
    */
    public boolean isValidNameFormats() {
        try {
            OPP_OpportunityNaming.validateSetting(currentONS);
            return true;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return false;
        }
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions for the Date Format
    */
    static public list<SelectOption> listSODateFormats {
        get {
            if (listSODateFormats == null) {
                listSODateFormats = new list<SelectOption>();
                listSODateFormats.add(new SelectOption('', Label.stgLabelNone));
                listSODateFormats.add(new SelectOption('yyyy-MM-dd', 'yyyy-MM-dd'));
                listSODateFormats.add(new SelectOption('MM/dd/yyyy', 'MM/dd/yyyy'));
                listSODateFormats.add(new SelectOption('MMMM dd, yyyy', 'MMMM dd, yyyy'));
                listSODateFormats.add(new SelectOption('yyyy', 'yyyy'));
                listSODateFormats.add(new SelectOption(Label.stgLabelOther, Label.stgLabelOther));
            }
            return listSODateFormats;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions for the Opportunity Naming Formats
    */
    static public list<SelectOption> listSOOpportunityNamingFormats {
        get {
            if (listSOOpportunityNamingFormats == null) {
                listSOOpportunityNamingFormats = new list<SelectOption>();
                listSOOpportunityNamingFormats.add(new SelectOption('', Label.stgLabelDoNotRename));
                listSOOpportunityNamingFormats.add(new SelectOption('{!Contact.Name} {!Amount} {!RecordType.Name} {!CloseDate} {!' + rdInstallmentFieldName + '}', '{!Contact.Name} {!Amount} {!RecordType.Name} {!CloseDate} {!' + rdInstallmentFieldName + '}'));
                listSOOpportunityNamingFormats.add(new SelectOption('{!Account.Name} {!Amount} {!RecordType.Name} {!CloseDate}', '{!Account.Name} {!Amount} {!RecordType.Name} {!CloseDate}'));
                listSOOpportunityNamingFormats.add(new SelectOption('{!Contact.Name} {!RecordType.Name} {!CloseDate} {!Campaign.Name}', '{!Contact.Name} {!RecordType.Name} {!CloseDate} {!Campaign.Name}'));
                listSOOpportunityNamingFormats.add(new SelectOption(Label.stgLabelOther, Label.stgLabelOther));
            }
            return listSOOpportunityNamingFormats;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions for Opportunity Attribution
    */
    public static list<SelectOption> listSOOpportunityAttribution {
        get {
            if (listSOOpportunityAttribution == null) {
                listSOOpportunityAttribution = new AttributionSettings().getSelectOptions();
            }
            return listSOOpportunityAttribution;
        }
        private set;
    }


   /***
    * @description Handles Opportunity Naming Settings Attribution options
    */
    public class AttributionSettings {

        public String selectedOption { get; private set; }
        public String selectedLabel { get; private set; }

        /***
        * @description Contains the Opp Naming Settings Attribution API name to the custom label mapping
        */
        private Map<String, String> labelByOption {
            get {
                if (labelByOption == null) {
                    labelByOption = new Map<String, String>{
                        AttributionOptions.Both.name() => System.Label.OppNamingBoth,
                        AttributionOptions.Contact_Donations.name() => System.Label.oppNamingIndividual,
                        AttributionOptions.Organization_Donations.name() => System.Label.oppNamingOrganizational
                    };
                }
                return labelByOption;
            }
            set;
        }

        /***
        * @description Contains the Opp Naming Settings Attribution custom label to the API name mapping
        */
        private Map<String, String> optionByLabel {
            get {
                if (optionByLabel == null) {
                    optionByLabel = new Map<String, String>{
                        System.Label.OppNamingBoth => AttributionOptions.Both.name(),
                        'Both' => AttributionOptions.Both.name(),

                        System.Label.oppNamingIndividual => AttributionOptions.Contact_Donations.name(),
                        'Contact Donations' => AttributionOptions.Contact_Donations.name(),

                        System.Label.oppNamingOrganizational => AttributionOptions.Organization_Donations.name(),
                        'Organization Donations' => AttributionOptions.Organization_Donations.name()
                    };
                }
                return optionByLabel;
            }
            set;
        }

        /***
        * @description Sets attribution value as configured in the Opportunity Naming Settings
        */
        public AttributionSettings withSelected(String option) {
            this.selectedOption = optionByLabel.containsKey(option) ? optionByLabel.get(option) : option;
            this.selectedLabel = getLabel(this.selectedOption);
            return this;
        }

        /***
        * @description Generate the select options for attribution settings
        */
        public List<SelectOption> getSelectOptions() {
            List<SelectOption> options = new List<SelectOption>();

            for (AttributionOptions option : AttributionOptions.values()) {
                options.add(new SelectOption(option.name(), getLabel(option.name())));
            }

            return options;
        }

        /***
        * @description Map the attribution option to the custom label used in Opp naming or settings field option display
        */
        public String getLabel(String option) {
            String label = labelByOption.get(option);

            return String.isBlank(label)
                ? String.isBlank(option) ? '' : option
                : label;
        }

        /***
        * @description Returns true if attribution is applicable to both Contact and Organization Donations
        */
        public Boolean isBoth() {
            return selectedOption == AttributionOptions.Both.name();
        }

    }

    public class OpportunityNamingSetting {
        public Opportunity_Naming_Settings__c so { get; set; }
        public String oppRecordTypesString { get; set; }
        public String nameFormatString { get; set; }
        public OpportunityNamingSetting(Opportunity_Naming_Settings__c ons) {
            this.so = ons;
            this.oppRecordTypesString = STG_Panel.getRecordTypeNamesFromPicklistString(
                Opportunity.sObjectType,
                ons.Opportunity_Record_Types__c,
                Label.stgLabelAllRecordTypes
            );
            if (string.isBlank(ons.Opportunity_Name_Format__c)) {
                this.nameFormatString = Label.stgLabelDoNotRename;
            } else {
                this.nameFormatString = ons.Opportunity_Name_Format__c;
            }
        }
    }
}