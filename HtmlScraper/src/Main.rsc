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

// Annotations
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
	str classSignature = getClassSignature(classHtml);
	bool isDeprecated = isClassDeprecated(classHtml);
	classAst = parse(#ClassDef, classSignature);
	str className = getClassName(classAst);
	str classModifiers = getClassModifiers(classAst);
	str classType = getClassTypeCategory(classAst);
	Type classSuperClass = getClassSuperClass(classAst);
	list[Type] classInterfaces = getClassInterfaces(classAst);
	
	list[Constructor] constructors = getConstructors(classConstructs["constructors"]);
	list[ConstantField] constantsAndFields = getConstantsAndFields(classConstructs["constants"] + classConstructs["fields"]);
	list[Method] methods = getMethods(classConstructs["methods"]);

	// Check for innerclasses
	if(contains(className, ".")) {
		if (acceptNestedClass) {
			name = substring(className, findFirst(className, ".") + 1, size(className));
		} else {
			return nothing();
		}
	}

	// Fix bug in documentation: some interface implement interfaces, which isn't possible in Java (see: http://developer.android.com/reference/org/xml/sax/ext/Attributes2.html)
	if (classType == "interface") {
		if (!isEmpty(classInterfaces)) {
			superClass = head(classInterfaces);
			interfaces = [];
		}
	}

	return just(class(packagePath, classType, className, classModifiers, classSuperClass, classInterfaces, isDeprecated, constantsAndFields, constructors, methods, []));
}

// Parses the constructors and returns them in the needed type for creating the templates
public list[Constructor] getConstructors(list[list[node]] constructorNodes) {
	list[Constructor] constructors = [];
	// Get constructors
	for(constructorNode <- constructorNodes){
		str constructorSignature = getConstructSignature(constructorNode);
		constructorAst = parse(#ConstructDef, constructorSignature);
		str constructorName = getConstructName(constructorAst);
		str constructorModifiers = getConstructModifiers(constructorAst);
		list[Argument] constuctorArguments = getConstructArguments(constructorAst);
		constructors += constructor(constructorName, constructorModifiers, constuctorArguments);
	}
	return constructors;
}

// Parses the constants and fields and returns them in the needed type for creating the templates
public list[ConstantField] getConstantsAndFields(list[list[node]] constantsAndFieldsNodes) {
	list[ConstantField] constantsAndFields = [];
	// Get constants and fields
	for(constantOrFieldNode <- constantsAndFieldsNodes){
		str constantSignature = getConstructSignature(constantOrFieldNode);
		constantAst = parse(#ConstructDef, constantSignature);
		str constantName = getConstructName(constantAst);
		str constantModifiers =  getConstructModifiers(constantAst);
		Type contantType = getConstructType(constantAst);
		constantsAndFields += constantField(constantName, constantModifiers, contantType);
	}
	return constantsAndFields;
}

// Parses the methods and returns them in the needed type for creating the templates
public list[Method] getMethods(list[list[node]] methodNodes) {
	list[Method] methods = [];
	// Get methods
	for(methodNode <- methodNodes) {
		str methodSignature = getConstructSignature(methodNode);
		methodAst = parse(#ConstructDef, methodSignature);
		str methodName = getConstructName(methodAst);
		str methodModifiers = getConstructModifiers(methodAst);
		Type methodReturnType = getConstructType(methodAst);
		list[Argument] methodArguments = getConstructArguments(methodAst);
		methods += method(methodName, methodModifiers, methodReturnType, methodArguments);
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

public str getClassSignature(node classHtml) {
	str class_sig = "";
	visit(classHtml) {
		case divC:"div"(div_class_sig): if((divC@id ? "") == "jd-header") {
			visit(div_class_sig) {
				case text:"text"(text_content) :{ class_sig += text_content + " "; }
				case alink:"a"(a_content) :if((alink@href ? "") != "") {
					class_sig += alink@href + " ";
				}
			}
		}
	}
	return trim(class_sig);
}

public str getClassName(ClassDef classDef) {
	visit (classDef) {
		case (ClassDef)`<Modifiers+ _> <TypeCategory _> <Iden i> <ExtendsClause? _> <ImplementsClause? _>`: return "<i>";
	}
}

public str getClassModifiers(ClassDef classDef) {
	visit (classDef) {
		case (ClassDef)`<Modifiers+ m> <TypeCategory _> <Iden i> <ExtendsClause? _> <ImplementsClause? _>`: return "<m>";
	}
}

public str getClassTypeCategory(ClassDef classDef) {
	visit (classDef) {
		case (ClassDef)`<Modifiers+ _> <TypeCategory t> <Iden i> <ExtendsClause? _> <ImplementsClause? _>`: return "<t>";
	}
}

public Type getClassSuperClass(ClassDef classDef) {
	visit (classDef) {
		case (ClassDef)`<Modifiers+ _> <TypeCategory t> <Iden i> <ImplementsClause? _>`: return \void();
		case (ClassDef)`<Modifiers+ _> <TypeCategory t> <Iden i> <ExtendsClause e> <ImplementsClause? _>`: return getExtendsClause(e);
	}
}

Type getExtendsClause((ExtendsClause)`extends <Type t>`) = getType(t);
default Type getExtendsClause(ExtendsClause e) { throw "You forgot a case for <e>"; }

public list[Type] getClassInterfaces(ClassDef classDef) {
	visit (classDef) {
		case (ClassDef)`<Modifiers+ _> <TypeCategory t> <Iden i> <ExtendsClause? _>`: return [];
		case (ClassDef)`<Modifiers+ _> <TypeCategory t> <Iden i> <ExtendsClause? _> <ImplementsClause i>`: return getImplementsClause(i);
	}
}

list[Type] getImplementsClause((ImplementsClause)`implements <Type+ ts>`) = [ getType(t) | t <- ts ];
default list[Type] getImplementsClause(ImplementsClause i) { throw "You forgot a case for <i>"; }

public str getConstructSignature(list[node] constructNodes) {
	str signature = "";
	visit (constructNodes) {
		case text:"text"(partOfSignature): signature += partOfSignature;
		case alink:"a"(linkToTypes): if ((alink@href ? "") != "") signature += " " + alink@href + " ";
	}
	return signature;
}

public str getConstructName(ConstructDef constructDef) {
	visit (constructDef) {
		case (ConstructDef)`<Modifiers+ _> <Type _> <Iden i> ( <Arguments _> )`: return "<i>";
		case (ConstructDef)`<Modifiers+ _> <Type _> <Iden i>`: return "<i>";
		case (ConstructDef)`<Modifiers+ _> <Iden i> ( <Arguments _> )`: return "<i>";
	}
}

public str getConstructModifiers(ConstructDef constructDef) {
	visit (constructDef) {
		case (ConstructDef)`<Modifiers+ m> <Type _> <Iden _> ( <Arguments _> )`: return "<m>";
		case (ConstructDef)`<Modifiers+ m> <Type _> <Iden _>`: return "<m>";
		case (ConstructDef)`<Modifiers+ m> <Iden _> ( <Arguments _> )`: return "<m>";
	}
}

public Type getConstructType(ConstructDef constructDef) {
	println(constructDef);
	visit (constructDef) {
		case (ConstructDef)`<Modifiers+ _> <Type t> <Iden _> ( <Arguments _> )`: return getType(t);
		case (ConstructDef)`<Modifiers+ _> <Type t> <Iden _>`: return getType(t);
	}
}

Type getType((Type)`void`) = \void();
Type getType((Type)`<Iden i>`) = \array(getType([SignatureParser::Type] b))
	when /^<b:.*>\[\]$/ := "<i>";
Type getType((Type)`<Iden i>`) = \typeParameter("<i>")
	when size("<i>") == 1;
Type getType((Type)`<Iden i>`) = \primitive("<i>");
Type getType((Type)`<Iden i> <Link l>`) = \type(getPackageNameFromUrl("<l>"), "<i>");
Type getType((Type)`<Iden i> <Link l> <NestedGeneric g>`) = \type(getPackageNameFromUrl("<l>"), "<i>", getNestedGeneric(g));
default Type getType(Type t) { throw "You forgot a case for <t>"; }

list[Generic] getNestedGeneric((NestedGeneric)`\<<{Generic ","}* gs>\>`) = [ getGeneric(g) | g <- gs ];
default list[Generic] getNestedGeneric(NestedGeneric g) { throw "You forgot a case for <g>"; }

Generic getGeneric((Generic)`<Type t>`) = \simpleGeneric(getType(t));
Generic getGeneric((Generic)`<Type t> <ExtendsClause e>`) = \extendsGeneric(getType(t), getExtendsClause(e));
Generic getGeneric((Generic)`<Type t> <SuperClause s>`) = \superGeneric(getType(t), getType(s));
default Generic getGeneric(Generic g) { throw "You forgot a case for <g>"; }

Type getSuperClause((SuperClause)`super <Type t>`) = getType(t);
default Type getSuperClause(SuperClause s) { throw "You forgot a case for <s>"; }


public list[Argument] getConstructArguments(ConstructDef constructDef) {
	visit (constructDef) {
		case (ConstructDef)`<Modifiers+ m> <Type _> <Iden _> ( <Arguments as> )`: return getArguments(as);
		case (ConstructDef)`<Modifiers+ m> <Iden _> ( <Arguments as> )`: return getArguments(as);
	}
}

list[Argument] getArguments((Arguments)`<{Argument ","}* as>`) = [ getArgument(a) | a <- as ];
default Generic getArguments(Arguments as) { throw "You forgot a case for <as>"; }

Argument getArgument((Argument)`<Type t> <Iden i>`) = argument("<i>", getType(t));
default Generic getArgument(Argument a) { throw "You forgot a case for <a>"; }

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

private str getPackageNameFromUrl(str url) {
	return replaceAll(substring(url, 11, findLast(url, ".")), "/", ".");
}
