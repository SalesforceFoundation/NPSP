from cumulusci.tasks.salesforce import BaseSalesforceApiTask

class is_rd2_enabled(BaseSalesforceApiTask):
    def __call__(self):
        self._init_task()

        settings = self.sf.query(
            "SELECT IsRecurringDonations2Enabled__c "
            "FROM npe03__Recurring_Donations_Settings__c "
            "WHERE SetupOwnerId IN (SELECT Id FROM Organization)"
        )

        if settings.get("records"):
            if settings["records"][0]["IsRecurringDonations2Enabled__c"]:
                return True

        return False