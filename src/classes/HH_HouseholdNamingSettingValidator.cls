/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Households
* @description Validates Household Naming Settings fields. Collects errors (if any) in the Notification.
*/
public with sharing class HH_HouseholdNamingSettingValidator {

    /*********************************************************************************************************
    * @description List of example Contacts
    */
    private static Contact[] exampleContacts {
        get {
            return exampleContacts = exampleContacts == null
                ? buildExampleContacts()
                : exampleContacts;
        }
        set;
    }

    /*********************************************************************************************************
    * @description The validator's constructor 
    */
    public HH_HouseholdNamingSettingValidator() {
    }

    /*********************************************************************************************************
    * @description Validates Household Naming Settings
    * @param settings Household Naming Settings
    * @return Notification Contains reported validation errors
    */
    public Notification validate(Household_Naming_Settings__c settings) {
        Notification notification = new Notification();

        HH_INaming hhNaming = validateImplementingClass(settings, notification);

        validateFormatFields(settings, hhNaming, notification);

        return notification;
    }

    /*********************************************************************************************************
    * @description Validates Household Naming Settings Implementing Class. Returns its instance if valid. 
    * @param settings Household Naming Settings
    * @param notification Contains reported validation errors
    * @return HH_INaming An instance of a valid Implementing Class; null if the instance cannot be created.
    */
    public HH_INaming validateImplementingClass(Household_Naming_Settings__c settings, Notification notification) {
        String className = settings.Implementing_Class__c;  
        className = String.isBlank(className) ? 'HH_NameSpec' : className; 

        Type classType = Type.forName(className);
        if (classType == null) {   
            notification.addError(Label.stgErrorInvalidClass);
            return null;  
        }

        Object classInstance = classType.newInstance();
        if (classInstance instanceof HH_INaming) {
            return (HH_INaming) classInstance;
        } 
        
        notification.addError(Label.stgErrorINaming);
        return null;  
    }

    /*********************************************************************************************************
    * @description Validates Household Naming Settings format fields
    * @param settings Household Naming Settings
    * @param hhNaming An instance of the settings' Implementing Class
    * @param notification Contains reported validation errors
    * @return void
    */
    private void validateFormatFields(Household_Naming_Settings__c settings, HH_INaming hhNaming, Notification notification) {
        if (hhNaming == null) {
            return;
        }

        validateFormat('Household_Name_Format__c', settings, hhNaming, notification);
        validateFormat('Formal_Greeting_Format__c', settings, hhNaming, notification);
        validateFormat('Informal_Greeting_Format__c', settings, hhNaming, notification);
    }

    /*********************************************************************************************************
    * @description Validates format of a field
    * @param fieldName Household Naming Settings field Name
    * @param settings Household Naming Settings
    * @param hhNaming An instance of the settings' Implementing Class
    * @param notification Contains reported validation errors
    * @return void
    */
    private void validateFormat(
        String fieldName, Household_Naming_Settings__c settings,
        HH_INaming hhNaming, Notification notification
    ) {
        String fieldLabel = UTIL_Describe.getFieldLabel(
            UTIL_Namespace.StrTokenNSPrefix('Household_Naming_Settings__c'), 
            UTIL_Namespace.StrTokenNSPrefix(fieldName)
        );
        
        try {
            hhNaming.getExampleName(settings, fieldName, exampleContacts);

        } catch (Exception ex) {
            notification.addError(
                String.format(Label.stgErrorInvalidNameFormat, new String[]{ fieldLabel, ex.getMessage() })
            );       
        } 
    } 

    /*********************************************************************************************************
    * @description Builds list of example Contacts used to validate settings' format fields
    * @return Contact[]
    */
    private static Contact[] buildExampleContacts() {
        Account acc = new Account(
            Name = 'Sample',
            BillingCity = 'Seattle'
        );

        Contact c1 = new Contact();
        c1.Account = acc;
        c1.FirstName = 'Sam';
        c1.LastName = 'Smith';
        c1.Salutation = 'Dr.';
        c1.MailingCity = 'Seattle';

        acc.npe01__One2OneContact__r = c1;
        
        Contact c2 = new Contact();
        c2.Account = acc;
        c2.FirstName = 'Sally';
        c2.LastName = 'Smith';
        c2.Salutation = 'Mrs.';
        c2.MailingCity = 'Seattle';
        
        return new Contact[] { c1, c2 };
    }

    /*********************************************************************************************************
    * @description Notification class containing Household Naming Settings validation errors 
    */
    public class Notification {
        /*********************************************************************************************************
        * @description Contains validation errors 
        */
        private String[] errors = new String[0];
        
        /*********************************************************************************************************
        * @description Adds specified errors into the list of all errors
        * @return Notification The instance of itself
        */
        public Notification addErrors(String[] errors) {
            if (errors != null) {
                this.errors.addAll(errors);
            }

            return this;
        }

        /*********************************************************************************************************
        * @description Adds specified error into the list of all errors
        * @return Notification The instance of itself
        */
        public Notification addError(String error) {
            if (!String.isBlank(error)) {
                errors.add(error);
            }

            return this;
        }

        /*********************************************************************************************************
        * @description Returns errors
        * @return String[] List of errors
        */
        public String[] getErrors() {
            return errors.clone();
        }

        /*********************************************************************************************************
        * @description Specifies if the Notification contains no error
        * @return Boolean True if there are no errors, false otherwise
        */
        public Boolean isSuccess() {
            return errors.isEmpty();
        }
    }
}