@IsTest
private class UsageSummaryTests_TEST {
    @IsTest
    static void should_calculate_time_in_millis_correctly() {
        UsageSummary usageSummary = new UsageSummary(
                new List<UsageSnapshot>{
                        new UsageSnapshot(
                                0, 0, 0, 0
                        ),
                        new UsageSnapshot(
                                10, 10, 10, 10
                        ),
                        new UsageSnapshot(
                                10, 10, 10, 10
                        )
                }
        );

        System.assertEquals(20, usageSummary.totalTimeMillis());

    }

    @IsTest
    static void should_calculate_queries_correctly() {
        UsageSummary usageSummary = new UsageSummary(
                new List<UsageSnapshot>{
                        new UsageSnapshot(
                                0, 50, 0, 0
                        ),
                        new UsageSnapshot(
                                10, 10, 10, 10
                        ),
                        new UsageSnapshot(
                                10, 0, 10, 10
                        )
                }
        );

        System.assertEquals(60, usageSummary.totalQueries());

    }
}