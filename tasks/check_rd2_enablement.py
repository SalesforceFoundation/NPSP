import simple_salesforce
from cumulusci.tasks.salesforce import BaseSalesforceApiTask

class is_rd2_enabled(BaseSalesforceApiTask):
    def _run_task(self):
        try:
            settings = self.sf.query(
                "SELECT npsp__IsRecurringDonations2Enabled__c "
                "FROM npe03__Recurring_Donations_Settings__c "
                "WHERE SetupOwnerId IN (SELECT Id FROM Organization)"
            )
        except simple_salesforce.exceptions.SalesforceMalformedRequest:
            # The field does not exist in the target org, meaning it's
            # pre-RD2
            self.return_values = False
            self.logger.info("Identified Enhanced Recurring Donations status: {}".format(self.return_values))
            return

        if settings.get("records"):
            if settings["records"][0]["npsp__IsRecurringDonations2Enabled__c"]:
                self.return_values = True
                self.logger.info("Identified Enhanced Recurring Donations status: {}".format(self.return_values))
                return

        self.return_values = False
        self.logger.info("Identified Enhanced Recurring Donations status: {}".format(self.return_values))