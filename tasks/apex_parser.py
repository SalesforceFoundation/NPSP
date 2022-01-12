from cumulusci.tasks.github.base import BaseGithubTask
from pprint import pprint

import sys
sys.path.append("/Users/psadie/Workspaces/Cumulus/tasks/apexParser")

from ApexLexer import ApexLexer
from ApexParser import ApexParser
from ApexParserListener import ApexParserListener
from antlr4 import *

class ApexParser(BaseGithubTask):

    temp_repo_path = ''

    def _run_task(self):
        self.logger.info('Running Hackathon Task')
        is_it = self.is_apex_class_global('/Users/psadie/Workspaces/Cumulus/force-app/main/default/classes/SomeNewlyGlobalClass.cls')
        pprint(is_it)
        self.is_apex_class_global('/Users/psadie/Workspaces/Cumulus/force-app/main/default/classes/SomeNewlyGlobalClass.cls')

    def is_apex_class_global(self, file_path):
        input_stream = FileStream(file_path)
        lexer = ApexLexer(input_stream)
        stream = CommonTokenStream(lexer)
        parser = ApexParser(stream)
        parse_tree = parser.compilationUnit()
        apex_parser_listener = ApexParserListener()
        parse_walker = ParseTreeWalker()
        parse_walker.walk(apex_parser_listener, parse_tree)

        type_declarations = apex_parser_listener.enterTypeDeclaration(parse_tree)
        for type_declaration in type_declarations:
            if hasattr(type_declaration, 'children'):
                type_contexts = type_declaration.children
                for type_context in type_contexts:
                    if type_context.getText().lower() == 'global':
                        return True
        return False
