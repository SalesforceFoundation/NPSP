import os
import re
import fnmatch
import ConfigParser

patterns = {
    'namespace': r'<namespace>(\w+)</namespace>',
    'major': r'<majorNumber>(\d+)</majorNumber>',
    'minor': r'<minorNumber>(\d+)</minorNumber>',
}

config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)),'cumulus.cfg')
root_dir = os.path.abspath(os.path.join(os.path.abspath(__file__),os.path.pardir,os.path.pardir))
src_dir = os.path.join(root_dir,'src')
readme_file = os.path.join(root_dir,'README.md')
#build_xml_file = os.path.join(root_dir,'build.xml')
version_properties_file = os.path.join(root_dir,'version.properties')

def get_meta_files():
    matches = []
    for root, dirnames, filenames in os.walk(src_dir):
        for filename in fnmatch.filter(filenames, '*-meta.xml'):
            matches.append(os.path.join(root, filename))
    return matches

def update_meta_files(files):
    for fname in files:
        print "Checking %s" % fname
        changed = False
    
        output = []
        metafile = open(fname, 'r')
        namespace = None

        # This dictionary is used to allow differences in element ordering.  For example,
        # namespace may come after major/minor and thus we have to queue up the namespace,
        # major, and minor lines to process once all 3 are collected.
        namespace_lines = {}

        # Loop through the lines in the file
        for line in metafile.readlines():
            output_line = line
   
            # Look for values we need to check
            line_namespace = re.findall(patterns['namespace'], line)
            line_major = re.findall(patterns['major'], line)
            line_minor = re.findall(patterns['minor'], line)
  
            if line_namespace or line_major or line_minor:
                if line_namespace:
                    # Set the namespace
                    namespace = line_namespace[0]
                    namespace_lines['namespace'] = {'value': namespace, 'line': line}
                
                elif line_major:
                    namespace_lines['major'] = {'value': line_major[0], 'line': line}
        
                elif line_minor:
                    namespace_lines['minor'] = {'value': line_minor[0], 'line': line}

                if len(namespace_lines) == 3:
                    # We have a namespace, major, and minor version number, output it

                    # Namespace line is unchanged
                    output.append(namespace_lines['namespace']['line'])

                    # Check if major needs changed and if so, change it
                    major = str(int(namespace_lines['major']['value']))
                    cfg_major = str(config.getint(namespace, 'major'))
                    if major != cfg_major:
                        changed = True
                        print 'Updated %s majorNumber from %s to %s' % (namespace, major, cfg_major)
                        output.append(namespace_lines['major']['line'].replace(major, cfg_major))
                    else:
                        output.append(namespace_lines['major']['line'])

                    # Check if minor needs changed and if so, change it
                    minor = str(int(namespace_lines['minor']['value']))
                    cfg_minor = str(config.getint(namespace, 'minor'))
                    if minor != cfg_minor:
                        changed = True
                        print 'Updated %s minorNumber from %s to %s' % (namespace, minor, cfg_minor)
                        output.append(namespace_lines['minor']['line'].replace(minor, cfg_minor))
                    else:
                        output.append(namespace_lines['minor']['line'])

                    namespace = None
                    namespace_lines = {}

                continue
    
            output.append(output_line)

        metafile.close()

        if changed:
            # Write the updated file only if it was changed
            outfile = open(fname,'w')
            outfile.writelines(output)
            outfile.close()
  
def update_readme_links():
    print 'Checking install urls in README.md'
    readme = open(readme_file, 'r').read()
    orig_readme = readme
    for section in config.sections():
        search = r'\[(%s)\]\((.*)\)' % config.get(section, 'name')
        replace = r'[\1](%s)' % config.get(section, 'install_url')
        readme = re.sub(search, replace, readme)
    if orig_readme != readme:
        print 'Updated install urls in README.md'
        open(readme_file, 'w').write(readme)    

#def update_build_xml_versions():
#    print 'Checking installPackage versions in build.xml'
#    build_xml = open(build_xml_file, 'r').read()
#    orig_build_xml = build_xml
#    for section in config.sections():
#        search = r'(<property.*name="version.%s".*value=)"(\d+\.\d+)"' % section
#        full_version = '%s.%s' % (config.get(section, 'major'), config.get(section, 'minor')) 
#        replace = r'\1"%s"' % full_version
#        build_xml = re.sub(search, replace, build_xml)
#    if orig_build_xml != build_xml:
#        print 'Updated installPackage versions in build.xml'
#        open(build_xml_file, 'w').write(build_xml)

def update_version_properties():
    print "Checking version.properties file"
    props = open(version_properties_file, 'r').read()
    orig_props = props
    for section in config.sections():
        search = r'version\.%s=(.*)' % section
        full_version = '%s.%s' % (config.get(section, 'major'), config.get(section, 'minor')) 
        replace = r'version.%s=%s' % (section, full_version)
        props = re.sub(search, replace, props)
    if orig_props != props:
        print 'Updated version.properites with new managed package versions'
        open(version_properties_file, 'w').write(props)
    
def main():
    # Parse the config file
    global config;
    config = ConfigParser.ConfigParser()
    config.readfp(open(config_file))

    files = get_meta_files()
    update_meta_files(files)
    update_readme_links()
    update_version_properties()

if __name__ == '__main__':
  main()
