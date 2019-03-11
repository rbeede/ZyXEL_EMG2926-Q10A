/* ZyXEL prestige 660HW series password calculator by brainstorm 
  * Thanks to http://www.adslayuda.com/Zyxel650-9.html authors
  *
  * Example usage:
  *
  * Router:
  * ======
  *
  * ATSE
  * 0028D6DF1C03
  * OK
  *
  * Computer:
  * ========
  *
  * ./zyxel 0028D6DF1C03
  * ATEN 1,221E3111
  *
  * Router:
  * ======
  * ATEN 1,221E3111
  * OK
  *
  * "Dangerous" commands enabled :-)
  *
  * */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define magic1  0x10F0A563L
#define magic2  7
#define atse_length 12  /* ATSE command, ZyNOS seed password length */

#define WORD_LENGTH (8*sizeof(value))
int ror(unsigned int value, int places)
{
  return (value>>places)|(value<<(WORD_LENGTH-places));
}


int main (int argc, char* argv[]) {

        char *seed, a[7], c[3];
        unsigned int b,d,e,password;

        if ( argc != 2 ) {
                printf("Only one argument is permitted: 00BDC8667E5B\n");
                exit(-1);

        } else if ( strlen(argv[1]) != atse_length ) {
                printf( "Incorrect parameter length, should be %d characters long\n", atse_length );
                exit (-2);
        }

        seed = argv[1];

        strncpy (a, seed , 6);  //a="ersten" 3Bytes vom seed
        e = strtol(a,NULL,16);  //e=a

        strncpy (c, seed + strlen(seed)-2, 2); //c= last 2 bytes of seed?
        d = strtol(c,NULL,16) & magic2; //d="last byte" AND 7
        b = e + magic1; //

        b = ror(b,d);
        password = b ^ e;
        printf("\nATEN 1,%X\n", password);

        return 0;
}