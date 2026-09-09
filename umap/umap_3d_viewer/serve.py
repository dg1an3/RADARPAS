"""Dual-stack static server for the UMAP viewer (HTTP or HTTPS).

`python -m http.server --bind 0.0.0.0` listens on IPv4 only, so accessing the
machine by hostname (fractadon.local) fails when the name resolves to an IPv6
address first. This binds [::] with IPV6_V6ONLY disabled, so the same socket
serves both IPv4 and IPv6 on every interface.

WebXR needs a *secure context* (HTTPS) for any non-localhost origin, so to use
a real headset over the LAN you need HTTPS. Pass --https to serve TLS with a
self-signed cert (auto-generated via `cryptography` on first run). The headset
will show a one-time "not private" warning — proceed past it.

Usage:
  python serve.py [port]                 # HTTP  (good for desktop / localhost)
  python serve.py [port] --https         # HTTPS (needed for a real headset)
"""
import datetime
import ipaddress
import socket
import socketserver
import ssl
import sys
from http.server import SimpleHTTPRequestHandler
from pathlib import Path

PORT = next((int(a) for a in sys.argv[1:] if a.isdigit()), 8777)
HTTPS = "--https" in sys.argv

HERE = Path(__file__).resolve().parent
CERT = HERE / "cert.pem"
KEY = HERE / "key.pem"

# Names/addresses to embed in the self-signed cert's SubjectAltName.
SAN_DNS = ["fractadon.local", "fractadon", "localhost"]
SAN_IP = ["127.0.0.1", "::1", "10.0.0.179"]


def ensure_cert():
    if CERT.exists() and KEY.exists():
        return
    from cryptography import x509
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.x509.oid import NameOID

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "fractadon.local")])
    alt = [x509.DNSName(d) for d in SAN_DNS]
    alt += [x509.IPAddress(ipaddress.ip_address(ip)) for ip in SAN_IP]
    now = datetime.datetime.utcnow()
    cert = (
        x509.CertificateBuilder()
        .subject_name(name).issuer_name(name)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - datetime.timedelta(days=1))
        .not_valid_after(now + datetime.timedelta(days=825))
        .add_extension(x509.SubjectAlternativeName(alt), critical=False)
        .sign(key, hashes.SHA256())
    )
    KEY.write_bytes(key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.TraditionalOpenSSL,
        serialization.NoEncryption()))
    CERT.write_bytes(cert.public_bytes(serialization.Encoding.PEM))
    print(f"generated self-signed cert: {CERT.name}, {KEY.name}")


class NoCacheHandler(SimpleHTTPRequestHandler):
    """Serve files with no-cache headers so reloads always pick up fresh
    data.json / index.html instead of a stale browser copy."""

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


class DualStackServer(socketserver.TCPServer):
    address_family = socket.AF_INET6
    allow_reuse_address = True

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        super().server_bind()


if __name__ == "__main__":
    httpd = DualStackServer(("::", PORT), NoCacheHandler)
    scheme = "http"
    if HTTPS:
        ensure_cert()
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain(certfile=str(CERT), keyfile=str(KEY))
        httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
        scheme = "https"
    print(f"serving dual-stack {scheme.upper()} (IPv4 + IPv6) on port {PORT}")
    print(f"  {scheme}://localhost:{PORT}/   {scheme}://fractadon.local:{PORT}/")
    httpd.serve_forever()
