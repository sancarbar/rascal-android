module Template

import String;
import IO;
import Set;
import List;

data Type = \void() | \primitive(str typeName) | \type(str packageName, str typeName) | \type(str packageName, str typeName, list[Generic] generics) | \typeParameter(str typeParameterName) | \array(Type arrayType);
data Generic = simpleGeneric(Type genericType) | extendsGeneric(Type baseType, Type extendsType) | superGeneric(Type baseType, Type superType);
data Class = class(str packageName, str classType, str name, str modifiers, Type superClass, list[Type] interfaces, bool isDeprecated, list[ConstantField] constantsAndFields, list[Constructor] constructors, list[Method] methods, list[Class] nestedClasses, list[str] enumValues);
data Method = method(str name, str modifiers, Type returnType, list[Argument] arguments, bool isDeprecated);
data ConstantField = constantField(str name, str modifiers, Type constantType, bool isDeprecated);
data Constructor = constructor(str name, str modifiers, list[Argument] arguments, bool isDeprecated);
data Argument = argument(str name, Type argType);

// Creates Java file
public void createClassFile(str packagePath, Class class, loc eclipseProject = |project://Android/src|) {
	str packageName = replaceAll(packagePath, "/", ".");
	list[str] parts = split(".", packageName);
	loc packageLoc = eclipseProject + parts[0]  ;
		if(!exists(packageLoc)) {
		   mkDirectory(packageLoc);}
	for(p <- parts[1..]){
	
			   packageLoc = packageLoc + "." + p;
		   	if(!exists(packageLoc)) {
		   mkDirectory(packageLoc);
		
	}
	
	}
	//loc packageLoc = eclipseProject + packagePath;
	//if(!exists(packageLoc)) {
		//mkDirectory(packageLoc);
	//}
	loc classLoc = packageLoc + getFileName(class.name,".java");
	appendToFile(classLoc, genClass(packageName, class));
}

public str getFileName(str name, str ext){
	return capitalize(name) + ext;
}

// Helper function to generate a class
public str genClass(str packageName, Class class, bool isNestedClass = false) {
	list[Type] types = getTypes(class);
	return
	  	"
	  	'<if (!isNestedClass) {>
	  	'package <packageName>;
	  	'
	  	'<genImports(types, class.name)>
	    '<}>
		'<if (class.isDeprecated) {>@Deprecated<}>
	    '<class.modifiers> <class.classType> <class.name><genTypeParameters(types)><genExtend(class.superClass)><genImplements(class.interfaces)> {
	    '<genEnumValues(class.enumValues)>
	    '<for (constant <- class.constantsAndFields) {>
	    	'<genConstant(constant)>
	    '<}>
	    '<for (constructor <- class.constructors) {>
	    	'<genConstructor(constructor)>
	    '<}>
	    '<for (method <- class.methods) {>
	    	'<genMethod(method)>
	    '<}>
	    '<for (nestedClass <- class.nestedClasses) {>
	    	'<genClass(packageName, nestedClass, isNestedClass = true)>
	    '<}>
	    '}";
}

private list[Type] getTypes(Class class) {
	list[Type] types = [];
	types += class.superClass;
	types += class.interfaces;
	for (method <- class.methods) {
		types += method.returnType;
		for (argument <- method.arguments) {
			types += argument.argType;
		}
	}
	for (constant <- class.constantsAndFields) {
		types += constant.constantType;
	}
	for (constructor <- class.constructors) {
		for (arg <- constructor.arguments) {
			types += arg.argType;
		}
	}
	types += getNestedClassesTypes(class.nestedClasses);

	return types;
}

private list[Type] getNestedClassesTypes(list[Class] nestedClasses) {
	return ([] | it + getTypes(nestedClass) | nestedClass <- nestedClasses);
}

// Helper function to generate the imports
private str genImports(list[Type] types, str className) = intercalate("\n", dup([ genImport(aType) | aType <- types, aType is \type, aType.packageName != "" && !contains(aType.packageName, className)]));

// Helper function to generate the type parameters
private str genTypeParameters(list[Type] types) {
	list[str] typeParameters = dup([ aType.typeParameterName | aType <- types, aType is \typeParameter ]);
	return size(typeParameters) > 0 ? "\<<intercalate(",", typeParameters)>\>" : "";
}

// Helper function to generate an import
private str genImport(\type(str packageName, _)) = "import <packageName>;";
private str genImport(\type(str packageName, _, _)) = "import <packageName>;";

// Helper functions to generate an extend
private str genExtend(\type(_, str typeName)) {
	return " extends <typeName>";
}
private str genExtend(\type(_, str typeName, list[Generic] generics)) {
	return " extends <typeName>\<<printGenerics(generics)>\>";
}
private str genExtend(noExtend){ 
	return "";
}

// Helper function to generate the implements
public str genImplements(list[Type] interfaces) {
	list[str] implements = [];
	str implementsValue = "";
	for (interface <- interfaces, interface is \type) {
		implements +=  genImplement(interface);
	}
	if (!isEmpty(implements)){
		implementsValue = " implements " + intercalate(", ", implements);
	}
	return implementsValue;
}
private str genImplement(\type(_, str typeName)) {
	return "<typeName>";
}
private str genImplement(\type(_, str typeName, list[Generic] generics)) {
	return "<typeName>\<<printGenerics(generics)>\>";
}

// Helper functions to generate a constructor
private str genConstructor(Constructor constructor) {
	return 
		"
		'<if (constructor.isDeprecated) {>\t@Deprecated<}>
		'\t<constructor.modifiers> <constructor.name>(<genArgumentsString(constructor.arguments)>) {};";
}

// Helper functions to generate a constant or a field
public str genConstant(ConstantField constant) {
	return 
		"
		'<if (constant.isDeprecated) {>\t@Deprecated<}>
		'\t<constant.modifiers> <printType(constant.constantType)> <constant.name> = <getDefaultTypeValue(constant.constantType)>; ";
}

// Helper functions to generate the enum values
public str genEnumValues(list[str] enumValues) = isEmpty(enumValues) ? "" : "\t<intercalate(", ", [ enumValue | enumValue <- enumValues ])>;";

// Helper functions to generate a method
private str genMethod(Method method) {
	return 
		"
		'<if (method.isDeprecated) {>\t@Deprecated<}>
		'\t<method.modifiers> <printType(method.returnType)> <method.name>(<genArgumentsString(method.arguments)>)<genMethodBody(method.modifiers, method.returnType)>;";
}

private str genMethodBody(str modifiers, Type returnType) {
	str methodBody = "";
	if (!contains(modifiers, "abstract")) {
		methodBody = " { <getDefaultReturnTypeValue(returnType)> }";
	}
	return methodBody;
}

// Helper function to generate an argument string
public str genArgumentsString(list[Argument] arguments){
	return intercalate(", ", ["<printType(arg.argType)> <arg.name>" | arg <- arguments]);
}

private str printType(Type aType) {
	switch (aType) {
		case \void(): return "void";
		case \primitive(str typeName): return typeName;
		case \type(str packageName, str typeName): return typeName;
		case \type(str packageName, str typeName, list[Generic] generics): return "<typeName>\<<printGenerics(generics)>\>";
		case \typeParameter(str typeParameterName): return typeParameterName;
		case \array(Type arrayType): return printType(arrayType) + "[]";
	}
}

private str printGenerics(list[Generic] generics) {
	return intercalate(", ", [printGeneric(generic) | generic <- generics]);
}

private str printGeneric(Generic generic) {
	switch (generic) {
		case simpleGeneric(Type genericType): return "<printType(genericType)>";
		case extendsGeneric(Type baseType, Type extendsType): return "<printType(baseType)> extends <printType(extendsType)>";
		case superGeneric(Type baseType, Type superType): return "<printType(baseType)> super <printType(superType)>";
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
		case \type(_, _): return "null";
		case \type(_, _, _): return "null";
		case \typeParameter(_): return "null";
		case \array(_): return "null";
	}
}
