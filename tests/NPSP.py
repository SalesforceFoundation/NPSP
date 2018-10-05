import logging
import re
import time

from robot.libraries.BuiltIn import BuiltIn
from selenium.common.exceptions import ElementNotInteractableException
from selenium.common.exceptions import StaleElementReferenceException
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import WebDriverException
from selenium.webdriver.common.keys import Keys
from SeleniumLibrary.errors import ElementNotFound
from simple_salesforce import SalesforceMalformedRequest
from simple_salesforce import SalesforceResourceNotFound
from locator_backup_91118 import npsp_lex_locators
from selenium.webdriver import ActionChains
#import os
import sys
from email.mime import text
from httplib import PAYMENT_REQUIRED
#sys.path.append(os.path.abspath(os.path.join('..',
#sys.path.append("/Users/skristem/Documents/GitHub/CumulusCI/cumulusci/robotframework/tests")
#import Salesforce


class NPSP(object):
    
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = 1.0
 
    def __init__(self, debug=False):
        self.debug = debug
        self.current_page = None
        self._session_records = []
        self.val=0
        # Turn off info logging of all http requests 
        logging.getLogger('requests.packages.urllib3.connectionpool').setLevel(logging.WARN)
 
    @property
    def builtin(self):
        return BuiltIn()   
 
    @property
    def cumulusci(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.CumulusCI')
  
    @property
    def selenium(self):
        return self.builtin.get_library_instance('SeleniumLibrary')
            
    def populate_address(self, loc, value):
        """ Populate address with Place Holder aka Mailing Street etc as a locator
            and actual value of the place holder.
        """
        xpath = npsp_lex_locators["mailing_address"].format(loc)
        field = self.selenium.get_webelement(xpath)
        field.send_keys(value)
        time.sleep(1)
        
        
    def click_record_button(self, title):
        """ Pass title of the button to click the buttons on the records edit page. Usually save and cancel are the buttons seen.
        """
        locator = npsp_lex_locators['record']['button'].format(title)
        self.selenium.set_focus_to_element(locator)
        button = self.selenium.get_webelement(locator)
        button.click()
        time.sleep(5)
        
    def select_tab(self, title):
        """ Switch between different tabs on a record page like Related, Details, News, Activity and Chatter
            Pass title of the tab
        """
        locator = npsp_lex_locators['tab'].format(title)
        self.selenium.set_focus_to_element(locator)
        button = self.selenium.get_webelement(locator)
        button.click()
        time.sleep(5)    
        
    def click_special_related_list_button(self, heading, button_title):
        """ To Click on a related list button which would open up a new lightning page rather than a modal.
            Pass the list name and button name
        """
        locator = npsp_lex_locators['record']['related']['button'].format(heading, button_title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()
        
    def click_dropdown(self, title):
        locator = npsp_lex_locators['record']['list'].format(title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()     
    
    def pick_date(self, value):
        """To pick a date from the date picker"""
        locator = npsp_lex_locators['record']['datepicker'].format(value)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click() 
        
#     def select_row(self,value):
#         """To select a row on object page based on name and open the dropdown"""    
#         drop_down = npsp_lex_locators['locating_delete_dropdown'].format(value)
#         self.selenium.get_webelement(drop_down).click()
#         #self.selenium.get_webelement(drop_down).click()

#     def select_row(self,value):
#         """To select a row on object page based on name and open the dropdown"""    
#         locator = npsp_lex_locators['select_name'].format(value)
#         self.selenium.set_focus_to_element(locator)
#         drop_down = npsp_lex_locators['locating_delete_dropdown'].format(value)
#         time.sleep(1)
#         return drop_down
    
    def select_row(self, value):
        """To select a row on object page based on name and open the dropdown"""
        locators = npsp_lex_locators['name']
        list_ele = self.selenium.get_webelements(locators)
        for index, element in enumerate(list_ele):
            if element.text == value:
                drop_down = npsp_lex_locators['locate_dropdown'].format(index + 1)
                self.selenium.get_webelement(drop_down).click()
                time.sleep(1)

    def select_related_row(self, value):
        """To select a row on object page based on name and open the dropdown"""
        locators = npsp_lex_locators['related_name']
        list_ele = self.selenium.get_webelements(locators)
        for index, element in enumerate(list_ele):
            if element.text == value:
                drop_down = npsp_lex_locators['rel_loc_dd'].format(index + 1)
                self.selenium.get_webelement(drop_down).click()
                time.sleep(1)
#     def select_row(self, value ):
#         """To select a row on object page based on name and open the dropdown"""
#         locators = npsp_lex_locators['name']
#         list_ele = self.selenium.get_webelements(locators)
#         index= 1
#         for locator in list_ele:
#             global index
#             if locator.text != value:
#                 index = index+1
#             else:
#                 drop_down = npsp_lex_locators['locate_dropdown'].format(index)
#                 self.selenium.get_webelement(drop_down).click()
#                 self.selenium.get_webelement(drop_down).click()
            
#     def select_related_row(self, value ):
#         """To select row from a related list based on name and open the dropdown"""
#         locators = npsp_lex_locators['related_name']
#         list_ele = self.selenium.get_webelements(locators)
#         index= 1
#         for locator in list_ele:
#             global index
#             if locator.text != value:
#                 index = index+1
#             else:
#                 drop_down = npsp_lex_locators['rel_loc_dd'].format(index)
#                 self.selenium.get_webelement(drop_down).click()
#                 self.selenium.get_webelement(drop_down).click()      
                
    def delete_icon(self, field_name,value):  
        """To click on x """
        locator=npsp_lex_locators['delete_icon'].format(field_name,value)
        self.selenium.get_webelement(locator).click() 
        
    def click_edit_button(self, title):  
        locator=npsp_lex_locators['record']['edit_button'].format(title)
        self.selenium.get_webelement(locator).click()   
        
    def click_id(self, title):  
        locator=npsp_lex_locators['aff_id'].format(title)
        self.selenium.get_webelement(locator).click()     
         
    def select_object_dropdown(self): 
        locator=npsp_lex_locators['object_dd']
        self.selenium.get_webelement(locator).click()   
        
    def check_status(self, acc_name):
        aff_list = npsp_lex_locators['aff_status'].format(acc_name)
        aff_list_text=self.selenium.get_webelement(aff_list).text 
        self.aff_id=npsp_lex_locators['aff_id'].format(acc_name)
        self.aff_id_text=self.selenium.get_webelement(self.aff_id).text
        return self.aff_id_text,aff_list_text     
            
            
    def get_id(self):
        locator=npsp_lex_locators['click_aff_id'].format(self.aff_id_text)
        self.selenium.get_webelement(locator).click()   
        
    def confirm_value(self, field,value,status):
        locator=npsp_lex_locators['check_status'].format(field,value)
        if status.upper()=="Y":
            self.selenium.page_should_contain_element(locator)
        elif status.upper()=="N":
            self.selenium.page_should_not_contain_element(locator)
        #verify_former=self.selenium.get_webelement(locator).text
        #return verify_former
    
    def verify_field_value(self, field,value,status):
        locator=npsp_lex_locators['check_field'].format(field,value)
        if status.upper()=="Y":
            self.selenium.page_should_contain_element(locator)
        elif status.upper()=="N":
            self.selenium.page_should_not_contain_element(locator)
#         verify_former=self.selenium.get_webelement(locator).text
#         return verify_former
    
    def verify_record(self, name):
        """ Checks for the record in the object page and returns true if found else returns false
        """
        locator=npsp_lex_locators['account_list'].format(name)
        self.selenium.page_should_contain_element(locator)

            
    def select_option(self, name):  
        """selects various options in Contact>New opportunity page using name
        """
        locator=npsp_lex_locators['dd_options'].format(name)
        self.selenium.get_webelement(locator).click()
        
    def verify_related_list_items(self,list_name,value):
        """Verifies a specified related list has specified value(doesn't work if the list is in table format)"""
        locator=npsp_lex_locators['related_list_items'].format(list_name,value)
        self.selenium.page_should_contain_element(locator)
    
    def click_span_button(self,title):  
        """clicks on the button under span tag"""      
        locator=npsp_lex_locators['span_button'].format(title)
        self.selenium.get_webelement(locator).click()  
        
    def header_field_value(self,title,value):   
        """Validates if the specified header field has specified value"""   
        locator= npsp_lex_locators['header_field_value'].format(title,value)
        self.selenium.page_should_contain_element(locator)
        
    def Verify_affiliated_contact(self,list_name,first_name,last_name, y):   
        """Validates if the affiliated contacts have the added contact details enter Y for positive case and N for negative case"""   
        locator= npsp_lex_locators['affiliated_contacts'].format(list_name,first_name,last_name)
        if y.upper()=="Y":
            self.selenium.page_should_contain_element(locator)
        elif y.upper()=="N":
            self.selenium.page_should_not_contain_element(locator)
        
    def fill_address_form(self, **kwargs):
        """Validates if the affiliated contacts have the added contact details enter Y for positive case and N for negative case""" 
        for label, value in kwargs.items():
            locator= npsp_lex_locators['manage_hh_page']['address'].format(label,value)
            if label=="Street":
                locator = locator+"textarea"
                self.selenium.get_webelement(locator).send_keys(value)
            else:
                locator = locator+"input"
                self.selenium.get_webelement(locator).send_keys(value)
         
    def Verify_details_address(self,field,value):   
        """Validates if the details page address field has specified value"""   
        locator= npsp_lex_locators['detail_page']['address'].format(field,value)
        self.selenium.page_should_contain_element(locator)        
        
   
    def validate_checkbox(self,name,checkbox_title):   
        """validates all 3 checkboxes for contact on manage hh page and returns locator for the checkbox thats required"""   
          
        locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBInformal")
        self.selenium.page_should_contain_element(locator)
        
        locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBFormal")
        self.selenium.page_should_contain_element(locator)
        
        locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBExName") 
        self.selenium.page_should_contain_element(locator)
        
        if checkbox_title == "Informal Greeting":
            locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBInformal")
        elif checkbox_title == "Formal Greeting":
            locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBFormal") 
        elif checkbox_title.capitalize() == "Household Name":
            locator=npsp_lex_locators['manage_hh_page']['mhh_checkbox'].format(name,"fauxCBExName")       
        return locator
    
    def check_field_value(self, title, value):
        """checks value of a field in details page(section without header)"""
        locator=npsp_lex_locators['detail_page']['verify_field_value'].format(title,value)
        self.selenium.page_should_contain_element(locator)
        
    def click_managehh_button(self,title):  
        """clicks on the new contact button on manage hh page"""      
        locator=npsp_lex_locators['manage_hh_page']['button'].format(title)
        self.selenium.get_webelement(locator).click()    
    
    def select_modal_checkbox(self,title):
        """"""
        locator=npsp_lex_locators['modal']['checkbox'].format(title)
        self.selenium.get_webelement(locator).click()    
        
    def verify_occurance(self,title,value):
        """"""
        locator=npsp_lex_locators['record']['related']['check_occurance'].format(title,value)
        self.selenium.page_should_contain_element(locator)    
     
    def select_related_dropdown(self,title):
        """Clicks on the dropdown next to Related List"""
        locator=npsp_lex_locators['record']['related']['drop-down'].format(title)
        self.selenium.get_webelement(locator).click()   
        
    def get_header_date_value(self,title):   
        """Validates if the specified header field has specified value"""   
        locator= npsp_lex_locators['header_datepicker'].format(title)
        date=self.selenium.get_webelement(locator).text   
        return date 
        
    def get_main_header(self):
        header = self.selenium.get_webelement("//h1/span").text
        return header
    
    def verify_contact_role(self,name,role):
        """verifies the contact role on opportunity page"""
        locator=npsp_lex_locators['opportunity']['contact_role'].format(name,role)
        self.selenium.page_should_contain_element(locator)  
        
    def select_relatedlist(self,title):
        """click on the related list to open it"""
        locator=npsp_lex_locators['record']['related']['title'].format(title)
        self.selenium.get_webelement(locator).click()  
        
    def verify_contact_roles(self, **kwargs):
        """verifies the role of a specific contact on Opportunities page""" 
        for name, value in kwargs.items():
            locator= npsp_lex_locators['object']['contact_role'].format(name,value)
            self.selenium.page_should_contain_element(locator)   
            
    def page_contains_record(self,title):   
        """Validates if the specified record is present on the page"""   
        locator= npsp_lex_locators['object']['record'].format(title)
        self.selenium.page_should_not_contain_element(locator) 
             
                         
               
    def click_special_object_button(self, title):
        locator = npsp_lex_locators['object']['button'].format(title)
        self.selenium.get_webelement(locator).click()
        
    def click_eng_plan_dropdown(self, title):
        locator = npsp_lex_locators['engagement_plan']['dropdown'].format(title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()
        
    def select_eng_plan_checkbox(self,title):
        """"""
        if title=="Skip Weekends":
            locator=npsp_lex_locators['engagement_plan']['checkbox'].format("span",title)
            self.selenium.get_webelement(locator).click()
        else:
            locator=npsp_lex_locators['engagement_plan']['checkbox'].format("label",title)
            self.selenium.get_webelement(locator).click()
            
    def enter_eng_plan_values(self, **kwargs):
        """Enter values into corresponding fields in Engagement Plan Templet page"""
        for name, value in kwargs.items():
            if name == "Engagement Plan Template Name":
                id = "idName"
                locator = npsp_lex_locators['engagement_plan']['id'].format(id) 
                self.selenium.get_webelement(locator).send_keys(value)     
            elif name == "Description":
                id = "idDesc"
                locator = npsp_lex_locators['engagement_plan']['id'].format(id)
                self.selenium.get_webelement(locator).send_keys(value)  

                
    def enter_task_id_and_subject(self, id, value):
        """Enter values into corresponding task subject fields based on last 2 digits of id"""
        locator = npsp_lex_locators['engagement_plan']['input_box'].format(id) 
        self.selenium.get_webelement(locator).send_keys(value)
    
    
    def click_task_button(self, title):
        if title=="Add Dependent Task":
            id="btnAddDepTask"           
            locator = npsp_lex_locators['id'].format(id)
            self.selenium.get_webelement(locator).click()    
        elif title=="Add Task":
            id="j_id0:theForm:btnAddTask"
            locator = npsp_lex_locators['id'].format(id)
            self.selenium.get_webelement(locator).click() 
        elif title=="Save":
            id="j_id0:theForm:j_id5:j_id6:saveBTN"
            locator = npsp_lex_locators['id'].format(id)
            self.selenium.get_webelement(locator).click()
        elif title=="Add Row":
            id="j_id0:theForm:j_id49:0:addRowBTN"  
            locator = npsp_lex_locators['id'].format(id)
            self.selenium.get_webelement(locator).click()  
    
    def check_related_list_values(self,list_name,*args):
        """Verifies the value of custom related list"""
        for value in args:
            locator = npsp_lex_locators['engagement_plan']['check_related_list_item'].format(list_name,value)
            self.selenium.page_should_contain_element(locator)

    def verify_eng_plan_exists(self,name, delete=None):  
        """verifies that the Engagement Plans related list has a plan stored under it and clicks on dropdown if True is passed as 2nd argument"""
        locator = npsp_lex_locators['engagement_plan']['check_eng_plan'].format(name)
        self.selenium.page_should_contain_element(locator) 
        plan=self.selenium.get_webelement(locator).text   
        if delete == "True":
               locator = npsp_lex_locators['engagement_plan']['dd'].format(name)
               self.selenium.get_webelement(locator).click()      
        return plan
    
    def check_activity_tasks(self, *args):
        """verifies that the specified tasks are present under activity tab """
        for value in args:
            locator = npsp_lex_locators['engagement_plan']['tasks'].format(value)
            self.selenium.page_should_contain_element(locator)

    def enter_level_values(self, **kwargs):
        """Enter values into corresponding fields in Levels page"""
        for name, value in kwargs.items():
            if name == "Level Name":
                id = "fldName"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.selenium.set_focus_to_element(locator)  
                self.selenium.get_webelement(locator).send_keys(value)      
            elif name == "Minimum Amount":
                id = "fldMinAmount"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.selenium.set_focus_to_element(locator) 
                field=self.selenium.get_webelement(locator)
                field.clear()
                field.send_keys(value)  
            elif name == "Maximum Amount":
                id = "fldMaxAmount"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.selenium.set_focus_to_element(locator) 
                field=self.selenium.get_webelement(locator)
                field.clear()
                field.send_keys(value)                    

    def enter_level_dd_values(self, name,value):
        """Enter values into corresponding fields in Levels page"""                 
        if name == "Target":
            id = "fldTarget"
            locator = npsp_lex_locators['levels']['select'].format(id)
            loc = self.selenium.get_webelement(locator)
            self.selenium.set_focus_to_element(locator)       
            self.selenium.select_from_list_by_label(loc,value)
            time.sleep(2)
        elif name == "Source Field":
            id = "fldSourceField"
            locator = npsp_lex_locators['levels']['select'].format(id)
            loc = self.selenium.get_webelement(locator) 
            self.selenium.set_focus_to_element(locator)      
            self.selenium.select_from_list_by_label(loc,value) 
            time.sleep(2) 
        elif name == "Level Field":
            id = "fldLevel"
            locator = npsp_lex_locators['levels']['select'].format(id)
            loc = self.selenium.get_webelement(locator) 
            self.selenium.set_focus_to_element(locator)      
            self.selenium.select_from_list_by_label(loc,value)
            time.sleep(2)
        elif name == "Previous Level Field":
            id = "fldPreviousLevel"
            locator = npsp_lex_locators['levels']['select'].format(id)
            loc = self.selenium.get_webelement(locator) 
            self.selenium.set_focus_to_element(locator)      
            self.selenium.select_from_list_by_label(loc,value) 
    
    def click_level_button(self,title):   
        if title == "Save":
            id = "saveBTN"
            locator = npsp_lex_locators['levels']['button'].format(id) 
            self.selenium.get_webelement(locator).click()                
            
    def select_app_launcher_link(self,title):
        locator = npsp_lex_locators['app_launcher']['select-option'].format(title) 
        self.selenium.get_webelement(locator).click()
        time.sleep(1)
        
    def click_on_first_record(self):  
        """selects first record of the page"""
        locator = npsp_lex_locators['select_one_record']
        self.selenium.get_webelement(locator).click()
        time.sleep(1)  
        
    def select_search(self, index, value):
        """"""
        locator = npsp_lex_locators["click_search"].format(index)
        loc_value = self.selenium.get_webelement(locator).send_keys(value)
        loc = self.selenium.get_webelement(locator)
        #loc.send_keys(Keys.TAB+ Keys.RETURN)
        time.sleep(1)  
        
    def enter_gau(self, value):
        id = "lksrch"
        locator = npsp_lex_locators["id"].format(id)
        loc = self.selenium.get_webelement(locator)
        loc.send_keys(value)
        self.selenium.get_webelement("//*[@title='Go!']").click()
        time.sleep(1)

    def add_gau_allocation(self,type,index, value):
        if type=="percentage":
            id="j_id0:theForm:j_id49:{}:alloInputPercent"
            locator = npsp_lex_locators["id"].format(id)
            locc = locator.format(index)
            loc = self.selenium.get_webelement(locc)
            loc.send_keys(value)
        elif type=="amount":
            id="j_id0:theForm:j_id49:{}:alloInputAmount"
            locator = npsp_lex_locators["id"].format(id)
            locc = locator.format(index)
            loc = self.selenium.get_webelement(locc)
            loc.send_keys(value)    
        
    def click_save(self, page):
        if  page== "GAU":
            id="j_id0:theForm:j_id9:j_id10:saveBTN"
            locator = npsp_lex_locators["id"].format(id)
            self.selenium.get_webelement(locator).click()
     
    def enter_payment_schedule(self, *args):
        """Enter values into corresponding fields in Levels page"""                 
        #if name == "Payments":
        id = ["j_id0:vfForm:paymentCount","j_id0:vfForm:intervals","j_id0:vfForm:intervalunits"]
        for i in range(len(args)):
            locator = npsp_lex_locators['id'].format(id[i])
            loc = self.selenium.get_webelement(locator)
            self.selenium.set_focus_to_element(locator)       
            self.selenium.select_from_list_by_label(loc,args[i])
            time.sleep(2)    
                
    def verify_payment_split(self, amount, no_payments):
        loc = "//*[@id='pmtTable']/tbody/tr/td[2]/div//input[@value= '{}']"
        values = int(amount)/int(no_payments)
        #global self.val
        values_1 = "{0:.2f}".format(values)
        self.val = str(values_1)
        locator =  loc.format(self.val)
        list_payments = self.selenium.get_webelements(locator)
        t_loc=len(list_payments)
        if  t_loc == int(no_payments):
            for i in list_payments:
                self.selenium.page_should_contain_element(i)             
            return str(t_loc)
        else:
            return str(t_loc)
       
    def verify_date_split(self,date, no_payments, interval): 
        ddate=[]  
        mm, dd, yyyy = date.split("/")
        mm, dd, yyyy = int(mm), int(dd), int(yyyy)
        locator = npsp_lex_locators['payments']['date_loc'].format(date)
        t_dates = self.selenium.get_webelement(locator)
        self.selenium.page_should_contain_element(t_dates)
#            for i in range(int(no_payments) + 1):
        if mm <= 12:
            date_list = [mm, dd, yyyy]
            dates = list(map(str, date_list))
            new_date = "/".join(dates)
            mm = mm + int(interval)
            dates = list(map(str, date_list))
            #if new_date not in t_dates: 
            locator1 = npsp_lex_locators['payments']['date_loc'].format(new_date)
            t_dates = self.selenium.get_webelement(locator1)                  
            self.selenium.page_should_contain_element(t_dates)
        elif mm > 12:
            yyyy = yyyy + 1
            mm = (mm + int(interval))-(12+int(interval))
            #return "pass"
#         else:
#             return "fail"
        
    def click_viewall_related_list (self,title):  
        """clicks on the View All link under the Related List"""      
        locator=npsp_lex_locators['record']['related']['viewall'].format(title)
        self.selenium.get_webelement(locator).click()
        
    def click_payments_button (self,title):  
        """clicks on the button on the payments page"""      
        locator=npsp_lex_locators['payments']['button'].format(title)
        self.selenium.get_webelement(locator).click()
        
#         
#     def verify_payments(self, amount,no_payments):
#         """To select a row on object page based on name and open the dropdown"""
#         locators = npsp_lex_locators['payments']['no_payments']
#         list_ele = self.selenium.get_webelements(locators)
#         t_count=len(list_ele)
#         for index, element in enumerate(list_ele):
#             if element.text == amount:
#                 loc = npsp_lex_locators['payments']['pay_amount'].format(index + 1, amount)
#                 self.selenium.page_should_contain_element(loc)
#                 time.sleep(1)
                
    def verify_occurance_payments(self,title,value=None):
        """"""
        locator=npsp_lex_locators['payments']['check_occurance'].format(title)
        occ_value=self.selenium.get_webelement(locator).text
        return occ_value        
        
        
    def verify_payment(self):
        locators=npsp_lex_locators['payments']['no_payments']
        list_ele=self.selenium.get_webelements(locators)
        for element in list_ele:
            payment_com=self.selenium.get_webelement(element).text
            cc=payment_com.replace("$","")
            if cc == str(self.val):
                pass
            return cc, self.val
#             else:
#                 return "fail"
#             if cc in self.payment_list:
#                 pass
#             else:
#                 return "fail"
        
    def testing(self):
        d=[]
        s= [1,2,3,4,5]
        for i in range(9):
            pass
            #d.append(i)
        return i
                
    """Copied below keywords from Salesforce Library"""    
        
#     def populate_lookup_field(self, name, value):
#         self.populate_field(name, value)
#         locator = npsp_lex_locators['field_lookup_value'].format(value)
#         #self._call_selenium('_populate_lookup_field', True, locator)
#         self.selenium.set_focus_to_element(locator)
#         self.selenium.get_webelement(locator).click() 
#         
#     def populate_form(self, **kwargs):
#         for name, value in kwargs.items():
#             locator = npsp_lex_locators['field'].format(name)
#             self.selenium.set_focus_to_element(locator)
#             field = self.selenium.get_webelement(locator)
#             field.clear()
#             field.send_keys(value)
#     
#     def populate_field(self, name, value):
#         locator = lex_locators['object']['field'].format(name) 
#         self.selenium.set_focus_to_element(locator)
#         field = self.selenium.get_webelement(locator)
#         field.clear()
#         field.send_keys(value)  
        