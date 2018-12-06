public with sharing class UTIL_HtmlOutput_CTRL {
    private static final Map<String, String> SUBSTITUTION_BY_ALLOWED_TAG = new Map<String, String> {
        '<br/>' => '|break|',
        '<b>' => '|startBold|',
        '<b/>' => '|endBold|'
    };
    public String label { 
        get; 
        set {
            if (value != null) {
                label = value;
            }
        }
    }
    private static final Map<String, List<String>> FORMATTING_ARGUMENTS_BY_LABEL = new Map<String, List<String>>{
        'stgHelpSalesforceSetup' => new List<String>{ '<a href="/setup/forcecomHomepage.apexp?setupid=ForceCom" target="_blank">', '</a>' }
    };

    public String getSafeHtml() {
        if (String.isBlank(label)) {
            return '';
        }

        String labelBody = getLabelBody();

        for (String allowedTag : SUBSTITUTION_BY_ALLOWED_TAG.keySet()) {
            labelBody.replace(allowedTag, SUBSTITUTION_BY_ALLOWED_TAG.get(allowedTag));
        }
        labelBody = labelBody.escapeHtml4();
        for (String allowedTag : SUBSTITUTION_BY_ALLOWED_TAG.keySet()) {
            labelBody.replace(SUBSTITUTION_BY_ALLOWED_TAG.get(allowedTag), allowedTag);
        }

        if (FORMATTING_ARGUMENTS_BY_LABEL.containsKey(label)) {
            labelBody = String.format(labelBody, FORMATTING_ARGUMENTS_BY_LABEL.get(label));
        }
        return labelBody;
    }

    private String getLabelBody() {
        Component.Apex.OutputText output = new Component.Apex.OutputText();

        output.expressions.value = '{!$Label.' + label + '}';
        return String.valueOf(output.value);
    }
}
