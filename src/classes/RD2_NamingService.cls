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
* @description Recurring Donations Naming Service
*
*/
public with sharing class RD2_NamingService {

    private static final String CURRENCY_ISO_CODE_FIELD = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;
    public static final Integer MAX_NAME_LENGTH = 80;

    /**
    * @description Support special Naming Tokens that can be used in the RD Name
    */
    private static final Map<String, String> namingTokens = new Map<String, String>{
        '$RECURRING_NAME_SUFFIX$' => System.Label.RecurringDonationNameSuffix,
        '$RECURRING_OBJECT_NAME$' => UTIL_Describe.getObjectLabel('npe03__Recurring_Donation__c')
    };

    /***
    * @description Supported RD Naming format options
    */
    public static final String RD_NAMING_OPTION_1 = '{!npe03__Donor_Name__c} {!npe03__Amount__c} - $RECURRING_NAME_SUFFIX$';
    public static final String RD_NAMING_OPTION_2 = '{!npe03__Donor_Name__c} {!npe03__Installment_Period__c} $RECURRING_OBJECT_NAME$ - {!npe03__Amount__c}';
    public static final String RD_NAMING_OPTION_3 = '{!npe03__Donor_Name__c} {!npe03__Amount__c} {!npe03__Installment_Period__c}';

    /***
    * @description Checks if the Recurring Donation automatic naming is turned on
    */
    @TestVisible
    public static Boolean isAutomaticNamingEnabled {
        get {
            if (isAutomaticNamingEnabled == null) {
                isAutomaticNamingEnabled = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().EnableAutomaticNaming__c == true;
            }
            return isAutomaticNamingEnabled;
        }
        private set;
    }

    /***
    * @description Retrieves the record type id for the household account record type
    */
    @TestVisible
    public static String hhRecordTypeId {
        get {
            if (hhRecordTypeId == null) {
                hhRecordTypeId = UTIL_CustomSettingsFacade.getContactsSettings().npe01__HH_Account_RecordTypeID__c;
            }
            return hhRecordTypeId;
        }
        private set;
    }

    /***
    * @description Determines if multi-currency is enabled for the org
    */
    private static Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }

    /***
    * @description Currency symbol for the user default currency
    */
    private static String userDefaultCurrencySymbol {
        get {
            if (userDefaultCurrencySymbol == null) {
                userDefaultCurrencySymbol = UTIL_Currency.getInstance().getCurrencySymbol(UserInfo.getDefaultCurrency());
            }
            return userDefaultCurrencySymbol;
        }
        set;
    }

    /***
    * @description Returns Donor (Account/Contact) records
    */
    @TestVisible
    private RD2_Donor.IGateway donorGateway {
        get {
            if (donorGateway == null) {
                donorGateway = new RD2_Donor.Gateway();
            }
            return donorGateway;
        }
        set;
    }

    /***
    * @description Autogenerates recurring donation names if Name construct fields have changed
    * @param rds New/changed Recurring Donations
    * @param oldRds Old Recurring Donations
    */
    public void autogenerateNamesOnChange(List<npe03__Recurring_Donation__c> rds, List<npe03__Recurring_Donation__c> oldRds) {
        if (!isAutomaticNamingEnabled) {
            return;
        }

        Map<Id, npe03__Recurring_Donation__c> oldRdById = new Map<Id, npe03__Recurring_Donation__c>(oldRds);
        List<npe03__Recurring_Donation__c> changedRds = new List<npe03__Recurring_Donation__c>();

        for (npe03__Recurring_Donation__c rd : rds) {
            if (hasChanged(rd, oldRdById.get(rd.Id))) {
                changedRds.add(rd);
            }
        }

        constructNames(changedRds);
    }

    /***
    * @description Determines if Name construct fields have changed
    * @param rd Changed Recurring Donation record
    * @param oldRd Old Recurring Donation record
    * @return Boolean Indication of the Recurring Donation Name construct fields are changed
    */
    @TestVisible
    private Boolean hasChanged(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        Boolean hasChanged = rd.npe03__Organization__c != oldRd.npe03__Organization__c
            || rd.npe03__Contact__c != oldRd.npe03__Contact__c
            || rd.npe03__Amount__c != oldRd.npe03__Amount__c
            || rd.npe03__Installment_Period__c != oldRd.npe03__Installment_Period__c
            || rd.Name == System.Label.npo02.NameReplacementText;

        if (!hasChanged && isMultiCurrencyEnabled) {
            hasChanged = (String) rd.get(CURRENCY_ISO_CODE_FIELD) != (String) oldRd.get(CURRENCY_ISO_CODE_FIELD);
        }

        return hasChanged;
    }

    /***
    * @description Autogenerates recurring donation names for all specified records on insert
    * @param rds New Recurring Donation records
    * @return void
    */
    public void autogenerateNames(List<npe03__Recurring_Donation__c> rds) {
        if (isAutomaticNamingEnabled) {
            constructNames(rds);

        } else if (RD2_EnablementService.isRecurringDonations2Enabled) {
            // autogenerate names when Elevate RD Name is empty
            List<npe03__Recurring_Donation__c> elevateRds = new List<npe03__Recurring_Donation__c>();
            for (npe03__Recurring_Donation__c rd : rds) {
                if (String.isNotBlank(rd.CommitmentId__c) && String.isBlank(rd.Name)) {
                    elevateRds.add(rd);
                }
            }
            constructNames(elevateRds);
        }
        //no special name handling for legacy RDs when auto-naming is not enabled
    }

    /***
    * @description Autogenerates recurring donation names for all specified records
    * @param rds New Recurring Donation records
    * @return void
    */
    private void constructNames(List<npe03__Recurring_Donation__c> rds) {
        if (rds == null || rds.isEmpty()) {
            return;
        }

        Map<Id, RD2_Donor.Record> donorById = donorGateway.getDonors(rds);
        for (npe03__Recurring_Donation__c rd : rds) {
            rd.Name = constructName(rd, donorById);
        }
    }

    /***
    * @description Constructs recurring donation name
    * Name formatting: "{!DonorName} {User Default Currency Symbol}{!Amount} - Recurring".
    *
    * @param rd Recurring Donation record
    * @param donorById Account/Contact donor record by Id
    * @return String New name for the Recurring Donation record
    */
    private String constructName(npe03__Recurring_Donation__c rd, Map<Id, RD2_Donor.Record> donorById) {

        RecurringDonationNameBuilder nameBuilder = new RecurringDonationNameBuilder(rd)
            .withDonorsById(donorById)
            .withNameFormat(getCurrentNamingFormat());

        return nameBuilder.build();
    }

    /**
     * @return The currently configured RD naming format string
     */
    private String getCurrentNamingFormat() {

        String format = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().RecurringDonationNameFormat__c;
        if (format == null) {
            format = RD_NAMING_OPTION_1; // the default format
        }

        return format;
    }

    /**
     * @description Build out the Recurring Donation name based on the define naming format
     */
    private class RecurringDonationNameBuilder {

        private npe03__Recurring_Donation__c rd;
        private String nameFormat;
        private Map<Id, RD2_Donor.Record> donorById;

        private String rdName;

        /**
         * @description Constructor
         * @param rd Recurring Donation
         */
        public RecurringDonationNameBuilder(npe03__Recurring_Donation__c rd) {
            this.rd = rd;
        }

        /**
         * @param nameFormat The RD Naming format to use
         * @return current instance
         */
        public RecurringDonationNameBuilder withNameFormat(String nameFormat) {
            this.nameFormat = nameFormat;
            return this;
        }

        /**
         * @param donorById Map of Donor Account or Contact information by RD Id
         * @return current instance
         */
        public RecurringDonationNameBuilder withDonorsById(Map<Id, RD2_Donor.Record> donorById) {
            this.donorById = donorById;
            return this;
        }

        /**
         * @description Generate the RD name
         * @return Recurring Donations Name
         */
        public String build() {
            rdName = this.nameFormat;

            rdName = replaceTokenValues();
            rdName = replaceFieldValues();
            rdName = replaceDonorName();

            return rdName;
        }

        /**
         * @return Replace instances of field tokens with field values, except for the Donor_Name__c field
         */
        private String replaceFieldValues() {

            Set<String> fields = getFieldNamesFromSpec();
            Map<String, String> fieldReplacements = new Map<String, String>();

            for (String fld : fields) {
                DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe('npe03__Recurring_Donation__c', fld);

                if (fld == 'npe03__Donor_Name__c') {
                    // Do this one last outside of the loop of all possible fields to support truncation

                } else if (dfr.getType() == DisplayType.CURRENCY) {
                    Object fldValue = rd.get(fld);
                    Double amtValue = 0;
                    if (fldValue != null) {
                        amtValue = (Double)fldValue;
                    }
                    fieldReplacements.put(fld, formatAmount(amtValue));

                } else if (dfr.getType() == DisplayType.PICKLIST) {
                    String fldValue = String.valueOf(rd.get(fld));
                    fldValue = UTIL_Describe.getTranslatedPicklistLabel(npe03__Recurring_Donation__c.SObjectType,
                        dfr.getSobjectField(), fldValue);
                    fieldReplacements.put(fld, fldValue);

                } else {
                    String fldValue = String.valueOf(rd.get(fld));
                    fieldReplacements.put(fld, fldValue);
                }
            }

            for (String fld : fieldReplacements.keySet()) {
                String token = '{!' + fld + '}';
                while (rdName.containsIgnoreCase(token)) {
                    String val = fieldReplacements.get(fld);
                    rdName = rdName.replace(token, (val != null ? val : ''));
                }
            }

            return rdName;
        }

        /**
         * @return The DonorName replacement in the naming format requires special handling to allow for
         * abbreviating it based on the total length of the name relative to the max size of the Name field
         */
        private String replaceDonorName() {
            String token = '{!npe03__Donor_Name__c}';

            if (!rdName.contains(token)) {
                return rdName;
            }

            Integer maxNameLength = MAX_NAME_LENGTH - (rdName.length() - token.length());
            String donorName = (maxNameLength > 0 ? getDonorName().abbreviate(maxNameLength) : '');
            rdName = rdName.replace(token, donorName);

            return rdName;
        }

        /**
         * @return Replace instances of special tokens with their values
         */
        private String replaceTokenValues() {
            for (String token : namingTokens.keySet()) {
                rdName = rdName.replace(token, namingTokens.get(token));
            }
            return rdName;
        }

        /**
         * @return The correct donor (contact or account) name to use in the name
         */
        private String getDonorName() {
            Boolean useContact = rd.npe03__Organization__c == null;
            if (!useContact) {
                useContact = donorById.get(rd.npe03__Organization__c).recordTypeId == hhRecordTypeId;
            }

            RD2_Donor.Record donor = useContact
                ? donorById.get(rd.npe03__Contact__c)
                : donorById.get(rd.npe03__Organization__c);

            return (donor != null) ? donor.name : '';
        }

        /***
        * @description Formats amount used to construct the name
        * @param amtValue Current value to format
        * @return String Formatted amount
        */
        private String formatAmount(Double amtValue) {
            String formattedAmount = amtValue.format();

            if (formattedAmount.endsWith('.00')) {
                formattedAmount = formattedAmount.removeEnd('.00');
            } else if (formattedAmount.endsWith('.0')) {
                formattedAmount = formattedAmount.removeEnd('.0');
            }

            String currencySymbol = userDefaultCurrencySymbol;
            if (isMultiCurrencyEnabled) {
                String code = (String) rd.get(CURRENCY_ISO_CODE_FIELD);
                currencySymbol = UTIL_Currency.getInstance().getCurrencySymbol(code);
            }

            if (String.isNotBlank(currencySymbol) && currencySymbol.length() > 1) {
                formattedAmount = currencySymbol + ' ' + formattedAmount;
            } else {
                formattedAmount = currencySymbol + formattedAmount;
            }

            return formattedAmount;
        }

        /**
        * @description Parses out field names from an RD naming spec and returns them as a set of strings
        * @return Set<String> The field names from the spec, without the curly brackets
        */
        private Set<String> getFieldNamesFromSpec() {
            Set<String> fields = new Set<String>();

            if (String.isBlank(nameFormat)) {
                return fields;
            }

            final String fldStartToken = '{!';
            final String fldEndToken = '}';

            Pattern MyPattern = Pattern.compile('\\{![^\\{!]*\\}');
            Matcher MyMatcher = MyPattern.matcher(nameFormat);
            while (MyMatcher.find()) {
                // get the fieldname without the {}'s
                String strField = nameFormat.substring(MyMatcher.start() + fldStartToken.length(), MyMatcher.end()-fldEndToken.length());
                fields.add(strField.trim());
            }
            return fields;
        }

    }
}