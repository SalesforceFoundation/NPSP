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
* @description Domain class for One-to-one accounts.
 * THIS CLASS SHOULD NOT CONTAIN ANY PUBLIC CONSTRUCTORS. To retrieve an instance of this domain, use the public static
 * newInstance() method to retrieve the domain instance from the domain factory. Logic is used in the inner
 * Constructor class to ensure only one-to-one records are contained in the instanced domain collection.
*/
public with sharing class OneToOneAccounts extends fflib_SObjects2 implements IOneToOneAccounts {

    @TestVisible
    private OneToOneAccounts(List<SObject> records) {
        super(records, Account.SObjectType);
    }

    public static IHouseholds newInstance(List<SObject> records) {
        Application.Domain.replaceWith(Account.SObjectType, IOneToOneAccounts.class, OneToOneAccounts.Constructor.class);
        return (IHouseholds) Application.Domain.newInstance(records, Account.SObjectType);
    }

    public IOneToOneAccounts getOneToOneAccounts() {
        return (IOneToOneAccounts) getRecords(
            isOneToOneAccount()
        );
    }

    private fflib_Criteria isOneToOneAccount() {
        return new fflib_Criteria()
                .andCriteria()
                .notEqualTo(Account.RecordTypeId, null)
                .addOrCriteria(
                        new fflib_Criteria()
                                .orCriteria()
                                .equalTo(Account.RecordTypeId, ContactAndOrgSettings.rtIdForAccountModel(false))
                                .equalTo(Account.npe01__SYSTEM_AccountType__c, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE)
                );
    }

    public class Constructor extends fflib_SObjects2 implements fflib_IDomainConstructor
    {
        public fflib_IDomain construct(List<Object> records)
        {
            List<SObject> filteredOneToOneAccounts = new OneToOneAccounts((List<SObject>) records)
                .getOneToOneAccounts()
                .getRecords();

            return (fflib_IDomain) new OneToOneAccounts(filteredOneToOneAccounts);
        }
    }
}