import os
import string
from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.core.exceptions import ApexCompilationException
from cumulusci.core.exceptions import ApexException
from cumulusci.core.exceptions import SalesforceException
from cumulusci.utils import findReplace


class AnonymousApexFromFileTask(BaseSalesforceApiTask):
    """ Executes anonymous apex from a file. """
    task_options = {
        'managed': {
            'description': 'If True, will insert the actual namespace prefix.  Defaults to False or no namespace',
            'required': False,
        },
        'namespaced': {
            'description': 'If True, the tokens %%%NAMESPACED_RT%%% and %%%namespaced%%% will get replaced with the namespace prefix for Record Types.',
            'required': False,
        },
        'path': {
            'description': 'The path to an Apex file to run.',
            'required': True,
        },
        'method': {
            'description': 'Options apex method to execute within the class specified by PATH.',
            'required': False,
        }
    }

    def _init_options(self, kwargs):
        super(AnonymousApexFromFileTask, self)._init_options(kwargs)

        if 'managed' not in self.options:
            self.options['managed'] = False

        if 'namespaced' not in self.options:
            self.options['namespaced'] = False

    def _run_task(self):

        managed = self.options['managed']
        namespaced = self.options['namespaced']
        path = self.options['path']
        pwd = os.getcwd()

        path = os.path.join(pwd, path)

        if not os.path.isdir( os.path.dirname(path) ):
            self.logger.warn('Path {} not found, skipping'.format(path))
            return

        self.logger.info('Getting Apex to run from {}'.format(
            self.options['path'],
        ))
        with open(path, 'r') as apex_content:
            apex = apex_content.read()

        # Process namespace tokens
        namespace = self.project_config.project__package__namespace
        namespace_prefix = ''
        record_type_prefix = ''

        if managed or namespaced:
            namespace_prefix = namespace + '__'

        if namespaced:
            record_type_prefix = namespace + '.'

        apex = apex.replace('%%%NAMESPACE%%%',namespace_prefix);
        apex = apex.replace('%%%NAMESPACED_ORG%%%',namespace_prefix);
        apex = apex.replace('%%%NAMESPACED_RT%%%',record_type_prefix);

        if apex and 'method' in self.options:
            apex = apex + ' ' + self.options['method']

        # self.logger.info(apex) # Too much to print out

        self.logger.info('Executing Anonymous Apex')
        result = self.tooling._call_salesforce(
            method='GET',
            url='{}executeAnonymous'.format(self.tooling.base_url),
            params={'anonymousBody': apex },
        )
        if result.status_code != 200:
            raise SalesforceGeneralError(url,
                                         path,
                                         result.status_code,
                                         result.content)
        # anon_results is an ExecuteAnonymous Result
        # https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/sforce_api_calls_executeanonymous_result.htm

        anon_results = result.json()
        if not anon_results['compiled']:
            raise ApexCompilationException(
                anon_results['line'], anon_results['compileProblem'])

        if not anon_results['success']:
            raise ApexException(
                anon_results['exceptionMessage'], anon_results['exceptionStackTrace'])

        self.logger.info('Anonymous Apex Success')