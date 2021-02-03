#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>


using namespace std;

class SymbolInfo {
    string name;
    string type;
    SymbolInfo* next;
    string dataType;
    int size;
    bool isArray;
    bool isFunction;
    vector<string> parameters;
    bool isDeclaration; //stores if this symbolInfo object is a function declaration, rather than a definition
    
    
    public:
    string code;//added for code generation
    
    SymbolInfo() {
        next = nullptr;
        dataType = "";
        dataType = "none";
    }

    
    SymbolInfo(SymbolInfo* symbol) {
        //this func is used in parser in $$ = new SymbolInfo($1) scenarios
        SymbolInfo::name = symbol -> getName();
        SymbolInfo::type = symbol -> getType();
        SymbolInfo::dataType = symbol -> getDataType();
        next = nullptr;
       
        SymbolInfo::parameters = symbol -> getParameters();
        
        SymbolInfo::isArray = symbol -> getIsArray();
        SymbolInfo::isFunction = symbol -> getIsFunction();
        SymbolInfo::isDeclaration = symbol -> getIsDeclaration();
        SymbolInfo::size = symbol -> size;
        SymbolInfo::code = symbol -> code;
    }
    
    SymbolInfo(string name,string type) {
        SymbolInfo::name = name;
        SymbolInfo::type = type;
        next = nullptr;
        dataType = "none";
        size = 1;
    }
    
    SymbolInfo(string name,string type, string dataType) {
        SymbolInfo::name = name;
        SymbolInfo::type = type;
        next = nullptr;
        SymbolInfo::dataType = dataType;
        size = 1;   //1 means element, >1 means array
    }
    
    void setIsDeclaration(bool in) {
        isDeclaration = in;
    }
    
    
    bool getIsDeclaration() {
        return isDeclaration;
    }
    void addParameter(string dataType) {
        parameters.push_back(dataType);
    }
    
    void setParameters(vector<string> parameters) {
        SymbolInfo::parameters = parameters;
    }
    
    vector<string> getParameters() {
        return parameters;
    }
    
    
    
    int hash(int tableSize) {
        int hashVal = 0;
        
        for(int i = 0; i < name.length();  i++)
        hashVal = 37 * hashVal+name[i];
        
        hashVal %= tableSize;
        
        if(hashVal < 0)
        hashVal += tableSize;
        
        return hashVal;
    }
    
    void setIsFunction(bool value) {
        isFunction = value;
    }
    
    void setIsArray(bool value) {
        isArray = value;
    }
    
    bool getIsFunction() {
        return isFunction;
    }
    
    bool getIsArray() {
        return isArray;
    }
    
    
    
    void setDataType(string dataType) {
        SymbolInfo::dataType = dataType;
    }
    
    const string &getDataType() {
        return dataType;
    }
    
    void setSize(int size) {
        SymbolInfo::size = size;
    }
    
    const int &getSize() {
        return size;
    }
    
    
    const string &getName() const {
        
        return name;
    }
    
    const string &getType() const {
        return type;
    }
    
    void setName(const string &name) {
        SymbolInfo::name = name;
    }
    
    void setType(const string &type) {
        SymbolInfo::type = type;
    }
    
    SymbolInfo *getNext() const {
        return next;
    }
    
    void setNext(SymbolInfo *next) {
        SymbolInfo::next = next;
    }
    
    virtual ~SymbolInfo() {
        
        if(next) {
            delete next;
            next = nullptr;
        }
    }
    
    
    
};
