public without sharing abstract class Clock {

    public virtual Datetime timeStamp() {
        return System.now();
    }

    public virtual Long getCurrentTimeMillis() {
        return System.currentTimeMillis();
    }

}