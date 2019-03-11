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

#include "common.h"
#include "dev-ap9x-pci.h"
#include "dev-gpio-buttons.h"
#include "dev-eth.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"

#define AP135_GPIO_LED_USB		4
#define AP135_GPIO_LED_WLAN_5G		12
#define AP135_GPIO_LED_WLAN_2G		13
#define AP135_GPIO_LED_STATUS_RED	14
#define AP135_GPIO_LED_WPS_RED		15
#define AP135_GPIO_LED_STATUS_GREEN	19
#define AP135_GPIO_LED_WPS_GREEN	20

#define AP135_GPIO_BTN_WPS		16
#define AP135_GPIO_BTN_RFKILL		21

#define AP135_KEYS_POLL_INTERVAL	20	/* msecs */
#define AP135_KEYS_DEBOUNCE_INTERVAL	(3 * AP135_KEYS_POLL_INTERVAL)

#define AP135_MAC0_OFFSET		0
#define AP135_MAC1_OFFSET		6
#define AP135_WMAC_CALDATA_OFFSET	0x1000
#define AP135_PCIE_CALDATA_OFFSET	0x5000

#define CONFIG_QCA955x_GE0_IS_SGMII

static struct gpio_led ap135_leds_gpio[] __initdata = {
	{
		.name		= "ap135:green:status",
		.gpio		= AP135_GPIO_LED_STATUS_GREEN,
		.active_low	= 1,
	},
	{
		.name		= "ap135:red:status",
		.gpio		= AP135_GPIO_LED_STATUS_RED,
		.active_low	= 1,
	},
	{
		.name		= "ap135:green:wps",
		.gpio		= AP135_GPIO_LED_WPS_GREEN,
		.active_low	= 1,
	},
	{
		.name		= "ap135:red:wps",
		.gpio		= AP135_GPIO_LED_WPS_RED,
		.active_low	= 1,
	},
	{
		.name		= "ap135:red:wlan-2g",
		.gpio		= AP135_GPIO_LED_WLAN_2G,
		.active_low	= 1,
	},
	{
		.name		= "ap135:red:usb",
		.gpio		= AP135_GPIO_LED_USB,
		.active_low	= 1,
	}
};

static struct gpio_keys_button ap135_gpio_keys[] __initdata = {
	{
		.desc		= "WPS button",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.debounce_interval = AP135_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= AP135_GPIO_BTN_WPS,
		.active_low	= 1,
	},
	{
		.desc		= "RFKILL button",
		.type		= EV_KEY,
		.code		= KEY_RFKILL,
		.debounce_interval = AP135_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= AP135_GPIO_BTN_RFKILL,
		.active_low	= 1,
	},
};

static struct ar8327_pad_cfg ap135_ar8327_pad0_cfg;
static struct ar8327_pad_cfg ap135_ar8327_pad6_cfg;

static struct ar8327_platform_data ap135_ar8327_data = {
	.pad0_cfg = &ap135_ar8327_pad0_cfg,
	.pad6_cfg = &ap135_ar8327_pad6_cfg,
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
	}
};

static struct mdio_board_info ap135_mdio0_info[] = {
	{
		.bus_id = "ag71xx-mdio.0",
		.phy_addr = 0,
		.platform_data = &ap135_ar8327_data,
	},
};

static void __init ap135_gmac_setup(void)
{
	void __iomem *base;
	u32 t;

	base = ioremap(QCA955X_GMAC_BASE, QCA955X_GMAC_SIZE);

	t = __raw_readl(base + QCA955X_GMAC_REG_ETH_CFG);

	t &= ~(QCA955X_ETH_CFG_RGMII_EN | QCA955X_ETH_CFG_GE0_SGMII);
#ifdef CONFIG_QCA955x_GE0_IS_SGMII
    t |= QCA955X_ETH_CFG_GE0_SGMII;
#else
	t |= QCA955X_ETH_CFG_RGMII_EN;
#endif
	__raw_writel(t, base + QCA955X_GMAC_REG_ETH_CFG);

	iounmap(base);
}

static void __init ap135_common_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(ap135_leds_gpio),
				 ap135_leds_gpio);
	ath79_register_gpio_keys_polled(-1, AP135_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(ap135_gpio_keys),
					ap135_gpio_keys);

	ath79_register_usb();
	ath79_register_wmac(art + AP135_WMAC_CALDATA_OFFSET, NULL);
	ap91_pci_init(art + AP135_PCIE_CALDATA_OFFSET, NULL);

	ap135_gmac_setup();

	ath79_register_mdio(0, 0x0);

	ath79_init_mac(ath79_eth0_data.mac_addr, art + AP135_MAC0_OFFSET, 0);

	mdiobus_register_board_info(ap135_mdio0_info,
				    ARRAY_SIZE(ap135_mdio0_info));

#ifdef CONFIG_QCA955x_GE0_IS_SGMII
    /* GMAC0 is connected to SGMII interface */
    ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_SGMII;
    ath79_eth0_data.phy_mask = BIT(0);
    ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;

    /* GMAC1 is connected tot eh RGMII interface */
    ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_RGMII;
    ath79_eth1_data.speed = SPEED_1000;
    ath79_eth1_data.duplex = DUPLEX_FULL;
#else
    /* GMAC0 is connected to RGMII interface */
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_RGMII;
	ath79_eth0_data.phy_mask = BIT(0);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;

	/* GMAC1 is connected to SGMII interface */
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_SGMII;
	ath79_eth1_data.speed = SPEED_1000;
	ath79_eth1_data.duplex = DUPLEX_FULL;
#endif

    ath79_register_eth(0);
    //ath79_register_eth(1);
}

static void __init ap135_setup(void)
{
	/* GMAC0 of the AR8327 switch is connected to QCA955x via SGMII */
	ap135_ar8327_pad0_cfg.mode = AR8327_PAD_MAC_SGMII;
	ap135_ar8327_pad0_cfg.sgmii_delay_en = true;

	/* GMAC6 of the AR8327 switch is connected to QCA955x via RGMII */
	ap135_ar8327_pad6_cfg.mode = AR8327_PAD_MAC_RGMII;
	ap135_ar8327_pad6_cfg.txclk_delay_en = true;
	ap135_ar8327_pad6_cfg.rxclk_delay_en = true;
	ap135_ar8327_pad6_cfg.txclk_delay_sel = AR8327_CLK_DELAY_SEL1;
	ap135_ar8327_pad6_cfg.rxclk_delay_sel = AR8327_CLK_DELAY_SEL2;

#ifdef CONFIG_QCA955x_GE0_IS_SGMII
    ath79_eth0_pll_data.pll_1000 = 0x03000101;
    ath79_eth1_pll_data.pll_1000 = 0x56000000;
#else
    ath79_eth0_pll_data.pll_1000 = 0x56000000;
	ath79_eth1_pll_data.pll_1000 = 0x03000101;
#endif

	ap135_common_setup();
}

MIPS_MACHINE(ATH79_MACH_AP135, "AP135", "Atheros AP135 reference board",
	     ap135_setup);
