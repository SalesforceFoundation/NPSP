public with sharing class ERR_ExceptionHandler {
    private static final Map<String, String> exceptionMessages = new Map<String, String>{
        'FIELD_CUSTOM_VALIDATION_EXCEPTION' => 'A validation rule is preventing the record from saving: ',
        'REQUIRED_FIELD_MISSING' => 'A required field is missing: '
    };

    public static void beautifyException(Exception ex) {
        String message = ex.getMessage();
        for (String status : exceptionMessages.keySet()) {
            if (message.contains(status)) {
                message = exceptionMessages.get(status) + message.substringBetween(status, ':');
                ex.setMessage(message);
            }
        }
    }
}