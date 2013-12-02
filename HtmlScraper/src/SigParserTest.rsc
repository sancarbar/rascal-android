module SigParserTest

import ParseTree;
import IO;

// Layouts
layout Spaces = [\t\ \n]* !>> [\t\ \n];

// Lexicals
lexical Modifier = "static" | "public" | "abstract" | "protected" | "final" | "strict" | "private";
lexical Name = [a-zA-Z/\\.\[\]0-9?]+ !>> [a-zA-Z/\\.\[\]0-9?];
lexical Value = [a-zA-Z/\\.\[\]0-9\<\>\"\']+ !>> [a-zA-Z/\\.\[\]0-9\<\>\"\'];

// Class
syntax Class = class: Modifier+ "class" Name ("extends" Name)? ("implements" Name+)?;
// Method
syntax Method = method: Modifier+ Name? Name "(" {Param ","}* ")";
syntax Param = Name Name | Name"\<"Name "extends" Name"\>" Name;
// Field
syntax Field 
	= field: Modifier+ Name Name 
	| field: Modifier+ Name Name "=" Value;
  
// parseMethodSignature("public T execute (HttpHost target, HttpRequest request, ResponseHandler\<? extends T\> responseHandler, HttpContext context)");
// parseMethodSignature("public Camera.Area (Rect rect, int weight)");
// parseMethodSignature("public boolean equals (Object obj)");
public node parseMethodSignature(str signature) {
	node ast = implode(#node, parse(#Method, signature));
	return ast;
}

// parseFieldSignature("public int weight");
public node parseFieldSignature(str signature) {
	node ast = implode(#node, parse(#Field, signature));	
	return ast;
}

// parseClassSignature("public class Camera.Size extends Object implements String");
public node parseClassSignature(str signature) {
	node ast = implode(#node, parse(#Class, signature));	
	return ast;
}