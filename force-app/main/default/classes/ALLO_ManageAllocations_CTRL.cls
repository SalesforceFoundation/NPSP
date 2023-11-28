/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Controller for the Manage Allocations page.
*/
public with sharing class ALLO_ManageAllocations_CTRL {

    /** @description Parent of the allocation. An opportunity, payment, campaign, or recurring donation. */
    public AllocationParent parent {get;set;}
    /** @description The current list of allocations we're managing, as displayed on the page.*/
    public list<Allocation__c> allocations {get;set;}
    /** @description If defaults are enabled, the default allocation is here, and not in listAllo. */
    public Allocation__c defaultAllocation {get;set;}

    /**
     * @description True if the current user has Read access to the relevant parent object
     * for the current allocations.
     */
    public Boolean hasAccess {
        get { return hasAccess == null ? false : hasAccess; }
        set;
    }

    private Boolean canCreate {
        get {
            if (this.canCreate == null) {
                this.canCreate = this.checkCreate();
            }

            return this.canCreate;
        }
        set;
    }

    private Boolean canDelete {
        get {
            if (this.canDelete == null) {
                this.canDelete = this.checkDelete();
            }

            return this.canDelete;
        }
        set;
    }

    private Boolean canUpdate {
        get {
            if (this.canUpdate == null) {
                this.canUpdate = this.checkUpdate();
            }

            return this.canUpdate;
        }
        set;
    }

    private Set<SObjectField> getFieldsForFLSCheck() {
        Set<SObjectField> objectFields = new Set<SObjectField>();

        objectFields.add(Allocation__c.Amount__c.getDescribe().getSobjectField());
        objectFields.add(Allocation__c.Percent__c.getDescribe().getSobjectField());
        objectFields.add(Allocation__c.General_Accounting_Unit__c.getDescribe().getSobjectField());

        for(Schema.FieldSetMember additionalField : additionalAllocationFields) {
            objectFields.add(additionalField.getSObjectField());
        }

        return objectFields;
    }

    private Boolean checkCreate() {
        return UTIL_Permissions.getInstance().canCreate(Allocation__c.SObjectType, fieldsForFLSCheck);
    }

    private Boolean checkDelete() {
        return UTIL_Permissions.getInstance().canDelete(Allocation__c.SObjectType);
    }

    private Boolean checkUpdate() {
        return UTIL_Permissions.getInstance().canUpdate(Allocation__c.SObjectType, fieldsForFLSCheck);
    }

    public String getNamespace() {
        return UTIL_Namespace.getComponentNamespace();
    }

    /**
    * @description Manage Allocation additional fields to be edited 
    */
    public List<Schema.FieldSetMember> additionalAllocationFields {
        get {
            if (additionalAllocationFields == null) {
                additionalAllocationFields = getAdditionalAllocationFields();
            }
            return additionalAllocationFields;
        }
        set;
    }

    private Set<SObjectField> fieldsForFLSCheck {
        get {
            if (fieldsForFLSCheck == null) {
                fieldsForFLSCheck = getFieldsForFLSCheck();
            }
            return fieldsForFLSCheck;
        }
        set;
    }

    /** @description List of allocations to delete when the user clicks Save.*/
    public list<Allocation__c> allocationsToBeDeleted = new list<Allocation__c>();
    /** @description The id of the parent object; Opportunity, Campaign, or Recurring Donation.*/
    public Id parentId {get;set;}
    /** @description The allocations settings object. */
    public Allocations_Settings__c settings {
        get {
            if (settings==null) {
                settings = UTIL_CustomSettingsFacade.getAllocationsSettings();
            }
            return settings;
        }
        set;
    }

    /**
    * @description Determine if the page is loading
    */
    public Boolean isLoading {
        get {
            if (isLoading == null) {
                isLoading = true;
            }
            return isLoading;
        }set;
    }

    /**
    * description After successful save set to true to redirect page 
    */
    public Boolean redirect {get;set;}

    /** @description The page title based on which type of allocation we're using. */
    public string pageTitle {get;set;}

    public Boolean isSupportedObject() {
        Set<sObjectType> allowedParentSObjectType = new Set<sObjectType> {
            Opportunity.sObjectType,
            Campaign.sObjectType,
            npe03__Recurring_Donation__c.sObjectType,
            npe01__OppPayment__c.sObjectType
        };
        return allowedParentSObjectType.contains(parentId.getSobjectType());
    }

    /** @description Used to disable the save button in the visualforce page */
    public Boolean getIsSaveDisabled() {
        return !isSupportedObject() || (parent.isOpportunity() && parent.getAmount() == 0) || isLoading;
    }

    /** @description Row number sent back by page for add and delete row methods.*/
    public integer rowNumber {get;set;}

    /**
     * @description The currency symbol or ISO code of the related record or
     * org default
     */
    @TestVisible
    private String currencySymbol;

    /**
     * @description Query of the Parent Records CurrencyIsoCode value to use when retrieving the currency symbol.
     */
    @TestVisible
    private String parentCurrencyCode;

    /**
    * @description Default Allocation__c fields to be queried 
    */
    private Set<String> defaultAllocationFields = new Set<String> {
        'Id',
        'Name',
        'Amount__c',
        'Percent__c',
        'General_Accounting_Unit__c'
    };

    @TestVisible
    private ALLO_ManageAllocations_CTRL() {}

    public ALLO_ManageAllocations_CTRL(ApexPages.StandardSetController ssc) {
        parentId = ApexPages.currentPage().getParameters().get('id');
        hasAccess = canUserRead(parentId.getSobjectType());

        if (hasAccess && isSupportedObject()) {
            parent = new AllocationParent(parentId);
            pageTitle = pageTitlesBySObjectType.get(parent.objectType());
            parentCurrencyCode = parent.currencyCode();

            setupAllocations();
            verifyPageLoadConditions();
        }

        isLoading = false;
    }

    /**
     * @description Checks that current user in context has read access to the provided sObjectType.
     * @param parentSObjectType The allocation's parent object (Campaign, Opportunity, Payment, Recurring Donation).
     * @return Boolean True if the user has Read access to the parent object.
     */
    private Boolean canUserRead(SObjectType parentSObjectType) {
        UTIL_Permissions permissions = UTIL_Permissions.getInstance();
        return permissions.canRead(parentSObjectType);
    }

    /**
     * @description Map of custom labels keyed by a supported SObjectType used to populate the
     * visualforce page title.
     */
    private Map<SObjectType, String> pageTitlesBySObjectType = new Map<SObjectType, String> {
        Opportunity.SObjectType => System.Label.alloManageOppAllocations,
        Campaign.SObjectType => System.Label.alloManageCampaignAllocations,
        npe03__Recurring_Donation__c.SObjectType => System.Label.alloManageRecurringDonationAllocations,
        npe01__OppPayment__c.SObjectType => System.Label.alloManagePaymentAllocations
    };

    /**
     * @description Sets values for various allocation related member variables and adds a
     * default GAU and/or a default allocation if necessary.
     */
    private void setupAllocations() {
        defaultAllocation = new Allocation__c();
        allocations = getAllocations(parentId);

        Boolean shouldSetDefaultGAU = settings.Default_Allocations_Enabled__c && (parent.hasAmountField());
        if (shouldSetDefaultGAU) {
            setDefaultGAU();
        }

        if (allocations.isEmpty()) {
            addRow();
        }
    }

    /**
     * @description Finds a matching default GAU and updates relevant member variables as needed.
     */
    private void setDefaultGAU() {
        for (integer i=0; i<allocations.size(); i++) {
            Boolean isDefaultGAU = allocations[i].General_Accounting_Unit__c == settings.Default__c;
            if (isDefaultGAU) {
                defaultAllocation = allocations[i];
                allocations.remove(i);
                break;
            }
        }
    }

    /*******************************************************************************************************
    * @description Verify data conditions and add any necessary page messages that need to be rendered on load.
    */
    public void verifyPageLoadConditions() {
        if (!isSupportedObject()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.alloObjectUnsupported));
        } else if (hasAccess && parent.isOpportunityWithZeroAmount()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.alloCantAllocateNothing));
        }
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
        if (currencySymbol == null && parentCurrencyCode != null) {
            currencySymbol = UTIL_Currency.getInstance().getCurrencySymbol(parentCurrencyCode);
        }
        return currencySymbol;
    }

    /** @description Adds an empty row to the bottom of the list and refreshes the page.*/
    public PageReference addRow() {
        Allocation__c allocation = new Allocation__c();
        allocation.put(parent.getAllocationLookupApiName(), parentId);
        // always add to last row
        allocations.add(allocation);
        
        return null;
    }

    /** @description Removes a row from the page, and adds to the list for deletion once the user saves.*/
    public PageReference delRow() {
        Boolean hasId = allocations[rowNumber].id != null;

        //add to deletion list if the allocation has an id
        if (hasId) {
            if (!isAllocationDeletable()) {
                addDelExceptionMessage();
                return null;
            }
            allocationsToBeDeleted.add(allocations[rowNumber]);
        }
        allocations.remove(rowNumber);

        return null;
    }

    /** 
    * @description Saves changes and returns user to parent object detail page.
    * @return PageReference
    */
    public PageReference saveClose() {
        isLoading = true;

        list<Allocation__c> listAlloForInsert = new list<Allocation__c>();
        list<Allocation__c> listAlloForUpdate = new list<Allocation__c>();

        //split into insert and update cases so we can reset recursion flags for each operation
        for (Allocation__c allocation : allocations) {
            if (allocation.Id != null) {
                listAlloForUpdate.add(allocation);
            }
            else {
                listAlloForInsert.add(allocation);
            }
        }

        Savepoint sp = Database.setSavepoint(); 
        try {
            if (!allocationsToBeDeleted.isEmpty()) {
                if (!canDelete) {
                    UTIL_AuraEnabledCommon.throwAuraHandledException(System.Label.commonAccessErrorMessage);
                }
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);
                delete allocationsToBeDeleted;

                //allow user to delete all GAUs and save with one empty GAU
                if (allocations.size() == 1
                    && allocations[0].General_Accounting_Unit__c == null
                    && allocations[0].Amount__c == null
                    && allocations[0].Percent__c == null
                ) {
                    redirect = true;
                }
            }

            if (!listAlloForUpdate.isEmpty()) {
                if (!canUpdate) {
                    UTIL_AuraEnabledCommon.throwAuraHandledException(System.Label.commonAccessErrorMessage);
                }
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);
                update listAlloForUpdate;
            }

            if (!listAlloForInsert.isEmpty()) {
                if (!canCreate) {
                    UTIL_AuraEnabledCommon.throwAuraHandledException(System.Label.commonAccessErrorMessage);
                }
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);
                insert listAlloForInsert;
            }
            redirect = true;

        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
            isLoading = false;
        }

        return null;
        
    }

    /** @description Discards all changes and returns user to parent object detail page.*/
    public PageReference cancel() {
        PageReference source = new PageReference('/' + parentId);
        return source;
    }

    /** @description Returns the decimal separator character in use for the Users current Locale setting */
    public String getDecimalSeparator() {
        return (1.5).format().subString(1,2);
    }

    /** @description Returns the thousands separator character in use for the Users current Locale setting */
    public String getThousandsSeparator() {
        return (1000).format().subString(1,2);
    }

    private Boolean isAllocationDeletable() {
        return UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrTokenNSPrefix('Allocation__c')).isDeletable();
    }

    private void addDelExceptionMessage() {
        ApexPages.addMessage(
            new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    String.format(
                        System.Label.commonAccessErrorMessage,
                        new String[]{UTIL_Describe.getObjectLabel(UTIL_Namespace.StrTokenNSPrefix('Allocation__c'))})));
    
    }

    /**
    * @description Contrcut and query Recurring Donation's children Allocations
    * @param parentId Recurring Donation Id
    * @return List<Allocation__c> 
    */
    @TestVisible
    private List<Allocation__c> getAllocations(Id parentId) {
        Set<String> queryFields = new Set<String>();
        queryFields.addAll(defaultAllocationFields);

        for(Schema.FieldSetMember additionalField : additionalAllocationFields) {
            queryFields.add(additionalField.getFieldPath());
        }

        String soql = new UTIL_Query()
            .withFrom(Allocation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere(
                'Opportunity__c = :parentId ' +
                'OR Campaign__c = :parentId ' +
                'OR Recurring_Donation__c = :parentId ' +
                'OR Payment__c = :parentId '
            )
            .build();

        return Database.query(soql);
    }

    /**
    * @description Retrieve Manage Allocations Table Fields Field Set and exclude any parent record field and rich text area
    * @return List<Schema.FieldSetMember>
    */
    @TestVisible
    private List<Schema.FieldSetMember> getAdditionalAllocationFields() {
        List<Schema.FieldSetMember> qualifiedFields = new List<Schema.FieldSetMember>();

        List<Schema.FieldSetMember> fieldSetFields = 
            Schema.SObjectType.Allocation__c.fieldSets.ManageAllocationsAdditionalFields.getFields();

        for (Schema.FieldSetMember field : fieldSetFields) {
            if (field.getFieldPath().contains('__r.')
                || (field.getType() == Schema.DisplayType.TEXTAREA && field.getSObjectField().getDescribe().isHtmlFormatted())) {
                continue;
            }
            qualifiedFields.add(field);
        }

        return qualifiedFields;
    }
}