public inherited sharing class NPSP_Address implements anAddress {

    private Address__c addr;

    public NPSP_Address(Address__c address) {
        this.addr = address;
        if (isPartialSeasonalAddr(this.addr)) {
            this.addr.addError(Label.addrSeasonalPartial);
        }
    }

    public Boolean isSeasonal() {
        return (this.addr.Seasonal_Start_Month__c != null && this.addr.Seasonal_Start_Day__c != null &&
                this.addr.Seasonal_End_Month__c != null && this.addr.Seasonal_End_Day__c != null);
    }

    public void checkForPartialSeasonalErrors(){
        if (isPartialSeasonalAddr()) {
            this.addr.addError(Label.addrSeasonalPartial);
        }
    }
    /*******************************************************************************************************
    * @description utility to see if the address has only a subset of its seasonal fields set
    * @param addr the Address to look at
    * @return boolean
    */
    private static boolean isPartialSeasonalAddr(Address__c addr) {
        integer cParts = 0;
        if (addr.Seasonal_Start_Month__c != null) cParts++;
        if (addr.Seasonal_Start_Day__c != null) cParts++;
        if (addr.Seasonal_End_Month__c != null) cParts++;
        if (addr.Seasonal_End_Day__c != null) cParts++;
        return (cParts > 0 && cParts < 4);
    }

    public Address__c getRecord() {
        return this.addr;
    }

    public Boolean belongsToSameHouseholdAs(anAddress other) {
        return householdId() == other.householdId();
    }

    public String householdId() {
        return this.addr.Household_Account__c;
    }

    public Boolean overlapsWith(anAddress other) {
        if (other == null)
            return false;
        if (!isSeasonal() || !other.isSeasonal())
            return false;

        // we don't need to know what year or month we are currently in, but
        // we need to take into account days (since we could be in the same month).
        // to make this easy to compare, we convert month & day to be a decimal of month.day.
        // eg., 3.01 for Feb 1st and 3.28 for Feb 28th.
        decimal start1 = decimalOfMonthDay(startMonth(), startDay());
        decimal end1 = decimalOfMonthDay(endMonth(), endDay());
        decimal start2 = decimalOfMonthDay(other.startMonth(), other.startDay());
        decimal end2 = decimalOfMonthDay(other.endMonth(), other.endDay());

        // now we see if the ranges are increasing (Jan '14 - March '14), or decreasing (Nov 14' - Feb '15),
        boolean range1Increases = start1 < end1;
        boolean range2Increases = start2 < end2;

        // we can now tell if there is overlap simply by looking at three scenarios:
        // 1. both ranges increase, make sure start1 not in range2, and start2 not in range1.
        if (range1Increases && range2Increases) {
            return (start1 >= start2 && start1 <= end2) || (start2 >= start1 && start2 <= end1);
        }
        // 2. one range increases, one range decreases, make sure end1 not in range2, and end2 not in range1.
        else if (range1Increases != range2Increases) {
            return (end1 >= start2 && end1 <= end2) || (end2 >= start1 && end2 <= end1);
        }
        // 3. both ranges decrease, always implies an overlap of the new year!
        else {
            return true;
        }

    }

    public String endDay() {
        return addr.Seasonal_End_Day__c;
    }

    public String endMonth() {
        return addr.Seasonal_End_Month__c;
    }

    public String startDay() {
        return addr.Seasonal_Start_Day__c;
    }

    public String startMonth() {
        return addr.Seasonal_Start_Month__c;
    }

    /*******************************************************************************************************
    * @description utility to create the month and day strings to a decimal we can use in comparisons.
    * @param m the month ordinal as a string
    * @param d the day ordinal as a string
    * @return decimal
    */
    private static decimal decimalOfMonthDay(string m, string d) {
        if (integer.valueOf(d) < 10)
            return decimal.valueOf(m + '.0' + d); else
                return decimal.valueOf(m + '.' + d);
    }

}