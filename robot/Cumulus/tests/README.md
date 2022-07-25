## NPSP Robot test tags

There are a number of tags applied to NPSP Robot tests which have implications for robot test plans run by MetaCI and/or NPSP robot test maintenance best practices. Those tags, and the appropriate way to handle those tags is covered by this README file.

* `feature:RD2` Robot tests which rely on Enhanced Recurring Donations and standard Recurring Donations cannot be run in the same plan by MetaCI without special handling. Tests which require Enhanced Recurring Donations are tagged `feature:RD2` to allow plans to determine which configuration is required for Recurring Donation tests.
* `unstable` Tests tagged `unstable` should normally be excluded from automated builds until they can repaired. The best practice for a failing test is to tag it `unstable` and commit/merge that change. It should then be automatically excluded by plans that are configured to do so. That practice preserves the expectation that robot test builds should always succeed. After the failing test has been repaired, the `unstable` tag should be removed and committed, which should then automatically start running the test again.
* `deprecated` Tests tagged `deprecated` should always be excluded from automated builds. The best practice for a robot test which duplicates a unit test, has been superseded by a unit test, or has been determined to be unnecessary for other reasons is to tag it `deprecated` and commit that change.
* `unit` Tests tagged `unit` have been identified as good candidates for replacement with a unit test. The best practice for a robot test that can be replaced with a unit test is to tag it `unit` and commit/merge that change. When a replacement unit test has been identified or created, the `unit` tag should be replaced with the `deprecated` tag.
* `api` Tests tagged `api` have been identified as tests that will become more robust if browser automation is replaced with api calls.  The best practice for a robot test that would benefit from replacing browser automation with api calls is to tag it `api` and commit/merge that change.  When the change has been made, the api tag should be removed.
* `feature:<feature_name>` It is a best practice to categorize robot tests according to the feature being tested and group features together in a separate directory. Doing so allows us to identify tests associated with a particular feature efficiently. The current feature tags are:
  * `feature:Affiliations`
  * `feature:Automated Soft Credits`
  * `feature:BDI`
  * `feature:Contacts and Accounts`
  * `feature:CRLP`
  * `feature:Donations`
  * `feature:Donations and Payments`
  * `feature:Engagements`
  * `feature:GAU`
  * `feature:GE`
  * `feature:Levels`
  * `feature:Manage Households`
  * `feature:NPSP Settings`
  * `feature:Payment Allocations`
  * `feature:Recurring Donations`
  * `feature:Relationships`
  * `feature:RD2`
* The best practice for adding multiple tags to a line is to start with the `feature` tag, followed by the `unstable` or `deprecated` tag if appropriate. The `unit` and `api` tags are test maintenance information only and should always be included at the end of the tag line when they are used. Nothing will break if tag ordering does not follow this convention, but it will be easier to locate tests with a particular combination of tags using regex if the pattern is predictable.