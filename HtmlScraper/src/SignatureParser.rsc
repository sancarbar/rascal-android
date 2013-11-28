module SignatureParser
import ParseTree;
import IO;

//grammar for class signatures
layout Spaces = [\t\ \n]* !>> [\t\ \n]; 
lexical Iden = [a-zA-Z/\\.\[\]()0-9]+ !>> [a-zA-Z/\\.\[\]()0-9];

// public static class ClassName extends extender implements implementer link implementer2 link2

syntax ClassDef
  = class: Modifiers+ "class" Iden ExtendsClause ImplementsClause
  | interface: Modifiers+ "interface" Iden ExtendsClause ImplementsClause
  | enum: Modifiers+ "enum" Iden ExtendsClause ImplementsClause
  ;
  
 //possible modifiers
lexical Modifiers
  = "static" 
  | "public" 
  | "abstract" 
  | "protected" 
  | "final"
  | "strict" 
  | "private" 
  ;

//will be of the form Object reference/linktoObject.html
syntax ExtendsClause 
  = empty:
  | extends: "extends" IdenLink+
  ;
  
syntax ImplementsClause 
  = empty:
  | implements: "implements" IdenLink+
  ;

syntax IdenLink
 = link: Iden Iden;
  //grammar for methods
  // modifiers return name (parameters)
 
 syntax MethodDef
  = method: Modifiers+ ReturnType Iden "(" Params+ ")";
  
 syntax ReturnType
  = \return: Iden;
  
  //Param p or Param p, Param p2, Param p3 etc (comma!!)
 syntax Params
  = empty:
  | nonempty: Iden Iden","?
  ;
  
  /* testing class, under construction much!
// still need to find out how the implode works
// so a ADT can be build :) */
public node parseClassToADT(str classsig){
	
			 node ast = implode(#node,parse(#ClassDef,classsig));
	 println(ast);
	 return ast;
}
  