/*
    Copyright (c) 2017 Salesforce.org
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
* @group Utilities
* @description Unit tests for UTIL_CascadeDeleteLookups_TDTM class
*/
@isTest
private class UTIL_CascadeDeleteLookups_TDTM_TEST {

    /**************************************************************************************************************************
    @description Test of the function that returns the Plain Text. The text contains a list of the child records
    verify: The text returned by the function has the Plain Text
    ***************************************************************************************************************************/   
    private static testMethod void testGetPlainTextChildRecords() {
        List<Account> testAccounts = new List<Account>{
            new Account(name='TEST_ACCOUNT_1'),
            new Account(name='TEST_ACCOUNT_2')
        };
        insert testAccounts;

        Map<Id,Account> testAccountsMap = new Map<Id,Account>(testAccounts);

        UTIL_CascadeDeleteLookups_TDTM cascadeDeleteLookupsTDTM = new CascadeDeleteLookupsMock();
        String cascadeDeleteChildRecordPlainText = cascadeDeleteLookupsTDTM.getPlainTextChildRecords(testAccountsMap, new List<Id>(testAccountsMap.keySet()));

        List<String> expectedChildRecordsPlainText = new List<String>();
        for (Account testAccount :testAccounts) {
            expectedChildRecordsPlainText.add(testAccount.Name);
        }

        System.assertEquals(String.join(expectedChildRecordsPlainText,', '), cascadeDeleteChildRecordPlainText);
    }

    /**************************************************************************************************************************
    @description Test of the function that returns the HTML text. The text contains a list of the child records
    verify: The text returned by the function has the HTML Text
    ***************************************************************************************************************************/   
    private static testMethod void testGetHTMLTextChildRecords() {
        List<Account> testAccounts = new List<Account>{
            new Account(name='TEST_ACCOUNT_1'),
            new Account(name='TEST_ACCOUNT_2')
        };
        insert testAccounts;

        Map<Id,Account> testAccountsMap = new Map<Id,Account>(testAccounts);

        UTIL_CascadeDeleteLookups_TDTM cascadeDeleteLookupsTDTM = new CascadeDeleteLookupsMock();
        String cascadeDeleteChildRecordHTMLText = cascadeDeleteLookupsTDTM.getHTMLTextChildRecords(testAccountsMap, new List<Id>(testAccountsMap.keySet()));

        List<String> expectedChildRecordsHTMLText = new List<String>();
        expectedChildRecordsHTMLText.add('<ul>');
        for (Account testAccount :testAccounts) {
            expectedChildRecordsHTMLText.add(String.format(
                UTIL_CascadeDeleteLookups_TDTM.HTML_TEXT_CHILD_RECORDS_FORMAT, 
                new List<String>{testAccount.Id, testAccount.Name}
            ));
        }
        expectedChildRecordsHTMLText.add('</ul>');

        System.assertEquals(String.join(expectedChildRecordsHTMLText,''), cascadeDeleteChildRecordHTMLText);
    }

    /*******************************************************************************************************
    * @description Mock Class that extends the UTIL_CascadeDeleteLookups_TDTM. 
    * UTIL_CascadeDeleteLookups_TDTM is an abstract class, so we need a concrete class in order to do the test. 
    ********************************************************************************************************/
    class CascadeDeleteLookupsMock extends UTIL_CascadeDeleteLookups_TDTM {}
}