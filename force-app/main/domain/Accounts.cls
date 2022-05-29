/*
 *
 *     Copyright (c) 2022, Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 * /
 */
/**
* @author Salesforce.org
* @description Accounts domain class
*/
public inherited sharing class Accounts extends fflib_SObjects2 implements IAccounts {

    public static IAccounts newInstance(List<Account> records)
    {
        return (IAccounts) Application.Domain.newInstance(records);
    }

    public Accounts(List<SObject> records) {
        super(records, Account.SObjectType);
    }

    public IAccounts needsTypeAndIndividualFieldsSet() {
        return new Accounts ((List<SObject>) getRecords (
            isMissingAccountTypeCriteria()
                .addOrCriteria(isNotIndividualAccountCriteria())
        ));
    }

    private fflib_Criteria isMissingAccountTypeCriteria() {
        return new fflib_Criteria()
            .equalTo(Account.npe01__SYSTEM_AccountType__c, null);
    }

    private fflib_Criteria isNotIndividualAccountCriteria() {
        return new fflib_Criteria()
                .notEqualTo(Account.npe01__SYSTEMIsIndividual__c, true);
    }

    public List<SObject> getAccounts() {
        return (List<SObject>) getRecords();
    }

    public class Constructor implements fflib_IDomainConstructor
    {
        public fflib_IDomain construct(List<Object> records)
        {
            return (fflib_IDomain) new Accounts((List<SObject>) records);
        }
    }
}