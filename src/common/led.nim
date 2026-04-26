import std/strformat

const SunxiLedPath = "/sys/devices/platform/sunxi-led/leds"

type LedColour* = enum
    Red = 1
    Green = 2
    Blue = 3

type LedTrigger* = enum
    On = "default-on"
    Off = "none"
    BatteryChargingOrFull = "lradc_battery-charging-or-full"
    BatteryCharging = "lradc_battery-charging"
    BatteryFull = "lradc_battery-full"
    BatteryChargingBlinkFullSolid = "lradc_battery-charging-blink-full-solid"
    MMC0 = "mmc0"
    MMC1 = "mmc1"
    MMC2 = "mmc2"
    Timer = "timer"
    Heartbeat = "heartbeat"
    DoubleFlash = "doubleflash"
    Backlight = "backlight"
    GPIO = "gpio"

proc setLedBrightness*(colour: LedColour, val: int) =
    writeFile(
        &"{SunxiLedPath}/led{colour.ord}/brightness",
        $max(0, min(val, 255))
    )

proc setLedTrigger*(colour: LedColour, trigger: LedTrigger) =
    writeFile(
        &"{SunxiLedPath}/led{colour.ord}/trigger",
        $trigger
    )

proc setLedTimer*(colour: LedColour, delayOff: int, delayOn: int) =
    setLedTrigger(colour, LedTrigger.Timer)
    writeFile(
        &"{SunxiLedPath}/led{colour.ord}/delay_off",
        $delayOff
    )
    writeFile(
        &"{SunxiLedPath}/led{colour.ord}/delay_on",
        $delayOn
    )
