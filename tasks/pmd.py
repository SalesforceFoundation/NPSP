from cumulusci.core.exceptions import CommandException
from cumulusci.core.tasks import BaseTask
from cumulusci.core.utils import process_bool_arg
import os
import re
from subprocess import Popen, PIPE

class PMDTask(BaseTask):
    name = 'PMDTask'
    task_options = {
        'path': {
            'description': 'The local path to run PMD against. Defaults to src/classes',
            'required': True
        },
        'output': {
            'description': 'The report type to the output. Available options are text and html. The html report type creates a file in the current working directory. Defaults to text.',
            'required': True
        },
        'htmlfilename': {
            'description': 'The name of the html file to be written to the directory. This only applies if the output is html. Defaults to pmd.html',
            'required': True
        },
        'runAllApex' : {
            'description': 'If True, runs the entire path specified instead of just changed files',
            'required': True
        }
    }

    def _init_options(self, kwargs):
        super(PMDTask, self)._init_options(kwargs)
        if self.options['output'] not in {'text', 'html'}:
            self.options['output'] = 'text'
        self.pmd_args = [
            'pmd', 'pmd',
            '-l', 'apex',
            '-f', self.options['output'],
            '-R', 'apex-apexunit,apex-performance,apex-complexity,apex-style,apex-security',
            '-failOnViolation', 'false'
        ]

    def _run_task(self):
        if not process_bool_arg(self.options.get('runAllApex', True)):
            #create CSV file and save list of changed files
            git_cmd = "touch changedFiles.txt | git status --porcelain | sed s/^...// > changedFiles.txt"
            p = Popen((git_cmd, os.getcwd()), stdout=PIPE, stderr=PIPE, shell=True)
            p.wait()

            with open('changedFiles.txt', 'r') as fr:
                # filter for specific file types
                filteredList = []
                for line in fr:
                    # if re.match(".+\.(cls|js|cmp)$", line): --> look at adding support for lightning components
                    if re.match(".+\.(cls)$", line):
                        filteredList.append(line)
                os.remove('changedFiles.txt')
                if not filteredList:
                    self.logger.warn('No valid file changes in this diff.')
                    return
            with open('filteredFiles.txt', 'w') as fw:
                fw.write(','.join(filteredList))
            self.pmd_args.extend(['-filelist', 'filteredFiles.txt'])
        else:
            self.pmd_args.extend(['-d', self.options['path']])

        pmd_out = None
        if self.options['output'] == 'html':
            pmd_out = open(self.options['htmlfilename'], 'w+')

        process = Popen(self.pmd_args, stdout=pmd_out, stderr=PIPE)

        _, stderr = process.communicate()
        returncode = process.returncode

        if os.path.isfile('filteredFiles.txt'):
            os.remove('filteredFiles.txt')

        if returncode:
            message = 'Return code: {}\nstderr: {}'.format(returncode, stderr)
            self.logger.error(message)
            raise CommandException(message)