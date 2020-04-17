import time
import re
from cumulusci.robotframework.utils import capture_screenshot_on_error
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

OID_REGEX = r"^(%2F)?([a-zA-Z0-9]{15,18})$"
@pageobject("Custom", "GE_Gift_Entry")
class GiftEntryPage(BaseNPSPPage, BasePage):

    
    def _go_to_page(self):
        """To go to Gift Entry page"""
        url_template = "{root}/lightning/n/{object}"
        name = self._object_name
        object_name = "{}{}".format(self.cumulusci.get_namespace_prefix(), name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.selenium.wait_until_page_contains("Templates")

    def _is_current_page(self):
        """
        Verifies that current page is Gift Entry landing page
        """
        self.selenium.wait_until_location_contains("GE_Gift_Entry", timeout=60, 
                                                   message="Current page is not Gift Entry landing page")
        self.selenium.wait_until_page_contains("Default Gift Entry Template")                                               

    def click_gift_entry_button(self,title):
        """clicks on Gift Entry button identified with title"""
        locator=npsp_lex_locators["gift_entry"]["button"].format(title)
        self.selenium.wait_until_page_contains_element(locator)
        self.selenium.click_element(locator)  

    def enter_value_in_field(self,**kwargs):
        """Enter value in specified field"""
        for key,value in kwargs.items():
            if key=='Description':
                locator=npsp_lex_locators["gift_entry"]["field_input"].format(key,"textarea")
                self.selenium.wait_until_page_contains_element(locator)
                self.salesforce._populate_field(locator, value)
            else:
                locator=npsp_lex_locators["gift_entry"]["field_input"].format(key,"input")
                self.selenium.wait_until_page_contains_element(locator)
                self.salesforce._populate_field(locator, value)      

    def select_template_action(self,name,action):
        """From the template table, select template with name and select an action from the dropdown"""
        locator=npsp_lex_locators["gift_entry"]["actions_dropdown"].format(name)
        self.selenium.click_element(locator)
        element=self.selenium.get_webelement(locator)
        status=element.get_attribute("aria-expanded")
        if status=="false":
            self.selenium.wait_until_page_contains("Clone")    
        self.selenium.click_link(action)
        if action=="Edit" or action=="Clone":
            self.selenium.wait_until_page_contains("Gift Entry Template Information")
        elif action=="Delete":
            self.selenium.wait_until_page_does_not_contain(name)    

    def select_object_group_field(self,object_group,field):
        """Select the specified field under specified object group 
           to add the field to gift entry form and verify field is added"""
        locator=npsp_lex_locators["gift_entry"]["form_object_dropdown"].format(object_group)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_element(locator)
        element=self.selenium.get_webelement(locator)
        status=element.get_attribute("aria-expanded")
        if status=="false":
            time.sleep(2)       
        field_checkbox=npsp_lex_locators["gift_entry"]["object_field_checkbox"].format(field)  
        self.selenium.scroll_element_into_view(field_checkbox)   
        self.selenium.click_element(field_checkbox)
        field_label=object_group+': '+field
        self.selenium.wait_until_page_contains(field_label)

    def verify_template_is_not_available(self,template):
        """Verify that a gift template is not available for selection while creating a new batch"""
        field=npsp_lex_locators["adv_mappings"]["field_mapping"].format("Template")
        self.selenium.click_element(field)
        element=self.selenium.get_webelement(field)
        status=element.get_attribute("aria-activedescendant")
        if status is not None:
            self.selenium.page_should_not_contain(template)
        else:
            self.selenium.wait_until_page_contains("Default Gift Entry Template")
            self.selenium.page_should_not_contain(template)  
        self.selenium.click_button("Cancel")

    def get_template_record_id(self,template):
        """ Parses the current url to get the object id of the current record.
            Expects url format like: [a-zA-Z0-9]{15,18}
        """
        locator=npsp_lex_locators["link-text"].format(template)
        element = self.selenium.get_webelement(locator)
        e=element.get_attribute("href")
        print(f"url is {e}")
        for part in e.split("="):
            oid_match = re.match(OID_REGEX, part)
            if oid_match is not None:
                return oid_match.group(2)
        raise AssertionError("Could not parse record id from url: {}".format(e))

    def store_template_record_id(self,template):
        """ Parses the template href to get the object id of the current record.
            Expects url format like: [a-zA-Z0-9]{15,18}
        """
        id=self.get_template_record_id(template) 
        self.salesforce.store_session_record("Form_Template__c",id)   
              

   

        

