### This is the first code used to read data from the microphone. It's was used a
### Raspberry Pi Pico as the microcontroller and so it's written in micropython.

## Just a reminder that the DE/RE pins in the RS-485 Converter must be connected in the same port, GP21.


from umodbus.serial import Serial as ModbusRTUMaster
from machine import Pin
from utime import sleep

rtu_pins = (Pin(16), Pin(17))     # (TX, RX)
baudrate = 4800
uart_id = 0

sleep(5)

host = ModbusRTUMaster(
    pins=rtu_pins,          # given as tuple (TX, RX)
    baudrate=baudrate,      # optional, default 9600
    # data_bits=8,          # optional, default 8
    # stop_bits=1,          # optional, default 1
    # parity=None,          # optional, default None
    ctrl_pin=Pin(21),          # optional, control DE/RE
    uart_id=uart_id         # optional, default 1, see port specific docs
)


slave_addr = 0x01
hreg_address = 0x00
register_qty = 1

while True:
    register_value = host.read_holding_registers(
        slave_addr=slave_addr,
        starting_addr=hreg_address,
        register_qty=register_qty,
        signed=False)
    print(f'Reading: {register_value[0] / 10} dB') # Outputs the value in dB.
