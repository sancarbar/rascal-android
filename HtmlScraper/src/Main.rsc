module Main

import IO;
import lang::html::IO;
import Set;
import util::ValueUI;
import Location;
import String;
import Template;
import ParseTree;
import SignatureParser;

//annotations

anno str node@id;
anno str node@href;
anno str node@class;

// |http://developer.android.com/reference/packages.html|

public void main() {
	loc project = |http://developer.android.com/reference/packages.html|;
	
	set[value] packages = {};
	
	for (package_info <- getPackages(project)) {
		// Retrieve detailed package information.
		map[str,set[map[str,value]]] information = getPackageInformation(package_info["url"]);
		// Add detailed to package information to the package information we already have.
		map[str, value] package_information = package_info + ("information":information);
		// Add full package information to set.
		packages += {package_information};
		text(package_information);		
	}
	
	text(packages);
}

public void buildProject() {
	loc project = |http://developer.android.com/reference/packages.html|;
	for (package_info <- getPackages(project)) {
		map[str,set[map[str,value]]] information = getPackageInformation(package_info["url"]);
		for (class <- information["classes"]) {
			//text(class);
			url = class["url"];
			methods = getMethodsOfClass(url);
			println("url <url>");
			//text(methods);

			for(method <- methods) {
				str signature = getConstructSignature(method);
				println(signature);
				println(getConstructName(signature));
				println("----------------------");
			}

			//lrel[str name, Type returnType, lrel[str, Type] arguments] methodss = [<"a", \void(), []> | method <- methods];
			//createClassFile(class["package_path"], class["name"], [], class["sig"].extends, class["sig"]["implements"]);
			//createClassFile(class["package_path"], class["name"], []);
		}
	}
}

public set[map[str,value]] getPackages(loc packageSummaryUrl) {
	// Read html file as Node.
	node html = readHTMLFile(packageSummaryUrl);
	
	set[map[str,value]] packageSet = {};
	
	// Get parent div with list of anchors.
	visit(html) {
		case parent:"div"(ulist): if((parent@id ? "") == "packages-nav") {
			// Get anchors.
			visit(ulist) {
				case alink:"a"(a_content): if((alink@href ? "") != "") {
					// Get Names
					visit(a_content) {
						case atext:"text"(text_content): { 
							map[str,value] package_info = (
								"package":text_content,
								"url":|http://developer.android.com<alink@href>|
							);
							// Add anchor to set.
							packageSet += {package_info};
						}
					}		
				}
			}
		}
	}
	
	return packageSet;
}

public map[str, set[map[str, value]]] getPackageInformation(loc packageInformationUrl) {
	node html = readHTMLFile(packageInformationUrl);
	
	set[str] urlSet = {};
	set[map[str,value]] classSet = {};
	set[map[str,value]] interfaceSet = {};
	set[map[str,value]] exceptionSet = {};
	set[map[str,value]] enumsSet = {};
	set[map[str,value]] errorSet = {};
	
	visit(html) {
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
												"sig" : "TODO", //extractClassSig(|http://developer.android.com<alink@href>|),
												"name":text_content,
												"url":|http://developer.android.com<alink@href>|,
												"package_path":replaceAll(substring(alink@href, 11, findLast(alink@href, "/")), "/", ""),
												"information":getClassInformation(|http://developer.android.com<alink@href>|)
											);
											// Group by class type.
											switch (entry_type)
											{
												case "Classes": {
													classSet += {package_info};
													
													//getClassInformation(|http://developer.android.com<package_info["url"]>|);
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
	
	map[str,set[map[str,value]]] packageDescription = (
		"classes": classSet,
		"interfaces": interfaceSet,
		"exceptions": exceptionSet,
		"enums": enumsSet,
		"errors": errorSet
	);
	
	return packageDescription;
}

public list[list[node]] getMethodsOfClass(loc classUrl) {
	return getClassConstructs(classUrl)["methods"];
}

public list[list[node]] getConstructorsOfClass(loc classUrl) {
	return getClassConstructs(classUrl)["constructors"];
}

public list[list[node]] getConstantsOfClass(loc classUrl) {
	return getClassConstructs(classUrl)["constants"];
}

public list[list[node]] getFieldsOfClass(loc classUrl) {
	return getClassConstructs(classUrl)["fields"];
}

private map[str, list[list[node]]] getClassConstructs(loc classUrl) {
	node html = readHTMLFile(classUrl);
	list[list[node]] methods = [];
	list[list[node]] constants = [];
	list[list[node]] fields = [];
	list[list[node]] constructors = [];
	
	str construct;
	visit(html) {
		case h2Elem:"h2"(h2Content): {
			visit(h2Content) {
				case textElem:"text"(textContent): construct = textContent;
			}
		}
		case div:"div"(divMethod): if(/jd-details / := (div@class ? "")) {
			list[node] constructNode;
			visit(divMethod) {
				case header:"h4"(h4Content): if ((header@class ? "" ) == "jd-details-title") {
					constructNode = h4Content;
				}
			}
			switch(construct) {
				case "Public Methods":  methods += [constructNode];
				case "Public Constructors": constructors += [constructNode];
				case "Constants": constants += [constructNode];
				case "Fields": fields += [constructNode];
				case "Protected Methods": methods += [constructNode];
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
	if (/(public|private|protected)?\s*(static|abstract|final){0,3}\s*[a-zA-Z0-9_\-\.]*\s*<constructName:[a-zA-Z0-9_\-]*>/ := constructSignature) {
		name = constructName;
	}
	return name;
}

//public map[str, set[map[str,value]]] getClassInformation(loc classInformationUrl) {
//	node html = readHTMLFile(classInformationUrl);
//
//	str entry_type = "";
//
//	set[map[str,value]] methodSet = {};
//	set[map[str,value]] constantSet = {};
//	set[map[str,value]] fieldSet = {};
//	set[map[str,value]] constructorSet = {};
//
//	set[map[str,value]] dataTypes = {};
//
//	visit(html){
//		case h2_elem:"h2"(h2_content): {
//			visit(h2_content) {
//				case text_elem:"text"(text_content): entry_type = text_content;
//			}
//		}
//		case div:"div"(div_method): if(/jd-details / := (div@class ? "")) {
//			str methodName = "";
//			str apiLevel = "";
//
//			visit(div_method) {
//				case header:"h4"(h4_content): if((header@class ? "" ) == "jd-details-title") {
//					// Get urls
//					visit(h4_content){
//						case alink:"a"(a_content): if((alink@href ? "") != "") {
//							visit(a_content) {
//								case atext:"text"(text_content): {
//									map[str,value] datatype_info = (
//										"name":text_content,
//										"url":|http://developer.android.com<alink@href>|,
//										"package_path":replaceAll(substring(alink@href, 11, size(alink@href) - 5), "/", ".")
//									);
//									dataTypes += {datatype_info};
//								}
//							}
//						}
//					}
//					// Get Text.
//		  			visit(h4_content){
//						case text:"text"(method_sig): methodName += method_sig;
//					}
//				}
//				case apidiv:"div"(div_content): if((apidiv@class ? "") == "api-level") {
//					visit(div_content) {
//						case text:"text"(api_level): apiLevel += api_level;
//					}
//				}
//			}
//			map[str,value] method = (
//				"sig" : methodName,
//				"api" : apiLevel,
//				"information": extractInformationFromSignature(entry_type, methodName, dataTypes = dataTypes)
//			);
//
//			switch(entry_type) {
//				case "Public Methods":  methodSet += {method};
//				case "Public Constructors": constructorSet += {method};
//				case "Constants": constantSet += {method};
//				case "Fields": fieldSet += {method};
//				case "Protected Methods": methodSet += {method};
//			}
//		}
//	}
//
//	map[str,set[map[str,value]]] classDescription = (
//		"methods": methodSet,
//		"constants": constantSet,
//		"fields": fieldSet,
//		"constructors": constructorSet
//		//"innerclasses": "TODO"
//	);
//
//	return classDescription;
//}

public map[str,value] extractClassSig(loc classInformationUrl){
	node html = readHTMLFile(classInformationUrl);
	str entry_type = "";
	str class_sig = "";
	visit(html){
		 
		case divC:"div"(div_class_sig): if((divC@id ? "") == "jd-header"){
			visit(div_class_sig){
				case text:"text"(text_content) :{ class_sig += " " + text_content;}
				case alink:"a"(a_content) :if((alink@href ? "") != "") {
					class_sig += " " + alink@href + " ";
				} 
						
			}
			println(class_sig);
			//println(parse(#ClassDef,class_sig));
		}
	}
	map[str,value] classSignature = ();
	if(/\s<words:.*>(extends\s+<ex:.*>)?(implements\s+<imp:.*>)?/ := class_sig) 
	{
	  println("words + <words>");

	  if(/<state:.*>\s+<name:\w+>/ := words)
	  {
	    classSignature["state"] = state;
	    classSignature["name"] = name;
	  }
	  str url = trim(substring(ex,findFirst(ex,"/"),size(ex)));
	  classSignature["extends"] =  ("url":url, "type":getTypeFromUrl(url));
	  classSignature ["implements"] = [("url" : i, "type": getTypeFromUrl(i)) | i <- split(" ",imp), contains(i,"/reference")];

	}
	return classSignature;
}

private Type getTypeFromUrl(str url){
	return  \type(substring(url, findLast(url, "/") + 1, size(url) - 5), replaceAll(substring(url, 11, findLast(url,"/")), "/", "."));
}

//public map[str,value] extractInformationFromSignature(str sectionType, str signature, set[map[str,value]] dataTypes = {}) {
//	map[str,value] extractedInformation = ();
//
//
//
//
//	switch (sectionType) {
//		case "Constants": {
//			// extractInformationFromSignature("Constants", "public static final int fade_in");
//			if (/<visibility:public|private|protected>? *<state1:static|abstract|final>? *<state2:static|abstract|final>? *<dtype:[a-zA-Z0-9_\-\.]*> *<pname:[a-zA-Z0-9_\-]*>/ := signature) {
//				extractedInformation += (
//					"visibility": visibility,
//					"state": "<state1> <state2>",
//					"dtype": dtype,
//					"property_name": pname
//				);
//			}
//		}
//		case "Public Methods": {
//			// extractInformationFromSignature("Public Methods", "public void setFeature (String name, boolean value)");
//			if (/<visibility:public|private|protected>? *<state1:static|abstract|final>? *<state2:static|abstract|final>? *<dtype:[a-zA-Z0-9_\-\.]*> *<mname:[a-zA-Z0-9_\-]*> *\(<params:.*>\)/ := signature) {
//
//				list[str] params = split(",", params);
//				list[value] splittedparam = [];
//				for (param <- params) {
//					splittedparam += split(" ", trim(param));
//
//					// TODO: Matching data type information.
//
//				}
//
//
//				extractedInformation += (
//					"visibility": visibility,
//					"state": trim("<state1> <state2>"),
//					"type": dtype,
//					"method_name": mname,
//					"parameters": splittedparam
//				);
//			}
//		}
//	}
//
//	return extractedInformation;
//}
