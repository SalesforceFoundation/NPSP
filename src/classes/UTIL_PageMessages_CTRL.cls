public class UTIL_PageMessages_CTRL {
    public List<Message> getPageMessages() {
        List<Message> pageMessages = new List<Message>();

        for (ApexPages.Message m : ApexPages.getMessages()) {
            pageMessages.add(new Message(m));
        }

        return pageMessages;
    }

    public class Message {
        public MessageSeverity severity {get; set;}
        public String summary {get; set;}
        public String detail {get; set;}
        public String componentLabel {get; set;}

        public Message(ApexPages.Message m) {
            this.summary = m.getSummary();
            this.detail = m.getDetail();
            this.componentLabel = m.getComponentLabel();

            ApexPages.Severity s = m.getSeverity();

            if (ApexPages.Severity.CONFIRM == s) {
                this.severity = MessageSeverity.CONFIRM;
            } else if (ApexPages.Severity.ERROR == s) {
                this.severity = MessageSeverity.ERROR;
            } else if (ApexPages.Severity.FATAL == s) {
                this.severity = MessageSeverity.FATAL;
            } else if (ApexPages.Severity.INFO == s) {
                this.severity = MessageSeverity.INFO;
            } else if (ApexPages.Severity.WARNING == s) {
                this.severity = MessageSeverity.WARNING;
            }
        }

        public String getSeverityTheme() {
            if (MessageSeverity.CONFIRM == severity) {
                return 'info';
            } else if (MessageSeverity.ERROR == severity) {
                return 'error';
            } else if (MessageSeverity.FATAL == severity) {
                return 'error';
            } else if (MessageSeverity.INFO == severity) {
                return 'info';
            } else if (MessageSeverity.WARNING == severity) {
                return 'warning';
            } else {
                return 'info';
            }
        }
    }

    public enum MessageSeverity {
        CONFIRM,
        ERROR,
        FATAL,
        INFO,
        WARNING
    }
}