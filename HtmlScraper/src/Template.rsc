module Template

import String;
import IO;
import Set;
import List;

data Type = \void() | \primitive(str typeName) | \type(str packageName, str typeName);

// Creates Java file
public void createClassFile(str packagePath, str name, lrel[str name, Type returnType, lrel[str, Type] arguments] methods, Type superClass = \void(), list[Type] interfaces = []) {
	str packageName = replaceAll(packagePath, "/", ".");
	loc packageLoc = |project://GeneratedJavaSource/src| + packagePath;
	if(!exists(packageLoc)) {
		mkDirectory(packageLoc);
	}
	loc classLoc = packageLoc + getFileName(name,".java");
	appendToFile(classLoc, genClass(packageName, name, methods, superClass, interfaces));
}

public str getFileName(str name, str ext){
	return capitalize(name) + ext;
}

// Helper function to generate a class
public str genClass(str packageName, str name, lrel[str name, Type returnType, lrel[str, Type] arguments] methods, Type superClass, list[Type] interfaces) {
  return
  	"package <packageName>;
  	'
  	'<genImports(methods, superClass, interfaces)>
    '
    'public class <name> <genExtend(superClass)> <genImplements(interfaces)> {
    '<for (method <- methods) {>
    	'<genMethod(method.name, method.returnType, method.arguments)>
    '<}>
    '}";
}

// Helper function to generate the imports
private str genImports(lrel[str name, Type returnType, lrel[str argName, Type argType] arguments] methods, Type superClass, list[Type] interfaces) {
	set[str] imports = {};
	if(superClass is \type){
		imports += genImport(superClass);
	}
	for(interface <- interfaces, interface is \type){
		imports += genImport(interface);
	}
	for (method <- methods) {
		if (method.returnType is \type) {
			imports += genImport(method.returnType);
		}
		for (argument <- method.arguments, argument.argType is \type) {
			imports += genImport(argument.argType);
		}
	}
	return intercalate("\n", toList(imports));
}

private str genExtend(\type(_, str typeName)){ 
	return "extends <typeName>";
}
private str genExtend(noExtend){ 
	return "";
}

private str genImplements(list[Type] interfaces){
	list[str] implements = [];
	str implementsValue = "";
	for(interface <- interfaces, interface is \type){
		implements +=  "<interface.typeName>";
	}
	if(!isEmpty(implements)){
		implementsValue = "implements " + intercalate(", ", implements);
	}
	return implementsValue;
}

// Helper function to generate an import
private str genImport(\type(str packageName, _)) {
	return "import <packageName>;";
}

// Helper functions to generate a method
private str genMethod(str name, \void(), lrel[str, Type] arguments) {
  return "\tpublic void <name>(<genArgumentsString(arguments)>) { };";
}
private str genMethod(str name, returnType, lrel[str, Type] arguments) {
  return "\tpublic <returnType.typeName> <name>(<genArgumentsString(arguments)>) { return <getReturnTypeDefaultValue(returnType)>; };";
}

private str getReturnTypeDefaultValue(Type returnType) {
	if (returnType is \type) {
		return "null";
	} else {
		switch (returnType.typeName) {
			case /char/: return "\'\u0000\'";
			case /boolean/: return "false";
			default: return "0";
		}
	}
}

// Helper function to generate an argument string
public str genArgumentsString(lrel[str name, Type argType] arguments){
	return intercalate(", ", ["<arg.argType.typeName> <arg.name>" | arg <- arguments]);
}

//createClassFile("com/test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.lang.String", "String")>]>, <"isCool", \primitive("boolean"), []>]);

//println(genClass("com/test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.lang.String", "String")>]>, <"isCool", \primitive("boolean"), []>], \type("Somthing", "extendingClass"), [\type("Somthing", "extendingClass")]));
