module Main

import IO;
import lang::html::IO;
import Set;
import util::ValueUI;
import Location;
import String;
import Template;

anno str node@id;
anno str node@href;
anno str node@class;

// |http://developer.android.com/reference/packages.html|

public void main() {
	loc project = |http://developer.android.com/reference/packages.html|;
	for (package_info <- getPackages(project)) {
		//println(package_info);
		map[str,set[map[str,str]]] information = getPackageInformation(|http://developer.android.com<package_info["url"]>|);
		iprintln(information);
	}
}

public void buildProject() {
	loc project = |http://developer.android.com/reference/packages.html|;
	map[str,str] package_info = getOneFrom(getPackages(project));
	map[str,set[map[str,str]]] information = getPackageInformation(|http://developer.android.com<package_info["url"]>|);
	for (class <- information["classes"]) {
		createClassFile(class["package_path"], class["name"], []);
	}
}

public set[map[str,str]] getPackages(loc packageSummaryUrl) {
	// Read html file as Node.
	node html = readHTMLFile(packageSummaryUrl);
	
	set[map[str,str]] packageSet = {};
	
	// Get parent div with list of anchors.
	visit(html) {
		case parent:"div"(ulist): if((parent@id ? "") == "packages-nav") {
			// Get anchors.
			visit(ulist) {
				case alink:"a"(a_content): if((alink@href ? "") != "") {
					// Get Names
					visit(a_content) {
						case atext:"text"(text_content): { 
							map[str,str] package_info = (
								"package":text_content,
								"url":alink@href
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

public map[str, set[map[str, str]]] getPackageInformation(loc packageInformationUrl) {
	node html = readHTMLFile(packageInformationUrl);
	
	set[str] urlSet = {};
	set[map[str,str]] classSet = {};
	set[map[str,str]] interfaceSet = {};
	set[map[str,str]] exceptionSet = {};
	set[map[str,str]] enumsSet = {};
	set[map[str,str]] errorSet = {};
	
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
											map[str,str] package_info = (
												"name":text_content,
												"url":alink@href,
												"package_path":substring(alink@href, 11, findLast(alink@href, "/"))
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
	
	map[str,set[map[str,str]]] packageDescription = (
		"classes": classSet,
		"interfaces": interfaceSet,
		"exceptions": exceptionSet,
		"enums": enumsSet,
		"errors": errorSet
	);
	
	return packageDescription;
}

	//str methodName = "";
	set[map[str,str]] methodSet = {};
	set[map[str,str]] constantSet = {};
	set[map[str,str]] fieldSet = {};
	set[map[str,str]] constructorSet = {};
	str entry_type = "";
	visit(html){
		
		case h2_elem:"h2"(h2_content): {
					visit(h2_content) {
						case text_elem:"text"(text_content): entry_type = text_content;
					}
				} 
		case div:"div"(div_method): if(/jd-details / := (div@class ? ""))
		{
			//println(entry_type);
			str methodName = "";
			str apiLevel = "";
			visit(div_method){
				case header:"h4"(h4_content): if((header@class ? "" ) == "jd-details-title")
				{
		  			//str methodName = "";
					visit(h4_content){
					case text:"text"(method_sig): methodName += method_sig;
					}
				}
				case apidiv:"div"(div_content): if((apidiv@class ? "") == "api-level")
				{
					visit(div_content){
						case text:"text"(api_level): apiLevel += api_level;
						}

				}
			}
			map[str,str] method = ("sig" : methodName, "api" : apiLevel);
			
			switch(entry_type){
				case "Public Methods":  methodSet += {method};
				case "Public Constructors": constructorSet += {method}; 
				case "Constants": constantSet += {method};
				case "Fields": fieldSet += {method}; 
				case "Protected Methods": methodSet += {method};
			}
			
		}
		
		
	}
	//println(methodSet);
	map[str,set[map[str,str]]] classDescription = (
		"methods": methodSet,
		"constants": constantSet,
		"fields": fieldSet,
		"constructors": constructorSet
	);
	
	return classDescription;
}
/*
public set[str] getClassesUrls(str packageURL)
{
	//add reference to the base url
	packageUrlTotal = |http://developer.android.com|; 
	packageUrlTotal += packageURL;
	node packageFile = readHTMLFile(packageUrlTotal);
	
	set[str] classUrlSet = {};
	
	visit(packageFile){
	 case parent:"div"(table): if((parent@id ? "missing") == "jd-content")
	 {
	 	visit(table){

				case alink:"a"(_): if((alink@href ? "") != "") {

					classUrlSet += {alink@href};
				}
	 	};
	 }
	};

	return classUrlSet;
	//contains pause() and resume() at some links, contains an license.html