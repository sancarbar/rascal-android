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
			text(class);
			m = class["sig"];
			println("class[sig] <m["name"]>");
			createClassFile(class["package_path"], class["name"], [], class["sig"].extends, class["sig"]["implements"]);
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
												"sig" : extractClassSig(|http://developer.android.com<alink@href>|),
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

public map[str, value] getClassInformation(loc classInformationUrl) {
	node html = readHTMLFile(classInformationUrl);
	
	str entry_type = "";
	
	set[map[str,value]] methodSet = {};
	set[map[str,value]] constantSet = {};
	set[map[str,value]] fieldSet = {};
	set[map[str,value]] constructorSet = {};
	
	set[map[str,value]] dataTypes = {};
	
	visit(html){
		case h2_elem:"h2"(h2_content): {
			visit(h2_content) {
				case text_elem:"text"(text_content): entry_type = text_content;
			}
		} 
		case div:"div"(div_method): if(/jd-details / := (div@class ? "")) {
			str methodName = "";
			str apiLevel = "";
			
			visit(div_method) {
				case header:"h4"(h4_content): if((header@class ? "" ) == "jd-details-title") {
					// Get urls
					visit(h4_content){
						case alink:"a"(a_content): if((alink@href ? "") != "") {
							visit(a_content) {
								case atext:"text"(text_content): {
									map[str,value] datatype_info = (
										"name":text_content,
										"url":|http://developer.android.com<alink@href>|,
										"package_path":replaceAll(substring(alink@href, 11, size(alink@href) - 5), "/", ".")
									);
									dataTypes += {datatype_info};
								}
							}
						}
					}
					// Get Text.
		  			visit(h4_content){
						case text:"text"(method_sig): methodName += method_sig;
					}
				}
				case apidiv:"div"(div_content): if((apidiv@class ? "") == "api-level") {
					visit(div_content) {
						case text:"text"(api_level): apiLevel += api_level;
					}
				}
			}
			map[str,value] method = (
				"sig" : methodName, 
				"api" : apiLevel,
				"information": extractInformationFromSignature(entry_type, methodName, dataTypes = dataTypes)
			);
			
			switch(entry_type) {
				case "Public Methods":  methodSet += {method};
				case "Public Constructors": constructorSet += {method}; 
				case "Constants": constantSet += {method};
				case "Fields": fieldSet += {method}; 
				case "Protected Methods": methodSet += {method};
			}
		}
	}
	
	map[str,value] classDescription = (
		"methods": methodSet,
		"constants": constantSet,
		"fields": fieldSet,
		"constructors": constructorSet,
		"innerclasses": "TODO"
	);
	
	return classDescription;
}

public map[str,value] extractClassSig(loc classInformationUrl){
	node html = readHTMLFile(classInformationUrl);
	str class_sig = "";
	visit(html){
		 
		case divC:"div"(div_class_sig): if((divC@id ? "") == "jd-header"){
			visit(div_class_sig){
				case text:"text"(text_content) :{ class_sig += text_content + " ";}
				case alink:"a"(a_content) :if((alink@href ? "") != "") {
					class_sig += alink@href + " ";
				} 
						
			}
			//println("class + <class_sig>");
		}
	}
	//to remove the last space and avoid parse errors.
	int i = size(class_sig);
	class_sig = class_sig[0..i-1];

	map[str,value] classSignature = ();
	list[map[str,value]] impSet = [];
	node class_AST = parseClassToAST(class_sig);
	println(class_AST);
	visit(class_AST){
	//v1 = modifiers, v2 = name, v3= list of extenders, v4 = list of implementers
		case "class"(v1,v2,v3,v4):{
			classSignature["state"] = v1; 
			classSignature["name"] = v2; 
			visit(v3){
				case ex:"extends"(l):{
					visit(l){
						case "link"(l1,l2):{ 
							classSignature["extends"] =  ("url":l2, "type":getTypeFromUrl(l2));
						}
					}
				}
			}
			visit(v4){
				case impl:"implements"(im):{
					visit(im){			
						case "link"(i1,i2):{ 
						    //map(implements: {()
							impSet += ("url":i2, "type":getTypeFromUrl(i2));
						}
					}
					classSignature["implements"] = impSet;
				}
			}
		} 
	}
	return classSignature;
}

private Type getTypeFromUrl(str url){
	return  \type(substring(url, findLast(url, "/") + 1, size(url) - 5), replaceAll(substring(url, 11, findLast(url,"/")), "/", "."));
}

public void extractInformationFromMethodSignature()
{}

public map[str,value] extractInformationFromSignature(str sectionType, str signature, set[map[str,value]] dataTypes = {}) {
	map[str,value] extractedInformation = ();
	
	
	
	
	switch (sectionType) {
		case "Constants": {
			// extractInformationFromSignature("Constants", "public static final int fade_in");	
			if (/<visibility:public|private|protected>? *<state1:static|abstract|final>? *<state2:static|abstract|final>? *<dtype:[a-zA-Z0-9_\-\.]*> *<pname:[a-zA-Z0-9_\-]*>/ := signature) {
				extractedInformation += (
					"visibility": visibility,
					"state": "<state1> <state2>",
					"dtype": dtype,
					"property_name": pname
				);
			}
		}
		case "Public Methods": {
			// extractInformationFromSignature("Public Methods", "public void setFeature (String name, boolean value)");
			if (/<visibility:public|private|protected>? *<state1:static|abstract|final>? *<state2:static|abstract|final>? *<dtype:[a-zA-Z0-9_\-\.]*> *<mname:[a-zA-Z0-9_\-]*> *\(<params:.*>\)/ := signature) {
			
				list[str] params = split(",", params);
				list[value] splittedparam = [];
				for (param <- params) {
					splittedparam += split(" ", trim(param));
					
					// TODO: Matching data type information.
					
				}
			
			
				extractedInformation += (
					"visibility": visibility,
					"state": trim("<state1> <state2>"),
					"type": dtype,
					"method_name": mname,
					"parameters": splittedparam
				);
			}
		}
	}
	
	return extractedInformation;
}