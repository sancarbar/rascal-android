module Template

import String;
import IO;
import Set;
import List;

data Type = \void() | \primitive(str typeName) | \type(str packageName, str typeName);

// Helper function to generate a class
public str genClass(str packageName, str name, lrel[str name, Type returnType, lrel[str, Type] arguments] methods) {
  return
  	"package <packageName>;
  	'
  	'<genImports(methods)>
    '
    'public class <name> {
    '<for (method <- methods) {>
    	'<genMethod(method.name, method.returnType, method.arguments)>
    '<}>
    '}";
}

// Helper function to generate the imports
private str genImports(lrel[str name, Type returnType, lrel[str argName, Type argType] arguments] methods) {
	set[str] imports = {};
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

// Helper functions to generate a method
private str genMethod(str name, \void(), lrel[str, Type] arguments) {
  return "\tpublic void <name> (<genArgumentsString(arguments)>) { };";
}
private str genMethod(str name, returnType, lrel[str, Type] arguments) {
  return "\tpublic <returnType.typeName> <name> (<genArgumentsString(arguments)>) { };";
}

// Helper function to generate an argument string
public str genArgumentsString(lrel[str name, Type argType] arguments){
	return intercalate(", ", ["<arg.argType.typeName> <arg.name>" | arg <- arguments]);
}

//println(genClass("com.test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.util.String", "String")>]>, <"isCool", \primitive("boolean"), []>]));



public void createClassFile(str package, str name, list[str] methods){
//createClassFile("a", "test", ["public void testMethod()"]);
	packageLoc = ROOT_LOC + package;
	if(!exists(packageLoc))
		mkDirectory(packageLoc);
	loc classLoc = packageLoc + getFileName(name,".java"); 
	appendToFile(classLoc, getPackageName(package));
	appendToFile(classLoc,  "\n\n\n\npublic class "+capitalize(name)+"{\n\n");
	for(m <- methods){
		appendToFile(classLoc,  m +"{}");	
	}
	appendToFile(classLoc,  "\n\n}\n");
}




public str getFileName(str name, str ext){
	return capitalize(name) + ext;
}

public str getPackageName(str package){
	return "package android." + package + ";\n";
}


