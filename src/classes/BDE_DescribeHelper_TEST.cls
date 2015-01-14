/*
Copyright (c) 2011, salesforce.com foundation, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com foundation. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
/**
* @author Team Kick Ass; Veronica Waters, Evan Callahan, Derek Dsouza, Mike Fullmore
* @date 04/27/2011
* @description test class for apex describe calls used in batch entry
*/
@isTest
public with sharing class BDE_DescribeHelper_TEST {

    // TEST
    static testmethod void testDescribe() {
        
        string s;
        
        Schema.DescribeSObjectResult res = UTIL_Describe.getObjectDescribe('Contact');     
        system.assertEquals(res.getName(), 'Contact');
        s = UTIL_Describe.getObjectLabel('Contact');
        system.assertEquals (s, res.getLabel());

        account a = new account(name='Test');
        insert a;
        system.assert(UTIL_Describe.isObjectIdThisType(a.id, 'Account'));
        
        s = UTIL_Describe.getFieldLabel('Account', 'LastModifiedDate');
        integer calls = limits.getfieldsdescribes();
        
        Schema.DescribeFieldResult fr = UTIL_Describe.getFieldDescribe('Account', 'CreatedDate');      
        s = UTIL_Describe.getFieldLabel('Account', 'CreatedDate');
        system.assertEquals (s, fr.getLabel());

        Map<String, Schema.DescribeFieldResult> afd = UTIL_Describe.getAllFieldsDescribe('Account');
        system.assertEquals ('BillingCity', afd.get('billingcity').getName());
        afd = UTIL_Describe.getAllFieldsDescribe('Account');

        SObject acctObj = UTIL_Describe.getPrototypeObject('Account');
        // should be able to cast to account
        account acct = (account)(acctObj);

        // another call should not use another describe
        system.assertEquals(limits.getfieldsdescribes(), calls);
        
        s = UTIL_Describe.getFieldType('Account', 'CreatedDate');
        system.assertEquals('DATETIME', s);
        
        try {
            s = UTIL_Describe.getObjectLabel('sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (exception e) {
            system.assertEquals('Invalid object name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        } 
        try {
            s = UTIL_Describe.getFieldLabel('Opportunity', 'sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (exception e) {
            system.assertEquals('Invalid field name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        } 
    } 
}