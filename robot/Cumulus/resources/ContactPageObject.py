from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators



@pageobject("Listing", "Contact")
class ContactListingPage(BaseNPSPPage, ListingPage):
    object_name = "Contact"
   
    def click_delete_account_button(self):
        """Clicks on Delete Account button inside the iframe"""
        self.selenium.wait_until_location_contains("/delete", message="Account delete page did not load in 30 seconds")
        self.npsp.select_frame_and_click_element("vfFrameId","button","Delete Account")    

@pageobject("Details", "Contact")
class ContactDetailPage(BaseNPSPPage, DetailPage):
    object_name = "Contact"

    def _is_current_page(self):
        """ Verify we are on the Contact detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Detail page did not load in 1 min")
        self.selenium.location_should_contain("/lightning/r/Contact/",message="Current page is not a Contact record detail view")
        

    def update_field_value(self,field_name,old_value,new_value):
        """Delete the old value in specified field by clicking on delete icon and update with new value"""
        locator=npsp_lex_locators['delete_icon'].format(field_name,old_value)
        self.selenium.get_webelement(locator).click() 
        self.salesforce.populate_lookup_field(field_name,new_value)
        
            

    def waitfor_actions_dropdown_and_click_option(self,option):
        """Wait for the Action dropdown menu to load from the contact details page
           Click on the desired option passed as a parameter
        """
        loc=npsp_lex_locators['contacts_actions_dropdown_menu']
        self.selenium.wait_until_element_is_visible(loc)
        self.selenium.click_link(option)

    def validate_relation_status_message(self, contact1, contact2, relation):
        """Obtains the status message displayed on the relationships section of contact details page
           Validates it against the expected status message
           Note: Pass contact1,contact2, relation in a desired pattern to format as contact1 is contact2's relation
        """
        expectedstatus = ("{} is {}'s {}".format(contact1,contact2,relation))
        id,actualstatus = self.npsp.check_status(contact1)
        self.builtin.should_be_equal_as_strings(actualstatus,expectedstatus)

    # def validate_field_value_under_section(self, section, fieldname, value):
    #     section="text:"+section
    #     self.selenium.scroll_element_into_view(section)
    #     self.npsp.confirm_field_value(fieldname, "contains", value)

