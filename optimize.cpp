#include <stdio.h>
#include <vector>
#include <string>

using namespace std;

vector<string> split(string rawCode, string delim) {
    
    vector<string> out;
    int i = 0;
    size_t lastFound = 0;
    size_t found = rawCode.find_first_of(delim, 0);
    
    while(found != string::npos) {
        //found contains position of first newline
        string temp = rawCode.substr(lastFound, found - lastFound);
        //rawCode.copy(temp, found, lastFound);
        if(!(temp == "")) {
            out.push_back(temp);
        }
        
        lastFound = found + 1;
        
        found = rawCode.find_first_of(delim, lastFound);
        
    }
    
    if(found > lastFound) {
        //string temp = rawCode.substr(lastFound, found - lastFound);
        string temp = rawCode.substr(lastFound);
        if(temp != "") {
            out.push_back(temp);
        }
    }
    
    return out;
}

bool optimize(string s1, string s2) {
    
    //if "mov ax, t; mov t, ax" found, then return first line
    
    vector<string> v1 = split(s1, " ,");
    vector<string> v2 = split(s2, " ,");
    
    int i = 0;
    int j = 0;
//
//    while(v1[i] == " ") i++;   //skip initial spaces
//    while(v2[j] == " ") j++;   //skip initial spaces
    
//    cout << v1[i] << endl;
//    cout << v2[j] << endl;
    if(v1[i] == "mov" && v2[j] == "mov") {
        
        i++;
        j++;
        if(v1[i] == v2[j + 1] && v1[i + 1] == v2[j]) {
            return true;
        }
        return false;
    }
    return false;
}


string optimizeCode(string rawCode) {
    vector<string> code = split(rawCode, "\n");
    string out;
    
    
    for(int i = 0; i < code.size() - 1; i++) {
        string s1 = code[i];
        string s2 = code[i + 1];
        
        
        if(optimize(s1, s2)) {
            i++;
        }
        out += s1 + "\n";
        
        if(i + 1 == code.size() - 1) {
            out += s2 + "\n";
        }
        
    }
    
    return out;
    
}


