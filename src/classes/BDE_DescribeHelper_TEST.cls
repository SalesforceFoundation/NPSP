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
        
        Schema.DescribeSObjectResult res = BDE_DescribeHelper_UTIL.getObjectDescribe('Contact');     
        system.assertEquals(res.getName(), 'Contact');
        s = BDE_DescribeHelper_UTIL.getObjectLabel('Contact');
        system.assertEquals (s, res.getLabel());

        account a = new account(name='Test');
        insert a;
        system.assert(BDE_DescribeHelper_UTIL.isObjectIdThisType(a.id, 'Account'));
        
        s = BDE_DescribeHelper_UTIL.getFieldLabel('Account', 'LastModifiedDate');
        integer calls = limits.getfieldsdescribes();
        
        Schema.DescribeFieldResult fr = BDE_DescribeHelper_UTIL.getFieldDescribe('Account', 'CreatedDate');      
        s = BDE_DescribeHelper_UTIL.getFieldLabel('Account', 'CreatedDate');
        system.assertEquals (s, fr.getLabel());

        Map<String, Schema.DescribeFieldResult> afd = BDE_DescribeHelper_UTIL.getAllFieldsDescribe('Account');
        system.assertEquals ('BillingCity', afd.get('billingcity').getName());
        afd = BDE_DescribeHelper_UTIL.getAllFieldsDescribe('Account');

        SObject acctObj = BDE_DescribeHelper_UTIL.getPrototypeObject('Account');
        // should be able to cast to account
        account acct = (account)(acctObj);

        // another call should not use another describe
        system.assertEquals(limits.getfieldsdescribes(), calls);
        
        s = BDE_DescribeHelper_UTIL.getFieldType('Account', 'CreatedDate');
        system.assertEquals('DATETIME', s);
        
        try {
            s = BDE_DescribeHelper_UTIL.getObjectLabel('sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (exception e) {
            system.assertEquals('Invalid object name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        } 
        try {
            s = BDE_DescribeHelper_UTIL.getFieldLabel('Opportunity', 'sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (exception e) {
            system.assertEquals('Invalid field name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        } 
    } 
}