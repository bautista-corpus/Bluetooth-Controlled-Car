# Proyecto: Carrito a control
## Carrito a control con Bluetooth y detonación

Este proyecto implementa:

- Una forma de reportar el funcionamiento del PIC.
    - *Se utiliza **U1TXInterrupt*** 

- La interrupción RX modifica el movimiento y direccion del PIC

    - *Se utiliza **UART1** junto **U1RXInterrupt** con salida de control en **PORTB** en el **PIC***

- Una interrupción de un solo bit al detectar un obstaculo ***INT0*** a traves del sensor de proximidad

### Materiales
- dsPIC30F4013
- Modulo Bluetooth HC-06
- Bluetooth terminal (App de Android)
- Sensor fotodiodo
- Amplificador operacional
- Motores DC
- Puente H

### Información adicional

- IDE: MPLAB X 5.25
- Compilador: xc16
- Numero de lineas de codigo: 722
- Data memory: 266 bytes
- Dynamic memory: 1782 bytes
- Program memory: 1557 bytes

