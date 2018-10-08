# JSONParse
Salesforce Apex JSON parser to make it easier to extract information from nested JSON structures.

If you're sick of writing code like this:

```apex
Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(someJSON);
Map<String, Object> menu = (Map<String, Object>)root.get('menu');
Map<String, Object> popup = (Map<String, Object>)menu.get('popup');
List<Object> menuitem = (List<Object>)menu.get('menuitem');
Map<String, Object> secondItem = (Map<String, Object>)menuitem.get(1);
String thingIActuallyWanted = String.valueOf(secondItem.get('name'));
```

...then this parser is for you! Voila!

```apex
new JSONParse(someJSON).get('menu.popup.menuitem.[1].name').getStringValue();
```

Do I have your attention? Great! Now let's go a little deeper.

## Concepts ##

The idea of JSONParse is that a JSON payload is treated as a tree, with each node in the tree wrapped in an instance of JSONParse. So you start with a JSONParse instance at the root, and as you drill deeper into the nested data structure you are revealing yet more JSONParse instances.

At any time you can use your current JSONParse instance to get one of two collection types (Maps/Lists), or raw data primitives, depending on what this particular JSONParse node is wrapping (an object, an array, or a primitive).

A little fuzzy? That's OK, let's look at some examples.

## Usage ##

Let's start with a simple example. Say we have the following JSON structure:

```json
{"menu": {
  "id": "file",
  "value": "File",
  "popup": {
    "menuitem": [
      {"value": "New", "onclick": "CreateNewDoc()"},
      {"value": "Open", "onclick": "OpenDoc()"},
      {"value": "Close", "onclick": "CloseDoc()"}
    ]
  }
}}
```

We always start by instantiating JSONParse with a String value that holds some JSON:

`JSONParse root = new JSONParse(someJSONData);`

If we wanted to get to the `value` property inside `menu`, we would do this:

```apex
root.get('menu.value').getStringValue(); // "File"
```

But what is actually happening here? Let's be a little more verbose:

```apex
JSONParse childNode = root.get('menu.value');
childNode.getStringValue(); // "File"
```

The `get()` method is our key workhorse method in JSONParse. It allows us to drill into the tree structure and always returns an instance of JSONParse.

For additional clarity:

```apex
System.debug(root.toStringPretty());
```

```json
{
  "menu" : {
    "popup" : {
      "menuitem" : [ {
        "onclick" : "CreateNewDoc()",
        "value" : "New"
      }, {
        "onclick" : "OpenDoc()",
        "value" : "Open"
      }, {
        "onclick" : "CloseDoc()",
        "value" : "Close"
      } ]
    },
    "value" : "File",
    "id" : "file"
  }
}
```

```apex
System.debug(root.get('menu.popup').toStringPretty());
```

```json
{
  "menuitem" : [ {
    "onclick" : "CreateNewDoc()",
    "value" : "New"
  }, {
    "onclick" : "OpenDoc()",
    "value" : "Open"
  }, {
    "onclick" : "CloseDoc()",
    "value" : "Close"
  } ]
}
```

```apex
System.debug(root.get('menu.popup.menuitem').toStringPretty());
```

```json
[ {
  "onclick" : "CreateNewDoc()",
  "value" : "New"
}, {
  "onclick" : "OpenDoc()",
  "value" : "Open"
}, {
  "onclick" : "CloseDoc()",
  "value" : "Close"
} ]
```

```apex
System.debug(root.get('menu.popup.menuitem.[0]').toStringPretty());
```

```json
{
  "onclick" : "CreateNewDoc()",
  "value" : "New"
}
```

You can see as we drill deeper and deeper into the data structure, we get smaller and smaller slices of the tree back.

Don't be misled by these examples that all start from `root`. You can just as easily drill partway down, do some stuff, then keep going. You can even do things like this:

```apex
root.get('menu.popup').get('menuitem').get('[2].onclick').getStringValue();
```

## What can I pass to get()? ##
```apex
public JSONParse get(String path) {}
```

The syntax for what you pass to the `get()` method is simple. You are passing a series of tokens separated by periods. A token is either:

1. An array token
2. A key token

Array tokens look like this: \[2]

They are used to choose a specific item in an array.

The other token type, key tokens, are just simple strings that are going to be used to match on a JSON object property name. This matching is **case sensitive**.

You can mix and match these two token types to your heart's content. Just remember you are following your JSON data structure, so your get() path that you send should match it!

Tokens are always separated by a period. Here's a common mistake (don't do this):

```apex
// NOT VALID SYNTAX
root.get('menu.popup.menuitem[0]');

// VALID SYNTAX
root.get('menu.popup.menuitem.[0]');
```

## Working with Collections ##

If you'd like to work with your collection nodes (object = Map, array = List), there are two methods on JSONParse:

```apex
public Map<String, JSONParse> asMap() {}
public List<JSONParse> asList() {}
```

So, to build on our previous examples, you could do something like this:

```apex
for(JSONParse node : root.get('menu.popup.menuitem').asList()) {
    System.debug('Onclick: ' + node.get('onclick').toStringValue());
    System.debug('Value: ' + node.get('value').toStringValue());
}
```

Or this:

```apex
Map<String, JSONParse> menuProperties = root.get('menu').asMap();
System.debug(menuProperties.keySet()); // (id, value, popup)
for(String key : menuProperties.keySet()) {
  JSONParse node = children.get(key);
}
```

You can of course nest and repeat these patterns, to drill into arbitrarily complex data structures.

## Dynamic Inspection ##

There's some discovery built into the parser so you can explore the JSON structure without knowing the shape in advance.

To do so, simply combine the two collection methods you just saw with these utility methods:

```apex
public Boolean isObject() {}
public Boolean isArray() {}
```

These two methods peek under the covers at the wrapped data and give you some information about what's inside. Here's an arbitrary example, where I use recursion to perform a dynamic inspection of the entire JSON tree. Obviously this contrived but it should give you an idea of what's possible!

```apex
public void explore(JSONParse node, Integer depth) {
	if(!(node.isObject() || node.isArray())) {
		System.debug( '*'.repeat(depth) + node.getValue());
	}
	if(node.isObject()) {
		for(String key : node.asMap().keySet()) {
			explore(node.get(key), depth + 1);
		}
	}
	if(node.isArray()) {
		for(JSONParse item : node.asList()) {
			explore(item, depth + 1);
		}
	}
}

JSONParse root = new JSONParse('{"menu":{"id":"file","value":"File","popup":{"menuitem":[{"value":"New","onclick":"CreateNewDoc()"},{"value":"Open","onclick":"OpenDoc()"},{"value":"Close","onclick":"CloseDoc()"}]}}}');

explore(root, 0);
```

Result:

```
13:37:23.34 (39921697)|USER_DEBUG|[3]|DEBUG|**file
13:37:23.34 (40158891)|USER_DEBUG|[3]|DEBUG|**File
13:37:23.34 (40964502)|USER_DEBUG|[3]|DEBUG|*****New
13:37:23.34 (41091905)|USER_DEBUG|[3]|DEBUG|*****CreateNewDoc()
13:37:23.34 (41310876)|USER_DEBUG|[3]|DEBUG|*****Open
13:37:23.34 (41477025)|USER_DEBUG|[3]|DEBUG|*****OpenDoc()
13:37:23.34 (41820815)|USER_DEBUG|[3]|DEBUG|*****Close
13:37:23.34 (41952080)|USER_DEBUG|[3]|DEBUG|*****CloseDoc()
```

## Primitive Value Extraction ##

A parser is no good if you can't get to the juicy stuff it's wrapped around!

There are a number of methods to pull primitive values out of JSONParse nodes. In general we followed the conventions in the native JSONParser class, except in a few places where we supported a broader / more flexible set of behaviors. For example, you can build Date or Time instances from Long values.

```
public Blob getBlobValue() {}

public Boolean getBooleanValue() {}

public Datetime getDatetimeValue() {}

public Date getDateValue() {}

public Decimal getDecimalValue() {}

public Double getDoubleValue() {}

public Id getIdValue() {}

public Integer getIntegerValue() {}

public Long getLongValue() {}

public String getStringValue() {}

public Time getTimeValue() {}

public Object getValue() {}
```

### Disclaimers ###
This helper class only reads JSON, it does not write it. For writing, may we suggest using the native and perfectly serviceable [JSON.serialize()](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Json.htm)!
