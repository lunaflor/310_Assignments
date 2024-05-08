#include <xc.h>
#include "mcc_generated_files/system/system.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define _XTAL_FREQ 4000000  // Adjust with your actual clock frequency in Hz

/*
    Generate a random number between min_num and max_num 
*/
int random_number(int min_num, int max_num)
{
    return (rand() % (max_num - min_num + 1)) + min_num;
}

/*
    Main application
*/
int main(void)
{
    SYSTEM_Initialize();
    UART2_Initialize();
    srand(time(NULL));  // Seed the random number generator with the current time

    while(1)
    {
        int randomNumber = random_number(1, 100);
        printf("%d\r\n", randomNumber);
        __delay_ms(1000);  // Delay for one second
    }
}
