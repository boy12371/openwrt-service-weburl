# LuCI Service WebURL Application

A LuCI web interface for managing service URLs with SQLite backend on OpenWrt.

## Features

- **Service Management**: Add, edit, delete and view service URLs
- **Log System**: Record all operations with timestamps
- **Responsive Design**: Works on both desktop and mobile
- **Internationalization**: Support for multiple languages
- **Secure**: Input validation and SQL injection protection

## Screenshots

![Service List](screenshots/service-list.png)
![Service Settings](screenshots/service-settings.png)
![Operation Logs](screenshots/operation-logs.png)

## Installation

1. Ensure you have a working OpenWrt system
2. Install dependencies:
   ```bash
   opkg update
   opkg install lsqlite3
   ```
3. Install the application:
   ```bash
   # For development
   cp -r luci-app-service-weburl /usr/lib/lua/luci/
   # Or create an IPK package and install it
   make package/luci-app-service-weburl/compile V=99
   ```

## Configuration

Main configuration file: `/etc/config/service_weburl`

```bash
config main
    option enabled '1'
    option db_path '/var/lib/service_weburl.db'
    option log_retention_days '30'
```

## Usage

1. Access the LuCI web interface
2. Navigate to: `Services > Service Management`
3. Use the interface to manage your service URLs

## Development

### Dependencies

- OpenWrt SDK
- lsqlite3
- LuCI base libraries

### Build

```bash
make -C path/to/openwrt/sdk package/luci-app-service-weburl/compile
```

### File Structure

```
luci-app-service-weburl/
├── luasrc/                # Lua source code
│   ├── controller/        # MVC controllers
│   └── model/             # Data models
├── po/                    # Translation files
├── root/                  # System files
│   ├── etc/              # Configuration
│   └── usr/              # Runtime files
└── Makefile               # Build configuration
```

## License

MIT

## Author

Your Name <your.email@example.com>