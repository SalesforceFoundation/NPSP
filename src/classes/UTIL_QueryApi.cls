public class UTIL_QueryApi {

	public interface Finder {
		List<sObject> find();
		Boolean isSoql();
	}
}