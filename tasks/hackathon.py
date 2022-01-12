from cumulusci.tasks.github.base import BaseGithubTask
from cumulusci.utils import (
    download_extract_github_from_repo,
    temporary_dir,
)
from cumulusci.utils.xml import metadata_tree
import json
from pathlib import Path
from pprint import pprint

# import sys
# sys.path.append("/Users/psadie/Workspaces/Cumulus/tasks/apexParser")

# from ApexLexer import ApexLexer
# from ApexParser import ApexParser
# from ApexParserListener import ApexParserListener
# from antlr4 import *

class MetaScoop(BaseGithubTask):

    temp_repo_path = ''

    def _run_task(self):
        # class_name = 'GE_GiftEntryController'
        # file_path = '/Users/psadie/Workspaces/Cumulus/force-app/main/default/classes/' + class_name + '.cls'
        # self.try_apex_parser(file_path)
        change_groups = self.brute_force()
        self.generate_release_notes(change_groups)

    def generate_release_notes(self, change_groups):
        critical_changes = '# Critical Changes'
        changes = '# Changes'
        issues_closed = '# Issues Closed'
        community_ideas_delivered = '# Community Ideas Delivered'
        features_intended_for_future_release = '# Features Intended for Future Release'
        features_for_elevate_customers = '# Features for Elevate Customers'
        new_metadata = '# New Metadata'
        deleted_metadata = '# Deleted Metadata'

        pr_description = (
            f'{critical_changes}\n'
            f'{changes}\n'
            f'{issues_closed}\n'
            f'{community_ideas_delivered}\n'
            f'{features_intended_for_future_release}\n'
            f'{features_for_elevate_customers}\n'
            f'{new_metadata}\n'
        )
        
        for group in change_groups:
            if group == 'Aura Components' and change_groups[group]:
                pr_description += f'- {group}\n'
                for change in change_groups[group]:
                    pr_description += f'  - {self.file_name_for_description(change)}\n'
            elif group == 'Apex Classes' and change_groups[group]:
                pr_description += '\n'
                pr_description += f'- {group}\n'
                for change in change_groups[group]:
                    pr_description += f'  - {self.file_name_for_description(change)}\n'
            elif group == 'Lightning Components' and change_groups[group]:
                pr_description += f'- {group}\n'
                for change in change_groups[group]:
                    pr_description += f'  - {self.file_name_for_description(change)}\n'
            elif group == 'Fields' and change_groups[group]:
                pr_description += '\n'
                pr_description += f'- {group}\n'
                for change in change_groups[group]:
                    pr_description += f'  - {self.file_name_for_description(change)}\n'
            elif group == 'Objects' and change_groups[group]:
                pr_description += '\n'
                pr_description += f'- {group}\n'
                for change in change_groups[group]:
                    pr_description += f'  - {self.file_name_for_description(change)}\n'
            elif group == 'Settings' and change_groups[group]:
                pr_description += '\n'
                pr_description += f'- {group}\n'
                for change in change_groups[group]:
                    pr_description += f'  - {self.file_name_for_description(change)}\n'
            elif group == 'Tabs' and change_groups[group]:
                pr_description += '\n'
                pr_description += f'- {group}\n'
                for change in change_groups[group]:
                    pr_description += f'  - {self.file_name_for_description(change)}\n'

        pr_description += (
            f'{deleted_metadata}\n'
        )

        for line in pr_description.split('\n'):
            print(line)

        # f = open('pr_description.txt', 'w')
        # f.write(pr_description)
        # f.close()

    def file_name_for_description(self, file_name):
        path = Path(file_name)
        return f'{path.stem}{path.suffix}'

    def try_apex_parser(self, file_path=None):
        if file_path is None:
            file_path = '/Users/psadie/Workspaces/Cumulus/force-app/main/default/classes/SomeNewlyGlobalClass.cls'
        is_it = self.is_apex_class_global(file_path)
        self.logger.info(f'Is the following apex class global? {file_path}')
        self.logger.info(f'{is_it}')
    
    def brute_force(self):
        local_set = self.get_relevant_local_files()
        repo_set = self.get_relevant_repo_files()

        relevant_changes = repo_set.difference(local_set)

        change_groups = {
            'Fields': [],
            'Objects': [],
            'Settings': [],
            'Tabs': [],
            'Lightning Components': [],
            'Aura Components': [],
            'Apex Classes': []
        }

        for change in relevant_changes:
            if '.cmp' in change:
                change_groups['Aura Components'].append(change)
            if '.cls' in change:
                change_groups['Apex Classes'].append(change)
            if '.js' in change and '/lwc/' in change:
                change_groups['Lightning Components'].append(change)

        # pprint(change_groups)

        return change_groups

    def get_relevant_repo_files(self):
        repo_set = self.build_temp_repo_directory_from('psadie/hackathon-example')
        return repo_set

    def get_relevant_local_files(self):
        local_set = set()

        # self.logger.info('Exposed LWCs in local directory')
        exposed_lwc_files = self.get_exposed_lwcs()
        local_set.update(exposed_lwc_files)
        # pprint(list(exposed_lwc_files))
        # pprint(len(list(exposed_lwc_files)))

        # self.logger.info('Global aura components in local directory')
        global_aura_components = self.get_global_aura_components()
        local_set.update(global_aura_components)
        # pprint(list(global_aura_components))
        # pprint(len((list(global_aura_components))))

        # self.logger.info('Global aura app components in local directory')
        global_app_components = self.get_global_aura_app_components()
        local_set.update(global_app_components)
        # pprint(list(global_app_components))
        # pprint(len((list(global_app_components))))

        # self.logger.info('Global aura event components in local directory')
        global_aura_event_components = self.get_global_aura_event_components()
        local_set.update(global_aura_event_components)
        # pprint(list(global_aura_event_components))
        # pprint(len((list(global_aura_event_components))))

        # self.logger.info('Global aura interface components in local directory')
        global_aura_interface_components = self.get_global_aura_interface_components()
        local_set.update(global_aura_interface_components)
        # pprint(list(global_aura_interface_components))
        # pprint(len((list(global_aura_interface_components))))

        # self.logger.info('Global apex classes in local directory')
        global_apex_classes = self.get_global_apex_classes()
        local_set.update(global_apex_classes)
        # pprint(list(global_apex_classes))
        # pprint(len((list(global_apex_classes))))

        # self.logger.info('All visualforce pages')
        # visualforce_pages = self.get_visualforce_pages()
        # pprint(list(visualforce_pages))
        # pprint(len((list(visualforce_pages))))

        return local_set

    def get_exposed_lwcs(self, directory=None):
        exposed_lwc_files = []
        if directory is None:
            directory = self.get_default_directory_path()
        lwc_files = directory.glob('**/*.js-meta.xml')
        for lwc_file in lwc_files:
            lwc_metadata = metadata_tree.parse(open(lwc_file))
            if lwc_metadata.isExposed.text.lower() == 'true':
                file_name = self.get_diffable_file_name(str(lwc_file))
                exposed_lwc_files.append(file_name)
        return exposed_lwc_files

    def get_global_aura_components(self, directory=None):
        global_aura_components = []
        if directory is None:
            directory = self.get_default_directory_path()
        aura_component_files = directory.glob('**/*.cmp-meta.xml')
        for aura_component_file in aura_component_files:
            file_path = self.get_component_file_path(str(aura_component_file))
            contents = Path(file_path).read_text()
            if self.is_global_aura_component(contents):
                file_name = self.get_diffable_file_name(str(aura_component_file))
                global_aura_components.append(file_name)
        return global_aura_components

    def get_global_aura_app_components(self, directory=None):
        global_app_components = []
        if directory is None:
            directory = self.get_default_directory_path()
        app_component_files = directory.glob('**/*.app-meta.xml')
        for app_component_file in app_component_files:
            file_path = self.get_component_file_path(str(app_component_file))
            if Path(file_path).exists():
                contents = Path(file_path).read_text()
                if self.is_global_aura_component(contents):
                    file_name = self.get_diffable_file_name(str(app_component_file))
                    global_app_components.append(file_name)
        return global_app_components

    def get_global_aura_event_components(self, directory=None):
        aura_event_components = []
        if directory is None:
            directory = self.get_default_directory_path()
        event_component_files = directory.glob('**/*.evt-meta.xml')
        for event_component_file in event_component_files:
            file_path = self.get_component_file_path(str(event_component_file))
            if Path(file_path).exists():
                contents = Path(file_path).read_text()
                if self.is_global_aura_component(contents):
                    file_name = self.get_diffable_file_name(str(event_component_file))
                    aura_event_components.append(file_name)
        return aura_event_components

    def get_global_aura_interface_components(self, directory=None):
        aura_interface_components = []
        if directory is None:
            directory = self.get_default_directory_path()
        interface_component_files = directory.glob('**/*.intf-meta.xml')
        for interface_component_file in interface_component_files:
            file_path = self.get_component_file_path(str(interface_component_file))
            if Path(file_path).exists():
                contents = Path(file_path).read_text()
                if self.is_global_aura_component(contents):
                    file_name = self.get_diffable_file_name(str(interface_component_file))
                    aura_interface_components.append(file_name)
        return aura_interface_components

    # Notes:
    # Gotta figure out where and how visualforce pages may be considered "global".
    # Might be prohibitively difficult to figure out when a page is "global", used in a point-click capacity, etc.
    def get_visualforce_pages(self, directory=None):
        visualforce_pages = []
        if directory is None:
            directory = self.get_default_directory_path()
        visualforce_page_files = directory.glob('**/*.page-meta.xml')
        for visualforce_page_file in visualforce_page_files:
            visualforce_pages.append(visualforce_page_file)
        return visualforce_pages

    def get_global_apex_classes(self, directory=None):
        apex_classes = []
        if directory is None:
            directory = self.get_default_directory_path()
        apex_class_files = directory.glob('**/*.cls-meta.xml')
        for apex_class_file in apex_class_files:
            file_path = self.get_component_file_path(str(apex_class_file))
            if Path(file_path).exists():
                contents = Path(file_path).read_text()
                if self.is_global_apex_class(contents):
                    file_name = self.get_diffable_file_name(str(apex_class_file))
                    apex_classes.append(file_name)
        return apex_classes

    def get_default_directory_path(self):
        directories = json.load(open('sfdx-project.json'))['packageDirectories']
        default_directory_path = '/'
        for directory in directories:
            if directory['default'] == True:
                default_directory_path = directory['path']
                break
        return Path(default_directory_path)

    def is_global_apex_class(self, contents):
        contents = contents.lower()
        return ('global with sharing' in contents
            or 'global without sharing' in contents
            or 'global inherited sharing' in contents
            or 'global abstract' in contents
            or 'global virtual' in contents
            or 'global static' in contents
            or 'global enum' in contents
            or 'global class' in contents)

    def is_global_aura_component(self, component_contents):
        component_contents = component_contents.lower()
        return ('access="global"' in component_contents
            or "access='global'" in component_contents)

    def get_component_file_path(self, file_path):
        file_name = ''
        file_name = file_path.removesuffix('-meta.xml')
        return file_name
    
    def get_diffable_file_name(self, file_path):
        file_name = ''
        file_name = file_path.removeprefix(self.temp_repo_path + '/')
        file_name = file_name.removesuffix('-meta.xml')
        return file_name

    # TODO: This doesn't seem to retrieve the expected branch
    def build_temp_repo_directory_from(self, branch_name=None):
        self.logger.info('Extracting files from repo...')
        repo = self.get_repo()
        zf = download_extract_github_from_repo(repo, None, branch_name)

        self.logger.info('Creating temporary directory...')

        repo_set = set()

        with temporary_dir() as temp_dir:
            zf.extractall(temp_dir)

            # self.logger.info('Exposed LWCs in repo')
            self.temp_repo_path = temp_dir
            # pprint('temp repo path: ' + self.temp_repo_path)
            repo_directory = Path(temp_dir)

            exposed_lwc_files = self.get_exposed_lwcs(repo_directory)
            repo_set.update(exposed_lwc_files)
            # pprint(list(exposed_lwc_files))
            # pprint(len(list(exposed_lwc_files)))

            # self.logger.info('Global aura components in repo')
            global_aura_components = self.get_global_aura_components(repo_directory)
            repo_set.update(global_aura_components)
            # pprint(list(global_aura_components))
            # pprint(len(global_aura_components))

            # self.logger.info('Global aura app components in repo')
            global_app_components = self.get_global_aura_app_components(repo_directory)
            repo_set.update(global_app_components)
            # pprint(list(global_app_components))
            # pprint(len(global_app_components))

            # self.logger.info('Global aura event components in repo')
            global_aura_event_components = self.get_global_aura_event_components(repo_directory)
            repo_set.update(global_aura_event_components)
            # pprint(list(global_aura_event_components))
            # pprint(len(global_aura_event_components))

            # self.logger.info('Global aura interface components in repo')
            global_aura_interface_components = self.get_global_aura_interface_components(repo_directory)
            repo_set.update(global_aura_interface_components)
            # pprint(list(global_aura_interface_components))
            # pprint(len(global_aura_interface_components))

            # self.logger.info('Global apex classes in repo')
            global_apex_classes = self.get_global_apex_classes(repo_directory)
            repo_set.update(global_apex_classes)
            # pprint(list(global_apex_classes))
            # pprint(len(global_apex_classes))

        return repo_set

    def is_apex_class_global(self, file_path):
        parse_tree = self.build_parse_tree(file_path)
        apex_parser_listener = self.walk_tree(parse_tree)

        # type_declarations = apex_parser_listener.enterTypeDeclaration(parse_tree)
        # for type_declaration in type_declarations:
        #     if hasattr(type_declaration, 'children'):
        #         type_contexts = type_declaration.children
        #         for type_context in type_contexts:
        #             if type_context.getText().lower() == 'global':
        #                 return True
        # return False
        return self.walk_type_declarations(parse_tree, apex_parser_listener)
    
    def build_parse_tree(self, file_path):
        input_stream = FileStream(file_path)
        lexer = ApexLexer(input_stream)
        stream = CommonTokenStream(lexer)
        parser = ApexParser(stream)
        parse_tree = parser.compilationUnit()
        return parse_tree
    
    def walk_tree(self, parse_tree):
        apex_parser_listener = ApexParserListener()
        parse_walker = ParseTreeWalker()
        parse_walker.walk(apex_parser_listener, parse_tree)
        return apex_parser_listener

    def walk_type_declarations(self, parse_tree, apex_parser_listener):
        type_declarations = apex_parser_listener.enterTypeDeclaration(parse_tree)
        for type_declaration in type_declarations:
            if hasattr(type_declaration, 'children'):
                type_contexts = type_declaration.children
                for type_context in type_contexts:
                    if type_context.getText().lower() == 'global':
                        return True
        return False

    def log_properties_for(self, object):
        object_properties = [method_name for method_name in dir(object)]
        self.logger.info(f'Properties: {object_properties}')
