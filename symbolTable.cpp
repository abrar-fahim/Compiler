#include <iostream>
#include <string>
#include <fstream>

using namespace std;



#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>

#include "SymbolInfo.cpp"


using namespace std;


class ScopeTable {

    static int currentId;

    int id;

    SymbolInfo* symbols;        //the array of symbols in the table

    ScopeTable* parentTable;
    int size;

public:

    int getId() const;

    void setParentTable(ScopeTable *parentTable) {
        ScopeTable::parentTable = parentTable;
    }

    ScopeTable *getParentTable() const {
        return parentTable;
    }

    ScopeTable(int size) {
        this -> size = size;

        id = currentId;
        currentId++;
        symbols = new SymbolInfo[size];

        for(int i = 0; i < size; i++) {
            symbols[i].setType("DUMMY");
            symbols[i].setNext(nullptr);
        }

        parentTable = nullptr;
    }

    bool insert(string name, string type) {

        int tablePos, chainPos;

        SymbolInfo symbol;

        symbol.setName(name);
        symbol.setType(type);

        tablePos = symbol.hash(size);

        if (symbols[tablePos].getType() == "DUMMY") {
            symbols[tablePos] = symbol;
            chainPos = 0;
            symbols[tablePos].setNext(nullptr);

            cout << "Inserted in ScopeTable# " << id << " at position "
                 << tablePos << ", " << chainPos << endl;
            return true;
        } else {

            int chainPos = 0;

            SymbolInfo *symbol = new SymbolInfo();

            symbol->setName(name);
            symbol->setType(type);

            symbol->setNext(nullptr);

            SymbolInfo *current = &symbols[tablePos];

            if (current -> getName() == name) {
                cout << "symbol already in table" << endl;
                return false;
            }
            while (current->getNext()) {
                current = current->getNext();
                chainPos++;

                if (current -> getName() == name) {
                    cout << "symbol already in table" << endl;
                    return false;
                }
            }

            current->setNext(symbol);
            chainPos++;

            cout << "Inserted in ScopeTable# " << id << " at position "
                 << tablePos << ", " << chainPos << endl;

            return true;
        }
    }
    
    bool insert(SymbolInfo* input) {
        
        int tablePos, chainPos;
        
        //SymbolInfo symbol(input -> getName(), input -> getType(), input -> getDataType());
        
        SymbolInfo symbol = *input; //this works because we never insert a symbol wiht a non-null next pointer in the table
        
//        symbol.setName(name);
//        symbol.setType(type);
        
        tablePos = symbol.hash(size);
        
        if (symbols[tablePos].getType() == "DUMMY") {
            symbols[tablePos] = symbol;
            chainPos = 0;
            symbols[tablePos].setNext(nullptr);
            
            cout  << symbols[tablePos].getName()<< " Inserted in ScopeTable# " << id << " at position "
            << tablePos << ", " << chainPos << endl;
            return true;
        } else {
            
            int chainPos = 0;
            
            SymbolInfo *symbol = new SymbolInfo(input);
            
//            symbol->setName(name);
//            symbol->setType(type);
//
//            symbol->setNext(nullptr);
            
            SymbolInfo *current = &symbols[tablePos];
            
            if (current -> getName() == input -> getName()) {
                cout << "symbol already in table" << endl;
                return false;
            }
            while (current->getNext()) {
                current = current->getNext();
                chainPos++;
                
                if (current -> getName() == input -> getName()) {
                    cout << "symbol already in table" << endl;
                    return false;
                }
            }
            
            current->setNext(symbol);
            chainPos++;
            
            cout << "Inserted in ScopeTable# " << id << " at position "
            << tablePos << ", " << chainPos << endl;
            
            return true;
        }
    }

    SymbolInfo* lookUp(string name) {

        int tablePos, chainPos;

        SymbolInfo symbol;
        symbol.setName(name);
        symbol.setNext(nullptr);

        tablePos = symbol.hash(size);

        if (symbols[tablePos].getType() == "DUMMY") {

            cout << "not found" << endl;
            return nullptr;
        }

        SymbolInfo *current = &symbols[tablePos];

        chainPos = 0;

        while (current) {

            if (current -> getName() == name) {

                cout << "Found in ScopeTable# " << id << " at position "
                     << tablePos << ", " << chainPos << endl;

                return current;
            }

            current = current->getNext();
            chainPos++;

        }
        cout << "not found" << endl;
        return nullptr;
    }

    bool deleteSymbol(string name) {

        int tablePos, chainPos;

        SymbolInfo symbol;
        symbol.setName(name);

//        SymbolInfo *symbol = lookUp(name);
//
//
//        if (symbol == nullptr) {
//            cout << "not found for deletion" << endl;
//            return false;
//        }
        tablePos = symbol.hash(size);

        SymbolInfo *current = &symbols[tablePos];
        SymbolInfo *prev = nullptr;
        SymbolInfo *temp = nullptr;

        chainPos = 0;

        while (current) {

            if (current -> getName() == name) {
                if(prev) {
                    prev->setNext(current->getNext());
                    temp = current -> getNext();
                    delete current;
                    current = nullptr;
                }
                else {
                    if(current -> getNext()) {
                        symbols[tablePos] = *(current -> getNext());
                        temp -> getNext();
                    }
                    else {
                        current -> setName("");
                        current -> setType("DUMMY");
                    }

                }

                cout << "deleted entry at "  << tablePos << ", " << chainPos <<  " from current scope table" << endl;

                return true;
            }

            prev = current;

            current = current->getNext();
            chainPos++;
        }

//        while(temp) {
//            temp -> setChainPos(temp -> getChainPos() - 1);
//            temp = temp -> getNext();
//        }


        cout << "not found for deletion" << endl;
        return false;
    }

    void print(FILE* out) {

        for(int i = 0; i < size; i++) {

            SymbolInfo *current = &symbols[i];
            
            if(current -> getType() != "DUMMY") {
                fprintf(out, "%d: ", i);
            }
            else {
                continue;
            }

            //out << i << ": ";

            while(current) {

                if(current -> getType() != "DUMMY") {
                    fprintf(out ,"<%s, %s> -> ", current -> getName().c_str(), current -> getType().c_str());
                    //out << "< " << current -> getName() << ", " << current -> getType() << "> -> ";
                }
                current = current -> getNext();
            }

	    fprintf(out, "\n");
            //out << endl;
        }

    }

    virtual ~ScopeTable() {

        delete[] symbols;
        symbols = nullptr;
        delete parentTable;
    }

};

int ScopeTable::currentId = 0;

int ScopeTable::getId() const {
    return id;
}

class SymbolTable {

    int size;

    //ScopeTable* firstTable;

    ScopeTable* currentScopeTable;

public:

    SymbolTable(int size) {
        //firstTable = new ScopeTable(size);
        this -> size = size;
        currentScopeTable = new ScopeTable(size);
    }

    void enterScope() {
        ScopeTable* table = new ScopeTable(size);
        table -> setParentTable(currentScopeTable);
        currentScopeTable = table;

        cout << "New scopetable with id " << currentScopeTable -> getId() << " created" << endl;
    }

    void exitScope() {

        cout << "scopetable with id " << currentScopeTable -> getId() << " removed" << endl;

        ScopeTable* temp = currentScopeTable;

        currentScopeTable = currentScopeTable -> getParentTable();

        temp -> setParentTable(nullptr);

        delete temp;
    }

    bool insert(string name, string type) {

        currentScopeTable -> insert(name, type);
    }
    
    bool insert(SymbolInfo* symbol) {
        currentScopeTable -> insert(symbol);
    }

    bool remove(string name) {

        currentScopeTable -> deleteSymbol(name);
    }

    SymbolInfo* lookUp(string name) {

        ScopeTable* current = currentScopeTable;
        while(current) {
            SymbolInfo* temp = current -> lookUp(name);
            if(temp == nullptr) {
                current = current -> getParentTable();
            }
            else {
                return temp;
            }
        }

        return nullptr;

    }
    
    SymbolInfo* lookUpInCurrentScope(string name) {
        return currentScopeTable -> lookUp(name);
        
        
    }
    

    void printCurrentScopeTable(FILE* out) {

	fprintf(out, "ScopeTable # %d\n", currentScopeTable -> getId());

        //out << "ScopeTable # " << currentScopeTable -> getId() << endl;
        currentScopeTable -> print(out);
    }

    void printAllScopeTables(FILE* out) {

        ScopeTable* current = currentScopeTable;

        while(current) {
	    fprintf(out, "ScopeTable # %d\n", current -> getId());
            //out << "ScopeTable # " << current -> getId() << endl;
            current -> print(out);

            current = current -> getParentTable();
	    fprintf(out, "\n");
            //out << endl;
        }
    }

    virtual ~SymbolTable() {

        if(currentScopeTable) {
            delete currentScopeTable;
            currentScopeTable = nullptr;
        }

    }

};


int main11() {
    ifstream infile("input.txt");

    int size;

    infile >> size;

    SymbolTable table(size);

    char action;

    string name;
    string type;


    while(true) {
        infile >> action;

        switch(action) {
            case 'I':

                infile >> name;
                infile >> type;

                cout << action << " " << name << " " << type << endl << endl;

                table.insert(name, type);

                cout << endl;
                break;

            case 'L':

                infile >> name;

                cout << action << " " << name << endl << endl;

                table.lookUp(name);

                cout << endl;

                break;

            case 'D' :

                infile >> name;

                cout << action << " " << name << endl << endl;

                table.remove(name);

                cout << endl;
                break;

            case 'P':

                char type;

                infile >> type;

                cout << action << " " << type << endl << endl;

                /*if(type == 'A') {
                    table.printAllScopeTables(std::out);
                }
                else if(type == 'C') {
                    table.printCurrentScopeTable(std::out);
                }

                else {
                    cout << "invalid print command" << endl;
                }*/

                cout << endl;
                break;

            case 'S':

                cout << action << endl;

                table.enterScope();

                cout << endl;

                break;

            case 'E':

                cout << action << endl << endl;

                table.exitScope();

                cout << endl;

                break;

            default:

                cout << "not valid action" << endl;

                cout << endl;

                return 0;
        }
    }


    return 0;
}
