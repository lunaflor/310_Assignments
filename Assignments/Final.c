#include <xc.h>
#include <stdio.h>
#include <string.h>
#include "PWM.h" // must have this

#define _XTAL_FREQ 4000000 // Fosc frequency for _delay() library
#define FCY _XTAL_FREQ / 4

#define RS LATB0       /* PORTB 0 pin is used for Register Select */
#define EN LATB1       /* PORTB 1 pin is used for Enable */
#define ldata LATD     /* PORTD is used for transmitting data to LCD */
#define BUZZER LATAbits.LATA5   /* PORTA 5 pin is used for Buzzer */
#define BUZZER_TRIS TRISAbits.TRISA5
#define LCD_Port TRISD
#define LCD_Control TRISB
#define Vref 5.0 // voltage reference
#define PWM2_INITIALIZE_DUTY_VALUE 100

uint16_t checkdutyCycle;
char preScale;
_Bool pwmStatus;

int digital;    // Holds the digital value
float voltage;  // Holds the analog value (in volts)
char data[10];  // Buffer to store the display string

// Function prototypes
void ADC_Init(void);
void ADC_Read(void);
void LCD_Init(void);
void LCD_Command(char);
void LCD_Char(char x);
void LCD_String(const char *);
void LCD_String_xy(char, char, const char *);
void MSdelay(unsigned int);
void Buzzer_Init(void);
void Buzzer_On(void);
void Buzzer_Off(void);
void INTERRUPT_Initialize(void);
void __interrupt(irq(IRQ_INT2), base(0x4008)) INT2_ISR(void);

void main(void) {
    // Initialize peripherals
    OSCSTATbits.HFOR = 1; // enable HFINTOSC Oscillator (see clock schematic)
    OSCFRQ = 0x02; // 00=1 MHZ, 02=4MHZ internal - see page 106 of data sheet
    
    ANSELA = 0b00000000;    
    TRISA = 0b00000000; // sets PORTA as all outputs 
    PORTA = 0b00000000; // turns off PORTA outputs so that the LED is initially off
    TMR2_Initialize();
    TMR2_StartTimer(); 
    PWM_Output_D8_Enable();
    PWM2_Initialize();
    PWM2_LoadDutyValue(PWM2_INITIALIZE_DUTY_VALUE); // initialize CCPR2H/L

    // Duty Cycle in percentage 
    checkdutyCycle = (uint16_t)((100UL * PWM2_INITIALIZE_DUTY_VALUE) / (4 * (T2PR + 1)));
    // binary value of Register T2CON.PRESCALE
    preScale = ((T2CON >> 4) & (0x0F)); 

    LCD_Init();
    ADC_Init();
    Buzzer_Init();
    INTERRUPT_Initialize();

    // Ensure the buzzer is off and the display shows normal status
    Buzzer_Off();
    LCD_Command(0x01); // Clear display screen
    LCD_String_xy(0, 0, "System Normal");

    while (1) {
        // Perform ADC reading and update the display
        ADC_Read();
        MSdelay(500); // Delay for 500 ms between updates to reduce flickering
    }
}

void LCD_Init(void) {
    MSdelay(20);           // 20ms, 16x2 LCD Power-on delay
    LCD_Port = 0x00;       // Set PORTD as output PORT for LCD data (D0-D7) pins
    LCD_Control = 0x00;    // Set PORTB as output PORT for LCD Control (RS, EN) pins
    LCD_Command(0x38);     // Use 2 lines and initialize 5x7 matrix of LCD
    MSdelay(5);
    LCD_Command(0x0c);     // Display ON, cursor OFF
    MSdelay(5);
    LCD_Command(0x06);     // Increment cursor (shift cursor to right)
    MSdelay(5);
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
        for (j = 0; j < 165; j++); // Provide a delay of 1 ms for 4 MHz Frequency
    }
}

void Buzzer_Init(void) {
    BUZZER_TRIS = 0x00; // Set BUZZER pin as output
}

void Buzzer_On(void) {
    //BUZZER = 1; // Turn on the buzzer
    PWM2_LoadDutyValue(512); // Set PWM duty cycle to 50% to turn on the buzzer
}

void Buzzer_Off(void) {
    BUZZER = 0; // Turn off the buzzer
}

void INTERRUPT_Initialize(void) {
    TRISBbits.TRISB2 = 1; // Set RB2 as input
    ANSELBbits.ANSELB2 = 0; // Set RB2 as digital input

    INTCON0bits.IPEN = 1;  // Enable interrupt priority
    INTCON0bits.GIEH = 1;  // Enable high-priority interrupts
    INTCON0bits.GIEL = 1;  // Enable low-priority interrupts
    INTCON0bits.INT2EDG = 0; // Interrupt on falling edge for INT2
    IPR7bits.INT2IP = 1;   // Set INT2 interrupt as high priority
    PIE7bits.INT2IE = 1;   // Enable INT2 interrupt
    PIR7bits.INT2IF = 0;   // Clear INT2 interrupt flag
}

void __interrupt(irq(IRQ_INT2), base(0x4008)) INT2_ISR(void) {
    if (PIR7bits.INT2IF) {  // Check if INT2 interrupt flag is set
        // Handle the interruption
        Buzzer_On();
        
        sprintf(data, "V: %.2f", voltage);
        LCD_Command(0x80); // Move cursor to first row
        LCD_String("ACCESS DENIED");
        LCD_Command(0xC0); // Move cursor to second row
        LCD_String(data);
        PIR7bits.INT2IF = 0; // Clear INT2 interrupt flag
    }
}

void ADC_Read(void) {
    // Start ADC conversion
    ADCON0bits.GO = 1;
    while (ADCON0bits.GO); // Wait for conversion to finish
    digital = (ADRESH * 256) | (ADRESL); // Combine 8-bit LSB and 2-bit MSB

    // Calculate the voltage value
    voltage = digital * (Vref / 4096.0);

    // Update the LCD only if the voltage value changes significantly
    static float last_voltage = -1;
    if (voltage < 0.5) {
        // Enable the interrupt manually
        PIR7bits.INT2IF = 1; // Set the interrupt flag to trigger the ISR
    } else if ((voltage - last_voltage) > 0.5) {
        sprintf(data, "V: %.2f", voltage);
        LCD_Command(0x80); // Move cursor to first row
        LCD_String("System Status");
        LCD_Command(0xC0); // Move cursor to second row
        LCD_String(data);
        last_voltage = voltage;
    }
}

void ADC_Init(void) {
    // Setup ADC
    ADCON0bits.FM = 1;  // right justify
    ADCON0bits.CS = 1; // ADCRC Clock

    TRISAbits.TRISA0 = 1; // Set RA0 to input
    ANSELAbits.ANSELA0 = 1; // Set RA0 to analog

    ADPCH = 0x00; // Set RA0 as Analog channel in ADC ADPCH
    ADCLK = 0x00; // Set ADC CLOCK Selection register to zero

    ADRESH = 0x00; // Clear ADC Result registers
    ADRESL = 0x00; 

    ADPREL = 0x00; // Set precharge select to 0 in register ADPERL & ADPERH
    ADPREH = 0x00; 

    ADACQL = 0x00;  // Set acquisition low and high byte to zero 
    ADACQH = 0x00;    
    
    ADCON0bits.ON = 1; // Turn ADC On 
}
