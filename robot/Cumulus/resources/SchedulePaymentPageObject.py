from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
import time
from cumulusci.robotframework.utils import capture_screenshot_on_error
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "SchedulePayment")
class SchedulePaymentPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Waits for the Schedule Payments iframe to load in the edit mode
        """
        self.npsp.wait_for_locator('frame','Create one or more Payments for this Opportunity')
        self.npsp.choose_frame('Create one or more Payments for this Opportunity')

    def enter_textfield_value(self, inputvalue):
        locator = self.npsp.get_npsp_locator('id', 'inputX')
        self.salesforce._populate_field(locator, inputvalue)

    def enter_payment_schedule(self, *args):

        id = ["paymentCount","vfForm:intervalnumber","intervalunits"]
        for i in range(len(args)):
            locator = npsp_lex_locators['id'].format(id[i])
            loc = self.selenium.get_webelement(locator)
            self.selenium.set_focus_to_element(locator)
            self.selenium.select_from_list_by_label(loc,args[i])
            time.sleep(2)

    def verify_payment_split(self, amount, no_payments):
        loc = "//*[@id='pmtTable']/tbody/tr/td[2]/div//input[@value= '{}']"
        values = int(amount)/int(no_payments)

        values_1 = "{:0.2f}".format(values)
        self.val = str(values_1)
        locator =  loc.format(self.val)
        list_payments = self.selenium.get_webelements(locator)
        self.t_loc=len(list_payments)
        if  self.t_loc == int(no_payments):
            for i in list_payments:
                self.selenium.page_should_contain_element(i)
            return str(self.t_loc)
        else:
            return str(self.t_loc)

    def verify_date_split(self,date, no_payments, interval):
        ddate=[]
        mm, dd, yyyy = date.split("/")
        mm, dd, yyyy = int(mm), int(dd), int(yyyy)
        locator = npsp_lex_locators['payments']['date_loc'].format(date)
        t_dates = self.selenium.get_webelement(locator)
        self.selenium.page_should_contain_element(t_dates)

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

    def verify_payment(self):
        locators=npsp_lex_locators['payments']['no_payments']
        list_ele=self.selenium.get_webelements(locators)
        l_no_payments = len(list_ele)

        for element in list_ele:
            payment_com=self.selenium.get_webelement(element).text
            cc=payment_com.replace("$","")
            if cc == str(self.val) and self.t_loc == l_no_payments :
                return 'pass'
            else:
                return "fail"