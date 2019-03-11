/*
 * Atheros AP135 reference board support
 *
 * Copyright (c) 2012 Qualcomm Atheros
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <linux/platform_device.h>
#include <linux/ar8216_platform.h>

#include <asm/mach-ath79/ar71xx_regs.h>
#include <linux/delay.h>

#include "common.h"
#include "pci.h"
#include "dev-ap9x-pci.h"
#include "dev-gpio-buttons.h"
#include "dev-eth.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-nand.h"
#include "dev-wmac.h"
#include "machtypes.h"


#define EMG3425AAYJGPIO_LED_USB0		4
#define EMG3425AAYJGPIO_LED_USB1		13
#define EMG3425AAYJGPIO_LED_POWER		15
#define EMG3425AAYJGPIO_LED_INTERNET		17
#define EMG3425AAYJGPIO_LED_WLAN_2G		19
#define EMG3425AAYJGPIO_LED_WPS		21

//#define EMG3425AAYJGPIO_LED_WLAN_5G		20
#define EMG3425AAYJGPIO_5GWIFI_RESET		18


#define EMG3425AAYJGPIO_BTN_WPS		22
#define EMG3425AAYJGPIO_BTN_RESET		23
#define EMG3425AAYJGPIO_BTN_USB0		14
#define EMG3425AAYJGPIO_BTN_USB1		0
#define EMG3425AAYJGPIO_BTN_WLAN_DISABLE	1

#define EMG3425AAYJKEYS_POLL_INTERVAL	20	/* msecs */
#define EMG3425AAYJKEYS_DEBOUNCE_INTERVAL	(3 * EMG3425AAYJKEYS_POLL_INTERVAL)

#define EMG3425AAYJMAC0_OFFSET		0
#define EMG3425AAYJMAC1_OFFSET		6
#define EMG3425AAYJWMAC_CALDATA_OFFSET	0x1000
#define EMG3425AAYJPCIE_CALDATA_OFFSET	0x5000

static struct gpio_led emg3425aayj_leds_gpio[] __initdata = {
	{
		.name		= "POWER",
		.gpio		= EMG3425AAYJGPIO_LED_POWER,
		.active_low	= 0,
	},
	{
		.name		= "USB0",
		.gpio		= EMG3425AAYJGPIO_LED_USB0,
		.active_low	= 0,
	},
	{
		.name		= "USB1",
		.gpio		= EMG3425AAYJGPIO_LED_USB1,
		.active_low	= 0,
	},
//	{
//		.name		= "WiFi_5G",
//		.gpio		= EMG3425AAYJGPIO_LED_WLAN_5G,
//		.active_low	= 1,
//	},
	{
		.name		= "WiFi_2G",
		.gpio		= EMG3425AAYJGPIO_LED_WLAN_2G,
		.active_low	= 0,
	},
	{
		.name		= "INTERNET",
		.gpio		= EMG3425AAYJGPIO_LED_INTERNET,
		.active_low	= 0,
	},
	{
		.name		= "WPS",
		.gpio		= EMG3425AAYJGPIO_LED_WPS,
		.active_low	= 0,
	},
	{
		.name		= "WiFi_5G_RESET",
		.gpio		= EMG3425AAYJGPIO_5GWIFI_RESET,
		.active_low	= 1,
	},
};

static struct gpio_keys_button emg3425aayj_gpio_keys[] __initdata = {
	{
		.desc		= "WPS",
		.type		= EV_KEY,
		.code		= BTN_2,
		.debounce_interval = EMG3425AAYJKEYS_DEBOUNCE_INTERVAL,
		.gpio		= EMG3425AAYJGPIO_BTN_WPS,
		.active_low	= 1,
	},
	{
		.desc		= "RESET",
		.type		= EV_KEY,
		.code		= BTN_0,
		.debounce_interval = EMG3425AAYJKEYS_DEBOUNCE_INTERVAL,
		.gpio		= EMG3425AAYJGPIO_BTN_RESET,
		.active_low	= 1,
	},
	{
		.desc		= "USB0",
		.type		= EV_KEY,
		.code		= BTN_3,
		.debounce_interval = EMG3425AAYJKEYS_DEBOUNCE_INTERVAL,
		.gpio		= EMG3425AAYJGPIO_BTN_USB0,
		.active_low	= 1,
	},
	{
		.desc		= "USB1",
		.type		= EV_KEY,
		.code		= BTN_4,
		.debounce_interval = EMG3425AAYJKEYS_DEBOUNCE_INTERVAL,
		.gpio		= EMG3425AAYJGPIO_BTN_USB1,
		.active_low	= 1,
	},
	{
		.desc		= "WLAN_DISABLE",
		.type		= EV_KEY,
		.code		= BTN_5,
		.debounce_interval = EMG3425AAYJKEYS_DEBOUNCE_INTERVAL,
		.gpio		= EMG3425AAYJGPIO_BTN_WLAN_DISABLE,
		.active_low	= 1,
	}
};

static struct ar8327_pad_cfg emg3425aayj_ar8327_pad0_cfg = {
	.mode = AR8327_PAD_MAC_SGMII,
	.sgmii_clk_phase_sel = AR8327_SGMII_CLK_PHASE_SEL3,
};

static struct ar8327_pad_cfg emg3425aayj_ar8327_pad6_cfg = {
	.mode = AR8327_PAD_MAC_RGMII,
	.txclk_delay_en = true,
	.rxclk_delay_en = true,
	.txclk_delay_sel = AR8327_CLK_DELAY_SEL1,
	.rxclk_delay_sel = AR8327_CLK_DELAY_SEL2,
};

static struct ar8327_led_cfg emg3425aayj_ar8327_led_cfg;

static struct ar8327_platform_data emg3425aayj_ar8327_data = {
	.pad0_cfg = &emg3425aayj_ar8327_pad0_cfg,
	.pad6_cfg = &emg3425aayj_ar8327_pad6_cfg,
	.port0_cfg = {
		.force_link = 1,
		.speed = AR8327_PORT_SPEED_1000,
		.duplex = 1,
		.txpause = 1,
		.rxpause = 1,
	},
	.port6_cfg = {
		.force_link = 1,
		.speed = AR8327_PORT_SPEED_1000,
		.duplex = 1,
		.txpause = 1,
		.rxpause = 1,
	},
	.led_cfg = &emg3425aayj_ar8327_led_cfg
};

static struct mdio_board_info emg3425aayj_mdio0_info[] = {
	{
		.bus_id = "ag71xx-mdio.0",
		.phy_addr = 0,
		.platform_data = &emg3425aayj_ar8327_data,
	},
};

static void __init check_sgmii_debug(void)
{
	void __iomem *base;
	u32 t;

	base = ioremap(QCA955X_GMAC_BASE, QCA955X_GMAC_SIZE);

	t = __raw_readl(base + 0x58) & 0xff;
	
	if (!(t == 0x0F || t == 0x10)) {
           /* sgmii interface is not in a expected state. Issue PHY reset in two steps (SW WAR) */
           /* SGMII WAR Step 1: Initiate the PHY reset */
		
	   t = __raw_readl(base + 0x1c) | 0x00008000;		
	   __raw_writel(t, base + 0x1c);          

           /* Step 2 is releasing the PHY reset which will be done after
              setting the link to down in the next polling */
	   mdelay(1000);		
	   t = __raw_readl(base + 0x1c) & 0xffff7fff;
	   __raw_writel(t, base + 0x1c);    		
        }
	
	iounmap(base);
}

static void __init emg3425aayj_gmac_setup(void)
{
	void __iomem *base;
	u32 t;

	base = ioremap(QCA955X_GMAC_BASE, QCA955X_GMAC_SIZE);

	t = __raw_readl(base + QCA955X_GMAC_REG_ETH_CFG);

	t &= ~(QCA955X_ETH_CFG_RGMII_EN | QCA955X_ETH_CFG_GE0_SGMII);
	t |= QCA955X_ETH_CFG_RGMII_EN;
	__raw_writel(t, base + QCA955X_GMAC_REG_ETH_CFG);

	iounmap(base);
}

static void __init emg3425aayj_common_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1f050000);
	//printk("EMG3425AAYJ: ART address=0x%08X\n", (u32)art);

	ath79_register_m25p80(NULL);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(emg3425aayj_leds_gpio),
				 emg3425aayj_leds_gpio);
	ath79_register_gpio_keys_polled(-1, EMG3425AAYJKEYS_POLL_INTERVAL,
					ARRAY_SIZE(emg3425aayj_gpio_keys),
					emg3425aayj_gpio_keys);

	ath79_register_usb();
	ath79_register_wmac(art + EMG3425AAYJWMAC_CALDATA_OFFSET, NULL);
	//ap91_pci_init(art + EMG3425AAYJPCIE_CALDATA_OFFSET, NULL);
	ath79_register_pci();

	emg3425aayj_gmac_setup();

	ath79_register_mdio(0, 0x0);

	ath79_init_mac(ath79_eth0_data.mac_addr, art + EMG3425AAYJMAC0_OFFSET, 0);
	ath79_init_mac(ath79_eth1_data.mac_addr, art + EMG3425AAYJMAC1_OFFSET, 0);

	mdiobus_register_board_info(emg3425aayj_mdio0_info,
				    ARRAY_SIZE(emg3425aayj_mdio0_info));

	/* GMAC0 is connected to RGMII interface */
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_RGMII;
	ath79_eth0_data.phy_mask = BIT(0);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;
	ath79_eth0_pll_data.pll_1000 = 0xa6000000;

	/* GMAC1 is connected to SGMII interface */
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_SGMII;
	ath79_eth1_data.speed = SPEED_1000;
	ath79_eth1_data.duplex = DUPLEX_FULL;
	ath79_eth1_pll_data.pll_1000 = 0x03000101;

	ath79_register_eth(0);
	ath79_register_eth(1);

	//Gary
	check_sgmii_debug();

}

static void __init emg3425aayj_setup(void)
{
	emg3425aayj_ar8327_pad0_cfg.mode = AR8327_PAD_MAC_SGMII;
	emg3425aayj_ar8327_pad0_cfg.sgmii_clk_phase_sel = AR8327_SGMII_CLK_PHASE_SEL3;

	emg3425aayj_ar8327_pad6_cfg.mode = AR8327_PAD_MAC_RGMII;
	emg3425aayj_ar8327_pad6_cfg.txclk_delay_en = true;
	emg3425aayj_ar8327_pad6_cfg.rxclk_delay_en = true;
	emg3425aayj_ar8327_pad6_cfg.txclk_delay_sel = AR8327_CLK_DELAY_SEL1;
	emg3425aayj_ar8327_pad6_cfg.rxclk_delay_sel = AR8327_CLK_DELAY_SEL2;

	ath79_eth0_pll_data.pll_1000 = 0xa6000000;
	ath79_eth1_pll_data.pll_1000 = 0x03000101;

	emg3425aayj_ar8327_led_cfg.open_drain = 0;
	emg3425aayj_ar8327_led_cfg.led_ctrl0 = 0xffb7ffb7;
	emg3425aayj_ar8327_led_cfg.led_ctrl1 = 0xffb7ffb7;
	emg3425aayj_ar8327_led_cfg.led_ctrl2 = 0xffb7ffb7;
	emg3425aayj_ar8327_led_cfg.led_ctrl3 = 0x03ffff00;

	emg3425aayj_common_setup();
	ath79_register_nand();
}

MIPS_MACHINE(ATH79_MACH_EMG3425AAYJ, "EMG-3425AAYJQ10A", "ZyXEL EMG3425AAYJ",
	     emg3425aayj_setup);
