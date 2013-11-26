module SignatureParser

//grammar for class signatures
layout Spaces = [\t\ \n]*;
lexical Iden = [a-zA-Z/.\[\]]+;
lexical Link = [a-zA-Z/.]+;
// public static class ClassName extends extender implements implementer link implementer2 link2
syntax ClassDef
  = class: Modifiers+ "class" Iden ExtendsClause ImplementsClause
  |interface: Modifiers+ "interface" Iden ExtendsClause ImplementsClause //Modifiers "interface" //Id ExtendsClause ImplementsClause
  |enum: Modifiers+ "enum" Iden ExtendsClause ImplementsClause
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
  | nonEmpty: "extends" (Iden Link)+
  ;
  
syntax ImplementsClause 
  = empty:
  | nonEmpty: "implements" (Iden Link)+
  ;

  //grammar for methods
  // modifiers return name (parameters)
  syntax MethodDef
  = Modifiers+ Iden Iden "(" Params ")";
  
  //Param p or Param p, Param p2, Param p3 etc (comma!!)
  syntax Params
  = empty:
  | nonempty: (Iden Iden ","?)+
  ;