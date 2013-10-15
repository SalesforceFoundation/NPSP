import os
import re
import fnmatch
import ConfigParser

patterns = {
    'namespace': r'<namespace>(\w+)</namespace>',
    'major': r'<majorNumber>(\d+)</majorNumber>',
    'minor': r'<minorNumber>(\d+)</minorNumber>',
}

src_dir = os.path.abspath(os.path.join(os.path.abspath(__file__),os.path.pardir,os.path.pardir,'src'))

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

                    # Check if minor needs changed and if so, change it
                    minor = str(int(namespace_lines['minor']['value']))
                    cfg_minor = str(config.getint(namespace, 'minor'))
                    if minor != cfg_minor:
                        changed = True
                        print 'Updated %s minorNumber from %s to %s' % (namespace, minor, cfg_minor)
                        output.append(namespace_lines['minor']['line'].replace(minor, cfg_minor))

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
            
    
def main():
    # Parse the config file
    global config;
    config_file = os.path.dirname(os.path.abspath(__file__)) + '/cumulus.cfg'
    config = ConfigParser.ConfigParser()
    config.readfp(open(config_file))

    files = get_meta_files()
    update_meta_files(files)

if __name__ == '__main__':
  main()
