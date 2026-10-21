/* Symbolic stdin crackme: the target exit code (0) needs the input "ngkz". */
#include <stdio.h>
#include <unistd.h>

int main(void) {
  char buf[8];
  ssize_t n = read(0, buf, sizeof(buf) - 1);

  if (n < 4) {
    return 1;
  }
  if (buf[0] == 'n' && buf[1] == 'g' && buf[2] == 'k' && buf[3] == 'z') {
    puts("hit");
    return 0;
  }
  return 2;
}
