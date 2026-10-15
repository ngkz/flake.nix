// Functional test binary for the angr check: reads a password from stdin and
// compares it against a magic string. angr must recover that string symbolically.
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define PASSWORD "angr-nix!"

int main(void) {
    char buf[32] = { 0 };
    if (write(1, "password: ", 10) < 0)
        return 1;
    if (read(0, buf, sizeof buf - 1) < 0)
        return 1;
    if (memcmp(buf, PASSWORD, sizeof PASSWORD) == 0)
        puts("Congrats, the angr check passed!");
    else
        puts("Nope.");
    return 0;
}
