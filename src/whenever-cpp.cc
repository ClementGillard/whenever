#include <fstream>
#include <string>
#include <vector>

#include "parse.hh"

extern FILE* yyin;

std::string parse_whenever();

std::vector<int> funcs;

std::ofstream funcfile("funcs.cc");

int main(int argc, char* argv[])
{
  if (argc < 2)
    return 1;

  yyin = fopen(argv[1], "r");

  funcfile << "#include <iostream>\n"
              "\n"
              "#include \"runtime.hh\"\n"
           << parse_whenever();

  std::cout << argv[1] << " translated to C++ functions in funcs.cc.\n"
               "To get an executable, compile against whenever-cpp's runtime:\n"
               "g++ -Iruntime funcs.cc runtime/runtime.cc -o executable\n";
}
