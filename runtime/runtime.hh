#ifndef RUNTIME_HH
# define RUNTIME_HH

typedef void (*func)();

void add(int lineno, int times = 1);
void remove(int lineno, int times = 1);
int N(int lineno);
int read();

#endif /* !RUNTIME_HH */
