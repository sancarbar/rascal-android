module SignatureParser
import ParseTree;
import IO;

//grammar for class signatures
layout Spaces = [\t\ \n]*;
lexical Iden = [a-zA-Z/.\[\]()]+;
lexical Link = [a-zA-Z/.\[\]()]+;

// public static class ClassName extends extender implements implementer link implementer2 link2

syntax ClassDef
  = Modifiers+ "class" Iden ExtendsClause ImplementsClause
  | Modifiers+ "interface" Iden ExtendsClause ImplementsClause //Modifiers "interface" //Id ExtendsClause ImplementsClause
  | Modifiers+ "enum" Iden ExtendsClause ImplementsClause
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
  | nonEmpty: "extends" IdenLink+
  ;
  
syntax ImplementsClause 
  = empty:
  | nonEmpty: "implements" IdenLink+
  ;

syntax IdenLink
= empty:
| nonempty: Iden Link;
  //grammar for methods
  // modifiers return name (parameters)
 
 syntax MethodDef
  = Modifiers+ Iden Iden "(" Params+ ")";
  
  //Param p or Param p, Param p2, Param p3 etc (comma!!)
 syntax Params
  = empty:
  | nonempty: Iden Iden ","?
  ;
  
  /* testing class, under construction much!
// still need to find out how the implode works
// so a ADT can be build :) */
public node parseClassToADT(str classsig){
	
	node ast = implode(#node,parse(#ClassDef,classsig));
	println(ast);
	return ast;
}
  