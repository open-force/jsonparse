/**
 * Exercises the JSONParse class.
 */
@IsTest
private class JSONParseTests {

	// Some JSON samples from https://json.org/example.html
	public static final String SAMPLE1 = '{"menu":{"id":"file","value":"File","popup":{"menuitem":[{"value":"New","onclick":"CreateNewDoc()"},{"value":"Open","onclick":"OpenDoc()"},{"value":"Close","onclick":"CloseDoc()"}]}}}';
	public static final String SAMPLE2 = '{"widget":{"debug":"on","window":{"title":"SampleKonfabulatorWidget","name":"main_window","width":500,"height":500},"image":{"src":"Images/Sun.png","name":"sun1","hOffset":250,"vOffset":250,"alignment":"center"},"text":{"data":"ClickHere","size":36,"style":"bold","name":"text1","hOffset":250,"vOffset":100,"alignment":"center","onMouseUp":"sun1.opacity=(sun1.opacity/100)*90;"}}}';
	public static final String SAMPLE3 = '[{"servlet-name":"cofaxCDS","servlet-class":"org.cofax.cds.CDSServlet","init-param":{"configGlossary:installationAt":"Philadelphia,PA","configGlossary:adminEmail":"ksm@pobox.com","configGlossary:poweredBy":"Cofax","configGlossary:poweredByIcon":"/images/cofax.gif","configGlossary:staticPath":"/content/static","templateProcessorClass":"org.cofax.WysiwygTemplate","templateLoaderClass":"org.cofax.FilesTemplateLoader","templatePath":"templates","templateOverridePath":"","defaultListTemplate":"listTemplate.htm","defaultFileTemplate":"articleTemplate.htm","useJSP":false,"jspListTemplate":"listTemplate.jsp","jspFileTemplate":"articleTemplate.jsp","cachePackageTagsTrack":200,"cachePackageTagsStore":200,"cachePackageTagsRefresh":60,"cacheTemplatesTrack":100,"cacheTemplatesStore":50,"cacheTemplatesRefresh":15,"cachePagesTrack":200,"cachePagesStore":100,"cachePagesRefresh":10,"cachePagesDirtyRead":10,"searchEngineListTemplate":"forSearchEnginesList.htm","searchEngineFileTemplate":"forSearchEngines.htm","searchEngineRobotsDb":"WEB-INF/robots.db","useDataStore":true,"dataStoreClass":"org.cofax.SqlDataStore","redirectionClass":"org.cofax.SqlRedirection","dataStoreName":"cofax","dataStoreDriver":"com.microsoft.jdbc.sqlserver.SQLServerDriver","dataStoreUrl":"jdbc:microsoft:sqlserver://LOCALHOST:1433;DatabaseName=goon","dataStoreUser":"sa","dataStorePassword":"dataStoreTestQuery","dataStoreTestQuery":"SETNOCOUNTON;selecttest=\'test\';","dataStoreLogFile":"/usr/local/tomcat/logs/datastore.log","dataStoreInitConns":10,"dataStoreMaxConns":100,"dataStoreConnUsageLimit":100,"dataStoreLogLevel":"debug","maxUrlLength":500}},{"servlet-name":"cofaxEmail","servlet-class":"org.cofax.cds.EmailServlet","init-param":{"mailHost":"mail1","mailHostOverride":"mail2"}},{"servlet-name":"cofaxAdmin","servlet-class":"org.cofax.cds.AdminServlet"},{"servlet-name":"fileServlet","servlet-class":"org.cofax.cds.FileServlet"},{"servlet-name":"cofaxTools","servlet-class":"org.cofax.cms.CofaxToolsServlet","init-param":{"templatePath":"toolstemplates/","log":1,"logLocation":"/usr/local/tomcat/logs/CofaxTools.log","logMaxSize":"","dataLog":1,"dataLogLocation":"/usr/local/tomcat/logs/dataLog.log","dataLogMaxSize":"","removePageCache":"/content/admin/remove?cache=pages&id=","removeTemplateCache":"/content/admin/remove?cache=templates&id=","fileTransferFolder":"/usr/local/tomcat/webapps/content/fileTransferFolder","lookInContext":1,"adminGroupID":4,"betaServer":true}}]';

	@IsTest static void testRawString() {

		JSONParse parser = new JSONParse('"HelloWorld"');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals('HelloWorld', parser.getStringValue());
	}

	@IsTest static void testRawBooleanFalse() {

		JSONParse parser = new JSONParse('false');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(false, parser.getBooleanValue());
	}

	@IsTest static void testRawBooleanTrue() {

		JSONParse parser = new JSONParse('true');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(true, parser.getBooleanValue());
	}

	@IsTest static void testRawNull() {

		JSONParse parser = new JSONParse('null');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(null, parser.getValue());
	}

	@IsTest static void testRawInteger() {

		JSONParse parser = new JSONParse('42');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(42, parser.getIntegerValue());
	}

	@IsTest static void testRawDecimal() {

		JSONParse parser = new JSONParse('17.22');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(17.22, parser.getDecimalValue());
	}

	@IsTest static void testRawNumberWithENotation() {

		JSONParse parser = new JSONParse('1.2483e+2');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(124.83, parser.getDecimalValue());
	}

	@IsTest static void testSimpleGet() {

		JSONParse parser = new JSONParse(SAMPLE1);
		System.assertEquals(true, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals('File', parser.get('menu.value').getStringValue());
		System.assertEquals('File', parser.get('menu.value').getValue());
	}

	@IsTest static void testArrayGet() {

		JSONParse parser = new JSONParse(SAMPLE1);
		System.assertEquals(true, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals('OpenDoc()', parser.get('menu.popup.menuitem.[1].onclick').getValue());
	}

	@IsTest static void testNumberGet() {

		JSONParse parser = new JSONParse(SAMPLE2);
		System.assertEquals(true, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(100, parser.get('widget.text.vOffset').getIntegerValue());
	}

	@IsTest static void testCompoundGet() {

		JSONParse parser = new JSONParse(SAMPLE1);
		System.assertEquals(true, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals('Close', parser.get('menu').get('popup.menuitem').get('[2].value').getStringValue());
	}

	@IsTest static void testAsMap() {

		JSONParse parser = new JSONParse(SAMPLE1);
		System.assertEquals(true, parser.isObject());
		System.assertEquals(false, parser.isArray());
		Map<String, JSONParse> theMap = parser.get('menu').asMap();
		System.assertEquals(3, theMap.size());
		System.assertEquals(false, theMap.get('id').isObject());
		System.assertEquals(false, theMap.get('id').isArray());
		System.assertEquals('file', theMap.get('id').getValue());
		System.assertEquals(true, theMap.get('popup').isObject());
		System.assertEquals(false, theMap.get('popup').isArray());
	}

	@IsTest static void testAsList() {

		JSONParse parser = new JSONParse(SAMPLE3);
		System.assertEquals(false, parser.isObject());
		System.assertEquals(true, parser.isArray());
		List<JSONParse> items = parser.asList();
		System.assertEquals(5, items.size());
		System.assertEquals('ksm@pobox.com', items[0].get('init-param.configGlossary:adminEmail').getValue());
		System.assertEquals(true, items[1].get('init-param').isObject());
		System.assertEquals('cofaxEmail', items[1].get('servlet-name').getStringValue());
	}

	@IsTest static void testOutOfBoundsException() {

		JSONParse parser = new JSONParse(SAMPLE3);

		try {
			parser.get('[7]');
			System.assert(false, 'We used an index outside the bounds of our array, should have seen an exception about that.');
		}
		catch(ListException e) {
			System.assertEquals('List index out of bounds: 7', e.getMessage());
		}
	}

	@IsTest static void testMissingKeyException() {

		JSONParse parser = new JSONParse(SAMPLE2);

		try {
			parser.get('badKey');
			System.assert(false, 'Our key was invalid, should have seen an exception about that.');
		}
		catch(JSONParse.MissingKeyException e) {
			System.assertEquals('No match found for <badKey>: {widget}', e.getMessage());
		}
	}

	@IsTest static void testRootNotAnObjectException() {

		JSONParse parser = new JSONParse(SAMPLE3);

		try {
			parser.asMap();
			System.assert(false, 'Root node is not an object, should have seen an exception about that.');
		}
		catch(JSONParse.NotAnObjectException e) {
			System.assert(e.getMessage().startsWith('The wrapped value is not a JSON object:'));
		}
	}

	@IsTest static void testGetNotAnObjectException() {

		JSONParse parser = new JSONParse(SAMPLE1);

		try {
			parser.get('menu.popup.menuitem.first');
			System.assert(false, 'Node is not an object, should have seen an exception about that.');
		}
		catch(JSONParse.NotAnObjectException e) {
			System.assert(e.getMessage().startsWith('The wrapped value is not a JSON object:'));
		}
	}

	@IsTest static void testRootNotAnArrayException() {

		JSONParse parser = new JSONParse(SAMPLE2);

		try {
			parser.asList();
			System.assert(false, 'Root node is not an array, should have seen an exception about that.');
		}
		catch(JSONParse.NotAnArrayException e) {
			System.assert(e.getMessage().startsWith('The wrapped value is not a JSON array:'));
		}
	}

	@IsTest static void testGetNotAnArrayException() {

		JSONParse parser = new JSONParse(SAMPLE1);

		try {
			parser.get('menu.popup.[0]');
			System.assert(false, 'Node is not an array, should have seen an exception about that.');
		}
		catch(JSONParse.NotAnArrayException e) {
			System.assert(e.getMessage().startsWith('The wrapped value is not a JSON array:'));
		}
	}

	@IsTest static void testExistsGoodKey() {

		JSONParse parser = new JSONParse(SAMPLE1);

		System.assertEquals(true, parser.exists('menu.popup.menuitem.[1].onclick'));
	}

	@IsTest static void testExistsNoIntermediaryKey() {

		JSONParse parser = new JSONParse(SAMPLE1);

		System.assertEquals(false, parser.exists('menu.popup.menuitems.[1].onclick'));
	}

	@IsTest static void testExistsNoKey() {

		JSONParse parser = new JSONParse(SAMPLE1);

		System.assertEquals(false, parser.exists('menu.popup.menuitem.[1].onexplosion'));
	}

	@IsTest static void testExistsGoodIndex() {

		JSONParse parser = new JSONParse(SAMPLE3);

		System.assertEquals(true, parser.exists('[1]'));
	}

	@IsTest static void testExistsBadIndex() {

		JSONParse parser = new JSONParse(SAMPLE3);

		System.assertEquals(false, parser.exists('[7]'));
	}

	@IsTest static void testGetBlobValue() {

		Blob helloWorld = Blob.valueOf('HelloWorld');
		String encoded = EncodingUtil.base64Encode(helloWorld);

		JSONParse parser = new JSONParse('"' + encoded + '"');
		System.assertEquals(encoded, parser.getStringValue());
		System.assertEquals(helloWorld, parser.getBlobValue());

		try {
			parser = new JSONParse('42');
			parser.getBlobValue();
			System.assert(false, 'Node is not a valid Blob, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('Only String values can be converted to a Blob: 42', e.getMessage());
		}
	}

	@IsTest static void testGetBooleanValue() {

		JSONParse parser = new JSONParse('false');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(false, parser.getBooleanValue());

		parser = new JSONParse('"false"');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(false, parser.getBooleanValue());

		parser = new JSONParse('"FALSE"');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(false, parser.getBooleanValue());

		parser = new JSONParse('true');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(true, parser.getBooleanValue());

		parser = new JSONParse('"true"');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(true, parser.getBooleanValue());

		parser = new JSONParse('"TRUE"');
		System.assertEquals(false, parser.isObject());
		System.assertEquals(false, parser.isArray());
		System.assertEquals(true, parser.getBooleanValue());
	}

	@IsTest static void testGetDatetimeValue() {

		JSONParse parser = new JSONParse('"2011-03-22T13:01:23"');
		System.assertEquals(Datetime.newInstanceGmt(2011, 3, 22, 13, 1, 23), parser.getDatetimeValue());

		parser = new JSONParse('1538783039073');
		System.assertEquals(Datetime.newInstanceGmt(2018, 10, 05, 23, 43, 59), parser.getDatetimeValue());

		try {
			parser = new JSONParse('[1,2,3]');
			parser.getDatetimeValue();
			System.assert(false, 'Node is not a valid Datetime, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('Only Long and String values can be converted to a Datetime: [ 1, 2, 3 ]', e.getMessage());
		}
	}

	@IsTest static void testGetDateValue() {

		JSONParse parser = new JSONParse('"2011-03-22"');
		System.assertEquals(Date.newInstance(2011, 3, 22), parser.getDateValue());

		parser = new JSONParse('1538783039073');
		System.assertEquals(Date.newInstance(2018, 10, 05), parser.getDateValue());

		try {
			parser = new JSONParse('[1,2,3]');
			parser.getDateValue();
			System.assert(false, 'Node is not a valid Date, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('Only Long and String values can be converted to a Date: [ 1, 2, 3 ]', e.getMessage());
		}
	}

	@IsTest static void testGetDecimalValue() {

		JSONParse parser = new JSONParse('12');
		System.assertEquals(12.0, parser.getDecimalValue());

		parser = new JSONParse('12.5');
		System.assertEquals(12.5, parser.getDecimalValue());

		parser = new JSONParse('"12.5"');
		System.assertEquals(12.5, parser.getDecimalValue());

		parser = new JSONParse('1538783039073');
		System.assertEquals(1538783039073.0, parser.getDecimalValue());

		try {
			parser = new JSONParse('[1,2,3]');
			parser.getDecimalValue();
			System.assert(false, 'Node is not a valid Decimal, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('This value cannot be converted to a Decimal: [ 1, 2, 3 ]', e.getMessage());
		}
	}

	@IsTest static void testGetDoubleValue() {

		JSONParse parser = new JSONParse('12');
		System.assertEquals(12.0, parser.getDoubleValue());

		parser = new JSONParse('12.5');
		System.assertEquals(12.5, parser.getDoubleValue());

		parser = new JSONParse('"12.5"');
		System.assertEquals(12.5, parser.getDoubleValue());

		parser = new JSONParse('1538783039073');
		System.assertEquals(1538783039073.0, parser.getDoubleValue());

		try {
			parser = new JSONParse('[1,2,3]');
			parser.getDoubleValue();
			System.assert(false, 'Node is not a valid Double, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('This value cannot be converted to a Double: [ 1, 2, 3 ]', e.getMessage());
		}
	}

	@IsTest static void testGetIdValue() {

		Account a = new Account(Name = 'Acme');
		insert a;

		JSONParse parser = new JSONParse('"' + String.valueOf(a.Id) + '"');
		System.assertEquals(a.Id, parser.getIdValue());

		try {
			parser = new JSONParse('[1,2,3]');
			parser.getIdValue();
			System.assert(false, 'Node is not a valid Id, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('This value cannot be converted to an Id: [ 1, 2, 3 ]', e.getMessage());
		}
	}

	@IsTest static void testGetIntegerValue() {

		JSONParse parser = new JSONParse('12');
		System.assertEquals(12, parser.getIntegerValue());

		parser = new JSONParse('"12"');
		System.assertEquals(12, parser.getIntegerValue());

		parser = new JSONParse('12.5');
		System.assertEquals(12, parser.getIntegerValue());

		parser = new JSONParse('1538783039073');
		System.assertEquals(1184747105, parser.getIntegerValue()); // integer gets truncated

		try {
			parser = new JSONParse('[1,2,3]');
			parser.getIntegerValue();
			System.assert(false, 'Node is not a valid Integer, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('This value cannot be converted to an Integer: [ 1, 2, 3 ]', e.getMessage());
		}
	}

	@IsTest static void testGetLongValue() {

		JSONParse parser = new JSONParse('12');
		System.assertEquals(12, parser.getLongValue());

		parser = new JSONParse('"12"');
		System.assertEquals(12, parser.getLongValue());

		parser = new JSONParse('12.5');
		System.assertEquals(12, parser.getLongValue());

		parser = new JSONParse('1538783039073');
		System.assertEquals(1538783039073L, parser.getLongValue());

		try {
			parser = new JSONParse('[1,2,3]');
			parser.getLongValue();
			System.assert(false, 'Node is not a valid Long, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('This value cannot be converted to a Long: [ 1, 2, 3 ]', e.getMessage());
		}
	}

	@IsTest static void testGetStringValue() {

		JSONParse parser = new JSONParse('"HelloWorld"');
		System.assertEquals('HelloWorld', parser.getStringValue());

		parser = new JSONParse('true');
		System.assertEquals('true', parser.getStringValue());

		parser = new JSONParse('null');
		System.assertEquals(null, parser.getStringValue());

		parser = new JSONParse('12.5');
		System.assertEquals('12.5', parser.getStringValue());

		try {
			parser = new JSONParse('{}');
			parser.getStringValue();
			System.assert(false, 'Node is not a valid String, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('Objects and arrays are not Strings: { }', e.getMessage());
		}

		try {
			parser = new JSONParse('[]');
			parser.getStringValue();
			System.assert(false, 'Node is not a valid String, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('Objects and arrays are not Strings: [ ]', e.getMessage());
		}
	}

	@IsTest static void testGetTimeValue() {

		JSONParse parser = new JSONParse('"2011-03-22T13:01:23"');
		System.assertEquals(Time.newInstance(13, 1, 23, 0), parser.getTimeValue());

		parser = new JSONParse('1538783039073');
		System.assertEquals(Time.newInstance(23, 43, 59, 73), parser.getTimeValue());

		try {
			parser = new JSONParse('[1,2,3]');
			parser.getTimeValue();
			System.assert(false, 'Node is not a valid Time, should have seen an exception about that.');
		}
		catch(JSONParse.InvalidConversionException e) {
			System.assertEquals('Only Long and String values can be converted to a Time: [ 1, 2, 3 ]', e.getMessage());
		}
	}
}
