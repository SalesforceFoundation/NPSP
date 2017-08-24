@isTest
private class RLLP_Engine_TEST {

    //dummy operations for instantiating RLLP_Engine class
    private static final RLLP_Operation streak = new RLLP_Operation(Contact.Title, RLLP_Operation.RollupType.CURRENT_STREAK);

    static testMethod void streakStartingThisYear() {
        RLLP_Engine engine = new RLLP_Engine(new List<RLLP_Operation>{streak});
        Integer year = RLLP_FiscalYears.getYear(System.today());
        for (Integer i = 0; i < 10; i++) {
            engine.yearly.put(String.valueOf(year), new RLLP_Engine.Sum());
            year--;
        }
        //add an extra year to make sure it isn't counted
        engine.yearly.put('1984', new RLLP_Engine.Sum());
        System.assertEquals(10, engine.getDonorStreak(), 'Donor streak should equal ten years.');
    }

    static testMethod void streakStartingLastYear() {
        RLLP_Engine engine = new RLLP_Engine(new List<RLLP_Operation>{streak});
        Integer year = RLLP_FiscalYears.getYear(System.today().addYears(-1));
        for (Integer i = 0; i < 10; i++) {
            engine.yearly.put(String.valueOf(year), new RLLP_Engine.Sum());
            year--;
        }
        //add an extra year to make sure it isn't counted
        engine.yearly.put('1984', new RLLP_Engine.Sum());
        System.assertEquals(10, engine.getDonorStreak(), 'Donor streak should equal ten years.');
    }

    static testMethod void streakStartingTwoYearsAgo() {
        RLLP_Engine engine = new RLLP_Engine(new List<RLLP_Operation>{streak});
        Integer year = RLLP_FiscalYears.getYear(System.today().addYears(-2));
        for (Integer i = 0; i < 10; i++) {
            engine.yearly.put(String.valueOf(year), new RLLP_Engine.Sum());
            year--;
        }
        //add an extra year to make sure it isn't counted
        engine.yearly.put('1984', new RLLP_Engine.Sum());
        System.assertEquals(0, engine.getDonorStreak(), 'Donor streak should equal zero.');
    }

    static testMethod void yearsDonated() {
        RLLP_Engine engine = new RLLP_Engine(new List<RLLP_Operation>{streak});

        List<String> years = new List<String>{'2012','1984','2017','2000','2001'};

        for (Integer i = 0; i < years.size(); i++) {
            engine.yearly.put(years[i], new RLLP_Engine.Sum());
        }
        System.assertEquals('1984;2000;2001;2012;2017', engine.getYearsDonated(), 'Years donated should be sorted and concatenated.');
    }

}