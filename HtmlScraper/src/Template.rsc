module Template

import String;
import IO;
import Set;
import List;

data Type = \void() | \primitive(str typeName) | \type(str packageName, str typeName) | \array(Type arrayType);

// Creates Java file
public void createClassFile(str packagePath, str name, lrel[str name, str modifiers, Type returnType, lrel[str, Type] arguments] methods, Type superClass = \void(), list[Type] interfaces = []) {
	str packageName = replaceAll(packagePath, "/", ".");
	loc packageLoc = |project://Android/src| + packagePath;
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
public str genClass(str packageName, str name, lrel[str name, str modifiers, Type returnType, lrel[str, Type] arguments] methods, Type superClass, list[Type] interfaces) {
  return
  	"package <packageName>;
  	'
  	'<genImports(methods, superClass, interfaces)>
    '
    'public class <name><genExtend(superClass)><genImplements(interfaces)> {
    '<for (method <- methods) {>
    	'<genMethod(method.name, method.modifiers, method.returnType, method.arguments)>
    '<}>
    '}";
}

// Helper function to generate the imports
private str genImports(lrel[str name, str modifiers, Type returnType, lrel[str argName, Type argType] arguments] methods, Type superClass, list[Type] interfaces) {
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

// Helper function to generate an import
private str genImport(\type(str packageName, _)) {
	return "import <packageName>;";
}

// Helper functions to generate an extend
private str genExtend(\type(_, str typeName)){ 
	return " extends <typeName>";
}
private str genExtend(noExtend){ 
	return "";
}

// Helper function to generate the implements
private str genImplements(list[Type] interfaces){
	list[str] implements = [];
	str implementsValue = "";
	for(interface <- interfaces, interface is \type){
		implements +=  "<interface.typeName>";
	}
	if(!isEmpty(implements)){
		implementsValue = " implements " + intercalate(", ", implements);
	}
	return implementsValue;
}

// Helper functions to generate a method
private str genMethod(str name, str modifiers, Type returnType, lrel[str, Type] arguments) {
	return "\t<modifiers><printType(returnType)> <name>(<genArgumentsString(arguments)>)<genMethodBody(modifiers, returnType)>;";
}

private str genMethodBody(str modifiers, Type returnType) {
	str methodBody = "";
	if (!contains(modifiers, "abstract")) {
		methodBody = " { <getDefaultReturnTypeValue(returnType)> }";
	}
	return methodBody;
}

// Helper function to generate an argument string
public str genArgumentsString(lrel[str name, Type argType] arguments){
	return intercalate(", ", ["<printType(arg.argType)> <arg.name>" | arg <- arguments]);
}

private str printType(Type aType) {
	switch (aType) {
		case \void(): return "void";
		case \primitive(str typeName): return typeName;
		case \type(str packageName, str typeName): return typeName;
		case \array(Type arrayType): return printType(arrayType) + "[]";
	}
}

private str getDefaultReturnTypeValue(Type returnType) {
	switch (returnType) {
		case \void(): return "";
		case \primitive(str typeName): {
			switch (returnType.typeName) {
				case /char/: return "return \'\u0000\';";
				case /boolean/: return "return false;";
				case /String/: return "return \"\";";
				case /Object/: return "return null;";
				default: return "return 0;";
			}
		}
		case \type(str packageName, str typeName): return "return null;";
		case \array(Type arrayType): return "return null;";
	}
}

//Examples:
//createClassFile("com/test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.lang.String", "String")>]>, <"isCool", \primitive("boolean"), []>]);
//createClassFile("com/test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.lang.String", "String")>]>, <"isCool", \primitive("boolean"), []>], superClass = \type("java.util.ArrayList", "ArrayList"), interfaces = [\type("java.util.List", "List")]);
//println(genClass("com/test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.lang.String", "String")>]>, <"isCool", \primitive("boolean"), []>], \type("Somthing", "extendingClass"), [\type("Somthing", "extendingClass")]));
