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
	
	set[value] packages = {};
	
	for (package_info <- getPackages(project)) {
		// Retrieve detailed package information.
		map[str,set[map[str,value]]] information = getPackageInformation(package_info["url"]);
		// Add detailed to package information to the package information we already have.
		map[str, value] package_information = package_info + ("information":information);
		// Add full package information to set.
		packages += {package_information};
		println(package_information);		
	}
	
	text(packages);
}

public void buildProject() {
	loc project = |http://developer.android.com/reference/packages.html|;
	map[str,str] package_info = getOneFrom(getPackages(project));
	map[str,set[map[str,str]]] information = getPackageInformation(package_info["url"]);
	for (class <- information["classes"]) {
		createClassFile(class["package_path"], class["name"], []);
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
												"name":text_content,
												"url":|http://developer.android.com<alink@href>|,
												"package_path":substring(alink@href, 11, findLast(alink@href, "/")),
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
	
	set[map[str,str]] methodSet = {};
	set[map[str,str]] constantSet = {};
	set[map[str,str]] fieldSet = {};
	set[map[str,str]] constructorSet = {};
	
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
			map[str,str] method = ("sig" : methodName, "api" : apiLevel);
			
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

public void extractInformationFromMethodSignature()
{

}