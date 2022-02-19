#include <hal_gpio.h>
#include <hal_delay.h>
#include <hal_init.h>

#define LED0 GPIO(GPIO_PORTB, 22)

int cycles = 0;

int main() {
  // get the chip going
  init_mcu();
  delay_init(SysTick);

  // config GPIO
  gpio_set_pin_level(LED0, false);
  gpio_set_pin_direction(LED0, GPIO_DIRECTION_OUT);
  gpio_set_pin_function(LED0, GPIO_PIN_FUNCTION_OFF);

  // blink forever
  while (1) {
    gpio_set_pin_level(LED0, true);
    delay_ms(100);
    gpio_set_pin_level(LED0, false);
    delay_ms(100);
    cycles++;
  }

  return 0;
}