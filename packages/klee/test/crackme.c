/* Symbolic int crackme: the target exit code (0) needs x == 1234. */
#include <klee/klee.h>
#include <stdlib.h>

int main(void) {
  int x;
  int *acc;

  klee_make_symbolic(&x, sizeof(x), "x");
  if (x > 100) {
    acc = (int *)malloc(sizeof(int));
    *acc = x;
    free(acc);
    if (x == 1234) {
      return 0;
    }
  }
  return 1;
}
