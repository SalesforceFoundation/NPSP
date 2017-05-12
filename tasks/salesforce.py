import os
from cumulusci.tasks.salesforce import UpdateAdminProfile as BaseUpdateAdminProfile
from cumulusci.utils import findReplace
from cumulusci.utils import findReplaceRegex

rt_visibility_template = """
<recordTypeVisibilities>
    <default>{}</default>
    <personAccountDefault>true</personAccountDefault>
    <recordType>{}</recordType>
    <visible>true</visible>
</recordTypeVisibilities>
"""

app_visibility_template = """
<applicationVisibilities>
    <default>{}</default>
    <application>{}</application>
    <visible>true</visible>
</applicationVisibilities>
"""

class UpdateAdminProfile(BaseUpdateAdminProfile):
        
    def _process_metadata(self):
        super(UpdateAdminProfile, self)._process_metadata()
        
        self._strip_access('recordTypeVisibilities')
        self._strip_access('applicationVisibilities')
        
        # Set record type visibilities
        self._set_record_type('Account.HH_Account', 'false')
        self._set_record_type('Account.Organization', 'true')
        self._set_record_type('Opportunity.NPSP_Default', 'true')
        self._set_app('Nonprofit_CRM','true')

    def _set_visibility(self, visibility_template, name, default):
        rt = visibility_template.format(default, name)
        findReplace(
            '<tabVisibilities>',
            '{}<tabVisibilities>'.format(rt),
            os.path.join(self.tempdir, 'profiles'),
            'Admin.profile',
            max=1,
        )

    def _strip_access(self,name):
        findReplaceRegex(
            '<{0}>([^\$]+)</{0}>'.format(name),
            '',
            os.path.join(self.tempdir, 'profiles'),
            'Admin.profile'
        )

    def _set_record_type(self,name,default):
        self._set_visibility(rt_visibility_template,name,default)

    def _set_app(self,name,default):
        self._set_visibility(app_visibility_template,name,default)