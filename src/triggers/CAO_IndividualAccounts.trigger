/*
    Copyright (c) 2009, Salesforce.com Foundation
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
trigger CAO_IndividualAccounts on Contact (before insert, before update, after insert, after update,after delete) {

    npe01__Contacts_and_Orgs_Settings__c cos = CAO_Constants.getContactsSettings();
    
    if (true /* DJH:UNDONE !cos.npe01__DISABLE_IndividualAccounts_trigger__c */){
        if(Trigger.isInsert && Trigger.isBefore){
            CAO_IndividualAccounts process = new CAO_IndividualAccounts(Trigger.new, Trigger.old, CAO_Constants.triggerAction.beforeInsert);
        }
        if(Trigger.isUpdate && Trigger.isBefore){
            CAO_IndividualAccounts process = new CAO_IndividualAccounts(Trigger.new, Trigger.old, CAO_Constants.triggerAction.beforeUpdate);
        }
        if( Trigger.isAfter && Trigger.isInsert ){
            //requery to get correct Account values
            Contact[] newContacts = [select id,npe01__SystemAccountProcessor__c,npe01__Private__c,AccountId,Account.npe01__SYSTEMIsIndividual__c,Account.Name,firstname, lastname from Contact where Id IN :trigger.New];
            
            CAO_IndividualAccounts process = new CAO_IndividualAccounts(newContacts, Trigger.old, CAO_Constants.triggerAction.afterInsert);
        }
        if( Trigger.isAfter && Trigger.isUpdate ){
           //requery to get correct Account values
           Contact[] newContacts = [select id,npe01__SystemAccountProcessor__c,npe01__Private__c,AccountId,Account.npe01__SYSTEMIsIndividual__c,npe01__Organization_Type__c,Account.Name,firstname, lastname,MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, Phone, Fax from Contact where Id IN :trigger.New];
        
            CAO_IndividualAccounts process = new CAO_IndividualAccounts(newContacts, Trigger.old, CAO_Constants.triggerAction.afterUpdate);
        }
        if( Trigger.isAfter && Trigger.isDelete ){
            CAO_IndividualAccounts process = new CAO_IndividualAccounts(Trigger.new, Trigger.old, CAO_Constants.triggerAction.afterDelete);
        }
    }        
}