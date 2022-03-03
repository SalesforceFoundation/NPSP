public without sharing virtual class Clock {

    public virtual Datetime timeStamp() {
        return System.now();
    }

    public virtual Long getCurrentTimeMillis() {
        return System.currentTimeMillis();
    }

}