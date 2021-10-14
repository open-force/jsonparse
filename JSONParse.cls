/*
MIT License

Copyright (c) 2018 open-force

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
/**
 * Utility class to streamline parsing nested JSON data structures.
 *
 * @see https://github.com/open-force/jsonparse
 */
public with sharing class JSONParse {

	private static final Pattern ARRAY_NOTATION = Pattern.compile('\\[(\\d+)]');

	public static String SEPARATOR = '\\.';

	/**
	 * Every JSONParse instance is a wrapper around some actual data, which we store here.
	 */
	private Object value;

	/**
	 * Create a JSONParse instance from a serialized JSON string.
	 *
	 * @param jsonData JSON data to parse
	 */
	public JSONParse(String jsonData) {
		value = JSON.deserializeUntyped(jsonData);
	}

	/**
	 * Create a JSONParse instance from data that has already been unmarshalled from a JSON string.
	 *
	 * @param value An already-decoded value (such as a Map<String,Object>, or List<Object>, or a primitive)
	 */
	private JSONParse(Object value) {
		this.value = value;
	}

	// ---------------------------------------
	// ------ Interactions -------------------
	// ---------------------------------------

	/**
	 * Drill into a nested structure to get to some subtree in the document. We allow the path to include a mix
	 * of array notation and string keys.
	 *
	 * @param path Specially-formatted string that describes where to find a data value
	 *
	 * @return A new JSONParse wrapper that wraps the targeted subtree.
	 * @throws NotAnArrayException if we try to apply an array notation to a node that isn't an array
	 * @throws NotAnObjectException if we try to apply a map key to a node that isn't an object
	 * @throws MissingKeyException if part of the path can't be resolved because there is no match on that key
	 * @throws ListException if part of the path can't be resolved because an array index is used that is out of bounds
	 */
	public JSONParse get(String path) {

		JSONParse currentNode = this; // we start with ourselves and drill deeper

		// drill down through the nested structure
		for(String key : path.split(SEPARATOR)) {

			// check to see if we are going to parse this key as a reference to an array item
			Matcher arrayMatcher = ARRAY_NOTATION.matcher(key);

			if(arrayMatcher.matches()) {

				Integer index = Integer.valueOf(arrayMatcher.group(1));
				currentNode = currentNode.asList().get(index);
			}
			else { // otherwise, treat this key as a normal map key

				Map<String, JSONParse> wrappedMap = currentNode.asMap();

				if(!wrappedMap.containsKey(key)) {
					throw new MissingKeyException('No match found for <' + key + '>: ' + wrappedMap.keySet());
				}

				currentNode = wrappedMap.get(key);
			}
		}

		return currentNode;
	}

	/**
	 * Test a get() path to see if that final property exists or not.
	 *
	 * @param path Specially-formatted string that describes where to find a data value
	 *
	 * @return True if the property exists, or false if the property or any part of the path didn't exist.
	 */
	public Boolean exists(String path) {
		return exists(path, false);
	}

	/**
	 * Test a get() path to see if that final property exists or not.
	 *
	 * @param path Specially-formatted string that describes where to find a data value
	 * @param notNull If true, this check will also assert the resulting value is not null
	 *
	 * @return True if the property exists, or false if the property or any part of the path didn't exist.
	 */
	public Boolean exists(String path, Boolean notNull) {

		JSONParse currentNode = this; // we start with ourselves and drill deeper

		// drill down through the nested structure
		for(String key : path.split(SEPARATOR)) {

			// check to see if we are going to parse this key as a reference to an array item
			Matcher arrayMatcher = ARRAY_NOTATION.matcher(key);

			if(arrayMatcher.matches()) {

				Integer index = Integer.valueOf(arrayMatcher.group(1));
				List<JSONParse> nodeAsList = currentNode.asList();
				if(0 < index && index < nodeAsList.size()) {
					currentNode = currentNode.asList().get(index);
				}
				else {
					return false; // index out of bounds
				}
			}
			else { // otherwise, treat this key as a normal map key

				Map<String, JSONParse> wrappedMap = currentNode.asMap();

				if(!wrappedMap.containsKey(key)) {
					return false; // map missing key
				}

				currentNode = wrappedMap.get(key);
			}
		}

		if(notNull == true) {
			return currentNode.getValue() != null;
		}

		return true; // found a node
	}

	/**
	 * Make an assumption that this JSONParse instance wraps a JSON object, and attempt to return a Map of the values.
	 *
	 * @return A Map of JSONParse instances
	 * @throws NotAnObjectException if the internal wrapped value is not a JSON object
	 */
	public Map<String, JSONParse> asMap() {
		if(!isObject()) {
			throw new NotAnObjectException('The wrapped value is not a JSON object:\n' + toStringPretty());
		}

		Map<String, Object> valueAsMap = (Map<String, Object>)value;
		Map<String, JSONParse> wrappers = new Map<String, JSONParse>();
		for(String key : valueAsMap.keySet()) {
			wrappers.put(key, new JSONParse(valueAsMap.get(key)));
		}

		return wrappers;
	}

	/**
	 * Make an assumption that this JSONParse instance wraps a List, and attempt to return an iterable version
	 * of the values.
	 *
	 * @return A List of JSONParse instances, each wrapping one of the List items
	 * @throws NotAnArrayException if the internal wrapped value is not a List instance
	 */
	public List<JSONParse> asList() {
		if(!isArray()) {
			throw new NotAnArrayException('The wrapped value is not a JSON array:\n' + toStringPretty());
		}

		List<JSONParse> wrappers = new List<JSONParse>();
		for(Object item : (List<Object>)value) {
			wrappers.add(new JSONParse(item));
		}

		return wrappers;
	}

	// ---------------------------------------
	// ------ Utility ------------------------
	// ---------------------------------------

	public Boolean isObject() {
		return value instanceof Map<String, Object>;
	}

	public Boolean isArray() {
		return value instanceof List<Object>;
	}

	public String toStringPretty() {
		return JSON.serializePretty(value);
	}

	// ---------------------------------------
	// ------ Value Extraction ---------------
	// ---------------------------------------

	public Blob getBlobValue() {
		if(value instanceof String) {
			return EncodingUtil.base64Decode((String)value);
		}
		throw new InvalidConversionException('Only String values can be converted to a Blob: ' + toStringPretty());
	}

	public Boolean getBooleanValue() {
		if(value instanceof Boolean) {
			return (Boolean)value;
		}
		return Boolean.valueOf(value);
	}

	public Datetime getDatetimeValue() {
		if(value instanceof Long) {
			return Datetime.newInstance((Long)value);
		}
		if(value instanceof String) {
			return Datetime.valueOfGmt(((String)value).replace('T', ' '));
		}
		throw new InvalidConversionException('Only Long and String values can be converted to a Datetime: ' + toStringPretty());
	}

	public Date getDateValue() {
		if(value instanceof Long) {
			return Datetime.newInstance((Long)value).dateGmt();
		}
		if(value instanceof String) {
			return Date.valueOf((String)value);
		}
		throw new InvalidConversionException('Only Long and String values can be converted to a Date: ' + toStringPretty());
	}

	public Decimal getDecimalValue() {
		if(value instanceof Decimal) {
			return (Decimal)value;
		}
		if(value instanceof String) {
			return Decimal.valueOf((String)value);
		}
		throw new InvalidConversionException('This value cannot be converted to a Decimal: ' + toStringPretty());
	}

	public Double getDoubleValue() {
		if(value instanceof Double) {
			return (Double)value;
		}
		if(value instanceof String) {
			return Double.valueOf((String)value);
		}
		throw new InvalidConversionException('This value cannot be converted to a Double: ' + toStringPretty());
	}

	public Id getIdValue() {
		if(value instanceof String) {
			return Id.valueOf((String)value);
		}
		throw new InvalidConversionException('This value cannot be converted to an Id: ' + toStringPretty());
	}

	public Integer getIntegerValue() {
		if(value instanceof Integer) {
			return (Integer)value;
		}
		if(value instanceof Decimal) {
			return ((Decimal)value).intValue();
		}
		if(value instanceof String) {
			return Integer.valueOf((String)value);
		}
		throw new InvalidConversionException('This value cannot be converted to an Integer: ' + toStringPretty());
	}

	public Long getLongValue() {
		if(value instanceof Long) {
			return (Long)value;
		}
		if(value instanceof Decimal) {
			return ((Decimal)value).longValue();
		}
		if(value instanceof String) {
			return Long.valueOf((String)value);
		}
		throw new InvalidConversionException('This value cannot be converted to a Long: ' + toStringPretty());
	}

	public String getStringValue() {
		if(isObject() || isArray()) {
			throw new InvalidConversionException('Objects and arrays are not Strings: ' + toStringPretty());
		}
		if(value instanceof String) {
			return (String)value;
		}
		return String.valueOf(value);
	}

	public Time getTimeValue() {
		if(value instanceof Long) {
			return Datetime.newInstance((Long)value).timeGmt();
		}
		if(value instanceof String) {
			return Datetime.valueOfGmt(((String)value).replace('T', ' ')).timeGmt();
		}
		throw new InvalidConversionException('Only Long and String values can be converted to a Time: ' + toStringPretty());
	}

	public Object getValue() {
		return value;
	}

	// ---------------------------------------
	// ------ Exceptions ---------------------
	// ---------------------------------------
	public class NotAnObjectException extends Exception {}
	public class NotAnArrayException extends Exception {}
	public class MissingKeyException extends Exception {}
	public class InvalidConversionException extends Exception {}
}
