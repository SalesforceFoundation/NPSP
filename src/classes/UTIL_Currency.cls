/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Utilities
* @description Utilities for working with currencies
*/
public with sharing class UTIL_Currency implements UTIL_Currency.Interface_x {

    /**
     * @description public Interface to enable mocking of this class functionality for unit tests in orgs
     * that may or may not have multicurrency enabled.
     */
    public interface Interface_x {
        Boolean isMultiCurrencyOrganization();
        Boolean isAdvancedCurrencyManagementEnabled();
        String getOrgDefaultCurrency();
        String getDefaultCurrency();
        String getDefaultCurrencySymbol();
        String getCurrencySymbol(Id recordId);
        String getCurrencySymbol(String currCode);
        String getCurrencyIsoCodeQuery(Id recordId);
        String queryCurrencyIsoCode(Id recordId);
    }

    /** @description Store instance for Singleton pattern */
    @TestVisible
    private static Interface_x instance;

    /**
     * @description Get the singleton instance of the UTIL_Currency class
     * @return UTIL_Currency.Interface_x
     */
    public static Interface_x getInstance() {
        if (instance == null) {
            instance = new UTIL_Currency();
        }
        return instance;
    }

    /** @description Private constructor for Singleton pattern */
    @TestVisible
    private UTIL_Currency() {}

    /**
     * @description Wrapper for UserInfo.isMultiCurrencyOrganization()
     */
    public Boolean isMultiCurrencyOrganization() {
        return UserInfo.isMultiCurrencyOrganization();
    }

    /**
     * @description Returns true if Advanced Currency Management is enabled in the org
     * - technically this will return true even if the Admin disables ACM after it's enabled the first time
     * - TODO: working on a solution for this still
     */
    private Boolean isACMEnabled = null;
    public Boolean isAdvancedCurrencyManagementEnabled() {
        if (isACMEnabled == null) {
            if (isMultiCurrencyOrganization()) {
                isACMEnabled = Schema.getGlobalDescribe().containsKey('DatedConversionRate');
            } else {
                isACMEnabled = false;
            }
        }
        return isACMEnabled;
    }

    /**
     * @description Returns the organizations default currency code (i.e., "Corporate" or "Home" Currency)
     */
    private static String orgDefaultCurrencyCode;
    public String getOrgDefaultCurrency() {
        if (orgDefaultCurrencyCode == null) {
            if (UserInfo.isMultiCurrencyOrganization()) {
                String soql = 'SELECT IsoCode FROM CurrencyType WHERE IsCorporate = True LIMIT 1';
                SObject currObj = database.query(soql);
                orgDefaultCurrencyCode = (String)currObj.get('IsoCode');
            } else {
                orgDefaultCurrencyCode = '';
            }
        }
        return orgDefaultCurrencyCode;
    }

    /**
     * @description Wrapper for UserInfo.getDefaultCurrency(). Returns the context user's default currency code
     * for multiple currency organizations or the organization's currency code for single currency organizations.
     */
    public String getDefaultCurrency() {
        return UserInfo.getDefaultCurrency();
    }

    /**
     * @description For single currency orgs, return the symbol of the user's
     * default currency or the user's currency ISO code if no symbol is known for that
     * currency
     *
     * @return String
     */
    public String getDefaultCurrencySymbol() {
        String userCurrency = UTIL_Currency.getInstance().getDefaultCurrency();
        if (currencySymbols.containsKey(userCurrency)) {
            return currencySymbols.get(userCurrency);
        } else {
            return userCurrency;
        }
    }

    /**
     * @description Return the currency symbol appropriate for the given record
     * id.
     * If the org is multi currency enabled, it will return the
     * currency iso code from the given record.  If the org is not multi
     * currency enabled, it will return the symbol for the currency of the org,
     * or the currency iso code if no symbol is known.
     *
     * @param recordId The id of the record to determine currency symbol from
     * @return String
     */
    public String getCurrencySymbol(Id recordId) {
        Interface_x currencyUtil = UTIL_Currency.getInstance();
        if (currencyUtil.isMultiCurrencyOrganization() && recordId != null) {
            return currencyUtil.queryCurrencyIsoCode(recordId);
        } else {
            return currencyUtil.getDefaultCurrencySymbol();
        }
    }

    /**
     * @description Return the currency symbol appropriate for the given currency code.
     * @param CurencyIsoCode
     * @return String
     */
    public String getCurrencySymbol(String currCode) {
        Interface_x currencyUtil = UTIL_Currency.getInstance();
        if (currencyUtil.isMultiCurrencyOrganization() && currCode != null) {
            return currencySymbols.get(currCode);
        } else {
            return currencyUtil.getDefaultCurrencySymbol();
        }
    }

    /**
     * @description Build a SOQL string to query CurrencyIsoCode from the
     * object identified by the given record id
     *
     * @param recordId The id of the record that should be queried
     * @return String
     */
    public String getCurrencyIsoCodeQuery(Id recordId) {
        String objectName = recordId.getSobjectType().getDescribe().getName();
        return String.format(
            'SELECT CurrencyIsoCode FROM {0} WHERE Id = \'\'{1}\'\' LIMIT 1',
            new List<String>{objectName, recordId}
        );
    }

    /**
     * @description Query the database for the CurrencyIsoCode of the object
     * identified by the given record id
     *
     * @param recordId The id of the record that should be queried
     * @return String
     */
    public String queryCurrencyIsoCode(Id recordId) {
        String isoCodeQuery = UTIL_Currency.getInstance().getCurrencyIsoCodeQuery(recordId);
        sObject objectWithCurrency = Database.query(isoCodeQuery);
        return (String) objectWithCurrency.get('CurrencyIsoCode');
    }

    /**
     * @description Mapping of common currency ISO codes to currency symbols
     */
    private static Map<String, String> currencySymbols = new Map<String, String>{
        'USD' => '$',
        'CNY' => '¥',
        'JPY' => '¥',
        'EUR' => '€',
        'GBP' => '£',
        'BRL' => 'R$',
        'INR' => '₹',
        'RUB' => '₽',
        'CAD' => '$',
        'AUD' => '$',
        'KRW' => '₩',
        'MXN' => '$',
        'IDR' => 'Rp',
        'TRY' => '₺',
        'SAR' => '﷼'
    };
}