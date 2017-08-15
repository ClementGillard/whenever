#include <algorithm>
#include <iostream>
#include <cstdlib>
#include <vector>

#include "runtime.hh"

// number of lines in the original file / functions
extern unsigned nfuncs;
// map id -> function pointer
extern func funcs[];
// map id -> user name
extern int names[];

std::vector<int> todo(nfuncs);
int current;

std::ostream& log()
{
  return std::clog << "Line " << names[current] << ": ";
}

int get_id(int lineno)
{
  for (int i = 0; i < nfuncs; ++i)
  {
    if (names[i] == lineno)
      return i;
  }
  log() << "could not get the name of line " << lineno << '\n';
  return -1;
}

void add(int lineno, int times)
{
  todo.insert(todo.end(), times, get_id(lineno));
}

void remove(int lineno, int times)
{
  int id = get_id(lineno);
  auto from = todo.begin();
  for (int i = 0; i < times; ++i)
  {
    auto it = std::find(from, todo.end(), id);
    if (it == todo.end())
    {
      log() << "asked to remove line " << lineno << ' ' << times
            << " times, had " << i << ".\n";
      return;
    }
    bool dirty = it == from;
    if (!dirty)
      from = it - 1;
    todo.erase(it);
    if (dirty)
      from = todo.begin();
  }
}

int N(int lineno)
{
  return std::count(todo.begin(), todo.end(), get_id(lineno));
}

int read(){return 0;}

int main()
{
  for (int i = 0; i < nfuncs; ++i)
    todo[i] = i;

  while (!todo.empty())
  {
    current = rand() % todo.size();
    funcs[todo[current]]();
  }
}
