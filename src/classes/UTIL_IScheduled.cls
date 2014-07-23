global Interface UTIL_IScheduled {

     //Keeping the method just because it won't let us change the signature of an existing method
     //of a global class in a managed package. We wanted to change the return type.
     void execute(SchedulableContext context);
     
     Boolean executeIfYouCan(SchedulableContext context);
}