module Template



import String;
import IO;
import Set;
import List;


public map[str, str] packages;


// Capitalize the first character of a string

public str capitalize(str s) {  
  return toUpperCase(substring(s, 0, 1)) + substring(s, 1);
}

// Helper function to generate a method
private str genMethod(str name, str returnType, lrel[str,str] arguments) {
  return "public <returnType> <name> (<getArgumentsString(arguments)>) { };";
}

public str getArgumentsString(lrel[str argType, str name] arguments){
	return intercalate(", ", ["<arg.argType> <arg.name>" | arg <- arguments]);	 
}

// Generate a class with given name and fields.
// The field names are processed in sorted order.
// methods 
public str genClass(str packageName, str name, lrel[str name, tuple[str typeName, str packageName] returnType, lrel[str,str] arguments] methods) { 
  return 
  	"package <packageName>;
  	'<for (method <- methods) {>
  		'import <method.returnType.packageName>;
  	'<}>
    'public class <name> {
    '<for (method <- methods) {>
    '<genMethod(method.name, method.returnType.typeName, method.arguments)> <}>
    '}";
}


//println(genClass("com.test","Test", [<"method1", <"int","x">, [<"int", "geMat">, <"bool", "isTrue">]>]));