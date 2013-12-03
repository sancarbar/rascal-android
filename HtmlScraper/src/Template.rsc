module Template

import String;
import IO;
import Set;
import List;

data Type = \void() | \primitive(str typeName) | \type(str packageName, str typeName) | \array(Type arrayType);
data Class = class(str packageName, str classType, str name, str modifiers, Type superClass, list[Type] interfaces, list[ConstantField] constantsAndFields, list[Constructor] constructors,  list[Method] methods);
data Method = method(str name, str modifiers, Type returnType, lrel[str argName, Type argType] arguments);
data ConstantField = constantField(str name, str modifiers, Type cType);
data Constructor = constructor(str signature, lrel[str argName, Type argType] arguments);

// Creates Java file
public void createClassFile(str packagePath, Class classInfo) {
	str packageName = replaceAll(packagePath, "/", ".");
	loc packageLoc = |project://Android/src| + packagePath;
	if(!exists(packageLoc)) {
		mkDirectory(packageLoc);
	}
	loc classLoc = packageLoc + getFileName(classInfo.name,".java");
	appendToFile(classLoc, genClass(packageName, classInfo));
}

public str getFileName(str name, str ext){
	return capitalize(name) + ext;
}

// Helper function to generate a class
public str genClass(str packageName, classInfo) {
  return
  	"package <packageName>;
  	'
  	'<genImports(classInfo.methods, classInfo.superClass, classInfo.interfaces, classInfo.constantsAndFields, classInfo.constructors)>
    '
    '<classInfo.modifiers> <classInfo.classType> <classInfo.name><genExtend(classInfo.superClass)><genImplements(classInfo.interfaces)> {
    '<for (constant <- classInfo.constantsAndFields) {>
    	'<genConstant(constant)>
    '<}>
    '<for (constructor <- classInfo.constructors) {>
    	'<genConstructor(constructor.signature)>
    '<}>
    '<for (method <- classInfo.methods) {>
    	'<genMethod(method.name, method.modifiers, method.returnType, method.arguments)>
    '<}>
    '}";
}

// Helper function to generate the imports
private str genImports(list[Method] methods, Type superClass, list[Type] interfaces, list[ConstantField] constants, list[Constructor] constructors) {
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
	for (constant <- constants) {
		if (constant.constantType is \type) {
			imports += genImport(constant.constantType);
		}
	}
	for(constructor <- constructors) {
		for (arg <- constructor.arguments, arg.argType is \type) {
			imports += genImport(arg.argType);
		}
	}
	
	return intercalate("\n", toList(imports));
}

// Helper function to generate an import
private str genImport(\type(str packageName, _)) {
	return "import <packageName>;";
}

// Helper functions to generate an extend
private str genExtend(\type(_, str typeName)) {
	return " extends <typeName>";
}
private str genExtend(noExtend){ 
	return "";
}

public str genConstant(tuple[str name, str modifiers, Type constantType] constant) {
	return "\t<constant.modifiers><printType(constant.constantType)> <constant.name> = <getDefaultTypeValue(constant.constantType)>; ";
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

private str genConstructor(str signature) {
	return "\t<signature> {};";
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
	if(returnType is \void)
		return "";
	else
		return "return <getDefaultTypeValue(returnType)>;";
}

private str getDefaultTypeValue(Type constructType) {
	switch (constructType) {
		case \primitive(str typeName): {
			switch (constructType.typeName) {
				case /char/: return "\'\u0000\'";
				case /boolean/: return "false";
				case /String/: return "\"\"";
				case /Object/: return "null";
				default: return "0";
			}
		}
		case \type(str packageName, str typeName): return "null";
		case \array(Type arrayType): return "null";
	}
}


//Examples:
//createClassFile("com/test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.lang.String", "String")>]>, <"isCool", \primitive("boolean"), []>]);
//createClassFile("com/test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.lang.String", "String")>]>, <"isCool", \primitive("boolean"), []>], superClass = \type("java.util.ArrayList", "ArrayList"), interfaces = [\type("java.util.List", "List")]);
//println(genClass("com/test","Test", [<"method1", \type("java.util.List", "List"), [<"getItems", \primitive("int")>, <"isTrue", \primitive("boolean")>]>, <"setSomething", \void(), [<"something", \type("java.lang.String", "String")>]>, <"isCool", \primitive("boolean"), []>], \type("Somthing", "extendingClass"), [\type("Somthing", "extendingClass")]));
