from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators


@pageobject("Details", "Relationship")
class RelationshipDetailPage(BaseNPSPPage, DetailPage):
    object_name = "npe4__Relationship__c"

    def _is_current_page(self):
        """ Verify we are on the Relationship detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view")

    def validate_relation_status_message(self, contact1, contact2, relation):
        """Obtains the status message displayed on the relationship details page
           Validates it against the expected status message
        """
        self.builtin.log_to_console(contact1)
        expectedstatus = ("{} is {}'s {}".format(contact1,contact2,relation))
        self.builtin.log_to_console(expectedstatus)
        id,actualstatus = self.npsp.check_status(contact1)
        self.builtin.log_to_console(actualstatus)
        self.builtin.should_be_equal_as_strings(actualstatus,expectedstatus)
