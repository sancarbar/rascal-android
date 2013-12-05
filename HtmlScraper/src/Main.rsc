module Main

import IO;
import lang::html::IO;
import Set;
import List;
import util::ValueUI;
import String;
import Template;
import ParseTree;
import SignatureParser;
import util::Maybe;
import DateTime;

//annotations
anno str node@id;
anno str node@href;
anno str node@class;

// |http://developer.android.com/reference/packages.html|
public void main(int apiLevel) {
	loc project = |http://developer.android.com/reference/packages.html|;
	
	set[value] packages = {};
	
	for (package <- getPackages(project)) {
		// Retrieve detailed package information.
		map[str,set[map[str,value]]] information = getPackageInformation(package, apiLevel);
		// Add detailed to package information to the package information we already have.
		map[str, value] package_information = ("package": information);
		// Add full package information to set.
		packages += {package_information};
		text(package_information);		
	}
	
	text(packages);
}

public void buildProject(int apiLevel) {
	println("start at: <now()>");

	loc project = |http://developer.android.com/reference/packages.html|;
	set[loc] packages = getPackages(project);
	int packageIndex = 1;

	println("packages: <size(packages)>");
	for (package <- packages) {
		map[str,set[map[str,value]]] information = getPackageInformation(package, apiLevel);
		println("<packageIndex>. Package <package>");
		for (class <- information["classes"] + information["interfaces"] + information["exceptions"] + information["errors"]) {
			url = class["url"];
			packagePath = class["package_path"];
			println("-- Class <url>");

			buildClass(url, packagePath, apiLevel);
		}
		packageIndex += 1;
	}

	println("finished at: <now()>");
}


public void testBuild(){
	loc url = |http://developer.android.com/reference/android/R.html|;
	str packagePath = "android";
	int apiLevel = 11;
	buildClass(url, packagePath, apiLevel);

}

public void buildClass(loc url, str packagePath, int apiLevel) {
	Maybe[Class] maybeClass = getClass(url, packagePath, apiLevel);
	list[Class] nestedClasses = [];
	for(nestedClassUrl <- getNestedClasses(url)){
		nestedClass = getClass(nestedClassUrl, packagePath, apiLevel, acceptNestedClass = true);
		if (nestedClass is just)
			nestedClasses += nestedClass.val; 
	}
	
	if (maybeClass is just) {
		Class class = maybeClass.val;
		class.nestedClasses = nestedClasses;
		createClassFile(packagePath, class);
	}
}

private Maybe[Class] getClass(loc url, str packagePath, int apiLevel, bool acceptNestedClass = false) {
	node classHtml = readHTMLFile(url);
	map[str, list[list[node]]] classConstructs = getClassConstructs(classHtml, apiLevel);
	str classSignature = extractClassSig(classHtml);
	bool isDeprecated = isClassDeprecated(classHtml);
	node classSignatureAst = parseClassSignatureToAST(classSignature);
	str classType = getClassType(classSignatureAst);
	str name = getClassName(classSignatureAst);
	//check for innerclasses
	
	if(contains(name, ".")){
		if(acceptNestedClass)
			name = substring(name, findFirst(name, ".") + 1, size(name));
		else
			return nothing();
	}
	str modifiers = intercalate(" ", getClassModifiers(classSignatureAst));
	Type superClass = getClassSuperClass(classSignatureAst);
	list[Type] interfaces = getClassInterfaces(classSignatureAst);
	list[Constructor] constructors = getConstructors(classConstructs["constructors"]);
	list[ConstantField] constantsAndFields = getConstantsAndFields(classConstructs["constants"] + classConstructs["fields"]);
	list[Method] methods = getMethods(classConstructs["methods"]);

	// Fix bug in documentation: some interface implement interfaces, which isn't possible in Java (see: http://developer.android.com/reference/org/xml/sax/ext/Attributes2.html)
	if (classType == "interface") {
		if (!isEmpty(interfaces)) {
			superClass = head(interfaces);
			interfaces = [];
		}
	}
	return just(class(packagePath, classType, name, modifiers, superClass, interfaces, isDeprecated, constantsAndFields, constructors, methods, []));
}

// Parses the constructors and returns them in the needed type for creating the templates
public list[Constructor] getConstructors(list[list[node]] constructorNodes) {
	list[Constructor] constructors = [];
	// Get constructors
	for(constructorNode <- constructorNodes){
		str constructorSignature = getConstructSignature(constructorNode);
		list[str] argumentSignatures = getConstructArgumentSignatures(constructorSignature);
		// Get arguments of constructor
		list[Argument] arguments = [];
		for (argumentSignature <- argumentSignatures) {
			str argumentName = getConstructName(argumentSignature);
			Type argumentType = getConstructType(argumentName, argumentSignature, constructorNode);
			arguments += argument(argumentName, argumentType);
		}
		constructors += constructor(constructorSignature, arguments);
	}
	return constructors;
}

// Parses the constants and fields and returns them in the needed type for creating the templates
public list[ConstantField] getConstantsAndFields(list[list[node]] constantsAndFieldsNodes) {
	list[ConstantField] constantsAndFields = [];
	// Get constants and fields
	for(constantOrFieldNode <- constantsAndFieldsNodes){
		str constantSignature = getConstructSignature(constantOrFieldNode);
		node constantAst = parseConstructSignatureToAST(constantSignature);
		str constantName = getConstructName1(constantAst); //getConstructName(constantSignature);
		str constantModifiers =  getConstructModifiers1(constantAst); //getConstructModifiers(constantSignature);
		Type contantType = getConstructType(constantName, constantSignature, constantOrFieldNode);
		constantsAndFields += constantField(constantName, constantModifiers, contantType);
	}
	return constantsAndFields;
}

// Parses the methods and returns them in the needed type for creating the templates
public list[Method] getMethods(list[list[node]] methodNodes) {
	list[Method] methods = [];
	// Get methods
	for(methodNode <- methodNodes) {
		str methodSignature = getConstructSignature1(methodNode);
		node methodAst = parseConstructSignatureToAST(methodSignature);
		str methodName = getConstructName1(methodAst); //getConstructName(methodSignature);
		str methodModifiers = getConstructModifiers1(methodAst); //getConstructModifiers(methodSignature);
		Type methodReturnType = getConstructType(methodName, methodSignature, methodNode);
		list[str] argumentSignatures = getConstructArgumentSignatures(methodSignature);

		// Get arguments of method
		list[Argument] arguments = [];
		for (argumentSignature <- argumentSignatures) {
			str argumentName = getConstructName(argumentSignature);
			Type argumentType = getConstructType(argumentName, argumentSignature, methodNode);
			arguments += argument(argumentName, argumentType);
		}

		methods += method(methodName, methodModifiers, methodReturnType, arguments);
	}
	return methods;
}

public set[loc] getPackages(loc packageSummaryUrl) {
	node overviewHtml = readHTMLFile(packageSummaryUrl);
	set[loc] packages = {};
	
	// Get parent div with list of anchors.
	visit(overviewHtml) {
		case parent:"div"(ulList): if((parent@id ? "") == "packages-nav") {
			// Get anchors.
			visit(ulList) {
				case alink:"a"(aContent): if((alink@href ? "") != "") {
					packages += |http://developer.android.com<alink@href>|;
				}
			}
		}
	}

	return packages;
}


public map[str, set[map[str, value]]] getPackageInformation(loc packageInformationUrl, value api) {
	node packageHtml = readHTMLFile(packageInformationUrl);
	
	set[str] urlSet = {};
	set[map[str,value]] classSet = {};
	set[map[str,value]] interfaceSet = {};
	set[map[str,value]] exceptionSet = {};
	set[map[str,value]] enumsSet = {};
	set[map[str,value]] errorSet = {};
	
	visit(packageHtml) {
		// Get content div.
		case parent_div_elem:"div"(div_content): if((parent_div_elem@id ? "") == "jd-content") {
		
			str entry_type = "";
		
			visit (div_content) {
				case h2_elem:"h2"(h2_content): {
					visit(h2_content) {
						case text_elem:"text"(text_content): entry_type = text_content;
					}
				}
				case table_elem:"table"(table_trs): if((table_elem@class ? "") == "jd-sumtable-expando") {
					
					
					// Get anchors.
					visit(table_trs) {
						case trlink:"td"(field_content): if ((trlink@class ? "") == "jd-linkcol") {
							visit(field_content) {
								case alink:"a"(a_content): if((alink@href ? "") != "") {
									// Get Names
									visit(a_content) {
										case atext:"text"(text_content): { 
											map[str,value] package_info = (

												//"sig" : extractClassSig(html),
												//sure it shouldn't be the one below? because the html does not contain the link to the class?
												//"sig" : extractClassSig(readHTMLFile(|http://developer.android.com<alink@href>|)),
												"name":text_content,
												"url":|http://developer.android.com<alink@href>|,
												"package_path": substring(alink@href, 11, findLast(alink@href, "/")),
												"api-level": getClassAPI(|http://developer.android.com<alink@href>|)
												//"information":getClassInformation(|http://developer.android.com<alink@href>|)
											);
											// Group by class type.
											value apiLVL = package_info["api-level"];
											if(apiLVL > api){
													classSet += {};
												}
											else{
												switch (entry_type)
												{
													case "Classes": {
														classSet += {package_info};
														
													}
													case "Interfaces": interfaceSet += {package_info};
													case "Exceptions": exceptionSet += {package_info};
													case "Enums": enumsSet += {package_info};
													case "Errors": errorSet += {package_info};
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}	
		}	
	}
	
	map[str,set[map[str,value]]] packageDescription = (
		"classes": classSet,
		"interfaces": interfaceSet,
		"exceptions": exceptionSet,
		"enums": enumsSet,
		"errors": errorSet
	);
	
	return packageDescription;
}


public list[loc] getNestedClasses(loc classUrl) {
	node ast = readHTMLFile(classUrl);
	str entry_type = "";
	list[loc] nclasses = [];
	visit(ast){
		case table:"table"(table_content): if((table@id ? "") == "nestedclasses"){
			//text(table_content);
			visit(table_content){
				case th:"th"(content):{
					visit(content){
						case "text"(text_con):{
							entry_type = text_con;
							//table tags are not properly closed on website, therefore match on tableheader Nested Classes
						}
					}
				}
			    case tdlink:"td"(td_content): if((tdlink@class ? "") == "jd-linkcol"){
			    	visit(td_content){
			    		case alink:"a"(a_content): if((alink@href ? "") != ""){
							switch(entry_type){
							case "Nested Classes": nclasses += |http://developer.android.com<alink@href>|;
							}
						}
					}
			    }
			}
		}
	}
	return nclasses;
}

public int getClassAPI(loc classURL) {
	node ast = readHTMLFile(classURL);
	visit(ast) {
		case div:"div"(class_API_container):if((div@class ? "") == "api-level") {
			visit(class_API_container) {
				case text:"text"(apiLevelContent): {
					apiLevel = apiLevelContent;
					if(/.*\s<lvl:[0-9]+>/ := apiLevel) {
						return toInt(lvl);
					}
				}						
			}
		}
	}
	return 1; // if there is no apilevel in the sourcecode it will be considered as lvl 1
}

public map[str, list[list[node]]] getClassConstructs(node classHtml, int apiLevel) {
	list[list[node]] methods = [];
	list[list[node]] constants = [];
	list[list[node]] fields = [];
	list[list[node]] constructors = [];
	list[list[node]] innerClasses = [];
	
	str construct;
	visit(classHtml) {
		case h2Elem:"h2"(h2Content): {
			visit(h2Content) {
				case textElem:"text"(textContent): construct = textContent;
			}
		}
		case div:"div"(divMethod): if(/jd-details / := (div@class ? "")) {
			list[node] constructNode;
			int constructApiLevel = 0;
			visit(divMethod) {
				case header:"h4"(h4Content): if ((header@class ? "" ) == "jd-details-title") {
					constructNode = h4Content;
				}
				case divApi:"div"(divContent): if((divApi@class ? "") == "api-level") {
					visit(divContent) {
						case text:"text"(apiLevelContent): {
							if(/.*\s<lvl:[0-9]+>/ := apiLevelContent) {
								constructApiLevel = toInt(lvl);
							}
							
						}						
					}
				}
			}
			//do add the methods with the apiLevels that are higher than the version currently bui;l
			if(constructApiLevel <= apiLevel) {
				switch(construct) {
					case "Public Methods":  methods += [constructNode];
					case "Protected Methods": methods += [constructNode];
					case "Public Constructors": constructors += [constructNode];
					case "Protected Constructors": constructors += [constructNode];
					case "Constants": constants += [constructNode];
					case "Fields": fields += [constructNode];
				}
			}
		}
	}
	
	map[str,list[list[node]]] classConstructs = (
		"methods": methods,
		"constants": constants,
		"fields": fields,
		"constructors": constructors
		//"innerclasses": "TODO"
	);
	
	return classConstructs;
}

public str getConstructSignature(list[node] constructNodes) {
	str signature = "";
	visit (constructNodes) {
		case text:"text"(partOfSignature): signature += partOfSignature;
	}
	return signature;
}

public str getConstructSignature1(list[node] constructNodes) {
	str signature = "";
	visit (constructNodes) {
		case text:"text"(partOfSignature): signature += partOfSignature;
		case alink:"a"(linkToTypes): if ((alink@href ? "") != "") signature += " " + alink@href + " ";
	}
	println(signature);
	return signature;
}

public str getConstructName(str constructSignature) {
	str name = "";
	if (/(public|private|protected|static|abstract|final|\s)*[a-zA-Z0-9_\-\.\[\]]*\s*<constructName:[a-zA-Z0-9_\-]*>/ := constructSignature) {
		name = constructName;
	}
	return name;
}

public str getConstructName1(node methodAst) {
	visit(methodAst) {
		case "method"(modifiers, constructType, name, params): return name;
		case "constantOrField"(modifiers, constructType, name): return name;
		case "constructor"(modifiers, name, params): return name;
	}
}

public str getConstructModifiers(str constructSignature) {
	str modifiers = "";
	if (/<modifierNames:(public|private|protected|static|abstract|final|\s)*>/ := constructSignature) {
		modifiers = modifierNames;
	}
	return modifiers;
}

public str getConstructModifiers1(node methodAst) {
	visit(methodAst) {
		case "method"(modifiers, constructType, name, params): return intercalate(" ", modifiers);
		case "constantOrField"(modifiers, constructType, name): return intercalate(" ", modifiers);
		case "constructor"(modifiers, name, params): return intercalate(" ", modifiers);
	}
}

public Type getConstructType(str constructName, str constructSignature, list[node] constructNodes) {
	str typeName = "";
	if (/<constructTypeName:[a-zA-Z0-9_\-\.\[\]]*>\s*<constructName>/ := constructSignature) {
		typeName = constructTypeName;
	}
	Type constructType = getTypeFromString(typeName);

	if (constructType is \type) {
		visit(constructNodes) {
			case aLink:"a"(aContent): if((aLink@href ? "") != "") {
				visit(aContent) {
					case aText:"text"(textContent): {
						return getTypeFromUrl(aLink@href); // return is necessary! The first link & text found is the one we need.
					}
				}
			}
		}
	}
	return constructType;
}

//public str getMethodReturnType(node methodAst) {
//	visit(methodAst) {
//		case "method"(modifiers, constructType, name, params): return constructType;
//		case "constantOrField"(modifiers, constructType, name): return constructType;
//	}
//}

public list[str] getConstructArgumentSignatures(str constructSignature) {
	if (/\(<params:.*>\)/ := constructSignature) {
		return [ trim(param) | param <- split(",", params), !isEmpty(trim(param)) ];
	}
}

public str extractClassSig(node classHtml) {
	str class_sig = "";
	visit(classHtml) {
		case divC:"div"(div_class_sig): if((divC@id ? "") == "jd-header") {
			//text(div_class_sig);
			visit(div_class_sig) {
				case text:"text"(text_content) :{ class_sig += text_content + " "; }//println(class_sig);}
				case alink:"a"(a_content) :if((alink@href ? "") != "") {
					class_sig += alink@href + " ";
				}
			}
		}
	}
	return trim(class_sig);
}

public bool isClassDeprecated(node classHtml) {
	visit(classHtml) {
		case divC:"div"(divClassContent): if((divC@id ? "") == "jd-content") {
			visit(divClassContent) {
				case divD:"div"(divDescription): if((divD@class ? "") == "jd-descr") {
					visit(divClassContent) {
						case pC:"p"(pContent): if((pC@class ? "") == "caution") {
							return true;
						}
					}
				}
			}
		}
	}
	return false;
}

public str getClassName(node ast) {
	visit(ast) {
		case "type"(_,_,name,_,_): {
			return name;
		}
	}
}

public str getClassType(node ast) {
	visit(ast) {
		case "type"(_,classType,_,_,_): {
			return classType;
		}
	}
}

public Type getClassSuperClass(node ast) {
	Type superClass = \void();
	visit(ast) {
		case ex:"extends"(l): {
			visit(l){
				case "link"(l1,l2,l3): {
					//println(l);
					//println("LAYER 1 <l1>  <l2> <l3>");
					superClass = getTypeFromUrl(l2);
//					visit(l3){
//						case "extends"(inpt):{
//							visit(inpt){
//								case "link"(e1,e2,e3):{
//									println("LAYER 2 <e1>  <e2> <e3>");
//								}
//							}
//						}//Enum link < E2 link2 <E>> 
////"public static final enum Bitmap.Config extends  Enum /reference/java/lang/Enum.html \<E Enum /reference/java/lang/Enum.html \<E\>\>"
////extends hoofd:type, E: type>\>
//				//type (enum, enumref) [type(enum, enumref) :  <extends >		
//					}
				}
			}
		}
	}
	return superClass;
}

public list[Type] getClassInterfaces(node ast) {
	list[Type] interfaces = [];
	visit(ast) {
		case impl:"implements"(im): {
			visit(im){			
				case "link"(i1,i2,i3): {
					interfaces += getTypeFromUrl(i2);
				}
			}
		}
	}
	return interfaces;
}

public list[str] getClassModifiers(node ast) {
	visit(ast) {
		case "type"(modifiers,_,_,_,_): {
			return modifiers;
		}
	}
}

private Type getTypeFromString(str typeName) {
	if (typeName == "void") {
		return \void();
	} else if (endsWith(typeName, "[]")) {
		return \array(getTypeFromString(substring(typeName, 0, size(typeName) - 2)));
	} else if (typeName in ["byte", "short", "int", "long", "float", "double", "char", "String", "boolean", "Object", "Class"]) {
		return \primitive(typeName);
	} else {
		return \type("", typeName);
	}
}

private Type getTypeFromUrl(str url){
	return  \type(getPackageNameFromUrl(url), getTypeNameFromUrl(url));
}

private str getPackageNameFromUrl(str url) {
	return replaceAll(substring(url, 11, findLast(url, ".")), "/", ".");
}

private str getTypeNameFromUrl(str url) {
	return substring(url, findLast(url, "/") + 1, size(url) - 5);
}
