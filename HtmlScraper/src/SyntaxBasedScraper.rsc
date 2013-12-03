module SyntaxBasedScraper

import lang::html::IO;
import util::ValueUI;
import IO;
import List;
import Set;
import String;
import AndroidSyntaxParser;
import ParseTree;




public node getPackages() {
	// Read html file as string.
	str html = readFile(|http://developer.android.com/reference/packages.html|);
	// Remove Unnecessary html parts.
	html = replaceAll(html, "\n\n", "\n");
	html = replaceAll(html, "\n", "");
	html = replaceAll(html, "\<br/\>", "");
	html = replaceAll(html, "\</li\>    \<li", "\</li\>\<li");
	
	// Strip down the html so we get only the list items with information about the packages. 
	str head = "\<div id=\"packages-nav\" class=\"scroll-pane\"\>              \<ul\>                    ";
	str end = "              \</ul\>            \</div\> ";
	int startPosition = findFirst(html, head) + size(head);
	int endPosition = findFirst(html, end); 
	
	return parsePackages(html[startPosition..endPosition]);	
}

// |http://developer.android.com/reference/android/media/package-summary.html|
// |http://developer.android.com/reference/android/graphics/drawable/package-summary.html|
public node getInterfacesForPackage(loc packagesSummaryUrl) {
	// Read html file as string.
	str html = readFile(packagesSummaryUrl);
	// Remove Unnecessary html parts.
	html = replaceAll(html, "\n\n", "\n");
	html = replaceAll(html, "\n", "");
	html = replaceAll(html, "\<br/\>", "");
	// Strip start.
	str head = "\<h2\>Interfaces\</h2\>      \<ul\>        ";
	int startPosition = findFirst(html, head) + size(head);
	html = html[startPosition..];	
	// Strip end.
	str end = "\</ul\>";
	int endPosition = findFirst(html, end);
	html = html[..endPosition];
	
	html = replaceAll(html, "\</li\>        \<li", "\</li\>\<li");
	return parseClasses(trim(html));
}

public node getClassesForPackage(loc packagesSummaryUrl) {
	// Read html file as string.
	str html = readFile(packagesSummaryUrl);
	// Remove Unnecessary html parts.
	html = replaceAll(html, "\n\n", "\n");
	html = replaceAll(html, "\n", "");
	html = replaceAll(html, "\<br/\>", "");
	// Strip start.
	str head = "\<h2\>Classes\</h2\>      \<ul\>        ";
	int startPosition = findFirst(html, head) + size(head);
	html = html[startPosition..];	
	// Strip end.
	str end = "\</ul\>";
	int endPosition = findFirst(html, end);
	html = html[..endPosition];
	
	html = replaceAll(html, "\</li\>        \<li", "\</li\>\<li");
	return parseClasses(trim(html));
}

public node getExceptionsForPackage(loc packagesSummaryUrl) {
	// Read html file as string.
	str html = readFile(packagesSummaryUrl);
	// Remove Unnecessary html parts.
	html = replaceAll(html, "\n\n", "\n");
	html = replaceAll(html, "\n", "");
	html = replaceAll(html, "\<br/\>", "");
	// Strip start.
	str head = "\<h2\>Exceptions\</h2\>      \<ul\>        ";
	int startPosition = findFirst(html, head) + size(head);
	html = html[startPosition..];	
	// Strip end.
	str end = "\</ul\>";
	int endPosition = findFirst(html, end);
	html = html[..endPosition];
	
	html = replaceAll(html, "\</li\>        \<li", "\</li\>\<li");
	return parseClasses(trim(html));
}

public node getErrorsForPackage(loc packagesSummaryUrl) {
	// Read html file as string.
	str html = readFile(packagesSummaryUrl);
	// Remove Unnecessary html parts.
	html = replaceAll(html, "\n\n", "\n");
	html = replaceAll(html, "\n", "");
	html = replaceAll(html, "\<br/\>", "");
	// Strip start.
	str head = "\<h2\>Errors\</h2\>      \<ul\>        ";
	int startPosition = findFirst(html, head) + size(head);
	html = html[startPosition..];	
	// Strip end.
	str end = "\</ul\>";
	int endPosition = findFirst(html, end);
	html = html[..endPosition];
	
	html = replaceAll(html, "\</li\>        \<li", "\</li\>\<li");
	return parseClasses(trim(html));
}

public node getEnumsForPackage(loc packagesSummaryUrl) {
	// Read html file as string.
	str html = readFile(packagesSummaryUrl);
	// Remove Unnecessary html parts.
	html = replaceAll(html, "\n\n", "\n");
	html = replaceAll(html, "\n", "");
	html = replaceAll(html, "\<br/\>", "");
	// Strip start.
	str head = "\<h2\>Enums\</h2\>      \<ul\>        ";
	int startPosition = findFirst(html, head) + size(head);
	html = html[startPosition..];	
	// Strip end.
	str end = "\</ul\>";
	int endPosition = findFirst(html, end);
	html = html[..endPosition];
	
	html = replaceAll(html, "\</li\>        \<li", "\</li\>\<li");
	return parseClasses(trim(html));
}

// getClassSignature(|http://developer.android.com/reference/android/telephony/gsm/SmsManager.html|);
public node getClassSignature(loc classSummaryUrl) {
	// Read html file as string.
	str html = readFile(classSummaryUrl);
	// Remove Unnecessary html parts.
	html = replaceAll(html, "\n\n", "\n");
	html = replaceAll(html, "\n", "");
	html = replaceAll(html, "\<br/\>", "");
	html = replaceAll(html, "&nbsp;", " ");
	
		
	
	// Strip start.
	str head = "\<!-- ======== START OF CLASS DATA ======== --\>\<div id=\"jd-header\"\>";
	int startPosition = findFirst(html, head) + size(head);
	html = html[startPosition..];
	// Strip end.
	str end = "\</div\>";
	int endPosition = findFirst(html, end);
	html = html[..endPosition];
	
	text(trim(html));
	
	return parseClassSignature(trim(html));
}



