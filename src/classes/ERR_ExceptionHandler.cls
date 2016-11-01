public with sharing class ERR_ExceptionHandler {
    private static final Map<String, String> exceptionMessages = new Map<String, String>{
        'FIELD_CUSTOM_VALIDATION_EXCEPTION, ' => 'A validation rule is preventing the record from saving: ',
        'REQUIRED_FIELD_MISSING, ' => 'A required field is missing: '
    };

    public static void beautifyExceptionMessage(Exception ex) {
        String message = ex.getMessage();
        for (String status : exceptionMessages.keySet()) {
            if (message.contains(status)) {
                message = exceptionMessages.get(status) + message.substringBetween(status, ':');
                ex.setMessage(message);
                break;
            }
        }
    }

    //is this an exception we can or already have handled?
    public static Boolean isHandledException(Exception ex) {
        for (String status : exceptionMessages.keySet()) {
            if (ex.getMessage().contains(status) || ex.getMessage().contains(exceptionMessages.get(status))) {
                return true;
            }
        }
        return false;
    }
}