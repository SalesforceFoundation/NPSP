import glob
from xml.sax.saxutils import escape

import lxml.etree as ET

from cumulusci.core.tasks import BaseTask
from cumulusci.utils import cd
from cumulusci.utils import elementtree_parse_file


def salesforce_encoding(xdoc):
    r = ""
    xdoc.getroot().attrib["xmlns"] = "http://soap.sforce.com/2006/04/metadata"
    for action, elem in ET.iterwalk(xdoc, events=("start", "end", "start-ns",
                                                  "end-ns", "comment")):
        if action == 'start-ns':
            pass  # TODO: handle this nicely
        elif action == 'start':
            tag = elem.tag
            if "}" in tag:
                tag = tag.split("}")[1]
            text = (escape(elem.text, {"'": "&apos;", "\"": "&quot;"})
                    if elem.text is not None else "")
            attrs = "".join([' %s="%s"' % (k, v) for k, v in elem.attrib.items()])
            r += "<%s%s>%s" % (tag, attrs, text)
        elif action == 'end':
            tag = elem.tag
            if "}" in tag:
                tag = tag.split("}")[1]
            r += "</%s>%s" % (tag, elem.tail if elem.tail else "\n")
        elif action == 'comment':
            r += str(elem) + (elem.tail if elem.tail else "")
    return r


class RemoveElementsXPath(BaseTask):
    task_options = {
        "elements": {
            "description": "A list of dictionaries containing path and xpath keys. The path key is a file path that supports wildcards and xpath is the xpath for the elements to remove.  Multiple dictionaries can be passed in the list to run multiple removal queries in the same task.  Metadata elements in the xpath need to be prefixed with ns:, for example: ./ns:Layout/ns:relatedLists",
            "required": True,
        },
        "chdir": {
            "description": "Change the current directory before running the replace"
        },
        "output_style": {
            "description": "Output style to use: 'salesforce' or 'simple'",
            "required": False,
        }
    }

    def _run_task(self):
        chdir = self.options.get("chdir")
        if chdir:
            self.logger.info("Changing directory to {}".format(chdir))
        with cd(chdir):
            for element in self.options["elements"]:
                self._process_element(element,
                                      self.options.get("output_style", ""))

    def _process_element(self, step, output_style):
        self.logger.info(
            "Removing elements matching {xpath} from {path}".format(**step)
        )
        for f in glob.glob(step["path"], recursive=True):
            self.logger.info(f"Checking {f}")
            with open(f, "rb") as fp:
                orig = fp.read()
            root = ET.parse(f)
            res = root.xpath(
                step["xpath"],
                namespaces={"ns": "http://soap.sforce.com/2006/04/metadata",
                            "re": "http://exslt.org/regular-expressions"},
            )
            self.logger.info(f"Found {len(res)} matching elements")
            for element in res:
                element.getparent().remove(element)

            if output_style.lower() == "salesforce":
                xml_body = bytes(salesforce_encoding(root), "utf-8")
            else:
                xml_body = ET.tostring(root, encoding="utf-8") + "\n"

            processed = (
                    b'<?xml version="1.0" encoding="UTF-8"?>\n'
                    + xml_body
            )

            if orig != processed:
                self.logger.info("Modified {}".format(f))
                with open(f, "wb") as fp:
                    fp.write(processed)
