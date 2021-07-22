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
public without sharing class UTIL_Currency implements UTIL_Currency.Interface_x {
    
    public static final String CURRENCY_ISO_CODE_FIELD = 'CurrencyIsoCode';

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
        String getCurrencySymbol(String currCode);
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
     * - This is as accurate an assessment as we can get within Apex at present.
     */
    private Boolean isACMEnabled = null;
    public Boolean isAdvancedCurrencyManagementEnabled() {
        if (isACMEnabled == null) {
            isACMEnabled = false;
            if (isMultiCurrencyOrganization()) {
                // Using a string in Database.query because this query won't compile if multicurrency isn't enabled
                // Using try/catch in case platform bug gets fixed whereby
                // DatedConverstionRate will (accurately) not exist in MultiCurrency org without ACM enabled
                try {
                    Integer DCRCount = Database.query('SELECT Id FROM DatedConversionRate LIMIT 1').size();
                    if (DCRCount == 1) {
                        isACMEnabled = true;
                    }
                } catch (Exception e) {
                    // Nothing to do, ACM = false
                }
            }
        }
        return isACMEnabled;
    }

    /**
     * @description Returns the organizations default currency code (i.e., "Corporate" or "Home" Currency)
     */
    public String getOrgDefaultCurrency() {
        return UTIL_CurrencyCache.getOrgDefaultCurrency();
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
     * @description Mapping of common currency ISO codes to currency symbols
     */
    private static Map<String, String> currencySymbols = new Map<String, String>{
        'AED' => 'د.إ',
        'AFN' => '؋',
        'ALL' => 'L',
        'AMD' => '֏',
        'ANG' => 'ƒ',
        'AOA' => 'Kz',
        'ARS' => '$',
        'AUD' => '$',
        'AWG' => 'ƒ',
        'AZN' => '₼',
        'BAM' => 'KM',
        'BBD' => '$',
        'BDT' => '৳',
        'BGN' => 'лв',
        'BHD' => '.د.ب',
        'BIF' => 'FBu',
        'BMD' => '$',
        'BND' => '$',
        'BOB' => '$b',
        'BRL' => 'R$',
        'BSD' => '$',
        'BTN' => 'Nu.',
        'BWP' => 'P',
        'BYN' => 'Br',
        'BZD' => 'BZ$',
        'CAD' => '$',
        'CDF' => 'FC',
        'CHF' => 'CHF',
        'CLP' => '$',
        'CNY' => '¥',
        'COP' => '$',
        'CRC' => '₡',
        'CSD' => 'CSD',
        'CUP' => '₱',
        'CVE' => '$',
        'CZK' => 'Kč',
        'DJF' => 'Fdj',
        'DKK' => 'kr',
        'DOP' => 'RD$',
        'DZD' => 'دج',
        'EGP' => '£',
        'ERN' => 'Nfk',
        'ETB' => 'Br',
        'EUR' => '€',
        'FJD' => '$',
        'FKP' => '£',
        'GBP' => '£',
        'GEL' => '₾',
        'GHS' => 'GH₵',
        'GIP' => '£',
        'GMD' => 'D',
        'GNF' => 'FG',
        'GTQ' => 'Q',
        'GYD' => '$',
        'HKD' => '$',
        'HNL' => 'L',
        'HRK' => 'kn',
        'HTG' => 'G',
        'HUF' => 'Ft',
        'IDR' => 'Rp',
        'ILS' => '₪',
        'INR' => '₹',
        'IQD' => 'ع.د',
        'IRR' => '﷼',
        'ISK' => 'kr',
        'JMD' => 'J$',
        'JOD' => 'JD',
        'JPY' => '¥',
        'KES' => 'KSh',
        'KGS' => 'лв',
        'KHR' => '៛',
        'KMF' => 'CF',
        'KPW' => '₩',
        'KRW' => '₩',
        'KWD' => 'KD',
        'KYD' => '$',
        'KZT' => 'лв',
        'LAK' => '₭',
        'LBP' => '£',
        'LKR' => '₨',
        'LRD' => '$',
        'LYD' => 'LD',
        'MAD' => 'MAD',
        'MDL' => 'lei',
        'MGA' => 'Ar',
        'MKD' => 'ден',
        'MMK' => 'K',
        'MOP' => 'MOP$',
        'MRO' => 'UM',
        'MUR' => '₨',
        'MWK' => 'MK',
        'MXN' => '$',
        'MYR' => 'RM',
        'MZN' => 'MT',
        'NAD' => '$',
        'NGN' => '₦',
        'NIO' => 'C$',
        'NOK' => 'kr',
        'NPR' => '₨',
        'NZD' => '$',
        'OMR' => '﷼',
        'PAB' => 'B/.',
        'PEN' => 'S/.',
        'PGK' => 'K',
        'PHP' => '₱',
        'PKR' => '₨',
        'PLN' => 'zł',
        'PYG' => 'Gs',
        'QAR' => '﷼',
        'RON' => 'lei',
        'RSD' => 'Дин.',
        'RUB' => '₽',
        'RWF' => 'R₣',
        'SAR' => '﷼',
        'SBD' => '$',
        'SCR' => '₨',
        'SDG' => 'ج.س.',
        'SEK' => 'kr',
        'SGD' => '$',
        'SHP' => '£',
        'SLL' => 'Le',
        'SOS' => 'S',
        'SRD' => '$',
        'STN' => 'Db',
        'SYP' => '£',
        'SZL' => 'E',
        'THB' => '฿',
        'TJS' => 'SM',
        'TND' => 'د.ت',
        'TOP' => 'T$',
        'TRY' => '₺',
        'TTD' => 'TT$',
        'TWD' => 'NT$',
        'TZS' => 'TSh',
        'UAH' => '₴',
        'UGX' => 'USh',
        'USD' => '$',
        'UYU' => '$U',
        'UZS' => 'лв',
        'VEF' => 'Bs',
        'VND' => '₫',
        'VUV' => 'VT',
        'WST' => 'WS$',
        'XAF' => 'FCFA',
        'XCD' => '$',
        'XOF' => 'CFA',
        'XPF' => '₣',
        'YER' => '﷼',
        'ZAR' => 'R'
    };
}