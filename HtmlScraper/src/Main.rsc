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
	loc project = |http://developer.android.com/reference/packages.html|;
	for (package <- getPackages(project)) {
		map[str,set[map[str,value]]] information = getPackageInformation(package, apiLevel);
		for (class <- information["classes"]) {
			url = class["url"];
			packagePath = class["package_path"];
			println("url <url>");
			buildClass(url, packagePath, apiLevel);
		}
	}
}

public void buildClass(loc url, str packagePath, int api) {
	// Get class information
	map[str, list[list[node]]] classConstructs = getClassConstructs(url, api);
	str classSignature = extractClassSig(url);
	node classAst = parseClassToAST(classSignature);
	str classType = getClassType(classAst);
	str className = getClassName(classAst);
	str classModifiers = intercalate(" ", getClassModifiers(classAst));
	Type classSuperClass = getClassSuperClass(classAst);
	list[Type] classInterfaces = getClassInterfaces(classAst);
	lrel[str, lrel[str, Type]] classConstructors = getConstructors(classConstructs["constructors"]);
	lrel[str, str, Type] classMethodsAndFields = getConstantsAndFields(classConstructs["constants"] + classConstructs["fields"]);
	lrel[str, str, Type, lrel[str, Type]] classMethods = getMethods(classConstructs["methods"]);

	// Fix bug in documentation: some interface implement interfaces, which isn't possible in Java (see: http://developer.android.com/reference/org/xml/sax/ext/Attributes2.html)
	if (classType == "interface") {
		if (!isEmpty(classInterfaces)) {
			classSuperClass = head(classInterfaces);
			classInterfaces = [];
		}
	}

	// Create class file
	createClassFile(packagePath, classType, className, classModifiers, classSuperClass, classInterfaces, classMethodsAndFields, classConstructors, classMethods);
}

// Parses the constructors and returns them in the needed type for creating the templates
public lrel[str, lrel[str, Type]] getConstructors(list[list[node]] constructorNodes) {
	lrel[str, lrel[str, Type]] constructors = [];
	// Get constructors
	for(constructor <- constructorNodes){
		str constructorSignature = getConstructSignature(constructor);
		list[str] argumentSignatures = getConstructArgumentSignatures(constructorSignature);
		// Get arguments of constructor
		lrel[str, Type] arguments = [];
		for (argumentSignature <- argumentSignatures) {
			str argumentName = getConstructName(argumentSignature);
			Type argumentType = getConstructType(argumentName, argumentSignature, constructor);
			arguments += <argumentName, argumentType>;
		}
		constructors += <constructorSignature, arguments>;
	}
	return constructors;
}

// Parses the constants and fields and returns them in the needed type for creating the templates
public lrel[str, str, Type] getConstantsAndFields(list[list[node]] methodsAndFieldsNodes) {
	lrel[str, str, Type] constantsAndFields = [];
	// Get constants and fields
	for(constant <- methodsAndFieldsNodes){
		str constantSignature = getConstructSignature(constant);
		str constantName = getConstructName(constantSignature);
		str constantModifiers = getConstructModifiers(constantSignature);
		Type contantType = getConstructType(constantName, constantSignature, constant);
		constantsAndFields += <constantName, constantModifiers, contantType>;
	}
	return constantsAndFields;
}

// Parses the methods and returns them in the needed type for creating the templates
public lrel[str, str, Type, lrel[str, Type]] getMethods(list[list[node]] methodNodes) {
	lrel[str, str, Type, lrel[str, Type]] methods = [];
	// Get methods
	for(method <- methodNodes) {
		str methodSignature = getConstructSignature(method);
		str methodName = getConstructName(methodSignature);
		str methodModifiers = getConstructModifiers(methodSignature);
		Type methodReturnType = getConstructType(methodName, methodSignature, method);
		list[str] argumentSignatures = getConstructArgumentSignatures(methodSignature);

		// Get arguments of method
		lrel[str, Type] arguments = [];
		for (argumentSignature <- argumentSignatures) {
			str argumentName = getConstructName(argumentSignature);
			Type argumentType = getConstructType(argumentName, argumentSignature, method);
			arguments += <argumentName, argumentType>;
		}

		methods += <methodName, methodModifiers, methodReturnType, arguments>;
	}
	return methods;
}

public set[loc] getPackages(loc packageSummaryUrl) {
	node html = readHTMLFile(packageSummaryUrl);
	set[loc] packages = {};
	
	// Get parent div with list of anchors.
	visit(html) {
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
	node html = readHTMLFile(packageInformationUrl);
	
	set[str] urlSet = {};
	set[map[str,value]] classSet = {};
	set[map[str,value]] interfaceSet = {};
	set[map[str,value]] exceptionSet = {};
	set[map[str,value]] enumsSet = {};
	set[map[str,value]] errorSet = {};
	
	visit(html){
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
												"sig" : extractClassSig(|http://developer.android.com<alink@href>|),
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


public list[loc] getNestedClasses(loc classUrl){

	node ast = readHTMLFile(classUrl);
	//table tags are not properly closed on website, therefore match on tableheader
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
}

public map[str, list[list[node]]] getClassConstructs(loc classUrl, value api) {
	node html = readHTMLFile(classUrl);
	list[list[node]] methods = [];
	list[list[node]] constants = [];
	list[list[node]] fields = [];
	list[list[node]] constructors = [];
	list[list[node]] innerClasses = [];
	
	str construct;
	visit(html) {
		case h2Elem:"h2"(h2Content): {
			visit(h2Content) {
				case textElem:"text"(textContent): construct = textContent;
			}
		}
		case div:"div"(divMethod): if(/jd-details / := (div@class ? "")) {
			list[node] constructNode;
			str apiLevel = "";
			value apiLvl = 0;
			visit(divMethod) {
				case header:"h4"(h4Content): if ((header@class ? "" ) == "jd-details-title") {
					constructNode = h4Content;
				}
				case divApi:"div"(divContent): if((divApi@class ? "") == "api-level") {
					visit(divContent) {
						case text:"text"(apiLevelContent): 
						{
							apiLevel = apiLevelContent;
							if(/.*\s<lvl:[0-9]+>/ := apiLevel){
							apiLvl = lvl;
							}
							
						}						
					}
				}
			}
			//do add the methods with the apiLevels that are higher than the version currently bui;d
			if(apiLvl > api) {
				methods += [];
			}
			else {
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
	visit(constructNodes) {
		case text:"text"(partOfSignature): signature += partOfSignature;
	}
	return signature;
}

public str getConstructName(str constructSignature) {
	str name = "";
	if (/(public|private|protected|static|abstract|final|\s)*[a-zA-Z0-9_\-\.\[\]]*\s*<constructName:[a-zA-Z0-9_\-]*>/ := constructSignature) {
		name = constructName;
	}
	return name;
}

public str getConstructModifiers(str constructSignature) {
	str modifiers = "";
	if (/<modifierNames:(public|private|protected|static|abstract|final|\s)*>/ := constructSignature) {
		modifiers = modifierNames;
	}
	return modifiers;
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

public list[str] getConstructArgumentSignatures(str constructSignature) {
	if (/\(<params:.*>\)/ := constructSignature) {
		return [ trim(param) | param <- split(",", params), !isEmpty(trim(param)) ];
	}
}

public str extractClassSig(loc classInformationUrl){
	node html = readHTMLFile(classInformationUrl);
	str class_sig = "";
	visit(html){
		case divC:"div"(div_class_sig): if((divC@id ? "") == "jd-header") {
			visit(div_class_sig) {
				case text:"text"(text_content) :{ class_sig += text_content + " ";}
				case alink:"a"(a_content) :if((alink@href ? "") != "") {
					class_sig += alink@href + " ";
				}
			}
		}
	}
	return trim(class_sig);
}

public str getClassName(node ast) {
	visit(ast) {
		case "class"(_,name,_,_): {
			return name;
		}
		case "interface"(_,name,_,_): {
			return name;
		}
		case "enum"(_,name,_,_): {
			return name;
		}
	}
}

public str getClassType(node ast) {
	visit(ast) {
		case "class"(_,_,_,_): {
			return "class";
		}
		case "interface"(_,_,_,_): {
			return "interface";
		}
		case "enum"(_,_,_,_): {
			return "enum";
		}
	}
}

public Type getClassSuperClass(node ast) {
	Type superClass = \void();
	visit(ast) {
		case ex:"extends"(l): {
			visit(l){
				case "link"(l1,l2): {
					superClass = getTypeFromUrl(l2);
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
				case "link"(i1,i2): {
					interfaces += getTypeFromUrl(i2);
				}
			}
		}
	}
	return interfaces;
}

public list[str] getClassModifiers(node ast) {
	visit(ast) {
		case "class"(modifiers,_,_,_): {
			return modifiers;
		}
		case "interface"(modifiers,_,_,_): {
			return modifiers;
		}
		case "enum"(modifiers,_,_,_): {
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
