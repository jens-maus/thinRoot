/*
 * thinRoot boot server: iPXE build options
 *
 * Copied to src/config/local/general.h, which iPXE includes after its
 * defaults, so these settings also apply to the BIOS (pcbios) builds.
 */

#define NSLOOKUP_CMD	/* DNS resolving command */
#define PING_CMD	/* Ping command */
#define TIME_CMD	/* Time commands (provides "sleep") */
#define CONSOLE_CMD	/* Console command, used by boot/net.theme */
#define IMAGE_PNG	/* PNG support for the boot menu background */
#define REBOOT_CMD	/* Reboot command */
#define POWEROFF_CMD	/* Power off command */
