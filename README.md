wg-api-web
==========

This is a simple web monitoring tool for WireGuard connections.
It uses [wg-api] to query data and formats it as a nice, sortable HTML table.

[wg-api]: https://github.com/jamescun/wg-api

Usage
-----

Clone the repository and run

    WG_IFACE=wg0 docker-compose up -d

Replace `WG_IFACE` with your interface name (or omit it to use wg0).

### Peer aliases

You can set readable aliases for peers' public keys.
Put them in a file and map to /data/aliases.
See [data/aliases] for an example.

[data/aliases]: data/aliases

Basically, it's like a `hosts` file, with keys on the left and readable names
on the right.

License
-------

Distributed under the MIT License.
See [LICENSE.txt] for details.

[LICENSE.txt]: LICENSE.txt
