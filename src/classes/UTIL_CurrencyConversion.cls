/*
    Copyright (c) 2017, Salesforce.org
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
* @description Utilities for converting amounts using the organizations currency exchange rates
*/
public class UTIL_CurrencyConversion {

    /**
     * @description Returns the proper effective rate to use based on the date and the from/to currencies
     * Leverages the UTIL_CurrencyCache class to handle either standard or dated exchanges as well as the
     * platform cache if it's been allocated.
     * @param dt - Effective Date to use for conversion (or null to use the current date)
     * @param fromCurr - The currency to convert from
     * @param toCurr - The currency to convert to.
     * @return Exchange Rate
     */
    public static Decimal getExchangeRate(Date dt, String fromCurr, String toCurr) {

        // If the from and to currencies are the same, just return 1
        if (fromCurr == toCurr) {
            return 1;
        }

        // Retrieve the conversion rate from the "From" Currency to the Org Default Currency
        Decimal fromRate = UTIL_CurrencyCache.getEffectiveExchangeRate(fromCurr, dt);

        // If the "to" currency is the org default, just return the fromRate
        if (toCurr == UTIL_Currency.getInstance().getOrgDefaultCurrency()) {
            return fromRate;
        }

        // Otherwise we have to calculate the rate between the two currencies.
        Decimal toRate = UTIL_CurrencyCache.getEffectiveExchangeRate(toCurr, dt);
        Decimal effRate = fromRate.divide(toRate, 6, System.RoundingMode.HALF_UP);

        return effRate;
    }

    /**
     * @description Returns the converted amount to the toCurr using the proper exchange rate.
     * @param amt - The amount to convert
     * @param dt - Effective Date to use for conversion (or null to use the current date)
     * @param fromCurr - The currency to convert from
     * @param toCurr - The currency to convert to.
     * @return Amount converted to the toCurr using the applied effective date
     */
    public static Decimal convertAmount(Decimal amt, Date dt, String fromCurr, String toCurr) {
        if (fromCurr == toCurr) {
            return amt;
        } else {
            Decimal effRate = getExchangeRate(dt, fromCurr, toCurr);
            return amt.divide(effRate, 2, System.RoundingMode.HALF_UP);
        }
    }

}