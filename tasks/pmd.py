from cumulusci.core.exceptions import CommandException
from cumulusci.core.tasks import BaseTask
from cumulusci.core.utils import process_bool_arg
import os
import re
from subprocess import Popen, PIPE

class pmd(BaseTask):
    name = 'pmd'
    task_options = {
        'path': {
            'description': 'The local path to run PMD against. Defaults to src/classes',
            'required': False
        },
        'output': {
            'description': 'The report type to the output. Available options are text and html. The html report type creates a file in the current working directory. Defaults to text.',
            'required': False
        },
        'htmlfilename': {
            'description': 'The name of the html file to be written to the directory. This only applies if the output is html. Defaults to pmd.html',
            'required': False
        },
        'runAllApex' : {
            'description': 'If True, runs the entire path specified instead of just changed files',
            'required': False
        }
    }

    def _init_options(self, kwargs):
        super(pmd, self)._init_options(kwargs)
        if 'path' not in self.options:
            self.options['path'] = 'src/classes'
        if 'output' not in self.options:
            self.options['output'] = 'text'
        if self.options['output'] not in {'text', 'html'}:
            self.options['output'] = 'text'
        if 'htmlfilename' not in self.options:
            self.options['htmlfilename'] = 'pmd.html'
        if 'runAllApex' not in self.options:
            self.options['runAllApex'] = False

    def _run_task(self):
        if not process_bool_arg(self.options.get('runAllApex', True)):
            #create CSV file and save list of changed files
            fr = open('changedFiles.txt', 'r')
            git = "git status --porcelain | sed s/^...// > changedFiles.txt"
            Popen((git, os.getcwd() ), stdout=PIPE, stderr=PIPE, shell=True)
            #filter for specific file types
            filteredList = []
            for line in fr:
                #if re.match(".+\.(cls|js|cmp)$", line): --> look at adding support for lightning components
                if re.match(".+\.(cls)$", line):
                    filteredList.append(line)
            fw = open('filteredFiles.txt', 'w')
            fw.write(','.join(filteredList))
            fr.close()
            fw.close()

            args = [
                'pmd', 'pmd',
                '-filelist', 'filteredFiles.txt',
                '-l', 'apex',
                '-f', self.options['output'],
                '-R', 'apex-apexunit,apex-performance,apex-complexity,apex-style,apex-security',
                '-failOnViolation', 'false'
            ]
        else:
            args = [
                'pmd', 'pmd',
                '-d', self.options['path'],
                '-l', 'apex',
                '-f', self.options['output'],
                '-R', 'apex-apexunit,apex-performance,apex-complexity,apex-style,apex-security',
                '-failOnViolation', 'false'
            ]

        stdout = None
        if self.options['output'] == 'html':
            stdout = open(self.options['htmlfilename'], 'w')

        process = Popen(args, stdout=stdout, stderr=PIPE)

        _, stderr = process.communicate()
        returncode = process.returncode

        if returncode:
            message = 'Return code: {}\nstderr: {}'.format(returncode, stderr)
            self.logger.error(message)
            raise CommandException(message)

        os.remove('changedFiles.txt')
        os.remove('filteredFiles.txt')