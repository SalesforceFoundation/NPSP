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
* @description Interface that classes that provide Household Naming must implement.
*/
public Interface HH_INaming {

    // Methods to get the appropriate name/greeting for the passed in list of Contacts from a single Household.
    // Contacts who have set their npo02__Naming_Exclusions__c field to be excluded from the name/greeting, are not included in the list of Contacts.
    // If the list of Contacts is empty, return the appropriate 'anonymous' name/greeting.
    string getHouseholdName(list<Contact> listCon);
    string getHouseholdFormalGreeting(list<Contact> listCon);
    string getHouseholdInformalGreeting(list<Contact> listCon);
    
    // for the Settings page, get the formatted name for the list of Contacts.
    // hns holds an in-memory Household Naming Settings object, and strField is one of:
    // Household_Name_Format__c, Formal_Greeting_Format__c, or Informal_Greeting_Format__c.
    string getExampleName(Household_Naming_Settings__c hns, string strField, list<Contact> listCon);
}