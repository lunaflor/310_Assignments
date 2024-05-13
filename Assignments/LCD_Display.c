// PIC18F46K42 Configuration Bit Settings
// (Omitted for brevity; use your existing configuration bits)

#include <xc.h>
#include <stdio.h>
#include <string.h>

#define _XTAL_FREQ 4000000 // Fosc frequency for _delay() library
#define FCY _XTAL_FREQ / 4

#define RS LATB0       /* PORTB 0 pin is used for Register Select */
#define EN LATB1       /* PORTB 1 pin is used for Enable */
#define ldata LATD     /* PORTD is used for transmitting data to LCD */

#define LCD_Port TRISD
#define LCD_Control TRISB
#define Vref 5.0 // voltage reference

int digital;    // Holds the digital value
float lux; 
float voltage;  // Holds the analog value (in volts)
char data[10];  // Buffer to store the display string

// Function prototypes
void ADC_Init(void);
void ADC();
void LCD_Init();
void LCD_Command(char);
void LCD_Char(char x);
void LCD_String(const char *);
void LCD_String_xy(char, char, const char *);
void MSdelay(unsigned int);

void main(void) {
    // Initialize LCD and ADC only once
    LCD_Init();                    
    ADC_Init();

    while (1) {
        ADC();  // Only perform ADC reading and related display updates in the loop
        MSdelay(500); // Delay for 500 ms between updates to reduce flickering
    }
}

void LCD_Init() {
    MSdelay(15);           // 15ms, 16x2 LCD Power-on delay
    LCD_Port = 0x00;       // Set PORTD as output PORT for LCD data (D0-D7) pins
    LCD_Control = 0x00;    // Set PORTB as output PORT for LCD Control (RS, EN) pins
    LCD_Command(0x38);     // Use 2 lines and initialize 5x7 matrix of LCD
    LCD_Command(0x01);     // Clear display screen
    LCD_Command(0x0c);     // Display ON, cursor OFF
    LCD_Command(0x06);     // Increment cursor (shift cursor to right)
}

void LCD_Command(char cmd) {
    ldata = cmd;           // Send data to PORT as a command for LCD
    RS = 0;                // Command Register is selected
    EN = 1;                // High-to-low pulse on Enable pin to latch data
    __delay_us(1);         // Short delay for data latch
    EN = 0;
    MSdelay(3);            // Command execution delay
}

void LCD_Char(char dat) {
    ldata = dat;           // Send data to LCD
    RS = 1;                // Data Register is selected
    EN = 1;                // High-to-low pulse on Enable pin to latch data
    __delay_us(1);         // Short delay for data latch
    EN = 0;
    MSdelay(1);            // Data execution delay
}

void LCD_String(const char *msg) {
    while (*msg != 0) {
        LCD_Char(*msg);    // Send each character of the string to the LCD
        msg++;
    }
}

void LCD_String_xy(char row, char pos, const char *msg) {
    char location = 0;
    if (row == 0) {
        location = 0x80 | (pos & 0x0F); // Print on the 1st row at the desired position
    } else {
        location = 0xC0 | (pos & 0x0F); // Print on the 2nd row at the desired position
    }
    LCD_Command(location);
    LCD_String(msg);
}

void MSdelay(unsigned int val) {
    unsigned int i, j;
    for (i = 0; i < val; i++) {
        for (j = 0; j < 165; j++); // Provide a delay of 1 ms for 8 MHz Frequency
    }
}

void ADC() {
    // Start ADC conversion
    ADCON0bits.GO = 1;
    while (ADCON0bits.GO); // Wait for conversion to finish
    digital = (ADRESH * 256) | (ADRESL); // Combine 8-bit LSB and 2-bit MSB

    // Calculate the voltage value
    voltage = digital * (Vref / 4096.0);
    lux = voltage*45;
    // Print voltage value on LCD
    sprintf(data, "%.2f", lux);
    LCD_String_xy(0, 2, "Input Lux:");
    LCD_String_xy(1, 1, data);
    
}

void ADC_Init(void) {
    // Setup ADC
    ADCON0bits.FM = 1;  //right justify
    ADCON0bits.CS = 1; //ADCRC Clock
    
    TRISAbits.TRISA0 = 1; //Set RA0 to input
    ANSELAbits.ANSELA0 = 1; //Set RA0 to analog
    // Added 
    ADPCH = 0x00; //Set RA0 as Analog channel in ADC ADPCH
    ADCLK = 0x00; //set ADC CLOCK Selection register to zero
    
    ADRESH = 0x00; // Clear ADC Result registers
    ADRESL = 0x00; 
    
    ADPREL = 0x00; // set precharge select to 0 in register ADPERL & ADPERH
    ADPREH = 0x00; 
    
    ADACQL = 0x00;  // set acquisition low and high byte to zero 
    ADACQH = 0x00;    
    
    ADCON0bits.ON = 1; //Turn ADC On 
}
