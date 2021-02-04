# Simple C Compiler

This is a simple C Compiler that parses an input file written in C and outputs the corresponding assembly 8086 code. 


## Setup
You'll need Flex and Bison installed on you machine in order to run script.sh~ and successfully compile the routines that are used to parse the c file. 
Running script.sh~ file parses the c code in "input.c" and outputs 8086 assembly language equivalent of the c code in "output.txt".
Any compile time errors are reported in "log.txt". 
Presence of compile time errors suspends parsing, so "output.txt" is invalid in this case. 


## Details
This project uses Flex and Bison to create a text scanner and parser that can process text files written in programming language C to output assembly code. 
Flex (Fast Lexical Analyzer Generator) is a tool that generates programs that can recognize lexical patterns in text. The scanner generated converts the stream of text in the input text file into a series of tokens. 
The tokens generated can then be fed into a parser, which is generated here using Bison. 
The parser file performs syntax and semantic analysis using grammar rules (present in "grammar.txt" file). 
Code generation logic for this project is inbuilt into the parser, which executes c++ code corresponding to different grammar rules of the C language. 

This compiler also does some basic code optimization (peephole optimization) to remove redundant lines of `mov` instructions in the generated assembly code file. Optimization logic is present in "optimize.cpp" file




## C Features Supported

- Basics
  - For, While loops
  - If statements
  - `int`, `float` and `void` data types only

- Functions
  - Function calls `int a = func(a,b);`
  - Function declarations `int func(int a,int b);`
  - Function Definitions `int func(int a,int b) {...}`
  - Print function `println(a)` : this only works with single ids
  
- Variables and arrays
  - Declaration `float a, b, c[100 * a];`
  - (Declaration and assignment in one line isnt supported: `int a = 5;`)
  
- Expressions (Logical, Relational and Mathematical)
  - Logical: `!a || b`
  - Relational: `a < b`
  - Mathematical: `a + b`
  
- Operators
  - `a++`
  - `a--`
  - `+, -, /, *, %`
