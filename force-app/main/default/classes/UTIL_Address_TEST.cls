/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Utilities
* @description Tests specific to Address utility methods.
*/

@isTest(IsParallel=true)
public with sharing class UTIL_Address_TEST {

    /***
    * @description Verifies that addresses which should not be altered are not.
    */
    @isTest
    private static void shouldEqualInputAddress() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();

        accounts.add(new Account());
        accounts.add(new Account(BillingStreet = '\r\n'));
        accounts.add(new Account(BillingStreet = '\r\ntext\n'));
        accounts.add(new Account(BillingStreet = 'one line'));
        accounts.add(new Account(BillingStreet = '\n\r'));

        contacts.add(new Contact());
        contacts.add(new Contact(MailingStreet = '\r\n'));
        contacts.add(new Contact(MailingStreet = '\r\ntext\n'));
        contacts.add(new Contact(MailingStreet = 'one line'));
        contacts.add(new Contact(MailingStreet = '\n\r'));

        List<Account> clonedAccounts = accounts.deepClone();
        List<Contact> clonedContacts = contacts.deepClone();

        for (Account acc : clonedAccounts) {
            UTIL_Address.normalizeLineBreak(acc);
        }
        for (Contact con : clonedContacts) {
            UTIL_Address.normalizeLineBreak(con);
        }

        for (Integer i; i < 4; i++) {
            System.assertEquals(accounts[i].BillingStreet, clonedAccounts[i].BillingStreet, 'Normalized street address should be equal to input');
            System.assertEquals(contacts[i].MailingStreet, clonedContacts[i].MailingStreet, 'Normalized street address should be equal to input');
        }
    }

    /***
    * @description Verifies that addresses which should be altered are.
    */
    @isTest
    private static void shouldReplaceLineBreakWithCRLF() {
        final Account originalAccount = new Account(BillingStreet = '\n');
        final Contact originalContact = new Contact(MailingStreet = '\n');

        Account newAccount = originalAccount.clone();
        Contact newContact = originalContact.clone();

        UTIL_Address.normalizeLineBreak(newAccount);
        UTIL_Address.normalizeLineBreak(newContact);

        System.assertNotEquals(originalAccount.BillingStreet, newAccount.BillingStreet, 'Normalized street address should not be equal to input');
        System.assertNotEquals(originalContact.MailingStreet, newContact.MailingStreet, 'Normalized street address should not be equal to input');
        System.assertEquals(true, newAccount.BillingStreet.contains('\r\n'), 'Normalized street address should contain CRLF');
        System.assertEquals(true, newContact.MailingStreet.contains('\r\n'), 'Normalized street address should contain CRLF');
    }
}
