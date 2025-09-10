/*
    Copyright (c) 2011, Salesforce.org
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
* @author Evan Callahan & Steve Andersen
* @date 2008/7 (2.1)
* @group Payments
* @description Controller for payment creation wizard
*/
public with sharing class PMT_PaymentWizard_CTRL {

    /*******************************************************************************************************
    * @description Opportunity for the opp we're coming from
    */
    public Opportunity currentOpp { get; private set; }

    /*******************************************************************************************************
    * @description does the Opp have an outstanding balance
    */
    public Boolean haveAmount { get; private set; }

    /*******************************************************************************************************
    * @description after successful save set to true to redirect page
    */
    public Boolean redirect { get; set; }

    /**
     * @description The currency symbol or ISO code of the related record or
     * org default
     */
    @TestVisible
    private String currencySymbol;

    /*******************************************************************************************************
    * @description Permissions class used to determine if the running user has permissions
    */
    @TestVisible
    private UTIL_Permissions permissions {
        get {
            if (permissions == null) {
                permissions = new UTIL_Permissions();
            }

            return permissions;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Class that stored numbered payment
    */
    public class Payment {
        public Integer paymentNumber { get; private set; }
        public npe01__OppPayment__c oppPayment { get; set; }

        public Payment(Integer i) {
            paymentNumber = i;
            oppPayment = new npe01__OppPayment__c();
        }
    }

    /*******************************************************************************************************
    * @description is this the Writeoff wizard
    */
    public Boolean isWriteoffWizard{ get; set; }

    /*******************************************************************************************************
    * @description is this the Schedule Payments wizard
    */
    public Boolean isScheduleWizard{ get; set; }

    /*******************************************************************************************************
    * @description is this opportunity in a closed/lost stage
    */
    public Boolean isClosedLost{ get; set; }

    /*******************************************************************************************************
    * @description list of new payments to be created
    */
    List<Payment> newPayments = new List<Payment>();

    /*******************************************************************************************************
    * @description get the new payments list
    * @return List<Payment> the list of new payments to be created
    */
    public List<Payment> getPayments() {
        return newPayments ;
    }

    /*******************************************************************************************************
    * @description holds a sample payment object for use on the page
    */
    public npe01__oppPayment__c samplePayment { get; set; }

    /*******************************************************************************************************
    * @description holds the payment to represent a writeoff of outstanding balance
    */
    public npe01__oppPayment__c writeoffPayment { get; set; }

    /*******************************************************************************************************
    * @description number of payments to write off for the opp
    */
    public Integer writeoffPaymentCount { get; set; }

    /*******************************************************************************************************
    * @description integer for the number of installments to create
    */
    public Integer numberOfPayments { get; set; }

    /*******************************************************************************************************
    * @description integer to hold the interval chosen
    */
    public Integer interval { get; set; }

    /*******************************************************************************************************
    * @description boolean to remove paid payments and create a new schedule
    */
    public Boolean removePaidPayments { get; set; }

    /*******************************************************************************************************
    * @description holds Contact & Org Settings that contain the payment related settings
    */
    private npe01__Contacts_and_Orgs_Settings__c paymentsSettings;

    /*******************************************************************************************************
    * @description Returns true if the user has access to the Payment Wizard feature
    */
    public Boolean hasFeatureAccess {
        get {
            if (hasFeatureAccess == null) {
                hasFeatureAccess = hasFeatureAccess();
            }
            return hasFeatureAccess;
        }
        set;
    }

    public String getNamespace() {
        return UTIL_Namespace.getComponentNamespace();
    }

    /*******************************************************************************************************
    * @description decimal for amount already written off
    */
    private Decimal amountWrittenOff { get; set; }


    /*******************************************************************************************************
    * @description Integer for count of invalid payment records
    */
    private Integer invalidPaymentRecordCount { get; set; }

    /*******************************************************************************************************
    * @description Boolean to indicate if the wizard page should be enabled
    */
    public Boolean isWizardEnabled { get; set; }

    /*******************************************************************************************************
    * @description gets the payment related settings
    * @return npe01__Contacts_and_Orgs_Settings__c the settings object
    */
    @TestVisible
    private npe01__Contacts_and_Orgs_Settings__c getPaymentsSettings(){
        if (paymentsSettings == null) {
           paymentsSettings = UTIL_CustomSettingsFacade.getContactsSettings();
        }

        return paymentsSettings;
    }

    /*******************************************************************************************************
    * @description Returns true if Payments enabled is true on paymentsSettings
    * @return Boolean
    */
    public Boolean getIsPaymentsEnabled() {
        if (getPaymentsSettings() == null) {
            return false;
        }
        return getPaymentsSettings().npe01__Payments_Enabled__c == true;

    }

    /*******************************************************************************************************
    * @description Constructor for the wizard that initializes data structures
    */
    public PMT_PaymentWizard_CTRL() {
        this.redirect = this.removePaidPayments = false;
        this.isWizardEnabled = true;
        String wizardType = ApexPages.currentPage().getParameters().get('wtype');

        if (wizardType == 'writeoff'){
            setupWriteoffWizard();

        } else if (wizardType == 'payment'){
            setupPaymentWizard();
        }

        getPageValidationMessages();
    }

    /*******************************************************************************************************
    * @description initialize payment figures and make sure the opportunity has valid amounts
    */
    private void setupPaymentAmounts(Opportunity opp) {
        // Set default values
        this.writeoffPaymentCount = 1;
        this.amountWrittenOff = 0;
        this.invalidPaymentRecordCount = 0;

        if (opp.Amount == null || opp.Amount == 0) {
            isWizardEnabled = false;
        }

        Integer outstandingPaymentCount = 0;

        for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {

            if (payment.npe01__Paid__c == true) {
                if (payment.npe01__Written_Off__c == true) {
                    invalidPaymentRecordCount++;
                }
                continue;
            }

            if (payment.npe01__Written_Off__c == true) {
                if (payment.npe01__Payment_Amount__c != null) {
                    amountWrittenOff += payment.npe01__Payment_Amount__c;
                }
                continue;
            }

            outstandingPaymentCount++;
        }

        // if there are no payments outstanding then we set the count to 1 as
        // we will create a single payment for the new write off amount
        if (outstandingPaymentCount>0) {
            writeoffPaymentCount = outstandingPaymentCount;
        }

        if (invalidPaymentRecordCount > 0) {
            isWizardEnabled = false;
        }
    }


    /*******************************************************************************************************
    * @description initializes data for the Payment wizard
    * @return void
    */
    @TestVisible
    private void setupPaymentWizard() {
        String id = ApexPages.currentPage().getParameters().get('id');
        Opportunity[] o = Database.query(buildOpportunityQuery() + ' WHERE Id = :id');

        isWriteoffWizard = false;
        isScheduleWizard = true;

        if (o.isEmpty()) {
            haveAmount = false;
            return;
        }

        currentOpp = o[0];
        setupPaymentAmounts(currentOpp);

        haveAmount = (getAmountOutstanding() > 0);

        isClosedLost = currentOpp.isClosed && !currentOpp.isWon;
        samplePayment = new npe01__OppPayment__c();
        samplePayment.npe01__Scheduled_Date__c = System.today();
        numberOfPayments = 12;
        interval = 1;
        intervalUnit = 'Month';

    }

    /*******************************************************************************************************
    * @description initializes data for the Writeoff wizard
    * @return void
    */
    @TestVisible
    private void setupWriteoffWizard() {
        String id = ApexPages.currentPage().getParameters().get('id');
        Opportunity[] o = Database.query(buildOpportunityQuery() + ' WHERE Id = :id');

        isWriteoffWizard = true;
        isScheduleWizard = false;

        if (o.isEmpty()) {
            haveAmount = false;
            return;
        }

        currentOpp = o[0];
        setupPaymentAmounts(currentOpp);

        haveAmount = (getAmountOutstanding() > 0);
        writeoffPayment = new npe01__OppPayment__c();
        writeoffPayment.npe01__Payment_Amount__c = getAmountOutstanding();
        writeoffPayment.npe01__Written_Off__c = true;
        writeoffPayment.npe01__Opportunity__c = currentOpp.Id;
        writeoffPayment.npe01__Payment_Date__c = System.today();

        if (UserInfo.isMultiCurrencyOrganization()) {
            writeoffPayment.put('CurrencyIsoCode', (String) currentOpp.get('CurrencyIsoCode'));
        }

    }

    /*******************************************************************************************************
    * @description Creates an opportunity query with payment mapping and currency fields, filtered on id paramter.
    * @return string An opportunity query string.
    */
    private String buildOpportunityQuery() {
        // requery the Opportunity for all fields that we need.
        String query = 'SELECT name, amount, stagename, npe01__payments_made__c, ' +
            'npe01__amount_outstanding__c, description, closedate, npe01__Number_of_Payments__c, isClosed, isWon';

        // add any opportunity fields from payment field mappings
        for (String s : PMT_PaymentCreator.paymentMappings.keyset()) {
            npe01__Payment_Field_Mapping_Settings__c pfms = PMT_PaymentCreator.paymentMappings.get(s);

            if (!query.contains(pfms.npe01__Opportunity_Field__c.toLowerCase())) {
                query += ', ' + pfms.npe01__Opportunity_Field__c;
            }
        }
        query += ', (SELECT Id, npe01__Payment_Amount__c, ' +
            'npe01__Written_Off__c, npe01__Paid__c FROM npe01__OppPayment__r)';

        //if currencyiso field exists add it to query for use later
        if (Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode') != null) {
            query = query + ',CurrencyIsoCode';
        }

        query += ' FROM Opportunity';
        return query;
    }

    /*******************************************************************************************************
    * @description ActionMethod for the Calculate button that given the current opp outstanding balance,
    * creates the specified new payments to cover the amount.
    * @return PageReference null
    */
    public PageReference calculate() {
        if (!hasFeatureAccess) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.commonAccessErrorMessage));
            return null;
        }

        if (haveAmount || removePaidPayments) {
            // clear the list
            newPayments.clear();

            Decimal OppAmountFloat = getAmountOutstanding();
            if (removePaidPayments == true) {
                OppAmountFloat = currentOpp.Amount;
            }

            //divide the amount by the number of installments, and deal with the remainder
            Decimal paymentAmount = OppAmountFloat.divide(numberOfPayments, 2, system.roundingmode.FLOOR);
            Decimal remainder = OppAmountFloat - (paymentAmount * numberOfPayments);

            // get the start date
            Date nextDate;
            if (samplePayment.npe01__Scheduled_Date__c != null) {
                nextDate = samplePayment.npe01__Scheduled_Date__c;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.exceptionRequiredField + ' ' + System.Label.pmtWizardFirstPaymentDate));
                return null;
            }

            // Multicurrency support
            // James Melville 05/03/2011 Added to support multi-currency sfdc.  */
            // CurrencyIsoCode doesn't exist in non-multi-currency orgs
            SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
            SObjectField PaymentCurrencyField = Schema.sObjectType.npe01__OppPayment__c.fields.getMap().get('CurrencyIsoCode');

            for (Integer i=1; i <= numberOfPayments; i++) {

                // create the payment record
                Payment thisPayment = new Payment(i);
                // set values on the oppPayment object
                thisPayment.oppPayment.npe01__Opportunity__c = currentOpp.id;
                thisPayment.oppPayment.npe01__Scheduled_Date__c = nextDate;
                thisPayment.oppPayment.npe01__payment_method__c = samplePayment.npe01__payment_method__c;

                // add the extra pennies, if any
                if (remainder > 0) {
                    thisPayment.oppPayment.npe01__Payment_Amount__c = paymentAmount + .01;
                    remainder-=.01;
                } else {
                    thisPayment.oppPayment.npe01__Payment_Amount__c = paymentAmount;
                }

                //in multicurrency SFDC set the payment currency field to equal the opp currency
                if (PaymentCurrencyField != null && OppCurrencyField != null) {
                    thisPayment.oppPayment.put(PaymentCurrencyField, currentOpp.get(OppCurrencyField));
                }

                // modify new payment records with any Opp-Payment Mappings.
                if (PMT_PaymentCreator.paymentMappings.size() > 0) {
                    for (String s : PMT_PaymentCreator.paymentMappings.keyset()) {
                        npe01__Payment_Field_Mapping_Settings__c pfms = PMT_PaymentCreator.paymentMappings.get(s);
                        String x = pfms.npe01__Opportunity_Field__c;

                        if (currentOpp.get(x) != null) {
                            thisPayment.oppPayment.put(pfms.npe01__Payment_Field__c, currentOpp.get(x));
                        }
                    }
                }

                //put the payment in the list
                newPayments.add(thisPayment);

                //add the interval unit
                if (intervalUnit == 'Week') {
                    nextDate = nextDate.addDays(7 * interval);
                } else if (intervalUnit == 'Month') {
                    nextDate = nextDate.addMonths(interval);
                } else if (intervalUnit == 'Year') {
                    nextDate = nextDate.addYears(interval);
                }
            }

        }

        getPageValidationMessages();

        return null;
    }

    /*******************************************************************************************************
    * @description ActionMethod for the WriteOff button
    * @return PageReference null
    */
    public pageReference writeoff() {
    	Savepoint sp = Database.setSavepoint();
    	try {
	        List<npe01__OppPayment__c> paymentsToDelete = new List<npe01__OppPayment__c>();

	        for (npe01__OppPayment__c thisPayment : currentOpp.npe01__OppPayment__r){
	            if (thisPayment.npe01__Paid__c == false && thisPayment.npe01__Written_Off__c == false) {
	                paymentsToDelete.add(thisPayment);
	            }
	        }

	        if (!paymentsToDelete.isEmpty()) {
                delete paymentsToDelete;
            }

            insert writeoffPayment;

	        redirect = true;

    	} catch(Exception e) {
    		Database.rollback(sp);
    		ERR_Handler.processError(e, ERR_Handler_API.Context.PMT);
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    	}
        return null;
    }

    /*******************************************************************************************************
    * @description Verify data conditions and add any necessary page messages that need to be rendered.
    */
    public void getPageValidationMessages() {

        if (!getIsPaymentsEnabled()) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.WARNING,
                System.Label.pmtWizardPaymentsDisabledTitle,
                System.Label.pmtWizardPaymentsDisabled)
            );
            return;
        }

        if (currentOpp == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.pmtWizardMsgNoOppFound));
            return;
        }

        if (currentOpp.Amount == null || currentOpp.Amount == 0) {
            if (isScheduleWizard) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.pmtWizardScheduleNoAmount));
            } else if (isWriteoffWizard) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.pmtWizardWriteOffNoAmount));
            }
            return;
        }

        if (invalidPaymentRecordCount > 0) {
            if (isScheduleWizard) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.pmtWizardScheduleInvalidRecords));
            } else if (isWriteoffWizard) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.pmtWizardWriteOffInvalidRecords));
            }
            return;
        }

        if (isClosedLost == true) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.pmtWizardClosedLost));
        }

        if (!removePaidPayments && isScheduleWizard == true && haveAmount == false && isClosedLost == false) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.pmtWizardNoUnpaidAmount));
        } else if (!removePaidPayments && isWriteoffWizard == true && haveAmount == false) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.pmtWizardNoWriteoffAmount));
        }

    }

    /*******************************************************************************************************
    * @description Returns true if the user has permissions to access, create and delete npe01__oppPayment__c
    * and all relevant fields are both readable and modifiable
    * @return Boolean
    */
    private Boolean hasFeatureAccess() {
        if (hasRequiredObjectLevelAccess()) {
            return hasReadAccessTo(npe01__OppPayment__c.getSObjectType(), paymentFields())
                && hasModifyAccessTo(npe01__OppPayment__c.getSObjectType(), paymentFields())
                && hasReadAccessTo(Opportunity.getSObjectType(), opportunityReadFields())
                && hasModifyAccessTo(Opportunity.getSObjectType(), opportunityModifyFields());
        }
        return false;
    }

    private Boolean hasReadAccessTo(SObjectType sObjectType, Set<SObjectField> sObjectFields) {
        return permissions.canRead(sObjectType, sObjectFields);
    }
    private Boolean hasModifyAccessTo(SObjectType sObjectType, Set<SObjectField> sObjectFields) {
        return permissions.canUpdate(sObjectType, sObjectFields);
    }

    private Boolean hasRequiredObjectLevelAccess() {
        return hasRequiredPermissionsForPayment()
            && hasCreateAccessToOpportunity();
    }

    private Boolean hasRequiredPermissionsForPayment() {
        String paymentObject = String.valueOf(npe01__OppPayment__c.getSObjectType());
        return permissions.canCreate(npe01__OppPayment__c.getSObjectType())
            && UTIL_Permissions.canDelete(paymentObject, false);
    }

    private Boolean hasCreateAccessToOpportunity() {
        return permissions.canCreate(Opportunity.getSObjectType());
    }

    private Set<SObjectField> paymentFields() {
        return new Set<SObjectField>{
            npe01__OppPayment__c.fields.npe01__Check_Reference_Number__c,
            npe01__OppPayment__c.fields.npe01__Paid__c,
            npe01__OppPayment__c.fields.npe01__Payment_Amount__c,
            npe01__OppPayment__c.fields.npe01__Payment_Date__c,
            npe01__OppPayment__c.fields.npe01__Payment_Method__c,
            npe01__OppPayment__c.fields.npe01__Scheduled_Date__c,
            npe01__OppPayment__c.fields.npe01__Written_Off__c
        };
    }

    private Set<SObjectField> opportunityReadFields() {
        return new Set<SObjectField>{
            Opportunity.fields.Name,
            Opportunity.fields.Amount,
            Opportunity.fields.StageName,
            Opportunity.fields.npe01__Payments_Made__c,
            Opportunity.fields.npe01__Amount_Outstanding__c,
            Opportunity.fields.Description,
            Opportunity.fields.CloseDate,
            Opportunity.fields.npe01__Number_of_Payments__c,
            Opportunity.fields.IsClosed,
            Opportunity.fields.IsWon
        };
    }
    private Set<SObjectField> opportunityModifyFields() {
        return new Set<SObjectField>{
            Opportunity.fields.Amount
        };
    }


    /*******************************************************************************************************
    * @description list of items for picklist of the number of payments to be created
    * @return List<SelectOption>
    */
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        Decimal maxPayments;

        if (getPaymentsSettings().Max_Payments__c != null) {
            maxPayments = paymentsSettings.Max_Payments__c;
        } else {
            maxPayments = 12;
        }

        for (Integer i = 1; i <= maxPayments; i++) {
            String s = i.format();
            options.add(new SelectOption(s, s));
        }
        return options;
    }

    /*******************************************************************************************************
    * @description list of items for picklist of the interval between payments to be created
    * @return List<SelectOption>
    */
    public List<SelectOption> getIntervals() {
        List<SelectOption> options = new List<SelectOption>();

        for (Integer i = 1; i <= 12; i++) {
            String s = i.format();
            options.add(new SelectOption(s, s));
        }
        return options;
    }

    /*******************************************************************************************************
    * @description the unit of the interval
    */
    public String intervalUnit { get; set; }

    /*******************************************************************************************************
    * @description list of items for picklist of the interval unit between payments to be created
    * @return List<SelectOption>
    */
    public List<SelectOption> getIntervalUnits() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Week', System.Label.pmtWizardWeek));
        options.add(new SelectOption('Month', System.Label.pmtWizardMonth));
        options.add(new SelectOption('Year', System.Label.pmtWizardYear));
        return options;
    }

    /*******************************************************************************************************
    * @description holds the list of FieldSetMembers from the appropriate field set.
    * @return List<Schema.FieldSetMember>
    */
    public List<Schema.FieldSetMember> pmtFieldSet {
        get {
            if (pmtFieldSet == null) {
                pmtFieldSet = Schema.SObjectType.npe01__OppPayment__c.FieldSets.Payment_WizardFS.getFields();
            }
            return pmtFieldSet;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description ActionMethod for the Create Payments button
    * @return PageReference null
    */
    public PageReference createPayments() {
        if (!hasFeatureAccess) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.commonAccessErrorMessage));
            return null;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            List<npe01__oppPayment__c> paymentsToDelete = new List<npe01__OppPayment__c>();
            List<npe01__OppPayment__c> existingPayments = [
                SELECT Id, npe01__Paid__c, npe01__Written_Off__c
                FROM npe01__OppPayment__c
                WHERE npe01__Opportunity__c = :currentOpp.Id
            ];

            for (npe01__OppPayment__c payment : existingPayments) {
                if (payment.npe01__Paid__c == false && payment.npe01__Written_Off__c == false) {
                    paymentsToDelete.add(payment);
                    continue;
                }
                if (removePaidPayments) {
                    paymentsToDelete.add(payment);
                }
            }

            if (!paymentsToDelete.isEmpty()) {
                delete paymentsToDelete;
            }

	        // get the new payments into a list
	        npe01__oppPayment__c[] pmts = new npe01__oppPayment__c[0];
	        for (Payment p : newPayments) {
                pmts.add(p.oppPayment);
            }

	        // create the payment records
	        insert pmts;

	        redirect = true;

        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.PMT);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*******************************************************************************************************
    * @description ActionMethod for the Remove Paid Payments button, which sets the internal flag to
    * track this.
    * @return PageReference null
    */
    public pageReference removePaidPayments() {
        removePaidPayments = true;
        return null;
    }

    /**
     * @description Return the currency symbol appropriate for the current
     * user/org/record.  If the org is multi currency enabled, it will use the
     * currency iso code from the related record.  If the org is not multi
     * currency enabled, it will return the symbol for the currency of the org,
     * or the currency iso code if no symbol is known.
     *
     * @return String A currency symbol or currency ISO code
     */
    public String getCurrencySymbol() {
        if (currencySymbol == null) {
            if (UserInfo.isMultiCurrencyOrganization()) {
                currencySymbol = (String) currentOpp.get('CurrencyIsoCode') + ' ';
            } else {
                currencySymbol = UTIL_Currency.getInstance().getCurrencySymbol(UserInfo.getDefaultCurrency());
            }
        }
        return currencySymbol;
    }


     /**
     * @description Given an amount return the formatted currency String for that amount based on the User's locale
     * @param amount to format in Decimal
     * @return formatted String
     */
    @TestVisible
    private String formatCurrency(Decimal amount) {
        // Decimal.format is locale aware but it will truncate the decimals for .00 amounts
        // Adding thousandths of a cent to keep the decimal and then remove it before returning the result
        Decimal currencyAmt = Decimal.valueOf(Math.roundToLong(amount * 100)) / 100;
        String formattedCurrency = (currencyAmt.setScale(2) + (currencyAmt >= 0 ? 0.001 : -0.001)).format();
        formattedCurrency = formattedCurrency.left(formattedCurrency.length() - 1);

        return getCurrencySymbol() + formattedCurrency;

    }

    /*******************************************************************************************************
    * @description When Advanced Currency Management is enabled in an org, the packaged rollups and formula
    * from the Payment object will not work. This method will detect that scenario and return either the
    * value from the formula or calculate the Amount Outstanding from the payment records
    * track this.
    * @return Decimal amount outstanding
    */
    public Decimal getAmountOutstanding() {
        return PMT_PaymentCreator.getAmountOutstanding(this.currentOpp);
    }

    /*******************************************************************************************************
    * @description Returns a formatted text of the outstanding amount based on the user locale
    * @return String amount outstanding
    */
    public String getAmountOutstandingText() {
        return formatCurrency(getAmountOutstanding());
    }

    /*******************************************************************************************************
    * @description When Advanced Currency Management is enabled in an org, the packaged rollups and formula
    * from the Payment object will not work. This method will detect that scenario and return either the
    * value from the formula or calculate the Amount Outstanding from the payment records
    * track this.
    * @return String total paid payments
    */
    public String getTotalPaymentsMade() {
        return formatCurrency(PMT_PaymentCreator.getPaymentsMade(this.currentOpp));
    }

    /*******************************************************************************************************
    * @description Returns the formatted text of the amount written off
    * @return String total written off payments
    */
    public String getTotalWrittenOff() {
        return formatCurrency(amountWrittenOff);
    }

    /*******************************************************************************************************
    * @description Returns the formatted text of the amount Opportunity
    * @return String opportunity amount
    */
    public String getOppAmount() {
        if (currentOpp.Amount != null) {
            return formatCurrency(currentOpp.Amount);
        }
        return '';
    }
}
