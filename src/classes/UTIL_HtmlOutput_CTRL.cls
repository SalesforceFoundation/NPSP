public with sharing class UTIL_HtmlOutput_CTRL {
    private static final Map<String, String> SUBSTITUTION_BY_ALLOWED_TAG = new Map<String, String> {
        '<br>' => '|badBreak|',
        '<br/>' => '|break|',
        '<b>' => '|startBold|',
        '</b>' => '|endBold|'
    };
    private static final Map<String, String> SUBSTITUTION_BY_ALLOWED_URL = new Map<String, String> {
        '<a href="https://powerofus.force.com/' => '|hubURL|',
        'target="_blank">' => '|blankTarget|',
        '</a>' => '|endURL|',
        '<a href="/setup/' => '|setupURL|',
        '<a href="#" onclick="ShowPanel(\'idPanelHealthCheck\');return false;">' => '|showPanelHealthCheck|',
        '<a href="#" onclick="ShowPanel(\'idPanelErrorLog\');return false;">' => '|showPanelErrorLog|'
    };
    public String unsafeHtml { 
        get; 
        set {
            if (value != null) {
                unsafeHtml = value;
            }
        }
    }
    public Boolean hasURL {
        get; 
        set {
            if (value != null) {
                hasURL = value;
            } else {
                hasURL = false;
            }
        }
    }

    public String getSafeHtml() {
        if (String.isBlank(unsafeHtml)) {
            return '';
        }
        System.debug(unsafeHtml);

        for (String allowedTag : SUBSTITUTION_BY_ALLOWED_TAG.keySet()) {
            unsafeHtml = unsafeHtml.replace(allowedTag, SUBSTITUTION_BY_ALLOWED_TAG.get(allowedTag));
        }

        if (hasURL) {
            for (String allowedUrl : SUBSTITUTION_BY_ALLOWED_URL.keySet()) {
                unsafeHtml = unsafeHtml.replace(allowedUrl, SUBSTITUTION_BY_ALLOWED_URL.get(allowedUrl));
            }
        }

        unsafeHtml = unsafeHtml.escapeHtml4();

        for (String allowedTag : SUBSTITUTION_BY_ALLOWED_TAG.keySet()) {
            unsafeHtml = unsafeHtml.replace(SUBSTITUTION_BY_ALLOWED_TAG.get(allowedTag), allowedTag);
        }

        if (hasURL) {
            for (String allowedUrl : SUBSTITUTION_BY_ALLOWED_URL.keySet()) {
                unsafeHtml = unsafeHtml.replace(SUBSTITUTION_BY_ALLOWED_URL.get(allowedUrl), allowedUrl);
            }
        }
        System.debug(unsafeHtml);

        return unsafeHtml;
    }

}
