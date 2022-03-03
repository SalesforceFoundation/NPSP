@IsTest
private class UsageIncrementTests_TEST {
    @IsTest
    static void should_be_equal() {
        UsageIncrement increment = new UsageIncrement(
                1,2,1,1
        );
        UsageIncrement otherIncrement = new UsageIncrement(
                1,2,1,1
        );

        System.assert(increment.equals(otherIncrement),
                'The two increments should be equal.');
    }
}