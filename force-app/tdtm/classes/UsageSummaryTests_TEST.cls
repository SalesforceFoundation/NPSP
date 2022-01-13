@IsTest
private class UsageSummaryTests_TEST {
    @IsTest
    static void should_calculate_time_in_millis_correctly() {
        UsageSummary usageSummary = new UsageSummary(
                new List<UsageIncrement>{
                        new UsageIncrement(
                                0, 0, 0, 0
                        ),
                        new UsageIncrement(
                                10, 10, 10, 10
                        ),
                        new UsageIncrement(
                                10, 10, 10, 10
                        )
                }
        );

        System.assertEquals(20, usageSummary.totalTimeMillis());

    }

    @IsTest
    static void should_calculate_queries_correctly() {
        UsageSummary usageSummary = new UsageSummary(
                new List<UsageIncrement>{
                        new UsageIncrement(
                                0, 50, 0, 0
                        ),
                        new UsageIncrement(
                                10, 10, 10, 10
                        ),
                        new UsageIncrement(
                                10, 0, 10, 10
                        )
                }
        );

        System.assertEquals(60, usageSummary.totalQueries());
        System.assertEquals(20, usageSummary.totalDmlRows());

    }

    @IsTest
    static void format_should_include_values() {
        UsageIncrement usageIncrement =
                new UsageIncrement(10, 10, 10, 90);

        UsageSummary usageSummary =
                new UsageSummary(
                        new List<UsageIncrement>{
                                usageIncrement
                        }
                );
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + usageSummary.format());
        System.debug(LoggingLevel.ERROR, '^^^^^^ usageIncrement.format() ^^^^^^');

        System.assert(usageSummary.format().contains('10'));
        System.assert(usageSummary.format().contains('90'));
    }

    @IsTest
    static void times_run_should_count_snapshots() {
        UsageIncrement usageIncrement =
                new UsageIncrement(10, 10, 10, 10);
        UsageIncrement usageIncrement2 =
                new UsageIncrement(10, 10, 10, 10);

        UsageSummary usageSummary =
                new UsageSummary(
                        new List<UsageIncrement>{
                                usageIncrement, usageIncrement2
                        }
                );
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + usageSummary.format());
        System.debug(LoggingLevel.ERROR, '^^^^^^ usageIncrement.format() ^^^^^^');

        System.assert(usageSummary.format().contains('"timesRun" : 2'));
    }
}