module AndroidSyntaxParser

import ParseTree;
import IO;

// Layouts
layout Spaces = [\t\ \n]* !>> [\t\ \n];

// Lexicals
lexical Modifier = "static" | "public" | "abstract" | "protected" | "final" | "strict" | "private";
lexical ClassType = "class" | "interface" | "enum";
lexical Integer = [0-9]+ !>> [0-9]; 
lexical Url = [0-9/\-.a-zA-Z_]+ !>> [0-9/\-.a-zA-Z_]; 
lexical PackageName = [0-9a-z.]+ !>> [0-9a-z.];
lexical ClassName = [0-9a-zA-Z._]+ !>> [0-9a-zA-Z._];


// Syntaxes
syntax Package = package: "\<li class=\"api apilevel-" (Integer|"") "\"\>  \<a href=\"" Url "\"\>" PackageName "\</a\>\</li\>";
syntax Packages = packages: Package*;

syntax Class = class: "\<li class=\"api apilevel-" (Integer|"") "\"\>\<a href=\"" Url "\"\>" ClassName "\</a\>\</li\>";
syntax Classes = classes: Class*;

syntax Extend 
	= classNameWithReference: "\<a href=\"" Url "\"\>" ClassName "\</a\>" 
	| className: ClassName 
	| doubleNestedGenericExtends: Extend "&lt;" Extend "extends" Extend "&lt;" Extend "&gt;&gt;";	
syntax ClassSignature = classSignature: Modifier+ ClassType "\<h1 itemprop=\"name\"\>" ClassName "\</h1\>" ("extends" Extend*);
// \<a href=\"/reference/java/lang/Enum.html\"\>Enum\</a\>&lt;E extends \<a href=\"/reference/java/lang/Enum.html\"\>Enum\</a\>&lt;E&gt;&gt;"

// "public    static     final         enum\<h1 itemprop=\"name\"\>GradientDrawable.Orientation\</h1\>            extends \<a href=\"/reference/java/lang/Enum.html\"\>Enum\</a\>&lt;E&nbsp;extends&nbsp;\<a href=\"/reference/java/lang/Enum.html\"\>Enum\</a\>&lt;E&gt;&gt;"

public node parsePackages(str signature) { return implode(#node, parse(#Packages, signature)); }
public node parseClasses(str signature) { return implode(#node, parse(#Classes, signature)); }

//"public         final         class\<h1 itemprop=\"name\"\>SmsManager\</h1\>      extends \<a href=\"/reference/java/lang/Object.html\"\>Object\</a\>"
public node parseClassSignature(str signature) { return implode(#node, parse(#ClassSignature, signature)); }